-- Fine-grained (every 15 frames, 1/4 sec) screenshot pass over a narrow
-- window (79500-80500) to pinpoint the exact frame of the apparent
-- dual-fighter-to-single hit spotted around frame 80000 in the wide
-- pass (tools/probe-dualfighter.lua). Once found, a single-frame
-- before/after zero-page dump (not a 50-frame diff, which was too
-- noisy with ordinary gameplay) should isolate the actual byte.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]

local F = 0
local START, STOP = 79500, 80500

emu.register_frame_done(function()
  F = F + 1
  if F >= START and F <= STOP and F % 15 == 0 then
    MACHINE.video:snapshot()
    print(string.format("SNAPSHOT frame %d", F))
  end
  if F > STOP then MACHINE:exit() end
end)
