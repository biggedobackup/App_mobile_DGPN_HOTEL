import 'package:intl/intl.dart';

class ClientModel {
  final int? id;
  final String nom;
  final String prenom;
  final String dateNaissance;
  final String lieuNaissance;
  final String nationalite;
  final String profession;
  final String? sexe;            // 'HOMME' | 'FEMME' | null
  final String? paysResidence;   // pays_residence
  final String? villeResidence;  // ville_residence
  final String lieuResidence;
  final String contactTelephone;
  final String typeDocument;
  final String numeroDocument;
  final String? nomJeuneFille;
  final String? adresseComplete;
  final String? dateDelivranceDoc;
  final String? paysDelivranceDoc;
  final String? photoClient;
  final String? documentRecto;
  final String? documentVerso;
  final String? photoSignatureClient;
  final String? identifiantUnique;

  ClientModel({
    this.id,
    required this.nom,
    required this.prenom,
    required this.dateNaissance,
    required this.lieuNaissance,
    required this.nationalite,
    required this.profession,
    this.sexe,
    this.paysResidence,
    this.villeResidence,
    required this.lieuResidence,
    required this.contactTelephone,
    required this.typeDocument,
    required this.numeroDocument,
    this.nomJeuneFille,
    this.adresseComplete,
    this.dateDelivranceDoc,
    this.paysDelivranceDoc,
    this.photoClient,
    this.documentRecto,
    this.documentVerso,
    this.photoSignatureClient,
    this.identifiantUnique,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'],
      nom: json['nom'] ?? json['nom_client'] ?? '',
      prenom: json['prenom'] ?? json['prenom_client'] ?? '',
      dateNaissance: json['date_naissance'] ?? '',
      lieuNaissance: json['lieu_naissance'] ?? '',
      nationalite: json['nationalite'] ?? '',
      profession: json['profession'] ?? '',
      sexe: json['sexe'],
      paysResidence: json['pays_residence'],
      villeResidence: json['ville_residence'],
      lieuResidence: json['lieu_residence'] ?? '',
      contactTelephone: json['contact_telephone'] ?? '',
      typeDocument: json['type_document'] ?? '',
      numeroDocument: json['numero_document'] ?? '',
      nomJeuneFille: json['nom_jeune_fille'],
      adresseComplete: json['adresse_complete'],
      dateDelivranceDoc: json['date_delivrance_doc'],
      paysDelivranceDoc: json['pays_delivrance_doc'],
      photoClient: json['photo_client'],
      documentRecto: json['document_recto'],
      documentVerso: json['document_verso'],
      photoSignatureClient: json['photo_signature_client'],
      identifiantUnique: json['identifiant_unique'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'date_naissance': dateNaissance,
      'lieu_naissance': lieuNaissance,
      'nationalite': nationalite,
      'profession': profession,
      'sexe': sexe,
      'pays_residence': paysResidence,
      'ville_residence': villeResidence,
      'lieu_residence': lieuResidence,
      'contact_telephone': contactTelephone,
      'type_document': typeDocument,
      'numero_document': numeroDocument,
      'nom_jeune_fille': nomJeuneFille,
      'adresse_complete': adresseComplete,
      'date_delivrance_doc': dateDelivranceDoc,
      'pays_delivrance_doc': paysDelivranceDoc,
      'photo_client': photoClient,
      'document_recto': documentRecto,
      'document_verso': documentVerso,
      'photo_signature_client': photoSignatureClient,
      'identifiant_unique': identifiantUnique,
    };
  }
}

class SejourModel {
  final int? id;
  final ClientModel client;
  final String dateEntree;
  final String? dateSortiePrevue;
  final String? dateSortie;
  final String? observationsSortie;
  final String motifSejour;
  final String numeroChambre;
  final String? venantDe;
  final String? allantA;
  final String? moyenTransport;
  final String? numeroImmatriculation;
  final int hotel;
  final String? hotelDenomination;
  final String? agentEntreeNom;
  final String? agentSortieNom;
  final String? dateModification;
  final String statut;
  final String? identifiantUnique;
  final bool isOffline;

  // Accesseurs de compatibilité pour éviter de casser les écrans existants
  String get nomClient => client.nom;
  String get prenomClient => client.prenom;
  String get dateNaissance => client.dateNaissance;
  String get lieuNaissance => client.lieuNaissance;
  String get lieuResidence => client.lieuResidence;
  String get profession => client.profession;
  String get nationalite => client.nationalite;
  String get typeDocument => client.typeDocument;
  String get numeroDocument => client.numeroDocument;
  String get contactTelephone => client.contactTelephone;
  String? get photoClient => client.photoClient;
  String? get documentRecto => client.documentRecto;
  String? get documentVerso => client.documentVerso;

  SejourModel({
    this.id,
    required this.client,
    required this.dateEntree,
    this.dateSortiePrevue,
    this.dateSortie,
    this.observationsSortie,
    required this.motifSejour,
    required this.numeroChambre,
    this.venantDe,
    this.allantA,
    this.moyenTransport,
    this.numeroImmatriculation,
    required this.hotel,
    this.hotelDenomination,
    this.agentEntreeNom,
    this.agentSortieNom,
    this.dateModification,
    required this.statut,
    this.identifiantUnique,
    this.isOffline = false,
  });

