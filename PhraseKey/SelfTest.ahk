#Requires AutoHotkey v2.0
#Include ChordEngine.ahk

; Tests use the ACTUAL recogniser, with deterministic event times.
; No keyboard hooks, GUI input, settings changes or text injection.
Count := 0
try {
    for order in ["the", "teh", "hte", "het", "eth", "eht"] {
        for release in ["the", "teh", "hte", "het", "eth", "eht"] {
            engine := NewEngine()
            out := ""
            for i, key in StrSplit(order)
                engine.Down(key, i * 15)
            for i, key in StrSplit(release)
                out .= engine.Up(key, 100 + i * 15)
            Check(out, "the", "Press " order ", release " release)
            Check(engine.Chars, 3, "Erase count")
        }
    }
    engine := NewEngine()
    out := ""
    for i, key in StrSplit("thethanksthereother") {
        engine.Down(key, i * 30)
        out .= engine.Up(key, i * 30 + 10)
    }
    Check(out, "", "Sequential typing")

    engine := NewEngine()
    engine.Down("t", 0), engine.Down("h", 20)
    out := engine.Up("t", 30)
    engine.Down("e", 40)
    out .= engine.Up("h", 50) engine.Up("e", 60)
    Check(out, "", "No chord without three-way overlap")

    engine := NewEngine()
    engine.Down("t", 0), engine.Down("h", 110), engine.Down("e", 120)
    out := engine.Up("t", 130) engine.Up("h", 140) engine.Up("e", 150)
    Check(out, "", "Too slow is typing")

    engine := ChordEngine(Map("adfghjks", "eight"), 90)
    for i, key in StrSplit("asdfghjk")
        engine.Down(key, i * 80)
    out := ""
    for i, key in StrSplit("asdfghjk")
        out .= engine.Up(key, 2000 + i * 80)
    Check(out, "eight", "Large chords have no time limit")
    Check(engine.Last.Expanded, true, "Report says expanded")

    for order in ["as;1", ";1sa", "1;as"] {
        engine := ChordEngine(Map("1;as", "mixed"), 90)
        for i, key in StrSplit(order)
            engine.Down(key, i * 10)
        out := ""
        for i, key in StrSplit(order)
            out .= engine.Up(key, 100 + i * 10)
        Check(out, "mixed", "Digit and punctuation keys: " order)
    }

    engine := NewEngine()
    engine.Down("t", 0), engine.Down("h", 10), engine.Down("e", 20)
    Loop 5
        engine.Down("e", 500 + A_Index * 30)
    out := engine.Up("t", 1010) engine.Up("h", 1020) engine.Up("e", 1030)
    Check(out, "the", "Completed chord can be held")
    Check(engine.Chars, 8, "Auto-repeat letters are erased too")

    engine := NewEngine()
    engine.Down("t", 0), engine.Down("h", 10)
    out := engine.Up("t", 20) engine.Up("h", 30)
    Check(out, "", "Partial chord is typing")

    engine := NewEngine()
    engine.Down("t", 0), engine.Down("h", 10), engine.Down("e", 20), engine.Down("a", 30)
    out := engine.Up("t", 40) engine.Up("h", 50) engine.Up("e", 60) engine.Up("a", 70)
    Check(out, "", "Extra letter is typing")

    engine := NewEngine()
    engine.Down("t", 0), engine.Down("h", 10), engine.Down("e", 20)
    engine.Break()
    out := engine.Up("t", 30) engine.Up("h", 40) engine.Up("e", 50)
    Check(out, "", "Other key or focus change cancels")

    engine := NewEngine()
    engine.Down("t", 0), engine.Down("h", 10), engine.Down("e", 20)
    engine.Forget("t")
    out := engine.Up("h", 40) engine.Up("e", 50)
    Check(out, "the", "Missed key-up does not jam the recogniser")
    engine.Down("t", 100), engine.Down("h", 110), engine.Down("e", 120)
    out := engine.Up("t", 130) engine.Up("h", 140) engine.Up("e", 150)
    Check(out, "the", "Next chord after a completed one")

    engine := ChordEngine(Map("adn", "and", "eht", "the"), 90)
    engine.Down("n", 0), engine.Down("a", 10), engine.Down("d", 20)
    out := engine.Up("d", 30) engine.Up("n", 40) engine.Up("a", 50)
    Check(out, "and", "Custom chord")

    for size, chord in Map(6, "eiqruw", 8, "abcdefgh") {
        for order in [chord, SubStr(chord, 4) SubStr(chord, 1, 3)] {
            engine := ChordEngine(Map(chord, size " keys"), 90)
            out := ""
            for i, key in StrSplit(order)
                engine.Down(key, i * 10)
            for i, key in StrSplit(chord)
                out .= engine.Up(key, 200 + i * 10)
            Check(out, size " keys", size "-key chord: " order)
        }
    }

    if A_Args.Length && A_Args[1] = "--quiet"
        FileAppend Count " checks passed.`n", "*"
    else
        MsgBox Count " checks passed. This tests the chord recogniser, not Windows input delivery or JAWS accessibility.", "PhraseKey self-test"
} catch as err {
    if A_Args.Length && A_Args[1] = "--quiet"
        FileAppend err.Message "`n", "**"
    else
        MsgBox err.Message, "PhraseKey self-test FAILED"
    ExitApp 1
}
ExitApp 0

NewEngine() => ChordEngine(Map("eht", "the"), 90)
Check(actual, expected, label) {
    global Count
    Count += 1
    if actual != expected
        throw Error(label ": expected [" expected "], got [" actual "]")
}
