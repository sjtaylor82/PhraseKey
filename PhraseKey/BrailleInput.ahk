#Requires AutoHotkey v2.0

; Braille entries. With Unicode braille input on, JAWS types each cell as a
; character from U+2800 to U+28FF whose low eight bits are the dots pressed,
; so the dots are known exactly, whatever the braille table. Space comes as
; the blank cell, U+2800. Dots are written per cell, cells separated by a
; space: dots 45 then dots 134 is "45 134".

IsBrailleCell(char) => StrLen(char) = 1 && Ord(char) >= 0x2800 && Ord(char) <= 0x28FF
CellDots(cell) {
    bits := Ord(cell) - 0x2800
    dots := ""
    Loop 8
        if bits & (1 << (A_Index - 1))
            dots .= A_Index
    return dots
}
CellsDots(cells) {
    dots := ""
    for cell in StrSplit(cells)
        dots .= (dots = "" ? "" : " ") CellDots(cell)
    return dots
}
; "45 134", "45-134", "45/134" or the braille characters themselves, into
; "45 134"; "" if that is not 1 to 20 cells of dots 1 to 8.
NormaliseDots(text) {
    text := Trim(text)
    cells := []
    ; Typed on the display, the cells may be followed by the blank cell.
    typed := RegExReplace(text, "[\s\x{2800}]")
    if RegExMatch(typed, "^[\x{2801}-\x{28FF}]+$") {
        for cell in StrSplit(typed)
            cells.Push(CellDots(cell))
    } else {
        for part in StrSplit(RegExReplace(text, "[\s/,-]+", " "), " ") {
            if !RegExMatch(part, "^[1-8]{1,8}$")
                return ""
            ; Each dot once, in order: 541 is 145.
            dots := ""
            Loop 8
                if InStr(part, A_Index)
                    dots .= A_Index
            if StrLen(dots) != StrLen(part)
                return ""
            cells.Push(dots)
        }
    }
    if cells.Length < 1 || cells.Length > 20
        return ""
    dots := ""
    for cell in cells
        dots .= (dots = "" ? "" : " ") cell
    return dots
}

; True if some entry in rules, keyed by dots, starts with these dots and
; goes on: typing dots could still be the start of it.
LongerBrailleEntry(rules, dots) {
    for key in rules
        if SubStr(key, 1, StrLen(dots) + 1) == dots " "
            return true
    return false
}

; The cells typed since the last ending. Pure: times are passed in.
class BrailleRun {
    ; A run left this long before its next cell is abandoned: the JAWS
    ; toggle types nothing, so this is the only sign of a run given up on.
    static PauseMs := 3000
    ; Enter is a real key whether Unicode braille input is on or not, and
    ; JAWS can type contracted braille without PhraseKey seeing it, so
    ; Enter only ends cells typed just before it.
    static EnterMs := 2000
    ; Cells that match an entry but may be the start of a longer one are
    ; replaced once this long passes without another cell.
    static SettleMs := 1000
    __New() {
        this.Clear()
    }
    Clear() {
        this.Cells := ""
        this.Last := 0
    }
    Add(cell, now) {
        if this.Cells != "" && now - this.Last > BrailleRun.PauseMs
            this.Cells := ""
        this.Cells .= cell
        this.Last := now
    }
    Erase() {
        this.Cells := SubStr(this.Cells, 1, -1)
    }
    ; Takes the run: its dots and how many characters it is in the text.
    Take() {
        taken := {Dots: CellsDots(this.Cells), Count: StrLen(this.Cells)}
        this.Clear()
        return taken
    }
}

; Asks JAWS to run its own Unicode braille input toggle, through the COM
; interface every JAWS installation registers. No JAWS script is changed.
; Only call this when Unicode input is known to be on, as a blank cell shows.
TurnOffUnicodeBraille() {
    static jaws := 0
    if !ProcessExist("jfw.exe")
        return false
    try {
        if !jaws
            jaws := ComObject("FreedomSci.JawsApi")
        return jaws.RunScript("ToggleUnicodeBrailleInput")
    }
    jaws := 0
    return false
}
