import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../services/catalog_service.dart';
import '../../services/room_service.dart';
import '../placement/placement_plan_screen.dart';

class ProductSelectionScreen extends StatefulWidget {
  const ProductSelectionScreen({
    super.key,
    required this.roomId,
    required this.selectedCategories,
    this.imagePath,
  });

  final String roomId;
  final String? imagePath;
  final List<Map<String, dynamic>> selectedCategories;

  @override
  State<ProductSelectionScreen> createState() => _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends State<ProductSelectionScreen> {
  final CatalogService _catalogService = CatalogService();
  final RoomService _roomService = RoomService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _products = [];
  final Set<String> _selectedProductIds = {};
  bool _loading = true;
  bool _continuing = false;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categoryIds => widget.selectedCategories
      .map((item) => item['id']?.toString() ?? '')
      .where((id) => id.isNotEmpty)
      .toList();

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final products = await _catalogService.getProducts(
        categoryIds: _categoryIds,
      );

      if (!mounted) return;
      setState(() {
        _products = products;
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
        _error = 'Unable to load products.';
      });
    }
  }

  List<Map<String, dynamic>> get _visibleProducts {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return _products;

    return _products.where((product) {
      final values = [
        product['name'],
        product['color'],
        product['style'],
        product['material'],
        (product['category'] as Map?)?['name'],
      ].map((value) => value?.toString().toLowerCase() ?? '');

      return values.any((value) => value.contains(query));
    }).toList();
  }

  void _toggleProduct(String id) {
    setState(() {
      if (_selectedProductIds.contains(id)) {
        _selectedProductIds.remove(id);
      } else {
        _selectedProductIds.add(id);
      }
    });
  }

  String _priceText(Map<String, dynamic> product) {
    final min = double.tryParse(product['priceMin']?.toString() ?? '');
    final max = double.tryParse(product['priceMax']?.toString() ?? '');

    String money(double value) {
      final rounded = value.round();
      return 'PKR ${rounded.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      )}';
    }

    if (min != null && max != null) {
      if (min == max) return money(min);
      return '${money(min)} – ${money(max)}';
    }
    if (min != null) return 'From ${money(min)}';
    if (max != null) return 'Up to ${money(max)}';
    return 'Price on request';
  }

  Future<void> _continue() async {
    if (_selectedProductIds.isEmpty || _continuing) return;

    setState(() {
      _continuing = true;
    });

    try {
      await _roomService.saveSelectedProducts(
        widget.roomId,
        _selectedProductIds.toList(),
      );

      final placement = await _roomService.startPlacementPlan(
        widget.roomId,
      );

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlacementPlanScreen(
            roomId: widget.roomId,
            placement: placement,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to prepare the placement plan. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _continuing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Select Products',
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
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _ProductErrorState(
                          message: _error!,
                          onRetry: _loadProducts,
                        )
                      : RefreshIndicator(
                          onRefresh: _loadProducts,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            children: [
                              Container(
                                padding: const EdgeInsets.all(19),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'EXACT PRODUCTS',
                                      style: TextStyle(
                                        color: AppColors.goldLight,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Choose what should appear in your room',
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${widget.selectedCategories.length} categories selected • ${_selectedProductIds.length} products chosen',
                                      style: const TextStyle(
                                        color: Color(0xFFE5EEE9),
                                        fontSize: 13,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _searchController,
                                onChanged: (value) {
                                  setState(() => _search = value);
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search products, style, material...',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _search.isEmpty
                                      ? null
                                      : IconButton(
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _search = '');
                                          },
                                          icon: const Icon(Icons.close_rounded),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              if (_products.isEmpty)
                                const _EmptyCatalogState()
                              else if (visible.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 50),
                                  child: Center(
                                    child: Text(
                                      'No products match your search.',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...visible.map(
                                  (product) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _ProductCard(
                                      product: product,
                                      priceText: _priceText(product),
                                      selected: _selectedProductIds.contains(
                                        product['id']?.toString(),
                                      ),
                                      onTap: () {
                                        final id =
                                            product['id']?.toString() ?? '';
                                        if (id.isNotEmpty) {
                                          _toggleProduct(id);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                            ],
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
                  onPressed:
                      _selectedProductIds.isEmpty || _continuing
                          ? null
                          : _continue,
                  icon: _continuing
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    _continuing
                        ? 'Preparing Placement Plan...'
                        : _selectedProductIds.isEmpty
                            ? 'Select at least one product'
                            : 'Continue (${_selectedProductIds.length})',
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.priceText,
    required this.selected,
    required this.onTap,
  });

  final Map<String, dynamic> product;
  final String priceText;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final category = product['category'] is Map
        ? Map<String, dynamic>.from(product['category'] as Map)
        : <String, dynamic>{};

    final images = product['images'] is List
        ? List<dynamic>.from(product['images'] as List)
        : <dynamic>[];

    final firstImage = images
        .map((item) => item?.toString() ?? '')
        .firstWhere((item) => item.isNotEmpty, orElse: () => '');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF0F5F1) : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.forest : AppColors.divider,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: firstImage.isEmpty
                      ? Container(
                          color: AppColors.surfaceSoft,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.chair_rounded,
                            color: AppColors.forest,
                            size: 34,
                          ),
                        )
                      : Image.network(
                          firstImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.surfaceSoft,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.textLight,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product['name']?.toString() ?? 'Product',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: selected
                              ? AppColors.forest
                              : AppColors.textLight,
                          size: 23,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      category['name']?.toString() ?? 'Product',
                      style: const TextStyle(
                        color: AppColors.goldDark,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      priceText,
                      style: const TextStyle(
                        color: AppColors.forestDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      [
                        product['color']?.toString(),
                        product['style']?.toString(),
                        product['material']?.toString(),
                      ]
                          .where((item) => item != null && item.trim().isNotEmpty)
                          .join(' • '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCatalogState extends StatelessWidget {
  const _EmptyCatalogState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 44,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: AppColors.textLight,
            size: 44,
          ),
          SizedBox(height: 13),
          Text(
            'No products added yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Products for the selected categories will appear here after they are added to the RoomStylo catalog.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductErrorState extends StatelessWidget {
  const _ProductErrorState({
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
