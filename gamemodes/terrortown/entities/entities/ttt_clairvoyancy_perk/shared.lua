-- author "Doctor Jew"
-- contact "http://steamcommunity.com/DoctorJew"
CreateConVar("ttt_clairvoyant_vision_duration", 2, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "The duration for the clairvoyant vision in seconds.")
CreateConVar("ttt_clairvoyant_vision_camera_distance", 150, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "The maximum allowed distance from the dead body and the camera when having a vision.")
CreateConVar("ttt_clairvoyant_vision", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should Detectives be able to buy the Clairvoyant Perk?")
CreateConVar("ttt_clairvoyant_vision_chance", 0.5, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Chance that the Detective will see an outline of the body (0.0 - 1.0).")
CreateConVar("ttt_clairvoyant_chance_duration", 20, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Time a highlighted body will be visible.")
EQUIP_CLAIRVOYANT = (GenerateNewEquipmentID and GenerateNewEquipmentID()) or 98

local perk = {
	id = EQUIP_CLAIRVOYANT,
	loadout = false,
	type = "item_passive",
	material = "vgui/ttt/icon_brain",
	name = "clairvoyant_perk_name",
	desc = "clairvoyant_perk_desc",
	hud = true
}

if (GetConVar("ttt_clairvoyant_vision"):GetBool()) then
	table.insert(EquipmentItems[ROLE_DETECTIVE], perk)
end