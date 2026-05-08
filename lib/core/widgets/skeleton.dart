import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';

class Skeleton extends StatelessWidget {
  final double? height;
  final double? width;
  final double borderRadius;

  const Skeleton({
    super.key,
    this.height,
    this.width,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.slate100,
      highlightColor: AppColors.slate50,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ListSkeleton extends StatelessWidget {
  final int itemCount;
  final bool isHorizontal;

  const ListSkeleton({
    super.key,
    this.itemCount = 5,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: isHorizontal ? Axis.horizontal : Axis.vertical,
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 16, width: 16),
      itemBuilder: (context, index) => const CardSkeleton(),
    );
  }
}

class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Row(
        children: [
          const Skeleton(height: 50, width: 50, borderRadius: 12),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Skeleton(height: 16, width: 150),
                const SizedBox(height: 8),
                const Skeleton(height: 12, width: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatSkeleton extends StatelessWidget {
  const StatSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Skeleton(height: 32, width: 32, borderRadius: 8),
          const SizedBox(height: 12),
          const Skeleton(height: 24, width: 60),
          const SizedBox(height: 4),
          const Skeleton(height: 12, width: 80),
        ],
      ),
    );
  }
}
class FormSkeleton extends StatelessWidget {
  const FormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(height: 20, width: 150),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: const Skeleton(height: 100, borderRadius: 12)),
              const SizedBox(width: 8),
              Expanded(child: const Skeleton(height: 100, borderRadius: 12)),
              const SizedBox(width: 8),
              Expanded(child: const Skeleton(height: 100, borderRadius: 12)),
            ],
          ),
          const SizedBox(height: 28),
          const Skeleton(height: 20, width: 200),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: const Skeleton(height: 50, borderRadius: 12)),
              const SizedBox(width: 12),
              Expanded(child: const Skeleton(height: 50, borderRadius: 12)),
            ],
          ),
          const SizedBox(height: 12),
          const Skeleton(height: 50, borderRadius: 12),
          const SizedBox(height: 12),
          const Skeleton(height: 50, borderRadius: 12),
          const SizedBox(height: 28),
          const Skeleton(height: 20, width: 180),
          const SizedBox(height: 16),
          const Skeleton(height: 50, borderRadius: 12),
          const SizedBox(height: 32),
          const Skeleton(height: 56, borderRadius: 16),
        ],
      ),
    );
  }
}

class StatsGridSkeleton extends StatelessWidget {
  const StatsGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => const StatSkeleton(),
    );
  }
}
