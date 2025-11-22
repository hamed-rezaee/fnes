import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fnes/components/apu.dart';
import 'package:fnes/components/bus.dart';
import 'package:fnes/components/cpu.dart';
import 'package:fnes/components/ppu.dart';
import 'package:fnes/cubits/nes_emulator_cubit.dart';
import 'package:fnes/cubits/nes_emulator_state.dart';
import 'package:fnes/cubits/palette_debug_view_cubit.dart';
import 'package:fnes/widgets/debug_panel.dart';

void main() => runApp(const MainApp());

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
        home: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => NESEmulatorCubit(
                bus: Bus(cpu: CPU(), ppu: PPU(), apu: APU()),
              ),
            ),
            BlocProvider(create: (context) => PaletteDebugViewCubit()),
          ],
          child: Focus(
            onKeyEvent: (focus, onKey) => KeyEventResult.handled,
            child: const NESEmulatorScreen(),
          ),
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
  late final NESEmulatorCubit _nesCubit = context.read<NESEmulatorCubit>();
  late Ticker _emulationTicker;
  late FocusNode _focusNode;

  late final NESEmulatorCubit _nesEmulatorCubit;

  @override
  void initState() {
    super.initState();
    _emulationTicker = createTicker((_) => _updateEmulation());
    _focusNode = FocusNode();

    _nesEmulatorCubit = context.read<NESEmulatorCubit>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _updateEmulation() => _nesEmulatorCubit.updateEmulation();

  @override
  Widget build(
    BuildContext context,
  ) =>
      BlocListener<NESEmulatorCubit, NESEmulatorState>(
        listener: (context, state) {
          if (state is NESEmulatorRunning) {
            if (!_emulationTicker.isActive) {
              unawaited(_emulationTicker.start());
            }
            _focusNode.requestFocus();
          } else if (state is NESEmulatorPaused) {
            _emulationTicker.stop();
          } else if (state is NESEmulatorROMLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ROM loaded successfully: ${state.fileName}'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is NESEmulatorError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<NESEmulatorCubit, NESEmulatorState>(
          builder: (context, state) => Scaffold(
            appBar: AppBar(
              elevation: 0,
              title: Text(
                'Flutter NES Emulator${_nesCubit.romName != null ? ' - ${_nesCubit.romName}' : ''}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.folder_open),
                      tooltip: 'Load ROM',
                      onPressed: () => _nesEmulatorCubit.loadROMFile(),
                    ),
                    IconButton(
                      icon: Icon(
                        _nesEmulatorCubit.isRunning
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      tooltip: _nesEmulatorCubit.isRunning ? 'Pause' : 'Resume',
                      onPressed: _nesEmulatorCubit.isROMLoaded
                          ? () {
                              if (_nesEmulatorCubit.isRunning) {
                                _nesEmulatorCubit.pauseEmulation();
                              } else {
                                _nesEmulatorCubit.startEmulation();
                              }
                            }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      tooltip: 'Step',
                      onPressed: _nesEmulatorCubit.isROMLoaded &&
                              !_nesEmulatorCubit.isRunning
                          ? _nesEmulatorCubit.stepEmulation
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Reset',
                      onPressed: _nesEmulatorCubit.isROMLoaded
                          ? _nesEmulatorCubit.resetEmulation
                          : null,
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
                  _nesEmulatorCubit.handleKeyDown(event.logicalKey);
                } else if (event is KeyUpEvent) {
                  _nesEmulatorCubit.handleKeyUp(event.logicalKey);
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
                          'FPS: ${_nesEmulatorCubit.currentFPS.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildRenderer(),
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
                  if (_nesEmulatorCubit.showDebugger)
                    DebugPanel(bus: _nesEmulatorCubit.bus),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildRenderer() => GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: StreamBuilder<Image>(
          stream: _nesEmulatorCubit.imageStream,
          builder: (context, snapshot) => Container(
            width: 512,
            height: 480,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[600]!),
            ),
            child: (snapshot.hasData)
                ? RawImage(
                    image: snapshot.data,
                    width: 512,
                    height: 480,
                    fit: BoxFit.fill,
                    filterQuality: _nesEmulatorCubit.filterQuality,
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

  Widget _buildSettingsMenu() => PopupMenuButton<String>(
        icon: const Icon(Icons.settings),
        tooltip: 'Settings',
        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            value: 'toggle_debugger',
            child: Row(
              spacing: 16,
              children: [
                Icon(
                  _nesEmulatorCubit.showDebugger
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
            onTap: () => _nesEmulatorCubit.toggleDebugger(),
          ),
          PopupMenuItem<String>(
            value: 'toggle_filter',
            child: Row(
              spacing: 16,
              children: [
                Icon(
                  _nesEmulatorCubit.filterQuality == FilterQuality.high
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  size: 16,
                  color: Colors.black,
                ),
                const Text('Video Filter', style: TextStyle(fontSize: 12)),
              ],
            ),
            onTap: () => _nesEmulatorCubit.changeFilterQuality(
              _nesEmulatorCubit.filterQuality == FilterQuality.high
                  ? FilterQuality.none
                  : FilterQuality.high,
            ),
          ),
          PopupMenuItem<String>(
            value: 'toggle_audio',
            child: Row(
              spacing: 16,
              children: [
                Icon(
                  _nesEmulatorCubit.audioEnabled
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
            onTap: () => _nesEmulatorCubit.toggleAudio(),
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

  Future<void> _showROMInfoDialog() async {
    final info = _nesEmulatorCubit.bus.cart?.getMapperInfoMap();
    final isROMLoaded = _nesEmulatorCubit.isROMLoaded;
    final hasCart = _nesEmulatorCubit.bus.cart != null;

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
