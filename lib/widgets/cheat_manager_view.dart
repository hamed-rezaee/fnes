import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fnes/components/bus.dart';
import 'package:fnes/components/cheat_code.dart';
import 'package:fnes/controllers/cheat_controller.dart';
import 'package:fnes/widgets/no_rom_loaded.dart';
import 'package:signals/signals_flutter.dart';

class CheatManagerView extends StatefulWidget {
  const CheatManagerView({
    required this.bus,
    required this.cheatController,
    required this.romName,
    super.key,
  });

  final Bus bus;
  final CheatController cheatController;
  final String? romName;

  @override
  State<CheatManagerView> createState() => _CheatManagerViewState();
}

class _CheatManagerViewState extends State<CheatManagerView> {
  @override
  Widget build(BuildContext context) =>
      widget.bus.cart?.getMapperInfoMap() == null
      ? const NoRomLoaded()
      : SizedBox(
          height: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Watch((context) {
                final count = widget.cheatController.enabledCheatCount.value;
                return RichText(
                  text: TextSpan(
                    style: _monoTextStyle(9, color: Colors.black),
                    children: [
                      const TextSpan(
                        text: 'ACTIVE ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: '$count'),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              Expanded(
                child: Watch((context) {
                  final cheats = widget.cheatController.cheats.value;

                  if (cheats.isEmpty) {
                    return Center(
                      child: Text(
                        'No cheats added.',
                        style: _bodyTextStyle(Colors.grey.shade600),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final cheat in cheats) ...[
                          _CheatListItem(
                            cheat: cheat,
                            onToggle: (enabled) =>
                                widget.cheatController.toggleCheat(
                                  id: cheat.id,
                                  enabled: enabled,
                                  romName: widget.romName,
                                ),
                            onDelete: () => widget.cheatController.removeCheat(
                              cheat.id,
                              widget.romName,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildButton(
                      label: 'Add',
                      onPressed: _showAddCheatDialog,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildButton(
                      label: 'Clear',
                      onPressed: _showClearConfirmDialog,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
  }) => InkWell(
    onTap: onPressed,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: _borderDecoration(),
      child: Center(
        child: Text(
          label,
          style: _labelTextStyle(),
        ),
      ),
    ),
  );

  TextStyle _labelTextStyle() => const TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    fontFamily: 'MonospaceFont',
  );

  TextStyle _bodyTextStyle(Color? color) => TextStyle(
    fontSize: 12,
    fontFamily: 'MonospaceFont',
    color: color,
  );

  TextStyle _monoTextStyle(
    double fontSize, {
    Color? color,
    FontWeight? fontWeight,
  }) => TextStyle(
    fontSize: fontSize,
    fontFamily: 'MonospaceFont',
    color: color,
    fontWeight: fontWeight,
  );

  BoxDecoration _borderDecoration([Color? backgroundColor]) => BoxDecoration(
    border: Border.all(color: Colors.grey.shade300),
    color: backgroundColor,
  );

  void _showAddCheatDialog() => showDialog<void>(
    context: context,
    builder: (context) => _AddCheatDialog(
      cheatController: widget.cheatController,
      romName: widget.romName,
    ),
  );

  void _showClearConfirmDialog() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Clear All?',
        style: _monoTextStyle(14, fontWeight: FontWeight.bold),
      ),
      content: Text(
        'Remove all cheats for this ROM?',
        style: _monoTextStyle(12),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            unawaited(widget.cheatController.clearAllCheats(widget.romName));
            Navigator.pop(context);
          },
          child: const Text('Clear'),
        ),
      ],
    ),
  );
}

class _CheatListItem extends StatelessWidget {
  const _CheatListItem({
    required this.cheat,
    required this.onToggle,
    required this.onDelete,
  });

  final CheatCode cheat;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  static BoxDecoration _borderDecoration(Color backgroundColor) =>
      BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        color: backgroundColor,
      );

  static TextStyle _monoTextStyle(
    double fontSize, {
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
  }) => TextStyle(
    fontSize: fontSize,
    fontFamily: 'MonospaceFont',
    color: color,
    fontWeight: fontWeight,
    decoration: decoration,
  );

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: _borderDecoration(
      cheat.enabled ? Colors.white : Colors.grey.shade100,
    ),
    child: Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: cheat.enabled,
            onChanged: (value) => onToggle(value ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cheat.name,
                style: _monoTextStyle(
                  9,
                  fontWeight: FontWeight.bold,
                  decoration: cheat.enabled ? null : TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${cheat.address.toRadixString(16).toUpperCase().padLeft(4, '0')} = '
                '${cheat.value.toRadixString(16).toUpperCase().padLeft(2, '0')}',
                style: _monoTextStyle(8, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onDelete,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.close,
              size: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _AddCheatDialog extends StatefulWidget {
  const _AddCheatDialog({
    required this.cheatController,
    required this.romName,
  });

  final CheatController cheatController;
  final String? romName;

  @override
  State<_AddCheatDialog> createState() => _AddCheatDialogState();
}

class _AddCheatDialogState extends State<_AddCheatDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text(
      'Add Game Genie Code',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        fontFamily: 'MonospaceFont',
      ),
    ),
    content: SizedBox(
      width: 280,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabeledTextField(
              label: 'Name',
              controller: _nameController,
              hint: 'e.g. Infinite Lives',
              validator: (value) {
                if (value?.trim().isEmpty ?? true) return 'Name required';

                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildLabeledTextField(
              label: 'Game Genie Code',
              controller: _codeController,
              hint: 'XXXXXX',
              maxLength: 8,
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) return 'Code required';

                final clean = value!.replaceAll(RegExp('[^A-Z0-9]'), '');

                if (clean.length != 6 && clean.length != 8) {
                  return '6 or 8 characters required';
                }

                return null;
              },
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: _addCheat,
        child: const Text('Add'),
      ),
    ],
  );

  Widget _buildLabeledTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    int? maxLength,
    TextCapitalization? textCapitalization,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'MonospaceFont',
        ),
      ),
      const SizedBox(height: 4),
      TextFormField(
        controller: controller,
        maxLength: maxLength,
        style: const TextStyle(
          fontSize: 10,
          fontFamily: 'MonospaceFont',
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
          ),
          isDense: true,
        ),
        textCapitalization: textCapitalization ?? TextCapitalization.none,
        validator: validator,
      ),
    ],
  );

  Future<void> _addCheat() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final code = _codeController.text.trim();

    await widget.cheatController.addGameGenieCheat(
      code,
      widget.romName,
      name: name,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();

    super.dispose();
  }
}
