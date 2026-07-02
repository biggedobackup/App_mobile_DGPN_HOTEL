import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../constants/api_config.dart';
import '../models/sejour_model.dart';
import 'sync_service.dart';

class SejourService {
  static const String _baseUrl = ApiConfig.baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<bool> _isOfflineSafe() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  /// Télécharge et met en cache les images d'un séjour de manière proactive.
  void _preCacheSejourImages(Map<String, dynamic> json) {
    final client = json['client'] ?? json['client_details'] ?? json;
    _downloadFile(client['photo_client']);
    _downloadFile(client['document_recto']);
    _downloadFile(client['document_verso']);
  }

  Future<void> _downloadFile(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      final fullUrl = url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url';

      // getSingleFile télécharge l'image si elle n'est pas déjà présente
      // et la stocke dans le cache dont dépend CachedNetworkImage.
      await DefaultCacheManager().getSingleFile(fullUrl);
    } catch (_) {}
  }

  Future<Map<String, dynamic>> getSejoursActifs({
    int page = 1,
    String? search,
    String? dateDebut,
    String? dateFin,
  }) async {
    final cacheBox = Hive.box('cache');
    final cacheKey = 'sejours_actifs_p$page';

    try {
      final token = await _getToken();
      final queryParams = {
        'page': '$page',
        if (search != null && search.isNotEmpty) 'search': search,
        if (dateDebut != null && dateDebut.isNotEmpty)
          'date_creation__gte': dateDebut,
        if (dateFin != null && dateFin.isNotEmpty)
          'date_creation__lte': dateFin,
      };

      final uri = Uri.parse(
        '$_baseUrl${ApiConfig.sejoursActifsUrl}',
      ).replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> results = data['results'] ?? [];

        // Mise en cache individuelle de chaque séjour pour permettre l'accès au détail hors-ligne
        for (var json in results) {
          if (json['id'] != null) {
            await cacheBox.put('sejour_detail_${json['id']}', json);
            // Pré-chargement des images pour le mode hors-ligne
            _preCacheSejourImages(json);
          }
        }

        final Map<String, dynamic> finalData = {
          'count': data['count'] ?? 0,
          'results': results.map((json) => SejourModel.fromJson(json)).toList(),
        };

        // --- FUSION DONNÉES HORS-LIGNE (Uniquement page 1) ---
        if (page == 1) {
          final boxOffline = Hive.box('sejours_offline');
          final List<SejourModel> offlineResults = boxOffline.values.map((raw) {
            return SejourModel.fromOffline(jsonDecode(raw as String));
          }).toList();

          finalData['results'] = [...offlineResults, ...finalData['results']];
          finalData['count'] =
              (finalData['count'] as int) + offlineResults.length;
        }

        // Mise en cache (on stocke le JSON brut pour plus de simplicité)

        await cacheBox.put(cacheKey, data);
        return finalData;
      }
    } catch (_) {
      // Échec : on tente de lire le cache
    }

    final cached = cacheBox.get(cacheKey);
    if (cached != null) {
      final Map<String, dynamic> cachedData = Map<String, dynamic>.from(cached);
      final List<dynamic> results = cachedData['results'] ?? [];

      final resultsModels = results
          .map((json) => SejourModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      if (page == 1) {
        final boxOffline = Hive.box('sejours_offline');
        final List<SejourModel> offlineResults = boxOffline.values.map((raw) {
          return SejourModel.fromOffline(jsonDecode(raw as String));
        }).toList();
        return {
          'count': (cachedData['count'] ?? 0) + offlineResults.length,
          'results': [...offlineResults, ...resultsModels],
        };
      }

      return {'count': cachedData['count'] ?? 0, 'results': resultsModels};
    }

    return {'count': 0, 'results': <SejourModel>[]};
  }

  Future<Map<String, dynamic>> getSejoursTermines({
    int page = 1,
    String? search,
  }) async {
    final cacheBox = Hive.box('cache');
    final cacheKey = 'sejours_termines_p$page';
    try {
      final token = await _getToken();
      final queryParams = {
        'page': '$page',
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse(
        '$_baseUrl${ApiConfig.sejoursTerminesUrl}',
      ).replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        await cacheBox.put(cacheKey, data);
        final List<dynamic> results = data['results'] ?? [];

        // Mise en cache individuelle de chaque séjour pour permettre l'accès au détail hors-ligne
        for (var json in results) {
          if (json['id'] != null) {
            await cacheBox.put('sejour_detail_${json['id']}', json);
            // Pré-chargement des images pour le mode hors-ligne
            _preCacheSejourImages(json);
          }
        }

        return {
          'count': data['count'] ?? 0,
          'results': results.map((json) => SejourModel.fromJson(json)).toList(),
        };
      }
    } catch (_) {}

    final cached = cacheBox.get(cacheKey);
    if (cached != null) {
      final Map<String, dynamic> cachedData = Map<String, dynamic>.from(cached);
      final List<dynamic> results = cachedData['results'] ?? [];
      return {
        'count': cachedData['count'] ?? 0,
        'results': results
            .map(
              (json) => SejourModel.fromJson(Map<String, dynamic>.from(json)),
            )
            .toList(),
      };
    }
    return {'count': 0, 'results': <SejourModel>[]};
  }

  Future<Map<String, dynamic>> getHistoriqueSejours({
    int page = 1,
    String? search,
    String? dateDebut,
    String? dateFin,
    String? hotel,
    String? statut,
    String? nationalite,
  }) async {
    final cacheBox = Hive.box('cache');
    final cacheKey = 'historique_sejours_p$page';
    try {
      final token = await _getToken();
      final queryParams = {
        'page': '$page',
        if (search != null && search.isNotEmpty) 'search': search,
        if (dateDebut != null && dateDebut.isNotEmpty)
          'date_creation__gte': dateDebut,
        if (dateFin != null && dateFin.isNotEmpty)
          'date_creation__lte': dateFin,
        if (hotel != null && hotel.isNotEmpty) 'hotel': hotel,
        if (statut != null && statut.isNotEmpty) 'statut': statut,
        if (nationalite != null && nationalite.isNotEmpty)
          'nationalite': nationalite,
      };

      final uri = Uri.parse(
        '$_baseUrl${ApiConfig.historiqueSejoursUrl}',
      ).replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        await cacheBox.put(cacheKey, data);
        final List<dynamic> results = data['results'] ?? [];

        // Mise en cache individuelle de chaque séjour pour permettre l'accès au détail hors-ligne
        for (var json in results) {
          if (json['id'] != null) {
            await cacheBox.put('sejour_detail_${json['id']}', json);
            // Pré-chargement des images pour le mode hors-ligne
            _preCacheSejourImages(json);
          }
        }

        final Map<String, dynamic> finalData = {
          'count': data['count'] ?? 0,
          'results': results
              .map((json) => ClientHistoriqueModel.fromJson(json))
              .toList(),
        };

        return finalData;
      }
    } catch (_) {}

    final cached = cacheBox.get(cacheKey);
    if (cached != null) {
      final Map<String, dynamic> cachedData = Map<String, dynamic>.from(cached);
      final List<dynamic> results = cachedData['results'] ?? [];

      final resultsModels = results
          .map(
            (json) =>
                ClientHistoriqueModel.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();

      return {'count': cachedData['count'] ?? 0, 'results': resultsModels};
    }

    return {'count': 0, 'results': <ClientHistoriqueModel>[]};
  }

  Future<bool> enregistrerSejour({
    required Map<String, String> fields,
    File? photoClient,
    File? documentRecto,
    File? documentVerso,
    bool fromSync = false,
  }) async {
    try {
      // --- Vérification de la connexion ---
      final bool offline = await _isOfflineSafe();
      if (offline) {
        if (!fromSync) {
          await SyncService().addToQueue(
            fields: fields,
            photoClient: photoClient,
            documentRecto: documentRecto,
            documentVerso: documentVerso,
          );
          return true; // "Réussite" locale
        }
        return false; // Échec pour le SyncManager
      }

      final token = await _getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl${ApiConfig.sejoursUrl}'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields.addAll(fields);

      if (photoClient != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'photo_client',
            photoClient.path,
            filename: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      }
      if (documentRecto != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'document_recto',
            documentRecto.path,
            filename: 'recto_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      }
      if (documentVerso != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'document_verso',
            documentVerso.path,
            filename: 'verso_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      }

      final response = await request.send();
      final respBody = await response.stream.bytesToString();
      // ignore: avoid_print
      print("RESPONSE BODY: $respBody");

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        // ignore: avoid_print
        print("API ERROR ${response.statusCode}: falling back to offline");
        // Erreur API (pas forcément réseau) -> on tente quand même la sauvegarde locale pour ne pas perdre la donnée
        if (!fromSync) {
          await SyncService().addToQueue(
            fields: fields,
            photoClient: photoClient,
            documentRecto: documentRecto,
            documentVerso: documentVerso,
          );
          return true;
        }
        return false;
      }
    } catch (_) {
      // Exception réseau -> sauvegarde locale
      if (!fromSync) {
        await SyncService().addToQueue(
          fields: fields,
          photoClient: photoClient,
          documentRecto: documentRecto,
          documentVerso: documentVerso,
        );
        return true;
      }
      return false;
    }
  }

  Future<bool> updateSejour({
    required int id,
    required Map<String, String> fields,
    File? photoClient,
    File? documentRecto,
    File? documentVerso,
  }) async {
    try {
      final token = await _getToken();
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$_baseUrl${ApiConfig.sejoursUrl}$id/'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields.addAll(fields);

      if (photoClient != null) {
        request.files.add(
          await http.MultipartFile.fromPath('photo_client', photoClient.path),
        );
      }
      if (documentRecto != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'document_recto',
            documentRecto.path,
          ),
        );
      }
      if (documentVerso != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'document_verso',
            documentVerso.path,
          ),
        );
      }

      final response = await request.send();
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> scanDocument({
    required File recto,
    File? verso,
  }) async {
    try {
      final token = await _getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/sejours/scan-document/'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('recto', recto.path));
      if (verso != null) {
        request.files.add(
          await http.MultipartFile.fromPath('verso', verso.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Enregistre une sortie en ligne, ou la met en queue hors-ligne.
  /// [fromSync] = true quand c'est le SyncService qui appelle (évite la boucle infinie).
  Future<bool> enregistrerSortie(
    int sejourId,
    String dateSortie,
    String observations, {
    bool fromSync = false,
  }) async {
    try {
      final bool offline = await _isOfflineSafe();
      if (offline) {
        if (!fromSync) {
          await SyncService().addSortieToQueue(
            sejourId,
            dateSortie,
            observations,
          );
        }
        return !fromSync; // false pour le SyncService (il doit savoir que c'est un échec)
      }

      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl${ApiConfig.sejoursUrl}$sejourId/enregistrer_sortie/',
            ),
            headers: headers,
            body: jsonEncode({
              'date_sortie': dateSortie,
              'observations_sortie': observations,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      // Erreur API inattendue -> mise en queue pour retry
      if (!fromSync) {
        await SyncService().addSortieToQueue(
          sejourId,
          dateSortie,
          observations,
        );
      }
      return !fromSync;
    } catch (_) {
      // Exception réseau -> mise en queue
      if (!fromSync) {
        await SyncService().addSortieToQueue(
          sejourId,
          dateSortie,
          observations,
        );
      }
      return !fromSync;
    }
  }

  Future<SejourModel?> getSejourById(int id) async {
    final cacheBox = Hive.box('cache');
    final cacheKey = 'sejour_detail_$id';
    try {
      final token = await _getToken();
      final uri = Uri.parse('$_baseUrl${ApiConfig.sejoursUrl}$id/');
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        await cacheBox.put(cacheKey, data);
        return SejourModel.fromJson(data);
      }
    } catch (_) {
      // Erreur réseau : check cache
    }

    final cached = cacheBox.get(cacheKey);
    return cached != null
        ? SejourModel.fromJson(Map<String, dynamic>.from(cached))
        : null;
  }

  Future<ClientHistoriqueModel?> getClientHistorique(
    String nom,
    String prenom,
    String document,
  ) async {
    // Note: Cette méthode est dépréciée au profit de getClientHistoriqueById
    // car le backend utilise désormais l'ID numérique du client.
    return null;
  }

  Future<ClientHistoriqueModel?> getClientHistoriqueById(int clientId) async {
    final cacheBox = Hive.box('cache');
    final cacheKey = 'client_hist_id_$clientId';
    try {
      final token = await _getToken();
      final uri = Uri.parse(
        '$_baseUrl${ApiConfig.clientHistoriqueUrl}$clientId/',
      );

      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        await cacheBox.put(cacheKey, data);
        return ClientHistoriqueModel.fromJson(data);
      }
    } catch (_) {}

    final cached = cacheBox.get(cacheKey);
    return cached != null
        ? ClientHistoriqueModel.fromJson(Map<String, dynamic>.from(cached))
        : null;
  }

  Future<List<dynamic>> getNationalites() async {
    final cacheBox = Hive.box('cache');
    const cacheKey = 'nationalites_list';
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$_baseUrl${ApiConfig.nationalitesUrl}'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        // Mise en cache pour usage hors-ligne
        await cacheBox.put(cacheKey, data);
        return data;
      }
    } catch (_) {}

    // Fallback : liste locale mise en cache lors de la dernière connexion
    final cached = cacheBox.get(cacheKey);
    if (cached != null) return List<dynamic>.from(cached);
    return [];
  }

  Future<List<dynamic>> getPays() async {
    final cacheBox = Hive.box('cache');
    const cacheKey = 'pays_list';
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$_baseUrl${ApiConfig.paysUrl}'), headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        // Mise en cache pour usage hors-ligne
        await cacheBox.put(cacheKey, data);
        return data;
      }
    } catch (_) {}

    // Fallback : liste locale mise en cache lors de la dernière connexion
    final cached = cacheBox.get(cacheKey);
    if (cached != null) return List<dynamic>.from(cached);
    return [];
  }

  Future<Map<String, dynamic>?> getStats() async {
    final cacheBox = Hive.box('cache');

    Map<String, dynamic>? parseCache(dynamic cachedData) {
      if (cachedData == null) return null;
      final stats = Map<String, dynamic>.from(cachedData);
      if (stats['activites_recentes'] != null) {
        stats['activites_recentes'] = (stats['activites_recentes'] as List)
            .map((a) => Map<String, dynamic>.from(a))
            .toList();
      }
      return stats;
    }

    try {
      final bool offline = await _isOfflineSafe();
      if (offline) {
        return parseCache(cacheBox.get('last_stats'));
      }

      final headers = await _getHeaders();
      final url = '$_baseUrl${ApiConfig.statsUrl}';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final stats = {
          'nombre_clients_en_sejour':
              (data['nombre_clients_en_sejour'] ?? 0) +
              Hive.box('sejours_offline').length,
          'nombre_sorties_clients':
              (data['nombre_sorties_clients'] ?? 0) +
              Hive.box('sorties_offline').length,
          'nombre_enregistrements_clients':
              (data['nombre_enregistrements_clients'] ?? 0) +
              Hive.box('sejours_offline').length,
          'nombre_historique_sejours': data['nombre_historique_sejours'] ?? 0,
          'nombre_utilisateurs': data['nombre_utilisateurs'] ?? 0,
          'activites_recentes': data['activites_recentes'] ?? [],
        };

        // Injecter les activités hors-ligne en tête de liste
        final offlineSejours = Hive.box('sejours_offline').values.map((raw) {
          final info = jsonDecode(raw as String);
          final fields = info['fields'] ?? {};
          return {
            'id': null,
            'nom': '${fields['prenom_client']} ${fields['nom_client']}',
            'hotel': 'HORS-LIGNE (En attente)',
            'date': 'À l\'instant',
            'statut': 'En attente synchro',
          };
        }).toList();

        stats['activites_recentes'] = [
          ...offlineSejours,
          ...stats['activites_recentes'],
        ];

        // Mettre en cache
        await cacheBox.put('last_stats', stats);
        return stats;
      }

      // En cas d'erreur API, on tente le cache
      return parseCache(cacheBox.get('last_stats'));
    } catch (_) {
      return parseCache(cacheBox.get('last_stats'));
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // SYNCHRO EN MASSE (2-Step : texte d'abord, images ensuite)
  // ════════════════════════════════════════════════════════════════════════

  /// Envoie un lot de séjours (données textuelles uniquement) au serveur.
  /// Retourne un Map {local_uuid → db_id} pour les items créés/mis à jour.
  /// Retourne null si la requête réseau échoue complètement.
  Future<Map<String, int>?> sendSejoursEnMasse(
    List<Map<String, dynamic>> sejours,
  ) async {
    try {
      final token = await _getToken();
      final response = await http
          .post(
            Uri.parse('$_baseUrl${ApiConfig.sejoursEnMasseUrl}'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'sejours': sejours}),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final rawIds = data['results']?['ids'] as Map? ?? {};
        // Conversion en Map<String, int>
        return rawIds.map((k, v) => MapEntry(k.toString(), v as int));
      }
      // ignore: avoid_print
      print(
        '[SejourService.sendSejoursEnMasse] HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 200))}',
      );
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[SejourService.sendSejoursEnMasse] Exception: $e');
      return null;
    }
  }

  /// Upload les images (photo, recto, verso) d'un séjour déjà créé côté serveur,
  /// identifié par son UUID local Flutter.
  /// Retourne true si le serveur confirme OK (200), false sinon.
  Future<bool> uploadImagesParUuid(
    String localUuid, {
    File? photo,
    File? recto,
    File? verso,
  }) async {
    // Si aucune image, rien à faire
    if (photo == null && recto == null && verso == null) return true;

    try {
      final token = await _getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl${ApiConfig.sejoursUploadImagesUrl}'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['local_uuid'] = localUuid;

      if (photo != null && await photo.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'photo_client',
            photo.path,
            filename: 'photo_$localUuid.jpg',
          ),
        );
      }
      if (recto != null && await recto.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'document_recto',
            recto.path,
            filename: 'recto_$localUuid.jpg',
          ),
        );
      }
      if (verso != null && await verso.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'document_verso',
            verso.path,
            filename: 'verso_$localUuid.jpg',
          ),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      if (streamedResponse.statusCode != 200) {
        final respStr = await streamedResponse.stream.bytesToString();
        // ignore: avoid_print
        print("UPLOAD IMAGES ERROR ${streamedResponse.statusCode}: $respStr");
        return false;
      }
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('[SejourService.uploadImagesParUuid] Exception: $e');
      return false;
    }
  }

  /// Vérifie si l'API en ligne / serveur est accessible et répond normalement.
  Future<bool> checkApiHealth() async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$_baseUrl${ApiConfig.nationalitesUrl}');
      final response = await http
          .get(
            uri,
            headers: {
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 3));
      
      // Si on reçoit une réponse valide (inférieure à 500), le serveur est vivant
      return response.statusCode < 500;
    } catch (e) {
      return false;
    }
  }
}

