-- TE4 - T-Engine 4
-- Copyright (C) 2009 - 2014 Nicolas Casalini
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

--- Handles actors temporary effects (temporary boost of a stat, ...)
module(..., package.seeall, class.make)

_M.tempeffect_def = {}

--- Defines actor temporary effects
-- Static!
function _M:loadDefinition(file, env)
	local f, err = util.loadfilemods(file, setmetatable(env or {
		DamageType = require "engine.DamageType",
		TemporaryEffects = self,
		newEffect = function(t) self:newEffect(t) end,
		load = function(f) self:loadDefinition(f, getfenv(2)) end
	}, {__index=_G}))
	if not f and err then error(err) end
	f()
end

--- Defines one effect
-- Static!
function _M:newEffect(t)
	assert(t.name, "no effect name")
	assert(t.desc, "no effect desc")
	assert(t.type, "no effect type")
	t.name = t.name:upper()
	t.activation = t.activation or function() end
	t.deactivation = t.deactivation or function() end
	t.parameters = t.parameters or {}
	t.type = t.type or "physical"
	t.status = t.status or "detrimental"
	t.decrease = t.decrease or 1

	self.tempeffect_def["EFF_"..t.name] = t
	t.id = "EFF_"..t.name
	self["EFF_"..t.name] = "EFF_"..t.name
end


function _M:init(t)
	self.tmp = self.tmp or {}
end

--- Counts down timed effects, call from your actors "act" method
-- @param filter if not nil a function that gets passed the effect and its parameters, must return true to handle the effect
function _M:timedEffects(filter)
	local todel = {}
	local def
	for eff, p in pairs(self.tmp) do
		def = _M.tempeffect_def[eff]
		if not filter or filter(def, p) then
			if p.dur <= 0 then
				todel[#todel+1] = eff
			else
				if def.on_timeout then
					if p.src then p.src.__project_source = p end -- intermediate projector source
					if def.on_timeout(self, p) then
						todel[#todel+1] = eff
					end
					if p.src then p.src.__project_source = nil end
				end
			end
			p.dur = p.dur - def.decrease
		end
	end

	while #todel > 0 do
		self:removeEffect(table.remove(todel))
	end
end

--- Sets a timed effect on the actor
-- @param eff_id the effect to set
-- @param dur the number of turns to go on
-- @param p a table containing the effects parameters
-- @parm silent true to suppress messages
function _M:setEffect(eff_id, dur, p, silent)
	local had = self.tmp[eff_id]

	-- Beware, setting to 0 means removing
	if dur <= 0 then return self:removeEffect(eff_id) end
	dur = math.floor(dur)

	for k, e in pairs(_M.tempeffect_def[eff_id].parameters) do
		if not p[k] then p[k] = e end
	end
	p.dur = dur
	p.effect_id = eff_id
	self:check("on_set_temporary_effect", eff_id, _M.tempeffect_def[eff_id], p)
	if p.dur <= 0 then return self:removeEffect(eff_id) end

	-- If we already have it, we check if it knows how to "merge", or else we remove it and re-add it
	if self:hasEffect(eff_id) then
		if _M.tempeffect_def[eff_id].on_merge then
			self.tmp[eff_id] = _M.tempeffect_def[eff_id].on_merge(self, self.tmp[eff_id], p)
			self.changed = true
			return
		else
			self:removeEffect(eff_id, true, true)
		end
	end

	self.tmp[eff_id] = p
	if _M.tempeffect_def[eff_id].on_gain then
		local ret, fly = _M.tempeffect_def[eff_id].on_gain(self, p)
		if not silent and not had then
			if ret then
				game.logSeen(self, ret:gsub("#Target#", self.name:capitalize()):gsub("#target#", self.name))
			end
			if fly and game.flyers and self.x and self.y and game.level.map.seens(self.x, self.y) then
				local sx, sy = game.level.map:getTileToScreen(self.x, self.y)
				if game.level.map.seens(self.x, self.y) then game.flyers:add(sx, sy, 20, (rng.range(0,2)-1) * 0.5, -3, fly, {255,100,80}) end
			end
		end
	end
	if _M.tempeffect_def[eff_id].activate then _M.tempeffect_def[eff_id].activate(self, p) end
	self.changed = true
	self:check("on_temporary_effect_added", eff_id, _M.tempeffect_def[eff_id], p)
end

--- Check timed effect
-- @param eff_id the effect to check for
-- @return either nil or the parameters table for the effect
function _M:hasEffect(eff_id)
	return self.tmp[eff_id]
end

--- Removes the effect
function _M:removeEffect(eff, silent, force)
	local p = self.tmp[eff]
	if not p then return end
	if _M.tempeffect_def[eff].no_remove and not force then return end
	self.tmp[eff] = nil
	self.changed = true
	if _M.tempeffect_def[eff].on_lose then
		local ret, fly = _M.tempeffect_def[eff].on_lose(self, p)
		if not silent then
			if ret then
				game.logSeen(self, ret:gsub("#Target#", self.name:capitalize()):gsub("#target#", self.name))
			end
			if fly and game.flyers and self.x and self.y then
				local sx, sy = game.level.map:getTileToScreen(self.x, self.y)
				if game.level.map.seens(self.x, self.y) then game.flyers:add(sx, sy, 20, (rng.range(0,2)-1) * 0.5, -3, fly, {255,100,80}) end
			end
		end
	end
	if p.__tmpvals then
		for i = 1, #p.__tmpvals do
			self:removeTemporaryValue(p.__tmpvals[i][1], p.__tmpvals[i][2])
		end
	end
	if _M.tempeffect_def[eff].deactivate then _M.tempeffect_def[eff].deactivate(self, p) end
	self:check("on_temporary_effect_removed", eff, _M.tempeffect_def[eff], p)
end

--- Removes the effect
function _M:removeAllEffects()
	local todel = {}
	for eff, p in pairs(self.tmp) do
		todel[#todel+1] = eff
	end

	while #todel > 0 do
		self:removeEffect(table.remove(todel))
	end
end

--- Helper function to add temporary values and not have to remove them manualy
function _M:effectTemporaryValue(eff, k, v)
	if not eff.__tmpvals then eff.__tmpvals = {} end
	eff.__tmpvals[#eff.__tmpvals+1] = {k, self:addTemporaryValue(k, v)}
end

--- Trigger an effect method
function _M:callEffect(eff_id, name, ...)
	local e = _M.tempeffect_def[eff_id]
	local p = self.tmp[eff_id]
	name = name or "trigger"
	if e[name] and p then return e[name](self, p, ...) end
end
