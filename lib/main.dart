import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'routes/app_router.dart';
import 'core/constants/app_colors.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:workmanager/workmanager.dart';
import 'core/services/sync_service.dart';
import 'core/services/cache_warmup_service.dart';
import 'core/services/local_ocr_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Initialisation minimale pour les tâches d'arrière-plan
    await Hive.initFlutter();
    await Hive.openBox('sejours_offline');
    await Hive.openBox('sorties_offline');
    await Hive.openBox('cache');

    // 1. Synchroniser les données locales vers le serveur
    await SyncService().processAllQueues();

    // 2. Préchauffage proactif du cache
    await CacheWarmupService().warmUp();

    return Future.value(true);
  });
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  
  // Initialisation du stockage local et synchro
  await Hive.initFlutter();
  await Hive.openBox('sejours_offline');
  await Hive.openBox('sorties_offline');
  await Hive.openBox('cache');
  SyncService().init();

  // Configuration de Workmanager pour la synchronisation en arrière-plan
  await Workmanager().initialize(
    callbackDispatcher,
  );
  
  // Tâche périodique (toutes les 15 min minimum par défaut sur Android)
  await Workmanager().registerPeriodicTask(
    "dgpn-sync-task",
    "syncAndWarmup",
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  // Préchauffage immédiat au démarrage (ne bloque pas l'UI)
  CacheWarmupService().warmUp();

  // Initialisation asynchrone du SDK Regula pour l'OCR local
  LocalOcrService().initialize();

  await initializeDateFormatting('fr_FR', null);
  runApp(const DgpnHotelApp());
}

class DgpnHotelApp extends StatelessWidget {
  const DgpnHotelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DGPN Hôtel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.emerald600,
          primary: AppColors.emerald600,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: AppColors.slate50,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.emerald600,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.emerald600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 48),
            textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.slate50,
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      routerConfig: appRouter,
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            const GlobalOfflineBanner(),
          ],
        );
      },
    );
  }
}

class GlobalOfflineBanner extends StatelessWidget {
  const GlobalOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final results = snapshot.data ?? [];
        final isOffline = results.contains(ConnectivityResult.none);
        
        if (!isOffline) return const SizedBox.shrink();

        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 70,
          right: 70,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706), // Amber-600
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'MODE HORS-LIGNE',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
