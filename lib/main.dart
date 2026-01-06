import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';
import 'package:fnes/components/apu.dart';
import 'package:fnes/components/bus.dart';
import 'package:fnes/components/cheat_engine.dart';
import 'package:fnes/components/cpu.dart';
import 'package:fnes/components/ppu.dart';
import 'package:fnes/controllers/nes_emulator_controller.dart';
import 'package:fnes/utils/responsive_utils.dart';
import 'package:fnes/widgets/debug_panel.dart';
import 'package:fnes/widgets/no_rom_loaded.dart';
import 'package:fnes/widgets/on_screen_controller.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

class _NESEmulatorScreenState extends State<NESEmulatorScreen> {
  final _nesController = NESEmulatorController(
    bus: Bus(cpu: CPU(), ppu: PPU(), apu: APU(), cheatEngine: CheatEngine()),
  );

  static const _targetFrameTimeMicros = 16639;

  Timer? _emulationTimer;
  DateTime? _lastFrameTime;
  int _accumulatedTimeMicros = 0;

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
    final showOnScreenController =
        _nesController.isOnScreenControllerVisible.value;
    final currentFPS = _nesController.currentFPS.value;
    final filterQuality = _nesController.filterQuality.value;
    final isRewindEnabled = _nesController.rewindEnabled.value;
    final isRewinding = _nesController.isRewinding.value;
    final rewindProgress = _nesController.rewindProgress.value;
    final errorMessage = _nesController.errorMessage.value;

    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _showErrorToast(errorMessage);
        _nesController.clearErrorMessage();
      });
    }

    if (isRunning) {
      if (_emulationTimer == null || !_emulationTimer!.isActive) {
        _startEmulationLoop();
      }

      _focusNode.requestFocus();
    } else if (!isRunning && _emulationTimer != null) {
      _stopEmulationLoop();
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          context.isMobile
              ? 'FNES${romName != null ? ' - $romName' : ''}'
              : 'Flutter NES Emulator${romName != null ? ' - $romName' : ''}',
          style: TextStyle(
            fontSize: ResponsiveSizing.appBarTitleSize(context),
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder),
            tooltip: 'Load ROM',
            onPressed: _nesController.loadROMFile,
          ),
          const VerticalDivider(indent: 16, endIndent: 16, color: Colors.grey),
          IconButton(
            icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
            tooltip: isRunning ? 'Pause' : 'Resume',
            onPressed: romLoaded
                ? () => isRunning
                      ? _nesController.pauseEmulation()
                      : _nesController.startEmulation()
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
            onPressed: romLoaded
                ? () => _confirmAction(
                    title: 'Reset Emulator?',
                    message:
                        'Resetting clears the current game state. Do you want to continue?',
                    confirmLabel: 'Reset',
                    onConfirm: _nesController.resetEmulation,
                  )
                : null,
          ),
          const VerticalDivider(indent: 16, endIndent: 16, color: Colors.grey),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save State',
            onPressed: romLoaded
                ? () => _confirmAction(
                    title: 'Overwrite Save State?',
                    message:
                        'Saving now will replace your previous save state. Proceed?',
                    confirmLabel: 'Save',
                    onConfirm: _nesController.saveState,
                  )
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Load State',
            onPressed: romLoaded && _nesController.hasSaveState.value
                ? () => _confirmAction(
                    title: 'Load Save State?',
                    message:
                        'Loading a save will discard current progress. Continue?',
                    confirmLabel: 'Load',
                    onConfirm: _nesController.loadState,
                  )
                : null,
          ),
          const VerticalDivider(indent: 16, endIndent: 16, color: Colors.grey),
          _buildSettingsMenu(),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = context.isMobileOrTablet;

            return SingleChildScrollView(
              child: isMobile
                  ? Column(
                      children: [
                        _buildEmulatorSection(
                          context,
                          currentFPS,
                          filterQuality,
                          showOnScreenController,
                          isRewinding,
                          rewindProgress,
                          isRewindEnabled,
                        ),
                        DebugPanel(
                          nesEmulatorController: _nesController,
                          bus: _nesController.bus,
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildEmulatorSection(
                            context,
                            currentFPS,
                            filterQuality,
                            showOnScreenController,
                            isRewinding,
                            rewindProgress,
                            isRewindEnabled,
                          ),
                        ),
                        DebugPanel(
                          nesEmulatorController: _nesController,
                          bus: _nesController.bus,
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  });

  Widget _buildEmulatorSection(
    BuildContext context,
    double currentFPS,
    FilterQuality filterQuality,
    bool showOnScreenController,
    bool isRewinding,
    double rewindProgress,
    bool isRewindEnabled,
  ) => Column(
    children: [
      Padding(
        padding: EdgeInsets.all(context.isMobile ? 8.0 : 16.0),
        child: Text(
          'FPS: ${currentFPS.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: ResponsiveSizing.fpsTextSize(context),
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.isMobile ? 8.0 : 16.0,
        ),
        child: _buildRenderer(
          context: context,
          filterQuality: filterQuality,
          showOnScreenController: showOnScreenController,
          isRewinding: isRewinding,
          rewindProgress: rewindProgress,
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(
          vertical: context.isMobile ? 8.0 : 12.0,
          horizontal: 8,
        ),
        child: _buildKeyBindingsHint(context, isRewindEnabled),
      ),
    ],
  );

  Widget _buildRenderer({
    required BuildContext context,
    required FilterQuality filterQuality,
    required bool showOnScreenController,
    required bool isRewinding,
    required double rewindProgress,
  }) => GestureDetector(
    onTap: _focusNode.requestFocus,
    child: StreamBuilder<Image>(
      stream: _nesController.imageStream,
      builder: (context, snapshot) {
        final screenWidth = ResponsiveSizing.nesScreenWidth(context);
        final screenHeight = ResponsiveSizing.nesScreenHeight(screenWidth);

        return Container(
          width: screenWidth,
          height: screenHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[600]!),
          ),
          child: (snapshot.hasData)
              ? Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    RawImage(
                      image: snapshot.data,
                      width: screenWidth,
                      height: screenHeight,
                      fit: BoxFit.fill,
                      filterQuality: filterQuality,
                    ),
                    if (isRewinding)
                      Positioned(
                        child: _buildRewindIndicator(rewindProgress),
                      ),
                    if (showOnScreenController)
                      Transform.scale(
                        scale: ResponsiveSizing.onScreenControllerScale(
                          context,
                        ),
                        child: Opacity(
                          opacity: 0.75,
                          child: OnScreenController(
                            controller: _nesController,
                          ),
                        ),
                      ),
                  ],
                )
              : const Center(child: NoRomLoaded(fontSize: 22)),
        );
      },
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
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
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
    final filterQuality = _nesController.filterQuality.value;
    final showOnScreenController =
        _nesController.isOnScreenControllerVisible.value;
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
                rewindEnabled ? Icons.check_box : Icons.check_box_outline_blank,
                size: 16,
                color: Colors.black,
              ),
              const Text('Enable Rewind', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        _buildMenuGroupHeader('INFORMATION'),
        PopupMenuItem<String>(
          value: 'about',
          onTap: () => _showAboutDialog(context),
          child: const Row(
            spacing: 12,
            children: [
              Icon(Icons.info, size: 16, color: Colors.black),
              Text('About', style: TextStyle(fontSize: 12)),
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

  Widget _buildKeyBindingsHint(
    BuildContext context,
    bool isRewindEnabled,
  ) {
    final textSize = ResponsiveSizing.keyBindingsTextSize(context);

    return Column(
      spacing: 4,
      children: [
        Text(
          'Arrow Keys = D-pad | Z = A | X = B | Space = Start | Enter = Select',
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          'A = Turbo A | S = Turbo B',
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
          textAlign: TextAlign.center,
        ),
        if (isRewindEnabled)
          Text(
            'Hold R = Rewind',
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) => showAboutDialog(
    context: context,
    applicationName: 'FNES: Flutter NES Emulator',
    applicationVersion: '0.8.5',
    applicationIcon: const Icon(Icons.gamepad_outlined, size: 48),
    children: [
      const Text(
        'A full-featured NES emulator with CPU, PPU, and APU support, built-in debugger,\nand cross-platform compatibility using Flutter.',
        style: TextStyle(fontSize: 12),
      ),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () => launchUrl(
          Uri.parse('https://github.com/hamed-rezaee/fnes'),
          mode: LaunchMode.externalApplication,
        ),
        child: const Text(
          'https://github.com/hamed-rezaee/fnes',
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    ],
  );

  void _showErrorToast(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message.replaceAll('Exception: ', '')),
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      ),
    );

  Future<void> _confirmAction({
    required String title,
    required String message,
    required FutureOr<void> Function() onConfirm,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
  }) async {
    final result =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            content: Text(message, style: const TextStyle(fontSize: 12)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(cancelLabel, style: const TextStyle(fontSize: 12)),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(confirmLabel, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ) ??
        false;

    if (result) await onConfirm();
  }

  void _startEmulationLoop() {
    _emulationTimer?.cancel();
    _lastFrameTime = DateTime.now();
    _accumulatedTimeMicros = 0;

    _emulationTimer = Timer.periodic(const Duration(milliseconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      if (_lastFrameTime != null) {
        final elapsed = now.difference(_lastFrameTime!).inMicroseconds;
        _accumulatedTimeMicros += elapsed;

        while (_accumulatedTimeMicros >= _targetFrameTimeMicros) {
          _nesController.updateEmulation();
          _accumulatedTimeMicros -= _targetFrameTimeMicros;

          if (_accumulatedTimeMicros > _targetFrameTimeMicros * 3) {
            _accumulatedTimeMicros = 0;
            break;
          }
        }
      }

      _lastFrameTime = now;
    });
  }

  void _stopEmulationLoop() {
    _emulationTimer?.cancel();
    _emulationTimer = null;
    _lastFrameTime = null;
    _accumulatedTimeMicros = 0;
  }

  @override
  Future<void> dispose() async {
    _stopEmulationLoop();
    _focusNode.dispose();

    super.dispose();
  }
}
