-- TE4 - T-Engine 4
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

require "engine.class"
local Base = require "engine.ui.Base"
local Focusable = require "engine.ui.Focusable"

--- A generic UI list
module(..., package.seeall, class.inherit(Base, Focusable))

function _M:init(t)
	self.tree = assert(t.tree, "no tree tree")
	self.columns = assert(t.columns, "no list columns")
	self.w = assert(t.width, "no tree width")
	self.h = t.height
	self.nb_items = t.nb_items
	assert(self.h or self.nb_items, "no tree height/nb_items")
	self.fct = t.fct
	self.on_expand = t.on_expand
	self.display_prop = t.display_prop or "name"
	self.scrollbar = t.scrollbar
	self.all_clicks = t.all_clicks
	self.level_offset = t.level_offset or 12

	local w = self.w
	if self.scrollbar then w = w - 10 end
	for j, col in ipairs(self.columns) do
		col.width = w * col.width / 100
	end

	Base.init(self, t)
end

local ls, ls_w, ls_h = _M:getImage("ui/selection-left-sel.png")
local ms, ms_w, ms_h = _M:getImage("ui/selection-middle-sel.png")
local rs, rs_w, rs_h = _M:getImage("ui/selection-right-sel.png")
local l, l_w, l_h = _M:getImage("ui/selection-left.png")
local m, m_w, m_h = _M:getImage("ui/selection-middle.png")
local r, r_w, r_h = _M:getImage("ui/selection-right.png")
local plus, plus_w, plus_h = _M:getImage("ui/plus.png")
local minus, minus_w, minus_h = _M:getImage("ui/minus.png")

function _M:drawItem(item)
	item.cols = {}
	for i, col in ipairs(self.columns) do
		local level = item.level
		local color = item.color or {255,255,255}
		local text = tostring(item[col.display_prop])
		local ss = core.display.newSurface(col.width, self.fh)
		local sus = core.display.newSurface(col.width, self.fh)
		local s = core.display.newSurface(col.width, self.fh)

		local offset = 0
		if i == 1 then
			offset = level * self.level_offset
			if item.nodes then offset = offset + plus_w end
		end
		local startx = ls_w + offset

		if i == 1 and item.nodes then ss:merge(item.shown and minus or plus, 0, 0) end
		ss:merge(ls, offset, 0)
		for i = startx, col.width - rs_w do ss:merge(ms, i, 0) end
		ss:merge(rs, col.width - rs_w, 0)
		ss:drawColorStringBlended(self.font, text, startx, (self.fh - self.font_h) / 2, color[1], color[2], color[3], nil, col.width - startx - rs_w)

		s:erase(0, 0, 0)
		if i == 1 and item.nodes then s:merge(item.shown and minus or plus, 0, 0) end
		s:drawColorStringBlended(self.font, text, startx, (self.fh - self.font_h) / 2, color[1], color[2], color[3], nil, col.width - startx - rs_w)

		if i == 1 and item.nodes then sus:merge(item.shown and minus or plus, 0, 0) end
		sus:merge(l, offset, 0)
		for i = startx, col.width - r_w do sus:merge(m, i, 0) end
		sus:merge(r, col.width - r_w, 0)
		sus:drawColorStringBlended(self.font, text, startx, (self.fh - self.font_h) / 2, color[1], color[2], color[3], nil, col.width - startx - rs_w)

		item.cols[i] = {}
		item.cols[i]._tex, item.cols[i]._tex_w, item.cols[i]._tex_h = s:glTexture()
		item.cols[i]._stex = ss:glTexture()
		item.cols[i]._sustex = sus:glTexture()
	end
end

