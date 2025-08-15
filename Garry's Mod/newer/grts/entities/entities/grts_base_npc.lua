AddCSLuaFile()

ENT.PrintName = "GMod RTS NPC"
ENT.Type			= "nextbot"
ENT.Base			= "base_nextbot"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Health")
	self:NetworkVar("Int", 1, "MaxHealth")
	self:NetworkVar("Int", 2, "WeaponDamage")
	self:NetworkVar("Int", 3, "Speed")
	self:NetworkVar("Int", 4, "FireDist")
	
	self:NetworkVar("Bool", 0, "CanRegen")
	
	self:NetworkVar("Entity", 0, "COwner")
	self:NetworkVar("Entity", 1, "CTarget")
	
	self:NetworkVar("String", 0, "SpawnWeapon")
	self:NetworkVar("String", 1, "AmmoType")
	self:NetworkVar("String", 2, "SpawnModel")
	
	self:NetworkVar("Vector", 0, "MoveTo")
end
	
if SERVER then
	-- Default variables. You change your stuff in here.
	function ENT:DoVars()
		self:SetHealth(20)
		self:SetMaxHealth(20)
		
		self:SetCanRegen(false)
		self:SetSpawnWeapon("weapon_annabelle")
		self:SetSpawnModel("models/monk.mdl")
		self:SetWeaponDamage(3)
		self:SetSpeed(50)
		self:SetFireDist(125)
		self:SetAmmoType("Buckshot")
	end
	
	function ENT:Initialize()
		self:DoVars()
		
		self:SetModel(self:GetSpawnModel())
		self:SetModelScale(0.3)
		
		self:SetUseType(SIMPLE_USE)
		
		-- TODO: [=] Refactor this and it's code.
		self:GiveWeapon(self:GetSpawnWeapon())
	end
	
	-- TODO: [=] Refactor this and it's code.
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
	
	function ENT:OnInjured(dmg)
		local infl = dmg:GetInflictor()
		
		if IsValid(infl) and infl:IsPlayer() then
			dmg:SetDamage(0)
			return
		end
		
		-- Regression: WTF
		if (infl:GetClass():find("grts_") and true or false) then
			local damage = dmg:GetDamage()
			self:SetHealth(self:Health() - damage)
			
			CreateIndicator(infl:GetCOwner(), tostring(damage) .. " damage!", Color(255, 100, 100), self:GetPos())
			
			if self:Health() < 1 then
				CreateIndicator(infl:GetCOwner(), "Got a kill!", Color(255, 100, 100), infl:GetPos())
				
				CreateIndicator(self:GetCOwner(), "Your troop died!", Color(255, 0, 0), self:GetPos())
			end
		else
			dmg:SetDamage(0)
			return
		end
	end
	
	function ENT:RunBehaviour()
		while true do
			local target = self:GetCTarget()
			
			if self:GetMoveTo() == Vector(0, 0, 0) then
				self:StartActivity(ACT_IDLE)
			else
				if not IsValid(target) then
				--else
					self:StartActivity(ACT_WALK)
					
					self.loco:FaceTowards(self:GetMoveTo())
					self.loco:SetDesiredSpeed(self:GetSpeed())
						
					self:MoveToPos(self:GetMoveTo())
						
					if self:GetPos():DistToSqr(self:GetMoveTo()) <= 400 then
						self:SetMoveTo(Vector(0, 0, 0))
					end
					
					-- TODO: [==] Use ENT:GetVar or network variables.
					if self.__lookfor then
						-- The enemy might've died already by the time they reach them.
						if not IsValid(self.__lookfor) then
							self.__lookfor = nil
							self:SetMoveTo(Vector(0, 0, 0))
						else
							local tpos = self.__lookfor:GetPos()
							local dist = tpos:DistToSqr(self:GetPos())
							
							-- print(dist)
							if dist <= self:GetFireDist() ^ 2 then
								self:SetCTarget(self.__lookfor)
								self.__lookfor = nil
								
								CreateIndicator(self:GetCOwner(), "We found them!", Color(255, 255, 120), self:GetPos())
							end
						end
					end
				end
			end
			
			
			if IsValid(target) then
				local tpos = target:GetPos()
				
				self:PlaySequenceAndWait("Idle_SMG1_Aim")
				self.loco:SetMaxYawRate(2000)
				self.loco:FaceTowards(tpos)
				
				-- fire if distance is less
				-- else, abandon and start moving towards
				
				local dist = tpos:DistToSqr(self:GetPos())
				if dist >= self:GetFireDist() ^ 2 then
					self:StartActivity(ACT_IDLE)
					self.__lookfor = target
					self.loco:SetMaxYawRate(250)
					
					self:SetMoveTo(Vector(0,0,0))
					self:SetCTarget(nil)
					
					CreateIndicator(self:GetCOwner(), "Out of range...", Color(120, 255, 120), self:GetPos())
				else
					local hboxz = target:OBBCenter().z
					
					local shootpos = self:GetPos() + (self:GetForward() * 10) + Vector(0, 0, hboxz)
					local dir = (tpos - self:GetPos())
					
					local bullet = {}
					bullet.Num = 1
					bullet.Src = shootpos
					bullet.Dir = dir
					bullet.Spread = Vector(0, 0, 0)
					bullet.Tracer = 5
					bullet.Force = 0
					bullet.Damage = self:GetWeaponDamage()
					bullet.AmmoType = self:GetAmmoType()
					bullet.Attacker = self
					bullet.IgnoreEntity = self:GetCOwner()
					bullet.Callback = function(ent, trace, dmg)
						local ent_tr = trace.Entity
						local base = ent_tr.Base
						
						if base == "grts_base_building" and ent_tr == self:GetCTarget() then
							local d = dmg:GetDamage()
							ent_tr:SetHealth(ent_tr:Health() - d)
						end
					end
					
					self:FireBullets(bullet)
					
					-- TODO: [===] Make more friendly to use instead of having to remake the whole run behaviour.
					self:PlaySequenceAndWait("shoot_shotgun")
					
					-- check if target is alive or nah
					if not IsValid(target) or target:Health() < 1 then -- it's probably dead or got removed in some wierd instance
						self:StartActivity(ACT_IDLE)
						self.loco:SetMaxYawRate(250)
						
						self:SetMoveTo(Vector(0,0,0))
						self:SetCTarget(nil)
					end
				end
			end
			
			coroutine.wait(.2)
			coroutine.yield()
		end
	end
	
	function ENT:Use(a, c)
		-- TODO: Remake.
		
		if a ~= self:GetCOwner() then
			return
		end
		
		net.Start("grts_openmenu")
		net.WriteEntity(self)
		net.Send(self:GetCOwner())
		
		
		--[[print(a, c, self:GetCOwner())
		if a ~= self:GetCOwner() then return end
		
		-- local bool = self:GetNWBool("grts_selected", false)
		-- self:SetNWBool("grts_selected", not bool)
		
		net.Start(Tag)
			net.WriteString("Sound")
			net.WriteString("buttons/blip1.wav")
			--net.WriteString(bool and "buttons/blip1.wav" or )
		net.Send(a)
		
		net.Start(Tag)
			net.WriteString("Menu")
			net.WriteEntity(self)
		net.Send(a)
		
		-- a:SetNWBool("grts_is_selecting", true)]]
	end
