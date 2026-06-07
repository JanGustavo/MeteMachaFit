import 'package:flutter/material.dart';

class PlaceholderWidget extends StatelessWidget {
  final String label;
  const PlaceholderWidget({super.key, this.label = 'Widget'});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(label));
  }
}
