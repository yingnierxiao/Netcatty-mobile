import 'package:flutter/widgets.dart';

import '../../domain/models/settings.dart';

/// Tracks only two-finger touch spans, without competing with terminal scroll
/// and text-selection gesture recognizers.
class TerminalPinchZoom {
  final _touches = <int, Offset>{};
  double? _initialSpan;
  double _initialSize = 14;
  double _lastSize = 14;

  bool get hasMultipleTouches => _touches.length >= 2;

  void pointerDown(int pointer, Offset position, double fontSize) {
    _touches[pointer] = position;
    if (_touches.length == 2) {
      _initialSpan = _span;
      _initialSize = fontSize;
      _lastSize = fontSize;
    } else {
      _initialSpan = null;
    }
  }

  double get _span => (_touches.values.first - _touches.values.last).distance;

  double? pointerMove(int pointer, Offset position) {
    if (!_touches.containsKey(pointer)) return null;
    _touches[pointer] = position;
    if (_touches.length != 2) return null;
    final span = _span;
    final initial = _initialSpan;
    if (initial == null || initial < 8) {
      if (span >= 8) _initialSpan = span;
      return null;
    }
    final scaled = _initialSize * span / initial;
    final size = ((scaled * 2).round() / 2)
        .clamp(minTerminalFontSize, maxTerminalFontSize)
        .toDouble();
    if (size == _lastSize) return null;
    _lastSize = size;
    return size;
  }

  void pointerEnd(int pointer) {
    if (_touches.remove(pointer) == null) return;
    _initialSpan = null;
    if (_touches.length == 2) {
      _initialSpan = _span;
      _initialSize = _lastSize;
    }
  }

  void reset() {
    _touches.clear();
    _initialSpan = null;
  }
}
