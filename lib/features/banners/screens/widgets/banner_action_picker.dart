import 'package:flutter/material.dart';
import '../../repository/banner_action_repository.dart';

/// Result returned from the picker sheet.
class BannerActionResult {
  final String type; // 'product' | 'category'
  final String? productId;
  final String? productName;
  final String? categoryName;
  final String? subCategoryName;

  BannerActionResult.product(this.productId, this.productName)
    : type = 'product',
      categoryName = null,
      subCategoryName = null;

  BannerActionResult.category(this.categoryName, this.subCategoryName)
    : type = 'category',
      productId = null,
      productName = null;
}

Future<BannerActionResult?> showBannerActionPicker(BuildContext context) {
  return showModalBottomSheet<BannerActionResult>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const _ActionPickerSheet(),
  );
}

class _ActionPickerSheet extends StatefulWidget {
  const _ActionPickerSheet();

  @override
  State<_ActionPickerSheet> createState() => _ActionPickerSheetState();
}

class _ActionPickerSheetState extends State<_ActionPickerSheet>
    with SingleTickerProviderStateMixin {
  final _repo = BannerActionRepository();
  late final TabController _tabController;

  List<BannerProductOption> _products = [];
  List<BannerCategoryOption> _categories = [];
  bool _loading = true;
  String _productSearch = '';
  String? _expandedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final products = await _repo.fetchProducts();
    final categories = await _repo.fetchCategories();
    setState(() {
      _products = products;
      _categories = categories;
      _loading = false;
    });
  }

  List<BannerProductOption> get _filteredProducts {
    if (_productSearch.trim().isEmpty) return _products;
    final q = _productSearch.toLowerCase();
    return _products
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.modelNumber.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Text(
              'Select banner target',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Product'),
                Tab(text: 'Category'),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProductTab(scrollController),
                        _buildCategoryTab(scrollController),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductTab(ScrollController scrollController) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by name or model number',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _productSearch = v),
          ),
        ),
        Expanded(
          child: _filteredProducts.isEmpty
              ? const Center(child: Text('No products found'))
              : ListView.builder(
                  controller: scrollController,
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final p = _filteredProducts[index];

                    // build "Model: X · 8GB / 128GB" style subtitle,
                    // only including the parts that actually have data
                    final subtitleParts = <String>[];
                    if (p.modelNumber.isNotEmpty) {
                      subtitleParts.add('Model: ${p.modelNumber}');
                    }
                    final hasRam = p.ram != null && p.ram!.trim().isNotEmpty;
                    final hasStorage =
                        p.storage != null && p.storage!.trim().isNotEmpty;
                    if (hasRam || hasStorage) {
                      final ramText = hasRam ? '${p.ram}GB' : '';
                      final storageText = hasStorage ? '${p.storage}GB' : '';
                      subtitleParts.add(
                        [
                          ramText,
                          storageText,
                        ].where((s) => s.isNotEmpty).join(' / '),
                      );
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: p.imageUrl.isNotEmpty
                            ? NetworkImage(p.imageUrl)
                            : null,
                        child: p.imageUrl.isEmpty
                            ? const Icon(Icons.inventory_2)
                            : null,
                      ),
                      title: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: subtitleParts.isEmpty
                          ? null
                          : Text(subtitleParts.join(' · ')),
                      onTap: () => Navigator.pop(
                        context,
                        BannerActionResult.product(p.id, p.name),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryTab(ScrollController scrollController) {
    if (_categories.isEmpty) {
      return const Center(child: Text('No categories found'));
    }
    return ListView.builder(
      controller: scrollController,
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final isExpanded = _expandedCategory == cat.name;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                cat.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: cat.subCategories.isEmpty
                  ? null
                  : Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              onTap: () {
                if (cat.subCategories.isEmpty) {
                  Navigator.pop(
                    context,
                    BannerActionResult.category(cat.name, null),
                  );
                } else {
                  setState(
                    () => _expandedCategory = isExpanded ? null : cat.name,
                  );
                }
              },
              onLongPress: () => Navigator.pop(
                context,
                BannerActionResult.category(cat.name, null),
              ),
            ),
            if (isExpanded)
              ...cat.subCategories.map(
                (sub) => Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: ListTile(
                    dense: true,
                    title: Text(sub),
                    onTap: () => Navigator.pop(
                      context,
                      BannerActionResult.category(cat.name, sub),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
