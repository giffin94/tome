-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009, 2010, 2011 Nicolas Casalini
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

name = "Melinda, lucky girl"
desc = function(self, who)
	local desc = {}
	desc[#desc+1] = "After rescuing Melinda from Kryl-Feijan and the cultists you met her again in Last Hope."
	if who.female then
		desc[#desc+1] = "You talked for a while and it seems she has a crush on you, even though you are yourself a woman."
	else
		desc[#desc+1] = "You talked for a while and it seems she has a crush on you."
	end
	if self:isCompleted("moved-in") then
		desc[#desc+1] = "Melinda decided to come live with you in your Fortress."
	end
	return table.concat(desc, "\n")
end

function onWin(self, who)
	if who.dead then return end
	return 10, {
		"After your victory you came back to Last Hope and reunited with Melinda, who after many years remains free of demonic corruption.",
		"You lived together and led a happy life. Melinda even learned a few adventurer's tricks and you both traveled Eyal, making new legends.",
	}
end

function spawnFortress(self, who) game:onTickEnd(function()
	local melinda = require("mod.class.NPC").new{
		name = "Melinda",
		type = "humanoid", subtype = "human", female=true,
		display = "@", color=colors.LIGHT_BLUE,
		image = "player/cornac_female_redhair.png",
		moddable_tile = "human_female",
		moddable_tile_base = "base_redhead_01.png",
		desc = [[You saved her from the depth of a cultists lair and fell in love with her. She has moved in the Fortress to see you more often.]],
		autolevel = "tank",
		ai = "none",
		stats = { str=8, dex=7, mag=8, con=12 },
		faction = who.faction,
		never_anger = true,

		resolvers.equip{ id=true,
			{defined="SIMPLE_GOWN", autoreq=true, ego_chance=-1000}
		},

		body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1, QUIVER=1 },
		lite = 4,
		rank = 2,
		exp_worth = 0,

		max_life = 100, life_regen = 0,
		life_rating = 12,
		combat_armor = 3, combat_def = 3,

		on_die = function(self) game.player:setQuestStatus("love-melinda", engine.Quest.FAILED) end,
		can_talk = "melinda-fortress",
	}
	melinda:resolve() melinda:resolve(nil, true)
	local spot = game.level:pickSpot{type="spawn", subtype="melinda"}
	game.zone:addEntity(game.level, melinda, "actor", spot.x, spot.y)
	who:move(spot.x + 1, spot.y)

	who:setQuestStatus(self.id, self.COMPLETED, "moved-in")
end) end
