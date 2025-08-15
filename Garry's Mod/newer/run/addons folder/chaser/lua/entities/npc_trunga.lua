
AddCSLuaFile()

ENT.Base = "base_nextbot"

ENT.PhysgunDisabled = true
ENT.AutomaticFrameAdvance = false

ENT.JumpSound = Sound("")
ENT.JumpHighSound = Sound("")
ENT.TauntSounds = {
	Sound("npc_trunga/bingbong.mp3"),
}
local chaseMusic = Sound("npc_trunga/trunga_chase.mp3")

local workshopID = "2812450140"

local IsValid = IsValid

local TRUNGA_3D_MODEL = Model("models/trunga/trunga.mdl")

local npc_trunga_use_3d =
	CreateConVar("npc_trunga_use_3d", 0, FCVAR_REPLICATED,
	"Enable the 3D model.")

if SERVER then -- SERVER --

local npc_trunga_acquire_distance =
	CreateConVar("npc_trunga_acquire_distance", 2500, FCVAR_NONE,
	"The maximum distance at which Donald Trunga will chase a target.")

local npc_trunga_spawn_protect =
	CreateConVar("npc_trunga_spawn_protect", 1, FCVAR_NONE,
	"If set to 1, trunga will not target players or hide within 200 units of \z
	a spawn point.")

local npc_trunga_attack_distance =
	CreateConVar("npc_trunga_attack_distance", 80, FCVAR_NONE,
	"The reach of trunga's attack.")

local npc_trunga_attack_interval =
	CreateConVar("npc_trunga_attack_interval", 0.2, FCVAR_NONE,
	"The delay between trunga's attacks.")

local npc_trunga_attack_force =
	CreateConVar("npc_trunga_attack_force", 500, FCVAR_NONE,
	"The physical force of trunga's attack. Higher values throw things \z
	farther.")

local npc_trunga_smash_props =
	CreateConVar("npc_trunga_smash_props", 1, FCVAR_NONE,
	"If set to 1, trunga will punch through any props placed in their way.")

local npc_trunga_allow_jump =
	CreateConVar("npc_trunga_allow_jump", 1, FCVAR_NONE,
	"If set to 1, trunga will be able to jump.")

local npc_trunga_hiding_scan_interval =
	CreateConVar("npc_trunga_hiding_scan_interval", 3, FCVAR_NONE,
	"trunga will only seek out hiding places every X seconds. This can be an \z
	expensive operation, so it is not recommended to lower this too much. \z
	However, if distant trungas are not hiding from you quickly enough, you \z
	may consider lowering this a small amount.")

local npc_trunga_hiding_repath_interval =
	CreateConVar("npc_trunga_hiding_repath_interval", 1, FCVAR_NONE,
	"The path to trunga's hiding spot will be redetermined every X seconds.")

local npc_trunga_chase_repath_interval =
	CreateConVar("npc_trunga_chase_repath_interval", 0.1, FCVAR_NONE,
	"The path to and position of trunga's target will be redetermined every \z
	X seconds.")

local npc_trunga_expensive_scan_interval =
	CreateConVar("npc_trunga_expensive_scan_interval", 1, FCVAR_NONE,
	"Slightly expensive operations (distance calculations and entity \z
	searching) will occur every X seconds.")

local npc_trunga_force_download =
	CreateConVar("npc_trunga_force_download", 1, FCVAR_ARCHIVE,
	"If set to 1, clients will be forced to download trunga resources \z
	(restart required after changing).\n\z
	WARNING: If this option is disabled, clients will be unable to see or \z
	hear trunga!")

 -- So we don't spam voice TOO much.
local TAUNT_INTERVAL = 1.2
local PATH_INFRACTION_TIMEOUT = 5

if npc_trunga_force_download:GetBool() then
	resource.AddWorkshop(workshopID)
end

util.AddNetworkString("trunga_nag")
util.AddNetworkString("trunga_navgen")

 -- Pathfinding is only concerned with static geometry anyway.
local trace = {
	mask = MASK_SOLID_BRUSHONLY
}

local function isPointNearSpawn(point, distance)
	--TODO: Is this a reliable standard??
	if not GAMEMODE.SpawnPoints then return false end

	local distanceSqr = distance * distance
	for _, spawnPoint in pairs(GAMEMODE.SpawnPoints) do
		if not IsValid(spawnPoint) then continue end

		if point:DistToSqr(spawnPoint:GetPos()) <= distanceSqr then
			return true
		end
	end

	return false
end

local function isPositionExposed(pos)
	for _, ply in pairs(player.GetAll()) do
		if IsValid(ply) and ply:Alive() and ply:IsLineOfSightClear(pos) then
			-- This spot can be seen!
			return true
		end
	end

	return false
end

local VECTOR_TRUNGA_HEIGHT = Vector(0, 0, 96)
local function isPointSuitableForHiding(point)
	trace.start = point
	trace.endpos = point + VECTOR_TRUNGA_HEIGHT
	local tr = util.TraceLine(trace)

	return (not tr.Hit)
end

local g_hidingSpots = nil
local function buildHidingSpotCache()
	local rStart = SysTime()

	g_hidingSpots = {}

	-- Look in every area on the navmesh for usable hiding places.
	-- Compile them into one nice list for lookup.
	local areas = navmesh.GetAllNavAreas()
	local goodSpots, badSpots = 0, 0
	for _, area in pairs(areas) do
		for _, hidingSpot in pairs(area:GetHidingSpots()) do
			if isPointSuitableForHiding(hidingSpot) then
				g_hidingSpots[goodSpots + 1] = {
					pos = hidingSpot,
					nearSpawn = isPointNearSpawn(hidingSpot, 200),
					occupant = nil,
				}
				goodSpots = goodSpots + 1
			else
				badSpots = badSpots + 1
			end
		end
	end

	print(string.format("npc_trunga: found %d suitable (%d unsuitable) hiding \z
		places in %d areas over %.2fms!", goodSpots, badSpots, #areas,
		(SysTime() - rStart) * 1000))
end

local ai_ignoreplayers = GetConVar("ai_ignoreplayers")
local function isValidTarget(ent)
	-- Ignore non-existant entities.
	if not IsValid(ent) then return false end

	-- Ignore dead players (or all players if `ai_ignoreplayers' is 1)
	if ent:IsPlayer() then
		if ai_ignoreplayers:GetBool() then return false end
		return ent:Alive()
	end

	-- Ignore dead NPCs, other trungas, and dummy NPCs.
	local class = ent:GetClass()
	return (ent:IsNPC()
		and ent:Health() > 0
		and class ~= "npc_trunga"
		and not class:find("bullseye"))
end

hook.Add("PlayerSpawnedNPC", "TrungaMissingNavmeshNag", function(ply, ent)
	if not IsValid(ent) then return end
	if ent:GetClass() ~= "npc_trunga" then return end
	if navmesh.GetNavAreaCount() > 0 then return end

	-- Try to explain why trunga isn't working.
	net.Start("trunga_nag")
	net.Send(ply)
end)

local generateStart = 0
local function navEndGenerate()
	local timeElapsedStr = string.NiceTime(SysTime() - generateStart)

	if not navmesh.IsGenerating() then
		print("npc_trunga: Navmesh generation completed in " .. timeElapsedStr)
	else
		print("npc_trunga: Navmesh generation aborted after " .. timeElapsedStr)
	end

	-- Turn this back off.
	RunConsoleCommand("developer", "0")
end

local DEFAULT_SEEDCLASSES = {
	-- Source games in general
	"info_player_start",

	-- Garry's Mod (Obsolete)
	"gmod_player_start", "info_spawnpoint",

	-- Half-Life 2: Deathmatch
	"info_player_combine", "info_player_rebel", "info_player_deathmatch",

	-- Counter-Strike (Source & Global Offensive)
	"info_player_counterterrorist", "info_player_terrorist",

	-- Day of Defeat: Source
	"info_player_allies", "info_player_axis",

	-- Team Fortress 2
	"info_player_teamspawn",

	-- Left 4 Dead (1 & 2)
	"info_survivor_position",

	-- Portal 2
	"info_coop_spawn",

	-- Age of Chivalry
	"aoc_spawnpoint",

	-- D.I.P.R.I.P. Warm Up
	"diprip_start_team_red", "diprip_start_team_blue",

	-- Dystopia
	"dys_spawn_point",

	-- Insurgency
	"ins_spawnpoint",

	-- Pirates, Vikings, and Knights II
	"info_player_pirate", "info_player_viking", "info_player_knight",

	-- Obsidian Conflict (and probably some generic CTF)
	"info_player_red", "info_player_blue",

	-- Synergy
	"info_player_coop",

	-- Zombie Master
	"info_player_zombiemaster",

	-- Zombie Panic: Source
	"info_player_human", "info_player_zombie",

	-- Some maps start you in a cage room with a start button, have building
	-- interiors with teleportation doors, or the like.
	-- This is so the navmesh will (hopefully) still generate correctly and
	-- fully in these cases.
	"info_teleport_destination",
}

local function addEntitiesToSet(set, ents)
	for _, ent in pairs(ents) do
		if IsValid(ent) then
			set[ent] = true
		end
	end
end

local NAV_GEN_STEP_SIZE = 25
local function navGenerate()
	local seeds = {}

	-- Add a bunch of the usual classes as walkable seeds.
	for _, class in pairs(DEFAULT_SEEDCLASSES) do
		addEntitiesToSet(seeds, ents.FindByClass(class))
	end

	-- For gamemodes that define their own spawnpoint entities.
	addEntitiesToSet(seeds, GAMEMODE.SpawnPoints or {})

	if next(seeds, nil) == nil then
		print("npc_trunga: Couldn't find any places to seed nav_generate")
		return false
	end

	for seed in pairs(seeds) do
		local pos = seed:GetPos()
		pos.x = NAV_GEN_STEP_SIZE * math.Round(pos.x / NAV_GEN_STEP_SIZE)
		pos.y = NAV_GEN_STEP_SIZE * math.Round(pos.y / NAV_GEN_STEP_SIZE)

		-- Start a little above because some mappers stick the
		-- teleport destination right on the ground.
		trace.start = pos + vector_up
		trace.endpos = pos - vector_up * 16384
		local tr = util.TraceLine(trace)

		if not tr.StartSolid and tr.Hit then
			print(string.format("npc_trunga: Adding seed %s at %s", seed, pos))
			navmesh.AddWalkableSeed(tr.HitPos, tr.HitNormal)
		else
			print(string.format("npc_trunga: Couldn't add seed %s at %s", seed,
				pos))
		end
	end

	-- The least we can do is ensure they don't have to listen to this noise.
	for _, trunga in pairs(ents.FindByClass("npc_trunga")) do
		trunga:Remove()
	end

	-- This isn't strictly necessary since we just added EVERY spawnpoint as a
	-- walkable seed, but I dunno. What does it hurt?
	navmesh.SetPlayerSpawnName(next(seeds, nil):GetClass())

	navmesh.BeginGeneration()

	if navmesh.IsGenerating() then
		generateStart = SysTime()
		hook.Add("ShutDown", "TrungaNavGen", navEndGenerate)
	else
		print("npc_trunga: nav_generate failed to initialize")
		navmesh.ClearWalkableSeeds()
	end

	return navmesh.IsGenerating()
end

concommand.Add("npc_trunga_learn", function(ply, cmd, args)
	if navmesh.IsGenerating() then
		return
	end

	-- Rcon or single-player only.
	local isConsole = (ply:EntIndex() == 0)
	if game.SinglePlayer() then
		print("npc_trunga: Beginning nav_generate requested by " .. ply:Name())

		-- Disable expensive computations in single-player. trunga doesn't use
		-- their results, and it consumes a massive amount of time and CPU.
		-- We'd do this on dedicated servers as well, except that sv_cheats
		-- needs to be enabled in order to disable visibility computations.
		RunConsoleCommand("nav_max_view_distance", "1")
		RunConsoleCommand("nav_quicksave", "1")

		-- Enable developer mode so we can see console messages in the corner.
		RunConsoleCommand("developer", "1")
	elseif isConsole then
		print("npc_trunga: Beginning nav_generate requested by server console")
	else
		return
	end

	local success = navGenerate()

	-- If it fails, only the person who started it needs to know.
	local recipients = (success and player.GetHumans() or {ply})

	net.Start("trunga_navgen")
		net.WriteBool(success)
	net.Send(recipients)
end)

ENT.LastPathRecompute = 0
ENT.LastTargetSearch = 0
ENT.LastJumpScan = 0
ENT.LastStuckCheck = 0
ENT.LastAttack = 0
ENT.LastHidingPlaceScan = 0
ENT.LastTaunt = 0

ENT.CurrentTarget = nil
ENT.HidingSpot = nil

function ENT:Initialize()
	-- Spawn effect resets render override. Bug!!!
	self:SetSpawnEffect(false)

	self:SetBloodColor(DONT_BLEED)

	-- Just in case.
	self:SetHealth(1e8)

	--self:DrawShadow(false) -- Why doesn't this work???

	--HACK!!! Disables shadow (for real).
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetColor(npc_trunga_use_3d:GetBool() and color_white or Color(255, 255, 255, 1))

	-- April Fools 2020 lives on forever in convar form.
	self:SetModel(TRUNGA_3D_MODEL)

	-- Human-sized collision.
	self:SetCollisionBounds(Vector(-13, -13, 0), Vector(13, 13, 72))

	-- We're a little timid on drops... Give the player a chance. :)
	self.loco:SetDeathDropHeight(600)

	-- In Sandbox, players are faster in singleplayer.
	self.loco:SetDesiredSpeed(game.SinglePlayer() and 650 or 500)

	-- Take corners a bit sharp.
	self.loco:SetAcceleration(500)
	self.loco:SetDeceleration(500)

	-- This isn't really important because we reset it all the time anyway.
	self.loco:SetJumpHeight(300)

	-- Rebuild caches.
	self:OnReloaded()
end

cvars.RemoveChangeCallback("npc_trunga_use_3d", "trunga_render_flip")
cvars.AddChangeCallback("npc_trunga_use_3d", function(cvar, oldValue, newValue)
	local oldNum = math.floor(tonumber(oldValue) or 0)
	local newNum = math.floor(tonumber(newValue) or 0)

	local oldBool = (oldNum ~= 0)
	local newBool = (newNum ~= 0)

	if oldBool == newBool then return end

	for _, trunga in pairs(ents.FindByClass("npc_trunga")) do
		trunga:SetColor(newBool and color_white or Color(255, 255, 255, 1))
	end
end, "trunga_render_flip")

function ENT:OnInjured(dmg)
	-- Just in case.
	dmg:SetDamage(0)
end

function ENT:OnReloaded()
	if g_hidingSpots == nil then
		buildHidingSpotCache()
	end
end

function ENT:OnRemove()
	-- Give up our hiding spot when we're deleted.
	self:ClaimHidingSpot(nil)
end

function ENT:GetNearestTarget()
	-- Only target entities within the acquire distance.
	local maxAcquireDist = npc_trunga_acquire_distance:GetInt()
	local myPos = self:GetPos()
	local distToSqr = myPos.DistToSqr
	local getPos = self.GetPos

	local target = nil
	local maxAcquireDistSqr = maxAcquireDist * maxAcquireDist

	for _, ent in pairs(ents.FindInSphere(myPos, maxAcquireDist)) do
		-- Ignore invalid targets, of course.
		if not isValidTarget(ent) then continue end

		-- Spawn protection! Ignore players within 200 units of a spawn point
		-- if `npc_trunga_spawn_protect' = 1.
		if npc_trunga_spawn_protect:GetBool() and ent:IsPlayer()
			and isPointNearSpawn(ent:GetPos(), 200)
		then
			continue
		end

		-- Find the nearest target to chase.
		local distSqr = distToSqr(getPos(ent), myPos)
		if distSqr < maxAcquireDistSqr then
			target = ent
			maxAcquireDistSqr = distSqr
		end
	end

	return target
end

function ENT:AttackNearbyTargets(radius)
	local attackForce = npc_trunga_attack_force:GetInt()
	local hitSource = self:LocalToWorld(self:OBBCenter())
	local hurtOpponent = false

	for _, ent in pairs(ents.FindInSphere(hitSource, radius)) do
		if isValidTarget(ent) then
			hurtOpponent = self:AttackOpponent(ent, hitSource, attackForce)
				or hurtOpponent
		elseif ent:GetMoveType() == MOVETYPE_VPHYSICS then
			if not npc_trunga_smash_props:GetBool() then continue end
			if ent:IsVehicle() and IsValid(ent:GetDriver()) then continue end
			self:AttackProp(ent, hitSource, attackForce)
		elseif ent:GetClass() == "prop_door_rotating" then
			if not npc_trunga_smash_props:GetBool() then continue end
			self:AttackDoor(ent, hitSource, attackForce)
		end
	end

	return hurtOpponent
end

local WL_SUBMERGED = 3

function ENT:AttackOpponent(target, hitSource, attackForce)
	local startHealth = target:Health()

	if target:IsPlayer() and IsValid(target:GetVehicle()) then
		-- Hiding in a vehicle, eh?
		-- Damaging the vehicle will damage the player.
		-- Players are otherwise invulnerable while driving.
		self:AttackProp(target:GetVehicle(), hitSource, attackForce)
	else
		target:EmitSound(string.format(
			"physics/body/body_medium_impact_hard%d.wav",
			math.random(1, 6)), 350, 120)

		-- We fudge the source of the punch so that it tends to punch targets
		-- up into the air.
		local targetPos = target:LocalToWorld(target:OBBCenter())
		local fudgedHitSource = hitSource + Vector(0, 0, -10)
		local hitDirection = targetPos - fudgedHitSource
		hitDirection:Normalize()

		-- Give our target a good whack. trunga means business.
		local smackForce = hitDirection * attackForce

		if target:IsPlayer() then
			-- This is for those with god mode enabled.
			local velocity = smackForce

			-- For players above water, z "velocity" is treated as a force. We
			-- want our new velocity to apply in full, so we need the force that
			-- will result in an impulse that will instantaneously apply the
			-- desired velocity.
			-- Impulse = Force * Time, so Force = Impulse / Time.
			if target:WaterLevel() < WL_SUBMERGED then
				velocity.z = velocity.z / FrameTime()
			end

			-- The ground is sticky, so we need to force players off of it if
			-- we want some airtime.
			if target:IsFlagSet(FL_ONGROUND) then
				-- Clear the stickiness. This will clear the ground flag.
				target:SetGroundEntity(nil)
			end

			-- If velocity has been applied this frame, don't overwrite.
			if target:IsFlagSet(FL_BASEVELOCITY) then
				velocity = velocity + target:GetBaseVelocity()
			end

			-- Base velocity is velocity applied by external forces. Regular
			-- velocity is *local* velocity, applied by the entity to itself.
			-- Physics props ignore base velocity, but it's the only correct
			-- way to apply forces to players and NPCs. So naturally, GMod has
			-- no SetBaseVelocity function. Whoops. Good thing we have this!
			target:SetSaveValue("m_vecBaseVelocity", velocity)
			target:AddFlags(FL_BASEVELOCITY)
		end

		local dmgInfo = DamageInfo()
		dmgInfo:SetAttacker(self)
		dmgInfo:SetInflictor(self)
		dmgInfo:SetDamage(1e8)
		dmgInfo:SetDamagePosition(self:GetPos())
		dmgInfo:SetDamageForce(smackForce * 100)
		target:TakeDamageInfo(dmgInfo)
	end

	-- Hits only count if we dealt some damage.
	return (target:Health() < startHealth)
end

-- It's mildly more expensive to look this up than I care for.
local g_materialSoundCache = {}
local function getMaterialImpactSound(material)
	local soundName = g_materialSoundCache[material]
	if soundName then
		return soundName
	end

	local surfaceId = util.GetSurfaceIndex(material)
	local surfaceProps = util.GetSurfaceData(surfaceId)

	soundName = surfaceProps.impactHardSound
	g_materialSoundCache[material] = soundName
	return soundName
end

function ENT:AttackProp(prop, hitSource, attackForce)
	-- Knock away any props put in our path.
	local entPos = prop:LocalToWorld(prop:OBBCenter())
	local hitDirection = entPos - hitSource
	hitDirection:Normalize()
	local hitOffset = prop:NearestPoint(hitSource)

	-- Wake it up and get some basic info.
	local phys = prop:GetPhysicsObject()
	local mass = 0
	local material = "Default"
	if IsValid(phys) then
		phys:Wake()
		mass = phys:GetMass()
		material = phys:GetMaterial()
	end

	local hitForce = hitDirection * (attackForce * mass)

	if prop:IsVehicle() then
		-- Vehicles play different sounds and don't apply forces per-bone.
		-- Make a nice SMASH noise.
		prop:EmitSound(string.format(
			"physics/metal/metal_sheet_impact_hard%d.wav",
			math.random(6, 8)), 350, 120)

		-- Give it a good whack.
		if IsValid(phys) then
			phys:ApplyForceOffset(hitForce, hitOffset)
		end

		-- Hit vehicles EXTRA hard, in case there's a player inside.
		prop:TakeDamage(1e8, self, self)
	else
		-- Don't make a noise if the object is too light.
		-- It's probably a gib.
		if mass >= 5 then
			prop:EmitSound(getMaterialImpactSound(material), 350, 120)
		end

		-- Remove anything tying the entity down.
		-- We're crashing through here!
		constraint.RemoveAll(prop)

		-- Unfreeze all bones, and give the object a good whack.
		for id = 0, prop:GetPhysicsObjectCount() - 1 do
			local physBone = prop:GetPhysicsObjectNum(id)
			if IsValid(physBone) then
				physBone:EnableMotion(true)
				physBone:ApplyForceOffset(hitForce, hitOffset)
			end
		end

		-- Deal some solid damage, too.
		prop:TakeDamage(25, self, self)
	end
end

-- Open any corresponding areaportals. These are closely tied with doors in the
-- Source engine.
local function detachAreaPortals(door)
	door.TRUNGA_detachedAreaPortals = {}

	local doorName = door:GetName()
	if doorName == "" then return end

	for id, portal in pairs(ents.FindByClass("func_areaportal")) do
		local portalTarget = portal:GetInternalVariable("m_target")
		if portalTarget ~= doorName then continue end

		portal:Input("Open", self, door)

		-- Disconnect the areaportal so any entities playing with the door don't
		-- trigger it to close. We'll link it again when we put the door back.
		door.TRUNGA_detachedAreaPortals[id] = portal
		portal:SetSaveValue("m_target", "")
	end
end

-- From Source SDK 2013, BasePropDoor.h
-- Door is fully closed.
local DOOR_STATE_CLOSED = 0

-- Reconnect a door's areaportals and update their state.
local function reattachAreaPortals(door)
	local doorName = door:GetName()
	local doorClosed = (door:GetInternalVariable("m_eDoorState")
		== DOOR_STATE_CLOSED)
	for _, portal in pairs(door.TRUNGA_detachedAreaPortals) do
		portal:SetSaveValue("m_target", doorName)
		portal:Input(doorClosed and "Close" or "Open", door, door)
	end
	door.TRUNGA_detachedAreaPortals = nil
end

-- Create a physics-only clone of the given door.
local function createDoorClone(door)
	local fakeDoor = ents.Create("prop_physics")

	-- Clone visuals.
	fakeDoor:SetModel(door:GetModel())
	fakeDoor:SetSkin(door:GetSkin())

	-- Copy bodygroups so the handles stay the same
	local numBodygroups = door:GetNumBodyGroups()
	for i = 0, numBodygroups - 1 do
		fakeDoor:SetBodygroup(i, door:GetBodygroup(i))
	end

	-- Position it the same.
	fakeDoor:SetPos(door:GetPos())
	fakeDoor:SetAngles(door:GetAngles())

	return fakeDoor
end

-- Remove the entity in a shower of sparks.
local function fizzleRemove(ent)
	-- Temporary "removal" so we can play an effect.
	constraint.RemoveAll(ent)

	-- Hide and freeze.
	ent:SetNoDraw(true)
	ent:SetNotSolid(true)
	ent:SetMoveType(MOVETYPE_NONE)

	-- Poof!
	local effectData = EffectData()
	effectData:SetEntity(fakeDoor)
	util.Effect("entity_remove", effectData, true, true)

	-- Remove it for real shortly after.
	timer.Simple(1, function()
		if ent:IsValid() then
			ent:Remove()
		end
	end)
end

local function restoreBrokenDoor(door, fakeDoor)
	if door:IsValid() then
		-- Don't just pop the door back in. Use a nice effect.
		local effectData = EffectData()
		effectData:SetOrigin(door:GetPos())
		effectData:SetEntity(door)
		util.Effect("propspawn", effectData, true, true)

		-- Put the original door back.
		door:SetNoDraw(false)
		door:SetNotSolid(false)

		timer.Simple(1, function()
			reattachAreaPortals(door)
		end)
	end

	if fakeDoor:IsValid() then
		fizzleRemove(fakeDoor)
	end
end

-- Don't respawn if a player is this close or they might get stuck in the door.
local DOOR_DANGER_CLOSE_DIST_SQR = math.pow(100, 2)

-- Watch for players this near. They might want to pass through the empty
-- doorframe, so don't surprise them with a sudden door.
local DOOR_POSSIBLE_APPROACH_DIST_SQR = math.pow(1000, 2)

-- The approach angle at which we assume they're coming toward the door.
local DOOR_APPROACH_COSINE = math.cos(math.pi / 4) -- 45 degrees

-- There are cases where restoring the door is a bad idea.
local function doorShouldRepawn(door)
	for _, ply in pairs(player.GetAll()) do
		if not ply:Alive() then continue end

		-- Make sure nobody is in the way so we don't trap them.
		local distSqr = ply:GetPos():DistToSqr(door:GetPos())
		if distSqr < DOOR_DANGER_CLOSE_DIST_SQR then
			-- Too near! Try again later.
			return false
		elseif distSqr < DOOR_POSSIBLE_APPROACH_DIST_SQR then
			-- Kind of close. Don't slam a door in their face.
			-- Can this door be seen from a player's position?
			local doorPos = door:LocalToWorld(door:OBBCenter())
			local tr = util.TraceLine({
				start = ply:EyePos(),
				endpos = doorPos,
				mask = MASK_OPAQUE,
			})

			if tr.Fraction == 1 then
				-- Player is within LOS of the door.
				-- Let's guess if they want to go through.
				-- Are they moving roughly towards the door?
				local doorDir = doorPos - ply:EyePos()
				doorDir:Normalize()
				local walkDir = ply:GetVelocity()
				walkDir:Normalize()

				local walkingCos = doorDir:Dot(walkDir)
				if walkingCos > DOOR_APPROACH_COSINE then
					-- Walking roughly toward the door.
					return false
				end

				-- Are they looking this way?
				local lookDir = ply:EyeAngles():Forward()

				local lookingCos = doorDir:Dot(lookDir)
				if lookingCos > DOOR_APPROACH_COSINE then
					-- Looking roughly at the door.
					return false
				end
			end
		end
	end

	return true
end

local function queueDoorRestorationFunc(door, fakeDoor)
	-- Self-referencing function so we can retry.
	local restoreFunc
	restoreFunc = function()
		if door:IsValid() and not doorShouldRepawn(door) then
			timer.Simple(1, restoreFunc)
			return
		end

		restoreBrokenDoor(door, fakeDoor)
	end

	return restoreFunc
end

function ENT:AttackDoor(door, hitSource, attackForce)
	-- Don't hit doors we've already hit.
	if bit.band(door:GetSolidFlags(), FSOLID_NOT_SOLID) ~= 0 then return end
	if door.TRUNGA_detachedAreaPortals ~= nil then return end

	-- Hide the original door. We'll put it back later.
	door:SetNoDraw(true)
	door:SetNotSolid(true)

	detachAreaPortals(door)

	-- Create a matching fake door.
	-- We don't apply any force since TRUNGA will do that for us next attack.
	local fakeDoor = createDoorClone(door)
	fakeDoor:Spawn()
	fakeDoor:Activate()

	-- Copy the physics material, too.
	local realPhys = door:GetPhysicsObject()
	if IsValid(realPhys) then
		local fakePhys = fakeDoor:GetPhysicsObject()
		if IsValid(fakePhys) then
			fakePhys:SetMaterial(realPhys:GetMaterial())
		end
	end

	-- What's this door made out of?
	local physMaterial = "metal"
	local phys = fakeDoor:GetPhysicsObject()
	if IsValid(phys) then
		physMaterial = phys:GetMaterial()
	end

	-- Use a really punchy noise for doors. These things are being
	-- knocked off their hinges, after all.
	if physMaterial == "wood" then
		door:EmitSound(string.format(
			"physics/wood/wood_crate_break%d.wav",
			math.random(1, 5)), 350, 120)
	else
		-- Default to metal sounds. They're good in all cases.
		-- Hinges are metal, after all!
		local randSoundId = math.random(1, 4)
		if randSoundId < 4 then
			door:EmitSound(string.format("doors/vent_open%d.wav",
				randSoundId), 350, 120)
		else
			door:EmitSound("doors/heavy_metal_stop1.wav", 350, 120)
		end
	end

	-- WHAM. Smash that door in!
	self:AttackProp(fakeDoor, hitSource, attackForce)

	-- Try to put the door back after a while.
	timer.Simple(10, queueDoorRestorationFunc(door, fakeDoor))
end

function ENT:IsHidingSpotFull(hidingSpot)
	-- It's not full if there's no occupant, or we're the one in it.
	local occupant = hidingSpot.occupant
	if not IsValid(occupant) or occupant == self then
		return false
	end

	return true
end

function ENT:GetNearestUsableHidingSpot()
	local nearestHidingSpot = nil
	local nearestHidingDistSqr = 1e8

	local myPos = self:GetPos()
	local isHidingSpotFull = self.IsHidingSpotFull
	local distToSqr = myPos.DistToSqr

	-- This could be a long loop. Optimize the heck out of it.
	for _, hidingSpot in pairs(g_hidingSpots) do
		-- Ignore hiding spots that are near spawn, or full.
		if hidingSpot.nearSpawn or isHidingSpotFull(self, hidingSpot) then
			continue
		end

		local hidingSpotDistSqr = distToSqr(hidingSpot.pos, myPos)
		if hidingSpotDistSqr < nearestHidingDistSqr
			and not isPositionExposed(hidingSpot.pos)
		then
			nearestHidingDistSqr = hidingSpotDistSqr
			nearestHidingSpot = hidingSpot
		end
	end

	return nearestHidingSpot
end

function ENT:ClaimHidingSpot(hidingSpot)
	-- Release our claim on the old spot.
	if self.HidingSpot ~= nil then
		self.HidingSpot.occupant = nil
	end

	-- Can't claim something that doesn't exist, or a spot that's
	-- already claimed.
	if hidingSpot == nil or self:IsHidingSpotFull(hidingSpot) then
		self.HidingSpot = nil
		return false
	end

	-- Yoink.
	self.HidingSpot = hidingSpot
	self.HidingSpot.occupant = self
	return true
end

-- The threshold at which we play a different jump sound.
local HIGH_JUMP_HEIGHT = 500

function ENT:AttemptJumpAtTarget()
	-- No double-jumping.
	if not self:IsOnGround() then return end

	local targetPos = self.CurrentTarget:GetPos()
	local xyDistSqr = (targetPos - self:GetPos()):Length2DSqr()
	local zDifference = targetPos.z - self:GetPos().z
	local maxAttackDistance = npc_trunga_attack_distance:GetInt()
	if xyDistSqr <= math.pow(maxAttackDistance + 200, 2)
		and zDifference >= maxAttackDistance
	then
		--TODO: Set up jump so target lands on parabola.
		local jumpHeight = zDifference + 50
		self.loco:SetJumpHeight(jumpHeight)
		self.loco:Jump()
		self.loco:SetJumpHeight(300)

		self:EmitSound((jumpHeight > HIGH_JUMP_HEIGHT and
			self.JumpHighSound or self.JumpSound), 350, 100)
	end
end

local VECTOR_HIGH = Vector(0, 0, 16384)
ENT.LastPathingInfraction = 0
function ENT:RecomputeTargetPath()
	if CurTime() - self.LastPathingInfraction < PATH_INFRACTION_TIMEOUT then
		-- No calculations for you today.
		return
	end

	local targetPos = self.CurrentTarget:GetPos()

	-- Run toward the position below the entity we're targetting,
	-- since we can't fly.
	trace.start = targetPos
	trace.endpos = targetPos - VECTOR_HIGH
	trace.filter = self.CurrentTarget
	local tr = util.TraceEntity(trace, self.CurrentTarget)

	-- Of course, be sure that there IS a "below the target."
	if tr.Hit and util.IsInWorld(tr.HitPos) then
		targetPos = tr.HitPos
	end

	local rTime = SysTime()
	self.MovePath:Compute(self, targetPos)

	-- If path computation takes longer than 5ms (A LONG TIME),
	-- disable computation for a little while for this bot.
	if SysTime() - rTime > 0.005 then
		self.LastPathingInfraction = CurTime()
	end
end

function ENT:BehaveStart()
	self.MovePath = Path("Follow")
	self.MovePath:SetMinLookAheadDistance(500)
	self.MovePath:SetGoalTolerance(10)
end

local ai_disabled = GetConVar("ai_disabled")
function ENT:BehaveUpdate()
	-- trunga can fall out of the map when warping. Oops.
	local myPos = self:GetPos()
	if myPos.z < -40000 then
		-- Yeah, we're below the map. Warp back up to it.
		local nearestArea = navmesh.GetNearestNavArea(myPos, true, 1e8, false,
			false)
		self:SetPos(nearestArea:GetRandomPoint())
	end

	if ai_disabled:GetBool() then
		-- We may be a bot, but we're still an NPC at heart.
		return
	end

	local currentTime = CurTime()

	local scanInterval = npc_trunga_expensive_scan_interval:GetFloat()
	if currentTime - self.LastTargetSearch > scanInterval then
		local target = self:GetNearestTarget()

		if target ~= self.CurrentTarget then
			-- We have a new target! Figure out a new path immediately.
			self.LastPathRecompute = 0
		end

		self.CurrentTarget = target
		self.LastTargetSearch = currentTime
	end

	-- Do we have a target?
	if IsValid(self.CurrentTarget) then
		self:ChaseUpdate()
	else
		self:HideUpdate()
	end

	if currentTime - self.LastStuckCheck >= scanInterval then
		-- Don't even wait until the STUCK flag is set for this.
		-- It's much more fluid this way.
		self:UnstickFromCeiling()

		-- Make sure we haven't fallen off of the navmesh.
		self:GetBackToNavmesh()

		self.LastStuckCheck = currentTime
	end

	if currentTime - self.LastStuck >= 5 then
		self.StuckTries = 0
	end
end

function ENT:ChaseUpdate()
	local currentTime = CurTime()

	-- Be ready to repath to a hiding place as soon as we lose target.
	self.LastHidingPlaceScan = 0

	-- Attack anyone nearby while we're rampaging.
	local attackInterval = npc_trunga_attack_interval:GetFloat()
	if currentTime - self.LastAttack > attackInterval then
		local attackDistance = npc_trunga_attack_distance:GetInt()
		if self:AttackNearbyTargets(attackDistance) then
			if currentTime - self.LastTaunt > TAUNT_INTERVAL then
				self.LastTaunt = currentTime
				self:EmitSound(table.Random(self.TauntSounds), 350, 100)
			end

			-- Immediately look for another target.
			self.LastTargetSearch = 0
		end

		self.LastAttack = currentTime
	end

	-- Recompute the path to the target every so often.
	local repathInterval = npc_trunga_chase_repath_interval:GetFloat()
	if currentTime - self.LastPathRecompute > repathInterval then
		self.LastPathRecompute = currentTime
		self:RecomputeTargetPath()
	end

	-- Move!
	self.MovePath:Update(self)

	-- Try to jump at a target in the air.
	local scanInterval = npc_trunga_expensive_scan_interval:GetFloat()
	if self:IsOnGround() and npc_trunga_allow_jump:GetBool()
		and currentTime - self.LastJumpScan >= scanInterval
	then
		self:AttemptJumpAtTarget()
		self.LastJumpScan = currentTime
	end
end

function ENT:HideUpdate()
	local currentTime = CurTime()

	local hidingScanInterval = npc_trunga_hiding_scan_interval:GetFloat()
	if currentTime - self.LastHidingPlaceScan >= hidingScanInterval then
		self.LastHidingPlaceScan = currentTime

		-- Grab a new hiding spot.
		local hidingSpot = self:GetNearestUsableHidingSpot()
		self:ClaimHidingSpot(hidingSpot)
	end

	if self.HidingSpot ~= nil then
		local hidingInterval = npc_trunga_hiding_repath_interval:GetFloat()
		if currentTime - self.LastPathRecompute >= hidingInterval then
			self.LastPathRecompute = currentTime
			self.MovePath:Compute(self, self.HidingSpot.pos)
		end
		self.MovePath:Update(self)
	else
		--TODO: Wander if we didn't find a place to hide.
		--      Preferably AWAY from spawn points.
	end
end

ENT.LastStuck = 0
ENT.StuckTries = 0
function ENT:OnStuck()
	self.LastStuck = CurTime()

	-- Don't warp across the whole map.
	-- Besides, if we try to warp onto a player, it doesn't work.
	-- Not sure why, but it might have something to do with the hook we're in.
	if self.StuckTries > 10 then
		self.StuckTries = 0
	end

	-- Jump forward a bit on the path.
	local newCursor = self.MovePath:GetCursorPosition()
		+ 40 * math.pow(2, self.StuckTries)
	local newPos = self.MovePath:GetPositionOnPath(newCursor)
	self.StuckTries = self.StuckTries + 1

	-- Some malformed navmeshes have climb junctions that pass through the
	-- void. We'll check for those and try not to fall out of the map.
	if not util.IsInWorld(newPos) then
		-- The next stuck check will retry this.
		return
	end

	self:SetPos(newPos)

	-- Hope that we're not stuck anymore.
	self.loco:ClearStuck()
end

function ENT:UnstickFromCeiling()
	if self:IsOnGround() then return end

	-- NextBots LOVE to get stuck. Stuck in the morning. Stuck in the evening.
	-- Stuck in the ceiling. Stuck on each other. The stuck never ends.
	local myPos = self:GetPos()
	local myHullMin, myHullMax = self:GetCollisionBounds()
	local myHull = myHullMax - myHullMin
	local myHullTop = myPos + vector_up * myHull.z
	trace.start = myPos
	trace.endpos = myHullTop
	trace.filter = self
	local upTrace = util.TraceLine(trace)

	if upTrace.Hit and upTrace.HitNormal ~= vector_origin
		and upTrace.Fraction > 0.5
	then
		local unstuckPos = myPos
			+ upTrace.HitNormal * (myHull.z * (1 - upTrace.Fraction))
		self:SetPos(unstuckPos)
	end
end

-- How many units of movement between stuck checks constitutes movement.
local MOTION_THRESHOLD_SQR = math.pow(10, 2)

ENT.LastMotion = 0
ENT.LastPos = vector_origin

function ENT:GetBackToNavmesh()
	-- We have no bindings for OnMoveToFailure, so we need to determine if our
	-- pathing failed heuristically.
	local myPos = self:GetPos()

	-- If we've moved, we're not stuck.
	if myPos:DistToSqr(self.LastPos) >= MOTION_THRESHOLD_SQR then
		self.LastMotion = CurTime()
	end

	if CurTime() - self.LastMotion > 5 then
		-- We haven't moved for a while. Are we on a navarea?
		local areaBeneath = navmesh.GetNavArea(myPos, 10)
		if !IsValid(areaBeneath) then
			-- We're off the navmesh, and we haven't moved for a while.
			-- Sounds like we're stuck. Warp to safety!
			local nearArea = navmesh.GetNearestNavArea(myPos, true, 1e8,
				false, false)
			local warpPos = nearArea:GetClosestPointOnArea(myPos)

			-- Golly I sure hope nobody sees me do this.
			self:SetPos(warpPos)
			myPos = warpPos
		end
	end

	self.LastPos = myPos
end

else -- CLIENT --

local MAT_TRUNGA = Material("npc_trunga/trunga")
killicon.Add("npc_trunga", "npc_trunga/killicon", color_white)
language.Add("npc_trunga", "DONALD TRUNGA")

local BASE = ENT
ENT.RenderGroup = npc_trunga_use_3d:GetBool() and RENDERGROUP_OPAQUE or RENDERGROUP_TRANSLUCENT

local developer = GetConVar("developer")
local function DevPrint(devLevel, msg)
	if developer:GetInt() >= devLevel then
		print("npc_trunga: " .. msg)
	end
end

local panicMusic = nil
local lastPanic = 0 -- The last time we were in music range of a trunga.

local npc_trunga_music_volume =
	CreateConVar("npc_trunga_music_volume", 1,
	bit.bor(FCVAR_DEMO, FCVAR_ARCHIVE),
	"Maximum music volume when being chased by trunga. (0-1, where 0 is muted)")

-- If another trunga comes in range before this delay is up,
-- the music will continue where it left off.
local MUSIC_RESTART_DELAY = 2

-- Beyond this distance, trungas do not count to music volume.
local MUSIC_CUTOFF_DISTANCE = 1000

-- Max volume is achieved when MUSIC_trunga_PANIC_COUNT trungas are this close,
-- or an equivalent score.
local MUSIC_PANIC_DISTANCE = 200

 -- That's a lot of NUT.
local MUSIC_TRUNGA_PANIC_COUNT = 8

local MUSIC_TRUNGA_MAX_DISTANCE_SCORE =
	(MUSIC_CUTOFF_DISTANCE - MUSIC_PANIC_DISTANCE) * MUSIC_TRUNGA_PANIC_COUNT

local function updatePanicMusic()
	if #ents.FindByClass("npc_trunga") == 0 then
		-- Whoops. No need to run for now.
		DevPrint(4, "Halting music timer.")
		timer.Remove("TrungaPanicMusicUpdate")

		if panicMusic ~= nil then
			panicMusic:Stop()
		end

		return
	end

	if panicMusic == nil then
		if IsValid(LocalPlayer()) then
			panicMusic = CreateSound(LocalPlayer(), chaseMusic)
			panicMusic:Stop()
		else
			return -- No LocalPlayer yet!
		end
	end

	local userVolume = math.Clamp(npc_trunga_music_volume:GetFloat(), 0, 1)
	if userVolume == 0 or not IsValid(LocalPlayer()) then
		panicMusic:Stop()
		return
	end

	local totalDistanceScore = 0
	local nearEntities = ents.FindInSphere(LocalPlayer():GetPos(), 1000)
	for _, ent in pairs(nearEntities) do
		if IsValid(ent) and ent:GetClass() == "npc_trunga" then
			local distanceScore = math.max(0, MUSIC_CUTOFF_DISTANCE
				- LocalPlayer():GetPos():Distance(ent:GetPos()))
			totalDistanceScore = totalDistanceScore + distanceScore
		end
	end

	local musicVolume = math.min(1,
		totalDistanceScore / MUSIC_TRUNGA_MAX_DISTANCE_SCORE)

	local shouldRestartMusic = (CurTime() - lastPanic >= MUSIC_RESTART_DELAY)
	if musicVolume > 0 then
		if shouldRestartMusic then
			panicMusic:Play()
		end

		if not LocalPlayer():Alive() then
			-- Quiet down so we can hear TRUNGA taunt us.
			musicVolume = musicVolume / 4
		end

		lastPanic = CurTime()
	elseif shouldRestartMusic then
		panicMusic:Stop()
		return
	else
		musicVolume = 0
	end

	musicVolume = math.max(0.01, musicVolume * userVolume)

	panicMusic:Play()

	-- Just for kicks.
	panicMusic:ChangePitch(math.Clamp(game.GetTimeScale() * 100, 50, 255), 0)
	panicMusic:ChangeVolume(musicVolume, 0)
end

local REPEAT_FOREVER = 0
local function startTimer()
	if not timer.Exists("TrungaPanicMusicUpdate") then
		timer.Create("TrungaPanicMusicUpdate", 0.05, REPEAT_FOREVER,
			updatePanicMusic)
		DevPrint(4, "Beginning music timer.")
	end
end

local SPRITE_SIZE = 128
function ENT:Initialize()
	self:SetRenderBounds(
		Vector(-SPRITE_SIZE / 2, -SPRITE_SIZE / 2, 0),
		Vector(SPRITE_SIZE / 2, SPRITE_SIZE / 2, SPRITE_SIZE),
		Vector(5, 5, 5)
	)

	startTimer()
end

--HACK: Apparently no change callback on replicated cvars.
local oldHD = true
hook.Add("Think", "npc_trunga_use_3d_switch", function()
	local newHD = npc_trunga_use_3d:GetBool()
	if newHD == oldHD then return end
	oldHD = newHD

	BASE.RenderGroup = newHD and RENDERGROUP_OPAQUE or RENDERGROUP_TRANSLUCENT
	for _, trunga in pairs(ents.FindByClass("npc_trunga")) do
		trunga.RenderGroup = newHD and RENDERGROUP_OPAQUE or RENDERGROUP_TRANSLUCENT
	end
end)

--HACK: Okay listen I tried cam.PushModelMatrix and it does nothing.
--      I've been out of this game too long.
local TRUNGA_3D_INSTANCE = ClientsideModel(TRUNGA_3D_MODEL, RENDERGROUP_OPAQUE)
TRUNGA_3D_INSTANCE:SetNoDraw(true)

TRUNGA_3D_INSTANCE:SetModelScale(1.8)
local OOPS_OFFSET_ANGLE = Angle(0, 180, 0)
local OOPS_OFFSET_POS = Vector(0, 0, -10)

function ENT:Draw()
	TRUNGA_3D_INSTANCE:SetRenderOrigin(self:GetPos() + OOPS_OFFSET_POS)
	TRUNGA_3D_INSTANCE:SetRenderAngles(self:GetAngles() + OOPS_OFFSET_ANGLE)
	TRUNGA_3D_INSTANCE:SetupBones()
	TRUNGA_3D_INSTANCE:DrawModel()
end

local DRAW_OFFSET = SPRITE_SIZE / 2 * vector_up
function ENT:DrawTranslucent()
	render.SetMaterial(MAT_TRUNGA)

	-- Get the normal vector from TRUNGA to the player's eyes, and then compute
	-- a corresponding projection onto the xy-plane.
	local pos = self:GetPos() + DRAW_OFFSET
	local normal = EyePos() - pos
	normal:Normalize()
	local xyNormal = Vector(normal.x, normal.y, 0)
	xyNormal:Normalize()

	-- TRUNGA should only look 1/3 of the way up to the player so that they
	-- don't appear to lay flat from above.
	local pitch = math.acos(math.Clamp(normal:Dot(xyNormal), -1, 1)) / 3
	local cos = math.cos(pitch)
	normal = Vector(
		xyNormal.x * cos,
		xyNormal.y * cos,
		math.sin(pitch)
	)

	render.DrawQuadEasy(pos, normal, SPRITE_SIZE, SPRITE_SIZE,
		color_white, 180)
end

surface.CreateFont("TrungaHUD", {
	font = "Arial",
	size = 56
})

surface.CreateFont("TrungaHUDSmall", {
	font = "Arial",
	size = 24
})

local function string_ToHMS(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds / 60) % 60)
	local seconds = math.floor(seconds % 60)

	if hours > 0 then
		return string.format("%02d:%02d:%02d", hours, minutes, seconds)
	else
		return string.format("%02d:%02d", minutes, seconds)
	end
end

local flavourTexts = {
	{
		"Learning map.",
		"Learning this should be easy.",
		"This is too easy."
	}, {
		"This must be a big map.",
		"This map is a bit bigger than I thought.",
	}, {
		"Just how big is this place?",
		"This place is pretty big."
	}, {
		"This place is enormous!",
		"A guy could get lost around here."
	}, {
		"Surely I'm almost done...",
		"There can't be too much more...",
		"This isn't gm_bigcity, is it?",
		"Is it over yet?",
		"You never told me the map was this big!"
	}
}
local SECONDS_PER_BRACKET = 5 * 60
local color_yellow = Color(255, 255, 80)
local flavourText = ""
local lastBracket = 0
local generateStart = 0
local function navGenerateHUDOverlay()
	draw.SimpleTextOutlined("Trunga is studying this map.", "TrungaHUD",
		ScrW() / 2, ScrH() / 2, color_white,
		TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, color_black)
	draw.SimpleTextOutlined("Please wait...", "TrungaHUD",
		ScrW() / 2, ScrH() / 2, color_white,
		TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, color_black)

	local elapsed = SysTime() - generateStart
	local elapsedStr = string_ToHMS(elapsed)
	draw.SimpleTextOutlined("Time Elapsed:", "TrungaHUDSmall",
		ScrW() / 2, ScrH() * 3/4, color_white,
		TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, color_black)
	draw.SimpleTextOutlined(elapsedStr, "TrungaHUDSmall",
		ScrW() / 2, ScrH() * 3/4, color_white,
		TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)

	-- It's taking a while.
	local textBracket = math.floor(elapsed / SECONDS_PER_BRACKET) + 1
	if textBracket ~= lastBracket then
		flavourText = table.Random(flavourTexts[math.min(5, textBracket)])
		lastBracket = textBracket
	end
	draw.SimpleTextOutlined(flavourText, "TrungaHUDSmall",
		ScrW() / 2, ScrH() * 4/5, color_yellow,
		TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
end

net.Receive("trunga_navgen", function()
	local startSuccess = net.ReadBool()
	if startSuccess then
		generateStart = SysTime()
		lastBracket = 0
		hook.Add("HUDPaint", "TrungaNavGenOverlay", navGenerateHUDOverlay)
	else
		Derma_Message("Oh no. Donald Trunga doesn't even know where to start with \z
		this map.\n\z
		If you're not running the Sandbox gamemode, switch to that and try \z
		again.", "Error!")
	end
end)

local nagMe = true

local function requestNavGenerate()
	RunConsoleCommand("npc_trunga_learn")
end

local function stopNagging()
	nagMe = false
end

local function navWarning()
	Derma_Query("It will take a while (possibly hours) for Donald Trunga to figure \z
		this map out.\n\z
		While he's studying it, you won't be able to play,\n\z
		and the game will appear to have frozen/crashed.\n\z
		\n\z
		Also note that THE MAP WILL BE RESTARTED.\n\z
		Anything that has been built will be deleted.", "Warning!",
		"Go ahead!", requestNavGenerate,
		"Not right now.", nil)
end

net.Receive("trunga_nag", function()
	if not nagMe then return end

	if game.SinglePlayer() then
		Derma_Query("Uh oh! Donald Trunga doesn't know this map.\n\z
			Would you like him to learn it?",
			"This map is not yet Trunga-compatible!",
			"Yes", navWarning,
			"No", nil,
			"No. Don't ask again.", stopNagging)
	else
		Derma_Query("Uh oh! Donald Trunga doesn't know this map. \z
			He won't be able to move!\n\z
			Because you're not in a single-player game, he isn't able to \z
			learn it.\n\z
			\n\z
			Ask the server host about teaching this map to Donald Trunga.\n\z
			\n\z
			If you ARE the server host, you can run npc_trunga_learn over \z
			rcon.\n\z
			Keep in mind that it may take hours during which you will be \z
			unable\n\z
			to play, and THE MAP WILL BE RESTARTED.",
			"This map is currently not Trunga-compatible!",
			"Ok", nil,
			"Ok. Don't say this again.", stopNagging)
	end
end)

end

--
-- List the NPC as spawnable.
--
list.Set("NPC", "npc_trunga", {
	Name = "DONALD TRUNGA",
	Class = "npc_trunga",
	Category = "Nextbot",
	AdminOnly = true
})
