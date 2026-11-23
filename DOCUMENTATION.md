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
| `release.yml` | À chaque envoi sur `main` | Si la version de `pubspec.yaml` n'est pas encore publiée : tests, APK signé, release GitHub avec `fit-home.apk` et les notes du `CHANGELOG.md` |

Le tag `vX.Y.Z` est créé par le workflow lui-même. Le numéro de build Android (`versionCode`) est calculé à partir de l'heure : il augmente toujours, condition pour qu'Android accepte la mise à jour.

### Étape 5 — Compilation, corrections et publication

La CI utilise **Flutter 3.50.0** (Dart 3.14). Voici les problèmes rencontrés et leur solution : c'est la partie la plus instructive.

| Problème | Cause | Solution |
| --- | --- | --- |
| Le workflow `bootstrap` échoue : « No such file or directory » | Git ne garde pas les dossiers vides : `docs/` n'existait pas sur la machine GitHub | `mkdir -p docs` avant d'y écrire |
| `ambiguous_import` sur `Ink` | Notre classe de couleurs s'appelait `Ink`, comme un widget de Flutter | Renommée `Tone` (même problème que `Step` → `PlanStep` à l'étape 1) |
| La construction de l'APK plante dans `lintVitalAnalyzeRelease` | Bug de l'outil d'analyse Android sur le code du plugin `url_launcher_android` | Tâches `lintVital*` désactivées dans `android/build.gradle.kts` (nos tests Dart restent actifs) |
| Avertissement sur `setMockInitialValues` | Une fonction réservée aux tests utilisée hors du dossier `test/` | Dossier `screenshots/` exclu de l'analyse |
| L'envoi d'un tag `v1.0.0` est refusé | L'environnement de travail n'a pas le droit de créer des tags sur GitHub | La release se déclenche désormais quand la version de `pubspec.yaml` change ; c'est le workflow qui crée le tag |
| Impossible de télécharger les captures depuis l'onglet Actions | Le stockage des « artifacts » n'est pas accessible depuis l'environnement de travail | La CI publie aussi les captures sur une branche `captures` |

**Les avertissements « material.dart is deprecated »** : depuis Flutter 3.47, la bibliothèque Material est déplacée dans un
paquet séparé (`material_ui`). Ce ne sont que des informations, le code fonctionne ; la migration pourra se faire dans une prochaine version.

**Les captures de contrôle** (`screenshots/screens_test.dart`) : sans téléphone ni émulateur, la CI « photographie » les écrans
principaux et les 32 animations avec des tests Flutter (`matchesGoldenFile` + `--update-goldens`). On les retrouve sur la branche
`captures` du dépôt. C'est ainsi que l'interface a été vérifiée à l'œil avant la publication.

**Résultat** : 45 tests verts (logique, 32 animations sans membre sous le sol, démarrage de l'app), APK signé, release `v1.0.0` publiée
(`fit-home.apk`, environ 54 Mo).

**Piste pour une prochaine version** : l'APK est « universel » (il contient le code pour tous les processeurs Android, d'où sa taille).
On pourra publier des APK séparés par processeur (`--split-per-abi`, environ 20 Mo chacun) pour économiser les données mobiles.

### Version 1.0.1 — Retours après les premiers essais

| Retour | Ce qui se passait | Correction |
| --- | --- | --- |
| « Quand je passe le repos, ça revient en arrière » | Chaque exercice compte 3 séries : après le repos, l'app réaffichait le même exercice pour la série 2, ce qui ressemblait à un retour en arrière | Points « Série 2 sur 3 » à l'écran, repos qui annonce « avant la série 2 sur 3 du même exercice », bouton « Exercice suivant » |
| « À quoi sert la page Journal ? » | Il fallait penser à noter la séance, sinon la rotation A → B → C n'avançait pas | Enregistrement automatique en fin de séance + deux questions rapides ; onglet renommé « Progrès » avec une explication |
| Mention « fait avec Flutter par dev-Chris06 » | Jugée peu professionnelle | Retirée |

