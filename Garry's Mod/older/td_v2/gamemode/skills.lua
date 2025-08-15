print('balls', SERVER, CLIENT)

local function hex( cat, type, influence )
	return {
		cat = cat,
		type = type,
		influence = influence
	}
end

if SERVER then
	
	resource.AddFile( "materials/palette/9mm.png" )

	util.AddNetworkString("td_palette_request")
	util.AddNetworkString("td_palette_action")

	hook.Add("PlayerFullLoad", "skill", function(ply)
		ply.SkillPalData = {
			inv = { hex( 1, 1, 0.2 ) },
			grid = {
				[0] = {
					[0] = hex( 1, 1, 0.5 ),
					[-1] = hex( 1, 1, .34 )
				}
			}
		}
	end)

	function GM:SendSkillPalDataTo(ply)
		net.Start('td_palette_request')
			net.WriteTable(ply.SkillPalData.inv)
			net.WriteTable(ply.SkillPalData.grid)
		net.Send(ply)
	end

	concommand.Add("td_open_palette", function(p)
		p.SkillPalData = {
			inv = { hex( 1, 1, 0.2 ) },
			grid = {
				[0] = {
					[0] = hex( 2, 1, 0.5 ),
					[-1] = hex( 4, 1, .34 )
				},
				[-1] = {
					[0] = hex(1, 1, 0.5)
				}
			}
		}
		GAMEMODE:SendSkillPalDataTo(p)
	end)

	net.Receive("td_palette_request", function(len, ply)
	end)
	net.Receive("td_palette_action", function(len, ply)
	end)
	return

end


local catcols = {
	Color(255, 0, 0),
	Color(255, 255, 0),
	Color(0, 255, 0),
	Color(0, 0, 255),
	Color(160, 160, 160)
}
local cattypes = {
	{
		{
			aug = "Strength",
			desc = "Towers deal %s%% more damage. (NON STACKING)",
			extra = "The game will use the highest valued one in your Skill Palette\nfor damage calculations.",
			range = { min = 1, max = 5 },
			round = 1,
			icon = Material("palette/9mm.png")
		}
	},
	{
		{
			aug = "Riches",
			desc = "Starting cash is increased by +$%s.",
			range = { min = 25, max = 100 },
			round = 0,
		}
	},
	{
		{
			aug = "Life",
			desc = "Starting lives are increased by +%s.",
			range = { min = 2, max = 10 }
		}
	},
	{
		{
			aug = "Crippling",
			desc = "Enemies have -%s%% health.",
			range = { min = 1, max = 5 }
		},
		{
			aug = "Safety",
			desc = "Enemies have a %s%% percent chance to not take a life whenever they reach the end.",
			range = { min = 5, max = 25 }
		}
	}
}


net.Receive("td_palette_request", function()
	local inv, grid = net.ReadTable(), net.ReadTable()

	--if not GAMEMODE.CachedPalette then
		GAMEMODE.CachedPalette = { inv = inv, grid = grid }
	--end

	GAMEMODE:CreateSkillPalPanel()
end)

local cachedPolygons = {}
local function generateHexagonPoly(cx, cy, radius)
	if cachedPolygons[cx] and cachedPolygons[cx][cy] and cachedPolygons[cx][cy][radius] then
		return cachedPolygons[cx][cy][radius]
	end
	cachedPolygons[cx] = cachedPolygons[cx] or {}
	cachedPolygons[cx][cy] = cachedPolygons[cx][cy] or {}

	local rad60 = math.rad(60)
	-- x and y are the center of the hexagon
	local poly = {
		[1] = {
			x = cx,
			y = cy-radius,
		},
		[2] = {
			x = cx + math.sin(rad60) * radius,
			y = cy + math.cos(rad60) * -radius,
		},
		[3] = {
			x = cx + math.sin(rad60) * radius,
			y = cy + math.cos(rad60) * radius,
		},
		[4] = {
			x = cx,
			y = cy+radius,
		},
		[5] = {
			x = cx + math.sin(rad60) * -radius,
			y = cy + math.cos(rad60) * radius,
		},
		[6] = {
			x = cx + math.sin(rad60) * -radius,
			y = cy + math.cos(rad60) * -radius,
		}

	}
	cachedPolygons[cx][cy][radius] = poly

	return poly
end

surface.CreateFont("SkillPalTitle", {
	size = 35,
	weight = 800,
	font = "Trebuchet",
	extended = false
})
surface.CreateFont("SkillPalSTitle", {
	size = 25,
	weight = 500,
	font = "Trebuchet",
	extended = false
})


