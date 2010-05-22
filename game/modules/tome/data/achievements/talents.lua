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

newAchievement{
	name = "Elementalist",
	desc = [[Maxed all elemental spells.]],
	mode = "player",
	can_gain = function(self, who)
		local types = table.reverse{"spell/fire", "spell/earth", "spell/water", "spell/air"}
		local nb = 0
		for id, _ in pairs(who.talents) do
			local t = who:getTalentFromId(id)
			if types[t.type[1]] then nb = nb + who:getTalentLevelRaw(t) end
		end
		return nb >= 4 * 4 * 5
	end
}

newAchievement{
	name = "Warper",
	desc = [[Maxed all arcane, conveyance, divination, and temporal spells.]],
	mode = "player",
	can_gain = function(self, who)
		local types = table.reverse{"spell/arcane", "spell/temporal", "spell/conveyance", "spell/divination"}
		local nb = 0
		for id, _ in pairs(who.talents) do
			local t = who:getTalentFromId(id)
			if types[t.type[1]] then nb = nb + who:getTalentLevelRaw(t) end
		end
		return nb >= 4 * 4 * 5
	end
}
