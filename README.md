# DOD DeathNades - Written for Day of Defeat 1.3

- Rewritten by Vet(3TT3V)
- Rewritten by Wilson [29th ID]
- Original Plugin by Firestorm

## About this Plugin
This plugin is another rewrite of Firestorm's dod_dropgrenades plugin. That plugin was also rewritten by Wilson [29th ID] who added some sweet features. However, Firestorm's was written with engine instead of fakemeta, and I never could get Wilson's to work the way I thought it should, so I decided to write my own. So this rewrite is kind of a combination of those 2 plugins, plus I've added many new features. And I omitted a few of the others' features. Feature changes are listed below. Both Firestorm's original plugin and Wilson's rewrite can be obtained at www.dodplugins.net

## Description
This plugin will allow players who die, to drop the grenades they're carrying, and allows other players to pick them up and use them. The number of grenades dropped is dependent upon the plugin's control setting. The plugin's behavior is controllable by admins with level 'h' status via the 'amx_dod_deathnades' console command. The plugin has been fully tested on both Windows and LINUX servers running Amxx 1.76c.

New Features:
- Ability to control, via Admin Command, how many grenades are dropped
- Grenades will not be dropped if player commits suicide or is TKed
- Optionally reports to the killer, via chat, that the victim dropped grenades
- Optionally disallows victims killed by grenades or rockets to spawn grenades
- Grenades will fall at random locations near the victim, and at random angles
- Players may only carry 2 grenades of each type (4 grenades max)
- Ability to drop enemy grenades you've picked up
- Bots won't pickup grenades when 'use' key is not enforced
- Logs changes made by admins to the control value

Features Kept:
- Option to force players to press their 'use' key to pick up nades
- Grenade's lifespan time can be changed via cvar
- Spawns actual enemy's grenades

Features Dropped - why:
- Compatability with Zor's Smoke Grenades plugin - don't know how
- Option to drop ammobox model instead of grenade - didn't like it
- Ability to drop grenades while alive - like I'm gonna give up a nade
(Feel free to modify this plugin to re-add the features if you want them)

## Command
amx_dod_deathnades <#|?> (0 - 4, default = 2)

0. Disables the plugin
1. Drop 1 nade of YOUR TEAM'S type
2. Drops up to 2 nades of ANY type (default)
3. Drops up to 3 nades of ANY type
4. Drops ALL nades of ANY type

(Note: Of course, nades are only dropped if you have them)

## CVARS
- dod_deathnades_life <##> - Life (in seconds) of the grenade after its dropped (Default 20)
- dod_deathnades_say <0|1> - Announce to killer, in chat, that victim dropped grenades (Default 1)
- dod_deathnades_wpn <0|1> - Don't drop a grenade if killed by a grenade or rocket (Default 1)
- dod_deathnades_use <0|1> - Force players to press the 'use' key to pick up grenades (Default 0)
- dod_deathnades_glow <0|1> - Give nades a 'glowing' effect to help recognition.(Default 0)
- dod_deathnades_glow_type <-1|0|1> - Glow for dropped (-1), both (0) or live (1) nades (Default 1)
- dod_deathnades_glow_team <0|1> - Glow with yellow or use the team colors (Default 1 - team)

## CREDIT and THANKS
Firestorm - www.dodplugins.net
- Original plugin idea and code

Wilson [29th ID] - www.dodplugins.net
- The main conversion of Firestorm's plugin to fakemeta
- Implemention of the 'use' key to pickup grenades
- Giving grenades a variable lifespan
- Use of #defines instead of fakemeta_util (sweet idea)

teame06 - www.alliedmods.net
- Providing a work-around for 'dod_get_user_ammo' on LINUX machines
