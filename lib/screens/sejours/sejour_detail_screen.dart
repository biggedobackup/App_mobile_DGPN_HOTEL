import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/skeleton.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/sejour_model.dart';
import '../../core/services/sejour_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/user_model.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/dgpn_image.dart';

class SejourDetailScreen extends StatefulWidget {
  final int sejourId;
  final bool scrollToCheckout;
  const SejourDetailScreen({super.key, required this.sejourId, this.scrollToCheckout = false});

  @override
  State<SejourDetailScreen> createState() => _SejourDetailScreenState();
}

class _SejourDetailScreenState extends State<SejourDetailScreen> {
  final _sejourService = SejourService();
  final _authService = AuthService();
  UserModel? _user;
  SejourModel? _sejour;
  bool _loading = true;
  final _obsCtrl = TextEditingController();
  bool _savingSortie = false;
  final _scrollController = ScrollController();
  final _checkoutKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final user = await _authService.getCurrentUser();
    final data = await _sejourService.getSejourById(widget.sejourId);
    if (mounted) {
      setState(() {
        _user = user;
        _sejour = data;
        _loading = false;
      });
      // Auto-scroll vers la section fin de séjour si demandé
      if (widget.scrollToCheckout) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = _checkoutKey.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(
              ctx,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: Text(
          'DÉTAIL DU SÉJOUR',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
      ),
      body: _loading
          ? _buildShimmerDetail()
          : _sejour == null
              ? _buildError()
              : _buildContent(),
    );
  }

