-- Checks whether the game keeps progressing autonomously (under whatever
-- input state was last held) after run-01.inp's own recorded frames run
-- out at ~35901, instead of assuming nothing happens past that point and
-- exiting there (a bug in this project's earlier probes -- they capped
-- their own run length at the recording's length, never actually letting
-- the emulation continue to see what a held final input state produces).
--
--   mame a7800 -rompath ../bios -cart <rom> -skip_gameinfo -video none \
--       -sound none -nothrottle -playback run-01.inp \
--       -autoboot_script tools/probe-coast.lua -str 600 \
--       -snapshot_directory .

local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]

local F = 0
local SNAP_EVERY = 6000
local MAX_FRAMES = 300000  -- far past the recording's own 35901 frames

local function score_digits()
  local addrs = {0x275C,0x275D,0x275E,0x275F,0x2760,0x2761,0x2762,0x2763}
  local parts = {}
  for _, a in ipairs(addrs) do
    parts[#parts+1] = tostring(mem:read_u8(a))
  end
  return table.concat(parts, ",")
end

emu.register_frame_done(function()
  F = F + 1
  if F % SNAP_EVERY == 0 then
    print(string.format("frame %d: digits=[%s] c42=%d c43=%d",
      F, score_digits(), mem:read_u8(0x42), mem:read_u8(0x43)))
    MACHINE.video:snapshot()
  end
  if F >= MAX_FRAMES then
    MACHINE:exit()
  end
end)
