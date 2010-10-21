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

load("/data/general/npcs/skeleton.lua", rarity(0))
load("/data/general/npcs/ghoul.lua", rarity(0))
load("/data/general/npcs/ghost.lua", rarity(4))
load("/data/general/npcs/bone-giant.lua", rarity(3))
load("/data/general/npcs/faeros.lua", rarity(4))
load("/data/general/npcs/gwelgoroth.lua", rarity(4))
load("/data/general/npcs/aquatic_critter.lua", function(e) if e.rarity then e.aquatic_rarity, e.rarity = e.rarity, nil end end)
load("/data/general/npcs/aquatic_demon.lua", function(e) if e.rarity then e.aquatic_rarity, e.rarity = e.rarity, nil end end)

load("/data/general/npcs/all.lua", rarity(4, 35))

local Talents = require("engine.interface.ActorTalents")

newEntity{ define_as = "TANNEN",
	type = "humanoid", subtype = "human", unique = true,
	name = "Tannen",
	display = "p", color=colors.VIOLET,
	desc = [[The traitor has been revealed, and he does not intend to let you escape to tell the tale.]],
	level_range = {35, nil}, exp_worth = 2,
	max_life = 250, life_rating = 16, fixed_rating = true,
	max_mana = 850, mana_regen = 40,
	mana_regen = 15,
	rank = 4,
	size_category = 2,
	infravision = 20,
	stats = { str=10, dex=12, cun=14, mag=25, con=16 },
	movement_speed = 1.4,

	instakill_immune = 1,
	blind_immune = 1,

	body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1, QUIVER=1, },
	equipment = resolvers.equip{
		{type="weapon", subtype="staff", ego_chance=100, autoreq=true},
		{type="armor", subtype="cloth", ego_chance=100, autoreq=true},
	},
	resolvers.drops{chance=100, nb=4, {ego_chance=100} },
	resolvers.drops{chance=100, nb=1, {defined="ORB_MANY_WAYS2"} },
	resolvers.drops{chance=100, nb=1, {defined="ATHAME_WEST2"} },

	resists = { [DamageType.ACID] = 100, },

	resolvers.talents{
		[Talents.T_THROW_BOMB]=4,
		[Talents.T_CHANNEL_STAFF]=5,
		[Talents.T_STAFF_MASTERY]=5,
		[Talents.T_ALCHEMIST_PROTECTION]=5,
		[Talents.T_SHOCKWAVE_BOMB]=4,
		[Talents.T_HEAT]=4,
		[Talents.T_BODY_OF_FIRE]=3,
		[Talents.T_ACID_INFUSION]=5,
		[Talents.T_STONE_TOUCH]=3,
	},

	resolvers.generic(function(self)
		-- Make and wield some alchemist gems
		local t = self:getTalentFromId(self.T_CREATE_ALCHEMIST_GEMS)
		local gem = t.make_gem(self, t, "GEM_BLOODSTONE")
		self:wearObject(gem, true, false)
	end),

	autolevel = "dexmage",
	ai = "dumb_talented_simple", ai_state = {ai_target="target_player_radius", sense_radius=400, talent_in=1, ai_move="move_astar" },

	on_die = function(self, who)
		game.player:resolveSource():setQuestStatus("east-portal", engine.Quest.COMPLETED, "tannen-dead")
	end,
}

newEntity{ define_as = "DROLEM",
	type = "construct", subtype = "golem",
	display = 'g', color=colors.GREEN,
	desc = [[This is Tannen's construct, a #{bold}#HUGE#{normal}# golem in the rough shape of a dragon.
It is so huge that it blocks sight beyond it.]],
	level_range = {35, nil}, exp_worth=2,
	max_life = 600, life_rating = 13, fixed_rating = true,

	-- Special, the golem is HUGE and blocks LOS
	block_sight = true,

	combat = { dam=10, atk=10, apr=0, dammod={str=1} },

	resists = { [DamageType.ACID] = 100, },

	body = { INVEN = 50, MAINHAND=1, OFFHAND=1, BODY=1, HEAD=1, },
	instakill_immune = 1,
	blind_immune = 1,
	infravision = 20,
	see_invisible = 100,
	rank = 4,
	size_category = 5,
	move_others=true,

	resolvers.talents{
		[Talents.T_MASSIVE_ARMOUR_TRAINING]=5,
		[Talents.T_HEAVY_ARMOUR_TRAINING]=5,
		[Talents.T_WEAPON_COMBAT]=7,
		[Talents.T_POISON_BREATH]=6,
		[Talents.T_WEAPONS_MASTERY]=11,
	},
	resolvers.drops{chance=100, nb=1, {defined="RESONATING_DIAMOND_WEST2"} },

	resolvers.equip{
		{type="weapon", subtype="greatsword", ego_chance=100, autoreq=true},
		{type="armor", subtype="massive", ego_chance=100, autoreq=true},
		{type="armor", subtype="head", ego_chance=100, autoreq=true},
	},

	autolevel = "warrior",
	ai = "dumb_talented_simple", ai_state = { ai_target="target_player_radius", sense_radius=400, talent_in=4, },
	energy = { mod=1 },
	stats = { str=14, dex=12, mag=10, wil=67, con=12 },

	open_door = true,
	blind_immune = 1,
	fear_immune = 1,
	poison_immune = 1,
	disease_immune = 1,
	stone_immune = 1,
	see_invisible = 30,
	no_breath = 1,

	on_die = function(self, who)
		game.player:resolveSource():setQuestStatus("east-portal", engine.Quest.COMPLETED, "drolem-dead")
	end,
}
