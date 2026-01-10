import 'dart:ui';

typedef ElementLayout = ({
  Offset offset,
  Size size,
});

typedef TextElementLayout = ({
  Offset offset,
  Size size,
  Alignment alignment,
  double fontSize
});

enum Alignment {
  left,
  center,
  right,
}
