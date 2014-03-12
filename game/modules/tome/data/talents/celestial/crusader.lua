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

newTalent{
	name = "Absorption Strike",
	type = {"celestial/crusader", 1},
	require = divi_req1,
	points = 5,
	cooldown = 8,
	positive = -7,
	tactical = { ATTACK = 2, DISABLE = 1 },
	range = 1,
	requires_target = true,
	getWeakness = function(self, t) return self:combatTalentScale(t, 20, 45, 0.75) end,
	getDamage = function(self, t) return self:combatTalentWeaponDamage(t, 1.1, 2.3) end,
	on_pre_use = function(self, t, silent) if not self:hasTwoHandedWeapon() then if not silent then game.logPlayer(self, "You require a two handed weapon to use this talent.") end return false end return true end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end
		local hit = self:attackTarget(target, nil, t.getDamage(self, t), true)
		if hit then
			self:project({type="ball", radius=2, selffire=false}, self.x, self.y, function(px, py)
				local a = game.level.map(px, py, Map.ACTOR)
				if a then
					a:setEffect(a.EFF_ABSORPTION_STRIKE, 5, {apply_power=self:combatSpellpower(), power=t.getWeakness(self, t)})
				end
			end)
		end
		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		return ([[You strike your foe with your two handed weapon, dealing %d%% weapon damage.
		If the attack hits all foes in radius 2 will have their light resistance reduced by %d%% for 5 turns.]]):
		format(100 * damage, t.getWeakness(self, t))
	end,
}

newTalent{
	name = "Mark of Light",
	type = {"celestial/crusader", 2},
	require = divi_req2,
	points = 5,
	no_energy = true,
	cooldown = 15,
	positive = 20,
	tactical = { ATTACK=0.5, DISABLE=2, HEAL=2 },
	range = 1,
	requires_target = true,
	getPower = function(self, t) return self:combatTalentScale(t, 30, 70) end,
	getDamage = function(self, t) return self:combatTalentWeaponDamage(t, 0.2, 0.7) end,
	on_pre_use = function(self, t, silent) if not self:hasTwoHandedWeapon() then if not silent then game.logPlayer(self, "You require a two handed weapon to use this talent.") end return false end return true end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end
		local hit = self:attackTarget(target, nil, t.getDamage(self, t), true)
		if hit then
			target:setEffect(target.EFF_MARK_OF_LIGHT, 5, {apply_power=self:combatSpellpower(), src=self, power=t.getPower(self, t)})
		end
		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		return ([[You swifty thrust the hilt of your 2H weapon into your target, dealing %d%% weapon damage.
		If the attack hits the creature is marked with light for 5 turns. All melee hits you deal to it will heal you for %d%% of the damage done.]]):
		format(100 * damage, t.getPower(self, t))
	end,
}

newTalent{
	name = "Righteous Strength",
	type = {"celestial/crusader",3},
	require = divi_req3,
	points = 5,
	mode = "passive",
	getArmor = function(self, t) return self:combatTalentScale(t, 5, 30) end,
	getDamage = function(self, t) return self:combatTalentSpellDamage(t, 10, 120) end,
	getCrit = function(self, t) return self:combatTalentScale(t, 3, 10, 0.75) end,
	getPower = function(self, t) return self:combatTalentScale(t, 5, 20) end,
	callbackOnCrit = function(self, t, kind, dam, chance, target)
		if kind ~= "physical" or not target then return end
		if self.turn_procs.righteous_strength then return end
		self.turn_procs.righteous_strength = true

		target:setEffect(target.EFF_LIGHTBURN, 5, {apply_power=self:combatSpellpower(), src=self, dam=t.getDamage(self, t)/5, armor=t.getArmor(self, t)})
		self:setEffect(self.EFF_RIGHTEOUS_STRENGTH, 4, {power=t.getPower(self, t), max_power=t.getPower(self, t) * 3})
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "combat_physcrit", t.getCrit(self, t))
	end,
	info = function(self, t)
		return ([[While wielding a two handed weapon, your critical strike chance is increased by %d%%, and your melee criticals instill you with righteous strength, increasing all physical and light damage you deal by %d%%, stacking up to 3 times.
		In addition, your melee critical strikes leave a lasting lightburn on the target, dealing %0.2f light damage over 5 turns and reducing opponents armour by %d.
		The damage increase with your Spellpower.]]):
		format(t.getCrit(self, t), t.getPower(self, t), damDesc(self, DamageType.LIGHT, t.getDamage(self, t)), t.getArmor(self, t))
	end,
}

newTalent{
	name = "Flash of the Blade",
	type = {"celestial/crusader", 4},
	require = divi_req4,
	random_ego = "attack",
	points = 5,
	cooldown = 10,
	positive = 15,
	tactical = { ATTACKAREA = {LIGHT = 2} },
	range = 0,
	radius = 2,
	requires_target = true,
	target = function(self, t)
		return {type="ball", range=self:getTalentRange(t), selffire=false, radius=self:getTalentRadius(t)}
	end,
	on_pre_use = function(self, t, silent) if not self:hasTwoHandedWeapon() then if not silent then game.logPlayer(self, "You require a two handed weapon to use this talent.") end return false end return true end,
	get1Damage = function(self, t) return self:combatTalentWeaponDamage(t, 0.8, 1.6) end,
	get2Damage = function(self, t) return self:combatTalentWeaponDamage(t, 0.5, 1.2) end,
	action = function(self, t)
		local tg1 = self:getTalentTarget(t) tg1.radius = 1
		local tg2 = self:getTalentTarget(t)
		self:project(tg1, self.x, self.y, function(px, py, tg, self)
			local target = game.level.map(px, py, Map.ACTOR)
			if target and target ~= self then
				self:attackTarget(target, nil, t.get1Damage(self, t), true)
			end
		end)
		self:project(tg2, self.x, self.y, function(px, py, tg, self)
			local target = game.level.map(px, py, Map.ACTOR)
			if target and target ~= self then
				self:attackTarget(target, DamageType.LIGHT, t.get2Damage(self, t), true)
				if self:getTalentLevel(t) >= 4 then
					target:setEffect(target.EFF_DAZED, 3, {apply_power=self:combatSpellpower()})
				end
			end
		end)

		self:addParticles(Particles.new("meleestorm", 2, {radius=2, img="spinningwinds_yellow"}))
		self:addParticles(Particles.new("meleestorm", 1, {img="spinningwinds_yellow"}))
		return true
	end,
	info = function(self, t)
		return ([[Infuse your two handed weapon with light while spinning around.
		All creatures in radius one take %d%% weapon damage.
		In addition while spinning your weapon shines so much it deals %d%% light weapon damage to all foes in radius 2.
		At level 4 creatures may also be dazed by the light.]]):
		format(t.get1Damage(self, t) * 100, t.get2Damage(self, t) * 100)
	end,
}
