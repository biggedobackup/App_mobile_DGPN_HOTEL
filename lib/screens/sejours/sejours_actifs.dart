import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/sejour_service.dart';
import '../../core/models/sejour_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/user_model.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/utils/debouncer.dart';
import '../../core/widgets/dgpn_image.dart';


class SejoursActifsScreen extends StatefulWidget {
  const SejoursActifsScreen({super.key});

  @override
  State<SejoursActifsScreen> createState() => _SejoursActifsScreenState();
}

class _SejoursActifsScreenState extends State<SejoursActifsScreen> {
  final _sejourService = SejourService();
  final _authService = AuthService();
  UserModel? _user;
  final _searchCtrl = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 500);
  final _scrollController = ScrollController();
  
  DateTime? _dateDebut;
  DateTime? _dateFin;

  List<SejourModel> _sejours = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _currentPage = 1;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _charger();
    _searchCtrl.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onSearchChanged() {
    _debouncer.run(() {
      _charger();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_loading && !_loadingMore && _sejours.length < _totalCount) {
        _chargerPlus();
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _currentPage = 1;
      _sejours = [];
    });
    
    final user = await _authService.getCurrentUser();
    final data = await _sejourService.getSejoursActifs(
      page: _currentPage,
      search: _searchCtrl.text,
      dateDebut: _dateDebut?.toIso8601String().split('T')[0],
      dateFin: _dateFin?.toIso8601String().split('T')[0],
    );
    
    if (mounted) {
      setState(() {
        _user = user;
        _sejours = List<SejourModel>.from(data['results'] ?? []);

        _totalCount = data['count'] as int;
        _loading = false;
      });
    }
  }

  Future<void> _chargerPlus() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    
    _currentPage++;
    final data = await _sejourService.getSejoursActifs(
      page: _currentPage,
      search: _searchCtrl.text,
      dateDebut: _dateDebut?.toIso8601String().split('T')[0],
      dateFin: _dateFin?.toIso8601String().split('T')[0],
    );

    if (mounted) {
      setState(() {
        _sejours.addAll(List<SejourModel>.from(data['results'] ?? []));

        _loadingMore = false;
      });
    }
  }

  Future<void> _selectDate(bool isDebut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.emerald600,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isDebut) {
          _dateDebut = picked;
        } else {
          _dateFin = picked;
        }
      });
      _charger();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: Text(
          'SÉJOURS EN COURS',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildActiveFilterChips(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _charger,
              color: AppColors.emerald600,
              child: _loading
                  ? _buildShimmerList()
                  : _sejours.isEmpty
                      ? _buildEmptyState()
                      : _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: ListSkeleton(itemCount: 6),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          CustomTextField(
            label: 'RECHERCHE',
            controller: _searchCtrl,
            prefixIcon: Icons.search,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateBtn(
                  _dateDebut == null ? 'DÉBUT' : _dateDebut!.toIso8601String().split('T')[0],
                  () => _selectDate(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateBtn(
                  _dateFin == null ? 'FIN' : _dateFin!.toIso8601String().split('T')[0],
                  () => _selectDate(false),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    _dateDebut = null;
                    _dateFin = null;
                    _searchCtrl.clear();
                  });
                  _charger();
                },
                icon: const Icon(Icons.refresh, color: AppColors.slate400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateBtn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.slate50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 14, color: AppColors.slate400),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.slate700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChips() {
    if (_dateDebut == null && _dateFin == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            'FILTRES ACTIFS:',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.slate400,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'PÉRIODE PERSONNALISÉE',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: AppColors.emerald700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hotel_class_rounded, size: 64, color: AppColors.slate300),
          const SizedBox(height: 16),
          Text(
            'Aucun séjour en cours trouvé',
            style: GoogleFonts.inter(color: AppColors.slate500),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _sejours.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _sejours.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildSejourCard(_sejours[index]),
          );
        } else {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.emerald600),
            ),
          );
        }
      },
    );
  }

  Widget _buildSejourCard(SejourModel s) {
    final String? role = _user?.role;
    final bool restrictMedia = role == 'AGENT_ACCUEIL' || role == 'GERANT_HOTEL';
    return InkWell(
      onTap: s.isOffline
          ? null
          : () {
              context
                  .push('/enregistrement/${s.id}/detail')
                  .then((_) => _charger());
            },

      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!restrictMedia) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: DgpnImage(
                        url: s.photoClient,
                        localUuid: s.identifiantUnique,
                        type: DgpnImageType.photo,
                        width: 40,
                        height: 40,
                        placeholderIcon: Icons.person,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.clientFullName.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: AppColors.slate800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chambre ${s.numeroChambre}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.slate500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Entrée: ${s.formattedDateArrivee}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.slate400,
                          ),
                        ),
                        if (s.dateSortiePrevue != null && s.dateSortiePrevue!.isNotEmpty)
                          Text(
                            'Sortie prévue: ${s.formattedDateSortiePrevue}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.emerald600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: s.isOffline ? const Color(0xFFFEF3C7) : AppColors.emerald50,
                      borderRadius: BorderRadius.circular(8),
                      border: s.isOffline ? Border.all(color: const Color(0xFFFDE68A)) : null,
                    ),
                    child: Text(
                      s.isOffline ? 'HORS-LIGNE' : 'ACTIF',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        fontSize: 8,
                        color: s.isOffline ? const Color(0xFFD97706) : AppColors.emerald700,
                      ),
                    ),
                  ),

                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                   Expanded(
                    child: Text(
                      s.motifSejour,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate700,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: s.isOffline ? null : () => context.push('/enregistrement/${s.id}/modifier').then((_) => _charger()),
                    icon: const Icon(Icons.edit, size: 12),
                    label: const Text('MODIFIER'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.slate100,
                      foregroundColor: AppColors.slate700,
                      elevation: 0,
                      minimumSize: const Size(64, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: s.isOffline ? null : () => context.push('/enregistrement/${s.id}/detail', extra: true).then((_) => _charger()),
                    icon: const Icon(Icons.logout, size: 12),
                    label: const Text('SORTIE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: s.isOffline ? AppColors.slate200 : AppColors.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(64, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),

                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
