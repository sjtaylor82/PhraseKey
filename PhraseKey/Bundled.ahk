#Requires AutoHotkey v2.0

; Text files that ship inside PhraseKey: the licence and word-list notices
; shown in the About window, and the list of English words. The compiled
; program carries them as resources; the script reads the files.
;@Ahk2Exe-AddResource ..\LICENSE, LICENSE.TXT
;@Ahk2Exe-AddResource WORDLIST-NOTICE.txt, WORDLIST-NOTICE.TXT
;@Ahk2Exe-AddResource Words.txt, WORDS.TXT
LicenceText() => BundledText("LICENSE.TXT", A_ScriptDir "\..\LICENSE")
WordListNoticeText() => BundledText("WORDLIST-NOTICE.TXT", A_ScriptDir "\WORDLIST-NOTICE.txt")

BundledText(resource, file) {
    try {
        if !A_IsCompiled
            return FileRead(file, "UTF-8")
        ; RT_RCDATA
        found := DllCall("FindResource", "Ptr", 0, "Str", resource, "Ptr", 10, "Ptr")
        size := DllCall("SizeofResource", "Ptr", 0, "Ptr", found, "UInt")
        data := DllCall("LockResource", "Ptr", DllCall("LoadResource", "Ptr", 0, "Ptr", found, "Ptr"), "Ptr")
        if data && size
            return StrGet(data, size, "UTF-8")
    }
    return "(Not found. See " resource " in the PhraseKey download.)"
}

; True if word is an English word PhraseKey knows, from Words.txt (made by
; tools\MakeWordList.ahk). It is read the first time it is needed.
KnownWord(word) {
    static words := 0
    if !IsObject(words)
        words := StrSplit(Trim(BundledText("WORDS.TXT", A_ScriptDir "\Words.txt"), "`n"), "`n")
    word := StrLower(word)
    ; Words.txt is sorted by character code.
    low := 1, high := words.Length
    while low <= high {
        middle := (low + high) // 2
        order := StrCompare(words[middle], word, true)
        if order = 0
            return true
        if order < 0
            low := middle + 1
        else
            high := middle - 1
    }
    return false
}
