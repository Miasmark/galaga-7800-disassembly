-- Wider follow-up on the tractor-beam mechanism, now that the user has
-- confirmed live-play ground truth: capture events happened "a few
-- times early on in the run" (matching the two rare score/spawn-flag
-- events already found at wave 1 and wave 2). This taps the two bytes
-- identified as the capture-attempt sequence's own state --
-- CaptureAttemptTimer (ram_00B4, armed to $B4=180 and counted down) and
-- CapturingEnemyIndex (ram_005C) -- across the whole early game
-- (frames 0-40000, comfortably covering waves 1-7) to find every
-- capture ATTEMPT, not just the ones that happened to end in a kill
-- during the narrow score-flag tap used last pass. Sped up with
-- -nothrottle throughout, per standing project practice for a
-- recording this long.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local cpu = MACHINE.devices[":maincpu"]

local F = 0
local MAX_FRAMES = 45000
local last_b4, last_5c = 0, 0
local pending_shots = {}

local function wave_bcd(v) return (v >> 4) * 10 + (v & 0xF) end

local function tap_b4(offset, data)
  local pc = cpu.state["PC"].value
  print(string.format("WRITE_B4 frame %d pc=$%04X val=$%02X wave=%d",
    F, pc, data, wave_bcd(mem:read_u8(0x43))))
  return data
end

local function tap_5c(offset, data)
  local pc = cpu.state["PC"].value
  print(string.format("WRITE_5C frame %d pc=$%04X val=$%02X wave=%d",
    F, pc, data, wave_bcd(mem:read_u8(0x43))))
  if pc == 0x9076 then  -- rom:sub_903E's capture-arm site specifically
    for _, off in ipairs({0, 60, 120, 240, 360, 480, 600}) do
      table.insert(pending_shots, {frame = F + off, tag = string.format("f%d_arm", F)})
    end
  end
  return data
end

TAPB4 = mem:install_write_tap(0x00B4, 0x00B4, "captimer", tap_b4)
TAP5C = mem:install_write_tap(0x005C, 0x005C, "capidx", tap_5c)

emu.register_frame_done(function()
  F = F + 1
  for i = #pending_shots, 1, -1 do
    if pending_shots[i].frame == F then
      MACHINE.video:snapshot()
      print(string.format("SNAPSHOT frame %d tag=%s", F, pending_shots[i].tag))
      table.remove(pending_shots, i)
    end
  end
  if F % 10000 == 0 then print(string.format("progress frame %d", F)) end
  if F >= MAX_FRAMES then MACHINE:exit() end
end)
