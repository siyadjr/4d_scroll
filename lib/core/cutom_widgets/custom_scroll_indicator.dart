import 'package:flutter/material.dart';

class Dot extends StatelessWidget {
  final bool isActive;
  final Color? color;
  final int? count;
  const Dot({super.key, required this.isActive, this.color, this.count});

  @override
  Widget build(BuildContext context) {
    if (!isActive) return const SizedBox.shrink();

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        shape: BoxShape.circle,
      ),
      child: count != null && count != 0
          ? Center(
              child: Text(
                count.toString(),
                style: const TextStyle(color: Colors.black, fontSize: 10),
              ),
            )
          : const SizedBox(),
    );
  }
}