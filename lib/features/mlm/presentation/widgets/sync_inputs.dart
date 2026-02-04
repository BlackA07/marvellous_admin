import 'package:flutter/material.dart';
import '../controllers/mlm_controller.dart';

class SyncInputs extends StatefulWidget {
  final String initialPercent;
  final double initialAmount;
  final Function(String) onPercentChanged;
  final MLMController controller;
  final int? levelIndex;
  final bool isCashback;

  const SyncInputs({
    Key? key,
    required this.initialPercent,
    required this.initialAmount,
    required this.onPercentChanged,
    required this.controller,
    this.levelIndex,
    this.isCashback = false,
  }) : super(key: key);

  @override
  State<SyncInputs> createState() => _SyncInputsState();
}

class _SyncInputsState extends State<SyncInputs> {
  late TextEditingController _pCtrl;
  late TextEditingController _aCtrl;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _pCtrl = TextEditingController(text: widget.initialPercent);
    _aCtrl = TextEditingController(
      text: widget.initialAmount.toStringAsFixed(2),
    );
  }

  @override
  void didUpdateWidget(SyncInputs oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Jab external data change ho (like total amount change) to update karo
    if (!_isUpdating) {
      if (widget.initialPercent != oldWidget.initialPercent) {
        _pCtrl.text = widget.initialPercent;
      }
      if ((widget.initialAmount - oldWidget.initialAmount).abs() > 0.01) {
        _aCtrl.text = widget.initialAmount.toStringAsFixed(2);
      }
    }
  }

  void _syncAmount() {
    if (_isUpdating) return;
    _isUpdating = true;

    final p = double.tryParse(_pCtrl.text) ?? 0;
    final total = widget.controller.totalDistAmount.value;
    final exact = (p * total) / 100;
    _aCtrl.text = exact.toStringAsFixed(2);

    _isUpdating = false;
  }

  void _syncPercent() {
    if (_isUpdating) return;
    _isUpdating = true;

    final a = double.tryParse(_aCtrl.text) ?? 0;
    final total = widget.controller.totalDistAmount.value;
    if (total <= 0) {
      _isUpdating = false;
      return;
    }

    final p = (a / total) * 100;
    _pCtrl.text = p.toStringAsFixed(6);
    widget.onPercentChanged(_pCtrl.text);

    if (widget.levelIndex != null) {
      widget.controller.updateLevelByAmount(widget.levelIndex!, a);
    } else if (widget.isCashback) {
      widget.controller.updateCashbackByAmount(a);
    }

    _isUpdating = false;
  }

  @override
  void dispose() {
    _pCtrl.dispose();
    _aCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 75,
          child: _input(
            controller: _pCtrl,
            hint: "%",
            onChanged: (v) {
              widget.onPercentChanged(v);
              _syncAmount();
            },
            readOnly: false,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 95,
          child: _input(
            controller: _aCtrl,
            hint: "Rs",
            onChanged: (_) => _syncPercent(),
            readOnly: false,
          ),
        ),
      ],
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required Function(String) onChanged,
    required bool readOnly,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: readOnly ? Colors.black54 : Colors.black,
      ),
      decoration: InputDecoration(
        isDense: true,
        suffixText: hint,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: readOnly
            ? const Color.fromARGB(255, 240, 240, 240)
            : const Color.fromARGB(255, 209, 176, 176),
      ),
      onChanged: onChanged,
    );
  }
}
