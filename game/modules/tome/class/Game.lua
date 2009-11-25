require "engine.class"
require "engine.GameTurnBased"
require "engine.KeyCommand"
require "engine.LogDisplay"
local Tooltip = require "engine.Tooltip"
local QuitDialog = require "mod.dialogs.Quit"
local Calendar = require "engine.Calendar"
local Zone = require "engine.Zone"
local Map = require "engine.Map"
local Target = require "engine.Target"
local Level = require "engine.Level"
local Grid = require "engine.Grid"
local Actor = require "mod.class.Actor"
local Player = require "mod.class.Player"
local NPC = require "mod.class.NPC"

module(..., package.seeall, class.inherit(engine.GameTurnBased))

function _M:init()
	engine.GameTurnBased.init(self, engine.Key.current, 1000, 100)
end

function _M:run()
	Zone:setup{npc_class="mod.class.NPC", grid_class="mod.class.Grid", object_class="engine.Entity"}
	Map:setViewPort(0, 0, self.w, math.floor(self.h * 0.80), 16, 16)

	self.calendar = Calendar.new("/data/calendar_rivendell.lua", "Today is the %s %s of the %s year of the Fourth Age of Middle-earth.\nThe time is %02d:%02d.", 122)
	self.day_of_year = self.calendar:getDayOfYear(self.turn)

	self.zone = Zone.new("ancient_ruins")

	self.tooltip = engine.Tooltip.new(nil, nil, {255,255,255}, {30,30,30})

	self.log = engine.LogDisplay.new(0, self.h * 0.80, self.w * 0.5, self.h * 0.20, nil, nil, nil, {255,255,255}, {30,30,30})
	self.log("Welcome to #00FF00#Tales of Middle Earth!")
	self.logSeen = function(e, ...) if e and self.level.map.seens(e.x, e.y) then self.log(...) end end

	self.player = Player.new{name="player", image='player.png', display='@', color_r=230, color_g=230, color_b=230}

	self:changeLevel(1)

	self.target = Target.new(Map, self.player)
	self.target.target.entity = self.player
	self.old_tmx, self.old_tmy = 0, 0

	-- Ok everything is good to go, activate the game in the engine!
	self:setCurrent()

	self:setupCommands()
	self:setupMouse()

--	self:registerDialog(require('mod.dialogs.EnterName').new())
end

function _M:changeLevel(lev)
	self.zone:getLevel(self, lev)
	self.player:move(self.level.start.x, self.level.start.y, true)
	self.level:addEntity(self.player)
end


function _M:tick()
	engine.GameTurnBased.tick(self)

	if self.day_of_year ~= self.calendar:getDayOfYear(self.turn) then
		self.log(self.calendar:getTimeDate(self.turn))
		self.day_of_year = self.calendar:getDayOfYear(self.turn)
	end
end

function _M:display()
	self.log:display():toScreen(self.log.display_x, self.log.display_y)

	if self.level and self.level.map then
		if self.level.map.changed then
			self.level.map:fov(self.player.x, self.player.y, 20)
			self.level.map:fovLite(self.player.x, self.player.y, 4)
		end
		local s = self.level.map:display()
		if s then
			s:toScreen(self.level.map.display_x, self.level.map.display_y)
		end

		local mx, my = core.mouse.get()
		local tmx, tmy = math.floor(mx / self.level.map.tile_w), math.floor(my / self.level.map.tile_h)
		local tt = self.level.map:checkAllEntities(tmx, tmy, "tooltip")
		if tt then
			self.tooltip:set(tt)
			local t = self.tooltip:display()
			if t then t:toScreen(mx, my) end
		end
		if self.old_tmx ~= tmx or self.old_tmy ~= tmy then
			self.target.target.x, self.target.target.y = tmx, tmy
		end
		self.old_tmx, self.old_tmy = tmx, tmy

		self.target:display()
	end

	engine.GameTurnBased.display(self)
end