  factory SejourModel.fromJson(Map<String, dynamic> json) {
    // Le backend peut envoyer 'client' (objet) ou 'client_details' (anciennement)
    final clientData = json['client'] ?? json['client_details'];
    
    return SejourModel(
      id: json['id'],
      client: clientData != null 
          ? ClientModel.fromJson(clientData)
          : ClientModel(
              nom: json['nom_client'] ?? '',
              prenom: json['prenom_client'] ?? '',
              dateNaissance: json['date_naissance'] ?? '',
              lieuNaissance: json['lieu_naissance'] ?? '',
              lieuResidence: json['lieu_residence'] ?? '',
              profession: json['profession'] ?? '',
              nationalite: json['nationalite'] ?? '',
              typeDocument: json['type_document'] ?? '',
              numeroDocument: json['numero_document'] ?? '',
              contactTelephone: json['contact_telephone'] ?? '',
              sexe: json['sexe'],
              paysResidence: json['pays_residence'],
              villeResidence: json['ville_residence'],
              nomJeuneFille: json['nom_jeune_fille'],
              adresseComplete: json['adresse_complete'],
              dateDelivranceDoc: json['date_delivrance_doc'],
              paysDelivranceDoc: json['pays_delivrance_doc'],
              photoClient: json['photo_client'],
              documentRecto: json['document_recto'],
              documentVerso: json['document_verso'],
            ),
      dateEntree: json['date_entree'] ?? '',
      dateSortiePrevue: json['date_sortie_prevue'],
      dateSortie: json['date_sortie'],
      observationsSortie: json['observations_sortie'],
      motifSejour: json['motif_sejour'] ?? '',
      numeroChambre: json['numero_chambre'] ?? '',
      venantDe: json['venant_de'],
      allantA: json['allant_a'],
      moyenTransport: json['moyen_transport'],
      numeroImmatriculation: json['numero_immatriculation'],
      hotel: json['hotel'] ?? 0,
      hotelDenomination: json['hotel_denomination'],
      agentEntreeNom: json['agent_entree_nom'],
      agentSortieNom: json['agent_sortie_nom'],
      dateModification: json['date_modification'],
      statut: json['statut'] ?? 'EN_SEJOUR',
      identifiantUnique: json['identifiant_unique']?.toString(),
      isOffline: false,
    );
  }

  factory SejourModel.fromOffline(Map<String, dynamic> offlineData) {
    final fields = Map<String, String>.from(offlineData['fields'] ?? {});
    return SejourModel(
      id: null,
      client: ClientModel(
        nom: fields['nom_client'] ?? '',
        prenom: fields['prenom_client'] ?? '',
        dateNaissance: fields['date_naissance'] ?? '',
        lieuNaissance: fields['lieu_naissance'] ?? '',
        lieuResidence: fields['lieu_residence'] ?? '',
        profession: fields['profession'] ?? '',
        nationalite: fields['nationalite'] ?? '',
        sexe: fields['sexe'],
        paysResidence: fields['pays_residence'],
        villeResidence: fields['ville_residence'],
        typeDocument: fields['type_document'] ?? '',
        numeroDocument: fields['numero_document'] ?? '',
        contactTelephone: fields['contact_telephone'] ?? '',
        nomJeuneFille: fields['nom_jeune_fille'],
        adresseComplete: fields['adresse_complete'],
        dateDelivranceDoc: fields['date_delivrance_doc'],
        paysDelivranceDoc: fields['pays_delivrance_doc'],
        photoClient: offlineData['photoClient'],
        documentRecto: offlineData['documentRecto'],
        documentVerso: offlineData['documentVerso'],
      ),
      dateEntree: offlineData['timestamp'] ?? DateTime.now().toIso8601String(),
      dateSortiePrevue: fields['date_sortie_prevue'],
      motifSejour: fields['motif_sejour'] ?? '',
      numeroChambre: fields['numero_chambre'] ?? '',
      venantDe: fields['venant_de'],
      allantA: fields['allant_a'],
      moyenTransport: fields['moyen_transport'],
      numeroImmatriculation: fields['numero_immatriculation'],
      hotel: 0,
      statut: 'HORS-LIGNE',
      identifiantUnique: offlineData['local_uuid']?.toString(),
      isOffline: true,
    );
  }

  String get clientFullName => '${client.prenom} ${client.nom}'.trim();

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

  String get formattedDateSortiePrevue {
    if (dateSortiePrevue == null || dateSortiePrevue!.isEmpty) return 'Non définie';
    try {
      final date = DateTime.parse(dateSortiePrevue!);
      return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
    } catch (_) {
      return dateSortiePrevue!;
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
  final ClientModel client;
  final int nombreSejours;
  final String dernierSejourDate;
  final String? dernierHotel;
  final String? statutDernierSejour;
  final String? dateEntreeDernier;
  final String? dateSortieDernier;
  final List<SejourModel> sejours;

  ClientHistoriqueModel({
    required this.client,
    required this.nombreSejours,
    required this.dernierSejourDate,
    this.dernierHotel,
    this.statutDernierSejour,
    this.dateEntreeDernier,
    this.dateSortieDernier,
    required this.sejours,
  });

  factory ClientHistoriqueModel.fromJson(Map<String, dynamic> json) {
    var sejoursList = json['sejours'] as List? ?? [];
    final clientData = json['client'] ?? json['client_details'] ?? json;
    return ClientHistoriqueModel(
      client: ClientModel.fromJson(clientData),
      nombreSejours: json['nombre_sejours'] ?? 0,
      dernierSejourDate: json['dernier_sejour_date'] ?? '',
      dernierHotel: json['dernier_hotel'],
      statutDernierSejour: json['statut_dernier_sejour'],
      dateEntreeDernier: json['date_entree_dernier'],
      dateSortieDernier: json['date_sortie_dernier'],
      sejours: sejoursList.map((s) => SejourModel.fromJson(s)).toList(),
    );
  }
}
