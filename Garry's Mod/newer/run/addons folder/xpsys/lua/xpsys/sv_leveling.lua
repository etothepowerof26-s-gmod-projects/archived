local Tag = "xpsys"

module(Tag, package.seeall)

--NoExperience = {Color(255, 60, 60), 'NO EXPERIENCE: ', Color(255, 255, 255), 'Death by suicide.'}

XPPerKill = CreateConVar(Tag .. "_xp_per_kill", "10", FCVAR_ARCHIVE)

hook.Add(Tag .. "_penalty", Tag, function(victim, inflictor, attacker)
	if inflictor:GetClass() == "prop_physics" then
		return "mult", 0.2, "Prop kill."
	elseif inflictor:GetClass() == "pac_projectile" then
		return "mult", 0.2, "Kill with a PAC projectile."
	elseif victim == attacker then
		return "mult", 0, "Death by suicide."
	end
	
	return "none", 1, "Playing the server!"
end)

hook.Add(Tag .. "_xpupdate", Tag, function(attacker, experience, multiplier)
	if ( !attacker:GetClass():find("^npc_") ) then 
		local newXP = (experience * multiplier)
		local atkXP = attacker:GetExperience() + newXP
		
		attacker:SetExperience(atkXP)
		
		SaveData(attacker)
		
		if attacker:ExpNeededToLevelUp() < 1 then
			attacker:SetExperience( attacker:GetExperience() - LevelingFormula(attacker:GetLevel()) )
			attacker:SetLevel( attacker:GetLevel() + 1 )
			PrintMessage( 3, attacker:Name() .. " has reached level " .. attacker:GetLevel() .. "!" )
			-- if experience is still too high, run the hook again
			if attacker:ExpNeededToLevelUp() < 1 then
				hook.Run( "xpsys_xpupdate", attacker, 0, 1 )
			end
		end
	end
end)