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

--updated 7:33 PM 1/28/2010

local Talents = require("engine.interface.ActorTalents")

newEntity{
	define_as = "BASE_NPC_INSECT",
	type = "insect", subtype = "swarms",
	display = "I", color=colors.WHITE,
	can_multiply = 2,
	desc = "Buzzzzzzzzzzzzzzzzzzzzzzzzzzz.",
	body = { INVEN = 1 },
	autolevel = "warrior",
	ai = "dumb_talented_simple", ai_state = { talent_in=1, },
	stats = { str=1, dex=20, mag=3, con=1 },
	energy = { mod=2 },
	infravision = 20,
	combat_armor = 1, combat_def = 10,
	rank = 1,
	size_category = 1,
}

newEntity{ base = "BASE_NPC_INSECT",
	name = "midge swarm", color=colors.UMBER, image="npc/midge_swarm.png",
	desc = "A swarm of midges, they want blood.",
	level_range = {1, 25}, exp_worth = 1,
	rarity = 1,
	max_life = resolvers.rngavg(1,2),
	combat = { dam=1, atk=15, apr=20 },
}

newEntity{ base = "BASE_NPC_INSECT",
	name = "bee swarm", color=colors.GOLD, image="npc/bee_swarm.png",
	desc = "They buzz at you threateningly, as you have gotten too close to their hive.",
	level_range = {2, 25}, exp_worth = 1,
	rarity = 1,
	max_life = resolvers.rngavg(1,3),
	combat = { dam=2, atk=15, apr=20 },

	resolvers.talents{ [Talents.T_BITE_POISON]=1 },
}

newEntity{ base = "BASE_NPC_INSECT",
	name = "hornet swarm", color=colors.YELLOW, image="npc/hornet_swarm.png",
	desc = "You have intruded on their grounds, they will defend it at all costs.",
	level_range = {3, 25}, exp_worth = 1,
	rarity = 1,
	max_life = resolvers.rngavg(3,5),
	combat = { dam=5, atk=15, apr=20 },

	resolvers.talents{ [Talents.T_BITE_POISON]=2 },
}

newEntity{ base = "BASE_NPC_INSECT",
	name = "hummerhorn", color=colors.YELLOW, image="npc/hommerhorn.png",
	desc = "A giant buzzing wasp, its stinger drips venom. ",
	level_range = {16, nil}, exp_worth = 1,
	rarity = 4,
	max_life = resolvers.rngavg(5,7),
	combat = { dam=10, atk=15, apr=20 },
	can_multiply = 4,

	resolvers.talents{ [Talents.T_BITE_POISON]=3 },
}
