--[[-------------------------------------------------------------------------
 - We enable prop walking by having the player walk on a prop walker (called pw) entity instead of actual props.

 - Each prop (called ground) has its own prop walker. It's created whenever a player makes contact with a new ground,
and is removed after 10 minutes of being inactive (unstepped on by players) for optimization purposes.

 - The per ground approach is preferred (rather than a per-player approach) to allow smooth transitions between grounds.

 - A prop walker is parented to its ground, and always shares its ground's physcollides, position and angles client and server side.

TODO:
	Crucial:
		For prop walker: Disable shoot traces, enable movement traces
		For ground: Enable shoot traces, disable movement traces

		Improve player-on-ground illusion on calcview, player draws, etc.
		Prevent physics damage with objects travelling the same velocity
	
	Optimization:
		Check if we really need to network prop walker position as well (for proper predictions) on pw:NetworkAbsPosition()

	Optional:
		Simulate player weight on original ground
		Tweak player velocity to match ground's during dismounts
		Resolve more player stuck cases
---------------------------------------------------------------------------]]

--[[-------------------------------------------------------------------------
MACRO/MICRO OPS (if you're doing this at least use a module)
---------------------------------------------------------------------------]]
local util, table, ents = util, table, ents
local Vector, IsValid = Vector, IsValid

CreateConVar("propwalker_remove_delay", "2", FCVAR_ARCHIVE, "(in minutes)")

--[[-------------------------------------------------------------------------
Only cover certain grounds (currently valid physics props)
---------------------------------------------------------------------------]]
local function ShouldCoverGround(ground)
	-- Check the ground
	if !IsValid(ground) then return false end

	if ground:GetClass() != "prop_physics" then return false end
	return true
end

--[[-------------------------------------------------------------------------
Only serve players that are actually on a ground
---------------------------------------------------------------------------]]
local function ShouldServePlayer(ply)
	-- Check the player
	if ply.m_bWasNoclipping then return false end
	if ply:InVehicle() or !ply:Alive() then return false end

	return true
end

--[[-------------------------------------------------------------------------
Create & handle prop walkers, tweak player positions
---------------------------------------------------------------------------]]
local maxSlope = 0.707107 -- We can't walk on slopes bigger than this (excluding 1)
local turnOnDist = Vector(0, 0, 50) -- Ground coverage turns on when this many units above the ground
local plyHeight = Vector()
hook.Add("Move", "PropWalk", function(ply, mv)
	-- Check if we have a ground we should cover
	local mins, maxs = ply:GetCollisionBounds()
	local origin = mv:GetOrigin()
	local filter = table.Copy(propWalkers)
	table.insert(filter, 1, ply) --Insert the player into the first slot of our trace filter
	plyHeight.z = (maxs.z - mins.z)

	local tr0 = util.TraceHull{
		start = origin + plyHeight, -- Trace from up to down
		endpos = origin - turnOnDist,
		filter = filter,
		mins = mins,
		maxs = maxs,
		mask = MASK_PLAYERSOLID
	}

	local ground = tr0.Entity
	local goodSlope = tr0.HitNormal.z >= maxSlope or tr0.HitNormal.z == 0
	if tr0.Hit and ShouldCoverGround(ground) and ShouldServePlayer(ply) and goodSlope then -- We're above a workable ground
		local pw = ground:GetNW2Entity("PropWalker")
		if !IsValid(pw) then
			-- The ground is uncovered, create a new prop walker
			if SERVER then
				pw = ents.Create("prop_walker")
				-- Network the ground as soon as possible for correct initialization on client
				pw:SetNW2Entity("Ground", ground)
				ground:SetNW2Entity("PropWalker", pw)
				pw:Spawn()
			end
			return -- Wait for the next iteration
		end
		-- We have a valid prop walker, continue

		if SERVER then
			-- Reset the removal timer
			pw:RestartRemovalTimer()
			-- Update the absolute position on the client
			pw:NetworkAbsPosition()

			-- Set our local prop walker position
			local lastPW = ply.lastPW
			local lastPWPos = ply.lastPWPos
			if lastPWPos and pw == lastPW then
				mv:SetOrigin(pw:LocalToWorld(lastPWPos))
			end
		end

		-- Fix prop walker position & angle networking
		if CLIENT then
			local netAng = pw:GetNW2Angle("GroundAng")
			local netPos = pw:GetNW2Vector("GroundPos")
			if netAng then pw:SetAngles(netAng) end
			if netPos then pw:SetPos(netPos) end
		end
		
		-- Find out if we're stuck & resolve if needed (currently only does vertical unstuck)
		-- Do this on the client as well to minimize prediction errors
		local tr1 = util.TraceHull{
			start = mv:GetOrigin() + plyHeight, -- Trace from up to down
			endpos = mv:GetOrigin(),
			filter = { ply, ground },
			mins = mins,
			maxs = maxs,
			mask = MASK_PLAYERSOLID
		}

		if tr1.Hit then -- We're stuck, resolve
			if tr1.Entity == pw or tr1.Entity == ground then
				if tr1.HitPos.z - mv:GetOrigin().z < 25 then
					mv:SetOrigin(tr1.HitPos)
				end
			end
		end
		ply.lastPW = pw
	else
		if IsValid(ply.lastPW) then
			-- We've left our ground for good, match the player's velocity to the ground's velocity
			local lastPW = ply.lastPW
			local ground = lastPW:GetNW2Entity("Ground")
			if IsValid(ground) then
				ply:SetVelocity(ground:GetVelocity())
			end
		end
		ply.lastPW = nil
	end
end)


--[[-------------------------------------------------------------------------
Obtain relative ground position to be used later
---------------------------------------------------------------------------]]
hook.Add("FinishMove", "GetRelativeGroundPosition", function(ply, mv)
	local pw = ply.lastPW
	
	-- Store post-move origin, used to localize player movement in respect to their moving grounds
	if IsValid(pw) then
		ply.lastPWPos = pw:WorldToLocal(mv:GetOrigin())
	else
		ply.lastPWPos = nil
	end
	
	-- Sync again on the client
	if CLIENT then
		local ground = nil
		if IsValid(pw) then ground = pw:GetNW2Entity("Ground") end

		if IsValid(pw) and IsValid(ground) then
			local netAng = pw:GetNW2Angle("GroundAng")
			local netPos = pw:GetNW2Vector("GroundPos")

			if netAng then
				pw:SetAngles(netAng)
				ground:SetAngles(netAng)
			end

			if netPos then
				pw:SetPos(netPos)
				ground:SetPos(netPos)
			end
		else
			ply.lastPWPos = nil
		end
	end
end)


--[[-------------------------------------------------------------------------
Prevent nearby physics damage to the player when on moving grounds
---------------------------------------------------------------------------]]
hook.Add("PlayerShouldTakeDamage", "PreventDamage", function(ply, attacker)
	-- If the attacker doesn't have a physics movetype, bail
	if attacker:GetMoveType() != MOVETYPE_VPHYSICS then return end

	local pw = ply.lastPW
	if !IsValid(pw) then return end

	local ground = pw:GetNW2Entity("Ground")
	if !IsValid(ground) then return end

	local diffVel = attacker:GetVelocity():DistToSqr(ground:GetVelocity())

	if diffVel < 9000000 then return false end

end)


--[[-------------------------------------------------------------------------
Prevent Physgun pickups
---------------------------------------------------------------------------]]
hook.Add("PhysgunPickup", "PreventPickups", function(ply, ent)
	if ent:GetClass() == "prop_walker" then return false end
end)
