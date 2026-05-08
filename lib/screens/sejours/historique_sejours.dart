import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/sejour_service.dart';
import '../../core/models/sejour_model.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/utils/debouncer.dart';
import 'client_historique_detail_screen.dart';

class HistoriqueSejoursScreen extends StatefulWidget {
  const HistoriqueSejoursScreen({super.key});

  @override
  State<HistoriqueSejoursScreen> createState() =>
      _HistoriqueSejoursScreenState();
}

class _HistoriqueSejoursScreenState extends State<HistoriqueSejoursScreen> {
  final _sejourService = SejourService();
  final _searchCtrl = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 500);
  final _scrollController = ScrollController();

  DateTime? _dateDebut;
  DateTime? _dateFin;

  List<ClientHistoriqueModel> _clients = [];
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_loading && !_loadingMore && _clients.length < _totalCount) {
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
      _clients = [];
    });

    final data = await _sejourService.getHistoriqueSejours(
      page: _currentPage,
      search: _searchCtrl.text,
      dateDebut: _dateDebut?.toIso8601String().split('T')[0],
      dateFin: _dateFin?.toIso8601String().split('T')[0],
    );

    if (mounted) {
      setState(() {
        _clients = List<ClientHistoriqueModel>.from(data['results'] ?? []);

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
        _clients.addAll(
          List<ClientHistoriqueModel>.from(data['results'] ?? []),
        );

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
            colorScheme: ColorScheme.light(primary: AppColors.emerald600),
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
                  : _clients.isEmpty
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
      child: ListSkeleton(itemCount: 8),
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
                  _dateDebut == null
                      ? 'DÉBUT'
                      : _dateDebut!.toIso8601String().split('T')[0],
                  () => _selectDate(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateBtn(
                  _dateFin == null
                      ? 'FIN'
                      : _dateFin!.toIso8601String().split('T')[0],
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
            const Icon(
              Icons.calendar_today,
              size: 14,
              color: AppColors.slate400,
            ),
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
          const Icon(
            Icons.history_rounded,
            size: 64,
            color: AppColors.slate300,
          ),
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
      itemCount: _clients.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _clients.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildHistoryCard(_clients[index]),
          );
        } else {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.emerald600,
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildHistoryCard(ClientHistoriqueModel c) {
    final bool isEnCours = c.statutDernierSejour == 'EN_SEJOUR';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ClientHistoriqueDetailScreen(clientId: c.client.id!),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.slate100,
                  child: Text(
                    '${c.client.prenom.isNotEmpty ? c.client.prenom[0] : ''}${c.client.nom.isNotEmpty ? c.client.nom[0] : ''}'
                        .toUpperCase(),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      color: AppColors.slate600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${c.client.nom} ${c.client.prenom}'.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: AppColors.slate800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${c.client.typeDocument} : ${c.client.numeroDocument}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: AppColors.slate400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            c.client.nationalite.isEmpty ? '-' : c.client.nationalite,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.phone,
                            size: 12,
                            color: AppColors.slate400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            c.client.contactTelephone.isEmpty ? '-' : c.client.contactTelephone,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppColors.slate400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          c.dateEntreeDernier != null
                              ? c.dateEntreeDernier!.split('T')[0]
                              : '-',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate600,
                          ),
                        ),
                        if (c.dateSortieDernier != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '→',
                            style: TextStyle(
                              color: AppColors.slate400,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            c.dateSortieDernier!.split('T')[0],
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isEnCours ? AppColors.emerald50 : AppColors.slate100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isEnCours ? 'EN SÉJOUR' : 'TERMINÉ',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isEnCours
                          ? AppColors.emerald700
                          : AppColors.slate600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
