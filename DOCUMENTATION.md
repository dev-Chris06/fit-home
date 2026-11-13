# Documentation de Fit Home

Ce document explique **comment l'app est construite et pourquoi**, étape par étape, au fur et à mesure du projet.
Il sert à la fois de journal de bord et de support pour apprendre Flutter à partir d'un vrai projet.

---

## Les décisions de départ

| Sujet | Choix | Pourquoi |
| --- | --- | --- |
| Plateforme | Android uniquement | Le téléphone de l'utilisateur, test simple (même démarche que Loady) |
| Données | Sur le téléphone (`shared_preferences`) | L'app doit marcher sans internet ; pas de compte, pas de serveur |
| Animations | Redessinées en Dart (`CustomPainter`) | Légères, fluides, hors ligne ; pas de vidéos qui alourdissent l'APK |
| Construction de l'APK | GitHub Actions | Le PC de développement a 4 Go de RAM : on ne compile pas dessus |
| Mises à jour | Releases GitHub + bouton dans l'app | Pas de Play Store : l'app compare sa version à la dernière release |
| Style | Bleu nuit, vert menthe, orange | Le même que les animations du programme |

---

## Architecture

```
lib/
├── main.dart                  Point d'entrée, thème, barre de navigation (4 onglets)
├── app_state.dart             Journal, palier, réglages ; sauvegarde sur le téléphone
├── theme.dart                 Couleurs et composants visuels communs (Panel, Eyebrow)
├── data/
│   ├── programme.dart         Les 32 exercices, les séances, les paliers (toutes les données)
│   └── session_plan.dart      Transforme une séance en étapes : effort, repos, effort…
├── anim/
│   ├── stage.dart             Le moteur : silhouette posée par angles, formes, accessoires
│   ├── exercise_anims.dart    Les 32 animations (une fonction par exercice)
│   └── exercise_view.dart     Le widget qui joue une animation en boucle
├── services/
│   └── update_service.dart    Recherche de mise à jour (seul appel internet de l'app)
├── widgets/                   Morceaux d'interface réutilisés (dialogue de mise à jour, tuiles…)
└── screens/                   Les écrans : accueil, séances, exercice, séance guidée, journal, plus…
test/
├── logic_test.dart            Rotation A→B→C, paliers, plan de séance, comparaison de versions
├── anim_test.dart             Les 32 animations : pas de plantage, aucun membre sous le sol
└── widget_test.dart           L'app démarre et propose la séance A
```

La règle suivie partout : **la logique est séparée de l'affichage**. `programme.dart`, `session_plan.dart` et
`JournalLogic` (dans `app_state.dart`) ne connaissent rien de l'écran ; on peut donc les tester sans téléphone.

---

## Journal de construction

### Étape 1 — Base de l'app : données, thème, état

**Ce qui a été fait**
- `pubspec.yaml` minimal. Les dépendances ne sont pas écrites à la main : le workflow `bootstrap` les ajoute avec
  `flutter pub add`, qui choisit des versions compatibles avec le Flutter de la CI.
