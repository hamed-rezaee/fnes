import 'package:flutter/material.dart';
import 'package:fnes/components/bus.dart';
import 'package:fnes/widgets/no_rom_loaded.dart';

class CartridgeDebugView extends StatelessWidget {
  const CartridgeDebugView({required this.bus, super.key});

  final Bus bus;

  @override
  Widget build(BuildContext context) {
    final info = bus.cart?.getMapperInfoMap();

    return info == null
        ? const NoRomLoaded()
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: info.entries
                .map(
                  (MapEntry<String, String> e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            e.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                              color: Colors.black,
                              fontFamily: 'MonospaceFont',
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            e.value,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.black,
                              fontFamily: 'MonospaceFont',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          );
  }
}
