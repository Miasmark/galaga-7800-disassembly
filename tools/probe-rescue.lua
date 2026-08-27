-- Live-confirms when the dual-fighter actually forms (ram_1E11 going
-- nonzero, confirmed via cluster analysis against screenshots as the
-- escort-attached flag) and cross-references against the CPY #$28 kill
-- at frame 26758 and the five capture-arm events already found, to
-- settle which released-captive path (the CPY #$28 / spawn-flag-$0B
-- path, or one of $09/$0A/$0C) is actually the rescue.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local cpu = MACHINE.devices[":maincpu"]

local F = 0
local MAX_FRAMES = 55000
local last_11, last_12 = 0, 0

local function wave_bcd(v) return (v >> 4) * 10 + (v & 0xF) end

emu.register_frame_done(function()
  F = F + 1
  local v11 = mem:read_u8(0x1E11)
  local v12 = mem:read_u8(0x1E12)
  if v11 ~= last_11 then
    print(string.format("1E11 frame %d: %d -> %d  wave=%d", F, last_11, v11, wave_bcd(mem:read_u8(0x43))))
    last_11 = v11
  end
  if v12 ~= last_12 then
    print(string.format("1E12 frame %d: %d -> %d  wave=%d", F, last_12, v12, wave_bcd(mem:read_u8(0x43))))
    last_12 = v12
  end
  if F >= MAX_FRAMES then MACHINE:exit() end
end)
