ITEM.Name = 'Laser Trail'
ITEM.Price = 150
ITEM.Material = 'trails/laser.vmt'

function ITEM:OnEquip(ply, modifications)
	SafeRemoveEntity(ply.LaserTrail)
	ply.LaserTrail = util.SpriteTrail(ply, 0, modifications.color, false, 15, 1, 4, 0.125, self.Material)
end

function ITEM:OnHolster(ply)
	SafeRemoveEntity(ply.LaserTrail)
end

function ITEM:Modify(modifications)
	PS:ShowColorChooser(self, modifications)
end

function ITEM:OnModify(ply, modifications)
	SafeRemoveEntity(ply.LaserTrail)
	self:OnEquip(ply, modifications)
end

-- Since trails allow players to change the color we limit the table to only color for security reasons
function ITEM:SanitizeTable( modifications )
    return {color=modifications.color and Color(modifications.color.r or 255, modifications.color.g or 255, modifications.color.b or 255) or nil}
end
