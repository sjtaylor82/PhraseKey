#Requires AutoHotkey v2.0
#Include ChordEngine.ahk
#Include AfterExpansion.ahk
#Include WordForms.ahk
#Include Bundled.ahk
#Include Updater.ahk
#Include BrailleInput.ahk

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

    engine := ChordEngine(Map("eht", "the"), 90, Map(";i", "ing"))
    engine.Down(";", 0), engine.Down("i", 10)
    out := engine.Up(";", 20) engine.Up("i", 30)
    Check(out, "ing", "Suffix chord gives its ending")
    Check(engine.Last.Suffix, true, "Suffix chord is reported as one")
    engine.Down("t", 100), engine.Down("h", 110), engine.Down("e", 120)
    out := engine.Up("t", 130) engine.Up("h", 140) engine.Up("e", 150)
    Check(engine.Last.Suffix, false, "Ordinary chord is not a suffix chord")
    engine.Down(";", 200)
    Check(engine.MayComplete(), true, "Held key may still become a chord")
    engine.Down("x", 210)
    Check(engine.MayComplete(), false, "No chord uses these keys")
    engine.Up(";", 220), engine.Up("x", 230)
    engine.Down(".", 300)
    Check(engine.MayComplete(), false, "Key used by no chord")
    engine.Up(".", 310)

    for test in [["like", "ing", "liking"], ["like", "ed", "liked"], ["make", "ing", "making"],
            ["run", "ing", "running"], ["run", "ed", "ran"], ["stop", "ed", "stopped"],
            ["visit", "ing", "visiting"], ["open", "ed", "opened"], ["prefer", "ed", "preferred"],
            ["try", "s", "tries"], ["try", "ed", "tried"], ["try", "ing", "trying"], ["play", "ed", "played"],
            ["watch", "s", "watches"], ["child", "s", "children"], ["man", "s", "men"], ["go", "s", "goes"],
            ["happy", "ness", "happiness"], ["happy", "ly", "happily"], ["happy", "er", "happier"],
            ["care", "ful", "careful"], ["careful", "ly", "carefully"], ["gentle", "ly", "gently"],
            ["basic", "ly", "basically"], ["full", "ly", "fully"], ["die", "ing", "dying"],
            ["see", "ing", "seeing"], ["good", "er", "better"], ["big", "er", "bigger"],
            ["quick", "er", "quicker"], ["teach", "er", "teacher"], ["quit", "ing", "quitting"],
            ["determine", "ed", "determined"], ["millionaire", "s", "millionaires"],
            ["Like", "ing", "Liking"], ["LIKE", "ing", "LIKING"], ["write", "ed", "wrote"]]
        Check(AddSuffix(test[1], test[2]), test[3], test[1] " + " test[2])
    Check(AddSuffix("Run", "ed", Map("run", Map("ed", "runned"))), "Runned", "Saved form comes first")

    after := AfterExpansion()
    after.Expanded("like", true)
    after.Add(";"), after.Add("i")
    Check(Edit(after.Suffix("ing", 2)), "7:liking ", "Suffix replaces word and space")
    after.Add(";"), after.Add("l")
    Check(Edit(after.Suffix("ly", 2)), "9:likingly ", "Suffixes stack")
    after.Expanded("care", true)
    after.Add(";"), after.Add("f")
    after.Suffix("ful", 2)
    after.Add(";"), after.Add("l")
    Check(Edit(after.Suffix("ly", 2)), "10:carefully ", "Care, careful, carefully")
    after.Expanded("like", false)
    after.Add(";"), after.Add("i")
    Check(Edit(after.Suffix("ing", 2)), "6:liking ", "Suffix after a replacement with no space adds one")
    after.Expanded("as soon as possible", true)
    after.Add(";"), after.Add("s")
    Check(after.Suffix("s", 2), 0, "No suffix after a phrase")
    after.Expanded("like", true)
    after.Add("x")
    Check(after.Punctuate(false, false), 0, "Letter is not punctuation")
    after.Add(";"), after.Add("i")
    Check(after.Suffix("ing", 2), 0, "No suffix once something else was typed")
    ; Prefix: pre with no space, then determine.
    after.Expanded("pre", false)
    after.Expanded("determine", true)
    after.Add(";"), after.Add("e")
    Check(Edit(after.Suffix("ed", 2)), "12:determined ", "Suffix changes only the last replacement")

    after.Expanded("like", true)
    after.Add(".")
    Check(Edit(after.Punctuate(false, false)), "2:.", "Full stop replaces the space")
    after.Expanded("like", true)
    after.Add(",")
    Check(Edit(after.Punctuate(false, true)), "2:, ", "Optional space after punctuation")
    after.Expanded("like", true)
    after.Add(";")
    Check(after.Punctuate(true, false), 0, "Wait while a chord may be under way")
    after.Add(" ")
    Check(Edit(after.Punctuate(false, false)), "3:; ", "Space typed fast after a semicolon is kept")
    after.Expanded("like", true)
    after.Add('"')
    Check(after.Punctuate(false, false), 0, "Quote keeps the space")
    after.Expanded("like", true)
    after.Add("-")
    Check(after.Punctuate(false, false), 0, "Dash keeps the space")
    after.Expanded("pre", false)
    after.Add(".")
    Check(after.Punctuate(false, false), 0, "Nothing to remove without a space")
    after.Expanded("like", true)
    after.Add("'"), after.Punctuate(false, false)
    after.Add("s")
    Check(after.Punctuate(false, false), 0, "Punctuation is fixed only once")

    Check(Edit(TypedSuffix("walk;i", 2, "ing")), "6:walking ", "Typed word, suffix straight after")
    Check(Edit(TypedSuffix("walk `;i", 2, "ing")), "7:walking ", "Typed word and space, then suffix")
    Check(Edit(TypedSuffix("Walk;e", 2, "ed")), "6:Walked ", "Typed word keeps its capital")
    Check(Edit(TypedSuffix("I walk `;e", 2, "ed")), "7:walked ", "Only the last word changes")
    Check(Edit(TypedSuffix("walk i", 2, "ing")), "6:walking ", "Space suffix key, straight after the word")
    Check(Edit(TypedSuffix("walk  i", 2, "ing")), "7:walking ", "Space suffix key, after a space")
    Check(TypedSuffix(";i", 2, "ing"), 0, "No typed word to change")
    Check(TypedSuffix("x.;i", 2, "ing"), 0, "Typed text that is not a word")
    Check(TypedSuffix("walk  `;i", 2, "ing"), 0, "Two spaces after the word")

    engine := ChordEngine(Map("eht", "the"), 90, Map(" i", "ing"))
    engine.Down(" ", 0), engine.Down("i", 20)
    out := engine.Up(" ", 40) engine.Up("i", 50)
    Check(out, "ing", "Space chord pressed together")
    engine.Down(" ", 100), engine.Down("i", 160)
    out := engine.Up(" ", 170) engine.Up("i", 180)
    Check(out, "", "Space rolled into the next word is typing")
    Check(InStr(engine.Last.Reason, "Space") > 0, true, "Report names the Space limit")
    engine.Down("t", 200), engine.Down("h", 260), engine.Down("e", 270)
    out := engine.Up("t", 280) engine.Up("h", 290) engine.Up("e", 300)
    Check(out, "the", "Other chords keep the usual limit")

    for word in ["happy", "happier", "happiness", "happily", "carefully", "walking", "can't", "a", "zygote"]
        Check(KnownWord(word), true, "Known word " word)
    for word in ["happying", "happies", "happied", "walkly", "likingly", "zzz", ""]
        Check(KnownWord(word), false, "Not a word " word)
    Check(KnownWord("Happiness"), true, "Capitals do not matter")

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

    Check(CellDots(Chr(0x2818)), "45", "Cell dots 45")
    Check(CellDots(Chr(0x28FF)), "12345678", "Cell with all eight dots")
    Check(CellsDots(Chr(0x2818) Chr(0x280D)), "45 134", "Cells into dots")
    Check(IsBrailleCell(Chr(0x2800)), true, "Blank cell is a cell")
    Check(IsBrailleCell("m"), false, "A letter is not a cell")
    for pair in [["45 134", "45 134"], [" 45-134 ", "45 134"], ["45/134", "45 134"], ["54 431", "45 134"],
            [Chr(0x2818) Chr(0x280D), "45 134"], [Chr(0x2818) Chr(0x280D) Chr(0x2800), "45 134"],
            ["78", "78"], ["", ""], ["9", ""], ["0", ""], ["445", ""], ["45 x", ""], [Chr(0x2800), ""]]
        Check(NormaliseDots(pair[1]), pair[2], "Normalise dots [" pair[1] "]")
    cells := BrailleRun()
    cells.Add(Chr(0x2818), 1000), cells.Add(Chr(0x280D), 1500)
    taken := cells.Take()
    Check(taken.Dots " " taken.Count, "45 134 2", "Run of two cells")
    Check(cells.Cells, "", "Taking a run clears it")
    cells.Add(Chr(0x2818), 1000), cells.Add(Chr(0x280D), 1000 + BrailleRun.PauseMs + 1)
    Check(cells.Take().Dots, "134", "A pause drops the cells before it")
    cells.Add(Chr(0x2818), 0), cells.Add(Chr(0x2801), 10), cells.Erase(), cells.Add(Chr(0x280D), 20)
    Check(cells.Take().Dots, "45 134", "Backspace erases the last cell")

    rules := Map("45", "a", "45 234", "b", "1 12", "c")
    Check(LongerBrailleEntry(rules, "45"), true, "45 may become 45 234")
    Check(LongerBrailleEntry(rules, "45 234"), false, "Nothing longer than 45 234")
    Check(LongerBrailleEntry(rules, "4"), false, "4 is not the start of 45's first cell")
    Check(LongerBrailleEntry(rules, "1"), true, "1 may become 1 12")

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
Edit(edit) => IsObject(edit) ? edit.Erase ":" edit.Text : "none"
Check(actual, expected, label) {
    global Count
    Count += 1
    if actual != expected
        throw Error(label ": expected [" expected "], got [" actual "]")
}
