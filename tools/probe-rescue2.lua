-- PC-tagged write-tap on ram_1E11 specifically, narrowed to frames
-- 36000-39000 (bracketing the real dual-fighter-formation transition
-- found at frame 37714 by tools/probe-rescue.lua) to identify exactly
-- which code path sets it -- the nibble-dispatch theory from static
-- reading (sub_896C's CMP #$0B case) didn't line up with the nearest
-- known $0B/CPY #$28 score event, so this checks empirically instead
-- of trusting the static guess further.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local cpu = MACHINE.devices[":maincpu"]

local F = 0
local START, STOP = 36000, 39000

local function tap(offset, data)
  local pc = cpu.state["PC"].value
  print(string.format("WRITE_1E11 frame %d pc=$%04X val=%d", F, pc, data))
  return data
end

TAP = mem:install_write_tap(0x1E11, 0x1E11, "escortflag", tap)

emu.register_frame_done(function()
  F = F + 1
  if F > STOP then MACHINE:exit() end
end)
