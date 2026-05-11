# WSL Manager

> Application Windows portable pour gérer visuellement vos instances WSL2.

![Version](https://img.shields.io/badge/version-1.1.0-blue)
![Platform](https://img.shields.io/badge/platform-Windows%2011%20x64-lightgrey)
![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.22-02569B)

---

## Présentation

WSL Manager est une application de bureau Windows (portable, sans installation) qui offre une interface graphique complète pour administrer vos distributions WSL2. Fini les commandes `wsl` en ligne de commande : toutes les opérations courantes sont accessibles en quelques clics.

L'application s'intègre dans la barre système et reste disponible en arrière-plan pour surveiller vos instances.

---

## Captures d'écran

### Tableau de bord

<!-- TODO: ajouter capture du tableau de bord -->

### Détail d'une instance

<!-- TODO: ajouter capture de l'écran de détail -->

### Assistant de création

<!-- TODO: ajouter capture du wizard de création -->

### Gestion des snapshots

<!-- TODO: ajouter capture de l'écran snapshots -->

### Gestion des templates

<!-- TODO: ajouter capture de l'écran templates -->

### Paramètres

<!-- TODO: ajouter capture de l'écran paramètres -->

---

## Fonctionnalités

### Gestion des instances
- **Démarrer / Arrêter** une instance en un clic
- **Créer** une nouvelle instance via un assistant pas-à-pas (nom, source, utilisateur, mot de passe, chemin d'installation)
- **Supprimer** une instance avec confirmation
- **Dupliquer** une instance existante
- **Renommer** une instance (export + import + désenregistrement automatiques)
- **Convertir** WSL1 ↔ WSL2 (avec élévation UAC à la demande)
- **Éditer** la configuration `.wslconfig` directement depuis l'interface

### Groupes
- Organiser les instances par **groupes personnalisés**
- Filtrage et affichage par groupe depuis le tableau de bord

### Snapshots
- **Créer** un snapshot (export `.tar`) d'une instance à tout moment
- **Restaurer** une instance depuis un snapshot
- **Gérer** la bibliothèque de snapshots (liste, suppression)

### Templates
- **Sauvegarder** une instance comme template réutilisable
- **Créer** rapidement une nouvelle instance depuis un template
- **Gérer** la bibliothèque de templates

### Monitoring
- Surveillance en temps réel du **CPU** et de la **RAM** par instance
- Barre de statistiques globales visible depuis le tableau de bord
- Graphiques de charge via `/proc/stat` et `/proc/meminfo`

### Intégration système
- **Icône dans la barre système** (systray) avec menu contextuel
- Option de **minimisation vers le systray** à la fermeture de la fenêtre
- Effet visuel **Mica** (Windows 11)

---

## Prérequis

| Composant | Version minimale |
|---|---|
| Windows | 11 x64 |
| WSL2 | activé et configuré |
| Aucun runtime .NET / VC++ requis | — |

---

## Installation

1. Télécharger `WSLManager_portable.zip` depuis la [page des releases](https://github.com/jordane45/wslManager/releases)
2. Extraire le contenu dans le dossier de votre choix
3. Lancer `WSLManager.exe`

Aucune installation requise. Les données de l'application (templates, snapshots, configuration) sont stockées dans `%LOCALAPPDATA%\WSLManager\`.

---

## Développement

### Prérequis

- [Flutter](https://flutter.dev) stable >= 3.22
- Dart >= 3.4
- Windows 11 x64

### Commandes

```powershell
# Depuis le dossier wsl_manager/

# Installer les dépendances
flutter pub get

# Lancer en développement
flutter run -d windows

# Générer le code Riverpod (après modification des providers)
dart run build_runner build --delete-conflicting-outputs

# Analyser
flutter analyze

# Formater
dart format lib/

# Build release
flutter build windows --release

# Créer le ZIP portable
.\scripts\build_portable.ps1
```

### Architecture

```
lib/
├── main.dart          # Initialisation window_manager, Mica, systray
├── app.dart           # MaterialApp.router, thème, go_router
├── models/            # Classes de données (WslInstance, WslTemplate, WslSnapshot, AppConfig)
├── services/          # Logique métier (WslService, StorageService, UacService…)
├── providers/         # Providers Riverpod (instances, monitoring, config)
├── screens/           # Écrans de l'application
│   ├── dashboard/     # Tableau de bord principal
│   ├── instance_detail/ # Détail / monitoring d'une instance
│   ├── wizard/        # Assistant de création
│   ├── snapshots/     # Gestion des snapshots
│   ├── templates/     # Gestion des templates
│   └── settings/      # Paramètres
└── widgets/           # Widgets réutilisables
```

---

## Licence

© Jordane Reynet — [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/)

Usage personnel et non commercial uniquement. Redistribution sans modification autorisée avec attribution.
