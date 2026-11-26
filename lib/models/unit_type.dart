enum UnitType {
  strip,
  box,
  bottle,
  piece;

  String get displayName {
    switch (this) {
      case UnitType.strip:
        return 'Strip';
      case UnitType.box:
        return 'Box';
      case UnitType.bottle:
        return 'Bottle';
      case UnitType.piece:
        return 'Piece';
    }
  }

  static UnitType fromString(String? val) {
    if (val == null) return UnitType.strip;
    switch (val.toUpperCase()) {
      case 'BOX':
        return UnitType.box;
      case 'BOTTLE':
        return UnitType.bottle;
      case 'PIECE':
        return UnitType.piece;
      case 'STRIP':
      default:
        return UnitType.strip;
    }
  }

  String toDbString() => name.toUpperCase();
}

