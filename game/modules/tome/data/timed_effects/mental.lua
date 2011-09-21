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

local Stats = require "engine.interface.ActorStats"
local Particles = require "engine.Particles"
local Entity = require "engine.Entity"
local Chat = require "engine.Chat"
local Map = require "engine.Map"
local Level = require "engine.Level"

newEffect{
	name = "SILENCED",
	desc = "Silenced",
	long_desc = function(self, eff) return "The target is silenced, preventing it from casting spells and using some vocal talents." end,
	type = "mental",
	status = "detrimental",
	parameters = {},
	on_gain = function(self, err) return "#Target# is silenced!", "+Silenced" end,
	on_lose = function(self, err) return "#Target# is not silenced anymore.", "-Silenced" end,
	activate = function(self, eff)
		eff.tmpid = self:addTemporaryValue("silence", 1)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("silence", eff.tmpid)
	end,
}

newEffect{
	name = "MEDITATION",
	desc = "Meditation",
	long_desc = function(self, eff) return "The target is meditating. Any damage will stop it." end,
	type = "mental",
	status = "detrimental",
	parameters = {},
	on_timeout = function(self, eff)
		self:incEquilibrium(-eff.per_turn)
	end,
	activate = function(self, eff)
		eff.tmpid = self:addTemporaryValue("dazed", 1)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("dazed", eff.tmpid)
		if eff.dur <= 0 then
			self:incEquilibrium(-eff.final)
		end
	end,
}

newEffect{
	name = "SUMMON_CONTROL",
	desc = "Summon Control",
	long_desc = function(self, eff) return ("Reduces damage received by %d%% and increases summon time by %d."):format(eff.res, eff.incdur) end,
	type = "mental",
	status = "beneficial",
	parameters = { res=10, incdur=10 },
	activate = function(self, eff)
		eff.resid = self:addTemporaryValue("resists", {all=eff.res})
		eff.durid = self:addTemporaryValue("summon_time", eff.incdur)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("resists", eff.resid)
		self:removeTemporaryValue("summon_time", eff.durid)
	end,
	on_timeout = function(self, eff)
		eff.dur = self.summon_time
	end,
}

newEffect{
	name = "CONFUSED",
	desc = "Confused",
	long_desc = function(self, eff) return ("The target is confused, acting randomly (chance %d%%) and unable to perform complex actions."):format(eff.power) end,
	type = "mental",
	status = "detrimental",
	parameters = { power=50 },
	on_gain = function(self, err) return "#Target# wanders around!.", "+Confused" end,
	on_lose = function(self, err) return "#Target# seems more focused.", "-Confused" end,
	activate = function(self, eff)
		eff.power = eff.power - (self:attr("confusion_immune") or 0) / 2
		eff.tmpid = self:addTemporaryValue("confused", eff.power)
		if eff.power <= 0 then eff.dur = 0 end
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("confused", eff.tmpid)
	end,
}

newEffect{
	name = "DOMINANT_WILL",
	desc = "Dominated",
	long_desc = function(self, eff) return ("The target's mind has been shattered. Its body remains as a thrall to your mind.") end,
	type = "mental",
	status = "detrimental",
	parameters = { },
	on_gain = function(self, err) return "#Target#'s mind is shattered." end,
	on_lose = function(self, err) return "#Target# collapses." end,
	activate = function(self, eff)
		eff.pid = self:addTemporaryValue("inc_damage", {all=-15})
		self.faction = eff.src.faction
		self.ai_state = self.ai_state or {}
		self.ai_state.tactic_leash = 100
		self.remove_from_party_on_death = true
		self.no_inventory_access = true
		self.move_others = true
		self.summoner = eff.src
		self.summoner_gain_exp = true
		game.party:addMember(self, {
			control="full",
			type="thrall",
			title="Thrall",
			orders = {leash=true, follow=true},
			on_control = function(self)
				self:hotkeyAutoTalents()
			end,
		})
	end,
	deactivate = function(self, eff)
		self:die(eff.src)
	end,
}

newEffect{
	name = "BATTLE_SHOUT",
	desc = "Battle Shout",
	long_desc = function(self, eff) return ("Increases maximum life and stamina by %d%%."):format(eff.power) end,
	type = "mental",
	status = "beneficial",
	parameters = { power=10 },
	activate = function(self, eff)
		eff.life = self:addTemporaryValue("max_life", self.max_life * eff.power / 100)
		eff.stamina = self:addTemporaryValue("max_stamina", self.max_stamina * eff.power / 100)
		self:heal(self.max_life * eff.power / 100)
		self:incStamina(self.max_stamina * eff.power / 100)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("max_life", eff.life)
		self:removeTemporaryValue("max_stamina", eff.stamina)
	end,
}

