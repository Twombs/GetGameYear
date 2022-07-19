# GetGameYear
A program to return the Year and PCGaming Wiki URL for a game.

The program works by manual input, browsing or drag & drop of a folder.

[]!(https://github.com/Twombs/GetGameYear/blob/main/Screenshots/GetGameYear_mode.png?raw=true)

Manual input can be typing or pasting a game title.

Browsing has a recursive option for sub-folders, allowing for multiple add.

Drag & Drop is available through the Viewer with a small floating DROPBOX.

[]!(https://github.com/Twombs/GetGameYear/blob/main/Screenshots/GetGameYear_dropbox.png?raw=true)

A viewer is provided, which lists all added games, and has various helpful features, including reducing the need for manual editing.

[]!(https://github.com/Twombs/GetGameYear/blob/main/Screenshots/GetGameYear_1-6.png?raw=true)

The program uses one of two resources, depending on the option selected - PCGaming Wiki or Wikidata (default). PCGaming Wiki is slower and relies on web page scraping, whereas Wikidata is via API. They can both fail at times, and in my experience so far, PCGaming Wiki is the more reliable when it comes to correct year.
