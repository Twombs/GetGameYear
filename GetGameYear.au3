;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                       ;;
;;  AutoIt Version: 3.3.14.2                                                             ;;
;;                                                                                       ;;
;;  Template AutoIt script.                                                              ;;
;;                                                                                       ;;
;;  AUTHOR:  TheSaint <thsaint@ihug.com.au> (aka Timboli)                                ;;
;;                                                                                       ;;
;;  SCRIPT FUNCTION:  Get the Year and URL for a game from PCGaming Wiki or Wikidata.    ;;
;;                                                                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; FUNCTIONS
; DropBoxGUI(), ViewerGUI()
; GetFound(), GetSetGameCount(), GetTheYear

#include <Constants.au3>
#include <WindowsConstants.au3>
#include <GUIConstantsEx.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <ListBoxConstants.au3>
#include <StaticConstants.au3>
#include <InetConstants.au3>
#include <GuiListBox.au3>
#include <String.au3>
#include <Misc.au3>
#include <File.au3>
#include <Inet.au3>
#include <Array.au3>

Global $Group_games, $List_games

Global $a, $ans, $array, $cliptxt, $cnt, $d, $date, $found, $from, $game, $gamesfold, $html, $htmlfile, $inifle, $misslog, $mode, $pos, $pth, $result, $retry
Global $savfold, $select, $sub, $subfold, $subpth, $subs, $title, $titles, $updated, $URL, $value, $version, $wikidata, $wikiurl, $winpos, $year, $yearfile

_Singleton("get-game-year-timboli", 0)

$htmlfile = @ScriptDir & "\Wikipage.html"
$inifle = @ScriptDir & "\Options.ini"
$misslog = @ScriptDir & "\Missing.log"
$savfold = @ScriptDir & "\Saves"
$wikiurl = "https://www.pcgamingwiki.com/wiki/"
$yearfile = @ScriptDir & "\GameYears.ini"

$updated = "(updated in July 2022)"
$version = "v1.6"

If Not FileExists($savfold) Then DirCreate($savfold)

$wikidata = IniRead($inifle, "Wikidata API", "use", "")
If $wikidata = "" Then
	$wikidata = 1
	IniWrite($inifle, "Wikidata API", "use", $wikidata)
EndIf

$title = ""

;_FileCreate($misslog)

; Query to be in paste mode or folder mode. Folder mode gets a list of folder names in a folder and uses them as game names.
$ans = MsgBox(35 + 262144, "Get Mode Query", "This program can be used in the three following ways." & @LF & @LF & "YES = Paste a game name into the floating input field." _
	& @LF & "NO = Browse to select a folder to be scanned for sub" & @LF & "folder names as game names."& @LF & @LF & "CANCEL = Go to the Viewer (includes a Dropbox).", 0)
If $ans = 6 Then
	$mode = "paste"
	$from = "query"
	GetTheYear()
ElseIf $ans = 7 Then
	$mode = "folder"
	$from = "query"
	$gamesfold = IniRead($inifle, "Last Games Folder", "path", "")
	$pth = FileSelectFolder("Select a folder of game folders. Each will be a game name.", "", 6, $gamesfold)
	If Not @error Then
		; Aborted
		;Exit
	;Else
		IniWrite($inifle, "Last Games Folder", "path", $pth)
		$subs = "|"
		$array = _FileListToArray($pth, "*", 2, False)
		$a = 0
		GetTheYear()
	EndIf
	$ans = MsgBox(33 + 262144, "Viewer Query", "Do you want to open the Viewer?", 0)
	If $ans = 1 Then
		$from = "viewer"
		ViewerGUI()
	EndIf
Else
	$from = "viewer"
	ViewerGUI()
EndIf

Exit