newEffect{
	name = "BATTLE_CRY",
	desc = "Battle Cry",
	long_desc = function(self, eff) return ("The target's will to defend itself is shattered by the powerful battle cry, reducing defense by %d."):format(eff.power) end,
	type = "mental",
	status = "detrimental",
	parameters = { power=10 },
	on_gain = function(self, err) return "#Target#'s will is shattered.", "+Battle Cry" end,
	on_lose = function(self, err) return "#Target# regains some of its will.", "-Battle Cry" end,
	activate = function(self, eff)
		eff.tmpid = self:addTemporaryValue("combat_def", -eff.power)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("combat_def", eff.tmpid)
	end,
}

newEffect{
	name = "WILLFUL_COMBAT",
	desc = "Willful Combat",
	long_desc = function(self, eff) return ("The target puts all its willpower into its blows, improving damage by %d."):format(eff.power) end,
	type = "mental",
	status = "beneficial",
	parameters = { power=10 },
	on_gain = function(self, err) return "#Target# lashes out with pure willpower." end,
	on_lose = function(self, err) return "#Target#'s willpower rush ends." end,
	activate = function(self, eff)
		eff.tmpid = self:addTemporaryValue("combat_dam", eff.power)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("combat_dam", eff.tmpid)
	end,
}

newEffect{
	name = "GLOOM_WEAKNESS",
	desc = "Gloom Weakness",
	long_desc = function(self, eff) return ("The gloom reduces the target's attack by %d and damage rating by %d."):format(eff.atk, eff.dam) end,
	type = "mental",
	status = "detrimental",
	parameters = { atk=10, dam=10 },
	on_gain = function(self, err) return "#F53CBE##Target# is weakened by the gloom." end,
	on_lose = function(self, err) return "#F53CBE##Target# is no longer weakened." end,
	activate = function(self, eff)
		eff.particle = self:addParticles(Particles.new("gloom_weakness", 1))
		eff.atkid = self:addTemporaryValue("combat_atk", -eff.atk)
		eff.damid = self:addTemporaryValue("combat_dam", -eff.dam)
	end,
	deactivate = function(self, eff)
		self:removeParticles(eff.particle)
		self:removeTemporaryValue("combat_atk", eff.atkid)
		self:removeTemporaryValue("combat_dam", eff.damid)
	end,
}

newEffect{
	name = "GLOOM_SLOW",
	desc = "Slowed by the gloom",
	long_desc = function(self, eff) return ("The gloom reduces the target's global speed by %d%%."):format(eff.power * 100) end,
	type = "mental",
	status = "detrimental",
	parameters = { power=0.1 },
	on_gain = function(self, err) return "#F53CBE##Target# moves reluctantly!", "+Slow" end,
	on_lose = function(self, err) return "#Target# overcomes the gloom.", "-Slow" end,
	activate = function(self, eff)
		eff.particle = self:addParticles(Particles.new("gloom_slow", 1))
		eff.tmpid = self:addTemporaryValue("global_speed_add", -eff.power)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("global_speed_add", eff.tmpid)
		self:removeParticles(eff.particle)
	end,
}

newEffect{
	name = "GLOOM_STUNNED",
	desc = "Paralyzed by the gloom",
	long_desc = function(self, eff) return "The gloom has paralyzed the target, rendering it unable to act." end,
	type = "mental",
	status = "detrimental",
	parameters = {},
	on_gain = function(self, err) return "#F53CBE##Target# is paralyzed with fear!", "+Paralyzed" end,
	on_lose = function(self, err) return "#Target# overcomes the gloom", "-Paralyzed" end,
	activate = function(self, eff)
		eff.particle = self:addParticles(Particles.new("gloom_stunned", 1))
		eff.tmpid = self:addTemporaryValue("paralyzed", 1)
		-- Start the stun counter only if this is the first stun
		if self.paralyzed == 1 then self.paralyzed_counter = (self:attr("stun_immune") or 0) * 100 end
	end,
	deactivate = function(self, eff)
		self:removeParticles(eff.particle)
		self:removeTemporaryValue("paralyzed", eff.tmpid)
		if not self:attr("paralyzed") then self.paralyzed_counter = nil end
	end,
}

newEffect{
	name = "GLOOM_CONFUSED",
	desc = "Confused by the gloom",
	long_desc = function(self, eff) return ("The gloom has confused the target, making it act randomly (%d%% chance) and unable to perform complex actions."):format(eff.power) end,
	type = "mental",
	status = "detrimental",
	parameters = {},
	on_gain = function(self, err) return "#F53CBE##Target# is lost in despair!", "+Confused" end,
	on_lose = function(self, err) return "#Target# overcomes the gloom", "-Confused" end,
	activate = function(self, eff)
		eff.particle = self:addParticles(Particles.new("gloom_confused", 1))
		eff.tmpid = self:addTemporaryValue("confused", eff.power)
	end,
	deactivate = function(self, eff)
		self:removeParticles(eff.particle)
		self:removeTemporaryValue("confused", eff.tmpid)
	end,
}

