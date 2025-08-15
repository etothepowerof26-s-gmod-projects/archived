GM.Name = "GMOD Tower Defense"
GM.Author = "twentysix"
GM.Email = "artillerybeacon@gmail.com"
GM.Website = "nil"

include( 'indicator.lua' )
include( 'ulib_integration.lua' )

function GM:Initialize()
	self.BaseClass.Initialize(self)

	if SERVER then
		self:LoadWaypoints()
		self:GenerateDiffVoteSeed()
	end
	
	
end

function GM:GenerateDiffVoteSeed()
	SetGlobalInt("TowerDefenseDiffVoteSeed", math.random(1e9, 2e9))
end

local function check()
	math.randomseed(GetGlobalInt("TowerDefenseDiffVoteSeed", 0))
	local a = math.random() < ( 1/3 )
	if a then print("ULTRA")return'u' else print("HARD")return'h' end
end

GM.IsUltra = check

concommand.Add("td_check_for_ultra", check)
concommand.Add("td_regenerate_seed", GM.GenerateDiffVoteSeed)



if SERVER then

	ChatPrintColor = function( ... )
		local tab = { ... }
		net.Start( "ChatPrintColor" )
		net.WriteTable( tab )
		net.Broadcast()

		MsgC(...)
		print()
	end

else

	ChatPrintColor = chat.AddText

	net.Receive( "ChatPrintColor", function()
		chat.AddText( unpack( net.ReadTable() ) )
	end )

end