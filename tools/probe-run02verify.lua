local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local cpu = MACHINE.devices[":maincpu"]
local F = 0
local START, STOP = 3560, 4000
local last89 = 0

local function tap89(offset, data)
  local pc = cpu.state["PC"].value
  print(string.format("WRITE89 frame %d pc=$%04X val=$%02X", F, pc, data))
  return data
end
TAP89 = mem:install_write_tap(0x0089, 0x0089, "arm89", tap89)

emu.register_frame_done(function()
  F = F + 1
  if F >= START and F <= STOP then
    local px = mem:read_u8(0x1E5A)
    local ox = mem:read_u8(0x64)
    local timer = mem:read_u8(0xB4)
    local lives = mem:read_u8(0x00) -- placeholder, will check real lives addr separately
    if F % 10 == 0 then
      print(string.format("state frame %d PlayerX=%d CaptureOriginX=%d diff=%d timer=%d",
        F, px, ox, px-ox, timer))
    end
  end
  if F > STOP then MACHINE:exit() end
end)
