import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'sejour_service.dart';
import 'dart:io';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _sejourService = SejourService();
  bool _isSyncing = false;

  /// Démarre l'écoute des changements de connexion
  void init() {
    Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.wifi) || 
          results.contains(ConnectivityResult.mobile)) {
        processQueue();
      }
    });
  }

  /// Ajoute un séjour à la file d'attente locale
  Future<void> addToQueue({
    required Map<String, String> fields,
    File? photoClient,
    File? documentRecto,
    File? documentVerso,
  }) async {
    final box = Hive.box('sejours_offline');
    
    final data = {
      'fields': fields,
      'photoClient': photoClient?.path,
      'documentRecto': documentRecto?.path,
      'documentVerso': documentVerso?.path,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await box.add(jsonEncode(data));
    print('📥 Séjour sauvegardé localement (Hors-ligne)');
  }

  /// Tente d'envoyer tous les séjours en attente
  Future<void> processQueue() async {
    if (_isSyncing) return;
    
    final box = Hive.box('sejours_offline');
    if (box.isEmpty) return;

    _isSyncing = true;
    print('🔄 Début de la synchronisation (${box.length} éléments)...');

    final List<dynamic> keys = box.keys.toList();

    for (var key in keys) {
      final String rawInfo = box.get(key);
      final Map<String, dynamic> info = jsonDecode(rawInfo);

      final Map<String, String> fields = Map<String, String>.from(info['fields']);
      final File? photo = info['photoClient'] != null ? File(info['photoClient']) : null;
      final File? recto = info['documentRecto'] != null ? File(info['documentRecto']) : null;
      final File? verso = info['documentVerso'] != null ? File(info['documentVerso']) : null;

      try {
        final success = await _sejourService.enregistrerSejour(
          fields: fields,
          photoClient: photo,
          documentRecto: recto,
          documentVerso: verso,
        );

        if (success) {
          await box.delete(key);
          print('✅ Synchronisation réussie pour un séjour');
        } else {
          print('❌ Échec de synchronisation (API)');
          break; // On arrête pour ne pas encombrer le serveur si erreur
        }
      } catch (e) {
        print('⚠️ Erreur réseau lors de la synchro: $e');
        break;
      }
    }

    _isSyncing = false;
    print('🏁 Fin de la synchronisation.');
  }

  int get pendingCount => Hive.box('sejours_offline').length;
}
