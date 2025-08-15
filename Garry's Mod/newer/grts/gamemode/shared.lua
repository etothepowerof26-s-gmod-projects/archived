GM.Name = "Garry's Mod RTS"
GM.Author = "twentysix"
GM.Email = "artillerybeacon@gmail.com"
GM.Website = "no"

function GM:Initialize()
	self.BaseClass:Initialize()
end

module("gmodrts", package.seeall)

teams = {
	[1] = {
		name = "Red",
		color = Color(255, 0, 0)
	},
	[2] = {
		name = "Blue",
		color = Color(0, 0, 255)
	},
	[3] = {
		name = "Green",
		color = Color(0, 255, 0)
	},
	[4] = {
		name = "Yellow",
		color = Color(255, 255, 0)
	}
}

function Print(...)
	print("[gmodrts] ", ...)
end

hook.Add("Initialize", "gmodrts", function()
	for k,v in pairs(teams) do
		Print("setting up team " .. v.name)
		team.SetUp(26 + k, v.name, v.color)
	end
	
	Print("loaded!")
end)