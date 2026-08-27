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
  veggie-value table turned out to have. **RESOLVED -- see "The wave-36
  hint, solved" below.** Not wave-indexed at all: a cyclical gate keyed
  to a completed-challenge-stage counter, and the "drop" the user saw is
  the first low point of a repeating 32-wave cycle, not a permanent
  change.
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
  death. **RESOLVED -- see "The tractor beam, solved" further down.**
  The "formation-kill vs. diving-kill" framing turned out not to be the
  real mechanism (a specific circumstantial guess along those lines was
  made and then retracted); the real one, directly confirmed on screen
  and in the collision code: getting hit while a rescued escort is
  attached costs the escort, not a life -- matching the user's own
  fuller description (dual-fighter for most of a 37-wave run, one hit
  reverting it to single) once that arrived.

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
each time it runs, gated by `ram_0061`. Checked against the first pass
through `run-01.inp` (`tools/probe-ram-snapshots.lua`, which at this
point in the project only covered roughly the first 35,900 of the
recording's real 104,454 frames -- see "Found the wave counter" below):
the counter sits at 0 for the first ~29,000 of those frames, then climbs
in a burst over about 1,500 frames (0 up to 51), then resets to 0 -- an
isolated excursion that lines up with the user's own account of
attempting a challenge stage. (Whether this is the only such excursion in
the full recording, or just the first, hasn't been re-checked against the
corrected frame range.) Not fully
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

**A rejection that was itself wrong -- caught much later, and for a
different reason than the byte itself.** A BCD-plus-plain-binary counter
pair (`rom:9DBE`, bytes `ram_0042`/`ram_0043`) looked at first read like a
strong wave-number candidate -- it resets to 1 (not 0) on overflow,
alongside several other bytes being cleared, matching "a new round is
starting." Checked against `run-01.inp` and it only ever reached 5, with
several resets to 0 along the way -- inconsistent with the user's report
of reaching wave 36 in this same session, so it was set aside as rejected.
**That rejection was wrong, and not because the candidate was bad: the
probe checking it was silently reading only the first third of the
recording.** See "Found the wave counter" below for the full story --
`ram_0042`/`ram_0043` *is* the wave counter after all, and the original
instinct here (resets to 1, clears sibling bytes, matches "a new round")
was correct the whole time. Left here rather than deleted, per this
project's own convention of keeping a wrong conclusion visible next to its
correction instead of quietly rewriting history. Separately, `ChallengeHitCount`
itself needed a correction: the first live check read its raw peak byte
value (`51`) as the count directly, when it's BCD-encoded and the real
peak was **33** (`0x33`, digits '3' and '3') -- 33 out of the manual's
40-ships-per-stage figure, which lines up with the user's own account of
not getting a perfect clear almost exactly, and reads as a near-1:1 kill
count after all rather than the "points in some unit" guess made before
the correction.

## Mapping the challenge-stage gate: a timer found

Traced `ram_0061` (the gate at `rom:D021`) back to its source rather than
guessing at its meaning directly. It's set by a small state machine built
around `ChallengeCountdown` (`ram_00BD`, newly named): a per-tick timer
armed to `$80` (128) at two points -- game boot, and inside the same area
that increments the `ram_0042`/`0043` pair discussed below -- and
decremented once per pass through `rom:sub_9D87` (itself gated on an
unidentified pause/animation-lock byte). `ram_0061`'s challenge-stage
window opens specifically when the countdown reaches `$60` -- 32 ticks
after being armed -- and a separate path (the countdown reaching 0
without that condition firing) resets `ChallengeHitCountBin` and two
other bytes, reading as a timeout/cleanup distinct from a real
challenge-stage entry. This is real structure, not a guess -- but it
explains *when* the challenge window can open within a single ~128-tick
cycle, not what determines that a given wave is a challenge wave in the
first place, and it doesn't reach the wave-36 point-value question
directly.

**`ram_0046` reinterpreted, and a live dead end.** Following the
countdown-timer thread led to `rom:sub_9D0F`, which resets `ram_0046` (the
byte compared against `13/25/37/49/61` in the formation-pattern code) to
1. That routine only runs at boot and from inside the countdown-timer
area -- neither fires once per wave -- while live data shows `ram_0046`
cycling through roughly 1-62 dozens of times across the ~10-minute
recording, far more often than a per-wave reset would produce. Revised: a
per-formation-entry-step sub-counter *within* a wave, not the wave number.
Separately chased a promising-looking candidate, `ram_2775`
(mostly-monotonic by a coarse first/last comparison, climbing to the low
30s-40s by the end of the recording) and ruled it out on closer
inspection: the full frame-by-frame trajectory is a continuous sawtooth
oscillation the entire session, not a step counter -- the coarse
comparison that flagged it only looked at endpoints and missed the
back-and-forth in between. Matches its code usage (`INC`/`DEC` on a
per-object indexed array, most likely enemy movement/animation phase, not
game progress).

**Net for this pass:** more of the challenge-stage machinery is mapped
(a real countdown timer, a real entry-window condition, a real timeout
path), and one more wrong-looking byte was caught and written up as wrong
rather than left as an untested guess. The wave-number counter itself
turned out to already be in hand (`ram_0042`/`ram_0043`, rejected two
sections up) -- just checked against a probe that was quietly reading
only the first third of the file. See below.

## The real score display, found and screenshot-verified -- and a bigger surprise

Following up on the manual's own note ("waves display at lower right")
found the on-screen digit-rendering code the same way `ram_0043`'s
(unrelated) render use was found earlier: grepping for the digit-split
idiom (`AND #$0F` plus four `LSR`s). That led to `rom:sub_B406`, and this
time the check wasn't just live RAM behavior -- it was a direct
screenshot comparison. Captured a screenshot *and* a full RAM dump at the
exact same frame, twice, at two different points in `run-01.inp` where
the on-screen score read 28,200 and 32,250. Both times, five consecutive
bytes at `$275F`-`$2763` held those exact digits, byte for byte, most
significant first (`ScoreDigit0`-`ScoreDigit4`). This is about as solid
as live confirmation gets in this project -- not a behavioral pattern
match, a literal byte-for-byte comparison against what was on screen at
that instant.

It also *retracts* last pass's `ScoreHi`/`Mid`/`Lo` naming for
`ram_2724`-`ram_2726`. That accumulator is still real and still fires
every frame as documented, but it isn't backing the on-screen score. What
`ram_2724`-`ram_2726` actually is stays open; the labels were removed
rather than left wrong.

## Found the wave counter -- after finding and fixing a bug in this project's own probes

The "score never exceeds ~32,000, the wave-36 run isn't in this
recording" conclusion two commits ago was wrong, and wrong for a
specific, findable reason: **every probe script in this project, from
the very first one, had been calling `MACHINE:exit()` based on a wrong
belief about where `run-01.inp` ends.** An early exploratory run used an
exit threshold around frame 35,900 (an arbitrary early guess); MAME's
own "Total playback frames: N" summary line, printed at whatever point
the *process* stops (not necessarily where the recording's real content
ends), then reported a number in that same neighborhood -- and that
number was mistaken for the file's true length. Every subsequent probe
inherited a similarly-sized exit threshold, so every one of them
"confirmed" the same wrong boundary, including the real-time re-run that
was used to rule out a `-nothrottle` desync (that test was internally
valid -- both runs agreed with each other -- it just wasn't testing far
enough to matter).

The user gave the fix directly: they'd watched past that point using
`Play Recording.command` *without providing any input themselves*, and
the game kept going regardless. That's the tell -- if the game keeps
progressing with nobody touching the controls, the recording's real
content must extend further than assumed, since `Play Recording.command`
doesn't feed anything after the file ends. Removed the artificial exit
threshold, replaced it with one far beyond any prior guess (300,000
frames), and reran. The recording's real length is **104,454 frames**
(~29 minutes, not ~10) -- playback exhausts there and the game freezes on
a static state, almost certainly the last life being lost. This project
had only ever analyzed the first third of the file.

**With the real range, `ram_0042`/`ram_0043` (`Wave`/`WaveBCD`) is
confirmed as the wave counter, exactly as first guessed.** Sampling every
6000 frames from 6000 to 102000, `ram_0042` (raw binary) and `ram_0043`
(properly BCD-decoded -- high nibble times 10 plus low nibble, not its
raw byte value, which was the error that made this pair look like it
"only reached 5" during the truncated-data pass) agree with each other
exactly at every single checkpoint, and both track the confirmed score
digits the way a wave counter should: value 16 at a score around
111,520, value 28 at a score around 201,980 -- matching the user's own
recollection (~wave 17 at ~111K, wave 28 at ~200K) almost exactly, wave
28 landing exactly on the number given. `rom:sub_9DBE`'s reset-to-1 (not
0) on BCD overflow, previously read as "probably a new-wave reset, but
not proven," is now confirmed as exactly that.

