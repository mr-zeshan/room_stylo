import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class PlacementPlanScreen extends StatelessWidget {
  const PlacementPlanScreen({
    super.key,
    required this.roomId,
    required this.placement,
  });

  final String roomId;
  final Map<String, dynamic> placement;

  Map<String, dynamic> get _plan {
    final value = placement['plan'];
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> get _items {
    final value = _plan['items'];
    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<String> _strings(String key) {
    final value = _plan[key];
    if (value is! List) return [];

    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final status = placement['status']?.toString() ?? '';
    final summary = _plan['summary']?.toString() ?? '';
    final circulation = _strings('circulationNotes');
    final lighting = _strings('lightingNotes');
    final warnings = _strings('warnings');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Placement Plan',
          style: TextStyle(
            color: AppColors.forestDark,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ROOMSTYLO PLACEMENT',
                    style: TextStyle(
                      color: AppColors.goldLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your products have a place',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    summary.isEmpty
                        ? 'Placement plan generated for your selected products.'
                        : summary,
                    style: const TextStyle(
                      color: Color(0xFFE5EEE9),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x22FFFFFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toLowerCase() == 'completed'
                          ? 'Plan Ready'
                          : status,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const _SectionTitle(
              title: 'Product Placement',
              subtitle:
                  'Placement guidance based on your room analysis and exact catalog products.',
            ),
            const SizedBox(height: 12),
            if (_items.isEmpty)
              const _EmptyPlanCard()
            else
              ..._items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PlacementItemCard(item: item),
                ),
              ),
            if (circulation.isNotEmpty) ...[
              const SizedBox(height: 10),
              _NotesCard(
                title: 'Circulation',
                icon: Icons.route_rounded,
                notes: circulation,
              ),
            ],
            if (lighting.isNotEmpty) ...[
              const SizedBox(height: 12),
              _NotesCard(
                title: 'Lighting',
                icon: Icons.light_mode_outlined,
                notes: lighting,
              ),
            ],
            if (warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              _NotesCard(
                title: 'Before Visual Rendering',
                icon: Icons.info_outline_rounded,
                notes: warnings,
              ),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFF0D8A8),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.goldDark,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This plan is the structured placement foundation. Exact perspective, depth, occlusion and photorealistic product insertion are handled in the visual placement stage.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _PlacementItemCard extends StatelessWidget {
  const _PlacementItemCard({
    required this.item,
  });

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final name = item['productName']?.toString() ?? 'Product';
    final category = item['category']?.toString() ?? 'Product';
    final placement = item['placement']?.toString() ?? '';
    final orientation = item['orientation']?.toString() ?? '';
    final scale = item['scaleGuidance']?.toString() ?? '';
    final reason = item['reason']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.chair_rounded,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      category,
                      style: const TextStyle(
                        color: AppColors.goldDark,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (placement.isNotEmpty) ...[
            const SizedBox(height: 15),
            _DetailRow(
              icon: Icons.place_outlined,
              title: 'Placement',
              text: placement,
            ),
          ],
          if (orientation.isNotEmpty) ...[
            const SizedBox(height: 11),
            _DetailRow(
              icon: Icons.screen_rotation_alt_outlined,
              title: 'Orientation',
              text: orientation,
            ),
          ],
          if (scale.isNotEmpty) ...[
            const SizedBox(height: 11),
            _DetailRow(
              icon: Icons.straighten_rounded,
              title: 'Scale',
              text: scale,
            ),
          ],
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 11),
            _DetailRow(
              icon: Icons.psychology_alt_outlined,
              title: 'Why here',
              text: reason,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: AppColors.forest,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.45,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({
    required this.title,
    required this.icon,
    required this.notes,
  });

  final String title;
  final IconData icon;
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.forest,
                size: 21,
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ...notes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: CircleAvatar(
                      radius: 2.3,
                      backgroundColor: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      note,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlanCard extends StatelessWidget {
  const _EmptyPlanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Text(
        'No placement items were returned.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
