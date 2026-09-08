import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/announcement_list_controller.dart';
import '../models/announcement_model.dart';
import 'add_announcement_screen.dart';

class AnnouncementListScreen extends StatelessWidget {
  const AnnouncementListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AnnouncementListController());

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const AddAnnouncementScreen()),
        icon: const Icon(Icons.add),
        label: const Text('Add Announcement'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.announcements.isEmpty) {
          return const Center(
            child: Text('No announcements yet. Tap + to add one.'),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatsBar(controller: controller),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  int crossAxisCount = 1;
                  if (width > 1100) {
                    crossAxisCount = 3;
                  } else if (width > 700) {
                    crossAxisCount = 2;
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 1.4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: controller.announcements.length,
                    itemBuilder: (context, index) {
                      return _AnnouncementCard(
                        announcement: controller.announcements[index],
                        controller: controller,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _StatsBar extends StatelessWidget {
  final AnnouncementListController controller;
  const _StatsBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B3A), Color(0xFF2A2450)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Total', value: '${controller.announcements.length}'),
          _StatItem(label: 'Active', value: '${controller.activeCount}'),
          _StatItem(
            label: 'Inactive',
            value: '${controller.announcements.length - controller.activeCount}',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final AnnouncementListController controller;
  const _AnnouncementCard({
    required this.announcement,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: announcement.backgroundColor,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    child: Text(
                      announcement.message,
                      textAlign: announcement.align,
                      style: announcement.toTextStyle(),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _ActiveBadge(isActive: announcement.isActive),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat(
                      'dd MMM yyyy',
                    ).format(announcement.updatedAt ?? announcement.createdAt),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
                Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: announcement.isActive,
                    activeThumbColor: Colors.green,
                    onChanged: (_) => controller.toggleActive(announcement),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.visibility, size: 18),
                  tooltip: 'View',
                  onPressed: () => _showFull(context),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: 'Edit',
                  onPressed: () => Get.to(
                    () =>
                        AddAnnouncementScreen(editAnnouncement: announcement),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  tooltip: 'Delete',
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFull(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: announcement.backgroundColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      announcement.message,
                      textAlign: announcement.align,
                      style: announcement.toTextStyle(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _MetaRow(announcement: announcement),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text(
          'Are you sure you want to delete this announcement?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              controller.deleteAnnouncement(announcement.id);
              Get.back();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final AnnouncementModel announcement;
  const _MetaRow({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        _chip('Font: ${announcement.fontFamily}'),
        _chip('Size: ${announcement.fontSize.toStringAsFixed(0)}'),
        _chip('Text: ${announcement.textColorHex}'),
        _chip('BG: ${announcement.backgroundColorHex}'),
        _chip('Align: ${announcement.textAlign}'),
        if (announcement.isBold) _chip('Bold'),
        if (announcement.isItalic) _chip('Italic'),
      ],
    );
  }

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white24),
    ),
    child: Text(text, style: const TextStyle(fontSize: 11)),
  );
}

class _ActiveBadge extends StatelessWidget {
  final bool isActive;
  const _ActiveBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.grey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
