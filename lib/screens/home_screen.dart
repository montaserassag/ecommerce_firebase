import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../widgets/deal_card.dart';
import '../widgets/trending_tile.dart';

/// Exercise 1: Fetch Products from API + show a loading indicator.
/// Exercise 3: Offline Support — banner + last cached products.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: (() {
          // ── No data yet & currently fetching → full-screen loader ──────
          if (productProvider.isLoading && productProvider.products.isEmpty) {
            return const _LoadingView();
          }

          // ── No data & request failed (and no cache) → error + retry ────
          if (productProvider.hasError && productProvider.products.isEmpty) {
            return _ErrorView(
              message: productProvider.errorMessage,
              onRetry: () => context.read<ProductProvider>().fetchProducts(),
            );
          }

          // ── We have products (fresh or cached) → show the catalog ──────
          final deals    = productProvider.deals;
          final trending = productProvider.trending;

          return RefreshIndicator(
            color: kAccent,
            backgroundColor: kCardColor,
            onRefresh: () => context.read<ProductProvider>().fetchProducts(),
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  floating: true,
                  backgroundColor: kBgColor,
                  elevation: 0,
                  title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Today Deals ',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    const Text('Fresh picks curated for today only',
                      style: TextStyle(fontSize: 11, color: kTextSecond, fontWeight: FontWeight.normal)),
                  ]),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: kTextSecond),
                      tooltip: 'Refresh',
                      onPressed: () => context.read<ProductProvider>().fetchProducts(),
                    ),
                  ],
                ),

                // ── Exercise 3: "Offline mode" message ────────────────────
                if (productProvider.isOffline)
                  const SliverToBoxAdapter(child: _OfflineBanner()),

                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: kCardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorderColor),
                      ),
                      child: const TextField(
                        style: TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          hintStyle: TextStyle(color: kTextSecond, fontSize: 13),
                          prefixIcon: Icon(Icons.search_rounded, color: kTextSecond, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ),
                ),

                // Today Deals - horizontal scroll
                if (deals.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 270,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        itemCount: deals.length,
                        itemBuilder: (_, i) => DealCard(p: deals[i]),
                      ),
                    ),
                  ),

                // Trending Header
                if (trending.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Trending ',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                          GestureDetector(
                            onTap: () => context.read<ProductProvider>().fetchProducts(),
                            child: const Text('Refresh',
                              style: TextStyle(fontSize: 12, color: kAccent, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Trending List
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => TrendingTile(p: trending[i]),
                    childCount: trending.length,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          );
        })(),
      ),
    );
  }
}

// ── Loading state ────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(color: kAccent),
      SizedBox(height: 16),
      Text('Loading products...', style: TextStyle(fontSize: 13, color: kTextSecond)),
    ]),
  );
}

// ── Error state (no cache available) ───────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.cloud_off_rounded, size: 56, color: kTextSecond),
        const SizedBox(height: 16),
        const Text('Couldn\'t load products',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: kTextSecond)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Try Again'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kGold, foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
      ]),
    ),
  );
}

// ── Exercise 3: Offline banner ──────────────────────────────────────────
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(14, 4, 14, 0),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFF9800).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.4)),
    ),
    child: Row(children: [
      const Icon(Icons.wifi_off_rounded, size: 18, color: Color(0xFFFF9800)),
      const SizedBox(width: 10),
      const Expanded(
        child: Text(
          'Offline mode — showing last saved products',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFFB74D)),
        ),
      ),
    ]),
  );
}
