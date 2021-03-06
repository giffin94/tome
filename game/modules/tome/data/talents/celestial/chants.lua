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

local function cancelChants(self)
	local chants = {self.T_CHANT_OF_FORTITUDE, self.T_CHANT_OF_FORTRESS, self.T_CHANT_OF_RESISTANCE, self.T_CHANT_OF_LIGHT}
	for i, t in ipairs(chants) do
		if self:isTalentActive(t) then
			self:forceUseTalent(t, {ignore_energy=true})
		end
	end
end

newTalent{
	name = "Chant of Fortitude",
	type = {"celestial/chants", 1},
	mode = "sustained",
	require = divi_req1,
	points = 5,
	cooldown = 12,
	sustain_positive = 20,
	no_energy = true,
	dont_provide_pool = true,
	tactical = { BUFF = 2 },
	range = 10,
	getResists = function(self, t) return self:combatTalentSpellDamage(t, 5, 70) end,
	getDamageOnMeleeHit = function(self, t) return self:combatTalentSpellDamage(t, 5, 25) end,
	activate = function(self, t)
		cancelChants(self)
		local power = t.getResists(self, t)
		game:playSoundNear(self, "talents/spell_generic2")
		local ret = {
			onhit = self:addTemporaryValue("on_melee_hit", {[DamageType.LIGHT]=t.getDamageOnMeleeHit(self, t)}),
			phys = self:addTemporaryValue("combat_physresist", power),
			spell = self:addTemporaryValue("combat_spellresist", power),
			particle = self:addParticles(Particles.new("golden_shield", 1))
		}
		return ret
	end,
	deactivate = function(self, t, p)
		self:removeParticles(p.particle)
		self:removeTemporaryValue("on_melee_hit", p.onhit)
		self:removeTemporaryValue("combat_physresist", p.phys)
		self:removeTemporaryValue("combat_spellresist", p.spell)
		return true
	end,
	info = function(self, t)
		local saves = t.getResists(self, t)
		local damageonmeleehit = t.getDamageOnMeleeHit(self, t)
		return ([[You chant the glory of the Sun, granting you %d Physical Save and Spell Save.
		In addition, this talent surrounds you with a shield of light, dealing %0.2f light damage to anything that attacks you.
		You may only have one Chant active at once.
		The effects will increase with your Spellpower.]]):
		format(saves, damDesc(self, DamageType.LIGHT, damageonmeleehit))
	end,
}

newTalent{
	name = "Chant of Fortress",
	type = {"celestial/chants", 2},
	mode = "sustained",
	require = divi_req2,
	points = 5,
	cooldown = 12,
	sustain_positive = 20,
	no_energy = true,
	dont_provide_pool = true,
	tactical = { BUFF = 2 },
	range = 10,
	getPhysicalResistance = function(self, t) return self:combatTalentSpellDamage(t, 5, 23) end,
	getDamageOnMeleeHit = function(self, t) return self:combatTalentSpellDamage(t, 5, 25) end,
	activate = function(self, t)
		cancelChants(self)
		game:playSoundNear(self, "talents/spell_generic2")
		local ret = {
			onhit = self:addTemporaryValue("on_melee_hit", {[DamageType.LIGHT]=t.getDamageOnMeleeHit(self, t)}),
			phys = self:addTemporaryValue("resists", {[DamageType.PHYSICAL] = t.getPhysicalResistance(self, t)}),
			particle = self:addParticles(Particles.new("golden_shield", 1))
		}
		return ret
	end,
	deactivate = function(self, t, p)
		self:removeParticles(p.particle)
		self:removeTemporaryValue("on_melee_hit", p.onhit)
		self:removeTemporaryValue("resists", p.phys)
		return true
	end,
	info = function(self, t)
		local physicalresistance = t.getPhysicalResistance(self, t)
		local damageonmeleehit = t.getDamageOnMeleeHit(self, t)
		return ([[You chant the glory of the Sun, granting you %d%% physical damage resistance.
		In addition, this talent surrounds you with a shield of light, dealing %0.2f light damage to anything that attacks you.
		You may only have one Chant active at once.
		The effects will increase with your Spellpower.]]):
		format(physicalresistance, damDesc(self, DamageType.LIGHT, damageonmeleehit))
	end,
}

