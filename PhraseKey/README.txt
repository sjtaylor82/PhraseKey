PhraseKey 0.8
Windows, AutoHotkey v2.

GLOBAL OPERATION

Run PhraseKey.ahk with AutoHotkey v2, or run your compiled PhraseKey.exe.
Expansion is active across applications while the program runs. There is no
practice mode or Notepad opt-in. Choose Hide or switch to another application to type. The entry manager and its dialogs are excluded so you
can enter and edit triggers without expanding them.

The main window contains the saved-entry list and Add, Edit, Remove, Hide and
Exit. Hide (Alt+H) removes the window from the taskbar and Alt+Tab while leaving
expansion running. Its icon remains in the Windows notification area.
Press Ctrl+Alt+F11 from another application to restore the entry list. You can
also select Open entries from its notification-area menu. A user does not need
to navigate the tray to restore the window. The ordinary title-bar minimise
button still minimises normally; choose Hide for removal from Alt+Tab.
Alt+F4 on the main window, closing it, or choosing Exit stops expansion
completely. Alt+F4 in an Add/Edit dialog cancels that dialog only.
Ctrl+Alt+F12 exits even when the window is hidden. The notification-area menu has Open entries, Pause
expansion and Exit. Pause is temporary and resets when the program restarts.

MANAGING ENTRIES

1. Choose Add, or select an existing entry and choose Edit.
2. Select the Abbreviation or Chord radio button with the arrow keys.
3. Enter the trigger in Keys, then enter the replacement text.
4. Choose Save. The entry becomes active immediately and is saved locally.

Alt+A adds; Alt+D edits; Alt+R removes; Alt+E focuses the list; Alt+H hides;
Alt+X exits. Alt+K opens a Keyboard shortcuts list. Alt+P toggles the "Play sound on text replacement" check box:
when checked, a short quiet tick plays each time an abbreviation or chord is
replaced. It is off by default and the choice is saved.
In the entry dialog: Alt+B selects Abbreviation, Alt+H selects Chord,
Alt+K focuses Keys, Alt+R focuses Replacement, Alt+S saves, and Escape cancels.
Editing changes the selected entry, including its type or trigger, rather
than leaving an old duplicate. Duplicate triggers are rejected.

ABBREVIATIONS

Type the abbreviation normally, then press Space. Examples:
addr -> 123 Example Street
brb -> be right back
$sig -> your email signature
#sig -> a second signature

An abbreviation is 1 to 40 characters with no spaces: letters, digits and
punctuation in any mixture. Input matching is case-insensitive; replacement
text uses the exact saved case. Space is the only expansion trigger; Tab,
Enter and punctuation do not trigger it.

An abbreviation that starts with a letter or digit must be a whole word:
addr does not expand at the end of xaddr, but does after punctuation, as in
"(addr". One that starts with punctuation, such as $sig, expands after
anything, including directly after a word. If more than one abbreviation
fits, the longest wins.

Backspacing to correct an abbreviation before pressing Space works. Arrow
keys, Enter, Tab, a mouse click or switching window start a new word.
Replacement text is literal, can contain multiple lines, and does not execute
script commands. It does not trigger another expansion recursively.

CHORDS

Press two to eight different keys together, then release them. Chord keys
are letters, digits and the punctuation keys, such as ; ' \ = , . / [ ] - and `.
Enter them in the Keys field as typed without Shift, separated by spaces if
you like: a s ; rather than A S :, and 4 rather than $.
The default T H E chord inserts "the" followed by a space.
Key order does not matter. A key cannot be repeated within a chord.
All keys must be down together before the first key is released. Chords of
two or three keys must also go down within 90 milliseconds by default, because
fast typing can overlap that many keys. Chords of four or more keys have no
time limit: get every key down, in any order and at any pace, then let go.

Once an exact chord is held, you can release at your own pace. It expands once,
when the last key is released. The letters appear as you press them and are
then erased and replaced. Incomplete combinations simply stay as the letters
typed. Fast normal typing can overlap enough to resemble a chord;
this is a timing trade-off rather than something software can always resolve.
Chords may share keys but cannot be subsets of one another: T H and T H E
cannot coexist. Abbreviations and chords can coexist independently.
Keyboard rollover can depend on the particular combination, even when some
other eight-key combinations work.

SAVING AND UPGRADING

