import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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

  Future<Map<String, dynamic>> getSejoursActifs({
    int page = 1,
    String? search,
    String? dateDebut,
    String? dateFin,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = {
        'page': '$page',
        if (search != null && search.isNotEmpty) 'search': search,
        if (dateDebut != null && dateDebut.isNotEmpty) 'date_creation__gte': dateDebut,
        if (dateFin != null && dateFin.isNotEmpty) 'date_creation__lte': dateFin,
      };

      final uri = Uri.parse('$_baseUrl${ApiConfig.sejoursActifsUrl}').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> results = data['results'] ?? [];
        return {
          'count': data['count'] ?? 0,
          'results': results.map((json) => SejourModel.fromJson(json)).toList(),
        };
      }
      return {'count': 0, 'results': <SejourModel>[]};
    } catch (_) {
      return {'count': 0, 'results': <SejourModel>[]};
    }
  }

  Future<Map<String, dynamic>> getSejoursTermines({
    int page = 1,
    String? search,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = {
        'page': '$page',
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse('$_baseUrl${ApiConfig.sejoursTerminesUrl}').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> results = data['results'] ?? [];
        return {
          'count': data['count'] ?? 0,
          'results': results.map((json) => SejourModel.fromJson(json)).toList(),
        };
      }
      return {'count': 0, 'results': <SejourModel>[]};
    } catch (_) {
      return {'count': 0, 'results': <SejourModel>[]};
    }
  }

  Future<Map<String, dynamic>> getHistoriqueSejours({
    int page = 1,
    String? search,
    String? dateDebut,
    String? dateFin,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = {
        'page': '$page',
        if (search != null && search.isNotEmpty) 'search': search,
        if (dateDebut != null && dateDebut.isNotEmpty) 'date_creation__gte': dateDebut,
        if (dateFin != null && dateFin.isNotEmpty) 'date_creation__lte': dateFin,
      };

      final uri = Uri.parse('$_baseUrl${ApiConfig.historiqueSejoursUrl}').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> results = data['results'] ?? [];
        return {
          'count': data['count'] ?? 0,
          'results': results.map((json) => SejourModel.fromJson(json)).toList(),
        };
      }
      return {'count': 0, 'results': <SejourModel>[]};
    } catch (_) {
      return {'count': 0, 'results': <SejourModel>[]};
    }
  }

  Future<bool> enregistrerSejour({
    required Map<String, String> fields,
    File? photoClient,
    File? documentRecto,
    File? documentVerso,
  }) async {
    try {
      // --- Vérification de la connexion ---
      final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        await SyncService().addToQueue(
          fields: fields,
          photoClient: photoClient,
          documentRecto: documentRecto,
          documentVerso: documentVerso,
        );
        return true; // "Réussite" locale
      }

      final token = await _getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl${ApiConfig.sejoursUrl}'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      request.fields.addAll(fields);

      if (photoClient != null) {
        request.files.add(await http.MultipartFile.fromPath('photo_client', photoClient.path));
      }
      if (documentRecto != null) {
        request.files.add(await http.MultipartFile.fromPath('document_recto', documentRecto.path));
      }
      if (documentVerso != null) {
        request.files.add(await http.MultipartFile.fromPath('document_verso', documentVerso.path));
      }

      final response = await request.send();
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        // Erreur API (pas forcément réseau) -> on tente quand même la sauvegarde locale pour ne pas perdre la donnée
        await SyncService().addToQueue(
          fields: fields,
          photoClient: photoClient,
          documentRecto: documentRecto,
          documentVerso: documentVerso,
        );
        return true;
      }
    } catch (_) {
      // Exception réseau -> sauvegarde locale
      await SyncService().addToQueue(
        fields: fields,
        photoClient: photoClient,
        documentRecto: documentRecto,
        documentVerso: documentVerso,
      );
      return true;
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
        request.files.add(await http.MultipartFile.fromPath('photo_client', photoClient.path));
      }
      if (documentRecto != null) {
        request.files.add(await http.MultipartFile.fromPath('document_recto', documentRecto.path));
      }
      if (documentVerso != null) {
        request.files.add(await http.MultipartFile.fromPath('document_verso', documentVerso.path));
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
        request.files.add(await http.MultipartFile.fromPath('verso', verso.path));
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

  Future<bool> enregistrerSortie(int sejourId, String dateSortie, String observations) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConfig.sejoursUrl}$sejourId/enregistrer_sortie/'),
        headers: headers,
        body: jsonEncode({
          'date_sortie': dateSortie,
          'observations_sortie': observations,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<SejourModel?> getSejourById(int id) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$_baseUrl${ApiConfig.sejoursUrl}$id/');
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        return SejourModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<ClientHistoriqueModel?> getClientHistorique(String nom, String prenom, String document) async {
    try {
      final token = await _getToken();
      final clientId = "${nom}_${prenom}_$document";
      final uri = Uri.parse('$_baseUrl/sejours/historique-clients/${Uri.encodeComponent(clientId)}/');
      
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        return ClientHistoriqueModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>> getNationalites() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiConfig.nationalitesUrl}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as List;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getStats() async {
    try {
      final headers = await _getHeaders();
      final url = '$_baseUrl${ApiConfig.statsUrl}';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        // On retourne les clés brutes de l'API
        return {
          'nombre_clients_en_sejour': data['nombre_clients_en_sejour'] ?? 0,
          'nombre_sorties_clients': data['nombre_sorties_clients'] ?? 0,
          'nombre_enregistrements_clients': data['nombre_enregistrements_clients'] ?? 0,
          'nombre_historique_sejours': data['nombre_historique_sejours'] ?? 0,
          'nombre_utilisateurs': data['nombre_utilisateurs'] ?? 0,
          'activites_recentes': data['activites_recentes'] ?? [],
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
