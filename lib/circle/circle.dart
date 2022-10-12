import 'package:freezed_annotation/freezed_annotation.dart';

part 'circle.freezed.dart';

@freezed
class Circle with _$Circle {
  factory Circle({
    required String x,
    required String y,
  }) = _Circle;
}