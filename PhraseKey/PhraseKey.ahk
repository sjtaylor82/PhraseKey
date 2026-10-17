#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ChordEngine.ahk
#Include AfterExpansion.ahk
#Include WordForms.ahk
#Include Bundled.ahk
#Include Updater.ahk

; Chords use letter, digit and punctuation keys; abbreviations any characters.
; Settings only are persisted. Typed text is never logged or saved.
SendMode "Event"
SetKeyDelay -1, -1
SetWorkingDir A_ScriptDir
AppVersion := "0.9.2"
Rules := Map("eht", "the")
SingleRules := Map()
; Suffix chords are saved without the suffix key, as "i" => "ing";
; Suffixes holds the chords themselves, as ";i" => "ing".
SuffixEntries := Map()
Suffixes := Map()
SuffixKey := " "
; Entries that type no space after their replacement, as "chord:eht".
NoSpace := Map()
; Word forms the user corrected: word => Map(ending => form).
SavedForms := Map()
SettingsPath := A_AppData "\PhraseKey"
; Automated tests use their own settings: PhraseKey.ahk --settings folder
if A_Args.Length = 2 && A_Args[1] = "--settings"
    SettingsPath := A_Args[2]
DirCreate SettingsPath
SettingsFile := SettingsPath "\settings.ini"
WindowMs := 30
SpaceWindowMs := 20
TrailingSpace := true
PlayTick := false
NvdaWarning := true
CheckUpdates := true
SkippedVersion := ""
SpaceAfterPunctuation := false
SuffixOnTyped := true
PunctuationExpands := true
try {
    PlayTick := IniRead(SettingsFile, "Options", "PlaySound", "0") = "1"
    NvdaWarning := IniRead(SettingsFile, "Options", "NvdaWarning", "1") = "1"
    CheckUpdates := IniRead(SettingsFile, "Options", "CheckUpdates", "1") = "1"
    SkippedVersion := IniRead(SettingsFile, "Options", "SkippedVersion", "")
    SpaceAfterPunctuation := IniRead(SettingsFile, "Options", "SpaceAfterPunctuation", "0") = "1"
    SuffixOnTyped := IniRead(SettingsFile, "Options", "SuffixOnTypedWords", "1") = "1"
    PunctuationExpands := IniRead(SettingsFile, "Options", "PunctuationExpands", "1") = "1"
    key := DecodeKey(IniRead(SettingsFile, "Options", "SuffixKey", EncodeKey(" ")))
    if IsSuffixKey(key)
        SuffixKey := key
}
try {
    WindowMs := Integer(IniRead(SettingsFile, "Options", "WindowMs", "30"))
    ; Version 0.9 and earlier saved 90, the old default, and had no Space
    ; chord timing. 90 lets fast typing on many keyboards through as chords.
    if WindowMs = 90 && IniRead(SettingsFile, "Options", "SpaceWindowMs", "") = ""
        WindowMs := 30
    if WindowMs < 5 || WindowMs > 500
        WindowMs := 30
    SpaceWindowMs := Integer(IniRead(SettingsFile, "Options", "SpaceWindowMs", "20"))
    if SpaceWindowMs < 5 || SpaceWindowMs > 500
        SpaceWindowMs := 20
    TrailingSpace := IniRead(SettingsFile, "Options", "TrailingSpace", "1") = "1"
    section := IniRead(SettingsFile, "Chords",, "")
    if section != "" {
        loaded := Map()
        for line in StrSplit(section, "`n", "`r") {
            equals := InStr(line, "=")
            if equals && SubStr(line, 1, equals - 1) != "_saved" {
                chord := Normalise(DecodeKey(SubStr(line, 1, equals - 1)))
                if chord != ""
                    loaded[chord] := Decode(SubStr(line, equals + 1))
            }
        }
        Rules := loaded
    }
}
try {
    section := IniRead(SettingsFile, "Strings",, IniRead(SettingsFile, "Singles",, ""))
    for line in StrSplit(section, "`n", "`r") {
        equals := InStr(line, "=")
        if equals && SubStr(line, 1, equals - 1) != "_saved" {
            letter := StrLower(DecodeKey(SubStr(line, 1, equals - 1)))
            if RegExMatch(letter, "^\S{1,64}$")
                SingleRules[letter] := Decode(SubStr(line, equals + 1))
        }
    }
}
; Older versions ignore these sections, so going back a version keeps the
; other entries working.
try {
    section := IniRead(SettingsFile, "Suffixes",, "")
    if section = ""
        section := "e=ed`ni=ing`ns=s`nr=er`nl=ly"
    for line in StrSplit(section, "`n", "`r") {
        equals := InStr(line, "=")
        if equals && SubStr(line, 1, equals - 1) != "_saved" {
            keys := Normalise(DecodeKey(SubStr(line, 1, equals - 1)), 1, 7)
            ending := StrLower(Decode(SubStr(line, equals + 1)))
            if keys != "" && !InStr(keys, SuffixKey) && RegExMatch(ending, "^[a-z]{1,15}$")
                SuffixEntries[keys] := ending
        }
    }
}
BuildSuffixes()
try {
    for line in StrSplit(IniRead(SettingsFile, "NoSpace",, ""), "`n", "`r") {
        equals := InStr(line, "=")
        if equals
            NoSpace[DecodeKey(SubStr(line, 1, equals - 1))] := true
    }
}
try {
    for line in StrSplit(IniRead(SettingsFile, "Forms",, ""), "`n", "`r") {
        equals := InStr(line, "=")
        if equals
            SavedForms[DecodeKey(SubStr(line, 1, equals - 1))] := ParseForms(Decode(SubStr(line, equals + 1)))
    }
}
Engine := ChordEngine(Rules, WindowMs, Suffixes)
Engine.SpaceWindow := SpaceWindowMs
After := AfterExpansion()
Paused := false
; Characters typed since the last space. Dirty means the text before them
; is unknown, so they cannot be matched as a whole word.
Word := ""
Dirty := false
; What was typed lately, as far as PhraseKey can be sure of it, for suffix
; chords on typed words.
Recent := ""
; An abbreviation whose Space may be the start of a Space suffix chord: it
; expands when that Space is let go. Typed is what came after the Space.
Pending := {Abbreviation: "", Typed: ""}
Target := 0
RelayWatch := {Until: 0, Seen: 0, Told: false}

EditorGui := 0
OptionsGui := 0
EditingId := ""
OwnPid := DllCall("GetCurrentProcessId", "UInt")

UpdateBusy := false
UpdateWindow := 0

