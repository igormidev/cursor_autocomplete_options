// ignore_for_file: unnecessary_cast
import 'package:cursor_autocomplete_options/src/debouncer.dart';
import 'package:cursor_autocomplete_options/src/model/folder_structure.dart';
import 'package:cursor_autocomplete_options/src/widgets/search_widget.dart';
import 'package:enchanted_collection/enchanted_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class FolderDialogPage<T> extends StatefulWidget {
  /// The height of the overlay card that the options will be displayed.
  final double height;

  /// The width of the overlay card that the options will be displayed.
  final double width;

  final List<StructuredDataType<T>> children;

  /// The callback that will be called when the user close the overlay.
  final void Function() onClose;

  /// {@macro optionAsString}
  final String Function(T option) optionAsString;

  /// The callback that will be called when the user select an option.
  final void Function(T option) onSelect;

  final Widget Function(
    T option,
    bool isSelected,
    void Function() onSelectCallback,
  )? tileBuilder;

  const FolderDialogPage({
    super.key,
    required this.children,
    required this.height,
    required this.width,
    required this.onClose,
    required this.optionAsString,
    required this.onSelect,
    this.tileBuilder,
  });

  @override
  State<FolderDialogPage<T>> createState() => _FolderDialogPageState<T>();
}

class _FolderDialogPageState<T> extends State<FolderDialogPage<T>> {
  late List<PagePayload<T>> currentPage;
  late final Debouncer debouncer;

