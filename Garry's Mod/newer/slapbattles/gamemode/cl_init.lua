include("shared.lua")
include("outline.lua")
include("abilities.lua")
local smol = Vector(10, 10, 10)

local hull_trace = {
    -- start = pos, -- endpos = pos - (angles:Forward() * 100),
    mins = -smol,
    maxs = smol,
    mask = MASK_SHOT_HULL,
    filter = GM.Trace_Slap
}

local function GetNewCameraPos(ply, pos, angles, filter)
    hull_trace.start = pos
    hull_trace.endpos = pos - (angles:Forward() * 100)

    return util.TraceHull(hull_trace).HitPos
end

function PrintBones(entity)
    for i = 0, entity:GetBoneCount() - 1 do
        print(i, entity:GetBoneName(i))
    end
end

local FakeView

function GM:CalcView(ply, pos, angles, fov)
    local view = {}
    view.origin = GetNewCameraPos(ply, pos, angles)
    view.angles = angles
    view.fov = fov
    view.drawviewer = true
    local our_ragdoll = ply:GetNWEntity("Ragdoll", nil)

    if IsValid(our_ragdoll) then
        if not FakeView then
            FakeView = angles
        end

        LocalPlayer():SetEyeAngles(FakeView)
        local newpos = our_ragdoll:GetPos()
        view.origin = GetNewCameraPos(ply, newpos, FakeView)
        view.angles = FakeView
        view.drawviewer = false
    else
        if FakeView then
            LocalPlayer():SetEyeAngles(FakeView)
            FakeView = nil
        end
    end

    return view
end

hook.Add("CreateMove", "slap_ragdoll_camera", function(cmd)
    if FakeView then
        FakeView = FakeView + Angle(cmd:GetMouseY() * .022, cmd:GetMouseX() * -.022, 0)
        FakeView:Normalize()
        FakeView.x = math.Clamp(FakeView.x, -89, 89)
        cmd:SetForwardMove(0)
        cmd:SetSideMove(0)
        -- cmd:SetViewAngles(fakeview);
    end
end)

function GM:HUDDrawTargetID()
    local tr = util.GetPlayerTrace(LocalPlayer())
    local trace = util.TraceLine(tr)
    if (not trace.Hit) then return end
    if (not trace.HitNonWorld) then return end
    local text = "ERROR"
    local font = "TargetID"

    if (trace.Entity:IsPlayer()) then
        if IsValid(GetRagdoll(trace.Entity)) then return end
        text = trace.Entity:Nick()
    else
        return
    end

    surface.SetFont(font)
    local w, h = surface.GetTextSize(text)
    local MouseX, MouseY = input.GetCursorPos()

    if (MouseX == 0 and MouseY == 0) then
        MouseX = ScrW() / 2
        MouseY = ScrH() / 2
    end

    local x = MouseX
    local y = MouseY
    x = x - w / 2
    y = y + 30
    -- The fonts internal drop shadow looks lousy with AA on
    draw.SimpleText(text, font, x + 1, y + 1, Color(0, 0, 0, 120))
    draw.SimpleText(text, font, x + 2, y + 2, Color(0, 0, 0, 50))
    draw.SimpleText(text, font, x, y, self:GetTeamColor(trace.Entity))
    y = y + h + 5
    text = trace.Entity:Health() .. "%"
    font = "TargetIDSmall"
    surface.SetFont(font)
    w, h = surface.GetTextSize(text)
    x = MouseX - w / 2
    draw.SimpleText(text, font, x + 1, y + 1, Color(0, 0, 0, 120))
    draw.SimpleText(text, font, x + 2, y + 2, Color(0, 0, 0, 50))
    draw.SimpleText(text, font, x, y, self:GetTeamColor(trace.Entity))
end

net.Receive("slap_visible_ply", function()
    local ent = net.ReadEntity()
    local visible = net.ReadBit() == 1

    if visible then
        local color = ent.OldColor or color_white
        ent:SetColor(color)
    else
        ent.OldColor = ent:GetColor()
        ent:SetRenderMode(RENDERMODE_TRANSALPHA)
        ent:SetColor(Color(0, 0, 0, 0))
    end
end)

do
    return
end

