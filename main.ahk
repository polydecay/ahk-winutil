; --------------------------------------------------------------------
; Global Configuration

; AHK configuration.
#NoEnv
#NoTrayIcon
#SingleInstance, force
SetTitleMatchMode, 2
StringCaseSense, On
AutoTrim, Off
SetWinDelay, 25

; GLobal variables.
global G_Version := "0.0.0"
global G_CapsLockRebind := true
global G_Clip := ""

; --------------------------------------------------------------------
; Keybindings

; + = Shift, ^ = Ctrl, ! = Alt, # = WinKey

Pause:: Return
Pause & Esc:: Suspend, Toggle
Pause & r:: Reload
Pause & h:: PrintHelp()
Pause & i:: PrintWindowInfo(GetWindow())
Pause & CapsLock:: G_CapsLockRebind := !G_CapsLockRebind

~MButton & LButton:: SmartDragWindow()
~MButton & RButton:: SmartDragResizeWindow()

#MButton:: ToggleWindowAlwaysOnTop(GetWindow("MouseWin"))
#LButton:: ToggleWindowCaption(GetWindow("MouseWin"))
#RButton:: ToggleWindowBorders(GetWindow("MouseWin"))
+#LButton:: ToggleWindowCaption(GetWindow("MouseWin"), true)
+#RButton:: ToggleWindowBorders(GetWindow("MouseWin"), true)

#w:: CloseWindow(GetWindow())
#a:: ToggleWindowAlwaysOnTop(GetWindow())
#s:: InteractiveWindowMove(GetWindow())
#t:: InteractiveWindowTransparency(GetWindow())

+#z:: SetWindowRegion(GetWindow())
+#x:: ClearWindowRegion(GetWindow())

+^c:: CopyToClipboard()
+^v:: PasteFromClipboard()

^+!LButton::
	While GetKeyState("LButton", "P") {
		Click
		Sleep 2
	}
Return

#if (G_CapsLockRebind)
	*CapsLock:: SendInput {Blind}{Shift Down}{Ctrl Down}{Alt Down}
	*CapsLock Up:: SendInput {Blind}{Shift Up}{Ctrl Up}{Alt Up}
#if

#if GetKeyState("CapsLock", "P")
	; voidtools Everything binding.
	f:: SendInput {blind}{Shift Up}f{Shift Down}
#if

; --------------------------------------------------------------------
; Temporary Hacks

; Thorttle mouse back button because of faulty hardware causing double clicks.
XButton1::
	if (A_TimeSincePriorHotkey < 150) {
		Return
	}

	Send {XButton1 Down}
	KeyWait XButton1
	Send {XButton1 Up}
Return

; --------------------------------------------------------------------
; Window Resizing/Positioning Functions

SmartDragWindow() {
	CoordMode, Mouse
	MouseGetPos, MouseX, MouseY, MouseWin
	WinGetPos, X, Y, W, H, ahk_id %MouseWin%

	if (IsProtectedWindow(MouseWin)) {
		Return
	}

	EdgeSize := 16
	if ((MouseX - X < EdgeSize) or (X + W - MouseX < EdgeSize)) {
		DragWindow("X")
	} else if ((MouseY - Y < EdgeSize) or (Y + H - MouseY < EdgeSize)) {
		DragWindow("Y")
	} else {
		DragWindow()
	}
}

DragWindow(Constraint := "") {
	CoordMode, Mouse
	SetWinDelay, 0 ; Reduce the WinDelay to make the dragging smoother.

	MouseGetPos, MouseLastX, MouseLastY, MouseWin

	if (IsProtectedWindow(MouseWin)) {
		Return
	}

	; Abort if the window is maximized.
	WinGet, WinStatus, MinMax, ahk_id %MouseWin%
	if (WinStatus != 0) {
		return
	}

	; Sends middle mouse button click to cancel any action that was started
	; by the initial click. (Useful in chrome and firefox.)
	GetKeyState, MButtonState, MButton
	if (MButtonState = "D") {
		Send {MButton down}
		Send {MButton up}
	}

	While GetKeyState("LButton", "P") {
		MouseGetPos, MouseX, MouseY
		if ((MouseX == MouseLastX) and (MouseY == MouseLastY)) {
			Continue
		}

		WinGetPos, X, Y,,, ahk_id %MouseWin%

		if (not Constraint) {
			WinMove, ahk_id %MouseWin%,, X + MouseX - MouseLastX, Y + MouseY - MouseLastY
		} else if (Constraint == "X") {
			WinMove, ahk_id %MouseWin%,, X + MouseX - MouseLastX
		} else if (Constraint == "Y") {
			WinMove, ahk_id %MouseWin%,,, Y + MouseY - MouseLastY
		}

		MouseLastX := MouseX
		MouseLastY := MouseY
	}
}