newEffect{
	name = "STALKER",
	desc = "Stalking",
	long_desc = function(self, eff) return ("Stalking %s."):format(eff.target.name) end,
	type = "mental",
	status = "beneficial",
	parameters = {},
	activate = function(self, eff)
		if not self.stalkee then
			self.stalkee = eff.target
			game.logSeen(self, "#F53CBE#%s is being stalked by %s!", eff.target.name:capitalize(), self.name)
		end
	end,
	deactivate = function(self, eff)
		self.stalkee = nil
		game.logSeen(self, "#F53CBE#%s is no longer being stalked by %s.", eff.target.name:capitalize(), self.name)
	end,
}

newEffect{
	name = "STALKED",
	desc = "Being Stalked",
	long_desc = function(self, eff) return "The target is being stalked." end,
	type = "mental",
	status = "detrimental",
	parameters = {},
	activate = function(self, eff)
		if not self.stalker then
			eff.particle = self:addParticles(Particles.new("stalked", 1))
			self.stalker = eff.target
		end
	end,
	deactivate = function(self, eff)
		self.stalker = nil
		if eff.particle then self:removeParticles(eff.particle) end
	end,
}

newEffect{
	name = "DOMINATED",
	desc = "Dominated",
	long_desc = function(self, eff) return ("The target is dominated, increasing damage done to it by its master by %d%%."):format(eff.dominatedDamMult * 100) end,
	type = "mental",
	status = "detrimental",
	on_gain = function(self, err) return "#F53CBE##Target# has been dominated!", "+Dominated" end,
	on_lose = function(self, err) return "#F53CBE##Target# is no longer dominated.", "-Dominated" end,
	parameters = { dominatedDamMult = 1.3 },
	activate = function(self, eff)
		if not self.dominatedSource then
			self.dominatedSource = eff.dominatedSource
			self.dominatedDamMult = 1.3 or eff.dominatedDamMult
			eff.particle = self:addParticles(Particles.new("dominated", 1))
		end
	end,
	deactivate = function(self, eff)
		self.dominatedSource = nil
		self.dominatedDamMult = nil
		self:removeParticles(eff.particle)
	end,
}

newEffect{
	name = "RADIANT_FEAR",
	desc = "Radiating Fear",
	long_desc = function(self, eff) return "The target is frightening, pushing away other creatures." end,
	type = "mental",
	status = "beneficial",
	parameters = { knockback = 1, radius = 3 },
	on_gain = function(self, err) return "#F53CBE##Target# is surrounded by fear!", "+Radiant Fear" end,
	on_lose = function(self, err) return "#F53CBE##Target# is no longer surrounded by fear.", "-Radiant Fear" end,
	activate = function(self, eff)
		eff.particle = self:addParticles(Particles.new("radiant_fear", 1))
	end,
	deactivate = function(self, eff)
		self:removeParticles(eff.particle)
	end,
	on_timeout = function(self, eff)
		self:project({type="ball", radius=eff.radius, selffire=false}, self.x, self.y, function(xx, yy)
			local target = game.level.map(xx, yy, game.level.map.ACTOR)
			if target and target ~= self and target ~= eff.source and target:canBe("knockback") and (target.never_move or 0) ~= 1 then
				-- attempt to move target away from self
				local currentDistance = core.fov.distance(self.x, self.y, xx, yy)
				local bestDistance, bestX, bestY
				for i = 0, 8 do
					local x = xx + (i % 3) - 1
					local y = yy + math.floor((i % 9) / 3) - 1
					if x ~= xx or y ~= yy then
						local distance = core.fov.distance(self.x, self.y, x, y)
						if distance > currentDistance and (not bestDistance or distance > maxDistance) then
							-- this is a move away, see if it works
							if game.level.map:isBound(x, y) and not game.level.map:checkAllEntities(x, y, "block_move", target) then
								bestDistance, bestX, bestY = distance, x, y
								break
							end
						end
					end
				end

				if bestDistance then
					target:move(bestX, bestY, true)
					if not target.did_energy then target:useEnergy() end
				end
			end
		end)
	end,
}

newEffect{
	name = "INVIGORATED",
	desc = "Invigorated",
	long_desc = function(self, eff) return ("The target is invigorated by death, increasing global speed by %d%%."):format(eff.speed) end,
	type = "mental",
	status = "beneficial",
	parameters = { speed = 30, duration = 3 },
	on_gain = function(self, err) return nil, "+Invigorated" end,
	on_lose = function(self, err) return nil, "-Invigorated" end,
	activate = function(self, eff)
		eff.tmpid = self:addTemporaryValue("global_speed_add", eff.speed * 0.01)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("global_speed_add", eff.tmpid)
	end,
	on_merge = function(self, old_eff, new_eff)
		old_eff.dur = math.min(old_eff.dur + new_eff.dur, 15)
		return old_eff
	end,
}