function _M:generate()
	self.mouse:reset()
	self.key:reset()

	local fw, fh = self.w, ls_h
	self.fw, self.fh = fw, fh

	if not self.h then self.h = self.nb_items * fh end

	self.max_display = math.floor(self.h / fh)

	-- Draw the scrollbar
	if self.scrollbar then
		local sb, sb_w, sb_h = self:getImage("ui/scrollbar.png")
		local ssb, ssb_w, ssb_h = self:getImage("ui/scrollbar-sel.png")

		self.scrollbar = { bar = {}, sel = {} }
		self.scrollbar.sel.w, self.scrollbar.sel.h, self.scrollbar.sel.tex, self.scrollbar.sel.texw, self.scrollbar.sel.texh = ssb_w, ssb_h, ssb:glTexture()
		local s = core.display.newSurface(sb_w, self.h - fh)
		for i = 0, self.h - fh do s:merge(sb, 0, i) end
		self.scrollbar.bar.w, self.scrollbar.bar.h, self.scrollbar.bar.tex, self.scrollbar.bar.texw, self.scrollbar.bar.texh = ssb_w, self.h - fh, s:glTexture()
	end

	-- Draw the tree items
	local recurs recurs = function(list, level)
		for i, item in ipairs(list) do
			item.level = level
			self:drawItem(item)
			if item.nodes then recurs(item.nodes, level+1) end
		end
	end
	recurs(self.tree, 0)

	-- Add UI controls
	self.mouse:registerZone(0, 0, self.w, self.h, function(button, x, y, xrel, yrel, bx, by, event)
		if button == "wheelup" and event == "button" then self.scroll = util.bound(self.scroll - 1, 1, self.max - self.max_display + 1)
		elseif button == "wheeldown" and event == "button" then self.scroll = util.bound(self.scroll + 1, 1, self.max - self.max_display + 1) end

		self.sel = util.bound(self.scroll + math.floor(by / self.fh), 1, self.max)
		if self.list[self.sel] and self.list[self.sel].nodes and bx <= plus_w and button ~= "wheelup" and button ~= "wheeldown" and event == "button" then
			self:treeExpand(nil)
		else
			if (self.all_clicks or button == "left") and button ~= "wheelup" and button ~= "wheeldown" and event == "button" then self:onUse(button) end
		end
	end)
	self.key:addBinds{
		ACCEPT = function() self:onUse() end,
		MOVE_UP = function() self.sel = util.boundWrap(self.sel - 1, 1, self.max) self.scroll = util.scroll(self.sel, self.scroll, self.max_display) end,
		MOVE_DOWN = function() self.sel = util.boundWrap(self.sel + 1, 1, self.max) self.scroll = util.scroll(self.sel, self.scroll, self.max_display) end,
	}
	self.key:addCommands{
		_HOME = function()
			self.sel = 1
			self.scroll = util.scroll(self.sel, self.scroll, self.max_display)
		end,
		_END = function()
			self.sel = self.max
			self.scroll = util.scroll(self.sel, self.scroll, self.max_display)
		end,
		_PAGEUP = function()
			self.sel = util.bound(self.sel - self.max_display, 1, self.max)
			self.scroll = util.scroll(self.sel, self.scroll, self.max_display)
		end,
		_PAGEDOWN = function()
			self.sel = util.bound(self.sel + self.max_display, 1, self.max)
			self.scroll = util.scroll(self.sel, self.scroll, self.max_display)
		end,
	}

	self:outputList()
end

function _M:outputList()
	local flist = {}
	self.list = flist

	local recurs recurs = function(list)
		for i, item in ipairs(list) do
			flist[#flist+1] = item
			if item.nodes and item.shown then recurs(item.nodes) end
		end
	end
	recurs(self.tree)

	self.max = #self.list
	self.sel = util.bound(self.sel or 1, 1, self.max)
	self.scroll = self.scroll or 1
end

function _M:treeExpand(v)
	local item = self.list[self.sel]
	if not item then return end
	if v == nil then
		item.shown = not item.shown
	else
		item.shown = v
	end
	if self.on_expand then self.on_expand(item) end
	self:drawItem(item)
	self:outputList()
end

function _M:onUse(...)
	local item = self.list[self.sel]
	if not item then return end
	if item.fct then item.fct(self, item, self.sel, ...)
	else self.fct(self, item, self.sel, ...) end
end

function _M:display(x, y)
	local bx, by = x, y

	local max = math.min(self.scroll + self.max_display - 1, self.max)
	for i = self.scroll, max do
		local x = x
		for j = 1, #self.columns do
			local col = self.columns[j]
			local item = self.list[i]
			if not item then break end
			if self.sel == i then
				if self.focused then
					item.cols[j]._stex:toScreenFull(x, y, col.width, self.fh, item.cols[j]._tex_w, item.cols[j]._tex_h)
				else
					item.cols[j]._sustex:toScreenFull(x, y, col.width, self.fh, item.cols[j]._tex_w, item.cols[j]._tex_h)
				end
			else
				item.cols[j]._tex:toScreenFull(x, y, col.width, self.fh, item.cols[j]._tex_w, item.cols[j]._tex_h)
			end
			x = x + col.width
		end
		y = y + self.fh
	end

	if self.focused and self.scrollbar then
		local pos = self.sel * (self.h - self.fh) / self.max

		self.scrollbar.bar.tex:toScreenFull(bx + self.w - self.scrollbar.bar.w, by + self.fh, self.scrollbar.bar.w, self.scrollbar.bar.h, self.scrollbar.bar.texw, self.scrollbar.bar.texh)
		self.scrollbar.sel.tex:toScreenFull(bx + self.w - self.scrollbar.sel.w, by + self.fh + pos, self.scrollbar.sel.w, self.scrollbar.sel.h, self.scrollbar.sel.texw, self.scrollbar.sel.texh)
	end
end
