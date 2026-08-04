import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

import '../widgets/home_header.dart';
import '../widgets/hero_banner.dart';
import '../widgets/main_actions.dart';
import '../widgets/recent_sightings.dart';
import '../widgets/progress_card.dart';
import '../widgets/home_bottom_nav.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userName = user?.name.split(' ').first ?? 'Explorador';
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeHeader(userName: userName, isSmallScreen: isSmallScreen),
                const SizedBox(height: 32),
                const HeroBanner(),
                const SizedBox(height: 32),
                const MainActions(),
                const SizedBox(height: 32),
                const RecentSightings(),
                const SizedBox(height: 32),
                const ProgressCard(completedChapters: 2, totalChapters: 5), // Mock data for now
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const HomeBottomNav(),
    );
  }
}
