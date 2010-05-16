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

return {
	name = "Far East",
	level_range = {1, 1},
	max_level = 1,
	width = 100, height = 100,
--	all_remembered = true,
--	all_lited = true,
--	persistant = "memory",
	wilderness = true,
	wilderness_see_radius = 3,
	ambiant_music = "last",
	generator =  {
		map = {
			class = "engine.generator.map.Static",
			map = "wilderness/arda-fareast",
		},
	}
}
