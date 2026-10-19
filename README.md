# PhraseKey

PhraseKey is a small Windows program that types text for you. You set up a short trigger, and PhraseKey replaces it with whatever you want, for example, a phrase, your address, or an email signature.

There are three kinds of triggers:

- **Abbreviations.** Type a short code and press Space. For example, type `brb` then Space and get "be right back".
- **Chords.** Press several keys at the same time like on a braille display or piano, then let go. For example, press T, H and E together and get the word "the".
- **Braille entries.** On a braille display with JAWS, type a sequence of braille cells, such as dots 4 5 then dots 2 3 4, and get your text. See **Braille entries**.

Straight after a word, whether you typed it or PhraseKey did, a **suffix chord** can add an ending: "walk" becomes "walking", "happy" becomes "happiness", "run" becomes "ran".

PhraseKey works in whatever program you are typing in. It has been tested with the JAWS and NVDA screen readers.

## Getting started

1. Download the zip file and unzip it anywhere.
2. Run `PhraseKey.exe`. There is nothing to install.
3. The PhraseKey window opens with your list of saved entries. To begin with there is the T H E chord, which types "the", and five suffix chords, for ing, ed, s, er and ly. See **Suffix chords**.

PhraseKey keeps working while its window is open, minimised or hidden.

## Abbreviations

Type the abbreviation, then press Space. PhraseKey removes what you typed and types the replacement, followed by a space. (You can turn the space off for an entry. See **Joining words: prefixes and no space**.)

You can also end an abbreviation with punctuation instead of Space. Type `brb.` and get "be right back.", or `brb,` and get "be right back,".

Examples:

- `addr` could become "123 Example Street"
- `brb` could become "be right back"
- `$sig` could become your email signature

Things to know:

- An abbreviation can be 1 to 40 characters with no spaces. Letters, numbers and punctuation are all allowed.
- Capitals do not matter when you type it. `BRB` works the same as `brb`.
- Space triggers it, and so do `.` `,` `;` `:` `!` `?` and `)`. See **Ending an abbreviation with punctuation** below.
- Enter and Tab do not trigger it. Many programs act on Enter or Tab straight away, for example by sending a chat message or moving to the next box, before PhraseKey could replace anything.
- An abbreviation that starts with a letter or number must be a word on its own. `addr` will not fire at the end of "xaddr".
- An abbreviation that starts with punctuation, such as `$sig` or `#sig`, fires wherever you type it.
- If you make a typo, use Backspace to fix it before pressing Space.
- **To undo an expansion,** press Backspace straight after it. `brb` Space gives "be right back "; Backspace then puts back `brb` and your Space, as you typed them. This works for abbreviations typed on the keyboard or a braille display. Only the Backspace straight after counts: once you type anything else, Backspace deletes as usual.
- To end a sentence with an abbreviation, type the abbreviation then the full stop: `brb.` gives "be right back.". Typing Space first works too: `brb` Space `.` also gives "be right back.", because PhraseKey removes its own space before punctuation.

### Ending an abbreviation with punctuation

When you type `.` `,` `;` `:` `!` `?` or `)` straight after an abbreviation, PhraseKey replaces the abbreviation and keeps your punctuation after it. No space is added, so you type the next space yourself, as usual. If **Add a space after punctuation that follows a replacement** is checked, PhraseKey adds the space for you.

Things to know:

- The apostrophe, quotes and the hyphen do not trigger an abbreviation, because they are often part of a word. `can't` won't expand a `can` abbreviation.
- An abbreviation can contain punctuation, such as `e.g`. It expands at the punctuation after it, so `e.g.` gives the replacement followed by a full stop. If you also have an abbreviation `e`, typing `e.` expands that one first.
- Punctuation that is part of one of your chords, for example `;` if you make it the suffix key, does not trigger an abbreviation. Use Space, or a different punctuation mark.
- To turn this off so only Space triggers abbreviations, uncheck **Abbreviations also expand when followed by punctuation** in **Options**.

## Chords

Press two to eight keys together, then release them. The letters appear as you press, then PhraseKey replaces them, followed by a space. (You can turn the space off for an entry. See **Joining words: prefixes and no space**.)

Things to know:

