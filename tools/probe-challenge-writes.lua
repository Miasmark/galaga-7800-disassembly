-- Narrow, unthrottled PC+frame-tagged write-tap on the ENTIRE zero page
-- ($0000-$00FF), active only during the frame window where
-- ChallengeHitCount (ram_008A) is already known to be live (from
-- tools/probe-ram-snapshots.lua against run-01.inp: a single burst,
-- frames ~29000-31500) -- narrow enough in time that logging every write
-- to the whole page is tractable, instead of needing to guess which
-- address to watch. Goal: catch whatever score-add (or other bookkeeping)
-- co-occurs with each ChallengeHitCount step.
--
--   mame a7800 -rompath ../bios -cart <rom> -skip_gameinfo -video none \
--       -sound none -nothrottle -playback run-01.inp \
--       -autoboot_script tools/probe-challenge-writes.lua -str 600
--
-- Writes challenge-writes-out.json: {"events":[{"frame":N,"pc":"$XXXX",
-- "addr":"$XXXX","val":N}, ...]}

local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local cpu = MACHINE.devices[":maincpu"]

local events = {}
local F = 0
local ACTIVE_LO, ACTIVE_HI = 28800, 31800

local function tap(offset, data)
  if F >= ACTIVE_LO and F <= ACTIVE_HI then
    local pc = cpu.state["PC"].value
    events[#events + 1] = string.format(
      '{"frame":%d,"pc":"$%04X","addr":"$%04X","val":%d}', F, pc, offset, data)
  end
  return data
end

TAP1 = mem:install_write_tap(0x0000, 0x00FF, "zp", tap)
TAP2 = mem:install_write_tap(0x2700, 0x27FF, "obj27", tap)

emu.register_frame_done(function()
  F = F + 1
  if F % 3000 == 0 then
    print(string.format("progress frame %d: events=%d", F, #events))
  end
  if F >= 35850 then
    dump_final()
    MACHINE:exit()
  end
end)

function dump_final()
  print(string.format("FINAL: events=%d", #events))
  local h = io.open("challenge-writes-out.json", "w")
  if h then
    h:write(string.format('{"events":[%s]}', table.concat(events, ",")))
    h:close()
  end
end
