# cursor_autocomplete_options
Flutter already have a autocomplete widget. But it dosen't match the expected ui pattern that normaly we see in desktop and web versions.
That's because the autocomplete section is bellow the textfield and we can't change that in the autocomplete api.
For that reason this package has been made. To give the possibility to display a listview of options right bellow the
cursor indicator with each autocompletion option in a list tile displayed in a overlay. 

# Getting started

## First, import the pacakge:
```dart
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
```

## Setting variables
Inside the widget that contains the textfield, that needs to be statefull to dispose the resources after using it, we will create the following widgets:

```dart
late final OptionsController<String> optionsController;  
final FocusNode textfieldFocusNode = FocusNode(); 
final TextEditingController textEditingController = TextEditingController();
```

### ⚠️ Important!
We need to create a focus node for the textfield because the OptionsController needs to be able to focus on the textfield again after focusing in the listtile. Also, the app needs to now the textfield to be abble to calculate where to put the caracters. So don't forget to put the `textfield focus node` and the `textEditingController` in your TextFormField widget.  

## After that, in the init state we will initialize the OptionsController:

```dart
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
```

## About generic type <T> of OptionsController
The OptionsController receives a generic T value. This can be any model, but if you just want
to add in the cursor a text you can use <String> as the generic type.

### ⚠️ Important!
If the <T> is *diferent of String*, you need to pass the field `optionAsString` to cast it into a String. So this parameter becomes mandatory if you are not using <String> as the generic type. Otherwise, if the generic type is <String>, you don't need to pass this parametter because the package already know it's is a string.

## Now, you can use the textfield with the values we created:

```dart
TextFormField(
    focusNode: textfieldFocusNode, // <= Don't forget!
    controller: textEditingController, // <= Don't forget!
    style: const TextStyle(height: 1, fontSize: 18), // Don't forget *height* parametter!
    ...
),
```

### ⚠️ Important!
You need to initialize a field called `style` in the textfield with the parameter `height` of it beeing 1. I can't be other value.
The other values of the Textstyle, like fontSize, can be anyone that you like.

### ⚠️ Important!
Don't forget to dispose the controller and textfield in the end.
Notice: you *DON'T* need to dispose the textfield focus node because `OptionsController.dispose()`` will already dispose it for you. See the following exemple:

```dart
@override
void dispose() {
  super.dispose();

  // Don't forget to dispose!
  optionsController.dispose();
  textEditingController.dispose();
}
```

# Usage

You can trigger to show the dialog in the following cursor when ever you wan't.
Remember that the textfield has to be focused in order to the package reconize the cursor and it's location. For that the package will the focus node of the textfield to see if it is focused.

To trigger the overlay to appear with the options, you will call the funcion `showOptionsMenu()` in your OptionsController controller passing the list of options that you wan't
to give to the user. This function will receive the suggestion parameters that is a list of items of the type <T>, the same type of your OptionController<T>.

After the showOptionsMenu() function is trigged, it will show the dialog with the options and then, after the user select's the option, the app will trigger both functions `onSelectedOption` and `onSelectInsertInCursor` (the one's that are not null).

You can trigger it, for example, when the user types "#" in the textfield. But this is totally open for you about when to trigger it. Bellow is a example of this case:

```dart
TextFormField(
    ... // Other atributes
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
)
```

> You can see this full exemple by [clicking here](https://pub.dev/packages/cursor_autocomplete_options/example)

# Manipulating selections
You can manipulate and determine what will be done with the selection with two major functions: `onSelectedOption` and `onSelectInsertInCursor`.
> We don't recommend to use both of them, but technically there is no problem in using both.

## onSelectedOption
Will give you complete controll of what to do with the selected option. So if you want you can manipulate the textfield values yourself.

## onSelectInsertInCursor
This is a pre-built option builded above onSelectedOption that manipulate the TextEditingController in order to insert in the current cursor possition the return of this function.

# Configurations

## Change card size
Inside the `OptionsController`, you can manipulate the **width** and **height** of the options listview with the fields: `overlayCardHeight` and `overlayCardWeight`.

## Debounce
You can configure a debouncer in the trigger of the options overlay. The default is 300ms.

## Controll when to close dialog
Maybe, you don't want to close the dialog after doing your login in `onSelectedOption` or `onSelectInsertInCursor`. So you can set the `willAutomaticallyCloseDialogAfterSelection` field to false and the dialog will stop closing after selecting a value.

---
Made with ❤ by [Igor Miranda](https://github.com/igormidev) <br>
If you like the package, give a 👍