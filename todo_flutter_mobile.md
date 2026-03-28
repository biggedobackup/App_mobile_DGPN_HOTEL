# 📱 TODO — Application Mobile Flutter — HOTEL DGPN
> App pour : **Agent d'accueil** & **Gérant d'hôtel** uniquement  
> Design : Inspiré du frontend React JS — Palette Emerald / Blanc / Slate  
> Cible : Android (+ iOS optionnel)

---

## ARCHITECTURE DU PROJET

```
APP_MOBILE/lib/
├── main.dart                         ← 🔧 À réécrire (splash → connexion)
├── core/
│   ├── constants/
│   │   ├── app_colors.dart           ← Palette emerald/slate
│   │   ├── app_fonts.dart            ← Inter / textes
│   │   └── api_config.dart           ← BASE_URL + endpoints
│   ├── services/
│   │   ├── auth_service.dart         ← Login/logout/JWT
│   │   ├── sejour_service.dart       ← CRUD séjours
│   │   └── utilisateur_service.dart  ← CRUD utilisateurs
│   ├── models/
│   │   ├── user_model.dart
│   │   └── sejour_model.dart
│   └── widgets/
│       ├── custom_button.dart
│       ├── custom_text_field.dart
│       ├── stat_card.dart
│       └── loading_overlay.dart
├── screens/
│   ├── splash_screen.dart            ← Page actuelle → redirige vers connexion
│   ├── connexion.dart
│   ├── tableau.dart
│   ├── enregistrement.dart
│   ├── sejours_actifs.dart
│   ├── sejour_terminer.dart
│   ├── historique_sejours.dart
│   ├── utilisateurs.dart
│   └── profil.dart
└── routes/
    └── app_router.dart               ← GoRouter config
```

---

## ÉTAPE 0 — CONFIGURATION PROJET

### [ ] 0.1 — `pubspec.yaml` : Ajouter les dépendances

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Navigation
  go_router: ^13.0.0
  # HTTP & Stockage
  http: ^1.2.0
  shared_preferences: ^2.2.0
  flutter_secure_storage: ^9.0.0
  # JWT
  jwt_decoder: ^2.0.1
  # Images
  image_picker: ^1.0.7
  cached_network_image: ^3.3.0
  # UI
  google_fonts: ^6.1.0
  shimmer: ^3.0.0
  intl: ^0.19.0
  # Icons
  flutter_svg: ^2.0.9
