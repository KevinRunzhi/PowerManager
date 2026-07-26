import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';

final class HomeCategoryItem {
  const HomeCategoryItem({
    required this.category,
    required this.durationMinutes,
    required this.netDelta,
    required this.grossDelta,
  });

  final ActivityCategory category;
  final int durationMinutes;
  final int netDelta;
  final int grossDelta;
}

final class HomeViewModel {
  HomeViewModel.fromProjection(CurrentDayProjection current)
    : initialEstimate = current.projection.initialEstimate,
      currentEstimate = current.projection.currentEstimate,
      band = current.projection.band,
      categories =
          current.projection.categorySummaries.values
              .where((item) => item.durationMinutes > 0)
              .map(_categoryItem)
              .toList()
            ..sort(_compareCategories);

  final int initialEstimate;
  final int currentEstimate;
  final EstimatedEnergyBand band;
  final List<HomeCategoryItem> categories;

  String get bandLabel => switch (band) {
    EstimatedEnergyBand.estimatedNormal => '平稳',
    EstimatedEnergyBand.estimatedMediumLow => '估计中低',
    EstimatedEnergyBand.estimatedLow => '估计偏低',
    EstimatedEnergyBand.estimatedOverdraft => '估计透支',
  };

  static HomeCategoryItem _categoryItem(CategoryEstimatedSummary item) {
    return HomeCategoryItem(
      category: item.category,
      durationMinutes: item.durationMinutes,
      netDelta: item.netDelta,
      grossDelta: item.grossDelta,
    );
  }

  static int _compareCategories(HomeCategoryItem left, HomeCategoryItem right) {
    final gross = right.grossDelta.compareTo(left.grossDelta);
    return gross != 0
        ? gross
        : left.category.index.compareTo(right.category.index);
  }
}
