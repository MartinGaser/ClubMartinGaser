import 'package:flutter/material.dart';

import '../../data/models/sports_space.dart';

/// Tarjeta utilizada para mostrar un espacio deportivo.
class SportsSpaceCard extends StatelessWidget {
  const SportsSpaceCard({
    super.key,
    required this.sportsSpace,
    required this.onTap,
  });

  final SportsSpace sportsSpace;
  final VoidCallback onTap;

  IconData get _sportIcon {
    return switch (sportsSpace.sportType) {
      SportType.football => Icons.sports_soccer,
      SportType.tennis => Icons.sports_tennis,
      SportType.padel => Icons.sports_tennis,
      SportType.basketball => Icons.sports_basketball,
      SportType.volleyball => Icons.sports_volleyball,
      SportType.swimming => Icons.pool,
      SportType.other => Icons.sports,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _sportIcon,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sportsSpace.name,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sportsSpace.sportType.displayName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (sportsSpace.description != null &&
                        sportsSpace.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(sportsSpace.description!),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
