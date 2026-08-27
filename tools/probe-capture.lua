-- Watches for the two "spawn flag" moments found while tracing the
-- score code (rom:D097/rom:D29F): ram_0094 being set to $0B (the
-- CPY #$28 / 1000-point path) vs $0C (the sub_D29F / 1600-point path,
-- gated on the killed enemy's own ram_1F77 bit7 -- believed to mean
-- "was diving" -- being set). ram_0094's value becomes the newly
-- spawned replacement enemy's own ram_1F77 state (rom:D31E/D320).
--
-- Logs the frame, wave, and which flag fired, then snapshots a handful
-- of frames afterward so the actual on-screen result (hostile solo ship
-- vs. player's own dual-fighter) can be read directly rather than
-- inferred from code.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]

local F = 0
local MAX_FRAMES = 300000
local last_0094 = 0
local pending_shots = {}  -- list of {frame=, tag=}

local function wave_bcd(v) return (v >> 4) * 10 + (v & 0xF) end

emu.register_frame_done(function()
  F = F + 1

  local v94 = mem:read_u8(0x94)
  if v94 ~= 0 and v94 ~= last_0094 then
    print(string.format("SPAWNFLAG frame %d wave=%d flag=$%02X",
      F, wave_bcd(mem:read_u8(0x43)), v94))
    for _, off in ipairs({0, 10, 30, 60, 90}) do
      table.insert(pending_shots, {frame = F + off, tag = string.format("f%d_flag%02X", F, v94)})
    end
  end
  last_0094 = v94

  for i = #pending_shots, 1, -1 do
    if pending_shots[i].frame == F then
      MACHINE.video:snapshot()
      print(string.format("SNAPSHOT frame %d tag=%s", F, pending_shots[i].tag))
      table.remove(pending_shots, i)
    end
  end

  if F >= MAX_FRAMES then MACHINE:exit() end
end)
