// Path: lib/features/finances/presentation/tabs/fines_history_tab.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controller/admin_finance_controller.dart';

class FinesHistoryTab extends StatelessWidget {
  final AdminFinanceController controller;
  const FinesHistoryTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF222222),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: TextField(
        style: const TextStyle(color: Colors.white, fontSize: 13),
        onChanged: (v) {
          controller.finesSearchQuery.value = v;
          controller.applyFinesFilter();
        },
        decoration: InputDecoration(
          hintText: 'Search fine by name, phone, description...',
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
          prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
          suffixIcon: Obx(
            () => controller.finesSearchQuery.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: Colors.white38,
                      size: 16,
                    ),
                    onPressed: () {
                      controller.finesSearchQuery.value = '';
                      controller.applyFinesFilter();
                    },
                  )
                : const SizedBox.shrink(),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return Obx(() {
      final entries = controller.filteredFinesEntries;
      if (entries.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gavel, size: 60, color: Colors.white12),
              const SizedBox(height: 16),
              Text(
                'No fines found.',
                style: GoogleFonts.comicNeue(
                  color: Colors.white38,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final entry = entries[i];
          final identity =
              entry.linkedUserName ??
              entry.linkedUserPhone ??
              entry.linkedUserEmail ??
              'Unknown User';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orangeAccent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        identity,
                        style: GoogleFonts.comicNeue(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.description,
                        style: GoogleFonts.comicNeue(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Category: ${AdminFinanceController.categoryLabel(entry.category)}',
                        style: GoogleFonts.comicNeue(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs. ${entry.amount.toStringAsFixed(0)}',
                      style: GoogleFonts.comicNeue(
                        color: Colors.orangeAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yy, hh:mm a').format(entry.date),
                      style: GoogleFonts.comicNeue(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
