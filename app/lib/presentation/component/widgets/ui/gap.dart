import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';

class Gap extends StatelessWidget {
  final double width;
  final double height;

  /// Square gap where width == height.
  const Gap(double size, {super.key}) : width = size, height = size;

  /// Gap with explicit width/height.
  const Gap.only({super.key, this.width = kSpace0, this.height = kSpace0});

  /// Square presets.
  const Gap.xs({super.key}) : width = kSpace1, height = kSpace1;
  const Gap.sm({super.key}) : width = kSpace2, height = kSpace2;
  const Gap.md({super.key}) : width = kSpace4, height = kSpace4;
  const Gap.lg({super.key}) : width = kSpace6, height = kSpace6;
  const Gap.xl({super.key}) : width = kSpace7, height = kSpace7;

  /// Directional fluent API:
  /// - `Gap.horizontal.sm()`
  /// - `Gap.vertical.md()`
  static const horizontal = GapAxisFactory._(Axis.horizontal);
  static const vertical = GapAxisFactory._(Axis.vertical);

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, height: height);
  }
}

class GapAxisFactory {
  final Axis _axis;

  const GapAxisFactory._(this._axis);

  Gap _gap(double size, {Key? key}) {
    return _axis == Axis.horizontal
        ? Gap.only(key: key, width: size)
        : Gap.only(key: key, height: size);
  }

  Gap none({Key? key}) => _gap(kSpace0, key: key);
  Gap xs({Key? key}) => _gap(kSpace1, key: key);
  Gap sm({Key? key}) => _gap(kSpace2, key: key);
  Gap md({Key? key}) => _gap(kSpace4, key: key);
  Gap lg({Key? key}) => _gap(kSpace6, key: key);
  Gap xl({Key? key}) => _gap(kSpace7, key: key);
  Gap custom(double size, {Key? key}) => _gap(size, key: key);
}
