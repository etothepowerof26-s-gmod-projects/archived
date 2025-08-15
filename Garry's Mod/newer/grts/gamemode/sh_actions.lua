module("gmodrts", package.seeall)

-- TODO: Attack Rules?
if SERVER then
	
	util.AddNetworkString("grts_npcaction")
	
	-- Allows you to buy and sell things, such as buildings and NPCs
	util.AddNetworkString("grts_buy")
	util.AddNetworkString("grts_sell")
	util.AddNetworkString("grts_openmenu")
	
	net.Receive("grts_npcaction", function(len, ply)
		local entity = net.ReadEntity()
		local mode = net.ReadInt(8)
		
		if entity:GetCOwner() == ply then
			
			-- Unselect
			if mode == 0 then
				entity:SetNWInt("grts_selected", 0)
				ply:SetNWBool("grts_selecting", false)
				
				return
			-- Select
			elseif mode == 1 then
				entity:SetNWInt("grts_selected", 1)
			-- Attack
			elseif mode == 2 then
				entity:SetNWInt("grts_selected", 2)
			-- Anything else
			else
				print("Invalid mode? ", mode, "(" .. tostring(ply) .. ")")
				return
			end
			
			ply:SetNWBool("grts_selecting", true)
			
			net.Start("grts_npcaction")
			net.WriteInt(mode, 8)
			net.WriteEntity(entity)
			net.Send(ply)
			
		else
			ply:ChatPrint("Not your entity.")
		end
		
		--[[local isSelected = net.ReadBool()
		local isAttack = net.ReadBool()
		
		if entity:GetCOwner() == ply then
			entity:SetNWBool("grts_selected", not isSelected)
			ply:SetNWBool("grts_selecting", true)
			
			entity:SetNWBool("grts_select_attack", isAttack)
			
			net.Start(Tag)
				net.WriteString("Select")
				net.WriteEntity(entity)
			net.Send(ply)
		else
			ply:CQRS_ChatPrint("This is not your entity! WTF are you doing?")
		end]]
	end)
	
	-- TODO
	net.Receive("grts_buy", function(len, ply) end)
	net.Receive("grts_sell", function(len, ply) end)
end

if CLIENT then

	local me = LocalPlayer()
	move_table = {}
	
	hook.Add("KeyPress", "grts_move", function(ply, key)
		if not IsFirstTimePredicted() then return end
		
		if (key == IN_USE) then
			local selecting = me:GetNWBool("grts_is_selecting", false)
			if not selecting then return end
			
			local tr = me:GetEyeTrace()
			if tr.Entity == game.GetWorld() then
				net.Start("grts_npcmove")
					net.WriteTable(move_table)
					net.WriteVector(tr.HitPos)
				net.SendToServer()
				
				move_table = {}	
			else
				local ent = tr.Entity
				local cl = ent:GetClass()
				
				local IsMedic = (next(move_table) ~= nil and #move_table == 1) and move_table[1]:GetClass() == "grts_npc_medic"
				
				if cl:find("grts_") and (ent:GetCOwner() ~= LocalPlayer() or not IsMedic) then
					-- TODO: Refactor
					
					net.Start("grts_npcattack")
						net.WriteTable(move_table)
						net.WriteVector(tr.HitPos)
						net.WriteEntity(tr.Entity)
					net.SendToServer()
					
					move_table = {}
				end
			end
		end
	end)
	
	net.Receive("grts_npcaction", function(len)
		local mode = net.ReadInt(8)
		
		if mode == 1 or mode == 2 then
			local ent = net.ReadEntity()
			
			table.insert(move_table, ent)
		end
	end)
	
	local menuCreated = false
	local function createActionMenu(ent)
		if menuCreated then return end
		
		local frame = vgui.Create("DFrame")
		frame:SetSize(300, 500)
		frame:SetTitle("Conquerors Action Menu")
		frame:Center()
		frame:MakePopup()
		
		local o = frame.Close
		frame.Close = function(self)
			o(self)
			
			surface.PlaySound'buttons/button22.wav'
			menuCreated = false
		end
		
		local isSelected = ent:GetNWInt("grts_selected", 0)
		local move = vgui.Create("DButton", frame)
		move:SetPos(10, 30)
		move:SetSize(135, 25)
		move:SetText(isSelected and "Stop Moving" or "Move")
		move.DoClick = function(self)
			frame:Close()
			
			net.Start("grts_npcaction")
				net.WriteEntity(ent)
				net.WriteInt(1, 8)
			net.SendToServer()
			
			table.insert(move_table, ent)
		end
		
		local isAttacking = ent:GetNWInt("grts_selected", 0) == 2
		local attack = vgui.Create("DButton", frame)
		attack:SetPos(155, 30)
		attack:SetSize(135, 25)
		attack:SetText(isAttacking and "Attack" or "Stop Attacking")
		attack.DoClick = function(self)
			frame:Close()
			
			net.Start("grts_npcaction")
				net.WriteEntity(ent)
				net.WriteInt(2, 8)
			net.SendToServer()
			
			table.insert(move_table, ent)
		end
		
		local deltarget = vgui.Create("DButton", frame)
		deltarget:SetPos(10, 400)
		deltarget:SetSize(135, 25)
		deltarget:SetText("Stop Targeting")
		deltarget.DoClick = function(self)
			frame:Close()
			
			net.Start("grts_npcaction")
				net.WriteEntity(ent)
				net.WriteInt(0, 8)
			net.SendToServer()
		end
		
		
		menuCreated = true
	end
	
	net.Receive("grts_openmenu", function(len)
		local ent = net.ReadEntity()
		createActionMenu(ent)
	end)

end