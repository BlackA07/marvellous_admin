import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../model/staff_model.dart';

class StaffDetailScreen extends StatelessWidget {
  final StaffModel staff;

  const StaffDetailScreen({super.key, required this.staff});

  // Theme Colors
  static const Color _bg = Color(0xFF0D0D1A);
  static const Color _surface = Color(0xFF1A1A2E);
  static const Color _cardBorder = Color(0xFF2A2A4A);
  static const Color _accent = Color(0xFF4F8EF7);
  static const Color _textWhite = Color(0xFFEAEAFF);
  static const Color _textMid = Color(0xFF9090B0);
  static const Color _green = Color(0xFF00E5CC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        foregroundColor: _textWhite,
        title: const Text(
          'Staff Details',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSection('Personal Information', Icons.person_rounded, [
              _infoRow('CNIC', staff.cnic),
              _infoRow('Father Name', staff.fatherName),
              _infoRow('Mobile 1', staff.mobile1),
              if (staff.mobile2 != null) _infoRow('Mobile 2', staff.mobile2!),
              if (staff.email != null) _infoRow('Email', staff.email!),
              _infoRow('Address', staff.address),
            ]),
            const SizedBox(height: 16),
            _buildSection('Employment Details', Icons.work_rounded, [
              _infoRow(
                'Type',
                staff.employmentType.toUpperCase(),
                isHighlight: true,
              ),
              _infoRow(
                'Joining Date',
                DateFormat('dd MMM yyyy').format(staff.joiningDate),
              ),
              _infoRow(
                'Total Payable',
                'Rs. ${(staff.totalMonthlyPayable ?? 0).toStringAsFixed(0)}',
                isHighlight: true,
                highlightColor: _green,
              ),
              if (staff.salaryAmount != null && staff.salaryAmount! > 0)
                _infoRow(
                  'Base Salary',
                  'Rs. ${staff.salaryAmount!.toStringAsFixed(0)} (${staff.salaryFrequency})',
                ),
            ]),
            const SizedBox(height: 16),
            if (staff.employmentType != 'salary' &&
                staff.commissionRegions.isNotEmpty)
              _buildSection('Commission & Fuel', Icons.percent_rounded, [
                _infoRow('Regions', staff.commissionRegions.join(', ')),
                if (staff.productComFix != null)
                  _infoRow('Product Fixed Com', 'Rs. ${staff.productComFix}'),
                if (staff.productComPerc != null)
                  _infoRow('Product Perc Com', '${staff.productComPerc}%'),
                if (staff.fuelPerKm != null && staff.fuelPerKm! > 0)
                  _infoRow(
                    'Fuel Allowance',
                    'Rs. ${staff.fuelPerKm!.toStringAsFixed(2)} / km',
                  ),
              ]),
            const SizedBox(height: 16),
            _buildSection('Work Timings', Icons.access_time_rounded, [
              _infoRow(
                'Shift',
                '${staff.onTimeHour.toString().padLeft(2, '0')}:${staff.onTimeMinute.toString().padLeft(2, '0')} ${staff.onTimePeriod} - ${staff.offTimeHour.toString().padLeft(2, '0')}:${staff.offTimeMinute.toString().padLeft(2, '0')} ${staff.offTimePeriod}',
              ),
              _infoRow('Weekly Off', staff.weeklyOffs.join(', ')),
              _infoRow(
                'Location Track',
                staff.attendanceByLocation ? 'Enabled' : 'Disabled',
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: _accent.withOpacity(0.15),
            child: Text(
              staff.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: _accent,
                fontWeight: FontWeight.w800,
                fontSize: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            staff.name,
            style: const TextStyle(
              color: _textWhite,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              staff.designation,
              style: const TextStyle(
                color: _accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _accent, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: _textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: _cardBorder, height: 1),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool isHighlight = false,
    Color? highlightColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: _textMid,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isHighlight ? (highlightColor ?? _accent) : _textWhite,
                fontSize: isHighlight ? 15 : 14,
                fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
