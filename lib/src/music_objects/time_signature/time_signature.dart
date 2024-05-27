import 'package:flutter/material.dart';
import 'package:simple_sheet_music/src/mixins/position_mixin.dart';
import 'package:simple_sheet_music/src/mixins/text_paint_mixin.dart';
import 'package:simple_sheet_music/src/music_objects/clef/clef_type.dart';

import '../interface/built_object.dart';
import '../interface/music_object_on_canvas.dart';
import '../interface/music_object_on_canvas_helper.dart';
import '../interface/music_object_style.dart';

enum TimeSignatureType {
  sig2over4('', 1.8),
  sig2over2('', 1.8),
  sig3over2('', 1.8),
  sig3over4('', 1.8),
  sig3over8('', 1.8),
  sig4over4('', 1.8),
  sig5over4('', 1.8),
  sig5over8('', 1.8),
  sig6over4('', 1.8),
  sig6over8('', 1.8),
  sig7over8('', 1.8),
  sig9over8('', 1.8),
  sig12over8('', 3.0);

  const TimeSignatureType(this.glyph, this.width);

  final String glyph;
  final double width;

  Rect get bbox => Rect.fromLTRB(0.0, -4, width, 0);
}

class TimeSignature implements MusicObjectStyle {
  @override
  final EdgeInsets? specifiedMargin;
  @override
  final Color color;
  final TimeSignatureType type;

  const TimeSignature(
    this.type, {
    this.specifiedMargin,
    this.color = Colors.black,
  });

  @override
  BuiltObject build(ClefType clefType) {
    return BuiltTimeSignature(
        TimeSignaturePart(type, -4), this, specifiedMargin);
  }

  @override
  MusicObjectStyle copyWith(
          {Color? newColor,
          TimeSignatureType? newType,
          EdgeInsets? newSpecifiedMargin}) =>
      TimeSignature(
        newType ?? type,
        color: newColor ?? color,
        specifiedMargin: newSpecifiedMargin ?? specifiedMargin,
      );
}

class BuiltTimeSignature implements BuiltObject {
  final TimeSignature timeSignature;
  final TimeSignaturePart timeSignaturePart;

  final EdgeInsets? specifiedMargin;

  const BuiltTimeSignature(
      this.timeSignaturePart, this.timeSignature, this.specifiedMargin);

  EdgeInsets get margin =>
      specifiedMargin ?? const EdgeInsets.only(left: 0.2, right: 0.6);

  @override
  double get lowerHeight => timeSignaturePart.lowerHeight;

  @override
  double get upperHeight => timeSignaturePart.upperHeight;

  @override
  double get width => timeSignaturePart.width + margin.horizontal;

  @override
  ObjectOnCanvas placeOnCanvas(
      {required double staffLineCenterY,
      required double previousObjectsWidthSum}) {
    final bbox =
        Rect.fromLTRB(0.0, -upperHeight, timeSignaturePart.width, lowerHeight);
    final helper = ObjectOnCanvasHelper(
        bbox, Offset(previousObjectsWidthSum, staffLineCenterY), margin);

    return TimeSignatureOnCanvas(helper, timeSignature, timeSignaturePart);
  }
}

class TimeSignatureOnCanvas implements ObjectOnCanvas {
  @override
  final ObjectOnCanvasHelper helper;

  @override
  final MusicObjectStyle musicObjectStyle;

  final TimeSignaturePart timeSignaturePart;

  const TimeSignatureOnCanvas(
      this.helper, this.musicObjectStyle, this.timeSignaturePart);

  @override
  bool isHit(Offset position) => helper.isHit(position);

  @override
  Rect get renderArea => helper.renderArea;

  @override
  void render(Canvas canvas, Size size, String fontFamily) {
    final renderOffset = helper.renderOffset;
    timeSignaturePart.render(
        canvas, size, renderOffset, musicObjectStyle.color, fontFamily);
  }
}

class TimeSignaturePart with HasPosition, TextPaint {
  final String _glyph;
  final int _position;
  final Rect _bbox;

  const TimeSignaturePart._(this._glyph, this._position, this._bbox);

  factory TimeSignaturePart(TimeSignatureType timeSignatureType, int position) {
    return TimeSignaturePart._(
        timeSignatureType.glyph, position, timeSignatureType.bbox);
  }

  double get width => _bbox.width;
  double get upperHeight => -_bbox.top + positionOffsetHeight(_position);
  double get lowerHeight => _bbox.bottom + positionOffsetHeight(_position);

  void render(
      Canvas canvas, Size size, Offset offset, Color color, String fontType) {
    offset += getPositionOffset(_position);
    textPaint(canvas, size, _glyph, offset, color, fontType);
  }
}
