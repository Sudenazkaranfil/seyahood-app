import 'package:flutter/material.dart';

/// Plus (gümüş) / PRO (altın) gezgin rozeti. Free kullanıcılarda hiçbir şey
/// göstermez.
class PlanBadge extends StatelessWidget {
  final bool isPlus;
  final bool isPro;

  const PlanBadge({super.key, required this.isPlus, required this.isPro});

  static const _silver = Color(0xFF9AA1AC);
  static const _gold = Color(0xFFD4A017);

  @override
  Widget build(BuildContext context) {
    if (!isPlus && !isPro) return const SizedBox.shrink();
    final color = isPro ? _gold : _silver;
    final label = isPro ? 'PRO' : 'Plus';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('🧭', style: TextStyle(fontSize: 11)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }
}
