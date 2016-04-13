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

~MButton & LButton:: Return
~MButton & RButton:: Return

#MButton:: ToggleWindowAlwaysOnTop(GetWindow("MouseWin"))
#LButton:: Return
#RButton:: Return

#w:: Return
#a:: ToggleWindowAlwaysOnTop(GetWindow())
#s:: Return

^#Up:: Return
^#Down:: Return
^#Left:: Return
^#Right:: Return

+^c:: CopyToClipboard()
+^v:: PasteFromClipboard()

Pause & b:: Return
Pause & n:: Return
Pause & m:: Return

+^!F1:: Return
+^!F2:: Return
+^!F3:: Return
+^!F4:: Return

#if (G_CapsLockRebind)
	*CapsLock:: Send {Blind}{Shift DownTemp}{Ctrl DownTemp}{Alt DownTemp}
	*CapsLock up:: Send {Blind}{Shift Up}{Ctrl Up}{Alt Up}
#if

; --------------------------------------------------------------------
; Window Resizing/Positioning Functions

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

	Text := Text . "`n"
	Text := Text . "`n" . "Win-W:`t`t" . "Close active-window"
	Text := Text . "`n" . "Win-A:`t`t" . "Toggle active-window always-on-top"
	Text := Text . "`n" . "Win-S:`t`t" . "Set window size"
	Text := Text . "`n" . "Win-P:`t`t" . "Set window position"

	Text := Text . "`n"
	Text := Text . "`n" . "Alt-Win-Up:`t" . "Pseudo fullscreen active-window"
	Text := Text . "`n" . "Alt-Win-Down:`t" . "Center active-window"
	Text := Text . "`n" . "Alt-Win-Left:`t" . "Snap active-window to left"
	Text := Text . "`n" . "Alt-Win-Right:`t" . "Snap active-window to right"

	Text := Text . "`n"
	Text := Text . "`n" . "Shift-Ctrl-C:`t" . "Copy text to secondary clipboard"
	Text := Text . "`n" . "Shift-Ctrl-V:`t" . "Paste text to secondary clipboard"

	Text := Text . "`n"
	Text := Text . "`n" . "Pause-B:`t`t" . "FPS mouse accuracy check"
	Text := Text . "`n" . "Pause-N:`t`t" . "FPS mouse sensitivity check slow"
	Text := Text . "`n" . "Pause-M:`t`t" . "FPS mouse sensitivity check fast"

	Text := Text . "`n"
	Text := Text . "`n" . "Shift-Ctrl-Alt-F1:`t" . "Application specific function 1"
	Text := Text . "`n" . "Shift-Ctrl-Alt-F2:`t" . "Application specific function 2"
	Text := Text . "`n" . "Shift-Ctrl-Alt-F3:`t" . "Application specific function 3"
	Text := Text . "`n" . "Shift-Ctrl-Alt-F4:`t" . "Application specific function 4"

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

; --------------------------------------------------------------------
; Helper Functions

; Returns the 'active-window' by default. Passing "MouseWin" as a string
; will return the 'mouse-window'. You can also pass an 'ahk_id' and it'll be passed through.
GetWindow(Window := "") {
	if (not Window) {
		WinGet, Window,, A
	} else if (Window = "MouseWin") {
		MouseGetPos,,, Window
	}

	; Filter out Windows core UI elements to prevent accidental modifications.
	WinGet, PName, ProcessName, ahk_id %Window%
	if ((PName == "Explorer.EXE") or (PName == "ShellExperienceHost.exe") or (PName == "SearchUI.exe")) {
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
