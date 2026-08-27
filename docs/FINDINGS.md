# Galaga -- findings so far

`Galaga (NTSC) (Atari) (1987) (1A0A3EB3).a78`, 32K linear, no banking.
Everything below is reproducible with the
[a7800-toolkit](../../a7800-toolkit/README.md) against `annotations.json`
in this folder:

```
python3 ../a7800-toolkit/tools/disasm.py "Galaga (NTSC) (Atari) (1987) (1A0A3EB3).a78" -c annotations.json -o src
python3 ../a7800-toolkit/tools/verify.py "Galaga (NTSC) (Atari) (1987) (1A0A3EB3).a78" -d src
```

Static coverage from `tools/init.py`'s first pass (vectors only, no manual
work yet) is **35.9%** as traced code (11780/32768 bytes, 5482
instructions) -- a strong starting point, well above where the other three
projects in this series began. As of this same first day, every remaining
byte is also accounted for (`disasm.py --gaps` reports none left) -- see
"Every gap closed on day one" below for why that was mostly bookkeeping,
not a finding. Round-trip is byte-identical.

Vectors: `NMI $B15D` `RESET $FF73` `IRQ $B610`.

Manual (mechanics reference, scoring table, enemy behavior):
https://atariage.com/manual_html_page.php?SoftwareID=2132 -- 4 Command
Ships total (1 active + 3 in reserve), three difficulty levels (Novice/
Advanced/Expert). Two enemy types besides the flagship: Drones (blue, 50
pts lined up / 100 pts diving) and Hornets (red, 80/160). Flagships (yellow)
score 0 on a first hit (they lose their escort instead) and 150 on the
second; a *diving* flagship scores 400/800/1600 depending on whether it
still has 0/1/2 escorts with it. The tractor-beam capture mechanic: a
flagship can deploy a beam that captures the player's ship -- shooting the
flagship *while* it's actively capturing rescues the ship and creates a
synchronized dual-fighter; shooting it after capture completes destroys
the captured ship too. Bonus stages (formation-only, no return fire) start
after wave 2 and recur every third wave -- 5 groups of 8 ships, graduated
per-group point awards, a completion bonus for clearing all 40, and a
flat per-ship award if the pass is incomplete. Attack speed increases with
wave number. Facts only, not consulted for anything beyond this summary
list -- kept separate from the ROM's own bytes throughout the work below.

## The size question, resolved immediately

Before any code was read, the open question from picking this project was
why a 32K image would declare mapper flags of `$0000` -- the same "nothing
special" value a plain 16K cart uses. `tools/init.py` resolved it in one
run, correctly, with no manual digging needed: the 7800's own address bus
gives `$8000`-`$FFFF` as a full 32K window, so a 32K ROM fits there
*linearly*, no bank-switching hardware required at all. The sibling
projects (Centipede, Ballblazer, Dig Dug) are all 16K carts that happen to
map into the *upper* half of that same window (`$C000`-`$FFFF`); Galaga
just uses the whole thing. Not a lying header, not a bug -- the question
just had a simpler answer than the two live disassembly projects before
it, both 16K, had trained an expectation around.

## Methodology note

A privately-held, unlicensed historical source for this game exists (see
`README.md`). Deliberately not consulted yet, on the user's explicit
instruction -- the plan is to get substantially through this project's own
independent work first, then cross-check once, the same way Dig Dug's
cross-check was done, but without any earlier peek that could have steered
what got looked for. Whatever agrees or disagrees will be written up
honestly either way, per this whole series' standing discipline: never
quote or copy the reference in, never let it override live-verified
evidence from this project's own ROM, and treat disagreement as data
rather than an error to resolve in either direction.

## Every gap closed on day one -- because it was already-referenced data

The `init.py` baseline left 20850 bytes in 9 unclaimed ranges. Before
reading any of it as a mystery, checked programmatically whether the
gaps were genuinely unreferenced or just undeclared -- the same question
that turned out to matter repeatedly in the Dig Dug project. It wasn't
close: **every one of the 50 already-labeled `dat_` tables sitting inside
those 9 ranges already had a real cross-reference from already-traced
code.** None of it needed a trial entry point, a jump-table computation,
or a live probe -- it just needed the same block-declaration step Dig Dug
used repeatedly for small already-referenced tables that hadn't been
grouped into a `blocks` entry yet, done once at scale instead of one
table at a time.