newEffect{
	name = "FEED",
	desc = "Feeding",
	long_desc = function(self, eff) return ("%s is feeding from %s."):format(self.name:capitalize(), eff.target.name) end,
	type = "mental",
	status = "beneficial",
	parameters = { },
	activate = function(self, eff)
		eff.src = self

		-- hate
		if eff.hateGain and eff.hateGain > 0 then
			eff.hateGainId = self:addTemporaryValue("hate_regen", eff.hateGain)
		end

		-- health
		if eff.constitutionGain and eff.constitutionGain > 0 then
			eff.constitutionGainId = self:addTemporaryValue("inc_stats",
			{
				[Stats.STAT_CON] = eff.constitutionGain,
			})
			eff.constitutionLossId = eff.target:addTemporaryValue("inc_stats",
			{
				[Stats.STAT_CON] = -eff.constitutionGain,
			})
		end
		if eff.lifeRegenGain and eff.lifeRegenGain > 0 then
			eff.lifeRegenGainId = self:addTemporaryValue("life_regen", eff.lifeRegenGain)
			eff.lifeRegenLossId = eff.target:addTemporaryValue("life_regen", -eff.lifeRegenGain)
		end

		-- power
		if eff.damageGain and eff.damageGain > 0 then
			eff.damageGainId = self:addTemporaryValue("inc_damage", {all=eff.damageGain})
			eff.damageLossId = eff.target:addTemporaryValue("inc_damage", {all=eff.damageLoss})
		end

		-- strengths
		if eff.resistGain and eff.resistGain > 0 then
			local gainList = {}
			local lossList = {}
			for id, resist in pairs(eff.target.resists) do
				if resist > 0 then
					local amount = eff.resistGain * 0.01 * resist
					gainList[id] = amount
					lossList[id] = -amount
				end
			end

			eff.resistGainId = self:addTemporaryValue("resists", gainList)
			eff.resistLossId = eff.target:addTemporaryValue("resists", lossList)
		end

		eff.target:setEffect(eff.target.EFF_FED_UPON, eff.dur, { src = eff.src, target = eff.target })
	end,
	deactivate = function(self, eff)
		-- hate
		if eff.hateGainId then self:removeTemporaryValue("hate_regen", eff.hateGainId) end

		-- health
		if eff.constitutionGainId then self:removeTemporaryValue("inc_stats", eff.constitutionGainId) end
		if eff.constitutionLossId then eff.target:removeTemporaryValue("inc_stats", eff.constitutionLossId) end
		if eff.lifeRegenGainId then self:removeTemporaryValue("life_regen", eff.lifeRegenGainId) end
		if eff.lifeRegenLossId then eff.target:removeTemporaryValue("life_regen", eff.lifeRegenLossId) end

		-- power
		if eff.damageGainId then self:removeTemporaryValue("inc_damage", eff.damageGainId) end
		if eff.damageLossId then eff.target:removeTemporaryValue("inc_damage", eff.damageLossId) end

		-- strengths
		if eff.resistGainId then self:removeTemporaryValue("resists", eff.resistGainId) end
		if eff.resistLossId then eff.target:removeTemporaryValue("resists", eff.resistLossId) end

		if eff.particles then
			-- remove old particle emitter
			game.level.map:removeParticleEmitter(eff.particles)
			eff.particles = nil
		end

		eff.target:removeEffect(eff.target.EFF_FED_UPON)
	end,
	updateFeed = function(self, eff)
		local source = eff.src
		local target = eff.target

		if source.dead or target.dead or not game.level:hasEntity(source) or not game.level:hasEntity(target) or not source:hasLOS(target.x, target.y) then
			source:removeEffect(source.EFF_FEED)
			if eff.particles then
				game.level.map:removeParticleEmitter(eff.particles)
				eff.particles = nil
			end
			return
		end

		-- update particles position
		if not eff.particles or eff.particles.x ~= source.x or eff.particles.y ~= source.y or eff.particles.tx ~= target.x or eff.particles.ty ~= target.y then
			if eff.particles then
				game.level.map:removeParticleEmitter(eff.particles)
			end
			-- add updated particle emitter
			local dx, dy = target.x - source.x, target.y - source.y
			eff.particles = Particles.new("feed_hate", math.max(math.abs(dx), math.abs(dy)), { tx=dx, ty=dy })
			eff.particles.x = source.x
			eff.particles.y = source.y
			eff.particles.tx = target.x
			eff.particles.ty = target.y
			game.level.map:addParticleEmitter(eff.particles)
		end
	end
}

newEffect{
	name = "FED_UPON",
	desc = "Fed Upon",
	long_desc = function(self, eff) return ("%s is fed upon by %s."):format(self.name:capitalize(), eff.src.name) end,
	type = "mental",
	status = "detrimental",
	remove_on_clone = true,
	parameters = { },
	activate = function(self, eff)
	end,
	deactivate = function(self, eff)
		if eff.target == self and eff.src:hasEffect(eff.src.EFF_FEED) then
			eff.src:removeEffect(eff.src.EFF_FEED)
		end
	end,
}

