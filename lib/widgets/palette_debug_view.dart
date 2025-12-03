import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart' hide Image;
import 'package:fnes/components/bus.dart';
import 'package:fnes/controllers/nes_emulator_controller.dart';
import 'package:fnes/controllers/palette_debug_view_controller.dart';
import 'package:signals/signals_flutter.dart';

enum PatternTable {
  background('Background'),
  sprite('Sprite');

  const PatternTable(this.title);

  final String title;
}

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
              _buildDropdown<RenderMode>(
                label: 'Render Mode  ',
                value: renderMode,
                items: RenderMode.values
                    .map(
                      (mode) => DropdownMenuItem(
                        value: mode,
                        child: Row(
                          children: [
                            Text(
                              mode.label,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black,
                                fontWeight: renderMode == mode
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontFamily: 'MonospaceFont',
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    widget.nesEmulatorController.setRenderMode(value);
                  }
                },
              ),
              _buildDropdown<int>(
                label: 'Pattern Table',
                value: selectedPatternTable,
                items: [
                  for (var i = 0; i < PatternTable.values.length; i++)
                    DropdownMenuItem(
                      value: PatternTable.values[i].index,
                      child: Text(
                        PatternTable.values[i].title,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black,
                          fontWeight: selectedPatternTable == i
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontFamily: 'MonospaceFont',
                        ),
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) controller.changePatternTable(value);
                },
              ),
              _buildDropdown<int>(
                label: 'Palette      ',
                value: selectedPalette,
                items: List.generate(
                  8,
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black,
                        fontWeight: selectedPalette == index
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontFamily: 'MonospaceFont',
                      ),
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) controller.changePalette(value);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: FutureBuilder<Image>(
              key: ValueKey('$selectedPatternTable-$selectedPalette'),
              future:
                  _createPatternImage(selectedPatternTable, selectedPalette),
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

      return widget.bus.ppu.palScreen[colorIndex.clamp(
        0,
        widget.bus.ppu.palScreen.length - 1,
      )];
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

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) =>
      Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: value,
                  items: items,
                  onChanged: onChanged,
                  isDense: true,
                  focusColor: Colors.white,
                  style: const TextStyle(fontSize: 10, color: Colors.black),
                ),
              ),
            ),
          ),
        ],
      );
}
