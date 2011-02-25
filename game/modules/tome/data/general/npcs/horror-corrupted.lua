-- ToME - Tales of Maj'Eyal
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
	define_as = "BASE_NPC_CORRUPTED_HORROR",
	type = "horror", subtype = "corrupted",
	display = "h", color=colors.WHITE,
	blood_color = colors.BLUE,
	body = { INVEN = 10 },
	autolevel = "warrior",
	ai = "dumb_talented_simple", ai_state = { ai_move="move_dmap", talent_in=3, },

	combat_armor = 0, combat_def = 0,
	combat = { atk=2, dammod={str=0.6} },
--	max_life = resolvers.rngavg(30, 50),
	stats = { str=16, con=16 },
	energy = { mod=1 },
	infravision = 20,
	rank = 2,
	size_category = 3,

	blind_immune = 1,
	no_breath = 1,
}

newEntity{ base = "BASE_NPC_CORRUPTED_HORROR",
	dredge = 1,
	name = "dremling", color=colors.SLATE,
	desc = "A small disfigured humanoid with vaguely dwarven features.  It's waraxe and shield look battered, rusted, and generally in ill repair.",
	level_range = {1, nil}, exp_worth = 1,

	combat = { atk=6, dammod={str=0.6} },
	max_life = resolvers.rngavg(30, 50),

	rarity = 1,
	rank = 2,
	size_category = 2,
	autolevel = "warrior",

	open_door = true,

	resists = { [DamageType.BLIGHT] = 20, [DamageType.DARKNESS] = 20,  [DamageType.LIGHT] = - 20 },

	body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1, QUIVER=1 },
	resolvers.drops{chance=20, nb=1, {} },
	resolvers.drops{chance=60, nb=1, {type="money"} },

	resolvers.equip{
		{type="weapon", subtype="waraxe", autoreq=true},
		{type="armor", subtype="shield", autoreq=true},
	},

	resolvers.talents{
		[Talents.T_DWARF_RESILIENCE]=1,
	},

	resolvers.sustains_at_birth(),
}

newEntity{ base = "BASE_NPC_CORRUPTED_HORROR",
	dredge = 1,
	name = "drem", color=colors.DARK_SLATE_GRAY,
	desc = "A giant black-skinned humanoid covered in spikey scabrous deposits.",
	level_range = {3, nil}, exp_worth = 1,

	combat_armor = 4, combat_def = 0,
	combat = { dam=resolvers.mbonus(45, 10), atk=2, apr=6, physspeed=2, dammod={str=0.8} },
	max_life = resolvers.rngavg(120,140),

	life_rating = 15,
	life_regen = 2,
	max_stamina = 90,

	open_door = true,

	rarity = 1,
	rank = 2,
	size_category = 4,
	autolevel = "warrior",

	resists = { [DamageType.FIRE] = -50 },
	fear_immune = 1,

	body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1, QUIVER=1 },
	resolvers.drops{chance=20, nb=1, {} },
	resolvers.drops{chance=60, nb=1, {type="money"} },

	resolvers.talents{
		[Talents.T_CARBON_SPIKES]=3,
		[Talents.T_STAMINA_POOL]=1,
		[Talents.T_STUN]=1,
	},

	resolvers.sustains_at_birth(),
}