```

### [ ] 0.2 — `core/constants/api_config.dart`
```
const String BASE_URL = 'http://your-server/api';
// Endpoints
const String LOGIN_URL = '$BASE_URL/connexion/';
const String SEJOURS_URL = '$BASE_URL/sejours/';
const String UTILISATEURS_URL = '$BASE_URL/utilisateurs/';
const String STATS_URL = '$BASE_URL/stats/dashboard/';
```

### [ ] 0.3 — `core/constants/app_colors.dart`
```
Emerald 600   → Color(0xFF059669)   ← Couleur principale
Emerald 50    → Color(0xFFECFDF5)   ← Arrière-plans
Slate 800     → Color(0xFF1E293B)   ← Titres
Slate 500     → Color(0xFF64748B)   ← Textes secondaires
Slate 100     → Color(0xFFF1F5F9)   ← Bordures
White         → Colors.white
```

---

## ÉTAPE 1 — SPLASH SCREEN (main.dart)

**Fichier :** `screens/splash_screen.dart`

### [ ] 1.1 — Design splash
- Fond dégradé `emerald-900` → `emerald-700` (vertical du haut en bas)
- Logo centré : `Image.asset('assets/images/logo.png')` — taille 120px
- Nom app : **« PORTAIL HOTEL »** — texte blanc, fontSize 22, fontWeight 900, letterspacing
- Sous-titre : **« DGPN »** — texte blanc opacity 70%, fontSize 12
- Indicateur circulaire `CircularProgressIndicator` couleur blanc en bas

### [ ] 1.2 — Navigation automatique
```dart
// Logique dans initState :
// 1. Attendre 2 secondes
// 2. Vérifier si token JWT valide dans SharedPreferences
// 3. Si valide → aller à /tableau
// 4. Si invalide/absent → aller à /connexion
```

### [ ] 1.3 — Modifier [main.dart](file:///c:/Users/BigGedo/Desktop/DEV/IKASOLUTION/DGPN/HOTEL/APP_MOBILE/lib/main.dart)
```dart
// Route initiale vers SplashScreen
// Thème global : primaryColor = emerald 600
// fontFamily = 'Inter' (Google Fonts)
// Routes à déclarer :
// /splash → SplashScreen
// /connexion → ConnexionScreen
// /tableau → TableauScreen
// /enregistrement → EnregistrementScreen
// /sejours-actifs → SejoursActifsScreen
// /sejour-terminer → SejourTerminerScreen
// /historique-sejours → HistoriqueSejoursScreen
// /utilisateurs → UtilisateursScreen
// /profil → ProfilScreen
```

---

## ÉTAPE 2 — CONNEXION (connexion.dart)

**Design référence :** [Connexion.tsx](file:///c:/Users/BigGedo/Desktop/DEV/IKASOLUTION/DGPN/HOTEL/FRONTEND_HOTEL/src/pages/Authentification/Connexion.tsx) — fond emerald-900 + card blanche arrondie

### [ ] 2.1 — Layout principal
- `Scaffold` → `body` avec fond `emerald-900` (container plein écran)
- 2 cercles flous en arrière-plan (comme le React) via `Container` + `BoxDecoration` + `borderRadius`
- Carte centrale blanche : `borderRadius 40px`, `elevation` forte, padding 24px, `maxWidth 420`

### [ ] 2.2 — Header card
- Logo : `Image.asset('assets/images/logo.png')`, h=80px, dans `Container` `emerald-50`, borderRadius 24
- Titre : **« ACCÈS PORTAIL HOTEL »** — slate-800, fontSize 18, fontWeight 900, uppercase
- Sous-titre : **« Authentification sécurisée requise »** — slate-400, fontSize 12

### [ ] 2.3 — Formulaire (champs identiques au React)

| Champ | Type Flutter | Icône | Placeholder |
|-------|-------------|-------|-------------|
| `email` | `TextFormField` type email | `Icons.mail_outline` | `admin@hotel.com` |
| `password` | `TextFormField` type password | `Icons.lock_outline` | `••••••••` |
| Toggle visibilité mdp | `IconButton` suffix | `Icons.visibility_off` / `Icons.visibility` | — |
| Checkbox "Rester connecté" | `Checkbox` + `Row` | — | `Rester connecté` |
| Lien "Oublié ?" | `TextButton` | — | Couleur emerald-600, uppercase |

### [ ] 2.4 — Bouton connexion
- `ElevatedButton` pleine largeur, fond emerald-600, texte blanc, hauteur 48px
- Icône flèche droite `Icons.chevron_right` à droite
- État loading : `CircularProgressIndicator` blanc + texte `Connexion...`
- Désactivé et opaque 50% pendant le chargement

### [ ] 2.5 — Gestion erreur
- `Container` rouge/amber selon type d'erreur — identique au React
- Message session expirée vs erreur serveur (couleurs différentes)

### [ ] 2.6 — Modal "Mot de passe oublié"
- `showDialog()` avec `AlertDialog` arrondi (borderRadius 40px)
- Champ email `TextFormField`
- Bouton **« Envoyer le lien »** emerald-600
- Bouton fermer X en haut à droite
- Message de confirmation après envoi

### [ ] 2.7 — Logique API connexion
```dart
// POST /api/connexion/
// Body: { email, password }
// Réponse OK:
//   access_token → SecureStorage
//   refresh_token → SecureStorage
//   user.role → SharedPreferences (doit être AGENT_ACCUEIL ou GERANT_HOTEL)
//   user.hotel_id → SharedPreferences
//   user.nom, user.prenom → SharedPreferences
// Si rôle non autorisé → afficher erreur « Accès non autorisé »
// Navigation → /tableau
```

---

## ÉTAPE 3 — TABLEAU DE BORD (tableau.dart)

**Design référence :** [Tableau.tsx](file:///c:/Users/BigGedo/Desktop/DEV/IKASOLUTION/DGPN/HOTEL/FRONTEND_HOTEL/src/pages/TableauDeBord/Tableau.tsx)

### [ ] 3.1 — Structure Scaffold avec NavigationBar
- `BottomNavigationBar` ou `NavigationBar` avec 5 onglets :
  1. Tableau (home icon)
  2. Enregistrement (person_add icon)
  3. Séjours actifs (bed icon)
  4. Terminés (logout icon) — ou Historique selon rôle
  5. Profil (account_circle icon)

### [ ] 3.2 — Header tableau
- Texte de bienvenue : **"Bonjour, [Prenom] [Nom]"** — slate-800, gras
- Sous-titre dynamique selon rôle :
  - `AGENT_ACCUEIL` → **"Gestion de votre établissement"**
  - `GERANT_HOTEL` → **"Supervision de votre établissement"**
- Nom de l'hôtel en badge emerald sous le sous-titre

### [ ] 3.3 — Grille de statistiques (cartes)

**Pour Agent d'accueil** (3 cartes) :
| Carte | Icône | Couleur | Route |
|-------|-------|---------|-------|
| Enregistrement Clients | `Icons.person_add` | purple | /enregistrement |
| Sortie Clients | `Icons.logout` | orange | /sejour-terminer |
| Clients en Séjour | `Icons.bedroom_child` | pink | /sejours-actifs |

**Pour Gérant d'hôtel** (4 cartes — idem + Utilisateurs) :
| Carte | Icône | Couleur | Route |
|-------|-------|---------|-------|
| Enregistrement Clients | `Icons.person_add` | purple | /enregistrement |
| Sortie Clients | `Icons.logout` | orange | /sejour-terminer |
| Clients en Séjour | `Icons.bedroom_child` | pink | /sejours-actifs |
| Utilisateurs | `Icons.people` | blue | /utilisateurs |

**Design de chaque carte** :
- `InkWell` → `Card` blanche, borderRadius 16px, elevation légère
- Icône dans `Container` carré 40px, fond coloré pastel
- Petit label 10px uppercase slate-400
- Chiffre gras 28px slate-800
- Flèche `Icons.arrow_forward` grise à droite

### [ ] 3.4 — Chargement des stats
```dart
// GET /api/stats/dashboard/
// Headers: Authorization: Bearer {token}
// Remplir les cartes avec les valeurs numériques
// Skeleton loading (shimmer) pendant le chargement
```

### [ ] 3.5 — Activités récentes
- `ListView` des 5 dernières activités (nom client, hôtel, date, statut)
- Chaque item : avatar initiales + nom + statut coloré + date

---

## ÉTAPE 4 — ENREGISTREMENT (enregistrement.dart)

**Design référence :** [Enregistrement/Ajouter.tsx](file:///c:/Users/BigGedo/Desktop/DEV/IKASOLUTION/DGPN/HOTEL/FRONTEND_HOTEL/src/pages/Enregistrement/Ajouter.tsx) — 4 sections numérotées

### [ ] 4.1 — AppBar
- Fond emerald-600, titre **"NOUVEL ENREGISTREMENT"** blanc
- Bouton retour `IconButton` blanc gauche

### [ ] 4.2 — Section 01 — Photos & Identité

| Champ | Widget Flutter |
|-------|---------------|
| Document Recto | `ImagePicker` → CarrE dashed zone 16/9 avec preview |
| Document Verso | `ImagePicker` → Carré dashed zone 16/9 avec preview |
| Photo Profil | `ImagePicker` → Carré dashed zone 16/9 avec preview |
| Bouton Analyser | `ElevatedButton` indigo-600, icône `Icons.document_scanner` |

- Statut scan Regula : badge rouge `Équipement non connecté` identique au React

### [ ] 4.3 — Section 02 — Informations Personnelles

| Champ | Type | Obligatoire | Icône |
|-------|------|-------------|-------|
| `nom_client` | `TextFormField` | ✅ | `Icons.person` |
| `prenom_client` | `TextFormField` | ✅ | `Icons.person` |
| `date_naissance` | `DatePicker` → `TextFormField` | ✅ | `Icons.calendar_today` |
| `lieu_naissance` | `TextFormField` | ✅ | `Icons.location_on` |
| [nationalite](file:///c:/Users/BigGedo/Desktop/DEV/IKASOLUTION/DGPN/HOTEL/BACKEND_HOTEL/sejours/views.py#414-419) | `DropdownButtonFormField` | ✅ | `Icons.public` |
| `profession` | `TextFormField` | ✅ | `Icons.work` |
| `contact_telephone` | `TextFormField` type phone | ✅ | `Icons.phone` |
| `lieu_residence` | `TextFormField` | ✅ | `Icons.location_on` |

**Nationalités :** charger depuis `GET /api/sejours/nationalites/`

### [ ] 4.4 — Section 03 — Document d'identité

| Champ | Type | Options |
|-------|------|---------|
| `type_document` | `DropdownButtonFormField` | CNI, PASSEPORT, CARTE_CONSULAIRE, PERMIS_DE_SEJOUR, VISA, AUTRE |
| `numero_document` | `TextFormField` | Obligatoire |

### [ ] 4.5 — Section 04 — Détails du Séjour

| Champ | Type | Options/Valeur |
|-------|------|----------------|
| [hotel](file:///c:/Users/BigGedo/Desktop/DEV/IKASOLUTION/DGPN/HOTEL/BACKEND_HOTEL/stats/views.py#30-83) | Affichage lecture seule | Hôtel assigné à l'utilisateur (non modifiable) |
| `numero_chambre` | `TextFormField` | Obligatoire |
| `date_entree` | `DateTimePicker` → `TextFormField` | Défaut : maintenant |
| `motif_sejour` | `DropdownButtonFormField` | AFFAIRES, TOURISME, VISITE, SANTE, TRANSIT, AUTRE |

### [ ] 4.6 — Boutons action
- **Annuler** : `TextButton` slate-500 → retour
- **Enregistrer l'entrée** : `ElevatedButton` emerald-600, icône `Icons.save`, pleine largeur

### [ ] 4.7 — Logique API
```dart
// POST /api/sejours/ (multipart/form-data)
// Champs texte : formData (tous les champs ci-dessus)
// Fichiers : photo_client, document_recto, document_verso
// Succès → notification SnackBar verte → retour liste
// Erreur → SnackBar rouge avec message
```

---

## ÉTAPE 5 — SÉJOURS ACTIFS (sejours_actifs.dart)

**Design référence :** [SejoursActifs/Liste.tsx](file:///c:/Users/BigGedo/Desktop/DEV/IKASOLUTION/DGPN/HOTEL/FRONTEND_HOTEL/src/pages/SejoursActifs/Liste.tsx)

### [ ] 5.1 — Header + filtres

| Filtre | Widget | Source |
|--------|--------|--------|
| Recherche (nom/n° doc) | `TextField` avec `Icons.search` | — |
| Date début | `DatePicker` → `TextFormField` | — |
| Date fin | `DatePicker` → `TextFormField` | — |
| Bouton réinitialiser | `OutlinedButton` rouge | — |

### [ ] 5.2 — Liste des séjours
Chaque item `Card` affiche :
- Avatar initiales (2 lettres) dans cercle slate-100
- **Nom Prénom** — uppercase gras slate-700
- Nationalité + drapeau 🌍 — slate-400, petit
- Nom de l'hôtel + chambre — emerald-600
- Date d'entrée (format `DD/MM/YYYY HH:mm`)
- Durée actuelle (calculée en jours)
- Badge **"En séjour"** vert animé pulse

### [ ] 5.3 — Actions par item
- **Voir** : bouton → ouvrir modal détail ou nouvelle page
- **PDF** : bouton → `GET /api/sejours/{id}/fiche-pdf/?token={token}`
- **Départ** : bouton orange → ouvrir bottom sheet enregistrement sortie

### [ ] 5.4 — Bottom Sheet "Enregistrement sortie"
```
Titre : ENREGISTREMENT SORTIE
Nom client (lecture seule)
Date de sortie * → DateTimePicker (obligatoire)
Observations de sortie → TextArea (optionnel)
[Bouton] VALIDER LE DÉPART → POST /api/sejours/{id}/enregistrer_sortie/
```

### [ ] 5.5 — Pagination
- `ListView` avec `onScrollEnd` → charger page suivante
- Indicateur "page X / Y" en bas
- Total des résultats affiché

### [ ] 5.6 — Logique API
```dart
// GET /api/sejours/en-sejour/ ?search=&page=&date_creation__gte=&date_creation__lte=
// Headers: Authorization: Bearer {token}
// Pagination: response.count, response.results
```

---

## ÉTAPE 6 — SÉJOUR TERMINÉ (sejour_terminer.dart)

**Design référence :** [SejourTerminer/Liste.tsx](file:///c:/Users/BigGedo/Desktop/DEV/IKASOLUTION/DGPN/HOTEL/FRONTEND_HOTEL/src/pages/SejourTerminer/Liste.tsx)

### [ ] 6.1 — Identique à Sejours Actifs avec différences :
- Titre : **"SORTIES CLIENTS"**
- Badge statut → Orange **"Séjour Terminé"** (pas de pulse)
- Afficher en plus : **Date de sortie** et **durée totale du séjour**
- Pas de bouton "Départ" (déjà terminé)
- Bouton "PDF" toujours présent

### [ ] 6.2 — Logique API
```dart
// GET /api/sejours/termines/ ?search=&page=&...
```

---

## ÉTAPE 7 — HISTORIQUE SÉJOURS (historique_sejours.dart)

**Design référence :** [HistoriqueSejours/Liste.tsx](file:///c:/Users/BigGedo/Desktop/DEV/IKASOLUTION/DGPN/HOTEL/FRONTEND_HOTEL/src/pages/HistoriqueSejours/Liste.tsx)

### [ ] 7.1 — Vue groupée par client
- Afficher les clients avec plusieurs séjours groupés
- Chaque group : nom client + nombre de séjours + dernier hôtel + date dernier séjour
- Expandable pour voir les séjours individuels

### [ ] 7.2 — Filtres
- Recherche par nom/numéro document
- Filtre par date

### [ ] 7.3 — Logique API
```dart
// GET /api/sejours/historique/ ?search=&page=
```

---

## ÉTAPE 8 — UTILISATEURS (utilisateurs.dart)

**Design référence :** [Utilisateurs/Liste.tsx](file:///c:/Users/BigGedo/Desktop/DEV/IKASOLUTION/DGPN/HOTEL/FRONTEND_HOTEL/src/pages/Utilisateurs/Liste.tsx) + [Utilisateurs/Ajouter.tsx](file:///c:/Users/BigGedo/Desktop/DEV/IKASOLUTION/DGPN/HOTEL/FRONTEND_HOTEL/src/pages/Utilisateurs/Ajouter.tsx)  
**Accessible uniquement :** Gérant d'hôtel  
**Rôles créables :** AGENT_ACCUEIL uniquement

### [ ] 8.1 — Liste utilisateurs
Chaque item affiche :
- Avatar initiales dans cercle coloré selon rôle
- Nom Prénom — gras, uppercase
- Email — slate-400
- Rôle badge coloré (**AGENT_ACCUEIL** vert, **GÉRANT** bleu)
- Statut actif/inactif
- Boutons : Voir | Modifier | Désactiver

### [ ] 8.2 — Modal/Page "Ajouter utilisateur"

| Champ | Type | Options |
|-------|------|---------|
| `nom` | `TextFormField` | Obligatoire |
| `prenom` | `TextFormField` | Obligatoire |
| `email` | `TextFormField` type email | Obligatoire |
| `password` | `TextFormField` type password + toggle | Obligatoire |
| `role` | `DropdownButtonFormField` | AGENT_ACCUEIL uniquement (gérant ne peut créer que des agents) |
| `contact_telephone` | `TextFormField` type phone | Optionnel |
| Photo profil | `ImagePicker` | Optionnel |

### [ ] 8.3 — Modal/Page "Modifier utilisateur"
- Mêmes champs sauf `email` (lecture seule) et sans `password`
- Champ `password` optionnel séparé si changement souhaité

### [ ] 8.4 — Logique API
```dart
// GET /api/utilisateurs/ → liste
// POST /api/inscription/ → créer (IsGerantOrHigher)
// PATCH /api/utilisateurs/{id}/ → modifier
// POST /api/utilisateurs/{id}/desactiver/ → désactiver
```

---

## ÉTAPE 9 — PROFIL (profil.dart)

### [ ] 9.1 — Informations profil
- Photo de profil (avatar initiales ou image uploadée)
- Nom Prénom — grand, gras
- Rôle badge coloré
- Email — lecture seule
- Hôtel assigné — lecture seule
- Téléphone — éditable

### [ ] 9.2 — Section hôtel assigné
- Nom de l'hôtel, adresse/commune
- Non modifiable (assigné par l'admin)

### [ ] 9.3 — Actions
- **Modifier le profil** → formulaire inline
- **Changer le mot de passe** :
  - Ancien mot de passe
  - Nouveau mot de passe
  - Confirmer nouveau mot de passe
- **Se déconnecter** → effacer tokens → `/connexion`
  - Confirmation dialog avant déconnexion

### [ ] 9.4 — Logique API
```dart
// GET /api/profil/ → charger données
// PATCH /api/profil/ → modifier
// POST /api/changer-mot-de-passe/ → modifier mdp
// Déconnexion → effacer SecureStorage + SharedPreferences
```

---

## ÉTAPE 10 — COMPOSANTS COMMUNS

### [ ] 10.1 — `widgets/custom_button.dart`
- Bouton primaire emerald-600 + variante outline
- Props : label, onPressed, isLoading, icon, fullWidth

### [ ] 10.2 — `widgets/custom_text_field.dart`
- Input styled avec fond slate-50, border slate-300, focus emerald-500
- Props : label, hint, controller, type, prefixIcon, suffixIcon, validator

### [ ] 10.3 — `widgets/stat_card.dart`
- Carte de statistique avec icône, label, valeur, couleur, onTap

### [ ] 10.4 — `widgets/loading_overlay.dart`
- Overlay translucide avec `CircularProgressIndicator` émeraude

### [ ] 10.5 — `widgets/section_header.dart`
- En-tête numéroté pour formulaires (numéro + titre + bordure bas)
- Style identique aux `<h2>` du React (01 Photos & Identité, etc.)

### [ ] 10.6 — Navigation Bottom Bar
- 5 onglets persistent sur toutes les pages après connexion
- Rôle `AGENT_ACCUEIL` → 4 onglets (Tableau, Enregistrement, Séjours, Profil)
- Rôle `GERANT_HOTEL` → 5 onglets (+ Utilisateurs)
- Badge rouge sur Tableau si stat > 0

---

## ÉTAPE 11 — SERVICES / LOGIQUE MÉTIER

### [ ] 11.1 — `services/auth_service.dart`
```dart
// login(email, password) → Future<Map>
// logout() → vider storage
// getToken() → String?
// isTokenValid() → bool (jwt_decoder)
// refreshToken() → Future<bool>
```

### [ ] 11.2 — `services/sejour_service.dart`
```dart
// getSejoursActifs({filters}) → Future<PaginatedResponse>
// getSejoursTermines({filters}) → Future<PaginatedResponse>
// getHistorique({filters}) → Future<PaginatedResponse>
// createSejour(FormData) → Future<Sejour>
// enregistrerSortie(id, date, observations) → Future<void>
// getNationalites() → Future<List<String>>
// telechargerPDF(id) → Future<void>
```

### [ ] 11.3 — `services/utilisateur_service.dart`
```dart
// getUtilisateurs() → Future<List<User>>
// createUtilisateur(data) → Future<User>
// updateUtilisateur(id, data) → Future<User>
// getProfil() → Future<User>
```

### [ ] 11.4 — Intercepteur HTTP (token auto-renouvelé)
```dart
// Avant chaque requête : ajouter Bearer token
// Si 401 → essayer refresh token
// Si refresh échoué → rediriger vers /connexion?session=expired
```

---

## ORDRE D'IMPLÉMENTATION RECOMMANDÉ

```
Semaine 1 : Fondations
  ✅ main.dart + SplashScreen (→ connexion)
  ✅ connexion.dart (formulaire + API + stockage JWT)
  ✅ Composants communs (CustomButton, CustomTextField, StatCard)

