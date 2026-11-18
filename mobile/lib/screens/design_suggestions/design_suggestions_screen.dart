import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../services/room_service.dart';
import '../product_selection/product_category_selection_screen.dart';

class DesignSuggestionsScreen extends StatefulWidget {
  const DesignSuggestionsScreen({
    super.key,
    required this.roomId,
    this.imagePath,
  });

  final String roomId;
  final String? imagePath;

  @override
  State<DesignSuggestionsScreen> createState() =>
      _DesignSuggestionsScreenState();
}

class _DesignSuggestionsScreenState
    extends State<DesignSuggestionsScreen> {
  final RoomService _roomService = RoomService();

  Timer? _pollingTimer;
  bool _requestRunning = false;
  String _status = 'starting';
  String? _error;
  Map<String, dynamic>? _advice;

  @override
  void initState() {
    super.initState();
    _startSuggestions();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _startSuggestions() async {
    if (_requestRunning || widget.roomId.isEmpty) {
      return;
    }

    _requestRunning = true;
    _pollingTimer?.cancel();

    if (mounted) {
      setState(() {
        _status = 'starting';
        _error = null;
      });
    }

    try {
      final response =
          await _roomService.startDesignSuggestions(widget.roomId);
      _applyResponse(response);

      if (_status == 'generating') {
        _startPolling();
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _status = 'failed';
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = 'failed';
          _error = 'Unable to generate design suggestions.';
        });
      }
    } finally {
      _requestRunning = false;
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _pollSuggestions(),
    );
  }

  Future<void> _pollSuggestions() async {
    if (_requestRunning || !mounted) {
      return;
    }

    _requestRunning = true;

    try {
      final response =
          await _roomService.getDesignSuggestions(widget.roomId);
      _applyResponse(response);

      if (_status == 'completed' || _status == 'failed') {
        _pollingTimer?.cancel();
      }
    } on ApiException catch (error) {
      if (error.statusCode == 401 && mounted) {
        setState(() {
          _status = 'failed';
          _error = error.message;
        });
        _pollingTimer?.cancel();
      }
    } finally {
      _requestRunning = false;
    }
  }

  void _applyResponse(Map<String, dynamic> response) {
    if (!mounted) return;

    final status = response['status']?.toString().toLowerCase() ?? 'generating';
    final rawAdvice = response['advice'];

    setState(() {
      _status = status;
      _error = response['error']?.toString();
      if (rawAdvice is Map) {
        _advice = rawAdvice.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    });
  }

  List<String> _list(String key) {
    final value = _advice?[key];
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _text(String key, {String fallback = ''}) {
    final value = _advice?[key]?.toString().trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  List<Map<String, dynamic>> _categories() {
    final value = _advice?['categoryRecommendations'];
    if (value is! List) return const [];

    return value.whereType<Map>().map((item) {
      return item.map((key, value) => MapEntry(key.toString(), value));
    }).toList();
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
          'Design Suggestions',
          style: TextStyle(
            color: AppColors.forestDark,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _status == 'completed' && _advice != null
            ? _buildCompleted()
            : _status == 'failed'
                ? _buildFailed()
                : _buildGenerating(),
      ),
    );
  }

  Widget _buildGenerating() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.white,
                size: 38,
              ),
            ),
            const SizedBox(height: 26),
            const Text(
              'Creating your design direction',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'RoomStylo is turning your room analysis into practical style, colour, layout and product-category suggestions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 26),
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.forest,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailed() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 42,
              ),
              const SizedBox(height: 14),
              const Text(
                'Suggestions could not be completed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Please try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _startSuggestions,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompleted() {
    final categories = _categories();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.imagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
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
                      size: 42,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ROOMSTYLO DIRECTION',
                  style: TextStyle(
                    color: AppColors.goldLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _text('recommendedStyle', fallback: 'Recommended Style'),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _text('designDirection'),
                  style: const TextStyle(
                    color: Color(0xFFE5EEE9),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                if (_text('styleReason').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    _text('styleReason'),
                    style: const TextStyle(
                      color: Color(0xFFC9DCD2),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          _PaletteCard(colors: _list('colorPalette')),
          const SizedBox(height: 18),
          const _SectionTitle(
            icon: Icons.chair_alt_rounded,
            title: 'Recommended Categories',
          ),
          const SizedBox(height: 10),
          if (categories.isEmpty)
            const _EmptyCard(text: 'No product categories suggested.')
          else
            ...categories.map((category) => _CategoryCard(data: category)),
          const SizedBox(height: 6),
          _SuggestionListCard(
            icon: Icons.grid_view_rounded,
            title: 'Layout Suggestions',
            items: _list('layoutSuggestions'),
          ),
          _SuggestionListCard(
            icon: Icons.check_circle_outline_rounded,
            title: 'Keep',
            items: _list('keepItems'),
          ),
          _SuggestionListCard(
            icon: Icons.tune_rounded,
            title: 'Improve',
            items: _list('improveItems'),
          ),
          _SuggestionListCard(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Designer Notes',
            items: _list('notes'),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductCategorySelectionScreen(
                      roomId: widget.roomId,
                      imagePath: widget.imagePath,
                      recommendedCategories: categories,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Select Product Categories'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.forest, size: 21),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PaletteCard extends StatelessWidget {
  const _PaletteCard({required this.colors});
  final List<String> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.palette_outlined,
            title: 'Suggested Palette',
          ),
          const SizedBox(height: 14),
          if (colors.isEmpty)
            const Text(
              'No palette suggested.',
              style: TextStyle(color: AppColors.textLight),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: colors
                  .map(
                    (color) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        color,
                        style: const TextStyle(
                          color: AppColors.forestDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.data});
  final Map<String, dynamic> data;

  List<String> get characteristics {
    final value = data['suggestedCharacteristics'];
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final priority = data['priority']?.toString().toLowerCase() ?? 'medium';
    final priorityLabel = priority.isEmpty
        ? 'Medium'
        : '${priority[0].toUpperCase()}${priority.substring(1)}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data['category']?.toString() ?? 'Category',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$priorityLabel priority',
                  style: const TextStyle(
                    color: AppColors.goldDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data['reason']?.toString() ?? '',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (characteristics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: characteristics
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestionListCard extends StatelessWidget {
  const _SuggestionListCard({
    required this.icon,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: icon, title: title),
          const SizedBox(height: 13),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textLight),
      ),
    );
  }
}