SmartDragResizeWindow() {
	CoordMode, Mouse
	MouseGetPos, MouseX, MouseY, MouseWin
	WinGetPos, X, Y, W, H, ahk_id %MouseWin%

	if (IsProtectedWindow(MouseWin)) {
		Return
	}

	EdgeSize := 16
	Constraint := ""

	if (MouseY - Y < EdgeSize) {
		Constraint := "Top"
	} else if (Y + H - MouseY < EdgeSize) {
		Constraint := "Bottom"
	}

	if (MouseX - X < EdgeSize) {
		Constraint := Constraint . "Left"
	} else if (X + W - MouseX < EdgeSize) {
		Constraint := Constraint . "Right"
	}

	DragResizeWindow(Constraint)
}

DragResizeWindow(ResizeFrom := "") {
	CoordMode, Mouse
	SetWinDelay, 0 ; Reduce the WinDelay to make the dragging smoother.

	MouseGetPos, MouseLastX, MouseLastY, MouseWin

	if (IsProtectedWindow(MouseWin)) {
		Return
	}

	; Abort if the window is maximized.
	WinGet, WinStatus, MinMax, ahk_id %MouseWin%
	if (WinStatus != 0) {
		Return
	}

	; Sends middle mouse button click to cancel any action that was started
	; by the initial click. (Useful in chrome and firefox.)
	GetKeyState, MButtonState, MButton
	if (MButtonState = "D") {
		Send {MButton down}
		Send {MButton up}
	}

	While GetKeyState("RButton", "P") {
		MouseGetPos, MouseX, MouseY
		if ((MouseX == MouseLastX) and (MouseY == MouseLastY)) {
			Continue
		}

		WinGetPos, X, Y, W, H, ahk_id %MouseWin%

		if ((not ResizeFrom) or (ResizeFrom == "BottomRight")) {
			WinMove, ahk_id %MouseWin%,,,, W + MouseX - MouseLastX, H + MouseY - MouseLastY
		} else if (ResizeFrom == "Bottom") {
			WinMove, ahk_id %MouseWin%,,,,, H + MouseY - MouseLastY
		} else if (ResizeFrom == "BottomLeft") {
			WinMove, ahk_id %MouseWin%,
			       , X + MouseX - MouseLastX,, W - MouseX + MouseLastX, H + MouseY - MouseLastY
		} else if (ResizeFrom == "Left") {
			WinMove, ahk_id %MouseWin%,
			       , X + MouseX - MouseLastX,, W - MouseX + MouseLastX
		} else if (ResizeFrom == "TopLeft") {
			WinMove, ahk_id %MouseWin%,
			       , X + MouseX - MouseLastX, Y + MouseY - MouseLastY
			       , W - MouseX + MouseLastX, H - MouseY + MouseLastY
		} else if (ResizeFrom == "Top") {
			WinMove, ahk_id %MouseWin%,,, Y + MouseY - MouseLastY,, H - MouseY + MouseLastY
		} else if (ResizeFrom == "TopRight") {
			WinMove, ahk_id %MouseWin%,,
			       , Y + MouseY - MouseLastY, W + MouseX - MouseLastX, H - MouseY + MouseLastY
		} else if (ResizeFrom == "Right") {
			WinMove, ahk_id %MouseWin%,,,, W + MouseX - MouseLastX
		}

		MouseLastX := MouseX
		MouseLastY := MouseY
	}
}

InteractiveWindowMove(Window) {
	if (Window == "") {
		Return
	}

	InputBox, Size, Window Size, Enter window size (W/H) or (*Mult),, 235, 125
	If (ErrorLevel) {
		Return
	}

	if (RegExMatch(Size, "^(\*\d+|\*\d*\.\d+)$")) {
		WinGetPos, X, Y, W, H, ahk_id %Window%
		Mult := StrSplit(Size, ["*"])[2]
		W := W * Mult
		H := H * Mult
	} else {
		SizeSplit := StrSplit(Size, [",", "/", "x", A_Space])
		W := SizeSplit[1]
		H := SizeSplit[2]
	}

	InputBox, Pos, Window Position, Enter window position (X/Y),, 200, 125
	if (ErrorLevel) {
		Return
	}

	PosSplit := StrSplit(Pos, [",", "/", "x", A_Space])
	X := PosSplit[1]
	Y := PosSplit[2]

	WinMove, ahk_id %Window%,, X, Y, W, H
}

