-- Captures the exact on-screen score (ScoreDigit0-4, $275F-$2763) at every
-- frame where ChallengeHitCountBin ($63) wraps from 7 back to 0 -- the
-- group-of-8 bonus award moment identified at rom:D097 -- plus the frame
-- immediately before, to isolate the group bonus's own score delta from
-- ordinary per-kill increments landing the same frame.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]

local F = 0
local START = 80000
local MAX_FRAMES = 300000
local last_bin = nil
local prev_digits = nil

local function digits()
  local parts = {}
  for a = 0x275F, 0x2763 do
    local v = mem:read_u8(a)
    parts[#parts+1] = (v == 0x0A) and "_" or tostring(v)
  end
  return table.concat(parts)
end

local function wave_bcd(v) return (v >> 4) * 10 + (v & 0xF) end

emu.register_frame_done(function()
  F = F + 1
  if F >= START then
    local bin = mem:read_u8(0x63)
    if last_bin == 7 and bin == 0 then
      print(string.format("WRAP frame %d wave=%d 005A=%d before=%s after=%s",
        F, wave_bcd(mem:read_u8(0x43)), mem:read_u8(0x5A),
        prev_digits or "?", digits()))
    end
    last_bin = bin
    prev_digits = digits()
  end

  if F >= MAX_FRAMES then MACHINE:exit() end
end)
