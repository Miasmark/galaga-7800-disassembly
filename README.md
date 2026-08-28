# Galaga (Atari 7800) disassembly

A byte-identical disassembly and memory-map investigation of *Galaga*
(NTSC, Atari, 1987), built with
[a7800-toolkit](https://github.com/Miasmark/a7800-toolkit) and MAME as a
live-verification instrument, not just a static reader.

**This repo does not contain the ROM.** Supply your own legally-owned dump
(`Galaga (NTSC) (Atari) (1987) (1A0A3EB3).a78`, alongside a 7800 BIOS) to
reproduce anything here. The disassembly listing itself (`src/rom.asm`)
isn't committed either -- it's fully generated from
[`annotations.json`](annotations.json) plus the ROM, and regenerating it is
one command (below).

## Start here

[`docs/FINDINGS.md`](docs/FINDINGS.md) is the real deliverable: a narrative
of what's been confirmed live in MAME, what's still just a hint, and what
was actively distrusted, tested, and sometimes retracted rather than
assumed. Every gap in the ROM closed on day one; the wave-scoring cycle
and the full tractor-beam capture/rescue mechanic are fully solved and
live-verified, each with the wrong turns left visible next to the
correction rather than edited away. [`annotations.json`](annotations.json)
is the machine-readable form of the same knowledge.

**A deliberate methodology note for this project specifically:** a
privately-held, unlicensed historical source for this game exists (the
same archive Centipede's and Dig Dug's reference sources came from), and
it was used the same way -- as a check, never as the origin of a finding,
and never quoted or copied in. Unlike those two projects, this one held
off on even looking at it until both of the user's original gameplay
hints were fully solved independently, specifically so that whatever
agreed or disagreed could be compared against a genuinely independent
effort rather than one that had already been steered by a peek partway
through. The cross-check is written up in `docs/FINDINGS.md`: strong
structural corroboration on the tractor-beam mechanism, one specific
hypothesis (a suggested identity for a mystery byte) tested directly
against this ROM's own bytes and found wrong, and one genuine,
unreconciled disagreement left open rather than forced to agree.

Working discipline, same as the sibling projects: every claim about what a
byte range does should be checked live before it's trusted, not just
pattern-matched from a probe script carried over from a previous project.
Every `annotations.json` change is followed by JSON validation, `disasm.py`
regeneration, and a `verify.py` byte-identical round-trip check.

## Reproducing it

```
# from this directory, with the toolkit checked out as a sibling (adjust
# the path below to wherever you have it) and your own ROM copy dropped in:

python3 ../a7800-toolkit/tools/disasm.py "Galaga (NTSC) (Atari) (1987) (1A0A3EB3).a78" -c annotations.json -o src
python3 ../a7800-toolkit/tools/verify.py "Galaga (NTSC) (Atari) (1987) (1A0A3EB3).a78" -d src
# -> ROUND-TRIP PASSED
```

`src/rom.asm` is then a full listing, byte-identical when reassembled.

Add `--gaps` for a text report of every byte reached as neither code nor a
declared data block, or `--map` for the same picture as a heatmap (green
code, blue declared data, red gap -- needs Pillow):

```
python3 ../a7800-toolkit/tools/disasm.py "Galaga (NTSC) (Atari) (1987) (1A0A3EB3).a78" -c annotations.json -o src --gaps --map
```

![Coverage map](docs/img/coverage-map.png)

## Recording a session

Live findings in this project come from replaying a MAME input
recording (a deterministic button-press log, not video, and not
copyrighted content) against a PC/frame-tagged Lua probe -- the same
technique the sibling projects used throughout. Two recordings
(`run-01.inp`, `run-02.inp`) are committed in this repo; most of the
tractor-beam findings trace back to specific, cited frames in one or the
other.

```
./"Record Session.command"        # play, Esc to stop -> next free run-NN.inp
./"Play Recording.command" run-01 # watch a recording play back
```

Manual (mechanics reference, scoring table, enemy behavior):
https://atariage.com/manual_html_page.php?SoftwareID=2132

## Layout

| | |
|---|---|
| `annotations.json` | The recipe. Feed it to `disasm.py` to get the listing. |
| `docs/FINDINGS.md` | The narrative -- read this first. |
| `docs/img/` | `coverage-map.png` (regenerate with `disasm.py --map`). |
| `tools/` | This project's own probe scripts. |
| `Play Recording.command`, `Record Session.command` | Double-click launchers for replaying/recording a session (macOS + MAME on `PATH`). |

Not committed (see `.gitignore`): the ROM, the generated `src/rom.asm` and
`build/`, and the probe scripts' regeneratable output manifests -- all
reproducible from the ROM and a recording.
