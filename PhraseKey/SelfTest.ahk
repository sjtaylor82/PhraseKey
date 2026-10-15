#Requires AutoHotkey v2.0
#Include ChordEngine.ahk
#Include Updater.ahk

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

    engine := ChordEngine(Map("ew", "we", "'ew", "we'll"), 90)
    engine.Down("w", 0), engine.Down("e", 10)
    out := engine.Up("w", 20) engine.Up("e", 30)
    Check(out, "we", "Chord inside a larger chord")
    engine.Down("w", 100), engine.Down("e", 110), engine.Down("'", 120)
    out := engine.Up("w", 130) engine.Up("e", 140) engine.Up("'", 150)
    Check(out, "we'll", "Larger chord containing a smaller one")

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

    for pair in [["0.9", "0.8", 1], ["v0.10", "0.9", 1], ["1.0", "1", 0], ["0.8", "0.8.1", -1]]
        Check(Sign(CompareVersions(pair[1], pair[2])), pair[3], "Compare " pair[1] " with " pair[2])

    digest := (n) => '"digest":"sha256:' StrRepeat(n, 64) '"'
    json := '{"tag_name":"v0.9","assets":[{"name":"notes.txt","uploader":{"login":"x"},' digest("a")
        . ',"browser_download_url":"https://example.com/notes.txt"},{"name":"PhraseKey-0.9-win64.zip",'
        . '"uploader":{"login":"x"},' digest("B") ',"browser_download_url":"https://example.com/PhraseKey-0.9-win64.zip"}]}'
    release := ParseRelease(json)
    Check(release.Version, "0.9", "Release version")
    Check(release.Url, "https://example.com/PhraseKey-0.9-win64.zip", "Windows zip chosen")
    Check(release.Sha256, StrRepeat("b", 64), "Digest belongs to the zip")
    release := ParseRelease('{"tag_name":"v0.9","assets":[{' digest("a") ',"browser_download_url":"https://example.com/a.txt"},'
        . '{"digest":null,"browser_download_url":"https://example.com/PhraseKey-0.9-win64.zip"}]}')
    Check(release.Sha256, "", "Missing digest is not borrowed")
    Check(ParseRelease('{"message":"Not Found"}'), 0, "Not a release")

    sample := A_Temp "\PhraseKey-selftest.txt"
    try FileDelete sample
    FileAppend "abc", sample, "UTF-8-RAW"
    Check(FileSha256(sample), "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "SHA-256")
    FileDelete sample

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

Sign(n) => n > 0 ? 1 : n < 0 ? -1 : 0
StrRepeat(text, n) => StrReplace(Format("{:" n "}", ""), " ", text)
NewEngine() =>ChordEngine(Map("eht", "the"), 90)
Check(actual, expected, label) {
    global Count
    Count += 1
    if actual != expected
        throw Error(label ": expected [" expected "], got [" actual "]")
}
