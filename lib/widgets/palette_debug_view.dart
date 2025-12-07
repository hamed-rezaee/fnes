import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart' hide Image;
import 'package:fnes/components/bus.dart';
import 'package:fnes/components/color_palette.dart';
import 'package:fnes/controllers/nes_emulator_controller.dart';
import 'package:fnes/controllers/palette_debug_view_controller.dart';
import 'package:fnes/widgets/custom_segmented_button.dart';
import 'package:signals/signals_flutter.dart';

class PaletteDebugView extends StatefulWidget {
  const PaletteDebugView({
    required this.bus,
    required this.nesEmulatorController,
    super.key,
  });

  final Bus bus;
  final NESEmulatorController nesEmulatorController;

  @override
  State<PaletteDebugView> createState() => _PaletteDebugViewState();
}

class _PaletteDebugViewState extends State<PaletteDebugView> {
  static const int _tileSize = 8;
  static const int _tilesPerRow = 16;
  static const int _imageSize = 128;

  late final PaletteDebugViewController controller;

  @override
  void initState() {
    super.initState();

    controller = PaletteDebugViewController(
      nesEmulatorController: widget.nesEmulatorController,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final selectedPalette = controller.selectedPalette.value;
      final selectedPatternTable = controller.selectedPatternTable.value;
      final renderMode = widget.nesEmulatorController.renderMode.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            spacing: 8,
            children: [
              Row(
                spacing: 21,
                children: [
                  const Text(
                    'Render Mode',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'MonospaceFont',
                    ),
                  ),
                  Expanded(
                    child: CustomSegmentedButton<RenderMode>(
                      showSelectedIcon: false,
                      multiSelectionEnabled: false,
                      isEmptySelectionAllowed: true,
                      items: RenderMode.values,
                      selectedItems: {renderMode},
                      toLabel: (mode) => mode.label,
                      onSelectedPatternTableChanged: (selected) {
                        if (selected.isNotEmpty) {
                          widget.nesEmulatorController
                              .setRenderMode(selected.first);
                        }
                      },
                    ),
                  ),
                ],
              ),
              Row(
                spacing: 8,
                children: [
                  const Text(
                    'Pattern Table',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'MonospaceFont',
                    ),
                  ),
                  Expanded(
                    child: CustomSegmentedButton<PatternTable>(
                      showSelectedIcon: false,
                      multiSelectionEnabled: false,
                      isEmptySelectionAllowed: true,
                      items: PatternTable.values,
                      selectedItems: {selectedPatternTable},
                      toLabel: (table) => table.label,
                      onSelectedPatternTableChanged: (selected) {
                        if (selected.isNotEmpty) {
                          controller.changePatternTable(selected.first);
                        }
                      },
                    ),
                  ),
                ],
              ),
              Row(
                spacing: 8,
                children: [
                  const Text(
                    'Palette      ',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: CustomSegmentedButton<int>(
                      showSelectedIcon: false,
                      multiSelectionEnabled: false,
                      isEmptySelectionAllowed: true,
                      items: List.generate(8, (index) => index),
                      selectedItems: {selectedPalette},
                      toLabel: (palette) => '$palette',
                      onSelectedPatternTableChanged: (selected) {
                        if (selected.isNotEmpty) {
                          controller.changePalette(selected.first);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: FutureBuilder<Image>(
              key: ValueKey('$selectedPatternTable-$selectedPalette'),
              future: _createPatternImage(
                selectedPatternTable.index,
                selectedPalette,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                return _buildPatternTable(snapshot.data);
              },
            ),
          ),
        ],
      );
    });
  }

  int _readCharData(int address) {
    try {
      return widget.bus.ppu.ppuRead(address);
    } on Exception catch (e) {
      developer.log('Error reading CHR data: $e');

      if (widget.bus.cart != null) {
        var data = 0;

        if (widget.bus.cart!.ppuRead(address, (value) => data = value)) {
          return data;
        }
      }

      return (address < widget.bus.ppu.patternTable.length)
          ? widget.bus.ppu.patternTable[address]
          : 0;
    }
  }

  Color _getPixelColor(int pixelValue, int selectedPalette) {
    if (pixelValue == 0) {
      return const Color.fromARGB(255, 32, 32, 32);
    }

    try {
      final paletteAddress = 0x3F00 + (selectedPalette << 2) + pixelValue;
      final colorIndex = widget.bus.ppu.ppuRead(paletteAddress) & 0x3F;

      return colorPalette[colorIndex.clamp(0, colorPalette.length - 1)];
    } on Exception catch (e) {
      developer.log('Error getting pixel color: $e');

      final gray = pixelValue * 85;

      return Color.fromARGB(255, gray, gray, gray);
    }
  }

  Future<Image> _createPatternImage(
    int patternTableIndex,
    int selectedPalette,
  ) async {
    final completer = Completer<Image>();
    var bufferIndex = 0;
    final baseTableAddress = patternTableIndex << 12;
    final pixelBuffer = Uint8List(128 * 128 * 4);

    await Future.microtask(() {
      for (var tileY = 0; tileY < _tilesPerRow; tileY++) {
        for (var pixelY = 0; pixelY < _tileSize; pixelY++) {
          for (var tileX = 0; tileX < _tilesPerRow; tileX++) {
            final tileBaseAddress =
                baseTableAddress + ((tileY << 8) + (tileX << 4));

            final lsb = _readCharData(tileBaseAddress + pixelY);
            final msb = _readCharData(tileBaseAddress + pixelY + 8);

            for (var pixelX = 0; pixelX < _tileSize; pixelX++) {
              final mask = 0x80 >> pixelX;
              final pixelValue =
                  ((msb & mask) != 0 ? 2 : 0) | ((lsb & mask) != 0 ? 1 : 0);

              final color = _getPixelColor(pixelValue, selectedPalette);

              pixelBuffer[bufferIndex++] = (color.r * 255).round();
              pixelBuffer[bufferIndex++] = (color.g * 255).round();
              pixelBuffer[bufferIndex++] = (color.b * 255).round();
              pixelBuffer[bufferIndex++] = 255;
            }
          }
        }
      }
    });

    decodeImageFromPixels(
      pixelBuffer,
      _imageSize,
      _imageSize,
      PixelFormat.rgba8888,
      completer.complete,
    );

    return completer.future;
  }

  Widget _buildPatternTable(Image? image) => RawImage(
        image: image,
        width: _imageSize.toDouble() * 2,
        height: _imageSize.toDouble() * 2,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      );
}
