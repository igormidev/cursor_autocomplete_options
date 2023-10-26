import 'dart:async';
import 'package:cursor_autocomplete_options/src/debouncer.dart';
import 'package:cursor_autocomplete_options/src/overlay_choices_listview_widget.dart';
import 'package:flutter/material.dart';

/// {@template textfieldTemplate}
/// The controller of the textfield that will be used to now
/// where the cursor is and where to insert the selected text
/// {@endtemplate}

/// {@template textfieldFocusNode}
/// The focus node of the textfield that will be used to
/// focus again to the textfield after the user select an option.
/// {@endtemplate}

/// {@template context}
/// The context need in order to display a dialog in the screen
/// with the options.
/// {@endtemplate}

/// {@template overlayCardHeight}
/// The height of the card that will be displayed with the options.
/// {@endtemplate}

/// {@template overlayCardWeight}
/// The weight of the card that will be displayed with the options.
/// {@endtemplate}

/// {@template willAutomaticallyCloseDialogAfterSelection}
/// This variable will controll if the [OptionsController] will
/// close or not the dialog after the user select an option.
/// {@endtemplate}

/// {@template optionAsString}
/// The function that will be used to convert the option to a string
/// if needed. If the String is the generic type <T>, this function
/// is *not needed*. But if not, the controller needs a way to discover
/// how to display the option as a String and it uses this function for that.
/// {@endtemplate}

/// {@template onSelectedOption}
/// Will give you complete controll of what to do with the selected
/// option. So if you want you can manipulate the textfield values yourself.
/// {@endtemplate}

/// {@template onSelectInsertInCursor}
/// This is a pre-built option builded above onSelectedOption
/// that manipulate the TextEditingController in order to
/// insert in the current cursor possition the return of this function.
/// {@endtemplate}

class OptionsController<T> {
  /// {@macro textfieldTemplate}
  final ValueNotifier<TextEditingValue> _textEditingController;

  /// {@macro textfieldFocusNode}
  final FocusNode textfieldFocusNode;

  /// This focus node will be used to listen to the keyboard events.
  final FocusNode keyboardListenerNode;

  // The overlay state that will be used to display the options.
  final OverlayState _overlayState;

  /// The overlay entry that will be used to display the options.
  OverlayEntry? _suggestionTagoverlayEntry;

  /// {@macro optionAsString}
  String Function(T option)? optionAsString;

  /// {@macro overlayCardHeight}
  double overlayCardHeight;

  /// {@macro overlayCardWeight}
  double overlayCardWeight;

  /// Debouncer time of the widget
  final Debouncer _debouncer;

  /// {@macro onSelectedOption}
  FutureOr<void> Function(T option)? onSelectedOption;

  /// {@macro onSelectInsertInCursor}
  FutureOr<String> Function(T option)? onSelectInsertInCursor;

  /// {@macro willAutomaticallyCloseDialogAfterSelection}
  bool willAutomaticallyCloseDialogAfterSelection;

  /// The bottom margin used to balance the position of the dialog if
  /// the dialog dosent have space bellow to be displayed. (In this
  /// case, it will be displayed above the cursor).
  double _bottomMarginOffset = 0;

  /// The left margin used to balance the position of the dialog if
  /// the dialog dosent have space in then right to be displayed. (In this
  /// case, it will be displayed more to the left to fit in the screen).
  double _leftMarginOffset = 0;

  /// {@macro context}
  BuildContext _context;

  /// # OptionsController
  /// Will controll when and where to display the overlay card with
  /// the options so the user can select one.
  ///
  /// ## Variables:
  /// - [textfieldFocusNode]<br>
  /// {@macro textfieldFocusNode}
  /// - [textfieldEditingController]<br>
  /// {@macro textfieldTemplate}
  /// - [context]<br>
  /// {@macro context}
  /// - [overlayCardHeight]<br>
  /// {@macro overlayCardHeight}
  /// - [overlayCardWeight]<br>
  /// {@macro overlayCardWeight}
  /// - [debounceDuration]<br>
  /// Debouncer time of the widget.
  /// - [willAutomaticallyCloseDialogAfterSelection]<br>
  /// {@macro willAutomaticallyCloseDialogAfterSelection}
  /// - [optionAsString]<br>
  /// {@macro optionAsString}
  /// - [onSelectedOption]<br>
  /// {@macro onSelectedOption}
  /// - [onSelectInsertInCursor]<br>
  /// {@macro onSelectInsertInCursor}
  OptionsController({
    required this.textfieldFocusNode,
    required ValueNotifier<TextEditingValue> textEditingController,
    required BuildContext context,
    this.overlayCardHeight = 200,
    this.overlayCardWeight = 200,
    Duration debounceDuration = const Duration(milliseconds: 300),
    this.willAutomaticallyCloseDialogAfterSelection = true,
    this.optionAsString,
    this.onSelectedOption,
    this.onSelectInsertInCursor,
  })  : _textEditingController = textEditingController,
        _overlayState = Overlay.of(context),
        _debouncer = Debouncer(timerDuration: debounceDuration),
        keyboardListenerNode = FocusNode(),
        _context = context,
        assert(
            (optionAsString == null && T == String) || optionAsString != null,
            'The parameter `optionAsString` can only be null if the generic type <T> is not String.');

  /// The context that you had passed in the constructor can
  /// be deprecated in some point. So you can update the context
  /// that the controller is using by calling this function in a
  /// `didChangeDependencies` method or right bellow your build function.
  void updateContext(BuildContext context) {
    _context = context;
  }

  /// # The dialog trigger function
  ///
  /// Will show a dialog with the following [options] in a listview
  /// so the user can pick one of them.
  ///
  /// Defore executing anything, this function will debounce the
  /// call to avoid multiple calls in a short period of time.
  /// The debounce timmer can be setted in the constructor.
  void showOptionsMenu(List<T> options) {
    _debouncer.resetDebounce(() {
      _setOverlayEntry(options);
      if (_suggestionTagoverlayEntry != null) {
        _overlayState.insert(_suggestionTagoverlayEntry!);
      }
    });
  }

  /// Will dispose the controller resources and remove the overlay if it is open.
  void dispose() {
    _debouncer.dispose();
    _suggestionTagoverlayEntry?.remove();
    _suggestionTagoverlayEntry = null;
    textfieldFocusNode.dispose();
    keyboardListenerNode.dispose();
  }

  /// Will close the current overlay if it is open.
  ///
  /// If it is not open, it will do nothing.
  void closeOverlayIfOpen() {
    _suggestionTagoverlayEntry?.remove();
    _suggestionTagoverlayEntry = null;
    textfieldFocusNode.requestFocus();
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
              await _manegeSelectedText(option);
            }

            if (willAutomaticallyCloseDialogAfterSelection) {
              closeOverlayIfOpen();
            }
          },
          onClose: closeOverlayIfOpen,
          left: _leftMarginOffset,
          top: _bottomMarginOffset,
        );
      },
    );
  }

  Future<void> _manegeSelectedText(T option) async {
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
      _bottomMarginOffset = topValue - overlayCardHeight - textHeight;
    } else {
      _bottomMarginOffset = topValue;
    }

    if (leftValue + overlayCardWeight >= screenWidth) {
      _leftMarginOffset = leftValue - overlayCardWeight;
    } else {
      _leftMarginOffset = leftValue;
    }
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
