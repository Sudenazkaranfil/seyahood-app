/// Model describing an image sticker.
class PictureModel {
  /// Image URL or asset path.
  String stringUrl;

  /// Top position inside the sticker bounds.
  double top;

  /// Whether the sticker is currently selected.
  bool isSelected;

  /// Rotation in radians.
  double angle;

  /// Scale factor for the image.
  double scale;

  /// Left position inside the sticker bounds.
  double left;

  /// Creates a picture sticker model.
  PictureModel(
      {required this.stringUrl,
      required this.top,
      required this.isSelected,
      this.angle = 0,
      required this.scale,
      required this.left});

  /// Creates a picture sticker from a URL or asset path.
  factory PictureModel.fromUrl(
    String url, {
    double top = 0,
    double left = 0,
    double scale = 1,
    double angle = 0,
    bool isSelected = false,
  }) {
    return PictureModel(
      stringUrl: url,
      top: top,
      left: left,
      scale: scale,
      angle: angle,
      isSelected: isSelected,
    );
  }

  /// Creates a model from a JSON map.
  PictureModel.fromJson(Map<String, dynamic> data)
      : stringUrl = data['url'] ?? '',
        top = data['top'] ?? 0,
        left = data['left'] ?? 0,
        angle = data['angle'] ?? 0,
        scale = data['scale'] ?? 1,
        isSelected = false;

  /// Serializes the model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'url': stringUrl,
      'top': top,
      'left': left,
      'angle': angle,
      'scale': scale,
    };
  }
}
