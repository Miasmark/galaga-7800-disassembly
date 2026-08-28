-- Cross-check candidate from the private reference source (P1BONUS/
-- P2BONUS, an extra-life bonus accumulator) against ram_2724-2726, this
-- project's own "still real, live-active every frame, unexplained"
-- mystery byte. Rather than logging every frame (it changes constantly),
-- logs only when the HIGH byte (ram_2724) changes -- the rarest,
-- highest-order transitions, i.e. wherever this 3-byte BCD value crosses
-- a multiple-of-10,000 boundary -- since a bonus-life threshold should
-- be a clean round number an accumulator crosses relatively rarely.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local F = 0
local MAX_FRAMES = 300000
local last2724 = nil

emu.register_frame_done(function()
  F = F + 1
  local a = mem:read_u8(0x2724)
  if a ~= last2724 then
    local b, c = mem:read_u8(0x2725), mem:read_u8(0x2726)
    print(string.format("frame %d ram2724=%02X ram2725=%02X ram2726=%02X",
      F, a, b, c))
    last2724 = a
  end
  if F >= MAX_FRAMES then MACHINE:exit() end
end)
