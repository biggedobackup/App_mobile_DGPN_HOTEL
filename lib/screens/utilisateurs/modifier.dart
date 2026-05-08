import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/utilisateur_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/user_model.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/skeleton.dart';

class UtilisateurModifierScreen extends StatefulWidget {
  final int userId;
  const UtilisateurModifierScreen({super.key, required this.userId});
  @override
  State<UtilisateurModifierScreen> createState() => _UtilisateurModifierScreenState();
}

class _UtilisateurModifierScreenState extends State<UtilisateurModifierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = UtilisateurService();
  final _auth = AuthService();

  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();

  String _role = 'AGENT_ACCUEIL';
  bool _statut = true;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  UserModel? _user;
  String? _currentUserRole;
  int? _currentUserId;

  static const List<Map<String, String>> _roles = [
    {'value': 'AGENT_ACCUEIL', 'label': 'Agent d\'Accueil'},
    {'value': 'GERANT_HOTEL', 'label': 'Gérant d\'Hôtel'},
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final me = await _auth.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUserRole = me?.role;
        _currentUserId = me?.id;
      });
    }
    await _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = await _service.getUtilisateurById(widget.userId);
      if (user != null && mounted) {
        setState(() {
          _user = user;
          _nomCtrl.text = user.nom;
          _prenomCtrl.text = user.prenom;
          _telCtrl.text = user.telephone ?? '';
          _role = user.role;
          _statut = user.isActif ?? true;
          _loading = false;
        });
      } else {
        if (mounted) setState(() { _error = 'Utilisateur introuvable'; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Erreur de chargement'; _loading = false; });
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose(); _prenomCtrl.dispose(); _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    
    final Map<String, dynamic> payload = {
      'nom': _nomCtrl.text.trim(),
      'prenom': _prenomCtrl.text.trim(),
      'telephone': _telCtrl.text.trim(),
      'role': _role,
      'statut': _statut,
    };

    // On s'assure d'inclure l'hôtel pour les agents (obligatoire dans le serializer)
    if (_user?.hotelId != null) {
      payload['hotel'] = _user!.hotelId;
    }

    final ok = await _service.updateUtilisateur(widget.userId, payload);

    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: AppColors.emerald600,
        ));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erreur lors de la mise à jour'),
          backgroundColor: AppColors.error,
        ));
        setState(() => _saving = false);
      }
    }
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
        title: Text('MODIFIER L\'UTILISATEUR',
            style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5, color: AppColors.slate800)),
      ),
      body: _loading
          ? const FormSkeleton()
          : _error != null
              ? _buildError()
              : _buildForm(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: AppColors.error.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(_error!, style: GoogleFonts.inter(color: AppColors.slate500)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _charger,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald600),
              child: Text('RÉESSAYER', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final bool estMoi = _user?.id == _currentUserId;
    final bool roleBloque = estMoi && _role == 'GERANT_HOTEL';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bandeau identification
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.slate800,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.emerald600,
                    child: Text(_user?.initials ?? '?',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_user?.fullName.toUpperCase() ?? '',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13)),
                        Text(_user?.email ?? '',
                            style: GoogleFonts.inter(color: AppColors.slate400, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 01 — Infos
            _buildSectionHeader('01', 'Informations personnelles', AppColors.emerald600, const Color(0xFFD1FAE5)),
            const SizedBox(height: 14),
            _buildCard([
              CustomTextField(label: 'NOM *', controller: _nomCtrl, prefixIcon: Icons.person_outline, hint: 'Ex: Traoré'),
              const SizedBox(height: 12),
              CustomTextField(label: 'PRÉNOM *', controller: _prenomCtrl, prefixIcon: Icons.person_outline, hint: 'Ex: Amadou'),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'TÉLÉPHONE', controller: _telCtrl,
                prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone, hint: '+226 70 XX XX XX',
              ),
            ]),

            const SizedBox(height: 20),

            // Section 02 — Rôle & Statut
            _buildSectionHeader('02', 'Rôle & Statut', const Color(0xFF3B82F6), const Color(0xFFDBEAFE)),
            const SizedBox(height: 14),
            _buildCard([
              Text('RÔLE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.slate500, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _role,
                onChanged: roleBloque ? null : (v) => setState(() => _role = v!),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.shield_outlined, color: AppColors.slate400, size: 20),
                  filled: true,
                  fillColor: roleBloque ? AppColors.slate100 : AppColors.slate50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.emerald600)),
                ),
                items: _roles
                  .where((r) {
                    if (_currentUserRole == 'GERANT_HOTEL') return r['value'] == 'AGENT_ACCUEIL';
                    return true;
                  })
                  .map((r) => DropdownMenuItem(
                    value: r['value'],
                    child: Text(r['label']!, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                  )).toList(),
              ),
              if (roleBloque) ...[
                const SizedBox(height: 6),
                Text('Vous ne pouvez pas modifier votre propre rôle de Gérant.',
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.slate400, fontStyle: FontStyle.italic)),
              ],

              const SizedBox(height: 16),

              // Statut toggle
              if (!estMoi) ...[
                const Divider(color: AppColors.slate100),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('STATUT DU COMPTE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.slate500, letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Text(_statut ? 'Compte actif' : 'Compte désactivé',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
                                color: _statut ? AppColors.emerald600 : AppColors.error)),
                      ],
                    ),
                    Switch(
                      value: _statut,
                      onChanged: (v) => setState(() => _statut = v),
                      activeThumbColor: AppColors.emerald600,
                    ),
                  ],
                ),
              ],
            ]),

            const SizedBox(height: 28),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.slate200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('ANNULER', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.slate500)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(_saving ? 'ENREGISTREMENT...' : 'ENREGISTRER',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    );
  }

  Widget _buildSectionHeader(String num, String title, Color color, Color bg) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(num, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: color))),
        ),
        const SizedBox(width: 10),
        Text(title.toUpperCase(),
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.slate700, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}