**Lesson for the toolkit**, written up in `docs/pitfalls.md`: never trust
"traced across the whole recording" from a probe whose own exit condition
was chosen without independently verifying the file's real length first
-- a `.inp` playback that appears to end is not the same as the file
actually being that short, especially if the game can keep running
without further recorded input.

## The wave-36 hint, solved: a cyclical gate, not a one-time change

Went after this directly rather than waiting for another recording: found
the actual challenge-stage scheduler (`rom:9DD8`) by tracing `ram_0061`
(the challenge-active flag `rom:D021` gates on) back to every place that
sets or clears it, and found the score-value gate (`rom:sub_D097`) by
tracing forward from the packed-BCD score accumulator (`rom:93E0`) to
every place that stages a value for it.

**What schedules a challenge wave** (also closes an item that was open
since the countdown-timer pass): `rom:9DD8` runs once per wave, at the
same single-tick gate as everything else in this area
(`ChallengeCountdown` reading exactly `$60`), and tests `Wave mod 4 == 2`
via repeated subtraction. If true, it sets `ram_0061` and this wave is a
challenge stage. Live-checked against the full recording
(`tools/probe-groupvalue.lua`): challenge stages fire at wave 26, 30, and
34 in the 80,000-104,454 frame range with no exceptions -- exactly the
predicted schedule.

