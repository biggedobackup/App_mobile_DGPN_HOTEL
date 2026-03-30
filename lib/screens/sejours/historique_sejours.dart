import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/sejour_service.dart';
import '../../core/models/sejour_model.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/utils/debouncer.dart';
import 'client_historique_detail_screen.dart';

class HistoriqueSejoursScreen extends StatefulWidget {
  const HistoriqueSejoursScreen({super.key});

  @override
  State<HistoriqueSejoursScreen> createState() => _HistoriqueSejoursScreenState();
}

class _HistoriqueSejoursScreenState extends State<HistoriqueSejoursScreen> {
  final _sejourService = SejourService();
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
    
    final data = await _sejourService.getHistoriqueSejours(
      page: _currentPage,
      search: _searchCtrl.text,
      dateDebut: _dateDebut?.toIso8601String().split('T')[0],
      dateFin: _dateFin?.toIso8601String().split('T')[0],
    );
    
    if (mounted) {
      setState(() {
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
    final data = await _sejourService.getHistoriqueSejours(
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
          'HISTORIQUE GLOBAL',
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
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 8,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.grey[50]!,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          CustomTextField(
            label: 'RECHERCHE (NOM, DOCUMENT, CHAMBRE...)',
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
          const Icon(Icons.history_rounded, size: 64, color: AppColors.slate300),
          const SizedBox(height: 16),
          Text(
            'Aucun historique trouvé',
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
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildHistoryCard(_sejours[index]),
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

  Widget _buildHistoryCard(SejourModel s) {
    final bool isTermine = s.statut == 'SEJOUR_TERMINE' || s.dateSortie != null;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClientHistoriqueDetailScreen(
              nom: s.nomClient,
              prenom: s.prenomClient,
              numeroDocument: s.numeroDocument,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isTermine ? AppColors.slate100 : AppColors.emerald50,
              child: Icon(
                isTermine ? Icons.history : Icons.hotel,
                color: isTermine ? AppColors.slate600 : AppColors.emerald600,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
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
                    'Chambre ${s.numeroChambre} • ${s.motifSejour}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.slate400),
          ],
        ),
      ),
    );
  }
}
