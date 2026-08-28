local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local cpu = MACHINE.devices[":maincpu"]
local F = 0
local last88 = nil

local function tap(offset, data)
  local pc = cpu.state["PC"].value
  print(string.format("WRITE88 frame %d pc=$%04X val=%d", F, pc, data))
  return data
end
TAP = mem:install_write_tap(0x0088, 0x0088, "ram88", tap)

emu.register_frame_done(function()
  F = F + 1
  if F % 20 == 0 and F >= 4400 and F <= 4900 then
    local v = mem:read_u8(0x88)
    if v ~= last88 then
      print(string.format("state frame %d ram_0088=%d", F, v))
      last88 = v
    end
  end
  if F > 4950 then MACHINE:exit() end
end)
