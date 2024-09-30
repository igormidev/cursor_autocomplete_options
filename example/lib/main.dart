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
        textSelectionTheme: const TextSelectionThemeData(
          selectionHandleColor: Colors.transparent,
        ),
      ),
      home: const Example(),
    );
  }
}

enum SelectedType {
  simple,
  complex;
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
      selectInCursorParser: (option) {
        return InsertInCursorPayload(text: option);
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

  final Set<SelectedType> selectedTypes = {SelectedType.simple};

  @override
  Widget build(BuildContext context) {
    optionsController.updateContext(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter textfield sugestions demo'),
        leadingWidth: 310,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 16),
            IconButton(
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
              icon: const Icon(Icons.settings),
            ),
            const SizedBox(width: 16),
            SegmentedButton<SelectedType>(
              segments: SelectedType.values
                  .map(
                    (t) => ButtonSegment(
                      value: t,
                      label: Text(t.name),
                    ),
                  )
                  .toList(),
              selected: selectedTypes,
              onSelectionChanged: (p0) {
                setState(() {
                  selectedTypes.clear();
                  selectedTypes.addAll(p0);
                });
              },
            ),
          ],
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
                optionsController.showOptions(
                  children: complexSuggestion,
                  optionAsString: (option) {
                    return option;
                  },
                );
              }
            },
          ),
          // child: TextFormField(
          //   focusNode: textfieldFocusNode,
          //   controller: textEditingController,
          //   decoration: const InputDecoration(
          //     hintText: 'Type something and use "#" anytime to show options',
          //   ),
          //   style: const TextStyle(height: 1, fontSize: 18),
          //   maxLines: maxLines,
          //   onChanged: (value) {
          //     if (value.isEmpty) return;

          //     final cursorPositionIndex =
          //         textEditingController.selection.base.offset;

          //     final typedValue = value[cursorPositionIndex - 1];

          //     final isTypedCaracterHashtag = typedValue == '#';

          //     if (isTypedCaracterHashtag) {
          //       optionsController.showOptionsMenu(suggestion);
          //     }
          //   },
          // ),
        ),
      ),
    );
  }
}

final List<StructuredDataType<String>> complexSuggestion = [
  const FolderStructure(item: 'Folder 1', children: [
    FolderStructure(item: 'Folder 1.1', children: [
      FolderStructure(item: 'Folder 2.1.1', children: [
        FileStructureOptions(item: 'File 2.1.1'),
        FileStructureOptions(item: 'File 2.1.2'),
        FileStructureOptions(item: 'File 2.1.3'),
      ]),
      FileStructureOptions(item: 'File 1.1.1'),
      FileStructureOptions(item: 'File 1.1.2'),
      FileStructureOptions(item: 'File 1.1.3'),
    ]),
    FolderStructure(item: 'Folder 1.2', children: [
      FileStructureOptions(item: 'File 1.2.1'),
      FileStructureOptions(item: 'File 1.2.2'),
      FileStructureOptions(item: 'File 1.2.3'),
    ]),
    FolderStructure(item: 'Folder 1.3', children: [
      FileStructureOptions(item: 'File 1.3.1'),
      FileStructureOptions(item: 'File 1.3.2'),
      FileStructureOptions(item: 'File 1.3.3'),
    ]),
  ]),
  const FolderStructure(item: 'Folder 2', children: [
    FolderStructure(item: 'Folder 2.1', children: [
      FileStructureOptions(item: 'File 2.1.1'),
      FileStructureOptions(item: 'File 2.1.2'),
      FileStructureOptions(item: 'File 2.1.3'),
    ]),
    FolderStructure(item: 'Folder 2.2', children: [
      FileStructureOptions(item: 'File 2.2.1'),
      FileStructureOptions(item: 'File 2.2.2'),
      FileStructureOptions(item: 'File 2.2.3'),
    ]),
    FolderStructure(item: 'Folder 2.3', children: [
      FileStructureOptions(item: 'File 2.3.1'),
      FileStructureOptions(item: 'File 2.3.2'),
      FileStructureOptions(item: 'File 2.3.3'),
    ]),
  ]),
  const FolderStructure(item: 'Folder 3', children: [
    FolderStructure(item: 'Folder 3.1', children: [
      FileStructureOptions(item: 'File 3.1.1'),
      FileStructureOptions(item: 'File 3.1.2'),
      FileStructureOptions(item: 'File 3.1.3'),
    ]),
    FolderStructure(item: 'Folder 3.2', children: [
      FileStructureOptions(item: 'File 3.2.1'),
      FileStructureOptions(item: 'File 3.2.2'),
      FileStructureOptions(item: 'File 3.2.3'),
    ]),
    FolderStructure(item: 'Folder 3.3', children: [
      FileStructureOptions(item: 'File 3.3.1'),
      FileStructureOptions(item: 'File 3.3.2'),
      FileStructureOptions(item: 'File 3.3.3'),
    ]),
  ]),
  const FileStructureOptions(item: 'File 1'),
  const FileStructureOptions(item: 'File 2'),
  const FileStructureOptions(item: 'File 3'),
  const FileStructureOptions(item: 'File 4'),
  const FileStructureOptions(item: 'File 5'),
  const FileStructureOptions(item: 'File 6'),
];

final List<String> simpleSuggestion = [
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
