class ApiConfig {
  static const String baseUrl = 'http://10.10.16.83:8001/api';

  // Auth
  static const String loginUrl = '/connexion/';
  static const String refreshUrl = '/token/refresh/';

  // Sejours
  static const String sejoursUrl = '/sejours/tous/';
  static const String sejoursActifsUrl = '/sejours/actifs/';
  static const String sejoursTerminesUrl = '/sejours/termines/';
  static const String historiqueSejoursUrl = '/sejours/tous/';
  static const String enregistrementSejourUrl = '/sejours/enregistrer/';
  static const String nationalitesUrl = '/sejours/nationalites/';

  // Utilisateurs
  static const String utilisateursUrl = '/utilisateurs/';
  static const String profileUrl = '/profil/';
  static const String changePasswordUrl = '/modifier-mot-de-passe/';

  // Stats
  static const String statsUrl = '/tableau-bord/stats/';
}
