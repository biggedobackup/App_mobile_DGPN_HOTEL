# 📱 Architecture & Mode Hors-ligne - DGPN MOBILE

Ce document détaille la structure technique de l'application mobile, les dépendances utilisées et la stratégie mise en œuvre pour assurer un fonctionnement fluide sans connexion internet.

---

## 🛠️ Structure du Projet (`lib/`)

```text
lib/
├── core/
│   ├── constants/    # Configuration API, Couleurs, Thèmes
│   ├── models/       # Modèles de données (SejourModel, ClientHistoriqueModel...)
│   ├── services/     # Logique métier (SejourService, SyncService, CacheWarmupService)
│   ├── utils/        # Helpers UI, Debouncers, Formatage de dates
│   └── widgets/      # Composants partagés (DgpnImage, CustomButton, Skeletons)
├── screens/
│   ├── auth/         # Connexion & Authentification
│   ├── sejours/      # Formulaires, Détails, Listes actives/terminées/historique
│   └── tableau.dart  # Tableau de bord principal (Dashboard)
└── main.dart         # Point d'entrée & Configuration Hive
```

---

## 📦 Inventaire des Dépendances

### Persistance & Robustesse
- **`hive` / `hive_flutter`** : Base de données NoSQL locale (ultra-rapide) pour le cache et la file d'attente de synchronisation.
- **`shared_preferences`** : Stockage des préférences utilisateur simples (token, ID hôtel).
- **`flutter_secure_storage`** : Stockage sécurisé des données sensibles.
- **`path_provider`** : Accès au système de fichiers pour le stockage permanent des images.

### Réseau & Images
- **`http`** : Communication avec l'API Django.
- **`connectivity_plus`** : Détection en temps réel de l'état de la connexion.
- **`cached_network_image`** : Cache mémoire et disque pour les images distantes.
- **`flutter_cache_manager`** : Gestion manuelle et prédictive du téléchargement des médias.
- **`image_picker`** : Capture de photos via l'appareil.

### Tâches de Fond & Optimisation
- **`workmanager` (En attente/Prêt)** : Exécution de tâches de synchronisation en arrière-plan.
- **`shimmer`** : Effets de chargement (Skeletons) pour une UI fluide.

---

## 🌩️ Stratégie Hors-Ligne (Offline-First)

### 1. File d'attente de Synchronisation (`SyncService`)
Lorsqu'un séjour est enregistré sans connexion :
- Les données textuelles sont stockées dans la box Hive `sejours_offline`.
- Les fichiers images sont copiés dans un dossier local sécurisé.
- La synchronisation se fait en deux étapes : 
  1. Envoi du texte en lot (Batch).
  2. Envoi des images associées une par une via UUID local.

### 2. Cache Intelligent des Données
- **Données API** : Chaque réponse réseau (`getSejoursActifs`, `getClientHistorique`) est immédiatement mise en cache dans la box `cache`.
- **Fusion Locale** : Les listes affichées à l'écran fusionnent les données distantes (cache) et les données locales en attente d'envoi pour que l'utilisateur voie instantanément ses actions.

### 3. Gestion Résiliente des Images (`DgpnImage`)
Contrairement à une application classique qui échoue si le serveur est inaccessible, notre système :
1. Tente de charger via l'URL (Réseau).
2. Si échec ou mode hors-ligne, cherche dans le stockage local permanent via l'identifiant unique du séjour.
3. Les images ne sont **jamais supprimées** après synchronisation pour éviter de recharger sur le forfait mobile (Consultation économe).

---

## ⚡ Optimisations UI/UX

- **Warmup Service** : Au démarrage, l'application pré-charge (prefetch) les 20 derniers séjours et leurs images complexes pour qu'ils soient instantanément disponibles.
- **Debouncing** : Les recherches dans les listes attendent 500ms d'inactivité pour éviter de saturer le processeur/réseau.
- **Skeletons** : Aucun écran n'affiche de spinner bloquant ; des structures "Squelettes" occupent l'espace pour une sensation de rapidité.
- **Persistent Bottom Sheets** : Les menus de sortie et formulaires rapides pour une interaction directe.

---

## 💾 Schémas de données Locales (Hive)

| Nom de la Box | Usage | Durée de vie |
|---|---|---|
| `cache` | Réponses API (JSON) | Temporaire (Overwrite) |
| `sejours_offline` | Nouveaux séjours à envoyer | Supprimé après synchro |
| `sorties_offline` | Sorties clients à valider | Supprimé après synchro |
| `sync_images` | Index des chemins d'images locales | Permanent |
| `user` | Profil et droits | Durée de session |
