#Requires AutoHotkey v2.0

; JAWS puts text typed on a braille display straight into the document, so
; no keystrokes reach PhraseKey's tracker; only Space does. Then the word
; before the cursor is read from the document.

; Up to count characters before the cursor in the focused control, or "" if
; it can't say. How is set to how it was read, for Ctrl+Alt+F10.
TextBeforeCaret(&how, count := 80) {
    text := UiaTextBeforeCaret(count)
    if text != "" {
        how := "UI Automation"
        return text
    }
    text := EditTextBeforeCaret(count)
    how := text != "" ? "the edit control" : "nothing: the program did not say"
    return text
}

; True if the cursor is in a box that fills in suggestions as you type, such
; as the Run box or a file name box: an edit control inside a combo box.
; There JAWS's own braille typing and the suggestions get out of step with
; any change PhraseKey makes, so words JAWS typed are left alone.
SuggestingBox() {
    try {
        hwnd := ControlGetFocus("A")
        if !InStr(WinGetClass("ahk_id " hwnd), "Edit")
            return false
        parent := DllCall("GetParent", "Ptr", hwnd, "Ptr")
        return parent && InStr(WinGetClass("ahk_id " parent), "ComboBox")
    }
    return false
}

; Through UI Automation, which most programs support, browsers included.
UiaTextBeforeCaret(count) {
    static uia := 0
    try {
        if !uia
            uia := ComObject("{ff48dba4-60ef-4201-aa87-54103eef594e}", "{30cbe57d-d9d0-452a-ab13-7ac5ac4825ee}")
        ; IUIAutomation::GetFocusedElement
        ComCall(8, uia, "Ptr*", &element := 0)
        if !element
            return ""
        element := ComValue(13, element)
        ; IUIAutomationElement::GetCurrentPattern(UIA_TextPatternId)
        ComCall(16, element, "Int", 10014, "Ptr*", &pattern := 0)
        if !pattern
            return ""
        pattern := ComValue(13, pattern)
        textPattern := ComObjQuery(pattern, "{32eba289-3583-42c9-9c59-3b6d9a1e9b6a}")
        ; IUIAutomationTextPattern::GetSelection, then its first range
        ComCall(5, textPattern, "Ptr*", &ranges := 0)
        if !ranges
            return ""
        ranges := ComValue(13, ranges)
        ComCall(3, ranges, "Int*", &length := 0)
        if !length
            return ""
        ComCall(4, ranges, "Int", 0, "Ptr*", &range := 0)
        range := ComValue(13, range)
        ; Collapse it to its start, which is the cursor, in case text after
        ; it is selected. Not every program allows this, and the selection
        ; is usually empty anyway.
        try {
            ComCall(3, range, "Ptr*", &copy := 0)
            copy := ComValue(13, copy)
            ComCall(15, range, "Int", 1, "Ptr", copy, "Int", 0)
        }
        ; Move its start back by count characters, then read it.
        ComCall(14, range, "Int", 0, "Int", 0, "Int", -count, "Int*", &moved := 0)
        ComCall(12, range, "Int", -1, "Ptr*", &text := 0)
        result := StrGet(text)
        DllCall("OleAut32\SysFreeString", "Ptr", text)
        return result
    }
    return ""
}

; Through the messages of a standard edit control, such as Notepad's.
EditTextBeforeCaret(count) {
    try {
        hwnd := ControlGetFocus("A")
        class := WinGetClass("ahk_id " hwnd)
        if !InStr(class, "Edit")
            return ""
        ; EM_GETSEL: the start of the selection, which is the cursor.
        caret := SendMessage(0xB0, 0, 0, hwnd) & 0xFFFF
        text := ControlGetText(hwnd)
        ; A rich edit control counts a line break as one character.
        if InStr(class, "RichEdit")
            text := StrReplace(text, "`r`n", "`r")
        if caret < 1 || caret > StrLen(text)
            return ""
        return SubStr(text, Max(1, caret - count + 1), Min(caret, count))
    }
    return ""
}

; The word that ends text, or "" if a space or line break comes last.
WordAtEnd(text) {
    ; \z, not $, which would also match before a final line break.
    return RegExMatch(text, "\S+\z", &found) ? found[0] : ""
}
; The word before one final space, or "" if text does not end that way.
WordBeforeSpace(text) => SubStr(text, -1) = " " ? WordAtEnd(SubStr(text, 1, -1)) : ""
