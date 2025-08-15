local mat_white = Material("vgui/white")
function draw.LinearGradient(x, y, w, h, stops, horizontal)
	if #stops == 0 then
		return
	elseif #stops == 1 then
		surface.SetDrawColor(stops[1].color)
		surface.DrawRect(x, y, w, h)
		return
	end

	table.SortByMember(stops, "offset", true)

	render.SetMaterial(mat_white)
	mesh.Begin(MATERIAL_QUADS, #stops - 1)
	for i = 1, #stops - 1 do
		local offset1, offset2 = math.Clamp(stops[i].offset, 0, 1), math.Clamp(stops[i + 1].offset, 0, 1)
		if offset1 == offset2 then continue end

		local deltaX1, deltaY1, deltaX2, deltaY2

		local color1 = stops[i].color
		local color2 = stops[i + 1].color

		local r1, g1, b1, a1, 
			  r2, g2, b2, a2,
			  r3, g3, b3, a3,
			  r4, g4, b4, a4 = color1.r, color1.g, color1.b, color1.a,
							   nil, nil, nil, nil,
							   color2.r, color2.g, color2.b, color2.a,
							   nil, nil, nil, nil

		if horizontal then
			r2, g2, b2, a2, r4, g4, b4, a4 = r3, g3, b3, a3, r1, g1, b1, a1
			deltaX1, deltaY1, deltaX2, deltaY2 = offset1 * w, 0, offset2 * w, h
		else
			r2, g2, b2, a2, r4, g4, b4, a4 = r1, g1, b1, a1, r3, g3, b3, a3
			deltaX1, deltaY1, deltaX2, deltaY2 = 0, offset1 * h, w, offset2 * h
		end

		mesh.Color(r1, g1, b1, a1)
		mesh.Position(Vector(x + deltaX1, y + deltaY1))
		mesh.AdvanceVertex()

		mesh.Color(r2, g2, b2, a2)
		mesh.Position(Vector(x + deltaX2, y + deltaY1))
		mesh.AdvanceVertex()

		mesh.Color(r3, g3, b3, a3)
		mesh.Position(Vector(x + deltaX2, y + deltaY2))
		mesh.AdvanceVertex()

		mesh.Color(r4, g4, b4, a4)
		mesh.Position(Vector(x + deltaX1, y + deltaY2))
		mesh.AdvanceVertex()
	end
	mesh.End()
end

include( "shared.lua" )

include( "cl_diffvote.lua" )

include( 'skills.lua' )


local dont = {
	["CHudGeiger"] = true,
	["CHudHealth"] = true
}
function GM:HUDShouldDraw( name )
	if dont[name] then return false end

	return self.BaseClass.HUDShouldDraw(self, name)
end


function GM:CreateClientsideRagdoll( owner, ragdoll )
	ragdoll:SetVelocity(Vector(0, 0, 0))
	ragdoll:SetSaveValue( "m_bFadingOut", true )
end


-- UI
local skull = Material("icon16/exclamation.png")
local flag = Material("icon16/flag_yellow.png")
local function LerpColor(f, c1, c2)
	return Color(
		Lerp(f, c1.r, c2.r),
		Lerp(f, c1.g, c2.g),
		Lerp(f, c1.b, c2.b)
	)
end
local flipped
local color_t, color_r = Color(0, 255, 136), Color(255, 0, 0)
local lerpColor = color_t
local rounds = 0

local sx, sy, sw = ScrW() / 2, 0, ScrW() / 8
local edge = 50
local polygon = {
	{
		x = sx - sw,
		y = sy 
	},
	{
		x = sx + sw,
		y = sy
	},
	{
		x = sx + sw - edge,
		y = sy + edge
	},
	{ 
		x = sx - sw + edge,
		y = sy + edge
	}
}
local displays = {

	{
		icon = Material"icon16/money.png",
		value = function()
			return "100"
		end,
		color = Color(255, 255, 255)
	},
	{
		icon = Material"icon16/heart.png",
		value = function()
			return GetGlobalInt( "td_lives", 69420 )
		end,
		color = Color(255, 255, 0)
	},

}



function GM:HUDPaint()


	lerpColor = LerpColor(0.05, lerpColor, flipped and color_r or color_t)

	// gray background
	surface.SetDrawColor(80, 80, 80, 160)
	surface.DrawPoly(polygon)

	// white lines around background
	surface.SetDrawColor(240, 240, 240, 255)
	surface.DrawLine(sx, sy, sx + sw, sy)
	surface.DrawLine(sx + sw, sy, sx + sw - edge, sy + edge)
	surface.DrawLine(sx, sy, sx - sw, sy)
	surface.DrawLine(sx - sw, sy, sx - sw + edge, sy + edge)
	surface.DrawLine(sx - sw + edge, sy + edge, sx + sw - edge, sy + edge)

	// wave counter
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(sx - sw + edge, 10, sw * 2 - edge * 2, 10)
	// bar
	local bo = 2
	local max = 60
	local perc = rounds/max
	surface.SetDrawColor(lerpColor)
	surface.DrawRect(sx - sw + edge + bo, 10 + bo, (sw * 2 - edge * 2 - bo * 2) * perc, 10 - bo * 2)
	// wave beginning
	surface.SetFont("BudgetLabel")
	surface.SetTextColor(255, 255, 255, 255)
	surface.SetTextPos(sx - sw + edge - 10, 8)
	surface.DrawText("1")
	// wave end 
	surface.SetTextPos(sx + sw - edge + 5, 8)
	surface.DrawText(max)

	// draw flag and skull tokens every 12 rounds on the progress bar
	surface.SetDrawColor(255, 255, 255)
	surface.SetMaterial(skull) -- (sw * 2 - edge * 2 - bo * 2) * p  
	local f
	local kw, kh = 10, 10
	for i = 1, math.floor(max / 12) do
		local p = (12 * i) / max
		if perc == p then
			f = true
			continue
		elseif perc > p then
			continue 
		end
		local s = (sw * 2 - edge * 2 - bo * 2) * p
		if i == math.floor(max / 12) then
			surface.SetDrawColor(color_r)
		end
		surface.DrawTexturedRect(sx - sw + edge + bo + s - kw / 2, 10, kw, kh)
	end
	flipped = f

	surface.SetDrawColor(255, 255, 255)
	surface.SetMaterial(flag)
	local s = (sw * 2 - edge * 2 - bo * 2) * perc
	surface.DrawTexturedRect(sx - sw + edge + bo - kw / 2 + s, 10, kw, kh)

	if rounds > 1 and rounds < max then 
		local tw, th = surface.GetTextSize(tostring(rounds))
		surface.SetTextPos(sx - sw + edge + bo + s - tw / 2, 8)
		surface.DrawText(rounds)
	end

	// cash
	// wave counter

	local count = #displays

	for i = 1, count do
		local disp = displays[i]

		local asd = math.ceil((sw * 2 - edge * 2) / count)

		surface.SetMaterial(disp.icon)
		surface.SetDrawColor(color_white)
		surface.DrawTexturedRect(sx - sw + edge + asd * (i - 1) + asd / 2 - 5, edge - 15, 10, 10)

		local tw, th = surface.GetTextSize(disp.value())
		surface.SetTextPos( sx - sw + edge + asd * (i - 1) + asd / 2 - 1 - tw / 2, edge - 20 - th / 2 )
		surface.DrawText(disp.value())
	end
end

concommand.Add('asd', function()
	rounds = rounds + 1
end)