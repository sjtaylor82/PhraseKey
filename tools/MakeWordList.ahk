#Requires AutoHotkey v2.0

; Builds PhraseKey\Words.txt, the English words PhraseKey knows, so the Word
; forms box lists only real words. It combines SCOWL, Spell Checker Oriented
; Word Lists, up to size 70, with every plain form in AGID's infl.txt; both are
; at http://wordlist.aspell.net. See WORDLIST-NOTICE.txt.
; Usage: AutoHotkey64.exe MakeWordList.ahk path\to\scowl\final path\to\infl.txt
if A_Args.Length != 2 {
    FileAppend "Usage: MakeWordList.ahk path\to\scowl\final path\to\infl.txt`n", "**"
    ExitApp 1
}
words := Map()
Loop Files A_Args[1] "\*" {
    if !RegExMatch(A_LoopFileName, "^(english|american|british)-(words|contractions)\.(\d+)$", &list) || Integer(list[3]) > 70
        continue
    Loop Read A_LoopFileFullPath
        if RegExMatch(A_LoopReadLine, "^[a-z][a-z']*$")
            words[A_LoopReadLine] := true
}
Loop Read A_Args[2] {
    ; word V: past | ing | s, with doubtful forms marked ~ < ! ? or a variant level
    if !RegExMatch(A_LoopReadLine, "^([a-z][a-z']*) [VNA]\??: (.*)$", &entry)
        continue
    words[entry[1]] := true
    for slot in StrSplit(entry[2], " | ")
        for form in StrSplit(slot, ", ")
            if RegExMatch(form, "^[a-z']+$")
                words[form] := true
}
; A Map enumerates its keys in ordinal order, as KnownWord's search needs.
out := ""
for word in words
    out .= word "`n"
target := A_ScriptDir "\..\PhraseKey\Words.txt"
try FileDelete target
FileAppend out, target, "UTF-8-RAW"
FileAppend words.Count " words written.`n", "*"
ExitApp 0
