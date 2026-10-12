#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ChordEngine.ahk

; Chords use letter, digit and punctuation keys; abbreviations any characters.
; Settings only are persisted. Typed text is never logged or saved.
SendMode "Event"
SetKeyDelay -1, -1
SetWorkingDir A_ScriptDir
Rules := Map("eht", "the")
SingleRules := Map()
SettingsPath := A_AppData "\PhraseKey"
DirCreate SettingsPath
SettingsFile := SettingsPath "\settings.ini"
WindowMs := 90
TrailingSpace := true
PlayTick := false
NvdaWarning := true
try {
    PlayTick := IniRead(SettingsFile, "Options", "PlaySound", "0") = "1"
    NvdaWarning := IniRead(SettingsFile, "Options", "NvdaWarning", "1") = "1"
}
try {
    WindowMs := Integer(IniRead(SettingsFile, "Options", "WindowMs", "90"))
    if WindowMs < 20 || WindowMs > 500
        WindowMs := 90
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
Engine := ChordEngine(Rules, WindowMs)
Paused := false
; Characters typed since the last space. Dirty means the text before them
; is unknown, so they cannot be matched as a whole word.
Word := ""
Dirty := false
Target := 0
RelayWatch := {Until: 0, Seen: 0, Told: false}

EditorGui := 0
EditingId := ""
OwnPid := DllCall("GetCurrentProcessId", "UInt")

Main := Gui(, "PhraseKey 0.8")
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
SoundBox := Main.AddCheckbox("xm" (PlayTick ? " Checked" : ""), "&Play sound on text replacement")
SoundBox.OnEvent("Click", SoundToggled)
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
Main.Show()
ChordList.Focus()
ShowNvdaWarning()

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
    global Engine, Word, Dirty
    Engine.Break()
    Word := ""
    Dirty := false
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
ShortcutHeld() {
    return GetKeyState("Ctrl", "P") || GetKeyState("Alt", "P")
        || GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
        || GetKeyState("Insert", "P") || GetKeyState("NumpadIns", "P")
        || GetKeyState("CapsLock", "P")
}
; The unshifted character of a key that can take part in a chord, or "".
ChordKey(vk) {
    static names := Map()
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
Replace(eraseCount, text) {
    global TrailingSpace, PlayTick, RelayWatch
    ; One SendInput batch, so keys typed meanwhile cannot land in the middle.
    ; Text mode does not depend on the keyboard layout, Shift or Caps Lock.
    SendInput "{Backspace " eraseCount "}{Text}" text (TrailingSpace ? " " : "")
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
    help.AddEdit("w520 r22 ReadOnly",
        "Expansion stays active while the PhraseKey window is hidden.`n`n"
        . "From anywhere:`n"
        . "Ctrl+Alt+F11: bring the PhraseKey window back`n"
        . "Ctrl+Alt+F12: exit PhraseKey`n`n"
        . "In the PhraseKey window:`n"
        . "Alt+E: saved entries list`n"
        . "Alt+A: add`n"
        . "Alt+D: edit`n"
        . "Alt+R: remove`n"
        . "Alt+H: hide`n"
        . "Alt+X: exit`n"
        . "Alt+K: keyboard shortcuts`n"
        . "Alt+P: play sound on text replacement`n`n"
        . "In the Add or Edit dialog:`n"
        . "Alt+B: abbreviation`n"
        . "Alt+H: chord`n"
        . "Alt+K: keys`n"
        . "Alt+R: replacement text`n"
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
    global Engine, Word, Dirty
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
        Engine.Down(key, A_TickCount)
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
        if Word = ""
            Dirty := true
        else
            Word := SubStr(Word, 1, -1)
    } else if !IsTextKey(vk) {
        ; Navigation, Enter, Tab, Escape and so on start a new word.
        Word := ""
        Dirty := false
    }
}
KeyUp(hook, vk, sc) {
    global Engine, Word, Dirty, TrailingSpace
    Critical
    if (key := ChordKey(vk)) = ""
        return
    active := Tracking()
    text := Engine.Up(key, A_TickCount)
    if text = "" || !active || ShortcutHeld() || PasswordField()
        return
    Replace(Engine.Chars, text)
    Word := ""
    Dirty := !TrailingSpace
}
CharTyped(hook, char) {
    global Word, Dirty, SingleRules, TrailingSpace
    Critical
    if !Tracking() || ShortcutHeld()
        return
    Loop Parse char {
        if A_LoopField = " " {
            abbreviation := FindAbbreviation()
            expand := abbreviation != "" && !PasswordField()
            if expand
                Replace(StrLen(abbreviation) + 1, SingleRules[abbreviation])
            Word := ""
            Dirty := expand && !TrailingSpace
        } else if RegExMatch(A_LoopField, "^[^\s[:cntrl:]]$") {
            Word .= A_LoopField
            ; Keep only as much as the longest abbreviation could need.
            if StrLen(Word) > 130
                Word := SubStr(Word, -65)
        } else {
            ; Enter, Tab and other control characters start afresh.
            Word := ""
            Dirty := false
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
    global ChordList, RuleKeys, Rules, SingleRules
    ChordList.Delete()
    RuleKeys := []
    labels := []
    for key, value in SingleRules {
        RuleKeys.Push("single:" key)
        labels.Push("Abbreviation " key " = " StrReplace(StrReplace(value, "`r", ""), "`n", " / "))
    }
    for chord, value in Rules {
        RuleKeys.Push("chord:" chord)
        labels.Push("Chord " DisplayChord(chord) " = " StrReplace(StrReplace(value, "`r", ""), "`n", " / "))
    }
    ChordList.Add(labels)
    for index, id in RuleKeys
        if id = select
            ChordList.Choose(index)
}
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
    SingleRadio := EditorGui.AddRadio("xm Group Checked", "A&bbreviation (then Space)")
    ChordRadio := EditorGui.AddRadio("x+20", "C&hord (press together)")
    SingleRadio.OnEvent("Click", ModeChanged)
    ChordRadio.OnEvent("Click", ModeChanged)
    TriggerLabel := EditorGui.AddText("xm w580", "&Keys (abbreviation, such as addr or $sig):")
    ChordEdit := EditorGui.AddEdit("xm w580")
    EditorGui.AddText("xm", "&Replacement text:")
    ReplacementEdit := EditorGui.AddEdit("xm w580 r5 WantReturn")
    EditorGui.AddButton("xm w120 Default", "&Save").OnEvent("Click", SaveEntry)
    EditorGui.AddButton("x+10 w120", "&Cancel").OnEvent("Click", CloseEditor)
    EditorGui.OnEvent("Close", CloseEditor)
    EditorGui.OnEvent("Escape", CloseEditor)
    if id != "" {
        parts := StrSplit(id, ":",, 2)
        singleMode := parts[1] = "single"
        SingleRadio.Value := singleMode
        ChordRadio.Value := !singleMode
        ChordEdit.Value := singleMode ? parts[2] : DisplayChord(parts[2])
        ReplacementEdit.Value := singleMode ? SingleRules[parts[2]] : Rules[parts[2]]
        ModeChanged()
    }
    Main.Opt("+Disabled")
    EditorGui.Show()
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
    global SingleRadio, TriggerLabel
    TriggerLabel.Text := SingleRadio.Value ? "&Keys (abbreviation, such as addr or $sig):" : "&Keys (2 to 8 different keys, such as t h e or a s `;):"
}
SaveEntry(*) {
    global
    singleMode := SingleRadio.Value = 1
    key := singleMode ? StrLower(Trim(ChordEdit.Value)) : Normalise(ChordEdit.Value)
    if (singleMode && !RegExMatch(key, "^\S{1,40}$")) || (!singleMode && key = "") {
        MsgBox singleMode ? "Enter 1 to 40 characters with no spaces, such as addr, t or $sig." : "Enter two to eight different keys: letters, digits or punctuation keys as typed without Shift, such as t h e or a s `; (4 rather than $).", "Check keys"
        ChordEdit.Focus()
        return
    }
    if Trim(ReplacementEdit.Value) = "" {
        MsgBox "Enter replacement text.", "Check text"
        ReplacementEdit.Focus()
        return
    }
    id := (singleMode ? "single:" : "chord:") key
    table := singleMode ? SingleRules : Rules
    if table.Has(key) && id != EditingId {
        MsgBox "That entry already exists. Select it in the list and choose Edit.", "Duplicate entry"
        return
    }
    if !singleMode {
        for existing, value in Rules {
            if ("chord:" existing) = EditingId
                continue
            shorter := StrLen(existing) < StrLen(key) ? existing : key
            longer := StrLen(existing) < StrLen(key) ? key : existing
            subset := true
            for letter in StrSplit(shorter)
                if !InStr(longer, letter)
                    subset := false
            if subset {
                MsgBox "This contains all the keys of " DisplayChord(existing) " or is contained in it. Choose a different combination.", "Overlapping chord"
                return
            }
        }
    }
    if EditingId != "" && EditingId != id {
        old := StrSplit(EditingId, ":",, 2)
        if old[1] = "single"
            SingleRules.Delete(old[2])
        else
            Rules.Delete(old[2])
    }
    table[key] := ReplacementEdit.Value
    ClearTyping()
    RefreshList(id)
    Persist()
    CloseEditor()
}
RemoveSelected(*) {
    global ChordList, RuleKeys, SingleRules, Rules, Engine
    if !ChordList.Value
        return
    if MsgBox("Remove this saved entry?", "PhraseKey", "YesNo") != "Yes"
        return
    parts := StrSplit(RuleKeys[ChordList.Value], ":",, 2)
    if parts[1] = "single"
        SingleRules.Delete(parts[2])
    else
        Rules.Delete(parts[2])
    ClearTyping()
    RefreshList()
    Persist()
}

Normalise(text) {
    ; Keys may be separated by spaces or plus signs; + itself needs Shift,
    ; so it can never be a chord key.
    text := StrLower(RegExReplace(text, "[+\s]", ""))
    if !RegExMatch(text, "^.{2,8}$")
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
    return RTrim(RegExReplace(StrUpper(chord), "(.)", "$1 "))
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
        IniWrite TrailingSpace ? 1 : 0, temp, "Options", "TrailingSpace"
        IniWrite PlayTick ? 1 : 0, temp, "Options", "PlaySound"
        IniWrite NvdaWarning ? 1 : 0, temp, "Options", "NvdaWarning"
        ; Sentinel distinguishes an intentionally empty collection.
        IniWrite "1", temp, "Chords", "_saved"
        for chord, value in Rules
            IniWrite Encode(value), temp, "Chords", EncodeKey(chord)
        IniWrite "1", temp, "Strings", "_saved"
        for letter, value in SingleRules
            IniWrite Encode(value), temp, "Strings", EncodeKey(letter)
        FileMove temp, SettingsFile, 1
    } catch as err {
        MsgBox "Changes work for this session, but could not be saved: " err.Message, "Save failed"
    }
}
