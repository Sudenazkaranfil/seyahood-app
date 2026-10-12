import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

import '../model/text_model.dart';

/// Callback for providing a custom text editing flow.
typedef TextEditRequest =
    Future<String?> Function(BuildContext context, String currentText);

/// Editable sticker widget for text.
class TextEditingBox extends StatefulWidget {
  /// TextModel for your text
  final TextModel textModel;

  /// Your widget should be move within this [boundWidth]
  final double boundWidth;

  /// Your widget should be move within this [boundHeight]
  final double boundHeight;

  /// Disables interaction when true.
  final bool viewOnly;

  /// Custom controller Icons
  final Icon? editIcon;
  final Icon? resizeIcon;
  final Icon? rotateIcon;
  final Icon? closeIcon;

  /// If you use onTap then you Have to manage IsSelected field in TextModel
  final Function()? onTap;

  /// If you use onCancel then you Have to manage IsSelected field in TextModel
  final Function()? onCancel;

  /// Custom request to edit text. When provided, the default dialog is skipped.
  final TextEditRequest? onTextEditRequest;

  /// Create a [TextEditingBox] widget
  ///
  /// [TextModel] detail of your picture
  /// [onTap] callback function that called when you tap on [TextEditingBox]
  /// [onCancel] callback function that called when you tap on Cross icon in [TextEditingBox] border
  TextEditingBox({
    super.key,
    required this.textModel,
    required this.boundWidth,
    required this.boundHeight,
    this.editIcon,
    this.resizeIcon,
    this.rotateIcon,
    this.closeIcon,
    this.viewOnly = false,
    this.onCancel,
    this.onTap,
    this.onTextEditRequest,
  });

  @override
  _TextEditingBoxState createState() => _TextEditingBoxState();
}

class _TextEditingBoxState extends State<TextEditingBox> {
  Offset deltaOffset = const Offset(0, 0);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.textModel.top,
      left: widget.textModel.left,
      child: Transform.scale(
        scale: widget.textModel.scale,
        child: Transform.rotate(
          angle: widget.textModel.angle,
          child: GestureDetector(
            onScaleStart: (tap) {
              setState(() => deltaOffset = tap.focalPoint);
            },
            onScaleUpdate: (tap) {
              if (widget.viewOnly) {
                return;
              }

              setState(() {
                if (tap.pointerCount == 2) {
                  widget.textModel.scale = tap.scale;
                  widget.textModel.angle = tap.rotation;
                }
                if ((widget.textModel.left +
                            tap.focalPoint.dx -
                            deltaOffset.dx) <=
                        widget.boundWidth &&
                    (widget.textModel.left +
                            tap.focalPoint.dx -
                            deltaOffset.dx) >
                        0) {
                  widget.textModel.left += tap.focalPoint.dx - deltaOffset.dx;
                }
                if ((widget.textModel.top +
                            tap.focalPoint.dy -
                            deltaOffset.dy) <
                        widget.boundHeight &&
                    (widget.textModel.top +
                            tap.focalPoint.dy -
                            deltaOffset.dy) >
                        0) {
                  widget.textModel.top += tap.focalPoint.dy - deltaOffset.dy;
                }

                deltaOffset = tap.focalPoint;
              });
            },
            onTap: () {
              if (widget.viewOnly) {
                return;
              }

              if (widget.onTap == null) {
                setState(() {
                  widget.textModel.isSelected = !widget.textModel.isSelected;
                });
              } else {
                widget.onTap!();
              }
            },
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DottedBorder(
                    options: RectDottedBorderOptions(
                      padding: const EdgeInsets.all(4),
                      color: widget.textModel.isSelected
                          ? Colors.grey[600]!
                          : Colors.transparent,
                    ),
                    child: Text(
                      widget.textModel.name,
                      style: widget.textModel.textStyle,
                      textAlign: widget.textModel.textAlign,
                      textScaleFactor: widget.textModel.scale,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () {
                      if (widget.onCancel != null) {
                        widget.onCancel!();
                      }

                      setState(() {
                        widget.textModel.isSelected = false;
                      });
                    },
                    child: widget.textModel.isSelected
                        ? Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black, width: 1),
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child:
                                widget.closeIcon ??
                                const Icon(
                                  Icons.close,
                                  color: Colors.black,
                                  size: 12,
                                ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: InkWell(
                    onTap: () async {
                      if (widget.viewOnly) {
                        return;
                      }
                      await _showEditBox(context: context);
                    },
                    child: widget.textModel.isSelected
                        ? Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black, width: 1),
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child:
                                widget.editIcon ??
                                const Icon(
                                  Icons.edit,
                                  color: Colors.black,
                                  size: 10,
                                ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: GestureDetector(
                    onScaleUpdate: (detail) {
                      setState(
                        () => widget.textModel.angle =
                            detail.focalPoint.direction,
                      );
                    },
                    child: widget.textModel.isSelected
                        ? Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black, width: 1),
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child:
                                widget.rotateIcon ??
                                const Icon(
                                  Icons.rotate_right,
                                  color: Colors.black,
                                  size: 10,
                                ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onPanUpdate: (tap) {
                      if (tap.delta.dx.isNegative &&
                          widget.textModel.scale > .8) {
                        setState(() => widget.textModel.scale -= 0.01);
                      } else if (!tap.delta.dx.isNegative &&
                          widget.textModel.scale < 5) {
                        setState(() => widget.textModel.scale += 0.01);
                      }
                    },
                    child: widget.textModel.isSelected
                        ? Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black, width: 1),
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child:
                                widget.resizeIcon ??
                                const Icon(
                                  Icons.crop,
                                  color: Colors.black,
                                  size: 10,
                                ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditBox({required BuildContext context}) async {
    if (widget.onTextEditRequest != null) {
      final result = await widget.onTextEditRequest!(
        context,
        widget.textModel.name,
      );
      if (result == null) {
        return;
      }
      setState(() => widget.textModel.name = result);
      return;
    }

    final controller = TextEditingController(text: widget.textModel.name);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(240, 200, 200, 200),
          title: const Text('Edit Text'),
          content: TextField(
            controller: controller,
            maxLines: 6,
            minLines: 1,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter text'),
          ),
          actions: [
            ElevatedButton(
              child: const Text('Done'),
              onPressed: () {
                setState(() => widget.textModel.name = controller.text);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
