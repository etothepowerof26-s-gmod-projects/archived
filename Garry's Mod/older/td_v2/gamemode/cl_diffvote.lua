surface.CreateFont("DiffShow", {
	size = 25,
	weight = 100,
	font = "Trebuchet",
	extended = false
})

surface.CreateFont("DiffName", {
	size = 30,
	weight = 800, 
	font = "Trebuchet",
	extended = false
})

local function DiffVote(duration)
	duration = duration or 30

	local frame = vgui.Create("DFrame")
	frame:SetSize(900, 400)
	frame:SetTitle""
	frame:Center()
	frame:SetDraggable(false)
	frame:MakePopup()
	frame:ShowCloseButton(false)

	local toreset = {}
	function frame:Paint(w,h)
		if not self.s then self.s = SysTime() end
		Derma_DrawBackgroundBlur(self, self.s)

		if SysTime() > self.s + duration then
			self:Remove()
			return
		end

		surface.SetDrawColor(60, 60, 60, 255)
		surface.DrawRect(0, 0, w, h)

		local perc = 1 - (SysTime() - self.s) / duration
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(0, 0, w, 10)

		surface.SetDrawColor(0, 255, 255)
		surface.DrawRect(0, 0, w * perc, 10)

		surface.SetFont("DiffName")
		local txt = "Choose your difficulty:"
		local tw, th = surface.GetTextSize(txt)
		surface.SetTextColor(255, 255, 0, 255)
		surface.SetTextPos(w / 2 - tw / 2, th / 2)
		surface.DrawText(txt)
	end

end

local PANEL = {}

function PANEL:Init()
	self:SetSize(900, 400)
	self:SetTitle("")
	self:SetDraggable(false)
	self:Center()
	self:MakePopup()
	self:ShowCloseButton(false)

	GAMEMODE.DifficultyVoter = self
end

function PANEL:SetDuration(duration)
	self.Start = SysTime()
	self.End = duration
end

function PANEL:Think()
	if not self.Start or not self.End then return end

	if not self.Built then
		self:BuildDifficultyPanels(GAMEMODE.IsUltra() == 'u')
	end

	if SysTime() - self.Start >= self.End then
		-- TODO: Remove the panel after showing the result.
		self:Remove()
		return
	end
end

function PANEL:BuildDifficultyPanels(isultra)
	self.Built = true

	local toreset = {}
	local function dp(name, color, desc, a, b, c, d)
		local dp1 = vgui.Create("DPanel", self)
		dp1:Dock(LEFT)
		dp1:SetWide(900 / 3 - 11) 
		dp1:DockMargin(4,24,4,4)
		dp1:SetBackgroundColor(Color(50, 50, 50))

		local DPanel = vgui.GetControlTable("DPanel")
		local offset = 280
		local stat = function(s, c, w, h)
			local tw, th = surface.GetTextSize(s)
			surface.SetTextColor(c) 
			surface.SetTextPos(w / 2 - tw / 2, th / 2 - 5 + offset)
			surface.DrawText(s)
			offset = offset - th - 5
		end

		function dp1.Paint(dpSelf, w, h)
			DPanel.Paint(dpSelf, w, h)

			surface.SetFont("DiffShow")

			local txt = name
			local tw, th = surface.GetTextSize(name)
			surface.SetTextColor(color) 
			surface.SetTextPos(w / 2 - tw / 2, th / 2 - 5)
			surface.DrawText(name)

			local tw, th = surface.GetTextSize(desc)
			surface.SetTextColor(color_white) 
			surface.SetTextPos(w / 2 - tw / 2, th / 2 +75)
			surface.DrawText(desc)

			stat(string.format("%s wave limit", d), Color(136, 255, 0), w, h)
			if c != 0 then
				stat(
					string.format(
						"%s%s%% Tower Costs",
						c < 0 and "-" or "+",
						math.abs(c)
					),
					Color(0, 183, 255),
					w,
					h
				)
			end
			stat(
				string.format(
					"%s Li%se%s",
					b,
					b == 1 and "f" or "v",
					b == 1 and "" or "s"
				),
				Color(255, 0, 128),
				w,
				h
			)
			if a != 0 then stat(string.format("%s%s%% Gold earned", a < 0 and "-" or "+", math.abs(a)), Color(255, 200, 0), w, h) end

			--offset = offset - 50
			--stat(desc, Color(200, 200, 200), w, h)

			-- print(offset)
			offset = 250
		end

		local percent = vgui.Create("DPanel", dp1)
		percent:Dock(BOTTOM)
		percent:DockMargin(2,2,2,2)

		local plsvote = vgui.Create("DButton", dp1)
		plsvote:Dock(BOTTOM)
		plsvote:DockMargin(2,2,2,2)
		plsvote:SetText("Vote for difficulty")
		function plsvote:DoClick()
			for k,v in pairs(toreset) do
				v:SetEnabled(true)
				v:SetText("Vote for difficulty")
			end
			self:SetEnabled(false)
			self:SetText("Voted") -- TODO: net.Start("tdUpdateVote")
		end

		print(dp1)

		table.insert(toreset, plsvote)

	end

	dp("Baby", Color(0, 255, 0), "Come on dude.", 100, 50, -100, 24)
	dp("Normal", Color(0, 170, 255), "How it was meant to be", 0, 25, 0, 48)
	dp("Hard", Color(255, 0, 0), "A challenge. Don't die!", -50, 8, 50, 72)
end

function PANEL:Paint(w, h)
	if not self.Start or not self.End then return end

	-- Derma_DrawBackgroundBlur(self, self.Start)

	surface.SetDrawColor(60, 60, 60, 255)
	surface.DrawRect(0, 0, w, h)

	local perc = 1 - (SysTime() - self.Start) / self.End
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(0, 0, w, 10)

	surface.SetDrawColor(0, 255, 255)
	surface.DrawRect(0, 0, w * perc, 10)

	surface.SetFont("DiffName")
	local txt = "Choose your difficulty:"
	local tw, th = surface.GetTextSize(txt)
	surface.SetTextColor(255, 255, 0, 255)
	surface.SetTextPos(w / 2 - tw / 2, th / 2)
	surface.DrawText(txt)
end

vgui.Register("tdDifficultyVoter", PANEL, "DFrame")

net.Receive("tdStartDiffVote", function()
	local duration = net.ReadUInt(16)

	local frame = vgui.Create("tdDifficultyVoter")
	frame:SetDuration(duration)
end)

print("s")