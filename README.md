# Power DI
## Introduction
![Power DI](https://i.imgur.com/dMMECKK.png "Power DI")
Power DI is a framework for collecting, transforming and displaying Darktide statistical data.

## Notable features
* Customize reports to your liking, or even create them from scratch, all from within the ui.
* Records events as source data, which means you can create new reports and gain new insights even after a mission has concluded.
* While in a mission the auto save feature will periodically save all recorded data to disk, so in the event of a game crash or disconnect you can just continue where you left off.
* Inspect what gear and build players were using in any of your recorded sessions.
* API available for adding new data sources, datasets and report templates to Power DI.

## Core concepts
Power DI is build around the following three core concepts:
1. Data sources. Events are recorded to data sources, which is the source data in it's rawest form, and requires additional transformations to make them readable.
2. Data sets. One more data sources can be combined to create a dataset. A dataset is a formatted table containing all the information needed to create reports.
3. Reports. A report is generated from a dataset, and creates a specific view of that data by displaying it in a structured way.

# Reports screen
![Reports screen](https://i.imgur.com/xS1P0Nw.png "Reports screen")
The reports screen, for selecting and viewing reports. 

1. Sessions tab. Press to transition to the sessions screen.
2. List of your available reports, select one to generate that report for the currently selected session.
3. Create new report button. Press to start creating a new report from scratch.
4. Row order of the currently selected report. Order can be changed by dragging and dropping the rows.
5. Edit report button. Press to edit the currently selected report.
6. Report columns. When the field type of the column is of type "player" the player names can be clicked on to view the gear and build that player used during that specific match.
7. Report rows. Depending on the field type it will show the sum or average of all child rows. Press a row to expand it and show it's child rows (if available).
8. Exit Power DI. Press to close the ui.

# Sessions screen
![Sessions screen](https://i.imgur.com/yCNzJC5.png "Sessions screen")
The sessions screen. Shows an overview of your recorded sessions.

1. Reports tab. Press to transition to the report screen.
2. Sessions list. Select a session to load it (will automatically transition you to the reports screen)
3. Exit Power DI. Press to close the ui.
4. Delete session (not shown in image). To delete the currently selected session press and hold the key assigned to "discard item".

# Edit screen
![Edit screen](https://i.imgur.com/BzzdjD3.png "Edit screen")
The edit screen. Allows for creating or editing a report.

1. Report name. Fill in the desired name for the report.
2. Template. Select a template to use it as a basis for editing. Select "none" to create a report from scratch. (Only editable when creating a new report)
3. Dataset. Select the dataset you want to use for this report. (Only editable when creating a new report)
4. Report type. Select the report type you want to use. Currently only pivot table is available (Only editable when creating a new report) 
5. Exit without saving. Return to the reports screen without saving.
6. Save and exit. Save the report and return to the reports screen. (Only available when minimum requirements are met)
7. Dataset field. List of all the fields available in the dataset. Fields can be dragged and dropped to the column, rows and values sections.
8. Column. Drag and drop the desired field to be used as the column here. (Only one column can be selected)
9. Rows. Drag and drop the desired fields to be used as rows here. Rows can be ordered by drag and drop as well.
10. Values. Drag and drop the desired fields to be used as values here. Values can be ordered by drag and drop as well.
11. Expand value settings. Press to expand a value and show the settings for that value.
12. Label. Type in the desired label for the value.
13. Field/formula. Shows the field name for normal value. For a calculated value it will show the formula field, allowing you to enter the desired formula used for the calculated field. (See formulas section below for more information)
14. Format. Select the desired format for the value.
15. Visible. Select if the value should be visible in the final report. Useful in conjunction with calculated fields.
16. Add calculated field. Press to add a calculated field to the values list.
17. Data filter. Allows you to enter a formula used to filter the dataset. (See formulas section below for more information)
18. Pivot table settings. Currently unused, but will have setting specific to the pivot table report.
19. Exit Power DI. Press to close the ui.
20. Delete report (not shown in image), When editing an existing report there is a "Delete report" button available, visible above "Exit without saving" button.

## Report templates
The following report templates are available by default:
* Attack report
* Defense report
* Player abilities report
* Player blocked report
* Player buffs report
* Player interactions report
* Player slots report
* Player status report
* Player suppression report
* Tagging report

## Dataset templates
The following dataset templates are available by default:
* Attack reports
* Blocked attacks
* Player abilities
* Player buffs
* Player interactions
* Player status
* Player suppression
* Slots
* Tagging

## Formulas
Formulas are used for both the calculated fields and the data filter. Formulas use a simplified lua, and are run in a separate environment. For the calculated fields you have to compare to the labels of the values you entered. For the data filter you have to compare to the field names as shown in the dataset fields list.

Available symbols:
Symbol | Function
 --- | ---
`=`|equal
`~`|not equal
`>`|greater than
`<`|less than 
`or`|or
`and`|and
`(`|bracket open
`)`|bracket close
`""`|string
`+`|addition
`-`|subtraction
`*`|multiplication
`/`|division

Example:
`attacker_type = "Player" and damage > 0`

# Settings
![Settings](https://i.imgur.com/ZUSsxC9.png "Settings")
Mod settings screen

* Open Power DI. Create a keybinding used to open the Power DI UI.
* Dump data. Create a keybinding used to dump the session and user data to a file. ("\Warhammer 40,000 DARKTIDE\binaries\dump")
* Toggle force report generation. When enabled will force Power DI to always generate the report, bypassing the cache.
* Clear user reports templates. Create a keybinding used to delete all user reports.
* Development testing. Keybinding used during development, shouldn't be used.
* Auto save. Enable to periodical saving of the recorded data during a mission. Can have a performance impact.
* Auto save interval. Interval between auto saves, in seconds.
* Maximum cycles. Maximum number of loops the calculations will be allowed to do per frame. Higher numbers could impact fps.
* Debug mode. Enable to print additional info to the console.
* Date format. Select the date format used when displaying dates.

# API
For information regarding the API please check the wiki:<br />
[Power DI Wiki](https://github.com/OvenProofMars/Power_DI/wiki/2.-API).