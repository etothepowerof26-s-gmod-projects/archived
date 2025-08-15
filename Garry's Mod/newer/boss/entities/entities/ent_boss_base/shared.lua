AddCSLuaFile()

-- This is the default boss that will spawn if your boss is not defined.
ENT.PrintName = "Default Boss"
ENT.Author = "26"
ENT.Spawnable = false
ENT.Type = "nextbot"
ENT.Base = "base_nextbot"

-- Network variables for the boss.
function ENT:Data()
	-- Default stats for the boss. You will overwrite these.
	self:SetBLevel(math.random(25, 50))
	self:SetBHealthPLevel(500)
	self:SetBLastAttack(SysTime())
	self:SetBName("Based Boss")
	self:SetBModel("models/monk.mdl")
	self:SetBAttackDamage(50)
	self:SetBAttackSpeed(1)
	self:SetBIncomingDamageModifier(1)
	self:SetBModelScale(5)
	
	self:SetBIsRunic(math.random(1,2) == 1)
	self:SetBHasWeapon(true)
	self:SetBWeaponClass("weapon_annabelle")
	
	self:SetBossStage(0)
	
	-- Vanilla variables
	self:SetAmmoType("Buckshot")
	
	return
end

function ENT:SetupDataTables()
	-- Boss related variables
	self:NetworkVar("Int", 0, "BLevel")
	self:NetworkVar("Int", 1, "BHealthPLevel")
	self:NetworkVar("Int", 2, "BossStage")
	self:NetworkVar("Int", 3, "BAttackDamage")
	self:NetworkVar("Int", 5, "BModelScale")
	
	self:NetworkVar("Float", 0, "BLastAttack")
	self:NetworkVar("Float", 1, "BIncomingDamageModifier")
	self:NetworkVar("Float", 2, "BAttackSpeed")
	
	self:NetworkVar("String", 0, "BName")
	self:NetworkVar("String", 1, "BModel")
	self:NetworkVar("String", 2, "AmmoType")
	
	-- Is the boss runic?
	self:NetworkVar("Bool", 0, "BIsRunic")
	
	-- Does the boss have a weapon, if so what is it's class?
	self:NetworkVar("Bool", 1, "BHasWeapon")
	self:NetworkVar("String", 2, "BWeaponClass")
	
	-- Move this to self:Initialize
	-- self:Data()
end

function ENT:PlaySequenceNoWait( name, speed )
	local len = self:SetSequence( name )
	speed = speed or 1

	self:ResetSequenceInfo()
	self:SetCycle( 0 )
	self:SetPlaybackRate( speed )
end

