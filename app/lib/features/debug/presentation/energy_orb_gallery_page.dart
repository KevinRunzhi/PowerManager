import 'package:flutter/material.dart';
import 'package:power_manager/app/theme/app_colors.dart';
import 'package:power_manager/app/theme/app_spacing.dart';
import 'package:power_manager/features/home/presentation/energy_orb/energy_orb.dart';

class EnergyOrbGalleryPage extends StatelessWidget {
  const EnergyOrbGalleryPage({super.key});

  static const pageKey = Key('energy-orb-gallery-page');

  static const _states = <({String label, int estimate, bool active})>[
    (label: '未点亮', estimate: 100, active: false),
    (label: '充足 80%', estimate: 80, active: true),
    (label: '平静 50%', estimate: 50, active: true),
    (label: '中低 25%', estimate: 25, active: true),
    (label: '低 0%', estimate: 0, active: true),
    (label: '估计透支', estimate: -20, active: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: pageKey,
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(title: const Text('Stage18 · 能量球状态基准')),
      body: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.x2),
        child: GridView.builder(
          itemCount: _states.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.92,
            crossAxisSpacing: AppSpacing.x2,
            mainAxisSpacing: AppSpacing.x2,
          ),
          itemBuilder: (context, index) {
            final state = _states[index];
            return DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.backgroundRaised,
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.x2),
                    child: Text(
                      state.label,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  Expanded(
                    child: EnergyOrb(
                      key: Key('gallery-orb-$index'),
                      estimate: state.estimate,
                      initialEstimate: 100,
                      energyActivated: state.active,
                      morningCompleted: state.active,
                      diameterOverride: 126,
                      timeOverride: 18,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
