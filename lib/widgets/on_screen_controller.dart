import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fnes/cubits/nes_emulator_cubit.dart';

class OnScreenController extends StatefulWidget {
  const OnScreenController({super.key});

  @override
  State<OnScreenController> createState() => _OnScreenControllerState();
}

class _OnScreenControllerState extends State<OnScreenController> {
  final Set<String> _pressedButtons = {};

  void _onButtonDown(String buttonName) {
    setState(() => _pressedButtons.add(buttonName));

    context.read<NESEmulatorCubit>().pressButton(buttonName);
  }

  void _onButtonUp(String buttonName) {
    setState(() => _pressedButtons.remove(buttonName));

    context.read<NESEmulatorCubit>().releaseButton(buttonName);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 170,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStandardDPad(),
            _buildStandardUtilityButtons(),
            _buildStandardActionButtons(),
          ],
        ),
      );

  Widget _buildStandardDPad() {
    const buttonSize = 48.0;
    const spacing = 64;

    return SizedBox(
      width: buttonSize * 2 + spacing,
      height: buttonSize * 2 + spacing,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: buttonSize / 2 + spacing / 2,
            child: _buildDPadButton('up', Icons.arrow_upward),
          ),
          Positioned(
            bottom: 0,
            left: buttonSize / 2 + spacing / 2,
            child: _buildDPadButton('down', Icons.arrow_downward),
          ),
          Positioned(
            left: 0,
            top: buttonSize / 2 + spacing / 2,
            child: _buildDPadButton('left', Icons.arrow_back),
          ),
          Positioned(
            right: 0,
            top: buttonSize / 2 + spacing / 2,
            child: _buildDPadButton('right', Icons.arrow_forward),
          ),
        ],
      ),
    );
  }

  Widget _buildDPadButton(String direction, IconData icon) {
    final isPressed = _pressedButtons.contains(direction);

    return GestureDetector(
      onTapDown: (_) => _onButtonDown(direction),
      onTapUp: (_) => _onButtonUp(direction),
      onTapCancel: () => _onButtonUp(direction),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isPressed ? Colors.grey[700] : Colors.grey[600],
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 4,
              offset: Offset(0, isPressed ? 1 : 2),
            ),
          ],
          border: Border.all(color: Colors.black.withValues(alpha: 0.3)),
        ),
        child: Center(child: Icon(icon, color: Colors.white, size: 24)),
      ),
    );
  }

  Widget _buildStandardUtilityButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 12,
      children: [
        _buildUtilityButton('start', 'START'),
        _buildUtilityButton('select', 'SELECT'),
      ],
    );
  }

  Widget _buildUtilityButton(String buttonName, String label) {
    final isPressed = _pressedButtons.contains(buttonName);

    return GestureDetector(
      onTapDown: (_) => _onButtonDown(buttonName),
      onTapUp: (_) => _onButtonUp(buttonName),
      onTapCancel: () => _onButtonUp(buttonName),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isPressed ? Colors.grey[700] : Colors.grey[600],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 4,
              offset: Offset(0, isPressed ? 1 : 2),
            ),
          ],
          border: Border.all(color: Colors.black.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildStandardActionButtons() {
    const buttonSize = 64.0;

    return Row(
      spacing: 16,
      children: [
        _buildActionButton('b', 'B', Colors.red, buttonSize),
        _buildActionButton('a', 'A', Colors.red, buttonSize),
      ],
    );
  }

  Widget _buildActionButton(
    String buttonName,
    String label,
    Color color,
    double size,
  ) {
    final isPressed = _pressedButtons.contains(buttonName);

    return GestureDetector(
      onTapDown: (_) => _onButtonDown(buttonName),
      onTapUp: (_) => _onButtonUp(buttonName),
      onTapCancel: () => _onButtonUp(buttonName),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPressed ? color.withValues(alpha: 0.7) : color,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 4,
              offset: Offset(0, isPressed ? 1 : 2),
            ),
          ],
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
      ),
    );
  }
}
