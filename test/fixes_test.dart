import 'package:flutter_test/flutter_test.dart';
import 'package:dgpn_hotel/core/services/sejour_service.dart';
import 'package:dgpn_hotel/core/services/sync_service.dart';
import 'package:dgpn_hotel/core/models/sejour_model.dart';

void main() {
  group('Mobile Fixes Unit Tests', () {
    test('Date normalization: formats OCR JJ.MM.AAAA et JJ/MM/AAAA vers AAAA-MM-JJ', () {
      expect(SejourService.normalizeDateString('15.08.1990'), equals('1990-08-15'));
      expect(SejourService.normalizeDateString('05/12/2001'), equals('2001-12-05'));
      expect(SejourService.normalizeDateString('1/2/1985'), equals('1985-02-01'));
      expect(SejourService.normalizeDateString('01-02-1985'), equals('1985-02-01'));
      expect(SejourService.normalizeDateString('1990-08-15'), equals('1990-08-15'));
      expect(SejourService.normalizeDateString('2026/05/14'), equals('2026-05-14'));
      expect(SejourService.normalizeDateString('2026.05.14'), equals('2026-05-14'));
      expect(SejourService.normalizeDateString(''), isNull);
      expect(SejourService.normalizeDateString('   '), isNull);
      expect(SejourService.normalizeDateString(null), isNull);
    });

    test('SyncStatus and SyncEvent creation', () {
      final event1 = SyncEvent(SyncStatus.syncing, "Synchronisation en cours", 5);
      expect(event1.status, equals(SyncStatus.syncing));
      expect(event1.remaining, equals(5));

      final event2 = SyncEvent(SyncStatus.idle, "Prêt", 0);
      expect(event2.status, equals(SyncStatus.idle));
      expect(event2.remaining, equals(0));

      final event3 = SyncEvent(SyncStatus.success, "Succès", 0);
      expect(event3.status, equals(SyncStatus.success));

      final event4 = SyncEvent(SyncStatus.error, "Erreur", 2);
      expect(event4.status, equals(SyncStatus.error));
    });

    test('SejourModel serialization from JSON with new agent fields', () {
      final json = {
        'id': 101,
        'date_entree': '2026-10-26T14:00:00Z',
        'date_sortie_prevue': '2026-10-28T12:00:00Z',
        'numero_chambre': '204',
        'motif_sejour': 'AFFAIRES',
        'hotel': 1,
        'hotel_denomination': 'Splendid Hotel',
        'agent_entree_nom': 'KABORE',
        'agent_sortie_nom': null,
        'statut': 'EN_COURS',
        'client': {
          'id': 50,
          'nom': 'TRAORE',
          'prenom': 'Moussa',
          'date_naissance': '1992-04-10',
          'lieu_naissance': 'Bobo',
          'nationalite': 'Burkinabè',
          'profession': 'Ingenieur',
          'contact_telephone': '78001122',
          'type_document': 'CNI',
          'numero_document': 'B12345678',
          'pays_residence': 'Burkina Faso',
          'ville_residence': 'Bobo-Dioulasso'
        }
      };

      final sejour = SejourModel.fromJson(json);
      expect(sejour.id, equals(101));
      expect(sejour.nomClient, equals('TRAORE'));
      expect(sejour.prenomClient, equals('Moussa'));
      expect(sejour.numeroChambre, equals('204'));
      expect(sejour.agentEntreeNom, equals('KABORE'));
      expect(sejour.hotelDenomination, equals('Splendid Hotel'));
    });
  });
}
