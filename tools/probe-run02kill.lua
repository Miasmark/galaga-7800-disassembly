-- Checks for a kill/score event between the capture (~3568-3900) and
-- the merge completion (5007) in run-02.inp, per the user's correction:
-- the freed fighter spins for a long time after the attached boss is
-- killed mid-dive, and this happens somewhere in that window.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local cpu = MACHINE.devices[":maincpu"]
local F = 0
local START, STOP = 3800, 5100
local last94 = 0
local lastscore = nil

local function digits()
  local parts = {}
  for a = 0x275C, 0x2763 do
    local v = mem:read_u8(a)
    parts[#parts+1] = (v == 0x0A) and "_" or tostring(v)
  end
  return table.concat(parts)
end

local function tap94(offset, data)
  local pc = cpu.state["PC"].value
  print(string.format("WRITE94 frame %d pc=$%04X val=$%02X", F, pc, data))
  return data
end
TAP94 = mem:install_write_tap(0x0094, 0x0094, "spawn94", tap94)

emu.register_frame_done(function()
  F = F + 1
  if F >= START and F <= STOP then
    local d = digits()
    if d ~= lastscore then
      print(string.format("SCORE frame %d: %s", F, d))
      lastscore = d
    end
  end
  if F > STOP then MACHINE:exit() end
end)
