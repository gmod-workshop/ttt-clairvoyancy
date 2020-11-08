if TTT2 then return end

-- author "Doctor Jew"
-- contact "http://steamcommunity.com/DoctorJew"
CreateConVar("ttt_clairvoyant_duration", 3, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "The duration for the Clairvoyant vision in seconds.")
CreateConVar("ttt_clairvoyant_camera_distance", 150, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "The maximum allowed distance from the dead body and the camera when having a vision.")
CreateConVar("ttt_clairvoyant_outline_chance", 0.25, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Chance that the Clairvoyant will see an outline of the body (0.0 - 1.0).")
CreateConVar("ttt_clairvoyant_distance", 1800, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Minimum distance the Clairvoyant must be for clairvoyancy to trigger.")
CreateConVar("ttt_clairvoyant_outline_duration", 30, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The time the corpse outline will last for the Clairvoyant.")
CreateConVar("ttt_clairvoyant_loadout", 0, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should Detectives have Clairvoyant Vision in their loadout?")
CreateConVar("ttt_clairvoyant_overwhelm", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should the Clairvoyant be overwhelmed by multiple visions?")
CreateConVar("ttt_clairvoyant_overwhelm_threshold", 2, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The amount of ongoing visions that must occur for the Clairvoyant to be overwhelmed.")

if SERVER then
    resource.AddWorkshop("940215686") -- This addon

    util.AddNetworkString("ttt_clairvoyant_vision")
    util.AddNetworkString("ttt_clairvoyant_vision_bought")
    util.AddNetworkString("ttt_clairvoyant_overwhelm")
else
    LANG.AddToLanguage("English", "clairvoyant_perk_name", "Clairvoyancy")
    LANG.AddToLanguage("English", "clairvoyant_perk_desc", "When somebody dies, you may see their body for a brief moment.")
end

EQUIP_CLAIRVOYANT = GenerateNewEquipmentID and GenerateNewEquipmentID() or 65

local perk = {
	id = EQUIP_CLAIRVOYANT,
	loadout = false,
	type = "item_passive",
	material = "vgui/ttt/icon_brain",
	name = "clairvoyant_perk_name",
	desc = "clairvoyant_perk_desc",
	hud = true
}

if SERVER then
    perk["loadout"] = GetConVar("ttt_clairvoyant_loadout"):GetBool()
end

table.insert(EquipmentItems[ROLE_DETECTIVE], perk)

if SERVER then
    local clairvoyanting = {}

    --[[Perk logic]]
    --
    hook.Add("PlayerDeath", "TTTClairvoyantPerk", function(ply, infl, attacker)
        if GetRoundState() ~= ROUND_ACTIVE then return end -- Don't do anything if the round isn't in progress!
        local visionTime = GetConVar("ttt_clairvoyant_duration"):GetFloat()
        if visionTime <= 0 then return end
        if not IsValid(ply.server_ragdoll) or (attacker:IsPlayer() and attacker:IsActiveDetective()) then return end
        local dist = GetConVar("ttt_clairvoyant_camera_distance"):GetFloat()
        local minDist = GetConVar("ttt_clairvoyant_distance"):GetInt()
        local plyfilter = {}
        local found = false
        local pls = {}

        for k, v in pairs(util.GetAlivePlayers()) do
            if v:HasEquipmentItem(EQUIP_CLAIRVOYANT) and (not clairvoyanting[v:EntIndex()] or clairvoyanting[v:EntIndex()] < CurTime()) and v:GetViewEntity() == v and v:GetPos():Distance(ply.server_ragdoll:GetPos()) >= minDist then
                table.insert(plyfilter, v)
                clairvoyanting[v:EntIndex()] = CurTime() + visionTime + 0.3
                pls[#pls + 1] = v
                found = true
                v.clairvoyancy_counter = 1
            elseif clairvoyanting[v:EntIndex()] and clairvoyanting[v:EntIndex()] > CurTime() and v.clairvoyancy_counter >= 1 then
                if GetConVar("ttt_clairvoyant_overwhelm"):GetBool() and v.clairvoyancy_counter >= GetConVar("ttt_clairvoyant_overwhelm_threshold"):GetInt() then
                    v:SetHealth(v:Health() - (v.clairvoyancy_counter * math.Rand(2.5, 5)))
                    net.Start("ttt_clairvoyant_overwhelm")
                    net.Send(v)
                end
            end
        end

        if (found) then
            local spos = ply.server_ragdoll:GetPos() + Vector(0, 0, 30)
            local rag = ply.server_ragdoll

            timer.Simple(0.3, function()
                if not IsValid(rag) or not IsValid(ply) then return end

                for k, v in pairs(pls) do
                    if IsValid(v) then
                        if IsValid(v:GetActiveWeapon()) then
                            local w = v:GetActiveWeapon()

                            if w.SetIronsights and w.GetIronsights and w:GetIronsights() then
                                w:SetIronsights(false)
                            end
                        end

                        v:SetViewEntity(ply)
                        v:SetDSP(7)
                    end
                end

                local tpos = nil

                for i = 1, 8 do
                    local a = Angle(-20, 45 * i, math.random(-15, 15))

                    local t = util.TraceLine({
                        start = spos,
                        endpos = spos + (a:Forward() * dist) - Vector(0, 0, 80),
                        filter = {ply, rag, attacker}
                    })

                    if (util.PointContents(t.HitPos) ~= CONTENTS_SOLID) and (t.HitPos - spos):Length() > 70 then
                        tpos = t.HitPos
                        break
                    end
                end

                net.Start("ttt_clairvoyant_vision")
                net.WriteBool(true)
                net.WriteVector(rag:GetPos())
                net.WriteUInt(rag:EntIndex(), 16)
                net.WriteUInt(visionTime, 16)
                net.WriteUInt(rag.dmgtype or 0, 16)

                if (tpos) then
                    net.WriteVector(tpos)
                end

                net.Send(plyfilter)

                timer.Create("ttt_clairvoyant_vision_" .. ply:EntIndex() .. "_" .. os.time(), visionTime + 0.3, 1, function()
                    local plyfilter = {}
                    local found = false

                    for k, v in pairs(pls) do
                        if IsValid(v) and clairvoyanting[v:EntIndex()] then
                            v:SetViewEntity(v)
                            table.insert(plyfilter, v)
                            found = true
                            v:SetDSP(0)
                            v.clairvoyancy_counter = 0
                        end
                    end

                    if (found) then
                        net.Start("ttt_clairvoyant_vision")
                        net.WriteBool(false)
                        net.WriteVector(rag:GetPos())
                        net.WriteUInt(rag:EntIndex(), 16)
                        net.Send(plyfilter)
                    end
                end)
            end)
        end
    end)

    hook.Add("TTTOrderedEquipment", "TTTClairvoyantPerk", function(ply, id, is_item)
        if id == EQUIP_CLAIRVOYANT then
            net.Start("ttt_clairvoyant_vision_bought")
            net.WriteBool(true)
            net.Send(ply)
        end
    end)

    concommand.Add("_ttt_clairvoyant_end", function(ply)
        ply:SetViewEntity(ply)
        ply:SetDSP(0)
        table.remove(clairvoyanting, ply:EntIndex())
    end)
end

if CLIENT then
    -- feel for to use this function for your own perk, but please credit me
    -- your perk needs a "hud = true" in the table, to work properly
    local defaultY = ScrH() / 2 + 20

    local function getYCoordinate(currentPerkID)
        local amount, i, perk = 0, 1

        while (i < currentPerkID) do
            perk = GetEquipmentItem(LocalPlayer():GetRole(), i)

            if (istable(perk) and perk.hud and LocalPlayer():HasEquipmentItem(perk.id)) then
                amount = amount + 1
            end

            i = i * 2
        end

        return defaultY - 80 * amount
    end

    local yCoordinate = defaultY

    -- best performance, but the has about 0.5 seconds delay to the HasEquipmentItem() function
    hook.Add("TTTBoughtItem", "TTTClairvoyantPerk", function()
        if (LocalPlayer():HasEquipmentItem(EQUIP_CLAIRVOYANT)) then
            yCoordinate = getYCoordinate(EQUIP_CLAIRVOYANT)
        end
    end)

    -- draw the HUD icon
    local material = Material("vgui/ttt/perks/clairvoyant_perk_hud.png")

    hook.Add("HUDPaint", "TTTClairvoyantPerk", function()
        if (LocalPlayer():HasEquipmentItem(EQUIP_CLAIRVOYANT)) then
            surface.SetMaterial(material)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(20, yCoordinate, 64, 64)
        end
    end)

    --[[Perk logic]]
    --
    local body = {}
    local num = 1

    local function endClairvoyant(send, ent)
        hook.Remove("CalcView", "TTT_Clairvoyant_CalcView")
        hook.Remove("RenderScreenspaceEffects", "TTT_Clairvoyant_RenderScreenspaceEffects")
        hook.Remove("HUDPaint", "TTT_Clairvoyant_HUDPaint")

        if (send) then
            RunConsoleCommand("_ttt_clairvoyant_end")
        end

        LocalPlayer():EmitSound("ambient/machines/thumper_dust.wav", 500, 120)
        local t = 0

        hook.Add("RenderScreenspaceEffects", "TTT_Clairvoyant_RenderScreenspaceEffects1", function()
            local tab = {
                ["$pp_colour_brightness"] = 1 - t
            }

            t = math.Approach(t, 1, FrameTime() * 5)
            DrawColorModify(tab)

            if (t >= 1) then
                hook.Remove("RenderScreenspaceEffects", "TTT_Clairvoyant_RenderScreenspaceEffects1")
            end
        end)

        local rag = Entity(ent) or nil
        if not IsValid(rag) then return end

        if math.random() > GetConVar("ttt_clairvoyant_outline_chance"):GetFloat() then return end

        chat.AddText("Clairvoyancy: ", Color(255, 255, 255), "You remembered the location of the body!")
        chat.PlaySound()

        table.insert(body, num, rag)
        num = num + 1

        if timer.Exists("RagdollHalo" .. ent) then return end

        timer.Create("RagdollHalo" .. ent, GetConVar("ttt_clairvoyant_outline_duration"):GetFloat(), 1, function()
            table.RemoveByValue(body, rag)
            num = num - 1

            chat.AddText("Clairvoyancy: ", Color(255, 255, 255), "Your memory of the body fades. . .")
            chat.PlaySound()
        end)
    end

    local function startClairvoyant(rag, duration, tpos)
        LocalPlayer():EmitSound([[ambient/atmosphere/cave_hit]] .. math.random(1, 6) .. [[.wav]], 500, 240)
        rag:EmitSound([[ambient/atmosphere/cave_hit]] .. math.random(1, 6) .. [[.wav]], 500, 240)
        LocalPlayer():EmitSound("ambient/machines/thumper_hit.wav", 500, 120)
        rag:EmitSound("ambient/machines/thumper_hit.wav", 500, 120)
        local sharp = -5
        hook.Add("HUDPaint", "TTT_Clairvoyant_HUDPaint", function() return true end)

        hook.Add("RenderScreenspaceEffects", "TTT_Clairvoyant_RenderScreenspaceEffects", function()
            local tab = {
                ["$pp_colour_addr"] = 0.2,
                ["$pp_colour_addg"] = 0.4,
                ["$pp_colour_addb"] = 0.5,
                ["$pp_colour_brightness"] = -0.4,
                ["$pp_colour_contrast"] = 1.5,
                ["$pp_colour_colour"] = 0.05,
                ["$pp_colour_mulr"] = 0,
                ["$pp_colour_mulg"] = 0,
                ["$pp_colour_mulb"] = 0
            }

            sharp = math.Approach(sharp, 0, FrameTime() * 10)
            DrawSharpen(sharp, sharp)
            DrawMaterialOverlay("effects/tp_eyefx/tpeye", (sharp * -1) + 1)
            DrawColorModify(tab)
        end)

        local fo = 0
        local ar = Angle(0, 0, math.random(-15, 15))

        hook.Add("CalcView", "TTT_Clairvoyant_CalcView", function(ply, origin, angles, fov)
            if not (IsValid(rag) and LocalPlayer():IsTerror()) or LocalPlayer():KeyDown(IN_BACK) then
                endClairvoyant(true, rag:EntIndex())

                return
            end

            local dlight = DynamicLight(rag:EntIndex())

            if (dlight) then
                dlight.pos = rag:GetPos()
                dlight.r = 255
                dlight.g = 255
                dlight.b = 255
                dlight.brightness = 0.8
                dlight.Decay = 1000
                dlight.Size = 256
                dlight.DieTime = CurTime() + 1
            end

            local view = {
                origin = origin,
                angles = angles,
                fov = fov
            }

            local eyes = rag:LookupAttachment("eyes") or 0
            eyes = rag:GetAttachment(eyes)

            if eyes then
                if (tpos) then
                    view.fov = 60 - fo
                    fo = math.Approach(fo, 40, FrameTime() * 30)
                    view.origin = tpos
                    view.angles = (eyes.Pos - tpos):Angle() + ar
                else
                    view.origin = eyes.Pos
                    view.angles = eyes.Ang
                end
            end

            return view
        end)
    end

    hook.Add("PreDrawHalos", "TTT_Clairvoyant_PreDrawHalos", function()
        if num == 0 then return end

        if GetRoundState() ~= ROUND_ACTIVE then
            for k, v in pairs(body) do
                if timer.Exists("RagdollHalo" .. v:EntIndex()) then
                    timer.Adjust("RagdollHalo" .. v:EntIndex(), 0.01, 1, function()
                        table.RemoveByValue(body, v)
                        num = num - 1
                    end)
                end
            end

            return
        end

        halo.Add(body, Color(0, 255, 0), 0, 0, 2, true, true)
    end)

    local lastcla = nil

    net.Receive("ttt_clairvoyant_vision", function()
        local turnedOn = net.ReadBool()
        local pos = net.ReadVector()
        local index = net.ReadUInt(16)
        if (lastcla == turnedOn) then return end
        lastcla = turnedOn

        if (turnedOn == false) then
            endClairvoyant(false, index)

            return
        end

        local rag = nil
        local duration = CurTime() + net.ReadUInt(16)
        local dmgtype = net.ReadUInt(16)
        local tpos = net.ReadVector()

        hook.Add("RenderScreenspaceEffects", "TTT_Clairvoyant_RenderScreenspaceEffects", function()
            local tab = {
                ["$pp_colour_addr"] = 0.2,
                ["$pp_colour_addg"] = 0.4,
                ["$pp_colour_addb"] = 0.5,
                ["$pp_colour_brightness"] = 5,
                ["$pp_colour_contrast"] = 1.5,
                ["$pp_colour_colour"] = 0.05,
                ["$pp_colour_mulr"] = 0,
                ["$pp_colour_mulg"] = 0,
                ["$pp_colour_mulb"] = 0
            }

            DrawMaterialOverlay("effects/tp_eyefx/tpeye", 10)
            DrawColorModify(tab)
        end)

        timer.Simple(0.3, function()
            for k, v in pairs(ents.FindInSphere(pos, 50)) do
                if v:GetClass() == "prop_ragdoll" then
                    rag = v
                    break
                end
            end

            if not IsValid(rag) then
                endClairvoyant(true)

                return
            end

            timer.Simple(0.1, function()
                if IsValid(rag) then
                    if (dmgtype == 2 or dmgtype == 8194) then
                        rag:EmitSound("physics/flesh/flesh_impact_bullet" .. math.random(1, 4) .. ".wav", 500, 90)
                    elseif (dmgtype == 32) then
                        rag:EmitSound("physics/body/body_medium_break" .. math.random(2, 3) .. ".wav", 500, 95)
                    elseif (dmgtype == 1) then
                        rag:EmitSound("physics/body/body_medium_impact_hard" .. math.random(1, 6) .. ".wav", 500, 100)

                        timer.Simple(0.2, function()
                            if IsValid(rag) then
                                rag:EmitSound("physics/body/body_medium_break" .. math.random(2, 3) .. ".wav", 500, 95)
                            end
                        end)
                    elseif (dmgtype == 4) then
                        rag:EmitSound("weapons/knife/knife_stab.wav", 100, 100)
                    elseif (dmgtype == 128) then
                        rag:EmitSound("physics/body/body_medium_break" .. math.random(2, 3) .. ".wav", 500, 95)
                    elseif (dmgtype == 8 or dmgtype == DMG_DIRECT) then
                        rag:EmitSound("ambient/fire/ignite1.wav", 100, 100)
                    end
                end

                startClairvoyant(rag, duration - 0.4, tpos)
            end)
        end)
    end)

    net.Receive("ttt_clairvoyant_vision_bought", function()
        local bought = net.ReadBool()
        if not bought then return end
        chat.AddText("Clairvoyancy: ", Color(255, 255, 255), "Your mind awakens to the voices of the dead. . .")
        chat.PlaySound()
    end)

    net.Receive("ttt_clairvoyant_overwhelm", function()
        chat.AddText('Clairvoyancy: ', Color(255, 255, 255), 'Your powers overwhelm your mind!')
        chat.PlaySound()
    end)
end
