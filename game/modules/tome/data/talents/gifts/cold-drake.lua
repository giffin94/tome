-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009, 2010, 2011, 2012 Nicolas Casalini
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

local Object = require "engine.Object"

newTalent{
	name = "Ice Claw",
	type = {"wild-gift/cold-drake", 1},
	require = gifts_req1,
	points = 5,
	random_ego = "attack",
	equilibrium = 3,
	cooldown = 7,
	range = 1,
	tactical = { ATTACK = { COLD = 2 } },
	requires_target = true,
	on_learn = function(self, t) self.resists[DamageType.COLD] = (self.resists[DamageType.COLD] or 0) + 1 end,
	on_unlearn = function(self, t) self.resists[DamageType.COLD] = (self.resists[DamageType.COLD] or 0) - 1 end,
	action = function(self, t)
		local tg = {type="hit", range=self:getTalentRange(t)}
		local x, y, target = self:getTarget(tg)
		if not x or not y or not target then return nil end
		if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end
		self:attackTarget(target, (self:getTalentLevel(t) >= 4) and DamageType.ICE or DamageType.COLD, 1.4 + self:getTalentLevel(t) / 8, true)
		return true
	end,
	info = function(self, t)
		return ([[You call upon the mighty claw of a cold drake, doing %d%% weapon damage as cold damage.
		At level 4 the attack becomes pure ice, giving a chance to freeze the target.
		Each point in cold drake talents also increases your cold resistance by 1%%.]]):format(100 * (1.4 + self:getTalentLevel(t) / 8))
	end,
}

newTalent{
	name = "Icy Skin",
	type = {"wild-gift/cold-drake", 2},
	require = gifts_req2,
	mode = "sustained",
	points = 5,
	cooldown = 10,
	sustain_equilibrium = 30,
	range = 10,
	tactical = { ATTACK = { COLD = 1 }, DEFEND = 2 },
	on_learn = function(self, t) self.resists[DamageType.COLD] = (self.resists[DamageType.COLD] or 0) + 1 end,
	on_unlearn = function(self, t) self.resists[DamageType.COLD] = (self.resists[DamageType.COLD] or 0) - 1 end,
	getDamage = function(self, t) return self:combatTalentStatDamage(t, "wil", 10, 700) / 10 end,
	getArmor = function(self, t) return self:combatTalentStatDamage(t, "wil", 6, 600) / 10 end,
	activate = function(self, t)
		return {
			onhit = self:addTemporaryValue("on_melee_hit", {[DamageType.COLD]=t.getDamage(self, t)}),
			armor = self:addTemporaryValue("combat_armor", t.getArmor(self, t)),
		}
	end,
	deactivate = function(self, t, p)
		self:removeTemporaryValue("on_melee_hit", p.onhit)
		self:removeTemporaryValue("combat_armor", p.armor)
		return true
	end,
	info = function(self, t)
		return ([[Your skin forms icy scales, damaging all that hit you for %0.2f cold damage and increasing your armor by %d.
		Each point in cold drake talents also increases your cold resistance by 1%%.
		The damage and defense will scale with your Willpower stat.]]):format(damDesc(self, DamageType.COLD, t.getDamage(self, t)), t.getArmor(self, t))
	end,
}

