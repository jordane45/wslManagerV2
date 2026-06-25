    Dans le programme wslManager, plusieurs points à corriger/modifier.

- [x] Souci d'encodage utf8 des caractères accentués
- [x] Ajouter un champ "description" lors de la création / édition des instances afin de pouvoir y décrire le contenu
- [x] Lors des opérations : création d'une instance, renommage ..  il faudrait afficher dans la modale les commandes exécutées et les réponses de celles-ci, un peu comme un terminal en lecture seule. Ça permettrait de mieux comprendre ce qui se passe en cas d'erreur.
- [x] Toujours dans cette modale, si une opération échoue, arrêter le traitement au lieu de laisser tourner les étapes suivantes qui vont forcément échouer aussi. Afficher clairement le message d'erreur et proposer un bouton pour fermer la modale.
- [x] Sur le dashboard et dans le détail des instances, afficher : L'emplacement du fichier de l'image et la taille qu'il occupe sur le disque dur
    - Prévoir un bouton "parcourir" qui permet d'atteindre l'emplacement du fichier sur le disque dur dans l'explorateur de fichiers windows.
- [x] Ajouter une fonction de filtrage sur les instances démarrées / arrêtées pour faciliter la navigation quand on a beaucoup d'instances
- [x] Pouvoir paramétrer le dossier de démarrage par défaut d'une instance lorsqu'on l'ouvre dans vscode ou le terminal
- [x] Lors du renommage ou la sauvegarde ou la duplication d'une instance, vérifie avant de lancer le traitement si l'espace disque est suffisant.
- [x] Lors de la création d'une instance, prévoir une option permettant d'indiquer si l'on souhaite que soit installé automatiquement docker ou podman, avec la possibilité de choisir la version spécifique à installer. Prévoir un script d'installation qui configure correctement les permissions et ajoute l'utilisateur au groupe approprié pour éviter d'avoir à utiliser sudo pour les commandes docker/podman.
- [x] Si docker ou Podman installé sur une instance, ajouter un Tag/label dans le détail de l'instance (et visible sur le dashboard)
- [x] Pouvoir filtrer sur ce Tag dans le dashboard.
- [x] Ajouter une fonction d'optimisation/nettoyage des instances pour libérer de l'espace disque : suppression des fichiers temporaires, vidage des caches apt/yum, nettoyage des logs anciens. Afficher l'espace potentiellement récupérable avant d'exécuter le nettoyage.
  