  // ─── Shimmer ────────────────────────────────────────────────────────────────
  Widget _buildShimmerDetail() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Skeleton(height: 200, borderRadius: 24),
          SizedBox(height: 24),
          Skeleton(height: 300, borderRadius: 24),
          SizedBox(height: 24),
          Skeleton(height: 150, borderRadius: 24),
          SizedBox(height: 24),
          Skeleton(height: 120, borderRadius: 24),
        ],
      ),
    );
  }

  // ─── Error ───────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Séjour introuvable', style: GoogleFonts.inter(color: AppColors.slate500)),
        ],
      ),
    );
  }

  // ─── Main content ────────────────────────────────────────────────────────────
  Widget _buildContent() {
    final s = _sejour!;
    final bool isActif = s.statut == 'EN_SEJOUR';
    final String? role = _user?.role;
    final bool restrictMedia = role == 'AGENT_ACCUEIL' || role == 'GERANT_HOTEL';

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Titre / badge séjour ─────────────────────────────────────────
          _buildPageHeader(s, isActif),
          const SizedBox(height: 20),

          // ── Carte client (photo + nom) ───────────────────────────────────
          _buildClientCard(s, restrictMedia),
          const SizedBox(height: 16),

          // ── Identité client ──────────────────────────────────────────────
          _buildInfoSection('IDENTITÉ DU CLIENT', [
            _buildInfoRow(Icons.work, 'PROFESSION', s.profession),
            _buildInfoRow(Icons.phone, 'TÉLÉPHONE', s.contactTelephone),
            _buildInfoRow(Icons.flag, 'NATIONALITÉ', s.nationalite),
            _buildInfoRow(
              Icons.wc,
              'SEXE',
              s.client.sexe == 'HOMME'
                  ? 'Homme'
                  : s.client.sexe == 'FEMME'
                      ? 'Femme'
                      : '-',
            ),
            _buildInfoRow(Icons.cake, 'NAISSANCE', '${s.dateNaissance} à ${s.lieuNaissance}'),
            if (s.client.nomJeuneFille != null && s.client.nomJeuneFille!.isNotEmpty)
              _buildInfoRow(Icons.person, 'NOM JEUNE FILLE', s.client.nomJeuneFille!),
            _buildInfoRow(Icons.public, 'PAYS RÉSIDENCE', s.client.paysResidence ?? '-'),
            _buildInfoRow(Icons.location_city, 'VILLE RÉSIDENCE', s.client.villeResidence ?? '-'),
            if (s.client.adresseComplete != null && s.client.adresseComplete!.isNotEmpty)
              _buildInfoRow(Icons.location_on, 'ADRESSE', s.client.adresseComplete!),
          ]),
          const SizedBox(height: 16),

          // ── Pièce d'identité ─────────────────────────────────────────────
          _buildInfoSection('PIÈCE D\'IDENTITÉ', [
            _buildInfoRow(Icons.badge, 'TYPE', s.typeDocument),
            _buildInfoRow(Icons.numbers, 'NUMÉRO', s.numeroDocument),
            if (s.client.dateDelivranceDoc != null && s.client.dateDelivranceDoc!.isNotEmpty)
              _buildInfoRow(Icons.calendar_month, 'DÉLIVRANCE', s.client.dateDelivranceDoc!),
            if (s.client.paysDelivranceDoc != null && s.client.paysDelivranceDoc!.isNotEmpty)
              _buildInfoRow(Icons.public, 'PAYS DÉLIVRANCE', s.client.paysDelivranceDoc!),
            const SizedBox(height: 8),
            _buildDocumentScans(s),
          ]),
          const SizedBox(height: 16),

          // ── Hébergement ──────────────────────────────────────────────────
          _buildHebergementCard(s, isActif),
          const SizedBox(height: 16),

          // ── Traçabilité ─────────────────────────────────────────────────
          _buildInfoSection('TRAÇABILITÉ', [
            _buildInfoRow(Icons.person_add, 'ENREGISTRÉ PAR', s.agentEntreeNom ?? 'Inconnu'),
            _buildInfoRow(
              Icons.schedule,
              'DERNIÈRE MAJ',
              s.dateModification != null
                  ? DateTime.parse(s.dateModification!).toLocal().toString().split('.')[0]
                  : 'N/A',
            ),
            if (s.agentSortieNom != null)
              _buildInfoRow(Icons.person_remove, 'SORTIE VALIDÉE PAR', s.agentSortieNom!),
            if (s.observationsSortie != null && s.observationsSortie!.isNotEmpty)
              _buildInfoRow(Icons.comment, 'OBSERVATIONS', s.observationsSortie!),
          ]),

          const SizedBox(height: 32),

          // ── Section fin de séjour (tout en bas) ─────────────────────────
          if (isActif && (role == 'AGENT_ACCUEIL' || role == 'GERANT_HOTEL')) ...[
            SizedBox(key: _checkoutKey, width: double.infinity, child: _buildCheckoutSection(s)),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── En-tête page ────────────────────────────────────────────────────────────
  Widget _buildPageHeader(SejourModel s, bool isActif) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Détail du Séjour',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: AppColors.slate800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActif ? AppColors.emerald600 : AppColors.slate400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isActif
                        ? 'SÉJOUR ACTIF #${widget.sejourId}'
                        : 'SÉJOUR TERMINÉ #${widget.sejourId}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Carte client ────────────────────────────────────────────────────────────
  Widget _buildClientCard(SejourModel s, bool restrictMedia) {

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Photo client
          if (!restrictMedia)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: DgpnImage(
                url: s.photoClient,
                localUuid: s.identifiantUnique,
                type: DgpnImageType.photo,
                width: 96,
                height: 96,
                placeholderIcon: Icons.person,
              ),
            )
          else
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.person, size: 40, color: AppColors.slate400),
            ),

          const SizedBox(height: 16),

          // Nom complet
          Text(
            s.clientFullName.toUpperCase(),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: AppColors.slate800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          // Nom jeune fille
          if (s.client.nomJeuneFille != null && s.client.nomJeuneFille!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Née : ${s.client.nomJeuneFille}',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.slate400,
                letterSpacing: 0.8,
              ),
            ),
          ],

          const SizedBox(height: 6),

          // Nationalité
          Text(
            s.nationalite.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.emerald600,
              letterSpacing: 2,
            ),
          ),

        ],
      ),
    );
  }

  // ─── Carte Hébergement ───────────────────────────────────────────────────────
  Widget _buildHebergementCard(SejourModel s, bool isActif) {
    final int nuits = s.dureeSejoursJours;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête vert "ACTUELLEMENT PRÉSENT"
          if (isActif)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border(bottom: BorderSide(color: Color(0xFFD1FAE5))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.emerald600,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ACTUELLEMENT PRÉSENT',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.emerald700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre section
                Row(
                  children: [
                    const Icon(Icons.business, color: AppColors.emerald600, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Informations Hébergement',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppColors.slate800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Établissement + Chambre (côte à côte)
                Row(
                  children: [
                    Expanded(
                      child: _buildHebergInfoBlock(
                        'ÉTABLISSEMENT',
                        s.hotelDenomination ?? s.hotel.toString(),
                        icon: Icons.apartment,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildChambreChip(s.numeroChambre),
                  ],
                ),
                const SizedBox(height: 16),

                // Dates (arrivée + sortie prévue) en ligne
                Row(
                  children: [
                    Expanded(
                      child: _buildDateBlock(
                        'DATE D\'ARRIVÉE',
                        s.formattedDateArrivee,
                        Icons.login,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateBlock(
                        'SORTIE PRÉVUE',
                        s.formattedDateSortiePrevue,
                        Icons.event_note,
                      ),
                    ),
                  ],
                ),
                if (s.dateSortie != null && s.dateSortie!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDateBlock(
                    'DATE DE SORTIE',
                    s.formattedDateSortie,
                    Icons.logout,
                  ),
                ],
                const SizedBox(height: 16),

                // ── Nombre de nuitées ──────────────────────────────────────
                _buildNuiteesChip(nuits, isActif),

                const SizedBox(height: 16),

                // Transport / provenance si dispo
                if (s.venantDe != null && s.venantDe!.isNotEmpty)
                  _buildInfoRow(Icons.flight_land, 'PROVENANCE', s.venantDe!),
                if (s.allantA != null && s.allantA!.isNotEmpty)
                  _buildInfoRow(Icons.flight_takeoff, 'DESTINATION', s.allantA!),
                if (s.moyenTransport != null && s.moyenTransport!.isNotEmpty)
                  _buildInfoRow(Icons.directions_car, 'TRANSPORT', s.moyenTransport!),
                if (s.numeroImmatriculation != null && s.numeroImmatriculation!.isNotEmpty)
                  _buildInfoRow(Icons.numbers, 'IMMATRICULATION', s.numeroImmatriculation!),

                // Motif
                const SizedBox(height: 4),
                _buildMotifBlock(s.motifSejour),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHebergInfoBlock(String label, String value, {required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.slate400,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '-' : value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppColors.slate700,
          ),
        ),
      ],
    );
  }

  Widget _buildChambreChip(String numero) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD1FAE5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hotel, color: AppColors.emerald600, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CHAMBRE',
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: AppColors.emerald600,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                numero,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.emerald700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateBlock(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: AppColors.slate400,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: AppColors.emerald600, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Nuitées ──────────────────────────────────────────────────────────────────
  Widget _buildNuiteesChip(int nuits, bool isActif) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.nights_stay_rounded, color: AppColors.emerald600, size: 28),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NOMBRE DE NUITÉES',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppColors.emerald600,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '$nuits nuitée${nuits > 1 ? 's' : ''}',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.emerald700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isActif)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'En cours',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.emerald600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMotifBlock(String motif) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MOTIF DU SÉJOUR',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: AppColors.slate400,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: AppColors.emerald600, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '"$motif"',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Section générique ───────────────────────────────────────────────────────
  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.emerald600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: AppColors.slate400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: AppColors.slate500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate400,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'N/A' : value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Scans document ──────────────────────────────────────────────────────────
  Widget _buildDocumentScans(SejourModel s) {
    final String? role = _user?.role;
    final bool restrictMedia = role == 'AGENT_ACCUEIL' || role == 'GERANT_HOTEL';
    if (restrictMedia) return const SizedBox.shrink();

    if (s.documentRecto == null && s.documentVerso == null) return const SizedBox.shrink();

    return Row(
      children: [
        if (s.documentRecto != null)
          Expanded(child: _buildImageThumbnail('RECTO', s.documentRecto!, s)),
        if (s.documentRecto != null && s.documentVerso != null) const SizedBox(width: 12),
        if (s.documentVerso != null)
          Expanded(child: _buildImageThumbnail('VERSO', s.documentVerso!, s)),
      ],
    );
  }

  Widget _buildImageThumbnail(String label, String url, SejourModel s) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(url, label),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.slate400),
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: DgpnImage(
                    url: url,
                    localUuid: s.identifiantUnique,
                    type: label == 'RECTO' ? DgpnImageType.recto : DgpnImageType.verso,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          body: PhotoView(
            imageProvider: CachedNetworkImageProvider(url),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.0,
          ),
        ),
      ),
    );
  }

  // ─── Fin de séjour ───────────────────────────────────────────────────────────
  Widget _buildCheckoutSection(SejourModel s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.logout, color: AppColors.error, size: 22),
              const SizedBox(width: 8),
              Text(
                'FIN DE SÉJOUR',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.2,
                  color: AppColors.slate800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'OBSERVATIONS DE SORTIE (OPTIONNEL)',
            controller: _obsCtrl,
            maxLines: 3,
            hint: 'Ex: RAS, départ anticipé, bagages oubliés...',
          ),
          const SizedBox(height: 20),
          CustomButton(
            label: 'CLÔTURER LE SÉJOUR & ARCHIVER',
            color: AppColors.error,
            isLoading: _savingSortie,
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('ENREGISTRER LA SORTIE'),
                  content: const Text('Voulez-vous vraiment enregistrer la sortie de ce client ?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ANNULER')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('VALIDER', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
              if (confirm != true) return;

              setState(() => _savingSortie = true);
              final success = await _sejourService.enregistrerSortie(
                s.id!,
                DateTime.now().toIso8601String(),
                _obsCtrl.text,
              );
              if (!mounted) return;
              setState(() => _savingSortie = false);
              if (success) {
                UIUtils.showSuccessBanner(context, 'Sortie enregistrée avec succès !');
                context.go('/sejour-terminer');
              } else {
                UIUtils.showErrorBanner(context, 'Une erreur est survenue lors de l\'enregistrement de la sortie.');
              }
            },
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'ATTENTION : CETTE ACTION EST IRRÉVERSIBLE. LE SÉJOUR SERA DÉPLACÉ VERS L\'HISTORIQUE.\nAGENT RESPONSABLE : ${s.agentEntreeNom ?? "Inconnu"}',
              style: GoogleFonts.inter(
                fontSize: 9,
                color: AppColors.slate400,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