**What sets the per-group point value:** each challenge stage awards a
bonus every 8 kills (`ChallengeHitCountBin` wrapping 7->0). The amount is
gated by a new byte, `ram_005A` (`ChallengeValueCycle`): incremented once
per *completed* challenge stage at `rom:9DD8`, wrapping back to 0 at 8.
`rom:sub_D097` reads it: if `ChallengeValueCycle >= 4`, it forces a clean
`+1,600` (writes a fixed `$0160` into the score-accumulator staging
bytes, overwriting whatever was there); if `< 4`, it stages `+1,000` but
-- asymmetrically -- doesn't clear the low staging byte first, so
whatever that specific 8th kill's own per-kill point value already was
(50/80/100/160, depending on enemy type, set moments earlier the same
frame at `rom:D053`-`rom:D08F`) rides along on top of the 1,000.

Since `ChallengeValueCycle` cycles 0-7 across 8 consecutive challenge
stages (32 waves, one stage per 4 waves), stages land in the **low half
for roughly waves 2-14 of every 32-wave block, and the high half for
roughly waves 18-30**, then drop straight back to the low half at the
next block's first stage. Live-verified with
`tools/probe-groupdelta.lua`, capturing the exact score digits
immediately before and after each group-of-8 bonus: the wave-30 stage
(`ChallengeValueCycle`=7) shows two clean `+1,600` jumps; the cycle then
wraps to 0, and the very next stage -- **wave 34** -- shows `+1,160` and
`+1,100` (1,000 plus that group's own 8th-kill value, matching the
asymmetric-code prediction exactly). Wave 34 is the stage that leaves the
on-screen wave counter reading **36** once it finishes -- matching "around
wave 36" almost exactly.

**This is a better answer than the question implied.** The user's hint
described the point drop as something that happened once, around wave
36. It isn't a one-time change at all -- it's a repeating 32-wave cycle,
and wave 34 just happens to be the *first* low-half stage the recording
reaches. If play had continued, the value should climb back to a flat
`+1,600` again around wave 50 (the next time the cycle reaches 4) --
not checked live, since `run-01.inp` ends at wave 36.

## The tractor beam, solved: capture, rescue, and the "free hit" all directly confirmed

Went after the user's second hint next, through three rounds of
correction from the user's own live-play ground truth -- each one worth
recording because each fixed a wrong assumption this project had made
from code alone.

