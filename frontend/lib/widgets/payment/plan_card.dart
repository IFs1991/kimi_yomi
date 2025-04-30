import 'package:flutter/material.dart';
import '../../models/plan.dart';

/// 料金プランを表示するカードウィジェット
class PlanCard extends StatelessWidget {
  final Plan plan;
  final bool isSelected;
  final VoidCallback? onTap;

  const PlanCard({
    super.key,
    required this.plan,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isSelected ? 4.0 : 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    plan.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                plan.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                plan.formattedPrice, // Planモデルで定義したゲッターを使用
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12.0),
              // 特徴リスト (必要に応じて表示)
              if (plan.features.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: plan.features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                       children: [
                         Icon(Icons.check, size: 16, color: colorScheme.tertiary),
                         const SizedBox(width: 8.0),
                         Expanded(
                           child: Text(
                             feature,
                             style: theme.textTheme.bodySmall,
                           ),
                         ),
                       ],
                    ),
                  )).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}