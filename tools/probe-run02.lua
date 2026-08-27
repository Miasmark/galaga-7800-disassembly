-- run-02.inp is a short, targeted recording (~4 waves) the user made
-- specifically to capture an early tractor-beam capture-and-merge --
-- aimed squarely at this project's one remaining open item from the
-- tractor-beam investigation: what specifically ARMS the "returning
-- captive" sequence (ram_1E43/ram_1E8B/ram_1E12), as opposed to
-- completing it at rom:92B3 (which sets DualFighterFlag, ram_1E11).
--
-- Since the whole recording is short, taps everything relevant for its
-- entire length rather than narrowing a window first: CaptureAttemptTimer
-- (ram_00B4), CapturingEnemyIndex (ram_005C), the return-sequence chain
-- (ram_1E43, ram_1E8B, ram_1E12), DualFighterFlag (ram_1E11), and the
-- score/spawn-flag byte (ram_0094) already mapped from run-01.inp -- all
-- PC-tagged so the exact call chain from "kill this enemy" to "merge
-- into dual-fighter" can be read directly instead of guessed at.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local cpu = MACHINE.devices[":maincpu"]

local F = 0
local MAX_FRAMES = 60000  -- generous; run-02.inp is far shorter

local function wave_bcd(v) return (v >> 4) * 10 + (v & 0xF) end

local function tap(name)
  return function(offset, data)
    local pc = cpu.state["PC"].value
    print(string.format("%s frame %d pc=$%04X addr=$%04X val=$%02X wave=%d",
      name, F, pc, offset, data, wave_bcd(mem:read_u8(0x43))))
    return data
  end
end

TAP_B4  = mem:install_write_tap(0x00B4, 0x00B4, "captimer", tap("B4"))
TAP_5C  = mem:install_write_tap(0x005C, 0x005C, "capidx",   tap("5C"))
TAP_43  = mem:install_write_tap(0x1E43, 0x1E43, "e43",      tap("1E43"))
TAP_8B  = mem:install_write_tap(0x1E8B, 0x1E8B, "e8b",      tap("1E8B"))
TAP_12  = mem:install_write_tap(0x1E12, 0x1E12, "e12",      tap("1E12"))
TAP_11  = mem:install_write_tap(0x1E11, 0x1E11, "e11",      tap("1E11"))
TAP_94  = mem:install_write_tap(0x0094, 0x0094, "spawn94",  tap("94"))

emu.register_frame_done(function()
  F = F + 1
  if F % 5000 == 0 then print(string.format("progress frame %d", F)) end
  if F >= MAX_FRAMES then MACHINE:exit() end
end)
