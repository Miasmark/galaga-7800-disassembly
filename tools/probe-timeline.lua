-- Screenshots + score/corner-digit readout spread evenly across the WHOLE
-- recording (not just near the assumed end), to build a full timeline and
-- resolve a discrepancy between byte-level analysis and what's visible on
-- screen when replaying run-01.inp directly.
--
--   mame a7800 -rompath ../bios -cart <rom> -skip_gameinfo -video none \
--       -sound none -nothrottle -playback run-01.inp \
--       -autoboot_script tools/probe-timeline.lua -str 600 \
--       -snapshot_directory .

local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]

local TARGET_FRAMES = {}
for f = 2000, 35800, 2000 do TARGET_FRAMES[#TARGET_FRAMES + 1] = f end
local F = 0
local idx = 1

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
  if idx <= #TARGET_FRAMES and F == TARGET_FRAMES[idx] then
    print(string.format("frame %d: digits=[%s] c42=%d c43=%d c8a=%d",
      F, score_digits(), mem:read_u8(0x42), mem:read_u8(0x43), mem:read_u8(0x8A)))
    MACHINE.video:snapshot()
    idx = idx + 1
  end
  if F >= 35850 then
    MACHINE:exit()
  end
end)
