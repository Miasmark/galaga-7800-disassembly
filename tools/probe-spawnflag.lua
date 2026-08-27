-- Narrow write-tap on ram_0094 alone (a single byte, rare writes) across
-- the FULL recording -- the end-of-frame poll in probe-capture.lua found
-- nothing after frame 1 because rom:D097 sets it and rom:D325 (the
-- replacement-enemy spawn routine, sub_D2E4) clears it back to 0 within
-- the same frame; a periodic/end-of-frame read never sees the transient
-- nonzero value. Logs every write with PC and frame; on a nonzero write,
-- also fires a short run of snapshots so the resulting spawn's on-screen
-- behavior (hostile solo ship vs. player's own escort) can be read
-- directly a few seconds later.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local cpu = MACHINE.devices[":maincpu"]

local F = 0
local MAX_FRAMES = 300000
local pending_shots = {}

local function wave_bcd(v) return (v >> 4) * 10 + (v & 0xF) end

local function tap(offset, data)
  local pc = cpu.state["PC"].value
  print(string.format("WRITE94 frame %d pc=$%04X val=$%02X wave=%d",
    F, pc, data, wave_bcd(mem:read_u8(0x43))))
  if data ~= 0 then
    for _, off in ipairs({0, 30, 90, 180, 300}) do
      table.insert(pending_shots, {frame = F + off, tag = string.format("f%d_v%02X", F, data)})
    end
  end
  return data
end

TAP1 = mem:install_write_tap(0x0094, 0x0094, "spawnflag", tap)

emu.register_frame_done(function()
  F = F + 1
  for i = #pending_shots, 1, -1 do
    if pending_shots[i].frame == F then
      MACHINE.video:snapshot()
      print(string.format("SNAPSHOT frame %d tag=%s", F, pending_shots[i].tag))
      table.remove(pending_shots, i)
    end
  end
  if F % 10000 == 0 then
    print(string.format("progress frame %d", F))
  end
  if F >= MAX_FRAMES then MACHINE:exit() end
end)
