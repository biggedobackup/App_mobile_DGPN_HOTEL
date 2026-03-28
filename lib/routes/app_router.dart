import 'package:go_router/go_router.dart';
import '../screens/sejours/splash_screen.dart';
import '../screens/connexion.dart';
import '../screens/tableau.dart';
import '../screens/sejours/enregistrement.dart';
import '../screens/sejours/sejours_actifs.dart';
import '../screens/sejours/sejour_terminer.dart';
import '../screens/sejours/historique_sejours.dart';
import '../screens/profil.dart';
// Utilisateurs
import '../screens/utilisateurs/liste.dart';
import '../screens/utilisateurs/detail.dart';
import '../screens/utilisateurs/ajouter.dart';
import '../screens/utilisateurs/modifier.dart';
import '../screens/sejours/sejour_detail_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/connexion',
      builder: (context, state) => const ConnexionScreen(),
    ),
    GoRoute(
      path: '/tableau',
      builder: (context, state) => const TableauScreen(),
    ),
    GoRoute(
      path: '/enregistrement',
      builder: (context, state) => const EnregistrementScreen(),
    ),
    GoRoute(
      path: '/enregistrement/:id/detail',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return SejourDetailScreen(sejourId: id);
      },
    ),
    GoRoute(
      path: '/sejours-actifs',
      builder: (context, state) => const SejoursActifsScreen(),
    ),
    GoRoute(
      path: '/sejour-terminer',
      builder: (context, state) => const SejourTerminerScreen(),
    ),
    GoRoute(
      path: '/historique-sejours',
      builder: (context, state) => const HistoriqueSejoursScreen(),
    ),
    // ── Utilisateurs ──────────────────────────────────────────────
    GoRoute(
      path: '/utilisateurs',
      builder: (context, state) => const UtilisateursListeScreen(),
    ),
    GoRoute(
      path: '/utilisateurs/ajouter',
      builder: (context, state) => const UtilisateurAjouterScreen(),
    ),
    GoRoute(
      path: '/utilisateurs/:id/detail',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return UtilisateurDetailScreen(userId: id);
      },
    ),
    GoRoute(
      path: '/utilisateurs/:id/modifier',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return UtilisateurModifierScreen(userId: id);
      },
    ),
    // ──────────────────────────────────────────────────────────────
    GoRoute(path: '/profil', builder: (context, state) => const ProfilScreen()),
  ],
);
