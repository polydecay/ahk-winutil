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

; GLobal variables
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
#s:: InteractiveWindowResize(GetWindow())

+^c:: CopyToClipboard()
+^v:: PasteFromClipboard()

; TODO: Resync these values with my current setup.
Pause & n:: MoveMouse(5899)
Pause & m:: MoveMouse(347, 17)

#if (G_CapsLockRebind)
	*CapsLock:: Send {Blind}{Shift DownTemp}{Ctrl DownTemp}{Alt DownTemp}
	*CapsLock up:: Send {Blind}{Shift Up}{Ctrl Up}{Alt Up}
#if

; --------------------------------------------------------------------
; Window Resizing/Positioning Functions

SmartDragWindow() {
	CoordMode, Mouse
	MouseGetPos, MouseX, MouseY, MouseWin
	WinGetPos, WinX, WinY, WinW, WinH, ahk_id %MouseWin%

	EdgeSize := 16
	if ((MouseX - WinX < EdgeSize) or (WinX + WinW - MouseX < EdgeSize)) {
		DragWindow("X")
	} else if ((MouseY - WinY < EdgeSize) or (WinY + WinH - MouseY < EdgeSize)) {
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
		WinGetPos, WinX, WinY,,, ahk_id %MouseWin%

		if (not Constraint) {
			WinMove, ahk_id %MouseWin%,, WinX + MouseX - MouseLastX, WinY + MouseY - MouseLastY
		} else if (Constraint == "X") {
			WinMove, ahk_id %MouseWin%,, WinX + MouseX - MouseLastX
		} else if (Constraint == "Y") {
			WinMove, ahk_id %MouseWin%,,, WinY + MouseY - MouseLastY
		}

		MouseLastX := MouseX
		MouseLastY := MouseY
	}
}

SmartDragResizeWindow() {
	CoordMode, Mouse
	MouseGetPos, MouseX, MouseY, MouseWin
	WinGetPos, WinX, WinY, WinW, WinH, ahk_id %MouseWin%

	EdgeSize := 16
	Constraint := ""

	if (MouseY - WinY < EdgeSize) {
		Constraint := "Top"
	} else if (WinY + WinH - MouseY < EdgeSize) {
		Constraint := "Bottom"
	}

	if (MouseX - WinX < EdgeSize) {
		Constraint := Constraint . "Left"
	} else if (WinX + WinW - MouseX < EdgeSize) {
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
		WinGetPos, WinX, WinY, WinW, WinH, ahk_id %MouseWin%

		if ((not ResizeFrom) or (ResizeFrom == "BottomRight")) {
			WinMove, ahk_id %MouseWin%,,,, WinW + MouseX - MouseLastX, WinH + MouseY - MouseLastY
		} else if (ResizeFrom == "Bottom") {
			WinMove, ahk_id %MouseWin%,,,,, WinH + MouseY - MouseLastY
		} else if (ResizeFrom == "BottomLeft") {
			WinMove, ahk_id %MouseWin%,
			       , WinX + MouseX - MouseLastX,, WinW - MouseX + MouseLastX, WinH + MouseY - MouseLastY
		} else if (ResizeFrom == "Left") {
			WinMove, ahk_id %MouseWin%,
			       , WinX + MouseX - MouseLastX,, WinW - MouseX + MouseLastX
		} else if (ResizeFrom == "TopLeft") {
			WinMove, ahk_id %MouseWin%,
			       , WinX + MouseX - MouseLastX, WinY + MouseY - MouseLastY
			       , WinW - MouseX + MouseLastX, WinH - MouseY + MouseLastY
		} else if (ResizeFrom == "Top") {
			WinMove, ahk_id %MouseWin%,,, WinY + MouseY - MouseLastY,, WinH - MouseY + MouseLastY
		} else if (ResizeFrom == "TopRight") {
			WinMove, ahk_id %MouseWin%,,
			       , WinY + MouseY - MouseLastY, WinW + MouseX - MouseLastX, WinH - MouseY + MouseLastY
		} else if (ResizeFrom == "Right") {
			WinMove, ahk_id %MouseWin%,,,, WinW + MouseX - MouseLastX
		}

		MouseLastX := MouseX
		MouseLastY := MouseY
	}
}

