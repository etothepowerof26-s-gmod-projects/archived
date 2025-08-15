include("shared.lua")
include("sh_indicators.lua")
include("sh_actions.lua")

module("gmodrts", package.seeall)

surface.CreateFont("CoolveticaLarge",{
	font = "Coolvetica",
	size = 40,
	weight = 500,
	antialias = true,
}) 

surface.CreateFont("CoolveticaMedium",{
	font = "Coolvetica",
	size = 20,
	weight = 500,
	antialias = true,
}) 

surface.CreateFont("CoolveticaSmol",{
	font = "Coolvetica",
	size = 10,
	weight = 500,
	antialias = true,
})

-- Remove the ragdolls whenever an NPC dies, TODO: custom ragdolls, or death into ground?
hook.Add("CreateClientsideRagdoll", "gmodrts", function(ent, ragdoll)
	if ent:GetClass():find(Tag_HookCMD) then
		ragdoll:Remove()
	end
end)