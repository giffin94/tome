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

newTalent{
	name = "Rend",
	type = {"corruption/scourge", 1},
	require = corrs_req1,
	points = 5,
	vim = 9,
	cooldown = 6,
	range = 1,
	action = function(self, t)
		local weapon, offweapon = self:hasDualWeapon()
		if not weapon then
			game.logPlayer(self, "You cannot use Rend without two weapons!")
			return nil
		end

		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if math.floor(core.fov.distance(self.x, self.y, x, y)) > 1 then return nil end

		local speed1, hit1 = self:attackTargetWith(target, weapon.combat, nil, self:combatTalentWeaponDamage(t, 0.8, 1.6))
		local speed2, hit2 = self:attackTargetWith(target, offweapon.combat, nil, self:combatTalentWeaponDamage(t, 0.8, 1.6))

		-- Try to bleed !
		if hit1 then
			if target:checkHit(self:combatAttackStr(weapon.combat), target:combatPhysicalResist(), 0, 95, 8 - self:getTalentLevel(t) / 2) and target:canBe("cut") then
				target:setEffect(target.EFF_CUT, 5, {power=self:combatTalentSpellDamage(t, 5, 40), src=self})
			else
				game.logSeen(target, "%s resists the cut!", target.name:capitalize())
			end
		end
		if hit2 then
			if target:checkHit(self:combatAttackStr(offweapon.combat), target:combatPhysicalResist(), 0, 95, 8 - self:getTalentLevel(t) / 2) and target:canBe("cut") then
				target:setEffect(target.EFF_CUT, 5, {power=self:combatTalentSpellDamage(t, 5, 40), src=self})
			else
				game.logSeen(target, "%s resists the cut!", target.name:capitalize())
			end
		end

		return true
	end,
	info = function(self, t)
		return ([[Hit the target with both weapons doing %d%% damage, for each hit the target will bleed for %0.2f damage each turn for 5 turns.
		The bleeding effect will increase with your Magic stat.]]):
		format(100 * self:combatTalentWeaponDamage(t, 0.8, 1.6), self:combatTalentSpellDamage(t, 5, 40))
	end,
}

newTalent{
	name = "Ruin",
	type = {"corruption/scourge", 2},
	mode = "sustained",
	require = corrs_req2,
	points = 5,
	vim = 40,
	cooldown = 30,
	activate = function(self, t)
		game:playSoundNear(self, "talents/slime")
		local ret = {
			per = self:addTemporaryValue("inc_damage", {[DamageType.BLIGHT] = self:combatTalentSpellDamage(t, 15, 40)}),
		}
		return ret
	end,
	deactivate = function(self, t, p)
		self:removeTemporaryValue("inc_damage", p.per)
		return true
	end,
	info = function(self, t)
		return ([[Concentrate on the corruption you bring, increasing each of your melee strikes with %0.2f blight damage.
		The damage will increase with your Magic stat.]]):
		format(self:combatTalentSpellDamage(t, 15, 40))
	end,
}

newTalent{
	name = "Acid Strike",
	type = {"corruption/scourge", 3},
	require = corrs_req3,
	points = 5,
	vim = 18,
	cooldown = 12,
	range = 1,
	action = function(self, t)
		local weapon, offweapon = self:hasDualWeapon()
		if not weapon then
			game.logPlayer(self, "You cannot use Acid Strike without two weapons!")
			return nil
		end

		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if math.floor(core.fov.distance(self.x, self.y, x, y)) > 1 then return nil end

		local speed1, hit1 = self:attackTargetWith(target, weapon.combat, DamageType.ACID, self:combatTalentWeaponDamage(t, 0.8, 1.6))
		local speed2, hit2 = self:attackTargetWith(target, offweapon.combat, DamageType.ACID, self:combatTalentWeaponDamage(t, 0.8, 1.6))

		-- Acid splash !
		if hit1 or hit2 then
			local tg = {type="ball", range=0, radius=1, friendlyfire=false, talent=t}
			self:project(tg, target.x, target.y, DamageType.ACID, self:spellCrit(self:combatTalentSpellDamage(t, 10, 130)))
		end

		return true
	end,
	info = function(self, t)
		return ([[Strike with each of your weapons, doing %d%% acid weapon damage. If at least one of the strikes hits an acid splash is generated doing %0.2f acid damage.
		The splash damage will increase with your Magic stat.]]):
		format(100 * self:combatTalentWeaponDamage(t, 0.8, 1.6), self:combatTalentSpellDamage(t, 10, 130))
	end,
}

newTalent{
	name = "Dark Surprise",
	type = {"corruption/scourge", 4},
	require = corrs_req4,
	points = 5,
	vim = 14,
	cooldown = 8,
	range = 1,
	action = function(self, t)
		local weapon, offweapon = self:hasDualWeapon()
		if not weapon then
			game.logPlayer(self, "You cannot use Dark Surprise without two weapons!")
			return nil
		end

		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if math.floor(core.fov.distance(self.x, self.y, x, y)) > 1 then return nil end

		local speed1, hit1 = self:attackTargetWith(target, weapon.combat, DamageType.DARKNESS, self:combatTalentWeaponDamage(t, 0.6, 1.4))

		if hit1 then
			local speed2, hit2 = self:attackTargetWith(target, weapon.combat, DamageType.BLIGHT, self:combatTalentWeaponDamage(t, 0.6, 1.4))
			if hit2 and target:checkHit(self:combatAttack(offweapon.combat), target:combatPhysicalResist(), 0, 95, 10) and target:canBe("blind") then
				target:setEffect(target.EFF_BLINDED, 4, {})
			else
				game.logSeen(self, "%s resists the darkness.", target.name:capitalize())
			end
		end

		return true
	end,
	info = function(self, t)
		return ([[Hits the target with your main weapon, doing %d%% darkness weapon damage. If the attack hits you attack with your second weapon, doing %d%% blight weapon damage and granting an automatic critical. If this attack hits the target is blinded for 4 turns.]]):
		format(100 * self:combatTalentWeaponDamage(t, 0.6, 1.4), 100 * self:combatTalentWeaponDamage(t, 0.6, 1.4))
	end,
}