newEntity{ base = "BASE_NPC_CORRUPTED_HORROR",
	dredge = 1,
	name = "drem master", color=colors.LIGHT_GREY,
	desc = "A disfigured humanoid with vaguely dwarven features dressed in patched together and rusted mail armor.  It seems to be in command of the others.",
	level_range = {3, nil}, exp_worth = 1,

	combat = { atk=10, dammod={str=0.6} },
	max_life = resolvers.rngavg(80, 120),

	rarity = 3,
	rank = 2,
	size_category = 3,
	autolevel = "warrior",
	ai = "dumb_talented_simple", ai_state = { ai_move="move_dmap", talent_in=1, },
	hate_regen = 0.2,

	open_door = true,

	resists = { [DamageType.BLIGHT] = 20, [DamageType.DARKNESS] = 20,  [DamageType.LIGHT] = - 20 },

	body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1, QUIVER=1 },
	resolvers.drops{chance=20, nb=1, {} },
	resolvers.drops{chance=60, nb=1, {type="money"} },

	resolvers.equip{
		{type="weapon", subtype="waraxe", autoreq=true},
		{type="armor", subtype="shield", autoreq=true},
		{type="armor", subtype="heavy", autoreq=true},
	},

	make_escort = {
		{type="horror", subtype="corrupted", name="drem", number=1, no_subescort=true},
		{type="horror", subtype="corrupted", name="dremling", number=2, no_subescort=true},
	},

	resolvers.talents{
		[Talents.T_DWARF_RESILIENCE]=1,
		[Talents.T_DREDGE_FRENZY]=3,
		[Talents.T_DOMINATE]=1,
	},

	resolvers.sustains_at_birth(),
}

newEntity{ base = "BASE_NPC_CORRUPTED_HORROR",
	name = "brecklorn", color=colors.PINK,  -- gloom bat
	desc = "A giant hairless bat.  Pestulant sores cover it's malformed body and your heart weakens as it nears.",
	level_range = {1, nil}, exp_worth = 1,

	energy = { mod=0.7 },

	combat = { atk=10, dammod={dex=0.6} },
	combat_armor = 0, combat_def = 6,
	max_life = resolvers.rngavg(10, 20),

	rarity = 2,
	rank = 2,
	size_category = 3,
	autolevel = "rogue",
	ai = "tactical", ai_state = { talent_in=2, ai_move="move_astar", },
	ai_tactic = resolvers.tactic "ranged",
	energy = { mod=1.2 },

	resists = { [DamageType.BLIGHT] = 50, [DamageType.DARKNESS] = 20,  [DamageType.LIGHT] = - 20 },

	resolvers.talents{
		[Talents.T_SPIT_BLIGHT]=1,
		[Talents.T_SHRIEK]=1,
		[Talents.T_GLOOM]=1,
	},

	resolvers.sustains_at_birth(),
}

newEntity{ base = "BASE_NPC_CORRUPTED_HORROR",
	name = "grannor'vor", color=colors.GREEN,  -- acid slug
	desc = "A large sluglike creature that moves slowly, leaving a trail of acid in its wake.",
	level_range = {2, nil}, exp_worth = 1,

	combat = { dam=5, atk=15, apr=5, damtype=DamageType.ACID },
	combat_armor = 6, combat_def = 0,
	max_life = resolvers.rngavg(40, 60),

	rarity = 2,
	rank = 2,
	size_category = 3,
	autolevel = "warrior",

	energy = { mod=0.8 },

	resists = { [DamageType.ACID] = 50, [DamageType.DARKNESS] = 20,  [DamageType.LIGHT] = - 20 },

	resolvers.talents{
		[Talents.T_CRAWL_ACID]=2,
		[Talents.T_ACID_BLOOD]=1,
	},

	resolvers.sustains_at_birth(),
}

newEntity{ base = "BASE_NPC_CORRUPTED_HORROR",
	name = "grannor'vin", color=colors.BLACK,  -- shadow slug
	desc = "A large sluglike creature that moves slowly.  Shadows seem to be drawn to it's massive form and your light dims as it approaches.",
	level_range = {2, nil}, exp_worth = 1,

	combat = { dam=5, atk=15, apr=5, damtype=DamageType.DARKNESS },
	combat_armor = 6, combat_def = 0,
	max_life = resolvers.rngavg(40, 60),
	hate_regen = 0.2,

	rarity = 4,
	rank = 2,
	size_category = 3,
	autolevel = "caster",

	energy = { mod=0.8 },

	resists = { [DamageType.DARKNESS] = 50,  [DamageType.LIGHT] = - 20 },

	resolvers.talents{
		[Talents.T_CALL_SHADOWS]=2,
		[Talents.T_CREEPING_DARKNESS]=2,
	},

	resolvers.sustains_at_birth(),
}