import 'package:flutter/material.dart';

class NoRomLoaded extends StatelessWidget {
  const NoRomLoaded({this.fontSize = 9, super.key});

  final double fontSize;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        'NO ROM LOADED',
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontFamily: 'MonospaceFont',
        ),
      ),
    ),
  );
}
