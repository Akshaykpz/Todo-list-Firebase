import 'package:flutter/material.dart';

class ListHeader extends StatelessWidget {
  const ListHeader({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Tasks',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          '$count total',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
