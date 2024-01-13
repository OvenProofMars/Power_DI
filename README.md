# Power DI

A framework for collection, transforming, and displaying game statistics.

## Main view
![Main view](https://i.imgur.com/X5vV62Y.png "Main view")

#### Sessions
On the top left you can select a session, this will load the data from disk and generate any reports from that data. Selecting sessions will be unavailable during missions.

#### Report list
On the bottom left you can select a report from the list to generate it based on the currently selected session data. On the right of the selected report there is a cog item to edit the report. At the bottom there is a "+" sign to start creating a new report from scratch.

#### Workspace
The generated report will be displayed in the center. Any rows with a dot on the left can be expanded. If there are more than 4 columns in the report you can use the arrows on the left and rigth side of the columns to scroll. If for some reason the report fails to load it should display an error in it's place.

### Edit view
![Edit view](https://i.imgur.com/v3o9LFz.png "Edit view")

#### Report name
Fill in the desired report name, upon saving it will overwrite any report with that name.

#### Dataset
Select the dataset you want to use. Changing the dataset will reset the rest of the report.

#### Report type
Select the report type you want to use. Currently only the pivot table is implemented.

#### Save button
Will save the current report template, only available when all required fields have been set.

#### Main menu button
Will return to the main menu without saving

#### Data filter
Here you can create a filter to filter the dataset with. It uses a simplified lua, and is run in a separate environment. You can compare against fieldnames by just typing the field name

Available options:

`=` equal, `~` not equal, `>` greater than, `<` less than, `or` or, `and` and, `(` bracket open, `)` bracket close, `""` string

Example:

field1 = "value1" and field2 > 5

#### Fields
List of fields available in the dataset. Select a field to be able to move it to either the rows or columns.

#### Columns
List of fields that will be used as columns, currently multiple columns is not working well. Press the "Add selected field" button to move the currently selected field to the columns list. Select a field in the columns list and use the up and down arrows to order the list, or press the "x" to move it back to the fields list.

#### Rows
List of fields that will be used as rows. Press the "Add selected field" button to move the currently selected field to the rows list. Select a field in the rows list and use the up and down arrows to order the list, or press the "x" to move it back to the fields list.

#### Values
List of values that will be used. Select a value to edit it, or press clear selections to add a new value. After selecting a value you can delete it by pressing the "x".

* label - label that will be visible in the report
* type - select between "sum", "count" and "calculated field"
* field - Select the field you want to use as the base for the value. Only visible when "sum" or "count" has been selected.
* function - create a function to use for the calculated column. Works the same as the data filter, except you use the value labels instead of the field names. Only available when "calculated field"
* visible - select if the value needs to be visible in the final report. Only useful in combination with calculated fields.
* format - select a format to use. "None" to use the raw data, "number" to format the number with "," every thousend, "percentage" to show the value as a percentage

### Settings
![Settings](https://i.imgur.com/8JxQzuE.png "Settings")

* Open Power DI - create a keybind to open the main Power DI view.
* Dump data - create a keybind to dump the data to a file ("\Warhammer 40,000 DARKTIDE\binaries\dump")
* Auto save - enable to periodical saving of the recorded data during a mission.
* Auto save interval - interval between auto saves, in seconds.
* Maximum cycles - maximum number of loops the calculations will be allowed to do per frame. Higher numbers could impact fps.
* Debug mode - enable to print additional info to the console.

## Creating addons

I'll add some information regarding the mod's structure and API here later.