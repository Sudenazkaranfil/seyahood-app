import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';

class AppNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: AppTheme.navDark,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.navDark.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.book_outlined, label: context.tr('navBar.journal'), index: 0, currentIndex: currentIndex, onTap: onTap),
            _NavItem(icon: Icons.explore_outlined, label: context.tr('navBar.explore'), index: 1, currentIndex: currentIndex, onTap: onTap),
            _NavPlusButton(onTap: () => onTap(5)),
            _NavItem(icon: Icons.map_outlined, label: context.tr('navBar.map'), index: 2, currentIndex: currentIndex, onTap: onTap),
            _NavItem(icon: Icons.person_outline, label: context.tr('navBar.profile'), index: 3, currentIndex: currentIndex, onTap: onTap),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.terracotta.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20,
                color: isActive ? AppTheme.terracotta : Colors.white.withOpacity(0.35)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? AppTheme.terracotta : Colors.white.withOpacity(0.35),
                )),
          ],
        ),
      ),
    );
  }
}

class _NavPlusButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NavPlusButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: const BoxDecoration(
          color: AppTheme.terracotta,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 22),
      ).animate().scale(duration: 200.ms, curve: Curves.easeOut),
    );
  }
}