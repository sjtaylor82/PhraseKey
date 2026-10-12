# PhraseKey

PhraseKey is a small Windows program that types text for you. You set up a short trigger, and PhraseKey replaces it with whatever you want: a phrase, your address, an email signature.

There are two kinds of trigger:

- **Abbreviations.** Type a short code and press Space. For example, type `brb` then Space and get "be right back".
- **Chords.** Press several keys at the same moment, like a chord on a piano, then let go. For example, press T, H and E together and get "the".

PhraseKey works in whatever program you are typing in. It has been tested with the JAWS and NVDA screen readers.

## Getting started

1. Download the zip file and unzip it anywhere.
2. Run `PhraseKey.exe`. There is nothing to install.
3. The PhraseKey window opens with your list of saved entries. To begin with there is one: the T H E chord, which types "the".

PhraseKey keeps working while its window is open, minimised or hidden.

## Abbreviations

Type the abbreviation, then press Space. PhraseKey removes what you typed and types the replacement, followed by a space.

Examples:

- `addr` could become "123 Example Street"
- `brb` could become "be right back"
- `$sig` could become your email signature

Things to know:

- An abbreviation can be 1 to 40 characters with no spaces. Letters, numbers and punctuation are all allowed.
- Capitals do not matter when you type it. `BRB` works the same as `brb`.
- Only Space triggers it. Enter, Tab and punctuation do not.
- An abbreviation that starts with a letter or number must be a word on its own. `addr` will not fire at the end of "xaddr".
- An abbreviation that starts with punctuation, such as `$sig` or `#sig`, fires wherever you type it.
- If you make a typo, use Backspace to fix it before pressing Space.

## Chords

Press two to eight keys together, then release them. The letters appear as you press, then PhraseKey replaces them, followed by a space.

Things to know:

- You can use letter keys, number keys and punctuation keys such as `;` `'` `\` `=` `,` `.` `/` `[` `]` and `-`.
- The order you press the keys in does not matter. What matters is that they are all down together before you let any of them go.
- With four or more keys, take as long as you like to get them all down.
- With two or three keys, press them quickly and together. This stops ordinary fast typing from setting one off by accident.
- Two chords cannot be the same keys, and one cannot be contained in another. For example, you cannot have both T H and T H E.
- Some keyboards cannot register many keys at once. If a large chord sometimes fails, try a different combination or fewer keys.

## Adding, changing and removing entries

1. In the PhraseKey window, choose **Add**. To change an entry, select it in the list and choose **Edit**.
2. Choose **Abbreviation** or **Chord**.
3. In **Keys**, type the trigger.
   - For an abbreviation, type it as you would use it, for example `brb`.
   - For a chord, type the keys with spaces between them, for example `t h e` or `a s ;`. Type punctuation and number keys without Shift: `4`, not `$`.
4. In **Replacement text**, type what you want it to become. It can be more than one line.
5. Choose **Save**. The entry works straight away.

To delete an entry, select it in the list and choose **Remove**.

## Hiding, pausing and closing

- **Hide** removes the window from the taskbar and from Alt+Tab. PhraseKey keeps working.
- Press **Ctrl+Alt+F11** from anywhere to bring the window back.
- Press **Ctrl+Alt+F12** from anywhere to close PhraseKey.
- Closing the main window, or choosing **Exit**, closes PhraseKey completely.
- To pause without closing, use the PhraseKey icon in the notification area and choose **Pause expansion**. Choose it again to resume.

## Sound

Check **Play sound on text replacement** in the main window to hear a short, quiet tick each time PhraseKey replaces something. It is off to begin with.

## Screen readers

### NVDA

PhraseKey will only work properly when **Handle keys from other applications** is unchecked within NVDA's Keyboard settings.

To change it: open the NVDA menu, choose Preferences, then Settings, then Keyboard. Uncheck **Handle keys from other applications** and choose OK.

If that box is left checked, replacements come out with wrong letters, or what you typed disappears and nothing replaces it. PhraseKey shows a reminder when it starts while NVDA is running. You can turn the reminder off with **Don't show this again**.

Unchecking that box means NVDA no longer responds to keys typed by other programs, such as on-screen keyboards or speech recognition software.

### JAWS

No settings need changing.

## Keyboard shortcuts

The **Keyboard shortcuts** button in the main window shows this list.

From anywhere:

- Ctrl+Alt+F11: bring the PhraseKey window back
- Ctrl+Alt+F12: close PhraseKey

In the PhraseKey window:

- Alt+E: saved entries list
- Alt+A: add
- Alt+D: edit
- Alt+R: remove
- Alt+H: hide
- Alt+X: exit
- Alt+K: keyboard shortcuts
- Alt+P: play sound on text replacement

In the Add or Edit window:

- Alt+B: abbreviation
- Alt+H: chord
- Alt+K: keys
- Alt+R: replacement text
- Alt+S: save
- Escape: cancel

## Your entries and your privacy

- Your entries are saved on your own computer and are still there after you close and reopen PhraseKey, or replace it with a newer version.
- PhraseKey does not record what you type, does not use the internet and does not use the clipboard.
- PhraseKey leaves standard Windows password boxes alone. It cannot always recognise password boxes on web pages, so pause it there if you need to.

## Limits

- Programs running as administrator, and the Windows sign-in and permission screens, do not accept text from PhraseKey.
- While you hold Ctrl, Alt or the Windows key, PhraseKey stays out of the way. It does the same while you hold Insert or Caps Lock, so screen reader commands are not affected.
- Clicking the mouse or switching to another window cancels an abbreviation or chord you were part-way through.
- PhraseKey does not work inside its own windows, so you can type triggers there without setting them off.
