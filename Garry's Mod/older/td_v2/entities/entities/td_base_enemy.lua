AddCSLuaFile()

ENT.PrintName = "Tower Defense Enemy"
ENT.Author    = "26"
ENT.Base      = "base_nextbot"
ENT.Type      = "nextbot"

local GM = GAMEMODE

if SERVER then
	local R = 20^2
	function ENT:SetupDataTables()
		self:NetworkVar("Int", 0, "CurrentWaypointID")
	end
	
	function ENT:Initialize()
		self:SetModel("models/headcrabclassic.mdl")
		self:SetModelScale(1)
		self:SetMaxHealth(10)
		self:SetHealth(10)
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		self:SetCurrentWaypointID(1)
	end

	function ENT:UpdateCurrentWaypointInformation()
		if not GM.Waypoints or next(GM.Waypoints) == nil then
			error("rip, how did I Get here?")
		end
		self.CurrentWaypoint = GM.Waypoints["_" .. self:GetCurrentWaypointID()]
	end
	
	function ENT:Think()
		if self.CurrentWaypoint then
			self.CanGo = true
		end
		return
	end
	
	function ENT:CoroutineFigureOutMyPath()
			if self.CanGo and self.CurrentWaypoint then
				if not self.Path then
					self.Path = Path( "Follow" )
					self.Path:SetMinLookAheadDistance( 300 )
					self.Path:SetGoalTolerance( 20 )
				end

				self.Path:Compute(self, self.CurrentWaypoint.pos)
				self.Path:Update(self)

				if self:GetPos():DistToSqr(self.CurrentWaypoint.pos) <= R then
					local next_wp = self.CurrentWaypoint.nextWaypoint
					if istable(next_wp) then
						next_wp = next_wp[math.random(1, #next_wp)]
					end
					if not next_wp then
						PrintMessage(3, "we ded")
						self:Remove()
						return
					end
					self:SetCurrentWaypointID(next_wp)
					self:UpdateCurrentWaypointInformation()

					--self:TakeDamage(5, self, self)
				end
			end
	end

	function ENT:RunBehaviour()
		while true do
			self:StartActivity(ACT_RUN)
			self.loco:SetDesiredSpeed(75)
			self:CoroutineFigureOutMyPath()
			if (self.loco:IsStuck()) then
				PrintMessage(3, 'sadge')
				self.loco:ClearStuck()
				self:SetPos(GAMEMODE.Waypoints["_1"].pos)
			end
			coroutine.wait(.1)
			coroutine.yield()
		end
	end

	function ENT:OnInjured(dmginfo) -- TODO
	end
	
	function ENT:OnKilled(dmginfo)
		local atk = dmginfo:GetAttacker()
		local inf = dmginfo:GetInflictor()

		dmginfo:SetDamageForce(Vector(0, 0, 0))

		self:BecomeRagdoll(dmginfo)
	end
else
	function ENT:Draw()
		self:DrawModel()
	end
end

concommand.Add("thecrab",function()
	if CLIENT then return end
	
	timer.Create("balls", 1, 0, function()
	local e = ents.Create"td_base_enemy"
	e:Spawn()
	e:SetPos(GM.Waypoints["_1"].pos)
	e:UpdateCurrentWaypointInformation()
	end)
	local e =ents.Create'td_tower'
	e:SetPos(player.GetAll()[1]:GetPos())
	e:Spawn()
end)

for k,v in pairs(ents.FindByClass"td_base_enemy") do v:Remove() end 