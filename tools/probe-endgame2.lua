-- Same idea as probe-endgame.lua, but dumps zero page AND $2700-$27FF (not
-- just zero page) at the same target frames, since the first pass's
-- narrower search came up empty.
--
--   mame a7800 -rompath ../bios -cart <rom> -skip_gameinfo -video none \
--       -sound none -nothrottle -playback run-01.inp \
--       -autoboot_script tools/probe-endgame2.lua -str 600 \
--       -snapshot_directory .

local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]

local TARGET_FRAMES = {34100, 35600}
local F = 0
local idx = 1

local function dump(frame)
  local zp = {}
  for a = 0, 255 do zp[#zp + 1] = mem:read_u8(a) end
  local p27 = {}
  for a = 0x2700, 0x27FF do p27[#p27 + 1] = mem:read_u8(a) end
  local h = io.open(string.format("endgame2-%d.json", frame), "w")
  if h then
    h:write(string.format('{"frame":%d,"zp":[%s],"p27":[%s]}',
      frame, table.concat(zp, ","), table.concat(p27, ",")))
    h:close()
  end
end

emu.register_frame_done(function()
  F = F + 1
  if idx <= #TARGET_FRAMES and F == TARGET_FRAMES[idx] then
    print(string.format("capturing frame %d", F))
    MACHINE.video:snapshot()
    dump(F)
    idx = idx + 1
  end
  if F >= 35700 then
    MACHINE:exit()
  end
end)
