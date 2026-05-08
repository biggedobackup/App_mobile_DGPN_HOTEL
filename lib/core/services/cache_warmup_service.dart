import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sejour_service.dart';
import 'utilisateur_service.dart';

/// Service de préchauffage du cache hors-ligne.
///
/// Objectif : pré-charger PROACTIVEMENT toutes les données critiques de l'application
/// dès que l'utilisateur est connecté (démarrage, reconnexion réseau).
/// Ainsi, même si l'utilisateur n'a pas visité certaines pages, elles seront
/// disponibles en mode hors-ligne.
///
/// Données pré-chargées :
///   ✅ Tableau de bord (statistiques)
///   ✅ Séjours actifs (pages 1 à 3)
///   ✅ Séjours terminés (pages 1 à 3)
///   ✅ Historique des séjours (pages 1 à 2)
///   ✅ Nationalités (formulaire d'enregistrement)
///   ✅ Profil utilisateur connecté
///   ✅ Liste des utilisateurs
class CacheWarmupService {
  static final CacheWarmupService _instance = CacheWarmupService._internal();
  factory CacheWarmupService() => _instance;
  CacheWarmupService._internal();

  final _sejourService = SejourService();
  final _utilisateurService = UtilisateurService();

  bool _isWarming = false;

  /// Lance le préchauffage en arrière-plan.
  /// N'est exécuté que si l'utilisateur est connecté (token valide).
  /// Silencieux — ne bloque pas l'interface utilisateur.
  Future<void> warmUp() async {
    if (_isWarming) return;

    // Vérifier que l'utilisateur est authentifié (token présent)
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      // ignore: avoid_print
      print('[CacheWarmup] Pas de token — préchauffage ignoré.');
      return;
    }

    _isWarming = true;
    // ignore: avoid_print
    print('[CacheWarmup] 🔥 Démarrage du préchauffage du cache...');

    // Lancement en parallèle des appels indépendants
    await Future.wait([
      _warmStats(),
      _warmNationalites(),
      _warmProfil(),
      _warmUtilisateurs(),
      _warmSejoursActifs(),
      _warmSejoursTermines(),
      _warmHistoriqueSejours(),
    ], eagerError: false);


    // Préchauffage des détails (historique client) pour les séjours déjà en cache
    await _warmClientDetails();
    
    _isWarming = false;

    // Sauvegarder la timestamp du dernier préchauffage complet
    await prefs.setString(
        'last_cache_warmup', DateTime.now().toIso8601String());