InteractiveWindowResize(Window) {
	InputBox, WinW, Window Width, Enter window width:,, 200, 125
	InputBox, WinH, Window Height, Enter window height:,, 200, 125

	WinMove, ahk_id %Window%,,,, WinW, WinH
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
	if (BorderStyle = "NoCaption") {
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
		WinSet, Style, +0x400000, ahk_id %Window% ; Enable WS_DLGFRAME
	} else {
		WinSet, Style, -0x400000, ahk_id %Window% ; Disable WS_DLGFRAME
	}

	if (KeepInnerSize) {
		; Don't change teh window size while it's maximized.
		WinGet, WinStatus, MinMax, ahk_id %Window%
		if (WinStatus != 0) {
			Return
		}

		Sleep 10 ; Wait for the window style to update

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
	; Changing WS_SIZEBOX on a maximized window can have unpredictable behavior.
	WinGet, WinStatus, MinMax, ahk_id %Window%
	if (WinStatus != 0) {
		return
	}

	if (Enable) {
		WinSet, Style, +0xC00000, ahk_id %Window% ; Enable WS_CAPTION
		WinSet, Style, +0x40000, ahk_id %Window% ; Enable WS_SIZEBOX
	} else {
		WinSet, Style, -0xC00000, ahk_id %Window% ; Enable WS_CAPTION
		WinSet, Style, -0x40000, ahk_id %Window% ; Disable WS_SIZEBOX
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

; --------------------------------------------------------------------
; CLipboard Functions

CopyToClipboard() {
	; Save the original clipboard content.
	Saved := ClipboardAll

	Send ^c
	ClipWait, 1
	G_Clip := Clipboard

	; Restore the original clipboard.
	Clipboard := Saved
}

PasteFromClipboard() {
	; Save the original clipboard content.
	Saved := ClipboardAll

	Clipboard := G_Clip
	Send ^v

	; Restore the original clipboard.
	Clipboard := Saved
}

; --------------------------------------------------------------------
; Utility Functions

PrintHelp() {
	Text := "Pause-Esc:`t" . "Trun AHK-Script on/off"
	Text := Text . "`n" . "Pause-H:`t`t" . "Print AHK script help"
	Text := Text . "`n" . "Pause-R:`t`t" . "Reload AHK script"
	Text := Text . "`n" . "Pause-I:`t`t" . "Print active-window information"
	Text := Text . "`n" . "Pause-Caps:`t" . "Toggle caps lock mode"

	Text := Text . "`n"
	Text := Text . "`n" . "MButton->LButton:`t" . "Drag mouse-window"
	Text := Text . "`n" . "MButton->RButton:`t" . "Drag-resize mouse-window"

	Text := Text . "`n"
	Text := Text . "`n" . "Win-MButton:`t" . "Toggle mouse-window always-on-top"
	Text := Text . "`n" . "Win-LButton:`t" . "Toggle mouse-window caption"
	Text := Text . "`n" . "Win-RButton:`t" . "Toggle mouse-window borders"
	Text := Text . "`n" . "Shift-Win-LButton:`t" . "Toggle mouse-window caption (keep inner size)"
	Text := Text . "`n" . "Shift-Win-RButton:`t" . "Toggle mouse-window borders (keep inner size)"

	Text := Text . "`n"
	Text := Text . "`n" . "Win-W:`t`t" . "Close active-window"
	Text := Text . "`n" . "Win-A:`t`t" . "Toggle active-window always-on-top"
	Text := Text . "`n" . "Win-S:`t`t" . "Set window size"
	Text := Text . "`n" . "Win-P:`t`t" . "Set window position"

	Text := Text . "`n"
	Text := Text . "`n" . "Shift-Ctrl-C:`t" . "Copy text to secondary clipboard"
	Text := Text . "`n" . "Shift-Ctrl-V:`t" . "Paste text to secondary clipboard"

	Text := Text . "`n"
	Text := Text . "`n" . "Pause-N:`t`t" . "FPS mouse sensitivity check slow"
	Text := Text . "`n" . "Pause-M:`t`t" . "FPS mouse sensitivity check fast"

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
	O_WinDelay := A_WinDelay
	SetWinDelay, 0

	WinGetPos X, Y, Width, Height, ahk_id %Window%
	WinMove, ahk_id %Window%,,,, Width, Height - 1
	WinMove, ahk_id %Window%,,,, Width, Height

	; Restore the WinDelay
	SetWinDelay, %O_WinDelay%
}

MoveMouse(Units, Times := 1, Interval := 1) {
	While (Times > 0) {
		DllCall("mouse_event", uint, 1, int, Units, int, 0)
		Times--
		Sleep Interval
	}
}
