#Requires AutoHotkey v2.0

; Adds an ending such as ing, ed or ness to a word. A form the user saved for
; that word comes first, then the built-in word list (WordForms.ahk), which
; holds only the words these spelling rules would get wrong.
AddSuffix(word, ending, saved := 0) {
    lower := StrLower(word)
    ending := StrLower(ending)
    if IsObject(saved) && saved.Has(lower) && saved[lower].Has(ending)
        result := saved[lower][ending]
    else if (known := KnownForms()).Has(lower) && known[lower].Has(ending)
        result := known[lower][ending]
    else
        result := SuffixRule(lower, ending)
    return MatchCase(word, result)
}

; Lower-case word plus ending by the regular English spelling rules.
SuffixRule(word, ending) {
    if ending = "s" {
        if RegExMatch(word, "(s|x|z|ch|sh)$")
            return word "es"
        if RegExMatch(word, "[^aeiou]y$")
            return SubStr(word, 1, -1) "ies"
        return word "s"
    }
    first := SubStr(ending, 1, 1)
    if InStr("aeiouy", first) {
        ; die, lie, tie
        if first = "i" && RegExMatch(word, "ie$")
            return SubStr(word, 1, -2) "y" ending
        ; try: tried, happier; but trying keeps the y
        if first != "i" && RegExMatch(word, "[^aeiou]y$")
            return SubStr(word, 1, -1) "i" ending
        if SubStr(word, -1) = "e" {
            if first = "e"
                return SubStr(word, 1, -1) ending
            ; see, eye, hoe keep their e
            if RegExMatch(word, "(ee|ye|oe)$")
                return word ending
            return SubStr(word, 1, -1) ending
        }
        ; One syllable ending in one vowel and one consonant: stop, big, quit
        if RegExMatch(StrReplace(word, "qu", "q"), "^[^aeiou]*[aeiou][b-df-hj-np-tvz]$")
            return word SubStr(word, -1) ending
        return word ending
    }
    if ending = "ly" {
        ; gentle, simple; but whole, sole
        if RegExMatch(word, "[^aeiou]le$")
            return SubStr(word, 1, -1) "y"
        if RegExMatch(word, "ic$")
            return word "ally"
        if RegExMatch(word, "ll$")
            return word "y"
    }
    ; happy: happiness, happily; but shy, dry keep the y
    if StrLen(word) > 3 && RegExMatch(word, "[^aeiou]y$")
        return SubStr(word, 1, -1) "i" ending
    return word ending
}

; Like gives Liking, LIKE gives LIKING.
MatchCase(model, word) {
    if StrLen(model) > 1 && model == StrUpper(model) && model != StrLower(model)
        return StrUpper(word)
    if SubStr(model, 1, 1) != StrLower(SubStr(model, 1, 1))
        return StrUpper(SubStr(word, 1, 1)) SubStr(word, 2)
    return word
}

; word => Map(ending => form), read once from WordForms.ahk.
KnownForms() {
    static known := 0
    if IsObject(known)
        return known
    known := Map()
    for line in StrSplit(WordFormsData(), "`n", "`r") {
        parts := StrSplit(line, " ")
        if parts.Length < 2
            continue
        forms := Map()
        Loop parts.Length - 1 {
            pair := StrSplit(parts[A_Index + 1], "=")
            forms[pair[1]] := pair[2]
        }
        known[parts[1]] := forms
    }
    return known
}