Checked for the one real risk before declaring anything (the bug that
bit an earlier project in this series: a too-broad block silently
swallowing real code): swept every range for a `sub_`/`L_`-prefixed code
label and for any `JSR`/`JMP` in the traced program landing inside it.
Zero of either, across all nine ranges. Declared as nine blocks (one per
gap, following the existing boundaries rather than merging them, since
their characters weren't inspected closely enough yet to know if they're
the same resource).

**Result: `disasm.py --gaps` reports zero unclaimed bytes**, on day one,
with coverage as *code* unchanged at 35.9% (11780/32768 bytes) -- the
9 blocks are declared data, not traced instructions, so this isn't a
coverage win in the usual sense. It's an honest map of the ROM's shape:
about a third is code reached from the three vectors, and the rest is
almost entirely small, already-referenced parameter tables rather than
one or two big graphics sheets the way the 16K sibling projects had.
Whether any of these nine spans are actually graphics data (bit-plane
sprite/character sheets, the pattern the other three projects all
found) hasn't been checked -- a first skim of the raw bytes didn't show
the same dense `$00`/`$40`/`$AA`/`$FF` signature those did, but that
was eyeballing a handful of rows, not a real check.

## `run-01.inp`, and two hints from the user

A long recording (962,499 bytes) is now in the repo -- per the user, an
attempt at thorough coverage of the game's mechanics, though it doesn't
include a perfect challenge-stage clear. Two domain-expert observations
came with it, neither yet checked against the ROM's own bytes -- recorded
here as concrete, falsifiable targets for the first live probes, the same
role the Dig Dug user's own gameplay hints played in that project:

* **The bonus-stage per-group point award is not constant across the
  game -- it dropped from 1,600 to 1,000 points per cleared group around
  wave 36.** The manual's own figures (see above) don't mention this at
  all, so whatever table drives it is either wave-indexed with a change
  partway through, or there's a second mechanism entirely. A concrete,
  checkable claim: find the score-add call(s) for a bonus-stage kill, and
  see whether the awarded value is read from a small table indexed by
  wave number (or a wave-derived quantity), the same shape Dig Dug's
  veggie-value table turned out to have.
* **The tractor-beam capture mechanic has a real branch the manual's own
  summary glosses over.** Destroying the capturing flagship while it's
  still in *formation* (not actively diving) does NOT rescue the
  captured ship into a dual-fighter -- the captured fighter is released
  and comes flying at the player solo instead, behaving like an
  attacking enemy rather than a friendly rescue. The dual-fighter
  configuration only happens if the capturing flagship is destroyed
  while it is actively in flight/diving, matching the manual's "shoot it
  while it's attacking" line, but the *formation-kill* case was
  initially mistaken for a bug by the user during recording and turned
  out to be real, intended behavior. Two distinct code paths to find:
  whatever decides "released ship becomes a hostile flying at the
  player" vs. "released ship joins as a synchronized dual-fighter," keyed
  on whatever state the capturing flagship was in at the moment of its
  death.

## First live pass: BCD arithmetic found by grepping for `SED`, not by guessing

