-- Disambiguates which routine actually owns ram_1E43/ram_1E8B during the
-- apparent freeze (frame ~4610-4870) around the user-identified kill in
-- run-02.inp. A PC-tagged write-tap settles directly whether nothing
-- writes them at all (a genuine pause in rom:sub_9250's own sequence)
-- or whether an unrelated routine (e.g. rom:sub_915D, dispatch nibble 7)
-- is writing them for a different enemy's animation during that window,
-- which would mean the "freeze" was never really about our sequence at
-- all -- rather than reaching for the private reference source, this is
-- the same PC-tagged write-tap technique that has settled every other
-- byte in this project.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local cpu = MACHINE.devices[":maincpu"]
local F = 0
local START, STOP = 4550, 4950

local function tap(name)
  return function(offset, data)
    if F >= START and F <= STOP then
      local pc = cpu.state["PC"].value
      print(string.format("%s frame %d pc=$%04X val=%d", name, F, pc, data))
    end
    return data
  end
end

TAP43 = mem:install_write_tap(0x1E43, 0x1E43, "a43", tap("1E43"))
TAP8B = mem:install_write_tap(0x1E8B, 0x1E8B, "a8b", tap("1E8B"))

emu.register_frame_done(function()
  F = F + 1
  if F > STOP then MACHINE:exit() end
end)
