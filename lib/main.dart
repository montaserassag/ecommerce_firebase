import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'models/product.dart';
import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/product_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/profile_screen.dart';

Future<void> main() async {
  // ✅ Common Mistake #1 fix: ensureInitialized() BEFORE Firebase.initializeApp()
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Connect the app using flutterfire configure (run it first — see README)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),   // Ex 2: Firestore products
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()), // Ex 3: per-user favorites
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ecommerce_firebase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kBgColor,
        colorScheme: const ColorScheme.dark(primary: kGold, secondary: kAccent, surface: kCardColor),
        appBarTheme: const AppBarTheme(backgroundColor: kBgColor, elevation: 0, surfaceTintColor: Colors.transparent),
      ),
      // ✅ Exercise 1: Show different screen based on auth state (StreamBuilder)
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SplashScreen();
          }
          // User signed in → main app
          if (snapshot.hasData) return const MainScreen();
          // User signed out → login/register
          return const AuthScreen();
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: kBgColor,
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.storefront_rounded, size: 56, color: kGold),
      SizedBox(height: 20),
      CircularProgressIndicator(color: kAccent, strokeWidth: 2),
    ])),
  );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  static const _screens = [
    HomeScreen(), CategoriesScreen(), FavoritesScreen(), CartScreen(), ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cartN = context.watch<CartProvider>().totalItems;
    final favN  = context.watch<FavoritesProvider>().count;

    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: _BottomNav(
        index: _index, cartN: cartN, favN: favN,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index, cartN, favN;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.cartN, required this.favN, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Color(0xFF0D1220),
      border: Border(top: BorderSide(color: kBorderColor, width: 0.5)),
    ),
    child: SafeArea(top: false, child: SizedBox(height: 62,
      child: Row(children: [
        _NI(i: 0, cur: index, icon: Icons.home_rounded,          label: 'Home',       onTap: onTap),
        _NI(i: 1, cur: index, icon: Icons.grid_view_rounded,     label: 'Categories', onTap: onTap),
        _NI(i: 2, cur: index, icon: Icons.favorite_rounded,      label: 'Favorites',  onTap: onTap, badge: favN),
        _NI(i: 3, cur: index, icon: Icons.shopping_cart_rounded, label: 'Cart',       onTap: onTap, badge: cartN),
        _NI(i: 4, cur: index, icon: Icons.person_rounded,        label: 'Profile',    onTap: onTap),
      ]),
    )),
  );
}

class _NI extends StatelessWidget {
  final int i, cur, badge; final IconData icon; final String label; final ValueChanged<int> onTap;
  const _NI({required this.i, required this.cur, required this.icon, required this.label, required this.onTap, this.badge = 0});

  @override
  Widget build(BuildContext context) {
    final active = i == cur;
    return Expanded(child: GestureDetector(
      onTap: () => onTap(i), behavior: HitTestBehavior.opaque,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Stack(clipBehavior: Clip.none, children: [
          Icon(icon, size: 22, color: active ? kAccent : kTextSecond),
          if (badge > 0) Positioned(top: -5, right: -9,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 14),
              decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(10)),
              child: Text('$badge', textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w800)),
            )),
        ]),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600,
          color: active ? kAccent : kTextSecond)),
      ]),
    ));
  }
}