- You can use letter keys, number keys and punctuation keys such as `;` `'` `\` `=` `,` `.` `/` `[` `]` and `-`. Space can only be part of suffix chords.
- Choose chords that cannot easily be mistaken for ordinary typing. Three or more keys are safer than two, because fast typing often leaves two letter keys held down together for an instant.
- Avoid two-letter chords, especially pairs that occur in short words or at the beginnings of words. If you want a two-key chord, make one key punctuation, for example semicolon. Punctuation makes an accidental match much less likely.
- If a chord goes off during ordinary typing, try lowering **Chord timing** in **Options**. A lower value makes accidental matches less likely, but also means you must press an intended two- or three-key chord more nearly simultaneously.
- The order you press the keys in does not matter. What matters is that they are all down together before you let any of them go.
- With four or more keys, take as long as you like to get them all down.
- With two or three keys, press them all at once: they must all go down within 30 thousandths of a second to begin with. This stops ordinary fast typing from setting one off by accident. You can change the limit in **Options**; see **Fast typists**.
- Two chords cannot be exactly the same keys, but one can be contained in another. For example, you can have both W E and W E `'`: PhraseKey uses whichever set of keys you held down.
- Some keyboards cannot register many keys at once. If a large chord sometimes fails, try a different combination or fewer keys.

## Suffix chords

A suffix chord adds an ending to the word you have just written. PhraseKey removes the word, adds the ending with the spelling right, and puts the word back.

For example:

- walk, then the ING suffix chord, gives "walking"
- like, then ING, gives "liking". The E is dropped for you.
- run, then ING, gives "running". The N is doubled for you.
- run, then ED, gives "ran". PhraseKey knows irregular words.
- try, then S, gives "tries"
- child, then S, gives "children"
- happy, then NESS, gives "happiness"
- good, then ER, gives "better"

### Try it in one minute

1. Open any program you can type in, such as Notepad.
2. Type the word `walk`.
3. Press the Space bar and the I key together, then let go.
4. "walk" becomes "walking ", with a space after it, ready for the next word.

It also works with a space after the word:

1. Type `walk` and press Space.
2. Press Space and E together.
3. "walk " becomes "walked ". Either way, the new word always ends with one space.

### The suffix chords you start with

| Press together | Adds | Example |
|---|---|---|
| I and Space | ing | walk → walking |
| E and Space | ed | walk → walked |
| S and Space | s | walk → walks |
| R and Space | er | walk → walker |
| L and Space | ly | quick → quickly |

You can change, remove or add to these. See **Making your own suffix chords** below.

### When a suffix chord works

A suffix chord changes the word **immediately before it**. That word can be:

- **A word you typed**, with or without a space after it. For example `walk` then the chord, or `walk ` then the chord.
- **A word a chord or abbreviation typed.** For example, your L K chord for "like", then the ING chord, gives "liking".

A suffix chord does nothing, and its keys are typed as ordinary characters, when:

- Something other than the word came in between, such as a full stop. "walk." then the ING chord just types its keys: "walk. i" with Space as the suffix key.
- You moved the cursor, pressed Enter, Tab or Escape, clicked the mouse, or switched windows since the word. Backspace is fine while you are still in the word: `walks`, Backspace, then the ING chord gives "walking".
- The chord or abbreviation before it typed more than one word, such as "as soon as possible".

If a suffix chord does nothing and you're not sure why, press **Ctrl+Alt+F10** straight away. PhraseKey tells you why.

### Adding more than one ending

Suffix chords can follow one another. Each one changes the word the last one made:

- care, then FUL, then LY, gives "careful", then "carefully" (if you make a FUL suffix chord)
- determine, then ED, gives "determined"

### Capitals

The word keeps its capitals. "Walk" becomes "Walking", and "WALK" becomes "WALKING".

### Spelling

PhraseKey knows the forms of English words, including irregular ones such as ran, went, children, mice and better. For other words and other endings, it follows the usual English spelling rules:

- A final silent E is dropped before an ending that starts with a vowel: make → making.
- A final Y after a consonant becomes I: happy → happiness, try → tried. It stays a Y before ing: trying.
- A short word ending in one vowel and one consonant doubles the consonant: stop → stopped, big → bigger.
- S becomes ES after s, x, z, ch and sh: watch → watches.
- LY: gentle → gently, basic → basically, full → fully.

If PhraseKey gets a word wrong, you can correct it for that word. See **Word forms** below.

### Making your own suffix chords

