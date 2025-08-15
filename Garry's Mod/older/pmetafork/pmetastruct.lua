local Tag = "PMETASTRUCT"
PMETASTRUCT = { }

local me, Color, Vector, IsValid, pairs, ipairs,  error, tonumber, tostring, type, next 
	= LocalPlayer(), Color, Vector, IsValid, pairs, ipairs,  error, tonumber, tostring, type, next

local error  = function (m, n)
	_G.error("[" .. Tag .. "] " .. m, n)
end

local assert = function (condition, ...)
	if not condition then
		if next({...}) then
			local s, r = pcall(function (...)
					return(string.format(...)) 
				end, 
			...)
			if s then
				error("Assertion failed: " .. r, 2)
			end
		end
		error("Assertion failed!", 2)
	end
	return condition
end

local print = function ( ... )
	_G.print("[" .. Tag .. "]", ... )
end

local ChatPrint = function ( ... )
	chat.AddText( Color( 100, 100, 255 ), "[" .. Tag .. "] ", Color( 100, 255, 100 ), table.concat( {...}, " ") )
end

local timers = { }
local otc = timer.Create
timer.Create = function ( name, delay, reps, func )
	otc( name, delay, reps, func )
	timers[name] = true
end

local otd = timer.Destroy
timer.Destroy = function (name)
	otd(name)
	timers[name] = nil
end

timer.NewTimerExists = function (name)
	return timers[name]
end

timer.GetNewTimers = function ()
	return timers
end

_G.NewPTable = function() -- :D This giant global table is a meme..
	return setmetatable(
	{}, 
	{
		__newindex = function ( t, k, v )
			if t[k] then error("Can't delete "..Tag.." direct child entries D:") return end
			for sk, st in pairs(t) do
				if table.HasValue(st.ALIAS, k) then
					error("Can't create an index of an existant alias D:") 
					return
				end
			end
			v.super = t
			v.ALIAS = { } 
			rawset(t,k,v)
		end,
		__index = function ( t, v )
			for sk, st in pairs(t) do	
				if table.HasValue(st.ALIAS, v:lower()) then 
					return st
				end
			end
		
			local v1 = v:lower()
			local v2 = v:upper()
			local ks = table.GetKeys(t)
			
			-- avoid recursion D:
			if table.HasValue(ks, v1) then
				return t[v1]
			elseif table.HasValue(ks, v2) then
				return t[v2]
			end
		end
	} )
end

_G.OLDMETA = getmetatable(_G)
_G.META = {}
_G.META.__index = function(tbl, v)
	--if v:lower() == "didit" then say("did it=0.1*90") end
	if not PMETASTRUCT or not PMETASTRUCT.ALIAS then return end
	if PMETASTRUCT.ALIAS[v:lower()] then return PMETASTRUCT end
	for k, pv in pairs(PMETASTRUCT) do
		return pv[v] 
	end
end

_G = setmetatable(_G, _G.META)
_G["DestroyPMETASTRUCTAndAllItsBelovedChildrenThatOnceWalkedThisEarthInPeaceAndHarmony"] = function ()
	print"Destroying data..."
	PMETASTRUCT.DATA:Delete()
	
	print"Destroying hooks..."
	local hooks = hook.GetTable()
	for hid,hs in pairs(hooks) do
		for id in pairs(hs) do 
			if type(id) == "string" and #id > #Tag and string.sub(id, 1, #Tag) == Tag then
				hook.Remove( hid, id )
				print("Removed hook: "..hid..">"..id)
			end
		end
	end
	
	print"Destroying timers..."
	for id in pairs(timers) do
		if type(id) == "string" and #id > #Tag and string.sub(id, 1, #Tag) == Tag then
			timer.Destroy(id)
		end
	end
	
	print"Destroying temp data..."
	_G = setmetatable(_G, { })
	PMETASTRUCT = nil
	
	print"Completed - PMETASTRUCT Deletion!"
	LocalPlayer():ChatPrint"It has been done my child... PMETASTRUCT is no more."
end

PMETASTRUCT                                  = NewPTable()
PMETASTRUCT.TEMP                             = { }
PMETASTRUCT.CONFIG                           = { }
PMETASTRUCT.CONFIG.SHOOT_ASSIST              = true
PMETASTRUCT.CONFIG.RECOIL_ASSIST             = true
PMETASTRUCT.CONFIG.AIM_ASSIST                = true
PMETASTRUCT.CONFIG.HAX_AVOIDER               = true
PMETASTRUCT.CONFIG.VISUALISER_HOOK           = true
PMETASTRUCT.CONFIG.REVIVE_ME				 = true
PMETASTRUCT.CONFIG.AFK_ONTAB				 = true
PMETASTRUCT.CONFIG.TITLE_FUNC				 = function () end
PMETASTRUCT.CONSTANTS                        = { }
PMETASTRUCT.CONSTANTS.ALIAS                  = { "const", "finals", "guchivalues", "thingsdatdontchange" }
PMETASTRUCT.CONSTANTS.GC_LENGTH              = 126
PMETASTRUCT.CONSTANTS.PMC_LENGTH             = 220-9
PMETASTRUCT.CONSTANTS.TITLE_REFRESH_RATE     = 20
PMETASTRUCT.CONSTANTS.FORCE_GOTO_TIMEOUT     = 5
PMETASTRUCT.CONSTANTS.FORCE_GOTO_RETRY       = 3
PMETASTRUCT.CONSTANTS.TRIVIA_WAIT_TIME       = 15
PMETASTRUCT.CONSTANTS.CHAT_HISTORY_LIMIT     = 1000
PMETASTRUCT.CONSTANTS.CMD_HISTORY_LIMIT      = 1000
PMETASTRUCT.CONSTANTS.MENTION_HISTORY_LIMIT  = 1000
PMETASTRUCT.CONSTANTS.BIG_PRIME              = 1000000007
PMETASTRUCT.CONSTANTS.ID                     = 0x336E37C
PMETASTRUCT.ALIAS = { 
	["pm"] = "how it's good to be alive",
	["pmeta"] = "oh boi, oh boi.", 
	["pmt"] = "dank mehmes",
	["pmetastruct"] = "ahoy sailor",
}

-- LOAD AND SAVE DATA - .txt --/
-- works, not very good tho
PMETASTRUCT.DATA                        = { }
PMETASTRUCT.DATA.ALIAS                  = { "info", "knowledgeispower", "stuffthatgetsstored", "da" }
PMETASTRUCT.DATA.SAVE_CYCLE				= 60*5
PMETASTRUCT.DATA.TABLES                 = { }
PMETASTRUCT.DATA.TABLES.CMD_HISTORY     = { }
PMETASTRUCT.DATA.TABLES.BLACKLIST       = { }
PMETASTRUCT.DATA.TABLES.CHAT_HISTORY    = { }
PMETASTRUCT.DATA.TABLES.MENTION_HISTORY = { }
PMETASTRUCT.DATA.path                   = "pmetastruct_data.txt"

function PMETASTRUCT.DATA:Save()
	local mega_data = { }
	
	for k, t in pairs(self.TABLES) do
		if type(t) == "table" then
			print("Saving " .. k .."...")
			mega_data[k] = table.Copy(t) or { }    
		end
	end
	
	file.Write( self.path, util.TableToKeyValues(mega_data) )
	PMETASTRUCT.UTIL:PrintPM("Saved " .. Tag .. " data! [" .. self.path .. "]")
end

function PMETASTRUCT.DATA:Load()
	if not file.Exists(self.path, "DATA") then
		PMETASTRUCT.UTIL:PrintPM("No data file found! [" .. self.path .. "]")
		return
	end
	
	local kvalues = file.Read( self.path, "DATA" )
	local mega_data = util.KeyValuesToTable(kvalues)
	for k, t in pairs(self.TABLES) do
		if type(t) == "table" then
			PMETASTRUCT.DATA.TABLES[k] = table.Copy(mega_data[k]) or { }   
		end
	end
	PMETASTRUCT.UTIL:PrintPM("Loaded ".. Tag .. " data! [" .. self.path .. "]")
end

function PMETASTRUCT.DATA:Delete()
	if file.Exists(self.path, "DATA") then
		file.Write(self.path, "")
		PMETASTRUCT.UTIL:PrintPM("Deleted " .. Tag .. " data! [" .. self.path .. "]")
	else
		PMETASTRUCT.UTIL:PrintPM("Could not find file for " .. Tag .. " data! [" .. self.path .. "]")
	end
end

timer.Create(Tag.."_save", PMETASTRUCT.DATA.SAVE_CYCLE, 0, function ()
	PMETASTRUCT.DATA:Save()
end)

-- PMETASTRUCT UTIL Functions  --
PMETASTRUCT.UTIL        = { }
PMETASTRUCT.UTIL.ALIAS  = { "funcs", "methods", "libraryofstuff", "utility", "ut" }

function PMETASTRUCT.UTIL:TrenaryCall( cond, T, F, ... )
	if cond then return T(...) else return F(...) end
end

function PMETASTRUCT.UTIL:SinWave( speed, size, ab )
	local sin = math.sin( RealTime() * ( speed or 1 ) ) * (size or 1)
	if ( ab ) then sin = math.abs( sin ) end 
	return sin
end

function PMETASTRUCT.UTIL:Round(num, dps)
	local shift = 10 ^ dps
	return math.floor( num*shift + 0.5 ) / shift
end

function PMETASTRUCT.UTIL:SecondsToClock(seconds)
	seconds = tonumber(seconds)
	if (seconds == nil) then seconds = 0 end
	if seconds <= 0 then
		return "00:00:00"
	else
		local hours = string.format("%02.f", math.floor(seconds/3600))
		local mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)))
		local secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60))
		return hours..":"..mins..":"..secs
	end
end 

function PMETASTRUCT.UTIL.SecondsToWords(seconds)
	seconds = tonumber(seconds)
	if (seconds == nil) then seconds = 0 end
	if seconds <= 0 then
		return "00:00:00"
	else
		local hours = string.format("%02.f", math.floor(seconds/3600))
		local mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)))
		local secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60))
		return hours.." hours "..mins.." minutes and "..secs.." seconds"
	end
end 

function PMETASTRUCT.UTIL:Returnf( ... )
	local function wrapper(...) 
		return (string.format(...))
	end
	local status, result = pcall(wrapper, ...)
	if not status then
		print("Format for Returnf not recognised. Returning string instead. [" .. result .. "]")
		return ...
	end
	return result
end

function PMETASTRUCT.UTIL:PrintPM( ... )
	local str = self:Returnf( ... )
	local t = self:SmartChatSplit(str, PMETASTRUCT.CONSTANTS.PMC_LENGTH)
	for i=1, #t do
		if i == 1 then
			pmail.Send( {receiver=me:SteamID(), msg=t[i]} )
		else
			timer.Simple(1, function ()
				pmail.Send( {receiver=me:SteamID(), msg=t[i]} )
			end)
		end
	end
end