InteractiveWindowTransparency(Window) {
	if (Window == "") {
		Return
	}

	InputBox, Transparency, Window Transparency, Enter transparency (0-100),, 200, 125
	if (ErrorLevel) {
		Return
	}

	if (!RegExMatch(Transparency, "\d+|\d+\.\d+")) {
		MsgBox Transparency has to be a number between "0" and "100".
		Return
	}

	Value := (Transparency / 100) * 255
	WinSet, Transparent, %Value%, ahk_id %Window%
}

; --------------------------------------------------------------------
; Window State Functions

ToggleWindowAlwaysOnTop(Window) {
	if (Window == "") {
		Return
	}

	WinGet, ExStyle, ExStyle, ahk_id %Window%
	if (ExStyle & 0x8) {
		SetWindowAlwaysOnTop(Window, "Off")
	} else {
		SetWindowAlwaysOnTop(Window, "On")
	}
}

SetWindowAlwaysOnTop(Window, State := "On") {
	if (Window == "") {
		Return
	}

	WinSet, AlwaysOnTop, %State%, ahk_id %Window%

	; Move the window to the bottom when disabling AlwaysOnTop to make sure it's
	; not obscuring the active-window.
	if (State == "Off") {
		WinGet, ActiveWindow,, A
		if (ActiveWindow != Window) {
			WinSet, Bottom,, ahk_id %Window%
		}
	}
}

ToggleWindowCaption(Window, KeepInnerSize := false) {
	if (Window == "") {
		Return
	}

	BorderStyle := GetWindowBorderStyle(Window)
	if (BorderStyle == "NoCaption") {
		SetWindowCaption(Window, true, KeepInnerSize)
	} else if (BorderStyle == "NoBorders") {
		SetWindowBorders(Window, true, KeepInnerSize)
	} else {
		SetWindowCaption(Window, false, KeepInnerSize)
	}
}

SetWindowCaption(Window, Enable := true, KeepInnerSize := false) {
	if (Window == "") {
		Return
	}

	; Set the WS_DLGFRAME instead of WS_CAPTION because WS_CAPTION will mess with the WS_BORDER
	; style. WS_CAPTION will also resize the window by 1 pixel in all diractions.
	if (Enable) {
		WinSet, Style, +0x400000, ahk_id %Window% ; Enable WS_DLGFRAME.
	} else {
		WinSet, Style, -0x400000, ahk_id %Window% ; Disable WS_DLGFRAME.
	}

	if (KeepInnerSize) {
		; Don't change teh window size while it's maximized.
		WinGet, WinStatus, MinMax, ahk_id %Window%
		if (WinStatus != 0) {
			Return
		}

		Sleep 10 ; Wait for the window style to update.

		WinGetPos, X, Y, W, H, ahk_id %Window%
		if (Enable) {
			WinMove, ahk_id %Window%,, X, Y - 23, W, H + 23
		} else {
			WinMove, ahk_id %Window%,, X, Y + 23, W, H - 23
		}
	}
}

ToggleWindowBorders(Window, KeepInnerSize := false) {
	if (Window == "") {
		Return
	}

	BorderStyle := GetWindowBorderStyle(Window)
	if (BorderStyle == "NoCaption") {
		SetWindowCaption(Window, true, KeepInnerSize)
		SetWindowBorders(Window, false, KeepInnerSize)
	} else if (BorderStyle == "NoBorders") {
		SetWindowBorders(Window, true, KeepInnerSize)
	} else {
		SetWindowBorders(Window, false, KeepInnerSize)
	}
}

