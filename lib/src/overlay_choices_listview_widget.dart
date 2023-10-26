import 'package:cursor_autocomplete_options/src/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OverlayChoicesListViewWidget<T> extends StatefulWidget {
  final FocusNode focusNode;
  final double top;
  final double left;
  final double height;
  final double width;
  final List<T> options;
  final String Function(T option) optionAsString;
  final void Function(T option) onSelect;
  final void Function() onClose;

  const OverlayChoicesListViewWidget({
    super.key,
    required this.focusNode,
    required this.top,
    required this.left,
    required this.height,
    required this.width,
    required this.options,
    required this.optionAsString,
    required this.onSelect,
    required this.onClose,
  });

  @override
  State<OverlayChoicesListViewWidget<T>> createState() =>
      _OverlayChoicesListViewWidgetState<T>();
}

class _OverlayChoicesListViewWidgetState<T>
    extends State<OverlayChoicesListViewWidget<T>> {
  int selectedItemIndex = 0;
  Map<int, FocusNode> listViewFocusNodes = {};
  final ScrollController scrollController = ScrollController();
  late final Duration scrollDownDuration;
  late final double height;

  @override
  void initState() {
    super.initState();
    widget.focusNode.requestFocus();
    widget.options.forEachMapper((value, isFirst, isLast, index) {
      listViewFocusNodes[index] = FocusNode();

      if (isFirst) {
        listViewFocusNodes[index]?.requestFocus();
      }
    });
    scrollDownDuration = const Duration(milliseconds: 40);

    final totalItensHeight = widget.options.length * 36;
    final isTotalItemHeightBiggerThanHeight = totalItensHeight > widget.height;

    if (isTotalItemHeightBiggerThanHeight) {
      height = widget.height;
    } else {
      height = totalItensHeight.toDouble();
    }
  }

  @override
  void dispose() {
    listViewFocusNodes.forEach((key, focusNode) {
      focusNode.dispose();
    });
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      left: widget.left,
      child: SizedBox(
        height: height,
        width: widget.width,
        child: FocusScope(
          autofocus: true,
          child: Shortcuts(
            shortcuts: _noIntent,
            child: TapRegion(
              onTapOutside: (event) {
                widget.focusNode.unfocus();
                widget.onClose();
              },
              child: RawKeyboardListener(
                focusNode: widget.focusNode,
                onKey: (event) {
                  _manegeKeyboardClicked(event);
                },
                child: Material(
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  elevation: 0,
                  color: Colors.grey[300],
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: widget.options.length,
                      controller: scrollController,
                      itemBuilder: (context, index) {
                        final T option = widget.options.elementAt(index);
                        final focusNode = listViewFocusNodes[index];
                        final isFirst = index == 0;
                        final isLast = index == widget.options.length - 1;
                        final BorderRadius borderRaius;
                        if (isFirst) {
                          borderRaius = const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          );
                        } else if (isLast) {
                          borderRaius = const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          );
                        } else {
                          borderRaius = const BorderRadius.only();
                        }

                        return ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(20),
                          ),
                          child: SizedBox(
                            height: 36,
                            child: ListTile(
                              onTap: () {
                                widget.onSelect(option);
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: borderRaius,
                              ),
                              autofocus: false,
                              dense: true,
                              focusNode: focusNode,
                              title: Text(widget.optionAsString(option)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool didEndedAnimation = true;
  void _manegeKeyboardClicked(RawKeyEvent event) {
    if (widget.focusNode.hasFocus == false) {
      return;
    }

    if (event is RawKeyDownEvent) {
      return;
    }

    final esc = LogicalKeyboardKey.escape.keyLabel;
    final up = LogicalKeyboardKey.arrowUp.keyLabel;
    final down = LogicalKeyboardKey.arrowDown.keyLabel;
    final enter = LogicalKeyboardKey.enter.keyLabel;

    if (event.logicalKey.keyLabel == esc) {
      widget.focusNode.unfocus();
      widget.onClose();
    } else if (event.logicalKey.keyLabel == up) {
      if (didEndedAnimation == false) return;
      _changeSelectedTileIfNotDisplayed(_ChangeTileDirection.up);
      if (selectedItemIndex == 0) return;
      _unfocusPrevAndFocusNew(_ChangeTileDirection.up);
      _animateScrollToNewFocussedTile(_ChangeTileDirection.up);
    } else if (event.logicalKey.keyLabel == down) {
      if (didEndedAnimation == false) return;
      _changeSelectedTileIfNotDisplayed(_ChangeTileDirection.down);
      if (selectedItemIndex == widget.options.length - 1) return;
      _unfocusPrevAndFocusNew(_ChangeTileDirection.down);
      _animateScrollToNewFocussedTile(_ChangeTileDirection.down);
    } else if (event.logicalKey.keyLabel == enter) {
      widget.onSelect(widget.options[selectedItemIndex]);
    }
  }

  /// This is usefull in a situation like the following action:
  ///
  /// The user is with the dialog opened.
  /// He scrolls down with the mouse wheel.
  /// And then he taps the arrow up/down keyboard, but the focused
  /// element is not even apearing in screen because he scrolled down.
  /// So we will focus in the neerest element in the screen.
  void _changeSelectedTileIfNotDisplayed(_ChangeTileDirection type) {
    final currentOffset = scrollController.offset;
    final currentTileSelectedStartPosition = selectedItemIndex * 36;

    final isCurrentTileDisplayedInScreen =
        currentTileSelectedStartPosition >= currentOffset &&
            currentTileSelectedStartPosition <= currentOffset + widget.height;

    if (isCurrentTileDisplayedInScreen == false) {
      listViewFocusNodes[selectedItemIndex]?.unfocus();
      final heightPadding =
          type == _ChangeTileDirection.down ? 0 : widget.height;
      final double clossetsValue = (currentOffset + heightPadding - 1) / 36;
      final int clossetsValueInt = clossetsValue.round();
      listViewFocusNodes[clossetsValueInt]?.requestFocus();
      selectedItemIndex = clossetsValueInt;
    }
  }

  void _unfocusPrevAndFocusNew(_ChangeTileDirection type) {
    listViewFocusNodes[selectedItemIndex]?.unfocus();
    if (type == _ChangeTileDirection.up) {
      selectedItemIndex--;
    } else {
      selectedItemIndex++;
    }
    listViewFocusNodes[selectedItemIndex]?.requestFocus();
  }

  void _animateScrollToNewFocussedTile(_ChangeTileDirection type) {
    switch (type) {
      case _ChangeTileDirection.up:
        final currentOffset = scrollController.offset;
        didEndedAnimation = false;
        final didGotToTheTopOfTheList = currentOffset <= 0;
        if (didGotToTheTopOfTheList) {
          didEndedAnimation = true;
          return;
        }

        scrollController
            .animateTo(
              currentOffset - 36,
              duration: scrollDownDuration,
              curve: Curves.linear,
            )
            .then((_) => didEndedAnimation = true);
        break;

      case _ChangeTileDirection.down:
        final currentOffset = scrollController.offset;
        didEndedAnimation = false;
        final didGotToTheEndOfTheList =
            currentOffset >= scrollController.position.maxScrollExtent;
        if (didGotToTheEndOfTheList) {
          didEndedAnimation = true;
          return;
        }

        scrollController
            .animateTo(
              currentOffset + 36,
              duration: scrollDownDuration,
              curve: Curves.linear,
            )
            .then((_) => didEndedAnimation = true);
        break;
    }
  }
}

enum _ChangeTileDirection {
  up,
  down;

  const _ChangeTileDirection();
}

final Map<ShortcutActivator, Intent> _noIntent = {
  LogicalKeySet(LogicalKeyboardKey.escape): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.arrowUp): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.arrowDown): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.enter): const DoNothingIntent(),
};
