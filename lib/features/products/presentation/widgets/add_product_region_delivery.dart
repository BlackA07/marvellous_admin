// lib/features/products/presentation/widgets/add_product_region_delivery.dart
//
// Har selected availability unit (poori country / poora state / single city)
// ki apni delivery fee aur delivery time.
//
// Fee hamesha PKR (base) mein likhi jati hai; saath mein us region ki apni
// currency ka live conversion dikhta hai (currency badli ja sakti hai).
//
// COD fee sirf tab dikhti hai jab koi Pakistan wali unit select ho.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/product_model.dart';
import '../../services/currency_service.dart';

class AddProductRegionDelivery extends StatefulWidget {
  final List<ProductAvailabilityUnit> units;
  final Map<String, double> initialFees;
  final Map<String, String> initialTimes;
  final double initialCodFee;
  final Color cardColor, textColor, accentColor;

  /// (fees, times, codFee)
  final void Function(Map<String, double>, Map<String, String>, double)
  onChanged;

  const AddProductRegionDelivery({
    Key? key,
    required this.units,
    required this.initialFees,
    required this.initialTimes,
    required this.initialCodFee,
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<AddProductRegionDelivery> createState() =>
      _AddProductRegionDeliveryState();
}

class _AddProductRegionDeliveryState extends State<AddProductRegionDelivery> {
  final Map<String, TextEditingController> _feeCtrls = {};
  final Map<String, TextEditingController> _timeCtrls = {};
  final Map<String, String> _rowCurrency = {}; // key → preview currency

  final TextEditingController _codCtrl = TextEditingController();
  final TextEditingController _bulkFeeCtrl = TextEditingController();
  final TextEditingController _bulkTimeCtrl = TextEditingController();

  double _codFee = 0.0;
  bool _ratesLoading = true;

  static const List<String> _timePresets = [
    "1-2 Days",
    "3-5 Days",
    "5-7 Days",
    "7-15 Days",
    "15-30 Days",
  ];

  @override
  void initState() {
    super.initState();
    _codFee = widget.initialCodFee;
    _codCtrl.text = _codFee == 0 ? "" : _trim(_codFee);
    _syncControllers();
    _loadRates();
  }

  @override
  void didUpdateWidget(covariant AddProductRegionDelivery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_keysOf(oldWidget.units) != _keysOf(widget.units)) {
      _syncControllers();
      _emit();
    }
  }

  @override
  void dispose() {
    for (final c in _feeCtrls.values) {
      c.dispose();
    }
    for (final c in _timeCtrls.values) {
      c.dispose();
    }
    _codCtrl.dispose();
    _bulkFeeCtrl.dispose();
    _bulkTimeCtrl.dispose();
    super.dispose();
  }

  String _keysOf(List<ProductAvailabilityUnit> units) =>
      units.map((u) => u.key).join(',');

  String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _loadRates() async {
    await CurrencyService.ensureRates();
    if (mounted) setState(() => _ratesLoading = false);
  }

  /// Naye units ke liye controllers banao, hataye gaye units ke dispose karo.
  void _syncControllers() {
    final live = widget.units.map((u) => u.key).toSet();

    for (final key in _feeCtrls.keys.toList()) {
      if (!live.contains(key)) {
        _feeCtrls.remove(key)?.dispose();
        _timeCtrls.remove(key)?.dispose();
        _rowCurrency.remove(key);
      }
    }

    for (final u in widget.units) {
      if (_feeCtrls.containsKey(u.key)) continue;

      final double fee = widget.initialFees[u.key] ?? 0.0;
      final String time = widget.initialTimes[u.key] ?? "";

      _feeCtrls[u.key] = TextEditingController(
        text: fee == 0 ? "" : _trim(fee),
      );
      _timeCtrls[u.key] = TextEditingController(text: time);
      _rowCurrency[u.key] = CurrencyService.currencyForCountry(u.countryName);
    }
  }

  void _emit() {
    final fees = <String, double>{};
    final times = <String, String>{};

    for (final u in widget.units) {
      fees[u.key] = double.tryParse(_feeCtrls[u.key]?.text.trim() ?? '') ?? 0.0;
      times[u.key] = _timeCtrls[u.key]?.text.trim() ?? '';
    }

    widget.onChanged(fees, times, _codFee);
  }

  bool get _hasPakistan => widget.units.any(
    (u) => u.countryName.trim().toLowerCase() == 'pakistan',
  );

  int get _filledCount => widget.units.where((u) {
    final fee = double.tryParse(_feeCtrls[u.key]?.text.trim() ?? '') ?? 0;
    final time = _timeCtrls[u.key]?.text.trim() ?? '';
    return fee > 0 && time.isNotEmpty;
  }).length;

  void _applyToAll() {
    final feeText = _bulkFeeCtrl.text.trim();
    final timeText = _bulkTimeCtrl.text.trim();
    if (feeText.isEmpty && timeText.isEmpty) return;

    setState(() {
      for (final u in widget.units) {
        if (feeText.isNotEmpty) _feeCtrls[u.key]!.text = feeText;
        if (timeText.isNotEmpty) _timeCtrls[u.key]!.text = timeText;
      }
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),

        if (widget.units.isEmpty)
          _emptyState()
        else ...[
          _progressBar(),
          const SizedBox(height: 12),
          _applyToAllCard(),
          const SizedBox(height: 14),
          ...widget.units.map(_buildRow),
        ],

        // ── COD: sirf Pakistan par ─────────────────────────────────────
        if (_hasPakistan) ...[
          const SizedBox(height: 6),
          _codField(),
        ],
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Pehle upar se locations select karein — phir har zone ki fee aur time yahan aayenge.",
              style: GoogleFonts.comicNeue(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.orange.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar() {
    final total = widget.units.length;
    final done = _filledCount;
    final double pct = total == 0 ? 0 : done / total;
    final bool allDone = done == total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              allDone ? Icons.verified : Icons.timelapse,
              size: 17,
              color: allDone ? Colors.green : widget.accentColor,
            ),
            const SizedBox(width: 8),
            Text(
              allDone
                  ? "Sab $total zones ki fee & time bhar gaye 🎉"
                  : "$done / $total zones bhare — ${total - done} baqi hain",
              style: GoogleFonts.comicNeue(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: allDone ? Colors.green.shade700 : Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(
              allDone ? Colors.green : widget.accentColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _applyToAllCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.accentColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, size: 17, color: widget.accentColor),
              const SizedBox(width: 6),
              Text(
                "Apply to All — ek dafa likhein, sab zones mein bhar jayega",
                style: GoogleFonts.comicNeue(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: widget.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _miniField(
                  controller: _bulkFeeCtrl,
                  hint: "Fee (PKR)",
                  isNumber: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniField(
                  controller: _bulkTimeCtrl,
                  hint: "Time (e.g. 3-5 Days)",
                  suffix: _timePresetButton(_bulkTimeCtrl),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: _applyToAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: Text(
                    "Sab par lagao",
                    style: GoogleFonts.comicNeue(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(ProductAvailabilityUnit u) {
    final Color levelColor = u.level == 'country'
        ? Colors.teal
        : u.level == 'state'
        ? Colors.indigo
        : Colors.deepOrange;

    final double fee =
        double.tryParse(_feeCtrls[u.key]?.text.trim() ?? '') ?? 0;
    final String currency = _rowCurrency[u.key] ?? 'USD';
    final String? converted = fee > 0
        ? CurrencyService.formatted(fee, currency)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Zone label ────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: levelColor.withOpacity(0.35)),
                ),
                child: Text(
                  u.level.toUpperCase(),
                  style: GoogleFonts.comicNeue(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: levelColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  u.pathLabel,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.comicNeue(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Fee + Time ────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _miniField(
                      controller: _feeCtrls[u.key]!,
                      hint: "Delivery fee (PKR)",
                      isNumber: true,
                      onChanged: (_) {
                        setState(() {});
                        _emit();
                      },
                    ),
                    const SizedBox(height: 6),
                    _conversionChip(u.key, currency, converted),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniField(
                  controller: _timeCtrls[u.key]!,
                  hint: "Delivery time",
                  suffix: _timePresetButton(_timeCtrls[u.key]!),
                  onChanged: (_) {
                    setState(() {});
                    _emit();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _conversionChip(String key, String currency, String? converted) {
    if (_ratesLoading) {
      return Text(
        "Rates load ho rahe hain...",
        style: GoogleFonts.comicNeue(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.black26,
        ),
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.withOpacity(0.25)),
          ),
          child: Text(
            "${CurrencyService.flagOfCurrency(currency)} "
            "${converted ?? "≈ $currency —"}",
            style: GoogleFonts.comicNeue(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: Colors.green.shade800,
            ),
          ),
        ),
        _currencyPicker(key, currency),
      ],
    );
  }

  Widget _currencyPicker(String key, String currency) {
    if (CurrencyService.availableCurrencies.isEmpty) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () => _openCurrencySheet(key, currency),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CurrencyService.flagOfCurrency(currency),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(width: 4),
          Text(
            "change",
            style: GoogleFonts.comicNeue(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: widget.accentColor,
            ),
          ),
          Icon(Icons.arrow_drop_down, size: 15, color: widget.accentColor),
        ],
      ),
    );
  }

  /// Currency chunne ka dialog — flag + code + country, aur upar search
  /// (code ya country dono se dhoond sakte hain).
  void _openCurrencySheet(String key, String current) {
    final searchCtrl = TextEditingController();
    final all = CurrencyService.availableCurrencies;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final q = searchCtrl.text.trim().toLowerCase();
          final filtered = q.isEmpty
              ? all
              : all.where((c) {
                  final country = CurrencyService.countryOfCurrency(
                    c,
                  ).toLowerCase();
                  return c.toLowerCase().contains(q) || country.contains(q);
                }).toList();

          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              width: 420,
              height: MediaQuery.of(ctx).size.height * 0.7,
              child: Column(
                children: [
                  // ── Header ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 10, 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.currency_exchange,
                          size: 20,
                          color: widget.accentColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Select Currency",
                            style: GoogleFonts.orbitron(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        IconButton(
                          splashRadius: 18,
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.black38,
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // ── Search ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      onChanged: (_) => setSheetState(() {}),
                      style: GoogleFonts.comicNeue(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: "Search — code ya country (e.g. GBP, India)",
                        hintStyle: GoogleFonts.comicNeue(
                          fontSize: 13,
                          color: Colors.black26,
                          fontWeight: FontWeight.w600,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 18,
                          color: Colors.black26,
                        ),
                        suffixIcon: searchCtrl.text.isEmpty
                            ? null
                            : IconButton(
                                splashRadius: 14,
                                icon: const Icon(
                                  Icons.close,
                                  size: 15,
                                  color: Colors.black38,
                                ),
                                onPressed: () => setSheetState(
                                  searchCtrl.clear,
                                ),
                              ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: widget.accentColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── List ──────────────────────────────────────────
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              "Koi match nahi mila.",
                              style: GoogleFonts.comicNeue(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black38,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final code = filtered[i];
                              final country =
                                  CurrencyService.countryOfCurrency(code);
                              final bool selected = code == current;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 5),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? widget.accentColor.withOpacity(0.07)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected
                                        ? widget.accentColor.withOpacity(0.4)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: Text(
                                    CurrencyService.flagOfCurrency(code),
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  title: Text(
                                    code,
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w900,
                                      color: selected
                                          ? widget.accentColor
                                          : Colors.black87,
                                    ),
                                  ),
                                  subtitle: country.isEmpty
                                      ? null
                                      : Text(
                                          country,
                                          style: GoogleFonts.comicNeue(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black45,
                                          ),
                                        ),
                                  trailing: selected
                                      ? Icon(
                                          Icons.check_circle,
                                          size: 18,
                                          color: widget.accentColor,
                                        )
                                      : null,
                                  onTap: () {
                                    setState(() => _rowCurrency[key] = code);
                                    Navigator.pop(ctx);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) => searchCtrl.dispose());
  }

  Widget _timePresetButton(TextEditingController ctrl) {
    return PopupMenuButton<String>(
      tooltip: "Quick select",
      icon: const Icon(Icons.schedule, size: 16, color: Colors.black38),
      onSelected: (v) {
        setState(() => ctrl.text = v);
        _emit();
      },
      itemBuilder: (_) => _timePresets
          .map(
            (t) => PopupMenuItem<String>(
              value: t,
              height: 36,
              child: Text(
                t,
                style: GoogleFonts.comicNeue(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _codField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 17,
                color: Colors.blue,
              ),
              const SizedBox(width: 6),
              Text(
                "Cash on Delivery (COD) Fee — sirf Pakistan ke liye",
                style: GoogleFonts.comicNeue(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _miniField(
            controller: _codCtrl,
            hint: "COD fee (PKR)",
            isNumber: true,
            onChanged: (val) {
              _codFee = double.tryParse(val.trim()) ?? 0.0;
              _emit();
            },
          ),
        ],
      ),
    );
  }

  Widget _miniField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
    Widget? suffix,
    ValueChanged<String>? onChanged,
  }) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.comicNeue(
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: GoogleFonts.comicNeue(
            fontSize: 12.5,
            color: Colors.black26,
            fontWeight: FontWeight.w600,
          ),
          suffixIcon: suffix,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: widget.accentColor, width: 1.4),
          ),
        ),
      ),
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
              "Delivery Charges (per zone)",
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
