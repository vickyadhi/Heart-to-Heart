import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({super.key});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildSkeletonItem({
    required double height,
    double? width,
    double radius = 16.0,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            height: height,
            width: width ?? double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          // Header Row Skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildSkeletonItem(height: 48, width: 48, radius: 24),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSkeletonItem(height: 14, width: 80, radius: 4),
                      const SizedBox(height: 6),
                      _buildSkeletonItem(height: 16, width: 120, radius: 4),
                    ],
                  ),
                ],
              ),
              _buildSkeletonItem(height: 36, width: 70, radius: 18),
            ],
          ),
          const SizedBox(height: 28),

          // Neon Heart Area Placeholder
          Center(
            child: _buildSkeletonItem(height: 180, width: 180, radius: 90),
          ),
          const SizedBox(height: 24),

          // Tap to Love Status Text Placeholder
          Center(
            child: _buildSkeletonItem(height: 16, width: 160, radius: 4),
          ),
          const SizedBox(height: 28),

          // Map Placeholder
          _buildSkeletonItem(height: 180, radius: 20),
          const SizedBox(height: 20),

          // Stats Cards Placeholder
          Row(
            children: [
              Expanded(child: _buildSkeletonItem(height: 72, radius: 20)),
              const SizedBox(width: 8),
              Expanded(child: _buildSkeletonItem(height: 72, radius: 20)),
              const SizedBox(width: 8),
              Expanded(child: _buildSkeletonItem(height: 72, radius: 20)),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
