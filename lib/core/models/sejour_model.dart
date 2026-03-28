import 'package:intl/intl.dart';

class SejourModel {
  final int? id;
  final String nomClient;
  final String prenomClient;
  final String dateNaissance;
  final String lieuNaissance;
  final String lieuResidence;
  final String profession;
  final String nationalite;
  final String typeDocument;
  final String numeroDocument;
  final String dateEntree;
  final String? dateSortie;
  final String? observationsSortie;
  final String provenance;
  final String destination;
  final String motifSejour;
  final String numeroChambre;
  final int hotel;
  final String? hotelDenomination;
  final String? photoClient;
  final String? documentRecto;
  final String? documentVerso;
  final String contactTelephone;
  final String? agentEntreeNom;
  final String? agentSortieNom;
  final String? dateModification;
  final String statut;

  SejourModel({
    this.id,
    required this.nomClient,
    required this.prenomClient,
    required this.dateNaissance,
    required this.lieuNaissance,
    required this.lieuResidence,
    required this.profession,
    required this.nationalite,
    required this.typeDocument,
    required this.numeroDocument,
    required this.dateEntree,
    this.dateSortie,
    this.observationsSortie,
    required this.provenance,
    required this.destination,
    required this.motifSejour,
    required this.numeroChambre,
    required this.hotel,
    this.hotelDenomination,
    this.photoClient,
    this.documentRecto,
    this.documentVerso,
    required this.contactTelephone,
    this.agentEntreeNom,
    this.agentSortieNom,
    this.dateModification,
    required this.statut,
  });

  factory SejourModel.fromJson(Map<String, dynamic> json) {
    return SejourModel(
      id: json['id'],
      nomClient: json['nom_client'] ?? '',
      prenomClient: json['prenom_client'] ?? '',
      dateNaissance: json['date_naissance'] ?? '',
      lieuNaissance: json['lieu_naissance'] ?? '',
      lieuResidence: json['lieu_residence'] ?? '',
      profession: json['profession'] ?? '',
      nationalite: json['nationalite'] ?? '',
      typeDocument: json['type_document'] ?? '',
      numeroDocument: json['numero_document'] ?? '',
      dateEntree: json['date_entree'] ?? '',
      dateSortie: json['date_sortie'],
      observationsSortie: json['observations_sortie'],
      provenance: json['provenance'] ?? '',
      destination: json['destination'] ?? '',
      motifSejour: json['motif_sejour'] ?? '',
      numeroChambre: json['numero_chambre'] ?? '',
      hotel: json['hotel'] ?? 0,
      hotelDenomination: json['hotel_denomination'],
      photoClient: json['photo_client'],
      documentRecto: json['document_recto'],
      documentVerso: json['document_verso'],
      contactTelephone: json['contact_telephone'] ?? '',
      agentEntreeNom: json['agent_entree_nom'],
      agentSortieNom: json['agent_sortie_nom'],
      dateModification: json['date_modification'],
      statut: json['statut'] ?? 'EN_SEJOUR',
    );
  }

  String get clientFullName => '$prenomClient $nomClient'.trim();

  String get formattedDateArrivee {
    if (dateEntree.isEmpty) return 'Inconnue';
    try {
      final date = DateTime.parse(dateEntree);
      return DateFormat('dd MMM yyyy HH:mm', 'fr_FR').format(date);
    } catch (_) {
      return dateEntree;
    }
  }

  String get formattedDateSortie {
    if (dateSortie == null || dateSortie!.isEmpty) return 'Non définie';
    try {
      final date = DateTime.parse(dateSortie!);
      return DateFormat('dd MMM yyyy HH:mm', 'fr_FR').format(date);
    } catch (_) {
      return dateSortie!;
    }
  }

  int get dureeSejoursJours {
    try {
      final arrivee = DateTime.parse(dateEntree);
      final fin = dateSortie != null 
          ? DateTime.parse(dateSortie!) 
          : DateTime.now();
      return fin.difference(arrivee).inDays;
    } catch (_) {
      return 0;
    }
  }
}

class ClientHistoriqueModel {
  final String nomClient;
  final String prenomClient;
  final String numeroDocument;
  final String nationalite;
  final String contactTelephone;
  final int nombreSejours;
  final String dernierSejourDate;
  final String? dernierHotel;
  final List<SejourModel> sejours;

  ClientHistoriqueModel({
    required this.nomClient,
    required this.prenomClient,
    required this.numeroDocument,
    required this.nationalite,
    required this.contactTelephone,
    required this.nombreSejours,
    required this.dernierSejourDate,
    this.dernierHotel,
    required this.sejours,
  });

  factory ClientHistoriqueModel.fromJson(Map<String, dynamic> json) {
    var sejoursList = json['sejours'] as List? ?? [];
    return ClientHistoriqueModel(
      nomClient: json['nom_client'] ?? '',
      prenomClient: json['prenom_client'] ?? '',
      numeroDocument: json['numero_document'] ?? '',
      nationalite: json['nationalite'] ?? '',
      contactTelephone: json['contact_telephone'] ?? '',
      nombreSejours: json['nombre_sejours'] ?? 0,
      dernierSejourDate: json['dernier_sejour_date'] ?? '',
      dernierHotel: json['dernier_hotel'],
      sejours: sejoursList.map((s) => SejourModel.fromJson(s)).toList(),
    );
  }
}
