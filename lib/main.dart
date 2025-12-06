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

void main() => runApp(const MainApp());

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flutter NES Emulator',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'MonospaceFont',
          colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: Colors.black,
            onPrimary: Colors.white,
            secondary: Colors.white,
            onSecondary: Colors.black,
            error: Colors.red,
            onError: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
          dialogTheme: const DialogThemeData(shape: RoundedRectangleBorder()),
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
  final _nesController =
      NESEmulatorController(bus: Bus(cpu: CPU(), ppu: PPU(), apu: APU()));

  late final Ticker _emulationTicker =
      createTicker((_) => _nesController.updateEmulation());
  late final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) => Watch((_) {
        final isRunning = _nesController.isRunning.value;
        final romLoaded = _nesController.isROMLoaded.value;
        final romName = _nesController.romName.value;
        final isDebuggerVisible = _nesController.isDebuggerVisible.value;
        final showOnScreenController =
            _nesController.isOnScreenControllerVisible.value;
        final currentFPS = _nesController.currentFPS.value;
        final filterQuality = _nesController.filterQuality.value;
        final isRewindEnabled = _nesController.rewindEnabled.value;
        final isRewinding = _nesController.isRewinding.value;
        final rewindProgress = _nesController.rewindProgress.value;

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
                    icon: const Icon(Icons.folder),
                    tooltip: 'Load ROM',
                    onPressed: _nesController.loadROMFile,
                  ),
                  const VerticalDivider(
                    indent: 16,
                    endIndent: 16,
                    color: Colors.grey,
                  ),
                  IconButton(
                    icon: Icon(
                      isRunning ? Icons.pause : Icons.play_arrow,
                    ),
                    tooltip: isRunning ? 'Pause' : 'Resume',
                    onPressed: romLoaded
                        ? () {
                            if (isRunning) {
                              _nesController.pauseEmulation();
                            } else {
                              _nesController.startEmulation();
                            }
                          }
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    tooltip: 'Step',
                    onPressed: romLoaded && !isRunning
                        ? _nesController.stepEmulation
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.restart_alt),
                    tooltip: 'Reset',
                    onPressed: romLoaded ? _nesController.resetEmulation : null,
                  ),
                  const VerticalDivider(
                    indent: 16,
                    endIndent: 16,
                    color: Colors.grey,
                  ),
                  IconButton(
                    icon: const Icon(Icons.save),
                    tooltip: 'Save State',
                    onPressed: romLoaded ? _nesController.saveState : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.restore),
                    tooltip: 'Load State',
                    onPressed: romLoaded && _nesController.hasSaveState.value
                        ? _nesController.loadState
                        : null,
                  ),
                  const VerticalDivider(
                    indent: 16,
                    endIndent: 16,
                    color: Colors.grey,
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
                _nesController.handleKeyDown(event.logicalKey);
              } else if (event is KeyUpEvent) {
                _nesController.handleKeyUp(event.logicalKey);
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
                        isRewinding: isRewinding,
                        rewindProgress: rewindProgress,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        spacing: 4,
                        children: [
                          const Text(
                            'Arrow Keys = D-pad, Z = A, X = B, Space = Start, Enter = Select',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (isRewindEnabled)
                            const Text(
                              'Hold R = Rewind',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isDebuggerVisible)
                  DebugPanel(
                    nesEmulatorController: _nesController,
                    bus: _nesController.bus,
                  ),
              ],
            ),
          ),
        );
      });

  Widget _buildRenderer({
    required FilterQuality filterQuality,
    required bool showOnScreenController,
    required bool isRewinding,
    required double rewindProgress,
  }) =>
      GestureDetector(
        onTap: _focusNode.requestFocus,
        child: StreamBuilder<Image>(
          stream: _nesController.imageStream,
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
                      if (isRewinding)
                        Positioned(
                          child: _buildRewindIndicator(rewindProgress),
                        ),
                      if (showOnScreenController)
                        Transform.scale(
                          scale: 0.8,
                          child: Opacity(
                            opacity: 0.7,
                            child:
                                OnScreenController(controller: _nesController),
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

  Widget _buildRewindIndicator(double progress) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fast_rewind, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'REWINDING',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'MonospaceFont',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade400,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.orange),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toStringAsFixed(0).padLeft(2, '0')}% buffer remaining',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontFamily: 'MonospaceFont',
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildSettingsMenu() => Watch((_) {
        final showDebugger = _nesController.isDebuggerVisible.value;
        final filterQuality = _nesController.filterQuality.value;
        final showOnScreenController =
            _nesController.isOnScreenControllerVisible.value;
        final uncapFramerate = _nesController.uncapFramerate.value;
        final rewindEnabled = _nesController.rewindEnabled.value;

        return PopupMenuButton<String>(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          itemBuilder: (BuildContext context) => [
            _buildMenuGroupHeader('VIDEO'),
            PopupMenuItem<String>(
              value: 'toggle_filter',
              child: Row(
                spacing: 12,
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
              onTap: () => _nesController.changeFilterQuality(
                filterQuality == FilterQuality.high
                    ? FilterQuality.none
                    : FilterQuality.high,
              ),
            ),
            PopupMenuItem<String>(
              value: 'toggle_uncap_framerate',
              onTap: _nesController.toggleUncapFramerate,
              child: Row(
                spacing: 12,
                children: [
                  Icon(
                    uncapFramerate
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 16,
                    color: Colors.black,
                  ),
                  const Text('Uncap Framerate', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            _buildMenuGroupHeader('GAMEPLAY'),
            PopupMenuItem<String>(
              value: 'toggle_on_screen_controller',
              onTap: _nesController.toggleOnScreenController,
              child: Row(
                spacing: 12,
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
            PopupMenuItem<String>(
              value: 'toggle_rewind',
              onTap: _nesController.toggleRewind,
              child: Row(
                spacing: 12,
                children: [
                  Icon(
                    rewindEnabled
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 16,
                    color: Colors.black,
                  ),
                  const Text('Enable Rewind', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            _buildMenuGroupHeader('DEBUG'),
            PopupMenuItem<String>(
              value: 'toggle_debugger',
              onTap: _nesController.toggleDebugger,
              child: Row(
                spacing: 12,
                children: [
                  Icon(
                    showDebugger
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 16,
                    color: Colors.black,
                  ),
                  const Text('Debugger Panels', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            _buildMenuGroupHeader('INFORMATION'),
            PopupMenuItem<String>(
              value: 'rom_info',
              onTap: _showROMInfoDialog,
              child: const Row(
                spacing: 12,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.black),
                  Text('Cartridge Information', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        );
      });

  PopupMenuItem<String> _buildMenuGroupHeader(String label) => PopupMenuItem(
        child: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );

  Future<void> _showROMInfoDialog() async {
    final info = _nesController.bus.cart?.getMapperInfoMap();
    final isROMLoaded = _nesController.isROMLoaded.value;
    final hasCart = _nesController.bus.cart != null;

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
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            e.value,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          );
        } else {
          content =
              const Text('No ROM loaded.', style: TextStyle(fontSize: 12));
        }

        return AlertDialog(
          title: const Text(
            'Cartridge Information',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(child: content),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
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