function _M:setupCommands()
	self.key:addCommands
	{
		_LEFT = function()
			if self.player:move(self.player.x - 1, self.player.y) then
				self.paused = false
			end
		end,
		_RIGHT = function()
			if self.player:move(self.player.x + 1, self.player.y) then
				self.paused = false
			end
		end,
		_UP = function()
			if self.player:move(self.player.x, self.player.y - 1) then
				self.paused = false
			end
		end,
		_DOWN = function()
			if self.player:move(self.player.x, self.player.y + 1) then
				self.paused = false
			end
		end,
		_KP1 = function()
			if self.player:move(self.player.x - 1, self.player.y + 1) then
				self.paused = false
			end
		end,
		_KP2 = function()
			if self.player:move(self.player.x, self.player.y + 1) then
				self.paused = false
			end
		end,
		_KP3 = function()
			if self.player:move(self.player.x + 1, self.player.y + 1) then
				self.paused = false
			end
		end,
		_KP4 = function()
			if self.player:move(self.player.x - 1, self.player.y) then
				self.paused = false
			end
		end,
		_KP5 = function()
			if self.player:move(self.player.x, self.player.y) then
				self.paused = false
			end
		end,
		_KP6 = function()
			if self.player:move(self.player.x + 1, self.player.y) then
				self.paused = false
			end
		end,
		_KP7 = function()
			if self.player:move(self.player.x - 1, self.player.y - 1) then
				self.paused = false
			end
		end,
		_KP8 = function()
			if self.player:move(self.player.x, self.player.y - 1) then
				self.paused = false
			end
		end,
		_KP9 = function()
			if self.player:move(self.player.x + 1, self.player.y - 1) then
				self.paused = false
			end
		end,
		[{"_LESS","anymod"}] = function()
			local e = self.level.map(self.player.x, self.player.y, Map.TERRAIN)
			if self.player:enoughEnergy() and e.change_level then
				-- Do not unpause, the player is allowed first move on next level
				self:changeLevel(self.level.level + e.change_level)
				print(self.level.level)
			else
				self.log("There is no way out of this level here.")
			end
		end,
		_GREATER = {"alias", "_LESS"},
		-- Toggle tactical displau
		_t = function()
			if Map.view_faction then
				Map:setViewerFaction(nil)
				self.log("Tactical display disabled.")
				self.level.map.changed = true
				self.target:setActive(false)
			else
				Map:setViewerFaction("players")
				self.log("Tactical display enabled.")
				self.level.map.changed = true
				self.target:setActive(true)
				-- Find nearest target
				self.target:scan(5)
			end
		end,
		-- Toggle tactical displau
		[{"_t","ctrl"}] = function()
			self.log(self.calendar:getTimeDate(self.turn))
		end,
		-- Exit the game
		[{"_x","ctrl"}] = function()
			self:registerDialog(QuitDialog.new())
		end,

		-- Targeting movement
		[{"_LEFT","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x - 1 end,
		[{"_RIGHT","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x + 1 end,
		[{"_UP","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.y = self.target.target.y - 1 end,
		[{"_DOWN","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.y = self.target.target.y + 1 end,
		[{"_KP4","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x - 1 end,
		[{"_KP6","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x + 1 end,
		[{"_KP8","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.y = self.target.target.y - 1 end,
		[{"_KP2","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.y = self.target.target.y + 1 end,
		[{"_KP1","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x - 1 self.target.target.y = self.target.target.y + 1 end,
		[{"_KP3","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x + 1 self.target.target.y = self.target.target.y + 1 end,
		[{"_KP7","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x - 1 self.target.target.y = self.target.target.y - 1 end,
		[{"_KP9","ctrl","shift"}] = function() self.target.target.entity=nil self.target.target.x = self.target.target.x + 1 self.target.target.y = self.target.target.y - 1 end,

		[{"_LEFT","ctrl"}] = function() self.target:scan(4) end,
		[{"_RIGHT","ctrl"}] = function() self.target:scan(6) end,
		[{"_UP","ctrl"}] = function() self.target:scan(8) end,
		[{"_DOWN","ctrl"}] = function() self.target:scan(2) end,
		[{"_KP4","ctrl"}] = function() self.target:scan(4) end,
		[{"_KP6","ctrl"}] = function() self.target:scan(6) end,
		[{"_KP8","ctrl"}] = function() self.target:scan(8) end,
		[{"_KP2","ctrl"}] = function() self.target:scan(2) end,
		[{"_KP1","ctrl"}] = function() self.target:scan(1) end,
		[{"_KP3","ctrl"}] = function() self.target:scan(3) end,
		[{"_KP7","ctrl"}] = function() self.target:scan(7) end,
		[{"_KP9","ctrl"}] = function() self.target:scan(9) end,

	}
	self.key:setCurrent()
end

function _M:setupMouse()
--	self.mouse:registerZoneClick(Map.display_x, Map.display_y, Map.viewport.width, Map.viewport.height, function()
--	end)
	self.mouse:registerZoneClick(self.log.display_x, self.log.display_y, self.w, self.h, function(button)
		if button == "wheelup" then self.log:scrollUp(1) end
		if button == "wheeldown" then self.log:scrollUp(-1) end
	end)
end
