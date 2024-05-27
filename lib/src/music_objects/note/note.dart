import 'dart:math';
import 'package:flutter/material.dart';
import 'package:simple_sheet_music/src/music_objects/note/note_duration.dart';
import 'package:simple_sheet_music/src/music_objects/note/note_pitch.dart';

import '../clef/clef_type.dart';
import '../interface/built_object.dart';
import '../interface/music_object_on_canvas.dart';
import '../interface/music_object_on_canvas_helper.dart';
import '../interface/music_object_style.dart';
import 'accidentals/accidental_renderer.dart';
import 'accidentals/accidental.dart';
import 'parts/fingering.dart';
import 'parts/note_stem.dart';
import 'parts/noteflag.dart';
import 'parts/noteflag_type.dart';
import 'parts/notehead.dart';
import 'parts/notehead_type.dart';
import 'positions.dart';

class Note implements MusicObjectStyle {
  @override
  final EdgeInsets? specifiedMargin;
  @override
  final Color color;
  final Fingering? fingering;
  final Pitch pitch;
  final NoteDuration noteDuration;
  final Accidental? accidental;
  final bool augmented;

  const Note({
    required this.pitch,
    required this.noteDuration,
    this.accidental,
    this.fingering,
    this.specifiedMargin,
    this.color = Colors.black,
    this.augmented = false,
  });

  @override
  BuiltObject build(ClefType clefType) {
    final noteHeadType = noteDuration.noteHeadType;
    final noteFlagType = noteDuration.noteFlagType;
    final stavePosition = StavePosition(pitch.position, clefType);

    return BuiltNote(
      this,
      noteHeadType,
      stavePosition,
      specifiedMargin,
      noteFlagType: noteFlagType,
      accidentalType: accidental,
      fingering: fingering,
      augmented: augmented,
    );
  }

  @override
  MusicObjectStyle copyWith(
          {Pitch? newPitch,
          NoteDuration? newNoteDuration,
          Accidental? newAccidental,
          Fingering? newFingering,
          Color? newColor,
          bool? newAugmented,
          EdgeInsets? newSpecifiedMargin}) =>
      Note(
        pitch: newPitch ?? pitch,
        noteDuration: newNoteDuration ?? noteDuration,
        accidental: newAccidental ?? accidental,
        fingering: newFingering ?? fingering,
        specifiedMargin: newSpecifiedMargin ?? specifiedMargin,
        color: newColor ?? color,
        augmented: newAugmented ?? augmented,
      );
}

class BuiltNote implements BuiltObject {
  static const minStemLength = 3.5;
  static const halfPositionHeight = 0.5;

  final Accidental? accidentalType;
  final NoteHeadType noteHeadType;
  final NoteFlagType? noteFlagType;
  final Fingering? fingering;
  final StavePosition stavePosition;
  final Note noteStyle;
  final EdgeInsets? specifiedMargin;
  final bool augmented;

  const BuiltNote(this.noteStyle, this.noteHeadType, this.stavePosition,
      this.specifiedMargin,
      {this.noteFlagType,
      this.accidentalType,
      this.fingering,
      this.augmented = false});

  FingeringRenderer? get _fingeringOnMeasure => fingering != null
      ? FingeringRenderer(fingering!,
          noteUpperHeight: _noteUpperHeight,
          noteHeadCenterX: _noteHead.noteHeadCenterX)
      : null;

  EdgeInsets get _defaultMargin =>
      specifiedMargin ?? EdgeInsets.all(_objectWidth / 4);
  EdgeInsets get _margin => noteStyle.specifiedMargin ?? _defaultMargin;

  bool get _hasAccidental => accidentalType != null;

  AccidentalRenderer? get _accidental => _hasAccidental
      ? AccidentalRenderer(accidentalType!, _localPosition)
      : null;

  double get _accidentalWidth => _accidental?.width ?? 0;

  double get _accidentalSpacing => _accidentalWidth / 5;

  int get _localPosition => stavePosition.localPosition;
  bool get _isStemUp => _localPosition < 0;

  bool get _hasStem => noteHeadType.hasStem;

  NoteHead get _noteHead => NoteHead(noteHeadType, _localPosition,
      _accidentalWidth + _accidentalSpacing, augmented);

  NoteStem? get _noteStem => _hasStem
      ? NoteStem(
          _isStemUp,
          stemRootOffset: _stemRootOffset,
          stemTipOffset: _stemTipOffset,
        )
      : null;

  double get _stemX => _isStemUp ? _noteHead.stemUpX : _noteHead.stemDownX;
  double get _stemRootY =>
      _isStemUp ? _noteHead.stemUpRootY : _noteHead.stemDownRootY;

  Offset get _stemRootOffset => Offset(_stemX, _stemRootY);

  double get _stemTipY {
    if (_hasFlag) return _noteFlag!.stemTipY;
    return _isStemUp ? _stemUpTipY : _stemDownTipY;
  }

  double get _stemUpTipY =>
      _isStemTipOnCenter ? 0.0 : _noteHead.stemUpRootY - NoteStem.minStemLength;
  double get _stemDownTipY => _isStemTipOnCenter
      ? 0.0
      : _noteHead.stemDownRootY + NoteStem.minStemLength;

  Offset get _stemTipOffset => Offset(_stemX, _stemTipY);