    // ignore: avoid_print
    print('[CacheWarmup] ✅ Préchauffage terminé. Données disponibles hors-ligne.');
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Statistiques du tableau de bord
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> _warmStats() async {
    try {
      await _sejourService.getStats();
      // ignore: avoid_print
      print('[CacheWarmup] ✅ Stats pré-chargées');
    } catch (_) {
      // ignore: avoid_print
      print('[CacheWarmup] ⚠️ Stats échouées');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Nationalités (formulaire d'enregistrement)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> _warmNationalites() async {
    try {
      await _sejourService.getNationalites();
      // ignore: avoid_print
      print('[CacheWarmup] ✅ Nationalités pré-chargées');
    } catch (_) {
      // ignore: avoid_print
      print('[CacheWarmup] ⚠️ Nationalités échouées');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Profil de l'utilisateur connecté
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> _warmProfil() async {
    try {
      await _utilisateurService.getProfil();
      // ignore: avoid_print
      print('[CacheWarmup] ✅ Profil pré-chargé');
    } catch (_) {
      // ignore: avoid_print
      print('[CacheWarmup] ⚠️ Profil échoué');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Liste des utilisateurs (gestion des accès)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> _warmUtilisateurs() async {
    try {
      await _utilisateurService.getUtilisateurs();
      // ignore: avoid_print
      print('[CacheWarmup] ✅ Utilisateurs pré-chargés');
    } catch (_) {
      // ignore: avoid_print
      print('[CacheWarmup] ⚠️ Utilisateurs échoués');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Séjours actifs (3 premières pages)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> _warmSejoursActifs() async {
    try {
      // Page 1 en priorité, puis 2 et 3 si des données existent
      final p1 = await _sejourService.getSejoursActifs(page: 1);
      final count = (p1['count'] as int?) ?? 0;
      
      if (count > 20) {
        await _sejourService.getSejoursActifs(page: 2);
      }
      if (count > 40) {
        await _sejourService.getSejoursActifs(page: 3);
      }
      // ignore: avoid_print
      print('[CacheWarmup] ✅ Séjours actifs pré-chargés ($count total)');
    } catch (_) {
      // ignore: avoid_print
      print('[CacheWarmup] ⚠️ Séjours actifs échoués');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Séjours terminés (3 premières pages)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> _warmSejoursTermines() async {
    try {
      final p1 = await _sejourService.getSejoursTermines(page: 1);
      final count = (p1['count'] as int?) ?? 0;

      if (count > 20) {
        await _sejourService.getSejoursTermines(page: 2);
      }
      if (count > 40) {
        await _sejourService.getSejoursTermines(page: 3);
      }
      // ignore: avoid_print
      print('[CacheWarmup] ✅ Séjours terminés pré-chargés ($count total)');
    } catch (_) {
      // ignore: avoid_print
      print('[CacheWarmup] ⚠️ Séjours terminés échoués');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Historique des séjours (2 premières pages)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> _warmHistoriqueSejours() async {
    try {
      final p1 = await _sejourService.getHistoriqueSejours(page: 1);
      final count = (p1['count'] as int?) ?? 0;

      if (count > 20) {
        await _sejourService.getHistoriqueSejours(page: 2);
      }
      // ignore: avoid_print
      print('[CacheWarmup] ✅ Historique séjours pré-chargé ($count total)');
    } catch (_) {
      // ignore: avoid_print
      print('[CacheWarmup] ⚠️ Historique séjours échoué');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Préchauffage approfondi des fiches clients (Historique)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> _warmClientDetails() async {
    try {
      final cacheBox = Hive.box('cache');
      final Set<String> processedKeys = {};
      
      // On récupère les séjours des 3 boîtes principales pour extraire les clients
      final keys = ['sejours_actifs_p1', 'sejours_termines_p1', 'historique_sejours_p1'];
      
      for (var key in keys) {
        final data = cacheBox.get(key);
        if (data == null) continue;
        
        final results = data['results'] as List? ?? [];
        // On limite à 10 clients par catégorie pour ne pas surcharger
        for (var i = 0; i < results.length && i < 10; i++) {
          final s = results[i];
          final nom = s['nom_client'];
          final prenom = s['prenom_client'];
          final doc = s['numero_document'];
          
          if (nom == null || prenom == null || doc == null) continue;
          
          final uniqueKey = '${nom}_${prenom}_$doc';
          if (processedKeys.contains(uniqueKey)) continue;
          
          await _sejourService.getClientHistorique(nom, prenom, doc);
          processedKeys.add(uniqueKey);
        }
      }
      // ignore: avoid_print
      print('[CacheWarmup] ✅ ${processedKeys.length} fiches historiques clients pré-chargées.');
    } catch (e) {
       // ignore: avoid_print
      print('[CacheWarmup] ⚠️ Échec warmClientDetails: $e');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Utilitaires
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Efface tout le cache (utile lors de la déconnexion ou changement d'hôtel).
  Future<void> clearAllCache() async {
    final cacheBox = Hive.box('cache');
    await cacheBox.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_cache_warmup');
    // ignore: avoid_print
    print('[CacheWarmup] 🗑️ Cache entièrement effacé.');
  }

  /// Retourne la date du dernier préchauffage complet, ou null.
  Future<DateTime?> lastWarmupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('last_cache_warmup');
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  /// Indique si le cache est considéré comme périmé (> [maxAgeMinutes] minutes).
  Future<bool> isCacheStale({int maxAgeMinutes = 30}) async {
    final last = await lastWarmupTime();
    if (last == null) return true;
    return DateTime.now().difference(last).inMinutes > maxAgeMinutes;
  }
}
