if SERVER then
	
	util.AddNetworkString("Indicator")
	
	CreateIndicator = function(ply, text, color, pos)
		net.Start("Indicator")
			net.WriteString(text)
			net.WriteColor(color)
			net.WriteVector(pos)
		net.Send(ply)
	end

else
	
	local notices = {}
	
	local indc = {}
		AccessorFunc(indc,"m_fric","Friction")
		AccessorFunc(indc,"m_fade","Fade")
		AccessorFunc(indc,"m_grav","Gravity")
		AccessorFunc(indc,"m_life","LifeTime")
		AccessorFunc(indc,"m_text","Text")
		AccessorFunc(indc,"m_colr","Color")
		AccessorFunc(indc,"m_post","Pos")
		AccessorFunc(indc,"m_velo","Velocity")
		AccessorFunc(indc,"m_strt","Start")
		
	function NewIndicator()
		local nidc = setmetatable({}, { __index=indc })
		
		nidc:SetFriction(1.1)
		nidc:SetFade(3)
		nidc:SetGravity(.02)
		nidc:SetLifeTime(4)
		nidc:SetText("Indicator")
		nidc:SetColor(Color(255,255,255))
		nidc:SetPos(Vector(0,0,0))
		nidc:SetVelocity(Vector())
		nidc:SetStart(SysTime())
		
		return nidc
	end

	net.Receive("Indicator", function()
		local text = net.ReadString()
		local col = net.ReadColor()
		local pos = net.ReadVector()

		local idc = NewIndicator()

		idc:SetText(text)
		idc:SetColor(col)
		idc:SetPos(pos + VectorRand() * 15)
		idc:SetGravity(0)

		notices[#notices + 1] = idc
	end)
	
	hook.Add('HUDPaint','Indicators',function()
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
			
			v:SetVelocity((v:GetVelocity() - Vector(0,0,v:GetGravity())) / v:GetFriction())
			v:SetPos(v:GetPos() + v:GetVelocity())
			v:SetColor(Color(nc.r, nc.g, nc.b, nc.a - v:GetFade()))
				
			if SysTime() > v:GetStart() + v:GetLifeTime() then
				table.remove(notices, k)
			end
		end
	end)

end