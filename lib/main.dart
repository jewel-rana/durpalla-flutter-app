import 'package:durpalla/screens/auth/check_mobile_screen.dart';
import 'package:durpalla/screens/auth/login_screen.dart';
import 'package:durpalla/screens/auth/register_screen.dart';
import 'package:durpalla/utils/auth_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/trips_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/support_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/more_screen.dart';
import 'screens/privacy_policy_screen.dart';

void main() {
  // WidgetsFlutterBinding.ensureInitialized();
  //
  // // Draw behind system bars
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  //
  // // Make system bars transparent and remove divider
  // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
  //   statusBarColor: Colors.transparent,
  //   systemNavigationBarColor: Colors.transparent,
  //   systemNavigationBarDividerColor: Colors.transparent,
  //   statusBarIconBrightness: Brightness.dark,        // flip to light if dark bg
  //   systemNavigationBarIconBrightness: Brightness.dark,
  //   systemStatusBarContrastEnforced: false,
  //   systemNavigationBarContrastEnforced: false,
  // ));


  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Durpalla',
      themeMode: _themeMode,
      theme: ThemeData(
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.black87, // Global background color
          contentTextStyle: TextStyle(
            color: Colors.white,           // Global text color
            fontSize: 16,                   // Global text size
          ),
          behavior: SnackBarBehavior.floating, // Optional global behavior
        ),
        textTheme: GoogleFonts.robotoCondensedTextTheme(
          Theme.of(context).textTheme,
        ),
        brightness: Brightness.light,
        primaryColor: const Color(0xFF0061A8),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0061A8),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // Button background
            foregroundColor: Colors.white, // Text color
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF0061A8),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0061A8),
          ),
        ),
      ),
      // 🔌 Routes for auth journey (names can match what you built)
      routes: {
        '/auth/check': (_) => const CheckMobileScreen(),
        '/auth/login': (_) => const LoginScreen(),
        '/auth/register': (_) => const RegisterScreen(),
        '/home': (_) => MainScaffold(onThemeToggle: toggleTheme, isDark: _themeMode == ThemeMode.dark),
      },

      // 🔒 Let AuthGate decide first page
      // home: const AuthGate(),
      home: MainScaffold(
        appBar: AppBar(
          title: Image.asset(
            'assets/logo.png',
            height: 40, // Adjust as needed
          ),
          centerTitle: true, // Center the logo
          backgroundColor: Colors.white, // Optional
          elevation: 0, // Optional: flat app bar
        ),
        onThemeToggle: toggleTheme,
        isDark: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  final void Function(bool)? onThemeToggle;
  final bool isDark;

  // Make appBar optional and flexible
  final PreferredSizeWidget? appBar;

  const MainScaffold({
    super.key,
    this.onThemeToggle,
    this.isDark = false,
    this.appBar,
  });

  PreferredSizeWidget _defaultAppBar(BuildContext context) {
    return AppBar(
      title: Image.asset('assets/logo-white.png', height: 40),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
    );
  }

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  bool _loggedIn = false;

  static final List<Widget> _pages = <Widget>[
    const HomeScreen(),
    const BookingScreen(transportType: 'launch',),
    const TripsScreen()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _checkLogin();
    });
  }

  Future<void> _checkLogin() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (mounted) {
      setState(() {
        _loggedIn = token != null && token.isNotEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/logo-white.png', height: 30),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              icon: const Icon(Icons.account_circle, color: Colors.white),
              onPressed: () async {
                const storage = FlutterSecureStorage();
                final token = await storage.read(key: 'token');
                if (token == null || token.isEmpty) {
                  if (!mounted) return;
                  Navigator.pushNamed(context, '/auth/check');
                  return;
                }
                // already logged in
                // ignore: use_build_context_synchronously
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const AuthGuard(child: ProfileScreen()),
                ));
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF0061A8)),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              title: const Text('Support'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
            ),
            ListTile(
              title: const Text('Settings'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    isDarkMode: widget.isDark,
                    onToggleTheme: widget.onThemeToggle,
                  ),
                ),
              ),
            ),
            ListTile(
              title: const Text('More'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoreScreen())),
            ),
            ListTile(
              title: const Text('Privacy Policy'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3A95D8), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.center,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _selectedIndex,
            children: _pages.map((page) {
              return Scaffold(
                backgroundColor: Colors.transparent,
                body: page,
              );
            }).toList(),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: ColoredBox(
          color: Colors.blue.shade50, // same as your bar background
          child: Padding(
            // fill & paint the gesture area
            padding: EdgeInsets.only(
              bottom: 5,
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(icon: Icon(Icons.home, size: 28,), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.search, size: 28,), label: 'Search'),
                BottomNavigationBarItem(icon: Icon(Icons.airplane_ticket, size: 28,), label: 'Trips'),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: const Color(0xFF0061A8),
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF0061A8),
              ),
              unselectedItemColor: Colors.black87,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedFontSize: 12,
              onTap: _onItemTapped,
            ),
          ),
        ),
      ),

    );
  }
}