-- This will help with default behavior of the boss.
ENT.Stages = {
	[1] = {
		IsActive = false,
		DoActivate = function(ent)
			return ent:Health() < math.ceil(ent:GetMaxHealth() / 2)
		end,
		OnActivate = function(ent)
			ent:SetBAttackDamage(ent:GetBAttackDamage() * 2)
			print(ent:GetBAttackSpeed())
			ent:SetBAttackSpeed(ent:GetBAttackSpeed()/2)
			print(ent:GetBAttackSpeed())
			local snds = {
				{
					"vo/ravenholm/monk_mourn01.wav",
					"vo/ravenholm/monk_mourn02.wav",
					"vo/ravenholm/monk_mourn03.wav",
					"vo/ravenholm/monk_mourn04.wav",
					"vo/ravenholm/monk_mourn05.wav",
					"vo/ravenholm/monk_mourn06.wav",
					"vo/ravenholm/monk_mourn07.wav"
				},
				{
					"vo/ravenholm/monk_kill01.wav",
					"vo/ravenholm/monk_kill02.wav",
					"vo/ravenholm/monk_kill03.wav",
					"vo/ravenholm/monk_kill04.wav",
					"vo/ravenholm/monk_kill05.wav",
					"vo/ravenholm/monk_kill06.wav",
					"vo/ravenholm/monk_kill07.wav",
					"vo/ravenholm/monk_kill08.wav"
				},
				{
					"vo/ravenholm/monk_rant01.wav",
					"vo/ravenholm/monk_rant02.wav",
					"vo/ravenholm/monk_rant03.wav",
					"vo/ravenholm/monk_rant04.wav",
					"vo/ravenholm/monk_rant05.wav",
					"vo/ravenholm/monk_rant06.wav",
					"vo/ravenholm/monk_rant07.wav",
					"vo/ravenholm/monk_rant08.wav",
					"vo/ravenholm/monk_rant09.wav",
					"vo/ravenholm/monk_rant10.wav",
					"vo/ravenholm/monk_rant11.wav",
					"vo/ravenholm/monk_rant12.wav",
					"vo/ravenholm/monk_rant13.wav",
					"vo/ravenholm/monk_rant14.wav",
					"vo/ravenholm/monk_rant15.wav",
					"vo/ravenholm/monk_rant16.wav",
					"vo/ravenholm/monk_rant17.wav",
					"vo/ravenholm/monk_rant18.wav",
					"vo/ravenholm/monk_rant19.wav",
					"vo/ravenholm/monk_rant20.wav",
					"vo/ravenholm/monk_rant21.wav",
					"vo/ravenholm/monk_rant22.wav",
				}
				
			}
			local sndtbl = snds[math.random(#snds)]
			net.Start("boss.SendSound")
			net.WriteString(sndtbl[math.random(#sndtbl)])
			net.Broadcast()
			
			ent:PlaySequenceAndWait("Idle_Angry_Shotgun")
			--coroutine.wait(5)
		end,
		Cleanup = function(ent)
			ent:SetBAttackDamage(ent:GetBAttackDamage() / 2)
			ent:SetBAttackSpeed(ent:GetBAttackSpeed()*2)
			
			--coroutine.wait(5)
		end
	}
}

ENT.Attacks = {
	{
		CanAttack = function(chance)
			return chance>.25
		end,
		Callback = function(ent, target)
			-- from my conquerors code
			local self = ent
			local tpos = target:GetPos()
			local hboxz = target:OBBCenter().z
			
			self:PlaySequenceNoWait("Idle_SMG1_Aim")
			self.loco:SetMaxYawRate(2000)
			self.loco:FaceTowards(tpos)
			
			local shootpos = self:GetPos() + (self:GetForward() * 10) + Vector(0, 0, hboxz)
			local dir = (tpos - self:GetPos())
						
			local bullet = {}
			bullet.Num = 1
			bullet.Src = shootpos
			bullet.Dir = dir
			bullet.Spread = Vector(0, 0, 0)
			bullet.Tracer = 5
			bullet.Force = 0
			bullet.Damage = self:GetBAttackDamage()
			bullet.AmmoType = self:GetAmmoType()
			bullet.Attacker = self
			bullet.IgnoreEntity = self
						
			self:FireBullets(bullet)
			self:PlaySequenceNoWait("shoot_shotgun")
						
			-- check if target is alive or nah
			if not IsValid(target) or target:Health() < 1 then -- it's probably dead or got removed in some wierd instance
				self:StartActivity(ACT_IDLE)
				self.loco:SetMaxYawRate(250)
							
				--self:SetMoveTo(Vector(0,0,0))
				--self:SetCTarget(nil)
			end
		end
	},
	{
		CanAttack = function(chance)
			return chance<=.25
		end,
		Callback = function(ent,target)
			PrintMessage(3, "headcrabs YEET")
			local random=player.GetAll()[math.random(#player.GetAll())]
			
			for i=1,3 do
				for i=2,math.random(2,5) do
					local where=math.random(1,2)
					local p=Vector()
					local r1=math.random(-500,500)
					local r2=math.random(-500,500)
					if where==1 then
						p=target:GetPos()+Vector(r1,r2,0)
					else
						p=target:GetPos()+Vector(r1,r2,300)
					end
					
					local e=ents.Create("npc_headcrab")
					e:SetPos(p)
					e:Spawn()
					if not e:IsInWorld() then
						e:Remove()
					end
				end
				coroutine.wait(.3)
			end
		end
	}
}

-- Core stuff
if SERVER then
	
	local function generateRunes()
		local runes = {}
		local function spawned()
			local chance = math.random(1, 4)
			if chance == 1 then
				table.insert(runes, (table.Random(GAMEMODE.RuneTable)))
				
				spawned()
			end
		end
		
		return runes
	end
	
	function ENT:Initialize()
		self:Data()
		
		self:SetModel(self:GetBModel())
		self:SetHealth(self:GetBLevel() * self:GetBHealthPLevel())
		self:SetMaxHealth(self:Health())
		self:SetModelScale(self:GetBModelScale())
		
		if self:GetBHasWeapon() then
			timer.Simple(.1, function()
				self:GiveWeapon(self:GetBWeaponClass())
			end)
		end
		
		-- If we are runic, generate the runes.
		if self:GetBIsRunic() then
			for k,v in pairs(generateRunes()) do
				v.Proc(self)
			end
		end
	end
	
	function ENT:GiveWeapon(wep)
		if self.Weapon then self.Weapon:Remove() end
		
		local pos = self:GetAttachment(self:LookupAttachment("anim_attachment_RH")).Pos
		
		self.Weapon = ents.Create(wep)
		self.Weapon:SetOwner(self)
		self.Weapon:SetPos(pos)
		self.Weapon:Spawn()
		
		self.Weapon.DontPickUp = true
		self.Weapon:SetSolid(SOLID_NONE)
		self.Weapon:SetParent(self)
		
		self.Weapon:Fire("setparentattachment", "anim_attachment_RH")
		self.Weapon:AddEffects(EF_BONEMERGE)
	end
	
	ENT.CurrentTarget = nil
	
	function ENT:PickTarget()
		-- self.CurrentTarget:GetObserverMode() == 0
		local attempts = 0
		repeat
			attempts = attempts + 1
			self.CurrentTarget = player.GetAll()[math.random(#player.GetAll())]
			
			if attempts > 1000 then
				break
			end
		until self.CurrentTarget:GetObserverMode() == 0
		
		return self.CurrentTarget
	end
	
	function ENT:GetTarget()
		-- You can overwrite this.
		if self.CurrentTarget then
			if self.CurrentTarget:Health() < 0 then
				self:PickTarget()
			end
		else
			self:PickTarget()
		end
		
		return self.CurrentTarget
	end
	
	function ENT:RunBehaviour()
		while true do
			local NextStage = self.Stages[self:GetBossStage() + 1]
			if NextStage.DoActivate(self) and not NextStage.IsActive then
				-- Get previous stage and deactivate that. Apply the changes
				-- of this stage. This is also coroutine wrapped.
				local LastStage = self.Stages[self:GetBossStage() - 1]
				if LastStage then
					LastStage.Cleanup(self)
					LastStage.IsActive = false
				end
				
				NextStage.OnActivate(self)
				NextStage.IsActive = true
			end
			
			if SysTime() > self:GetBLastAttack() + self:GetBAttackSpeed() then
				local target = self:GetTarget()
				local attack = self.Attacks[math.random(#self.Attacks)]
				if attack and attack.CanAttack(math.random()) and target then
					attack.Callback(self,target)
				end
				
				self:SetBLastAttack(SysTime())
			end
			
			-- Finally, yield after everything.
			-- coroutine.wait() -- for good measure
			coroutine.yield()
		end
	end
else
	function ENT:Draw()
		self:DrawModel()
	end
end