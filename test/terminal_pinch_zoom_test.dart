import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netcatty_mobile/presentation/widgets/terminal_pinch_zoom.dart';

void main() {
  test('single finger scrolling does not change font size', () {
    final zoom = TerminalPinchZoom();
    zoom.pointerDown(1, Offset.zero, 14);
    expect(zoom.pointerMove(1, const Offset(0, 200)), isNull);
    zoom.pointerEnd(1);
    expect(zoom.hasMultipleTouches, isFalse);
  });

  test('pinch scales font in both directions and clamps to settings limits',
      () {
    final zoom = TerminalPinchZoom();
    zoom.pointerDown(1, Offset.zero, 14);
    zoom.pointerDown(2, const Offset(100, 0), 14);
    expect(zoom.hasMultipleTouches, isTrue);
    expect(zoom.pointerMove(2, const Offset(150, 0)), 21);
    expect(zoom.pointerMove(2, const Offset(200, 0)), 24);
    expect(zoom.pointerMove(2, const Offset(300, 0)), isNull);
    expect(zoom.pointerMove(2, const Offset(50, 0)), 7);
    expect(zoom.pointerMove(2, const Offset(20, 0)), 6);
    zoom.pointerEnd(2);
    expect(zoom.pointerMove(1, const Offset(20, 0)), isNull);
    zoom.pointerDown(3, const Offset(120, 0), 6);
    expect(zoom.pointerMove(3, const Offset(220, 0)), 12);
  });

  test('third touch pauses zoom and removing it rebases the span', () {
    final zoom = TerminalPinchZoom();
    zoom.pointerDown(1, Offset.zero, 14);
    zoom.pointerDown(2, const Offset(100, 0), 14);
    expect(zoom.pointerMove(2, const Offset(150, 0)), 21);
    zoom.pointerDown(3, const Offset(20, 20), 21);
    expect(zoom.pointerMove(2, const Offset(200, 0)), isNull);
    zoom.pointerEnd(3);
    expect(zoom.pointerMove(2, const Offset(200, 0)), isNull);
    expect(zoom.pointerMove(2, const Offset(220, 0)), 23);
    zoom.reset();
    expect(zoom.hasMultipleTouches, isFalse);
  });
}
