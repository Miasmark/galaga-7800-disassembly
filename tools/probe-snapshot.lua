-- Takes a PNG screenshot at a specific frame, and prints the live value of
-- a chosen zero-page byte at that same frame, so a static candidate (e.g.
-- ram_0043) can be checked directly against what's actually on screen
-- instead of reasoned about from code alone.
--
--   mame a7800 -rompath ../bios -cart <rom> -skip_gameinfo -video none \
--       -sound none -nothrottle -playback run-01.inp \
--       -autoboot_script tools/probe-snapshot.lua -str 600 \
--       -snapshot_directory .

local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]

local TARGET_FRAMES = {29500, 30000, 30500, 31000}
local F = 0
local idx = 1

emu.register_frame_done(function()
  F = F + 1
  if idx <= #TARGET_FRAMES and F == TARGET_FRAMES[idx] then
    local v43 = mem:read_u8(0x0043)
    local v42 = mem:read_u8(0x0042)
    print(string.format("frame %d: ram_0042=%d ram_0043=%d ($%02X)", F, v42, v43, v43))
    MACHINE.video:snapshot()
    idx = idx + 1
  end
  if F >= 31100 then
    MACHINE:exit()
  end
end)
