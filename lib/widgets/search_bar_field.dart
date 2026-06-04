import 'package:flutter/material.dart';

class SearchBarField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const SearchBarField({
    super.key,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: const Padding(
          padding: EdgeInsets.only(right: 12),
          child: Icon(Icons.tune_rounded, size: 20),
        ),
      ),
    );
  }
}