newTalent{
	name = "Chant of Resistance",
	type = {"celestial/chants",3},
	mode = "sustained",
	require = divi_req3,
	points = 5,
	cooldown = 12,
	sustain_positive = 20,
	dont_provide_pool = true,
	tactical = { BUFF = 2 },
	no_energy = true,
	range = 10,
	getResists = function(self, t) return self:combatTalentSpellDamage(t, 5, 20) end,
	getDamageOnMeleeHit = function(self, t) return self:combatTalentSpellDamage(t, 5, 25) end,
	activate = function(self, t)
		cancelChants(self)
		local power = t.getResists(self, t)
		game:playSoundNear(self, "talents/spell_generic2")
		local ret = {
			onhit = self:addTemporaryValue("on_melee_hit", {[DamageType.LIGHT]=t.getDamageOnMeleeHit(self, t)}),
			res = self:addTemporaryValue("resists", {
				[DamageType.FIRE] = power,
				[DamageType.LIGHTNING] = power,
				[DamageType.ACID] = power,
				[DamageType.COLD] = power,
			}),
			particle = self:addParticles(Particles.new("golden_shield", 1))
		}
		return ret
	end,
	deactivate = function(self, t, p)
		self:removeParticles(p.particle)
		self:removeTemporaryValue("on_melee_hit", p.onhit)
		self:removeTemporaryValue("resists", p.res)
		return true
	end,
	info = function(self, t)
		local resists = t.getResists(self, t)
		local damage = t.getDamageOnMeleeHit(self, t)
		return ([[You chant the glory of the Sun, granting you %d%% fire, lightning, acid and cold damage resistance.
		In addition, this talent surrounds you with a shield of light, dealing %0.2f light damage to anything that attacks you.
		You may only have one Chant active at once.
		The effects will increase with your Spellpower.]]):
		format(resists, damDesc(self, DamageType.LIGHT, damage))
	end,
}

newTalent{
	name = "Chant of Light",
	type = {"celestial/chants", 4},
	mode = "sustained",
	require = divi_req4,
	points = 5,
	cooldown = 12,
	sustain_positive = 20,
	no_energy = true,
	dont_provide_pool = true,
	tactical = { BUFF = 2 },
	range = 10,
	getLightDamageIncrease = function(self, t) return self:combatTalentSpellDamage(t, 10, 50) end,
	getDamageOnMeleeHit = function(self, t) return self:combatTalentSpellDamage(t, 5, 25) end,
	getLite = function(self, t) return math.floor(self:combatTalentScale(t, 2, 6, "log")) end,
	activate = function(self, t)
		cancelChants(self)
		game:playSoundNear(self, "talents/spell_generic2")
		local ret = {
			onhit = self:addTemporaryValue("on_melee_hit", {[DamageType.LIGHT]=t.getDamageOnMeleeHit(self, t)}),
			phys = self:addTemporaryValue("inc_damage", {[DamageType.LIGHT] = t.getLightDamageIncrease(self, t), [DamageType.FIRE] = t.getLightDamageIncrease(self, t)}),
			lite = self:addTemporaryValue("lite", t.getLite(self, t)),
			particle = self:addParticles(Particles.new("golden_shield", 1))
		}
		return ret
	end,
	deactivate = function(self, t, p)
		self:removeParticles(p.particle)
		self:removeTemporaryValue("on_melee_hit", p.onhit)
		self:removeTemporaryValue("inc_damage", p.phys)
		self:removeTemporaryValue("lite", p.lite)
		return true
	end,
	info = function(self, t)
		local damageinc = t.getLightDamageIncrease(self, t)
		local damage = t.getDamageOnMeleeHit(self, t)
		local lite = t.getLite(self, t)
		return ([[You chant the glory of the Sun, empowering your light and fire elemental attacks so that they do %d%% additional damage.
		In addition, this talent surrounds you with a shield of light, dealing %0.2f light damage to anything that attacks you.
		Your lite radius is also increased by %d.
		You may only have one Chant active at once.
		The effects will increase with your Spellpower.]]):
		format(damageinc, damDesc(self, DamageType.LIGHT, damage), lite)
	end,
}
