import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: 230,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.04),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(index: 0, icon: HugeIcons.strokeRoundedHome01, label: 'Home'),
                    _buildNavItem(index: 1, icon: HugeIcons.strokeRoundedBubbleChat, label: 'Chat'),
                    _buildNavItem(index: 2, icon: HugeIcons.strokeRoundedUser, label: 'Profile'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required dynamic icon,
    required String label,
  }) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: icon,
              color: isSelected ? Colors.white : AppTheme.textLight.withValues(alpha: 0.7),
              size: 18,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