**Round 1: the capture-attempt sequence, found by tracing forward from a
diving enemy's own state machine.** `rom:sub_903E` runs on a diving
enemy each frame; once it has descended past a fixed depth
(`ram_1E63,Y >= $78`), it arms `CaptureAttemptTimer` (`ram_00B4`) to
180, saves that enemy's index into `CapturingEnemyIndex` (`ram_005C`),
and plays two cue sounds. The timer ticks down once per frame
(`rom:sub_9081`), twice per frame once `Wave >= 18` (a real, if minor,
difficulty-scaling detail).

**Round 2: the user corrected the scope ("a few times early on"), and
the actual capture was directly confirmed on screen.** Tapped every
write to `CaptureAttemptTimer`/`CapturingEnemyIndex` across the whole
early game (`tools/probe-capture2.lua`, frames 0-40,000, `-nothrottle`
throughout, per standing practice for a recording this long). Found
**five** capture-arm events, not the two this project had found via
score/spawn-flag taps alone, reusing two formation slots
(`CapturingEnemyIndex` = `$1A` twice, `$11` twice, `$23` once).
Screenshotted the aftermath of all five: **every one shows the actual
on-screen "FIGHTER CAPTURED" text and tractor-beam graphic** (a striped
triangle from the diving boss to the player), about 60 frames after the
depth-threshold arm -- inside the 180-frame countdown, confirming a
separate, faster beam/player collision check exists. Also confirmed:
**getting captured costs a life exactly like dying** (a "READY" respawn
prompt, the ship-icon lives count drops by one).

At this point the project made a guess it shouldn't have: `CapturingEnemyIndex`
gets read back at `rom:sub_D36C`, called from the `CPY #$28` score/spawn
branch already mapped while solving the wave-36 hint (`rom:D01C`,
+1,000 points, spawn-flag `$0B`). Sequencing frame numbers against the
game's own early resets made one specific capture and that specific
`CPY #$28` kill look like the same continuity, and this got written up
as "probably the released-as-hostile case" -- a guess from timing
adjacency alone, flagged as circumstantial at the time.

**Round 3: the user gave the real ground truth ("dual fighter for most
of the 37-wave run, one hit brings it back to single"), and the earlier
guess turned out to be checking the wrong branch entirely.** A wide
periodic screenshot pass across the *whole* recording
(`tools/probe-dualfighter.lua`, every 4,000 frames, `-nothrottle`)
followed by cropped/upscaled comparisons made the dual-fighter's wider
two-ship silhouette directly visible: single at wave 5 (frame 36,000),
dual by wave 12 (frame 52,000), still dual at wave 26 (frame 79,950),
single again by wave 28 (frame 84,000). Binary-searching the transition
(`tools/probe-narrow2.lua` and finer follow-ups) landed the hit itself
at **frame ~80,300** -- an explosion sprite is directly visible right on
the ship at that exact frame.

With confirmed single/dual reference frames in hand, a cluster analysis
(bytes consistent within each pair of same-state frames, differing
between the two states -- across zero page, `$1D00-$1FFF`, and
`$2700-$27FF`, not just zero page) isolated **`DualFighterFlag`
(`ram_1E11`, newly named)**: 0 when single, 5 when dual, matching all
four reference frames exactly. A direct PC-tagged write-tap confirmed
where it's set: **`rom:92B3`**, the tail end of a multi-stage "returning
captive" animation inside `rom:sub_9250` (called every frame from the
main loop, gated on `ram_1E43` reaching `$50`, then `ram_1E8B` reaching
`$AB`, then `PlayerX` (`ram_1E5A`, newly named) reading exactly `$49`).
Both real occurrences of this write in the first 55,000 frames (frame
13,953 and frame 37,713) fire from this exact instruction -- the first
short-lived (reverts by frame 14,964), the second the long-lived one
that persists from wave 5 through wave 26, genuinely "most of the run"
once the early false-start games settle into the long sustained session.
**Neither lines up with a `$0B`/`CPY #$28` event nearby** -- the earlier
circumstantial guess was checking the wrong branch, and the comment at
`rom:9065` has been corrected in place to say so rather than left
looking right by accident.

