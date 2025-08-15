util.AddNetworkString("tdStartDiffVote")

gameevent.Listen( "player_disconnect" )

local color_dgray = Color(170, 170, 170)
local color_green = Color(0, 255, 0)
local color_red = Color(255, 0, 0)

GM.LoadingTableCache = GM.LoadingTableCache or { }

if not GetGlobalBool("tdDiffVoteInProgress") then
	SetGlobalBool("tdDiffVoteInProgress", false)
end

function GM:CheckPassword(sid64, ip, svp, clp, name)
	ChatPrintColor( color_dgray, '[Joining] ', color_green, '+ ', team.GetColor(0), name )

	// logic for handling people loading in.
	self.LoadingTableCache[sid64] = true

	print("loading table cache added sid64")
	PrintTable(self.LoadingTableCache)

	return self.BaseClass.CheckPassword(self, sid64, ip, svp, clp, name)
end

hook.Add( "player_disconnect", "td_diffvote_removedata", function( data )
	local name = data.name			// Same as Player:Nick()
	local steamid = data.networkid	// Same as Player:SteamID()
	local bot = data.bot			// Same as Player:IsBot()
	local reason = data.reason		// Text reason for disconnected such as "Kicked by console!", "Timed out!", etc...

	ChatPrintColor( color_dgray, '[Leaving] ', color_red, '- ', team.GetColor(0), name, ' ', color_dgray, "(", reason, ")" )

	if bot then return end

	print("loading table cache removed sid64")
	GAMEMODE.LoadingTableCache[util.SteamIDTo64(steamid)] = nil

	PrintTable(GAMEMODE.LoadingTableCache)

	if #player.GetAll() < 2 then
		self.DiffVoteStarted = false
	end 
end )

function GM:PlayerFullLoad(ply, time)
	ChatPrintColor( color_dgray, ply:Nick(), " is here." )

	if not ply:IsBot() then
		self.LoadingTableCache[ply:SteamID64()] = nil
	end

	if table.Count(self.LoadingTableCache) == 0 and not self.DiffVoteStarted then
		self.DiffVoteStarted = true

		print("everyone loaded in?")
		if #player.GetAll() < 2 then
			print("nobody here...")
			return
		end

		-- start difficulty vote
		ChatPrintColor( team.GetColor(0), "Difficulty Voting time!" )
		timer.Simple( 2, function()
			net.Start('tdStartDiffVote')
				net.WriteUInt(30, 16)
			net.Send(player.GetHumans())

			self.IsUltra()
		end )
	end
end






hook.Add("PlayerSay", "balls", function(ply, txt)
	if txt != "!dv" then return end

	net.Start('tdStartDiffVote')
	net.WriteUInt(30, 16)
	net.Send(player.GetHumans())

	PrintMessage(3, "balls")
end)