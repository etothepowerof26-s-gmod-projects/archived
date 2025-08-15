AddCSLuaFile()

SWEP.PrintName = "Plasma Net"

SWEP.m_bPlayPickupSound = false

SWEP.WorldModel = "models/weapons/w_shotgun.mdl"
SWEP.ViewModel = "models/weapons/c_shotgun.mdl"

SWEP.UseHands = true

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo		= "none"

SWEP.Secondary.ClipSize	  = 1
SWEP.Secondary.DefaultClip  = 1
SWEP.Secondary.Automatic	 = false
SWEP.Secondary.Ammo			= "none"

function SWEP:Deploy()
	timer.Simple( 15, function()
		if ( !IsValid(self) ) then return end
		self:GetOwner():ChatPrintColor( Color( 255, 0, 0 ), "Your plasma net disappeared! RUN!!" )
		SafeRemoveEntity( self )
		GAMEMODE:StopPlasma( self:GetOwner() )
	end )
end

function SWEP:PrimaryAttack()

	-- Make sure we can shoot first
	-- if ( !self:CanPrimaryAttack() ) then return end

	-- Play shoot sound
	self.Weapon:EmitSound("ambient/energy/weld2.wav")
	
	if SERVER then

		local ent = ents.Create( "prop_physics" )
		if ( not ent:IsValid() ) then return end

		ent:SetModel( "models/props_building_details/Storefront_Template001a_Bars.mdl" )
		ent:SetMaterial("models/props_combine/portalball001_sheet")

		local owner = self:GetOwner()
		local aimvec = owner:GetAimVector()
		local pos = aimvec * 32 -- This creates a new vector object
		pos:Add( owner:EyePos() ) -- This translates the local aimvector to world coordinates

		ent:SetPos( pos )
		ent:SetAngles( owner:EyeAngles() )
		ent:Spawn()
		ent.PlasmaNet = true
		ent.Shooter = owner
	
		local phys = ent:GetPhysicsObject()
		if ( not phys:IsValid() ) then ent:Remove() return end

		phys:EnableMotion( false )
		
		local ident = tostring(ent) .. "GoForward"
		local forward = owner:EyeAngles():Forward()
		timer.Create( ident, 0.01, 100, function()
			if ( !IsValid(ent) ) then
				timer.Remove( ident )
				return
			end
			ent:SetPos( ent:GetPos() + forward * 5 )
		end )
		timer.Simple(1, function()
			if ( !IsValid(ent) ) then
				timer.Remove( ident )
				return
			end
			timer.Remove( ident )
			ent.Shooter:ChatPrintColor( Color( 255, 0, 0 ), "Your plasma net missed! RUN!!" )
			SafeRemoveEntity( ent )
			GAMEMODE:StopPlasma( self:GetOwner() )
		end)
		GAMEMODE:StopPlasma( self:GetOwner() )
		
		self:Remove()
		--SafeRemoveEntity(self)
	end

end

function SWEP:SecondaryAttack()
	return false
end

function GAMEMODE:PlasmaNetThink(ent, hit)
	if ( hit:GetClass():find( "^prop_" ) and hit.PlasmaNet and not ent.Netted ) then
		ent.Netted = true
		ent.NetStart = SysTime()
		ent.NetPos = ent:GetPos()
		if ( hit.Shooter and IsValid( hit.Shooter ) ) then
			hit.Shooter:ChatPrintColor( Color( 0, 255, 0 ), "The plasma net hit the target!" )
			if ( hit.Shooter.PS2_AddStandardPoints ) then
				hit.Shooter:PS2_AddStandardPoints( 250, "successful plasma net", false )
			end
		end
		ent.Shooter = hit.Shooter
		hit:Remove()
		ent:EmitSound( "npc/dog/dog_alarmed1.wav" )
	end
	return false
end

function GAMEMODE:PlasmaNetThink2(ent)
	if ( ent.Netted ) then
		if ( !ent.NetStart ) then 
			ent.NetStart = SysTime()
		end
		if ( SysTime() > ent.NetStart + 8 ) then
			ent.Netted = false
			ent.Shooter:ChatPrintColor( team.GetColor(0), "The plasma net's effect wore off." )
			return false
		else
			ent:SetPos( ent.NetPos or Vector( 0, 0, 0 ) )
			return true
		end
	end
	return false
end
