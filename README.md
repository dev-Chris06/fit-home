# Fit Home

Application Android de programme sportif à la maison, **100 % hors ligne** : trois séances qui tournent (A → B → C),
une mini-séance posture et souplesse, 52 exercices animés, une séance guidée avec minuteur, un journal et des paliers de progression.

Faite avec Flutter par [dev-Chris06](https://github.com/dev-Chris06).

## Installer l'app

1. Sur ton téléphone Android, ouvre ce lien : **[télécharger fit-home.apk](https://github.com/dev-Chris06/fit-home/releases/latest/download/fit-home.apk)**.
2. Ouvre le fichier téléchargé. Android demande d'autoriser l'installation depuis ton navigateur : accepte pour ce navigateur.
3. Installe, puis ouvre **Fit Home**.

## Mettre à jour

Dans l'app : onglet **Plus → Rechercher une mise à jour**. Si une version plus récente existe, l'app propose de la télécharger ;
installe-la par-dessus l'ancienne : ton journal et tes réglages sont conservés.
L'app peut aussi vérifier toute seule au démarrage (une fois par jour, seulement avec internet) : option dans le même écran.

## Ce que fait l'app

| Écran | Rôle |
| --- | --- |
| Accueil | La prochaine séance de la rotation, un bouton pour la lancer, les statistiques |
| Séances | Échauffement, séances A, B, C, posture et variantes, avec l'animation de chaque exercice et le bouton « Remplacer » |
| Exercices | La bibliothèque des 52 exercices, filtrable par famille et par palier |
| Séance guidée | Enchaîne échauffement, séries et repos avec un minuteur ; l'écran reste allumé |
| Progrès | Les séances notées, le palier actuel et le conseil pour monter de palier |
| Plus | Paliers, alimentation, conseils de sécurité, mises à jour |

## Pour les développeurs

- Code : `lib/` (voir [DOCUMENTATION.md](DOCUMENTATION.md) pour l'architecture et le journal de construction).
- Les APK sont construits par **GitHub Actions** (`.github/workflows/`), pas besoin de compiler sur son PC.
- Publier une version : changer `version:` dans `pubspec.yaml`, ajouter la section correspondante dans `CHANGELOG.md`, envoyer sur `main` → le workflow `release` publie l'APK.
- Tests : `flutter test` (logique des séances, paliers, versions, et vérification des 52 animations).
