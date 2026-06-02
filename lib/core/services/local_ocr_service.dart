import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_document_reader_api/flutter_document_reader_api.dart' hide File;

class LocalOcrService {
  static final LocalOcrService _instance = LocalOcrService._internal();
  factory LocalOcrService() => _instance;
  LocalOcrService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? _initError;
  String? get initError => _initError;

  /// Initialise le SDK Regula de manière asynchrone avec la licence locale
  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('[LocalOcrService] Déjà initialisé dans l\'état Dart.');
      return true;
    }

    try {
      debugPrint('[LocalOcrService] Initialisation du SDK Regula...');
      final documentReader = DocumentReader.instance;
      
      // Charger le fichier de licence depuis les assets
      debugPrint('[LocalOcrService] Chargement du fichier assets/regula.license...');
      final ByteData licenseData = await rootBundle.load("assets/regula.license");
      debugPrint('[LocalOcrService] Fichier de licence chargé (${licenseData.lengthInBytes} octets).');
      final initConfig = InitConfig(licenseData);
      initConfig.delayedNNLoad = true; // Chargement NN asynchrone pour optimiser le démarrage de l'app
      
      debugPrint('[LocalOcrService] Appel de documentReader.initialize()...');
      final (success, error) = await documentReader.initialize(initConfig);
      
      if (error != null) {
        // En cas de hot restart, le côté natif est déjà initialisé
        if (error.message.contains("initialized already") ||
            error.message.contains("already initialized") ||
            error.message.contains("500")) {
          debugPrint("[LocalOcrService] Regula est déjà initialisé côté natif. Réinitialisation propre pour charger les scénarios...");
          try {
            documentReader.deinitializeReader();
            await Future.delayed(const Duration(milliseconds: 100));
            final (success2, error2) = await documentReader.initialize(initConfig);
            if (error2 == null && success2) {
              debugPrint("[LocalOcrService] Regula réinitialisé avec succès après deinitialize.");
              _isInitialized = true;
              _initError = null;
              
              // Afficher les scénarios disponibles
              final scenarios = documentReader.availableScenarios;
              debugPrint("[LocalOcrService] Scénarios après réinitialisation (${scenarios.length}) :");
              for (var s in scenarios) {
                debugPrint("[LocalOcrService] - ${s.name} : ${s.caption}");
              }
              return true;
            } else if (error2 != null) {
              debugPrint("[LocalOcrService] Échec de la réinitialisation après deinitialize : ${error2.message}");
            }
          } catch (deinitError) {
            debugPrint("[LocalOcrService] Exception lors de la réinitialisation propre : $deinitError");
          }

          // Fallback : Traité comme initialisé malgré l'échec de réinitialisation propre
          debugPrint("[LocalOcrService] Fallback : Traité comme initialisé.");
          _isInitialized = true;
          _initError = null;
          return true;
        }
        _initError = "${error.code} - ${error.message}";
        debugPrint("[LocalOcrService] Échec d'initialisation de Regula : $_initError");
        return false;
      }
      
      _isInitialized = success;
      debugPrint("[LocalOcrService] Regula initialisé avec succès : $success");
      if (success) {
        final scenarios = documentReader.availableScenarios;
        debugPrint("[LocalOcrService] Scénarios disponibles après initialisation normale (${scenarios.length}) :");
        for (var s in scenarios) {
          debugPrint("[LocalOcrService] - ${s.name} : ${s.caption}");
        }
      }
      return success;
    } catch (e) {
      _initError = e.toString();
      debugPrint("[LocalOcrService] Exception lors de l'initialisation de Regula (licence absente ou invalide) : $_initError");
      return false;
    }
  }

  /// Télécharge la base de données de documents Regula depuis internet
  Future<bool> downloadDatabase(void Function(double progress) onProgress) async {
    try {
      debugPrint('[LocalOcrService] Démarrage du téléchargement de la base de données Regula...');
      final documentReader = DocumentReader.instance;
      
      // La base de données 'Full' contient tous les pays supportés par la licence
      final (success, error) = await documentReader.prepareDatabase("Full", (progress) {
        final percentage = progress.progress / 100.0;
        onProgress(percentage);
      });
      
      if (error != null) {
        _initError = "Téléchargement échoué: ${error.code} - ${error.message}";
        debugPrint("[LocalOcrService] Échec du téléchargement : $_initError");
        return false;
      }
      
      debugPrint("[LocalOcrService] Base de données téléchargée et préparée avec succès !");
      return success;
    } catch (e) {
      _initError = "Exception de téléchargement: $e";
      debugPrint("[LocalOcrService] Exception de téléchargement : $_initError");
      return false;
    }
  }


  /// Analyse les images du document d'identité en local (hors-ligne) via Regula SDK
  Future<Map<String, dynamic>?> scanLocalDocument({
    required File recto,
    File? verso,
  }) async {
    try {
      debugPrint('[LocalOcrService] scanLocalDocument appelé...');
      if (!_isInitialized) {
        debugPrint('[LocalOcrService] Non initialisé dans l\'état Dart, tentative d\'initialisation...');
        final ok = await initialize();
        if (!ok) {
          debugPrint('[LocalOcrService] Échec d\'initialisation lors de scanLocalDocument : $_initError');
          return {
            'success': false,
            'error': 'license_missing',
            'message': 'Initialisation Regula échouée : $_initError'
          };
        }
      }

      debugPrint('[LocalOcrService] Préparation des octets images pour Regula...');
      final List<Uint8List> images = [];
      
      final rectoBytes = await recto.readAsBytes();
      images.add(rectoBytes);
      debugPrint('[LocalOcrService] Recto préparé : ${recto.path} (${rectoBytes.length} octets)');
      
      if (verso != null) {
        final versoBytes = await verso.readAsBytes();
        images.add(versoBytes);
        debugPrint('[LocalOcrService] Verso préparé : ${verso.path} (${versoBytes.length} octets)');
      }
      
      // Sélection dynamique du meilleur scénario supporté par la licence
      final scenario = _getBestScenario();
      debugPrint('[LocalOcrService] Utilisation du scénario sélectionné : $scenario');
      
      final config = RecognizeConfig.withScenario(
        scenario,
        images: images,
      );

      final completer = Completer<Map<String, dynamic>?>();

      debugPrint('[LocalOcrService] Lancement de la reconnaissance locale...');
      final startTime = DateTime.now();
      DocumentReader.instance.recognize(
        config,
        (DocReaderAction action, Results? results, DocReaderException? error) async {
          final duration = DateTime.now().difference(startTime);
          debugPrint("[LocalOcrService] Callback de reconnaissance reçu après ${duration.inMilliseconds}ms. Action : $action");
          
          if (error != null) {
            debugPrint("[LocalOcrService] Erreur lors de la reconnaissance Regula : ${error.message}");
            if (!completer.isCompleted) {
              completer.complete(null);
            }
            return;
          }

          if (action.stopped()) {
            if (results != null) {
              debugPrint("[LocalOcrService] Résultats de reconnaissance disponibles. Début du mapping...");
              final mapped = await _mapRegulaResults(results);
              if (!completer.isCompleted) {
                completer.complete(mapped);
              }
            } else {
              debugPrint("[LocalOcrService] Aucun résultat de reconnaissance disponible (results == null).");
              if (!completer.isCompleted) {
                completer.complete(null);
              }
            }
          }
        },
      );

      return await completer.future;
    } catch (e) {
      debugPrint('[LocalOcrService] Exception lors du scan local Regula : $e');
      return null;
    }
  }

  /// Mappe les résultats structurés de Regula vers le format attendu par le formulaire
  Future<Map<String, dynamic>> _mapRegulaResults(Results results) async {
    final Map<String, dynamic> champs = {};

    // 1. Nom (Surname)
    String? nom = await results.textFieldValueByType(FieldType.SURNAME);
    if (nom == null || nom.trim().isEmpty) {
      // Fallback sur le champ complet
      final surnameAndGiven = await results.textFieldValueByType(FieldType.SURNAME_AND_GIVEN_NAMES);
      if (surnameAndGiven != null && surnameAndGiven.contains('<<')) {
        nom = surnameAndGiven.split('<<').first.replaceAll('<', ' ').trim();
      } else {
        nom = surnameAndGiven;
      }
    }
    if (nom != null && nom.trim().isNotEmpty) {
      champs['Nom'] = nom.trim().toUpperCase();
    }

    // 2. Prénoms (Given names)
    String? prenoms = await results.textFieldValueByType(FieldType.GIVEN_NAMES);
    if (prenoms == null || prenoms.trim().isEmpty) {
      final surnameAndGiven = await results.textFieldValueByType(FieldType.SURNAME_AND_GIVEN_NAMES);
      if (surnameAndGiven != null && surnameAndGiven.contains('<<')) {
        final parts = surnameAndGiven.split('<<');
        if (parts.length > 1) {
          prenoms = parts[1].replaceAll('<', ' ').trim();
        }
      }
    }
    if (prenoms != null && prenoms.trim().isNotEmpty) {
      champs['Prénoms'] = prenoms.trim();
    }

    // 3. Date de naissance
    final dob = await results.textFieldValueByType(FieldType.DATE_OF_BIRTH);
    if (dob != null && dob.trim().isNotEmpty) {
      champs['Date de naissance'] = _formatRegulaDate(dob.trim());
    }

    // 4. Lieu de naissance
    final placeOfBirth = await results.textFieldValueByType(FieldType.PLACE_OF_BIRTH);
    if (placeOfBirth != null && placeOfBirth.trim().isNotEmpty) {
      champs['Lieu de naissance'] = placeOfBirth.trim();
    }

    // 5. Profession
    final profession = await results.textFieldValueByType(FieldType.PROFESSION);
    if (profession != null && profession.trim().isNotEmpty) {
      champs['Profession'] = profession.trim();
    }

    // 6. Numéro du document
    final docNum = await results.textFieldValueByType(FieldType.DOCUMENT_NUMBER);
    if (docNum != null && docNum.trim().isNotEmpty) {
      champs['Numéro du document'] = docNum.trim().toUpperCase();
    }

    // 7. Nationalité
    final nationality = await results.textFieldValueByType(FieldType.NATIONALITY);
    if (nationality != null && nationality.trim().isNotEmpty) {
      champs['Nationalité'] = nationality.trim();
    }

    // 8. Type de document
    final docClassCode = await results.textFieldValueByType(FieldType.DOCUMENT_CLASS_CODE);
    final docClassName = await results.textFieldValueByType(FieldType.DOCUMENT_CLASS_NAME);
    String? typeDoc;
    if (docClassCode != null) {
      typeDoc = _getTypeFromDocCode(docClassCode);
    } else if (docClassName != null) {
      typeDoc = _getTypeFromDocName(docClassName);
    }
    if (typeDoc != null) {
      champs['Type de document'] = typeDoc;
    } else {
      champs['Type de document'] = 'CNI';
    }

    // 9. Pays de résidence
    final addressCountry = await results.textFieldValueByType(FieldType.ADDRESS_COUNTRY);
    if (addressCountry != null && addressCountry.trim().isNotEmpty) {
      champs['Pays de résidence'] = addressCountry.trim();
    }

    // 10. Date de délivrance
    final doi = await results.textFieldValueByType(FieldType.DATE_OF_ISSUE);
    if (doi != null && doi.trim().isNotEmpty) {
      champs['Date de délivrance'] = _formatRegulaDate(doi.trim());
    }

    // 11. Nom de jeune fille
    String? maidenName = await results.textFieldValueByType(FieldType.FAMILY_NAME);
    if (maidenName == null || maidenName.trim().isEmpty) {
      maidenName = await results.textFieldValueByType(FieldType.SURNAME_OF_SPOSE);
    }
    if (maidenName != null && maidenName.trim().isNotEmpty) {
      champs['Nom de jeune fille'] = maidenName.trim().toUpperCase();
    }

    // 12. Pays de délivrance
    final issuingState = await results.textFieldValueByType(FieldType.ISSUING_STATE_NAME);
    if (issuingState != null && issuingState.trim().isNotEmpty) {
      champs['Pays de délivrance'] = issuingState.trim();
    }


    // Extraction et encodage du portrait en base64 (photo d'identité)
    String? portraitB64;
    try {
      final portraitBytes = await results.graphicFieldImageByType(GraphicFieldType.PORTRAIT);
      if (portraitBytes != null) {
        portraitB64 = base64Encode(portraitBytes);
      }
    } catch (e) {
      debugPrint("[LocalOcrService] Impossible d'extraire la photo d'identité : $e");
    }

    debugPrint("[LocalOcrService] Mapping terminé avec succès. Champs extraits :");
    champs.forEach((key, value) {
      debugPrint("[LocalOcrService] - $key : $value");
    });
    debugPrint("[LocalOcrService] - Portrait extrait : ${portraitB64 != null ? 'Oui' : 'Non'}");

    return {
      'success': true,
      'champs': champs,
      'portrait': portraitB64,
    };
  }

  /// Formate une date en YYYY-MM-DD
  String _formatRegulaDate(String dateStr) {
    if (dateStr.length == 6) {
      return _formatMrzDate(dateStr);
    }
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr)) {
      return dateStr;
    }
    final match = RegExp(r'^(\d{2})[\./-](\d{2})[\./-](\d{4})$').firstMatch(dateStr);
    if (match != null) {
      return '${match.group(3)}-${match.group(2)}-${match.group(1)}';
    }
    return dateStr;
  }

  /// Formate la date MRZ YYMMDD en YYYY-MM-DD
  String _formatMrzDate(String yymmdd) {
    if (yymmdd.length != 6) return yymmdd;
    int yy = int.tryParse(yymmdd.substring(0, 2)) ?? 0;
    String mm = yymmdd.substring(2, 4);
    String dd = yymmdd.substring(4, 6);
    int currentYear = DateTime.now().year % 100;
    int century = (yy <= currentYear + 5) ? 2000 : 1900;
    return '${century + yy}-$mm-$dd';
  }

  String _getTypeFromDocCode(String code) {
    code = code.toUpperCase();
    if (code.startsWith('P')) return 'PASSEPORT';
    if (code.startsWith('V')) return 'VISA';
    return 'CNI';
  }

  String _getTypeFromDocName(String name) {
    name = name.toUpperCase();
    if (name.contains('PASSPORT') || name.contains('PASSEPORT')) {
      return 'PASSEPORT';
    }
    if (name.contains('VISA')) {
      return 'VISA';
    }
    return 'CNI';
  }

  /// Détermine le meilleur scénario disponible supporté par la licence
  Scenario _getBestScenario() {
    final available = DocumentReader.instance.availableScenarios;
    debugPrint("[LocalOcrService] Nombre de scénarios disponibles dans le SDK : ${available.length}");
    
    if (available.isEmpty) {
      debugPrint("[LocalOcrService] AVERTISSEMENT : La liste des scénarios disponibles est vide ! Utilisation de Scenario.OCR par défaut.");
      return Scenario.OCR;
    }

    // Liste des scénarios préférés ordonnés du plus complet au plus basique
    final List<Scenario> priorityList = [
      Scenario.FULL_PROCESS,
      Scenario.MRZ_OR_BARCODE_OR_OCR,
      Scenario.MRZ_OR_OCR,
      Scenario.OCR,
      Scenario.MRZ,
      Scenario.BARCODE,
    ];

    for (var scenario in priorityList) {
      final isSupported = available.any((s) => s.name.toLowerCase() == scenario.value.toLowerCase());
      if (isSupported) {
        debugPrint("[LocalOcrService] Scénario sélectionné basé sur la priorité : ${scenario.name} (${scenario.value})");
        return scenario;
      }
    }

    // Si aucun de notre liste de priorité n'est directement trouvé, essayons de mapper le premier scénario disponible
    final firstAvailName = available.first.name;
    debugPrint("[LocalOcrService] Aucun scénario de la liste de priorité n'est supporté. Premier scénario disponible : $firstAvailName");
    
    for (var scenario in Scenario.values) {
      if (scenario.value.toLowerCase() == firstAvailName.toLowerCase()) {
        debugPrint("[LocalOcrService] Mappé avec succès au scénario prédéfini : ${scenario.name}");
        return scenario;
      }
    }

    // Fallback ultime
    debugPrint("[LocalOcrService] Fallback ultime : Scenario.OCR");
    return Scenario.OCR;
  }

  void dispose() {
    // Méthode no-op car le SDK Regula gère son propre cycle de vie
  }
}
