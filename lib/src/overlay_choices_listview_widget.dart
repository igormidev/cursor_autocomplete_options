import 'package:cursor_autocomplete_options/src/extensions.dart';
import 'package:cursor_autocomplete_options/src/helpers/text_normalizer.dart';
import 'package:cursor_autocomplete_options/src/widgets/search_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OverlayChoicesListViewWidget<T> extends StatefulWidget {
  /// The focus node of the overlay to focus in it
  final FocusNode focusNode;

  /// The height of the overlay card  that the options will be displayed.
  final double height;

  /// The width of the overlay card that the options will be displayed.
  final double width;

  /// The options that will be displayed in the overlay.
  final List<T> options;

  /// {@macro optionAsString}
  final String Function(T option) optionAsString;

  /// The callback that will be called when the user select an option.
  final void Function(T option) onSelect;

  /// The callback that will be called when the user close the overlay.
  final void Function() onClose;

  /// The height of each tile in the overlay.
  final double tileHeight;

  final Widget Function(
    T option,
    int index,
    FocusNode tileFocusNode,
    void Function() onSelectCallback,
  )? tileBuilder;

  const OverlayChoicesListViewWidget({
    super.key,
    required this.focusNode,
    required this.height,
    required this.width,
    required this.options,
    required this.optionAsString,
    required this.onSelect,
    required this.onClose,
    required this.tileBuilder,
    this.tileHeight = 36,
  });

  @override
  State<OverlayChoicesListViewWidget<T>> createState() =>
      _OverlayChoicesListViewWidgetState<T>();
}

