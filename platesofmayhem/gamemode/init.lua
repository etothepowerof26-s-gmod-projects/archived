AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
include("pom/config.lua")
util.AddNetworkString("addText_POM")

local TEAM_SPEC, TEAM_PLAY = 1, 2

POM.gameStarted = false
POM.spawnModel = POM.baseModel
POM.plates = {}
POM.playerAlive = {}
POM.playerDeathmatch = false

POM.actions = {
	{msg = "%s random player(s) will be ignited", action = function(plate)
		local p = plate:GetNWEntity("player", NULL)
		if (p ~= NULL and IsValid(p)) then
			p:Ignite(math.random(POM.settings.minIgnitionL, POM.settings.maxIgnitionL))
		end
	end},
	{msg = "%s random player(s) will explode", action = function(plate)
		local p = plate:GetNWEntity("player", NULL)
		if (p ~= NULL and IsValid(p)) then 
			local explode = ents.Create("env_explosion")
			explode:SetPos(p:GetPos())
			explode:Spawn()
			explode:SetKeyValue("iMagnitude", "50")
			explode:Fire("Explode", 0, 0)
			explode:EmitSound("weapon_AWP.Single", 400, 400)
		end
	end},
	{msg = "%s random player(s) will recieve a random amount health", action = function(plate)
		local p = plate:GetNWEntity("player", NULL)
		if (p ~= NULL and IsValid(p)) then
			p:SetHealth(p:Health() + math.random(1, POM.settings.maxHealthG))
		end
	end},
	{msg = "%s random player(s) will become smaller", action = function(plate)
		local p = plate:GetNWEntity("player", NULL)
		if (p ~= NULL and IsValid(p)) then
			p:SetModelScale(p:GetModelScale() * POM.settings.smallModel)
		end
	end},
	{msg = "%s random player(s) will become bigger", action = function(plate)
		local p = plate:GetNWEntity("player", NULL)
		if (p ~= NULL and IsValid(p)) then
			p:SetModelScale(p:GetModelScale() * POM.settings.bigModel)
		end
	end},
	{msg = "%s random player(s) will be able to superjump", action = function(plate)
		local p = plate:GetNWEntity("player", NULL)
		if (p ~= NULL and IsValid(p)) then
			p:SetGravity(.45)
		end
	end},
	{msg = "%s random player(s) will start dancing", action = function(plate)
		local p = plate:GetNWEntity("player", NULL)
		if (p ~= NULL and IsValid(p)) then
			p:ConCommand("act dance")
		end
	end},
	{msg = "%s random player(s) will teleported in the air", action = function(plate)
		local p = plate:GetNWEntity("player", NULL)
		if (p ~= NULL and IsValid(p)) then
			p:SetPos(p:GetPos()+Vector(0,0,200))
		end
	end},
	{msg = "%s random player(s) will recieve super speed", action = function(plate)
		local p = plate:GetNWEntity("player", NULL)
		if (p ~= NULL and IsValid(p)) then
			p:SetRunSpeed(800)
		end
	end},
	{msg = "%s random player(s) will recieve a random weapon with 3 shots", action = function(plate)
		local p = plate:GetNWEntity("player", NULL)
		if (p ~= NULL and IsValid(p)) then 
			p:Give("weapon_357")
			p:GetActiveWeapon():SetClip1(3)
		end
	end},
	{msg = "%s random player(s) will recieve a grenade", action = function(plate)
		local p = plate:GetNWEntity("player", NULL)
		if (p ~= NULL and IsValid(p)) then 
			p:Give("weapon_frag")
		end
	end},
	{msg = "%s random player(s) will recieve a crowbar", action = function(plate)
		local p = plate:GetNWEntity("player", NULL)
		if (p ~= NULL and IsValid(p)) then 
			p:Give("weapon_crowbar")
		end
	end},
	{msg = "%s random player(s) will be swapped with each other", action = function(plate)
		local p = plate:GetNWEntity("player", NULL)
		if (p ~= NULL and IsValid(p)) then 
			local p2 = table.Random(POM.playerAlive)
			local b = p:GetPos()
			p:SetPos(p2:GetPos())
			p2:SetPos(b)
		end
	end},
	{msg = "%s random player(s)' plate will recieve a buddy", action = function(plate)
		local Zombie = ents.Create("npc_zombie")
		Zombie:SetPos(plate:GetPos() + Vector(30, 30, 50))
		Zombie:Spawn()
	end},
	{msg = "%s random player(s)' plate will be slanted on a random angle", action = function(plate)
		plate:SetAngles(
			Angle(
				math.random(-POM.settings.maxIgnitionL, POM.settings.maxIgnitionL),
				math.random(-POM.settings.maxIgnitionL, POM.settings.maxIgnitionL),
				math.random(-POM.settings.maxIgnitionL, POM.settings.maxIgnitionL)
			)
		)
		local p = plate:GetNWEntity("player", NULL)
		if (p ~= NULL and IsValid(p)) then
			p:SetPos(p:GetPos()+Vector(0,0,30))
		end
	end},
	{msg = "%s random player(s)' plate will be transparent", action = function(plate)
		plate:SetRenderMode(RENDERMODE_TRANSALPHA)
		local c = plate:GetColor()
		plate:SetColor(Color(c.r,c.g,c.b,127))
	end},
	{msg = "%s random player(s)' model color will be randomized", action = function(plate)
		local p = plate:GetNWEntity("player", NULL)
		local r = math.random
		if (p ~= NULL and IsValid(p)) then
			p:SetColor(Color(r(0,255),r(0,255),r(0,255)))
		end
	end},
	{msg = "%s random player(s)' plate will become smaller", action = function(plate)
		--plate:SetModelScale(plate:GetModelScale() - (math.random(1, POM.settings.maxPlateScale) / 10))
		local mode = "/plates/plate"
		if plate:GetModel():find("cube") then mode = "/blocks/cube" end
		local plateSizex, plateSizey = 
			string.gmatch(plate:GetModel(), "models/hunter"..mode.."(.-)x(.-).mdl")()
		plateSizex, plateSizey = 
			math.Clamp(plateSizex - 1, 1, 8), math.Clamp(plateSizey - 1, 1, 8)
		plate:SetModel(string.format("models/hunter"..mode.."%sx%s.mdl",
			plateSizex, plateSizey))
	end},
	{msg = "%s random player(s)' plate will become bigger", action = function(plate)
		--plate:SetModelScale(plate:GetModelScale() - (math.random(1, POM.settings.maxPlateScale) / 10))
		local mode = "/plates/plate"
		if plate:GetModel():find("cube") then mode = "/blocks/cube" end
		local plateSizex, plateSizey = 
			string.gmatch(plate:GetModel(), "models/hunter"..mode.."(.-)x(.-).mdl")()
		plateSizex, plateSizey = 
			math.Clamp(plateSizex + 1, 1, 8), math.Clamp(plateSizey + 1, 1, 8)
		plate:SetModel(string.format("models/hunter"..mode.."%sx%s.mdl",
			plateSizex, plateSizey))end},
	{msg = "%s random player(s)' plate will become ignited", action = function(plate)
		local l = math.random(POM.settings.minIgnitionL, POM.settings.maxIgnitionL)
		plate:Ignite(l)
	end},
	{msg = "%s random player(s)' plate will be colored randomly", action = function(plate)
		local r = math.random
		plate:SetColor(Color(r(0,255),r(0,255),r(0,255)))
	end},
	{msg = "%s random player(s)' plate will become a cube", action = function(plate)
		local r = math.random
		plate:SetModel("models/hunter/blocks/cube4x4x4.mdl")
		local p = plate:GetNWEntity("player", NULL)
		if (p ~= NULL and IsValid(p)) then
			p:SetPos(p:GetPos()+Vector(0,0,100))
		end
	end}
}
POM.events = {
	{msg = "A combine gunship will spawn", action = function()
		local drop = ents.Create("npc_combinegunship")
		drop:SetPos(POM.platePos + Vector(POM.plateDistInc * (math.random(1,100) / 10), POM.plateDistInc * (math.random(1,100) / 10), 200))
		drop:Spawn()
	end},
	{msg = "Everyone will recieve a headcrab", action = function()
		for i,v in pairs(player.GetAll()) do
			local drop = ents.Create("npc_headcrab")
			drop:SetPos(v:GetPos() + Vector(0,0,100))
			drop:Spawn()
		end
	end}
}