Semaine 2 : Pages principales
  ✅ tableau.dart (grille stats + activités récentes + BottomNav)
  ✅ enregistrement.dart (formulaire complet 4 sections)

Semaine 3 : Listes
  ✅ sejours_actifs.dart (liste + filtres + bottom sheet sortie)
  ✅ sejour_terminer.dart (liste + filtres)
  ✅ historique_sejours.dart

Semaine 4 : Administration
  ✅ utilisateurs.dart (gérant uniquement)
  ✅ profil.dart (infos + changement mot de passe + déconnexion)
  ✅ Tests et corrections
```

---

## CHECKLIST DE CONFORMITÉ DESIGN

| Élément | Web React | Flutter | Statut |
|---------|-----------|---------|--------|
| Couleur principale | emerald-600 (#059669) | `Color(0xFF059669)` | ⬜ |
| Police | Inter (Google Fonts) | `google_fonts` Inter | ⬜ |
| Fond connexion | emerald-900 + blur circles | `BoxDecoration gradient` | ⬜ |
| Cards | borderRadius 16px, shadow-sm | `borderRadius: 16, elevation 2` | ⬜ |
| Inputs | slate-50 bg, emerald focus | Styled `InputDecoration` | ⬜ |
| Labels | 10px uppercase tracking | `fontSize 10, letterSpacing 2` | ⬜ |
| Boutons | py-3 px-8 font-black uppercase | hauteur 48px, fontWeight 900 | ⬜ |
| Titres | font-black uppercase tracking-tight | fontWeight 900 + letterSpacing | ⬜ |
| Badges statut | bg-emerald-50 text-emerald-600 | `Container` colored | ⬜ |

---

> **Note :** L'app mobile est strictement limitée aux rôles `AGENT_ACCUEIL` et `GERANT_HOTEL`. 
> Toute tentative de connexion avec un rôle différent doit être bloquée côté mobile avec le message :  
> **"Accès réservé au personnel hôtelier. Utilisez le portail web."**
