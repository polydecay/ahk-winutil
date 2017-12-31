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

+#z:: SetWindowRegion(GetWindow())
+#x:: ClearWindowRegion(GetWindow())

+^c:: CopyToClipboard()
+^v:: PasteFromClipboard()

^+!LButton::
	While GetKeyState("LButton", "P") {
		Click
		Sleep 10
	}
Return

; TODO: Resync these values with my current setup.
Pause & n:: MoveMouse(5899)
Pause & m:: MoveMouse(347, 17)

#if (G_CapsLockRebind)
	*CapsLock:: SendInput {Blind}{Shift DownTemp}{Ctrl DownTemp}{Alt DownTemp}
	*CapsLock up:: SendInput {Blind}{Shift Up}{Ctrl Up}{Alt Up}
#if

; --------------------------------------------------------------------
; Window Resizing/Positioning Functions

SmartDragWindow() {
	CoordMode, Mouse
	MouseGetPos, MouseX, MouseY, MouseWin
	WinGetPos, X, Y, W, H, ahk_id %MouseWin%

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

	; Abort if the window is maximized.
	WinGet, WinStatus, MinMax, ahk_id %MouseWin%
	if (WinStatus != 0) {
		return
	}

	While GetKeyState("LButton", "P") {
		MouseGetPos, MouseX, MouseY
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

	; Abort if the window is maximized.
	WinGet, WinStatus, MinMax, ahk_id %MouseWin%
	if (WinStatus != 0) {
		return
	}

	While GetKeyState("RButton", "P") {
		MouseGetPos, MouseX, MouseY
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
	InputBox, Size, Window Size, Enter window size (W/H),, 200, 125
	SizeSplit := StrSplit(Size, [",", "/", "x", A_Space])
	W := SizeSplit[1]
	H := SizeSplit[2]

	InputBox, Pos, Window Position, Enter window position (X/Y),, 200, 125
	PosSplit := StrSplit(Pos, [",", "/", "x", A_Space])
	X := PosSplit[1]
	Y := PosSplit[2]

	WinMove, ahk_id %Window%,, X, Y, W, H
}

; --------------------------------------------------------------------
; Window State Functions

ToggleWindowAlwaysOnTop(Window) {
	WinGet, ExStyle, ExStyle, ahk_id %Window%
	if (ExStyle & 0x8) {
		SetWindowAlwaysOnTop(Window, "Off")
	} else {
		SetWindowAlwaysOnTop(Window, "On")
	}
}

SetWindowAlwaysOnTop(Window, State := "On") {
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
	; Changing WS_SIZEBOX on a maximized window can cause unpredictable behavior.
	WinGet, WinStatus, MinMax, ahk_id %Window%
	if (WinStatus != 0) {
		return
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

	Text := Text . "`n"
	Text := Text . "`n" . "Shift-Ctrl + C:`t`t" . " Copy text to AHK clipboard"
	Text := Text . "`n" . "Shift-Ctrl + V:`t`t" . " Paste text from AHK clipboard"

	Text := Text . "`n"
	Text := Text . "`n" . "Shift-Ctrl-Alt + LMouse:`t" . " Spam click left mouse button"

	Text := Text . "`n"
	Text := Text . "`n" . "Pause + N:`t`t" . " FPS mouse sensitivity check slow"
	Text := Text . "`n" . "Pause + M:`t`t" . " FPS mouse sensitivity check fast"

	MsgBox, 0, AHK-Script v%G_Version% - Help, %Text%
}

PrintWindowInfo(Window) {
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

	; Filter out Windows core UI elements to prevent accidental modifications.
	WinGet, PName, ProcessName, ahk_id %Window%
	if ((PName == "Explorer.EXE")
	   or (PName == "ShellExperienceHost.exe")
	   or (PName == "SearchUI.exe")) {
		return ""
	}

	return Window
}

; Returns the window border style as a string.
GetWindowBorderStyle(Window) {
	WinGet, WinStyle, Style, ahk_id %Window%
	if (not WinStyle & 0xC00000) and (not WinStyle & 0x40000) {
		Return "NoBorders"
	} else if (not WinStyle & 0x400000) {
		Return "NoCaption"
	} else {
		Return "Default"
	}
}

; Nudges the window size to trigger a resize event. (This is required for
; some window operations to take effect.)
NudgeWindow(Window) {
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
