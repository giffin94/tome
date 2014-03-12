-- ToME - Tales of Maj'Eyal
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

function radianceRadius(self)
	return self:getTalentRadius(self:getTalentFromId(self.T_RADIANCE))
end

newTalent{
	name = "Radiance",
	type = {"celestial/radiance", 1},
	mode = "passive",
	require = divi_req1,
	points = 5,
	radius = function(self, t) return self:combatTalentScale(t, 3, 7) end,
	getResist = function(self, t) return math.min(100, self:combatTalentScale(t, 20, 90)) end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "radiance_aura", radianceRadius(self))
		self:talentTemporaryValue(p, "blind_immune", t.getResist(self, t) / 100)
	end,
	info = function(self, t)
		return ([[You are so infused with sunlight that your body glows permanently in radius %d, even in dark places.
		The light protects your eyes, giving %d%% blindness resistance.
		The light radius overrides your normal light if it is bigger (it does not stack).
		]]):
		format(radianceRadius(self), t.getResist(self, t))
	end,
}

newTalent{
	name = "Illumination",
	type = {"celestial/radiance", 2},
	require = divi_req2,
	points = 5,
	mode = "passive",
	getPower = function(self, t) return 15 + self:combatTalentSpellDamage(t, 1, 100) end,
	getDef = function(self, t) return 5 + self:combatTalentSpellDamage(t, 1, 35) end,
	callbackOnActBase = function(self, t)
		local radius = radianceRadius(self)
		local grids = core.fov.circle_grids(self.x, self.y, radius, true)
		for x, yy in pairs(grids) do for y, _ in pairs(grids[x]) do local target = game.level.map(x, y, Map.ACTOR) if target and self ~= target then
			target:setEffect(target.EFF_ILLUMINATION, 1, {power=t.getPower(self, t), def=t.getDef(self, t)})
			local ss = self:isTalentActive(self.T_SEARING_SIGHT)
			if ss then
				local dist = core.fov.distance(self.x, self.y, target.x, target.y) - 1
				local coeff = math.scale(radius - dist, 1, radius, 0.1, 1)
				local realdam = DamageType:get(DamageType.LIGHT).projector(self, target.x, target.y, DamageType.LIGHT, ss.dam * coeff)
				if ss.daze and rng.percent(ss.daze) and target:canBe("stun") then
					target:setEffect(target.EFF_DAZED, 3, {apply_power=self:combatSpellpower()})
				end

				if realdam and realdam > 0 and self:hasEffect(self.EFF_LIGHT_BURST) then
					self:setEffect(self.EFF_LIGHT_BURST_SPEED, 4, {})
				end
			end
		end end end		
	end,
	info = function(self, t)
		return ([[The light of your Radiance allows you to see that which would normally be unseen.
		All actors in your Radiance aura have their invisibility and stealth power reduced by %d.
		In addition, all actors affected by illumination are easier to see and therefore hit; their defense is reduced by %d and all evasion bonuses from being unseen are negated.
		The effects increase with your Spellpower.]]):
		format(t.getPower(self, t), t.getDef(self, t))
	end,
}

newTalent{
	name = "Searing Sight",
	type = {"celestial/radiance",3},
	require = divi_req3,
	mode = "sustained",
	points = 5,
	cooldown = 15,
	range = function(self) return radianceRadius(self) end,
	tactical = { ATTACKAREA = {LIGHT=1} },
	sustain_positive = 40,
	getDamage = function(self, t) return self:combatTalentSpellDamage(t, 1, 90) end,
	getDaze = function(self, t) return self:combatTalentLimit(t, 35, 5, 20) end,
	activate = function(self, t)
		local daze = nil
		if self:getTalentLevel(t) >= 4 then daze = t.getDaze(self, t) end
		return {dam=t.getDamage(self, t), daze=daze}
	end,
	deactivate = function(self, t, p)
	end,
	info = function(self, t)
		return ([[Your Radiance is so powerful it burns all foes caught in it, doing up to %0.2f light damage (reduced with distance) to all foes caught inside.
		At level 4 the light is so bright it has %d%% chances to daze them for 3 turns.
		The damage increase with your Spellpower.]]):
		format(damDesc(self, DamageType.LIGHT, t.getDamage(self, t)), t.getDaze(self, t))
	end,
}

newTalent{
	name = "Light Burst",
	type = {"celestial/radiance", 4},
	require = divi_req4,
	points = 5,
	cooldown = 25,
	positive = 15,
	tactical = { DISABLE = {blind=1} },
	range = function(self) return radianceRadius(self) end,
	requires_target = true,
	getDur = function(self, t) return self:combatTalentLimit(t, 9, 2, 6) end,
	getMax = function(self, t) return math.floor(self:combatTalentScale(t, 2, 8)) end,
	action = function(self, t)
		local radius = radianceRadius(self)
		local grids = core.fov.circle_grids(self.x, self.y, radius, true)
		for x, yy in pairs(grids) do for y, _ in pairs(grids[x]) do local target = game.level.map(x, y, Map.ACTOR) if target and self ~= target then
			if target:canBe("blind") then
				target:setEffect(target.EFF_BLINDED, 4, {apply_power=self:combatSpellpower()})
			end
		end end end

		self:setEffect(self.EFF_LIGHT_BURST, t.getDur(self, t), {max=t.getMax(self, t)})
		return true
	end,
	info = function(self, t)
		return ([[Concentrate your Radiance in a blinding flash of light. All foes caught inside will be blinded for 3 turns.
		In addition for %d turns each time your Searing Sight damages a foe you gain a movement bonus of 10%%, stacking up to %d times.]]):
		format(t.getDur(self, t), t.getMax(self, t))
	end,
}

