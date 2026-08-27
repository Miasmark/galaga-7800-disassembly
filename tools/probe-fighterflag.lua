-- Finds the dual-fighter state byte by clustering, not by noisy
-- adjacent-frame diffing (which was swamped by ordinary enemy-movement
-- writes). Takes full zero-page + $2700-$27FF snapshots at four frames
-- with a KNOWN visual state from the wide screenshot pass
-- (tools/probe-dualfighter.lua): frame 20000 (single, pre-rescue),
-- frame 40000 (dual, post-rescue), frame 79950 (dual, just before the
-- apparent hit), frame 84000 (single, post-hit). Prints every byte
-- that's consistent within each pair (single-single, dual-dual) but
-- differs between the two groups -- a real state flag should show up
-- there regardless of unrelated per-frame gameplay noise.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]

local F = 0
local TARGETS = {
  {frame = 20000, tag = "single_A"},
  {frame = 40000, tag = "dual_A"},
  {frame = 79950, tag = "dual_B"},
  {frame = 84000, tag = "single_B"},
}
local snaps = {}

local function dump()
  local t = {}
  for a = 0, 0xFF do t[a] = mem:read_u8(a) end
  for a = 0x2700, 0x27FF do t[a] = mem:read_u8(a) end
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
  if F >= 85000 then
    -- Cluster analysis: addresses where single_A==single_B and
    -- dual_A==dual_B but the two groups differ.
    local addrs = {}
    for a = 0, 0xFF do addrs[#addrs+1] = a end
    for a = 0x2700, 0x27FF do addrs[#addrs+1] = a end
    local hits = {}
    for _, a in ipairs(addrs) do
      local sA, sB = snaps.single_A[a], snaps.single_B[a]
      local dA, dB = snaps.dual_A[a], snaps.dual_B[a]
      if sA == sB and dA == dB and sA ~= dA then
        hits[#hits+1] = string.format("$%04X: single=%d dual=%d", a, sA, dA)
      end
    end
    print(string.format("CLUSTER HITS (%d):", #hits))
    for _, h in ipairs(hits) do print(h) end
    MACHINE:exit()
  end
end)