Main := Gui(, "PhraseKey " AppVersion)
Main.SetFont("s11", "Segoe UI")
Main.AddText("w640", "Saved &entries:")
ChordList := Main.AddListBox("xm w640 r12")
ChordList.OnEvent("DoubleClick", (*) => EditSelected())
Main.AddButton("xm w120", "&Add").OnEvent("Click", (*) => OpenEditor())
Main.AddButton("x+10 w120", "E&dit").OnEvent("Click", (*) => EditSelected())
Main.AddButton("x+10 w120", "&Remove").OnEvent("Click", RemoveSelected)
Main.AddButton("x+10 w120", "&Hide").OnEvent("Click", (*) => Main.Hide())
Main.AddButton("x+10 w120", "E&xit").OnEvent("Click", (*) => ExitApp())
Main.AddButton("xm w200", "&Keyboard shortcuts").OnEvent("Click", ShowShortcuts)
Main.AddButton("x+10 w200", "Check for &updates").OnEvent("Click", (*) => CheckForUpdate(true))
Main.AddButton("xm w200", "&Options").OnEvent("Click", OpenOptions)
Main.AddButton("x+10 w200", "A&bout").OnEvent("Click", ShowAbout)
SoundBox := Main.AddCheckbox("xm" (PlayTick ? " Checked" : ""), "&Play sound on text replacement")
SoundBox.OnEvent("Click", SoundToggled)
UpdateBox := Main.AddCheckbox("xm" (CheckUpdates ? " Checked" : ""), "&Check for updates when PhraseKey starts")
UpdateBox.OnEvent("Click", UpdateToggled)
Main.OnEvent("Close", (*) => ExitApp())
A_TrayMenu.Delete()
A_TrayMenu.Add("Open entries", ShowMain)
A_TrayMenu.Add("Pause expansion", TogglePause)
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Default := "Open entries"
A_IconTip := "PhraseKey: active"
RefreshList()

; Every key reaches the application untouched. The tracker only watches, and
; a recognised chord or abbreviation is erased and replaced afterwards, so
; ordinary typing is never delayed, reordered or re-sent. "I1" makes it
; ignore the replacement text this script sends.
Tracker := InputHook("V I1 L0")
Tracker.KeyOpt("{All}", "N")
Tracker.OnKeyDown := KeyDown
Tracker.OnKeyUp := KeyUp
Tracker.OnChar := CharTyped
Tracker.Start()
for key in ["LButton", "RButton", "MButton"]
    Hotkey "~*" key, (*) => ClearTyping()
Hotkey "^!F11", ShowMain
Hotkey "^!F12", (*) => ExitApp()
Hotkey "^!F10", ExplainLastChord
Main.Show()
ChordList.Focus()
ShowNvdaWarning()
if A_IsCompiled {
    ; Left behind by an update; the old copy may still be closing.
    try FileDelete A_ScriptFullPath ".old"
    SetTimer () => FileExist(A_ScriptFullPath ".old") && FileDelete(A_ScriptFullPath ".old"), -10000
}
if CheckUpdates
    SetTimer () => CheckForUpdate(false), -5000