1. In the PhraseKey window, choose **Add**.
2. Choose **Chord**, then check **Treat as suffix**.
3. In **Keys**, type the keys for the chord without the suffix key. For example, type `n` for a NESS chord. PhraseKey adds the suffix key for you, so the chord becomes N and Space pressed together. You can type the suffix key as well if you prefer; it makes no difference.
4. In **Replacement**, type the ending, for example `ness`. Use letters only.
5. Choose **Save**.

Ideas: `ful`, `ness`, `ment`, `less`, `able`, `est`, `ish`.

A suffix chord uses 1 to 7 keys plus the suffix key. Two chords cannot use exactly the same keys, so a suffix chord cannot have the same keys as one of your ordinary chords.

### The suffix key

The suffix key is part of every suffix chord. It is what tells PhraseKey you want an ending, not ordinary letters. It is Space to begin with.

You can change it to `;` (semicolon), `/` (slash) or `'` (apostrophe) in **Options**. All your suffix chords switch to the new key at once, so there is nothing to re-enter. If one of your ordinary chords already uses the same keys as a suffix chord would with the new key, PhraseKey says which and keeps the old suffix key. Change that chord first, then try again.

Which to choose:

- **Space** is under your thumb and easy to press with any letter. But when you type quickly, your thumb is often still on Space as the next word starts. Typing "walk in" fast can look like Space and I pressed together. To tell the two apart, chords with Space must go down closer together than other chords: within 20 milliseconds to begin with. See **Fast typists** below.
- **`;`**, **`/`** and **`'`** almost never overlap letters in ordinary typing, so they never go off by accident. They use your little finger instead of your thumb.

If Space chords go off while you are typing normally, either lower **Space chord timing** or change the suffix key to `;`.

### Turning off suffixes on typed words

If you only want suffix chords to work after chords and abbreviations, uncheck **Suffix chords also work on words I type** in **Options**.

You might want this if a program changes what you type behind PhraseKey's back. See **Autocorrect** under **Troubleshooting**.

## Braille entries

If you type on a braille display with JAWS, you can make a **braille entry**: a sequence of braille cells, identified by their exact dots, that PhraseKey replaces with your text. Because PhraseKey sees the dots rather than translated letters, a braille entry never clashes with ordinary contracted braille, and works whichever braille table you use.

### Typing a braille entry

1. Press **Backspace+Space+U** (dots 1 3 6 7 with Space). This is JAWS's own command to turn on Unicode braille input.
2. Type the cells, for example dots 4 5 then dots 2 3 4.

That's all. As soon as the cells match one of your entries, PhraseKey replaces them with your text and turns Unicode braille input off for you. You hear a short low tone, and you are back in ordinary braille.

### In short

- **You turn Unicode braille input on. PhraseKey turns it off.** Don't press Backspace+Space+U again afterwards: that would turn it back on, and JAWS would say so.
- **After a replacement, Space types a space as usual.** You are back in ordinary braille.
- **Enter gives a new line,** as usual.
- **A new braille entry adds no space after its text.** That way you can go straight on with punctuation, or with the rest of a word. If you want PhraseKey to add the space for you, check **Add a space after the replacement** when you set the entry up.

### Entries that start the same way

You can have one entry whose cells are the start of another's, for example 45p (dots 4 5, then 1 2 3 4) and 45pe (dots 4 5, then 1 2 3 4, then 1 5). PhraseKey can't tell which you mean until you go on:

- The longer one, 45pe, is replaced as soon as you type its last cell.
- The shorter one, 45p, is replaced when no further cell comes for 1 second. Just stop and wait for the tone.
- Or press **Space** to replace the shorter one straight away. Here Space only means "finished": it is used up, and the entry decides whether a space follows. With 45m set up as multi, with no space, 45m then Space gives multi, ready for the rest of the word. Press Space again if you do want a space.
- **Enter** also replaces the shorter one straight away, and gives a new line.

### Things to know

