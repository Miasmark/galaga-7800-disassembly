-- Captures a screenshot plus a full zero-page dump at several points near
-- the very end of the recording (last life lost), so whatever byte holds
-- the on-screen bottom-right number at that moment can be identified
-- directly by matching its value against what's visible in the
-- screenshot, rather than guessed at from behavior alone.
--
--   mame a7800 -rompath ../bios -cart <rom> -skip_gameinfo -video none \
--       -sound none -nothrottle -playback run-01.inp \
--       -autoboot_script tools/probe-endgame.lua -str 600 \
--       -snapshot_directory .

local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]

-- run-01.inp is 35901 total frames; sample every 300 frames from 34100
local TARGET_FRAMES = {}
for f = 34100, 35880, 300 do TARGET_FRAMES[#TARGET_FRAMES + 1] = f end
local F = 0
local idx = 1

local function dump_zp(frame)
  local parts = {}
  for a = 0, 255 do
    parts[#parts + 1] = string.format('%d', mem:read_u8(a))
  end
  local h = io.open(string.format("endgame-zp-%d.json", frame), "w")
  if h then
    h:write(string.format('{"frame":%d,"zp":[%s]}', frame, table.concat(parts, ",")))
    h:close()
  end
end

emu.register_frame_done(function()
  F = F + 1
  if idx <= #TARGET_FRAMES and F == TARGET_FRAMES[idx] then
    print(string.format("capturing frame %d", F))
    MACHINE.video:snapshot()
    dump_zp(F)
    idx = idx + 1
  end
  if F >= 35900 then
    MACHINE:exit()
  end
end)
