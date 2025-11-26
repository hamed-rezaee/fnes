import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:fnes/components/apu.dart';
import 'package:fnes/components/bus.dart';
import 'package:fnes/components/cpu.dart';
import 'package:fnes/components/ppu.dart';
import 'package:fnes/controllers/nes_emulator_controller.dart';
import 'package:fnes/widgets/debug_panel.dart';
import 'package:fnes/widgets/on_screen_controller.dart';
import 'package:signals/signals_flutter.dart';

late final NESEmulatorController nesController;

void main() {
  nesController =
      NESEmulatorController(bus: Bus(cpu: CPU(), ppu: PPU(), apu: APU()));

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flutter NES Emulator',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: false,
          fontFamily: 'MonospaceFont',
          primarySwatch: Colors.blueGrey,
        ),
        home: Focus(
          onKeyEvent: (focus, onKey) => KeyEventResult.handled,
          child: const NESEmulatorScreen(),
        ),
      );
}

class NESEmulatorScreen extends StatefulWidget {
  const NESEmulatorScreen({super.key});

  @override
  State<NESEmulatorScreen> createState() => _NESEmulatorScreenState();
}

class _NESEmulatorScreenState extends State<NESEmulatorScreen>
    with TickerProviderStateMixin {
  late Ticker _emulationTicker;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    _emulationTicker = createTicker((_) => _updateEmulation());
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _updateEmulation() => nesController.updateEmulation();

  @override
  Widget build(BuildContext context) => Watch((_) {
        final isRunning = nesController.isRunning.value;
        final romLoaded = nesController.isROMLoaded.value;
        final romName = nesController.romName.value;
        final isDebuggerVisible = nesController.isDebuggerVisible.value;
        final showOnScreenController =
            nesController.isOnScreenControllerVisible.value;
        final currentFPS = nesController.currentFPS.value;
        final filterQuality = nesController.filterQuality.value;

        if (isRunning) {
          if (!_emulationTicker.isActive) {
            unawaited(_emulationTicker.start());
          }

          _focusNode.requestFocus();
        } else if (!isRunning && _emulationTicker.isActive) {
          _emulationTicker.stop();
        }

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: Text(
              'Flutter NES Emulator${romName != null ? ' - $romName' : ''}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            actions: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.folder_open),
                    tooltip: 'Load ROM',
                    onPressed: nesController.loadROMFile,
                  ),
                  IconButton(
                    icon: Icon(
                      isRunning ? Icons.pause : Icons.play_arrow,
                    ),
                    tooltip: isRunning ? 'Pause' : 'Resume',
                    onPressed: romLoaded
                        ? () {
                            if (isRunning) {
                              nesController.pauseEmulation();
                            } else {
                              nesController.startEmulation();
                            }
                          }
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    tooltip: 'Step',
                    onPressed: romLoaded && !isRunning
                        ? nesController.stepEmulation
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Reset',
                    onPressed: romLoaded ? nesController.resetEmulation : null,
                  ),
                  _buildSettingsMenu(),
                ],
              ),
            ],
          ),
          body: KeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: (KeyEvent event) {
              if (event is KeyDownEvent) {
                nesController.handleKeyDown(event.logicalKey);
              } else if (event is KeyUpEvent) {
                nesController.handleKeyUp(event.logicalKey);
              }
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'FPS: ${currentFPS.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildRenderer(
                        filterQuality: filterQuality,
                        showOnScreenController: showOnScreenController,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Arrow Keys = D-pad, Z = A, X = B, Space = Start, Enter = Select',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                if (isDebuggerVisible)
                  DebugPanel(
                    nesEmulatorController: nesController,
                    bus: nesController.bus,
                  ),
              ],
            ),
          ),
        );
      });

  Widget _buildRenderer({
    required FilterQuality filterQuality,
    required bool showOnScreenController,
  }) =>
      GestureDetector(
        onTap: _focusNode.requestFocus,
        child: StreamBuilder<Image>(
          stream: nesController.imageStream,
          builder: (context, snapshot) => Container(
            width: 512,
            height: 480,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[600]!),
            ),
            child: (snapshot.hasData)
                ? Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      RawImage(
                        image: snapshot.data,
                        width: 512,
                        height: 480,
                        fit: BoxFit.fill,
                        filterQuality: filterQuality,
                      ),
                      if (showOnScreenController)
                        Transform.scale(
                          scale: 0.8,
                          child: Opacity(
                            opacity: 0.7,
                            child:
                                OnScreenController(controller: nesController),
                          ),
                        ),
                    ],
                  )
                : const Center(
                    child: Text(
                      'No ROM Loaded',
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ),
      );

  Widget _buildSettingsMenu() => Watch((_) {
        final showDebugger = nesController.isDebuggerVisible.value;
        final filterQuality = nesController.filterQuality.value;
        final audioEnabled = nesController.audioEnabled.value;
        final showOnScreenController =
            nesController.isOnScreenControllerVisible.value;
        final uncapFramerate = nesController.uncapFramerate.value;

        return PopupMenuButton<String>(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'toggle_filter',
              child: Row(
                spacing: 16,
                children: [
                  Icon(
                    filterQuality == FilterQuality.high
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 16,
                    color: Colors.black,
                  ),
                  const Text('Video Filter', style: TextStyle(fontSize: 12)),
                ],
              ),
              onTap: () => nesController.changeFilterQuality(
                filterQuality == FilterQuality.high
                    ? FilterQuality.none
                    : FilterQuality.high,
              ),
            ),
            PopupMenuItem<String>(
              value: 'toggle_uncap_framerate',
              onTap: nesController.toggleUncapFramerate,
              child: Row(
                spacing: 16,
                children: [
                  Icon(
                    uncapFramerate
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 16,
                    color: Colors.black,
                  ),
                  const Text(
                    'Uncap Framerate',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'toggle_audio',
              onTap: nesController.toggleAudio,
              child: Row(
                spacing: 16,
                children: [
                  Icon(
                    audioEnabled
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 16,
                    color: Colors.black,
                  ),
                  const Text(
                    'Audio',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'toggle_debugger',
              onTap: nesController.toggleDebugger,
              child: Row(
                spacing: 16,
                children: [
                  Icon(
                    showDebugger
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 16,
                    color: Colors.black,
                  ),
                  const Text(
                    'Debugger Panels',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'toggle_on_screen_controller',
              onTap: nesController.toggleOnScreenController,
              child: Row(
                spacing: 16,
                children: [
                  Icon(
                    showOnScreenController
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 16,
                    color: Colors.black,
                  ),
                  const Text(
                    'On-Screen Controller',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'rom_info',
              onTap: _showROMInfoDialog,
              child: const Row(
                spacing: 16,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.black),
                  Text('Cartridge Information', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        );
      });

  Future<void> _showROMInfoDialog() async {
    final info = nesController.bus.cart?.getMapperInfoMap();
    final isROMLoaded = nesController.isROMLoaded.value;
    final hasCart = nesController.bus.cart != null;

    return showDialog<void>(
      context: context,
      builder: (context) {
        Widget content;

        if (isROMLoaded && hasCart && info != null) {
          content = Column(
            mainAxisSize: MainAxisSize.min,
            children: info.entries
                .map(
                  (MapEntry<String, String> e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            e.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            e.value,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          );
        } else {
          content = const Text(
            'No ROM loaded.',
            style: TextStyle(fontSize: 12),
          );
        }

        return AlertDialog(
          title: const Text(
            'Cartridge Information',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(child: content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(fontSize: 12)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _emulationTicker.dispose();
    _focusNode.dispose();

    super.dispose();
  }
}
