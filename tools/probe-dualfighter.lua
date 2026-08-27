-- The user corrected a major assumption: the player was a dual-fighter
-- for MOST of the 37-wave run (rescued early, hit once partway through
-- reverting to single -- not lost outright), not "released as hostile"
-- as this project had been circumstantially guessing. This takes a wide,
-- periodic screenshot pass across the WHOLE recording to find (a) when
-- the dual-fighter configuration first appears on screen, and (b) when
-- it reverts to single, narrowing both transitions before going back to
-- static tracing. Sped up with -nothrottle throughout, per standing
-- practice for a recording this long.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]

local F = 0
local MAX_FRAMES = 300000
local SNAP_EVERY = 4000

local function wave_bcd(v) return (v >> 4) * 10 + (v & 0xF) end

emu.register_frame_done(function()
  F = F + 1
  if F % SNAP_EVERY == 0 then
    MACHINE.video:snapshot()
    print(string.format("SNAPSHOT frame %d wave=%d", F, wave_bcd(mem:read_u8(0x43))))
  end
  if F >= MAX_FRAMES then MACHINE:exit() end
end)