; False while paused or while one of this program's own windows is active.
Tracking() {
    global Paused, OwnPid, Target
    try {
        if !Paused && WinGetPID("A") != OwnPid {
            now := WinExist("A")
            if now != Target {
                ClearTyping()
                Target := now
            }
            return true
        }
    }
    ClearTyping()
    return false
}
ClearTyping() {
    global Engine, Word, Dirty, After, Recent, Pending
    Engine.Break()
    After.Clear()
    Pending := {Abbreviation: "", Typed: ""}
    Word := ""
    Dirty := false
    Recent := ""
}
; Leave conventional Windows password edit controls alone.
PasswordField() {
    try {
        hwnd := ControlGetFocus("A")
        return hwnd && InStr(WinGetClass("ahk_id " hwnd), "Edit")
            && (ControlGetStyle(hwnd) & 0x20)
    }
    return false
}
; The name of a modifier or screen reader key held down, or "". The hook's
; record of a key stays down if its release is missed, as when a screen
; reader takes the release for itself, which would block every chord until
; PhraseKey restarts; so Windows must agree that the key is down.
ShortcutHeld() {
    for key in ["Ctrl", "Alt", "LWin", "RWin", "Insert", "NumpadIns", "CapsLock"]
        if GetKeyState(key, "P") && DllCall("GetAsyncKeyState", "Int", GetKeyVK(key), "Short") < 0
            return key
    return ""
}
; The unshifted character of a key that can take part in a chord, or "".
ChordKey(vk) {
    global SuffixKey
    static names := Map()
    if vk = 0x20
        return SuffixKey = " " ? " " : ""
    if !names.Has(vk) {
        name := ""
        if (vk >= 0x30 && vk <= 0x39) || (vk >= 0x41 && vk <= 0x5A) || (vk >= 0xBA && vk <= 0xC0)
            || (vk >= 0xDB && vk <= 0xDF) || vk = 0xE2
            name := StrLower(GetKeyName(Format("vk{:02X}", vk)))
        names[vk] := StrLen(name) = 1 ? name : ""
    }
    return names[vk]
}
IsTextKey(vk) {
    return (vk >= 0x30 && vk <= 0x5A) || vk = 0x20 || (vk >= 0x60 && vk <= 0x6F)
        || (vk >= 0xBA && vk <= 0xC0) || (vk >= 0xDB && vk <= 0xDF)
        || vk = 0xE2 || vk = 0xE7
}
; Milliseconds, to a fraction: chord limits are finer than A_TickCount's
; steps of about 16 ms.
Now() {
    static frequency := 0
    if !frequency
        DllCall("QueryPerformanceFrequency", "Int64*", &frequency)
    DllCall("QueryPerformanceCounter", "Int64*", &count := 0)
    return count * 1000 / frequency
}
; Whether an entry types a space after its replacement.
WantsSpace(id) {
    global TrailingSpace, NoSpace
    return TrailingSpace && !NoSpace.Has(id)
}
; Erases eraseCount characters and types text. A replacement from a saved
; entry is followed by a space if the entry has one; an edit made after a
; replacement brings its own.
Replace(eraseCount, text, space := false, edit := false) {
    global PlayTick, RelayWatch, After, Word, Dirty, Recent, Engine
    started := Now()
    ; One SendInput batch, so keys typed meanwhile cannot land in the middle.
    ; Text mode does not depend on the keyboard layout, Shift or Caps Lock.
    SendInput "{Backspace " eraseCount "}{Text}" text (space ? " " : "")
    ; Keys pressed while this was typing are timed late; a chord under way,
    ; such as one whose Space just expanded an abbreviation, must not be
    ; charged for that.
    if Engine.Held.Count
        Engine.Start += Now() - started
    if !edit
        After.Expanded(text, space)
    ; Unless it ends with a space, the text runs into whatever comes next.
    Word := ""
    Dirty := !space && SubStr(text, -1) != " "
    Recent := ""
    if !RelayWatch.Told && ProcessExist("nvda.exe")
        RelayWatch.Until := A_TickCount + 600, RelayWatch.Seen := 0
    if PlayTick
        Tick()
}
; A quiet click of about 8 ms, built in memory so no sound file is needed.
Tick() {
    static wave := MakeTick()
    ; SND_ASYNC | SND_NODEFAULT | SND_MEMORY
    return DllCall("winmm\PlaySoundW", "Ptr", wave, "Ptr", 0, "UInt", 0x7)
}
MakeTick() {
    rate := 22050
    samples := 180
    wave := Buffer(44 + samples * 2, 0)
    StrPut("RIFF", wave, 4, "CP0")
    NumPut("UInt", 36 + samples * 2, wave, 4)
    StrPut("WAVEfmt ", wave.Ptr + 8, 8, "CP0")
    ; PCM, mono, 16-bit
    NumPut("UInt", 16, "UShort", 1, "UShort", 1, "UInt", rate, "UInt", rate * 2, "UShort", 2, "UShort", 16, wave, 16)
    StrPut("data", wave.Ptr + 36, 4, "CP0")
    NumPut("UInt", samples * 2, wave, 40)
    Loop samples {
        i := A_Index - 1
        ; 1800 Hz, fading out quickly, at about an eighth of full volume.
        NumPut("Short", Round(4000 * Exp(-i / 40) * Sin(2 * 3.14159265 * 1800 * i / rate)), wave, 44 + i * 2)
    }
    return wave
}
ShowShortcuts(*) {
    global Main
    help := Gui("+Owner" Main.Hwnd, "PhraseKey keyboard shortcuts")
    help.SetFont("s11", "Segoe UI")
    ; A read-only edit takes the focus, so a screen reader reads the text.
    help.AddEdit("w520 r32 ReadOnly",
        "Expansion stays active while the PhraseKey window is hidden.`n`n"
        . "From anywhere:`n"
        . "Ctrl+Alt+F11: bring the PhraseKey window back`n"
        . "Ctrl+Alt+F12: exit PhraseKey`n"
        . "Ctrl+Alt+F10: explain the last chord attempt`n`n"
        . "In the PhraseKey window:`n"
        . "Alt+E: saved entries list`n"
        . "Alt+A: add`n"
        . "Alt+D: edit`n"
        . "Alt+R: remove`n"
        . "Alt+H: hide`n"
        . "Alt+X: exit`n"
        . "Alt+K: keyboard shortcuts`n"
        . "Alt+U: check for updates`n"
        . "Alt+O: options`n"
        . "Alt+B: about PhraseKey`n"
        . "Alt+P: play sound on text replacement`n"
        . "Alt+C: check for updates when PhraseKey starts`n`n"
        . "In the Options window:`n"
        . "Alt+K: suffix key`n"
        . "Alt+W: suffix chords also work on words I type`n"
        . "Alt+B: abbreviations also expand when followed by punctuation`n"
        . "Alt+S: add a space after punctuation that follows a replacement`n"
        . "Alt+C: chord timing`n"
        . "Alt+T: Space chord timing`n"
        . "Alt+F: open the folder where your entries are saved`n`n"
        . "In the Add or Edit dialog:`n"
        . "Alt+B: abbreviation`n"
        . "Alt+H: chord`n"
        . "Alt+T: treat as suffix`n"
        . "Alt+K: keys`n"
        . "Alt+R: replacement text`n"
        . "Alt+P: add a space after the replacement`n"
        . "Alt+O: word forms`n"
        . "Alt+S: save`n"
        . "Escape: cancel")
    help.AddButton("xm w120 Default", "&Close").OnEvent("Click", (*) => help.Destroy())
    help.OnEvent("Close", (*) => help.Destroy())
    help.OnEvent("Escape", (*) => help.Destroy())
    help.Show()
}
SoundToggled(*) {
    global PlayTick, SoundBox
    PlayTick := SoundBox.Value
    if PlayTick
        Tick()
    Persist()
}
; Says why the most recent set of keys did or did not make a chord. Typing
; anything else first replaces it, so press this straight after the attempt.
ExplainLastChord(*) {
    global Engine
    last := Engine.Last
    if last.Keys = "" {
        message := "No chord has been attempted since PhraseKey started."
    } else {
        keys := StrLen(last.Keys)
        message := "Last attempt: " DisplayChord(last.Keys) ", " keys (keys = 1 ? " key" : " keys")
        if keys > 1
            message .= ", pressed over " last.Span " ms"
        message .= ".`n" (last.Expanded ? "It was replaced." : "Not replaced: " last.Reason ".")
    }
    report := Gui(, "PhraseKey: last chord")
    report.SetFont("s11", "Segoe UI")
    ; A read-only edit takes the focus, so a screen reader reads the message.
    report.AddEdit("w560 r4 ReadOnly", message)
    report.AddButton("xm w120 Default", "OK").OnEvent("Click", (*) => report.Destroy())
    report.OnEvent("Close", (*) => report.Destroy())
    report.OnEvent("Escape", (*) => report.Destroy())
    report.Show()
}
UpdateToggled(*) {
    global CheckUpdates, UpdateBox
    CheckUpdates := UpdateBox.Value
    Persist()
}
; Asks GitHub for the latest release. A check made at startup stays silent
; unless there is a version the user has not chosen to skip.
CheckForUpdate(manual) {
    global UpdateBusy
    if UpdateBusy {
        if manual
            MsgBox "An update check or download is already in progress.", "PhraseKey updates"
        return
    }
    UpdateBusy := true
    checked(request) {
        global UpdateBusy, SkippedVersion
        UpdateBusy := false
        release := 0
        try release := request ? ParseRelease(request.ResponseText) : 0
        if !release {
            if manual
                MsgBox "Could not check for updates. Please check your internet connection.", "PhraseKey updates", "Iconx"
            return
        }
        if CompareVersions(release.Version, AppVersion) <= 0 {
            if manual
                MsgBox "You are using the latest version, " AppVersion ".", "PhraseKey updates", "Iconi"
            return
        }
        if !manual && release.Version = SkippedVersion
            return
        OfferUpdate(release)
    }
    HttpGet(UpdateApi, "PhraseKey/" AppVersion, checked)
}
; Update windows have no owner, so they get a taskbar button even while the
; PhraseKey window is hidden.
OfferUpdate(release) {
    global UpdateWindow
    if IsObject(UpdateWindow)
        return
    UpdateWindow := Gui(, "PhraseKey update available")
    UpdateWindow.SetFont("s11", "Segoe UI")
    how := A_IsCompiled && release.Url != "" && release.Sha256 != ""
        ? "PhraseKey will download it, then restart. Your entries and settings are kept."
        : "Update now opens the download page."
    ; A read-only edit takes the focus, so a screen reader reads the message.
    UpdateWindow.AddEdit("w520 r3 ReadOnly", "PhraseKey " release.Version " is available. You are using " AppVersion ".`n" how)
    skip := UpdateWindow.AddCheckbox("xm", "&Skip this version")
    answer(update, *) {
        global UpdateWindow, SkippedVersion
        if !update && skip.Value {
            SkippedVersion := release.Version
            Persist()
        }
        UpdateWindow.Destroy()
        UpdateWindow := 0
        if update
            DownloadUpdate(release)
    }
    UpdateWindow.AddButton("xm w140 Default", "&Update now").OnEvent("Click", answer.Bind(true))
    UpdateWindow.AddButton("x+10 w140", "&Not now").OnEvent("Click", answer.Bind(false))
    UpdateWindow.OnEvent("Close", answer.Bind(false))
    UpdateWindow.OnEvent("Escape", answer.Bind(false))
    UpdateWindow.Show()
}
DownloadUpdate(release) {
    global UpdateBusy, UpdateWindow
    ; Only the compiled program can replace itself, and only with a download
    ; whose checksum GitHub published.
    if !A_IsCompiled || release.Url = "" || release.Sha256 = "" {
        Run UpdatePage
        return
    }
    UpdateBusy := true
    UpdateWindow := Gui(, "PhraseKey update")
    UpdateWindow.SetFont("s11", "Segoe UI")
    UpdateWindow.AddEdit("w520 r2 ReadOnly", "Downloading PhraseKey " release.Version ". PhraseKey will restart when it is ready.")
    UpdateWindow.Show()
    downloaded(request) {
        global UpdateBusy, UpdateWindow
        zip := A_Temp "\PhraseKey-" release.Version "-win64.zip"
        try {
            if !request
                throw Error("The download failed. Please check your internet connection.")
            SaveResponse(request, zip)
            if FileSha256(zip) != release.Sha256
                throw Error("The download did not match its published checksum, so it was not installed.")
            ApplyUpdate(zip, A_ScriptFullPath)
        } catch as err {
            try FileDelete zip
            UpdateBusy := false
            UpdateWindow.Destroy()
            UpdateWindow := 0
            if MsgBox("PhraseKey could not update itself. " err.Message "`n`nOpen the download page instead?", "PhraseKey update", "YesNo Iconx") = "Yes"
                Run UpdatePage
            return
        }
        Run '"' A_ScriptFullPath '"'
        ExitApp
    }
    HttpGet(release.Url, "PhraseKey/" AppVersion, downloaded)
}
; NVDA by default takes over simulated keys once a Backspace is sent and
; scrambles or drops what follows. Its documented remedy is a setting, which
; cannot be read reliably: NVDA saves its configuration only now and then.
ShowNvdaWarning(relayed := false) {
    global NvdaWarning, Main
    if !NvdaWarning || !ProcessExist("nvda.exe")
        return
    message := "PhraseKey will only work properly when Handle keys from other applications is unchecked within NVDA's Keyboard settings."
    if relayed
        message := "NVDA is intercepting the text PhraseKey types, so that replacement was probably scrambled or lost.`n`n" message
    warning := Gui("+Owner" Main.Hwnd, "PhraseKey: NVDA setting")
    warning.SetFont("s11", "Segoe UI")
    ; A read-only edit takes the focus, so a screen reader reads the message.
    warning.AddEdit("w560 r" (relayed ? 5 : 2) " ReadOnly", message)
    again := warning.AddCheckbox("xm", "&Don't show this again")
    close(*) {
        global NvdaWarning
        if again.Value {
            NvdaWarning := false
            Persist()
        }
        warning.Destroy()
    }
    warning.AddButton("xm w120 Default", "OK").OnEvent("Click", close)
    warning.OnEvent("Close", close)
    warning.OnEvent("Escape", close)
    warning.Show()
}
; PhraseKey's own Backspaces are invisible to the tracker. If they show up
; just after a replacement, NVDA has taken them over and is relaying them.
RelayedErase() {
    global RelayWatch
    if !IsObject(RelayWatch) || A_TickCount > RelayWatch.Until
        return false
    if ++RelayWatch.Seen = 2 && !RelayWatch.Told {
        RelayWatch.Told := true
        SetTimer () => ShowNvdaWarning(true), -1
    }
    return true
}
KeyDown(hook, vk, sc) {
    global Engine, Word, Dirty, After, Recent, Pending
    Critical
    if vk = 0x10 || vk = 0xA0 || vk = 0xA1    ; Shift
        return
    if !Tracking()
        return
    ; Ctrl, Alt, Win, Caps Lock
    if vk = 0x11 || vk = 0x12 || vk = 0x14 || vk = 0x5B || vk = 0x5C || (vk >= 0xA2 && vk <= 0xA5) {
        Engine.Break()
        return
    }
    if ShortcutHeld() {
        ClearTyping()
        return
    }
    if (key := ChordKey(vk)) != "" {
        for held in Engine.Held.Clone()
            if !GetKeyState(Format("vk{:02X}", GetKeyVK(held)))
                Engine.Forget(held)
        Engine.Down(key, Now())
        return
    }
    Engine.Break()
    if vk = 0x08 {
        if RelayedErase()
            return
        ; JAWS re-sends a typed Backspace, so it arrives twice at once.
        ; Auto-repeat is never faster than about 30 ms.
        static lastErase := 0
        duplicate := A_TickCount - lastErase < 25
        lastErase := A_TickCount
        if duplicate
            return
        After.Clear()
        Pending := {Abbreviation: "", Typed: ""}
        if Word = ""
            Dirty := true
        else
            Word := SubStr(Word, 1, -1)
        Recent := SubStr(Recent, 1, -1)
    } else if !IsTextKey(vk) {
        ; Navigation, Enter, Tab, Escape and so on start a new word.
        Word := ""
        Dirty := false
        Recent := ""
        After.Clear()
        Pending := {Abbreviation: "", Typed: ""}
    }
}
KeyUp(hook, vk, sc) {
    global Engine, After, SavedForms, SuffixOnTyped, Recent, Pending
    Critical
    if (key := ChordKey(vk)) = ""
        return
    active := Tracking()
    text := Engine.Up(key, Now())
    if Engine.Held.Count
        return
    if Pending.Abbreviation != "" {
        ExpandPending(active && Engine.Last.Suffix && !ShortcutHeld() && !PasswordField() ? text : "")
        return
    }
    if text = "" || !active || (held := ShortcutHeld()) || PasswordField() {
        if text != "" {
            Engine.Last.Expanded := false
            Engine.Last.Reason := !active ? "PhraseKey is paused or its own window is active"
                : held != "" ? held " was held down when the keys were released"
                : "the cursor is in a password field"
        }
        ; Typing, not a chord: punctuation it typed may still need its space removed.
        if active
            FixPunctuation()
        return
    }
    if !Engine.Last.Suffix {
        Replace(Engine.Chars, text, WantsSpace("chord:" Engine.Last.Keys))
        return
    }
    edit := After.Suffix(text, Engine.Chars, SavedForms)
    if edit {
        Replace(edit.Erase, edit.Text, false, true)
        return
    }
    if SuffixOnTyped && (edit := TypedSuffix(Recent, Engine.Chars, text, SavedForms)) {
        Replace(edit.Erase, edit.Text, false, true)
        ; Another suffix chord, or punctuation, can follow.
        After.Expanded(edit.Word, true)
        return
    }
    ; Its keys stay as typed.
    Engine.Last.Expanded := false
    Engine.Last.Reason := SuffixOnTyped
        ? "a suffix chord only works straight after a word, typed or replaced, with nothing else typed in between"
        : "a suffix chord only works straight after a chord or abbreviation that typed one word"
}
; Expands an abbreviation held back by a Space that might have started a
; suffix chord. ending is the chord's ending if it was one, else "".
ExpandPending(ending) {
    global Pending, SingleRules, SavedForms, Engine, After, Word, Dirty
    abbreviation := Pending.Abbreviation
    typed := Pending.Typed
    Pending := {Abbreviation: "", Typed: ""}
    if !SingleRules.Has(abbreviation)
        return
    replacement := SingleRules[abbreviation]
    space := WantsSpace("single:" abbreviation)
    ; hpy, then Space and N together: the Space and the N are the chord.
    if ending != "" && IsOneWord(replacement) && StrLen(typed) = Engine.Chars - 1 {
        Replace(StrLen(abbreviation) + Engine.Chars, AddSuffix(replacement, ending, SavedForms), true)
        return
    }
    ; Typing: expand as the Space would have, keeping what came after it.
    Replace(StrLen(abbreviation) + 1 + StrLen(typed), replacement (space ? " " : "") typed, false, true)
    After.Clear()
    if !InStr(typed, " ") {
        Word := typed
        Dirty := !space
    }
}
; Replaces the space PhraseKey added with the punctuation typed after it.
FixPunctuation() {
    global Engine, After, SpaceAfterPunctuation
    if edit := After.Punctuate(Engine.MayComplete(), SpaceAfterPunctuation)
        Replace(edit.Erase, edit.Text, false, true)
}
CharTyped(hook, char) {
    global Word, Dirty, SingleRules, After, Recent, Engine, PunctuationExpands, SpaceAfterPunctuation, Pending
    Critical
    if !Tracking() || ShortcutHeld()
        return
    Loop Parse char {
        After.Add(A_LoopField)
        Recent := SubStr(Recent A_LoopField, -40)
        if Pending.Abbreviation != ""
            Pending.Typed .= A_LoopField
        FixPunctuation()
        if A_LoopField = " " {
            abbreviation := FindAbbreviation()
            Word := ""
            Dirty := false
            if abbreviation != "" && !PasswordField() {
                ; With Space as the suffix key, this Space may be the start of
                ; a suffix chord. Expanding now would delay the chord's other
                ; keys and spoil its timing, so wait until Space is let go.
                if Engine.MayComplete()
                    Pending := {Abbreviation: abbreviation, Typed: ""}
                else
                    Replace(StrLen(abbreviation) + 1, SingleRules[abbreviation], WantsSpace("single:" abbreviation))
            }
        } else if PunctuationExpands && InStr(".,;:!?)", A_LoopField) && !Engine.MayComplete()
                && (abbreviation := FindAbbreviation()) != "" && !PasswordField() {
            ; brb. gives "be right back." Not while a chord using this key
            ; may be under way: it would erase what it typed.
            Replace(StrLen(abbreviation) + 1, SingleRules[abbreviation] A_LoopField (SpaceAfterPunctuation ? " " : ""), false, true)
        } else if RegExMatch(A_LoopField, "^[^\s[:cntrl:]]$") {
            Word .= A_LoopField
            ; Keep only as much as the longest abbreviation could need.
            if StrLen(Word) > 130
                Word := SubStr(Word, -65)
        } else {
            ; Enter, Tab and other control characters start afresh.
            Word := ""
            Dirty := false
            Recent := ""
        }
    }
}
; The longest abbreviation that ends what was typed since the last space.
; Input is case-insensitive. One that starts with a letter or digit must be
; a whole word (addr does not expand in xaddr, but does in "(addr"); one
; that starts with punctuation, such as $sig, expands after anything.
FindAbbreviation() {
    global Word, Dirty, SingleRules
    typed := StrLower(Word)
    best := ""
    for abbreviation in SingleRules {
        length := StrLen(abbreviation)
        if length <= StrLen(best) || length > StrLen(typed) || SubStr(typed, -length) !== abbreviation
            continue
        if RegExMatch(abbreviation, "^[\p{L}\p{N}]") {
            if length = StrLen(typed) ? Dirty : RegExMatch(SubStr(typed, -length - 1, 1), "[\p{L}\p{N}]")
                continue
        }
        best := abbreviation
    }
    return best
}
ShowMain(*) {
    global Main, ChordList, EditorGui, ChordEdit
    if IsObject(EditorGui) {
        EditorGui.Show()
        WinActivate "ahk_id " EditorGui.Hwnd
        ChordEdit.Focus()
        return
    }
    Main.Show()
    WinActivate "ahk_id " Main.Hwnd
    ChordList.Focus()
}
TogglePause(*) {
    global Paused, Engine
    ClearTyping()
    Paused := !Paused
    A_IconTip := Paused ? "PhraseKey: paused" : "PhraseKey: active"
    if Paused
        A_TrayMenu.Check("Pause expansion")
    else
        A_TrayMenu.Uncheck("Pause expansion")
}
RefreshList(select := "") {
    global ChordList, RuleKeys, Rules, SingleRules, SuffixEntries, SuffixKey, NoSpace
    ChordList.Delete()
    entries := []
    for key, value in SingleRules
        entries.Push(["single:" key, "Abbreviation " key " = " OneLine(value)])
    for chord, value in Rules
        entries.Push(["chord:" chord, "Chord " DisplayChord(chord) " = " OneLine(value)])
    for keys, ending in SuffixEntries
        entries.Push(["suffix:" keys, "Suffix chord " DisplayChord(keys) " " ShortKeyName(SuffixKey) " adds " ending])
    RuleKeys := []
    labels := []
    for entry in entries {
        RuleKeys.Push(entry[1])
        labels.Push(entry[2] (NoSpace.Has(entry[1]) ? ", no space after" : ""))
    }
    ChordList.Add(labels)
    for index, id in RuleKeys
        if id = select
            ChordList.Choose(index)
}
OneLine(text) => StrReplace(StrReplace(text, "`r", ""), "`n", " / ")
EditSelected() {
    global ChordList, RuleKeys
    if ChordList.Value
        OpenEditor(RuleKeys[ChordList.Value])
}
OpenEditor(id := "") {
    global
    EditingId := id
    EditorGui := Gui("+Owner" Main.Hwnd, id = "" ? "Add entry" : "Edit entry")
    EditorGui.SetFont("s11", "Segoe UI")
    EditorGui.AddText("w580", "Entry type:")
    SingleRadio := EditorGui.AddRadio("xm Group Checked", "A&bbreviation")
    ChordRadio := EditorGui.AddRadio("x+20", "C&hord (press together)")
    SingleRadio.OnEvent("Click", ModeChanged)
    ChordRadio.OnEvent("Click", ModeChanged)
    SuffixBox := EditorGui.AddCheckbox("xm", "&Treat as suffix: adds an ending, such as ing, to the word just before it")
    SuffixBox.OnEvent("Click", ModeChanged)
    TriggerLabel := EditorGui.AddText("xm w580")
    ChordEdit := EditorGui.AddEdit("xm w580")
    ReplacementLabel := EditorGui.AddText("xm w580")
    ReplacementEdit := EditorGui.AddEdit("xm w580 r5 WantReturn")
    ReplacementEdit.OnEvent("Change", (*) => ShowForms())
    SpaceBox := EditorGui.AddCheckbox("xm Checked", "Add a s&pace after the replacement")
    FormsLabel := EditorGui.AddText("xm w580", "Word f&orms: what your suffix chords make of this word, one per line, such as ing: running. Only real English words are listed. Correct any that are wrong, or add a missing one:")
    FormsEdit := EditorGui.AddEdit("xm w580 r5 WantReturn")
    FormsShown := ""
    EditorGui.AddButton("xm w120 Default", "&Save").OnEvent("Click", SaveEntry)
    EditorGui.AddButton("x+10 w120", "&Cancel").OnEvent("Click", CloseEditor)
    EditorGui.OnEvent("Close", CloseEditor)
    EditorGui.OnEvent("Escape", CloseEditor)
    if id != "" {
        parts := StrSplit(id, ":",, 2)
        kind := parts[1]
        SingleRadio.Value := kind = "single"
        ChordRadio.Value := kind != "single"
        SuffixBox.Value := kind = "suffix"
        ChordEdit.Value := kind = "single" ? parts[2] : kind = "suffix" ? DisplayChord(parts[2]) " " ShortKeyName(SuffixKey) : DisplayChord(parts[2])
        ReplacementEdit.Value := kind = "single" ? SingleRules[parts[2]] : kind = "suffix" ? SuffixEntries[parts[2]] : Rules[parts[2]]
        SpaceBox.Value := !NoSpace.Has(id)
    }
    ModeChanged()
    Main.Opt("+Disabled")
    EditorGui.Show()
    ; A new entry starts with its type; editing goes straight to the keys.
    if id = ""
        SingleRadio.Focus()
    else
        ChordEdit.Focus()
}
CloseEditor(*) {
    global Main, EditorGui, ChordList
    Main.Opt("-Disabled")
    if IsObject(EditorGui)
        EditorGui.Destroy()
    EditorGui := 0
    Main.Show()
    ChordList.Focus()
}
ModeChanged(*) {
    global SingleRadio, ChordRadio, SuffixBox, TriggerLabel, ReplacementLabel, SpaceBox, SuffixKey
    suffix := ChordRadio.Value && SuffixBox.Value
    SuffixBox.Visible := ChordRadio.Value
    TriggerLabel.Text := SingleRadio.Value ? "&Keys (abbreviation, such as addr or $sig):"
        : suffix ? "&Keys (1 to 7 keys, such as i for ing; the suffix key, " KeyName(SuffixKey) ", is added for you):"
        : "&Keys (2 to 8 different keys, such as t h e or a s `;):"
    ReplacementLabel.Text := suffix ? "&Replacement: the ending to add, such as ing or ness:" : "&Replacement text:"
    SpaceBox.Visible := !suffix
    ShowForms()
}
; For a replacement of one word, lists what each suffix chord makes of it,
; leaving out endings that make no English word, such as happying.
ShowForms() {
    global ChordRadio, SuffixBox, ReplacementEdit, FormsLabel, FormsEdit, FormsShown, SuffixEntries, SavedForms
    word := Trim(ReplacementEdit.Value)
    show := !(ChordRadio.Value && SuffixBox.Value) && SuffixEntries.Count && RegExMatch(word, "^\p{L}[\p{L}'-]*$")
    FormsLabel.Visible := show
    FormsEdit.Visible := show
    ; Keep anything the user has typed there.
    if !show || !FormsUnchanged()
        return
    endings := Map()
    text := ""
    lower := StrLower(word)
    for keys, ending in SuffixEntries {
        if endings.Has(ending)
            continue
        endings[ending] := true
        form := AddSuffix(word, ending, SavedForms)
        if KnownWord(form) || SavedForms.Has(lower) && SavedForms[lower].Has(ending)
            text .= (text = "" ? "" : "`n") ending ": " form
    }
    FormsEdit.Value := FormsShown := text
}
; The edit control may store line breaks differently.
FormsUnchanged() {
    global FormsEdit, FormsShown
    return StrReplace(FormsEdit.Value, "`r") == StrReplace(FormsShown, "`r")
}
SaveEntry(*) {
    global
    singleMode := SingleRadio.Value = 1
    suffixMode := !singleMode && SuffixBox.Value = 1
    if singleMode
        key := StrLower(Trim(ChordEdit.Value))
    else if suffixMode
        key := Normalise(StrReplace(RegExReplace(ChordEdit.Value, "i)\bspace\b"), SuffixKey), 1, 7)
    else {
        ; The letters of "space" would otherwise make a five-key chord.
        if RegExMatch(ChordEdit.Value, "i)\bspace\b") {
            MsgBox "Space can only be part of a suffix chord. To use it, check Treat as suffix.", "Check keys"
            ChordEdit.Focus()
            return
        }
        key := Normalise(ChordEdit.Value)
    }
    if (singleMode && !RegExMatch(key, "^\S{1,40}$")) || (!singleMode && key = "") {
        MsgBox singleMode ? "Enter 1 to 40 characters with no spaces, such as addr, t or $sig."
            : suffixMode ? "Enter one to seven different keys besides the suffix key, " KeyName(SuffixKey) ": letters, digits or punctuation keys as typed without Shift, such as i."
            : "Enter two to eight different keys: letters, digits or punctuation keys as typed without Shift, such as t h e or a s `; (4 rather than $).", "Check keys"
        ChordEdit.Focus()
        return
    }
    replacement := suffixMode ? StrLower(Trim(ReplacementEdit.Value)) : ReplacementEdit.Value
    if suffixMode ? !RegExMatch(replacement, "^[a-z]{1,15}$") : Trim(replacement) = "" {
        MsgBox suffixMode ? "Enter the ending to add: 1 to 15 letters, such as ing or ness." : "Enter replacement text.", "Check text"
        ReplacementEdit.Focus()
        return
    }
    id := (singleMode ? "single:" : suffixMode ? "suffix:" : "chord:") key
    if singleMode ? SingleRules.Has(key) && id != EditingId : ChordInUse(suffixMode ? SuffixChord(key) : key, EditingId) {
        MsgBox singleMode ? "That entry already exists. Select it in the list and choose Edit."
            : "Another chord or suffix chord already uses exactly these keys. Select it in the list and choose Edit.", "Duplicate entry"
        return
    }
    if EditingId != "" && EditingId != id
        DeleteEntry(EditingId)
    (singleMode ? SingleRules : suffixMode ? SuffixEntries : Rules)[key] := replacement
    if suffixMode || SpaceBox.Value {
        if NoSpace.Has(id)
            NoSpace.Delete(id)
    } else
        NoSpace[id] := true
    if FormsEdit.Visible && !FormsUnchanged()
        SaveForms(Trim(replacement), FormsEdit.Value)
    BuildSuffixes()
    ClearTyping()
    RefreshList(id)
    Persist()
    CloseEditor()
}
; True if a chord or suffix chord other than the one being edited uses
; exactly these keys.
ChordInUse(chord, editing) {
    global Rules, SuffixEntries
    if chord = ""
        return true
    if Rules.Has(chord) && "chord:" chord != editing
        return true
    for keys in SuffixEntries
        if SuffixChord(keys) = chord && "suffix:" keys != editing
            return true
    return false
}
DeleteEntry(id) {
    global SingleRules, Rules, SuffixEntries, NoSpace
    parts := StrSplit(id, ":",, 2)
    (parts[1] = "single" ? SingleRules : parts[1] = "suffix" ? SuffixEntries : Rules).Delete(parts[2])
    if NoSpace.Has(id)
        NoSpace.Delete(id)
}
; Keeps the forms typed in the editor that differ from what PhraseKey
; would make by itself.
SaveForms(word, text) {
    global SavedForms
    lower := StrLower(word)
    changed := Map()
    for ending, form in ParseForms(text)
        if form != AddSuffix(lower, ending)
            changed[ending] := form
    if changed.Count
        SavedForms[lower] := changed
    else if SavedForms.Has(lower)
        SavedForms.Delete(lower)
}
; "ing: running" or "ing=running", one or more, into Map("ing", "running").
ParseForms(text) {
    forms := Map()
    position := 1
    while position := RegExMatch(text, "([a-zA-Z]+)\s*[:=]\s*(\p{L}[\p{L}'-]*)", &match, position) {
        forms[StrLower(match[1])] := StrLower(match[2])
        position += match.Len
    }
    return forms
}
FormsText(forms) {
    text := ""
    for ending, form in forms
        text .= (text = "" ? "" : " ") ending "=" form
    return text
}
RemoveSelected(*) {
    global ChordList, RuleKeys
    if !ChordList.Value
        return
    if MsgBox("Remove this saved entry?", "PhraseKey", "YesNo") != "Yes"
        return
    DeleteEntry(RuleKeys[ChordList.Value])
    BuildSuffixes()
    ClearTyping()
    RefreshList()
    Persist()
}
; A suffix chord is its own keys plus the suffix key.
SuffixChord(keys, withKey := "") {
    global SuffixKey
    key := withKey = "" ? SuffixKey : withKey
    if key != " "
        return Normalise(keys key, 2, 8)
    ; Normalise drops spaces. Space sorts before every other key, as in
    ; ChordEngine.Signature.
    keys := Normalise(keys, 1, 7)
    return keys = "" ? "" : " " keys
}
; Fills Suffixes, which the chord engine reads, from SuffixEntries. Returns
; the suffix chords that cannot take that suffix key because another chord
; uses the same keys; with apply, they are left out.
BuildSuffixes(withKey := "", apply := true) {
    global Suffixes, SuffixEntries, Rules
    built := Map()
    clashes := []
    for keys, ending in SuffixEntries {
        chord := SuffixChord(keys, withKey)
        if chord = "" || Rules.Has(chord) || built.Has(chord)
            clashes.Push(keys)
        else
            built[chord] := ending
    }
    if apply {
        Suffixes.Clear()
        for chord, ending in built
            Suffixes[chord] := ending
    }
    return clashes
}
; Digit and punctuation keys that can be part of a chord.


