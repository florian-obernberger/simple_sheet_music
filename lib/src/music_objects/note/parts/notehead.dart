import 'dart:ui';

import '../../../mixins/position_mixin.dart';
import '../../../mixins/text_paint_mixin.dart';
import '../note_parts.dart';
import 'note_stem.dart';
import 'notehead_type.dart';

class NoteHead with HasPosition, TextPaint implements NoteParts {
  final NoteHeadType noteHeadType;
  final int position;
  final double accidentalWidth;
  final bool augmented;

  const NoteHead(
      this.noteHeadType, this.position, this.accidentalWidth, this.augmented);

  Offset get _positionOffset => getPositionOffset(position);

  Offset get _noteHeadOffset => _positionOffset + Offset(accidentalWidth, 0);

  String get _glyph => noteHeadType.glyph;

  Rect get bbox => noteHeadType.glyphBbox
      .shift(Offset(accidentalWidth, positionOffsetHeight(position)));

  double get width => bbox.width;

  @override
  double get upperHeight => -bbox.top;

  @override
  double get lowerHeight => bbox.bottom;

  double noteFlagX(bool isStemUp) => isStemUp
      ? accidentalWidth +
          noteHeadType.stemUpRootRightBottom!.dx -
          NoteStem.stemThickness
      : accidentalWidth;

  double initialX(Offset globalOffset) => globalOffset.dx + _noteHeadOffset.dx;

  double get stemUpX =>
      accidentalWidth +
      noteHeadType.stemUpRootRightBottom!.dx -
      NoteStem.stemThickness / 2;

  double get stemDownX =>
      accidentalWidth +
      noteHeadType.stemDownRootLeftTop!.dx +
      NoteStem.stemThickness / 2;

  double get stemUpRootY =>
      noteHeadType.stemUpRootRightBottom!.dy + positionOffsetHeight(position);

  double get stemDownRootY =>
      noteHeadType.stemDownRootLeftTop!.dy + positionOffsetHeight(position);

  double get noteHeadCenterX => _noteHeadOffset.dx + width / 2;

  render(Canvas canvas, Size size, Offset renderOffset, Color color,
      String fontFamily) {
    textPaint(canvas, size, _glyph, renderOffset + _noteHeadOffset, color,
        fontFamily);

    if (augmented) {
      textPaint(
          canvas,
          size,
          ' ',
          renderOffset +
              _noteHeadOffset +
              Offset(width * 0.9, _noteHeadOffset.dy % 1 != 0.0 ? 0.0 : -0.5),
          color,
          fontFamily);
    }
  }
}
