/**
 * Get the current instance of the Numbers application.
 * @returns Application<Numbers>.window | boolean<false>
 */
function Numbers() {
  const instance = Application('Numbers');
  instance.includeStandardAdditions = true;
  return instance.windows.length ? instance.windows[0] : false;
}

/**
 * Given a column object and row index number, set the value of the target cell.
 * @param column The column object containing the cell to be set.
 * @param rowIndex The zero-indexed row number of the cell to be set.
 * @param value The value which should be assigned to the cell.
 */
function setCellByColumnAndRowIndex(column, rowIndex, value) {
  column.cells.at(rowIndex).value = value;
}

/**
 * Get a named column from the active sheet of the frontmost Numbers instance.
 * @param colName The column name to resolve.
 * @returns Application<Numbers>.Column
 */
function getColumnByName(colName) {
  let col;
  try {
    col = Numbers().document.activeSheet.tables[0].columns.byName(colName)();
  } catch (ex) {
    col = false;
  }
  return col;
}

/**
 * Get the row number (zero-indexed) of the given cell.
 * @param cell The cell object to parse of the Numbers application instance.
 * @returns number
 */
function getRowNumberByCell(cell) {
  return cell.row().address() - 1;
}

/**
 * Get the currently selected cell or the first cell of an active selection.
 * @returns Cell | boolean
 */
function getCurrentlySelectedCell() {
  let selected;
  try {
    selected = Numbers()
      .document.activeSheet()
      .tables()[0]
      .selectionRange.cells();
  } catch (ex) {
    selected = [];
  }
  return selected.length ? selected[0] : false;
}