**Comment c'est fait**
- Chaque `PlanStep` connaît maintenant sa série (`set`, `sets`) et son exercice (`item`). Pour un repos, `set` désigne la série qui suit.
- `nextExerciseIndex()` cherche la première étape d'effort dont l'`item` change : c'est le bouton « Exercice suivant ». Testé dans `logic_test.dart`.
- À la fin de la séance, `_autoSave()` crée l'entrée avec des valeurs par défaut (ressenti « correct », séries non cochées) ;
  chaque réponse rapide appelle `app.updateEntry()` qui remplace l'entrée par sa copie modifiée (`copyWith`).

### Version 1.1.0 — Plus d'exercices, bibliothèque et remplacement

Demande : augmenter le nombre d'exercices. Choix faits par QCM : environ 20 de plus, dans les quatre familles
(abdos et gainage, fessiers et ischios, haut du corps, cardio et mobilité), consultables dans une bibliothèque et
utilisables dans une séance via un bouton « Remplacer », tous niveaux confondus avec le palier indiqué.

**Les données** (`lib/data/programme.dart`)
- `Groups` : les cinq familles (Jambes et fessiers, Haut du corps, Abdos et gainage, Cardio, Mobilité).
- `Exercise` reçoit `group`, `level` (1 à 3), `reps` (répétitions conseillées) et `seconds` (pour un maintien chronométré, sinon `null`).
  Les 32 anciens exercices ont été classés, 20 nouveaux ajoutés : 52 au total.

**Le remplacement** (`lib/data/session_plan.dart`, `lib/app_state.dart`)
- `app.subs` : pour chaque séance, la table « exercice d'origine → remplaçant », enregistrée sur le téléphone (clé `subs`).
- `effectiveItems()` applique d'abord les remplacements, puis les alternances habituelles (curl marteau, chaise, pompes classiques).
  Un exercice remplacé garde son nombre de séries et prend les répétitions (ou la durée) du remplaçant ; en circuit, la durée reste 40 s.
- Seuls les exercices de la même famille sont proposés ; « Revenir à … » annule le remplacement.

**Les écrans**
- Nouvel onglet « Exercices » (`library_screen.dart`) avec filtres par famille et par palier.
- Détail de séance : bouton à double flèche à côté de chaque exercice, mention « Remplace : … » quand il a été échangé.
- Fiche exercice : badge de palier et famille.

**Les animations** : 20 nouvelles fonctions dans `exercise_anims.dart`, avec quelques aides (`_frontLegsBody` pour les vues de face,
`_bridge` pour les ponts, `_handsAtTemples`, l'état d'un burpee). Le test « rien sous le sol » couvre les 52 animations,
et les captures 13 et 14 montrent les 20 nouvelles en grand à deux instants.

| Problème rencontré | Correction |
| --- | --- |
| Posture de l'enfant : la main éloignée passait sous le sol, puis la silhouette avait l'air allongée | Refaite : départ à genoux, fesses qui reculent sur les talons, buste couché sur les cuisses, bras devant, coude plié vers le haut |
| Filtres de la bibliothèque trop larges pour l'écran (débordement de 16 px) | Filtres sur plusieurs lignes (`Wrap`) |
| Le symbole ⇄ ne s'affichait pas avec la police de l'app | Remplacé par l'icône Material `swap_horiz` |

### Version 1.2 — Les rappels

Choix faits par QCM : un rappel que l'on règle soi-même au premier lancement et que l'on peut changer à tout moment,
délai de relance réglable (2 à 5 jours), heure réglable, rappels activés avec demande d'autorisation.

**Les deux modes** (`lib/data/reminders.dart`, fonctions pures testées dans `logic_test.dart`)
- *Relance* : une notification le jour « dernière séance + N jours » à l'heure choisie, puis deux relances 2 et 4 jours plus tard.
  Si cette date est déjà passée, le rappel arrive à la prochaine occurrence de l'heure choisie. Sans aucune séance, on compte à partir d'aujourd'hui.
- *Jours fixes* : chaque jour coché des 4 prochaines semaines, sauf un jour où une séance est déjà notée.
- Tout est recalculé au lancement de l'app, à chaque séance enregistrée ou supprimée, et à chaque changement de réglage
  (`app.onScheduleChange`, branché sur `Reminders.reschedule` dans `main.dart`).

