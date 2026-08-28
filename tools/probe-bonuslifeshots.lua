local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local F = 0
local TARGETS = {57400, 57500, 83500, 83600}
emu.register_frame_done(function()
  F = F + 1
  for _, t in ipairs(TARGETS) do
    if F == t then MACHINE.video:snapshot() end
  end
  if F > 83600 then MACHINE:exit() end
end)