Settings and entries remain in %APPDATA%\PhraseKey\settings.ini.
Existing chords and one-letter/string entries are loaded automatically.
Legacy triggers longer than AutoHotkey's native 40-letter limit remain saved
and visible but inactive; edit them to use a shorter abbreviation.
Replacing the scripts or compiled EXE does not remove these saved entries.
Typed text is not logged. There is no network access or clipboard use.

HOW IT WORKS, AND SCREEN READERS

PhraseKey never holds back, re-sends or reorders what you type. Every key goes
straight to the application; PhraseKey only watches. When it recognises an
abbreviation followed by Space, or a chord, it sends Backspaces to erase what
was typed and then types the replacement.

NVDA USERS: REQUIRED SETTING

NVDA's setting "Handle keys from other applications" is on by default. With it
on, NVDA takes over simulated keys as soon as a Backspace is sent into an edit
field and relays them itself, out of order. Expansions then come out scrambled
(wrong letters, lost capitals) or are erased with nothing typed,
which looks as if PhraseKey has stopped. No way of sending the text avoids it.

Turn the setting off: NVDA menu (NVDA+N), Preferences, Settings, Keyboard,
uncheck "Handle keys from other applications", OK. NVDA then ignores keys sent
by PhraseKey and other programs, and passes them straight to the application.
It will no longer speak or act on keys typed by on-screen keyboards or speech
recognition software, which is the purpose that setting serves.

When PhraseKey starts while NVDA is running, a dialog reminds you of this.
PhraseKey cannot read NVDA's setting, so the reminder does not say whether it
is on or off. If PhraseKey then sees NVDA intercepting a replacement, a second
dialog says so, once per run; it takes the focus from where you were typing.
Check "Don't show this again" in either dialog to stop both appearing.

The interface deliberately has no timing/settings panel. Existing preferences
are retained. For manual tuning, close the program and edit WindowMs in the
Options section of settings.ini (20 to 500 milliseconds). Lower means stricter
chords; higher makes them easier to press but increases accidental matches.
TrailingSpace=1 adds a space; TrailingSpace=0 omits it. Restart after editing.

DISTRIBUTING AN EXE

Keep PhraseKey.ahk and ChordEngine.ahk together when building. Compile only
PhraseKey.ahk using Ahk2Exe and an AutoHotkey v2 base executable. The included
engine is embedded into the EXE. Recipients need only PhraseKey.exe, without
AutoHotkey or any AHK source files. SelfTest.ahk is a developer test, not a
runtime dependency. The Windows release ZIP includes the EXE and this README.

VALIDATION AND LIMITATIONS

Version 0.8 was checked on Windows 11 with simulated typing into a standard
edit field: abbreviations, backspace correction, whole-word matching, and
3-, 6- and 8-key chords. With NVDA running at its default settings the same
tests fail as described above; with that NVDA setting turned off they pass.
Version 0.7 also passed with JAWS running; 0.8 has not been run with JAWS.
Simulated typing is not a physical keyboard, so try it by hand as well.
Global scope does not guarantee every editor accepts simulated input. Elevated
applications, secure desktops and some remote/custom editors may not accept
it. Conventional Windows password edit controls are excluded; custom/browser
password fields cannot be reliably identified by this prototype. Pause the
program when required. JAWS typing echo and letter-navigation commands need
hands-on testing with its keyboard hook alongside AutoHotkey.

Ctrl, Alt, Windows, held Insert and held Caps Lock bypass expansion. A click
or change of window cancels any pending chord or abbreviation. PhraseKey's own
windows are always excluded.

Suggested Windows checks:
1. Add addr = 123 Example Street as an Abbreviation. Test addr then Space in
   Notepad, Word, an email editor and a browser text field.
2. Verify ordinary words, backspacing and JAWS commands remain usable.
3. Test T+H+E with varied press/release orders and normal typing of "the".
4. Add a six- or eight-key chord and confirm one expansion per release.
5. Check Add/Edit/Remove, radio labels and restart persistence. Choose Hide
   and confirm it disappears from Alt+Tab while expansion still works in
   another app. Press Ctrl+Alt+F11 to restore the main window, press Alt+F4,
   and confirm expansion has stopped.
6. Compile the main script and test the EXE on a PC without AutoHotkey installed.

SelfTest.ahk exercises the actual chord recogniser, including six- and
eight-key chords, using deterministic events. It does not test abbreviations,
keyboard-hook integration, GUI operation or screen readers.
