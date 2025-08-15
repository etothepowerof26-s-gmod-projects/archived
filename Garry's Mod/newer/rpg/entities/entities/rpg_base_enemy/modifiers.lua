

if (SERVER) then

	util.AddNetworkString("rpg_network_mods")

	local function cooldown(ply, name, delay)
		if not delay then
			delay = 1
		end

		local co = name .. "_cooldown"

		if not ply:GetVar(co, false) then
			ply:SetVar(co, SysTime() + delay)
		else
			if SysTime() < ply:GetVar(co, SysTime()) then
				return false
			else
				ply:SetVar(co, SysTime() + delay)
			end
		end

		return true
	end

	net.Receive("rpg_network_mods", function(len, ply)

		if (!cooldown(ply, "rpg_network_mods")) then return end

		local moddedEnemy = net.ReadEntity()

		if (!IsValid(moddedEnemy) || moddedEnemy:IsPlayer()) then return end
		if (!moddedEnemy.ModEnabled) then return end

		net.Start("rpg_network_mods")
			net.WriteEntity(moddedEnemy)
			for i = 1, #GAMEMODE.EnemyModTable do
				net.WriteBit(moddedEnemy.ModTable and moddedEnemy.ModTable[i] or false)
			end
		net.Send(ply)
		
	end)

end

if (CLIENT) then

	net.Receive("rpg_network_mods", function()
	
		local ent = net.ReadEntity()
		local modTable = {}
		for i = 1, #GAMEMODE.EnemyModTable do
			modTable[i] = net.ReadBit() == 1
			chat.AddText("Added... ", tostring(i), " ", tostring(modTable[i]))
		end

		ent.CSModCheck = true
		ent.ModTable = modTable
		chat.AddText("Added... ", tostring(ent))

		ent:RegenerateModName()

	end)

end

ENT.ModTable = {}

for i = 1, #GAMEMODE.EnemyModTable do
	ENT.ModTable[i] = false
end

