import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/services/sejour_service.dart';

class EnregistrementScreen extends StatefulWidget {
  const EnregistrementScreen({super.key});
  @override
  State<EnregistrementScreen> createState() => _EnregistrementScreenState();
}

class _EnregistrementScreenState extends State<EnregistrementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sejourService = SejourService();
  bool _loading = false;

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
  final _provenanceCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();

  String _nationalite = 'Burkinabè';
  String _typeDoc = 'CNI';
  String _motifSejour = 'AFFAIRES';
  String _hotelId = '';

  File? _photoClient;
  File? _docRecto;
  File? _docVerso;

  List<String> _nationalites = ['Burkinabè'];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _dateEntreeCtrl.text = DateTime.now().toString().substring(0, 16);
    _chargerDonnees();
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
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() {
        if (type == 'recto') _docRecto = File(picked.path);
        if (type == 'verso') _docVerso = File(picked.path);
        if (type == 'photo') _photoClient = File(picked.path);
      });
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
    if (_docRecto == null) {
      _showError('Pièce d\'identité (Recto) requise');
      return;
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
      'provenance': _provenanceCtrl.text.trim(),
      'destination': _destinationCtrl.text.trim(),
      'hotel': _hotelId,
      'date_entree': DateTime.now().toIso8601String(),
    };

    final success = await _sejourService.enregistrerSejour(
      fields: fields,
      photoClient: _photoClient,
      documentRecto: _docRecto,
      documentVerso: _docVerso,
    );

    if (mounted) {
      setState(() => _loading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enregistrement réussi !'),
            backgroundColor: AppColors.emerald600,
          ),
        );
        context.go('/tableau');
      } else {
        _showError('Erreur lors de l\'enregistrement');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: Text(
          'NOUVEL ENREGISTREMENT',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(num: '01', title: 'Photos & Identité'),
              const SizedBox(height: 16),
              _buildPhotoGrid(),
              const SizedBox(height: 28),

              const SectionHeader(
                num: '02',
                title: 'Informations Personnelles',
              ),
              const SizedBox(height: 16),
              _buildPersonalInfo(),
              const SizedBox(height: 28),

              const SectionHeader(num: '03', title: "Document d'identité"),
              const SizedBox(height: 16),
              _buildDocInfo(),
              const SizedBox(height: 28),

              const SectionHeader(num: '04', title: 'Détails du Séjour'),
              const SizedBox(height: 16),
              _buildStayInfo(),
              const SizedBox(height: 32),

              CustomButton(
                label: "ENREGISTRER L'ENTRÉE",
                onPressed: _soumettre,
                isLoading: _loading,
                icon: Icons.save_rounded,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return Row(
      children: [
        Expanded(
          child: _uploadBox(
            'RECTO',
            _docRecto,
            () => _pickImage('recto'),
            Icons.article_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _uploadBox(
            'VERSO',
            _docVerso,
            () => _pickImage('verso'),
            Icons.article_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _uploadBox(
            'CLIENT',
            _photoClient,
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
              color: file != null ? AppColors.emerald50 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: file != null ? AppColors.emerald600 : AppColors.slate200,
              ),
            ),
            child: file != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(file, fit: BoxFit.cover),
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
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'PRÉNOM',
                controller: _prenomCtrl,
                prefixIcon: Icons.person_outline,
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
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'PROFESSION',
                controller: _professionCtrl,
                prefixIcon: Icons.work_outline,
              ),
            ),
          ],
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'PROVENANCE',
                controller: _provenanceCtrl,
                prefixIcon: Icons.flight_takeoff,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'DESTINATION',
                controller: _destinationCtrl,
                prefixIcon: Icons.flight_land,
              ),
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
          initialValue: options.contains(value) ? value : options.first,
          onChanged: onChanged,
          items: options
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
              .toList(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.slate200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.slate200),
            ),
          ),
        ),
      ],
    );
  }
}
