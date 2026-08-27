local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local cpu = MACHINE.devices[":maincpu"]
local F = 0
local STOP = 5100

local function tap(name)
  return function(offset, data)
    local pc = cpu.state["PC"].value
    print(string.format("%s frame %d pc=$%04X val=$%02X", name, F, pc, data))
    return data
  end
end

TAP89 = mem:install_write_tap(0x0089, 0x0089, "a89", tap("89"))
TAP12 = mem:install_write_tap(0x1E12, 0x1E12, "a12", tap("1E12"))
TAP11 = mem:install_write_tap(0x1E11, 0x1E11, "a11", tap("1E11"))
TAPD3 = mem:install_write_tap(0x1DD3, 0x1DD3+0x40, "adD3", tap("1DD3+"))

emu.register_frame_done(function()
  F = F + 1
  if F > STOP then MACHINE:exit() end
end)
