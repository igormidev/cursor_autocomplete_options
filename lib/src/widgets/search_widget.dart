import 'package:cursor_autocomplete_options/src/debouncer.dart';
import 'package:flutter/material.dart';

class SearchWidget extends StatefulWidget {
  const SearchWidget({
    super.key,
    required this.title,
    required this.onChanged,
    required this.searchFocusNode,
    required this.controller,
    required this.debouncer,
  });
  final Debouncer debouncer;
  final TextEditingController? controller;
  final FocusNode searchFocusNode;
  final String title;
  final void Function(String text) onChanged;

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      margin: const EdgeInsets.only(left: 8, right: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search),
          Expanded(
            child: Transform.translate(
              offset: const Offset(5, -7),
              child: TextFormField(
                textCapitalization: TextCapitalization.none,
                keyboardType: TextInputType.emailAddress,
                controller: widget.controller,
                focusNode: widget.searchFocusNode,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.title,
                  counterText: "",
                ),
                onChanged: (text) {
                  widget.debouncer.resetDebounce(
                    () {
                      widget.onChanged(text);
                    },
                  );
                },
                maxLength: 50,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: DebounceWidget(
              widget.debouncer,
            ),
          ),
        ],
      ),
    );
  }
}

class DebounceWidget extends StatefulWidget {
  final Debouncer debouncer;
  final Widget? child;
  const DebounceWidget(
    this.debouncer, {
    super.key,
    this.child,
  });

  @override
  State<DebounceWidget> createState() => _DebounceWidgetState();
}

class _DebounceWidgetState extends State<DebounceWidget> {
  final ValueNotifier<bool> isDebouncing = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    widget.debouncer.addOnInitFunction(() {
      isDebouncing.value = true;
    });
    widget.debouncer.addOnEndFunction(() {
      isDebouncing.value = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
    isDebouncing.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: ValueListenableBuilder(
        valueListenable: isDebouncing,
        child: const SizedBox(
          height: 30,
          width: 30,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(4.0),
              child: AspectRatio(
                aspectRatio: 1,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
        ),
        builder: (context, value, child) {
          if (value == true) return child!;

          return widget.child ?? SizedBox.fromSize();
        },
      ),
    );
  }
}
