AddCSLuaFile()

ENT.PrintName = "Test Boss"
ENT.Author    = "26"
ENT.Type      = "nextbot"
ENT.Base      = "base_nextbot"
ENT.Spawnable = false

--[[
0       =       ragdoll
1       =       reference
2       =       idle_0
3       =       idle_1
4       =       idle_2
5       =       combatidle
6       =       combatidle_long
7       =       worm_in
8       =       worm_out
9       =       worm_in_quick
10      =       worm_out_quick
11      =       worm_die
12      =       worm_grunt
13      =       worm_taunt_02
14      =       worm_taunt_01
15      =       worm_attack_1
16      =       worm_attack_2
17      =       worm_attack_arch
18      =       worm_attack_poison
19      =       worm_hit_out_quick
20      =       worm_hit_front
21      =       worm_hit_back
22      =       worm_hit_left
23      =       worm_hit_right
24      =       worm_strafe_left
25      =       worm_strafe_right
26      =       worm_turn_left
27      =       worm_turn_right

lua_run local e=ents.Create"boss_test" e:SetPos(Vector(0,0,0)) e:Spawn()

0       =       SK_Root
1       =       SK_pre_spine
2       =       SK_Spine01
3       =       SK_Spine02
4       =       SK_Spine03
5       =       SK_Spine04
6       =       SK_Spine05
7       =       SK_Spine06
8       =       SK_L_patte1B_01
9       =       SK_L_patte1B_02
10      =       SK_L_patte1B_03
11      =       SK_L_patte1A_01
12      =       SK_L_patte1A_02
13      =       SK_L_patte1A_03
14      =       SK_R_patte1A_01
15      =       SK_R_patte1A_02
16      =       SK_R_patte1A_03
17      =       SK_R_patte1B_01
18      =       SK_R_patte1B_02
19      =       SK_R_patte1B_03
20      =       SK_head_transition
21      =       SK_Head01
22      =       SK_Head02
23      =       SK_Forward
24      =       SK_jaw_01
25      =       SK_jaw_02
26      =       SK_mandibule_L_01
27      =       SK_mandibule_L_02
28      =       SK_mandibule_L_03
29      =       SK_mandibule_R_01
30      =       SK_mandibule_R_02
31      =       SK_mandibule_R_03
32      =       SK_mandibule_R_haut_01
33      =       SK_mandibule_R_haut_02
34      =       SK_mandibule_L_haut_01
35      =       SK_mandibule_L_haut_02
36      =       SK_L_patte2B_01
37      =       SK_L_patte2B_02
38      =       SK_L_patte2B_03
39      =       SK_L_patte2A_01
40      =       SK_L_patte2A_02
41      =       SK_R_patte2A_01
42      =       SK_R_patte2A_02
43      =       SK_R_patte2A_03
44      =       SK_R_patte2B_01
45      =       SK_R_patte2B_02
46      =       SK_R_patte2B_03
47      =       SK_L_patte3B_01
48      =       SK_L_patte3B_02
49      =       SK_L_patte3B_03
50      =       SK_L_patte3A_01
51      =       SK_L_patte3A_02
52      =       SK_L_patte3A_03
53      =       SK_R_patte3A_01
54      =       SK_R_patte3A_02
55      =       SK_R_patte3A_03
56      =       SK_R_patte3B_01
57      =       SK_R_patte3B_02
58      =       SK_R_patte3B_03
59      =       SK_L_patte4A_01
60      =       SK_L_patte4A_02
61      =       SK_L_patte4A_03
62      =       SK_L_patte4B_01
63      =       SK_L_patte4B_02
64      =       SK_L_patte4B_03
65      =       SK_R_patte4A_01
66      =       SK_R_patte4A_02
67      =       SK_R_patte4A_03
68      =       SK_R_patte4B_01
69      =       SK_R_patte4B_02
70      =       SK_R_patte4B_03
71      =       SK_L_patte5B_01
72      =       SK_L_patte5B_02
73      =       SK_L_patte5B_03
74      =       SK_L_patte5A_01
75      =       SK_L_patte5A_02
76      =       SK_L_patte5A_03
77      =       SK_R_patte5A_01
78      =       SK_R_patte5A_02
79      =       SK_R_patte5A_03
80      =       SK_R_patte5B_01
81      =       SK_R_patte5B_02
82      =       SK_R_patte5B_03
83      =       __INVALIDBONE__
]]

