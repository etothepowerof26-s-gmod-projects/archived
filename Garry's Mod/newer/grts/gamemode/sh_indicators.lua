module("gmodrts", package.seeall)

if SERVER then

	util.AddNetworkString("grts_indicate")

	CreateIndicator = function(ply, text, color, pos)
		net.Start("grts_indicate")
			net.WriteString(text)
			net.WriteColor(color)
			net.WriteVector(pos)
		net.Send(ply)
	end
	
end

if CLIENT then
	
	local notices = {}
	local Indicator = {}
	AccessorFunc(Indicator, "m_friction","Friction")
	AccessorFunc(Indicator, "m_fade","Fade")
	AccessorFunc(Indicator, "m_gravity","Gravity")
	AccessorFunc(Indicator, "m_life","LifeTime")
	AccessorFunc(Indicator, "m_text","Text")
	AccessorFunc(Indicator, "m_color","Color")
	AccessorFunc(Indicator, "m_position","Pos")
	AccessorFunc(Indicator, "m_velocity","Velocity")
	AccessorFunc(Indicator, "m_start","Start")
	
	function NewIndicator()
		local I = setmetatable({}, { __index = Indicator })
		
		I:SetFriction(1.1)
		I:SetFade(1)
		I:SetGravity(.02)
		I:SetLifeTime(4)
		I:SetText("Indicator")
		I:SetColor(Color(255,255,255))
		I:SetPos(Vector(0,0,0))
		I:SetVelocity(Vector(0,0,0))
		I:SetStart(SysTime())
		
		return I
	end
	
	hook.Add("HUDPaint", "grts_indicate" ,function()
		for k,v in pairs(notices) do
			local col = v:GetColor()
			local text = v:GetText()
			
			local pos = v:GetPos()
			local scrpos = pos:ToScreen()
			draw.SimpleTextOutlined(
				text,
				"Trebuchet24",
				scrpos.x,
				scrpos.y,
				col,
				1,
				1,
				1,
				Color(43, 42, 39, col.a)
			)
			
			local nc = v:GetColor()
			
			v:SetVelocity((v:GetVelocity() - Vector(0, 0, v:GetGravity())) / v:GetFriction())
			v:SetPos(v:GetPos() + v:GetVelocity())
			v:SetColor(Color(nc.r, nc.g, nc.b, nc.a - v:GetFade()))
				
			if SysTime() > v:GetStart() + v:GetLifeTime() then
				table.remove(notices, k)
			end
		end
	end)
	
	net.Receive("grts_indicate", function(len)
		local text = net.ReadString()
		local color = net.ReadColor()
		local pos = net.ReadVector()
		
		local I = NewIndicator()
		I:SetText(text)
		I:SetColor(color)
		I:SetPos(pos)
		I:SetVelocity(Vector(math.random(-2, 2), math.random(-2, 2), 3))
		
		table.insert(notices, I)
	end)

end