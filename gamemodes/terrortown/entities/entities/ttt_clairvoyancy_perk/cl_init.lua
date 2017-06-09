include("shared.lua")
LANG.AddToLanguage("english", "clairvoyant_perk_name", "Clairvoyancy")
LANG.AddToLanguage("english", "clairvoyant_perk_desc", "When somebody dies, you will see their body for a brief moment.")
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

	if math.random() > GetConVar("ttt_clairvoyant_vision_chance"):GetFloat() then return end

	chat.AddText("Clairvoyancy: ", Color(255, 255, 255), "You remembered the location of the body!")
	chat.PlaySound()

	table.insert(body, num, rag)
	num = num + 1

	if timer.Exists("RagdollHalo" .. ent) then return end

	timer.Create("RagdollHalo" .. ent, GetConVar("ttt_clairvoyant_chance_duration"):GetFloat(), 1, function()
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