import 'dart:async';
import 'package:cursor_autocomplete_options/src/debouncer.dart';
import 'package:cursor_autocomplete_options/src/overlay_choices_listview_widget.dart';
import 'package:flutter/material.dart';

class OptionsController<T> {
  final ValueNotifier<TextEditingValue> _textEditingController;
  final FocusNode textfieldFocusNode;
  final FocusNode keyboardListenerNode;

  final OverlayState _overlayState;
  OverlayEntry? _suggestionTagoverlayEntry;

  String Function(T option)? optionAsString;
  double overlayCardHeight;
  double overlayCardWeight;
  final Debouncer _debouncer;

  FutureOr<void> Function(T option)? onSelectedOption;
  FutureOr<String> Function(T option)? onSelectInsertInCursor;

  bool willAutomaticallyCloseDialogAfterSelection;
  double _topMarginOffset = 0;
  double _leftMarginOffset = 0;

  OptionsController({
    required this.textfieldFocusNode,
    required ValueNotifier<TextEditingValue> textEditingController,
    required BuildContext context,
    this.optionAsString,
    this.overlayCardHeight = 200,
    this.overlayCardWeight = 200,
    Duration debounceDuration = const Duration(milliseconds: 300),
    this.onSelectedOption,
    this.onSelectInsertInCursor,
    this.willAutomaticallyCloseDialogAfterSelection = true,
  })  : _textEditingController = textEditingController,
        _overlayState = Overlay.of(context),
        _debouncer = Debouncer(timerDuration: debounceDuration),
        keyboardListenerNode = FocusNode(),
        _context = context,
        assert(
            (optionAsString == null && T == String) || optionAsString != null,
            'The parameter `optionAsString` can only be null if the generic type <T> is not String.');

  BuildContext _context;
  void updateContext(BuildContext context) {
    _context = context;
  }

  void showOptionsMenu(List<T> options) {
    _debouncer.resetDebounce(() {
      _setOverlayEntry(options);
      if (_suggestionTagoverlayEntry != null) {
        _overlayState.insert(_suggestionTagoverlayEntry!);
      }
    });
  }

  void dispose() {
    _debouncer.dispose();
    _suggestionTagoverlayEntry?.remove();
    _suggestionTagoverlayEntry = null;
    textfieldFocusNode.dispose();
    keyboardListenerNode.dispose();
  }

  void _setOverlayEntry(List<T> options) {
    _displayWidgetInCursorPosition(_textEditingController.value);

    textfieldFocusNode.unfocus();
    keyboardListenerNode.requestFocus();
    _suggestionTagoverlayEntry = OverlayEntry(
      builder: (context) {
        return OverlayChoicesListViewWidget<T>(
          width: overlayCardWeight,
          height: overlayCardHeight,
          focusNode: keyboardListenerNode,
          options: options,
          optionAsString: (option) {
            if (optionAsString != null) {
              return optionAsString!.call(option);
            } else {
              return option as String;
            }
          },
          onSelect: (T option) async {
            await onSelectedOption?.call(option);
            if (onSelectInsertInCursor != null) {
              await manegeSelectedText(option);
            }

            if (willAutomaticallyCloseDialogAfterSelection) {
              closeOverlayIfOpen();
            }
          },
          onClose: closeOverlayIfOpen,
          left: _leftMarginOffset,
          top: _topMarginOffset,
        );
      },
    );
  }

  Future<void> manegeSelectedText(T option) async {
    final selectedText = await onSelectInsertInCursor?.call(option);
    if (selectedText == null) return;
    final TextEditingValue tev = _textEditingController.value;
    final int cursorPos = tev.selection.base.offset;

    final String prefixText = tev.text.substring(0, cursorPos);
    final String suffixText = tev.text.substring(cursorPos);
    final String newTextWithInsertedOption =
        prefixText + selectedText + suffixText;

    final int selectedTextLenght = selectedText.length;

    final newSelection = TextSelection(
      baseOffset: cursorPos + selectedTextLenght,
      extentOffset: cursorPos + selectedTextLenght,
    );

    if (!_isSelectionWithinTextBounds(
        newSelection, newTextWithInsertedOption)) {
      throw FlutterError('invalid text selection: $newSelection');
    }

    final TextRange newComposing = newSelection.isCollapsed &&
            _isSelectionWithinComposingRange(
                newSelection, _textEditingController.value.composing)
        ? _textEditingController.value.composing
        : TextRange.empty;

    final newEditingValue = TextEditingValue(
      text: newTextWithInsertedOption,
      selection: newSelection,
      composing: newComposing,
    );

    _textEditingController.value = newEditingValue;
  }

