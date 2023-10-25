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

  @override
  void initState() {
    widget.focusNode.requestFocus();
    widget.options.forEachMapper((value, isFirst, isLast, index) {
      listViewFocusNodes[index] = FocusNode();

      if (isFirst) {
        listViewFocusNodes[index]?.requestFocus();
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    listViewFocusNodes.forEach((key, focusNode) {
      focusNode.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      left: widget.left,
      child: SizedBox(
        height: widget.height,
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
              onKey: (event) {
                if (widget.focusNode.hasFocus == false) {
                  return;
                }

                if (event is RawKeyDownEvent) {
                  return;
                }

                final esc = LogicalKeyboardKey.escape.keyLabel;

                if (event.logicalKey.keyLabel == esc) {
                  widget.focusNode.unfocus();
                  widget.onClose();
                }
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
                    controller: ScrollController(),
                    itemBuilder: (context, index) {
                      final T option = widget.options.elementAt(index);
                      final focusNode = listViewFocusNodes[index];
                      return ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20)),
                        child: ListTile(
                          onTap: () {
                            widget.onSelect(option);
                          },
                          autofocus: false,
                          dense: true,
                          focusNode: focusNode,
                          title: Text(widget.optionAsString(option)),
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
}


/*

RawKeyboardListener(
          focusNode: widget.focusNode,
          autofocus: false,
          includeSemantics: false,
          onKey: (value) {
            return;
            if (widget.focusNode.hasFocus == false) {
              return;
            }

            if (value.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
              setState(() {
                selectedItemIndex++;
              });
            } else if (value.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
              setState(() {
                selectedItemIndex--;
              });
            } else if (value.isKeyPressed(LogicalKeyboardKey.enter)) {
              widget.onSelect(widget.options.elementAt(selectedItemIndex));
            } else if (value.isKeyPressed(LogicalKeyboardKey.escape)) {
              widget.onClose();
            }
          },


focusNode: FocusNode(
                        onKey: (node, event) {
                          if (event
                              .isKeyPressed(LogicalKeyboardKey.arrowDown)) {
                            setState(() {
                              selectedItemIndex++;
                            });
                          } else if (event
                              .isKeyPressed(LogicalKeyboardKey.arrowUp)) {
                            setState(() {
                              selectedItemIndex--;
                            });
                          } else if (event
                              .isKeyPressed(LogicalKeyboardKey.enter)) {
                            widget.onSelect(option);
                          } else if (event
                              .isKeyPressed(LogicalKeyboardKey.escape)) {
                            widget.onClose();
                          }
                          return true;
                        },
                      ),
*/