Func DropBoxGUI()
	Local $List_drop
	Local $atts, $dragfld, $DropBox, $left, $top
	;
	$left = IniRead($inifle, "DropBox Window", "left", "")
	$top = IniRead($inifle, "DropBox Window", "top", "")
	If $left = "" Then
		$left = @DesktopWidth - (80 + 25)
		$top = Round(@DesktopHeight / 2)
	EndIf
	$DropBox = GuiCreate("Drop Box", 80, 60, $left, $top, $WS_OVERLAPPED + $WS_CAPTION + $WS_SYSMENU + $WS_VISIBLE _
											+ $WS_CLIPSIBLINGS, $WS_EX_ACCEPTFILES + $WS_EX_TOPMOST + $WS_EX_TOOLWINDOW)
	; CONTROLS
	$List_drop = GUICtrlCreateList("", 0, 0, 80, 80, $WS_BORDER + $LBS_NOSEL + $LBS_USETABSTOPS) ; + $WS_VSCROLL
	GUICtrlSetState($List_drop, $GUI_DROPACCEPTED)
	GUICtrlSetFont($List_drop, 8, 400)
	GUICtrlSetBkColor($List_drop, $COLOR_YELLOW)
	GUICtrlSetTip($List_drop, "Drop an game folder here!")
	;
	;
	; SETTINGS
	GUICtrlSetData($List_drop, '  Drag & Drop')
	GUICtrlSetData($List_drop, '     A Game')
	GUICtrlSetData($List_drop, '      Folder')
	GUICtrlSetData($List_drop, '       HERE')
	;

	GuiSetState()
	While 1
		$msg = GuiGetMsg()
		Select
		Case $msg = $GUI_EVENT_CLOSE
			; Close the Dropbox
			If $game = "" Then
				$select = ""
			Else
				$select = $game
			EndIf
			;
			$winpos = WinGetPos($DropBox, "")
			$left = $winpos[0]
			If $left < 0 Then
				$left = 2
			ElseIf $left > @DesktopWidth - $winpos[2] Then
				$left = @DesktopWidth - $winpos[2]
			EndIf
			IniWrite($inifle, "DropBox Window", "left", $left)
			$top = $winpos[1]
			If $top < 0 Then
				$top = 2
			ElseIf $top > @DesktopHeight - $winpos[3] Then
				$top = @DesktopHeight - $winpos[3]
			EndIf
			IniWrite($inifle, "DropBox Window", "top", $top)
			;
			GUIDelete($DropBox)
			ExitLoop
		Case $msg = $GUI_EVENT_DROPPED
			; Entry added to list by drag and drop or Paste from clipboard
			GUICtrlSetState($List_drop, $GUI_DISABLE)
			If @GUI_DropId = $List_drop Then
				; Drag and drop
				$dragfld = @GUI_DragFile
				$atts = FileGetAttrib($dragfld)
				If StringInStr($atts, "D") > 0 Then
					GUICtrlSetBkColor($List_drop, $COLOR_RED)
					$game = StringSplit($dragfld, "\", 1)
					$game = $game[$game[0]]
					$mode = "dropbox"
					GetTheYear()
					GUICtrlSetBkColor($List_drop, $COLOR_LIME)
				Else
					MsgBox(262192, "Usage Error", "Need to drag & drop a folder, not a file.", 0, $DropBox)
				EndIf
			EndIf
		Case Else
			;;;
		EndSelect
	WEnd
EndFunc ;=> DropBoxGUI

Func ViewerGUI()
	Local $Button_case, $Button_copy, $Button_dropbox, $Button_fold, $Button_inf, $Button_query, $Button_quit, $Button_reload
	Local $Button_save, $Button_trim, $Button_update, $Button_web, $Checkbox_query, $Combo_adjust, $Combo_after, $Combo_before
	Local $Combo_dated, $Combo_show, $Input_game
	Local $Input_url, $Input_year, $Label_adjust, $Label_dated, $Label_game, $Label_show,  $Label_url, $Label_year
	;
	Local $adjust, $after, $before, $c, $dated, $dates, $g, $games, $icoD, $icoI, $icoR, $icoX, $left, $listed, $reload, $reset
	Local $savfile, $shell, $show, $showlist, $top, $user, $Viewer, $years
	;
	$left = IniRead($inifle, "Viewer Window", "left", @DesktopWidth - 465)
	$top = IniRead($inifle, "Viewer Window", "top", 30)
	$Viewer = GuiCreate("Get Game Year - Viewer", 440, 365, $left, $top, $WS_OVERLAPPED + $WS_MINIMIZEBOX + $WS_SYSMENU + _
											$WS_CAPTION + $WS_VISIBLE + $WS_CLIPSIBLINGS, $WS_EX_ACCEPTFILES + $WS_EX_TOPMOST)
	; CONTROLS
	$Group_games = GUICtrlCreateGroup("Games List", 10, 15, 420, 170)
	$List_games = GUICtrlCreateList("", 20, 35, 400, 140)
	GUICtrlSetTip($List_games, "List of games!")
	;
	$Button_reload = GUICtrlCreateButton("R", 300, 5, 30, 25, $BS_ICON)
	GUICtrlSetTip($Button_reload, "Reload the list!")
	;
	$Button_dropbox = GUICtrlCreateButton("DROPBOX", 340, 5, 80, 25)
	GUICtrlSetFont($Button_dropbox, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Button_dropbox, "Show the Dropbox!")
	;
	$Label_game = GUICtrlCreateLabel("GAME", 10, 195, 50, 20, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetBkColor($Label_game, $COLOR_FUCHSIA)
	GUICtrlSetFont($Label_game, 7, 600, 0, "Small Fonts")
	$Input_game = GUICtrlCreateInput("", 60, 195, 327, 20)
	GUICtrlSetTip($Input_game, "Selected game title!")
	$Button_trim = GUICtrlCreateButton("Trim", 390, 195, 40, 20)
	GUICtrlSetFont($Button_trim, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Button_trim, "Remove the last word from the game title!")
	;
	$Label_url = GUICtrlCreateLabel("URL", 10, 220, 40, 20, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN + $SS_NOTIFY)
	GUICtrlSetBkColor($Label_url, $COLOR_SKYBLUE)
	GUICtrlSetFont($Label_url, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Label_url, "Grab the URL from the clipboard!")
	$Input_url = GUICtrlCreateInput("", 50, 220, 337, 20)
	GUICtrlSetTip($Input_url, "Selected game url!")
	$Button_case = GUICtrlCreateButton("CaSe", 390, 220, 40, 20)
	GUICtrlSetFont($Button_case, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Button_case, "Toggle the game title case!")
	;
	$Label_year = GUICtrlCreateLabel("YEAR", 10, 245, 50, 20, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN + $SS_NOTIFY)
	GUICtrlSetBkColor($Label_year, $COLOR_YELLOW)
	GUICtrlSetFont($Label_year, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Label_year, "Grab the Year from the clipboard!")
	$Input_year = GUICtrlCreateInput("", 60, 245, 80, 21, $ES_CENTER)
	GUICtrlSetTip($Input_year, "Selected game year!")
	;
	$Button_update = GUICtrlCreateButton("UPDATE", 150, 245, 70, 21)
	GUICtrlSetFont($Button_update, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Button_update, "Update the year and URL!")
	;
	$Label_adjust = GUICtrlCreateLabel("ADJUST THE URL", 230, 245, 108, 21, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetBkColor($Label_adjust, $COLOR_RED)
	GUICtrlSetFont($Label_adjust, 7, 600, 0, "Small Fonts")
	$Combo_adjust = GUICtrlCreateCombo("", 338, 245, 92, 21)
	GUICtrlSetTip($Combo_adjust, "Adjust the URL!")
	;
	$Label_show = GUICtrlCreateLabel("SHOW", 10, 275, 50, 21, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetBkColor($Label_show, $COLOR_BLUE)
	GUICtrlSetColor($Label_show, $COLOR_WHITE)
	GUICtrlSetFont($Label_show, 7, 600, 0, "Small Fonts")
	$Combo_show = GUICtrlCreateCombo("", 60, 275, 90, 21)
	GUICtrlSetTip($Combo_show, "Show the selected group of games!")
	;
	$Label_dated = GUICtrlCreateLabel("DATED", 160, 275, 55, 21, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetBkColor($Label_dated, $COLOR_GREEN)
	GUICtrlSetColor($Label_dated, $COLOR_WHITE)
	GUICtrlSetFont($Label_dated, 7, 600, 0, "Small Fonts")
	$Combo_dated = GUICtrlCreateCombo("", 215, 275, 95, 21)
	GUICtrlSetTip($Combo_dated, "Show games for the selected year(s)!")
	$Combo_after = GUICtrlCreateCombo("", 320, 275, 50, 21)
	GUICtrlSetTip($Combo_after, "Show games after the selected year!")
	$Combo_before = GUICtrlCreateCombo("", 380, 275, 50, 21)
	GUICtrlSetTip($Combo_before, "Show games before the selected year!")
	;
	$Button_query = GUICtrlCreateButton("QUERY", 10, 305, 70, 30)
	GUICtrlSetFont($Button_query, 8, 600)
	GUICtrlSetTip($Button_query, "Query the year!")
	$Checkbox_query = GUICtrlCreateCheckbox("Wikidata", 17, 335, 70, 20)
	GUICtrlSetTip($Checkbox_query, "Query using wikidata!")
	;
	;$Button_copy = GUICtrlCreateButton("Copy To" & @LF & "Clipboard", 90, 305, 90, 50, $BS_MULTILINE)
	$Button_copy = GUICtrlCreateButton("COPY YEAR", 90, 305, 90, 22)
	GUICtrlSetFont($Button_copy, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Button_copy, "Copy year to clipboard!")
	;
	$Button_save = GUICtrlCreateButton("SAVE LIST", 90, 333, 90, 22)
	GUICtrlSetFont($Button_save, 7, 600, 0, "Small Fonts")
	GUICtrlSetTip($Button_save, "Save the current game list to file!")
	;
	$Button_web = GUICtrlCreateButton("WEB", 190, 305, 55, 50)
	GUICtrlSetFont($Button_web, 9, 600)
	GUICtrlSetTip($Button_web, "Go to web page!")
	;
	$Button_fold = GUICtrlCreateButton("Open", 255, 305, 50, 50, $BS_ICON)
	GUICtrlSetTip($Button_fold, "Open the program folder!")
	;
	$Button_inf = GUICtrlCreateButton("Info", 315, 305, 50, 50, $BS_ICON)
	GUICtrlSetTip($Button_inf, "Viewer Information!")
	;
	$Button_quit = GUICtrlCreateButton("EXIT", 375, 305, 55, 50, $BS_ICON)
	GUICtrlSetTip($Button_quit, "Exit / Close / Quit the program!")
	;
	; OS SETTINGS
	$user = @SystemDir & "\user32.dll"
	$shell = @SystemDir & "\shell32.dll"
	$icoD = -4
	$icoI = -5
	$icoR = -239
	$icoX = -4
	;
	; SETTINGS
	GUICtrlSetImage($Button_reload, $shell, $icoR, 0)
	GUICtrlSetImage($Button_fold, $shell, $icoD, 1)
	GUICtrlSetImage($Button_inf, $user, $icoI, 1)
	GUICtrlSetImage($Button_quit, $user, $icoX, 1)
	;
	GUICtrlSetState($Checkbox_query, $wikidata)
	;
	$adjustments = "||Game Title|Convert Title|Reduce Title|Replacements"
	GUICtrlSetData($Combo_adjust, $adjustments, "")
	;
	$showlist = "All Titles|Original Titles"
	$show = "All Titles"
	GUICtrlSetData($Combo_show, $showlist, $show)
	;
	$dates = "Every Year|Before|After|Between|Selected"
	$dated = "Every Year"
	GUICtrlSetData($Combo_dated, $dates, $dated)
	;
	$years = "|"
	For $y = 1970 To @YEAR
		$years &= "|" & $y
	Next
	GUICtrlSetData($Combo_after, $years, "")
	GUICtrlSetData($Combo_before, $years, "")
	GUICtrlSetState($Combo_after, $GUI_DISABLE)
	GUICtrlSetState($Combo_before, $GUI_DISABLE)
	;
	If FileExists($yearfile) Then
		$games = IniReadSectionNames($yearfile)
		For $g = 1 To $games[0]
			$game = $games[$g]
			GUICtrlSetData($List_games, $game)
		Next
		$cnt = _GUICtrlListBox_GetCount($List_games)
		If $cnt > 0 Then GUICtrlSetData($Group_games, "Games List  (" & $cnt & ")")
	EndIf
	$game = ""
	$reload = ""
	$reset = ""

	GuiSetState()
	While 1
		$msg = GuiGetMsg()
		Select
		Case $msg = $GUI_EVENT_CLOSE Or $msg = $Button_quit
			; Close the Viewer
			$winpos = WinGetPos($Viewer, "")
			$left = $winpos[0]
			If $left < 0 Then
				$left = 2
			ElseIf $left > @DesktopWidth - $winpos[2] Then
				$left = @DesktopWidth - $winpos[2]
			EndIf
			IniWrite($inifle, "Viewer Window", "left", $left)
			$top = $winpos[1]
			If $top < 0 Then
				$top = 2
			ElseIf $top > @DesktopHeight - $winpos[3] Then
				$top = @DesktopHeight - $winpos[3]
			EndIf
			IniWrite($inifle, "Viewer Window", "top", $top)
			;
			GUIDelete($Viewer)
			ExitLoop
		Case $msg = $Button_web
			; Go to web page
			If $game = "" Then
				MsgBox(262192, "Selection Error", "No game title selected!", 2, $Viewer)
			Else
				;If $wikidata = 1 Then
				$URL = GUICtrlRead($Input_url)
				If $URL = "missing" Then $URL = $wikiurl
				ShellExecute($URL)
			EndIf
		Case $msg = $Button_update
			; Update the year and URL
			If $game = "" Then
				MsgBox(262192, "Selection Error", "No game title selected!", 2, $Viewer)
			Else
				$year = GUICtrlRead($Input_year)
				$URL = GUICtrlRead($Input_url)
				If $year = "" Or $URL = "" Then
					$ans = MsgBox(33 + 262144, "Delete Query", "Do you want to remove this game from the list?" & @LF & @LF & $game, 0, $Viewer)
					If $ans = 1 Then
						$ind = _GUICtrlListBox_GetCurSel($List_games)
						If _GUICtrlListBox_GetText($List_games, $ind) = $game Then
							_GUICtrlListBox_DeleteString($List_games, $ind)
							IniDelete($yearfile, $game)
						EndIf
						ContinueLoop
					EndIf
				EndIf
				IniWrite($yearfile, $game, "year", $year)
				IniWrite($yearfile, $game, "url", $URL)
				$ans = MsgBox(33 + 262144, "Update Query", "Do you want to make this title the correct one?" & @LF & @LF & $game, 0, $Viewer)
				If $ans = 1 Then
					IniWrite($yearfile, $game, "found", 1)
				Else
					IniDelete($yearfile, $game, "found")
				EndIf
			EndIf
		Case $msg = $Button_trim
			; Remove the last word from the game title
			$game = GUICtrlRead($Input_game)
			If $game = "" Then
				MsgBox(262192, "Selection Error", "No game title selected!", 2, $Viewer)
			Else
				$pos = StringInStr($game, " ", 0, -1)
				If $pos > 0 Then
					$game = StringLeft($game, $pos - 1)
					If StringRight($game, 1) = ":" Then $game = StringTrimRight($game, 1)
					GUICtrlSetData($Input_game, $game)
				EndIf
			EndIf
		Case $msg = $Button_save
			; Save the current game list to file
			$savfile = $savfold & "\" & $show
			If $show = "All Titles" Then
				If $dated = "Every Year" Then
					$savfile = $savfile & " - " & $dated & ".txt"
				ElseIf $dated = "Before" Then
					$before = GUICtrlRead($Combo_before)
					$savfile = $savfile & " - " & $dated & " " & $before & ".txt"
				ElseIf $dated = "After" Then
					$after = GUICtrlRead($Combo_after)
					$savfile = $savfile & " - " & $dated & " " & $after & ".txt"
				ElseIf $dated = "Between" Then
					$after = GUICtrlRead($Combo_after)
					$before = GUICtrlRead($Combo_before)
					$savfile = $savfile & " - " & $dated & " " & $after & " and " & $before & ".txt"
				ElseIf $dated = "Selected" Then
					$before = GUICtrlRead($Combo_before)
					$savfile = $savfile & " - " & $before & ".txt"
				EndIf
			ElseIf $show = "Original Titles" Then
				If $dated = "Every Year" Then
					$savfile = $savfile & " - " & $dated & ".txt"
				ElseIf $dated = "Before" Then
					$before = GUICtrlRead($Combo_before)
					$savfile = $savfile & " - " & $dated & " " & $before & ".txt"
				ElseIf $dated = "After" Then
					$after = GUICtrlRead($Combo_after)
					$savfile = $savfile & " - " & $dated & " " & $after & ".txt"
				ElseIf $dated = "Between" Then
					$after = GUICtrlRead($Combo_after)
					$before = GUICtrlRead($Combo_before)
					$savfile = $savfile & " - " & $dated & " " & $after & " and " & $before & ".txt"
				ElseIf $dated = "Selected" Then
					$before = GUICtrlRead($Combo_before)
					$savfile = $savfile & " - " & $before & ".txt"
				EndIf
			EndIf
			$listed = ""
			$cnt = _GUICtrlListBox_GetCount($List_games)
			For $c = 0 To $cnt - 1
				$title = _GUICtrlListBox_GetText($List_games, $c)
				$listed &= $title & @CRLF
			Next
			;MsgBox(262192, "$listed", $listed, 0, $Viewer)
			FileWrite($savfile, $listed)
			If FileExists($savfile) Then ShellExecute($savfile)
		Case $msg = $Button_reload Or $reload = 1
			; Reload the list
			$reload = ""
			If $game = "" Then
				$select = ""
			Else
				$select = $game
			EndIf
			_GUICtrlListBox_ResetContent($List_games)
			If FileExists($yearfile) Then
				$games = IniReadSectionNames($yearfile)
				For $g = 1 To $games[0]
					$game = $games[$g]
					GetFound()
				Next
				GetSetGameCount()
			EndIf
			If $select = "" Then
				$game = ""
			Else
				$game = $select
				$ind = _GUICtrlListBox_FindString($List_games, $game, True)
				_GUICtrlListBox_SetCurSel($List_games, $ind)
				_GUICtrlListBox_ClickItem($List_games, $ind, "left", False, 1, 0)
			EndIf
		Case $msg = $Button_query
			; Query the year
			$game = GUICtrlRead($Input_game)
			If $game = "" Then
				MsgBox(262192, "Selection Error", "No game title selected!", 2, $Viewer)
			Else
				$mode = "query"
				GetTheYear()
				$year = IniRead($yearfile, $game, "year", "")
				;If $year = "Early access" Then $year = "not yet"
				GUICtrlSetData($Input_year, $year)
				$URL = IniRead($yearfile, $game, "url", "")
				GUICtrlSetData($Input_url, $URL)
			EndIf
		Case $msg = $Button_inf
			; Viewer Information
			MsgBox(262208, "Viewer Information", _
				"This is a program to obtain the year from 'pcgamingwiki.com'" & @LF & _
				"for each game specified (via paste or folder scan or selected)." & @LF & _
				"CHANGED - The program now uses 'wikidata' as the default" & @LF & _
				"to get the year, but this can be bypassed by deselecting it." & @LF & @LF & _
				"QUERY button checks enabled site for selected game year." & @LF & _
				"TRIM button removes last shown word from the game title." & @LF & _
				"UPDATE button updates the stored values to those shown," & @LF & _
				"or if Year or URL is blank, then list removal will be queried." & @LF & _
				"WEB button tries to go to selected URL or PCGaming Wiki." & @LF & @LF & _
				"LIST REMOVAL - See specifics in UPDATE button above." & @LF & @LF & _
				"ADJUST THE URL shows some possibles for the game URL." & @LF & @LF & _
				"IMPORTANT - Case in a game title can come in all sorts of" & @LF & _
				"arrangements, sometimes mid title or word. Use the CaSe" & @LF & _
				"button to try the usual variants, especially with a resulting" & @LF & _
				"URL (adjust the URL type each time). Then click the WEB" & @LF & _
				"button to check the URL result at PCGaming Wiki." & @LF & @LF & _
				"Clicking the colored labels for 'Year' or 'URL' will copy the" & @LF & _
				"appropriate value from the clipboard, if it exists." & @LF & @LF & _
				"© June 2022 by Timboli - Get Game Year " & $version & @LF & _
				$updated, 0, $Viewer)
		Case $msg = $Button_fold
			; Open the program folder
			ShellExecute(@ScriptDir)
		Case $msg = $Button_dropbox
			; Show the Dropbox
			GUISetState(@SW_MINIMIZE, $Viewer)
			_GUICtrlListBox_ResetContent($List_games)
			DropBoxGUI()
			If FileExists($yearfile) Then
				$games = IniReadSectionNames($yearfile)
				For $g = 1 To $games[0]
					$game = $games[$g]
					GUICtrlSetData($List_games, $game)
				Next
				GetSetGameCount()
			EndIf
			GUISetState(@SW_RESTORE, $Viewer)
			If $select = "" Then
				$game = ""
			Else
				$game = $select
				$ind = _GUICtrlListBox_FindString($List_games, $game, True)
				_GUICtrlListBox_SetCurSel($List_games, $ind)
				_GUICtrlListBox_ClickItem($List_games, $ind, "left", False, 1, 0)
			EndIf
		Case $msg = $Button_copy
			; Copy year to clipboard
			If $game = "" Then
				MsgBox(262192, "Selection Error", "No game title selected!", 2, $Viewer)
			Else
				;If $year = "not yet" Then $year = "Early access"
				ClipPut($year)
				;If $minimize = 1 Then WinSetState($Viewer, "", @SW_MINIMIZE)
			EndIf
		Case $msg = $Button_case
			; Toggle the game title case
			If $game = "" Then
				MsgBox(262192, "Selection Error", "No game title selected!", 2, $Viewer)
			Else
				$game = GUICtrlRead($Input_game)
				If $game == StringUpper($game) Then
					$game = StringLower($game)
				ElseIf $game == StringLower($game) Then
					$game = _StringProper($game)
				ElseIf $game == _StringProper($game) Then
					$game = StringUpper($game)
				EndIf
				GUICtrlSetData($Input_game, $game)
			EndIf
			;$URL = IniRead($yearfile, $game, "url", "")
			;GUICtrlSetData($Input_url, $URL)
		Case $msg = $Checkbox_query
			; Query using wikidata
			If GUICtrlRead($Checkbox_query) = $GUI_CHECKED Then
				$wikidata = 1
			Else
				$wikidata = 4
			EndIf
			IniWrite($inifle, "Wikidata API", "use", $wikidata)
		Case $msg = $Combo_show
			; Show the selected group of games!
			$show = GUICtrlRead($Combo_show)
			If $show = "All Titles" Then
				$titles = "all"
			ElseIf $show = "Original Titles" Then
				$titles = "found"
			EndIf
			$reload = 1
			$reset = 1
		Case $msg = $Combo_dated Or $reset = 1
			; Show games for the selected year(s)
			$reset = ""
			$dated = GUICtrlRead($Combo_dated)
			If $dated = "Every Year" Then
				$reload = 1
				GUICtrlSetData($Combo_after, "")
				GUICtrlSetData($Combo_before, "")
				GUICtrlSetState($Combo_after, $GUI_DISABLE)
				GUICtrlSetState($Combo_before, $GUI_DISABLE)
				;
				GUICtrlSetState($Button_reload, $GUI_ENABLE)
				GUICtrlSetState($Button_dropbox, $GUI_ENABLE)
			Else
				GUICtrlSetState($Button_reload, $GUI_DISABLE)
				GUICtrlSetState($Button_dropbox, $GUI_DISABLE)
				If $dated = "Before" Then
					$reload = 2
					GUICtrlSetData($Combo_after, "")
					GUICtrlSetData($Combo_before, "")
					GUICtrlSetData($Combo_before, $years, @YEAR)
					GUICtrlSetState($Combo_after, $GUI_DISABLE)
					GUICtrlSetState($Combo_before, $GUI_ENABLE)
				ElseIf $dated = "After" Then
					$reload = 3
					GUICtrlSetData($Combo_after, "")
					GUICtrlSetData($Combo_after, $years, "1970")
					GUICtrlSetData($Combo_before, "")
					GUICtrlSetState($Combo_after, $GUI_ENABLE)
					GUICtrlSetState($Combo_before, $GUI_DISABLE)
				ElseIf $dated = "Between" Then
					$reload = 2
					GUICtrlSetData($Combo_after, "")
					GUICtrlSetData($Combo_before, "")
					GUICtrlSetData($Combo_after, $years, "1970")
					GUICtrlSetData($Combo_before, $years, @YEAR)
					GUICtrlSetState($Combo_after, $GUI_ENABLE)
					GUICtrlSetState($Combo_before, $GUI_ENABLE)
				ElseIf $dated = "Selected" Then
					$reload = 2
					GUICtrlSetData($Combo_after, "")
					GUICtrlSetData($Combo_before, "")
					GUICtrlSetData($Combo_before, $years, @YEAR)
					GUICtrlSetState($Combo_after, $GUI_DISABLE)
					GUICtrlSetState($Combo_before, $GUI_ENABLE)
				EndIf
			EndIf
			$game = ""
		Case $msg = $Combo_before Or $reload = 2
			; Show games before the selected year
			$reload = ""
			$after = GUICtrlRead($Combo_after)
			$before = GUICtrlRead($Combo_before)
			;MsgBox(262192, "$after $before", $after & " | " & $before, 2, $Viewer)
			_GUICtrlListBox_ResetContent($List_games)
			If FileExists($yearfile) Then
				$games = IniReadSectionNames($yearfile)
				For $g = 1 To $games[0]
					$game = $games[$g]
					$year = IniRead($yearfile, $game, "year", "")
					If $year <> "" And StringIsDigit($year) = 1 Then
						If $dated = "Selected" Then
							If $year = $before Then
								;GUICtrlSetData($List_games, $game)
								GetFound()
							EndIf
						Else
							If $after = "" And $year < $before Then
								;GUICtrlSetData($List_games, $game)
								GetFound()
							ElseIf Number($year) > Number($after) And Number($year) < Number($before) Then
								;GUICtrlSetData($List_games, $game)
								GetFound()
							EndIf
						EndIf
					EndIf
				Next
				GetSetGameCount()
			EndIf
			$game = ""
		Case $msg = $Combo_after Or $reload = 3
			; Show games after the selected year
			$reload = ""
			$after = GUICtrlRead($Combo_after)
			$before = GUICtrlRead($Combo_before)
			_GUICtrlListBox_ResetContent($List_games)
			If FileExists($yearfile) Then
				$games = IniReadSectionNames($yearfile)
				For $g = 1 To $games[0]
					$game = $games[$g]
					$year = IniRead($yearfile, $game, "year", "")
					If $year <> "" And StringIsDigit($year) = 1 Then
						If $before = "" And $year > $after Then
							;GUICtrlSetData($List_games, $game)
							GetFound()
						ElseIf $year < $before And $year > $after Then
							;GUICtrlSetData($List_games, $game)
							GetFound()
						EndIf
					EndIf
				Next
				GetSetGameCount()
			EndIf
			$game = ""
		Case $msg = $Combo_adjust
			; Adjust the URL
			If $game = "" Then
				MsgBox(262192, "Selection Error", "No game title selected!", 2, $Viewer)
			Else
				;If $wikidata = 1 Then
				$adjust = GUICtrlRead($Combo_adjust)
				If $adjust = "" Then
					$URL = IniRead($yearfile, $game, "url", "")
				ElseIf $adjust = "Game Title" Then
					$URL = StringReplace($game, " ", "_")
					$URL = $wikiurl & $URL
				ElseIf $adjust = "Convert Title" Then
					$pos = StringInStr($game, " - ")
					If $pos > 0 Then
						$URL = StringLeft($game, $pos - 1) & ": " & StringMid($game, $pos + 3)
						$URL = StringReplace($URL, " ", "_")
						$URL = $wikiurl & $URL
					EndIf
				ElseIf $adjust = "Reduce Title" Then
					If $URL = "missing" Then
						$pos = StringInStr($game, " - ", 0, -1)
						If $pos > 0 Then
							$URL = StringLeft($game, $pos - 1)
							$URL = StringReplace($URL, " ", "_")
							$URL = $wikiurl & $URL
						Else
							$pos = StringInStr($URL, " ", 0, -1)
							If $pos > 0 Then
								$URL = StringLeft($URL, $pos - 1)
								$URL = $wikiurl & $URL
							EndIf
						EndIf
					Else
						$URL = GUICtrlRead($Input_url)
						$URL = StringReplace($URL, "_", " ")
						$pos = StringInStr($URL, " - ", 0, -1)
						If $pos > 0 Then
							$URL = StringLeft($URL, $pos - 1)
							$URL = StringReplace($URL, " ", "_")
						Else
							$pos = StringInStr($URL, " ", 0, -1)
							If $pos > 0 Then
								$URL = StringLeft($URL, $pos - 1)
								$URL = StringReplace($URL, " ", "_")
							EndIf
						EndIf
					EndIf
				ElseIf $adjust = "Replacements" Then
					$URL = GUICtrlRead($Input_url)
					$URL = StringReplace($URL, "'", "%27")
					$URL = StringReplace($URL, "(", "%28")
					$URL = StringReplace($URL, ")", "%29")
				EndIf
				GUICtrlSetData($Input_url, $URL)
			EndIf
		Case $msg = $Label_year
			; Grab the Year from the clipboard
			If $game = "" Then
				MsgBox(262192, "Selection Error", "No game title selected!", 2, $Viewer)
			Else
				$cliptxt = ClipGet()
				If (StringIsDigit($cliptxt) And StringLen($cliptxt) = 4) Or $year = "Early access" Then
					$year = $cliptxt
					GUICtrlSetData($Input_year, $year)
				EndIf
			EndIf
		Case $msg = $Label_url
			; Grab the URL from the clipboard
			If $game = "" Then
				MsgBox(262192, "Selection Error", "No game title selected!", 2, $Viewer)
			Else
				$cliptxt = ClipGet()
				If StringLeft($cliptxt, 8) = "https://" Then
					$URL = $cliptxt
					GUICtrlSetData($Input_url, $URL)
				EndIf
			EndIf
		Case $msg = $List_games
			; List of games
			$game = GUICtrlRead($List_games)
			GUICtrlSetData($Input_game, $game)
			$year = IniRead($yearfile, $game, "year", "")
			;If $year = "Early access" Then $year = "not yet"
			GUICtrlSetData($Input_year, $year)
			$URL = IniRead($yearfile, $game, "url", "")
			GUICtrlSetData($Input_url, $URL)
			If StringRight($game, 5) = ", The" Then
				$title = "The " & StringTrimRight($game, 5)
				$year = IniRead($yearfile, $title, "year", "")
				$URL = IniRead($yearfile, $title, "url", "")
				MsgBox(262208, "Alternate Name Result", $title & @LF & @LF & "Year = " & $year & @LF & "URL = " & $URL, 0, $Viewer)
			ElseIf StringInStr($game, ", The") > 0 Then
				$title = StringSplit($game, ", The", 1)
				If $title[0] = 2 Then
					$title = "The " & $title[1] & $title[2]
				EndIf
				$year = IniRead($yearfile, $title, "year", "")
				$URL = IniRead($yearfile, $title, "url", "")
				MsgBox(262208, "Alternate Name Result", $title & @LF & @LF & "Year = " & $year & @LF & "URL = " & $URL, 0, $Viewer)
			EndIf
		Case Else
			;;;
		EndSelect
	WEnd
EndFunc ;=> ViewerGUI


Func GetFound()
	If $titles = "found" Then
		$found = IniRead($yearfile, $game, "found", "")
	Else
		$found = 1
	EndIf
	If $found = 1 Then GUICtrlSetData($List_games, $game)
EndFunc ;=> GetFound

Func GetSetGameCount()
	$cnt = _GUICtrlListBox_GetCount($List_games)
	If $cnt > 0 Then
		GUICtrlSetData($Group_games, "Games List  (" & $cnt & ")")
	Else
		GUICtrlSetData($Group_games, "Games List")
	EndIf
EndFunc ;=> GetSetGameCount

Func GetTheYear()
	$subpth = ""
	$retry = 0
	While 1
		If $mode = "paste" Or $mode = "query" Or $mode = "dropbox" Then
			; Single game query via paste or viewer query or dropbox.
			If $from = "query" Then
				; Single game query via paste.
				If $retry = 1 Then
					$cliptxt = $game
				Else
					$cliptxt = ClipGet()
				EndIf
				If StringInStr($cliptxt, @LF) > 0 Or StringInStr($cliptxt, @CRLF) > 0 Or StringInStr($cliptxt, @CR) > 0 Then
					$cliptxt = ""
				ElseIf StringLen($cliptxt) > 100 Then
					$cliptxt = ""
				EndIf
				$game = InputBox("Game Year Query", "A game name is required, to check at the following." & @LF & @LF & $wikiurl, $cliptxt, "", 500, 155, Default, Default)
				If @error > 0 Then
					; Abort checking.
					$game = ""
				EndIf
			EndIf
			If StringRight($game, 5) = ", The" Then
				$game = StringTrimRight($game, 5)
				$game = "The " & $game
			EndIf
			$year = IniRead($yearfile, $game, "year", "")
			If $year <> "" Then
				; Year entry exists.
				If StringLen($year) = 4 Then
					; Year entry is correct length.
					If StringIsDigit($year) Then
						; Appears to be a Year value, so query to update.
						$ans = MsgBox(262177 + 256, "Year", $game & @LF & @LF & $year & @LF & @LF & "Do you want to update?" & @LF & @LF & "(skips in 4 seconds)", 4)
						If $ans = 2 Or $ans = -1 Then
							; Abort updating.
							ExitLoop
						EndIf
					EndIf
				EndIf
			EndIf
			If $title = "" Then $title = $game
		Else
			; Folder scan with possible multiple game names to check.
			$a = $a + 1
			If $a > $array[0] Then
				; Checking of first layer sub-folders is complete. Process any others indicated.
				If $subs <> "|" Then
					MsgBox(262192, "Next Level Folders", $subs, 0)
					$sub = StringSplit($subs, "|", 1)
					$sub = $sub[2]
					$subs = StringReplace($subs, "|" & $sub & "|", "|")
					$subpth = $pth & "\" & $sub
					$array = _FileListToArray($subpth, "*", 2, False)
					$a = 0
				Else
					; No other sub-folders to check.
					ExitLoop
				EndIf
				$game = ""
			Else
				; Checking the first layer of sub-folders, or any others indicated.
				$game = $array[$a]
				If StringRight($game, 5) = ", The" Then
					$game = StringTrimRight($game, 5)
					$game = "The " & $game
				EndIf
				If $title = "" Then $title = $game
				$year = IniRead($yearfile, $game, "year", "")
				If $year = "" Then
					; Year is missing, so query to check.
					$ans = MsgBox(33 + 262144, "Continue Query", "Getting year for the following game." & @LF & @LF & $game & @LF & @LF & "(auto continue in 3 seconds)", 3)
					If $ans = 2 Then
						; Skip current game.
						$game = ""
						; Query to abort all further games checking.
						$ans = MsgBox(33 + 262144, "Abort Query", "Do you want to abort further queries?", 0)
						If $ans = 1 Then ExitLoop
					EndIf
				Else
					; Year for game exists, so skip.
					$game = ""
				EndIf
			EndIf
		EndIf
		If $subpth = "" And $game <> "" And $mode = "folder" Then
			; First layer sub-folder check, to find if others next layer game sub-folders exist.
			$subfold = $pth & "\" & $game & "\collection.series"
			If FileExists($subfold) Then
				; File found indicating another layer of game folders in this sub-folder.
				$subs = $subs & $game & "|"
				$game = ""
			EndIf
		EndIf
		If $game <> "" Then
			If $wikidata = 1 Then
				; Use wikidata to get game year.
				;MsgBox(262192, "$game", $game, 0)
				$URL = "https://www.wikidata.org/w/api.php?action=wbsearchentities&search=" & $game & "&format=json&errorformat=plaintext&language=en&uselang=en&type=item"
			Else
				; Use pcgamingwiki to get game year.
				; https://www.pcgamingwiki.com/wiki/A_Vampyre_Story
				$URL = StringReplace($game, " ", "_")
			EndIf
			If $URL <> "" Then
				If $wikidata <> 1 Then
					; Use a guesstimate pcgamingwiki concentric URL (may not exist or might be different).
					$URL = $wikiurl & $URL
				EndIf
				$ping = Ping("gog.com", 4000)
				If $ping > 0 Then
					SplashTextOn("", "Downloading Info!", 200, 120, Default, Default, 33)
					_FileCreate($htmlfile)
					;$retry = 0
					While 1
						; Download web data to check for year (pcgamingwiki) or game title (wikidata).
						$html = _INetGetSource($URL, True)
						If $html <> "" Then
							;MsgBox(262192, "$html", $html, 0)
							$result = ""
							If $wikidata = 1 Then
								; Use wikidata queries.
								FileWrite($htmlfile, $html)
								; Check for an ID, which indicates specified game title was found.
								;'"id":"Q24664848",'
								$ID = StringSplit($html, '"id":"', 1)
								If $ID[0] > 1 Then
									; ID was found.
									$ID = $ID[2]
									$ID = StringSplit($ID, '",', 1)
									$ID = $ID[1]
									; Wikidata uses IDs for all properties, and P577 is the property for release date
									;$URL = "https://www.wikidata.org/wiki/Special:EntityData/" & $ID & ".json | jq .entities." & $ID & ".claims.P577[].mainsnak.datavalue.value.time"
									; Download data about the game.
									$URL = "https://www.wikidata.org/wiki/Special:EntityData/" & $ID & ".json"
									$html = _INetGetSource($URL, True)
									If $html <> "" Then
										FileWrite($htmlfile, $html)
										$date = StringSplit($html, '"P577":[', 1)
										If $date[0] > 1 Then
											; Release date indicator found.
											$year = ""
											For $d = 2 To $date[0]
												$value = $date[$d]
												;MsgBox(262192, "$value", $value, 0)
												$value = StringSplit($value, '","timezone"', 1)
												$value = $value[1]
												;MsgBox(262192, "$value", $value, 0)
												$value = StringSplit($value, '"time":"', 1)
												If $value[0] > 1 Then
													; Year value is indicated.
													$value = $value[2]
													;MsgBox(262192, "$value", $value, 0)
													$value = StringSplit($value, '-', 1)
													$value = $value[1]
													;MsgBox(262192, "$value", $value, 0)
													$value = StringReplace($value, '+', '')
													;MsgBox(262192, "$value", $value, 0)
													If StringIsDigit($value) = 0 Then
														; Value is not a year.
														$value = ""
													ElseIf StringLen($value) <> 4 Then
														; Year value is not the correct length.
														$value = ""
													EndIf
													;MsgBox(262192, "$value 2", $value, 0)
													If $value <> "" Then
														If $year = "" Then
															$year = $value
														ElseIf $value < $year Then
															$year = $value
														EndIf
													EndIf
												Else
													; Year value is not indicated.
												EndIf
											Next
											;
											;$year = $year[2]
											;$year = StringSplit($year, '","timezone"', 1)
											;$year = $year[1]
											;$year = StringSplit($year, '"time":"', 1)
											;If $year[0] > 1 Then
											;	; Year value is indicated.
											;	$year = $year[2]
											;	$year = StringSplit($year, '-', 1)
											;	$year = $year[1]
											;	$year = StringReplace($year, '+', '')
											;	If StringIsDigit($year) = 0 Then
											;		; Value is not a year.
											;		$year = ""
											;	ElseIf StringLen($year) <> 4 Then
											;		; Year value is not the correct length.
											;		$year = ""
											;	EndIf
											;	;MsgBox(262192, "$year", $year, 0)
											;Else
											;	; Year value is not indicated.
											;	$year = ""
											;EndIf
										Else
											; Release year indicator not found.
											$year = ""
										EndIf
									Else
										; No data downloaded or returned.
										;MsgBox(262192, "$ID", $ID, 0)
										$year = ""
									EndIf
									$retry = 0
								Else
									; No ID found.
									$year = ""
									$pos = StringInStr($game, " - ")
									If $pos > 0 And $retry < 1 Then
										;If $retry = 1 Then
										;	If StringInStr($game, " Premium Edition") > 0 Then
										;		$game = StringReplace($game, " Premium Edition", "")
										;	EndIf
										;Else
											;MsgBox(262192, "$pos", $pos, 0)
											$game = StringLeft($game, $pos - 1) & ": " & StringMid($game, $pos + 3)
											MsgBox(64 + 262144, "Advice", "Trying again with an adjusted title." & @LF & @LF & $game & @LF & @LF & "(auto continue in 3 seconds)", 3)
										;EndIf
										$retry = $retry + 1
										SplashOff()
										ContinueLoop 2
									Else
										$retry = 0
									EndIf
								EndIf
								If $year <> "" Then
									; Check for correct game title to use for a PCGaming Wiki URL.
									$URL = StringSplit($html, '"P6337":[', 1)
									If $URL[0] > 1 Then
										$URL = $URL[2]
										$URL = StringSplit($URL, '","type":"', 1)
										$URL = $URL[1]
										$URL = StringSplit($URL, '"datavalue":{"value":"', 1)
										If $URL[0] > 1 Then
											$URL = $URL[2]
											If $URL <> "" Then
												$URL = $wikiurl & $URL
												If StringRight($URL, 5) = ".json" Then $URL = "missing"
											EndIf
										Else
											; Correct URL game title second indicator not found.
											$URL = "missing"
										EndIf
									Else
										; Correct URL game title indicator not found.
										$URL = "missing"
									EndIf
								EndIf
								;ExitLoop
							Else
								; Use pcgaming wiki parsing.
								$year = StringSplit($html, '>Release dates</th>', 1)
								If $year[0] > 1 Then
									$value = $year[2]
									$year = StringSplit($value, '>DOS</td>', 1)
									If $year[0] < 2 Then
										$year = StringSplit($value, '>Windows</td>', 1)
									Else
										SplashTextOn("", "Game = DOS", 200, 120, Default, Default, 33)
										Sleep(1000)
									EndIf
									If $year[0] > 1 Then
										$value = $year[2]
										$value = StringSplit($value, '</td>', 1)
										$value = $value[1]
										$year = StringRight($value, 4)
										If StringIsDigit($year) = 0 Then
											$date = StringSplit($value, '<sup id=', 1)
											$date = $date[1]
											;MsgBox(262192, "$date", $date, 0)
											$year = StringRight($date, 4)
											If StringIsDigit($year) = 0 Then
												If StringRight($date, 12) = "Early access" Then
													$year = "Early access"
													$result = $year
												Else
													$result = $date
													$year = ""
												EndIf
											EndIf
										EndIf
									Else
										$year = ""
									EndIf
								Else
									$year = ""
								EndIf
							EndIf
							If $year = "" Or $year = "Early access" Then
								;MsgBox(262192, "$date", $date, 0)
								SplashTextOn("", "Get Year Failed!" & @LF & $result, 200, 120, Default, Default, 33)
								_FileWriteLog($misslog, "(FAILED) " & $game)
								Sleep(1000)
								If $year = "" Then $year = "failed"
								If StringInStr($URL, "/api.php?") > 0 Then $URL = "missing"
								If StringRight($URL, 5) = ".json" Then $URL = "missing"
								If $title <> $game Then
									IniWrite($yearfile, $title, "year", $year)
									IniWrite($yearfile, $title, "url", $URL)
									IniDelete($yearfile, $title, "found")
								EndIf
								IniWrite($yearfile, $game, "year", $year)
								IniWrite($yearfile, $game, "url", $URL)
								IniDelete($yearfile, $game, "found")
								FileWrite($htmlfile, $html)
								If Not FileExists($htmlfile) Then
									MsgBox(262192, "Path Error", "HTML file not found!", 0)
								EndIf
							ElseIf $year <> "" Then
								If StringRight($URL, 5) = ".json" Then $URL = "missing"
								If $title <> $game Then
									IniWrite($yearfile, $title, "year", $year)
									IniWrite($yearfile, $title, "url", $URL)
									IniDelete($yearfile, $title, "found")
								EndIf
								IniWrite($yearfile, $game, "year", $year)
								IniWrite($yearfile, $game, "url", $URL)
								IniWrite($yearfile, $game, "found", 1)
								SplashTextOn("", "Year = " & $year, 200, 120, Default, Default, 33)
								Sleep(1000)
							EndIf
							$retry = 0
							$title = ""
							ExitLoop
						Else
							$pos = StringInStr($game, " - ")
							If $pos > 0 And $retry < 1 And $wikidata <> 1 Then
								;If $retry = 1 Then
								;Else
									$URL = StringLeft($game, $pos - 1) & ": " & StringMid($game, $pos + 3)
									$URL = StringReplace($URL, " ", "_")
									MsgBox(64 + 262144, "Advice", "Trying again with an adjusted title." & @LF & @LF & $URL & @LF & @LF & "(auto continue in 3 seconds)", 3)
									$URL = $wikiurl & $URL
								;EndIf
								$retry = $retry + 1
							Else
								$retry = 0
								If FileExists($pth & "\" & $game & "\collection.series") And $subpth = "" Then
									$subs = $subs & $game & "|"
								Else
									_FileWriteLog($misslog, "(MISSING) " & $game)
									$year = "none"
									$URL = "missing"
									If $title <> $game Then
										IniWrite($yearfile, $title, "year", $year)
										IniWrite($yearfile, $title, "url", $URL)
										IniDelete($yearfile, $title, "found")
									EndIf
									IniWrite($yearfile, $game, "year", $year)
									IniWrite($yearfile, $game, "url", $URL)
									IniDelete($yearfile, $game, "found")
									MsgBox(262192, "Retrieval Error", "No data downloaded!" & @LF & @LF & $game & @LF & @LF & "(auto continue in 5 seconds)", 5)
								EndIf
								$title = ""
								ExitLoop
							EndIf
						EndIf
					WEnd
					SplashOff()
					If $mode = "query" Or $mode = "dropbox" Then ExitLoop
				Else
					MsgBox(262192, "Web Error", "No connection detected!", 0)
				EndIf
			Else
				MsgBox(262192, "Program Error", "No feasible game name provided!", 0)
			EndIf
		Else
			If $mode = "paste" Or $mode = "query" Then ExitLoop
		EndIf
	WEnd
EndFunc ;=> GetTheYear
