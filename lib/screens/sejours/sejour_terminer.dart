import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/sejour_service.dart';
import '../../core/models/sejour_model.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/utils/debouncer.dart';

class SejourTerminerScreen extends StatefulWidget {
  const SejourTerminerScreen({super.key});

  @override
  State<SejourTerminerScreen> createState() => _SejourTerminerScreenState();
}

class _SejourTerminerScreenState extends State<SejourTerminerScreen> {
  final _sejourService = SejourService();
  final _searchCtrl = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 500);
  final _scrollController = ScrollController();

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
    
    final data = await _sejourService.getSejoursTermines(
      page: _currentPage,
      search: _searchCtrl.text,
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
    final data = await _sejourService.getSejoursTermines(
      page: _currentPage,
      search: _searchCtrl.text,
    );

    if (mounted) {
      setState(() {
        _sejours.addAll(List<SejourModel>.from(data['results'] ?? []));

        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: Text(
          'SÉJOURS TERMINÉS',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: CustomTextField(
              label: 'RECHERCHER UN CLIENT',
              controller: _searchCtrl,
              prefixIcon: Icons.search,
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: 8,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.grey[50]!,
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
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
            'Aucun séjour terminé trouvé',
            style: GoogleFonts.inter(color: AppColors.slate500),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _sejours.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _sejours.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTerminatedCard(_sejours[index]),
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

  Widget _buildTerminatedCard(SejourModel s) {
    return InkWell(
      onTap: () {
        context.push('/enregistrement/${s.id}/detail').then((_) => _charger());
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
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle, color: AppColors.emerald600),
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
                      'Sortie le : ${s.formattedDateSortie}',
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
      ),
    );
  }
}
