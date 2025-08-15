local Tag = "xpsys"

module(Tag, package.seeall)

Tag_level = Tag .. "_level"
Tag_exp = Tag .. "_exp"

PLAYER = FindMetaTable("Player")
LevelingFormula = function(lvl)
	return math.ceil(50 * (1.1 ^ (lvl - 1)))
end



function PLAYER:GetLevel()
	return self:GetNWInt(Tag_level, 1)
end

function PLAYER:GetExperience()
	return self:GetNWFloat(Tag_exp, 0)
end

function PLAYER:ExpNeededToLevelUp()
	return LevelingFormula(self:GetLevel()) - self:GetExperience()
end

if SERVER then
	function PLAYER:ChatPrintColor(...)
		local tab = {...}
		
		net.Start(Tag .. "ChatPrintColor")
		net.WriteTable(tab)
		net.Send(self)
	end
else
	net.Receive(Tag .. "ChatPrintColor", function(len)
		local tab = net.ReadTable()
		
		chat.AddText(unpack(tab))
	end)
end