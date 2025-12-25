import 'package:flutter/material.dart';
import 'package:fnes/controllers/nes_emulator_controller.dart';
import 'package:fnes/utils/responsive_utils.dart';

class OnScreenController extends StatefulWidget {
  const OnScreenController({required this.controller, super.key});

  final NESEmulatorController controller;

  @override
  State<OnScreenController> createState() => _OnScreenControllerState();
}

class _OnScreenControllerState extends State<OnScreenController> {
  final Set<String> _pressedButtons = {};

  void _onButtonDown(String buttonName) {
    setState(() => _pressedButtons.add(buttonName));

    widget.controller.pressButton(buttonName);
  }

  void _onButtonUp(String buttonName) {
    setState(() => _pressedButtons.remove(buttonName));

    widget.controller.releaseButton(buttonName);
  }

  @override
  Widget build(BuildContext context) {
    const baseHeight = 170.0;
    final scaleFactor = context.responsive<double>(
      mobile: 0.8,
      tablet: 0.9,
      desktop: 1,
    );
    final height = baseHeight * scaleFactor;

    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStandardDPad(scaleFactor),
          _buildStandardUtilityButtons(scaleFactor),
          _buildStandardActionButtons(scaleFactor),
        ],
      ),
    );
  }

  Widget _buildStandardDPad(double scaleFactor) {
    final buttonSize = 48.0 * scaleFactor;
    final diagonalSize = 36.0 * scaleFactor;
    final spacing = 64.0 * scaleFactor;

    return SizedBox(
      width: buttonSize * 2 + spacing,
      height: buttonSize * 2 + spacing,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: buttonSize / 2 + spacing / 2,
            child: _buildDPadButton('up', Icons.arrow_upward, buttonSize),
          ),
          Positioned(
            bottom: 0,
            left: buttonSize / 2 + spacing / 2,
            child: _buildDPadButton('down', Icons.arrow_downward, buttonSize),
          ),
          Positioned(
            left: 0,
            top: buttonSize / 2 + spacing / 2,
            child: _buildDPadButton('left', Icons.arrow_back, buttonSize),
          ),
          Positioned(
            right: 0,
            top: buttonSize / 2 + spacing / 2,
            child: _buildDPadButton('right', Icons.arrow_forward, buttonSize),
          ),
          Positioned(
            top: 6 * scaleFactor,
            left: 6 * scaleFactor,
            child: _buildDiagonalButton(
              ['up', 'left'],
              Icons.north_west,
              diagonalSize,
              scaleFactor,
            ),
          ),
          Positioned(
            top: 6 * scaleFactor,
            right: 6 * scaleFactor,
            child: _buildDiagonalButton(
              ['up', 'right'],
              Icons.north_east,
              diagonalSize,
              scaleFactor,
            ),
          ),
          Positioned(
            bottom: 6 * scaleFactor,
            left: 6 * scaleFactor,
            child: _buildDiagonalButton(
              ['down', 'left'],
              Icons.south_west,
              diagonalSize,
              scaleFactor,
            ),
          ),
          Positioned(
            bottom: 6 * scaleFactor,
            right: 6 * scaleFactor,
            child: _buildDiagonalButton(
              ['down', 'right'],
              Icons.south_east,
              diagonalSize,
              scaleFactor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagonalButton(
    List<String> directions,
    IconData icon,
    double size,
    double scaleFactor,
  ) {
    final isPressed = directions.every(_pressedButtons.contains);
    final iconSize = 16.0 * scaleFactor;

    return Listener(
      onPointerDown: (_) => directions.forEach(_onButtonDown),
      onPointerUp: (_) => directions.forEach(_onButtonUp),
      onPointerCancel: (_) => directions.forEach(_onButtonUp),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isPressed ? Colors.grey[700] : Colors.grey[600],
          borderRadius: BorderRadius.circular(6 * scaleFactor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 4 * scaleFactor,
              offset: Offset(0, isPressed ? scaleFactor : 2 * scaleFactor),
            ),
          ],
          border: Border.all(color: Colors.black.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }

  Widget _buildDPadButton(String direction, IconData icon, double size) {
    final isPressed = _pressedButtons.contains(direction);
    final iconSize = size * 0.5;

    return Listener(
      onPointerDown: (_) => _onButtonDown(direction),
      onPointerUp: (_) => _onButtonUp(direction),
      onPointerCancel: (_) => _onButtonUp(direction),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isPressed ? Colors.grey[700] : Colors.grey[600],
          borderRadius: BorderRadius.circular(6 * (size / 48)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 4 * (size / 48),
              offset: Offset(0, isPressed ? size / 48 : 2 * (size / 48)),
            ),
          ],
          border: Border.all(color: Colors.black.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }

  Widget _buildStandardUtilityButtons(double scaleFactor) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: 16 * scaleFactor,
    children: [
      _buildUtilityButton('start', 'START', scaleFactor),
      _buildUtilityButton('select', 'SELECT', scaleFactor),
      if (widget.controller.rewindEnabled.value)
        _buildRewindButton(scaleFactor),
    ],
  );

  Widget _buildRewindButton(double scaleFactor) {
    final isRewinding = widget.controller.isRewinding.value;
    final buttonWidth = 120.0 * scaleFactor;
    final fontSize = 12.0 * scaleFactor;
    final iconSize = 16.0 * scaleFactor;

    return Listener(
      onPointerDown: (_) => widget.controller.startRewind(),
      onPointerUp: (_) => widget.controller.stopRewind(),
      onPointerCancel: (_) => widget.controller.stopRewind(),
      child: Container(
        width: buttonWidth,
        padding: EdgeInsets.symmetric(
          horizontal: 16 * scaleFactor,
          vertical: 8 * scaleFactor,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6 * scaleFactor),
          color: isRewinding
              ? Colors.deepOrange.withValues(alpha: 0.8)
              : Colors.grey[600],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 4 * scaleFactor,
              offset: Offset(0, isRewinding ? scaleFactor : 2 * scaleFactor),
            ),
          ],
          border: Border.all(color: Colors.black.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fast_rewind, color: Colors.white, size: iconSize),
            SizedBox(width: 4 * scaleFactor),
            Text(
              'REWIND',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilityButton(
    String buttonName,
    String label,
    double scaleFactor,
  ) {
    final isPressed = _pressedButtons.contains(buttonName);
    final buttonWidth = 80.0 * scaleFactor;
    final fontSize = 10.0 * scaleFactor;

    return Listener(
      onPointerDown: (_) => _onButtonDown(buttonName),
      onPointerUp: (_) => _onButtonUp(buttonName),
      onPointerCancel: (_) => _onButtonUp(buttonName),
      child: Container(
        width: buttonWidth,
        padding: EdgeInsets.symmetric(
          horizontal: 16 * scaleFactor,
          vertical: 8 * scaleFactor,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6 * scaleFactor),
          color: isPressed ? Colors.grey[700] : Colors.grey[600],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 4 * scaleFactor,
              offset: Offset(0, isPressed ? scaleFactor : 2 * scaleFactor),
            ),
          ],
          border: Border.all(color: Colors.black.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildStandardActionButtons(double scaleFactor) {
    final buttonSize = 64.0 * scaleFactor;

    return Row(
      spacing: 16 * scaleFactor,
      children: [
        _buildActionButton('b', 'B', Colors.red, buttonSize, scaleFactor),
        _buildActionButton('a', 'A', Colors.red, buttonSize, scaleFactor),
      ],
    );
  }

  Widget _buildActionButton(
    String buttonName,
    String label,
    Color color,
    double size,
    double scaleFactor,
  ) {
    final isPressed = _pressedButtons.contains(buttonName);
    final fontSize = 24.0 * scaleFactor;

    return Listener(
      onPointerDown: (_) => _onButtonDown(buttonName),
      onPointerUp: (_) => _onButtonUp(buttonName),
      onPointerCancel: (_) => _onButtonUp(buttonName),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPressed ? color.withValues(alpha: 0.7) : color,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 4 * scaleFactor,
              offset: Offset(0, isPressed ? scaleFactor : 2 * scaleFactor),
            ),
          ],
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.3),
            width: 1.5 * scaleFactor,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
        ),
      ),
    );
  }
}
