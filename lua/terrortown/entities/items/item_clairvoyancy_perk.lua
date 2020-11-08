-- author "Doctor Jew"
-- contact "http://steamcommunity.com/DoctorJew"

if SERVER then
    AddCSLuaFile()

    resource.AddWorkshop("940215686") -- This addon

    util.AddNetworkString("ttt_clairvoyant_vision")
    util.AddNetworkString("ttt_clairvoyant_vision_bought")
    util.AddNetworkString("ttt_clairvoyant_overwhelm")
else
    LANG.AddToLanguage("English", "clairvoyant_perk_name", "Clairvoyancy")
    LANG.AddToLanguage("English", "clairvoyant_perk_desc", "When somebody dies, you may see their body for a brief moment.")
    LANG.AddToLanguage("English", "clairvoyant_perk_corpse", "This person could have seen death after death..")
end

CreateConVar("ttt_clairvoyant_duration", 3, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "The duration for the clairvoyant vision in seconds.")
CreateConVar("ttt_clairvoyant_camera_distance", 150, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "The maximum allowed distance from the dead body and the camera when having a vision.")
CreateConVar("ttt_clairvoyant_outline_chance", 0.25, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Chance that the Clairvoyant will see an outline of the body (0.0 - 1.0).")
CreateConVar("ttt_clairvoyant_distance", 1800, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Minimum distance the Clairvoyant must be for clairvoyancy to trigger.")
CreateConVar("ttt_clairvoyant_outline_duration", 30, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The time the corpse outline will last for the Clairvoyant.")
CreateConVar("ttt_clairvoyant_overwhelm", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should the Clairvoyant be overwhelmed by multiple visions?")
CreateConVar("ttt_clairvoyant_overwhelm_threshold", 2, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The amount of ongoing visions that must occur for the Clairvoyant to be overwhelmed.")

ITEM.hud = Material("vgui/ttt/perks/clairvoyant_perk_hud_nobg.png")
ITEM.EquipMenuData = {
	type = "item_passive",
	name = "clairvoyant_perk_name",
	desc = "clairvoyant_perk_desc",
}
ITEM.material = "vgui/ttt/icon_brain"
ITEM.CanBuy = {ROLE_DETECTIVE}
ITEM.corpseDesc = "clairvoyant_perk_corpse"
ITEM.oldId = EQUIP_CLAIRVOYANT

hook.Add("TTTUlxInitCustomCVar", "TTTUlxInitCustomCVar.Clairvoyancy", function(name)
    ULib.replicatedWritableCvar("ttt_clairvoyant_duration", "rep_ttt_clairvoyant_duration", GetConVar("ttt_clairvoyant_duration"):GetFloat(), true, false, name)
    ULib.replicatedWritableCvar("ttt_clairvoyant_distance", "rep_ttt_clairvoyant_distance", GetConVar("ttt_clairvoyant_distance"):GetInt(), true, false, name)
    ULib.replicatedWritableCvar("ttt_clairvoyant_camera_distance", "rep_ttt_clairvoyant_camera_distance", GetConVar("ttt_clairvoyant_camera_distance"):GetFloat(), true, false, name)
    ULib.replicatedWritableCvar("ttt_clairvoyant_outline_chance", "rep_ttt_clairvoyant_outline_chance", GetConVar("ttt_clairvoyant_outline_chance"):GetFloat(), true, false, name)
    ULib.replicatedWritableCvar("ttt_clairvoyant_outline_duration", "rep_ttt_clairvoyant_outline_duration", GetConVar("ttt_clairvoyant_outline_duration"):GetInt(), true, false, name)
    ULib.replicatedWritableCvar("ttt_clairvoyant_overwhelm", "rep_ttt_clairvoyant_overwhelm", GetConVar("ttt_clairvoyant_overwhelm"):GetBool(), true, false, name)
    ULib.replicatedWritableCvar("ttt_clairvoyant_overwhelm_threshold", "rep_ttt_clairvoyant_overwhelm_threshold", GetConVar("ttt_clairvoyant_overwhelm_threshold"):GetInt(), true, false, name)
end)

if CLIENT then
    hook.Add("TTTUlxModifyAddonSettings", "TTTUlxModifyAddonSettings.Clairvoyancy", function(name)
        local tttrspnl = xlib.makelistlayout{w = 415, h = 318, parent = xgui.null}

        -- Basic Settings 
		local tttrsclp1 = vgui.Create('DCollapsibleCategory', tttrspnl)
		tttrsclp1:SetSize(390, 50)
		tttrsclp1:SetExpanded(1)
        tttrsclp1:SetLabel('Basic Settings')
        
        local tttrslst1 = vgui.Create('DPanelList', tttrsclp1)
		tttrslst1:SetPos(5, 25)
		tttrslst1:SetSize(390, 125)
        tttrslst1:SetSpacing(5)
        
        local tttrsdh11 = xlib.makeslider{label = 'ttt_clairvoyant_duration (Def. 3)', repconvar = 'rep_ttt_clairvoyant_duration', min = 0, max = 5, decimal = 1, parent = tttrslst1}
		tttrslst1:AddItem(tttrsdh11)

        local tttrsdh12 = xlib.makeslider{label = 'ttt_clairvoyant_distance (Def. 1800)', repconvar = 'rep_ttt_clairvoyant_distance', min = 0, max = 2500, decimal = 0, parent = tttrslst1}
		tttrslst1:AddItem(tttrsdh12)
	
		local tttrsdh13 = xlib.makeslider{label = 'ttt_clairvoyant_camera_distance (Def. 150)', repconvar = 'rep_ttt_clairvoyant_camera_distance', min = 0, max = 300, decimal = 1, parent = tttrslst1}
        tttrslst1:AddItem(tttrsdh13)
        
        local tttrsdh14 = xlib.makeslider{label = 'ttt_clairvoyant_outline_chance (Def. 0.25)', repconvar = 'rep_ttt_clairvoyant_outline_chance', min = 0, max = 1, decimal = 2, parent = tttrslst1}
        tttrslst1:AddItem(tttrsdh14)

        local tttrsdh15 = xlib.makeslider{label = 'ttt_clairvoyant_outline_duration (Def. 30)', repconvar = 'rep_ttt_clairvoyant_outline_duration', min = 0, max = 60, decimal = 0, parent = tttrslst1}
        tttrslst1:AddItem(tttrsdh15)

        -- Overwhelm Settings 
		local tttrsclp2 = vgui.Create('DCollapsibleCategory', tttrspnl)
		tttrsclp2:SetSize(390, 50)
		tttrsclp2:SetExpanded(1)
        tttrsclp2:SetLabel('Overwhelm Settings')
        
        local tttrslst2 = vgui.Create('DPanelList', tttrsclp2)
		tttrslst2:SetPos(5, 25)
		tttrslst2:SetSize(390, 50)
        tttrslst2:SetSpacing(5)

        local tttrsdh21 = xlib.makecheckbox{label = 'ttt_clairvoyant_overwhelm (Def. 1)', repconvar = 'rep_ttt_clairvoyant_overwhelm', parent = tttrslst2}
		tttrslst2:AddItem(tttrsdh21)

        local tttrsdh22 = xlib.makeslider{label = 'ttt_clairvoyant_overwhelm_threshold (Def. 2)', repconvar = 'rep_ttt_clairvoyant_overwhelm_threshold', min = 1, max = 5, decimal = 0, parent = tttrslst2}
		tttrslst2:AddItem(tttrsdh22)
        
        xgui.hookEvent("onProcessModules", nil, tttrspnl.processModules)
        xgui.addSubModule("Clairvoyancy", tttrspnl, nil, name)
    end)
end

if SERVER then
    local clairvoyanting = {}

    --[[Perk logic]]
    --
    hook.Add("PlayerDeath", "TTTClairvoyantPerk", function(ply, infl, attacker)
        if GetRoundState() ~= ROUND_ACTIVE then return end -- Don't do anything if the round isn't in progress!
        --if ply:IsGhost() then return end

        local visionTime = GetConVar("ttt_clairvoyant_duration"):GetFloat()
        if visionTime <= 0 then return end

        if not IsValid(ply.server_ragdoll) or (attacker:IsPlayer() and attacker:IsActiveDetective()) then return end

        local dist = GetConVar("ttt_clairvoyant_camera_distance"):GetFloat()
        local minDist = GetConVar("ttt_clairvoyant_distance"):GetInt()
        local plyfilter = {}
        local found = false
        local pls = {}

        for _, v in pairs(util.GetAlivePlayers()) do
            if v:HasEquipmentItem("item_clairvoyancy_perk") and (not clairvoyanting[v:EntIndex()] or clairvoyanting[v:EntIndex()] < CurTime()) and v:GetViewEntity() == v and v:GetPos():Distance(ply.server_ragdoll:GetPos()) >= minDist then
                table.insert(plyfilter, v)

                clairvoyanting[v:EntIndex()] = CurTime() + visionTime + 0.3
                pls[#pls + 1] = v
                found = true
                v.clairvoyancy_counter = 1
            elseif clairvoyanting[v:EntIndex()] and clairvoyanting[v:EntIndex()] > CurTime() and v.clairvoyancy_counter >= 1 then
                v.clairvoyancy_counter = v.clairvoyancy_counter + 1

                if GetConVar("ttt_clairvoyant_overwhelm"):GetBool() and v.clairvoyancy_counter >= GetConVar("ttt_clairvoyant_overwhelm_threshold"):GetInt() then
                    v:SetHealth(v:Health() - (v.clairvoyancy_counter * math.Rand(2.5, 5)))
                    net.Start("ttt_clairvoyant_overwhelm")
                    net.Send(v)
                end
            end
        end

        if found then
            local spos = ply.server_ragdoll:GetPos() + Vector(0, 0, 30)
            local rag = ply.server_ragdoll

            timer.Simple(0.3, function()
                if not IsValid(rag) or not IsValid(ply) then return end

                for _, v in pairs(pls) do
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

                    if util.PointContents(t.HitPos) ~= CONTENTS_SOLID and (t.HitPos - spos):Length() > 70 then
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

                if tpos then
                    net.WriteVector(tpos)
                end

                net.Send(plyfilter)

                timer.Create("ttt_clairvoyant_vision_" .. ply:EntIndex() .. "_" .. os.time(), visionTime + 0.3, 1, function()
                    local plyfilter2 = {}
                    local found2 = false

                    for _, v in pairs(pls) do
                        if IsValid(v) and clairvoyanting[v:EntIndex()] then
                            v:SetViewEntity(v)

                            table.insert(plyfilter2, v)

                            found2 = true

                            v:SetDSP(0)

                            v.clairvoyancy_counter = 0
                        end
                    end

                    if found2 then
                        net.Start("ttt_clairvoyant_vision")
                        net.WriteBool(false)
                        net.WriteVector(rag:GetPos())
                        net.WriteUInt(rag:EntIndex(), 16)
                        net.Send(plyfilter2)
                    end
                end)
            end)
        end
    end)

    function ITEM:Bought(ply)
        net.Start("ttt_clairvoyant_vision_bought")
        net.WriteBool(true)
        net.Send(ply)
    end

    concommand.Add("_ttt_clairvoyant_end", function(ply)
        ply:SetViewEntity(ply)
        ply:SetDSP(0)

        table.remove(clairvoyanting, ply:EntIndex())
    end)
end

if CLIENT then
    --[[Perk logic]]
    --
    local body = {}
    local num = 1
    local outlineDur = nil

    function ITEM:DrawInfo()
        if outlineDur then 
            return tostring(math.Round(outlineDur - CurTime()))
        end

        return nil
    end

    local function endClairvoyant(send, ent)
        hook.Remove("CalcView", "TTT_Clairvoyant_CalcView")
        hook.Remove("RenderScreenspaceEffects", "TTT_Clairvoyant_RenderScreenspaceEffects")
        hook.Remove("HUDPaint", "TTT_Clairvoyant_HUDPaint")

        if send then
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

            if t >= 1 then
                hook.Remove("RenderScreenspaceEffects", "TTT_Clairvoyant_RenderScreenspaceEffects1")
            end
        end)

        local rag = Entity(ent)

        if not IsValid(rag) then return end

        if math.random() > GetConVar("ttt_clairvoyant_outline_chance"):GetFloat() then return end

        chat.AddText("Clairvoyancy: ", Color(255, 255, 255), "You remembered the location of the body!")
        chat.PlaySound()

        table.insert(body, num, rag)

        num = num + 1

        if timer.Exists("RagdollHalo" .. ent) then return end

        local outlineTime = GetConVar("ttt_clairvoyant_outline_duration"):GetInt()

        outlineDur = CurTime() + outlineTime

        timer.Create("RagdollHalo" .. ent, outlineTime, 1, function()
            table.RemoveByValue(body, rag)

            outlineDur = nil

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

        hook.Add("HUDPaint", "TTT_Clairvoyant_HUDPaint", function()
            return true
        end)

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
            if not IsValid(rag) or not LocalPlayer():IsTerror() or LocalPlayer():KeyDown(IN_BACK) then
                endClairvoyant(true, rag:EntIndex())

                return
            end

            local dlight = DynamicLight(rag:EntIndex())
            if dlight then
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
                if tpos then
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
            for _, v in pairs(body) do
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

        if lastcla == turnedOn then return end

        lastcla = turnedOn

        if turnedOn == false then
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
            for _, v in ipairs(ents.FindInSphere(pos, 50)) do
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
                    if dmgtype == 2 or dmgtype == 8194 then
                        rag:EmitSound("physics/flesh/flesh_impact_bullet" .. math.random(1, 4) .. ".wav", 500, 90)
                    elseif dmgtype == 32 then
                        rag:EmitSound("physics/body/body_medium_break" .. math.random(2, 3) .. ".wav", 500, 95)
                    elseif dmgtype == 1 then
                        rag:EmitSound("physics/body/body_medium_impact_hard" .. math.random(1, 6) .. ".wav", 500, 100)

                        timer.Simple(0.2, function()
                            if IsValid(rag) then
                                rag:EmitSound("physics/body/body_medium_break" .. math.random(2, 3) .. ".wav", 500, 95)
                            end
                        end)
                    elseif dmgtype == 4 then
                        rag:EmitSound("weapons/knife/knife_stab.wav", 100, 100)
                    elseif dmgtype == 128 then
                        rag:EmitSound("physics/body/body_medium_break" .. math.random(2, 3) .. ".wav", 500, 95)
                    elseif dmgtype == 8 or dmgtype == DMG_DIRECT then
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