- PhraseKey changes nothing in JAWS. It uses JAWS's built-in Unicode braille command, and turns it off through the interface JAWS provides for other programs.
- If cells don't match any entry, they stay as typed. Press Space to finish with them: you hear a longer, lower buzz, and Unicode braille input is turned off.
- A pause of more than 3 seconds between cells starts afresh: the cells before the pause stay as typed.
- Tab, Escape or an arrow key straight after cells leaves them as typed, and turns Unicode braille input off.
- Enter only ends cells within 2 seconds of the last one. In programs that act on Enter at once, such as a chat program that sends the message, use Space instead.
- If you turn Unicode braille input off yourself before the cells are replaced, PhraseKey can't tell, and there is no tone. Cells that match a shorter entry are still replaced after the 1-second pause, and Unicode braille input then comes back on, which JAWS announces. Any other cells stay as typed: JAWS is then translating your braille, and PhraseKey stays out of its way so your text is not scrambled.
- For an entry that adds a space, punctuation straight after it replaces that space, as for any other replacement.
- To set up an entry, choose **Braille dots** in the Add window. In **Keys**, turn on Unicode braille input and type the cells; it is turned off when you leave the box. You can also type the dot numbers instead, with a space between cells, for example `45 234`.
- Switching to another program turns Unicode braille input off. That is JAWS's behaviour, not PhraseKey's.
- To keep Unicode braille input on after each entry, uncheck **Turn JAWS Unicode braille input off after a braille entry** in **Options**.
- If something doesn't work as expected, press **Ctrl+Alt+F10** straight away. It tells you which dots PhraseKey received and why they were or weren't replaced.
- NVDA has no command to turn Unicode braille input on and off, so braille entries are for JAWS for now.

## Word forms

When you add or edit a chord or abbreviation whose replacement is a single word, the window shows **Word forms** (Alt+O). It lists what each of your suffix chords will make of that word, one per line, for example:

```
ed: walked
ing: walking
s: walks
```

Only real English words are listed. For "happy" you see happier, happiness and happily, but not happying or happies, because those aren't words. PhraseKey checks against a list of about 240,000 English words.

- **If a form is wrong,** change it and choose **Save**. For example, change `ed: runned` to `ed: ran`.
- **If a form is missing,** perhaps a newer word the list doesn't have, add a line for it, such as `ing: googling`, and choose **Save**.

PhraseKey remembers your corrections for that word and uses them wherever the word appears, typed or replaced. To undo a correction, change it back to what PhraseKey suggested.

A suffix chord still works on any word, even if its result isn't in the list. The list only decides what the Word forms box shows.

## Punctuation after a replacement

When PhraseKey adds a space after a word and you then type punctuation, PhraseKey removes that space. For example, your "like" chord types "like ", and if you then type a full stop you get "like." rather than "like .".

This happens for `.` `,` `;` `:` `!` `?` `)` and `'`. The apostrophe means "like" then `'s` gives "like's".

It does not happen for `"` or `-`, because those often come after a space, as in `like "this"` or `like - so`.

It only removes a space PhraseKey added: after a chord, an abbreviation or a suffix chord. A space you typed yourself is never removed.

PhraseKey doesn't add a space after the punctuation; you type it as usual. To have PhraseKey add one, check **Add a space after punctuation that follows a replacement** in **Options**.

## Joining words: prefixes and no space

Each chord and abbreviation has its own **Add a space after the replacement** setting (Alt+P in the Add or Edit window). It is on to begin with.

Turn it off when the replacement is the start of something longer, such as:

- the start of a word: "pre", "multi", "un", "inter", "over"
- text that runs into what comes next: "@gmail.com", "https://www."

Examples:

- A "multi" chord with no space, then a "millionaire" chord, gives "multimillionaire ".
- A "pre" chord with no space, then a "determine" chord, gives "predetermine ". The ED suffix chord then gives "predetermined ".
- A "multi" chord with no space, then typing `task`, then the ING suffix chord, gives "multitasking ".

In the list of saved entries, an entry with this setting off ends with "no space after".

## When PhraseKey adds a space

The short version: **a word PhraseKey types or changes is followed by one space, ready for the next word, and that space disappears if you type punctuation next.**

In detail:

| You do this | You get |
|---|---|
| A chord or abbreviation (ended with Space) | the word and a space: `like ` |
| An abbreviation ended with punctuation, such as `brb.` | the replacement and the punctuation, no space: `be right back.` |
| A chord or abbreviation with **Add a space after the replacement** unchecked | the text with no space: `multi` |
| Punctuation straight after a space PhraseKey added | the space is removed: `like` then `.` gives `like.` |
| A suffix chord after a word, with or without a space after it | the new word and one space: `walk` or `walk ` gives `walking `, never `walk ing` |
| Another suffix chord straight after that | the same again: `care ` gives `careful `, then `carefully ` |
| Punctuation straight after a suffix | the space is removed: `walking ` then `.` gives `walking.` |