  void _displayWidgetInCursorPosition(TextEditingValue currentEditingValue) {
    final screenSize = MediaQuery.sizeOf(_context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    TextSpan? span;
    int? maxLines;
    Size? textFieldValidTextSize;
    _recursiveSearchForRender(
      context: _context,
      onTextfieldFound: (textfield, size) {
        final TextEditingValue tev = _textEditingController.value;
        final int cursorPos = tev.selection.base.offset;
        final String preCursorText = tev.text.substring(0, cursorPos);
        span = TextSpan(text: preCursorText, style: textfield.style);
      },
      onEditableTextFound: (EditableText editableText, Size size) {
        maxLines = editableText.maxLines;
        textFieldValidTextSize = size;
      },
    );

    assert(span != null, 'The textfield was not found in the widget tree.');
    assert(span?.style != null, 'The textfield style can not be null.');
    assert(span?.style?.height == 1,
        'The height inside of the textstyle style needs to be 1. Currently we do not support other values');
    assert(span?.style?.fontSize != null,
        'The style of the textstyle needs to contain the fontSize parameter');
    assert(textFieldValidTextSize != null,
        'Could not determine a size for the widget');
    assert(maxLines != null,
        'Could not determine the maxLines for the textfield. Ensure the textfield has a max line field setted');

    final tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: textFieldValidTextSize!.width);

    final style = span!.style!;
    final lineMetrics = tp.computeLineMetrics();
    final computedLines = lineMetrics.length;
    final numLines = computedLines < maxLines! ? computedLines : maxLines!;
    final currentLine = lineMetrics.isNotEmpty ? lineMetrics.last : null;
    final styleHeight = style.height ?? 1;
    final styleFontsize = style.fontSize ?? 14;
    final textHeight = styleHeight * styleFontsize;
    final heightPadding = textHeight * numLines;
    final offset = textfieldFocusNode.offset;
    final topValue = offset.dy + heightPadding;
    final leftValue = offset.dx + (currentLine?.width ?? 0) * styleHeight;

    if (topValue + overlayCardHeight >= screenHeight) {
      _topMarginOffset = topValue - overlayCardHeight - textHeight;
    } else {
      _topMarginOffset = topValue;
    }

    if (leftValue + overlayCardWeight >= screenWidth) {
      _leftMarginOffset = leftValue - overlayCardWeight;
    } else {
      _leftMarginOffset = leftValue;
    }
  }

  /// Will close the current overlay if it is open.
  ///
  /// If it is not open, it will do nothing.
  void closeOverlayIfOpen() {
    _suggestionTagoverlayEntry?.remove();
    _suggestionTagoverlayEntry = null;
    textfieldFocusNode.requestFocus();
  }

  /// Check that the [selection] is inside of the composing range.
  bool _isSelectionWithinComposingRange(
      TextSelection selection, TextRange composing) {
    return selection.start >= composing.start && selection.end <= composing.end;
  }

  /// Check that the [selection] is inside of the bounds of [text].
  bool _isSelectionWithinTextBounds(TextSelection selection, String text) {
    return selection.start <= text.length && selection.end <= text.length;
  }
}

void _recursiveSearchForRender({
  required BuildContext context,
  required void Function(TextField textfield, Size size) onTextfieldFound,
  required void Function(EditableText editableText, Size size)
      onEditableTextFound,
}) {
  context.visitChildElements((Element element) {
    if (element.widget is TextField) {
      final render = element.widget as TextField;
      onTextfieldFound(render, element.size!);
    } else if (element.widget is EditableText) {
      final render = element.widget as EditableText;
      onEditableTextFound(render, element.size!);
      return; // Exit the recursive search
    }

    _recursiveSearchForRender(
      context: element,
      onTextfieldFound: onTextfieldFound,
      onEditableTextFound: onEditableTextFound,
    );
  });
}
