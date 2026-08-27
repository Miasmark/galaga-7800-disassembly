-- Narrow zero-page snapshot diff around the apparent dual-fighter-to-
-- single-fighter hit transition spotted visually around frame 80000
-- (wave 26) in tools/probe-dualfighter.lua's wide pass. Diffs
-- consecutive 50-frame snapshots of $0000-$00FF across frames
-- 77000-83000 and prints only what actually changed, isolating
-- whatever byte tracks the player's fighter count/configuration.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]

local F = 0
local START, STOP = 77000, 83000
local last = {}
local have_last = false

local function wave_bcd(v) return (v >> 4) * 10 + (v & 0xF) end

emu.register_frame_done(function()
  F = F + 1
  if F >= START and F <= STOP and F % 50 == 0 then
    local cur = {}
    for a = 0, 0xFF do cur[a] = mem:read_u8(a) end
    if have_last then
      local diffs = {}
      for a = 0, 0xFF do
        if cur[a] ~= last[a] then
          diffs[#diffs+1] = string.format("$%02X:%d->%d", a, last[a], cur[a])
        end
      end
      if #diffs > 0 and #diffs <= 12 then
        print(string.format("frame %d wave=%d DIFF: %s",
          F, wave_bcd(mem:read_u8(0x43)), table.concat(diffs, " ")))
      elseif #diffs > 12 then
        print(string.format("frame %d wave=%d DIFF: (%d bytes changed, too many to list)",
          F, wave_bcd(mem:read_u8(0x43)), #diffs))
      end
    end
    last = cur
    have_last = true
  end
  if F > STOP then MACHINE:exit() end
end)
