GM.RuneTable = {}

-- Helps for aliasing.
local function map(n)
	if GM.RuneTable[n] then
		return GM.RuneTable[n]
	end
	return {}
end

GM.RuneTable["damage"] = {
	Proc = function(ent)
		local attackrand = math.random(20, 40)
		
		ent:SetBAttackDamage(ent:GetBAttackDamage() * (attackrand / 10))
	end
}
GM.RuneTable["dmg"] = map("damage")
GM.RuneTable["hurt"] = map("damage")

GM.RuneTable["attack"] = {
	Proc = function(ent)
		local speedrand = math.random(20, 40)
		
		ent:SetBAttackSpeed(ent:GetBAttackSpeed() / (speedrand / 10))
	end
}
GM.RuneTable["aspeed"] = map("attack")
GM.RuneTable["attackspeed"] = map("attack")

GM.RuneTable["health"] = {
	Proc = function(ent)
		local rand = math.random(15, 30)
		
		ent:SetHealth(ent:Health() * (rand / 10))
		ent:SetMaxHealth(ent:GetMaxHealth() * (rand / 10))
	end
}
GM.RuneTable["tank"] = map("health")
GM.RuneTable["durability"] = map("health")