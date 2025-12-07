import 'package:flutter/services.dart';

class InputMapper {
  static const int buttonRight = 0x01;
  static const int buttonLeft = 0x02;
  static const int buttonDown = 0x04;
  static const int buttonUp = 0x08;
  static const int buttonStart = 0x10;
  static const int buttonSelect = 0x20;
  static const int buttonB = 0x40;
  static const int buttonA = 0x80;

  static int? getKeyBit(LogicalKeyboardKey key) => switch (key) {
        LogicalKeyboardKey.arrowUp => buttonUp,
        LogicalKeyboardKey.arrowDown => buttonDown,
        LogicalKeyboardKey.arrowLeft => buttonLeft,
        LogicalKeyboardKey.arrowRight => buttonRight,
        LogicalKeyboardKey.keyZ => buttonA,
        LogicalKeyboardKey.keyX => buttonB,
        LogicalKeyboardKey.space => buttonStart,
        LogicalKeyboardKey.enter => buttonSelect,
        _ => null,
      };

  static int? getButtonBit(String buttonName) =>
      switch (buttonName.toLowerCase()) {
        'up' => buttonUp,
        'down' => buttonDown,
        'left' => buttonLeft,
        'right' => buttonRight,
        'a' => buttonA,
        'b' => buttonB,
        'start' => buttonStart,
        'select' => buttonSelect,
        _ => null,
      };

  static int pressButton(int currentState, int buttonBit) =>
      currentState | buttonBit;

  static int releaseButton(int currentState, int buttonBit) =>
      currentState & ~buttonBit;
}
