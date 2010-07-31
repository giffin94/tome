-- ToME - Tales of Middle-Earth
-- Copyright (C) 2009, 2010 Nicolas Casalini
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

local Talents = require("engine.interface.ActorTalents")

newEntity{
	define_as = "BASE_NPC_ORC_RAK_SHOR",
	type = "humanoid", subtype = "orc",
	display = "o", color=colors.DARK_GREY,
	faction = "orc-pride",

	combat = { dam=resolvers.rngavg(5,12), atk=2, apr=6, physspeed=2 },

	body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1, QUIVER=1 },
	resolvers.drops{chance=20, nb=1, {} },
	resolvers.drops{chance=10, nb=1, {type="money"} },
	infravision = 20,
	lite = 2,

	life_rating = 11,
	rank = 2,
	size_category = 3,

	open_door = true,

	autolevel = "warrior",
	ai = "dumb_talented_simple", ai_state = { talent_in=3, },
	energy = { mod=1 },
	stats = { str=20, dex=8, mag=6, con=16 },
}

newEntity{ base = "BASE_NPC_ORC_RAK_SHOR",
	name = "orc necromancer", color=colors.DARK_GREY,
	desc = [[An orc dressed in black robes. He mumbles is a harsh tongue.]],
	level_range = {25, nil}, exp_worth = 1,
	rarity = 1,
	max_life = resolvers.rngavg(70,80), life_rating = 7,
	resolvers.equip{
		{type="weapon", subtype="staff", autoreq=true},
		{type="armor", subtype="cloth", autoreq=true},
	},
	combat_armor = 0, combat_def = 5,
	summon = {
		{type="undead", subtype="skeleton", number=1, hasxp=false},
		{type="humanoid", subtype="ghoul", number=1, hasxp=false},
	},
	make_escort = {
		{type="undead", subtype="ghoul", no_subescort=true, chance=50, number=resolvers.mbonus(3, 2)},
		{type="undead", subtype="skeleton", no_subescort=true, chance=50, number=resolvers.mbonus(3, 2)},
	},

	resolvers.talents{
		[Talents.T_SUMMON]=1,
--		[Talents.T_]=3,
	},
}
