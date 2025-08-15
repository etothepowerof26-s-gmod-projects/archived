GM.Name = "RUN"
GM.Author = "twentysix"
GM.Email = ""
GM.Website = ""

function GM:Initialize()
	self.BaseClass.Initialize( self )

	if ( SERVER ) then
		self:HookOurNPCs( )
	end
end

function GM:HookOurNPCs( )
	local function hookInto( npcClass, npcTable )
		local ENT = npcTable

		if ( ENT.GamemodeHooked ) then
			print( npcClass .. ": Skipping" )
			return
		end

		local oldNearestTarget = ENT.GetNearestTarget
		function ENT.GetNearestTarget( entSelf )
			if ( entSelf.RUNForceTarget ) then
				return entSelf.RUNForceTarget
			end
			return oldNearestTarget( entSelf )
		end

		local oldBehaveUpdate = ENT.BehaveUpdate
		function ENT.BehaveUpdate( entSelf )
			if GAMEMODE:PlasmaNetThink2( entSelf ) then
				return
			end
			return oldBehaveUpdate( entSelf )
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

			-- Ignore dead NPCs, other obamids, and dummy NPCs.
			local class = ent:GetClass()
			return (ent:IsNPC()
				and ent:Health() > 0
				and class ~= k
				and not class:find("bullseye"))
		end

		function ENT.AttackNearbyTargets( entSelf, radius )
			local attackForce = 8500
			local hitSource = entSelf:LocalToWorld(entSelf:OBBCenter())
			local nearEntities = ents.FindInSphere(hitSource, radius)
			local hit = false
			for _, ent in pairs(nearEntities) do
				if isValidTarget(ent) then
					local health = ent:Health()

					if ent:IsPlayer() and IsValid(ent:GetVehicle()) then
						-- Hiding in a vehicle, eh?
						local vehicle = ent:GetVehicle()

						local vehiclePos = vehicle:LocalToWorld(vehicle:OBBCenter())
						local hitDirection = (vehiclePos - hitSource):GetNormal()

						-- Give it a good whack.
						local phys = vehicle:GetPhysicsObject()
						if IsValid(phys) then
							phys:Wake()
							local hitOffset = vehicle:NearestPoint(hitSource)
							phys:ApplyForceOffset(hitDirection
								* (attackForce * phys:GetMass()),
								hitOffset)
						end
						vehicle:TakeDamage(math.max(1e8, ent:Health()), entSelf, entSelf)

						-- Oh, and make a nice SMASH noise.
						vehicle:EmitSound(string.format(
							"physics/metal/metal_sheet_impact_hard%d.wav",
							math.random(6, 8)), 350, 120)
					else
						ent:EmitSound(string.format(
							"physics/body/body_medium_impact_hard%d.wav",
							math.random(1, 6)), 350, 120)
					end

					local hitDirection = (ent:GetPos() - hitSource):GetNormal()
					-- Give the player a good whack. obamid means business.
					-- This is for those with god mode enabled.
					ent:SetVelocity(hitDirection * attackForce + vector_up * 500)

					local dmgInfo = DamageInfo()
					dmgInfo:SetAttacker(entSelf)
					dmgInfo:SetInflictor(entSelf)
					dmgInfo:SetDamage(1e8)
					dmgInfo:SetDamagePosition(entSelf:GetPos())
					dmgInfo:SetDamageForce((hitDirection * attackForce
						+ vector_up * 500) * 100)
					ent:TakeDamageInfo(dmgInfo)

					local newHealth = ent:Health()

					-- Hits only count if we dealt some damage.
					hit = (hit or (newHealth < health))
				elseif ent:GetMoveType() == MOVETYPE_VPHYSICS then
					if ent:IsVehicle() and IsValid(ent:GetDriver()) then continue end

					if GAMEMODE:PlasmaNetThink(entSelf, ent) then continue end 

					-- Knock away any props put in our path.
					local entPos = ent:LocalToWorld(ent:OBBCenter())
					local hitDirection = (entPos - hitSource):GetNormal()
					local hitOffset = ent:NearestPoint(hitSource)

					-- Remove anything tying the entity down.
					-- We're crashing through here!
					constraint.RemoveAll(ent)

					-- Get the object's mass.
					local phys = ent:GetPhysicsObject()
					local mass = 0
					local material = "Default"
					if IsValid(phys) then
						mass = phys:GetMass()
						material = phys:GetMaterial()
					end

					-- Don't make a noise if the object is too light.
					-- It's probably a gib.
					if mass >= 5 then
						ent:EmitSound(material .. ".ImpactHard", 350, 120)
					end

					-- Unfreeze all bones, and give the object a good whack.
					for id = 0, ent:GetPhysicsObjectCount() - 1 do
						local phys = ent:GetPhysicsObjectNum(id)
						if IsValid(phys) then
							phys:EnableMotion(true)
							phys:ApplyForceOffset(hitDirection * (attackForce * mass),
								hitOffset)
						end
					end

					-- Deal some solid damage, too.
					ent:TakeDamage(25, entSelf, entSelf)
				end
			end

			return hit
		end

		ENT.GamemodeHooked = true

		scripted_ents.Register( ENT, npcClass )
		print( npcClass .. ": Done" )
	end
	for k,v in pairs( scripted_ents.GetList() ) do
		if ( k:find("^npc_") && v.Base == "base_nextbot" && ( v.t.LastHidingPlaceScan != nil ) ) then
			-- this is a nextbot NPC, hook into it's table
			print( "GM: Hooking Into " .. k .. "'s Functions" )
			hookInto( k, v.t )
		end
	end
end

concommand.Add( "run_gm_hook_npcs", function( ply )
	if ( !IsValid(ply) || ply:IsSuperAdmin() ) then
		GAMEMODE:HookOurNPCs( )
	end
end )

if SERVER then
	local PLAYER = FindMetaTable "Player"
	util.AddNetworkString( 'ChatPrintColor' )
	function GM:ChatPrintColor( ... )
		local tab = {...}
		
		net.Start("ChatPrintColor")
		net.WriteTable(tab)
		net.Send( player.GetHumans() )
	end
	function PLAYER:ChatPrintColor(...)
		local tab = {...}
		
		net.Start("ChatPrintColor")
		net.WriteTable(tab)
		net.Send(self)
	end
else
	net.Receive("ChatPrintColor", function(len)
		local tab = net.ReadTable()
		
		chat.AddText(unpack(tab))
	end)
end