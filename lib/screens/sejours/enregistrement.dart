import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/api_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/services/sejour_service.dart';
import '../../core/utils/ui_utils.dart';


class EnregistrementScreen extends StatefulWidget {
  final String? sejourId;
  const EnregistrementScreen({super.key, this.sejourId});
  @override
  State<EnregistrementScreen> createState() => _EnregistrementScreenState();
}

class _EnregistrementScreenState extends State<EnregistrementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sejourService = SejourService();
  bool _loading = false;
  bool _scanning = false;

  // Form Controllers
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _dateNaissCtrl = TextEditingController();
  final _lieuNaissCtrl = TextEditingController();
  final _professionCtrl = TextEditingController();
  final _lieuResCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _numDocCtrl = TextEditingController();
  final _chambreCtrl = TextEditingController();
  final _dateEntreeCtrl = TextEditingController();

  String _nationalite = 'Burkinabè';
  String _typeDoc = 'CNI';
  String _motifSejour = 'AFFAIRES';
  String _hotelId = '';

  File? _photoClient;
  File? _docRecto;
  File? _docVerso;

  String? _photoUrl;
  String? _rectoUrl;
  String? _versoUrl;

  List<String> _nationalites = ['Burkinabè'];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _dateEntreeCtrl.text = DateTime.now().toString().substring(0, 16);
    _chargerDonnees();
    if (widget.sejourId != null) {
      _chargerSejourExistant();
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
          _lieuResCtrl.text = s.lieuResidence;
          _telephoneCtrl.text = s.contactTelephone;
          _numDocCtrl.text = s.numeroDocument;
          _chambreCtrl.text = s.numeroChambre;
          
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
          
          _nationalite = s.nationalite;
          _typeDoc = s.typeDocument;
          _motifSejour = s.motifSejour;

          _photoUrl = s.photoClient;
          _rectoUrl = s.documentRecto;
          _versoUrl = s.documentVerso;
        });
      }
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _chargerDonnees() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hotelId = prefs.getString('user_hotel_id') ?? '';
    });

    final nats = await _sejourService.getNationalites();
    if (nats.isNotEmpty && mounted) {
      setState(() {
        _nationalites = nats.map((e) => e.toString()).toList();
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
    
    if (mounted) {
      setState(() => _scanning = true);
    }

    // --- Vérification de la connexion ---
    final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      // Hors-ligne : on arrête ici silencieusement
      if (mounted) {
        setState(() => _scanning = false);
      }
      return;
    }

    final result = await _sejourService.scanDocument(
      recto: _docRecto!,
      verso: _docVerso,
    );

    if (result != null && result['success'] == true && mounted) {
      final champs = result['champs'] as Map<String, dynamic>;
      setState(() {
        if (champs['Nom'] != null) _nomCtrl.text = champs['Nom'].toString();
        if (champs['Prénoms'] != null) _prenomCtrl.text = champs['Prénoms'].toString();
        if (champs['Date de naissance'] != null) _dateNaissCtrl.text = champs['Date de naissance'].toString();
        if (champs['Lieu de naissance'] != null) _lieuNaissCtrl.text = champs['Lieu de naissance'].toString();
        if (champs['Profession'] != null) _professionCtrl.text = champs['Profession'].toString();
        if (champs['Numéro du document'] != null) _numDocCtrl.text = champs['Numéro du document'].toString();
        if (champs['Nationalité'] != null) {
           final natRaw = champs['Nationalité'].toString();
           // Tenter de trouver le match exact dans la liste (insensible à la casse)
           final found = _nationalites.firstWhere(
             (n) => n.toUpperCase() == natRaw.toUpperCase(),
             orElse: () => _nationalites.first,
           );
           _nationalite = found;
        }
        if (champs['Type de document'] != null) {
          final t = champs['Type de document'].toString().toUpperCase();
          if (t.contains('PASSPORT') || t.contains('PASSEPORT')) {
            _typeDoc = 'PASSEPORT';
          } else if (t.contains('CNI') || t.contains('ID') || t.contains('CARD')) {
            _typeDoc = 'CNI';
          }
        }
        if (champs['Pays de résidence'] != null) {
          _lieuResCtrl.text = champs['Pays de résidence'].toString();
        }
      });

      // --- Récupération automatique du portrait ---
      if (result['portrait'] != null && _photoClient == null) {
        try {
          final String portraitB64 = result['portrait'];
          final bytes = base64Decode(portraitB64);
          final tempDir = await getTemporaryDirectory();
          final portraitFile = File('${tempDir.path}/portrait_extracted.jpg');
          await portraitFile.writeAsBytes(bytes);
          
          if (mounted) {
            setState(() {
              _photoClient = portraitFile;
            });
          }
        } catch (e) {
          debugPrint("Erreur lors de la récupération du portrait : $e");
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Données du document extraites avec succès'),
            backgroundColor: AppColors.emerald600,
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
      'lieu_residence': _lieuResCtrl.text.trim(),
      'type_document': _typeDoc,
      'numero_document': _numDocCtrl.text.trim(),
      'numero_chambre': _chambreCtrl.text.trim(),
      'motif_sejour': _motifSejour,
      'hotel': _hotelId,
      'date_entree': _dateEntreeCtrl.text.isNotEmpty 
          ? _dateEntreeCtrl.text.replaceAll(' ', 'T') 
          : DateTime.now().toIso8601String(),
    };


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
        final List<ConnectivityResult> connectivityResult =
            await Connectivity().checkConnectivity();
        final bool isOffline =
            connectivityResult.contains(ConnectivityResult.none);

        UIUtils.showSuccessBanner(
          context,
          widget.sejourId != null ? 'Séjour mis à jour' : 'Client enregistré',
          isOffline: isOffline,
        );


        if (widget.sejourId != null) {
          Navigator.pop(context, true);
        } else {
          context.go('/tableau');
        }
      }
 else {
        _showError(widget.sejourId != null ? 'Erreur lors de la modification' : 'Erreur lors de l\'enregistrement');
      }
    }
  }

  void _showError(String msg) {
    UIUtils.showErrorBanner(context, msg);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.sejourId != null ? 'MODIFICATION' : 'ENREGISTREMENT',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
      ),
      body: _loading && widget.sejourId != null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.emerald600),
            )
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
                              : "ENREGISTRER L'ENTRÉE",
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
                color: (file != null || (imageUrl != null && imageUrl.isNotEmpty)) 
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
                        child: CachedNetworkImage(
                          imageUrl: imageUrl.startsWith('http') 
                              ? imageUrl 
                              : '${ApiConfig.baseUrl}$imageUrl',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => Icon(icon, color: AppColors.slate400, size: 28),
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
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _choisirDate(_dateNaissCtrl),
                child: AbsorbPointer(
                  child: CustomTextField(
                    label: 'DATE NAISSANCE',
                    controller: _dateNaissCtrl,
                    prefixIcon: Icons.calendar_today,
                    validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                  ),

                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'LIEU NAISSANCE',
                controller: _lieuNaissCtrl,
                prefixIcon: Icons.location_on,
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),

            ),
          ],
        ),
        const SizedBox(height: 12),
        _dropdownField(
          'NATIONALITÉ',
          _nationalite,
          _nationalites,
          (v) => setState(() => _nationalite = v!),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
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
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'PROFESSION',
                controller: _professionCtrl,
                prefixIcon: Icons.work_outline,
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),

            ),
          ],
        ),
        const SizedBox(height: 12),
        CustomTextField(
          label: 'LIEU DE RÉSIDENCE',
          controller: _lieuResCtrl,
          prefixIcon: Icons.home_work_outlined,
          hint: 'Quartier, Ville',
          validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
        ),

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
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
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
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'CHAMBRE N°',
                controller: _chambreCtrl,
                prefixIcon: Icons.hotel,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),


            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dropdownField('MOTIF SÉJOUR', _motifSejour, [
                'AFFAIRES',
                'TOURISME',
                'VISITE',
                'AUTRE',
              ], (v) => setState(() => _motifSejour = v!)),
            ),
          ],
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
          value: options.contains(value) ? value : options.first,
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
              borderSide: const BorderSide(color: AppColors.emerald600, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