function POM.init()
	if IsValid(POM.specBase) then return end
	POM.specBase = ents.Create("spawnplatform")
	POM.specBase:SetModel(POM.baseModel)
	POM.specBase:SetColor(POM.baseColor)
	POM.specBase:SetPos(POM.basePos)
	POM.specBase:Spawn()
	POM.spawnPoint = ents.Create("info_player_start")
	POM.spawnPoint:SetPos(POM.spawnPos)
	POM.spawnPoint:Spawn()	
end
function POM.think()
	for i,p in pairs(player.GetAll()) do
		if (p:GetPos().z < POM.maxFallHeight) and (p:Health() > 0) then
			p:Kill()
		end
	end
	if (#player.GetAll() < POM.neededPlayers) and POM.playerDeathmatch == false and POM.gameStarted == true then
		GAMEMODE:BroadcastAddText({
			Color(255, 127, 255),
			"PLATES OF MAYHEM > ",
			Color(127, 255, 127),
			"Deathmatch starting because of low player count!"
		})
		POM.playerDeathmatch = true
		for i,p in pairs(player.GetAll()) do
			p:Give("weapon_357")
			p:GetActiveWeapon():SetClip1(24)
		end
	end
	if (#POM.playerAlive == 1 and POM.gameStarted == true) then
		GAMEMODE:BroadcastAddText({
			Color(255, 127, 255),
			"PLATES OF MAYHEM > ",
			Color(127, 255, 127),
			POM.playerAlive[1]:IsValid() and POM.playerAlive[1]:GetName() or "???",
			Color(255, 255, 0),
			" has won the game!"
		})
		POM.endGame()
	elseif (#POM.playerAlive == 0 and POM.gameStarted == true) then
		GAMEMODE:BroadcastAddText({
			Color(255, 127, 255),
			"PLATES OF MAYHEM > ",
			Color(255, 255, 127),
			"Nobody",
			Color(255, 255, 0),
			" has won the game!"
		})
		POM.endGame()
	end
end
function POM.createPlatforms()
	for x = 1, 5 do
		for y = 1, 5 do
			local self = ents.Create("spawnplatform")
			self:SetModel(POM.plateModel)
			self:SetColor(POM.baseColor)
			self:SetPos(POM.platePos + Vector(POM.plateDistInc * (x-1), POM.plateDistInc * (y-1), 0))
			self:Spawn()
			POM.plates[#POM.plates + 1] = self
		end
	end
end
function POM.teleportPlayers()
	for i,v in pairs(player.GetAll()) do
		::chose::
		local plat = table.Random(POM.plates)
		if (plat:GetNWEntity("player", 0) ~= 0) then goto chose; else
			v:Spawn()
			v:SetPos(plat:GetPos()+Vector(0,0,20))
			v:SetAngles(Angle())
			v:SetEyeAngles(Angle())
			v:Freeze(true)
			plat:SetNWEntity("player", v)
		end
	end
end
function POM.getPlayerPlate(p)
	if (not p or not type(p) == "player") then return end
	for _,plate in pairs(POM.plates) do
		if (plate:GetNWEntity("player",0) ~= 0 and plate:GetNWEntity("player"):IsValid()) then
			if (plate:GetNWEntity("player"):SteamID() == p:SteamID()) then
				return plate
			end
		else 
			if (p:IsBot()) then 
				return plate
			end
		end
	end
end
function POM.performAction()
	local act = table.Random(POM.actions)
	local amnt = math.random(1, #POM.playerAlive)
	if (POM.gameStarted ~= true) then return end
	
	local event = math.random(1,10) == 1
	if (event) then
		local act = table.Random(POM.events)
		GAMEMODE:BroadcastAddText({
			Color(255, 127, 255),
			"PLATES OF MAYHEM > SPECIAL: ",
			Color(255, 127, 127),
			act.msg,
			Color(255, 255, 255),
			" in ", Color(0, 255, 0),
			"10", Color(255, 255, 255),
			" seconds."
		})
		timer.Simple(POM.settings.plateActionDelay, function()
			if (POM.gameStarted ~= true) then return end
			act.action()
		end)
	else
		GAMEMODE:BroadcastAddText({
			Color(255, 127, 255),
			"PLATES OF MAYHEM > ",
			Color(255, 255, 0),
			string.format(act.msg, amnt),
			Color(255, 255, 255),
			" in ", Color(0, 255, 0),
			"10", Color(255, 255, 255),
			" seconds."
		})
		timer.Simple(POM.settings.plateActionDelay, function()
			if (POM.gameStarted ~= true) then return end
			local affected = {}
			for i = 1, amnt do
				affected[i] = table.Random(POM.playerAlive)
				if affected[i]:IsValid() then
					local plate = POM.getPlayerPlate(affected[i])
					act.action(plate)
					affected[i] = affected[i]:GetName()
				end	
			end
			GAMEMODE:BroadcastAddText({
				Color(255, 127, 255),
				"PLATES OF MAYHEM > ",
				Color(127, 255, 127),
				table.concat(affected, ", "),
				Color(255, 255, 0),
				" was affected."
			})
		end)
	end
	
end

function POM.startGame()
	if (#player.GetAll() < POM.neededPlayers) then
		GAMEMODE:BroadcastAddText({
			Color(255, 127, 255),
			"PLATES OF MAYHEM > ",
			Color(255, 0, 0),
			"Not enough players to start game!"
		})
	else
		GAMEMODE:BroadcastAddText({
			Color(255, 127, 255),
			"PLATES OF MAYHEM > ",
			Color(0, 255, 0),
			"The game is starting!"
		})
		
		POM.createPlatforms()
		POM.teleportPlayers()
		POM.gameStarted = true
		POM.playerAlive = table.Copy(player.GetAll())
		POM.playerDeathmatch = false
		
		for i,v in pairs(player.GetAll()) do
			v:SetTeam(TEAM_PLAY)
			v.DeathNotifPlayed = false
			v:StripWeapons()
		end
		for _,plate in pairs(POM.plates) do
			if (plate:GetNWEntity("player", NULL) == 0) then
				table.remove(POM.plates, _)
				plate:Remove()
			end
		end
		timer.Simple(3, function()
			for i,v in pairs(player.GetAll()) do
				v:Freeze(false)
			end
			POM.performAction()
			timer.Create("POM_actions", 12, 0, POM.performAction)
		end)
	end
end
function POM.endGame()
	for i,v in pairs(ents.FindByClass("spawnplatform")) do
		if (v:GetPos() ~= POM.basePos) then
			v:Remove()
		end
	end
	for i,v in pairs(ents.FindByClass("npc_*")) do
		v:Remove()
	end
	for i,v in pairs(player.GetAll()) do
		v:SetTeam(TEAM_SPEC)
		v:Spawn()
		v:StripWeapons()
		v.DeathNotifPlayed = true
	end
	POM.plates = {}
	POM.gameStarted = false
	POM.playerAlive = {}
	timer.Remove("POM_actions")
end

function GM:PlayerAddText(player, Args)
	net.Start("addText_POM")
		net.WriteTable(Args)
	net.Send(player)
end
function GM:BroadcastAddText(Args)
	net.Start("addText_POM")
		net.WriteTable(Args)
	net.Broadcast()
end
function GM:PlayerSpawn(ply)
	ply:SetPos(POM.spawnPos)
	ply:SetModelScale(1)
	ply:SetColor(POM.baseColor)
	ply:SetGravity(1)
	ply:SetRunSpeed(400)
	if (ply:Team() == 1) then
		GAMEMODE:PlayerAddText(ply, {
			Color(200, 200, 200),
			"You will spawn in next round."
		})
	end
end
function GM:PlayerInitialSpawn(ply)
	ply:SetTeam(TEAM_SPEC)
	ply:SetModel("models/player/Group03/Male_07.mdl")
	ply:SetNoCollideWithTeammates(true)
	ply:AllowFlashlight(true)
	ply.DeathNotifPlayed = true
	timer.Simple(.1, function()
		GAMEMODE:BroadcastAddText({
			Color(255, 127, 255),
			"PLATES OF MAYHEM > ",
			Color(255, 255, 0),
			ply:GetName(),
			Color(0, 255, 0),
			" (",ply:SteamID(),") ",
			Color(255, 255, 255),
			"has joined the game."
		})
	end)
end
function GM:PlayerDeath(ply, inf, att)
	if not ply.DeathNotifPlayed then 
		GAMEMODE:BroadcastAddText({
			Color(255, 127, 255),
			"PLATES OF MAYHEM > ",
			Color(255, 255, 0),
			ply:GetName(),
			Color(255, 0, 0),
			" has died!"
		})
		for i,v in pairs(POM.playerAlive) do
			if v == ply then
				table.remove(POM.playerAlive, i)
			end
		end
		ply.DeathNotifPlayed = true
	end
end
function GM:PlayerSelectSpawn(ply)
	return POM.spawnPoint
end

hook.Add("Think", "POM.think", POM.think)
hook.Add("InitPostEntity", "POM.init", POM.init)
concommand.Add("pom_start", POM.startGame)
concommand.Add("pom_end", POM.endGame)

print("POM loaded")