newTalent{
	name = "Ice Wall",
	type = {"wild-gift/cold-drake", 3},
	require = gifts_req3,
	points = 5,
	random_ego = "defensive",
	equilibrium = 10,
	cooldown = 30,
	range = 10,
	tactical = { DISABLE = 2 },
	requires_target = true,
	on_learn = function(self, t) self.resists[DamageType.COLD] = (self.resists[DamageType.COLD] or 0) + 1 end,
	on_unlearn = function(self, t) self.resists[DamageType.COLD] = (self.resists[DamageType.COLD] or 0) - 1 end,
	action = function(self, t)
		local tg = {type="bolt", range=self:getTalentRange(t), nolock=true, talent=t}
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		local _ _, x, y = self:canProject(tg, x, y)
		if game.level.map:checkEntity(x, y, Map.TERRAIN, "block_move") then return nil end

		local addwall = function(x, y)
			local e = Object.new{
				old_feat = game.level.map(x, y, Map.TRAP),
				name = "ice wall", image = "npc/iceblock.png",
				type = "wall", subtype = "ice",
				display = '#', color=colors.LIGHT_BLUE, back_color=colors.BLUE,
				always_remember = true,
				can_pass = {pass_wall=1},
				block_move = true,
				block_sight = false,
				temporary = 4 + self:getTalentLevel(t),
				x = x, y = y,
				canAct = false,
				act = function(self)
					self:useEnergy()
					self.temporary = self.temporary - 1
					if self.temporary <= 0 then
						if self.old_feat then game.level.map(self.x, self.y, engine.Map.TRAP, self.old_feat)
						else game.level.map:remove(self.x, self.y, engine.Map.TRAP) end
						game.level:removeEntity(self)
					end
				end,
				knownBy = function() return true end,
				canTrigger = function() return false end,
				canDisarm = function() return false end,
				setKnown = function() end,
				summoner_gain_exp = true,
				summoner = self,
			}
			game.level:addEntity(e)
			game.level.map(x, y, Map.TRAP, e)
		end

		local size = 1 + math.floor(self:getTalentLevel(t) / 2)
		local angle = math.atan2(y - self.y, x - self.x) + math.pi / 2
		local x1, y1 = x + math.cos(angle) * size, y + math.sin(angle) * size
		local x2, y2 = x - math.cos(angle) * size, y - math.sin(angle) * size

		local dx1, dy1 = math.abs(x1 - x), math.abs(y1 - y)
		local dx2, dy2 = math.abs(x2 - x), math.abs(y2 - y)
		local block_corner = function(_, bx, by)
				if game.level.map:checkAllEntities(bx, by, "block_move") then return true
				else addwall(bx, by) ; return false end
			end

		local l = core.fov.line(x, y, x1, y1, function(_, bx, by) return true end)
		l:set_corner_block(block_corner)
		-- use the correct tangent (not approximate) and round corner tie-breakers toward the player (via wiggles!)
		if dx1 < dy1 then
			l:change_step((x1-x)/dy1, (y1-y)/dy1)
			if y < self.y then l:wiggle(true) else l:wiggle() end
		else
			l:change_step((x1-x)/dx1, (y1-y)/dx1)
			if x < self.x then l:wiggle(true) else l:wiggle() end
		end
		while true do
			local lx, ly, is_corner_blocked = l:step()
			if not lx or is_corner_blocked or game.level.map:checkAllEntities(lx, ly, "block_move") then break end
			addwall(lx, ly)
		end

		local l = core.fov.line(x, y, x2, y2, function(_, bx, by) return true end)
		l:set_corner_block(block_corner)
		-- use the correct tangent (not approximate) and round corner tie-breakers toward the player (via wiggles!)
		if dx2 < dy2 then
			l:change_step((x2-x)/dy2, (y2-y)/dy2)
			if y < self.y then l:wiggle(true) else l:wiggle() end
		else
			l:change_step((x2-x)/dx2, (y2-y)/dx2)
			if x < self.x then l:wiggle(true) else l:wiggle() end
		end
		while true do
			local lx, ly, is_corner_blocked = l:step()
			if not lx or is_corner_blocked or game.level.map:checkAllEntities(lx, ly, "block_move") then break end
			addwall(lx, ly)
		end

		if not game.level.map:checkAllEntities(x, y, "block_move") then addwall(x, y) end

		game.level.map:redisplay()
		return true
	end,
	info = function(self, t)
		return ([[Summons an icy wall of %d length for %d turns. Ice walls are transparent.
		Each point in cold drake talents also increases your cold resistance by 1%%.]]):format(3 + math.floor(self:getTalentLevel(t) / 2) * 2, 4 + self:getTalentLevel(t))
	end,
}

newTalent{
	name = "Ice Breath",
	type = {"wild-gift/cold-drake", 4},
	require = gifts_req4,
	points = 5,
	random_ego = "attack",
	equilibrium = 12,
	cooldown = 12,
	message = "@Source@ breathes ice!",
	tactical = { ATTACKAREA = { COLD = 2 }, DISABLE = { stun = 1 } },
	range = 0,
	radius = function(self, t) return 4 + self:getTalentLevelRaw(t) end,
	direct_hit = true,
	requires_target = true,
	on_learn = function(self, t) self.resists[DamageType.COLD] = (self.resists[DamageType.COLD] or 0) + 1 end,
	on_unlearn = function(self, t) self.resists[DamageType.COLD] = (self.resists[DamageType.COLD] or 0) - 1 end,
	target = function(self, t)
		return {type="cone", range=self:getTalentRange(t), radius=self:getTalentRadius(t), selffire=false, talent=t}
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		self:project(tg, x, y, DamageType.ICE, self:mindCrit(self:combatTalentStatDamage(t, "str", 30, 430)))
		game.level.map:particleEmitter(self.x, self.y, tg.radius, "breath_cold", {radius=tg.radius, tx=x-self.x, ty=y-self.y})
		game:playSoundNear(self, "talents/breath")
		return true
	end,
	info = function(self, t)
		return ([[You breathe ice in a frontal cone of radius %d. Any target caught in the area will take %0.2f cold damage and has a 25%% to be frozen for a few turns(higher rank enemies will be frozen for a shorter time).
		The damage will increase with the Strength stat.
		Each point in cold drake talents also increases your cold resistance by 1%%.]]):format(self:getTalentRadius(t), damDesc(self, DamageType.COLD, self:combatTalentStatDamage(t, "str", 30, 430)))
	end,
}

