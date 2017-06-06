AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

resource.AddWorkshop("940215686") -- This addon

util.AddNetworkString("ttt_clairvoyant_vision")
util.AddNetworkString("ttt_clairvoyant_vision_bought")

local clairvoyanting = {}
local counter = 0

include("shared.lua")

--[[Perk logic]]
--
hook.Add("PlayerDeath", "TTTClairvoyantPerk", function(ply, infl, attacker)
	if GetRoundState() ~= ROUND_ACTIVE then return end -- Don't do anything if the round isn't in progress!
	local visionTime = GetConVar("ttt_clairvoyant_vision_duration"):GetFloat()
	if visionTime <= 0 then return end
	if not IsValid(ply.server_ragdoll) or attacker:GetDetective() then return end
	local dist = GetConVar("ttt_clairvoyant_vision_camera_distance"):GetFloat()
	local plyfilter = {}
	local found = false
	local pls = {}

	for k, v in pairs(util.GetAlivePlayers()) do
		if v:HasEquipmentItem(EQUIP_CLAIRVOYANT) and (not clairvoyanting[v:EntIndex()] or clairvoyanting[v:EntIndex()] < CurTime()) and v:GetViewEntity() == v and v:GetPos():Distance(ply.server_ragdoll:GetPos()) > 1800 then
			counter = 0
			table.insert(plyfilter, v)
			clairvoyanting[v:EntIndex()] = CurTime() + visionTime + 0.3
			pls[#pls + 1] = v
			found = true
			counter = 1
		elseif clairvoyanting[v:EntIndex()] and clairvoyanting[v:EntIndex()] > CurTime() and counter >= 1 then
			counter = counter + 1
			v:SetHealth(v:Health() - (counter * math.Rand(2, 2.5)))
			v:SendLua("chat.AddText('Clairvoyancy: ', Color(255, 255, 255), 'Your powers overwhelm your mind!')")
			v:SendLua("chat.PlaySound()")
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
					end
				end

				if (found) then
					net.Start("ttt_clairvoyant_vision")
					net.WriteBool(false)
					net.WriteVector(rag:GetPos())
					net.WriteUInt(rag:EntIndex(), 16)
					net.Send(plyfilter)
					counter = 0
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