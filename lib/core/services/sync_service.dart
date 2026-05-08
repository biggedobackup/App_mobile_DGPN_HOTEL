import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'sejour_service.dart';
import 'cache_warmup_service.dart';
import 'dart:async';

enum SyncStatus { idle, syncing, success, error }

class SyncEvent {
  final SyncStatus status;
  final String message;
  final int remaining;
  SyncEvent(this.status, this.message, this.remaining);
}


/// Service de synchronisation hors-ligne.
///
/// Architecture 2 queues :
///   - [_boxSejours]  → Nouveaux enregistrements de séjours (texte + images)
///   - [_boxSorties]  → Sorties clients (départs)
///
/// Synchro en masse (sejourenmasse) :
///   Étape 1 : envoi des données textuelles par lots de [_chunkSize] via JSON.
///   Étape 2 : upload des images séparément, identifiées par leur UUID local.
///   L'endpoint backend est idempotent (update_or_create), les retry sont sûrs.
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _sejourService = SejourService();
  bool _isSyncing = false;

  final _syncController = StreamController<SyncEvent>.broadcast();
  Stream<SyncEvent> get syncStream => _syncController.stream;

  void _notify(SyncStatus status, String message) {
    _syncController.add(SyncEvent(status, message, totalPendingCount));
  }


  // ── Boites Hive ────────────────────────────────────────────────────────
  static const String _boxSejours = 'sejours_offline';
  static const String _boxSorties = 'sorties_offline';

  // ── Taille maximale d'un lot envoyé au serveur ─────────────────────────
  static const int _chunkSize = 100;

  // ════════════════════════════════════════════════════════════════════════
  // DÉMARRAGE & ÉCOUTE RÉSEAU
  // ════════════════════════════════════════════════════════════════════════

  /// Démarre l'écoute réseau. Appeler une seule fois depuis main().
  void init() {
    try {
      Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
        if (!results.contains(ConnectivityResult.none)) {
          // Connexion rétablie : 1️⃣ Synchro des données en attente
          //                        2️⃣ Préchauffage du cache si périmé
          processAllQueues().then((_) async {
            final isStale = await CacheWarmupService().isCacheStale();
            if (isStale) {
              CacheWarmupService().warmUp();
            }
          });
        }
      });
    } catch (e) {
      // ignore: avoid_print
      print('[SyncService] Impossible d\'écouter les changements réseau: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // GÉNÉRATEUR UUID v4 (sans dépendance externe)
  // ════════════════════════════════════════════════════════════════════════

  /// Génère un UUID v4 valide compatible avec le champ UUIDField de Django.
  String _generateUuid() {
    final r = Random.secure();
    final chars = '0123456789abcdef';
    String s(int n) => List.generate(n, (_) => chars[r.nextInt(16)]).join();
    return '${s(8)}-${s(4)}-4${s(3)}-${['8', '9', 'a', 'b'][r.nextInt(4)]}${s(3)}-${s(12)}';
  }

  // ════════════════════════════════════════════════════════════════════════
  // QUEUE DES ENREGISTREMENTS (Nouveaux séjours)
  // ════════════════════════════════════════════════════════════════════════

  /// Ajoute un nouveau séjour à la file d'attente locale.
  /// Un UUID local est généré et attaché pour permettre la synchro en masse
  /// idempotente côté Django (update_or_create sur identifiant_unique).
  Future<void> addToQueue({
    required Map<String, String> fields,
    File? photoClient,
    File? documentRecto,
    File? documentVerso,
  }) async {
    final box = Hive.box(_boxSejours);
    final uuid = _generateUuid();

    // Persistance physique des fichiers (copie du cache temporaire vers document permanent)
    String? photoPath;
    String? rectoPath;
    String? versoPath;

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final offlineImagesDir = Directory(p.join(appDocDir.path, 'offline_images'));
      if (!await offlineImagesDir.exists()) {
        await offlineImagesDir.create(recursive: true);
      }

      if (photoClient != null && await photoClient.exists()) {
        final newFile = await photoClient.copy(p.join(offlineImagesDir.path, '${uuid}_photo.jpg'));
        photoPath = newFile.path;
      }
      if (documentRecto != null && await documentRecto.exists()) {
        final newFile = await documentRecto.copy(p.join(offlineImagesDir.path, '${uuid}_recto.jpg'));
        rectoPath = newFile.path;
      }
      if (documentVerso != null && await documentVerso.exists()) {
        final newFile = await documentVerso.copy(p.join(offlineImagesDir.path, '${uuid}_verso.jpg'));
        versoPath = newFile.path;
      }
    } catch (e) {
      // ignore: avoid_print
      print('[SyncService] Erreur lors de la copie des fichiers: $e');
    }

    final data = {
      'local_uuid': uuid,
      'fields': fields,
      'photoClient': photoPath,
      'documentRecto': rectoPath,
      'documentVerso': versoPath,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await box.add(jsonEncode(data));
    // ignore: avoid_print
    print('📥 Séjour hors-ligne sauvegardé (fichiers sécurisés). Total en attente: ${box.length}');
  }

  // ════════════════════════════════════════════════════════════════════════
  // SYNCHRO EN MASSE (Étape 1 : texte → Étape 2 : images)
  // ════════════════════════════════════════════════════════════════════════

  /// Synchronise tous les séjours en attente via l'endpoint sejourenmasse.
  ///
  /// Algorithme :
  /// 1. Lire tous les items de la Hive box
  /// 2. Générer un UUID aux anciens items qui n'en ont pas
  /// 3. Découper en lots de [_chunkSize]
  /// 4. Pour chaque lot :
  ///    a. POST le JSON texte → obtenir {local_uuid → db_id}
  ///    b. Pour chaque UUID confirmé → upload images
  ///    c. Supprimer de Hive uniquement si texte ET images réussis
  Future<void> processQueueBulk() async {
    if (_isSyncing) return;

    final box = Hive.box(_boxSejours);
    if (box.isEmpty) return;

    _isSyncing = true;
    _notify(SyncStatus.syncing, "Synchronisation des séjours en cours...");
    // ignore: avoid_print
    print('🔄 [Bulk] Début synchro: ${box.length} séjour(s) en attente...');


    try {
      // ── Phase de lecture + migration des anciens items sans UUID ──
      final allKeys = box.keys.toList();
      final List<_QueueItem> items = [];

      for (final key in allKeys) {
        final raw = box.get(key) as String?;
        if (raw == null) continue;

        final Map<String, dynamic> info = jsonDecode(raw);

        // Migration : les anciens items sans local_uuid en reçoivent un
        if (info['local_uuid'] == null || (info['local_uuid'] as String).isEmpty) {
          info['local_uuid'] = _generateUuid();
          await box.put(key, jsonEncode(info)); // Persistance pour retry
        }

        items.add(_QueueItem(
          hiveKey: key,
          localUuid: info['local_uuid'] as String,
          fields: Map<String, String>.from(info['fields'] ?? {}),
          photoPath: info['photoClient'] as String?,
          rectoPath: info['documentRecto'] as String?,
          versoPath: info['documentVerso'] as String?,
        ));
      }

      // ── Traitement par lots ──
      for (int i = 0; i < items.length; i += _chunkSize) {
        final chunk = items.sublist(
          i,
          (i + _chunkSize).clamp(0, items.length),
        );

        // ── Étape 1 : Envoi des données textuelles ──
        final List<Map<String, dynamic>> payload = chunk.map((item) => {
          ...item.fields,
          'local_uuid': item.localUuid,
        }).toList();

        // ignore: avoid_print
        print('📤 [Bulk] Lot ${i ~/ _chunkSize + 1}: ${chunk.length} séjour(s)...');

        final Map<String, int>? uuidToDbId =
            await _sejourService.sendSejoursEnMasse(payload);

        if (uuidToDbId == null) {
          _notify(SyncStatus.error, "Échec de connexion au serveur.");
          // ignore: avoid_print
          print('❌ [Bulk] Échec réseau pour ce lot — arrêt.');
          break;
        }


        // ignore: avoid_print
        print('✅ [Bulk] Texte: ${uuidToDbId.length} créés/mis à jour, '
            '${chunk.length - uuidToDbId.length} erreurs serveur.');

        // ── Étape 2 : Upload des images pour chaque item confirmé ──
        for (final item in chunk) {
          // Si le serveur n'a pas retourné un ID pour ce UUID → erreur → on skip
          if (!uuidToDbId.containsKey(item.localUuid)) continue;

          final photo = item.photoPath != null ? File(item.photoPath!) : null;
          final recto = item.rectoPath != null ? File(item.rectoPath!) : null;
          final verso = item.versoPath != null ? File(item.versoPath!) : null;

          final imagesOk = await _sejourService.uploadImagesParUuid(
            item.localUuid,
            photo: photo,
            recto: recto,
            verso: verso,
          );

          if (imagesOk) {
            // NOTE: On ne supprime plus les fichiers locaux immédiatement après la synchro
            // pour permettre la consultation hors-ligne des images même si la connexion repart.
            // Le nettoyage sera géré globalement par une tâche de maintenance.
            // await _deleteLocalFiles([photo, recto, verso]); 
            
            await box.delete(item.hiveKey);
            // ignore: avoid_print
            print('✅ [Bulk] Séjour ${item.localUuid} synchronisé (texte + images). Fichiers conservés pour cache local.');
          } else {
            // Images échouées → on garde en queue pour retry
            // Le texte est idempotent (update_or_create), donc le retry est safe
            // ignore: avoid_print
            print('⚠️ [Bulk] Images échouées pour ${item.localUuid} — réessai au prochain cycle.');
          }
        }
      }
    } finally {
      _isSyncing = false;
      if (box.isEmpty) {
        _notify(SyncStatus.success, "Tous les séjours sont synchronisés.");
      }
      // ignore: avoid_print
      print('🏁 [Bulk] Fin synchro. Restant: ${box.length} séjour(s).');
    }

  }

  /// Supprime une liste de fichiers locaux silencieusement.
  Future<void> deleteLocalFiles(List<File?> files) async {
    for (final f in files) {
      try {
        if (f != null && await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  /// Vide tout le dossier d'images hors-ligne (maintenance).
  Future<void> clearAllSyncImages() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final offlineImagesDir = Directory(p.join(appDocDir.path, 'offline_images'));
      if (await offlineImagesDir.exists()) {
        await offlineImagesDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  // ════════════════════════════════════════════════════════════════════════
  // QUEUE DES SORTIES (Départs clients)
  // ════════════════════════════════════════════════════════════════════════

  /// Ajoute une sortie client à la file d'attente locale.
  Future<void> addSortieToQueue(
      int sejourId, String dateSortie, String observations) async {
    final box = Hive.box(_boxSorties);
    final data = {
      'sejourId': sejourId,
      'dateSortie': dateSortie,
      'observations': observations,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await box.add(jsonEncode(data));
    // ignore: avoid_print
    print('📥 Sortie hors-ligne sauvegardée. Total: ${box.length}');
  }

  /// Envoie toutes les sorties en attente vers le serveur.
  Future<void> processSortieQueue() async {
    final box = Hive.box(_boxSorties);
    if (box.isEmpty) return;

    _notify(SyncStatus.syncing, "Synchronisation des sorties en cours...");
    // ignore: avoid_print
    print('🔄 [Sorties] Synchro: ${box.length} sortie(s) en attente...');


    for (final key in box.keys.toList()) {
      final raw = box.get(key) as String?;
      if (raw == null) continue;

      final Map<String, dynamic> info = jsonDecode(raw);
      final int sejourId = info['sejourId'] as int;
      final String dateSortie = info['dateSortie'] as String;
      final String obs = (info['observations'] as String?) ?? '';

      try {
        final success = await _sejourService.enregistrerSortie(
          sejourId,
          dateSortie,
          obs,
          fromSync: true,
        );

        if (success) {
          await box.delete(key);
          // ignore: avoid_print
          print('✅ [Sorties] Sortie séjour #$sejourId synchronisée.');
        } else {
          _notify(SyncStatus.error, "Erreur lors de la synchro des sorties.");
          // ignore: avoid_print
          print('❌ [Sorties] Échec sortie #$sejourId — arrêt du lot.');
          break;
        }

      } catch (e) {
        // ignore: avoid_print
        print('⚠️ [Sorties] Exception pour sortie #$sejourId: $e — arrêt.');
        break;
      }
    }

    if (box.isEmpty) {
      _notify(SyncStatus.success, "Toutes les sorties sont synchronisées.");
    }
    // ignore: avoid_print
    print('🏁 [Sorties] Fin synchro. Restant: ${box.length}.');
  }


  // ════════════════════════════════════════════════════════════════════════
  // POINT D'ENTRÉE UNIQUE
  // ════════════════════════════════════════════════════════════════════════

  /// Traite toutes les files dans l'ordre métier :
  /// 1. Séjours (enregistrements) — en masse
  /// 2. Sorties (départs) — après, car elles nécessitent que le séjour existe
  Future<void> processAllQueues() async {
    await processQueueBulk();
    await processSortieQueue();
  }

  // ── Compteurs (pour badges UI) ─────────────────────────────────────────
  int get pendingCount => Hive.box(_boxSejours).length;
  int get pendingSortiesCount => Hive.box(_boxSorties).length;
  int get totalPendingCount => pendingCount + pendingSortiesCount;
}

// ── Data class interne (Dart 2 compatible) ─────────────────────────────────
class _QueueItem {
  final dynamic hiveKey;
  final String localUuid;
  final Map<String, String> fields;
  final String? photoPath;
  final String? rectoPath;
  final String? versoPath;

  const _QueueItem({
    required this.hiveKey,
    required this.localUuid,
    required this.fields,
    this.photoPath,
    this.rectoPath,
    this.versoPath,
  });
}
