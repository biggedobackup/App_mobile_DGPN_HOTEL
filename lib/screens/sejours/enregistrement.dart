import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/widgets/dgpn_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/services/sejour_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/utilisateur_service.dart';
import '../../core/models/user_model.dart';
import '../../core/services/local_ocr_service.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/models/scan_result_data.dart';

class EnregistrementScreen extends StatefulWidget {
  final String? sejourId;
  final ScanResultData? scanData;
  const EnregistrementScreen({super.key, this.sejourId, this.scanData});
  @override
  State<EnregistrementScreen> createState() => _EnregistrementScreenState();
}

class _EnregistrementScreenState extends State<EnregistrementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sejourService = SejourService();
  final _authService = AuthService();
  final _userService = UtilisateurService();
  UserModel? _user;
  bool _loading = false;
  bool _scanning = false;

  // Form Controllers
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _dateNaissCtrl = TextEditingController();
  final _lieuNaissCtrl = TextEditingController();
  final _professionCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _numDocCtrl = TextEditingController();
  final _chambreCtrl = TextEditingController();
  final _dateEntreeCtrl = TextEditingController();
  final _dateSortiePrevueCtrl = TextEditingController();

  final _nomJeuneFilleCtrl = TextEditingController();
  final _dateDelivranceDocCtrl = TextEditingController();
  final _venantDeCtrl = TextEditingController();
  final _allantACtrl = TextEditingController();
  final _immatriculationCtrl = TextEditingController();
  final _villeResCtrl = TextEditingController();
  final _hotelCtrl = TextEditingController();

  String _nationalite = 'Burkinabè';
  String _sexe = 'HOMME';
  String _paysResidence = 'Burkina Faso';
  String _typeDoc = 'CNI';
  String _motifSejour = 'AFFAIRES';
  String _moyenTransport = 'AUTRE';
  String _paysDelivrance = 'Burkina Faso';
  String _hotelId = '';

  File? _photoClient;
  File? _docRecto;
  File? _docVerso;

  String? _photoUrl;
  String? _rectoUrl;
  String? _versoUrl;
  String? _localUuid;

  List<String> _nationalites = ['Burkinabè'];
  List<String> _paysList = ['Burkina Faso'];
  final ImagePicker _picker = ImagePicker();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool? _scanServiceReady;

  @override
  void initState() {
    super.initState();
    _dateEntreeCtrl.text = DateTime.now().toString().substring(0, 16);
    _initFormState();
  }

  Future<void> _initFormState() async {
    await _chargerDonnees();
    if (widget.sejourId != null) {
      await _chargerSejourExistant();
    } else if (widget.scanData != null) {
      _prefillFromScanData();
    }
    _checkScanStatus();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      _checkScanStatus();
    });
  }

  void _prefillFromScanData() {
    final d = widget.scanData!;
    setState(() {
      if (d.nom != null) _nomCtrl.text = d.nom!;
      if (d.prenom != null) _prenomCtrl.text = d.prenom!;
      if (d.dateNaissance != null) _dateNaissCtrl.text = d.dateNaissance!;
      if (d.lieuNaissance != null) _lieuNaissCtrl.text = d.lieuNaissance!;
      if (d.profession != null) _professionCtrl.text = d.profession!;
      if (d.numeroDocument != null) _numDocCtrl.text = d.numeroDocument!;
      if (d.nationalite != null && d.nationalite!.trim().isNotEmpty) {
        final natRaw = d.nationalite!.trim();
        final found = _nationalites.firstWhere(
          (n) => n.toUpperCase() == natRaw.toUpperCase(),
          orElse: () {
            _nationalites.add(natRaw);
            return natRaw;
          },
        );
        _nationalite = found;
      }
      if (d.typeDocument != null && d.typeDocument!.trim().isNotEmpty) {
        final t = d.typeDocument!.trim().toUpperCase();
        if (t.contains('PASSPORT') || t.contains('PASSEPORT')) {
          _typeDoc = 'PASSEPORT';
        } else if (t.contains('CNI') || t.contains('ID') || t.contains('CARD')) {
          _typeDoc = 'CNI';
        }
      }
      if (d.paysDelivrance != null && d.paysDelivrance!.trim().isNotEmpty) {
        final paysRaw = d.paysDelivrance!.trim();
        final found = _paysList.firstWhere(
          (p) => p.toUpperCase() == paysRaw.toUpperCase(),
          orElse: () {
            _paysList.add(paysRaw);
            return paysRaw;
          },
        );
        _paysDelivrance = found;
      }
      if (d.dateDelivrance != null) _dateDelivranceDocCtrl.text = d.dateDelivrance!;
      if (d.nomJeuneFille != null) _nomJeuneFilleCtrl.text = d.nomJeuneFille!;
      if (d.rectoImage != null) _docRecto = d.rectoImage;
      if (d.versoImage != null) _docVerso = d.versoImage;
      if (d.portrait != null) _photoClient = d.portrait;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _dateNaissCtrl.dispose();
    _lieuNaissCtrl.dispose();
    _professionCtrl.dispose();
    _telephoneCtrl.dispose();
    _numDocCtrl.dispose();
    _chambreCtrl.dispose();
    _dateEntreeCtrl.dispose();
    _dateSortiePrevueCtrl.dispose();
    _nomJeuneFilleCtrl.dispose();
    _dateDelivranceDocCtrl.dispose();
    _venantDeCtrl.dispose();
    _allantACtrl.dispose();
    _immatriculationCtrl.dispose();
    _villeResCtrl.dispose();
    _hotelCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkScanStatus() async {
    try {
      final localOcr = LocalOcrService();
      bool ready = localOcr.isInitialized;
      if (!ready) {
        ready = await localOcr.initialize();
      }
      
      if (mounted) {
        setState(() {
          _scanServiceReady = ready;
        });
      }
    } catch (e) {
      debugPrint("[EnregistrementScreen] Erreur lors de la vérification du statut local : $e");
      if (mounted) {
        setState(() {
          _scanServiceReady = false;
        });
      }
    }
  }


  Future<void> _chargerSejourExistant() async {
    setState(() => _loading = true);
    final id = int.tryParse(widget.sejourId!);
    if (id != null) {
      final s = await _sejourService.getSejourById(id);
      if (s != null && mounted) {
        setState(() {
          _nomCtrl.text = s.nomClient;
          _prenomCtrl.text = s.prenomClient;
          _dateNaissCtrl.text = s.dateNaissance;
          _lieuNaissCtrl.text = s.lieuNaissance;
          _professionCtrl.text = s.profession;
          _telephoneCtrl.text = s.contactTelephone;
          _numDocCtrl.text = s.numeroDocument;
          _chambreCtrl.text = s.numeroChambre;
          _nomJeuneFilleCtrl.text = s.client.nomJeuneFille ?? '';
          _dateDelivranceDocCtrl.text = s.client.dateDelivranceDoc ?? '';
          _paysDelivrance = s.client.paysDelivranceDoc ?? 'Burkina Faso';
          _sexe = s.client.sexe ?? 'HOMME';
          _paysResidence = s.client.paysResidence ?? 'Burkina Faso';
          _villeResCtrl.text = s.client.villeResidence ?? '';
          _venantDeCtrl.text = s.venantDe ?? '';
          _allantACtrl.text = s.allantA ?? '';
          _immatriculationCtrl.text = s.numeroImmatriculation ?? '';

          // Formattage de la date d'entrée
          if (s.dateEntree.isNotEmpty) {
            try {
              // Si c'est une date ISO, on prend les 16 premiers caractères
              _dateEntreeCtrl.text = s.dateEntree.length >= 16
                  ? s.dateEntree.substring(0, 16).replaceAll('T', ' ')
                  : s.dateEntree;
            } catch (_) {
              _dateEntreeCtrl.text = s.dateEntree;
            }
          }

          if (s.dateSortiePrevue != null && s.dateSortiePrevue!.isNotEmpty) {
            _dateSortiePrevueCtrl.text = s.dateSortiePrevue!.split('T')[0];
          }

          _nationalite = s.nationalite;
          _typeDoc = s.typeDocument;
          _motifSejour = s.motifSejour;
          _moyenTransport = s.moyenTransport ?? 'AUTRE';

          _photoUrl = s.photoClient;
          _rectoUrl = s.documentRecto;
          _versoUrl = s.documentVerso;
          _localUuid = s.identifiantUnique;
        });
      }
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _chargerDonnees() async {
    final prefs = await SharedPreferences.getInstance();
    UserModel? user = await _authService.getCurrentUser();

    // Si le nom de l'hôtel n'est pas en cache, le récupérer depuis l'API
    if (user != null && (user.hotelNom == null || user.hotelNom!.isEmpty)) {
      final profile = await _userService.getProfil();
      if (profile != null && profile.hotelNom != null && profile.hotelNom!.isNotEmpty) {
        user = profile;
        await prefs.setString('user_hotel_nom', profile.hotelNom!);
      }
    }

    setState(() {
      _user = user;
      _hotelId = prefs.getString('user_hotel_id') ?? '';
      _hotelCtrl.text = user?.hotelNom ?? 'Hôtel #$_hotelId';
    });

    final nats = await _sejourService.getNationalites();
    if (nats.isNotEmpty && mounted) {
      setState(() {
        _nationalites = nats.map((e) => e.toString()).toList();
      });
    }

    final pays = await _sejourService.getPays();
    if (pays.isNotEmpty && mounted) {
      setState(() {
        _paysList = pays.map((e) => e.toString()).toList();
        if (!_paysList.contains(_paysDelivrance)) {
          _paysDelivrance = _paysList.first;
        }
      });
    }
  }

  Future<void> _pickImage(String type) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.emerald600,
              ),
              title: const Text('Appareil photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: AppColors.emerald600,
              ),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() {
        if (type == 'recto') _docRecto = File(picked.path);
        if (type == 'verso') _docVerso = File(picked.path);
        if (type == 'photo') _photoClient = File(picked.path);
      });

      // Lancer le scan si c'est un document
      if (type == 'recto' || type == 'verso') {
        _lancerScan();
      }
    }
  }

  Future<void> _lancerScan() async {
    if (_docRecto == null) return;

    debugPrint("[EnregistrementScreen] _lancerScan lancé (Mode Local uniquement)...");
    if (mounted) {
      setState(() => _scanning = true);
    }

    Map<String, dynamic>? result;

    final localOcr = LocalOcrService();
    try {
      result = await localOcr.scanLocalDocument(
        recto: _docRecto!,
        verso: _docVerso,
      );
    } finally {
      localOcr.dispose();
    }

    debugPrint("[EnregistrementScreen] Résultat du scan reçu : $result");

    if (result != null && result['success'] == true && mounted) {
      final champs = result['champs'] as Map<String, dynamic>;
      debugPrint("[EnregistrementScreen] Extraction réussie. Remplissage des champs...");
      setState(() {
        // Helper function to update controller if it's currently empty and scanned value is not empty
        void updateIfEmpty(TextEditingController ctrl, String? newValue) {
          if (newValue != null && newValue.trim().isNotEmpty && ctrl.text.trim().isEmpty) {
            ctrl.text = newValue.trim();
          }
        }

        updateIfEmpty(_nomCtrl, champs['Nom']?.toString());
        updateIfEmpty(_prenomCtrl, champs['Prénoms']?.toString());
        updateIfEmpty(_dateNaissCtrl, champs['Date de naissance']?.toString());
        updateIfEmpty(_lieuNaissCtrl, champs['Lieu de naissance']?.toString());
        updateIfEmpty(_professionCtrl, champs['Profession']?.toString());
        updateIfEmpty(_numDocCtrl, champs['Numéro du document']?.toString());

        // Pays de résidence
        if (champs['Pays de résidence'] != null && champs['Pays de résidence'].toString().trim().isNotEmpty) {
          final paysRaw = champs['Pays de résidence'].toString().trim();
          final found = _paysList.firstWhere(
            (p) => p.toUpperCase() == paysRaw.toUpperCase(),
            orElse: () => _paysResidence,
          );
          _paysResidence = found;
        }

        // Ville de résidence
        updateIfEmpty(_villeResCtrl, champs['Ville de résidence']?.toString());

        // Sexe
        if (champs['Sexe'] != null) {
          final s = champs['Sexe'].toString().toUpperCase();
          if (s == 'FEMME' || s == 'F') {
            _sexe = 'FEMME';
          } else if (s == 'HOMME' || s == 'M') {
            _sexe = 'HOMME';
          }
        }

        // Nom de jeune fille
        final stringNomJeuneFille = champs['Nom de jeune fille']?.toString() ?? champs['nom_jeune_fille']?.toString();
        updateIfEmpty(_nomJeuneFilleCtrl, stringNomJeuneFille);

        // Date de délivrance
        final stringDateDelivrance = champs['Date de délivrance']?.toString() ?? champs['date_delivrance_doc']?.toString();
        updateIfEmpty(_dateDelivranceDocCtrl, stringDateDelivrance);

        // Nationalité
        if (champs['Nationalité'] != null && champs['Nationalité'].toString().trim().isNotEmpty) {
          final natRaw = champs['Nationalité'].toString().trim();
          // Tenter de trouver le match exact dans la liste (insensible à la casse)
          final found = _nationalites.firstWhere(
            (n) => n.toUpperCase() == natRaw.toUpperCase(),
            orElse: () => _nationalite, // Keep current nationality instead of resetting
          );
          _nationalite = found;
        }

        // Type de document
        if (champs['Type de document'] != null && champs['Type de document'].toString().trim().isNotEmpty) {
          final t = champs['Type de document'].toString().toUpperCase();
          if (t.contains('PASSPORT') || t.contains('PASSEPORT')) {
            _typeDoc = 'PASSEPORT';
          } else if (t.contains('CNI') ||
              t.contains('ID') ||
              t.contains('CARD')) {
            _typeDoc = 'CNI';
          }
        }

        // Pays de délivrance
        final paysRaw = champs['Pays de délivrance']?.toString() ?? champs['pays_delivrance_doc']?.toString();
        if (paysRaw != null && paysRaw.trim().isNotEmpty) {
          final found = _paysList.firstWhere(
            (p) => p.toUpperCase() == paysRaw.trim().toUpperCase(),
            orElse: () => _paysDelivrance, // Keep current issuing country instead of resetting
          );
          _paysDelivrance = found;
        }
      });

      // --- Récupération automatique du portrait ---
      if (result['portrait'] != null && _photoClient == null) {
        try {
          debugPrint("[EnregistrementScreen] Portrait trouvé dans les résultats, extraction...");
          final String portraitB64 = result['portrait'];
          final bytes = base64Decode(portraitB64);
          final tempDir = await getTemporaryDirectory();
          final portraitFile = File('${tempDir.path}/portrait_extracted.jpg');
          await portraitFile.writeAsBytes(bytes);

          if (mounted) {
            setState(() {
              _photoClient = portraitFile;
            });
            debugPrint("[EnregistrementScreen] Portrait extrait et affecté avec succès : ${portraitFile.path}");
          }
        } catch (e) {
          debugPrint("Erreur lors de la récupération du portrait : $e");
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Données du document extraites avec succès (Mode local)'),
            backgroundColor: AppColors.emerald600,
          ),
        );
      }
    } else {
      debugPrint("[EnregistrementScreen] Échec ou résultat vide de l'analyse.");
      if (mounted) {
        String msg = "Échec de l'analyse du document.";
        if (result != null && result['error'] == 'license_missing') {
          msg = result['message'] ?? "Licence Regula absente. Veuillez ajouter 'regula.license' dans le dossier assets/.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _scanning = false);
    }
  }

  Future<void> _choisirDate(TextEditingController ctrl) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.emerald600),
        ),
        child: child!,
      ),
    );
    if (d != null) {
      ctrl.text =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation des documents si création
    if (widget.sejourId == null) {
      if (_docRecto == null) {
        _showError('Document Recto obligatoire');
        return;
      }
      if (_docVerso == null) {
        _showError('Document Verso obligatoire');
        return;
      }
    }

    setState(() => _loading = true);

    final fields = {
      'nom_client': _nomCtrl.text.trim(),
      'prenom_client': _prenomCtrl.text.trim(),
      'date_naissance': _dateNaissCtrl.text,
      'lieu_naissance': _lieuNaissCtrl.text.trim(),
      'nationalite': _nationalite,
      'profession': _professionCtrl.text.trim(),
      'contact_telephone': _telephoneCtrl.text.trim(),
      'sexe': _sexe,
      'pays_residence': _paysResidence,
      'ville_residence': _villeResCtrl.text.trim(),
      'type_document': _typeDoc,
      'numero_document': _numDocCtrl.text.trim(),
      'numero_chambre': _chambreCtrl.text.trim(),
      'motif_sejour': _motifSejour,
      'nom_jeune_fille': _nomJeuneFilleCtrl.text.trim(),
      'date_delivrance_doc': _dateDelivranceDocCtrl.text,
      'pays_delivrance_doc': _paysDelivrance,
      'venant_de': _venantDeCtrl.text.trim(),
      'allant_a': _allantACtrl.text.trim(),
      'moyen_transport': _moyenTransport,
      'numero_immatriculation': _immatriculationCtrl.text.trim(),
      'hotel': _hotelId,
      'date_entree': _dateEntreeCtrl.text.isNotEmpty
          ? _dateEntreeCtrl.text.replaceAll(' ', 'T')
          : DateTime.now().toIso8601String(),
      'date_sortie_prevue': _dateSortiePrevueCtrl.text,
    };

    // DRF n'accepte pas toujours les chaînes vides ("") pour des dates ou des champs avec choices
    fields.removeWhere((key, value) => value.isEmpty);

    bool success;
    if (widget.sejourId != null) {
      success = await _sejourService.updateSejour(
        id: int.parse(widget.sejourId!),
        fields: fields,
        photoClient: _photoClient,
        documentRecto: _docRecto,
        documentVerso: _docVerso,
      );
    } else {
      success = await _sejourService.enregistrerSejour(
        fields: fields,
        photoClient: _photoClient,
        documentRecto: _docRecto,
        documentVerso: _docVerso,
      );
    }

    if (mounted) {
      setState(() => _loading = false);
      if (success) {
        final List<ConnectivityResult> connectivityResult = await Connectivity()
            .checkConnectivity();
        if (!mounted) return;
        final bool isOffline = connectivityResult.contains(
          ConnectivityResult.none,
        );

        UIUtils.showSuccessBanner(
          context,
          widget.sejourId != null ? 'Séjour mis à jour' : 'Client enregistré',
          isOffline: isOffline,
        );

        if (widget.sejourId != null) {
          Navigator.pop(context, true);
        } else {
          Navigator.pop(context, true);
        }
      } else {
        _showError(
          widget.sejourId != null
              ? 'Erreur lors de la modification'
              : 'Erreur lors de l\'enregistrement',
        );
      }
    }
  }

  void _showError(String msg) {
    UIUtils.showErrorBanner(context, msg);
  }

  Widget _buildStatusIndicator() {
    Color color;
    String label;
    if (_scanServiceReady == null) {
      color = AppColors.warning;
      label = 'Vérification...';
    } else if (_scanServiceReady == true) {
      color = const Color.fromARGB(255, 254, 255, 255);
      label = 'Scan actif';
    } else {
      color = AppColors.error;
      label = 'Scan inactif';
    }

    return Tooltip(
      message: label,
      child: Padding(
        padding: const EdgeInsets.only(right: 20.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.sejourId != null ? 'MODIFICATION' : 'ENREGISTRER SÉJOUR',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
        actions: [
          _buildStatusIndicator(),
        ],
      ),
      body: _loading && widget.sejourId != null
          ? const FormSkeleton()
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          num: '01',
                          title: 'Photos & Identité',
                        ),
                        const SizedBox(height: 16),
                        _photoGrid(),
                        const SizedBox(height: 28),
                        const SectionHeader(
                          num: '02',
                          title: 'Informations Personnelles',
                        ),
                        const SizedBox(height: 16),
                        _buildPersonalInfo(),
                        const SizedBox(height: 28),
                        const SectionHeader(
                          num: '03',
                          title: "Document d'identité",
                        ),
                        const SizedBox(height: 16),
                        _buildDocInfo(),
                        const SizedBox(height: 28),
                        const SectionHeader(
                          num: '04',
                          title: 'Détails du Séjour',
                        ),
                        const SizedBox(height: 16),
                        _buildStayInfo(),
                        const SizedBox(height: 32),
                        CustomButton(
                          label: widget.sejourId != null
                              ? "MODIFIER LE SÉJOUR"
                              : "ENREGISTRER LE CLIENT",
                          onPressed: _soumettre,
                          isLoading: _loading,
                          icon: Icons.save_rounded,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                if (_scanning)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            'ANALYSE DU DOCUMENT...',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              decoration: TextDecoration.none,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _photoGrid() {
    final String? role = _user?.role;
    final bool restrictMedia = role == 'AGENT_ACCUEIL' || role == 'GERANT_HOTEL';
    return Row(
      children: [
        Expanded(
          child: _uploadBox(
            'RECTO',
            _docRecto,
            _rectoUrl,
            () => _pickImage('recto'),
            Icons.article_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _uploadBox(
            'VERSO',
            _docVerso,
            _versoUrl,
            () => _pickImage('verso'),
            Icons.article_outlined,
          ),
        ),
        if (!restrictMedia) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _uploadBox(
              'CLIENT',
              _photoClient,
              _photoUrl,
              () => _pickImage('photo'),
              Icons.camera_alt_outlined,
            ),
          ),
        ],
      ],
    );
  }

  Widget _uploadBox(
    String label,
    File? file,
    String? imageUrl,
    VoidCallback onTap,
    IconData icon,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: (file != null || (imageUrl != null && imageUrl.isNotEmpty))
                  ? AppColors.emerald50
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    (file != null || (imageUrl != null && imageUrl.isNotEmpty))
                    ? AppColors.emerald600
                    : AppColors.slate200,
              ),
            ),
            child: file != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(file, fit: BoxFit.cover),
                  )
                : (imageUrl != null && imageUrl.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: DgpnImage(
                      url: imageUrl,
                      localUuid: _localUuid,
                      type: label == 'PHOTO CLIENT'
                          ? DgpnImageType.photo
                          : label == 'DOCUMENT RECTO'
                          ? DgpnImageType.recto
                          : DgpnImageType.verso,
                      fit: BoxFit.cover,
                      placeholderIcon: icon,
                    ),
                  )
                : Icon(icon, color: AppColors.slate400, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Column(
      children: [
        // Ligne 1 : NOM | PRÉNOM
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'NOM',
                controller: _nomCtrl,
                prefixIcon: Icons.person,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ\s-]')),
                ],
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'PRÉNOM',
                controller: _prenomCtrl,
                prefixIcon: Icons.person_outline,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ\s-]')),
                ],
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Ligne 2 : NOM DE JEUNE FILLE | DATE NAISSANCE
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'NOM DE JEUNE FILLE',
                controller: _nomJeuneFilleCtrl,
                prefixIcon: Icons.person_add_alt,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _choisirDate(_dateNaissCtrl),
                child: AbsorbPointer(
                  child: CustomTextField(
                    label: 'DATE NAISSANCE',
                    controller: _dateNaissCtrl,
                    prefixIcon: Icons.calendar_today,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Requis' : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Ligne 3 : LIEU NAISSANCE | NATIONALITÉ
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'LIEU NAISSANCE',
                controller: _lieuNaissCtrl,
                prefixIcon: Icons.location_on,
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dropdownField(
                'NATIONALITÉ',
                _nationalite,
                _nationalites,
                (v) => setState(() => _nationalite = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Ligne 4 : PROFESSION | TÉLÉPHONE
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'PROFESSION',
                controller: _professionCtrl,
                prefixIcon: Icons.work_outline,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ\s-]')),
                ],
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'TÉLÉPHONE',
                controller: _telephoneCtrl,
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Ligne 5 : SEXE | PAYS DE RÉSIDENCE
        Row(
          children: [
            Expanded(
              child: _dropdownField('SEXE', _sexe, [
                'HOMME',
                'FEMME',
              ], (v) => setState(() => _sexe = v!)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dropdownField(
                'PAYS DE RÉSIDENCE',
                _paysResidence,
                _paysList,
                (v) => setState(() => _paysResidence = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Ligne 6 : VILLE DE RÉSIDENCE (pleine largeur)
        CustomTextField(
          label: 'VILLE DE RÉSIDENCE',
          controller: _villeResCtrl,
          prefixIcon: Icons.location_city,
        ),
        const SizedBox(height: 12),

      ],
    );
  }

  Widget _buildDocInfo() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _dropdownField('TYPE DOCUMENT', _typeDoc, [
                'CNI',
                'PASSEPORT',
                'VISA',
                'AUTRE',
              ], (v) => setState(() => _typeDoc = v!)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'NUMÉRO DOCUMENT',
                controller: _numDocCtrl,
                prefixIcon: Icons.numbers,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                ],
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _choisirDate(_dateDelivranceDocCtrl),
                child: AbsorbPointer(
                  child: CustomTextField(
                    label: 'DATE DÉLIVRANCE',
                    controller: _dateDelivranceDocCtrl,
                    prefixIcon: Icons.calendar_month,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dropdownField(
                'PAYS DÉLIVRANCE',
                _paysDelivrance,
                _paysList,
                (v) => setState(() => _paysDelivrance = v!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStayInfo() {
    return Column(
      children: [
        // Ligne 1 : HÔTEL | DATE ENTRÉE
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'HÔTEL',
                controller: _hotelCtrl,
                prefixIcon: Icons.business,
                readOnly: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _choisirDate(_dateEntreeCtrl),
                child: AbsorbPointer(
                  child: CustomTextField(
                    label: 'DATE D\'ENTRÉE',
                    controller: _dateEntreeCtrl,
                    prefixIcon: Icons.calendar_today,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Ligne 2 : CHAMBRE N° | DATE SORTIE PRÉVUE
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'CHAMBRE N°',
                controller: _chambreCtrl,
                prefixIcon: Icons.hotel,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _choisirDate(_dateSortiePrevueCtrl),
                child: AbsorbPointer(
                  child: CustomTextField(
                    label: 'DATE DE SORTIE PRÉVUE',
                    controller: _dateSortiePrevueCtrl,
                    prefixIcon: Icons.calendar_today_outlined,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Ligne 2 : MOTIF SÉJOUR | PROVENANCE
        Row(
          children: [
            Expanded(
              child: _dropdownField('MOTIF SÉJOUR', _motifSejour, [
                'AFFAIRES',
                'TOURISME',
                'VISITE',
                'AUTRE',
              ], (v) => setState(() => _motifSejour = v!)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'PROVENANCE',
                controller: _venantDeCtrl,
                prefixIcon: Icons.flight_land,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Ligne 3 : DESTINATION | TRANSPORT
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'DESTINATION',
                controller: _allantACtrl,
                prefixIcon: Icons.flight_takeoff,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dropdownField(
                'TRANSPORT',
                _moyenTransport,
                ['AVION', 'TRAIN', 'VOITURE', 'CAR', 'AUTRE'],
                (v) => setState(() => _moyenTransport = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Ligne 4 : IMMATRICULATION (pleine largeur)
        CustomTextField(
          label: 'IMMATRICULATION',
          controller: _immatriculationCtrl,
          prefixIcon: Icons.numbers,
        ),
      ],
    );
  }

  Widget _dropdownField(
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: AppColors.slate500,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: options.contains(value) ? value : options.first,
          onChanged: onChanged,
          items: options
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.slate800,
                    ),
                  ),
                ),
              )
              .toList(),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.slate50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.slate300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.slate300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.emerald600,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
