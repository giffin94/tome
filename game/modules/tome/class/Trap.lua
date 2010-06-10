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

require "engine.class"
require "engine.Trap"
require "engine.interface.ActorProject"
require "engine.interface.ObjectIdentify"

module(..., package.seeall, class.inherit(
	engine.Trap,
	engine.interface.ObjectIdentify,
	engine.interface.ActorProject
))

function _M:init(t, no_default)
	engine.Trap.init(self, t, no_default)
	engine.interface.ObjectIdentify.init(self, t)
	engine.interface.ActorProject.init(self, t)
end

--- Gets the full name of the object
function _M:getName()
	local name = self.name
	if not self:isIdentified() and self:getUnidentifiedName() then name = self:getUnidentifiedName() end
	return name
end

--- Returns a tooltip for the trap
function _M:tooltip()
	if self:knownBy(game.player) then
		return self:getName()
	end
end

--- Can we disarm this trap?
function _M:canDisarm(x, y, who)
	if not engine.Trap.canDisarm(self, x, y, who) then return false end

	-- do we know how to disarm?
	if who:knowTalent(who.T_TRAP_DISARM) then
		local power = who:getTalentLevel(who.T_TRAP_DISARM) * who:getCun(25)
		if who:checkHit(power, self.disarm_power) then
			return true
		end
	end

	-- False by default
	return false
end

--- Called when disarmed
function _M:onDisarm(x, y, who)
	-- Let the actor gain exp
end

--- Called when triggered
function _M:canTrigger(x, y, who)
	if self.safe_levitation and who:attr("levitation") then return false end
	return true
end

function _M:resolveSource()
	if self.summoner_gain_exp and self.summoner then
		return self.summoner:resolveSource()
	else
		return self
	end
end

--- Identify the trap
function _M:identify(id)
	self.identified = id
end
