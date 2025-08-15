include("shared.lua")
include("modifiers.lua")

function ENT:Draw()
	self:DrawModel()
end

ENT.LastModSyncCheck = SysTime()
ENT.CSModCheck = false

function ENT:Think()

	local ply = LocalPlayer()
	
	if (SysTime() > self.LastModSyncCheck) then
		self.LastModSyncCheck = SysTime() + 10

		if (!self.CSModCheck) then
			chat.AddText("Mod count didn't sync up, retrying.")
			net.Start("rpg_network_mods")
				net.WriteEntity(self)
			net.SendToServer()
		else
			-- mod amount is synchronized, stop counting
			chat.AddText("Mod count is synced.")
			self.LastModSyncCheck = math.huge
		end
	end

end

function ENT:RegenerateModName()

	--GAMEMODE.EnemyModTable
	self.ModName = {}

	for i = 1, #GAMEMODE.EnemyModTable do

		local enabled = self.ModTable[i]
		if enabled then
			table.insert(self.ModName, GAMEMODE.EnemyModTable[i].name)
		end

	end

	self.ModName = table.concat(self.ModName, " ")
	print(self.ModName)

end