- `data/programme.dart` : chaque exercice a un `id` (ex. `squat`), un nom, une zone travaillée et un conseil.
  Une séance (`SessionDef`) est une liste de `SessionItem` : exercice + séries + répétitions (+ durée si l'effort est chronométré).
- `data/session_plan.dart` : `buildPlan()` déroule une séance en étapes `PlanStep` (effort ou repos). C'est là que vivent les règles :
  repos de 60 s (40 s au palier 3), circuit de 3 tours (4 au palier 3), alternances une séance sur deux
  (curl marteau, chaise contre le mur), pompes classiques au palier 3.
- `app_state.dart` : `AppState` est un `ChangeNotifier`. Quand le journal change, il appelle `notifyListeners()` et les écrans
  enveloppés dans un `ListenableBuilder` se redessinent. Les données sont enregistrées en JSON dans `shared_preferences`.

**À retenir (Flutter)**
- `ChangeNotifier` + `ListenableBuilder` : la façon la plus simple de partager un état sans librairie externe.
- `const` partout où c'est possible : Flutter réutilise ces objets au lieu de les recréer à chaque image.
- Le nom `Step` existait déjà dans Flutter (widget `Stepper`) : la classe a été renommée `PlanStep` pour éviter le conflit.

### Étape 2 — Le moteur d'animation

**L'idée** : la silhouette n'est pas une image, c'est un squelette. On donne des angles (buste, bras, avant-bras, cuisse, tibia, pied)
et le moteur calcule la position de chaque articulation, puis trace des traits épais à bouts ronds.

- Convention : 0° = vers la droite, 90° = vers le bas, -90° = vers le haut. `at(p, angle, longueur)` donne le point au bout d'un segment.
- `ik()` (cinématique inverse) : on fixe le bout d'un membre (la main au sol pendant une pompe, le pied sur le tapis)
  et la fonction trouve où doit être le coude ou le genou. C'est ce qui empêche les mains de glisser et le coude de se retourner.
- Chaque animation est une fonction pure `(Scene s, double t)` : pour un même `t`, la même image.
  Le widget `ExerciseView` fait avancer `t` avec un `Ticker` (≈ 60 images/s) et un `CustomPainter` dessine la scène.
- `TickerMode` coupe les animations des onglets cachés pour économiser la batterie.
- Le halo orange (`zone`) montre le muscle travaillé ; la flèche orange montre le sens du mouvement.

**Le test qui protège les animations** : `anim_test.dart` joue chaque animation sur 8 secondes (400 images) et vérifie
qu'aucun membre ne descend sous le sol (y > 886) et qu'aucune coordonnée n'est invalide. C'était le défaut principal
signalé sur les animations web ; le test l'empêche de revenir.

### Étape 3 — Les écrans

- **Accueil** : la prochaine séance est calculée par `JournalLogic.nextSession()` (rotation A → B → C d'après le journal).
- **Séance guidée** : un `Timer.periodic` de 200 ms compare l'heure de fin (`endAt`) à l'heure actuelle.
  Calculer à partir d'une heure de fin plutôt que décrémenter un compteur évite la dérive du minuteur.
  Pause = on mémorise le temps restant ; reprise = nouvelle heure de fin. Vibration à la fin de chaque minuteur et pendant les 3 dernières secondes.
  `WakelockPlus` garde l'écran allumé pendant la séance. `PopScope` demande confirmation avant de quitter.
- **Journal** : formulaire (séance, date, charge, ressenti, séries réussies, notes), historique, choix du palier.
  `palierAdvice()` conseille de monter après 3 séances réussies et pas dures, ou d'alléger après 2 séances dures et ratées.
- **Plus** : paliers, alimentation, sécurité, mises à jour.

### Étape 4 — Mises à jour et intégration continue

**Recherche de mise à jour** (`services/update_service.dart`)
1. L'app lit sa propre version avec `package_info_plus`.
2. Elle demande à l'API GitHub la dernière release : `GET /repos/dev-Chris06/fit-home/releases/latest`.
3. Elle compare les numéros (`isNewer`, testé) ; si la release est plus récente, un dialogue propose de télécharger l'APK.
4. Le téléchargement s'ouvre dans le navigateur (`url_launcher`) ; Android installe la nouvelle version par-dessus l'ancienne.

Pour qu'Android accepte une mise à jour par-dessus l'ancienne version, **toutes les versions doivent être signées avec la même clé**.
La clé de signature est stockée dans les secrets GitHub du dépôt (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`), jamais dans le code. Une copie de sauvegarde est gardée hors du dépôt :
si elle est perdue, il faudra désinstaller l'app pour installer les versions suivantes.

**Les workflows GitHub Actions**

| Workflow | Quand | Ce qu'il fait |
| --- | --- | --- |
| `bootstrap.yml` | Une seule fois, au premier envoi | `flutter create` génère le dossier `android/`, `flutter pub add` ajoute les dépendances |
| `ci.yml` | À chaque envoi sur `main` | Analyse, tests, APK de contrôle (dans l'onglet Actions) |
| `release.yml` | Quand on envoie un tag `vX.Y.Z` | Tests, APK signé, release GitHub avec `fit-home.apk` et les notes du `CHANGELOG.md` |

Le numéro de build Android (`versionCode`) est calculé à partir de l'heure : il augmente toujours, condition pour qu'Android accepte la mise à jour.

### Étape 5 — Compilation, corrections et publication

*(complétée au fil de la compilation sur GitHub Actions)*
