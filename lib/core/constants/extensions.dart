import 'package:flutter/material.dart';

extension DoubleOpetaions on int {
  // TODO: Use it with SizedBox Widget
  Widget get vrSpace => SizedBox(height: toDouble());

  Widget get hrSpace => SizedBox(width: toDouble());
}