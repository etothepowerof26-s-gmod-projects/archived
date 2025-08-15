include("shared.lua")

local circles = include("cl_circles.lua")

local m = Material("trails/laser")

function ENT:Draw()
	self:DrawModel()

	local gun = self:GetGun()

	local min, max = self:GetRenderBounds()
	local pos = self:GetPos() + Vector(0, 0, self:OBBMaxs().z * 3)
	local ang = self:GetAngles()
	ang:RotateAroundAxis(ang:Forward(), 90)
	ang.y = EyeAngles().y -90
	
	cam.Start3D2D(pos, ang, 0.1)
		if not self.Circles and self:GetDoReloadMechanism() then
			self.Circles = {
				circles.New(CIRCLE_FILLED, 53, 0, 0), -- background
				circles.New(CIRCLE_FILLED, 50, 0, 0), --timer
			}
			self.Circles[1]:SetColor(Color(0, 0, 0))
			self.Circles[2]:SetColor(Color(255, 255, 255))
			self.Circles[2]:SetStartAngle(-90)
		elseif self.Circles and self:GetDoReloadMechanism() then
			draw.NoTexture()
			self.Circles[1]()
			if self:GetIsReloading() then
				if not self.OldReloadStart then
					self.OldReloadStart = CurTime()
					self.Circles[2]:SetColor(Color(124, 124, 124))
				end	
				
				self.Circles[2]:SetEndAngle(Lerp((CurTime() - self.OldReloadStart)/ self:GetReloadTimer(), 0, 360) - 90)
			else
				self.OldReloadStart = nil
				self.Circles[2]:SetColor(Color(255, 255, 255))
				self.Circles[2]:SetEndAngle(Lerp(self:GetBullets() / self:GetDefaultClip(), 0, 360) - 90)
			end 
			self.Circles[2]()
		end
	cam.End3D2D()

	if self:GetIsReloading() then return end

	local target = ents.FindByClass("td_base_enemy")[#ents.FindByClass("td_base_enemy")]
	local tpos = target:GetPos() + Vector(0, 0, target:OBBMaxs().z / 2)

	render.SetMaterial(m)
	render.DrawBeam( gun:GetPos() + gun:GetForward() * 8 - gun:GetRight() * 1.5 + gun:GetUp() * 2 , tpos, 10, 1, 1, Color(255,255,255))

end

function ENT:Think()
	local target = ents.FindByClass("td_base_enemy")[#ents.FindByClass("td_base_enemy")]
	local gun = self:GetGun()

	if not IsValid(gun) then return end
	if self:GetIsReloading() then return end

	local gmodel, gtrans, gyoffs = self:GetGunModel()
	gun:SetAngles( ( target:GetPos() - self:GetPos() -  Vector(0, 0, target:OBBMaxs().z / 2)):Angle() )
	gun:SetPos( self:GetPos() + Vector(0, 0, gyoffs) + gun:GetForward() * 8 + gun:GetRight() )
end