SetWindowBorders(Window, Enable := true, KeepInnerSize := false) {
	if (Window == "") {
		Return
	}

	; Changing WS_SIZEBOX on a maximized window can cause unpredictable behavior.
	WinGet, WinStatus, MinMax, ahk_id %Window%
	if (WinStatus != 0) {
		Return
	}

	if (Enable) {
		WinSet, Style, +0xC00000, ahk_id %Window% ; Enable WS_CAPTION.
		WinSet, Style, +0x40000, ahk_id %Window% ; Enable WS_SIZEBOX.
	} else {
		WinSet, Style, -0xC00000, ahk_id %Window% ; Enable WS_CAPTION.
		WinSet, Style, -0x40000, ahk_id %Window% ; Disable WS_SIZEBOX.
	}

	Sleep 10 ; Wait for the window style to update.

	if (KeepInnerSize) {
		WinGetPos, X, Y, W, H, ahk_id %Window%
		if (Enable) {
			WinMove, ahk_id %Window%,, X - 8, Y - 31, W + 16, H + 39
		} else {
			WinMove, ahk_id %Window%,, X + 8, Y + 31, W - 16, H - 39
		}
	} else {
		; Make sure the window is refreshed after changing WS_SIZEBOX.
		NudgeWindow(Window)
	}
}

SetWindowRegion(Window) {
	if (Window == "") {
		Return
	}

	; The window region doesn't hide the borders so make sure they are
	; disabled before starting.
	BorderStyle := GetWindowBorderStyle(Window)
	if (BorderStyle != "NoBorders") {
		SetWindowBorders(Window, false, true)
	}

	WinGetPos,,, W, H, ahk_id %Window%

	; Show tooltip message and get regions TOP-RIGHT corner.
	ToolTip Select TOP-RIGHT Corner, 0, -25
	KeyWait, LButton, D
	MouseGetPos, MouseStartX, MouseStartY
	KeyWait, LButton

	; Show tooltip message and get regions BOTTOM-LEFT corner.
	ToolTip Select BOTTOM-LEFT Corner, W - 166, H + 5
	KeyWait, LButton, D
	MouseGetPos, MouseEndX, MouseEndY
	KeyWait, LButton

	ToolTip ; Clear the tooltip.

	RegionWidth := MouseEndX - MouseStartX
	RegionHeight := MouseEndY - MouseStartY

	WinSet, Region, %MouseStartX%-%MouseStartY% W%RegionWidth% H%RegionHeight%, ahk_id %Window%
	WinActivate, ahk_id %Window% ; Refocus the window in case it was lost during region setup.
}

ClearWindowRegion(Window) {
	if (Window == "") {
		Return
	}

	; Reset the borders to work more consistently with SetWindowRegion.
	BorderStyle := GetWindowBorderStyle(Window)
	if (BorderStyle == "NoBorders") {
		SetWindowBorders(Window, true, true)
	}

	WinSet, Region,, ahk_id %Window%
	NudgeWindow(Window)
}

; --------------------------------------------------------------------
; CLipboard Functions

CopyToClipboard() {
	; Save the original clipboard content.
	SavedClip := ClipboardAll

	Send ^c
	ClipWait, 1
	G_Clip := Clipboard

	; Restore the original clipboard.
	Clipboard := SavedClip
}

PasteFromClipboard() {
	; Save the original clipboard content.
	SavedClip := ClipboardAll

	Clipboard := G_Clip
	Send ^v

	; Restore the original clipboard.
	Clipboard := SavedClip
}

; --------------------------------------------------------------------
; Utility Functions

PrintHelp() {
	Text := "Pause + Esc:`t`t" . "Turn AHK-Script on/off"
	Text := Text . "`n" . "Pause + H:`t`t" . " Print AHK-Script help"
	Text := Text . "`n" . "Pause + R:`t`t" . " Reload AHK-Script"
	Text := Text . "`n" . "Pause + I:`t`t" . " Print active-window information"
	Text := Text . "`n" . "Pause + Caps:`t`t" . " Toggle caps lock mode"

	Text := Text . "`n"
	Text := Text . "`n" . "MMouse + LMouse:`t" . " Drag mouse-window"
	Text := Text . "`n" . "MMouse + RMouse:`t" . " Drag-resize mouse-window"

	Text := Text . "`n"
	Text := Text . "`n" . "Win + MMouse:`t`t" . " Toggle mouse-window always-on-top"
	Text := Text . "`n" . "Win + LMouse:`t`t" . " Toggle mouse-window caption"
	Text := Text . "`n" . "Win + RMouse:`t`t" . " Toggle mouse-window borders"
	Text := Text . "`n" . "Shift-Win + LMouse:`t" . " Toggle mouse-window caption (keep inner size)"
	Text := Text . "`n" . "Shift-Win + RMouse:`t" . " Toggle mouse-window borders (keep inner size)"

	Text := Text . "`n"
	Text := Text . "`n" . "Shift-Win + Z:`t`t" . " Set window region on active-window"
	Text := Text . "`n" . "Shift-Win + X:`t`t" . " Clear window region on active-window"

	Text := Text . "`n"
	Text := Text . "`n" . "Win + W:`t`t" . " Close active-window"
	Text := Text . "`n" . "Win + A:`t`t`t" . " Toggle active-window always-on-top"
	Text := Text . "`n" . "Win + S:`t`t`t" . " Set window size and position"
	Text := Text . "`n" . "Win + T:`t`t`t" . " Set window transparency"

	Text := Text . "`n"
	Text := Text . "`n" . "Shift-Ctrl + C:`t`t" . " Copy text to AHK clipboard"
	Text := Text . "`n" . "Shift-Ctrl + V:`t`t" . " Paste text from AHK clipboard"

	Text := Text . "`n"
	Text := Text . "`n" . "Shift-Ctrl-Alt + LMouse:`t" . " Spam click left mouse button"

	MsgBox, 0, AHK-Script v%G_Version% - Help, %Text%
}

