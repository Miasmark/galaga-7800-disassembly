-- Tests the structural finding at rom:D097 (sub_D097) / rom:9DD8 (L_9DD8):
-- challenge stages occur at Wave === 2 (mod 4), and the per-group-of-8 bonus
-- (ram_006D/ram_006E added to the score accumulator when ChallengeHitCountBin
-- hits 8) pays 1000 if ram_005A < 4, or 1600 if ram_005A >= 4 -- where
-- ram_005A itself increments once per completed challenge stage and wraps at 8.
-- Samples widely (frames 80000-104454, covering waves ~26-35) to catch the
-- predicted 1600->1000 transition between the wave-30 and wave-34 stages.
--
--   mame a7800 -rompath ../bios -cart <rom> -skip_gameinfo -video none \
--       -sound none -nothrottle -playback run-01.inp \
--       -autoboot_script tools/probe-groupvalue.lua -str 5100

local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]

local F = 0
local START = 80000
local MAX_FRAMES = 300000

local last_005A, last_61, last_bin, last_wave = nil, nil, nil, nil

local function wave_bcd(v)
  return (v >> 4) * 10 + (v & 0xF)
end

emu.register_frame_done(function()
  F = F + 1
  if F < START then return end

  local v5A = mem:read_u8(0x5A)
  local v61 = mem:read_u8(0x61)
  local bin = mem:read_u8(0x63)
  local wave = wave_bcd(mem:read_u8(0x43))

  -- Log any change in the gate byte, the stage counter, or the group tally --
  -- these are rare events (a handful per wave), so this stays a short log.
  if v5A ~= last_005A or v61 ~= last_61 or bin ~= last_bin or wave ~= last_wave then
    print(string.format("frame %d wave=%d ram005A=%d ram0061=%02X binCount=%d",
      F, wave, v5A, v61, bin))
    last_005A, last_61, last_bin, last_wave = v5A, v61, bin, wave
  end

  if F >= MAX_FRAMES then
    MACHINE:exit()
  end
end)