local DPanel = vgui.GetControlTable("DPanel")

--[[
	function jdraw.DrawProgressBar(PanelTable)
	local Radius = PanelTable.Radius or 0
	local Border = PanelTable.Border or 0
	local X, Y = PanelTable.Position.X, PanelTable.Position.Y
	local Width, Height = PanelTable.Size.Width, PanelTable.Size.Height
	local Value = PanelTable.Value
	local MaxValue = PanelTable.MaxValue
	local BarWidth = ((Width - (Border * 2)) / MaxValue) * Value
	local Text = PanelTable.Text
	if Radius > BarWidth then Radius = 1 end
	draw.RoundedBox(Radius, X, Y, Width, Height, PanelTable.BorderColor)
	draw.RoundedBox(Radius, X + Border, Y + Border, Width  - (Border * 2), Height - (Border * 2), Gray)
	surface.SetDrawColor(0, 0, 0, 70)
	surface.SetMaterial(GradiantDown)
	surface.DrawTexturedRect(X, Y, Width, Height)
	if Value > 0 then
		draw.RoundedBox(Radius, X + Border, Y + Border, BarWidth, Height - (Border * 2), PanelTable.Color)
		surface.SetDrawColor(0, 0, 0, 100)
		surface.SetMaterial(GradiantUp)
		surface.DrawTexturedRect(X + Border, Y + Border, BarWidth, Height - (Border * 2))
	end
	if Text and Text ~= "" then
		draw.SimpleText(Text, PanelTable.Font, X + (Width / 2), Y + (Height / 2), PanelTable.TextColor, 1, 1)
	end
end
]]

local gradient = Material("gui/gradient_down")
local gradient2 = Material("gui/gradient_up")

-- why the fuck
local gray = Color(97, 95, 90)
local dgray = Color(43, 42, 39)
local function drawGradientBox(radius, x, y, width, height, color, bordercolor, bordersize)
	draw.RoundedBox(radius, x, y, width, height, bordercolor)
	draw.RoundedBox(radius, x + bordersize, y + bordersize, width - bordersize*2, height - bordersize*2, color)

	surface.SetDrawColor(0, 0, 0, 150)
	surface.SetMaterial(gradient2)
	surface.DrawTexturedRect(x + bordersize, y + bordersize, width - bordersize*2, height - bordersize*2)
end

local function drawGradientProgBar(perc, radius, x, y, width, height, color, bordercolor, bordersize)

	draw.RoundedBox(radius, x, y, width, height, bordercolor)
	draw.RoundedBox(radius, x + bordersize, y + bordersize, width - bordersize*2, height - bordersize*2, gray)
	draw.RoundedBox(radius, x + bordersize, y + bordersize, (width - bordersize*2)*perc, height - bordersize*2, color)

	surface.SetDrawColor(0, 0, 0, 150)
	surface.SetMaterial(gradient2)
	surface.DrawTexturedRect(x + bordersize, y + bordersize, width - bordersize*2, height - bordersize*2)

end

hook.Add("HUDPaint", "sex", function()
	drawGradientProgBar(math.sin(CurTime()), 4, 200, 100, 100, 25, Color(255, 0, 0), dgray, 2)
end)

local PANEL = {}
function PANEL:Init()
	self:SetSize(1000, 800)
	self:Center()
	self:SetTitle''--("Skills")
	self:MakePopup()

	self.HexGrid = vgui.Create("DTowerPaletteHexGrid", self)
	self.HexGrid:SetSize(650, 650)

	self.Inventory = vgui.Create('DTowerPaletteInventory', self)
	timer.Simple(0.1, function()
		if not IsValid(self.HexGrid) then return end
		-- PrintTable(GAMEMODE.CachedPalette)
		self.HexGrid:Populate()
		self.Inventory:Populate()
	end)
end

function PANEL:PerformLayout(w, h)
	self.HexGrid:SetSize()
end


vgui.Register("DTowerSkillPalette", PANEL, "DFrame")

local PANEL = {}
function PANEL:Init()
	self:Dock(TOP)
	self:SetBackgroundColor(Color(60, 60, 90))
end
local gray, dgray, noalpha = Color(60, 60, 90), Color(50, 50, 80), Color(50, 50, 80, 0)
local realw, realh
local gradTable = {
	{
		offset = 0,
		color = gray
	},
	{
		offset = 0.3,
		color = noalpha
	},
	{
		offset = 0.7,
		color = noalpha
	},
	{
		offset = 1,
		color = gray
	}
}
local hexsize = 60
local function drawCenteredText(x, y, txt)
	local tw, th = surface.GetTextSize(txt)
	surface.SetTextPos(x - tw / 2, y - th / 2)
	surface.DrawText(txt)