; The keys that can be the suffix key, in the order offered.
SuffixKeyChoices() => [" ", ";", "/", "'"]
IsSuffixKey(key) {
    for choice in SuffixKeyChoices()
        if key == choice
            return true
    return false
}
KeyName(key) {
    static names := Map(" ", "Space", ";", "; (semicolon)", "/", "/ (slash)", "'", "' (apostrophe)")
    return names.Has(key) ? names[key] : key
}
ShortKeyName(key) => key = " " ? "Space" : key
OpenOptions(*) {
    global
    if IsObject(OptionsGui) {
        OptionsGui.Show()
        return
    }
    OptionsGui := Gui("+Owner" Main.Hwnd, "PhraseKey options")
    OptionsGui.SetFont("s10", "Segoe UI")
    ; Each explanation is part of its control's label, so a screen reader
    ; reads it along with the setting.
    OptionsGui.AddText("w860", "Suffix &key. A suffix chord is this key pressed together with a letter, and adds an ending to the word before it: walk, then Space and I together, gives walking. "
        . "Space is the easiest to press, but can go off when you type fast (see Space chord timing below). Semicolon, slash and apostrophe never go off by accident. "
        . "Changing it changes all your suffix chords.")
    names := []
    for choice in SuffixKeyChoices()
        names.Push(KeyName(choice))
    OptKey := OptionsGui.AddDropDownList("xm w200", names)
    for index, choice in SuffixKeyChoices()
        if choice == SuffixKey
            OptKey.Choose(index)
    OptTyped := OptionsGui.AddCheckbox("xm y+8 w860" (SuffixOnTyped ? " Checked" : ""),
        "Suffix chords also work on &words I type. Checked: type walk, then press a suffix chord, and get walking. "
        . "Unchecked: suffix chords only change a word that a chord or abbreviation typed. "
        . "Uncheck this if a program's autocorrect changes your words, as PhraseKey cannot see those changes.")
    OptExpand := OptionsGui.AddCheckbox("xm y+8 w860" (PunctuationExpands ? " Checked" : ""),
        "A&bbreviations also expand when followed by punctuation. Checked: with brb for be right back, typing brb followed by a full stop gives be right back followed by the full stop. "
        . "This works for full stop, comma, semicolon, colon, exclamation mark, question mark and closing bracket. "
        . "Unchecked: only Space expands an abbreviation.")
    OptSpace := OptionsGui.AddCheckbox("xm y+8 w860" (SpaceAfterPunctuation ? " Checked" : ""),
        "Add a &space after punctuation that follows a replacement. PhraseKey always removes the space it added when you type punctuation straight after, so like followed by a full stop gives like with the full stop. "
        . "Checked: PhraseKey also adds a space after the punctuation, ready for the next word. Unchecked: you type that space yourself, as usual.")
    OptionsGui.AddText("xm y+8 w860", "&Chord timing, in milliseconds, from 5 to 500. Normally 30. The keys of a chord of two or three keys must all go down within this time, which is how PhraseKey tells a chord from fast typing. "
        . "Lower it if chords go off while you are typing normally. Raise it if your chords often fail. "
        . "Chords of four or more keys have no time limit.")
    OptWindow := OptionsGui.AddEdit("xm w100 Number", WindowMs)
    OptionsGui.AddText("xm y+8 w860", "Space chord &timing, in milliseconds, from 5 to 500. Normally 20. The same, for chords that include Space. It is shorter because when you type fast, Space is often still down as the next word starts. "
        . "Lower it if Space chords go off while you type. Raise it if your Space chords often fail. "
        . "Pressing Ctrl+Alt+F10 straight after a chord tells you how far apart its keys went down.")
    OptSpaceWindow := OptionsGui.AddEdit("xm w100 Number", SpaceWindowMs)
    OptionsGui.AddText("xm y+8 w860", "Your entries and settings are saved in one file, settings.ini, in this folder: " SettingsPath ". "
        . "Copy that file to back them up or to move them to another computer. Close PhraseKey before replacing it.")
    OptionsGui.AddButton("xm w360", "Open the &folder where your entries are saved").OnEvent("Click", (*) => Run('explorer.exe "' SettingsPath '"'))
    OptionsGui.AddButton("xm y+8 w120 Default", "OK").OnEvent("Click", SaveOptions)
    OptionsGui.AddButton("x+10 w120", "Cancel").OnEvent("Click", CloseOptions)
    OptionsGui.OnEvent("Close", CloseOptions)
    OptionsGui.OnEvent("Escape", CloseOptions)
    OptionsGui.Show()
    OptKey.Focus()
}
CloseOptions(*) {
    global OptionsGui
    if IsObject(OptionsGui)
        OptionsGui.Destroy()
    OptionsGui := 0
}
SaveOptions(*) {
    global
    window := OptWindow.Value = "" ? 0 : Integer(OptWindow.Value)
    spaceWindow := OptSpaceWindow.Value = "" ? 0 : Integer(OptSpaceWindow.Value)
    if window < 5 || window > 500 {
        MsgBox "Enter a chord timing from 5 to 500.", "Check timing"
        OptWindow.Focus()
        return
    }
    if spaceWindow < 5 || spaceWindow > 500 {
        MsgBox "Enter a Space chord timing from 5 to 500.", "Check timing"
        OptSpaceWindow.Focus()
        return
    }
    key := SuffixKeyChoices()[OptKey.Value]
    if key != SuffixKey {
        clashes := BuildSuffixes(key, false)
        if clashes.Length {
            names := ""
            for keys in clashes
                names .= (names = "" ? "" : ", ") DisplayChord(keys)
            MsgBox "With " KeyName(key) " as the suffix key, these suffix chords would use the same keys as another chord: " names ". Change those first, or choose a different suffix key.", "Suffix key"
            OptKey.Focus()
            return
        }
    }
    SuffixKey := key
    SuffixOnTyped := OptTyped.Value
    PunctuationExpands := OptExpand.Value
    SpaceAfterPunctuation := OptSpace.Value
    WindowMs := window
    SpaceWindowMs := spaceWindow
    Engine.Window := WindowMs
    Engine.SpaceWindow := SpaceWindowMs
    BuildSuffixes()
    ClearTyping()
    RefreshList()
    Persist()
    CloseOptions()
}
ShowAbout(*) {
    global Main, AppVersion
    about := Gui("+Owner" Main.Hwnd, "About PhraseKey")
    about.SetFont("s11", "Segoe UI")
    ; A read-only edit takes the focus, so a screen reader reads the text.
    about.AddEdit("w620 r20 ReadOnly", "PhraseKey " AppVersion "`n"
        . "Copyright (c) 2026 Sam Taylor`n"
        . "https://github.com/sjtaylor82/PhraseKey`n`n"
        . "PhraseKey is free software, released under the MIT License, which is below.`n`n"
        . "PhraseKey is built with AutoHotkey, https://www.autohotkey.com, which is part of PhraseKey.exe. "
        . "AutoHotkey is licensed under the GNU General Public License, version 2. "
        . "Its source code is at https://github.com/AutoHotkey/AutoHotkey.`n`n"
        . "Word forms for suffix chords, and the list of English words they are checked against, come from "
        . "AGID and SCOWL by Kevin Atkinson, http://wordlist.aspell.net, whose notices are below.`n`n"
        . "MIT LICENSE`n`n" LicenceText() "`n`n"
        . "WORD LIST NOTICES`n`n" WordListNoticeText())
    about.AddButton("xm w120 Default", "&Close").OnEvent("Click", (*) => about.Destroy())
    about.OnEvent("Close", (*) => about.Destroy())
    about.OnEvent("Escape", (*) => about.Destroy())
    about.Show()
}