newEffect{
	name = "AGONY",
	desc = "Agony",
	long_desc = function(self, eff) return ("%s is writhing in agony, suffering from %d to %d damage over %d turns."):format(self.name:capitalize(), eff.damage / eff.duration, eff.damage, eff.duration) end,
	type = "mental",
	status = "detrimental",
	parameters = { damage=10, mindpower=10, range=10, minPercent=10 },
	on_gain = function(self, err) return "#Target# is writhing in agony!", "+Agony" end,
	on_lose = function(self, err) return "#Target# is no longer writhing in agony.", "-Agony" end,
	activate = function(self, eff)
		eff.power = 0
	end,
	deactivate = function(self, eff)
		if eff.particle then self:removeParticles(eff.particle) end
	end,
	on_timeout = function(self, eff)
		eff.turn = (eff.turn or 0) + 1

		local damage = math.floor(eff.damage * (eff.turn / eff.duration))
		if damage > 0 then
			DamageType:get(DamageType.MIND).projector(eff.source, self.x, self.y, DamageType.MIND, damage)
			game:playSoundNear(self, "talents/fire")
		end

		if self.dead then
			if eff.particle then self:removeParticles(eff.particle) end
			return
		end

		if eff.particle then self:removeParticles(eff.particle) end
		eff.particle = nil
		eff.particle = self:addParticles(Particles.new("agony", 1, { power = 10 * eff.turn / eff.duration }))
	end,
}

