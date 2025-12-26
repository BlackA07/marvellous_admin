import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product_model.dart';

class ProductTable extends StatelessWidget {
  final List<ProductModel> products;
  final Function(ProductModel) onEdit;
  final Function(String) onDelete;
  final Function(ProductModel) onView;

  const ProductTable({
    Key? key,
    required this.products,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.white10),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(
            Colors.white.withOpacity(0.05),
          ),
          dataRowHeight: 70, // Thora height badhaya images k liye
          horizontalMargin: 20,
          columnSpacing: 20,
          columns: [
            DataColumn(label: _headerText("Product")),
            DataColumn(label: _headerText("Category")),
            DataColumn(label: _headerText("Price")),
            DataColumn(label: _headerText("Stock")),
            DataColumn(label: _headerText("Actions")),
          ],
          rows: products.map((product) {
            return DataRow(
              cells: [
                // 1. Image & Name
                DataCell(
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                          image: product.images.isNotEmpty
                              ? DecorationImage(
                                  image: AssetImage(
                                    product.images.first,
                                  ), // NetworkImage agar URL ho
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: product.images.isEmpty
                            ? const Icon(Icons.image, color: Colors.white24)
                            : null,
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            product.name,
                            style: GoogleFonts.comicNeue(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            product.modelNumber,
                            style: GoogleFonts.comicNeue(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 2. Category
                DataCell(
                  Text(
                    product.category,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                // 3. Price
                DataCell(
                  Text(
                    "\$${product.salePrice}",
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 4. Stock Badge
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: product.stockQuantity < 10
                          ? Colors.red.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: product.stockQuantity < 10
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                    child: Text(
                      "${product.stockQuantity} Left",
                      style: TextStyle(
                        color: product.stockQuantity < 10
                            ? Colors.redAccent
                            : Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // 5. Actions
                DataCell(
                  Row(
                    children: [
                      _actionBtn(
                        Icons.visibility,
                        Colors.blueAccent,
                        () => onView(product),
                      ),
                      const SizedBox(width: 8),
                      _actionBtn(
                        Icons.edit,
                        Colors.orangeAccent,
                        () => onEdit(product),
                      ),
                      const SizedBox(width: 8),
                      _actionBtn(
                        Icons.delete,
                        Colors.redAccent,
                        () => onDelete(product.id!),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(
      text,
      style: GoogleFonts.orbitron(
        color: Colors.white54,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
