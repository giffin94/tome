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

local Stats = require "engine.interface.ActorStats"

newEntity{
	define_as = "BASE_GEM",
	type = "gem", subtype="white",
	display = "*", color=colors.YELLOW,
	encumber = 0,
	identified = true,
	stacking = true,
	desc = [[Gems can be sold for money or used in arcane rituals.]],
}

local function newGem(name, cost, rarity, color, min_level, max_level, tier, power, imbue, bomb)
	-- Gems, randomly lootable
	newEntity{ base = "BASE_GEM", define_as = "GEM_"..name:upper(),
		name = name:lower(), subtype = color,
		color = colors[color:upper()],
		level_range = {min_level, max_level},
		rarity = rarity, cost = cost,
		material_level = tier,
		imbue_powers = imbue,
	}
	-- Alchemist gems, not lootable, only created by talents
	newEntity{ base = "BASE_GEM", define_as = "ALCHEMIST_GEM_"..name:upper(),
		name = "alchemist "..name:lower(), type='alchemist-gem', subtype = color,
		slot = "QUIVER",
		color = colors[color:upper()],
		cost = 0,
		material_level = tier,
		alchemist_power = power,
		alchemist_bomb = bomb,
	}
end

newGem("Diamond",	5,	18,	"white",	40,	50, 5, 70,
	{ inc_stats = { [Stats.STAT_STR] = 5, [Stats.STAT_DEX] = 5, [Stats.STAT_MAG] = 5, [Stats.STAT_WIL] = 5, [Stats.STAT_CUN] = 5, [Stats.STAT_CUN] = 5, } },
	{}
)
newGem("Pearl",		5,	18,	"white",	40,	50, 5, 70,
	{ resists = {all=10} },
	{}
)
newGem("Moonstone",	5,	18,	"white",	40,	50, 5, 70,
	{ combat_def=10 },
	{}
)
newGem("Fire Opal",	5,	18,	"red",		40,	50, 5, 70,
	{ inc_damage = {all=10} },
	{}
)
newGem("Bloodstone",	5,	18,	"red",		40,	50, 5, 70,
	{ stun_immune=0.6 },
	{}
)
newGem("Ruby",		4,	16,	"red",		30,	40, 4, 65,
	{ inc_stats = { [Stats.STAT_STR] = 4, [Stats.STAT_DEX] = 4, [Stats.STAT_MAG] = 4, [Stats.STAT_WIL] = 4, [Stats.STAT_CUN] = 4, [Stats.STAT_CUN] = 4, } },
	{}
)
newGem("Amber",		4,	16,	"yellow",	30,	40, 4, 65,
	{ inc_damage = {all=8} },
	{}
)
newGem("Turquoise",	4,	16,	"green",	30,	40, 4, 65,
	{ see_invisible=10 },
	{}
)
newGem("Jade",		4,	16,	"green",	30,	40, 4, 65,
	{ resists = {all=8} },
	{}
)
newGem("Sapphire",	4,	16,	"blue",		30,	40, 4, 65,
	{ combat_def=8 },
	{}
)
newGem("Quartz",	3,	12,	"white",	20,	30, 3, 50,
	{ stun_immune=0.3 },
	{}
)
newGem("Emerald",	3,	12,	"green",	20,	30, 3, 50,
	{ resists = {all=6} },
	{}
)
newGem("Lapis Lazuli",	3,	12,	"blue",		20,	30, 3, 50,
	{ combat_def=6 },
	{}
)
newGem("Garnets",	3,	12,	"red",		20,	30, 3, 50,
	{ inc_damage = {all=6} },
	{}
)
newGem("Onyx",		3,	12,	"black",	20,	30, 3, 50,
	{ inc_stats = { [Stats.STAT_STR] = 3, [Stats.STAT_DEX] = 3, [Stats.STAT_MAG] = 3, [Stats.STAT_WIL] = 3, [Stats.STAT_CUN] = 3, [Stats.STAT_CUN] = 3, } },
	{}
)
newGem("Amethyst",	2,	10,	"violet",	10,	20, 2, 35,
	{ inc_damage = {all=4} },
	{}
)
newGem("Opal",		2,	10,	"blue",		10,	20, 2, 35,
	{ inc_stats = { [Stats.STAT_STR] = 2, [Stats.STAT_DEX] = 2, [Stats.STAT_MAG] = 2, [Stats.STAT_WIL] = 2, [Stats.STAT_CUN] = 2, [Stats.STAT_CUN] = 2, } },
	{}
)
newGem("Topaz",		2,	10,	"blue",		10,	20, 2, 35,
	{ combat_def=4 },
	{}
)
newGem("Aquamarine",	2,	10,	"blue",		10,	20, 2, 35,
	{ resists = {all=4} },
	{}
)
newGem("Ametrine",	1,	8,	"yellow",	1,	10, 1, 20,
	{ inc_damage = {all=2} },
	{}
)
newGem("Zircon",	1,	8,	"yellow",	1,	10, 1, 20,
	{ resists = {all=2} },
	{}
)
newGem("Spinel",	1,	8,	"green",	1,	10, 1, 20,
	{ combat_def=2 },
	{}
)
newGem("Citrine",	1,	8,	"yellow",	1,	10, 1, 20,
	{ lite=1 },
	{}
)
newGem("Agate",		1,	8,	"black",	1,	10, 1, 20,
	{ inc_stats = { [Stats.STAT_STR] = 1, [Stats.STAT_DEX] = 1, [Stats.STAT_MAG] = 1, [Stats.STAT_WIL] = 1, [Stats.STAT_CUN] = 1, [Stats.STAT_CUN] = 1, } },
	{}
)
