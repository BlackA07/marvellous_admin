// lib/features/coupons/screens/widgets/coupon_customer_picker.dart
//
// Multi-select dialog for "specific customers" coupons. Search matches name,
// email and phone, with an active / inactive filter and a shortcut to select
// everything currently filtered.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/common/widgets/user_avatar.dart';
import '../../controllers/coupon_editor_controller.dart';
import '../../models/coupon_model.dart';
import 'coupon_ui.dart';

Future<List<CouponCustomerRef>?> showCouponCustomerPicker(
  BuildContext context, {
  required CouponEditorController controller,
  required List<CouponCustomerRef> initial,
}) {
  return showDialog<List<CouponCustomerRef>>(
    context: context,
    builder: (_) =>
        _CustomerPickerDialog(controller: controller, initial: initial),
  );
}

enum _MemberFilter { all, active, inactive }

class _CustomerPickerDialog extends StatefulWidget {
  final CouponEditorController controller;
  final List<CouponCustomerRef> initial;

  const _CustomerPickerDialog({
    required this.controller,
    required this.initial,
  });

  @override
  State<_CustomerPickerDialog> createState() => _CustomerPickerDialogState();
}

class _CustomerPickerDialogState extends State<_CustomerPickerDialog> {
  late final List<CouponCustomerRef> _selected = List.of(widget.initial);
  String _query = '';
  _MemberFilter _filter = _MemberFilter.all;

  @override
  void initState() {
    super.initState();
    widget.controller.ensureCustomers();
  }

  List<CouponCustomerRef> _filtered(List<CouponCustomerRef> all) {
    final q = _query.trim().toLowerCase();
    return all.where((c) {
      if (_filter == _MemberFilter.active && !c.isActiveMember) return false;
      if (_filter == _MemberFilter.inactive && c.isActiveMember) return false;
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kCouponSurface,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: Obx(() {
          final all = widget.controller.allCustomers;
          final list = _filtered(all);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 10, 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_search_outlined,
                      color: kCouponAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Select Customers',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: () =>
                          widget.controller.ensureCustomers(force: true),
                      icon: const Icon(
                        Icons.refresh,
                        size: 19,
                        color: Colors.white54,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        size: 19,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: CouponSearchField(
                  hint: 'Search by name, email or phone...',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: Row(
                  children: [
                    CouponChip(
                      label: 'All (${all.length})',
                      selected: _filter == _MemberFilter.all,
                      onTap: () => setState(() => _filter = _MemberFilter.all),
                    ),
                    const SizedBox(width: 8),
                    CouponChip(
                      label:
                          'Active (${all.where((c) => c.isActiveMember).length})',
                      icon: Icons.verified_user_outlined,
                      selected: _filter == _MemberFilter.active,
                      onTap: () =>
                          setState(() => _filter = _MemberFilter.active),
                    ),
                    const SizedBox(width: 8),
                    CouponChip(
                      label:
                          'Inactive (${all.where((c) => !c.isActiveMember).length})',
                      icon: Icons.person_off_outlined,
                      selected: _filter == _MemberFilter.inactive,
                      onTap: () =>
                          setState(() => _filter = _MemberFilter.inactive),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              const Divider(height: 1, color: kCouponBorder),

              Expanded(
                child: widget.controller.isLoadingCustomers.value && all.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: kCouponAccent),
                      )
                    : list.isEmpty
                    ? const Center(
                        child: Text(
                          'No customers found',
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final customer = list[i];
                          final selected = _selected.contains(customer);
                          return _CustomerRow(
                            customer: customer,
                            selected: selected,
                            onTap: () => setState(() {
                              selected
                                  ? _selected.remove(customer)
                                  : _selected.add(customer);
                            }),
                          );
                        },
                      ),
              ),

              const Divider(height: 1, color: kCouponBorder),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_selected.length} selected',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: list.isEmpty
                          ? null
                          : () => setState(() {
                              for (final c in list) {
                                if (!_selected.contains(c)) _selected.add(c);
                              }
                            }),
                      child: const Text('Select filtered'),
                    ),
                    TextButton(
                      onPressed: _selected.isEmpty
                          ? null
                          : () => setState(_selected.clear),
                      child: const Text('Clear'),
                    ),
                    const SizedBox(width: 6),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, List.of(_selected)),
                      style: FilledButton.styleFrom(
                        backgroundColor: kCouponAccent,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  final CouponCustomerRef customer;
  final bool selected;
  final VoidCallback onTap;

  const _CustomerRow({
    required this.customer,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: selected
              ? kCouponAccent.withValues(alpha: 0.10)
              : kCouponSurfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? kCouponAccent : kCouponBorder),
        ),
        child: Row(
          children: [
            UserAvatar(
              uid: customer.uid,
              name: customer.name,
              imageData: customer.image,
              size: 38,
              background: Colors.white10,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          customer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: customer.isActiveMember
                              ? Colors.green.withValues(alpha: 0.18)
                              : Colors.orange.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          customer.isActiveMember ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: customer.isActiveMember
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (customer.email.isNotEmpty) customer.email,
                      if (customer.phone.isNotEmpty) customer.phone,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 20,
              color: selected ? kCouponAccent : Colors.white24,
            ),
          ],
        ),
      ),
    );
  }
}
