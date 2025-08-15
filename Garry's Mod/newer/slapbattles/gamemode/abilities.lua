if SERVER then
    util.AddNetworkString("Slap_AbilityCD")

    function GM:ShowAbilityCD(ply, name, cd)
        net.Start("Slap_AbilityCD")
        net.WriteString(name)
        net.WriteDouble(cd)
        net.Send(ply)
    end

    function GM:IsOnCooldown(ply, name)
        if not ply.cooldowns then return false end
        if ply.cooldowns and not ply.cooldowns[name] then return false end

        return CurTime() < ply.cooldowns[name]
    end

    function GM:Cooldown(ply, name, cd)
        if not ply.cooldowns then
            ply.cooldowns = {}
        end

        if (ply.cooldowns[name] and CurTime() > ply.cooldowns[name]) or not ply.cooldowns[name] then
            ply.cooldowns[name] = CurTime() + cd
            self:ShowAbilityCD(ply, name, cd)

            return CurTime(), CurTime() + cd
        end
    end

    concommand.Add("TestAbility", function(ply)
        local g = GAMEMODE.Gloves["Normal Glove"]
        g:AbilityUse(ply)
    end)
else
    local color_black = Color(0, 0, 0)
    local color_white = Color(255, 255, 255)
    local color_gray = Color(137, 137, 137)

    surface.CreateFont("SlapBattlesUI", {
        font = "Tahoma",
        size = 32,
        weight = 400
    })

    local scrw = ScrW()
    local scrh = ScrH()
    local barsize = 300
    local barheight = 75

    local function show(name, cd)
        local time_start = CurTime()
        local time_end = time_start + cd
        local fade_in = 0.15
        local fade_out = fade_in

        hook.Add("HUDPaint", "RenderSlapCooldown", function()
            local alpha

            if CurTime() <= time_start + fade_in then
                alpha = math.Remap(time_start + fade_in - CurTime(), 0.15, 0, 0, 255)
                -- print("start", time_start + fade_in - CurTime())
            elseif (time_end - CurTime()) < fade_out then
                alpha = math.Remap(time_end - CurTime(), 0.15, 0, 255, 0)

                if CurTime() > time_end then
                    hook.Remove("HUDPaint", "RenderSlapCooldown")

                    return
                end
            end

            color_black.a = alpha
            color_white.a = alpha
            color_gray.a = alpha
            local bx = scrw * 0.9 - barsize
            local by = scrh * 0.75 + barheight
            draw.RoundedBox(8, bx, by, barsize, barheight, color_gray)
            draw.SimpleTextOutlined(name, "SlapBattlesUI", bx + barsize / 2, by, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
            -- draw progress bar
            local margin = 10
            local pbarh = 20
            bx = bx + margin
            by = by + barheight - pbarh - margin
            local frac = (time_end - CurTime()) / cd
            surface.SetDrawColor(0, 0, 0, alpha)
            surface.DrawRect(bx, by, barsize - margin * 2, 20)
            surface.SetDrawColor(color_white)
            surface.DrawRect(bx, by, (barsize - margin * 2) * frac, 20)
        end)
    end

    net.Receive("Slap_AbilityCD", function()
        local name = net.ReadString()
        local cd = net.ReadDouble()
        show(name, cd)
    end)
end