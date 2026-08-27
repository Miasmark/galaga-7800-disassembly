local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local F = 0
local START, STOP = 4030, 4200
emu.register_frame_done(function()
  F = F + 1
  if F >= START and F <= STOP and F % 3 == 0 then
    MACHINE.video:snapshot()
  end
  if F > STOP then MACHINE:exit() end
end)