Things to know:

- PhraseKey only ever removes a space it added itself. A space you type is never removed.
- After punctuation PhraseKey adds no space; you type it as usual. To have PhraseKey add one, check **Add a space after punctuation that follows a replacement** in **Options**.
- PhraseKey never moves the cursor, and never changes anything except the word just before it.

## Troubleshooting

### A suffix chord typed its keys instead of changing the word

Something came between the word and the suffix chord, or PhraseKey lost track of the word. Press **Ctrl+Alt+F10** straight away to hear the reason. The usual causes:

- A full stop, comma or other character after the word.
- An arrow key, Enter, a click, or a change of window since the word.
- The keys were not quite together, or took too long. Two- and three-key chords must go down quickly and together.

### The ending is spelled wrong

Correct it in **Word forms** for that word. See **Word forms** above.

### Autocorrect

Some programs, such as Microsoft Word and Outlook, change words as you type, for example "dont" to "don't". PhraseKey can't see that change. If you use a suffix chord straight after a word that autocorrect has just changed, the result can be wrong by a letter or two.

If this happens often in a program you use, either turn off autocorrect in that program, or uncheck **Suffix chords also work on words I type** in **Options**. Suffix chords then only work after chords and abbreviations, which PhraseKey always tracks correctly.

### Punctuation removed a space I wanted

PhraseKey only removes a space it added itself, when the very next thing you type is punctuation. If you want a space before the punctuation, type the punctuation, then press Left Arrow and add the space. Or use a chord or abbreviation set to **Add a space after the replacement** off, and type the space yourself.

### Space chords go off while I type

When you type quickly, Space and the first letter of the next word can be down at the same time, which looks like a Space chord. Lower **Space chord timing** in **Options**, for example from 20 to 15. Or change the suffix key to `;`, which never overlaps typing.

### Chords are hard to press, or don't always work

Press **Ctrl+Alt+F10** straight after a chord that didn't work. If it says the keys were too slow, raise **Chord timing**, or **Space chord timing** for chords with Space, in **Options**. If it says a key such as Insert or Caps Lock was held down when you weren't holding it, exit PhraseKey (Ctrl+Alt+F12), start it again, and please report it.

## Options

Choose **Options** in the main window (Alt+O). Changes take effect when you choose **OK**.

- **Suffix key** (Alt+K): the key that is part of every suffix chord. Space, `;`, `/` or `'`. Space to begin with. See **The suffix key**.
- **Suffix chords also work on words I type** (Alt+W): on to begin with. When off, suffix chords only work after a chord or abbreviation.
- **Abbreviations also expand when followed by punctuation** (Alt+B): on to begin with. When off, only Space expands an abbreviation.
- **Add a space after punctuation that follows a replacement** (Alt+S): off to begin with.
- **Turn JAWS Unicode braille input off after a braille entry** (Alt+U): on to begin with. See **Braille entries**.
- **Chord timing** (Alt+C): how close together, in milliseconds, the keys of a two- or three-key chord must go down. 5 to 500, 30 to begin with. Chords of four or more keys have no limit, because typing never holds that many keys at once.
- **Space chord timing** (Alt+T): the same, for chords that include Space. 5 to 500, 20 to begin with.
- **Open the folder where your entries are saved** (Alt+F): opens the folder holding `settings.ini`. See **Where your entries are saved**.

## Where your entries are saved

All your abbreviations, chords, suffix chords, word form corrections and options are saved in one file, `settings.ini`, in your Windows profile:

```
%APPDATA%\PhraseKey\settings.ini
```

which is usually `C:\Users\your name\AppData\Roaming\PhraseKey\settings.ini`. To get there quickly, choose **Options** in the main window, then **Open the folder where your entries are saved**. The Options window also shows the full path.

- **To back up your entries,** copy `settings.ini` somewhere safe.
- **To move them to another computer,** close PhraseKey on that computer, put your copy of `settings.ini` in the same folder there, and start PhraseKey again.
- **To start afresh,** close PhraseKey and delete or rename `settings.ini`. PhraseKey starts with its built-in entries next time.

