local Tag = "xpsys"

module(Tag, package.seeall)

util.AddNetworkString(Tag_exp) -- for lerp experience
util.AddNetworkString(Tag .. "ChatPrintColor")

MaxLevel = CreateConVar(Tag .. "_maxlevel", "50", FCVAR_ARCHIVE)
function PLAYER:SetLevel(lvl)
	lvl = math.Clamp(tonumber(lvl), 0, MaxLevel:GetInt())

	self:SetNWInt(Tag_level, lvl)
end

function PLAYER:SetExperience(exp)
	exp = tonumber(exp)

	self:SetNWInt(Tag_exp, exp)
	self:UpdateExp()
end

function PLAYER:CanLevelUp()
	return self:ExpNeededToLevelUp() < 1
end

function PLAYER:UpdateExp()
	net.Start(Tag_exp)
	net.Send(self, true)
end

-- saving system
function InitDir()
	if not file.IsDir('xpsys', "DATA") then
		file.CreateDir('xpsys')
	end
end

function SaveData(ply)
	InitDir()
	
	local data = { level = ply:GetLevel(), exp = ply:GetExperience() }
	data = util.TableToJSON(data)
	
	local fname = ply:SteamID()
	fname = fname:gsub("%:", "_")
	fname = string.format("%s/%s.txt", Tag, fname)
	
	file.Write(fname, data)
	
	-- sanity check
	if not file.Exists(fname, "DATA") then
		ErrorNoHalt("player " .. tostring(ply) .. "'s data did not save. something bad happened!\n")
	else
		print(ply, "'s data saved")
	end
end

function LoadData(ply)
	InitDir()
	
	local fname = ply:SteamID()
	fname = fname:gsub("%:", "_")
	fname = string.format("%s/%s.txt", Tag, fname)
	
	if file.Exists(fname, "DATA") then
		local data = file.Read(fname, "DATA")
		data = util.JSONToTable(data)
		
		ply:SetLevel(data.level)
		ply:SetExperience(data.exp)
		ply:UpdateExp()
		
		print(ply, "data loaded successfully")
	else
		print(ply, "doesn't have data, saving")
	end
end

hook.Add("PlayerInitialSpawn", Tag, LoadData)