import 'package:flutter/material.dart';

import '../model/picture_model.dart';
import '../model/text_model.dart';
import 'sticker_box.dart';
import 'text_box.dart';

/// Wrapper that renders either a picture or text sticker.
class StickerWidget extends StatelessWidget {
  /// Your widget should be move within this [boundWidth]
  final double boundWidth;

  /// Your widget should be move within this [boundHeight]
  final double boundHeight;

  /// Sticker data (either [PictureModel] or [TextModel]).
  final Object data;

  /// If you use onCancel then you Have to manage IsSelected field in model
  final VoidCallback? onCancel;

  /// If you use onTap then you Have to manage IsSelected field in model
  final VoidCallback? onTap;

  /// Disables interaction when true.
  final bool viewOnly;

  /// Custom controller Icons
  final Icon? resizeIcon;
  final Icon? rotateIcon;
  final Icon? closeIcon;
  final Icon? editIcon;

  /// Custom request to edit text. When provided, the default dialog is skipped.
  final TextEditRequest? onTextEditRequest;

  /// Creates a sticker widget for either a [PictureModel] or [TextModel].
  const StickerWidget({
    super.key,
    required this.boundWidth,
    required this.boundHeight,
    required this.data,
    this.viewOnly = false,
    this.resizeIcon,
    this.rotateIcon,
    this.closeIcon,
    this.editIcon,
    this.onTap,
    this.onCancel,
    this.onTextEditRequest,
  });

  @override
  Widget build(BuildContext context) {
    if (data is PictureModel) {
      return PictureEditingBox(
        boundWidth: boundWidth,
        boundHeight: boundHeight,
        pictureModel: data as PictureModel,
        viewOnly: viewOnly,
        resizeIcon: resizeIcon,
        rotateIcon: rotateIcon,
        closeIcon: closeIcon,
        onTap: onTap,
        onCancel: onCancel,
      );
    }

    if (data is TextModel) {
      return TextEditingBox(
        boundWidth: boundWidth,
        boundHeight: boundHeight,
        textModel: data as TextModel,
        viewOnly: viewOnly,
        resizeIcon: resizeIcon,
        rotateIcon: rotateIcon,
        closeIcon: closeIcon,
        editIcon: editIcon,
        onTap: onTap,
        onCancel: onCancel,
        onTextEditRequest: onTextEditRequest,
      );
    }

    throw ArgumentError(
      'StickerWidget data must be a PictureModel or TextModel. '
      'Received: ${data.runtimeType}',
    );
  }
}