Close PhraseKey before replacing or editing the file, because PhraseKey rewrites it whenever you change an entry or option.

## Fast typists

PhraseKey is built so that typing fast doesn't lose or scramble anything:

- Chords and suffixes act the moment you let go of the keys, and punctuation is fixed the moment you type it. Each change counts exactly what you typed in the meantime, so carrying on typing straight away is normally fine.
- The one exception: a key pressed within a few thousandths of a second of letting go of a chord can, rarely, reach the program before PhraseKey's change does, especially when the computer is busy. The text then comes out wrong by a letter. Real typing is almost never that fast, but if it happens to you, pause for an instant after a chord.
- Anything PhraseKey isn't sure about, it leaves alone. Its keys are typed as ordinary characters.

The one thing fast typing affects is telling chords apart from ordinary typing, because fast typists often have two keys down at once without meaning to. The timings in **Options** control this. To tune them for the way you type:

1. Type normally for a while. If a chord goes off when you didn't mean it to, press **Ctrl+Alt+F10** straight away. It tells you which keys PhraseKey saw and how far apart they went down, for example "pressed over 42 ms".
2. Set the timing for that kind of chord a little below that number.
3. When you press a chord on purpose and it doesn't work, press **Ctrl+Alt+F10**. If it says the keys were too slow, raise the timing a little.

Most people find a good setting within a few tries. A suffix key of `;`, `/` or `'` avoids the question for suffix chords altogether.

## Adding, changing and removing entries

The saved-entry list starts each row with its replacement text, followed by its trigger and whether it is an abbreviation, chord, suffix chord or braille entry. With the list focused, type the first letter of a replacement to move to it. Use **Search saved entries** to filter the list by replacement, trigger or type.

1. In the PhraseKey window, choose **Add**. To change an entry, select it in the list and choose **Edit**.
2. Choose **Abbreviation**, **Chord** or **Braille dots**. For a suffix chord, choose **Chord** and check **Treat as suffix**.
3. In **Keys**, type the trigger.
   - For an abbreviation, type it as you would use it, for example `brb`.
   - For a chord, type the keys with spaces between them, for example `t h e` or `a s ;`. Type punctuation and number keys without Shift: `4`, not `$`.
   - For a suffix chord, type its keys without the suffix key, for example `i`. PhraseKey adds the suffix key for you.
   - For a braille entry, type the dots of each cell with spaces between cells, for example `45 134` for dots 4 5 then dots 1 3 4. Or turn on Unicode braille input with Backspace+Space+U and type the cells themselves; it is turned off when you leave the box.
4. In **Replacement text**, type what you want it to become. It can be more than one line. For a suffix chord, type the ending instead, such as `ing` or `ness`.
5. Uncheck **Add a space after the replacement** if it should run straight into what comes next.
6. Choose **Save**. The entry works straight away.

## Hiding, pausing and closing

- **Hide** removes the window from the taskbar and from Alt+Tab. PhraseKey keeps working.
- Press **Ctrl+Alt+F11** from anywhere to bring the window back.
- Press **Ctrl+Alt+F12** from anywhere to close PhraseKey.
- Closing the main window, or choosing **Exit**, closes PhraseKey completely.
- Only one copy of PhraseKey runs at a time. Starting it again, even from another folder, closes the copy already running, so two can never both replace the same text.
- To pause without closing, use the PhraseKey icon in the notification area and choose **Pause expansion**. Choose it again to resume.

## Sound

Check **Play sound on text replacement** in the main window to hear a short, quiet tick each time PhraseKey replaces something. It is off to begin with.

## Updates

A few seconds after it starts, PhraseKey checks whether a newer version is available. If there is one, it asks whether to update now.

- Choose **Update now** and PhraseKey downloads the new version, checks that the download is genuine and complete, replaces itself and restarts. Your entries and settings are kept.
- Choose **Not now** to be asked again next time. Check **Skip this version** first if you don't want to hear about that version again.
- Choose **Check for updates** in the main window to check at any time, even for a version you skipped.
- Uncheck **Check for updates when PhraseKey starts** to stop the automatic check.

If PhraseKey is in a folder it isn't allowed to change, such as Program Files, it offers to open the download page instead.

## Screen readers

### NVDA

PhraseKey will only work properly when **Handle keys from other applications** is unchecked within NVDA's Keyboard settings.