Normalise(text, fewest := 2, most := 8) {
    ; Keys may be separated by spaces or plus signs; + itself needs Shift,
    ; so it can never be a chord key.
    text := StrLower(RegExReplace(text, "[+\s]", ""))
    if StrLen(text) < fewest || StrLen(text) > most
        return ""
    keys := Map()
    for key in StrSplit(text) {
        ; Each must be what a chord key types without Shift.
        if keys.Has(key) || ChordKey(GetKeyVK(key)) !== key
            return ""
        keys[key] := true
    }
    ; A Map enumerates its keys in order, as ChordEngine.Signature relies on.
    result := ""
    for key in keys
        result .= key
    return result
}
DisplayChord(chord) {
    ; Display the familiar spelling for the default chord.
    if chord == "eht"
        return "T H E"
    shown := ""
    for key in StrSplit(StrUpper(chord))
        shown .= (key = " " ? "Space" : key) " "
    return RTrim(shown)
}
; Settings keys hold any character; an INI key cannot contain = ; or [.
EncodeKey(text) {
    result := ""
    Loop Parse text
        result .= RegExMatch(A_LoopField, "^[a-z0-9]$") ? A_LoopField : Format("%u{:04X}", Ord(A_LoopField))
    return result
}
DecodeKey(text) {
    result := ""
    position := 1
    while found := RegExMatch(text, "%u([0-9A-Fa-f]{4})", &match, position) {
        result .= SubStr(text, position, found - position) Chr("0x" match[1])
        position := found + 6
    }
    return result SubStr(text, position)
}
Encode(text) {
    text := StrReplace(text, "%", "%25")
    for pair in [["`r", "%0D"], ["`n", "%0A"], [" ", "%20"], ["`t", "%09"], [Chr(34), "%22"]]
        text := StrReplace(text, pair[1], pair[2])
    return text
}
Decode(text) {
    for pair in [["%0D", "`r"], ["%0A", "`n"], ["%20", " "], ["%09", "`t"], ["%22", Chr(34)]]
        text := StrReplace(text, pair[1], pair[2])
    return StrReplace(text, "%25", "%")
}
Persist() {
    global
    temp := SettingsFile ".tmp"
    try {
        if FileExist(temp)
            FileDelete temp
        IniWrite WindowMs, temp, "Options", "WindowMs"
        IniWrite SpaceWindowMs, temp, "Options", "SpaceWindowMs"
        IniWrite TrailingSpace ? 1 : 0, temp, "Options", "TrailingSpace"
        IniWrite PlayTick ? 1 : 0, temp, "Options", "PlaySound"
        IniWrite NvdaWarning ? 1 : 0, temp, "Options", "NvdaWarning"
        IniWrite CheckUpdates ? 1 : 0, temp, "Options", "CheckUpdates"
        IniWrite SkippedVersion, temp, "Options", "SkippedVersion"
        IniWrite SpaceAfterPunctuation ? 1 : 0, temp, "Options", "SpaceAfterPunctuation"
        IniWrite SuffixOnTyped ? 1 : 0, temp, "Options", "SuffixOnTypedWords"
        IniWrite PunctuationExpands ? 1 : 0, temp, "Options", "PunctuationExpands"
        IniWrite EncodeKey(SuffixKey), temp, "Options", "SuffixKey"
        ; Sentinel distinguishes an intentionally empty collection.
        IniWrite "1", temp, "Chords", "_saved"
        for chord, value in Rules
            IniWrite Encode(value), temp, "Chords", EncodeKey(chord)
        IniWrite "1", temp, "Strings", "_saved"
        for letter, value in SingleRules
            IniWrite Encode(value), temp, "Strings", EncodeKey(letter)
        IniWrite "1", temp, "Suffixes", "_saved"
        for keys, ending in SuffixEntries
            IniWrite Encode(ending), temp, "Suffixes", EncodeKey(keys)
        for id in NoSpace
            IniWrite "1", temp, "NoSpace", EncodeKey(id)
        for word, forms in SavedForms
            IniWrite Encode(FormsText(forms)), temp, "Forms", EncodeKey(word)
        FileMove temp, SettingsFile, 1
    } catch as err {
        MsgBox "Changes work for this session, but could not be saved: " err.Message, "Save failed"
    }
}
