/// {@template textPayload}
/// The text to be inserted in the cursor position.
///
/// The text inserted here will be placed in the
/// exact place the cursor currently is.
/// {@endtemplate}

/// {@template cursorIndexChangeQuantity}
/// If you want to change the cursor position
/// after the insertion, you can use this field.
///
/// For exemple:
/// * If you want to go back 2 characters with the cursor
/// after the insertion, you can set this field to -2.
///
/// * If you want to go forward 2 characters after the insertion,
/// you can set this field to 2.
/// {@endtemplate}

class InsertInCursorPayload {
  /// {@macro textPayload}
  final String text;

  /// {@macro cursorIndexChangeQuantity}
  final int cursorIndexChangeQuantity;

  /// # InsertInCursorPayload
  /// The payload with the data of what will be used to
  /// insert the text in the cursor position and change
  /// the position of the cursor after inserting a text.
  ///
  /// - [text]<br>
  /// {@macro textPayload}
  /// - [cursorIndexChangeQuantity]<br>
  /// {@macro cursorIndexChangeQuantity}
  const InsertInCursorPayload({
    required this.text,
    this.cursorIndexChangeQuantity = 0,
  });
}