**What being hit while dual-fighter actually does, confirmed from the
collision code itself, not just inference:** `rom:sub_D0C7` (the
player-enemy proximity check, comparing enemy X positions against
`PlayerX`) calls `rom:sub_D1D3` on a close approach, which clears
`DualFighterFlag` back to 0 instead of running the normal death path --
exactly "the first hit only brings it back to a single fighter," found
in the actual collision-resolution code rather than assumed from the
visual evidence alone.

**Net for this pass:** the full tractor-beam lifecycle is now directly
confirmed -- capture (with its on-screen text and life cost), rescue
into a dual-fighter (with the exact byte and the exact instruction that
sets it), and the no-death "free hit" mechanic (found in the collision
code). One detail was still open at the end of this pass: what
specifically *arms* the returning-captive sequence, as opposed to
completing it at `rom:92B3`. See the next section for how that closed,
and for a real surprise in what the answer turned out to be.

## `run-02.inp`: a second, targeted recording -- first pass wrong, corrected after the user caught it

The user made a short follow-up recording (~4 waves, confirmed at
10,330 frames via the same length-check discipline as `run-01.inp`,
`tools/probe-len02.lua`) specifically to catch a capture-and-merge early,
aimed squarely at the one open detail from the previous pass.

Tapping the whole known state chain across this much shorter file
(`tools/probe-run02.lua`: `CaptureAttemptTimer`, `CapturingEnemyIndex`,
`ram_1E43`/`ram_1E8B`/`ram_1E12`, `DualFighterFlag`, the score/spawn-flag
byte) found a capture-arm at frame 3,568 and `DualFighterFlag` set at
frame 5,007 -- a clean ~1,400-frame window, far more tractable than
hunting through the 104,454-frame original.

**First pass, wrong: "the capture never completes."** Screenshotted a
sparse set of frames in that window (3,568 / 3,600 / 3,628 / 3,660 /
3,768 / ...) and, seeing no "FIGHTER CAPTURED" text and an apparently
unchanged lives count at the frames actually *looked at*, concluded the
game has a reposition-based evasion window and the ship is never really
taken. **This was wrong, and wrong for an avoidable reason:** the
sparse screenshot set had already been taken at finer spacing including
frame 3,700 -- sitting squarely inside the capture window -- and that
frame, along with several others, simply wasn't opened before writing
the conclusion up. The user caught it directly: "There was a life lost
and a fighter capture shown in the shots you were looking at."

**Corrected, verified frame-by-frame.** A full re-check at 5-frame
resolution across the whole window (`tools/probe-run02recheck.lua`),
this time actually viewed in full, shows: `CaptureAttemptTimer` counts
down its complete, uninterrupted 180-frame course; "FIGHTER CAPTURED"
is on screen for roughly 80 frames (first visible ~frame 3,670, gone by
~3,800); the ship-icon lives count drops from 2 to 1; a "READY" respawn
prompt follows around frame 3,900 -- identical in every respect to
every capture in `run-01.inp`. The capture is never prevented.

**What `rom:sub_90DE` actually does, re-verified with a direct write-tap
instead of inference** (`tools/probe-run02verify.lua`, tapping `ram_0089`
directly and sampling `PlayerX`/`CaptureOriginX`/`CaptureAttemptTimer`
every 10 frames): during a specific mid-countdown band of
`CaptureAttemptTimer` (`$3C`-`$78`), it checks whether `PlayerX` is
still within 12 pixels of `CaptureOriginX` (the position saved at the
instant of arming). In this recording the ship barely moved during the
(likely input-locked) capture animation -- `PlayerX` and
`CaptureOriginX` sat 2 pixels apart the entire time -- so the check
passed almost immediately, arming `ram_0089` at frame 3,629, exactly
inside the predicted window. That flag then sits pending until the new
ship has actually respawned and become controllable (`ram_0089` cleared
by `rom:sub_8B53` at frame 3,876, right where `PlayerX` starts changing
under real input again), which queues the returning-captive animation
that completes at `rom:92B3` (`DualFighterFlag` set at frame 5,007).

