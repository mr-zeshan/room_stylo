import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../services/catalog_service.dart';
import 'product_selection_screen.dart';

class ProductCategorySelectionScreen extends StatefulWidget {
  const ProductCategorySelectionScreen({
    super.key,
    required this.roomId,
    required this.recommendedCategories,
    this.imagePath,
  });

  final String roomId;
  final String? imagePath;
  final List<Map<String, dynamic>> recommendedCategories;

  @override
  State<ProductCategorySelectionScreen> createState() =>
      _ProductCategorySelectionScreenState();
}

class _ProductCategorySelectionScreenState
    extends State<ProductCategorySelectionScreen> {
  final CatalogService _catalogService = CatalogService();

  List<Map<String, dynamic>> _categories = [];
  final Set<String> _selectedIds = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  static String _normalize(String value) {
    final normalized = value.trim().toLowerCase();

    const aliases = <String, String>{
      'sofas': 'sofa',
      'chairs': 'chair',
      'coffee tables': 'coffee table',
      'side tables': 'side table',
      'carpets': 'carpet',
      'rugs': 'rug',
      'curtain': 'curtains',
      'wallpapers': 'wallpaper',
      'lamps': 'lamp',
      'floor lamps': 'floor lamp',
      'table lamps': 'table lamp',
      'artificial plants': 'artificial plant',
      'plants': 'artificial plant',
      'plant': 'artificial plant',
      'wall arts': 'wall art',
      'mirrors': 'mirror',
      'cushion': 'cushions',
      'decor': 'decoration pieces',
      'decor pieces': 'decoration pieces',
      'decoration piece': 'decoration pieces',
    };

    return aliases[normalized] ?? normalized;
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final categories = await _catalogService.getCategories();

      final recommendedKeys = widget.recommendedCategories
          .map((item) => _normalize(item['category']?.toString() ?? ''))
          .where((item) => item.isNotEmpty)
          .toSet();

      final selectedIds = <String>{};

      for (final category in categories) {
        final nameKey = _normalize(category['name']?.toString() ?? '');
        final slugKey = _normalize(
          (category['slug']?.toString() ?? '').replaceAll('-', ' '),
        );

        if (recommendedKeys.contains(nameKey) ||
            recommendedKeys.contains(slugKey)) {
          final id = category['id']?.toString();
          if (id != null && id.isNotEmpty) {
            selectedIds.add(id);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _selectedIds
          ..clear()
          ..addAll(selectedIds);
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load product categories.';
      });
    }
  }

  Map<String, dynamic>? _recommendationFor(Map<String, dynamic> category) {
    final nameKey = _normalize(category['name']?.toString() ?? '');
    final slugKey = _normalize(
      (category['slug']?.toString() ?? '').replaceAll('-', ' '),
    );

    for (final item in widget.recommendedCategories) {
      final key = _normalize(item['category']?.toString() ?? '');
      if (key == nameKey || key == slugKey) {
        return item;
      }
    }
    return null;
  }

  IconData _iconFor(String iconKey, String name) {
    switch (iconKey.trim().toLowerCase()) {
      case 'sofa':
        return Icons.weekend_rounded;
      case 'chair':
        return Icons.chair_alt_rounded;
      case 'coffee_table':
        return Icons.table_restaurant_rounded;
      case 'side_table':
        return Icons.table_bar_rounded;
      case 'carpet':
        return Icons.texture_rounded;
      case 'rug':
        return Icons.grid_on_rounded;
      case 'curtains':
        return Icons.curtains_rounded;
      case 'wallpaper':
        return Icons.wallpaper_rounded;
      case 'lamp':
        return Icons.light_rounded;
      case 'floor_lamp':
        return Icons.lightbulb_outline_rounded;
      case 'table_lamp':
        return Icons.light_mode_outlined;
      case 'plant':
        return Icons.local_florist_rounded;
      case 'wall_art':
        return Icons.image_rounded;
      case 'mirror':
        return Icons.crop_portrait_rounded;
      case 'cushions':
        return Icons.airline_seat_individual_suite_rounded;
      case 'decor':
        return Icons.auto_awesome_rounded;
      default:
        final key = _normalize(name);
        if (key.contains('lamp')) return Icons.light_rounded;
        if (key.contains('table')) return Icons.table_restaurant_rounded;
        return Icons.chair_rounded;
    }
  }

  void _toggleCategory(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _continueToProducts() {
    if (_selectedIds.isEmpty) return;

    final selectedCategories = _categories
        .where((item) => _selectedIds.contains(item['id']?.toString()))
        .toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductSelectionScreen(
          roomId: widget.roomId,
          imagePath: widget.imagePath,
          selectedCategories: selectedCategories,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Choose Categories',
          style: TextStyle(
            color: AppColors.forestDark,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _error != null
                      ? _ErrorState(
                          message: _error!,
                          onRetry: _loadCategories,
                        )
                      : RefreshIndicator(
                          onRefresh: _loadCategories,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.imagePath != null) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: Image.file(
                                        File(widget.imagePath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: AppColors.surfaceSoft,
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.image_not_supported_outlined,
                                            color: AppColors.textLight,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(19),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'BUILD YOUR ROOM',
                                        style: TextStyle(
                                          color: AppColors.goldLight,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'What would you like to change?',
                                        style: TextStyle(
                                          color: AppColors.white,
                                          fontSize: 23,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'RoomStylo has pre-selected the AI recommendations. Keep them, remove them, or add anything else you want in the redesigned room.',
                                        style: TextStyle(
                                          color: Color(0xFFE5EEE9),
                                          fontSize: 13,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Product Categories',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 11,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceSoft,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        '${_selectedIds.length} selected',
                                        style: const TextStyle(
                                          color: AppColors.forestDark,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Categories are loaded from the RoomStylo catalog. AI recommendations are marked below.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _categories.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1.18,
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = _categories[index];
                                    final id = item['id']?.toString() ?? '';
                                    final recommendation =
                                        _recommendationFor(item);

                                    return _CategoryTile(
                                      label: item['name']?.toString() ?? 'Category',
                                      icon: _iconFor(
                                        item['iconKey']?.toString() ?? '',
                                        item['name']?.toString() ?? '',
                                      ),
                                      selected: _selectedIds.contains(id),
                                      recommended: recommendation != null,
                                      priority:
                                          recommendation?['priority']?.toString() ??
                                              '',
                                      onTap: id.isEmpty
                                          ? () {}
                                          : () => _toggleCategory(id),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _loading || _selectedIds.isEmpty
                      ? null
                      : _continueToProducts,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    _selectedIds.isEmpty
                        ? 'Select at least one category'
                        : 'Continue to Products (${_selectedIds.length})',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.recommended,
    required this.priority,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool recommended;
  final String priority;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final normalizedPriority = priority.trim().toLowerCase();
    final priorityLabel = normalizedPriority.isEmpty
        ? ''
        : '${normalizedPriority[0].toUpperCase()}${normalizedPriority.substring(1)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF0F5F1) : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.forest : AppColors.divider,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.forest
                          : AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      icon,
                      color: selected
                          ? AppColors.white
                          : AppColors.forestDark,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: selected ? AppColors.forest : AppColors.textLight,
                    size: 23,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (recommended) ...[
                const SizedBox(height: 7),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5DF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'AI Recommended',
                        style: TextStyle(
                          color: AppColors.goldDark,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (priorityLabel.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          priorityLabel,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.textLight,
              size: 46,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
