#Requires AutoHotkey v2.0

; Pure chord recogniser. It only observes key events; no OS calls.
; A stroke is a chord when all of its keys are down together before the
; first is released and the set of keys matches a rule. Chords of two or
; three keys must also go down within Window milliseconds, because fast
; ordinary typing can overlap that many keys; four or more keys held at
; once never happens in typing, so larger chords have no time limit.
; Up() returns the replacement when the last key of such a stroke is
; released; Chars is then the number of letters the stroke typed, which
; the caller erases. Last describes the most recent finished stroke;
; Last.Suffix says it matched a suffix chord, whose Up() result is the
; ending to add.
class ChordEngine {
    __New(rules, window := 30, suffixes := 0) {
        this.Rules := rules
        this.Suffixes := IsObject(suffixes) ? suffixes : Map()
        this.Window := window
        ; Space chords need a tighter limit: fast typing often holds Space
        ; while the first letter of the next word goes down.
        this.SpaceWindow := 20
        this.Last := {Keys: "", Span: 0, Expanded: false, Reason: "", Suffix: false}
        this.Reset()
    }
    Reset() {
        this.Held := Map()
        this.Keys := Map()
        this.Start := 0
        this.Span := 0
        this.Chars := 0
        this.Cancelled := true
        this.Staggered := false
        this.Released := false
    }
    Signature(keys) {
        ; A Map enumerates its keys in order, so this is the same for any
        ; order of pressing.
        s := ""
        for key in keys
            s .= key
        return s
    }
    ; Call for every letter key-down event, including auto-repeat.
    Down(key, time) {
        this.Chars += 1
        if this.Held.Has(key)
            return
        if this.Held.Count = 0 {
            this.Keys := Map()
            this.Start := time
            this.Chars := 1
            this.Cancelled := false
            this.Staggered := false
            this.Released := false
        }
        ; A key pressed after another was released is typing.
        if this.Released
            this.Staggered := true
        this.Span := time - this.Start
        this.Held[key] := true
        this.Keys[key] := true
    }
    Up(key, time) {
        if !this.Held.Has(key)
            return ""
        this.Held.Delete(key)
        this.Released := true
        if this.Held.Count
            return ""
        signature := this.Signature(this.Keys)
        if this.Cancelled
            reason := "cancelled by another key, a click or a change of window"
        else if this.Staggered
            reason := "the keys were not all held down together"
        else if !this.Rules.Has(signature) && !this.Suffixes.Has(signature)
            reason := "no saved chord uses exactly these keys"
        else if this.Keys.Count <= 3 && this.Span > (limit := this.Keys.Has(" ") ? this.SpaceWindow : this.Window)
            reason := "too slow for a chord of 2 or 3 keys (limit " limit " ms" (this.Keys.Has(" ") ? " for chords with Space" : "") ")"
        else
            reason := ""
        suffix := !this.Rules.Has(signature) && this.Suffixes.Has(signature)
        this.Last := {Keys: signature, Span: Round(this.Span), Expanded: reason = "", Reason: reason, Suffix: suffix}
        this.Cancelled := true
        return reason = "" ? (suffix ? this.Suffixes[signature] : this.Rules[signature]) : ""
    }
    ; True while the keys held so far could still become a chord when
    ; released, so what they typed must be left alone until then.
    MayComplete() {
        if !this.Held.Count || this.Cancelled || this.Staggered
            return false
        for table in [this.Rules, this.Suffixes]
            for signature in table {
                for key in this.Keys
                    if !InStr(signature, key)
                        continue 2
                return true
            }
        return false
    }
    ; Any other key, shortcut, click or focus change: not a chord.
    Break() {
        this.Cancelled := true
    }
    ; A key-up was missed (for example behind a secure desktop).
    Forget(key) {
        if this.Held.Has(key) {
            this.Held.Delete(key)
            this.Released := true
        }
    }
}
