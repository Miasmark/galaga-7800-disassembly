local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local F = 0
local TARGETS = {}
for f = 3900, 4609, 20 do table.insert(TARGETS, f) end
emu.register_frame_done(function()
  F = F + 1
  for _, t in ipairs(TARGETS) do
    if F == t then MACHINE.video:snapshot() end
  end
  if F > 4609 then MACHINE:exit() end
end)