else
	local function drawBlur(txt, font, x, y, col, align, s)
		draw.DrawText(txt, font, x, y, Color(0, 0, 0), align)
		draw.DrawText(txt, font, x+s, y+s, col, align)
	end
	
	local selmat = Material("SGM/playercircle")
	local lazermat = Material("trails/laser")
	local me = LocalPlayer()
	
	local function drawBubble(self, width, height, col, pos)
		local trace = {}
		trace.start = self:GetPos() + Vector(0, 0, 50)
		trace.endpos = trace.start + Vector(0, 0, -300)
		trace.filter = {self, unpack(player.GetAll())}
		
		local tr = util.TraceLine(trace)
		
		if not tr.HitWorld then
			tr.HitPos = self:GetPos()
		end
		
		render.SetMaterial(selmat)
		
		-- local a = math.abs(math.sin(self.SinAction / 25) * 100) + 50
		-- render.DrawQuadEasy(tr.HitPos + tr.HitNormal, tr.HitNormal, 20, 20, Color(100, 255, 100, a))
		render.DrawQuadEasy((not pos and tr.HitPos or pos) + tr.HitNormal, tr.HitNormal, width, height, col)
	end
	
	ENT.SinAction = 0
	function ENT:Draw()
		self:DrawModel()
		
		self.SinAction = self.SinAction + 1
		-- health
		local offset = Vector(0, 0, self:OBBMaxs().z + 25)
		local ang = LocalPlayer():EyeAngles()
		local pos = self:GetPos() + offset + ang:Up()
		
		ang:RotateAroundAxis(ang:Forward(), 90)
		ang:RotateAroundAxis(ang:Right(), 90)
		
		local health, maxhealth = self:Health(), self:GetMaxHealth()
		
		if health > 0 then
			cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.25)
				local col = Color((255 * (1 - health / maxhealth)), (255 * (health / maxhealth)), 0)
				drawBlur(tostring(health) .. " / " .. tostring(maxhealth), "CoolveticaMedium", 2, 60, col, TEXT_ALIGN_CENTER, 1)
			cam.End3D2D()
		end
		
		local IsOwnedByMe = me == (self.GetCOwner and self:GetCOwner() or me)
		local IsSelected = self:GetNWBool("grts_selected", false) -- TODO: Change to integer
		local IsAttackSelect = self:GetNWBool("grts_select_attack", false)
		
		-- Line that is drawn when the NPC is trying to move somewhere.
		-- TODO: Draw it's path?
		if IsOwnedByMe then
			local moveto = not self.GetMoveTo and Vector(0, 0, 0) or self:GetMoveTo()
			local target = (self.GetCTarget and self:GetCTarget() or me)
			
			if moveto ~= Vector(0, 0, 0) and (not IsValid(target) or target == me) then
				local a = math.abs(math.sin(self.SinAction / 50) * 50)
				
				render.SetMaterial(lazermat)
				render.DrawBeam(self:GetPos(), moveto, 10, self.SinAction, self.SinAction + 10, Color(0, 255, 0, a))
				-- drawBubble(self, 10, 10, Color(0, 255, 0, a), moveto)
			else
				if IsValid(target) and target ~= me then
					local obb = self:OBBMaxs().z
					obb = Vector(0, 0, obb / 1.25)
					
					render.SetMaterial(lazermat)
					render.DrawBeam(self:GetPos() + obb, target:GetPos() + obb, 10, self.SinAction, self.SinAction + 10, Color(255, 0, 0))
				end
			end
			
			-- selection bubble
			if IsSelected then
				local a = math.abs(math.sin(self.SinAction / 25) * 100) + 50
				drawBubble(self, 20, 20, Color(100, 255, 100, a))
				
				-- line to move to position
				local eyetrace = me:GetEyeTrace()
				local hp = eyetrace.HitPos
				
				if not hp then hp = me:GetPos() end
				hp.z = self:GetPos().z
				
				render.SetMaterial(lazermat)
				render.DrawBeam(self:GetPos(), hp, 10, self.SinAction, self.SinAction + 10,
					IsAttackSelect and Color(255, 0, 0) or Color(255, 255, 255))
			end
		else
		-- enemy bubble
			local etrace = me:GetEyeTrace()
			if not IsOwnedByMe and etrace.Entity == self and me:GetNWBool("grts_is_selecting", false) then
				local a = math.abs(math.sin(self.SinAction / 25) * 100) + 50
				drawBubble(self, 20, 20, Color(255, 100, 100, a))
			end
		end
	end
end