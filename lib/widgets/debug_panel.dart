import 'package:flutter/material.dart';
import 'package:fnes/components/bus.dart';
import 'package:fnes/controllers/nes_emulator_controller.dart';
import 'package:fnes/utils/responsive_utils.dart';
import 'package:fnes/widgets/audio_debug_view.dart';
import 'package:fnes/widgets/cartridge_debug_view.dart';
import 'package:fnes/widgets/cheat_manager_view.dart';
import 'package:fnes/widgets/cpu_debug_view.dart';
import 'package:fnes/widgets/memory_debug_view.dart';
import 'package:fnes/widgets/palette_debug_view.dart';

class DebugPanel extends StatefulWidget {
  const DebugPanel({
    required this.bus,
    required this.nesEmulatorController,
    super.key,
  });

  final Bus bus;
  final NESEmulatorController nesEmulatorController;

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  late Map<String, bool> _expandedSections;

  @override
  void initState() {
    super.initState();

    _expandedSections = {
      'registers': false,
      'memory': false,
      'palette': false,
      'audio': false,
      'cartridge': false,
      'cheats': false,
    };
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: ResponsiveSizing.debugPanelWidth(context),
    child: SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(context.isMobile ? 16.0 : 24.0),
        child: Column(
          spacing: 6,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCollapsibleSection(
              key: 'registers',
              title: 'Registers',
              child: CpuDebugView(
                bus: widget.bus,
                nesEmulatorController: widget.nesEmulatorController,
              ),
            ),
            _buildCollapsibleSection(
              key: 'memory',
              title: 'Memory',
              child: MemoryDebugView(
                cpu: widget.bus.cpu,
                nesEmulatorController: widget.nesEmulatorController,
              ),
            ),
            _buildCollapsibleSection(
              key: 'palette',
              title: 'Graphics',
              child: PaletteDebugView(
                bus: widget.bus,
                nesEmulatorController: widget.nesEmulatorController,
              ),
            ),
            _buildCollapsibleSection(
              key: 'audio',
              title: 'Audio',
              child: AudioDebugView(
                apu: widget.bus.apu,
                nesEmulatorController: widget.nesEmulatorController,
              ),
            ),
            _buildCollapsibleSection(
              key: 'cartridge',
              title: 'Cartridge Info',
              child: CartridgeDebugView(bus: widget.bus),
            ),
            _buildCollapsibleSection(
              key: 'cheats',
              title: 'Cheat Engine',
              child: CheatManagerView(
                bus: widget.bus,
                cheatController: widget.nesEmulatorController.cheatController,
                romName: widget.nesEmulatorController.romName.value,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildCollapsibleSection({
    required String key,
    required String title,
    required Widget child,
  }) {
    final isExpanded = _expandedSections[key] ?? true;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expandedSections[key] = !isExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  topRight: Radius.circular(3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
        ],
      ),
    );
  }
}
