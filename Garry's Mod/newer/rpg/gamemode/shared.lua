GM.Name = "Garry's Mod Dungeon"

function GM:Initialize()
	self.BaseClass.Initialize(self)

	

end

local function load()

	print("Garry's Mod Dungeon")

	local path = "rpg/gamemode/core/"
	local files,dirs = file.Find(path .. "*", "LUA")

	local order = {
		"shared.lua",
		"sh_init.lua",
		"init.lua",
		"sv_init.lua",
		"client.lua",
		"cl_init.lua"
	}

	local realms = {
		["shared.lua"] = {
			server = true,
			client = true
		},
		["init.lua"] = {
			server = true,
		},
		["client.lua"] = {
			client = true
		}
	}
	realms["sh_init.lua"] = realms["shared.lua"]
	realms["cl_init.lua"] = realms["client.lua"]
	realms["sv_init.lua"] = realms["init.lua"]

	for k,v in pairs(dirs) do
		print("> Loading module '" .. v .. "'")

		local _files, _dirs = file.Find(path .. v .. "/*.lua", "LUA")
		
		local temp = {}
		for _k, _v in pairs(_files) do
			temp[_v] = true
		end
		_files = temp

		for i = 1, #order do
			local opt = order[i]
			if _files[opt] then
				print("  Included priortised file " .. v .. "/" .. opt)
				
				AddCSLuaFile(path .. v .. "/" .. opt)
				if realms[opt].client and CLIENT then
					include(path .. v .. "/" .. opt)
					print("  on the Client Side")
				end
				if realms[opt].server and SERVER then
					include(path .. v .. "/" .. opt)
					print("  on the Server Side")
				end
				 

			end 
		end
	end

	print("Done!")

end 

load() 
concommand.Add("rpg_force_reload", function()
	if SERVER then
		for k,v in pairs(player.GetAll()) do
			v:ConCommand("rpg_force_reload")
		end
		load()
		return
	else
		load()
	end
end)