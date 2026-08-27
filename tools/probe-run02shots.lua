local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local F = 0
local TARGETS = {3568, 3600, 3628, 3660, 3700, 3768, 3800, 3876, 3900, 4000, 4200, 4500, 4800, 5007, 5050, 5100, 5200}
emu.register_frame_done(function()
  F = F + 1
  for _, t in ipairs(TARGETS) do
    if F == t then
      MACHINE.video:snapshot()
      print(string.format("SNAPSHOT frame %d", F))
    end
  end
  if F >= 5201 then MACHINE:exit() end
end)
