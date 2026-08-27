local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local F = 0
local START, STOP = 4590, 5015
emu.register_frame_done(function()
  F = F + 1
  if F >= START and F <= STOP then
    MACHINE.video:snapshot()
    if F % 5 == 0 then
      print(string.format("frame %d 1E43=%d 1E8B=%d 1E12=%d PlayerX=%d",
        F, mem:read_u8(0x1E43), mem:read_u8(0x1E8B), mem:read_u8(0x1E12), mem:read_u8(0x1E5A)))
    end
  end
  if F > STOP then MACHINE:exit() end
end)
