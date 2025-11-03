// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

// Servicios propios
import 'package:apphistorias/services/local_storage_service.dart';
import 'package:apphistorias/services/account_service.dart';
import 'package:apphistorias/services/cloud_sync_service.dart';

// Pantallas
import 'package:apphistorias/screens/home_screen.dart';
import 'package:apphistorias/screens/settings_screen.dart';
import 'package:apphistorias/screens/account_screen.dart';

// Modelos
import 'package:apphistorias/models/story.dart';

// Proveedor de historias (con recarga desde disco)
class StoryProvider with ChangeNotifier {
  final List<Story> _stories = [];
  List<Story> get stories => _stories;

  Future<void> init() async {
    final loaded = await LocalStorageService.getStories();
    _stories
      ..clear()
      ..addAll(loaded);
    notifyListeners();
  }

  Future<void> reloadFromDisk() async {
    final loaded = await LocalStorageService.getStories();
    _stories
      ..clear()
      ..addAll(loaded);
    notifyListeners();
  }

  Future<void> _persist() async {
    await LocalStorageService.saveStories(_stories);
  }

  Future<void> addStory(Story story) async {
    _stories.add(story);
    await _persist();
    notifyListeners();
  }

  Future<void> removeStoryAt(int index) async {
    if (index >= 0 && index < _stories.length) {
      _stories.removeAt(index);
      await _persist();
      notifyListeners();
    }
  }

  Future<void> removeStoryById(String id) async {
    final i = _stories.indexWhere((s) => s.id == id);
    if (i != -1) {
      _stories.removeAt(i);
      await _persist();
      notifyListeners();
    }
  }

  Future<void> saveAll() async {
    await _persist();
    notifyListeners();
  }

  void refresh() => notifyListeners();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Hive en la carpeta de documentos de la app
  final documents = await getApplicationDocumentsDirectory();
  Hive.init(documents.path);

  // Carga datos antes de pintar la UI
  final storyProvider = StoryProvider();
  await storyProvider.init();

  final accountService = AccountService();
  await accountService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<StoryProvider>.value(value: storyProvider),
        ChangeNotifierProvider<AccountService>.value(value: accountService),
        Provider<CloudSyncService>(create: (_) => CloudSyncService()),
      ],
      child: const MainThemeSwitcher(),
    ),
  );
}

class MainThemeSwitcher extends StatefulWidget {
  const MainThemeSwitcher({super.key});
  @override
  State<MainThemeSwitcher> createState() => _MainThemeSwitcherState();
}

class _MainThemeSwitcherState extends State<MainThemeSwitcher> {
  bool _isDark = false;
  void _toggleTheme(bool value) => setState(() => _isDark = value);

  @override
  Widget build(BuildContext context) {
    // Paleta
    const Color azulPrincipal = Color(0xFF2874A6);
    const Color verdeAccent = Color(0xFF43C59E);
    const Color coral = Color(0xFFFF6F61);
    const Color bgClaro = Color(0xFFEDF2F7);
    const Color bgOscuro = Color(0xFF202A38);

    return MaterialApp(
      title: 'AppHistorias',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: azulPrincipal,
          secondary: verdeAccent,
          surface: Colors.white,
          background: bgClaro,
          error: coral,
        ),
        scaffoldBackgroundColor: bgClaro,
        appBarTheme: const AppBarTheme(
          backgroundColor: bgClaro,
          foregroundColor: azulPrincipal,
          elevation: 1,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: azulPrincipal,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: coral,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: azulPrincipal,
          secondary: verdeAccent,
          surface: Color(0xFF252C39),
          background: bgOscuro,
          error: coral,
        ),
        scaffoldBackgroundColor: bgOscuro,
        appBarTheme: const AppBarTheme(
          backgroundColor: bgOscuro,
          foregroundColor: azulPrincipal,
          elevation: 1,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: azulPrincipal,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: coral,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(
        onThemeToggle: _toggleTheme,
        isDark: _isDark,
      ),
      routes: {
        '/settings': (context) => const SettingsScreen(),
        '/account': (context) => const AccountScreen(),
      },
    );
  }
}
