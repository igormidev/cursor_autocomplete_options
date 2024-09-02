## [1.7.0] 01-08-2024
* Added possibility to edit list tile 
* 🐛 BUG FIX - Focus node was not working as expected

## [1.6.0] 31-08-2024
* Added searchbar to facilitate find the target item
* Using Material Theme on dialog components for colors instead of static fixed colors

## [1.5.0] 23-02-2024
* Added `onTextAddedCallback`.
* Rename `onSelectInsertInCursor` to `selectInCursorParser`

## [1.4.0] 23-02-2024
* Added possibility to customize card and create a wrapper above the listview with the listtiles of the options.

## [1.3.1] 28-10-2023
* Added `InsertInCursorPayload` to public api's
* README updated onSelectInsertInCursor to include InsertInCursorPayload mention

#### ⚠️ Warning: Change of onSelectInsertInCursor function.
* `InsertInCursorPayload` created and added as response to `onSelectInsertInCursor` with the goal of giving more controll of what will be inserted and what will happend with the cursor after inserting it.
* `overlay` parameter added to OptionsController to give a option of the user to pass his own OverlayState.
* `tileHeight` parameter added to OptionsController to give the option to change the height of each option tile in the listview.

## [1.2.4] 26-10-2023
* OptionsController documentation created
* OverlayChoicesListViewWidget documentation created
* README added updateContext how-to-use documentation

## [1.2.3] 26-10-2023
* Readme html bug fix

## [1.2.2] 26-10-2023
* Readme improvement

## [1.2.1] 26-10-2023
* Live demo uploaded

## [1.2.0] 26-10-2023
* Mobile scroll fix
* Mobile full suport
* Example Demo - added more texts in suggestion

## [1.1.0] 25-10-2023
* Web scroll fix
* Border added to first and last item tiles 

## [1.0.0] 25-10-2023
* First release