function PMETASTRUCT.UTIL:SendPM( ... )
  local args = { ... }
  local ply  = args[#args]
  args[#args]= nil
  local str  = self:Returnf( unpack(args) )
	local t    = self:SmartChatSplit(str, PMETASTRUCT.CONSTANTS.PMC_LENGTH)
	for i=1, #t do
		if i == 1 then
			pmail.Send( {receiver=ply:SteamID(), msg=t[i]} )
		else
			timer.Simple(1, function ()
				pmail.Send( {receiver=ply:SteamID(), msg=t[i]} )
			end)
		end
	end
end

function PMETASTRUCT.UTIL:IndexError(err, index)
	return string.format("%s at index %d.", err, index)
end

function PMETASTRUCT.UTIL:toBoolean(v)
	return (type(v) == "string" and v == "true") or
		   (type(v) == "number" and v ~= 0) or
		   (type(v) == "boolean" and v)
end

function PMETASTRUCT.UTIL:IsWhitespace(str)
	local c = 0
	for w in str:gmatch("%S+") do c = c + 1 end
	return c == 0
end

function PMETASTRUCT.UTIL:IsChar(str)
	local s = str:lower()
	local alphabet = "abcdefghijklmnopqrstuvwxyz"
	return alphabet:find(s) ~= nil
end

function PMETASTRUCT.UTIL:IsNum(str)
	local num_chars = "0123456789-."
	return num_chars:find(str) ~= nil
end

function PMETASTRUCT.UTIL:Split(s, sep)
	local fields = {}
	local sep = sep or " "
	local pattern = string.format("([^%s]+)", sep)
	
	string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)
	return fields
end


function PMETASTRUCT.UTIL:ClearPatternChars(str)
	for _,v in pairs(self.BANNED_CHARS) do
		str = string.Replace(str, v, "")
	end
	return str
end

-- Value, decimal, 0..1 (similarity)
-- Currently, Longest Common Substring algorithm on one of the strings and the other string appended to itself once
function PMETASTRUCT.UTIL:StringSimilar(str1, str2)
	if #str1 == 0 and #str2 == 0 then
		return 1
	end
	
	if #str1 == 0 or #str2 == 0 then
		return 0
	end
	
	local str1str1 = string.rep(str1, 2)
	print(str1, str2)
	local lcstring = self:LongestCommonSubstring( str1str1, str2 )
	local len = #lcstring
	
	-- We need it not longer than str1 (e.g. "aircon")
	-- since we're actually comparing str1 and str2
	if (len > #str1) then len = #str1 end

	len = len * 2
	print(len)
	-- Prevent 100% similarity between a string and its
	-- cyclically shifted version (e.g. "aircon" and "conair")
	if (len == #str1 + #str2 and str1 ~= str2 ) then len = len - 1 end
	
	print(len, #str1+#str2)
	-- Get the final measure of the similarity
	return len / (#str1 + #str2)
end

-- Return a value between 0 and 1 for the similarity of 'fx' with 'fy'.
-- 1 means identical strings, 0 completely different strings
PMETASTRUCT.UTIL.BANNED_CHARS = { ".", "%", "+", "*", "-", "?", "[", "]" }
function PMETASTRUCT.UTIL:MatchingSimilarity( str1, str2 )
	str1 = self:ClearPatternChars(str1)
	str2 = self:ClearPatternChars(str2)

	local n = #str1
	local m = #str2
	local ssnc = 0

	if n > m then
		str1, str2 = str2, str1
		n, m = m, n
	end

	for i = n, 1, -1 do
		if i <= #str1 then
			for j = 1, n-i+1, 1 do
				local pattern = string.sub(str1, j, j+i-1)
				if #pattern == 0 then break end
				print(pattern)
				local found_at = string.find(str2, pattern)
				if found_at ~= nil then
					ssnc = ssnc + (2*i)^2
					str1 = string.sub(str1, 0, j-1) .. string.sub(str1, j+i)
					str2 = string.sub(str2, 0, found_at-1) .. string.sub(str2, found_at+i)
					break
				end
			end
		end
	end

	return (ssnc/((n+m)^2))^(1/2)
end

--[[
The longest suffix matrix matrix[][] is build up and the index of the cell having the maximum value is tracked. 
Let that index be represented by (row, col) pair. Now the final longest common substring is build with the help
of that index by diagonally traversing up the matrix[][] matrix until matrix[row][col] ~= 0 and during the 
iteration obtaining the characters either from str1[row-1] or str2[col-1] and adding them from right to left in the
resultant common string.
]]
function PMETASTRUCT.UTIL:LongestCommonSubstring( str1, str2 )
	local m,n    = #str1, #str2
	local matrix = { }
	for i=1, m+1, 1 do
		matrix[i] = {}
		for j=1, n+1, 1 do
			matrix[i][j] = 0
		end
	end
	
	local len  = 0
	local row, col
	
	for i=1, m+1, 1 do
		for j=1, n+1, 1 do
			if (i == 1 or j == 1) then
				matrix[i][j] = 0
			elseif (str1[i - 1] == str2[j - 1]) then
				matrix[i][j] = matrix[i - 1][j - 1] + 1
				if (len < matrix[i][j]) then 
					len = matrix[i][j]
					row = i
					col = j
				end
			else
				matrix[i][j] = 0
			end
		end
	end
 
	-- if true, then no common substring exists
	if (len == 0) then
		return { }
	end
	
	local result = { }
	while (matrix[row][col] ~= 0) do
		result[len] = str1[row - 1] -- or sr2[col-1]
 
		-- move diagonally up to previous cell
		row = row - 1
		col = col - 1
		len = len - 1
	end
	
	return result
end

-- Displacement of Characters in strings
function PMETASTRUCT.UTIL:LevenshteinDistance(s, t)
  if #s == 0 and #t == 0 then
	return "empty strings"
  end
  
	local minimum = function (a, b, c)
		local smallest = a
		if (smallest > b) then smallest = b end
		if (smallest > c) then smallest = c end
		return smallest
	end
	-- for all i and j, d[i][j] will hold the Levenshtein distance between
	-- the first i characters of s and the first j characters of t
	-- note that d has (#s+1)*(#t+1) values
	local d = { }
	for i=1, #s-1, 1 do
		d[i] = {}
		for j=1, #t+1, 1 do
			d[i][j] = 0
		end
	end
  
	-- source prefixes can be transformed into empty string by
	-- dropping all characters
	for i=2, #s-1, 1 do
		d[i][1] = i
	end
	
	-- target prefixes can be reached from empty source prefix
	 -- by inserting every character
	for j=2, #t-1, 1 do
		d[1][j] = j
	end
 
	local substitutionCost = 0
	for j=2, #t-1, 1 do
		for i=2, #s-1, 1 do
			if s[i] == t[j] then
				substitutionCost = 0
			else
				substitutionCost = 1
				d[i][j] = minimum( d[i-1][j] + 1,                     -- deletion
									d[i][j-1] + 1,                    -- insertion
									d[i-1][j-1] + substitutionCost)  -- substitution
			end
		end
	end

	return d[#s-1][#t-1]
end

-- Builds a magic square of size n sides.
function PMETASTRUCT.UTIL:OddMagicSquare( n )
	local magic_square = {}
	for j = 1, n do
		table.insert( magic_square, {} )
		for i = 1, n do
			table.insert( magic_square[j], 0 )
		end
	end
	
	if n % 2 == 0 then 
		n = n + 1
	end
	
	local p = 1
	local i, j, ti, tj = 1 + math.floor( n / 2 ), 1
	
	while( p <= n * n ) do
		magic_square[i][j] = p
		ti = i + 1 if ti > n then ti = 1 end
		tj = j - 1 if tj < 1 then tj = n end
		if magic_square[ti][tj] ~= 0 then
			ti = i tj = j + 1
		end
		i = ti j = tj p = p + 1
	end
   
	return magic_square, n
end

-----------     Num  <--->  Words
local num = {
	'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'eleven',
	'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen'
}

local tens = {
	'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'
}

local bases = {
	{math.floor(1e18), ' quintillion'}, 
	{math.floor(1e15), ' quadrillion'}, 
	{math.floor(1e12), ' trillion'},
	{math.floor(1e9), ' billion'}, 
	{1000000, ' million'}, 
	{1000, ' thousand'}, 
	{100, ' hundred'}
}

local insert_word_AND = false  -- 101 = "one hundred and one" / "one hundred one"

function PMETASTRUCT.UTIL:NumToWords(n)
	-- Returns a string (spelling of integer number n)
	-- n should be from -2^53 to 2^53  (-2^63 < n < 2^63 for integer argument in Lua 5.3)
	local str = {}
	if n < 0 then
		table.insert(str, "minus")
	end
	
	n = math.floor(math.abs(n)) 
	
	if n == 0 then
		return "zero"
	end
	
	if n >= 1e21 then
		table.insert(str, "infinity")
	else
		local AND
		for _, base in ipairs(bases) do
			local value = base[1]
			if n >= value then
				table.insert(str, self:NumToWords(n / value)..base[2])
				n, AND = n % value, insert_word_AND or nil
			end
		end
		if n > 0 then
			table.insert(str, AND and "and") -- a nice pun !
			table.insert(str, num[n] or tens[math.floor(n/10)-1]..(n%10 ~= 0 and '-'..num[n%10] or ''))
		end
	end
	
	return table.concat(str, ' ')
end

function PMETASTRUCT.UTIL:WordsToNum(number_as_text)
	number_as_text = number_as_text:lower():gsub("%W", "")
	for i = 1, 50 do
		if self:NumToWords(i):lower():gsub("%W", "") == number_as_text then
			return i
		end
	end
end

function PMETASTRUCT.UTIL:FindPlayerByName(str)
	if not isstring(str) then return nil end
	
	local rply, strv = nil, 0
	for k,v in pairs( player.GetAll() ) do
		if not IsValid(v) then continue end
		local cv = self:StringSimilar(str, v:ProperNick())
		print(cv, "<- similarity between", str, v:ProperNick())
		if cv > strv then
			strv = cv
			rply = v
		end
	end

	return rply, strv
end

function PMETASTRUCT.UTIL:FindEnt(str)
	local target = nil
	-- Try by index
	if isnumber(tonumber(str)) then
		target = ents.GetByIndex(tonumber(str))
	end
	
	return target or self:FindPlayerByName(str)
end

function PMETASTRUCT.UTIL:StringToGChat(str)
	if #str < PMETASTRUCT.CONSTANTS.GC_LENGTH then return str end
	local ap = "(...)"
	return string.sub(str, 1, PMETASTRUCT.CONSTANTS.GC_LENGTH-#ap ) .. ap
end

function PMETASTRUCT.UTIL:GCPrint(str)
	RunConsoleCommand("say", self:StringToGChat(str))
end

function PMETASTRUCT.UTIL:FindPlayersInSphere(pos, rad)
	local plys = { }
	for k,v in pairs(ents.FindInSphere( pos, rad )) do
		if IsValid(v) and v:IsPlayer() then
			table.insert(plys, v)
		end
	end
	
	return plys
end

function PMETASTRUCT.UTIL:FindDevsInSphere(pos, rad)
	local devs = { }
	for k,v in pairs(ents.FindInSphere( pos, rad )) do
		if IsValid(v) and v:IsPlayer() and v:GetUserGroup() == "developers" then
			table.insert(devs, v)
		end
	end
	
	return devs
end

function PMETASTRUCT.UTIL:FindFriendsInSphere(pos, rad, ply)
  	local fnds = { }
  	for k,v in pairs(ents.FindInSphere( pos, rad )) do
		if IsValid(v) and v:IsPlayer() and v:PartialFriends(ply) then
			table.insert(fnds, v)
		end
	end
	
	return fnds
end
-- expensive function - keep t small.
function PMETASTRUCT.UTIL:Filter( t, func )
	local data = func()
  
	if type(data) ~= "table" then 
		error("Function to filter doesn't return a table!")
  	end
  
  	for k,v in pairs(t) do
		for k2, v2 in pairs( data ) do
	  		if v == v2 then
				data[k2] = nil
	  		end
		end
	end

	return data
end

PMETASTRUCT.TEMP.last_goto = nil
function PMETASTRUCT.UTIL:Goto(loc)
	RunConsoleCommand("aowl", "goto", loc )
	PMETASTRUCT.TEMP.last_goto = loc
end

local matches = { "u%d%w%w%w", "u%w%d%w%w", "u%w%w%d%w", "u%w%w%w%d" }
local html_entity = { -- only the ones we want, lookup table would be massive
	["&amp"]    = "&",
	["&apos"]   = "'",
	["&gt"]     = ">",
	["&lt"]     = "<",
	["&quot"]   = "\"",
	["&copy"]   = "©",
	["&copy"]   = "§",
	["&plusmn"] = "±",
	["&deg"]    = "°",
	["&lsquo"]  = "‘",
	["&rsquo"]  = "’",
	["&trade"]  = "™",
	["&euro"]   = "€",
	["&asymp"]  = "≈",
}
function PMETASTRUCT.UTIL:BadString(str) -- turns unicode literals of form u%d%d%d. to hex then to char
	for k,v in pairs(matches) do
		local replace = string.match(str, v)
		if replace then
			local char = utf8.char(tonumber("0x"..replace:sub(2)))
			str = string.Replace(str, replace, char)
		end
	end
	
	for k,v in pairs(html_entity) do
		str = string.Replace(str, k, v)
	end
	
	while( string.find(str, "&") ) do
		local s = string.find(str, "&")
		local e = string.find(str, "")
		local replace = string.sub(str, s, e)
		str = string.Replace(str, replace, "")
	end
	
	while( string.find(str, "<") ) do
		local s = string.find(str, "<")
		local e = string.find(str, ">")
		local replace = string.sub(str, s, e)
		str = string.Replace(str, replace, "")
	end
	
	str = string.Replace(str, "\\", "")
	return str
end

function PMETASTRUCT.UTIL:SmartChatSplit(str, MAX_LENGTH)
	if #str <= MAX_LENGTH then return { str } end
   
	local WhereToSplit = function (str)
		str = str:reverse()
		local t = { ",", "%.", "", "-", "!", "?" }
		local s, e = #str+1,#str+1
		for _,v in pairs(t) do
			local si, ei = string.find( str, v )
			if si == nil or ei == nil then continue end
			if (si < s) then
				s = si 
			end
		end
		return s
	end
  
	local r = {}
	while (#str >= MAX_LENGTH) do
		local i = MAX_LENGTH-WhereToSplit(string.sub(str, 1, MAX_LENGTH))
		local savestr = string.sub(str, 1, i+1)
		str = string.sub( str, i+2 )
		table.insert(r, savestr:Trim())
	end
  
	table.insert(r, str:Trim())
	return r
end

function PMETASTRUCT.UTIL:GlobalChatSay( ... )
	local str = self:Returnf( ... )
	local t = self:SmartChatSplit(str, PMETASTRUCT.CONSTANTS.GC_LENGTH)
	for i=1, #t do
		if i == 1 then
			RunConsoleCommand("say", t[i])
		else
			timer.Simple(1, function ()
				RunConsoleCommand("say", t[i])
			end)
		end
	end
end

function PMETASTRUCT.UTIL:LocalChatSay( ... )
	local str = self:Returnf( ... )
	local t = self:SmartChatSplit(str, PMETASTRUCT.CONSTANTS.GC_LENGTH)
	for i=1, #t do
		if i == 1 then
			RunConsoleCommand("say_local", t[i])
		else
			timer.Simple(1, function ()
				RunConsoleCommand("say_local", t[i])
			end)
		end
	end
end

function PMETASTRUCT.UTIL:TTSSay( ... )
	local str = self:Returnf( ... )
	local t = self:SmartChatSplit(str, PMETASTRUCT.CONSTANTS.GC_LENGTH)
	PrintTable(t)
	local s = 0
	for i=1, #t do
		if i == 1 then
			me:ConCommand("say_local !tts " .. t[i])
		else
			--[[
			for token in string.gmatch(line,'%w+') do
				print (token)
			end ]]
			s = s + (#t[i-1])/16 -- change this soon to account for the length of pauses ", -, ." etc AND NUMBERS [ CONVERT TO TEXT! ]
			print(s, "HERE")
			timer.Simple(s, function()
				me:ConCommand("say_local !tts " .. t[i])
			end)
		end
	end
end

function PMETASTRUCT.UTIL:EntityAimData(v)
	local angledifference = function (a, b)
		return math.abs(a.y - b.y)
	end
	
	local isinfov = function (dist)
		if dist <= 60 then 
			return true
		else
			return false
		end
	end
	
	local rollover = function (n, min, max)
		while true do
			if n > max then
				n = min + n - max
			elseif n < min then
				n = max - min - n
			else
				return n
			end
		end
	end
	
	local head = v:LookupBone("ValveBiped.Bip01_Head1")
	local spine = v:LookupBone("ValveBiped.Bip01_Spine2")
	local origin = v:GetPos() + v:OBBCenter()
	local headpos = Vector(0, 0, 0)
	
	if head then
		headpos = v:GetBonePosition(head)
	elseif spine then
		headpos = v:GetBonePosition(spine)
	else
		headpos = origin
	end
	
	local scrpos = headpos:ToScreen()
	local tracedat = {}
	tracedat.start = me:GetShootPos()
	tracedat.endpos = headpos
	tracedat.mask = MASK_SHOT
	tracedat.filter = me
	
	local trac = util.TraceLine(tracedat)
	local dmg = 0
	local angdis = angledifference(me:EyeAngles(), (headpos - me:GetShootPos()):Angle())
	local distocenter = math.abs(rollover(angdis, -180, 180))
	local distoplayer = me:GetPos():DistToSqr(v:GetPos())
	
	if isinfov(distocenter) then
		if (trac.Entity == NULL or trac.Entity == v) or ignoreblocked == 0 then
			return {
				['ply'] = v,
				['source_pos'] = scrpos, 
				['center_distance'] = distocenter, 
				['headpos'] = headpos, 
				['dmg'] = dmg, 
				['distance_to_me'] = distoplayer^0.5,
			}
		end
	end
	
	return nil
end

--[[
	txt = string.Replace("#closest", )
	txt = string.Replace("#furthest", )
	txt = string.Replace("#richest", )
	txt = string.Replace("#longestonline", )
	txt = string.Replace("#laggiest", )
]]

function PMETASTRUCT.UTIL:ReplaceInArray( arr, re, pl )
	if not re or not pl then return arr end
	for k,v in pairs(arr) do
		arr[k] = string.Replace( arr[k], re, pl )
	end
	return arr
end

function PMETASTRUCT.UTIL:ClosestToPlayer( ply )
	local rply, ldis = nil, inf
	for k,v in pairs(player.GetAll()) do
		if v == ply then continue end
		local d = ply:GetPos():DistToSqr(v:GetPos())
		if d < ldis then
			rply = v
			ldis = d 
		end
	end
	return rply or ply
end

function PMETASTRUCT.UTIL:FurthestToPlayer( ply )
	local rply, ldis = nil, 0
	for k,v in pairs(player.GetAll()) do
		if v == ply then continue end
		local d = ply:GetPos():DistToSqr(v:GetPos())
		if d > ldis then
			rply = v
			ldis = d 
		end
	end
	return rply or ply
end

function PMETASTRUCT.UTIL:RichestPlayer()
	local t = player.GetAll()
	table.sort(t, function (p1, p2)
		return p1:GetCoins() > p2:GetCoins()
	end)
	return t[1]
end

function PMETASTRUCT.UTIL:LongestOnlinePlayer()
	local t = player.GetAll()
	table.sort(t, function (p1, p2)
		return p1:GetUTimeSessionTime() > p2:GetUTimeSessionTime()
	end)
	return t[1]
end

function PMETASTRUCT.UTIL:LaggiestPlayer()
	local t = player.GetAll()
	table.sort(t, function (p1, p2)
		return p1:Ping() > p2:Ping()
	end)
	return t[1]
end

function PMETASTRUCT.UTIL:LongestAFKPlayer()
	local t = player.GetAll()
	table.sort(t, function (p1, p2)
		local t1, t2 = p1:AFKTime(), p2:AFKTime()
		t1, t2 = t1 >= 0 and t1 or 0, t2 >=0 and t2 or 0
		return t1 > t2
	end)
	return t[1]
end

function PMETASTRUCT.UTIL:RandomPlayer()
	local t = player.GetAll()
	return t[math.random(1, #t)]
end

function PMETASTRUCT.UTIL:RandomDev()
	local t = player.GetAll()
	local devs = { }
	for k,v in pairs(t) do
		if v:GetUserGroup() == "developers" then
			table.insert(devs, v)
		end
	end
	return devs[math.random(1, #devs)]
end

function PMETASTRUCT.UTIL:LaggiestPlayer()
	local t = player.GetAll()
	table.sort(t, function (p1, p2)
		return p1:Ping() > p2:Ping()
	end)
	return t[1]
end

function PMETASTRUCT.UTIL:CmpPlayer( cmpfunc )
	local t = player.GetAll()
	table.sort(t, cmpfunc)
	return t[1]
end

function PMETASTRUCT.UTIL:This( ply )
	local tdata = ply:GetEyeTrace()
	local ent = tdata.Entity
	return ent
end

function PMETASTRUCT.UTIL:HttpRequest( url, method, parameters, headers, success, failed )
	return HTTP({
		url        = url,
		method     = method,
		parameters = parameters,
		headers    = headers,
		success    = success,
		failed     = failed,
	})
end

function PMETASTRUCT.UTIL:StringStackData()
	local sdata = debug.getinfo(2, "fnlSu")
	return " at line " .. sdata.currentline .. " of " .. tostring(sdata.func) ..  "[Params #" .. sdata.nparams.."]"
end

--/ JSON <-> Lua Table --
PMETASTRUCT.JSON = { }
PMETASTRUCT.JSON.ALIAS  = { "jayson", "jaison", "j-son", "jandson", "thejtheathestheothes", "js" }
function PMETASTRUCT.JSON:KindOf(obj)
	if type(obj) ~= 'table' then return type(obj) end
	local i = 1
	for _ in pairs(obj) do
		if obj[i] ~= nil then i = i + 1 else return 'table' end
	end
	if i == 1 then return 'table' else return 'array' end
end

function PMETASTRUCT.JSON:EscapeStr(s)
	local in_char  = {'\\', '"', '/', '\b', '\f', '\n', '\r', '\t'}
	local out_char = {'\\', '"', '/',  'b',  'f',  'n',  'r',  't'}
	for i, c in ipairs(in_char) do
		s = s:gsub(c, '\\' .. out_char[i])
	end
	 return s
end

-- Returns pos, did_find there are two cases:
-- 1. Delimiter found: pos = pos after leading space + delim did_find = true.
-- 2. Delimiter not found: pos = pos after leading space     did_find = false.
-- This throws an error if err_if_missing is true and the delim is not found.
function PMETASTRUCT.JSON:SkipDelim(str, pos, delim, err_if_missing)
	pos = pos + #str:match('^%s*', pos)
	if str:sub(pos, pos) ~= delim then
	  if err_if_missing then
		error('Expected ' .. delim .. ' near position ' .. pos)
	  end
	  return pos, false
	end
	return pos + 1, true
end

-- Expects the given pos to be the first character after the opening quote.
-- Returns val, pos the returned pos is after the closing quote character.
function PMETASTRUCT.JSON:ParseStrVal(str, pos, val)
	val = val or ''
	local early_end_error = 'End of input found while parsing string.'
	if pos > #str then error(early_end_error) end
	local c = str:sub(pos, pos)
	if c == '"'  then return val, pos + 1 end
	if c ~= '\\' then return self:ParseStrVal(str, pos + 1, val .. c) end
  -- We must have a \ character.
	local esc_map = {b = '\b', f = '\f', n = '\n', r = '\r', t = '\t'}
	local nextc = str:sub(pos + 1, pos + 1)
	if not nextc then error(early_end_error) end
	return self:ParseStrVal(str, pos + 2, val .. (esc_map[nextc] or nextc))
end

-- Returns val, pos the returned pos is after the number's final character.
function PMETASTRUCT.JSON:ParseNumVal(str, pos)
	local num_str = str:match('^-?%d+%.?%d*[eE]?[+-]?%d*', pos)
	local val = tonumber(num_str)
	if not val then error('Error parsing number at position ' .. pos .. '.') end
	return val, pos + #num_str
end

-- Public values and functions.
function PMETASTRUCT.JSON:Stringify(obj, as_key)
	local s = {}  -- We'll build the string as an array of strings to be concatenated.
	local kind = self:KindOf(obj)  -- This is 'array' if it's an array or type(obj) otherwise.
	if kind == 'array' then
		if as_key then error('Can\'t encode array as key.') end
		 s[#s + 1] = '['
		for i, val in ipairs(obj) do
			if i > 1 then s[#s + 1] = ', ' end
			s[#s + 1] = self:Stringify(val)
		end
		s[#s + 1] = ']'
	elseif kind == 'table' then
		if as_key then error('Can\'t encode table as key.') end
		s[#s + 1] = '{'
		for k, v in pairs(obj) do
			if #s > 1 then s[#s + 1] = ', ' end
			s[#s + 1] = self:Stringify(k, true)
			s[#s + 1] = ':'
			s[#s + 1] = self:Stringify(v)
		end
		s[#s + 1] = '}'
	elseif kind == 'string' then
		return '"' .. self:EscapeStr(obj) .. '"'
	elseif kind == 'number' then
		if as_key then return '"' .. tostring(obj) .. '"' end
		return tostring(obj)
	elseif kind == 'boolean' then
		return tostring(obj)
	elseif kind == 'nil' then
		return 'null'
	else
		error('Unjsonifiable type: ' .. kind .. '.')
	end
	return table.concat(s)
end

PMETASTRUCT.JSON.null = { } -- This is a one-off table to represent the null value.

function PMETASTRUCT.JSON:Parse(str, pos, end_delim)
	pos = pos or 1
	if pos > #str then error('Reached unexpected end of input.') end
	local pos = pos + #str:match('^%s*', pos)  -- Skip whitespace.
	local first = str:sub(pos, pos)
	if first == '{' then  -- self:Parse an object.
		local obj, key, delim_found = {}, true, true
		pos = pos + 1
		while true do
			key, pos = self:Parse(str, pos, '}')
		  if key == nil then return obj, pos end
		  if not delim_found then error('Comma missing between object items.') end
		  pos = self:SkipDelim(str, pos, ':', true)  -- true -> error if missing.
		  obj[key], pos = self:Parse(str, pos)
		  pos, delim_found = self:SkipDelim(str, pos, ',')
		end
	elseif first == '[' then  -- self:Parse an array.
		local arr, val, delim_found = {}, true, true
		pos = pos + 1
		while true do
			val, pos = self:Parse(str, pos, ']')
			if val == nil then return arr, pos end
			if not delim_found then error('Comma missing between array items.') end
			arr[#arr + 1] = val
			pos, delim_found = self:SkipDelim(str, pos, ',')
		end
	elseif first == '"' then  -- self:Parse a string.
		return self:ParseStrVal(str, pos + 1)
	elseif first == '-' or first:match('%d') then  -- self:Parse a number.
		return self:ParseNumVal(str, pos)
	elseif first == end_delim then  -- End of an object or array.
		return nil, pos + 1
	else  -- self:Parse true, false, or null.
		local literals = {['true'] = true, ['false'] = false, ['null'] = self.null}
		for lit_str, lit_val in pairs(literals) do
			local lit_end = pos + #lit_str - 1
			if str:sub(pos, lit_end) == lit_str then return lit_val, lit_end + 1 end
		end
		local pos_info_str = 'position ' .. pos .. ': ' .. str:sub(pos, pos + 10)
		error('Invalid json syntax starting at ' .. pos_info_str)
	end
end

-- CHAT CMDS AND API METHODS --/
PMETASTRUCT.APIS        = { }
PMETASTRUCT.APIS.ALIAS  = { "netstuff", "fetch", "as", "gimmegimme" }
PMETASTRUCT.APIS.KEYS   = { 
   -- ['oxford_dictionary'] = "8c6f6dc586216251fa396a9d4fd79cb2",
   ["open_weather"] = "2ab06783908172e9e0408fc26fb969f7",
   ["ldetect"]      = "f3d4ba4d759ffa48f27e9fa40ccee29f",
   ["google"]       = "AIzaSyDFwjTpEy-Ddbw-yHrJvCzEyIAFwNDLiBk",
}

function PMETASTRUCT.APIS:LanguageDetect(str, cbfunc)
	str = string.Replace( str, " ", "%" )
	http.Fetch( "http://apilayer.net/api/detect?access_key="..self.KEYS["ldetect"].."&query="..str,
	function( body, len, headers, code )
		local t = self.super.JSON:Parse(body, 1, "}")
		cbfunc(t)
	end, 
	function( error )
		self.super.UTIL:PrintPM("Error fetching from api " .. PMETASTRUCT.UTIL:StringStackData())
	end)   
end

function PMETASTRUCT.APIS:TranslateText(from, to, str, cbfunc)
	str = string.Replace( str, " ", "+" )
	http.Fetch( "https://www.googleapis.com/language/translate/v2?key="..PMETASTRUCT.APIS.KEYS.google.."&source="..from.."&target="..to.."&q="..str,
	function( body, len, headers, code )
		local t = self.super.JSON:Parse(body, 1, "}")
		cbfunc(t)
	end, 
	function( error )
		self.super.UTIL:PrintPM("Error fetching from api " .. PMETASTRUCT.UTIL:StringStackData())
	end)
end

function PMETASTRUCT.APIS:WeatherData(str, cbfunc)
	str = string.Replace( str, " ", "," )
	http.Fetch( "http://api.openweathermap.org/data/2.5/weather?q="..str.."&appid="..self.KEYS.open_weather.."&units=metric",
	function( body, len, headers, code )
		local t = self.super.JSON:Parse(body, 1, "}")
		cbfunc(t)
	end, 
	function( error )
		self.super.UTIL:PrintPM("Error fetching from api " .. PMETASTRUCT.UTIL:StringStackData())
	end)   
end

function PMETASTRUCT.APIS:CatFact(cbfunc)
	http.Fetch( "https://catfact.ninja/fact",
	function( body, len, headers, code )
		local t = self.super.JSON:Parse(body, 1, "}")
		cbfunc(t)
	end, 
	function( error )
		self.super.UTIL:PrintPM("Error fetching from api " .. PMETASTRUCT.UTIL:StringStackData())
	end)    
end

function PMETASTRUCT.APIS:UrbanDefine(str, cbfunc)
	str = string.Replace( str, " ", "+" )
	local uri = "http://api.urbandictionary.com/v0/define?term="..str
	http.Fetch( uri,
	function( body, len, headers, code )    
		local t = self.super.JSON:Parse(body, 1, "}")
		cbfunc(t)
	end,
	function( error )
		self.super.UTIL:PrintPM("Error fetching from api " .. PMETASTRUCT.UTIL:StringStackData())
	end)
end

function PMETASTRUCT.APIS:ProperDefine(str, cbfunc)
	str = string.Replace( str, " ", "+" )
	http.Fetch("http://api.pearson.com/v2/dictionaries/brep/entries?headword="+str, 
	function( body, len, headers, code )
		local t = self.super.JSON:Parse(body, 1, "}")
		cbfunc(t)
	end, 
	function( error )
		self.super.UTIL:PrintPM("Error fetching from api " .. PMETASTRUCT.UTIL:StringStackData())
	end)  
end

function PMETASTRUCT.APIS:EnglishToPortuguese(str, cbfunc)
	str = string.Replace( str, " ", "+" )
	http.Fetch("http://api.pearson.com/v2/dictionaries/brep/entries?headword="+str, 
	function( body, len, headers, code )
		local t = self.super.JSON:Parse(body, 1, "}")
		cbfunc(t)
		if (t.status == 100) then
			PMETASTRUCT.UTIL:GlobalChatSay("No results found for the input.")
		elseif (t.status == 200) then
			PMETASTRUCT.UTIL:GCPrint(str.." [EN] -> [PT] "..t.results[1].senses[1].translations[1].text[1])
			if #t.results[1].senses[1].translations[1].example > 0 then
				timer.Simple(2, function()
					PMETASTRUCT.UTIL:GlobalChatSay("i.e. "..t.results[1].senses[1].translations[1].example[1].translation.text[1])
				end)
			end
		else
			self.super.UTIL:PrintPM("Error fetching from api " .. PMETASTRUCT.UTIL:StringStackData())
			PrintTable(t)
		end
	end, 
	function( error )
		self.super.UTIL:PrintPM("Error fetching from api.")
	end)  
end

function PMETASTRUCT.APIS:TellMeAboutChuckNorris(cbfunc)
	http.Fetch( "https://api.chucknorris.io/jokes/random",
	function( body, len, headers, code )
		local t = self.super.JSON:Parse(body, 1, "}")
		cbfunc(t)
	end, 
	function( error )
		self.super.UTIL:PrintPM("Error fetching from api " .. PMETASTRUCT.UTIL:StringStackData())
	end)  
end

function PMETASTRUCT.APIS:InspirationalQuote(cbfunc)
  http.Fetch( "https://api.forismatic.com/api/1.0/?method=getQuote&format=json&lang=en",
	function( body, len, headers, code )
		local t = self.super.JSON:Parse(body, 1, "}")
		cbfunc(t)
	end, 
	function( error )
		self.super.UTIL:PrintPM("Error fetching from api " .. PMETASTRUCT.UTIL:StringStackData())
	end)  
end

function PMETASTRUCT.APIS:HasDonaldTrumpSaid(str, cbfunc)
	str = string.Replace( str, " ", "+" )
	http.Fetch("https://api.tronalddump.io/search/quote?query="+str,
	function( body, len, headers, code )
		local t = self.super.JSON:Parse(body, 1, "}")
		PrintTable(t)
		cbfunc(t)
	end, 
	function( error )
		self.super.UTIL:PrintPM("Error fetching from api " .. PMETASTRUCT.UTIL:StringStackData())
	end)  
end

function PMETASTRUCT.APIS:MomJoke(cbfunc)
	http.Fetch("http://api.yomomma.info/",
	function( body, len, headers, code )
		local t = self.super.JSON:Parse(body, 1, "}")
		PrintTable(t)
		cbfunc(t)
	end, 
	function( error )
		self.super.UTIL:PrintPM("Error fetching from api " .. PMETASTRUCT.UTIL:StringStackData())
	end) 
end

function PMETASTRUCT.APIS:Insult(cbfunc)
	http.Fetch("http://insult.mattbas.org/api/insult", 
	function( body, len, headers, code )
		local t = {}
		t.insult = body
		cbfunc(t)
	end, 
	function( error )
		self.super.UTIL:PrintPM("Error fetching from api " .. PMETASTRUCT.UTIL:StringStackData())
	end)
end

function PMETASTRUCT.APIS:Pokemon(str, cbfunc)
	str = string.Replace( str, " ", "+" )
	http.Fetch("https://pokeapi.co/api/v2/pokemon/"..str,
	function( body, len, headers, code )
		local t = self.super.JSON:Parse(body, 1, "}")
		cbfunc(t)
	end, 
	function( error )
		self.super.UTIL:PrintPM("Error fetching from api.")
	end)
end

PMETASTRUCT.APIS.trivia_id = 0
function PMETASTRUCT.APIS:Trivia(nqs, difficulty, cbfunc)
	http.Fetch("https://opentdb.com/api.php?amount="..nqs.."&difficulty="..difficulty,
	function( body, len, headers, code )
		local t = self.super.JSON:Parse(body, 1, "}")
		cbfunc(t)
	end, 
	function( error )
		self.super.UTIL:PrintPM("Error fetching from api " .. PMETASTRUCT.UTIL:StringStackData())
	end)
end

function PMETASTRUCT.APIS:CurrencyExchange(cbfunc)
	http.Fetch("https://exchangeratesapi.io/api/latest",
	function( body, len, headers, code )
		local t = self.super.JSON:Parse(body, 1, "}")
		cbfunc(t)
	end, 
	function( error )
		self.super.UTIL:PrintPM("Error fetching from api " .. PMETASTRUCT.UTIL:StringStackData())
	end)
end

function PMETASTRUCT.APIS:DesignQuote(cbfunc)
	http.Fetch("http://quotesondesign.com/wp-json/posts?filter[orderby]=rand",
	function( body, len, headers, code )
		local t = self.super.JSON:Parse(body, 1, "}")
		cbfunc(t)
	end, 
	function( error )
		self.super.UTIL:PrintPM("Error fetching from api " .. PMETASTRUCT.UTIL:StringStackData())
	end)
end

function PMETASTRUCT.APIS:DoggoPic(cbfunc)
	http.Fetch("https://dog.ceo/api/breeds/image/random", 
	function( body, len, headers, code )
		local t = self.super.JSON:Parse(body, 1, "}")
		cbfunc(t)
	end, 
	function( error )
		self.super.UTIL:PrintPM("Error fetching from api " .. PMETASTRUCT.UTIL:StringStackData())
	end)
end

function PMETASTRUCT.APIS:CatPic(cbfunc)
	http.Fetch("http://78.media.tumblr.com/tumblr_kolffz3BBz1qze5g2o1_250.gif", 
	function( body, len, headers, code )
		local t = self.super.JSON:Parse(body, 1, "}")
		cbfunc(t)
	end, 
	function( error )
		self.super.UTIL:PrintPM("Error fetching from api " .. PMETASTRUCT.UTIL:StringStackData())
	end)
end

function PMETASTRUCT.APIS:FoxPic(cbfunc)
	http.Fetch("https://randomfox.ca/floof/",
	function( body, len, headers, code )
		local t = self.super.JSON:Parse(body, 1, "}")
		cbfunc(t)
	end, 
	function( error )
		self.super.UTIL:PrintPM("Error fetching from api " .. PMETASTRUCT.UTIL:StringStackData())
	end)    
end

function PMETASTRUCT.APIS:FurryPic(cbfunc)
	http.Fetch("https://recogaming.tech/floof.json",
	function( body, len, headers, code )
		local t = self.super.JSON:Parse(body, 1, "}")
		cbfunc(t)
	end, 
	function( error )
		self.super.UTIL:PrintPM("Error fetching from api " .. PMETASTRUCT.UTIL:StringStackData())
	end)
end

-- PMETA FUNCTIONS --/

PMETASTRUCT.CASUAL        = { }
PMETASTRUCT.CASUAL.ALIAS  = { "caj", "stuff", "meh", "cl" }

function PMETASTRUCT.CASUAL:RGBString(bool, str)
	local new_str = ""
	if bool then
		for i=1, #str, 1 do
			local c = str:sub(i,i)
			new_str = new_str .. "<hsv=[time()*"..(i*100).."]>" .. c
		end
	else
		local s,e = string.find(str, "<hsv=", 1, false)
		if ( (s == nil) or (e == nil) ) then
			self.super.UTIL:PrintPM("String was not RGB format!")
			return
		end
		new_str = str
		for i=1, #new_str, 1 do
			local s1,e1 = string.find(new_str, "<")
			local s2,e2 = string.find(new_str, ">")
			if s1 and s2 then 
				new_str = string.Replace(new_str, new_str:sub(s1, s2), "")
			end
		end
	end
	return new_str
end

local t = { "It is certain", "Outlook good", "You may rely on it", "Ask again later.", "Perhaps", "Maybe", "Indeed", "It might as well be", "sure" }
function PMETASTRUCT.CASUAL:ABall(args)
	if #args == 0  or string.sub(args[#args], #args[#args]) ~= "?" then return "That was not a question." end
	return t[math.random(1, #t)]
end

PMETASTRUCT.TEMP.current_coin = nil
local coinSorter = function(c1, c2)
	return c1:GetPos():DistToSqr(me:GetPos()) < c2:GetPos():DistToSqr(me:GetPos())
end

PMETASTRUCT.CASUAL.coin_search_range = 500
function PMETASTRUCT.CASUAL:MoveToCoins()
	if not IsValid(PMETASTRUCT.TEMP.current_coin) then
		local cents = ents.FindInSphere(me:GetPos(), PMETASTRUCT.CASUAL.coin_search_range)
		table.sort(cents, coinSorter)
		for k,v in pairs(cents) do
			if IsValid(v) and v:GetClass():lower() == "coin" then
				PMETASTRUCT.TEMP.current_coin = v
				break
			end
		end
		if not IsValid(PMETASTRUCT.TEMP.current_coin) then 
			me:ConCommand("-speed")
			me:ConCommand("-forward")
			hooks.Think.collect_coins = nil
		end
	else
		me:SetEyeAngles( (PMETASTRUCT.TEMP.current_coin:GetPos()-me:GetShootPos()):Angle() )
		me:ConCommand("+speed")
		me:ConCommand("+forward")
	end
end

function PMETASTRUCT.CASUAL:ForceGoto( target, srange )
	local sortbydistance = function ( e1, e2 )
		return e1:GetPos():DistToSqr(me:GetPos()) < e2:GetPos():DistToSqr(me:GetPos())
	end
	timer.Create(Tag.."_force_goto", PMETASTRUCT.CONSTANTS.FORCE_GOTO_RETRY, 0, function ()
		-- yay :D 
		if me:IsAdmin() then
			me:ConCommand("aowl restrictions 0")
			PMETASTRUCT.UTIL:Goto(target:Nick())
			me:ConCommand("aowl restrictions 1")
			return
		end
		if IsValid(target) then
			local ents_around = ents.FindInSphere(target:GetPos(), srange)
			table.sort(ents_around, sortbydistance)
			for k,v in pairs(ents_around) do
				if IsValid(v) and v:GetPos():DistToSqr(target:GetPos()) <= srange^2 then
					PMETASTRUCT.UTIL:Goto("_"..v:EntIndex())
				end
				if me:GetPos():DistToSqr(target:GetPos()) <= srange^2 then
					me:SetEyeAngles( (target:GetPos()-me:GetShootPos()):Angle() )
					local name = IsValid(target) and target:Nick() or "NULL"
					PMETASTRUCT.UTIL:PrintPM("Teleported to: "..v:GetClass().."["..v:EntIndex().."]")
					PMETASTRUCT.UTIL:PrintPM("Completed force goto procedure on "..name)
					timer.Destroy(Tag.."_force_goto")
					return
				end
			end
		else
			PMETASTRUCT.UTIL:PrintPM("Invalid Target! He may have disconnected..")
			hook.Remove("Think", Tag.."force_goto")
			return
		end
	end)
	timer.Simple( PMETASTRUCT.CONSTANTS.FORCE_GOTO_RETRY*PMETASTRUCT.CONSTANTS.FORCE_GOTO_TIMEOUT, function ()
		if timer.Exists(Tag.."_force_goto") then
			timer.Destroy(Tag.."_force_goto")
			local name = IsValid(target) and target:Nick() or "NULL"
			PMETASTRUCT.UTIL:PrintPM("Took to long to string.find: "..name.." try again later!")
		end
	end)
end

PMETASTRUCT.TEMP.follow_target = nil
function PMETASTRUCT.CASUAL:FollowTarget()
	local target = PMETASTRUCT.TEMP.follow_target
	if not IsValid(target) then 
		PMETASTRUCT.UTIL:PrintPM("No target set/target invalid D: ") 
		hook.Remove("Think", Tag.."follow_target") 
		RunConsoleCommand("-forward")
		return 
	end
	-- speed
	local distance = me:GetPos():DistToSqr(target:GetPos())
	if distance > 1e4  then --100^2
		-- tp and stop noclip if stuck
		if PMETASTRUCT.TEMP.follow_target:IsPlayer() and me:IsStuck() then
			RunConsoleCommand("aowl", "goto", PMETASTRUCT.TEMP.follow_target:Nick() )
			if me:IsNoClipping() then
				RunConsoleCommand("noclip")
			end
		end
		-- tp if too far
		if PMETASTRUCT.TEMP.follow_target:IsPlayer() and distance > 1500 then
			RunConsoleCommand("aowl", "goto", PMETASTRUCT.TEMP.follow_target:Nick() )
		end
		-- fly if he moves beyond the z plane range
		if not me:IsNoClipping() and math.abs(target:GetPos().z - me:GetPos().z) > 100 then
			RunConsoleCommand("noclip")
		elseif me:IsOnGround() and me:IsNoClipping() then
			RunConsoleCommand("noclip")
		end
		-- just back and forth things
		if distance > 400 then
			RunConsoleCommand("+speed")
		else
			RunConsoleCommand("-speed")
		end
		RunConsoleCommand("+forward")
	else
		RunConsoleCommand("-forward")
	end
	
	me:SetEyeAngles( (target:GetPos()-me:GetShootPos()):Angle() )
end

PMETASTRUCT.CASUAL.TICTAC         = { }
PMETASTRUCT.CASUAL.TICTAC.GAMES   = { }
PMETASTRUCT.CASUAL.TICTAC.LEN     = 3  
PMETASTRUCT.CASUAL.TICTAC.MSQUARE = PMETASTRUCT.UTIL:OddMagicSquare( PMETASTRUCT.CASUAL.TICTAC.LEN )
PMETASTRUCT.CASUAL.TICTAC.MSQSUM  = PMETASTRUCT.CASUAL.TICTAC.LEN*(PMETASTRUCT.CASUAL.TICTAC.LEN*PMETASTRUCT.CASUAL.TICTAC.LEN+1)/2

function PMETASTRUCT.CASUAL.TICTAC:StartGame( ply1, ply2 )
	local game_data = {
		ply1    = ply1,
		ply2    = ply2,
		winner  = "no one",
		isover  = false,
		turn    = 0,
		board   = { },
	}
	
	for i = 1, self.LEN, 1 do
		game_data.board[i] = { }
		for j = 1, self.LEN, 1 do
			game_data.board[i][j] = { ply = nil, val = 0 } 
		end
	end
	
	table.insert(self.GAMES, game_data)
	
	return ply1:Nick().." started a tic tac game with "..ply2:Nick()
end

function PMETASTRUCT.CASUAL.TICTAC:GetGameIDByPlayer( ply )
	for k, g in pairs( self.GAMES ) do
		if table.HasValue(g, ply) then
			return k
		end
	end
	return nil
end

function PMETASTRUCT.CASUAL.TICTAC:EndGame( game )
	self.GAMES[game] = nil
	return "Game ID: "..game.." was ended"
end

function PMETASTRUCT.CASUAL.TICTAC:Play( ply, x, y )
	local game = self:GetGameIDByPlayer(ply)
	local pos_str = "["..x.."]["..y.."]"
	if x > self.LEN or x < 1 or y > self.LEN or y < 1 then
		return "Can't play on that position - pos: "..pos_str
	end
	
	if self.GAMES[game].board[x][y].ply then
		return "That position is already occupied - pos: "..pos_str
	end
	
	self.GAMES[game].board[x][y] = { ply = ply, val = self.MSQUARE[x][y] }
	
	if self.GAMES[game].turn >= self.LEN then 
		for i = 1, self.LEN, 1 do
			local hsum = 0
			local vsum = 0
			local dsum1, dsum2 = 0, 0
			
			for j = 1, self.LEN, 1 do
				hsum = hsum + self.GAMES[game].board[i][j].val
				vsum = vsum + self.GAMES[game].board[j][i].val
			end
			
			dsum1 = dsum1 + self.GAMES[game].board[i][i].val
			dsum2 = dsum2 + self.GAMES[game].board[i][self.LEN - i]
			
			if hsum == PMETASTRUCT.CASUAL.TICTAC.MSQSUM or vsum == PMETASTRUCT.CASUAL.TICTAC.MSQSUM then
				return "Player " .. self.GAMES[game].board[i][1].ply:Nick() .. " has won"
			end
			
			if dsum1 == PMETASTRUCT.CASUAL.TICTAC.MSQSUM or dsum2 == PMETASTRUCT.CASUAL.TICTAC.MSQSUM then
				local mid = math.floor(self.LEN/2)
				return "Player " .. self.GAMES[game].board[mid][mid].ply:Nick() .. " has won"
			end
		end
		
	end
	
	return "Player ".. ply:Nick() .."played at pos: "..pos_str
end


function PMETASTRUCT.CASUAL.TICTAC:IsGameOver( game )
	return self.GAMES[game].isover
end

function PMETASTRUCT.CASUAL.TICTAC:Winner( game )
	return self.GAMES[game].winner
end

--/ PMETA FFT --/
PMETASTRUCT.FFT                = { }
PMETASTRUCT.FFT.ALIAS          = { "musicboi", "ft" }
PMETASTRUCT.FFT.POLL_NEXTSONG  = 5
PMETASTRUCT.FFT.station        = nil
PMETASTRUCT.FFT.queue          = { }
-- HUD FFT
PMETASTRUCT.FFT.realBands      = { }
PMETASTRUCT.FFT.bands_prev     = { }
PMETASTRUCT.FFT.bands          = { }
PMETASTRUCT.FFT.bandThickness  = 18
PMETASTRUCT.FFT.bandMaxHeight  = ((ScrH()/3) * 2) - 75
PMETASTRUCT.FFT.amp            = 5000
PMETASTRUCT.FFT.dext           = 2
PMETASTRUCT.FFT.offset         = 0
PMETASTRUCT.FFT.DRAW_AS_CIRCLE = true

for i = 1 , 64 do
	PMETASTRUCT.FFT.realBands[i] = 0
end

for i = 1 , 512 do
	PMETASTRUCT.FFT.bands_prev[i] = 0
end

function PMETASTRUCT.FFT:PlayNextSong()
	local URI = self.queue[#self.queue]
	if URI == nil then 
		PMETASTRUCT.UTIL:PrintPM("Tried to queue nothing.")
		return
	end
	local f = function(sc, err, errname)
		if( IsValid(sc) ) then
			self.station = sc
			self.station:Play()
			PMETASTRUCT.UTIL:PrintPM("Now playing: " .. URI)
		else
			PMETASTRUCT.UTIL:PrintPM("Problem (" .. errname..") loading URI: " .. URI )
			self.station = nil
		end
	end
  
	if( file.Exists( URI, "GAME" ) )then
		sound.PlayFile( URI, "mono", f )
	else
		sound.PlayURL( URI, "mono", f )
	end
  
	table.remove(self.queue)
end

function PMETASTRUCT.FFT:QueueFFT(URI)
	table.insert(self.queue, URI)
	if self.station == nil then 
		self:PlayNextSong()
	end
	print("Queued at pos: " .. #self.queue .. ", file: " .. URI)
	PMETASTRUCT.UTIL:PrintPM("Queued at pos: " .. #self.queue .. ", file: " .. URI )  
end

function PMETASTRUCT.FFT:SkipSong()
	if( #self.queue > 0 ) then
		self.station:Stop()
		self.station = nil
		PMETASTRUCT.UTIL:PrintPM("Skipping to next song: " .. self.queue[#queue])
		self:PlayNextSong() 
	else
		PMETASTRUCT.UTIL:PrintPM("There is no next song.")
	end
end

-- Think LOL
hook.Add("Think", Tag.."updateAudioPos", function()
	if PMETASTRUCT.FFT.station ~= nil then
		PMETASTRUCT.FFT.station:SetPos(me:GetPos())
	end
end)

timer.Create(Tag.."_check_for_next_song", PMETASTRUCT.FFT.POLL_NEXTSONG, 0, function ()
	if ( (PMETASTRUCT.FFT.station == nil) and ( PMETASTRUCT.FFT.queue and #PMETASTRUCT.FFT.queue ~= 0) ) then
		PMETASTRUCT.FFT:PlayNextSong()
	end
end) 


hook.Add("HUDPaint", Tag.."fftv_hud", function()
	if PMETASTRUCT.FFT.station == nil then return end
	PMETASTRUCT.FFT.station:FFT(PMETASTRUCT.FFT.bands, FFT_8192)
	if not PMETASTRUCT.FFT.bands[1] then return end
		
	for i = 1 , 64 do  
		if PMETASTRUCT.FFT.bands[i + PMETASTRUCT.FFT.offset] * PMETASTRUCT.FFT.amp > PMETASTRUCT.FFT.bandMaxHeight then
		   PMETASTRUCT.FFT.bands[i + PMETASTRUCT.FFT.offset] = PMETASTRUCT.FFT.bandMaxHeight / PMETASTRUCT.FFT.amp
		end   
	
		if PMETASTRUCT.FFT.bands[i + PMETASTRUCT.FFT.offset] * PMETASTRUCT.FFT.amp < 2 then
			PMETASTRUCT.FFT.bands[i + PMETASTRUCT.FFT.offset] = 2
		else
			PMETASTRUCT.FFT.bands[i + PMETASTRUCT.FFT.offset] = PMETASTRUCT.FFT.bands[i + PMETASTRUCT.FFT.offset] * PMETASTRUCT.FFT.amp
		end
		
		PMETASTRUCT.FFT.realBands[i] = Lerp(30*FrameTime(), PMETASTRUCT.FFT.realBands[i], PMETASTRUCT.FFT.bands[i + PMETASTRUCT.FFT.offset])
	
		if i < 63  and i > 2 then 
			local a = PMETASTRUCT.FFT.realBands[i]
			local b = PMETASTRUCT.FFT.realBands[i + 1]
			local c = PMETASTRUCT.FFT.realBands[i - 1]
			PMETASTRUCT.FFT.realBands[i] = (a+b+c) / 3
		elseif i < 3 then
			local a = PMETASTRUCT.FFT.realBands[i]
			local b = PMETASTRUCT.FFT.realBands[i + 1]
			local c = 0
			PMETASTRUCT.FFT.realBands[i] = (a+b+c) / 3
		end
	end
		
	if PMETASTRUCT.FFT.DRAW_AS_CIRCLE then
		local interval = 360 / 64
		local centerX, centerY = ScrW()/2, ScrH()/2.5
		local radius = 250
		local pointThickness = 15
		local index = 1
			
		for i=1, 360, interval do
			local color = Color( math.Clamp( PMETASTRUCT.FFT.realBands[index]/2, 0, 255), math.Clamp( PMETASTRUCT.FFT.realBands[index]/4, 0, 255), 70 )                
			local x = (math.cos(i) * (PMETASTRUCT.FFT.realBands[index]+radius)) + centerX
			local y = (math.sin(i) * (PMETASTRUCT.FFT.realBands[index]+radius)) + centerY
		
			surface.SetDrawColor(color)
			surface.DrawLine(x, y, (math.cos(i) * radius) + centerX, (math.sin(i) * radius) + centerY)
			
			index = index + 1
		end
		draw.SimpleText(PMETASTRUCT.UTIL:SecondsToClock(PMETASTRUCT.FFT.station:GetTime()), "Song Title", centerX-225, centerY-draw.GetFontHeight("Song Title")/2, Color(255,255,255))
		--table.Copy(PMETASTRUCT.FFT.bands, PMETASTRUCT.FFT.bands_prev)
	else
		local w = (ScrW()) - 200
		local xPos = 100
		for i = 1, 64 do
			local color = Color( math.Clamp( PMETASTRUCT.FFT.realBands[i]/3, 0, 255), math.Clamp( PMETASTRUCT.FFT.realBands[i]/4, 0, 255), 70 )
			draw.RoundedBox( 0, xPos, math.ceil((ScrH()/3) * 2) - PMETASTRUCT.FFT.realBands[i], PMETASTRUCT.FFT.bandThickness, PMETASTRUCT.FFT.realBands[i], color )
			xPos = xPos + (w/64)
			print(PMETASTRUCT.FFT.realBands[i])
		end
		draw.SimpleText("FFT Visualiser - " .. PMETASTRUCT.UTIL:SecondsToClock(PMETASTRUCT.FFT.station:GetTime()), "Song Title", 100 + 190, ((ScrH()/3) * 2), Color(255,255,255))
	end
end)

--/ CLIENT CHAT COMMANDS --
PMETASTRUCT.CHATCMDS                    = { }
PMETASTRUCT.CHATCMDS.ALIAS              = { "chatstuff", "paulcommands", "pcommands", "cs" }
PMETASTRUCT.CHATCMDS.prefixes           = {"+", "-"}
PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY   = 0
PMETASTRUCT.CHATCMDS.PERSONAL           = 1
PMETASTRUCT.CHATCMDS.TTS                = 2
PMETASTRUCT.CHATCMDS.GLOBAL             = 3
PMETASTRUCT.CHATCMDS.LOCAL              = 4
PMETASTRUCT.CHATCMDS.PM                 = 5
PMETASTRUCT.CHATCMDS.PROXIMITY_DISTANCE = 500
PMETASTRUCT.CHATCMDS.BLOCK_ALL          = false
PMETASTRUCT.CHATCMDS.EmitMessage        = function(self, typ, msg)
	if typ == PMETASTRUCT.CHATCMDS.GLOBAL then
		PMETASTRUCT.UTIL:GlobalChatSay(msg)
	end

	if typ == PMETASTRUCT.CHATCMDS.TTS then
		PMETASTRUCT.UTIL:TTSSay(msg)
	end
	
	if typ == PMETASTRUCT.CHATCMDS.LOCAL then
		PMETASTRUCT.UTIL:LocalChatSay(msg)
	end
	
	if typ == PMETASTRUCT.CHATCMDS.PM then
		PMETASTRUCT.UTIL:PrintPM(msg)
	end
end

function PMETASTRUCT.CHATCMDS:AddTemp( desc, func, alias, type, scmd_desc, test )
	local cmd = {
		desc  = (desc or "") .. "[i.e.] %prefix%%alias%" .. (scmd_desc or ""),
		func  = func or function (self, data)
			PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "I currently do nothing :)!")
		end,
		alias = alias or { "cmd"..#self.cmds+1 },
		type  = type or { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY },
		test  = test or function(self, data)
			data.args = { "#me", "#nearest", "#furthest", "#richest", "#longestonline", "#laggiest", "#random", "#randomdev", "stuff", tostring(math.random(1e20)), "3.14159" }
			self:func(data)
		end,
	}
	
	table.insert(self.cmds, cmd)
	PMETASTRUCT.UTIL:PrintPM("Added a new temporary command! Index: " .. #self.cmds .. " 1st Alias: " .. cmd.alias[1])
	return cmd;
end

function PMETASTRUCT.CHATCMDS:StringToChatConstant(str)
	if not str then return nil end
	print(str, "---->", self[str:upper()])
	return self[str:upper()]
end

function PMETASTRUCT.CHATCMDS:GetCommandByAlias(str)
	for k,v in pairs(self.cmds) do
		if table.HasValue(v.alias, str:lower()) then
			return v
		end
	end
	return nil
end

function PMETASTRUCT.CHATCMDS:IsChatCMD(str)
	return self:GetCommandByAlias(str)
end

function PMETASTRUCT.CHATCMDS:DecodeDescription(cmd)
	local prefix_str = ""
	for k,v in pairs(PMETASTRUCT.CHATCMDS.prefixes) do
		prefix_str = prefix_str + v
		if k ~= #PMETASTRUCT.CHATCMDS.prefixes then
			prefix_str = prefix_str + "/"
		end
	end

	local alias_str = ""
	for k,v in pairs(cmd.alias) do
		alias_str = alias_str + v
		if k ~= #cmd.alias then
			alias_str = alias_str + "/"
		end
	end
	
	local desc = string.Replace(cmd.desc, "%prefix%", "<prefix: "..prefix_str..">")
	desc = string.Replace(desc, "%alias%", "<alias: "..alias_str..">")
	return desc
end

function PMETASTRUCT.CHATCMDS:Parse(ply, txt)
	-- Replacing, if this gets big enough - lookup table?
	local args = PMETASTRUCT.UTIL:Split(txt)
	args = PMETASTRUCT.UTIL:ReplaceInArray(args, "#me", ply:ProperNick())
	args = PMETASTRUCT.UTIL:ReplaceInArray(args, "#nearest", PMETASTRUCT.UTIL:ClosestToPlayer(ply):ProperNick())
	args = PMETASTRUCT.UTIL:ReplaceInArray(args, "#furthest", PMETASTRUCT.UTIL:FurthestToPlayer(ply):ProperNick())
	args = PMETASTRUCT.UTIL:ReplaceInArray(args, "#richest", PMETASTRUCT.UTIL:RichestPlayer():ProperNick())
	args = PMETASTRUCT.UTIL:ReplaceInArray(args, "#longestonline", PMETASTRUCT.UTIL:LongestOnlinePlayer():ProperNick())
	args = PMETASTRUCT.UTIL:ReplaceInArray(args, "#laggiest", PMETASTRUCT.UTIL:LaggiestPlayer():ProperNick())
	args = PMETASTRUCT.UTIL:ReplaceInArray(args, "#longestafk", PMETASTRUCT.UTIL:LongestAFKPlayer():ProperNick())
	args = PMETASTRUCT.UTIL:ReplaceInArray(args, "#random", PMETASTRUCT.UTIL:RandomPlayer():ProperNick())
	args = PMETASTRUCT.UTIL:ReplaceInArray(args, "#randomdev", (PMETASTRUCT.UTIL:RandomDev() or PMETASTRUCT.UTIL:RandomPlayer()):ProperNick())
	
	local this = PMETASTRUCT.UTIL:This(ply)
	args = PMETASTRUCT.UTIL:ReplaceInArray(args, "#this", this:IsPlayer() and this:ProperNick() or this:EntIndex() )
	
	return {
		tstamp      = os.date( "%H:%M:%S - %d/%m/%Y" , os.time() ),
		raw         = txt,
		prefix      = txt:sub(1,2),
		cmd         = string.sub(args[1], 2),
		args        = {unpack(args, 2)},
		emit_type   = PMETASTRUCT.CHATCMDS.GLOBAL, -- default
		ply         = ply, -- default
	}  
end

PMETASTRUCT.TEMP.TESTCASE_CO    = nil
PMETASTRUCT.TEMP.TESTCASE_SKIP  = nil
PMETASTRUCT.TEMP.TESTCASE_ABORT = false
function PMETASTRUCT.CHATCMDS:RunTestCases( cmds, types )
	cmds		= cmds or self.cmds
	types		= types or { PMETASTRUCT.CHATCMDS.GLOBAL, PMETASTRUCT.CHATCMDS.LOCAL, PMETASTRUCT.CHATCMDS.TTS }
	
	-- swap keys to values to lesser affect benchmarking
	for k,v in pairs(types) do
		types[v] = k
	end
	
	local btime, tsecs, async_tsecs = -1, -1, -1
	
	PMETASTRUCT.TEMP.TESTCASE_ABORT = false
	PMETASTRUCT.TEMP.TESTCASE_CO    = coroutine.create( function ()
		for k,v in pairs(cmds) do
			if PMETASTRUCT.TEMP.TESTCASE_ABORT then 
				ChatPrint("Aborted test cases!") 
				print"Aborted test cases!" 
				return 
			end
			
			if PMETASTRUCT.TEMP.TESTCASE_SKIP and PMETASTRUCT.TEMP.TESTCASE_SKIP > k then
				print"Skipping test case... " 
				continue
			end
			
			btime, tsecs, async_tsecs = SysTime(), CurTime(), UnPredictedCurTime()
			print("---------------- Running test cases for cmd #" .. k.."("..v.alias[1]..") ---------------------")
			ChatPrint("Running test case...  -> #"..k.." ["..v.alias[1].."]")
			
			-- global emmit type
			if types[PMETASTRUCT.CHATCMDS.GLOBAL] then
				print"GLOBAL TEST"
				local tstamp, raw, prefix = os.date( "%H:%M:%S - %d/%m/%Y" , os.time() ), "", "!"
				v:test({
					tstamp      = tstamp,
					raw         = raw,
					prefix      = prefix,
					cmd         = v.alias[1],
					args        = {},
					emit_type   = PMETASTRUCT.CHATCMDS.GLOBAL, -- default
					ply         = me, -- default
				});
			end
			-- local
			if types[PMETASTRUCT.CHATCMDS.LOCAL] then
				print"LOCAL TEST"
				v:test({
					tstamp      = tstamp,
					raw         = raw,
					prefix      = prefix,
					cmd         = v.alias[1],
					args        = {},
					emit_type   = PMETASTRUCT.CHATCMDS.LOCAL, -- default
					ply         = me, -- default
				});
			end
			-- tts
			if types[PMETASTRUCT.CHATCMDS.TTS] then
				print"TTS TEST"
				v:test({
					tstamp      = tstamp,
					raw         = raw,
					prefix      = prefix,
					cmd         = v.alias[1],
					args        = {},
					emit_type   = PMETASTRUCT.CHATCMDS.TTS, -- default
					ply         = me, -- default
				});
			end
			
			print("---------------- Test concluded Benchmark: [ ~".. SysTime() - btime .. "ms ] Time: [ ".. CurTime() - tsecs .. "s ] AsyncTime [ ".. UnPredictedCurTime() - async_tsecs .. "s ] -----------------------")
			ChatPrint("Test concluded for #" .. k .. "["..v.alias[1].."] (data output to console)")
			coroutine.yield(k)
		end
	end)

	coroutine.resume(PMETASTRUCT.TEMP.TESTCASE_CO)
end

hook.Add("OnPlayerChat", Tag.."cmds_test", function( ply, txt, a, b )
	if ply ~= me then return end
	local prefix = txt:sub(1,1)

	if prefix ~= "&" then return end
	if not PMETASTRUCT.TEMP.TESTCASE_CO then 
		PMETASTRUCT.UTIL:PrintPM("No test case coroutine is active! [This is an error btw (or you shouldnt be calling &cmds atm)]")
		return
	end

	txt = txt:sub(2, #txt)
	if txt == "next" then
		ChatPrint("Attempting to skip to the next test case...")
		coroutine.resume(PMETASTRUCT.TEMP.TESTCASE_CO)
	elseif txt == "abort" then
		ChatPrint("Attempting to abort next test cases...")
		PMETASTRUCT.TEMP.TESTCASE_ABORT = true
		coroutine.resume(PMETASTRUCT.TEMP.TESTCASE_CO)
		PMETASTRUCT.TEMP.TESTCASE_CO = nil
	elseif txt:sub(1,4) == "skip" then
		local i = string.Trim(txt:sub(5, #txt))
		local i = tonumber(i)
		
		if type(i) == "number" then
			ChatPrint("Attempting to skip to #".. i .. " test case...")
			PMETASTRUCT.TEMP.TESTCASE_SKIP = i
			coroutine.resume(PMETASTRUCT.TEMP.TESTCASE_CO)
		else
			ChatPrint("uh oh, testcase skip had a problem :*(")
			return
		end
	end
end)

PMETASTRUCT.CHATCMDS.cmds = {
	[0] = {
		desc  = "Testing123. Just a Testing command. [i.e.] %prefix%%alias%]",
		func  = function (self, data)
			PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Testing. Args: { " .. table.concat(data.args, ", ").." }")
		end,
		alias = { "test" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY },
		test  = function(self, data)
			data.args = { "#me", "#nearest", "#furthest", "#richest", "#longestonline", "#laggiest", "#random", "#randomdev", "stuff", tostring(math.random(1e20)), "3.14159" }
			self:func(data)
		end,
	},
	[1] = {
		desc  = "Gets a cat fact. [i.e.] %prefix%%alias%",
		func  = function (self, data)
			PMETASTRUCT.APIS:CatFact( function (t)
				PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, PMETASTRUCT.UTIL:BadString(t.fact))
			end)
		end,
		alias = { "catfact" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY  },
		test  = function(self, data)
			self:func(data)
		end,
	},
	[2] = {
		desc  = "Urban dictionary definition. [i.e.] %prefix%%alias% <words>",
		func  = function (self, data)
			if #data.args == 0  then
				PMETASTRUCT.UTIL:SendPM("Invalid arguments! Try -help "..data.cmd, data.ply)
				return
			end
			local input = table.concat(data.args, " ")
			PMETASTRUCT.APIS:UrbanDefine(input, function (t)
				local str = ""
				if #t.list == 0 then 
					print("No defs found")
					str = "No definitions found for: '"..input.."'"
				else
					print(t.list[1].definition)
					str = t.list[1].definition
				end
				 
				 PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, str)
			end)
		end,
		alias = { "udefine" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY  },
		data  = { },
		test  = function(self, data)
			data.args = { "Paul" }
			self:func(data)
		end
	},
	[3] = {
		desc  = "Oxford dictionary definition. [i.e.] %prefix%%alias% <words>",
		func  = function (self, data)
			if #data.args == 0 then
				PMETASTRUCT.UTIL:SendPM("Invalid arguments! Try -help "..data.cmd, data.ply)
				return
			end
			local input = table.concat(data.args, " ")
			PMETASTRUCT.APIS:ProperDefine(input, function(t)
				local str = ""
				PrintTable(t)
				if (t.status == 100) then
					PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "No results found for the input.")
				elseif (t.status == 200) then
					PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, t.results[1].senses[1].definition[1])
					if #t.results[1].senses[1].translations[1].example[1] > 0 then 
						PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "i.e. "..t.results[1].senses[1].translations[1].example[1].text)
					end
					print("hi", t.results[1].senses[1].definition)
				else
					PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Problem with API!")
					PrintTable(t)
				end
			end)
		end, 
		alias = { "pdefine", "properdefine", "def" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL },
		test  = function(self, data)
			data.args = { "wallet" }
			self:func(data)
		end,
	},
	[4] = {
		desc  = "Chuck Norris Fact. [i.e.] %prefix%%alias%",
		func  = function (self, data) 
			PMETASTRUCT.APIS:TellMeAboutChuckNorris(function (t)
				PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, PMETASTRUCT.UTIL:BadString(t.value))
			end)
		end,
		alias = { "chucknorris" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY  },
		test  = function(self, data)
			self:func(data)
		end,
	},
	[5] = {
		desc  = "RGB name. [i.e.] %prefix%%alias%",
		func  = function (self, data)
			print( PMETASTRUCT.CASUAL:RGBString(true, me:ProperNick()))
			me:ConCommand( "name_set "..PMETASTRUCT.CASUAL:RGBString(true, me:ProperNick()) )
			PMETASTRUCT.UTIL:PrintPM("Name set to RGB format!")
		end,
		alias = { "mergb" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL },
		test  = function(self, data)
			PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, PMETASTRUCT.CASUAL:RGBString(true, me:ProperNick()))
		end,
	},
	[6] = {
		desc  = "unRGB name. [i.e.] %prefix%%alias%",
		func  = function (self, data)
			me:ConCommand("name_set "..PMETASTRUCT.CASUAL:RGBString(false, me:Nick()) )
			PMETASTRUCT.UTIL:PrintPM("Name un set from RGB format!")
		end,
		alias = { "unmergb" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL },
		test  = function(self, data)
			PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, PMETASTRUCT.CASUAL:RGBString(false, PMETASTRUCT.CASUAL:RGBString(true, me:ProperNick())))
		end,
	},
	[7] = {
		desc  = "Help for cmds. [i.e.] %prefix%%alias%",
		func  = function (self, data)
			local str = ""
			if data.args[1] then
				local scmd = PMETASTRUCT.CHATCMDS:GetCommandByAlias(data.args[1])
				if scmd then
					PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Help@("..scmd.alias[1]..") - "..PMETASTRUCT.CHATCMDS:DecodeDescription(scmd))
				else
					PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Could not string.find help for that command D:")
				end
			else -- list all
				if data.ply == me then
					str = "Help printed to console. [i.e.] %prefix%%alias%"
					for k,v in pairs(PMETASTRUCT.CHATCMDS.cmds) do
						print("--/ NEW COMMAND - ["..k.."] --")
						PrintTable(v)
					end
					PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "CMD data output to console! :3")
				else
					local msg = ""
					for k,v in pairs(PMETASTRUCT.CHATCMDS.cmds) do
						if table.HasValue(v.type, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY) then
							msg = msg .. ", " .. v.alias[1]
						end
					end
					msg = string.sub(msg, 2)
					msg = "Commands = { "..msg.." }"
					str = msg
					PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Type '-help <cmd>' where cmd belongs in Commands, for extra help.")
					timer.Simple(1, function ()
						PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, str)
					end)
				end
			end
		end,
		alias = { "help", "pcmds", "paulcommands", "pcommands" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY },
		test  = function(self, data)
			self:func(data)
		end,
	},
	[8] = {
		desc = "Queues a song and tries to play it on FFT. [i.e.] %prefix%%alias% <audio>",
		func = function (self, data)
			if #data.args < 1 then 
				PMETASTRUCT.UTIL:SendPM("Invalid arguments! Try -help "..data.cmd, data.ply)
				return
			end
  
			PMETASTRUCT.FFT:QueueFFT(data.args[1])
		end,
		alias = { "qfft", "qsong", "queuefft", "queuesong" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL },
		test  = function(self, data)
			data.args = { "witcher.mp3" }
			self:func(data)
		end,
	},
	[9] = {
		desc  = "Disables FFT features. [i.e.] %prefix%%alias%",
		func = function (self, data)
			hook.Remove("PaintHUD", Tag.."fftv_hud")
			if IsValid(PMETASTRUCT.FFT.station) then
				PMETASTRUCT.FFT.station:Stop()
			end
			PMETASTRUCT.FFT.station = nil
			PMETASTRUCT.FFT.queue = nil
			PMETASTRUCT.UTIL:PrintPM("Removing FFT Visualiser. Deleting Queue.")
		end,
		alias = { "rfft", "removefft", "clearfft" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL },
		test  = function(self, data)
			self:func(data)
		end,
	},
	[10] = {
		desc = "Skips current FFT song. [i.e.] %prefix%%alias%",
		func = function (self, data)
	  
		end,
		alias = { "sfft", "ssong", "skipsong", "skipfft" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL },
		test  = function(self, data)

		end,
	},
	[11] = {
		desc = "Toggles esp. [i.e.] %prefix%%alias%",
		func = function (data)
			local str = ""
			if hooks['HUDPaint']['pmeta_esp'] then
				hook.Remove("HUDPaint", Tag.."pmeta_esp")
				str = "ESP: Removed."
			else
				hook.Add("HUDPaint", Tag.."pmeta_esp", PMETASTRUCT.ESP.DrawESP)
				str = "ESP: Activated"
			end
			PMETASTRUCT.UTIL:PrintPM(str)
		end,
		alias = { "esp", "wallhack", "huddata" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL },
		test  = function(self, data)
			self:func(data)
		end,
	},
	[12] = {
		desc = "Insipiring Quote. [i.e.] %prefix%%alias%",
		func = function (self, data)
			PMETASTRUCT.APIS:InspirationalQuote(function (t)
				PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, t.quoteText)
			end)
		end,
		alias = { "quote", "paulquote", "deepshit" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY },
		test  = function(self, data)
			self:func(data)
		end,
	},
	[13] = {
		desc = "Ask the magic eight ball anything. [i.e.] %prefix%%alias% <question(?)>",
		func = function (self, data)
			PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, PMETASTRUCT.CASUAL:ABall(data.args))
		end,
		alias = { "8ball", "eightball", "magicball", "questionball" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY  },
		test  = function(self, data)
			data.args = { "Is life real?" }
			self:func(data)
		end,
	},
	[14] = { 
		desc = "Queuery Donald Trump's real quotes. [i.e.] %prefix%%alias% <query_words>",
		func = function (self, data)
			PMETASTRUCT.APIS:HasDonaldTrumpSaid(table.concat(data.args, " "), function(t) 
				if t.total == nil then 
					PMETASTRUCT.UTIL:SendPM("Invalid arguments! Try -help "..data.cmd, data.ply)
					return
				end
				
				local quotes = t["_embedded"].quotes
				local n		 = #quotes
				local str = (n == 0) and "Could not string.find any Donald trump quote about that." or quotes[math.random(1, n)].value
				PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, str) 
			end)
		end,
		alias = { "donald", "donaldquote", "trump" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY  },
		test  = function(self, data)
			self.args = { "Fake News" }
			self:func(data)
		end,
	},
	[15] = {
		desc = "Blacklist add user. [i.e.] %prefix%%alias% <username>",
		func = function (self, data)
			print(data.args[1])
			local str = ""
			local ply = PMETASTRUCT.UTIL:FindEnt(data.args[1])
			if IsValid(ply) and ply:IsPlayer() then
				PMETASTRUCT.DATA.TABLES.BLACKLIST[ply:SteamID()] = ply
				str = ply:Nick().."("..ply:SteamID()..") added to blacklist!"
			else
				str = "Could not string.find player with input: "..data.args[1]
			end
			PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, str)
		end,
		alias = { "badd", "blacklistadd", "blacklist", "blist" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL },
		test  = function(self, data)
			PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Test blacklist features seperately.")
		end,
	},
	[16] = {
		desc = "Blacklist remove user. [i.e.] %prefix%%alias% <username>",
		func = function (self, data)
			local ply = PMETASTRUCT.UTIL:FindEnt(data.args[1])
			if IsValid(ply) and ply:IsPlayer() then
				local str = ""
				if PMETASTRUCT.DATA.TABLES.BLACKLIST[ply:SteamID()] then
					PMETASTRUCT.DATA.TABLES.BLACKLIST[ply:SteamID()] = nil
					str = "Removing user: "..ply:Nick().." from the blacklist!"
				else
					str = ply:Nick().."("..ply:SteamID()..") is not in the blacklist!"
				end
				PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, str)
			else
				PMETASTRUCT.UTIL:SendPM("Could not string.find player with input: "..data.args[1], data.ply)
			end
		end,
		alias = { "bremove", "blacklistremove", "deblacklist", "unblacklist" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL },
		test  = function(self, data)
			PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Test blacklist features seperately.")
		end,
	},
	[17] = {
		desc  = "Player information! [i.e.] %prefix%%alias% <username>",
		func  = function (self, data)
			local target = PMETASTRUCT.UTIL:FindEnt(data.args[1])
			if IsValid(target) and target:IsPlayer() then
				local ply = data.ply
				local str_nick = (target:Nick() ~= target:SteamNick()) and target:Nick() .. " originaly called " .. target:SteamNick() or target:Nick()
				local str_afk = target:IsAFK() and "They are AFK for "..PMETASTRUCT.UTIL.SecondsToWords(target:AFKTime()) .. ". " or ""
				local str_who = target:GetUserGroup()
				local str_pirate = target:IsPirate() and ", they are a pirate. " or ""
				local str_fshare = target:IsFamilySharing() and "They are using steam family share. " or ""
				local str_freinds = false and "You are steam friends. " or ""
				local str_typing = target:GetTypingMessage() and "They are typing a message. " or ""
				local str_speaking = target:IsSpeaking() and "They are speaking. " or ""
				local str_outfit = target:OutfitInfo() and target:OutfitInfo() or target:GetModel()
				local str_taunt = target:IsPlayingTaunt() and "They are currently taunting someone. " or ""
				local str_see = target:CanSee(ply) and "You are able to see him from your position. " or ""
				local s = string.find(str_outfit, "/[^/]*$")
				local e = string.find(str_outfit, ".mdl")
				
				local str =  str_nick .. ", is part of the " .. str_who .. str_pirate .. ". Their Steam ID: "..target:SteamID() .. ". "
				str = str .. str_fshare
				str = str .. "They have played on metastruct for ".. PMETASTRUCT.UTIL.SecondsToWords(target:GetUTime()) .. ". This session: "..PMETASTRUCT.UTIL.SecondsToWords(target:GetUTimeSessionTime())..". "
				str = str .. str_afk
				str = str .. "They can be found ".. math.floor(ply:GetPos():DistToSqr(target:GetPos())^0.5) .. " units away from you dressed as "..str_outfit:sub(s+1,e-1)..". "
				str = str .. "They have " .. ply:GetCoins() .. " coins. "
				str = str .. str_freinds
				str = str .. str_typing
				str = str .. str_speaking
				str = str .. str_taunt
				str = str .. "They are traveling at "..target:GetVelocity():Length().." units."
				str = str .. str_see
				
				PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, str)
			else
				PMETASTRUCT.UTIL:SendPM("Could not string.find target :(", data.ply)
			end
		end,
		alias = { "whois", "who" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY },
		test  = function(self, data)
			data.args = { me:Nick() }
			self:func(data)
		end,
	},
	[18] = {
		desc  = "Weather information. [i.e.] %prefix%%alias% <city>, <country_code>",
		func  = function (self, data)
			if #data.args == 0 then
				PMETASTRUCT.UTIL:SendPM("Invalid arguments! Try -help "..data.cmd, data.ply)
				return
			end
			local input = table.concat(data.args, " ")
			PMETASTRUCT.APIS:WeatherData(input, function (t)
				if t.cod == "404" then
					PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Weather@("..input..") - "..t.message)
					return
				end
				local str = ""
				for k, v in pairs(t.weather) do 
					str = str + v.description
					if #t.weather == 1 then continue end
					if k == #t.weather then str = str  + "and "
					else str = str  + ", " end
				end
				str = "Weather@("..t.name.." ["..t.sys.country.."]) - Currently we have "..str:Trim()..". Temperature: "..t.main.temp.."°C | Pressure: "..t.main.pressure.."psi | Wind: "..t.wind.speed.."m/s."
				PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, str)
			end)
		end,
		alias = { "weather" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY  },
		test  = function(self, data)
			data.args = { "liverpool", "uk" }
			self:func(data)
		end,
	},
	[19] = {
		desc = "Collect Nearby Coins. [i.e.] %prefix%%alias% <coin_range> <no_clip>",
		func = function (self, data)
			if data.args[1] then
				PMETASTRUCT.CASUAL.coin_range_limit = tonumber(data.args[1])
			end
			if data.args[2] then
				if( not me:IsNoClipping() ) then me:ConCommand("noclip") end
			end
			PMETASTRUCT.UTIL:PrintPM("Collecting coins hook starting.")
			hook.Add("Think", Tag.."collect_coins", PMETASTRUCT.CASUAL.MoveToCoins )
			if data.args[2] then
				if( me:IsNoClipping() ) then me:ConCommand("noclip") end
			end
		end,
		alias = { "collect", "gimme", "mycoinsnow" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL },
		test  = function(self, data)
			PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Test collect coins seperately!")
		end,
	},
	[20] = {
		desc = "Force Goto. [i.e.] %prefix%%alias% <username>",
		func = function (self, data)
			if data.args[1] == "%ABORT%" then
				timer.Destroy(Tag.."_force_goto")
				PMETASTRUCT.UTIL:PrintPM("Aborted force goto procedure.")
				return
			end
			
			local target = PMETASTRUCT.UTIL:FindEnt(data.args[1])
			local search_range = data.args[2] and tonumber(data.args[2]) or 1000
			if IsValid(target) then
				PMETASTRUCT.UTIL:PrintPM("Starting force goto on: "..target:Nick())
				PMETASTRUCT.CASUAL:ForceGoto(target, search_range)
			else
				PMETASTRUCT.UTIL:PrintPM("No target was found.")
			end
		end,
		alias = { "forcegoto", "fgoto" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL },
		test  = function(self, data)
			PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Test fgoto seperately!")
		end,
	},
	[21] = {
		desc = "Language Detection. [i.e.] %prefix%%alias% <words>",
		func = function (self, data)
			if #data.args == 0 then
				PMETASTRUCT.UTIL:SendPM("Invalid arguments! Try -language <words>", data.ply)
				return
			end
			local input = table.concat(data.args, " ")
			PMETASTRUCT.APIS:LanguageDetect(input, function(t)
				PrintTable(t)
				if t.results then
					local shift = 10 ^ 2
					local p = math.floor( t.results[1].percentage*shift + 0.5 ) / shift
					local str = "My algorithm says there is a "..p.."% chance that language is "..t.results[1].language_name.."."
					if t.results[2] then
						local p2 = math.floor( t.results[2].percentage*shift + 0.5 ) / shift
						str =  str + " Followed by a "..p2.."% chance of it being "..t.results[2].language_name.."."
					end
					PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, str)
				else
					PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Problem with API. D:")
				end
			end)        
		end,
		alias = { "language", "whatlanguage" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY },
		test  = function(self, data)
			data.args = { "Hello world! My name is Paul. I like cats. Cats are cute. Do you like cats? Thank you." }
			self:func(data)
		end,
	},
	[22] = {
		desc = "i th message information. [i.e.] %prefix%%alias% <i> <copy/language/info/relay>",
		func = function (self, data)
			local scmd = data.args[1]
			local im_offset = 1
			local im   = im_offset
			if not scmd then PMETASTRUCT.UTIL:SendPM("Invalid arguments! Try -imsg <i> <copy/language/info/relay>", data.ply) return end
			if isnumber(tonumber(scmd)) then im = im_offset + data.args[1] scmd = data.args[2] print"Check imsg cmd function pls, k thx." end
			if not scmd then PMETASTRUCT.UTIL:SendPM("Invalid arguments! Try -imsg <i> <copy/language/info/relay>", data.ply) return end
			if not PMETASTRUCT.DATA.TABLES.CHAT_HISTORY[im] then PMETASTRUCT.UTIL:SendPM("Unable to look up that message. Try a more recent one.", data.ply) return end
			
			local msg_data = PMETASTRUCT.DATA.TABLES.CHAT_HISTORY[im]
			scmd = scmd:lower()
			if scmd == "copy" then
				SetClipboardText(msg_data[2]) -- the text [1] is ply - check validity
			elseif scmd == "language" then
				PMETASTRUCT.APIS:LanguageDetect(msg_data[2], function(t)
					PrintTable(t)
					if t.results then
						local shift = 10 ^ 2
						local p = math.floor( t.results[1].percentage*shift + 0.5 ) / shift
						local str = "My algorithm says there is a "..p.."% chance that language is "..t.results[1].language_name.."."
						if t.results[2] then
							local p2 = math.floor( t.results[2].percentage*shift + 0.5 ) / shift
							str =  str + " Followed by a "..p2.."% chance of it being "..t.results[2].language_name.."."
						end
						PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, str)
					else
						PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Problem with API. D:")
					end
				end) 
			elseif scmd == "info" then
				local str = "Message written by "..msg_data[3].." at "..msg_data[4].."."
				PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, str)
			elseif scmd == "relay" then
				local s = string.find(msg_data[2]:lower(), "-imsg")
				if s then
					PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Can't relay into another -imsg message D:")
				else
					PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, msg_data[2])
				end
			else
				PMETASTRUCT.UTIL:SendPM("Invalid arguments! Try -help "..data.cmd, data.ply)
			end
		end,
		alias = { "ithmessage", "imsg" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY },
		test  = function(self, data)
			data.args = { "copy" }
			self:func(data)
			data.args = { "language" } 
			self:func(data)
			data.args = { "info" }
			self:func(data)
			data.args = { "relay" }
			self:func(data)
		end,
	},
	[23] = {
		desc = "Get Mentions. [i.e.] %prefix%%alias%",
		func = function (self, data)
			PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Mention data output to console.")
			PrintTable(PMETASTRUCT.DATA.TABLES.MENTION_HISTORY)
		end,
		alias = { "mentions", "getmentions" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL },
		test  = function(self, data)
			self:func(data)
		end,
	},
	[24] = {
		desc = "Better goto. [i.e.] %prefix%%alias% <username/macro/search_range <macro>>",
		func = function (self, data)
			if data.args[1] == nil then PMETASTRUCT.UTIL:SendPM("Invalid arguments! Try -help "..data.cmd, data.ply) return end
			local search_range, macro = 2000, data.args[1]
			if isnumber(data.args[1]) then search_range = data.args[1] macro = data.args[2] end
			
			if macro == "@people" then
				local dense_people = { }
				for k,v in pairs(player.GetAll()) do
					table.insert(dense_people, {v,#PMETASTRUCT.UTIL:FindPlayersInSphere(v:GetPos(), search_range)})
				end
				
				if #dense_people == 0 then PMETASTRUCT.UTIL:PrintPM("Could not teleport to a dense player area. None found?") return end
				table.sort(dense_people, function (p1,p2) return p1[2] > p2[2] end)
				
				for k, v in pairs(dense_people) do
					if IsValid(v[1]) then
						if ( v[1] == me ) then
						  PMETASTRUCT.UTIL:PrintPM("You are at a dense player area! Trying 2nd most...")
						else
						  PMETASTRUCT.UTIL:Goto(v[1]:Nick())
						  PMETASTRUCT.UTIL:PrintPM("Teleported to a dense player area.")
						  return
						end
					end
				end
				PMETASTRUCT.UTIL:PrintPM("Could not teleport to a dense player area. Few people?")
			elseif macro == "@devs" then -- MAKE THIS MODULAR PLEASE THANKYOU
				local dense_people = { }
				for k,v in pairs(player.GetAll()) do
					table.insert(dense_people, {v,#PMETASTRUCT.UTIL:FindDevsInSphere(v:GetPos(), search_range)})
				end
				
				if #dense_people == 0 then PMETASTRUCT.UTIL:PrintPM("Could not teleport to a dense dev area. None found?") return end
				table.sort(dense_people, function (p1,p2) return p1[2] > p2[2] end)
				
				for k, v in pairs(dense_people) do
					if IsValid(v[1]) and v[1] ~= me then
					  if ( v[1] == me ) then
						  PMETASTRUCT.UTIL:PrintPM("You are at a dense dev area! Trying 2nd most...")
						else
						  PMETASTRUCT.UTIL:Goto(v[1]:Nick())
						  PMETASTRUCT.UTIL:PrintPM("Teleported to a dense dev player area.")
						return
						end
					end
				end
				PMETASTRUCT.UTIL:PrintPM("Could not teleport to a dense player area. Few People`?")
			elseif macro == "@friends" then
			  local dense_people = { }
				for k,v in pairs(player.GetAll()) do
					table.insert(dense_people, {v,#PMETASTRUCT.UTIL:FindFriendsInSphere(v:GetPos(), search_range, me)})
				end
				
				if #dense_people == 0 then PMETASTRUCT.UTIL:PrintPM("Could not teleport to a dense friend area. None found?") return end
				table.sort(dense_people, function (p1,p2) return p1[2] > p2[2] end)
				
				for k, v in pairs(dense_people) do
					if IsValid(v[1]) and v[1] ~= me then
					  if ( v[1] == me ) then
						  PMETASTRUCT.UTIL:PrintPM("You are at a dense friend area! Trying 2nd most...")
						else
						  PMETASTRUCT.UTIL:Goto(v[1]:Nick())
						  PMETASTRUCT.UTIL:PrintPM("Teleported to a dense friend player area.")
						return
						end
					end
				end
				PMETASTRUCT.UTIL:PrintPM("Could not teleport to a dense player area. Few People`?")
			elseif macro == "@random" then
				local locs = table.GetKeys(aowl.GotoLocations)
				PMETASTRUCT.UTIL:Goto(locs[math.random(1,#locs)])
			elseif macro == "@locations" then
				local locs = table.GetKeys(aowl.GotoLocations)
				local str = "{"
				for k,v in pairs(locs) do str = str + v if k~=#locs then str = str+", " end end
				str = str + "}"
				PMETASTRUCT.UTIL:PrintPM(str)
			elseif macro == "@last" then
				if PMETASTRUCT.TEMP.last_goto then
					PMETASTRUCT.UTIL:Goto(PMETASTRUCT.TEMP.last_goto)
				else
					PMETASTRUCT.UTIL:PrintPM("There is no last location! Sorry D:")
				end
			elseif macro == "@func" then
				local possible_code = table.concat( {unpack(data.args, 2)}, " ")
				local s,e = string.find("function", possible_code)
				
				if not s or not e then 
					possible_code = "return function ( p1, p2 ) " .. possible_code.." end"
				end
				
				print(possible_code)
				local func = CompileString(possible_code, "@func")
				print(tostring(func()))
				
				if type(func) == "function" then
					local target = PMETASTRUCT.UTIL:CmpPlayer( func() )
					print("HELLO", target)
					if not IsValid(target) then
						PMETASTRUCT.UTIL:PrintPM("Target resultant from @func was not valid!")
						return
					end
					PMETASTRUCT.UTIL:Goto(target:Nick())
				else
					PMETASTRUCT.UTIL:PrintPM("Code was not evaluated as a func for @func param")
				end
			else
				PMETASTRUCT.UTIL:Goto(macro)
			end
		end,
		alias = { "bg", "bgoto", "bettergoto" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL },
		test  = function(self, data)
			PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Test bgoto seperately!")
		end,
	},
	[25] = {
		desc = "Get messages of a player. [i.e.] %prefix%%alias% <username>",
		func = function (self, data)
			local target = PMETASTRUCT.UTIL:FindEnt(data.args[1])
			if IsValid(target) and target:IsPlayer() then
				if #PMETASTRUCT.DATA.TABLES.CHAT_HISTORY == 0 then PMETASTRUCT.UTIL:PrintPM("Chat history empty!") return end
				local plog = { }
				for k,v in pairs(PMETASTRUCT.DATA.TABLES.CHAT_HISTORY) do
					if target == v[1] then
						table.insert(plog, v)
					end
				end
				PrintTable(plog)
				PMETASTRUCT.UTIL:PrintPM("Log of "..target:Nick().." printed to console!")
			else
				PMETASTRUCT.UTIL:PrintPM("Invalid player target!")
			end 
		end,
		alias = { "chatlog", "log" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL },
		test  = function(self, data)
			data.args = { me:GetNick() }
			self:func(data)
		end,
	},
	[26] = {
		desc  = "Mom joke. [i.e.] %prefix%%alias%",
		func  = function (self, data) 
			PMETASTRUCT.APIS:MomJoke(function (t)
				PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, t.joke)
			end)
		end,
		alias = { "momjoke", "yomamma" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY  },
		data  = { },
		test  = function(self, data)
			self:func(data)
		end,
	},
	[27] = {
		desc  = "Insult someone. [i.e.] %prefix%%alias% <username>",
		func  = function (self, data)
			local target = PMETASTRUCT.UTIL:FindEnt(data.args[1])
			if IsValid(target) then
				print"valid TARGET"
				PMETASTRUCT.APIS:Insult(function (t)
					t.insult = string.Replace(t.insult, "You are", target:Nick().." is")
					PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, t.insult)
				end)
			else
				print"invalid TARGET"
				PMETASTRUCT.APIS:Insult(function (t)
					PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, t.insult)
				end)
			end
		end,
		alias = { "insult", "atac" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY  },
		test  = function(self, data)
			self:func(data)
		end,
	},
	[28] = {
		desc  = "Follow someone. [i.e.] %prefix%%alias% <username>",
		func  = function (self, data)
			if data.args[1] == "%ABORT%" then 
				hook.Remove("Think", Tag.."follow_target") 
				RunConsoleCommand("-forward") 
				PMETASTRUCT.UTIL:PrintPM("Aborted following.")
				return
			end
			
			local target = PMETASTRUCT.UTIL:FindEnt(data.args[1])
			
			if IsValid(target) then
				PMETASTRUCT.TEMP.follow_target = target
				PMETASTRUCT.UTIL:PrintPM("Starting to follow a "..target:GetClass())
				hook.Add("Think", Tag.."follow_target", PMETASTRUCT.CASUAL.FollowTarget )
			else
				hook.Remove("Think", Tag.."follow_target")
			end
		end,
		alias = { "follow", "chase" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL },
		test  = function(self, data)
			PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Test follow seperately!")
		end,
	},
	[29] = {
		desc  = "Search a pokemon. [i.e.] %prefix%%alias% <pokemon_name>",
		func  = function (self, data)
			if #data.args == 0 then
				PMETASTRUCT.UTIL:SendPM("Invalid arguments! Try -help "..data.cmd, data.ply)
				return
			end
			local input = table.concat(data.args, " ")
			PMETASTRUCT.APIS:Pokemon(input, function (t)
				if not t.forms then
					PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Pokemon not found! D:")
					return
				end
				PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Pokemon ["..t.forms[1].name.."]["..t.types[1].type.name.."][Base XP:"..t.base_experience.."]")
			end)
		end,
		alias = { "pokemon", "pmon" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY },
		test  = function(self, data)
			data.args = { "pikachu" }
			self:func(data)
		end,
	},
	[30] = {
		desc  = "Trivia questions. [i.e.] %prefix%%alias% <difficulty(easy/medium/hard)> <#questions>",
		func  = function (self, data)
			if data.args[1] == "%WAIT_TIME%" then
				PMETASTRUCT.CONSTANTS.TRIVIA_WAIT_TIME = tonumber(data.args[2]) or 5
				PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Changed Trivia wait time to: "..PMETASTRUCT.CONSTANTS.TRIVIA_WAIT_TIME)
				return
			end
			local dif = data.args[1] or "medium"
			local nqs = data.args[2] or 1
			PMETASTRUCT.APIS:Trivia(nqs, dif, function (t)
				if t.response_code == 2 then
					PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Problem with API related with input. This was most likely because you didn't use the correct arguments.")
				else
					PMETASTRUCT.APIS.trivia_id = PMETASTRUCT.APIS.trivia_id + 1
					for k,v in pairs(t.results) do
						local question = PMETASTRUCT.UTIL:BadString(v.question)
						local choices = table.Copy(v.incorrect_answers)
						local id = PMETASTRUCT.APIS.trivia_id
						print("answer", v.correct_answer)
						PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, question.." ("..PMETASTRUCT.CONSTANTS.TRIVIA_WAIT_TIME.." sec)[ID:"..id.."]")
						table.insert(choices, math.random(1, #choices), v.correct_answer)
						hook.Add("OnPlayerChat", Tag.."trivia_answers"..id, function ( ply, txt, a, b )
							if txt:lower() == v.correct_answer:lower() then
								PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, ply:ProperNick().." has got the correct answer! [ID: "..id.."]")
							end
						end)
						timer.Simple( 1, function ()
							PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Choices [ID:"..id.."]: ".. table.concat(choices, ", "))
							timer.Simple(PMETASTRUCT.CONSTANTS.TRIVIA_WAIT_TIME, function ()
								hook.Remove("OnPlayerChat", Tag.."trivia_answers"..id)
								PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Answer [ID:"..id.."]: "..v.correct_answer)
								PMETASTRUCT.APIS.trivia_id = PMETASTRUCT.APIS.trivia_id - 1
							end)
						end)
					end
				end
			end)
		end,
		alias = { "trivia" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY },
		test  = function(self, data)
			self:func(data)
		end,
	},
	[31] = {
		desc = "Roll! [i.e.] %prefix%%alias% <out_of>",
		func = function (self, data)
			local sides = tonumber(data.args[1]) or 100
			if sides < 2 then
				PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Invalid roll! D:")
				return
			end
			PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, data.ply:Nick().." rolled a "..math.random(1, sides).."/"..sides)
		end,
		alias = { "roll", "dice" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY },
		test  = function(self, data)
			self:func(data)
			data.args = { "19" }
			self:func(data)
		end,
	},
	[32] = {
		desc = "Drop Coins! [i.e.] %prefix%%alias% <secs> <coins>",
		func = function (self, data)
			if data.args[1] == "%ABORT%" then 
				if timer.Exists(Tag.."_drop_coins") then timer.Destroy(Tag.."_drop_coins") end
				PMETASTRUCT.UTIL:PrintPM("Aborting drop coins")
				return
			end
			local secs  = data.args[1] or 3
			local coins = data.args[2] or 1000
			
			PMETASTRUCT.UTIL:PrintPM("Droping coins of "..coins.." value at "..secs.." intervals")
			timer.Create(Tag.."_drop_coins", secs, 0, function ()
				RunConsoleCommand("drop_coins", coins)
			end)
		end,
		alias = { "dropcoins", "dcoins" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL },
		test  = function(self, data)
			PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Test dropcoins seperately!")
		end,
	},
	[33] = {
		desc = "Checks if player is afk. [i.e.] %prefix%%alias% <username>",
		func = function (self, data)
			if #data.args < 1 then 
				PMETASTRUCT.UTIL:SendPM("Invalid arguments! Try -help "..data.cmd, data.ply)
				return
			end
			
			local target = PMETASTRUCT.UTIL:FindEnt(data.args[1])
			if IsValid(target) and target:IsPlayer() then
				local str = ""
				if target:IsAFK() then
					str = target:ProperNick().." is afk for "..PMETASTRUCT.UTIL.SecondsToWords(target:AFKTime())
				else
					str = target:ProperNick().." is not afk!"
				end
				PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, str)
			else
				PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Player not found D:")
			end
		end,
		alias = { "isafk", "afk" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY },
		test  = function(self, data)
			data.args = { me:Nick() }
			self:func(data)
		end,
	},
	[34] = {
		desc = "Translate text from a language to another. [i.e.] %prefix%%alias% <from_code> <to_code> <words>",
		func = function (self, data)
			if #data.args < 1 then 
				PMETASTRUCT.UTIL:SendPM("Invalid arguments! Try -help "..data.cmd, data.ply)
				return
			end
			local from = data.args[1]
			local to   = data.args[2]
			local str  = table.concat( {unpack(data.args, 3)}, " ")
			PMETASTRUCT.APIS:TranslateText( from, to, str, function (t)
				if t.error then
					PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, t.error.message)
				else
					PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, t.data.translations[1].translatedText)
				end
			end)
		end,
		alias = { "translate", "tr" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY },
		test  = function(self, data)
			data.args = { "pt", "en", "Ola a todos! Como vai isso?" }
			self:func(data)
			data.args = { "en", "pt", "Hello everyone! How is that going?" }
			self:func(data)
		end,
	},
	[35] = {
		desc = "Spins me D. [i.e.] %prefix%%alias% <speed>",
		func = function (self, data)
			if data.args[1] == "%ABORT%" then
				hooks.Think.spinme = nil
				PMETASTRUCT.UTIL:PrintPM("Spinning aborted!")
				return
			end
			
			local speed = data.args[1] or 20
			hooks.Think.spinme = function ()
				me:SetEyeAngles(me:EyeAngles() + Angle(0,speed,0)) 
			end
			PMETASTRUCT.UTIL:PrintPM("Spinning at speed "..speed)
		end,
		alias = { "spinme", "spin" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL },
		test  = function(self, data)
			PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Test spin seperately!")
		end,
	},
	[36] = {
		desc = "Auto bhop. [i.e.] %prefix%%alias%",
		func = function (self, data)
			if data.args[1] == "%ABORT%" then
				hooks.Think.bhop = nil
				PMETASTRUCT.UTIL:PrintPM("bhopping aborted!")
				return
			end
			hook.Add("Think", Tag.."bhop", function ()
				if me:IsOnGround() then 
					me:ConCommand("+jump")
				else
					me:ConCommand("-jump")
				end
			end)
			PMETASTRUCT.UTIL:PrintPM("Auto bhop started!")
		end,
		alias = { "bhop", "bhopping" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL },
		test  = function(self, data)
			self:func(data)
			timer.Simple(2, function ()
				self:func(data)
			end)
		end,
	},
	[37] = {
		desc = "Start a Tresure hunt! [i.e.] %prefix%%alias% <coin_value>",
		func = function (self, data)
			local coin_value = data.args[1] or 1000000
			RunConsoleCommand("coins_drop", coin_value)
			
			local x, y, z = math.floor(me:GetPos().x), math.floor(me:GetPos().y), math.floor(me:GetPos().z)
			local xm, ym, zm = 10^(#tostring(x)-2), 10^(#tostring(y)-2), 10^(#tostring(z)-2) 
			x = math.ceil(x / xm)*xm
			y = math.ceil(y / ym)*ym
			z = math.ceil(z / zm)*zm
			-- Note to self, following code is bad. Pls fix soon. It kinda works.
			timer.Simple(1, function () 
				local cents = ents.FindInSphere(me:GetPos(), 100)
				PrintTable(cents)
				for k,v in pairs(cents) do
					if v:GetClass():lower() == "coin" then
						RunConsoleCommand("say", " <hsv=[time()*100]>Treasure hunt! I've hidden a "..coin_value.." value coin around Vector("..x..", "..y..", "..z..")! Find it win it!")
						local cpos = v:GetPos()
						v.OnRemove = function ()
							local cdis, cply = 42135132, nil
							for k,v in pairs(player.GetAll()) do
								local dis = cpos:DistToSqr(v:GetPos())
								if dis < cdis then
									cdis = dis
									cply = v
								end
							end
							RunConsoleCommand("say", "<hsv=[time()*100]>Treasure Hunt coin was found by "..cply:ProperNick())
						end
						break
					end
				end
				RunConsoleCommand("aowl", "goto", "build")
			end)
		end,
		alias = { "thunt", "treasurehunt" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL },
		test  = function(self, data)
			PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Test treasure hunt seperately!")
		end,
	},
	[38] = {
		desc = "Get CMD History. [i.e.] %prefix%%alias%",
		func = function (self, data)
			PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "CMD history data output to console.")
			PrintTable(PMETASTRUCT.DATA.TABLES.CMD_HISTORY)
		end,
		alias = { "cmdhistory", "cmdh" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL },
		test  = function(self, data)
			self:func(data)
		end,
	},
	[39] = {
		desc = "Number to words. [i.e.] %prefix%%alias%",
		func = function (self, data)
			local num = tonumber(data.args[1])
			if not type(num) == "number" then
				PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Argument was not a number!")
				return
			end
			PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, PMETASTRUCT.UTIL:NumToWords(num))
		end,
		alias = { "numtowords", "numwords", "ntw" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY },
		test  = function(self, data)
			data.args = { "42134231421343214231" } 
			self:func(data)
		end,
	},
	[40] = {
		desc = "Currency exchange. [i.e.] %prefix%%alias% <to> <from> <value>",
		func = function (self, data)
			if data.args[1] == "date" then
				PMETASTRUCT.APIS:CurrencyExchange( function ( currency_table )
					PMETASTRUCT.CHATCMDS:EmitMessage( data.emit_type, "Date of exchange rates: "..currency_table.date )
				end)
				return
			end
			
			local to = data.args[1]
			local from = data.args[2]
			local value = PMETASTRUCT.UTIL:Round(tonumber(data.args[3]), 2)
				
			if not to or not from or not value then
				PMETASTRUCT.CHATCMDS:EmitMessage(data.emit_type, "Invalid Arguments!")
				return
			end
			
			PMETASTRUCT.APIS:CurrencyExchange( function ( currency_table )
				if not currency_table.rates[to:upper()] or not currency_table.rates[from:upper()] then
					PMETASTRUCT.CHATCMDS:EmitMessage( data.emit_type, "Invalid currency codes!")
					return
				end
				
				local euro   = value * currency_table.rates[from:upper()]
				local rvalue = PMETASTRUCT.UTIL:Round(euro / currency_table.rates[to:upper()], 2)
				
				PMETASTRUCT.CHATCMDS:EmitMessage( data.emit_type, "["..to.."] " .. value.." = ["..from.."] " .. rvalue )
			end)
		end,
		alias = { "convertcurrency", "currency", "moneyrates", "convertmoney" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY },
		test  = function(self, data)
			data.args = { "gbp", "eur", "1" }
			self:func(data)
			data.args = { "eur", "gbp", "1" }
			self:func(data)
		end,
	},
	[41] = {
		desc = "Random Design Quote. [i.e.] %prefix%%alias%",
		func = function (self, data)
			PMETASTRUCT.APIS:DesignQuote(function (t)
				PrintTable(t)
				PMETASTRUCT.CHATCMDS:EmitMessage( data.emit_type, PMETASTRUCT.UTIL:BadString(t[1].content))
			end)
		end,
		alias = { "dquote", "designquote" },
		type = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY },
		test  = function(self, data)
			self:func(data)
		end,
	},
	[42] = {
		desc = "Random Doggo Picture. [i.e.] %prefix%%alias%",
		func = function (self, data)
			PMETASTRUCT.APIS:DoggoPic( function (t)
				PMETASTRUCT.CHATCMDS:EmitMessage( data.emit_type, t.message )
			end)
		end,
		alias = { "doggo", "dogpic" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY },
		test  = function(self, data)
			self:func(data)
		end,
	},
	[43] = {
		desc  = "Random Cat Picture. [i.e.] %prefix%%alias%",
		func  = function (self, data)
			PMETASTRUCT.APIS:CatPic( function (t)
				PMETASTRUCT.CHATCMDS:EmitMessage( data.emit_type, t.file )
			end)
		end,
		alias = { "kitty", "catpic" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY },
		test  = function(self, data)
			self:func(data)
		end,
	},
	[44] = {
		desc  = "Random Fox Picture. [i.e.] %prefix%%alias%",
		func  = function (self, data)
			PMETASTRUCT.APIS:FoxPic( function (t)
				PMETASTRUCT.CHATCMDS:EmitMessage( data.emit_type, t.image )
			end)
		end,
		alias = { "rar", "foxpic", "foxy" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY },
		test  = function(self, data)
			self:func(data)
		end,
	},
	[45] = {
		desc  = "Run Lua String. [i.e.] %prefix%%alias% <code>",
		func  = function (self, data)
			local code = table.concat(data.args, " ")
			PMETASTRUCT.UTIL:PrintPM("Code was ran on you via lrun. Check console.")
			print("ororororororor THE CODE ororororororor|\n"..code)
			PMETASTRUCT.CHATCMDS:EmitMessage( data.emit_type, RunString( table.concat(data.args, " "), "RunStringPMETASTRUCT" ) or "Lua ran!")
		end,
		alias = { "lrun" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL },
		test  = function(self, data)
			data.args = LocalPlayer():ConCommand('say_local hello world!')
			self:func(data)
		end,
	},
	[46] = {
		desc  = "Random furry pic. [i.e.] %prefix%%alias%",
		func  = function (self, data)
			PMETASTRUCT.APIS:FurryPic( function (t)
				PMETASTRUCT.CHATCMDS:EmitMessage( data.emit_type, [[https://]]..t.file )
			end)
		end,
		alias = { "furry", "owo", "uwu" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY },
		test  = function(self, data)
			self:func(data)
		end,
	},
	[47] = {
		desc  = "Start test cases for the cmds. [i.e.] %prefix%%alias% <spew_local&/spew_tts&/spew_global>",
		func  = function (self, data)
			local t = { }
			for _, v in pairs( data.args ) do
				if v:lower() == "spew_local" then
					table.insert(t, PMETASTRUCT.CHATCMDS.LOCAL)
				elseif v:lower() == "spew_tts" then
					table.insert(t, PMETASTRUCT.CHATCMDS.TTS)
				elseif v:lower() == "spew_global" then
					table.insert(t, PMETASTRUCT.CHATCMDS.GLOBAL)
				end
			end
			
			if #t == 0 then
				PMETASTRUCT.CHATCMDS:EmitMessage( data.emit_type, "No test case spew types were found! Please follow format: " .. self.desc )
			else
 				PMETASTRUCT.CHATCMDS:RunTestCases( nil, t )
 			end
		end,
		alias = { "testing123", "testcases", "cmdtests", "testcmds" },
		type  = { PMETASTRUCT.CHATCMDS.PERSONAL },
		test  = function(self, data)
			PMETASTRUCT.CHATCMDS:EmitMessage( data.emit_type, "Skipping testcases command! :3")
		end,
	}
}

-- ESP lul --/
PMETASTRUCT.ESP        = { }
PMETASTRUCT.ESP.xm     = 1920/ScrW()
PMETASTRUCT.ESP.ym     = 1080/ScrH()
PMETASTRUCT.ESP.config = {
	crosshair_color = color_white,
	crosshair_width = 20,
	crosshair_height = 20,
	crosshair_thickness = 0,
	draw_crosshair = true,
	draw_player_names = true,
	draw_player_boxes = true,
}

function PMETASTRUCT.ESP:AliveCheck(v)
	return v:Alive() == true and v:Health() ~= 0 and v:Health() >= 0 and v ~= me and me:Alive()
end

function PMETASTRUCT.ESP:BoxCoordinates( ent )
	local min, max = ent:OBBMins(), ent:OBBMaxs()
	local corners = {
		Vector( min.x, min.y, min.z ),
		Vector( min.x, min.y, max.z ),
		Vector( min.x, max.y, min.z ),
		Vector( min.x, max.y, max.z ),
		Vector( max.x, min.y, min.z ),
		Vector( max.x, min.y, max.z ),
		Vector( max.x, max.y, min.z ),
		Vector( max.x, max.y, max.z )
	}
  
	local minX, minY, maxX, maxY = ScrW() * 2, ScrH() * 2, 0, 0
	for _, corner in pairs( corners ) do
		local onScreen = ent:LocalToWorld( corner ):ToScreen()
		minX, minY = math.min( minX, onScreen.x ), math.min( minY, onScreen.y )
		maxX, maxY = math.max( maxX, onScreen.x ), math.max( maxY, onScreen.y )
	end
 
	return minX, minY, maxX, maxY
end

function PMETASTRUCT.ESP:DrawTarget(ent)
	local x1,y1,x2,y2 = PMETASTRUCT.ESP:BoxCoordinates(ent)
	surface.SetDrawColor(ent:IsPlayer() and team.GetColor(ent:Team()) or Color(255, 160, 0))
	  
	surface.DrawLine( x1, y1, math.min( x1 + 5, x2 ), y1 )
	surface.DrawLine( x1, y1, x1, math.min( y1 + 5, y2 ) )
	   
	   
	surface.DrawLine( x2, y1, math.max( x2 - 5, x1 ), y1 )
	surface.DrawLine( x2, y1, x2, math.min( y1 + 5, y2 ) )
	   
	   
	surface.DrawLine( x1, y2, math.min( x1 + 5, x2 ), y2 )
	surface.DrawLine( x1, y2, x1, math.max( y2 - 5, y1 ) )
	   
	surface.DrawLine( x2, y2, math.max( x2 - 5, x1 ), y2 )
	surface.DrawLine( x2, y2, x2, math.max( y2 - 5, y1 ) )
end

local hzCross = CreateClientConVar("HZ_Crosshair", "0", false)
function PMETASTRUCT.ESP:DrawESP()
	-- Crosshair
	if PMETASTRUCT.ESP.config.draw_crosshair then
		surface.SetDrawColor(PMETASTRUCT.ESP.config.crosshair_color)
		surface.DrawLine(ScrW() / 2 - PMETASTRUCT.ESP.config.crosshair_width/2, ScrH() / 2, ScrW() / 2 + PMETASTRUCT.ESP.config.crosshair_width/2, ScrH() / 2)
		surface.DrawLine(ScrW() / 2, ScrH() / 2 - PMETASTRUCT.ESP.config.crosshair_height/2, ScrW() / 2 - 0 , ScrH() / 2 + PMETASTRUCT.ESP.config.crosshair_height/2)
	end
	-- Player Box
	for k,v in pairs(ents.GetAll()) do
		if IsValid(v) and v:IsPlayer() then
			local plypos = (v:GetPos() + Vector(0,0,80)):ToScreen()
			local color = v:GetUTime() > 3.6e6 and Color(30, 55, 210) or color_white
			color = v:GetUserGroup() == "developers" and Color(255,0,0) or color_white
			
			if v:IsAFK() then
				draw.DrawText("AFK - "..PMETASTRUCT.UTIL.SecondsToWords(v:AFKTime()), "Trebuchet18", plypos.x, plypos.y-15, color, 1)
			end
			
			draw.DrawText(v:Name().." - "..v:Health(), "Trebuchet18", plypos.x, plypos.y, color, 1)
			draw.DrawText(PMETASTRUCT.UTIL:Round(v:GetPos():DistToSqr(me:GetPos())^0.5, 2), "Trebuchet18", plypos.x, plypos.y+15, color, 1)
			
			if PMETASTRUCT.ESP.config.draw_player_boxes then
				PMETASTRUCT.ESP:DrawTarget(v)
			end
		else
			if v:GetClass():lower() == "coin" then
				local coinpos = (v:GetPos() + Vector(0,0,20)):ToScreen()
				local sin = PMETASTRUCT.UTIL:SinWave( 5, 4.5, true )
				
				halo.Add( { v }, Color(250, 100, 0), 1 + sin, 1 + sin, 1 )
				PMETASTRUCT.ESP:DrawTarget(v)
				
				local color = (v:GetValue() >= 1000000 ) and Color(math.random(0,255), math.random(0,255), math.random(0,255)) or color_white
				draw.DrawText(v:GetValue(), "Trebuchet18", coinpos.x, coinpos.y, color, 1)
			end
		end
	end
end

-- Personas --
PMETASTRUCT.Persona 	 = { }
PMETASTRUCT.Persona.list = { }
PMETASTRUCT.Persona.Create = function ( self, id, nick, model, outfitid, titlefunc )
	local p = { }
	p.id		= id
	p.nick		= nick
	p.model 	= model
	p.outfitid  = outfitid
	p.titlefunc = titlefunc
	
	p = setmetatable(p, {
		__index = PMETASTRUCT.Persona
	})
	
	table.insert(self.list, p)
	
	return p
end

PMETASTRUCT.Persona.BroadcastOutfit = function ( self )
	outfitter.BroadcastMyOutfit()
end

PMETASTRUCT.Persona.Load = function ( self )
	me:ConCommand("setnick " .. self.nick )
	
	if self.outfitid then
		outfitter.UIChoseWorkshop(self.outfitid)
		timer.Simple(3, function ()
			Say"!outfit 1"
			timer.Simple(2, function ()
				outfitter.UIBroadcastMyOutfit()
			end)
		end)
	end

	PMETASTRUCT.CONFIG.TITLE_FUNC = self.titlefunc
	PMETASTRUCT.UTIL:PrintPM("Persona " .. self.id .. "("..self.nick..") loaded!")
end

PMETASTRUCT.Persona.GetByID = function ( id )
	for k, p in ipairs( PMETASTRUCT.Persona.list ) do
		if p.id == id then 
			return p 
		end
	end
end

PMETASTRUCT.Persona.SetPersona = function ( id )
	local persona = assert( PMETASTRUCT.Persona.GetByID(id), "No persona was found with that id!")
	persona:Load()
	return persona
end

PMETASTRUCT.Persona.Add = function ( persona )
	table.insert(PMETASTRUCT.Persona.list, persona)
end

PMETASTRUCT.Persona:Add(PMETASTRUCT.Persona:Create( "cat", "cat", "", 952118754, function () 
	PMETASTRUCT.APIS:CatFact( function (t)
		t.fact = PMETASTRUCT.UTIL:BadString(t.fact)
		me:SetCustomTitles({{t.fact, 1}}) -- unicode characters ! method to Parse... needed
	end)
end))

PMETASTRUCT.Persona:Add(PMETASTRUCT.Persona:Create( "roarjr", ":roar: Jr.", "", 0x37b77590, function ()
	me:SetCustomTitles({{"owo", 1}})
end))

-- HOOKS Arrr --
hook.Add("OnPlayerChat", Tag.."chat_history", function ( ply, txt, a, b )
	if not IsValid(ply) then return end
	if #PMETASTRUCT.DATA.TABLES.CHAT_HISTORY <= PMETASTRUCT.CONSTANTS.CHAT_HISTORY_LIMIT then
		table.insert(PMETASTRUCT.DATA.TABLES.CHAT_HISTORY, 1, {ply, txt, ply:Nick(), os.date("!%c")} )
	else
		for k in pairs (PMETASTRUCT.DATA.TABLES.CHAT_HISTORY) do
			PMETASTRUCT.DATA.TABLES.CHAT_HISTORY[k] = nil
		end
		PMETASTRUCT.UTIL:PrintPM("Clearing chat history...")
	end
	
	if #PMETASTRUCT.DATA.TABLES.MENTION_HISTORY <= PMETASTRUCT.CONSTANTS.MENTION_HISTORY_LIMIT then
		if ply == me then return end 
		local ltxt  = txt:lower()
		local a     = string.match(ltxt, "paul")
		local b     = string.match(txt,  "%s"..me:Nick().."%s")
		local c     = string.match(txt,  "%s"..me:SteamID().."%s")
		local d     = string.match(txt,  "%s"..me:RealNick().."%s")
		local e     = string.match(ltxt, "%s"..me:ProperNick().."%s")
		
		if ( a or b or c or d or e ) then
			PMETASTRUCT.UTIL:PrintPM( ply:Nick().." has mentioned us!" )
			table.insert(PMETASTRUCT.DATA.TABLES.MENTION_HISTORY, 1, {ply, txt, ply:Nick(), os.date("!%c")} )
		end
	else
		for k in pairs (PMETASTRUCT.DATA.TABLES.MENTION_HISTORY) do
			PMETASTRUCT.DATA.TABLES.MENTION_HISTORY[k] = nil
		end
		PMETASTRUCT.UTIL:PrintPM("Clearing mention history...")
	end
end)

hook.Add("OnPlayerChat", Tag.."cmds", function( ply, txt, a, b )
	if ( #txt < 2 or not table.HasValue(PMETASTRUCT.CHATCMDS.prefixes, string.sub(txt:sub(1,2), 0, 1)) ) then return end
	local data       = PMETASTRUCT.CHATCMDS:Parse(ply, txt)
	local cmd_object = PMETASTRUCT.CHATCMDS:GetCommandByAlias(data.cmd:lower())
	
	if( cmd_object ) then -- 2 types of commands. Public. An Private. Public is proximity dependent. Private requires specs.
		local msg_scope = PMETASTRUCT.CHATCMDS:StringToChatConstant(data.args[1])
		if msg_scope then
			data.emit_type = msg_scope
			data.args = {unpack(data.args,2)}
		end 

		-- Force cmd
		if ( ply ~= me and ply:IsAHigherPower() ) then
			cmd_object:func(data)
			PMETASTRUCT.UTIL:SendPM("CMD Forced upon you!", ply)
			return
		end
		
		if ( PMETASTRUCT.CHATCMDS.BLOCK_ALL and ply ~= me ) then 
			PMETASTRUCT.UTIL:PrintPM("BLOCK_ALL is on!") 
			return 
		end
		
		if #PMETASTRUCT.DATA.TABLES.CMD_HISTORY > PMETASTRUCT.CONSTANTS.CMD_HISTORY_LIMIT then 
			for k in pairs (PMETASTRUCT.DATA.TABLES.CMD_HISTORY) do
				PMETASTRUCT.DATA.TABLES.CMD_HISTORY[k] = nil
			end
			PMETASTRUCT.UTIL:PrintPM("Clearing cmd history...")
		end
	
		table.insert(PMETASTRUCT.DATA.TABLES.CMD_HISTORY, data)
		
		if ( table.HasValue(cmd_object.type, PMETASTRUCT.CHATCMDS.PUBLIC_PROXIMITY) and ply ~= me ) then
			if PMETASTRUCT.DATA.TABLES.BLACKLIST[ply:SteamID()] then
				PMETASTRUCT.UTIL:SendPM("You are blacklisted from using paul commands.", ply)
				return
			end
			if( ply:GetPos():DistToSqr(me:GetPos())^0.5 <= PMETASTRUCT.CHATCMDS.PROXIMITY_DISTANCE ) then
				cmd_object:func(data)
			else
				PMETASTRUCT.UTIL:SendPM("You must be next to paul (" .. me:Nick() .. ") to run a paul command.", ply)
			end
		elseif ( table.HasValue(cmd_object.type, PMETASTRUCT.CHATCMDS.PERSONAL) and ply == me) then
			PrintTable(data)
			cmd_object:func(data)
		else
			PMETASTRUCT.UTIL:SendPM("Valid command with no type?? (Probably missing correct type in type array)Command: "..data.raw, ply)
		end
	else
		PMETASTRUCT.UTIL:PrintPM("Invalid CMD! Input: '" .. data.cmd .. "' by "..ply:Nick())
	end
end)

hook.Add("OnEntityCreated", Tag.."revive_me", function(ent)
	if not PMETASTRUCT.CONFIG.REVIVE_ME then return end
	if IsValid(ent) and ent == me:GetRagdollEntity() then
		timer.Simple(0.5, function()
		  RunConsoleCommand("aowl", "revive")
		end)
	end
end)

local hs = true
hook.Add("Think", Tag.."afk_on_tab", function()
	if not PMETASTRUCT.CONFIG.AFK_ONTAB then return end
	
	local nhs = system.HasFocus()
	if hs ~= nhs then
		hs = nhs
		me:SetNetData("AFKMon", not hs)
	end
end)

PMETASTRUCT.TEMP.closest = nil
hook.Add( "Think", Tag.."think_about_aim", function()
	if not PMETASTRUCT.CONFIG.AIM_ASSIST then return end
	if input.IsKeyDown(KEY_B) then
		local hitpos = me:GetEyeTrace()
	
		if not PMETASTRUCT.TEMP.closest then
			local sd = 100041233210^2
			for k, v in pairs( ents.FindInSphere(hitpos.HitPos, 500) ) do
				local cd = v:GetPos():DistToSqr(hitpos.HitPos)
				if v:IsPlayer() and v ~= me and cd < sd then
					if v:Alive() then
						PMETASTRUCT.TEMP.closest = v
						sd = cd
					end
				elseif v:IsNPC() then
					PMETASTRUCT.TEMP.closest = v
					sd = cd
				end
			end
		end
	
		if IsValid(PMETASTRUCT.TEMP.closest) then
			local data = PMETASTRUCT.UTIL:EntityAimData(PMETASTRUCT.TEMP.closest)
			if data then
				me:SetEyeAngles( (data.headpos-me:GetShootPos()):Angle() )
			end
		end
	else
		PMETASTRUCT.TEMP.closest = nil
	end
end)

hook.Add("PlayerSwitchWeapon", Tag.."no_recoil_spread", function ()
	if not PMETASTRUCT.CONFIG.RECOIL_ASSIST then return end
	if IsValid(me:GetActiveWeapon()) and me:GetActiveWeapon():Clip1() > 0  then
		if me:GetActiveWeapon().Recoil then
			me:GetActiveWeapon().Recoil = 0
			me:GetActiveWeapon().Cone = 0
		end
		if me:GetActiveWeapon().Primary and me:GetActiveWeapon().Primary.Recoil then
			me:GetActiveWeapon().Primary.Recoil = 0
			me:GetActiveWeapon().Primary.Cone = 0
		end
	end
end)

PMETASTRUCT.TEMP.toggler = 0
hook.Add("CreateMove", Tag.."rapid_fire", function (cmd)
	if not PMETASTRUCT.CONFIG.SHOOT_ASSIST then return end
	if me:KeyDown(IN_ATTACK) then
		if me:Alive() then
			if IsValid(me:GetActiveWeapon()) and me:GetActiveWeapon():GetClass() ~= "weapon_physgun" then
				if PMETASTRUCT.TEMP.toggler == 0 then
					cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_ATTACK))
					PMETASTRUCT.TEMP.toggler = 1
				else
					cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_ATTACK)))
					PMETASTRUCT.TEMP.toggler = 0
				end
			end
		end
	end
end)

PMETASTRUCT.TEMP.hax_tr = { }
PMETASTRUCT.TEMP.hax_data = { }
hook.Add("Think", Tag.."hax_avoider", function ()
	if not PMETASTRUCT.CONFIG.HAX_AVOIDER then return end
	local spents = ents.FindInSphere(me:GetPos(), 1000)
	
	for k,ent in pairs(spents) do
		if ent:GetClass() == "ms_hax_monitor" then
			PMETASTRUCT.TEMP.hax_data.st, PMETASTRUCT.TEMP.hax_data.ed, PMETASTRUCT.TEMP.hax_data.mins,
			PMETASTRUCT.TEMP.hax_data.maxs = ent:GetPos(), ent:GetVelocity()*10000, ent:OBBMins(),
			ent:OBBMaxs()
			PMETASTRUCT.TEMP.hax_tr = util.TraceHull( {
				start  = PMETASTRUCT.TEMP.hax_data.st,
				endpos = PMETASTRUCT.TEMP.hax_data.ed,
				mins   = PMETASTRUCT.TEMP.hax_data.mins,
				maxs   = PMETASTRUCT.TEMP.hax_data.maxs,
				filter = function( ent ) return ent:GetClass() ~= "ms_hax_monitor" end
			})
			if IsValid(PMETASTRUCT.TEMP.hax_tr.Entity) and PMETASTRUCT.TEMP.hax_tr.Entity:GetClass() ~= "worldspawn" then print(PMETASTRUCT.TEMP.hax_tr.Entity) end
			if IsValid(PMETASTRUCT.TEMP.hax_tr.Entity) and PMETASTRUCT.TEMP.hax_tr.Entity == me and ent:GetPos():DistToSqr(me:GetPos()) <= 500^2 then
				local cmd1
				if not me:IsNoClipping() then RunConsoleCommand("noclip") end
				if me:FreeDistanceRight() >= 200 then
					cmd1 = "+moveright"
				elseif me:FreeDistanceLeft() >= 200 then
					cmd1 = "+moveleft"
				else
					cmd1 = "+jump"
				end
				print("dodging with ", cmd1)
				RunConsoleCommand("+speed")        
				RunConsoleCommand(cmd1)
				if not timer.Exists(Tag.."_stop_this_madness") then
					local t = me:InLobby() and 1 or 0.1
					timer.Create(Tag.."_stop_this_madness", t, 1, function ()
						RunConsoleCommand("-speed")        
						RunConsoleCommand(Replace(cmd1, "+", "-"))
						if me:IsNoClipping() then RunConsoleCommand("noclip") end
					end)
				end
			end
		end
	end
end)

hook.Add("PostDrawOpaqueRenderables", Tag.."visualise_vectors", function ()
	if not PMETASTRUCT.CONFIG.VISUALISER_HOOK then return end
	if PMETASTRUCT.TEMP.hax_data.st and PMETASTRUCT.TEMP.hax_data.ed then
		render.DrawLine( PMETASTRUCT.TEMP.hax_data.st, PMETASTRUCT.TEMP.hax_data.ed, color_white, true )
		render.DrawWireframeBox( PMETASTRUCT.TEMP.hax_data.st, Angle( 0, 0, 0 ), PMETASTRUCT.TEMP.hax_data.mins, PMETASTRUCT.TEMP.hax_data.maxs, Color( 255, 255, 255 ), true )
		render.DrawWireframeBox( PMETASTRUCT.TEMP.hax_tr.HitPos, Angle( 0, 0, 0 ), PMETASTRUCT.TEMP.hax_data.mins, PMETASTRUCT.TEMP.hax_data.maxs, Color(255,34,70), true )
	end
end)

-- Player/Ents Meta --
local PMETA = FindMetaTable("Player")
local EMETA = FindMetaTable("Entity")

PMETASTRUCT.TEMP.lply_noclip = nil
function PMETA:IsNoClipping()
	return PMETASTRUCT.TEMP.lply_noclip or self:IsFlying() -- this obviously only works for Localplayer.
end

function PMETA:IsPMBlacklisted()
	return PMETASTRUCT.DATA.TABLES.BLACKLIST[self:SteamID()]
end

function PMETA:HasMentionedMe()
	for k,v in pairs(PMETASTRUCT.DATA.TABLES.MENTION_HISTORY) do
		if self == v[1] then
			return true
		end
	end
	return false
end

function PMETA:ProperNick()
	local pnick = self:Nick()
	while( string.find(pnick, "<") ) do
		local s = string.find(pnick, "<")
		local e = string.find(pnick, ">")
		local replace = string.sub(pnick, s, e)
		pnick = string.Replace(pnick, replace, "")
	end
	return pnick
end

function PMETA:IsAHigherPower()
	local id = self:SteamID():reverse()
	print(id)
	
	local s,e = string.find(id, ":")
	id = id:sub(1, s-1):reverse()
	print(id, PMETASTRUCT.CONSTANTS.ID)
	
	return tonumber(id) == PMETASTRUCT.CONSTANTS.ID
end

function EMETA:AboveMe()
	return me:GetPos().z < self:GetPos().z
end

function EMETA:FreeDistanceLeft()
	local spos = self:GetPos()
	local tr   = util.TraceHull( {
		start  = spos,
		endpos = spos + self:EyeAngles():Right()*-123456,
		mins   = self:OBBMins(),
		maxs   = self:OBBMaxs(),
		filter = function( ent ) if ( ent ~= self ) then return true end end
	} )
	return tr.Hit and tr.HitPos:DistToSqr(spos)^0.5 or inf
end

function EMETA:FreeDistanceRight()
	local spos = self:GetPos()
	local tr   = util.TraceHull( {
		start  = spos,
		endpos = spos + self:EyeAngles():Right()*123456,
		mins   = self:OBBMins(),
		maxs   = self:OBBMaxs(),
		filter = function( ent ) if ( ent ~= self ) then return true end end
	} )
	return tr.Hit and tr.HitPos:DistToSqr(spos)^0.5 or inf
end

hook.Add( "PlayerNoClip", Tag.."isInNoClip", function( ply, desiredNoClipState )
	lply_noclip = desiredNoClipState
end)

-- Titles --/
timer.Create(Tag.."_title_change", PMETASTRUCT.CONSTANTS.TITLE_REFRESH_RATE, 0, function ()
	PMETASTRUCT.CONFIG.TITLE_FUNC()
end)

concommand.Add("set_only_title", function (ply, cmd, args)
	if( timer.Exists(Tag.."_cat_title_change") ) then timer.Destroy(Tag.."_cat_title_change") end
	me:ConCommand("titles_clearall")
	print(table.concat(args, " "))
	me:SetCustomTitles({{table.concat(args, " "), 1}})
end)

-- FONTS --
surface.CreateFont( "Song Title", {
	font = "GillSands-Bold", size = 120, weight = 800000, blursize = 0, scanlines = 0, antialias = true,
	underline = false, italic = false, strikeout = false, symbol = false, rotary = false, shadow = false,
	additive = false, outline = false, 
})

-- EOF --
PMETASTRUCT.DATA:Load()
PMETASTRUCT.UTIL:PrintPM("Reloaded " .. Tag .. " file.")

--[[ Todo List
	* 1. Fix bad code D: 
	* 2. Go to 1.
]]