class _OverlayChoicesListViewWidgetState<T>
    extends State<OverlayChoicesListViewWidget<T>> {
  late final TextEditingController searchController;
  int selectedItemIndex = 0;
  final FocusNode searchFocusNode = FocusNode();
  Map<int, FocusNode> listViewFocusNodes = {};
  final ScrollController scrollController = ScrollController();
  late final Duration scrollDownDuration;
  late final double height;

  late final ValueNotifier<List<T>> optionsVN;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    optionsVN = ValueNotifier(widget.options);

    widget.focusNode.requestFocus();
    widget.options.forEachMapper((value, isFirst, isLast, index) {
      listViewFocusNodes[index] = FocusNode();

      if (isFirst) {
        listViewFocusNodes[index]?.requestFocus();
      }
    });
    scrollDownDuration = const Duration(milliseconds: 40);

    final totalItensHeight = widget.options.length * widget.tileHeight;
    final isTotalItemHeightBiggerThanHeight = totalItensHeight > widget.height;

    if (isTotalItemHeightBiggerThanHeight) {
      height = widget.height;
    } else {
      height = totalItensHeight.toDouble();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    listViewFocusNodes.forEach((key, focusNode) {
      focusNode.dispose();
    });
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      autofocus: true,
      child: Shortcuts(
        shortcuts: _noIntent,
        child: TapRegion(
          onTapOutside: (event) {
            widget.focusNode.unfocus();
            widget.onClose();
          },
          child: KeyboardListener(
            focusNode: widget.focusNode,
            onKeyEvent: (KeyEvent value) {
              _manegeKeyboardClicked(value);
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  SearchWidget(
                    title: 'Search',
                    controller: searchController,
                    searchFocusNode: searchFocusNode,
                    onChanged: (normalizedText) {
                      if (normalizedText.isEmpty) {
                        optionsVN.value = widget.options;
                        return;
                      }

                      setState(() {
                        optionsVN.value = widget.options.where((element) {
                          final optionAsString = widget.optionAsString(element);
                          return optionAsString.normalizeText
                              .contains(normalizedText);
                        }).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ValueListenableBuilder(
                        valueListenable: optionsVN,
                        builder: (context, options, child) {
                          return ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            controller: scrollController,
                            itemBuilder: (context, index) {
                              final T option = options.elementAt(index);
                              final FocusNode? focusNode =
                                  listViewFocusNodes[index];

                              final bool isLast = index == options.length - 1;
                              final bool isUnique = options.length == 1;

                              final BorderRadius borderRaius;
                              if (isLast && !isUnique) {
                                borderRaius = const BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                );
                              } else {
                                borderRaius = const BorderRadius.only();
                              }

                              void tapFunction() {
                                widget.onSelect(option);
                              }

                              return ClipRRect(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(20),
                                ),
                                child: SizedBox(
                                  height: widget.tileHeight,
                                  child: widget.tileBuilder?.call(
                                        option,
                                        index,
                                        focusNode!,
                                        tapFunction,
                                      ) ??
                                      ListTile(
                                        onTap: tapFunction,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: borderRaius,
                                        ),
                                        autofocus: false,
                                        dense: true,
                                        focusNode: focusNode!,
                                        title:
                                            Text(widget.optionAsString(option)),
                                      ),
                                ),
                              );
                            },
                          );
                        }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool didEndedAnimation = true;
  void _manegeKeyboardClicked(KeyEvent event) {
    if (widget.focusNode.hasFocus == false) {
      return;
    }

    if (event is KeyDownEvent) {
      return;
    }

    final esc = LogicalKeyboardKey.escape.keyLabel;
    final up = LogicalKeyboardKey.arrowUp.keyLabel;
    final down = LogicalKeyboardKey.arrowDown.keyLabel;
    final enter = LogicalKeyboardKey.enter.keyLabel;

    // print(event.logicalKey.keyLabel);

    // IF its an letter or number, lets focus the [searchFocusNode] node
    // We also need to add the typed caracter.
    if (event.logicalKey.keyLabel.length == 1) {
      if (searchFocusNode.hasFocus == false) {
        searchController.text =
            searchController.text + event.logicalKey.keyLabel;
        searchFocusNode.requestFocus();
      }

      return;
    }

    if (event.logicalKey.keyLabel == esc) {
      _manegeOutIntent();
    }

    if (optionsVN.value.isEmpty) return;

    if (event.logicalKey.keyLabel == up) {
      if (didEndedAnimation == false) return;
      _changeSelectedTileIfNotDisplayed(_ChangeTileDirection.up);
      if (selectedItemIndex == 0) return;
      _unfocusPrevAndFocusNew(_ChangeTileDirection.up);
      _animateScrollToNewFocussedTile(_ChangeTileDirection.up);
    } else if (event.logicalKey.keyLabel == down) {
      if (didEndedAnimation == false) return;
      _changeSelectedTileIfNotDisplayed(_ChangeTileDirection.down);
      if (selectedItemIndex == optionsVN.value.length - 1) return;
      _unfocusPrevAndFocusNew(_ChangeTileDirection.down);
      _animateScrollToNewFocussedTile(_ChangeTileDirection.down);
    } else if (event.logicalKey.keyLabel == enter) {
      widget.onSelect(optionsVN.value[selectedItemIndex]);
    }
  }

  void _manegeOutIntent() {
    if (searchFocusNode.hasFocus) {
      searchFocusNode.unfocus();
      widget.focusNode.requestFocus();
    } else {
      widget.focusNode.unfocus();
      widget.onClose();
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
    final currentTileSelectedStartPosition =
        selectedItemIndex * widget.tileHeight;

    final isCurrentTileDisplayedInScreen =
        currentTileSelectedStartPosition >= currentOffset &&
            currentTileSelectedStartPosition <= currentOffset + widget.height;

    if (isCurrentTileDisplayedInScreen == false) {
      listViewFocusNodes[selectedItemIndex]?.unfocus();
      final heightPadding =
          type == _ChangeTileDirection.down ? 0 : widget.height;
      final double clossetsValue =
          (currentOffset + heightPadding - 1) / widget.tileHeight;
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
              currentOffset - widget.tileHeight,
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
              currentOffset + widget.tileHeight,
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
