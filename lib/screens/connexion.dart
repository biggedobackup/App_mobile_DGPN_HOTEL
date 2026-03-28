import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';
import '../core/services/auth_service.dart';
import '../core/widgets/custom_text_field.dart';
import '../core/widgets/custom_button.dart';

class ConnexionScreen extends StatefulWidget {
  const ConnexionScreen({super.key});
  @override
  State<ConnexionScreen> createState() => _ConnexionScreenState();
}

class _ConnexionScreenState extends State<ConnexionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailOubliCtrl = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  bool _afficherMdp = false;
  bool _resterConnecte = false;
  String _erreur = '';
  bool _sessionExpiree = false;

  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = GoRouterState.of(context).extra;
      if (args is Map && args['session'] == 'expired') {
        setState(() {
          _sessionExpiree = true;
          _erreur = 'Votre session a expiré. Veuillez vous reconnecter.';
        });
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailOubliCtrl.dispose();
    super.dispose();
  }

  Future<void> _gererConnexion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _erreur = '';
    });

    final res = await _auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);

    if (!mounted) return;

    if (res['success']) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rester_connecte', _resterConnecte);
      if (mounted) context.go('/tableau');
    } else {
      setState(() {
        _erreur = res['error'];
        _loading = false;
      });
    }
  }

  void _ouvrirModalOubli() {
    _emailOubliCtrl.clear();
    String message = '';

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MOT DE PASSE OUBLIÉ',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.slate800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.slate400),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message.isEmpty
                      ? 'Entrez votre email pour recevoir un lien de réinitialisation.'
                      : message,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: message.isEmpty
                        ? AppColors.slate400
                        : AppColors.emerald600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'EMAIL',
                  controller: _emailOubliCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline,
                  hint: 'votre@email.com',
                ),
                const SizedBox(height: 20),
                CustomButton(
                  label: 'ENVOYER LE LIEN',
                  onPressed: () async {
                    setModalState(() => message = 'Si cet email existe, un lien a été envoyé.');
                    await Future.delayed(const Duration(seconds: 2));
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.emerald900, AppColors.emerald800, AppColors.emerald700],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emerald600.withValues(alpha: 0.3),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emerald800.withValues(alpha: 0.4),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _animCtrl,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.emerald50,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Image.asset(
                                        'assets/images/logo.png',
                                        height: 70,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, _, _) =>
                                            const Icon(
                                              Icons.hotel,
                                              size: 50,
                                              color: AppColors.emerald600,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'ACCÈS PORTAIL HOTEL',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.slate800,
                                        letterSpacing: 0.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Authentification sécurisée requise',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.slate400,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),

                              if (_erreur.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _sessionExpiree
                                        ? const Color(0xFFFFFBEB)
                                        : const Color(0xFFFFF1F2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _sessionExpiree
                                          ? const Color(0xFFFDE68A)
                                          : const Color(0xFFFFCDD2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _sessionExpiree
                                            ? Icons.access_time
                                            : Icons.error_outline,
                                        size: 16,
                                        color: _sessionExpiree
                                            ? AppColors.warning
                                            : AppColors.error,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _erreur,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: _sessionExpiree
                                                ? AppColors.warning
                                                : AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              CustomTextField(
                                label: 'EMAIL PROFESSIONNEL',
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.mail_outline,
                                hint: 'admin@hotel.com',
                                validator: (v) => v == null || v.isEmpty ? 'Email requis' : null,
                              ),
                              const SizedBox(height: 18),

                              CustomTextField(
                                label: 'MOT DE PASSE',
                                controller: _passwordCtrl,
                                obscureText: !_afficherMdp,
                                prefixIcon: Icons.lock_outline,
                                hint: '••••••••',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _afficherMdp
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.slate400,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _afficherMdp = !_afficherMdp,
                                  ),
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Mot de passe requis' : null,
                              ),
                              const SizedBox(height: 16),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          value: _resterConnecte,
                                          onChanged: (v) => setState(
                                            () => _resterConnecte = v!,
                                          ),
                                          activeColor: AppColors.emerald600,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          side: const BorderSide(
                                            color: AppColors.slate300,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Rester connecté',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.slate500,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: _ouvrirModalOubli,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Text(
                                      'OUBLIÉ ?',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.emerald600,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              CustomButton(
                                label: 'SE CONNECTER',
                                onPressed: _gererConnexion,
                                isLoading: _loading,
                                icon: Icons.chevron_right,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
