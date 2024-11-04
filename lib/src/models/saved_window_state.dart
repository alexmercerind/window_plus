class SavedWindowState {
  final int x;
  final int y;
  final int width;
  final int height;
  final bool maximized;

  const SavedWindowState(
    this.x,
    this.y,
    this.width,
    this.height,
    this.maximized,
  );

  SavedWindowState copyWith({
    int? x,
    int? y,
    int? width,
    int? height,
    bool? maximized,
  }) {
    return SavedWindowState(
      x ?? this.x,
      y ?? this.y,
      width ?? this.width,
      height ?? this.height,
      maximized ?? this.maximized,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedWindowState && runtimeType == other.runtimeType && x == other.x && y == other.y && width == other.width && height == other.height && maximized == other.maximized;

  @override
  int get hashCode => Object.hash(x, y, width, height, maximized);

  @override
  String toString() => 'SavedWindowState('
      'x: $x, '
      'y: $y, '
      'width: $width, '
      'height: $height, '
      'maximized: $maximized'
      ')';

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'maximized': maximized,
      };

  factory SavedWindowState.fromJson(dynamic json) => SavedWindowState(
        json['x'],
        json['y'],
        json['width'],
        json['height'],
        json['maximized'],
      );
}
