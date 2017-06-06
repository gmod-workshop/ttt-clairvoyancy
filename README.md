# TTT-Clairvoyancy

**NOTICE: This Addon only works for the "Trouble in Terrorist Town" - Gamemode.**

##Features
This equipment is available for the Detective in the Equipment menu. When somebody dies, the detectives who brought the Clairvoyant Powers (and are far enough away) will receive a vision of the dead body for 2 seconds (configurable via ConVars) and afterwards they have a 50% chance (configurable via ConVars) of the body being highlighted for them.

Be careful though! This power comes at a cost. You cannot control when your visions happen, so if someone dies somewhere when you're in danger, well you're in for the ride. Too many people dying at once will cause a sensory overload and hurt you as well!

Detectives killing people will NOT trigger the perk.

After you've bought the item in the shop, an icon shows up on the left hand side of your screen to indicate, that the perk is active.

Includes an individual .vmt and .vtf shop icon.

##ConVars
- ttt_clairvoyant_vision (def: 1) - Should Detectives be able to buy the Clairvoyancy Perk?
- ttt_clairvoyant_vision_duration (def: 2) - The duration for the clairvoyant vision in seconds.
- ttt_clairvoyant_vision_camera_distance (def: 150) - The maximum allowed distance from the dead body and the camera when having a vision.
- ttt_clairvoyant_vision_chance (def: 0.5) - Chance to see an outline of the body (0 - 1).
- ttt_clairvoyant_chance_duration (def: 20) - Time a highlighted body will be visible (in seconds).

**Note: After changing these values you may have to restart your map/server. Setting 'ttt_clairvoyant_vision_chance' to 0 will disable outlining and 1 will always highlight.**

##Server Infos
Add it to your server by following this guide: http://wiki.garrysmod.com/page/Server/Workshop
You can add "clairvoyant_perk_name" and "clairvoyant_perk_desc" to your translation file, to translate this addon.

##Source
The whole source code can be found on [GitHub](https://github.com/DoctorJew/TTT-Clairvoyancy), feel free to contribute. The original addon was taken from [here](http://steamcommunity.com/sharedfiles/filedetails/?id=654341247) (but modified extensively!). I agree to remove this item if the Author or Valve wishes to.

Thanks for reading, enjoy and have fun!
