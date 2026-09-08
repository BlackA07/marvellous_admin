// lib/features/products/presentation/widgets/add_product_live_location.dart
//
// Screen open hote hi admin ki live location auto fetch hoti hai.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/live_location_service.dart';

class AddProductLiveLocation extends StatefulWidget {
  final Color cardColor, textColor, accentColor;
  final LiveLocationResult? initialValue;
  final ValueChanged<LiveLocationResult?> onChanged;

  const AddProductLiveLocation({
    Key? key,
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
    required this.onChanged,
    this.initialValue,
  }) : super(key: key);

  @override
  State<AddProductLiveLocation> createState() =>
      _AddProductLiveLocationState();
}

class _AddProductLiveLocationState extends State<AddProductLiveLocation> {
  LiveLocationResult? _result;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _result = widget.initialValue;
    // Har dafa screen open hone par fresh location.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await LiveLocationService.fetchCurrentLocation();
      if (!mounted) return;
      setState(() {
        _result = res;
        _loading = false;
      });
      widget.onChanged(res);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _error != null
                  ? Colors.red.shade200
                  : Colors.grey.shade300,
            ),
          ),
          child: _loading
              ? _buildLoading()
              : _error != null
              ? _buildError()
              : _result == null
              ? _buildEmpty()
              : _buildResult(_result!),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Row(
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: widget.accentColor,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            "Aapki live location le rahe hain...",
            style: GoogleFonts.comicNeue(
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Row(
      children: [
        const Icon(Icons.location_off_outlined, color: Colors.black26),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            "Location abhi tak nahi mili.",
            style: GoogleFonts.comicNeue(
              color: Colors.black45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _retryButton(),
      ],
    );
  }

  Widget _buildError() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _error!,
            style: GoogleFonts.comicNeue(
              color: Colors.red.shade400,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        _retryButton(),
      ],
    );
  }

  Widget _retryButton() {
    return TextButton.icon(
      onPressed: _fetch,
      icon: Icon(Icons.refresh, size: 16, color: widget.accentColor),
      label: Text(
        "Retry",
        style: GoogleFonts.comicNeue(
          color: widget.accentColor,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildResult(LiveLocationResult r) {
    final chips = <List<String>>[
      if (r.houseNumber.isNotEmpty) ['House / Plot', r.houseNumber],
      if (r.building.isNotEmpty) ['Building', r.building],
      if (r.street.isNotEmpty) ['Street', r.street],
      if (r.area.isNotEmpty) ['Area', r.area],
      if (r.city.isNotEmpty) ['City', r.city],
      if (r.state.isNotEmpty) ['State', r.state],
      if (r.country.isNotEmpty) ['Country', r.country],
      if (r.postalCode.isNotEmpty) ['Postal', r.postalCode],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.my_location, color: widget.accentColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                r.hasAddress ? r.fullAddress : r.shortLine,
                style: GoogleFonts.comicNeue(
                  color: Colors.black87,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                ),
              ),
            ),
            IconButton(
              tooltip: "Location dobara lein",
              splashRadius: 18,
              onPressed: _fetch,
              icon: Icon(Icons.refresh, size: 18, color: widget.accentColor),
            ),
          ],
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: chips
                .map(
                  (c) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.accentColor.withOpacity(0.25),
                      ),
                    ),
                    child: Text(
                      "${c[0]}: ${c[1]}",
                      style: GoogleFonts.comicNeue(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: widget.accentColor,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          "Lat: ${r.latitude.toStringAsFixed(6)}  ·  Lng: ${r.longitude.toStringAsFixed(6)}",
          style: GoogleFonts.comicNeue(
            fontSize: 11.5,
            color: Colors.black38,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              color: widget.accentColor,
              margin: const EdgeInsets.only(right: 10),
            ),
            Text(
              "Live Location (Auto)",
              style: GoogleFonts.orbitron(
                color: widget.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 10),
      ],
    );
  }
}
