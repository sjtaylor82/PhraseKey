#Requires AutoHotkey v2.0
#Include WordRules.ahk

; What happens straight after PhraseKey types a replacement. Pure: it only
; tracks text and returns the edit to make, as {Erase: count, Text: text},
; or 0 for none.
; - A suffix chord changes a single-word replacement: like becomes liking.
;   The new word always ends with one space, ready for the next word.
; - Punctuation typed straight after the space PhraseKey added replaces
;   that space: "like ." becomes "like.".
; Anything else typed, and anything PhraseKey cannot follow, ends both.
class AfterExpansion {
    static Punctuation := ".,;:!?)'"
    __New() {
        this.Clear()
    }
    Clear() {
        ; Word is the replacement if it was one word; Space says PhraseKey
        ; typed a space after it; Typed is what has been typed since.
        this.Word := ""
        this.Space := false
        this.Typed := ""
    }
    Expanded(text, space) {
        this.Word := IsOneWord(text) ? text : ""
        this.Space := space
        this.Typed := ""
    }
    Add(char) {
        this.Typed .= char
        ; Neither change ever needs more than a chord's worth of keys.
        if StrLen(this.Typed) > 16
            this.Clear()
    }
    ; Call after each character, and when a stroke turns out not to be a
    ; chord. mayBeChord says the keys still held could become one.
    Punctuate(mayBeChord, spaceAfter) {
        if mayBeChord || !this.Space || this.Typed = ""
            return 0
        typed := this.Typed
        first := SubStr(typed, 1, 1)
        this.Clear()
        if !InStr(AfterExpansion.Punctuation, first)
            return 0
        rest := SubStr(typed, 2)
        if spaceAfter && SubStr(rest, 1, 1) != " "
            rest := " " rest
        return {Erase: StrLen(typed) + 1, Text: first rest}
    }
    ; Call when a suffix chord is recognised; chars is how many characters
    ; its keys typed. It applies only if nothing else was typed in between.
    Suffix(ending, chars, saved := 0) {
        if this.Word = "" || StrLen(this.Typed) != chars {
            this.Clear()
            return 0
        }
        word := AddSuffix(this.Word, ending, saved)
        edit := {Erase: chars + StrLen(this.Word) + (this.Space ? 1 : 0), Text: word " "}
        this.Word := word
        this.Space := true
        this.Typed := ""
        return edit
    }
}

IsOneWord(text) => RegExMatch(text, "^\p{L}[\p{L}'-]*$")

; A suffix chord after a word the user typed. recent is what PhraseKey saw
; typed lately, ending with the chars characters the chord's keys typed; only
; those characters are ever erased. The word may have one space after it;
; either way the new word ends with one. Returns {Erase, Text, Word} or 0.
TypedSuffix(recent, chars, ending, saved := 0) {
    if StrLen(recent) <= chars
        return 0
    rest := SubStr(recent, 1, StrLen(recent) - chars)
    space := SubStr(rest, -1) = " "
    if space
        rest := SubStr(rest, 1, -1)
    if !RegExMatch(rest, "\p{L}[\p{L}'-]*$", &match)
        return 0
    word := AddSuffix(match[0], ending, saved)
    return {Erase: chars + match.Len + space, Text: word " ", Word: word}
}
