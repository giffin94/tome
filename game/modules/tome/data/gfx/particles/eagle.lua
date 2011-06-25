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

base_size = 64

local r = 1
local g = 1
local b = 1
local a = 1

local first = true
return { generator = function()
	return {
		trail = 0,
		life = 300,
		size = shadow and 32 or 64, sizev = 0, sizea = 0,

		x = x, xv = 0, xa = 0,
		y = y, yv = 0, ya = 0,
		dir = dir, dirv = dirv, dira = 0,
		vel = 20, velv = 0.02, vela = 0,

		r = r, rv = 0, ra = 0,
		g = g, gv = 0, ga = 0,
		b = b, bv = 0, ba = 0,
		a = a, av = 0, aa = 0,
	}
end, },
function(self)
	if first then
		self.ps:emit(1)
		first = false
	end
end,
nil,
shadow and "shockbolt/npc/birds_eagle_shadow_01" or "shockbolt/npc/birds_eagle01"