**The real mechanic:** getting captured always costs a life and plays
out in full, exactly as it always did. Separately, if the ship stayed
near the capture point during a specific window of that same sequence,
the captured ship is queued to automatically merge with the *next*
spawned ship as an escort, rather than being lost for good or turning
hostile -- softening the cost of a capture without preventing it.
Whether this position check is close to automatic in practice (the
captured ship may not be player-movable during the beam sequence at
all, making a passing check the common case) or can meaningfully fail
is still open -- `run-01.inp` had five confirmed captures but only two
real `DualFighterFlag`-forming events, so it evidently doesn't always
succeed, and what differs between those cases hasn't been checked.
Whether a kill-based rescue path (shoot the diving captor) *also*
exists alongside this one remains unconfirmed either way.

**Lesson for next time, written up for the toolkit too:** a screenshot
sweep is only as good as the screenshots actually opened. Taking a
finer-grained capture and then eyeballing a coarse subset of it
re-creates exactly the kind of gap a periodic sample leaves -- the
frames that would have overturned the conclusion were sitting on disk,
unopened, the whole time.

## The kill really does matter -- the user was right about that too, confirmed frame-by-frame

Even after the correction above, this project's read of `rom:sub_90DE`
(a proximity check, arming the merge on its own) was still incomplete.
The user, watching this same recording, pointed at the exact moment:
"the specific foe is killed when the score turns 4500->4900, spins for
a couple of seconds" -- and asked for that to be checked directly rather
than taken on faith a third time.

It checked out. That kill (frame 4,609) goes through the same
`sub_CFEA`/`sub_CFEF` collision-resolution path already mapped while
solving the wave-36 hint (landing on the ordinary +400 default case,
not the `CPY #$28` branch). Tracking `ram_1E43`/`ram_1E8B` every 5
frames (`tools/probe-run02kill2.lua`) shows them **freeze** solid from
about frame 4,610 to about frame 4,870 -- right where the kill happens
-- and a tight consecutive-frame screenshot check during that freeze
shows a small sprite at the kill site visibly changing shape/orientation
frame to frame: a real spin, not a static object or a simple explosion
burst. Once the freeze ends, both values climb cleanly to their
completion targets, finishing at frame 5,007 -- "a couple of seconds"
of visible spin-and-return, matching the user's account closely.

This makes the earlier framing in this project's own `rom:90DE` comment
("the proximity check at frame 3,629 is what leads to the merge")
look wrong on its own terms, independent of the user's correction: that
arm event fires 1,378 frames before completion, far too early to be
what a "couple of seconds" tied to a specific kill 1,040 frames later
is describing. The more likely shape, **not yet confirmed at the
instruction level**: something early (plausibly that same proximity
check) arms a watcher, but the captive can't begin its own tracked
return until whatever is carrying it is actually destroyed -- gated,
plausibly, on whether the enemy at `CapturingEnemyIndex` is still
alive. No PC has been identified yet that reads `CapturingEnemyIndex`
and gates the freeze/resume on it directly; that's the concrete next
step, not a re-guess.

**Net for this whole thread:** three real corrections in a row, each
one caught either by the user's direct correction or a targeted
re-check rather than continued guessing -- capture always happens,
capture-with-eventual-merge is real, and the kill genuinely gates the
merge's completion. What's still missing is the specific instruction
that connects the kill to the freeze ending, and that gap is being
left open rather than filled with a fourth guess.

