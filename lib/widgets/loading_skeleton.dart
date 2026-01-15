import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/constants.dart';

/// Skeleton loader untuk better UX saat loading data
class LoadingSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  
  const LoadingSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppConstants.gray200,
      highlightColor: AppConstants.gray100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Skeleton untuk general fund card
class GeneralFundCardSkeleton extends StatelessWidget {
  const GeneralFundCardSkeleton({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const LoadingSkeleton(width: 180, height: 16),
          const SizedBox(height: 12),
          const LoadingSkeleton(width: 200, height: 32),
          const SizedBox(height: 8),
          LoadingSkeleton(
            width: double.infinity,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

/// Skeleton untuk active target card
class ActiveTargetCardSkeleton extends StatelessWidget {
  const ActiveTargetCardSkeleton({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppConstants.gray200, width: 2),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const LoadingSkeleton(width: 200, height: 20),
              LoadingSkeleton(
                width: 80,
                height: 28,
                borderRadius: BorderRadius.circular(12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const LoadingSkeleton(width: 180, height: 18),
          const SizedBox(height: 12),
          const LoadingSkeleton(width: 220, height: 14),
          const SizedBox(height: 20),
          const LoadingSkeleton(width: 120, height: 14),
          const SizedBox(height: 8),
          const LoadingSkeleton(width: 250, height: 24),
          const SizedBox(height: 12),
          LoadingSkeleton(
            width: double.infinity,
            height: 24,
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
    );
  }
}

/// Skeleton untuk transaction card
class TransactionCardSkeleton extends StatelessWidget {
  const TransactionCardSkeleton({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppConstants.gray200),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LoadingSkeleton(width: 120, height: 16),
                const SizedBox(height: 8),
                const LoadingSkeleton(width: 80, height: 12),
                const SizedBox(height: 4),
                LoadingSkeleton(
                  width: 100,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const LoadingSkeleton(width: 60, height: 12),
        ],
      ),
    );
  }
}

/// Skeleton untuk history section
class HistorySectionSkeleton extends StatelessWidget {
  const HistorySectionSkeleton({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LoadingSkeleton(width: 200, height: 18),
        const SizedBox(height: 4),
        const LoadingSkeleton(width: 150, height: 13),
        const SizedBox(height: 16),
        ...List.generate(
          3,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: TransactionCardSkeleton(),
          ),
        ),
      ],
    );
  }
}
