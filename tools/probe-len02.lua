local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local F = 0
emu.register_frame_done(function()
  F = F + 1
  if F % 20000 == 0 then print("progress frame "..F) end
  if F >= 300000 then MACHINE:exit() end
end)