  bool get _hasFlag => noteFlagType != null;

  NoteFlag? get _noteFlag => _hasFlag
      ? NoteFlag(_noteHead, noteFlagType!, _isStemUp, _isStemTipOnCenter)
      : null;

  bool get _isStemTipOnCenter => _localPosition <= -7 || 7 <= _localPosition;

  @override
  ObjectOnCanvas placeOnCanvas({
    required double previousObjectsWidthSum,
    required double staffLineCenterY,
  }) {
    final helper = ObjectOnCanvasHelper(
      _bboxWithNoMargin,
      Offset(previousObjectsWidthSum, staffLineCenterY),
      _margin,
    );

    return NoteRenderer(helper, noteStyle,
        noteHead: _noteHead,
        noteStem: _noteStem,
        noteFlag: _noteFlag,
        accidental: _accidental,
        position: _localPosition,
        fingering: _fingeringOnMeasure);
  }

  double get _fingeringHeight => _fingeringOnMeasure?.upperHeight ?? 0.0;

  double get _noteHeadUpperHeight => _noteHead.upperHeight;
  double get _noteHeadLowerHeight => _noteHead.lowerHeight;

  double get _noteFlagUpperHeight => _noteFlag?.upperHeight ?? 0.0;
  double get _noteFlagLowerHeight => _noteFlag?.lowerHeight ?? 0.0;

  double get _noteStemUpperHeight => _noteStem?.upperHeight ?? 0.0;
  double get _noteStemLowerHeight => _noteStem?.lowerHeight ?? 0.0;

  double get _accidentalUpperHeight => _accidental?.upperHeight ?? 0.0;
  double get _accidentalLowerHeight => _accidental?.lowerHeight ?? 0.0;

  double get _noteUpperHeight => [
        _noteHeadUpperHeight,
        _noteFlagUpperHeight,
        _noteStemUpperHeight,
        _accidentalUpperHeight,
      ].fold<double>(0.0,
          (previousValue, notePartUpper) => max(previousValue, notePartUpper));

  @override
  double get upperHeight => _upperWithNoMargin + _margin.top;

  double get _upperWithNoMargin => max(_noteUpperHeight, _fingeringHeight);

  @override
  double get lowerHeight => _lowerWithNoMargin + _margin.bottom;

  double get _lowerWithNoMargin => [
        _noteHeadLowerHeight,
        _noteFlagLowerHeight,
        _noteStemLowerHeight,
        _accidentalLowerHeight
      ].fold<double>(0.0,
          (previousValue, notePartLower) => max(previousValue, notePartLower));

  Rect get _bboxWithNoMargin =>
      Rect.fromLTRB(0.0, -_upperWithNoMargin, _objectWidth, _lowerWithNoMargin);

  double get _noteHeadWidth => noteHeadType.width + (augmented ? 0.6 : 0.0);

  double get _noteFlagWidth => _noteFlag?.width ?? 0.0;

  double get _downNoteWidth => max(_noteHeadWidth, _noteFlagWidth);

  double get _upNoteWithFlagWidth =>
      _hasFlag ? _noteHeadWidth + _noteFlagWidth - NoteStem.stemThickness : 0.0;

  double get _upNoteWidth => max(_upNoteWithFlagWidth, _noteHeadWidth);

  double get _noteWidth => _isStemUp ? _upNoteWidth : _downNoteWidth;

  @override
  double get width => _objectWidth + _margin.horizontal;

  double get _objectWidth => _accidentalWidth + _accidentalSpacing + _noteWidth;
}

class NoteRenderer implements ObjectOnCanvas {
  static const _upperLedgerLineMinPosition = 6;
  static const _lowerLedgerLineMaxPosition = -6;

  final AccidentalRenderer? accidental;
  final NoteStem? noteStem;
  final int position;
  final NoteHead noteHead;
  final NoteFlag? noteFlag;
  final FingeringRenderer? fingering;
  @override
  final ObjectOnCanvasHelper helper;

  @override
  final MusicObjectStyle musicObjectStyle;
  const NoteRenderer(this.helper, this.musicObjectStyle,
      {required this.noteHead,
      required this.position,
      this.accidental,
      this.noteStem,
      this.noteFlag,
      this.fingering});

  double get noteHeadInitialX => noteHead.initialX(helper.renderOffset);
  double get noteHeadWidth => noteHead.width;
  // Rect get renderArea => helper.renderArea;
  bool get requireLedgerLine =>
      position <= _lowerLedgerLineMaxPosition ||
      _upperLedgerLineMinPosition <= position;

  @override
  void render(Canvas canvas, Size size, String fontFamily) {
    accidental?.render(
        canvas, size, helper.renderOffset, musicObjectStyle.color, fontFamily);
    noteHead.render(
        canvas, size, helper.renderOffset, musicObjectStyle.color, fontFamily);
    noteStem?.render(canvas, musicObjectStyle.color, helper.renderOffset);
    noteFlag?.render(
        canvas, size, helper.renderOffset, musicObjectStyle.color, fontFamily);
    fingering?.render(
        canvas, size, helper.renderOffset, musicObjectStyle.color, fontFamily);
  }

  @override
  bool isHit(Offset position) => helper.isHit(position);

  @override
  Rect get renderArea => helper.renderArea;
}
