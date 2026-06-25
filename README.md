# WSL Manager

> Application Windows portable pour gérer visuellement vos instances WSL2.

![Version](https://img.shields.io/badge/version-2.0-blue)
![Platform](https://img.shields.io/badge/platform-Windows%2011%20x64-lightgrey)

---

## Présentation

WSL Manager est une application de bureau Windows (portable, sans installation) qui offre une interface graphique complète pour administrer vos distributions WSL2. Fini les commandes `wsl` en ligne de commande : toutes les opérations courantes sont accessibles en quelques clics.

L'application s'intègre dans la barre système et reste disponible en arrière-plan pour surveiller vos instances.

---

## Captures d'écran

### Tableau de bord

![Tableau de bord](screencapture/dashboard.png)

### Détail d'une instance

![Informations instance](screencapture/wsl_informations.png)

![Actions disponibles](screencapture/actions.png)

### Monitoring

![Monitoring CPU/RAM](screencapture/monitoring.png)

### Configuration WSL

![Éditeur .wslconfig](screencapture/wsl_conf.png)

### Assistant de création

![Nouvelle instance](screencapture/nouvell_instance.png)

### Gestion des templates

![Templates](screencapture/templates.png)

### Journal des commandes

![Journal des commandes](screencapture/logs.png)

### Paramètres

![Paramètres 1](screencapture/parametres_1.png)

![Paramètres 2](screencapture/parametres_2.png)

![Paramètres 3](screencapture/parametres_3.png)

---

## Fonctionnalités

### Gestion des instances
- **Démarrer / Arrêter** une instance en un clic
- **Créer** une nouvelle instance via un assistant pas-à-pas (source, nom, utilisateur, mot de passe, emplacement, outils)
- **Supprimer** une instance avec confirmation
- **Dupliquer** une instance existante (avec choix du dossier d'installation)
- **Renommer** une instance (avec choix du dossier d'installation)
- **Convertir** WSL1 ↔ WSL2 (avec élévation UAC à la demande)
- **Ouvrir un terminal** directement depuis l'interface (Windows Terminal ou CMD en fallback)
- **Description** personnalisée par instance

### Création d'instances
- **Téléchargement web direct** (`--web-download`) : installation sans pré-téléchargement du `.tar`
- **Import depuis un fichier `.tar`** local ou une URL personnalisée
- **Création depuis un template** existant
- **Emplacement personnalisable** : dossier d'installation par défaut configurable dans les paramètres, modifiable à la création
- **Installation automatique de Docker ou Podman** en option lors de la création

### Docker & Podman
- **Détection automatique** de Docker et Podman au démarrage des instances
- **Badges visuels** sur les cartes (Docker bleu · Podman violet)
- **Filtre** par Docker / Podman dans le tableau de bord
- Informations affichées dans la page de détail de l'instance

### Maintenance des instances
- **Nettoyage** : estimation de l'espace récupérable (cache apt, `/tmp`, logs) et nettoyage en un clic
- **Vérification de l'espace disque** automatique avant chaque export / import / snapshot / duplication / renommage
- **Accès au fichier VHDX** de l'instance

### Configuration WSL
- **Éditer le fichier `.wslconfig`** global directement depuis l'interface (limites CPU, RAM, swap, etc.)
- **Éditer la configuration** par instance
- **Dossier de démarrage** personnalisable par instance

### Ports forwarding
- Visualiser les **ports redirigés** pour chaque instance
- Gérer les règles de forwarding depuis l'écran de détail

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
- Graphiques de charge avec historique et axe X adaptatif
- **Seuils d'alerte** configurables pour CPU et RAM

### Journal des commandes
- Historique de toutes les commandes `wsl` exécutées par l'application
- Affichage du statut (succès / erreur), de la durée et de la sortie de chaque commande
- Accessible via l'onglet **Logs** dans la barre de navigation

### Serveur MCP (`wsl-manager`)
- Serveur MCP **Node.js/TypeScript** exposant les opérations WSL2 à des clients IA (Claude, Cursor…)
- Outils disponibles : `wsl_list_instances`, `wsl_start_instance`, `wsl_stop_instance`, `wsl_create_instance`, `wsl_delete_instance`, `wsl_exec`, `wsl_read_file`, `wsl_write_file`, `wsl_write_files_batch`, `wsl_list_ports`

### Intégration système
- **Icône dans la barre système** (systray) avec menu contextuel
- Option de **minimisation vers le systray** à la fermeture de la fenêtre
- Effet visuel **Mica** (Windows 11)
- Interface **responsive** : s'adapte aux fenêtres de petite taille

---

## Prérequis

| Composant | Version minimale |
|---|---|
| Windows | 11 x64 |
| WSL2 | activé et configuré |
| Aucun runtime .NET / VC++ requis | — |

---

## Installation

1. Télécharger `WSLManager_portable.zip` depuis la [page des releases](https://github.com/jordane45/wslManagerV2/releases)
2. Extraire le contenu dans le dossier de votre choix
3. Lancer `WSLManager.exe`

Aucune installation requise. Les données de l'application (templates, snapshots, configuration, journal) sont stockées dans `%LOCALAPPDATA%\WSLManager\`.

---

## Changelog

### V2.0
- Serveur MCP `wsl-manager` (Node.js/TypeScript)
- Téléchargement web direct (`--web-download`) avec barre de progression
- Détection et installation de Docker / Podman
- Badges Docker / Podman + filtre dans le tableau de bord
- Nettoyage des instances (cache apt, /tmp, logs)
- Vérification automatique de l'espace disque
- Emplacement d'installation personnalisable (paramètres + dialog natif)
- Graphique CPU/RAM : axe X adaptatif
- Encodage UTF-8 forcé sur les sorties WSL
- Description par instance, accès VHDX, dossier de démarrage
- Filtre par état (Running / Stopped)

### V1.5.1
- Corrections de bugs et améliorations de stabilité

### V1.5.0
- Ajout du journal des commandes
- Éditeur `.wslconfig` global
- Filtrage par groupe

---

## Licence

© Jordane Reynet — [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/)

Usage personnel et non commercial uniquement. Redistribution sans modification autorisée avec attribution.