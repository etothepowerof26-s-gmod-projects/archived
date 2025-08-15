
local Tag = "xpsys"

include'xpsys/sh_core.lua'
module(Tag, package.seeall)

local me 
local oldXP = 0
local newXP = 0
local lerp = 0
net.Receive(Tag_exp, function(len)
	if not me then me = LocalPlayer() return end
	oldXP = newXP
	lerp = oldXP
	if not me.GetExperience then 
	
include'xpsys/sh_core.lua'
return end
	newXP = me:GetExperience()
end)

local xpBar_visible = CreateConVar(Tag .. "_xpbar_visible", "1")

local function centertext(txt, x, y)
	local tw, th = surface.GetTextSize( txt )
	surface.SetTextPos(x - tw / 2, y - th / 2)
	surface.DrawText(txt)
end

PLAYER = FindMetaTable("Player")

hook.Add("HUDPaint", Tag, function()
	if not me then me = LocalPlayer() 
function me:GetLevel()
	return self:GetNWInt(Tag_level, 1)
end

function me:GetExperience()
	return self:GetNWFloat(Tag_exp, 0)
end

function me:ExpNeededToLevelUp()
	return LevelingFormula(self:GetLevel()) - self:GetExperience()
end
return end
	if not me.GetExperience then return end
	if not me.GetLevel then return end 
	local wantWidth = ScrW() * .25
	local wantHeight = 10

	local wantY = ScrH() * .25 * .25

	if xpBar_visible:GetBool() then
		local xp_wantWidth = wantWidth - 2
		local xp_wantHeight = wantHeight - 4

		draw.RoundedBoxEx(
			0,
			(ScrW() / 2) - (wantWidth / 2),
			(wantY - (wantHeight / 2)),
			wantWidth,
			wantHeight,
			Color(20, 20, 20, 120)
		)

		if newXP ~= nil then
			if lerp ~= nil then
				lerp = Lerp(0.1, lerp, newXP)
			end

			local div = LevelingFormula(me:GetLevel()) / lerp

			draw.RoundedBoxEx(
				0,
				(ScrW() / 2) - (xp_wantWidth / 2),
				(wantY - (xp_wantHeight / 2)),
				xp_wantWidth / div,
				xp_wantHeight,
				Color(0, 255, 255, 200)
			)
		end

		surface.SetFont("TargetID")
		surface.SetTextColor( color_white )
		centertext(string.format("%s / %s", newXP or 0, LevelingFormula(me:GetLevel()) ), ScrW() / 2, wantY + wantHeight + 2 )
		centertext(string.format("Level %s", me:GetLevel()), ScrW() / 2, wantY - wantHeight - 2)
		
		
		-- draw xp textbar near center of bar
	end
end)