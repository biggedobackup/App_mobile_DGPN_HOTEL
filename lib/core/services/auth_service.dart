import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../constants/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _baseUrl = ApiConfig.baseUrl;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConfig.loginUrl}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        final role = data['user']?['role'] ?? '';

        // Bloquer les rôles non autorisés sur mobile
        if (role != 'AGENT_ACCUEIL' && role != 'GERANT_HOTEL') {
          return {
            'success': false,
            'error':
                'Accès réservé au personnel hôtelier. Utilisez le portail web.'
          };
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access'] ?? '');
        await prefs.setString('refresh_token', data['refresh'] ?? '');
        await prefs.setString('user_role', role);
        await prefs.setString(
          'user_hotel_id',
          data['user']?['hotel_id']?.toString() ?? '',
        );
        await prefs.setString(
          'user_nom',
          '${data['user']?['prenom'] ?? ''} ${data['user']?['nom'] ?? ''}',
        );
        await prefs.setString('user_email', data['user']?['email'] ?? '');

        return {'success': true, 'user': UserModel.fromJson(data['user'])};
      } else {
        return {
          'success': false,
          'error': data['detail'] ?? 'Identifiants invalides.'
        };
      }
    } catch (_) {
      return {'success': false, 'error': 'Erreur de connexion au serveur.'};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_role');
    await prefs.remove('user_hotel_id');
    await prefs.remove('user_nom');
    await prefs.remove('user_email');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token != null && JwtDecoder.isExpired(token)) {
      final refreshed = await refreshToken();
      if (refreshed) {
        token = prefs.getString('access_token');
      } else {
        return null;
      }
    }
    return token;
  }

  Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refresh = prefs.getString('refresh_token');

      if (refresh == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('access_token', data['access']);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role') ?? '';
      final nom = prefs.getString('user_nom') ?? '';
      final email = prefs.getString('user_email') ?? '';
      final hotelIdStr = prefs.getString('user_hotel_id') ?? '';
      final hotelId = int.tryParse(hotelIdStr);

      final noms = nom.split(' ');
      final prenom = noms.isNotEmpty ? noms[0] : '';
      final nomSeul = noms.length > 1 ? noms.sublist(1).join(' ') : '';

      return UserModel(
        nom: nomSeul,
        prenom: prenom,
        email: email,
        role: role,
        hotelId: hotelId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConfig.changePasswordUrl}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
          'confirm_password': newPassword,
        }),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