Rather than diff RAM blindly for a score-shaped byte the way the sibling
projects' first passes did, searched the static disassembly directly for
`SED` (the 6502's set-decimal-mode instruction) -- a score-add routine
has to use BCD arithmetic to display cleanly, so every `SED` in the
program is a short list of real candidates instead of a haystack. Five
turned up. Two produced solid, if not fully closed, findings; a third
looked exactly like a score-add routine on paper and turned out not to
be, live-checked and rejected rather than assumed:

**A strong match for the user's challenge-stage hint, live-corroborated.**
`rom:D021` increments a BCD counter (`ChallengeHitCount`, `ram_008A`)
each time it runs, gated by `ram_0061`. Checked against `run-01.inp`
(`tools/probe-ram-snapshots.lua`): the counter sits at 0 for the first
~29,000 of the recording's ~35,900 frames, then climbs in a burst over
about 1,500 frames (0 up to 51), then resets to 0 -- a single, late,
isolated excursion that lines up with the user's own account of
attempting a challenge stage near the end of the session. Not fully
decoded (51 exceeds the manual's 40-ships-per-stage figure, so it's
likely counting something other than a plain kill), and `ram_0061`
itself -- the gate, referenced from a wide span of code
(`$966E`-`$9E03`) not yet mapped -- is the natural next target for the
wave-36 scoring-drop question specifically.

**A rejection that turned out to be wrong, caught and corrected in place.**
`rom:93E0` looked, on paper, exactly like a two-player score-add routine:
a 3-byte BCD accumulator add with carry chaining, immediately followed by
an identical second block into a different 3-byte accumulator, selected
by an index -- structurally the same shape Dig Dug's `ScoreLo/Mid/Hi`
finding had. First checked against the existing 60-frame-interval
RAM-snapshot capture, none of the six bytes involved appeared to change,
and the finding was written up as rejected. That was wrong, and the
lesson generalizes (written up in the toolkit's own `docs/pitfalls.md`):
a follow-up narrow, unthrottled, frame-exact write-tap
(`tools/probe-challenge-writes.lua`, over the same window the challenge
stage happens in) caught the routine's own `STA` firing on *every single
frame* without exception -- mostly adding zero, but with real BCD
increments landing in exact lockstep with `ChallengeHitCount`'s own
events. The 60-frame sampling simply never landed on a frame where the
accumulated total had moved net-net; that is not the same as the code
never running. Working out the loop's own addition order (lowest digits
added first, so carry flows into the higher ones) gives the real byte
order too, which runs opposite to address order: `ram_2726` = lowest BCD
digit pair (confirmed live cycling through the full 00-99 range
repeatedly), `ram_2725` = next pair up (climbed 16->34 across the
captured window), `ram_2724` = highest pair captured here (stayed 00
throughout) -- named `ScoreHi`/`ScoreMid`/`ScoreLo` accordingly, with a
second, so-far-unobserved copy at `ram_2727`-`ram_2729` for (plausibly) a
second player. **Not fully closed**: the value this implies across the
captured window (roughly 1600-3500) reads low for many minutes of active
play at a high wave number, which leaves real doubt this is the single
master on-screen score rather than a smaller sub-accumulator -- flagged
as open, not resolved.

**A likely misidentification, caught rather than asserted -- and a real
correction to an earlier misread nearby.** A separate BCD-plus-plain-
binary counter pair (`rom:9DBE`, bytes `ram_0042`/`ram_0043`) looked at
first read like a strong wave-number candidate -- it resets to 1 (not 0)
on overflow, alongside several other bytes being cleared, matching "a new
round is starting." Checked against `run-01.inp` and it only ever reached
5, with several resets to 0 along the way -- inconsistent with the user's
report of reaching wave 36 in this same session, and still flagged open
rather than corrected to a new guess. Separately, `ChallengeHitCount`
itself needed a correction: the first live check read its raw peak byte
value (`51`) as the count directly, when it's BCD-encoded and the real
peak was **33** (`0x33`, digits '3' and '3') -- 33 out of the manual's
40-ships-per-stage figure, which lines up with the user's own account of
not getting a perfect clear almost exactly, and reads as a near-1:1 kill
count after all rather than the "points in some unit" guess made before
the correction.

## What's still open

* Whether `ram_2724`-`ram_2726` (`ScoreHi`/`Mid`/`Lo`) is really the
  single master on-screen score, or a smaller sub-accumulator that feeds
  into something bigger not yet found -- the mechanism is now
  live-confirmed active, but the value it implies reads low for the
  session length and wave reached.
* The real wave-number counter -- one candidate (`ram_0042`/`0043`) was
  checked live and looks wrong (only ever reached 5); still unfound.
* `ram_0061` (the challenge-stage gate at `rom:D021`) and the wide span
  of code that references it (`$966E`-`$9E03`) -- unmapped, and the most
  direct path to the wave-36 scoring-drop question specifically (the
  formation-pattern-selection code nearby compares a related byte,
  `ram_0046`, against `13/25/37/49/61` -- an evenly-spaced sequence
  worth checking against the wave-36 report once the byte is mapped).
* Whether `CHARBASE` gets set anywhere in this ROM at all -- the one
  write found so far (`rom:B01D`) is inside a generic zero-clearing
  boot loop, not a deliberate graphics-sheet assignment, and no second
  writer has turned up yet in the 35.9% currently traced.
* Whether any of the nine newly-declared `dat_` blocks are actually
  graphics data rather than parameter tables -- not checked yet.
* The tractor-beam capture-vs-formation-kill branch from the user's
  second hint -- not started.
* The private reference source stays unconsulted, per the plan -- see
  `README.md`.
