# 🚀 Architecture Propre & Résilience Hors-ligne (Clean Flutter)

Ce document définit un standard d'architecture pour les applications Flutter nécessitant une gestion performante des données locales, du cache et de la synchronisation bidirectionnelle.

---

## 📂 Structure du Répertoire `lib/`

Une organisation granulaire permet une scalabilité et une maintenance aisées.

```text
lib/
├── core/                  # Cœur de l'application (Indépendant des fonctionnalités)
│   ├── constants/         # API Config, Thème, Palettes de couleurs (AppColors)
│   ├── models/            # Modèles de données + Mixins hors-ligne (UUID mapping)
│   ├── services/          # Services métier (NetworkService, SyncService, CacheManager)
│   ├── utils/             # Helpers (UI Utils, Debouncers, Formatage de dates/nombres)
│   └── widgets/           # Composants atomiques réutilisables (Boutons, TextFields)
├── routes/                # Configuration de la navigation (GoRouter, Guarding)
├── screens/               # Modules fonctionnels (Listes, Formulaires, Détails)
├── widgets/               # Layouts globaux et scaffolds de haut niveau
└── main.dart              # Initialisation (Hive, Firebase, System config)
```

---

## 💎 Moteur de Persistance & Local DB

### 1. Stockage NoSQL (Hive)
Le choix de **Hive** est privilégié pour sa rapidité d'accès aux données (mémoire-disque hybride).
- **Global Cache** : Stocke les réponses JSON brutes des requêtes API pour une consultation instantanée.
- **Sync Queue** : File d'attente sécurisée pour les créations/mises à jour en attente de connexion.
- **Media Index** : Mapping entre les identifiants uniques et les chemins de fichiers locaux.

### 2. Gestion Globale des Médias
Une approche résiliente consiste à ne jamais dépendre uniquement de l'URL distante :
- **Pré-chargement (Warmup)** : Téléchargement anticipé des images critiques en arrière-plan.
- **Fallback Local** : Utilisation d'un widget image personnalisé qui bascule automatiquement vers le stockage interne (`path_provider`) si le réseau échoue.
- **Non-suppression** : Conservation des fichiers synchronisés pour une consultation ultérieure hors-ligne (économie de bande passante).

---

## 🌩️ Stratégie de Résilience Hors-ligne

### Synchronisation en deux temps
1. **Batch Upload** : Envoi groupé des données textuelles pour optimiser les appels API (Format JSON).
2. **Parallel Media Sync** : Upload autonome des images volumineuses après confirmation de l'enregistrement texte, permettant à l'utilisateur de continuer à utiliser l'application sans blocage.

### Audit de Connectivité
L'utilisation de **`connectivity_plus`** permet d'adapter l'UI dynamiquement (bannières, blocage d'actions d'édition lourdes, passage en mode lecture seule).

---

## 🚀 Optimisations de Performance

- **Skeleton Loading** : Utilisation de masques de chargement (`shimmer`) pour une sensation de rapidité.
- **Debouncing** : Limitation des appels réseau lors de la recherche en temps réel.
- **Lazy Loading** : Pagination systématique sur les listes massives pour préserver la RAM.
- **Image Compression** : Réduction de la taille des fichiers capturés via l'appareil avant envoi.

---

## 📦 Dépendances Indispensables (Stack Technique)

| Catégorie | Package | Rôle |
|---|---|---|
| **Base de données** | `hive_flutter` | Stockage JSON & Sync Queue rapide |
| **Fichiers** | `path_provider` / `path` | Gestion des répertoires systèmes & chemins |
| **Réseau** | `http` | Communication REST standard |
| **Connectivité** | `connectivity_plus` | Écoute en temps réel de l'état réseau |
| **Cache Image** | `cached_network_image` | Cache intelligent disque/mémoire |
| **Gestion Cache** | `flutter_cache_manager` | Téléchargement proactif des médias |
| **Navigation** | `go_router` | Routage déclaratif & Navigation avancée |
| **Formatage** | `intl` | Internationalisation & Formatage local (Dates/Devises) |
| **Sécurité** | `flutter_secure_storage` | Chiffrement des clés & secrets locaux |
| **Auth** | `jwt_decoder` | Analyse des jetons pour la session |
| **Fonts & Icons** | `google_fonts` / `flutter_svg` | Typographie moderne & Icônes vectorielles |
| **Multimédia** | `image_picker` / `photo_view` | Capture & Visualisation avancée d'images |
| **UI** | `shimmer` | Effets de chargement (Skeletons) |
| **Tâches** | `workmanager` | Synchronisation silencieuse en tâche de fond |
