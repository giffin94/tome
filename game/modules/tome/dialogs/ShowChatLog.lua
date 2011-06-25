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

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local Tab = require "engine.ui.Tab"
local Mouse = require "engine.Mouse"
local Slider = require "engine.ui.Slider"

module(..., package.seeall, class.inherit(Dialog))

function _M:init(title, shadow, log, chat)
	local w = math.floor(game.w * 0.9)
	local h = math.floor(game.h * 0.9)
	Dialog.init(self, title, w, h)
	if shadow then self.shadow = shadow end

	self.log, self.chat = log, chat

	local tabs = {}

	local order = {}
	local list = {}
	for name, data in pairs(chat.channels) do list[#list+1] = name end
	table.sort(list, function(a,b) if a == "global" then return 1 elseif b == "global" then return nil else return a < b end end)
	order[#order+1] = {timestamp=log:getLogLast(), tab="__log"}

	tabs[#tabs+1] = {top=0, left=0, ui = Tab.new{title="Game Log", fct=function() end, on_change=function() local i = #tabs self:switchTo(tabs[1]) end, default=true}, tab_channel="__log" }
	for i, name in ipairs(list) do
		local oname = name
		local nb_users = 0
		for _, _ in pairs(chat.channels[name].users) do nb_users = nb_users + 1 end
		name = name:capitalize().." ("..nb_users..")"

		local ii = i
		tabs[#tabs+1] = {top=0, left=(#tabs==0) and 0 or tabs[#tabs].ui, ui = Tab.new{title=name, fct=function() end, on_change=function() local i = ii+1 self:switchTo(tabs[i]) end, default=false}, tab_channel=oname }
		order[#order+1] = {timestamp=chat:getLogLast(oname), tab=oname}
	end

	self.start_y = tabs[1].ui.h + 5

	self:loadUI(tabs)
	self.tabs = tabs
	self:setupUI()

	self.scrollbar = Slider.new{size=self.h - 20, max=1, inverse=true}

	table.sort(order, function(a,b) return a.timestamp > b.timestamp end)
	self:switchTo(self.last_tab or "__log")
end

function _M:generate()
	Dialog.generate(self)

	-- Add UI controls
	local tabs = self.tabs
	self.key:addBinds{
		MOVE_UP = function() self:setScroll(self.scroll - 1) end,
		MOVE_DOWN = function() self:setScroll(self.scroll + 1) end,
		ACCEPT = "EXIT",
		EXIT = function() game:unregisterDialog(self) end,
	}
	self.key:addCommands{
		_TAB = function() local sel = 1 for i=1, #tabs do if tabs[i].ui.selected then sel = i break end end self:switchTo(tabs[util.boundWrap(sel+1, 1, #tabs)]) end,
		_HOME = function() self:setScroll(1) end,
		_END = function() self:setScroll(self.max) end,
		_PAGEUP = function() self:setScroll(self.scroll - self.max_display) end,
		_PAGEDOWN = function() self:setScroll(self.scroll + self.max_display) end,
	}
end

function _M:mouseEvent(button, x, y, xrel, yrel, bx, by, event)
	Dialog.mouseEvent(self, button, x, y, xrel, yrel, bx, by, event)

	if button == "wheelup" and event == "button" then self.key:triggerVirtual("MOVE_UP")
	elseif button == "wheeldown" and event == "button" then self.key:triggerVirtual("MOVE_DOWN")
	end
end

function _M:loadLog(log)
	self.lines = {}
	for i = #log, 1, -1 do
		self.lines[#self.lines+1] = log[i]
	end

	self.max_h = self.ih - self.iy
	self.max = #log
	self.max_display = math.floor(self.max_h / self.font_h)

	self.scrollbar.max = self.max - self.max_display + 1
	self.scroll = nil
	self:setScroll(self.max - self.max_display + 1)
end

function _M:switchTo(ui)
	if type(ui) == "string" then for i, tab in ipairs(self.tabs) do if tab.tab_channel == ui then ui = tab end end end
	if type(ui) == "string" then ui = self.tabs[1] end

	for i, ui in ipairs(self.tabs) do ui.ui.selected = false end
	ui.ui.selected = true
	if ui.tab_channel == "__log" then
		self:loadLog(self.log:getLog())
	else
		self:loadLog(self.chat:getLog(ui.tab_channel))
	end
	-- Set it on the class to persist between invocations
	_M.last_tab = ui.tab_channel
end

function _M:setScroll(i)
	local old = self.scroll
	self.scroll = util.bound(i, 1, math.max(1, self.max - self.max_display + 1))
	if self.scroll == old then return end

	self.dlist = {}
	local nb = 0
	local old_style = self.font:getStyle()
	for z = 1 + self.scroll, #self.lines do
		local stop = false
		local tstr = self.lines[z]
		if not tstr then break end
		local gen = self.font:draw(tstr, self.iw - 10, 255, 255, 255)
		for i = 1, #gen do
			self.dlist[#self.dlist+1] = gen[i]
			nb = nb + 1
			if nb >= self.max_display then stop = true break end
		end
		if stop then break end
	end
	self.font:setStyle(old_style)
end

function _M:innerDisplay(x, y, nb_keyframes)
	local h = y + self.iy + self.start_y
	for i = 1, #self.dlist do
		local item = self.dlist[i]
		if self.shadow then item._tex:toScreenFull(x+2, h+2, item.w, item.h, item._tex_w, item._tex_h, 0,0,0, self.shadow) end
		item._tex:toScreenFull(x, h, item.w, item.h, item._tex_w, item._tex_h)
		h = h + self.font_h
	end

	self.scrollbar.pos = self.scrollbar.max - self.scroll + 1
	self.scrollbar:display(x + self.iw - self.scrollbar.w, y)
end