PrintWindowInfo(Window) {
	if (Window == "") {
		Return
	}

	WinGet, Process, ProcessName, ahk_id %Window%
	WinGetTitle, Title, ahk_id %Window%
	WinGetClass, Class, ahk_id %Window%
	WinGet, WinStyle, Style, ahk_id %Window%
	WinGetPos, X, Y, Width, Height, ahk_id %Window%

	Text := "Process: " . Process
	Text := Text . "`n" . "Title: " . Title
	Text := Text . "`n" . "Class: " . Class
	Text := Text . "`n" . "Style: " . WinStyle

	Text := Text . "`n"
	Text := Text . "`n" . "X: " . X . ", Y: " . Y
	Text := Text . "`n" . "W: " . Width . ", H: " . Height

	MsgBox, 0, Window Information, %Text%
}

CloseWindow(Window) {
	if (Window == "") {
		Return
	}

	WinClose, ahk_id %Window%
}

; --------------------------------------------------------------------
; Helper Functions

; Returns the 'active-window' by default. Passing "MouseWin" as a string
; will return the 'mouse-window'. You can also pass an 'ahk_id' and it'll be passed through.
GetWindow(Window := "") {
	if (not Window) {
		WinGet, Window,, A
	} else if (Window == "MouseWin") {
		MouseGetPos,,, Window
	}

	if (IsProtectedWindow(Window)) {
		Return ""
	}

	Return Window
}

; Returns the window border style as a string.
GetWindowBorderStyle(Window) {
	if (Window == "") {
		Return
	}

	WinGet, WinStyle, Style, ahk_id %Window%
	if (not WinStyle & 0xC00000) and (not WinStyle & 0x40000) {
		Return "NoBorders"
	} else if (not WinStyle & 0x400000) {
		Return "NoCaption"
	} else {
		Return "Default"
	}
}

; Protected Windows are core Windows UI elements that should probably be moved, resized, etc.
IsProtectedWindow(Window) {
	WinGet, PName, ProcessName, ahk_id %Window%
	StringLower, PName, PName

	if (PName == "explorer.exe") {
		WinGetTitle, Title, ahk_id %Window%
		if (Title == "") {
			Return True
		}
	} else if ((PName == "startmenuexperiencehost.exe")
		or (PName == "searchapp.exe")
		or (PName == "searchui.exe")
		or (PName == "shellexperiencehost.exe")) {
		Return True
	}

	Return False
}

; Nudges the window size to trigger a resize event. (This is required for
; some window operations to take effect.)
NudgeWindow(Window) {
	if (Window == "") {
		Return
	}

	; Temporarily disable the window delay to speed up the
	; nudge operation and avoid flickering.
	SavedWinDelay := A_WinDelay
	SetWinDelay, 0

	WinGetPos X, Y, Width, Height, ahk_id %Window%
	WinMove, ahk_id %Window%,,,, Width, Height - 1
	WinMove, ahk_id %Window%,,,, Width, Height

	; Restore the original WinDelay.
	SetWinDelay, %SavedWinDelay%
}

MoveMouse(Units, Times := 1, Interval := 1) {
	While (Times > 0) {
		DllCall("mouse_event", uint, 1, int, Units, int, 0)
		Times--
		Sleep Interval
	}
}
