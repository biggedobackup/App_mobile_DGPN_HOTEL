class UserModel {
  final int? id;
  final String nom;
  final String prenom;
  final String email;
  final String role;
  final int? hotelId;
  final String? hotelNom;
  final String? regionNom;
  final String? provinceNom;
  final String? communeNom;
  final String? roleDisplay;
  final String? lastLogin;
  final String? dateCreation;
  final String? telephone;
  final String? photo;
  final bool? isActif;

  UserModel({
    this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    this.roleDisplay,
    this.hotelId,
    this.hotelNom,
    this.regionNom,
    this.provinceNom,
    this.communeNom,
    this.lastLogin,
    this.dateCreation,
    this.telephone,
    this.photo,
    this.isActif,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Sécurité pour le champ hotel qui peut être un ID ou un objet
    int? finalHotelId;
    String? finalHotelNom;
    final hotelData = json['hotel'];
    if (hotelData is int) {
      finalHotelId = hotelData;
    } else if (hotelData is Map) {
      finalHotelId = hotelData['id'];
      finalHotelNom = hotelData['denomination'] ?? hotelData['nom'];
    }
    finalHotelNom ??= json['hotel_nom'];

    return UserModel(
      id: json['id'],
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      roleDisplay: json['role_display'],
      hotelId: finalHotelId,
      hotelNom: finalHotelNom,
      regionNom: json['region_nom'],
      provinceNom: json['province_nom'],
      communeNom: json['commune_nom'],
      lastLogin: json['last_login'],
      dateCreation: json['date_creation'],
      telephone: json['telephone'],
      photo: json['photo_profil'],
      isActif: json['statut'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'role': role,
      'hotel': hotelId,
      'telephone': telephone,
      'statut': isActif,
      if (id != null) 'id': id,
    };
  }

  String get fullName => '$prenom $nom'.trim();
  String get initials =>
      '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'
          .toUpperCase();
}
