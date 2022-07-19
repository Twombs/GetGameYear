# GetGameYear
A program to return the Year and PCGaming Wiki URL for a game.

The program works by manual input, browsing or drag & drop of a folder.

![](https://github.com/Twombs/GetGameYear/blob/main/Screenshots/GetGameYear_mode.png?raw=true)

Manual input can be typing or pasting a game title.

Browsing has a recursive option for sub-folders, allowing for multiple add.

Drag & Drop is available through the Viewer with a small floating DROPBOX.

![](https://github.com/Twombs/GetGameYear/blob/main/Screenshots/GetGameYear_dropbox.png?raw=true)

A viewer is provided, which lists all added games, and has various helpful features, including reducing the need for manual editing.

![](https://github.com/Twombs/GetGameYear/blob/main/Screenshots/GetGameYear_1-6.png?raw=true)

The program uses one of two resources, depending on the option selected - PCGaming Wiki or Wikidata (default). PCGaming Wiki is slower and relies on web page scraping, whereas Wikidata is via API. They can both fail at times, and in my experience so far, PCGaming Wiki is the more reliable when it comes to correct year.

### GetGameYear v1.6 is the first full release made available here.

#### (v1.1)
Added support for the wikidata site and queries, which are now the default. Added a TRIM button to the Viewer to assist with correct game title usage. Added recall of original game title as the title, which is also saved if it doesn't match the successful game name. Added support for game title removal from the game list of the Viewer, using the UPDATE button and a query, if either the Year or URL input fields are empty.

#### (v1.2)
If a year for a game already exists, then it is shown briefly in a 2 second dialog, when adding a single game. Added RELOAD and DROPBOX buttons and processes. NOTE - The dropbox process is the third way to add a game to the list and check for the year, by dragging & dropping a game folder.

#### (v1.3)
Various improvements, including a lot more comments in the code. Where possible, a game entry on the list is selected after a RELOAD and use of the DROPBOX. When a year already exists for a single selected game, a query to update is now presented along with that recorded year. After a folder scan, a query is now presented to show the Viewer.

#### (v1.4)
Added a work-a-round for conflicting years, where multiple are listed via wikidata, and now the earliest listed year rather than first is returned. Other minor improvement.

#### (v1.5)
The correct game title is now recorded as such, with the INI 'found' indicator. Game count for the list is now shown. Games displayed on the list can now be all or a single year or a selected range etc. The shown list of games can now be saved to a selection named text file, with the newly added SAVE LIST button. COPY TO CLIPBOARD button has been reduced in height and renamed to COPY YEAR. UPDATE button now presents a query about saving as the correct game title.

#### (v1.6)
The TRIM button now removes any trailing colon. A CASE button has been added for toggling the game title case, which can be needed for the URL to be correct. Added a 'Replacements' option for ADJUST THE URL, that replaces single quotes and standard brackets with the HTML equivalent (i.e %27). Other minor improvements, including more detail in the Program Information dialog. Bugfix for data in URL field.

Enjoy!