end
function PANEL:Paint(w, h)
	DPanel.Paint(self, w, h)
	draw.NoTexture()
	if not realw then
		realw, realh = w, h
	end

	local scrx, scry = self:LocalToScreen(0, 0)
	-- WOOHOO LINEAR GRADIENT YEAAAH
	surface.SetDrawColor(20, 20, 30)
	surface.DrawRect(0, 0, w, 50)

	surface.SetTextColor(color_white:Unpack())
	surface.SetFont("SkillPalTitle")
	drawCenteredText(w * .5, 25, "Skill Palette")

	draw.LinearGradient(
		scrx,
		scry + 50,
		w,
		h - 50,
		gradTable
	)
	
	--self.HoveredDataTable = nil--hex( 1, 1, 0.34 )

	local dat = self.HoveredDataTable
	if (dat) then
		
		surface.SetDrawColor(40, 40, 40)
		surface.DrawRect(0, 50, w, 50)
		surface.SetFont("SkillPalSTitle")
		local toptxt = ""
		local bottomtxt = "balls"
		local yo = 68
		if (next(dat) == nil) then
			toptxt = "No Augment"
			yo = 75
		else
			local c = cattypes[dat.cat][dat.type]
			toptxt = "Augment of " .. c.aug
			bottomtxt = string.format(
				c.desc,
				math.Round(
					math.Remap(
						dat.influence,
						0,
						1,
						c.range.min,
						c.range.max
					),
					c.round or 0
				)
			)
		end
		drawCenteredText(w * .5, yo, toptxt)
		if (bottomtxt != "") then
			surface.SetFont("BudgetLabel")
			yo = yo + 20
			drawCenteredText(w * .5, yo, bottomtxt)
		end

	end
end
function PANEL:Populate(w)
	local d = hexsize / 2
	w = w or 1
	-- panel:SetPos(rw/2 - w/2 - w*x - math.abs(y) * w / 2, rh/2 - h/2 - h * (y * 0.9))
	-- w = 60
	-- h = 60
	for x = -w, w do
		for y = -w, w - math.abs(x) do
			-- createHexagon(y, x)
			local hex = vgui.Create('DTowerPaletteHex', self)
			hex:SetPos(
				( realw / 2 ) - d - hexsize * y - math.abs(x) * d,
				( realh / 2 ) - d - hexsize * (0.9 * x)
			)
			hex:SetIDX(x)
			hex:SetIDY(y)

			if GAMEMODE.CachedPalette and GAMEMODE.CachedPalette.grid[x] and GAMEMODE.CachedPalette.grid[x][y] then
				hex:SetData(GAMEMODE.CachedPalette.grid[x][y])
			end
		end
	end
end
vgui.Register("DTowerPaletteHexGrid", PANEL, "DPanel")

local PANEL = {}
local noLerp, yesLerp = 34, 105
AccessorFunc(PANEL, "m_ix", "IDX", FORCE_NUMBER)
AccessorFunc(PANEL, "m_iy", "IDY", FORCE_NUMBER)
AccessorFunc(PANEL, "m_tData", "Data")
function PANEL:Init()
	self:SetSize(hexsize, hexsize)
	self.HoverLerp = noLerp
	self:Receiver('skilltreedragdrop', function(pnl, tbl, drop)
		if (!drop) then return end
		Derma_Query(
			"Are you sure you want to apply the node to your Skill Palette?\nYou will be able to unsocket the node, but at a price.",
			"Application Prompt",
			"Go ahead",
			function()
				chat.AddText( "Coming soon" )
			end,
			"NOOOO dont do it",
			function()
				chat.AddText( team.GetColor(0), "Cancelled node application." )
			end
		)
	end)
end
DEBUG_LABEL = true
function PANEL:Paint(w, h)
	draw.NoTexture()
	
	if (self:GetData() != nil) then
		surface.SetDrawColor(catcols[self.m_tData.cat])
		surface.DrawPoly(generateHexagonPoly(w / 2, h / 2, w / 2))
	--[[
		
		surface.SetDrawColor(catcols[self.Data.category])
		draw.NoTexture()
		surface.DrawPoly(generateHexagonPoly(w / 2, h / 2, w / 2))
	]]
	end

	surface.SetDrawColor(self.HoverLerp, self.HoverLerp, self.HoverLerp)
	surface.DrawPoly(
		generateHexagonPoly(
			w / 2,
			h / 2,
			w / 2 - 1
		)
	)
	if (not DEBUG_LABEL) then return end

	surface.SetFont("BudgetLabel")
	surface.SetTextPos(0, 0)
	surface.SetTextColor(255, 255, 255, 255)
	surface.DrawText(self:GetIDX() .. " " .. self:GetIDY())

	if (self:GetData() == nil) then return end
	-- todo: draw icon

