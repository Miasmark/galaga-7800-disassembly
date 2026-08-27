local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local F = 0
local START, STOP = 3560, 3900
emu.register_frame_done(function()
  F = F + 1
  if F >= START and F <= STOP and F % 5 == 0 then
    MACHINE.video:snapshot()
    print(string.format("SNAPSHOT frame %d", F))
  end
  if F > STOP then MACHINE:exit() end
end)
