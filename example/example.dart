import 'package:cursor_autocomplete_options/cursor_autocomplete_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Example(),
    );
  }
}

class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  late final OptionsController<String> optionsController;
  final FocusNode textfieldFocusNode = FocusNode();
  final TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();

    optionsController = OptionsController<String>(
      textfieldFocusNode: textfieldFocusNode,
      textEditingController: textEditingController,
      context: context,
      onSelectInsertInCursor: (option) {
        return option;
      },
    );
  }

  @override
  void dispose() {
    super.dispose();

    // Don't forget to dispose!
    optionsController.dispose();
    textEditingController.dispose();
  }

  AlignmentOptions alignmentOption = AlignmentOptions.center;
  double width = 300;
  int maxLines = 5;

  @override
  Widget build(BuildContext context) {
    optionsController.updateContext(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter textfield sugestions demo'),
        leading: IconButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                  child: ChangeFields(
                    value: width.round(),
                    textfieldLines: maxLines,
                    onSave: (newWidth, maxLines) {
                      setState(() {
                        width = newWidth;
                        this.maxLines = maxLines;
                      });
                    },
                  ),
                );
              },
            );
          },
          icon: const Icon(
            Icons.settings,
          ),
        ),
        actions: [
          DropdownButton<AlignmentOptions>(
            value: alignmentOption,
            items: AlignmentOptions.values.map((option) {
              return DropdownMenuItem<AlignmentOptions>(
                value: option,
                child: Text(option.text),
              );
            }).toList(),
            onChanged: (selectedValue) {
              if (selectedValue == null) return;
              setState(() {
                alignmentOption = selectedValue;
              });
            },
          ),
        ],
      ),
      body: Align(
        alignment: alignmentOption.alignment,
        child: Container(
          color: Colors.grey[200],
          width: width,
          child: TextFormField(
            focusNode: textfieldFocusNode,
            controller: textEditingController,
            decoration: const InputDecoration(
              hintText: 'Type something and use "#" anytime to show options',
            ),
            style: const TextStyle(height: 1, fontSize: 18),
            maxLines: maxLines,
            onChanged: (value) {
              if (value.isEmpty) return;

              final cursorPositionIndex =
                  textEditingController.selection.base.offset;

              final typedValue = value[cursorPositionIndex - 1];

              final isTypedCaracterHashtag = typedValue == '#';

              if (isTypedCaracterHashtag) {
                optionsController.showOptionsMenu(suggestion);
              }
            },
          ),
        ),
      ),
    );
  }
}

final List<String> suggestion = [
  'Floor',
  'Bar',
  'Manana',
  'Lerolero',
  'Idensa',
  'Yaha',
  'Tysaki',
  'Ruyma',
  'Rolmuro',
  'Ehuka',
  'Yah',
];

enum AlignmentOptions {
  center(Alignment.center, '- Center'),
  topLeft(Alignment.topLeft, '↖ Top left'),
  topCenter(Alignment.topCenter, '↑ Top center'),
  topRight(Alignment.topRight, '↗ Top right'),
  centerLeft(Alignment.centerLeft, '← Center left'),
  centerRight(Alignment.centerRight, '→ Center right'),
  bottomLeft(Alignment.bottomLeft, '↙ Bottom left'),
  bottomCenter(Alignment.bottomCenter, '↓ Bottom center'),
  bottomRight(Alignment.bottomRight, '↘ Bottom right');

  final Alignment alignment;
  final String text;
  const AlignmentOptions(this.alignment, this.text);
}

class ChangeFields extends StatefulWidget {
  final int value;
  final int textfieldLines;
  final void Function(double newWidth, int maxLines) onSave;

  const ChangeFields({
    super.key,
    required this.value,
    required this.textfieldLines,
    required this.onSave,
  });

  @override
  State<ChangeFields> createState() => _ChangeFieldsState();
}

class _ChangeFieldsState extends State<ChangeFields> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController widthEC;

  @override
  void initState() {
    super.initState();
    widthEC = TextEditingController(text: '${widget.value}');
    maxLines = widget.textfieldLines;
  }

  @override
  void dispose() {
    widthEC.dispose();
    super.dispose();
  }

  late int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 210,
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Width of textfield',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: widthEC,
              validator: (value) {
                final valueParsed = int.tryParse(value ?? 'a');
                return valueParsed == null || valueParsed < 150
                    ? 'Need to be a number bigger then 150'
                    : null;
              },
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Max lines',
                style: TextStyle(fontSize: 20),
              ),
              const Spacer(),
              SizedBox(
                width: 50,
                child: DropdownButton<int>(
                  value: maxLines,
                  items: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map((option) {
                    return DropdownMenuItem<int>(
                      value: option,
                      child: Text('$option'),
                    );
                  }).toList(),
                  onChanged: (selectedValue) {
                    if (selectedValue == null) return;
                    setState(() {
                      maxLines = selectedValue;
                    });
                  },
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              final parsedWidth = double.tryParse(widthEC.text);
              if (parsedWidth == null) return;
              widget.onSave(parsedWidth, maxLines);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
