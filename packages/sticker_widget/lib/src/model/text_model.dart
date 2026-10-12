import 'package:flutter/material.dart';

/// Model describing a text sticker.
class TextModel {
  /// Displayed text.
  String name;

  /// Text style for rendering.
  TextStyle textStyle;

  /// Top position inside the sticker bounds.
  double top;

  /// Left position inside the sticker bounds.
  double left;

  /// Whether the sticker is currently selected.
  bool isSelected;

  /// Rotation in radians.
  double angle;

  /// Text alignment.
  TextAlign textAlign;

  /// Scale factor for the text.
  double scale;

  /// Creates a text sticker model.
  TextModel(
      {required this.name,
      required this.textStyle,
      required this.top,
      required this.isSelected,
      this.angle = 0,
      required this.textAlign,
      required this.scale,
      required this.left});

  /// Creates a text sticker from a string.
  factory TextModel.fromText(
    String text, {
    TextStyle? textStyle,
    double top = 0,
    double left = 0,
    double scale = 1,
    double angle = 0,
    bool isSelected = false,
    TextAlign textAlign = TextAlign.left,
  }) {
    return TextModel(
      name: text,
      textStyle: textStyle ?? const TextStyle(),
      top: top,
      left: left,
      scale: scale,
      angle: angle,
      isSelected: isSelected,
      textAlign: textAlign,
    );
  }

  /// Creates a model from a JSON map.
  TextModel.fromJson(Map<String, dynamic> data)
      : name = data['text'] ?? '',
        textStyle = TextStyle(
          fontFamily: data['textStyle']!['font'],
          fontStyle: FontStyle.values[data['textStyle']!['fontStyle'] ?? 0],
          fontWeight: FontWeight.values[data['textStyle']!['fontWeight'] ?? 0],
          fontSize: data['textStyle']!['fontSize'],
          height: data['textStyle']!['height'],
          letterSpacing: data['textStyle']!['letterSpacing'],
          color: data['textStyle']!['color'] != null
              ? Color(data['textStyle']!['color'])
              : null,
          backgroundColor: data['textStyle']!['backgroundColor'] != null
              ? Color(data['textStyle']!['backgroundColor'])
              : null,
        ),
        top = data['top'] ?? 0,
        left = data['left'] ?? 0,
        scale = data['scale'] ?? 1,
        angle = data['angle'] ?? 0,
        isSelected = false,
        textAlign = TextAlign.values[data['textAlign'] ?? 0];

  /// Serializes the model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'text': name,
      'top': top,
      'left': left,
      'scale': scale,
      'angle': angle,
      'textStyle': {
        'font': textStyle.fontFamily,
        'fontStyle': textStyle.fontStyle?.index ?? 0,
        'fontWeight': textStyle.fontWeight?.index ?? 0,
        'fontSize': textStyle.fontSize,
        'height': textStyle.height,
        'letterSpacing': textStyle.letterSpacing,
        'color': textStyle.color?.toARGB32(),
        'backgroundColor': textStyle.backgroundColor?.toARGB32(),
      },
      'textAlign': textAlign.index
    };
  }
}
