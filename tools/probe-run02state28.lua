-- ram_1E43/ram_1E8B turned out to be ram_1E1B[$28]/ram_1E63[$28] --
-- slot $28's own X/Y position, hit via a hardcoded address inside
-- rom:sub_9250 rather than indexed addressing. That means ram_1F9F
-- (= ram_1F77 + $28) is slot $28's own STATE byte in the same array
-- used throughout this project's per-enemy dispatch tracing. This taps
-- it directly around the user-identified kill (frame ~4,609) to see
-- whether the kill transitions slot $28 into a new dispatch state.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local cpu = MACHINE.devices[":maincpu"]
local F = 0

local function tap(offset, data)
  local pc = cpu.state["PC"].value
  print(string.format("WRITE1F9F frame %d pc=$%04X val=$%02X nibble=%d",
    F, pc, data, data & 0x0F))
  return data
end
TAP = mem:install_write_tap(0x1F9F, 0x1F9F, "slot28state", tap)

emu.register_frame_done(function()
  F = F + 1
  if F > 5100 then MACHINE:exit() end
end)
