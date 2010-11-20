-- ToME - Tales of Maj'Eyal
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

local function getHateMultiplier(self, min, max)
	return (min + ((max - min) * math.min(self.hate, 10) / 10))
end

newTalent{
	name = "Unnatural Body",
	type = {"cursed/cursed-form", 1},
	mode = "passive",
	require = cursed_wil_req1,
	points = 5,
	on_learn = function(self, t)
		return true
	end,
	on_unlearn = function(self, t)
		return true
	end,
	getHealPerKill = function(self, t)
		return math.sqrt(self:getTalentLevel(t)) * 15
	end,
	getRegenRate = function(self, t)
		return math.sqrt(self:getTalentLevel(t) * 2) * self.max_life * 0.008
	end,
	getResist = function(self, t)
		return -18 + (self:getTalentLevel(t) * 3) + (18 * getHateMultiplier(self, 0, 1))
	end,
	do_regenLife  = function(self, t)
		-- heal
		local maxHeal = self.unnatural_body_heal or 0
		if maxHeal > 0 then
			local heal = math.min(t.getRegenRate(self, t), maxHeal)
			self:heal(heal)
		
			self.unnatural_body_heal = math.max(0, (self.unnatural_body_heal or 0) - heal)
		end
		
		-- update resists as well
		local oldResist = self.unnatural_body_resist or 0
		local newResist = t.getResist(self, t)
		self.resists.all = (self.resists.all or 0) - oldResist + newResist
		self.unnatural_body_resist = newResist
	end,
	on_kill = function(self, t, target)
		if target and target.max_life then
			heal = t.getHealPerKill(self, t) * 0.01 * target.max_life
			if heal > 0 then
				self.unnatural_body_heal = math.min(self.life, (self.unnatural_body_heal or 0) + heal)
			end
		end
	end,
	info = function(self, t)
		local healPerKill = t.getHealPerKill(self, t)
		local regenRate = t.getRegenRate(self, t)
		local resist = -18 + (self:getTalentLevel(t) * 3)
		return ([[Your body is now fed by your hatred. With each kill, you regenerate %d%% of your victim's life at a rate of %0.1f life per turn. As your hate fades and grows the damage you sustain is adjusted by %d%% to %d%%.]]):format(healPerKill, regenRate, resist, resist + 18)
	end,
}

--newTalent{
--	name = "Obsession",
--	type = {"cursed/cursed-form", 2},
--	require = cursed_wil_req2,
--	mode = "passive",
--	points = 5,
--	on_learn = function(self, t)
--		self.hate_per_kill = self.hate_per_kill + 0.1
--	end,
--	on_unlearn = function(self, t)
--		self.hate_per_kill = self.hate_per_kill - 0.1
--	end,
--	info = function(self, t)
--		return ([[Your suffering will become theirs. For every life that is taken you gain an extra %0.1f hate.]]):format(self:getTalentLevelRaw(t) * 0.1)
--	end
--}

--newTalent{
--	name = "Suffering",
--	type = {"cursed/cursed-form", 2},
--	require = cursed_wil_req2,
--	mode = "passive",
--	points = 5,
--	on_learn = function(self, t)
--		return true
--	end,
--	on_unlearn = function(self, t)
--		return true
--	end,
--	do_onTakeHit = function(self, t, damage)
--		if damage > 0 then
--			local hatePerLife = (1 + self:getTalentLevel(t)) / (self.max_life * 1.5)
--			self.hate = math.max(self.max_hate, self.hate + damage * hatePerLife)
--		end
--	end,
--	info = function(self, t)
--		local hatePerLife = (1 + self:getTalentLevel(t)) / (self.max_life * 1.5)
--		return ([[Your suffering will become theirs. For every %d life that is taken, you gain 1 hate.]]):format(1 / hatePerLife)
--	end
--}

newTalent{
	name = "Seethe",
	type = {"cursed/cursed-form", 2},
	random_ego = "utility",
	require = cursed_wil_req2,
	points = 5,
	cooldown = 400,
	action = function(self, t)
		self:incHate(2 + self:getTalentLevel(t) * 0.9)

		local damage = self.max_life * 0.25
		self:takeHit(damage, self)
		game.level.map:particleEmitter(self.x, self.y, 5, "fireflash", {radius=2, tx=self.x, ty=self.y})
		game:playSoundNear(self, "talents/fireflash")
		return true
	end,
	info = function(self, t)
		local increase = 2 + self:getTalentLevel(t) * 0.9
		local damage = self.max_life * 0.25
		return ([[Focus your rage gaining %0.1f hate at the cost of %d life.]]):format(increase, damage)
	end,
}

newTalent{
	name = "Relentless",
	type = {"cursed/cursed-form", 3},
	mode = "passive",
	require = cursed_wil_req3,
	points = 5,
	on_learn = function(self, t)
		self:attr("fear_immune", 0.15)
		self:attr("confusion_immune", 0.15)
		self:attr("knockback_immune", 0.15)
		self:attr("stun_immune", 0.15)
		return true
	end,
	on_unlearn = function(self, t)
		self:attr("fear_immune", -0.15)
		self:attr("confusion_immune", -0.15)
		self:attr("knockback_immune", -0.15)
		self:attr("stun_immune", -0.15)
		return true
	end,
	info = function(self, t)
		return ([[Your thirst for blood drives your movements. (+%d%% confusion, fear, knockback and stun immunity)]]):format(self:getTalentLevelRaw(t) * 15)
	end,
}

newTalent{
	name = "Enrage",
	type = {"cursed/cursed-form", 4},
	require = cursed_wil_req4,
	points = 5,
	rage = 0.1,
	cooldown = 50,
	action = function(self, t)
		local life = 50 + self:getTalentLevel(t) * 50
		self:setEffect(self.EFF_INCREASED_LIFE, 20, { life = life })
		return true
	end,
	info = function(self, t)
		local life = 50 + self:getTalentLevel(t) * 50
		return ([[In a burst of rage you become an even more fearsome opponent, gaining %d extra life for 20 turns.]]):format(life)
	end,
}


