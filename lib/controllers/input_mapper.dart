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

  static const int turboA = 0x100;
  static const int turboB = 0x200;

  static int? getKeyBit(LogicalKeyboardKey key) => switch (key) {
    LogicalKeyboardKey.arrowUp => buttonUp,
    LogicalKeyboardKey.arrowDown => buttonDown,
    LogicalKeyboardKey.arrowLeft => buttonLeft,
    LogicalKeyboardKey.arrowRight => buttonRight,
    LogicalKeyboardKey.keyZ => buttonA,
    LogicalKeyboardKey.keyX => buttonB,
    LogicalKeyboardKey.space => buttonStart,
    LogicalKeyboardKey.enter => buttonSelect,
    LogicalKeyboardKey.keyA => turboA,
    LogicalKeyboardKey.keyS => turboB,
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
        'turbea' => turboA,
        'turbob' => turboB,
        _ => null,
      };

  static String? getButtonName(int buttonBit) => switch (buttonBit) {
    buttonUp => 'UP',
    buttonDown => 'DOWN',
    buttonLeft => 'LEFT',
    buttonRight => 'RIGHT',
    buttonA => 'A',
    buttonB => 'B',
    buttonStart => 'START',
    buttonSelect => 'SELECT',
    turboA => 'TURBO_A',
    turboB => 'TURBO_B',
    _ => null,
  };

  static int pressButton(int currentState, int buttonBit) =>
      currentState | buttonBit;

  static int releaseButton(int currentState, int buttonBit) =>
      currentState & ~buttonBit;
}
