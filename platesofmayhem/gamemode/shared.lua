GM.Name = "Plates Of Mayhem"
GM.Author = "26 E's"
DeriveGamemode("base")

function GM:Initialize()
	self.BaseClass.Initialize(self)
end
local TEAM_SPEC, TEAM_PLAY = 1, 2

team.SetUp(TEAM_SPEC, "Spectators", Color(190, 190, 190))
team.SetUp(TEAM_PLAY, "Players", Color(0, 255, 0))

util.PrecacheModel("models/player/Group03/Male_07.mdl") 