**Visually confirmed, on direct instruction: the boss and its captive
fly in formation the whole time.** Screenshotted every 20 frames from
the moment the new ship respawns (frame 3,900, "READY" still on screen)
through the kill (frame 4,609) and found the same two-sprite pair (a
white moth-shaped enemy directly paired with a smaller blue enemy,
always adjacent, moving together) visible continuously across that
entire ~700-frame span -- present the instant the new ship spawns in,
still paired through several loops around the formation area, still
diving together right up to nine frames before the kill. This is direct
visual support for the basic shape of the user's original hint: a boss
carries a captured fighter with it, visibly, until something releases
it. Not yet settled: whether the paired sprite (rendered blue, not the
player's own white/red) is drawn from the player's own ship graphics or
a separate escort tile -- a detail worth checking before assuming which
it is.

## What's still open

* Whether the value really does climb back to 1,600 around wave 50, as
  the cyclical-gate theory predicts -- untestable against this recording
  (it ends at wave 36), the natural target for a second recording that
  reaches further.
* ~~Whether `ChallengeHitCount`'s single observed excursion... is the
  only challenge-stage attempt in the recording~~ -- **ANSWERED, in
  passing, while solving the wave-36 hint.** It isn't: `ChallengeHitCountBin`
  (the same counter's low-order twin) wraps roughly ten times across the
  full recording (`tools/probe-groupvalue.lua`'s `binCount` column, waves
  3 through 35), i.e. there were roughly ten group-of-8 challenge-kill
  bursts total, not the one this project originally caught before finding
  the truncation bug.
* ~~The small, still-unidentified digit (ranging 3-5...) sitting in the
  same general screen area the wave number was originally expected in~~
  -- **RETRACTED, per the user directly: there is no second digit near
  the wave counter.** This was never a separate byte -- it was the wave
  counter itself, seen early in the truncated-data pass when the
  recording's own real content (frames 0-~35,900 at the time) only
  covered waves 1-5, so of course the on-screen value read as a single
  digit in the 3-5 range. Confirming `Wave`/`WaveBCD` later made this
  look like two different things when it was one all along.
* What `ram_2724`-`ram_2726` actually represents, now that it's confirmed
  not to be the score -- still live-active every frame, still unexplained.
* ~~Whether `CHARBASE` gets set anywhere in this ROM at all~~ --
  **RESOLVED.** `rom:B01D` is its only write in the whole ROM (confirmed:
  no gaps exist, and a full-file grep finds no second writer), and it's a
  deliberate one, not incidental -- it sits just past the generic
  zero-page sweep loop's own range and is named individually alongside a
  short list of other specific addresses. Set once at boot to 0, never
  touched again: this ROM reads as using Maria's direct (non-CHARBASE-
  relative) addressing throughout, where the register just doesn't
  matter, not a mystery.
* Whether any of the nine newly-declared `dat_` blocks are actually
  graphics data rather than parameter tables -- **partially checked.** A
  byte-frequency pass over the five largest blocks (a quick, cheap first
  filter, not full decoding) found 170-249 distinct byte values in each
  (out of 256 possible), with no block dominated by a small handful of
  values -- unlike the dense, few-values-repeated-constantly signature
  the three 16K sibling projects' actual bit-plane character sheets all
  showed. Reads as evidence *against* these being raw graphics sheets,
  more consistent with jump tables, pointer tables, and other code-
  adjacent parameter data (`dat_9F46`'s own start, already noted as
  little-endian pointer pairs, fits this). Not conclusive -- an actual
  sprite sheet could still be compressed or interleaved with metadata in
  a way that would defeat a flat frequency count -- but a real, cheap
  data point in one direction rather than an open guess in either.
* ~~The tractor-beam capture-vs-formation-kill branch from the user's
  second hint~~ -- **LARGELY RESOLVED, across four corrections in a
  row** (see "The tractor beam, solved," "`run-02.inp`," and "The kill
  really does matter"). Confirmed: `DualFighterFlag` (`ram_1E11`), set
  at `rom:92B3` and cleared on a survivable hit at `rom:sub_D1D3`; a
  capture always plays out in full (text, life cost, respawn -- an
  earlier "the capture never completes" read was wrong, caught by the
  user); and killing the enemy carrying a captive genuinely gates the
  merge's completion, matching the user's original hint directly --
  confirmed by watching `ram_1E43`/`ram_1E8B` freeze right at a
  user-identified kill and resume ~260 frames later. **Not yet
  resolved:** the specific instruction connecting that kill to the
  freeze ending -- left open rather than guessed at a fourth time.
* What specifically reads `CapturingEnemyIndex` (`ram_005C`) to gate
  `ram_1E43`/`ram_1E8B`'s progression on whether that enemy is still
  alive -- the most likely mechanism given the freeze/resume timing, but
  no instruction has been identified that actually does this.
* What the roughly 1,300-frame gap between `rom:sub_90DE`'s proximity
  check (frame 3,629) and the kill that matters (frame 4,609) represents
  -- whether that early check is a real precondition for the merge (e.g.
  arming a watcher) or an unrelated event that happened to touch the
  same shared bytes.
* The private reference source stays unconsulted, per the plan -- see
  `README.md`.
