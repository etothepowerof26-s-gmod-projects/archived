local cvar = CreateClientConVar("boss_healthbar_overhead", "1")

surface.CreateFont("BossBar", {
	extended = false,
	font = "Verdana",
	size = 20,
	weight = 500,
	outline = true
})

do
	
	local barWidth = 200

	local x = -barWidth / 2
	local y = -50
	local t = 10

	local bt = 3
	local bH = 30

	hook.Add("PostDrawTranslucentRenderables", "BossBar", function()
		for k,v in pairs(ents.FindByClass("boss_*")) do
			if v:Health()<1 then continue end
			local curProgr  = v:Health()
			local max = v:GetMaxHealth()
			local _max = barWidth - 19
			
			local bgpolys = {
				{ x = x + t, y = y },
				{ x = x + barWidth, y = y },
				{ x = x + barWidth - t, y = y + bH },
				{ x = x, y = y + bH }
			}
			
			local barpolys = {
				{ x = x + t + bt, y = y + bt },
				{ x = x + (_max * (curProgr / max)) + t + bt, y = y + bt },
				{ x = x + (_max * (curProgr / max)) + t - 5, y = y - bt + bH },
				{ x = x + bt * 1.5, y = y + bH - bt }
			}
			
			local e = (curProgr / max)
			local f = 1 - e
			
			local eang = LocalPlayer():EyeAngles()
			local epos = v:GetPos() + Vector(0, 0, v:OBBMaxs().z + 6) + eang:Up()
			eang:RotateAroundAxis(eang:Forward(), 90)
			eang:RotateAroundAxis(eang:Right(), 90)
					
			cam.Start3D2D(epos, eang, 3)
				surface.SetDrawColor(0, 0, 0, 255)
				surface.DrawPoly(bgpolys)
				
				surface.SetDrawColor(255*f, 255*e, 0, 255)
				surface.DrawPoly(barpolys)
				
				surface.SetFont("BossBar")
				
				local bossname = v:GetBName()
				local bossnamesize = { surface.GetTextSize(v:GetBName()) }
				local healthtext = string.Comma(tostring(v:Health())) .. " / " .. string.Comma(tostring(v:GetMaxHealth()))
				local healthsize = { surface.GetTextSize(healthtext) }
				
				surface.SetTextColor(255, 255, 255, 255)
				surface.SetTextPos((x+_max/2)-(bossnamesize[1] / 2), y + bossnamesize[2] + 5)
				surface.DrawText(bossname)
				
				surface.SetTextPos((x+_max/2)-(healthsize[1] / 2.5), y - healthsize[2] - 5)
				surface.DrawText(healthtext)
			cam.End3D2D()
		end
	end)

end

do

	local shouldnt = {["CHudAmmo"] = true}
	hook.Add("HUDShouldDraw", "boss", function(name)
		if shouldnt[name] then
			return false
		end
	end)
		
end

do

	local offset = 10
	local bsize = ScrH() / 3
	local bw = 40

	local bs = 3

	hook.Add("HUDPaint", "ammo", function()
		local wep = LocalPlayer():GetActiveWeapon()
		if not wep then return end
		if not IsValid(wep) then return end
		
		local c1 = wep:Clip1()
		local cs = wep.Primary.ClipSize
		
		local perc = c1 / cs
		
		surface.SetDrawColor(20, 20, 20, 255)
		surface.DrawRect(ScrW() - bw - offset, ScrH() - bsize - offset, bw, bsize)
		
		surface.SetDrawColor(200, 200, 20, 255)
		surface.DrawRect(ScrW() - bw - offset + bs, ScrH() - bsize - offset + bs, bw - bs*2, (bsize - bs*2) * perc)
		
	end)

end