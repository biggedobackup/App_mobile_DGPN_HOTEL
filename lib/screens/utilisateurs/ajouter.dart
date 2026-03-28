import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/utilisateur_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/custom_text_field.dart';

class UtilisateurAjouterScreen extends StatefulWidget {
  const UtilisateurAjouterScreen({super.key});
  @override
  State<UtilisateurAjouterScreen> createState() =>
      _UtilisateurAjouterScreenState();
}

class _UtilisateurAjouterScreenState extends State<UtilisateurAjouterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = UtilisateurService();
  final _auth = AuthService();

  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _pwdConfirmCtrl = TextEditingController();

  String _role = 'AGENT_ACCUEIL';
  bool _loading = false;
  bool _showPwd = false;
  bool _showPwdConfirm = false;
  String? _currentUserRole;

  static const List<Map<String, String>> _roles = [
    {'value': 'AGENT_ACCUEIL', 'label': 'Agent d\'Accueil'},
    {'value': 'GERANT_HOTEL', 'label': 'Gérant d\'Hôtel'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final user = await _auth.getCurrentUser();
    if (mounted) setState(() => _currentUserRole = user?.role);
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _pwdCtrl.dispose();
    _pwdConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pwdCtrl.text != _pwdConfirmCtrl.text) {
      _showSnack('Les mots de passe ne correspondent pas', isError: true);
      return;
    }
    if (_pwdCtrl.text.length < 8) {
      _showSnack(
        'Le mot de passe doit contenir au moins 8 caractères',
        isError: true,
      );
      return;
    }

    setState(() => _loading = true);

    // On récupère les infos de l'utilisateur actuel (le gérant)
    final currentUser = await _auth.getCurrentUser();

    final Map<String, dynamic> payload = {
      'nom': _nomCtrl.text.trim(),
      'prenom': _prenomCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'telephone': _telCtrl.text.trim(),
      'role': _role,
      'password': _pwdCtrl.text,
      'password_confirm': _pwdConfirmCtrl.text,
    };

    // Si c'est un gérant qui crée, on hérite de son hôtel et sa localisation
    if (currentUser != null && currentUser.role == 'GERANT_HOTEL') {
      if (currentUser.hotelId != null) payload['hotel'] = currentUser.hotelId;
    }

    // DEBUG: On affiche ce qu'on envoie
    // ignore: avoid_print
    print('[DEBUG] Payload creation: $payload');

    final result = await _service.createUtilisateurWithDetail(payload);

    if (mounted) {
      if (result['success']) {
        _showSnack('Utilisateur créé avec succès !');
        Navigator.pop(context);
      } else {
        final String error = result['error'] ?? 'Erreur lors de la création';

        // On affiche un dialogue pour que l'erreur soit bien visible (ex: email invalide)
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              'ERREUR DE SAISIE',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
                color: AppColors.error,
                fontSize: 13,
              ),
            ),
            content: Text(error, style: GoogleFonts.inter(fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CORRIGER'),
              ),
            ],
          ),
        );

        setState(() => _loading = false);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.emerald600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.slate700),
        title: Text(
          'AJOUTER UN UTILISATEUR',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1.5,
            color: AppColors.slate800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 01 — Infos personnelles
              _buildSectionHeader(
                '01',
                'Informations personnelles',
                AppColors.emerald600,
                const Color(0xFFD1FAE5),
              ),
              const SizedBox(height: 14),
              _buildCard([
                CustomTextField(
                  label: 'NOM *',
                  controller: _nomCtrl,
                  prefixIcon: Icons.person_outline,
                  hint: 'Ex: Traoré',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'PRÉNOM *',
                  controller: _prenomCtrl,
                  prefixIcon: Icons.person_outline,
                  hint: 'Ex: Amadou',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'EMAIL *',
                  controller: _emailCtrl,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  hint: 'amadou@hotel.bf',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'TÉLÉPHONE',
                  controller: _telCtrl,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  hint: '+226 70 XX XX XX',
                ),
              ]),

              const SizedBox(height: 20),

              // Section 02 — Affectation
              _buildSectionHeader(
                '02',
                'Affectation & Rôle',
                const Color(0xFF3B82F6),
                const Color(0xFFDBEAFE),
              ),
              const SizedBox(height: 14),
              _buildCard([
                Text(
                  'RÔLE *',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.slate500,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  onChanged: (v) => setState(() => _role = v!),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.slate400,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: AppColors.slate50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.slate200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.slate200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.emerald600),
                    ),
                  ),
                  items: _roles
                      .where((r) {
                        if (_currentUserRole == 'GERANT_HOTEL') {
                          return r['value'] == 'AGENT_ACCUEIL';
                        }
                        return true;
                      })
                      .map(
                        (r) => DropdownMenuItem(
                          value: r['value'],
                          child: Text(
                            r['label']!,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ]),

              const SizedBox(height: 20),

              // Section 03 — Sécurité
              _buildSectionHeader(
                '03',
                'Sécurité',
                AppColors.error.withValues(alpha: 0.9),
                const Color(0xFFFEE2E2),
              ),
              const SizedBox(height: 14),
              _buildCard([
                _buildPwdField(
                  label: 'MOT DE PASSE *',
                  controller: _pwdCtrl,
                  show: _showPwd,
                  onToggle: () => setState(() => _showPwd = !_showPwd),
                ),
                const SizedBox(height: 12),
                _buildPwdField(
                  label: 'CONFIRMER MOT DE PASSE *',
                  controller: _pwdConfirmCtrl,
                  show: _showPwdConfirm,
                  onToggle: () =>
                      setState(() => _showPwdConfirm = !_showPwdConfirm),
                ),
                const SizedBox(height: 8),
                Text(
                  'Minimum 8 caractères',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.slate400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ]),

              const SizedBox(height: 28),

              // Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.slate200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'ANNULER',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: AppColors.slate500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(
                        _loading ? 'ENREGISTREMENT...' : 'CRÉER LE COMPTE',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                        shadowColor: AppColors.emerald600.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String num, String title, Color color, Color bg) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              num,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: AppColors.slate700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildPwdField({
    required String label,
    required TextEditingController controller,
    required bool show,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppColors.slate500,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !show,
          style: GoogleFonts.inter(fontSize: 14),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: GoogleFonts.inter(color: AppColors.slate300),
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: AppColors.slate400,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                show
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.slate400,
                size: 18,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: AppColors.slate50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.slate200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.slate200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.emerald600),
            ),
          ),
        ),
      ],
    );
  }
}