function ENT:SetupDataTables()
	self:NetworkVar("Bool",0,"CanTakeDamage")
	self:NetworkVar("Bool",1,"CanPlaySequence")
end

function ENT:GetBName()
	return "Worm Queen"
end

if SERVER then

	ENT.ActionQueue = {}
	
	function ENT:Initialize()
		self:SetModel("models/vj_darkmessiah/giantworm.mdl")
		self:SetModelScale(1)
		self:SetCanPlaySequence(true)
		
		self:SetMaxHealth(1e4)
		self:SetHealth(1e4)
		
		self.loco:SetMaxYawRate(500)
		
		if SERVER then
			net.Start("boss.SendSound")
			net.WriteString("vj_dm_giantworm/worm_in_quick.wav")
			net.Broadcast()
		end
		--PrintTable(self:GetSequenceList())
		
		--self:Remove()
	end
	
	ENT.Target = nil
	
	function ENT:PickTarget()
		
		if self.Target and IsValid(self.Target) then
			if self.Target:Alive() then
				return self.Target
			else
				self.Target = nil
			end
		end
		
		local closest = { ply = nil, dist = 1e20 }
		for k,v in pairs(player.GetAll()) do
			local dist = v:GetPos():DistToSqr(self:GetPos())
			
			if dist < closest.dist and v:Alive() then
				closest.ply = v
				closest.dist = dist
			end
		end
		
		return closest.ply, closest.dist
		
	end
	
	function ENT:RunBehaviour()
		while true do
			if not self.PlayedSpawnAnim then
				self.PlayedSpawnAnim = true
				
				self:PlaySequenceAndWait("worm_in")
			end
			
			
			self.Target = self:PickTarget()
			if self.Target then
				if SERVER then
					-- combatidle
					if not self.PlayedCombatAnim then
						net.Start("boss.SendSound")
						net.WriteString("vj_dm_giantworm/worm_idle" .. tostring(math.random(0,2)) .. ".wav")
						net.Broadcast()
						
						local len = self:SetSequence("combatidle")
						self:ResetSequenceInfo()
						self:SetCycle(0)
						self:SetPlaybackRate(1)
						self.PlayedCombatAnim = true
						self.CombatAnimDelay = SysTime() + len
					end
					
					self.loco:FaceTowards(self.Target:GetPos())
					
					if self.PlayedCombatAnim and SysTime() > self.CombatAnimDelay then
						local rand = math.random(1, 4)
						local attacks = {
							[1] = { anim = "worm_attack_1", snd = "vj_dm_giantworm/worm_striking1.wav", delay = 1.5, cb = function(ent)

							end },
							[2] = { anim = "worm_attack_2", snd = "vj_dm_giantworm/worm_striking2.wav", delay = 1.5, cb = function(ent)

							end },
							[3] = { anim = "worm_attack_arch", snd = "vj_dm_giantworm/worm_strikingarch1.wav", delay = 2, cb = function(ent)

							end },
							[4] = { anim = "worm_attack_poison", snd = "vj_dm_giantworm/worm_strikingpoison1.wav", delay = 2, cb = function(ent)
								local e = ents.Create("boss_worm_ball")
								e:SetPos(ent:GetBonePosition(22))
								e:SetFallPos(ent.Target:GetPos())
								
								e:Spawn()
							end },
						}
						
						local a = attacks[rand]
						
						PrintTable(a)
						
						
						timer.Simple( a.delay, function()
							net.Start("boss.SendSound")
							net.WriteString(a.snd)
							net.Broadcast()
							
							a.cb(self)
						end )
						self:PlaySequenceAndWait(attacks[rand].anim)
						
						self.PlayedCombatAnim = false
						self.CombatAnimDelay = nil
						self:PickTarget()
					end
					
					
				end
			end
			
			coroutine.yield()
		end
	end
else
	function ENT:Draw()
		self:DrawModel()
	end
end