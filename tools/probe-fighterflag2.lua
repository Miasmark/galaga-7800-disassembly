-- Corrected cluster analysis for the dual-fighter state byte. The first
-- attempt (tools/probe-fighterflag.lua) used frame 20000 as a "single"
-- reference without checking the screenshot first -- it turned out to
-- be sitting on a title/attract screen (an early false start; the game
-- restarted a few times before frame ~23569), which produced zero
-- cluster hits. This rechecks every reference frame by screenshot
-- first (done separately), then uses confirmed-good frames: 36000
-- (single, wave 5), 52000 (dual, wave 12), 80200 (dual, wave 26, one
-- frame before a directly-observed hit/explosion at 80300), 84000
-- (single, wave 28). Scans zero page, $1D00-$1FFF (the enemy-array
-- pages), and $2700-$27FF (the UI/score page) -- wider than the first
-- attempt's zero-page-only scan.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]

local F = 0
local TARGETS = {
  {frame = 36000, tag = "single_A"},
  {frame = 52000, tag = "dual_A"},
  {frame = 80200, tag = "dual_B"},
  {frame = 84000, tag = "single_B"},
}
local snaps = {}

local RANGES = {{0x0000, 0x00FF}, {0x1D00, 0x1FFF}, {0x2700, 0x27FF}}

local function dump()
  local t = {}
  for _, r in ipairs(RANGES) do
    for a = r[1], r[2] do t[a] = mem:read_u8(a) end
  end
  return t
end

emu.register_frame_done(function()
  F = F + 1
  for _, t in ipairs(TARGETS) do
    if F == t.frame then
      snaps[t.tag] = dump()
      print(string.format("captured %s at frame %d", t.tag, F))
    end
  end
  if F >= 84001 then
    local hits = {}
    for _, r in ipairs(RANGES) do
      for a = r[1], r[2] do
        local sA, sB = snaps.single_A[a], snaps.single_B[a]
        local dA, dB = snaps.dual_A[a], snaps.dual_B[a]
        if sA == sB and dA == dB and sA ~= dA then
          hits[#hits+1] = string.format("$%04X: single=%d dual=%d", a, sA, dA)
        end
      end
    end
    print(string.format("CLUSTER HITS (%d):", #hits))
    for _, h in ipairs(hits) do print(h) end
    MACHINE:exit()
  end
end)
