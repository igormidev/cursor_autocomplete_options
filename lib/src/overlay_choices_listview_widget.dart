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
          child: TapRegion(
            onTapOutside: (event) {
              widget.focusNode.unfocus();
              widget.onClose();
            },
            child: RawKeyboardListener(
              focusNode: widget.focusNode,
              onKey: _manegeKeyboardClicked,
              child: Material(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                elevation: 0,
                color: Colors.grey[300],
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: widget.options.length,
                    physics: const NeverScrollableScrollPhysics(),
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
      if (selectedItemIndex == 0) return;
      listViewFocusNodes[selectedItemIndex]?.unfocus();
      selectedItemIndex--;
      listViewFocusNodes[selectedItemIndex]?.requestFocus();

      // Animation
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
    } else if (event.logicalKey.keyLabel == down) {
      if (didEndedAnimation == false) return;
      if (selectedItemIndex == widget.options.length - 1) return;
      listViewFocusNodes[selectedItemIndex]?.unfocus();
      selectedItemIndex++;
      listViewFocusNodes[selectedItemIndex]?.requestFocus();

      // Animation
      didEndedAnimation = false;
      final currentOffset = scrollController.offset;
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
    } else if (event.logicalKey.keyLabel == enter) {
      widget.onSelect(widget.options[selectedItemIndex]);
    }
  }
}