**L'envoi** (`lib/services/reminder_service.dart`) : `flutter_local_notifications` programme les notifications dans Android.
- Mode « inexact » : Android peut décaler de quelques minutes pour économiser la batterie, mais aucune permission d'alarme exacte n'est demandée.
- L'heure locale est convertie en instant UTC (`TZDateTime.from(..., tz.UTC)`) : pas besoin de connaître le fuseau du téléphone.
- Après un redémarrage du téléphone, le plugin reprogramme les rappels (récepteur `BOOT_COMPLETED` dans le manifeste).
- Toutes les fonctions avalent leurs erreurs : un rappel raté ne doit jamais bloquer l'app (et dans les tests, il n'y a pas de notifications).

**Côté Android** : permissions `POST_NOTIFICATIONS` et `RECEIVE_BOOT_COMPLETED`, deux récepteurs du plugin, `compileSdk` 37 au minimum
et le *desugaring* (`desugar_jdk_libs`) exigés par le plugin.

**Les écrans** : `ReminderScreen` (premier lancement avec « Continuer », puis Plus → Rappels avec « Enregistrer » et un rappel d'essai).
Un encadré explique que l'économie de batterie de certaines marques peut bloquer les rappels.

| Problème rencontré | Correction |
| --- | --- |
| pub.dev inaccessible depuis l'environnement de travail | API du plugin lue directement dans son dépôt GitHub (version 23, paramètres nommés) |
| Test du premier lancement : bouton « Continuer » introuvable | Il était sous le bas de l'écran ; il est maintenant fixé en bas, toujours visible |
| Construction de l'APK en CI : erreur 429 de Maven (trop de requêtes) | Erreur passagère du serveur ; la publication, lancée en parallèle, a réussi |
| La flèche « → » ne s'affichait pas dans l'écran des rappels | Textes reformulés sans flèche (version 1.2.1) |

### Entretien du dépôt (23 novembre 2026)

| Point | Ce qui a été fait |
| --- | --- |
| Actions GitHub dépréciées (Node.js 20, `setup-java` v4 plus maintenu) | `actions/checkout@v7`, `actions/setup-java@v6`, `actions/upload-artifact@v7` dans les trois workflows |
| Erreurs 429 de Maven pendant la compilation | `cache: gradle` dans `setup-java` : les téléchargements de Gradle sont gardés d'une compilation à l'autre |
| Workflow `bootstrap` relancé à chaque envoi pour rien | Ne se lance plus qu'à la main (onglet Actions → bootstrap → Run workflow) |
| `pubspec.lock` en retard (sans la bibliothèque des rappels) | La CI calcule un `pubspec.lock` à jour à part et le publie sur la branche `captures` (`pubspec.lock.txt`), avec le bilan `dependances.txt` ; le fichier a été recopié dans le dépôt |
| `package:flutter/material.dart` déprécié depuis Flutter 3.47 | Passage au paquet `material_ui` (`import 'package:material_ui/material_ui.dart'`) ; les traductions du système viennent de `GlobalMaterialLocalizations.delegates` et `flutter_localizations` n'est plus nécessaire |
| Bibliothèques indirectes en retard (dbus, jni, url_launcher_android, vector_math) | Mises à jour par le nouveau `pubspec.lock`. `material_color_utilities` et `test_api` restent fixées par le SDK Flutter lui-même : c'est normal |

**Mettre à jour les bibliothèques plus tard** : ouvrir `dependances.txt` sur la branche `captures`. S'il signale des versions
bloquées, recopier `pubspec.lock.txt` de cette branche à la place de `pubspec.lock`, puis envoyer.

---

## Publier une nouvelle version (mode d'emploi)

1. Modifier le code.
2. Dans `pubspec.yaml`, changer la version : `version: 1.0.1+1`.
3. Ajouter en haut de `CHANGELOG.md` une section `## 1.0.1` avec les nouveautés.
4. Envoyer sur `main`. Le workflow `release` voit que la 1.0.1 n'existe pas encore, construit et publie `fit-home.apk`.
   Dans l'app, « Rechercher une mise à jour » la propose aussitôt.
