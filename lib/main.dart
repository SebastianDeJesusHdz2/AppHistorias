import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:apphistorias/services/local_storage_service.dart';
import 'package:apphistorias/services/account_service.dart';
import 'package:apphistorias/services/cloud_sync_service.dart';
import 'package:apphistorias/screens/home_screen.dart';
import 'package:apphistorias/screens/settings_screen.dart';
import 'package:apphistorias/screens/account_screen.dart';
import 'package:apphistorias/models/story.dart';

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

  final documents = await getApplicationDocumentsDirectory();
  Hive.init(documents.path);

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

  static const Color _azulPrincipal = Color(0xFF2874A6);
  static const Color _verdeAccent = Color(0xFF43C59E);
  static const Color _coral = Color(0xFFFF6F61);
  static const Color _bgClaro = Color(0xFFEDF2F7);
  static const Color _bgOscuro = Color(0xFF202A38);

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: _azulPrincipal,
        secondary: _verdeAccent,
        surface: Colors.white,
        background: _bgClaro,
        error: _coral,
      ),
      scaffoldBackgroundColor: _bgClaro,
      appBarTheme: const AppBarTheme(
        backgroundColor: _bgClaro,
        foregroundColor: _azulPrincipal,
        elevation: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _azulPrincipal,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _coral,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: _azulPrincipal,
        secondary: _verdeAccent,
        surface: Color(0xFF252C39),
        background: _bgOscuro,
        error: _coral,
      ),
      scaffoldBackgroundColor: _bgOscuro,
      appBarTheme: const AppBarTheme(
        backgroundColor: _bgOscuro,
        foregroundColor: _azulPrincipal,
        elevation: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _azulPrincipal,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _coral,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppHistorias',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
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