end
local globalRolloverSoundCD = 0
function PANEL:Think()
	self.HoverLerp = Lerp(
		FrameTime() * 15,
		self.HoverLerp,
		self:IsHovered() and yesLerp or noLerp
	)

	if self:IsHovered() and not self.PlayedHoverSound  then
		self.PlayedHoverSound = true
		-- button15 is for drop
		-- button18 is for cannot afford/error
		-- button19 is for success / button5
		if SysTime() > globalRolloverSoundCD + 0.1 then
			surface.PlaySound('UI/buttonrollover.wav')
			globalRolloverSoundCD = SysTime()
		end
		local par = self:GetParent()
		-- self:GetParent() will probably always be hexgrid
		if (par:GetName() != "DTowerPaletteHexGrid") then
			return
		end
		par.HoveredDataTable = self:GetData()
	elseif (not self:IsHovered()) and self.PlayedHoverSound then
		self.PlayedHoverSound = nil
	end
end
vgui.Register("DTowerPaletteHex", PANEL, "DPanel")

local PANEL = {}
function PANEL:Init()
	self:SetSize(150, 150)
	self:Dock(BOTTOM)
	self:SetBackgroundColor(Color(100, 100, 130))

	self.HScroller = vgui.Create("DHorizontalScroller", self)
	self.HScroller:Dock(FILL)
	self.HScroller:DockMargin(4, 4, 4, 4)
	self.HScroller:SetOverlap(-4)
end
function PANEL:Populate()
	for i = 1, 3 do
		local lol = vgui.Create'DTowerPaletteInvItem'
		self.HScroller:AddPanel(lol)
	end
end
vgui.Register("DTowerPaletteInventory", PANEL, "DPanel")

local PANEL = {}
PANEL.Data = {
	category = 1,
	typeid = 1,
	augment = {}
}
function PANEL:Init()
	self:SetWide(140)
	self:SetBackgroundColor(Color(60, 60, 60))
	
	self.RealDraggable = vgui.Create("DButton", self)
	self.RealDraggable:SetSize(60, 60)
	self.RealDraggable:SetPos(self:GetWide() / 2 - 30, self:GetWide() / 2 - 30)
	self.RealDraggable:SetText''
	self.RealDraggable:Droppable'skilltreedragdrop'
	self.RealDraggable:SetTooltip("Augment of Deez")
	function self.RealDraggable.Paint(_, w, h)
		surface.SetDrawColor(catcols[self.Data.category])
		draw.NoTexture()
		surface.DrawPoly(generateHexagonPoly(w / 2, h / 2, w / 2))
		surface.SetDrawColor(40, 40, 40)
		surface.DrawPoly(generateHexagonPoly(w / 2, h / 2, w / 2 - 1))
	end
	function self.RealDraggable.DoRightClick()
		local rclick = DermaMenu()
		rclick:AddOption( "Upgrade", function()
			chat.AddText( "Coming soon..." )
		end ):SetIcon( "icon16/arrow_divide.png" )
		rclick:AddSpacer()
		rclick:AddOption( "Salvage", function()
			Derma_Query(
				"Are you sure you want to salvage this node?\nYou will NOT get this back. This is a one time option.",
				"Salvage Prompt",
				"Go ahead",
				function()
					chat.AddText( "Coming soon" )
				end,
				"NOOOO dont do it",
				function()
					chat.AddText( team.GetColor(0), "Cancelled node salvaging." )
				end
			)
		end ):SetIcon( "icon16/wrench.png" )
		--rclick:AddOption( "Remove", function()
		--	chat.AddText( "Coming soon..." )
		--end ):SetIcon( "icon16/delete.png" )
		rclick:Open()
	end
end
vgui.Register("DTowerPaletteInvItem", PANEL, "DPanel")

function GM:CreateSkillPalPanel()
	if IsValid(self.Palette) then
		self.Palette:Remove()
		self.Palette = nil
	end
	self.Palette = vgui.Create"DTowerSkillPalette"
	return self.Palette
end

hook.Add("OnPlayerChat", "skills", function(ply, txt)
	if txt != "!s" then return end

	GAMEMODE:CreateSkillPalPanel()
end)