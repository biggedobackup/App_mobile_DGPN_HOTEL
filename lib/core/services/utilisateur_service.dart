import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';
import '../models/user_model.dart';

class UtilisateurService {
  static const String _baseUrl = ApiConfig.baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Aide au debug
  void debugPrintResponse(int code, String body) {
    // ignore: avoid_print
    print('[UtilisateurService] HTTP $code — ${body.substring(0, body.length.clamp(0, 200))}');
  }

  Future<List<UserModel>> getUtilisateurs({String? search, String? role, String? statut}) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (role != null && role.isNotEmpty) queryParams['role'] = role;
      if (statut != null && statut.isNotEmpty) queryParams['statut'] = statut;

      final uri = Uri.parse('$_baseUrl${ApiConfig.utilisateursUrl}')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> items;

        if (decoded is Map && decoded.containsKey('results')) {
          items = decoded['results'] as List<dynamic>;
        } else if (decoded is List) {
          items = decoded;
        } else {
          return [];
        }

        try {
          return items.map((u) => UserModel.fromJson(u as Map<String, dynamic>)).toList();
        } catch (e) {
          // ignore: avoid_print
          print('[UtilisateurService] Erreur mapping UserModel: $e');
          return [];
        }
      }
      debugPrintResponse(response.statusCode, response.body);
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('[UtilisateurService] getUtilisateurs catch: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createUtilisateurWithDetail(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConfig.utilisateursUrl}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 201) {
        return {'success': true};
      }

      String errorMessage = 'Erreur lors de la création';
      if (decoded is Map) {
        if (decoded.containsKey('detail')) {
          errorMessage = decoded['detail'].toString();
        } else {
          final List<String> errorList = [];
          decoded.forEach((key, value) {
            String field = key.toString().toUpperCase();
            if (value is List) {
              errorList.add("$field: ${value.join(', ')}");
            } else {
              errorList.add("$field: $value");
            }
          });
          if (errorList.isNotEmpty) errorMessage = errorList.join('\n');
        }
      }

      debugPrintResponse(response.statusCode, response.body);
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  Future<bool> createUtilisateur(Map<String, dynamic> data) async {
    final res = await createUtilisateurWithDetail(data);
    return res['success'] == true;
  }

  Future<bool> updateUtilisateur(int id, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await http.patch(
        Uri.parse('$_baseUrl${ApiConfig.utilisateursUrl}$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteUtilisateur(int id) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl${ApiConfig.utilisateursUrl}$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<UserModel?> getUtilisateurById(int id) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiConfig.utilisateursUrl}$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> getProfil() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiConfig.profileUrl}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return UserModel.fromJson(data);
      }
      debugPrintResponse(response.statusCode, response.body);
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[UtilisateurService] getProfil catch: $e');
      return null;
    }
  }

  Future<bool> updateProfil(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await http.patch(
        Uri.parse('$_baseUrl${ApiConfig.profileUrl}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
