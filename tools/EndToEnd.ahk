#Requires AutoHotkey v2.0
#SingleInstance Off

; Types into a window of its own through a running copy of PhraseKey.ahk,
; which uses throwaway settings, and checks what comes out. Needs the
; desktop: do not type while it runs. Exits 0 when everything passed.
; Usage: AutoHotkey64.exe EndToEnd.ahk [path\to\PhraseKey.exe]
SetKeyDelay 15, 15
SendMode "Event"
; PhraseKey ignores keys sent at level 0, as it does its own.
SendLevel 1
folder := A_Temp "\PhraseKey-endtoend"
DirCreate folder
program := A_Args.Length ? '"' A_Args[1] '"' : '"' A_AhkPath '" "' A_ScriptDir '\..\PhraseKey\PhraseKey.ahk"'
; Warn anyone using the computer: the test takes over the keyboard focus,
; and their typing would land in it.
Loop 5 {
    ToolTip "PhraseKey test takes over the keyboard in " (6 - A_Index) " seconds. Please stop typing until the low beep."
    SoundBeep 1000, 150
    Sleep 850
}
SoundBeep 1500, 400
ToolTip "PhraseKey test running. Please don't type until the low beep."
pad := Gui(, "PhraseKey end-to-end test")
box := pad.AddEdit("w500 r3")
pad.Show()
failures := []
passed := 0

; With ; as the suffix key.
pid := Start("%u003B")

Test("Suffix after a chord", () => (Chord("lk"), Chord(";i")), "liking ")
Test("Full stop after a suffix", () => (Chord("lk"), Chord(";i"), Send(".")), "liking.")
Test("Full stop replaces the space", () => (Chord("lk"), Send(".")), "like.")
Test("Comma, then typing on", () => (Chord("lk"), Send(", so")), "like, so")
Test("Suffix after an abbreviation", () => (Send("hpy "), Chord(";n")), "happiness ")
Test("Prefix with no space", () => (Chord("mu"), Chord("ilm"), Chord(";s")), "multimillionaires ")
Test("Ordinary letters after a chord", () => (Chord("lk"), Send("do")), "like do")
Test("Semicolon on its own", () => (Chord("lk"), Send(";")), "like;")
Test("Semicolon and space rolled together", () => (Chord("lk"), Send("{; down}{Space down}{; up}{Space up}")), "like; ")
Test("No suffix after text that is not a word", () => (Chord("lk"), Send("x."), Chord(";i")), "like x.;i")
Test("Suffix on a typed word", () => (Send("walk"), Chord(";i")), "walking ")
Test("Suffix on a typed word and space", () => (Send("walk "), Chord(";e")), "walked ")
Test("Typed word, suffix, full stop", () => (Send("walk "), Chord(";i"), Send(".")), "walking.")
Test("Typed word, two suffixes", () => (Send("try "), Chord(";e"), Chord(";s")), "trieds ")
Test("Prefix chord, typed word, suffix", () => (Chord("mu"), Send("task"), Chord(";i")), "multitasking ")
Test("Earlier words are left alone", () => (Send("I walk "), Chord(";e")), "I walked ")
Test("Stacked suffixes", () => (Chord("lk"), Chord(";i"), Chord(";s")), "likings ")
Test("Typing fast after a full stop", () => (Chord("lk"), SetKeyDelay(0, 0), Send(". The"), SetKeyDelay(15, 15)), "like. The")
Test("Abbreviation ended by a full stop", () => Send("hpy."), "happy.")
Test("Abbreviation ended by a comma, then typing on", () => Send("hpy, so"), "happy, so")
Test("Abbreviation, space, full stop", () => Send("hpy ."), "happy.")
Test("Abbreviation inside a word is left alone", () => Send("xhpy."), "xhpy.")
Test("Semicolon, the suffix key, does not expand", () => Send("hpy;"), "hpy;")
Test("Quote keeps the space", () => (Chord("lk"), Send('"')), 'like "')

ProcessClose pid

; With Space as the suffix key, as it is to begin with.
pid := Start("%u0020")
Test("Space: suffix straight after a typed word", () => (Send("miss"), Chord(" e")), "missed ")
Test("Space: suffix after a typed word and space", () => (Send("walk "), Chord(" e")), "walked ")
Test("Space: suffix after a chord", () => (Chord("lk"), Chord(" i")), "liking ")
Test("Space: suffix after an abbreviation", () => (Send("hpy"), Chord(" n")), "happiness ")
Test("Space: suffix, then full stop", () => (Send("walk"), Chord(" i"), Send(".")), "walking.")
Test("Space: ordinary typing", () => Send("we walk in the rain "), "we walk in the rain ")
Test("Space: rolled into the next word is typing", () => (Send("walk{Space down}"), Sleep(100), Send("{i down}{Space up}{i up}n")), "walk in")
Test("Space: abbreviation still expands", () => Send("hpy now"), "happy now")
Test("Space: abbreviation, Space rolled into the next word", () => (Send("hpy{Space down}"), Sleep(100), Send("{n down}{Space up}{n up}ow")), "happy now")
Test("Space: full stop after a chord", () => (Chord("lk"), Send(".")), "like.")
ProcessClose pid
pad.Destroy()
for failure in failures
    FileAppend failure "`n", "**"
FileAppend passed " end-to-end checks passed, " failures.Length " failed.`n", "*"
ToolTip
; Finished: the keyboard is free again.
SoundBeep 400, 600
ExitApp failures.Length ? 1 : 0

; Starts PhraseKey with fresh settings and the given suffix key, encoded.
Start(suffixKey) {
    global folder, program
    try FileDelete folder "\settings.ini"
    settings := "
    (
[Options]
SuffixKey=KEY
CheckUpdates=0
NvdaWarning=0
PlaySound=0
[Chords]
_saved=1
kl=like
mu=multi
ilm=millionaire
eht=the
[Strings]
_saved=1
hpy=happy
[Suffixes]
_saved=1
e=ed
i=ing
s=s
n=ness
[NoSpace]
chord%u003Amu=1
    )"
    FileAppend StrReplace(settings, "=KEY", "=" suffixKey, true), folder "\settings.ini", "UTF-16"
    Run program ' --settings "' folder '"',,, &pid
    if !WinWait("PhraseKey ahk_pid " pid,, 10)
        Fail("PhraseKey did not start")
    Sleep 500
    return pid
}
; Presses the keys together, then releases them.
Chord(keys) {
    down := "", up := ""
    for key in StrSplit(keys) {
        name := key = " " ? "Space" : key
        down .= "{" name " down}", up .= "{" name " up}"
    }
    ; Together, as a person presses them; Windows' Sleep is too coarse to
    ; space them out reliably.
    SetKeyDelay 0, 0
    Send down
    SetKeyDelay 15, 15
    Send up
}
Test(label, steps, expected) {
    global box, pad, failures, passed
    box.Value := ""
    WinActivate "ahk_id " pad.Hwnd
    WinWaitActive "ahk_id " pad.Hwnd,, 2
    box.Focus()
    ; A key PhraseKey treats as a fresh start.
    Send "{End}"
    Sleep 100
    steps()
    Sleep 400
    actual := box.Value
    if actual == expected
        passed += 1
    else
        failures.Push(label ": expected [" expected "], got [" actual "]")
}
Fail(message) {
    ToolTip
    SoundBeep 400, 600
    FileAppend message "`n", "**"
    ExitApp 2
}