  @override
  void initState() {
    super.initState();
    // widget.focusNode.unfocus();
    debouncer = Debouncer(timerDuration: Durations.extralong1);
    final focusNode = FocusNode();
    currentPage = [
      PagePayload(
        pageTitle: null,
        itemPositionsListener: ItemPositionsListener.create(),
        focusNode: focusNode..requestFocus(),
        itemScrollController: ItemScrollController(),
        currentPage: widget.children,
        selectedIndex: ValueNotifier(0),
        search: ValueNotifier(''),
      ),
    ];
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      FocusScope.of(context).requestFocus(currentPage.last.focusNode);
      currentPage.last.focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    debouncer.dispose();
    for (final page in currentPage) {
      page.selectedIndex.dispose();
      page.search.dispose();
      page.focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: (event) {
        widget.onClose();
      },
      child: Navigator(
        onDidRemovePage: (route) {},
        pages: currentPage.mapper((
          PagePayload<T> options,
          bool isFirst,
          bool isLast,
          int index,
        ) {
          String? lastdown = '';

          // .mapper((PagePayload<T> options, bool isFirst, bool isLast, int index) {
          final title = options.pageTitle;
          final selectedIndexVN = options.selectedIndex;
          final searchQueryVN = options.search;
          final itemScrollController = options.itemScrollController;
          final itemPositionsListener = options.itemPositionsListener;
          final currentPage = options.currentPage;
          final focusNode = options.focusNode;

          return MaterialPage(
            child: Material(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Shortcuts(
                shortcuts: _noIntent,
                child: ValueListenableBuilder(
                  valueListenable: searchQueryVN,
                  builder: (context, queryText, child) {
                    final queryFilterText =
                        queryText.replaceAll(' ', '').toLowerCase();
                    final items = currentPage.where((element) {
                      final optionAsString =
                          widget.optionAsString(element.item);
                      return optionAsString
                          .replaceAll(' ', '')
                          .toLowerCase()
                          .contains(queryFilterText);
                    }).toList();

                    return KeyboardListener(
                      focusNode: focusNode..requestFocus(),
                      onKeyEvent: (KeyEvent value) {
                        if (value.character != null) {
                          lastdown = value.character;
                        }

                        final isEmpty = items.isEmpty;

                        _manegeKeyboardClicked(value, lastdown, isEmpty);
                      },
                      child: ValueListenableBuilder(
                        valueListenable: selectedIndexVN,
                        builder: (context, value, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (!isFirst) ...[
                                    const SizedBox(width: 6),
                                    InkWell(
                                      radius: 30,
                                      onTap: onGoBack,
                                      child: const CircleAvatar(
                                        radius: 14.5,
                                        child: Icon(
                                          Icons.arrow_back,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                  Expanded(
                                    child: Container(
                                      height: 30,
                                      margin: const EdgeInsets.only(
                                          left: 8, right: 8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 8),
                                          const Icon(Icons.search),
                                          Expanded(
                                            child: RichText(
                                              maxLines: 1,
                                              text: TextSpan(
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface,
                                                    ),
                                                children: [
                                                  TextSpan(text: queryText),
                                                  WidgetSpan(
                                                    child: Container(
                                                      width: 2,
                                                      height: 18,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .secondary,
                                                    )
                                                        .animate(
                                                          delay: 1000.ms,
                                                          onPlay: (c) =>
                                                              c.repeat(),
                                                        )
                                                        .fadeIn(delay: 500.ms),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Transform.scale(
                                            scale: 0.9,
                                            child: DebounceWidget(debouncer),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (title != null) ...[
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontStyle: FontStyle.italic,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              if (items.isNotEmpty)
                                Expanded(
                                  child: ScrollablePositionedList.builder(
                                    itemPositionsListener:
                                        itemPositionsListener,
                                    itemScrollController: itemScrollController,
                                    itemCount: items.length,
                                    itemBuilder: (context, index) {
                                      final StructuredDataType<T> option =
                                          items[index];

                                      void tapFunction() {
                                        _optionChoose(option);
                                      }

                                      final isSelected = index == value;

                                      if (widget.tileBuilder != null) {
                                        return widget.tileBuilder!(
                                          option.item,
                                          isSelected,
                                          tapFunction,
                                        );
                                      }

                                      final text = option.item;
                                      final optionAsString =
                                          widget.optionAsString(text);

                                      return InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: tapFunction,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                            horizontal: 8,
                                          ),
                                          margin: const EdgeInsets.only(
                                            left: 8,
                                            right: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest
                                                : null,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            children: [
                                              switch (option) {
                                                FolderStructure<T>() =>
                                                  const Icon(Icons.folder),
                                                FileStructureOptions<T>() =>
                                                  const Icon(Icons.file_copy),
                                              },
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(optionAsString),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool get isCurrentEmtpy {
    return currentPage.last.itemPositionsListener.itemPositions.value.isEmpty;
  }

  void _optionChoose(StructuredDataType<T> option) {
    switch (option) {
      case FileStructureOptions<T>(item: T item):
        widget.onSelect(item);
      case FolderStructure<T>():
        // final last = currentPage.last.pageTitle;
        setState(() {
          currentPage = [
            ...currentPage,
            PagePayload(
              focusNode: FocusNode(),
              itemPositionsListener: ItemPositionsListener.create(),
              pageTitle: '../${widget.optionAsString(option.item)}',
              // pageTitle: last == null
              //     ? widget.optionAsString(option.item)
              //     : '$last > ${widget.optionAsString(option.item)}',
              itemScrollController: ItemScrollController(),
              currentPage: option.children,
              selectedIndex: ValueNotifier(0),
              search: ValueNotifier(''),
            ),
          ];
        });
        break;
    }
  }

  void _manegeKeyboardClicked(
    KeyEvent event,
    String? lastdown,
    bool isEmpty,
  ) {
    final keyLabel = event.logicalKey.keyLabel;

    // if (widget.focusNode.hasFocus == false) {
    //   return;
    // }

    if (event is KeyDownEvent) {
      return;
    }

    final esc = LogicalKeyboardKey.escape.keyLabel;
    final up = LogicalKeyboardKey.arrowUp.keyLabel;
    final down = LogicalKeyboardKey.arrowDown.keyLabel;
    final backspace = LogicalKeyboardKey.backspace.keyLabel;
    final enter = LogicalKeyboardKey.enter.keyLabel;
    final capslock = LogicalKeyboardKey.capsLock.keyLabel;
    if (capslock == keyLabel) {
      return;
    }

    final isEsc = keyLabel == esc;
    final isUp = keyLabel == up;
    final isDown = keyLabel == down;
    final isBackspace = keyLabel == backspace;
    final isEnter = keyLabel == enter;

    if (isEsc) {
      onGoBack();
    }

    if (isBackspace) {
      if (currentPage.last.search.value.isNotEmpty) {
        currentPage.last.search.value = currentPage.last.search.value
            .substring(0, currentPage.last.search.value.length - 1);

        if (isEmpty) return;

        currentPage.last.itemScrollController.scrollTo(
          index: 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        currentPage.last.selectedIndex.value = 0;
      }
      return;
    }

    if (isEnter) {
      if (isEmpty) return;

      final selectedOption =
          currentPage.last.currentPage[currentPage.last.selectedIndex.value];
      _optionChoose(selectedOption);

      return;
    }

    if (isUp) {
      if (isEmpty) return;
      changeTile(_ChangeTileDirection.up);
      return;
    }

    if (isDown) {
      if (isEmpty) return;
      changeTile(_ChangeTileDirection.down);
      return;
    }

    final caracter = lastdown;
    if (caracter != null) {
      final isLetterOrNumberOrSpace =
          keyLabel.length == 1 && RegExp(r'[a-zA-Z0-9 .,]').hasMatch(caracter);
      if (isLetterOrNumberOrSpace) {
        currentPage.last.search.value += caracter;

        if (isEmpty) return;

        currentPage.last.itemScrollController.scrollTo(
          index: 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        currentPage.last.selectedIndex.value = 0;
        return;
      }
    }
  }

  void onGoBack() {
    if (currentPage.length > 1) {
      currentPage.last.selectedIndex.dispose();
      currentPage.last.search.dispose();
      currentPage.last.focusNode.dispose();
      currentPage.removeLast();
      currentPage.last.focusNode.requestFocus();
      setState(() {});
      return;
    } else {
      widget.onClose();
    }
  }

  void changeTile(_ChangeTileDirection direction) {
    switch (direction) {
      case _ChangeTileDirection.up:
        if (currentPage.last.selectedIndex.value > 0) {
          // final isLast = currentPage.last.selectedIndex.value ==
          //     currentPage.last.currentPage.length - 1;

          currentPage.last.selectedIndex.value =
              currentPage.last.selectedIndex.value - 1;

          // if (isLast) {
          //   return;
          // }
          final index = currentPage.last.selectedIndex.value - 1;
          final items = currentPage
              .last.itemPositionsListener.itemPositions.value
              .map((e) => e.index)
              .toList();

          final isApearing = items.contains(index);
          if (!isApearing) {
            currentPage.last.itemScrollController.scrollTo(
              index: index < 0 ? 0 : index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
        break;
      case _ChangeTileDirection.down:
        if (currentPage.last.selectedIndex.value <
            currentPage.last.currentPage.length - 1) {
          currentPage.last.selectedIndex.value =
              currentPage.last.selectedIndex.value + 1;

          // If item is not visible, scroll to it
          final lastIndex = currentPage
              .last.itemPositionsListener.itemPositions.value.last.index;

          if (currentPage.last.selectedIndex.value >= lastIndex &&
              lastIndex != -1) {
            final isLastIndex =
                currentPage.last.selectedIndex.value == lastIndex;
            if (isLastIndex) {
              currentPage.last.itemScrollController.jumpTo(
                index: currentPage.last.selectedIndex.value,
              );
            } else {
              currentPage.last.itemScrollController.scrollTo(
                index: currentPage.last.selectedIndex.value,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
              );
            }
          }
        }
        break;
    }
  }
}

enum _ChangeTileDirection {
  up,
  down;
}

final Map<ShortcutActivator, Intent> _noIntent = {
  LogicalKeySet(LogicalKeyboardKey.escape): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.arrowUp): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.arrowDown): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.enter): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.backspace): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.space): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.capsLock): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.shiftLeft): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.shiftRight): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.controlLeft): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.controlRight): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.altLeft): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.altRight): const DoNothingIntent(),
  // All keys with shitf
  ..._getLogicalKey(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  //  LogicalKeySet(): const DoNothingIntent(),
  // LogicalKeySet(): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.keyZ): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.digit0): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.digit1): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.digit2): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.digit3): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.digit4): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.digit5): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.digit6): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.digit7): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.digit8): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.digit9): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.comma): const DoNothingIntent(),
  LogicalKeySet(LogicalKeyboardKey.period): const DoNothingIntent(),
};

Map<ShortcutActivator, Intent> _getLogicalKey() {
  final allLogicKeys = <ShortcutActivator, Intent>{};
  for (final element in <LogicalKeyboardKey>[
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.keyB,
    LogicalKeyboardKey.keyC,
    LogicalKeyboardKey.keyD,
    LogicalKeyboardKey.keyE,
    LogicalKeyboardKey.keyF,
    LogicalKeyboardKey.keyG,
    LogicalKeyboardKey.keyH,
    LogicalKeyboardKey.keyI,
    LogicalKeyboardKey.keyJ,
    LogicalKeyboardKey.keyK,
    LogicalKeyboardKey.keyL,
    LogicalKeyboardKey.keyM,
    LogicalKeyboardKey.keyN,
    LogicalKeyboardKey.keyO,
    LogicalKeyboardKey.keyP,
    LogicalKeyboardKey.keyQ,
    LogicalKeyboardKey.keyR,
    LogicalKeyboardKey.keyS,
    LogicalKeyboardKey.keyT,
    LogicalKeyboardKey.keyU,
    LogicalKeyboardKey.keyV,
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.keyX,
    LogicalKeyboardKey.keyY,
  ]) {
    allLogicKeys[LogicalKeySet(element)] = const DoNothingIntent();
    allLogicKeys[LogicalKeySet(LogicalKeyboardKey.shiftLeft, element)] =
        const DoNothingIntent();
    allLogicKeys[LogicalKeySet(LogicalKeyboardKey.shiftRight, element)] =
        const DoNothingIntent();
    allLogicKeys[LogicalKeySet(LogicalKeyboardKey.controlLeft, element)] =
        const DoNothingIntent();
    allLogicKeys[LogicalKeySet(LogicalKeyboardKey.controlRight, element)] =
        const DoNothingIntent();
    allLogicKeys[LogicalKeySet(LogicalKeyboardKey.altLeft, element)] =
        const DoNothingIntent();
    allLogicKeys[LogicalKeySet(LogicalKeyboardKey.altRight, element)] =
        const DoNothingIntent();
  }
  return allLogicKeys;
}

class PagePayload<T> {
  final String? pageTitle;
  final FocusNode focusNode;
  final ItemPositionsListener itemPositionsListener;
  final ItemScrollController itemScrollController;
  final List<StructuredDataType<T>> currentPage;
  final ValueNotifier<int> selectedIndex;
  final ValueNotifier<String> search;

  const PagePayload({
    required this.pageTitle,
    required this.focusNode,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.currentPage,
    required this.selectedIndex,
    required this.search,
  });
}
