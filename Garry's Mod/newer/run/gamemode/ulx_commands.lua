function GM.ULX_ClearRunners( caller, target )
	GAMEMODE:ClearRunners( target[1] )
	ulx.fancyLogAdmin( caller, "#A cleared #T's runners", target )
	target[1].stopped = true
end
local clear = ulx.command( "RUN", "run clearrunners", GM.ULX_ClearRunners, { "!clearrunners", "!clear" } )
clear:addParam{ type=ULib.cmds.PlayersArg }
clear:defaultAccess( ULib.ACCESS_ADMIN )
clear:help( "Clears the runners for a player." )

function GM.ULX_StopRunners( caller, target )
	timer.Remove( tostring(target[1]) )
	timer.Remove( tostring(target[1]) .. "s" )
	timer.Remove( tostring(target[1]) .. "p" )
	target[1].stopped = true
	ulx.fancyLogAdmin( caller, "#A stopped #T's runner spawn cycle", target )
end
local clear = ulx.command( "RUN", "run stoprunners", GM.ULX_StopRunners, { "!stoprunners" } )
clear:addParam{ type=ULib.cmds.PlayersArg }
clear:defaultAccess( ULib.ACCESS_ADMIN )
clear:help( "Stops runner spawns for a player." )

function GM.ULX_SpawnRunners( caller, target, amnt )
	timer.Create( "spawnRunners" .. tostring( caller ), 0, amnt, function()
		GAMEMODE:CreateRunners( target[1] )
	end )
	ulx.fancyLogAdmin( caller, "#A spawned #i runners for #T", amnt, target )
end
local clear = ulx.command( "RUN", "run spawnrunners", GM.ULX_SpawnRunners, { "!spawnrunners" } )
clear:addParam{ type=ULib.cmds.PlayersArg }
clear:addParam{ type=ULib.cmds.NumArg, min=1, max=30 }
clear:defaultAccess( ULib.ACCESS_ADMIN )
clear:help( "Spawns runners for player." )

function GM.ULX_ForceCrateSpawn( caller )
	GAMEMODE.lastSupplyCrate = SysTime() - 199239293
	timer.Simple( 0, function()
		caller:SetPos( GAMEMODE.SupplyCrate:GetPos() )
	end )
	ulx.fancyLogAdmin( caller, "#A forced a supply crate spawn" )
end
local clear = ulx.command( "RUN", "run forcecrate", GM.ULX_ForceCrateSpawn, { "!forcecrate" } )
clear:defaultAccess( ULib.ACCESS_ADMIN )
clear:help( "Forces the supply crate to spawn in." )