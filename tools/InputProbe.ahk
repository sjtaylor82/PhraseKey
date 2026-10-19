#Requires AutoHotkey v2.0
#SingleInstance Force

; Shows every key and character a watcher like PhraseKey's receives, with
; times, to see how a screen reader delivers braille typing. Nothing is
; saved; the log is only in this window. Exit or pause PhraseKey first.
; Ctrl+Alt+F8 clears the log, Ctrl+Alt+F9 exits.

Start := A_TickCount
Win := Gui("+Resize", "Input probe")
Win.AddText(, "Log (newest last). Ctrl+Alt+F8 clears, Ctrl+Alt+F9 exits:")
LogBox := Win.AddEdit("r24 w620 ReadOnly")
Win.OnEvent("Close", (*) => ExitApp())
Win.Show()

; As PhraseKey's tracker, so it sees what PhraseKey sees.
Hook := InputHook("V I1 L0")
Hook.KeyOpt("{All}", "N")
Hook.OnKeyDown := (ih, vk, sc) => Log(Format("down {:-12} vk {:02X} sc {:03X}", GetKeyName(Format("vk{:02X}sc{:03X}", vk, sc)), vk, sc))
Hook.OnKeyUp := (ih, vk, sc) => Log(Format("up   {:-12} vk {:02X}", GetKeyName(Format("vk{:02X}sc{:03X}", vk, sc)), vk))
Hook.OnChar := CharSeen
Hook.Start()
Hotkey "^!F8", (*) => (LogBox.Value := "")
Hotkey "^!F9", (*) => ExitApp()

CharSeen(ih, chars) {
    for char in StrSplit(chars)
        Log(Format("char U+{:04X} {}", Ord(char), Ord(char) < 32 ? "(control)" : char))
}

Log(text) {
    if WinActive("ahk_id " Win.Hwnd)
        return
    LogBox.Value .= (LogBox.Value = "" ? "" : "`r`n") Format("{:7}", A_TickCount - Start) "  " text
    SendMessage 0x115, 7, 0, LogBox ; WM_VSCROLL, SB_BOTTOM
}
