include("shared.lua")
include("cl_healthbar.lua")
include("sh_rune_modifiers.lua")
--include("player_class/default.lua")

net.Receive("boss.SendSound",function()
	surface.PlaySound(net.ReadString())
end)