newEffect{
	name = "HATEFUL_WHISPER",
	desc = "Hateful Whisper",
	long_desc = function(self, eff) return ("%s has heard the hateful whisper."):format(self.name:capitalize()) end,
	type = "mental",
	status = "detrimental",
	parameters = { },
	on_gain = function(self, err) return "#Target# has heard the hateful whisper!", "+Hateful Whisper" end,
	on_lose = function(self, err) return "#Target# no longer hears the hateful whisper.", "-Hateful Whisper" end,
	activate = function(self, eff)
		DamageType:get(DamageType.MIND).projector(eff.source, self.x, self.y, DamageType.MIND, eff.damage)

		if self.dead then
			-- only spread on activate if the target is dead
			self.tempeffect_def[self.EFF_HATEFUL_WHISPER].doSpread(self, eff)
			eff.duration = 0
		else
			eff.particle = self:addParticles(Particles.new("hateful_whisper", 1, { }))
		end

		game:playSoundNear(self, "talents/fire")
	end,
	deactivate = function(self, eff)
		if eff.particle then self:removeParticles(eff.particle) end
	end,
	on_timeout = function(self, eff)
		eff.duration = eff.duration - 1
		if eff.duration <= 0 then return false end

		if (eff.state or 0) == 0 then
			-- pause a turn before infecting others
			eff.state = 1
		elseif eff.state == 1 then
			self.tempeffect_def[self.EFF_HATEFUL_WHISPER].doSpread(self, eff)
			eff.state = 2
		end
	end,
	doSpread = function(self, eff)
		local targets = {}
		local grids = core.fov.circle_grids(self.x, self.y, eff.jumpRange, true)
		for x, yy in pairs(grids) do
			for y, _ in pairs(grids[x]) do
				local a = game.level.map(x, y, game.level.map.ACTOR)
				if a and eff.source:reactionToward(a) < 0 and self:hasLOS(a.x, a.y) then
					if not a:hasEffect(a.EFF_HATEFUL_WHISPER) then
						targets[#targets+1] = a
					end
				end
			end
		end

		if #targets > 0 then
			local hitCount = 1
			if rng.percent(eff.extraJumpChance or 0) then hitCount = hitCount + 1 end

			-- Randomly take targets
			for i = 1, hitCount do
				local target = rng.tableRemove(targets)
				target:setEffect(target.EFF_HATEFUL_WHISPER, eff.duration, {
					source = eff.source,
					duration = eff.duration,
					damage = eff.damage,
					mindpower = eff.mindpower,
					jumpRange = eff.jumpRange,
					extraJumpChance = eff.extraJumpChance
				})

				game.level.map:particleEmitter(target.x, target.y, 1, "reproach", { dx = self.x - target.x, dy = self.y - target.y })

				if #targets == 0 then break end
			end
		end
	end,
}

newEffect{
	name = "MADNESS_SLOW",
	desc = "Slowed by madness",
	long_desc = function(self, eff) return ("Madness reduces the target's global speed by %d%%."):format(eff.power * 100) end,
	type = "mental",
	status = "detrimental",
	parameters = { power=0.1 },
	on_gain = function(self, err) return "#F53CBE##Target# slows in the grip of madness!", "+Slow" end,
	on_lose = function(self, err) return "#Target# overcomes the madness.", "-Slow" end,
	activate = function(self, eff)
		eff.particle = self:addParticles(Particles.new("gloom_slow", 1))
		eff.tmpid = self:addTemporaryValue("global_speed_add", -eff.power)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("global_speed_add", eff.tmpid)
		self:removeParticles(eff.particle)
	end,
}

newEffect{
	name = "MADNESS_STUNNED",
	desc = "Paralyzed by madness",
	long_desc = function(self, eff) return "Madness has paralyzed the target, rendering it unable to act." end,
	type = "mental",
	status = "detrimental",
	parameters = {},
	on_gain = function(self, err) return "#F53CBE##Target# is paralyzed by madness!", "+Paralyzed" end,
	on_lose = function(self, err) return "#Target# overcomes the madness", "-Paralyzed" end,
	activate = function(self, eff)
		eff.particle = self:addParticles(Particles.new("gloom_stunned", 1))
		eff.tmpid = self:addTemporaryValue("paralyzed", 1)
		-- Start the stun counter only if this is the first stun
		if self.paralyzed == 1 then self.paralyzed_counter = (self:attr("stun_immune") or 0) * 100 end
	end,
	deactivate = function(self, eff)
		self:removeParticles(eff.particle)
		self:removeTemporaryValue("paralyzed", eff.tmpid)
		if not self:attr("paralyzed") then self.paralyzed_counter = nil end
	end,
}

newEffect{
	name = "MADNESS_CONFUSED",
	desc = "Confused by madness",
	long_desc = function(self, eff) return ("Madness has confused the target, making it act randomly (%d%% chance) and unable to perform complex actions."):format(eff.power) end,
	type = "mental",
	status = "detrimental",
	parameters = {},
	on_gain = function(self, err) return "#F53CBE##Target# is lost in madness!", "+Confused" end,
	on_lose = function(self, err) return "#Target# overcomes the madness", "-Confused" end,
	activate = function(self, eff)
		eff.particle = self:addParticles(Particles.new("gloom_confused", 1))
		eff.tmpid = self:addTemporaryValue("confused", eff.power)
	end,
	deactivate = function(self, eff)
		self:removeParticles(eff.particle)
		self:removeTemporaryValue("confused", eff.tmpid)
	end,
}

newEffect{
	name = "QUICKNESS",
	desc = "Quick",
	long_desc = function(self, eff) return ("Increases run speed by %d%%."):format(eff.power * 100) end,
	type = "mental",
	status = "beneficial",
	parameters = { power=0.1 },
	on_gain = function(self, err) return "#Target# speeds up.", "+Quick" end,
	on_lose = function(self, err) return "#Target# slows down.", "-Quick" end,
	activate = function(self, eff)
		eff.tmpid = self:addTemporaryValue("movement_speed", eff.power)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("movement_speed", eff.tmpid)
	end,
}
newEffect{
	name = "PSIFRENZY",
	desc = "Frenzied Psi-fighting",
	long_desc = function(self, eff) return ("Causes telekinetically-wielded weapons to hit up to %d targets each turn."):format(eff.power) end,
	type = "mental",
	status = "beneficial",
	parameters = {dam=10},
	on_gain = function(self, err) return "#Target# enters a frenzy!", "+Frenzy" end,
	on_lose = function(self, err) return "#Target# is no longer frenzied.", "-Frenzy" end,
}

newEffect{
	name = "KINSPIKE_SHIELD",
	desc = "Spiked Kinetic Shield",
	long_desc = function(self, eff) return ("The target erects a powerful kinetic shield capable of absorbing %d/%d physical or acid damage before it crumbles."):format(self.kinspike_shield_absorb, eff.power) end,
	type = "mental",
	status = "beneficial",
	parameters = { power=100 },
	on_gain = function(self, err) return "A powerful kinetic shield forms around #target#.", "+Shield" end,
	on_lose = function(self, err) return "The powerful kinetic shield around #target# crumbles.", "-Shield" end,
	activate = function(self, eff)
		eff.tmpid = self:addTemporaryValue("kinspike_shield", eff.power)
		self.kinspike_shield_absorb = eff.power
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("kinspike_shield", eff.tmpid)
		self.kinspike_shield_absorb = nil
	end,
}
newEffect{
	name = "THERMSPIKE_SHIELD",
	desc = "Spiked Thermal Shield",
	long_desc = function(self, eff) return ("The target erects a powerful thermal shield capable of absorbing %d/%d thermal damage before it crumbles."):format(self.thermspike_shield_absorb, eff.power) end,
	type = "mental",
	status = "beneficial",
	parameters = { power=100 },
	on_gain = function(self, err) return "A powerful thermal shield forms around #target#.", "+Shield" end,
	on_lose = function(self, err) return "The powerful thermal shield around #target# crumbles.", "-Shield" end,
	activate = function(self, eff)
		eff.tmpid = self:addTemporaryValue("thermspike_shield", eff.power)
		self.thermspike_shield_absorb = eff.power
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("thermspike_shield", eff.tmpid)
		self.thermspike_shield_absorb = nil
	end,
}
newEffect{
	name = "CHARGESPIKE_SHIELD",
	desc = "Spiked Charged Shield",
	long_desc = function(self, eff) return ("The target erects a powerful charged shield capable of absorbing %d/%d lightning or blight damage before it crumbles."):format(self.chargespike_shield_absorb, eff.power) end,
	type = "mental",
	status = "beneficial",
	parameters = { power=100 },
	on_gain = function(self, err) return "A powerful charged shield forms around #target#.", "+Shield" end,
	on_lose = function(self, err) return "The powerful charged shield around #target# crumbles.", "-Shield" end,
	activate = function(self, eff)
		eff.tmpid = self:addTemporaryValue("chargespike_shield", eff.power)
		self.chargespike_shield_absorb = eff.power
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("chargespike_shield", eff.tmpid)
		self.chargespike_shield_absorb = nil
	end,
}

newEffect{
	name = "CONTROL",
	desc = "Perfect control",
	long_desc = function(self, eff) return ("The target's combat attack and crit chance are improved by %d and %d%%, respectively."):format(eff.power, 0.5*eff.power) end,
	type = "mental",
	status = "beneficial",
	parameters = { power=10 },
	activate = function(self, eff)
		eff.attack = self:addTemporaryValue("combat_atk", eff.power)
		eff.crit = self:addTemporaryValue("combat_physcrit", 0.5*eff.power)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("combat_atk", eff.attack)
		self:removeTemporaryValue("combat_physcrit", eff.crit)
	end,
}

newEffect{
	name = "PSI_REGEN",
	desc = "Matter is energy",
	long_desc = function(self, eff) return ("The gem's matter gradually transforms, granting %0.2f energy per turn."):format(eff.power) end,
	type = "mental",
	status = "beneficial",
	parameters = { power=10 },
	on_gain = function(self, err) return "Energy starts pouring from the gem into #Target#.", "+Energy" end,
	on_lose = function(self, err) return "The flow of energy from #Target#'s gem ceases.", "-Energy" end,
	activate = function(self, eff)
		eff.tmpid = self:addTemporaryValue("psi_regen", eff.power)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("psi_regen", eff.tmpid)
	end,
}

newEffect{
	name = "MASTERFUL_TELEKINETIC_ARCHERY",
	desc = "Telekinetic Archery",
	long_desc = function(self, eff) return ("Your telekinetically-wielded bow automatically attacks the nearest target each turn.") end,
	type = "mental",
	status = "beneficial",
	parameters = {dam=10},
	on_gain = function(self, err) return "#Target# enters a telekinetic archer's trance!", "+Telekinetic archery" end,
	on_lose = function(self, err) return "#Target# is no longer in a telekinetic archer's trance.", "-Telekinetic archery" end,
}

newEffect{
	name = "WEAKENED_MIND",
	desc = "Weakened Mind",
	long_desc = function(self, eff) return ("Decreases mind save by %d."):format(eff.power) end,
	type = "mental",
	status = "detrimental",
	parameters = { power=10 },
	activate = function(self, eff)
		eff.mindid = self:addTemporaryValue("combat_mentalresist", -eff.power)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("combat_mentalresist", eff.mindid)
	end,
}

newEffect{
	name = "VOID_ECHOES",
	desc = "Void Echoes",
	long_desc = function(self, eff) return ("The target is seeing echoes from the void and will take %0.2f mind damage as well as some resource damage each turn it fails a mental save."):format(eff.power) end,
	type = "mental",
	status = "detrimental",
	parameters = { power=10 },
	on_gain = function(self, err) return "#Target# is being driven mad by the void.", "+Void Echoes" end,
	on_lose = function(self, err) return "#Target# has survived the void madness.", "-Void Echoes" end,
	on_timeout = function(self, eff)
		local drain = DamageType:get(DamageType.MIND).projector(eff.src or self, self.x, self.y, DamageType.MIND, eff.power) / 2
		self:incMana(-drain)
		self:incVim(-drain * 0.5)
		self:incPositive(-drain * 0.25)
		self:incNegative(-drain * 0.25)
		self:incStamina(-drain * 0.65)
		self:incHate(-drain * 0.05)
		self:incPsi(-drain * 0.2)
	end,
}

newEffect{
	name = "WAKING_NIGHTMARE",
	desc = "Waking Nightmare",
	long_desc = function(self, eff) return ("The target is lost in a waking nightmare that deals %0.2f darkness damage each turn and has a %d%% chance to cause a random effect detrimental."):format(eff.dam, eff.chance) end,
	type = "mental",
	status = "detrimental",
	parameters = { chance=10, dam = 10 },
	on_gain = function(self, err) return "#Target# is lost in a waking nightmare.", "+Waking Nightmare" end,
	on_lose = function(self, err) return "#Target# is free from the nightmare.", "-Waking Nightmare" end,
	on_timeout = function(self, eff)
		DamageType:get(DamageType.DARKNESS).projector(eff.src or self, self.x, self.y, DamageType.DARKNESS, eff.dam)
		if rng.percent(eff.chance or 0) then
			-- Pull random effect
			local chance = rng.range(1, 3)
			if chance == 1 then
				if self:canBe("blind") then
					self:setEffect(self.EFF_BLINDED, 3, {})
				end
			elseif chance == 2 then
				if self:canBe("stun") then
					self:setEffect(self.EFF_STUNNED, 3, {})
				end
			elseif chance == 3 then
				if self:canBe("confusion") then
					self:setEffect(self.EFF_CONFUSED, 3, {power=50})
				end
			end
			game.logSeen(self, "%s succumbs to the nightmare!", self.name:capitalize())
		end
	end,
}

newEffect{
	name = "ABYSSAL_SHROUD",
	desc = "Abyssal Shroud",
	long_desc = function(self, eff) return ("The target's lite radius has been reduced by %d and it's darkness resistance by %d%%."):format(eff.lite, eff.power) end,
	type = "mental",
	status = "detrimental",
	parameters = {power=20},
	on_gain = function(self, err) return "#Target# feels closer to the abyss!", "+Abyssal Shroud" end,
	on_lose = function(self, err) return "#Target# is free from the abyss.", "-Abyssal Shroud" end,
	activate = function(self, eff)
		eff.liteid = self:addTemporaryValue("lite", -eff.lite)
		eff.darkid = self:addTemporaryValue("resists", { [DamageType.DARKNESS] = -eff.power })
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("lite", eff.liteid)
		self:removeTemporaryValue("resists", eff.darkid)
	end,
}

newEffect{
	name = "INNER_DEMONS",
	desc = "Inner Demons",
	long_desc = function(self, eff) return ("The target is plagued by inner demons and each turn there's a %d%% chance that one will appear.  If the caster is killed or the target resists setting his demons loose the effect will end early."):format(eff.chance) end,
	type = "mental",
	status = "detrimental",
	parameters = {},
	on_gain = function(self, err) return "#Target# is plagued by inner demons!", "+Inner Demons" end,
	on_lose = function(self, err) return "#Target# is freed from the demons.", "-Inner Demons" end,
	on_timeout = function(self, eff)
		if eff.src.dead or not game.level:hasEntity(eff.src) then eff.dur = 0 return true end
		if rng.percent(eff.chance or 0) then
			if self:checkHit(eff.src:combatSpellpower(), self:combatSpellResist(), 0, 95, 5) then
				local t = eff.src:getTalentFromId(eff.src.T_INNER_DEMONS)
				t.summon_inner_demons(eff.src, self, t)
			else
				eff.dur = 0
			end
		end
	end,
}

newEffect{
	name = "PACIFICATION_HEX",
	desc = "Pacification Hex",
	long_desc = function(self, eff) return ("The target is hexed, granting it %d%% chance each turn to be dazed for 3 turns."):format(eff.chance) end,
	type = "mental",
	subtype = "hex",
	status = "detrimental",
	parameters = {chance=10, power=10},
	on_gain = function(self, err) return "#Target# is hexed!", "+Pacification Hex" end,
	on_lose = function(self, err) return "#Target# is free from the hex.", "-Pacification Hex" end,
	-- Damage each turn
	on_timeout = function(self, eff)
		if not self:hasEffect(self.EFF_DAZED) and rng.percent(eff.chance) then
			self:setEffect(self.EFF_DAZED, 3, {})
			if not self:checkHit(eff.power, self:combatSpellResist(), 0, 95, 15) then eff.dur = 0 end
		end
	end,
	activate = function(self, eff)
		self:setEffect(self.EFF_DAZED, 3, {})
	end,
}

newEffect{
	name = "BURNING_HEX",
	desc = "Burning Hex",
	long_desc = function(self, eff) return ("The target is hexed. Each time it uses an ability it takes %0.2f fire damage."):format(eff.dam) end,
	type = "mental",
	subtype = "hex",
	status = "detrimental",
	parameters = {dam=10},
	on_gain = function(self, err) return "#Target# is hexed!", "+Burning Hex" end,
	on_lose = function(self, err) return "#Target# is free from the hex.", "-Burning Hex" end,
}

newEffect{
	name = "EMPATHIC_HEX",
	desc = "Empathic Hex",
	long_desc = function(self, eff) return ("The target is hexed, creating an empathic bond with its victims. It takes %d%% feedback damage from all damage done."):format(eff.power) end,
	type = "mental",
	subtype = "hex",
	status = "detrimental",
	parameters = { power=10 },
	on_gain = function(self, err) return "#Target# is hexed.", "+Empathic Hex" end,
	on_lose = function(self, err) return "#Target# is free from the hex.", "-Empathic hex" end,
	activate = function(self, eff)
		eff.tmpid = self:addTemporaryValue("martyrdom", eff.power)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("martyrdom", eff.tmpid)
	end,
}

newEffect{
	name = "DOMINATION_HEX",
	desc = "Domination Hex",
	long_desc = function(self, eff) return ("The target is hexed, temporarily changing its faction to %s."):format(engine.Faction.factions[eff.faction].name) end,
	type = "mental",
	subtype = "hex",
	status = "detrimental",
	parameters = {},
	on_gain = function(self, err) return "#Target# is hexed.", "+Domination Hex" end,
	on_lose = function(self, err) return "#Target# is free from the hex.", "-Domination hex" end,
	activate = function(self, eff)
		eff.olf_faction = self.faction
		self.faction = eff.src.faction
	end,
	deactivate = function(self, eff)
		self.faction = eff.olf_faction
	end,
}
