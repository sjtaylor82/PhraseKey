#Requires AutoHotkey v2.0

; Update checking against the latest GitHub release. Nothing here touches the
; GUI or settings; PhraseKey.ahk decides what to tell the user.
UpdateApi := "https://api.github.com/repos/sjtaylor82/PhraseKey/releases/latest"
UpdatePage := "https://github.com/sjtaylor82/PhraseKey/releases/latest"

; Negative, zero or positive as version a is older, equal or newer than b.
; "v1.2" and "1.2.0" are equal.
CompareVersions(a, b) {
    pa := StrSplit(RegExReplace(a, "[^\d.]"), ".")
    pb := StrSplit(RegExReplace(b, "[^\d.]"), ".")
    Loop Max(pa.Length, pb.Length) {
        x := A_Index <= pa.Length && pa[A_Index] != "" ? Integer(pa[A_Index]) : 0
        y := A_Index <= pb.Length && pb[A_Index] != "" ? Integer(pb[A_Index]) : 0
        if x != y
            return x - y
    }
    return 0
}

; The version, Windows zip URL and its SHA-256 from a GitHub release in JSON.
; Url and Sha256 are "" when the release has no usable Windows zip.
ParseRelease(json) {
    if !RegExMatch(json, '"tag_name"\s*:\s*"v?([^"]+)"', &tag)
        return 0
    release := {Version: tag[1], Url: "", Sha256: ""}
    ; Each asset ends with its download URL, so an asset's digest lies
    ; between the previous asset's URL and its own.
    start := 1
    while found := RegExMatch(json, '"browser_download_url"\s*:\s*"([^"]+)"', &asset, start) {
        if RegExMatch(asset[1], "i)-win64\.zip$") {
            release.Url := asset[1]
            if RegExMatch(SubStr(json, start, found - start), '"digest"\s*:\s*"sha256:([0-9a-fA-F]{64})"', &digest)
                release.Sha256 := StrLower(digest[1])
            break
        }
        start := found + asset.Len
    }
    return release
}

FileSha256(path) {
    data := FileRead(path, "RAW")
    hash := Buffer(32)
    if DllCall("bcrypt\BCryptOpenAlgorithmProvider", "Ptr*", &alg := 0, "WStr", "SHA256", "Ptr", 0, "UInt", 0)
        throw Error("SHA-256 is unavailable")
    status := DllCall("bcrypt\BCryptHash", "Ptr", alg, "Ptr", 0, "UInt", 0, "Ptr", data, "UInt", data.Size, "Ptr", hash, "UInt", 32)
    DllCall("bcrypt\BCryptCloseAlgorithmProvider", "Ptr", alg, "UInt", 0)
    if status
        throw Error("SHA-256 failed")
    hex := ""
    Loop 32
        hex .= Format("{:02x}", NumGet(hash, A_Index - 1, "UChar"))
    return hex
}

; Fetches url without blocking; calls done(request) on HTTP 200, else done(0).
HttpGet(url, userAgent, done) {
    try {
        request := ComObject("WinHttp.WinHttpRequest.5.1")
        request.SetTimeouts(10000, 10000, 10000, 30000)
        request.Open("GET", url, true)
        request.SetRequestHeader("User-Agent", userAgent)
        request.Send()
    } catch {
        done(0)
        return
    }
    poll() {
        try {
            if !request.WaitForResponse(0)
                return
            result := request.Status = 200 ? request : 0
        } catch
            result := 0
        SetTimer poll, 0
        done(result)
    }
    SetTimer poll, 100
}

SaveResponse(request, path) {
    stream := ComObject("ADODB.Stream")
    stream.Type := 1
    stream.Open()
    stream.Write(request.ResponseBody)
    stream.SaveToFile(path, 2)
    stream.Close()
}

; Puts the PhraseKey.exe from zip in place of exePath. A running program can
; be renamed but not overwritten, so the old one becomes exePath ".old" and
; is deleted at the next start. Throws, leaving the old program, on failure.
ApplyUpdate(zip, exePath) {
    staging := A_Temp "\PhraseKey-update-" A_TickCount
    DirCreate staging
    try {
        RunWait '"' A_WinDir '\System32\tar.exe" -xf "' zip '" -C "' staging '"',, "Hide"
        if !FileExist(staging "\PhraseKey.exe")
            throw Error("The download does not contain PhraseKey.exe.")
        try FileDelete exePath ".old"
        FileMove exePath, exePath ".old"
        try FileCopy staging "\PhraseKey.exe", exePath
        catch as err {
            FileMove exePath ".old", exePath, 1
            throw err
        }
        SplitPath exePath,, &folder
        if FileExist(staging "\README.txt")
            try FileCopy staging "\README.txt", folder "\README.txt", 1
    } finally {
        try DirDelete staging, 1
        try FileDelete zip
    }
}
