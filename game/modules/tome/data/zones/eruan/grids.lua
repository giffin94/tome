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

load("/data/general/grids/basic.lua")
load("/data/general/grids/water.lua")
load("/data/general/grids/sand.lua")

newEntity{
	define_as = "MOUNT_DOOM_PORTAL",
	name = "Farportal: Mount Doom",
	display = '&', color_r=255, color_g=0, color_b=220, back_color=colors.VIOLET,
	notice = true,
	always_remember = true,
	show_tooltip = true,
	desc = [[A farportal is a way to travel incredible distances in the blink of an eye. They usually require an external item to use. You have no idea if it is even two-way.
This one seems to go to the west, to Mount Doom, in the land of Mordor...]],

	orb_portal = {
		change_level = 1,
		change_zone = "mount-doom",
		message = "#VIOLET#You enter the swirling portal while it fades away and in the blink of an eye you set foot on hellish land, the heart of a volcano...",
		on_preuse = function(self, who)
			-- Find all portals and deactivate them
			for i = -4, 4 do for j = -4, 4 do if game.level.map:isBound(who.x + i, who.y + j) then
				local g = game.level.map(who.x + i, who.y + j, engine.Map.TERRAIN)
				if g.define_as and g.define_as == "MOUNT_DOOM_PORTAL" then g.orb_portal = nil end
			end end end
		end,
		on_use = function(self, who)
			who:setQuestStatus("pre-mount-doom", engine.Quest.DONE)
		end,
	},
}