To change it: open the NVDA menu, choose Preferences, then Settings, then Keyboard. Uncheck **Handle keys from other applications** and choose OK.

If that box is left checked, replacements come out with wrong letters, or what you typed disappears and nothing replaces it. PhraseKey shows a reminder when it starts while NVDA is running. You can turn the reminder off with **Don't show this again**.

Unchecking that box means NVDA no longer responds to keys typed by other programs, such as on-screen keyboards or speech recognition software.

### JAWS

No settings need changing. For typing braille entries on a braille display, see **Braille entries**.

When you type on a braille display, JAWS puts your words straight into the document instead of typing them as keys, so PhraseKey only sees the Space. To expand an abbreviation typed this way, PhraseKey then reads the word before the cursor from the document itself. This works in most programs, including Notepad, Word and web pages. Because PhraseKey reads whatever word is there, moving the cursor to the end of an abbreviation already in the text and pressing Space also expands it. This doesn't work in boxes that fill in suggestions as you type, such as the Run box or the file name box in Open and Save windows: there JAWS's braille typing and the suggestions get out of step with any change PhraseKey makes, so PhraseKey leaves words typed on the display alone. Abbreviations typed on the keyboard still work there.

## Keyboard shortcuts

The **Keyboard shortcuts** button in the main window shows this list.

From anywhere:

- Ctrl+Alt+F11: bring the PhraseKey window back
- Ctrl+Alt+F12: close PhraseKey
- Ctrl+Alt+F10: explain the last chord attempt. If a chord doesn't work, press this straight away to hear which keys PhraseKey saw, how far apart they went down, and why it didn't replace them. It also explains the last braille cells: which dots PhraseKey received, and why they were or weren't replaced.

In the PhraseKey window:

- Alt+E: saved entries list
- Alt+A: add
- Alt+D: edit
- Alt+R: remove
- Alt+H: hide
- Alt+X: exit
- Alt+K: keyboard shortcuts
- Alt+U: check for updates
- Alt+P: play sound on text replacement
- Alt+C: check for updates when PhraseKey starts
- Alt+O: options
- Alt+B: about PhraseKey

In the Options window:

- Alt+K: suffix key
- Alt+W: suffix chords also work on words I type
- Alt+B: abbreviations also expand when followed by punctuation
- Alt+S: add a space after punctuation that follows a replacement
- Alt+U: turn JAWS Unicode braille input off after a braille entry
- Alt+C: chord timing
- Alt+T: Space chord timing
- Alt+F: open the folder where your entries are saved

In the Add or Edit window:

- Alt+B: abbreviation
- Alt+H: chord
- Alt+D: braille dots
- Alt+T: treat as suffix
- Alt+K: keys
- Alt+R: replacement text
- Alt+P: add a space after the replacement
- Alt+O: word forms
- Alt+S: save
- Escape: cancel

## Your entries and your privacy

- Your entries are saved on your own computer and are still there after you close and reopen PhraseKey, or replace it with a newer version.
- PhraseKey does not record what you type and does not use the clipboard.
- The only time PhraseKey uses the internet is to check GitHub for updates and download them. Nothing about you or your entries is sent.
- PhraseKey doesn't operate in standard Windows password controls.


## Limits

- Programs running as administrator, and the Windows sign-in and permission screens, do not accept text from PhraseKey.
- While you hold Ctrl, Alt or the Windows key, PhraseKey stays out of the way. It does the same while you hold Insert or Caps Lock, so screen reader commands are not affected.
- Clicking the mouse or switching to another window cancels an abbreviation or chord you were part-way through.

## About and licence

PhraseKey is made by Sam Taylor and is free software, released under the MIT License. The licence is in the `LICENSE` file, and in the **About** window (Alt+B in the main window).

PhraseKey.exe includes AutoHotkey (https://www.autohotkey.com), which is licensed under the GNU General Public License, version 2. AutoHotkey's source code is at https://github.com/AutoHotkey/AutoHotkey.

PhraseKey's word forms, and the list of English words it checks them against, come from AGID (the Automatically Generated Inflection Database) and SCOWL (Spell Checker Oriented Word Lists), both by Kevin Atkinson (http://wordlist.aspell.net). They include material from WordNet 1.6, Copyright 1997 by Princeton University, and other sources. The full copyright and licence terms are in `WORDLIST-NOTICE.txt` and the **About** window.