-- testing hull trace shit.
local hull_offsets = {
    {0.0, 0.0, 0.0},
    {0.0, 0.0, 1.0},
    {0.0, 0.0, -1.0},
    {0.0, 1.0, 0.0},
    {0.0, -1.0, 0.0},
    {1.0, 0.0, 0.0},
    {-1.0, 0.0, 0.0},
    {-1.0, 1.0, 1.0},
    {1.0, 1.0, 1.0},
    {1.0, -1.0, 1.0},
    {1.0, 1.0, -1.0},
    {-1.0, -1.0, 1.0},
    {1.0, -1.0, -1.0},
    {-1.0, 1.0, -1.0},
    {-1.0, -1.0, -1.0},
    {0.0, 0.0, 2.0},
    {0.0, 0.0, -2.0},
    {0.0, 2.0, 0.0},
    {0.0, -2.0, 0.0},
    {2.0, 0.0, 0.0},
    {-2.0, 0.0, 0.0},
    {-2.0, 2.0, 2.0},
    {2.0, 2.0, 2.0},
    {2.0, -2.0, 2.0},
    {2.0, 2.0, -2.0},
    {-2.0, -2.0, 2.0},
    {2.0, -2.0, -2.0},
    {-2.0, 2.0, -2.0},
    {-2.0, -2.0, -2.0},
    {0.0, 0.0, 3.0},
    {0.0, 0.0, -3.0},
    {0.0, 3.0, 0.0},
    {0.0, -3.0, 0.0},
    {3.0, 0.0, 0.0},
    {-3.0, 0.0, 0.0},
    {-3.0, 3.0, 3.0},
    {3.0, 3.0, 3.0},
    {3.0, -3.0, 3.0},
    {3.0, 3.0, -3.0},
    {-3.0, -3.0, 3.0},
    {3.0, -3.0, -3.0},
    {-3.0, 3.0, -3.0},
    {-3.0, -3.0, -3.0},
    {0.0, 0.0, 4.0},
    {0.0, 0.0, -4.0},
    {0.0, 4.0, 0.0},
    {0.0, -4.0, 0.0},
    {4.0, 0.0, 0.0},
    {-4.0, 0.0, 0.0},
    {-4.0, 4.0, 4.0},
    {4.0, 4.0, 4.0},
    {4.0, -4.0, 4.0},
    {4.0, 4.0, -4.0},
    {-4.0, -4.0, 4.0},
    {4.0, -4.0, -4.0},
    {-4.0, 4.0, -4.0},
    {-4.0, -4.0, -4.0},
    {0.0, 0.0, 5.0},
    {0.0, 0.0, -5.0},
    {0.0, 5.0, 0.0},
    {0.0, -5.0, 0.0},
    {5.0, 0.0, 0.0},
    {-5.0, 0.0, 0.0},
    {-5.0, 5.0, 5.0},
    {5.0, 5.0, 5.0},
    {5.0, -5.0, 5.0},
    {5.0, 5.0, -5.0},
    {-5.0, -5.0, 5.0},
    {5.0, -5.0, -5.0},
    {-5.0, 5.0, -5.0},
    {-5.0, -5.0, -5.0}
}

local Ent = LocalPlayer()

local Points = {Vector(Ent:OBBMaxs().x, Ent:OBBMaxs().y, Ent:OBBMaxs().z), Vector(Ent:OBBMaxs().x, Ent:OBBMaxs().y, Ent:OBBMins().z), Vector(Ent:OBBMaxs().x, Ent:OBBMins().y, Ent:OBBMins().z), Vector(Ent:OBBMaxs().x, Ent:OBBMins().y, Ent:OBBMaxs().z), Vector(Ent:OBBMins().x, Ent:OBBMins().y, Ent:OBBMins().z), Vector(Ent:OBBMins().x, Ent:OBBMins().y, Ent:OBBMaxs().z), Vector(Ent:OBBMins().x, Ent:OBBMaxs().y, Ent:OBBMins().z), Vector(Ent:OBBMins().x, Ent:OBBMaxs().y, Ent:OBBMaxs().z)}

local fakeplayer = {
    vec = nil,
    LocalToWorld = function(self, asd) return self.vec + asd end
}

local function drawInfo(ply, col)
    local V1, V2, V3, V4, V5, V6, V7, V8 = unpack(Points)
    local color_white = col or color_white

    if isvector(ply) then
        local vec = ply
        ply = fakeplayer
        ply.vec = vec
    end

    V1 = ply:LocalToWorld(V1)
    V2 = ply:LocalToWorld(V2)
    V3 = ply:LocalToWorld(V3)
    V4 = ply:LocalToWorld(V4)
    V5 = ply:LocalToWorld(V5)
    V6 = ply:LocalToWorld(V6)
    V7 = ply:LocalToWorld(V7)
    V8 = ply:LocalToWorld(V8)
    render.SetColorMaterial()
    render.DrawLine(V4, V6, color_white, false)
    render.DrawLine(V1, V8, color_white, false)
    render.DrawLine(V6, V8, color_white, false)
    render.DrawLine(V4, V1, color_white, false)
    --Bottom Box
    render.DrawLine(V3, V5, color_white, false)
    render.DrawLine(V2, V7, color_white, false)
    render.DrawLine(V3, V2, color_white, false)
    render.DrawLine(V5, V7, color_white, false)
    --Verticals
    render.DrawLine(V3, V4, color_white, false)
    render.DrawLine(V2, V1, color_white, false)
    render.DrawLine(V7, V8, color_white, false)
    render.DrawLine(V5, V6, color_white, false)
end

local thick = Vector(32, 32, 72)

hook.Remove("PostDrawOpaqueRenderables", "ass", function()
    local ply = LocalPlayer()
    local pos = ply:GetPos()
    local maxs = Vector(ply:OBBMaxs().X / ply:GetModelScale(), ply:OBBMaxs().Y / ply:GetModelScale(), ply:OBBMaxs().Z / ply:GetModelScale())

    if ply:Crouching() then
        maxs.z = maxs.z / 2
    end

    local mins = -maxs

    for i = 1, #hull_offsets do
        local e = LocalPlayer():GetPos() + Vector(unpack(hull_offsets[i])) * thick
        local tr = util.TraceBoundingBox(LocalPlayer(), e)
        -- PrintTable(tr)
        drawInfo(e, tr.Hit and Color(255, 0, 0) or color_white)

        if tr.Hit then
            render.DrawLine(e, tr.HitPos, Color(255, 255, 0), false)
        end

        render.DrawWireframeBox(pos, Angle(), mins, maxs, color_white)
        -- break
    end
end)