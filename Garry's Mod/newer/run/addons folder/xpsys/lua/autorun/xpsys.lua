AddCSLuaFile()

if SERVER then
	AddCSLuaFile("xpsys/sh_core.lua")
	AddCSLuaFile("xpsys/cl_gui.lua")
	
	include("xpsys/sh_core.lua")
	include("xpsys/sv_core.lua")
	include("xpsys/sv_leveling.lua")
	include("xpsys/sh_goals.lua")
else
	include("xpsys/sh_core.lua")
	include("xpsys/cl_gui.lua")
end