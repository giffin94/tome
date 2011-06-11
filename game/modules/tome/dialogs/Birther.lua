-- TE4 - T-Engine 4
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
local Birther = require "engine.Birther"
local List = require "engine.ui.List"
local TreeList = require "engine.ui.TreeList"
local Button = require "engine.ui.Button"
local Dropdown = require "engine.ui.Dropdown"
local Textbox = require "engine.ui.Textbox"
local Checkbox = require "engine.ui.Checkbox"
local Textzone = require "engine.ui.Textzone"
local ImageList = require "engine.ui.ImageList"
local TextzoneList = require "engine.ui.TextzoneList"
local Separator = require "engine.ui.Separator"
local NameGenerator = require "engine.NameGenerator"
local Module = require "engine.Module"
local Tiles = require "engine.Tiles"
local Particles = require "engine.Particles"
local CharacterVaultSave = require "engine.CharacterVaultSave"

module(..., package.seeall, class.inherit(Birther))

--- Instanciates a birther for the given actor
function _M:init(title, actor, order, at_end, quickbirth, w, h)
	self.quickbirth = quickbirth
	self.actor = actor
	self.order = order
	self.at_end = at_end
	self.tiles = Tiles.new(64, 64, nil, nil, true, nil)

	Dialog.init(self, title and title or "Character Creation", w or 600, h or 400)

	self.descriptors = {}
	self.descriptors_by_type = {}

	self.c_ok = Button.new{text="     Play!     ", fct=function() self:atEnd("created") end}
	self.c_random = Button.new{text="Random!", fct=function() self:randomBirth() end}
	self.c_premade = Button.new{text="Load premade", fct=function() self:loadPremadeUI() end}
	self.c_tile = Button.new{text="Select custom tile", fct=function() self:selectTile() end}
	self.c_cancel = Button.new{text="Cancel", fct=function() self:atEnd("quit") end}

	self.c_name = Textbox.new{title="Name: ", text=game.player_name, chars=30, max_len=50, fct=function() end, on_change=function() self:setDescriptor() end}

	self.c_female = Checkbox.new{title="Female", default=true,
		fct=function() end,
		on_change=function(s) self.c_male.checked = not s self:setDescriptor("sex", s and "Female" or "Male") end
	}
	self.c_male = Checkbox.new{title="Male", default=false,
		fct=function() end,
		on_change=function(s) self.c_female.checked = not s self:setDescriptor("sex", s and "Male" or "Female") end
	}

	self:generateCampaigns()
	self.c_campaign_text = Textzone.new{auto_width=true, auto_height=true, text="Campaign: "}
	self.c_campaign = Dropdown.new{width=300, fct=function(item) self:campaignUse(item) end, on_select=function(item) self:updateDesc(item) end, list=self.all_campaigns, nb_items=#self.all_campaigns}

	self:generateDifficulties()
	self.c_difficulty_text = Textzone.new{auto_width=true, auto_height=true, text="Difficulty: "}
	self.c_difficulty = Dropdown.new{width=300, fct=function(item) self:difficultyUse(item) end, on_select=function(item) self:updateDesc(item) end, list=self.all_difficulties, nb_items=#self.all_difficulties}

	self.c_desc = TextzoneList.new{width=math.floor(self.iw / 3 - 10), height=self.ih - self.c_female.h - self.c_ok.h - self.c_campaign.h - 10, scrollbar=true, no_color_bleed=true}

	self:setDescriptor("base", "base")
	self:setDescriptor("world", self.default_campaign)
	self:setDescriptor("difficulty", self.default_difficulty)
	self:setDescriptor("sex", "Female")

	self:generateRaces()
	self.c_race = TreeList.new{width=math.floor(self.iw / 3 - 10), height=self.ih - self.c_female.h - self.c_ok.h - self.c_campaign.h - 10, scrollbar=true, columns={
		{width=100, display_prop="name"},
	}, tree=self.all_races,
		fct=function(item, sel, v) self:raceUse(item, sel, v) end,
		select=function(item, sel) self:updateDesc(item) end,
		on_expand=function(item) end,
		on_drawitem=function(item) end,
	}

	self:generateClasses()
	self.c_class = TreeList.new{width=math.floor(self.iw / 3 - 10), height=self.ih - self.c_female.h - self.c_ok.h - self.c_campaign.h - 10, scrollbar=true, columns={
		{width=100, display_prop="name"},
	}, tree=self.all_classes,
		fct=function(item, sel, v) self:classUse(item, sel, v) end,
		select=function(item, sel) self:updateDesc(item) end,
		on_expand=function(item) end,
		on_drawitem=function(item) end,
	}

	self.cur_order = 1
	self.sel = 1

	self:loadUI{
		-- First line
		{left=0, top=0, ui=self.c_name},
		{left=self.c_name, top=0, ui=self.c_female},
		{left=self.c_female, top=0, ui=self.c_male},

		-- Second line
		{left=0, top=self.c_name, ui=self.c_campaign_text},
		{left=self.c_campaign_text, top=self.c_name, ui=self.c_campaign},
		{left=self.c_campaign, top=self.c_name, ui=self.c_difficulty_text},
		{left=self.c_difficulty_text, top=self.c_name, ui=self.c_difficulty},

		-- Lists
		{left=0, top=self.c_campaign, ui=self.c_race},
		{left=self.c_race, top=self.c_campaign, ui=self.c_class},
		{right=0, top=self.c_campaign, ui=self.c_desc},

		-- Buttons
		{left=0, bottom=0, ui=self.c_ok, hidden=true},
		{left=self.c_ok, bottom=0, ui=self.c_random},
		{left=self.c_random, bottom=0, ui=self.c_premade},
		{left=self.c_premade, bottom=0, ui=self.c_tile},
		{right=0, bottom=0, ui=self.c_cancel},
	}
	self:setupUI()

	if not profile.auth or not tonumber(profile.auth.donated) or tonumber(profile.auth.donated) <= 1 then self:toggleDisplay(self.c_tile, false) end

	if self.descriptors_by_type.difficulty == "Tutorial" then
		self:raceUse(self.all_races[1], 1)
		self:raceUse(self.all_races[1].nodes[1], 2)
		self:classUse(self.all_classes[1], 1)
		self:classUse(self.all_classes[1].nodes[1], 2)
	end
	for i, item in ipairs(self.c_campaign.c_list.list) do if self.default_campaign == item.id then self.c_campaign.c_list.sel = i break end end
	for i, item in ipairs(self.c_difficulty.c_list.list) do if self.default_difficulty == item.id then self.c_difficulty.c_list.sel = i break end end
	self:setFocus(self.c_campaign)
	self:setFocus(self.c_name)
end

function _M:checkNew(fct)
	local savename = self.c_name.text:gsub("[^a-zA-Z0-9_-.]", "_")
	if fs.exists(("/save/%s/game.teag"):format(savename)) then
		Dialog:yesnoPopup("Overwrite character?", "There is already a character with this name, do you want to overwrite it?", function(ret)
			if not ret then fct() end
		end, "No", "Yes")
	else
		fct()
	end
end

function _M:atEnd(v)
	if v == "created" and not self.ui_by_ui[self.c_ok].hidden then
		self:checkNew(function()
			local ps = self.actor:getParticlesList()
			for i, p in ipairs(ps) do self.actor:removeParticles(p) end
			self.actor:defineDisplayCallback()

			game:unregisterDialog(self)
			self:apply()
			if self.actor.has_custom_tile then self.actor.make_tile = nil end
			game:setPlayerName(self.c_name.text)
			self.at_end(false)
		end)
	elseif v == "loaded" then
		self:checkNew(function()
			game:unregisterDialog(self)
			game:setPlayerName(self.c_name.text)
			self.at_end(true)
		end)
	elseif v == "quit" then
		util.showMainMenu()
	end
end

function _M:randomBirth()
	-- Random sex
	local sex = rng.percent(50)
	self.c_male.checked = sex
	self.c_female.checked = not sex
	self:setDescriptor("sex", sex and "Male" or "Female")

	-- Random name
	local namegen = NameGenerator.new(sex and {
		phonemesVocals = "a, e, i, o, u, y",
		phonemesConsonants = "b, c, ch, ck, cz, d, dh, f, g, gh, h, j, k, kh, l, m, n, p, ph, q, r, rh, s, sh, t, th, ts, tz, v, w, x, z, zh",
		syllablesStart = "Aer, Al, Am, An, Ar, Arm, Arth, B, Bal, Bar, Be, Bel, Ber, Bok, Bor, Bran, Breg, Bren, Brod, Cam, Chal, Cham, Ch, Cuth, Dag, Daim, Dair, Del, Dr, Dur, Duv, Ear, Elen, Er, Erel, Erem, Fal, Ful, Gal, G, Get, Gil, Gor, Grin, Gun, H, Hal, Han, Har, Hath, Hett, Hur, Iss, Khel, K, Kor, Lel, Lor, M, Mal, Man, Mard, N, Ol, Radh, Rag, Relg, Rh, Run, Sam, Tarr, T, Tor, Tul, Tur, Ul, Ulf, Unr, Ur, Urth, Yar, Z, Zan, Zer",
		syllablesMiddle = "de, do, dra, du, duna, ga, go, hara, kaltho, la, latha, le, ma, nari, ra, re, rego, ro, rodda, romi, rui, sa, to, ya, zila",
		syllablesEnd = "bar, bers, blek, chak, chik, dan, dar, das, dig, dil, din, dir, dor, dur, fang, fast, gar, gas, gen, gorn, grim, gund, had, hek, hell, hir, hor, kan, kath, khad, kor, lach, lar, ldil, ldir, leg, len, lin, mas, mnir, ndil, ndur, neg, nik, ntir, rab, rach, rain, rak, ran, rand, rath, rek, rig, rim, rin, rion, sin, sta, stir, sus, tar, thad, thel, tir, von, vor, yon, zor",
		rules = "$s$v$35m$10m$e",
	} or {
		phonemesVocals = "a, e, i, o, u, y",
		syllablesStart = "Ad, Aer, Ar, Bel, Bet, Beth, Ce'N, Cyr, Eilin, El, Em, Emel, G, Gl, Glor, Is, Isl, Iv, Lay, Lis, May, Ner, Pol, Por, Sal, Sil, Vel, Vor, X, Xan, Xer, Yv, Zub",
		syllablesMiddle = "bre, da, dhe, ga, lda, le, lra, mi, ra, ri, ria, re, se, ya",
		syllablesEnd = "ba, beth, da, kira, laith, lle, ma, mina, mira, na, nn, nne, nor, ra, rin, ssra, ta, th, tha, thra, tira, tta, vea, vena, we, wen, wyn",
		rules = "$s$v$35m$10m$e",
	})
	self.c_name:setText(namegen:generate())

	-- Random campaign
	local camp, camp_id = nil
	repeat camp, camp_id = rng.table(self.c_campaign.c_list.list)
	until not camp.locked
	self.c_campaign.c_list.sel = camp_id
	self:campaignUse(camp)

	-- Random difficulty
	local diff, diff_id = nil
	repeat diff, diff_id = rng.table(self.c_difficulty.c_list.list)
	until diff.name ~= "Tutorial" and not diff.locked
	self.c_difficulty.c_list.sel = diff_id
	self:difficultyUse(diff)

	-- Random race
	local race, race_id = nil
	repeat race, race_id = rng.table(self.all_races)
	until not race.locked
	self:raceUse(race)

	-- Random subrace
	local subrace, subrace_id = nil
	repeat subrace, subrace_id = rng.table(self.all_races[race_id].nodes)
	until not subrace.locked
	self:raceUse(subrace)

	-- Random class
	local class, class_id = nil
	repeat class, class_id = rng.table(self.all_classes)
	until not class or not class.locked
	self:classUse(class)

	-- Random subclass
	if class then
		local subclass, subclass_id = nil
		repeat subclass, subclass_id = rng.table(self.all_classes[class_id].nodes)
		until not subclass.locked
		self:classUse(subclass)
	end
end

function _M:on_focus(id, ui)
	if self.focus_ui and self.focus_ui.ui == self.c_female then self.c_desc:switchItem(self.c_female, self.birth_descriptor_def.sex.Female.desc)
	elseif self.focus_ui and self.focus_ui.ui == self.c_male then self.c_desc:switchItem(self.c_male, self.birth_descriptor_def.sex.Male.desc)
	elseif self.focus_ui and self.focus_ui.ui == self.c_campaign then
		local item = self.c_campaign.c_list.list[self.c_campaign.c_list.sel]
		self.c_desc:switchItem(item, item.desc)
	elseif self.focus_ui and self.focus_ui.ui == self.c_difficulty then
		local item = self.c_difficulty.c_list.list[self.c_difficulty.c_list.sel]
		self.c_desc:switchItem(item, item.desc)
	end
end

function _M:updateDesc(item)
	if item and item.desc then
		self.c_desc:switchItem(item, item.desc)
	end
end

function _M:campaignUse(item)
	if not item then return end
	if item.locked then
		self.c_campaign.c_list.sel = self.c_campaign.previous
	else
		self:setDescriptor("world", item.id)

		self:generateDifficulties()
		self:generateRaces()
		self:generateClasses()
	end
end

function _M:difficultyUse(item)
	if not item then return end
	if item.locked then
		self.c_difficulty.c_list.sel = self.c_difficulty.previous
	else
		self:setDescriptor("difficulty", item.id)

		self:generateRaces()
		self:generateClasses()
	end
end

function _M:raceUse(item, sel, v)
	if not item then return end
	if item.nodes then
		for i, item in ipairs(self.c_race.tree) do if item.shown then self.c_race:treeExpand(false, item) end end
		self.c_race:treeExpand(nil, item)
	elseif not item.locked and item.basename then
		if self.sel_race then
			self.sel_race.name = self.sel_race.basename
			self.c_race:drawItem(self.sel_race)
		end
		self:setDescriptor("race", item.pid)
		self:setDescriptor("subrace", item.id)
		self.sel_race = item
		self.sel_race.name = tstring{{"font","bold"}, {"color","LIGHT_GREEN"}, self.sel_race.basename:toString(), {"font","normal"}}
		self.c_race:drawItem(item)

		self:generateClasses()
	end
end

function _M:classUse(item, sel, v)
	if not item then return end
	if item.nodes then
		for i, item in ipairs(self.c_class.tree) do if item.shown then self.c_class:treeExpand(false, item) end end
		self.c_class:treeExpand(nil, item)
	elseif not item.locked and item.basename then
		if self.sel_class then
			self.sel_class.name = self.sel_class.basename
			self.c_class:drawItem(self.sel_class)
		end
		self:setDescriptor("class", item.pid)
		self:setDescriptor("subclass", item.id)
		self.sel_class = item
		self.sel_class.name = tstring{{"font","bold"}, {"color","LIGHT_GREEN"}, self.sel_class.basename:toString(), {"font","normal"}}
		self.c_class:drawItem(item)
	end
end

function _M:updateDescriptors()
	self.descriptors = {}
	table.insert(self.descriptors, self.birth_descriptor_def.base[self.descriptors_by_type.base])
	table.insert(self.descriptors, self.birth_descriptor_def.world[self.descriptors_by_type.world])
	table.insert(self.descriptors, self.birth_descriptor_def.difficulty[self.descriptors_by_type.difficulty])
	table.insert(self.descriptors, self.birth_descriptor_def.sex[self.descriptors_by_type.sex])
	if self.descriptors_by_type.subrace then
		table.insert(self.descriptors, self.birth_descriptor_def.race[self.descriptors_by_type.race])
		table.insert(self.descriptors, self.birth_descriptor_def.subrace[self.descriptors_by_type.subrace])
	end
	if self.descriptors_by_type.subclass then
		table.insert(self.descriptors, self.birth_descriptor_def.class[self.descriptors_by_type.class])
		table.insert(self.descriptors, self.birth_descriptor_def.subclass[self.descriptors_by_type.subclass])
	end
end

function _M:setDescriptor(key, val)
	if key then
		self.descriptors_by_type[key] = val
		print("[BIRTHER] set descriptor", key, val)
	end
	self:updateDescriptors()
	self:setTile()

	local ok = self.c_name.text:len() >= 2
	for i, o in ipairs(self.order) do
		if not self.descriptors_by_type[o] then
			ok = false
			print("Missing ", o)
			break
		end
	end
	self:toggleDisplay(self.c_ok, ok)
end

function _M:isDescriptorAllowed(d)
	self:updateDescriptors()

	local allowed = true
	local type = d.type
	print("[BIRTHER] checking allowance for ", d.name)
	for j, od in ipairs(self.descriptors) do
		if od.descriptor_choices and od.descriptor_choices[type] then
			local what = util.getval(od.descriptor_choices[type][d.name], self) or util.getval(od.descriptor_choices[type].__ALL__, self)
			if what and what == "allow" then
				allowed = true
			elseif what and (what == "never" or what == "disallow") then
				allowed = false
			elseif what and what == "forbid" then
				allowed = nil
			end
			print("[BIRTHER] test against ", od.name, "=>", what, allowed)
			if allowed == nil then break end
		end
	end

	-- Check it is allowed
	return allowed
end

function _M:getLock(d)
	if not d.locked then return false end
	local ret = d.locked()
	if ret == "hide" then return "hide" end
	return not ret
end

function _M:generateCampaigns()
	local locktext = "\n\n#GOLD#This is a locked birth option. Performing certain actions and completing certain quests will make locked campaigns, races and classes permanently available."
	local list = {}

	for i, d in ipairs(self.birth_descriptor_def.world) do
		if self:isDescriptorAllowed(d) then
			local locked = self:getLock(d)
			if locked == true then
				list[#list+1] = { name = tstring{{"font", "italic"}, {"color", "GREY"}, "-- locked --", {"font", "normal"}}:toString(), id=d.name, locked=true, desc=d.locked_desc..locktext }
			elseif locked == false then
				local desc = d.desc
				if type(desc) == "table" then desc = table.concat(d.desc, "\n") end
				list[#list+1] = { name = tstring{d.display_name}:toString(), id=d.name, desc=desc }
			end
		end
	end

	self.all_campaigns = list
	self.default_campaign = list[1].id
end

function _M:generateDifficulties()
	local locktext = "\n\n#GOLD#This is a locked birth option. Performing certain actions and completing certain quests will make locked campaigns, races and classes permanently available."
	local list = {}

	local oldsel = nil
	if self.c_difficulty then
		oldsel = self.c_difficulty.c_list.list[self.c_difficulty.c_list.sel].id
	end

	for i, d in ipairs(self.birth_descriptor_def.difficulty) do
		if self:isDescriptorAllowed(d) then
			local locked = self:getLock(d)
			if locked == true then
				list[#list+1] = { name = tstring{{"font", "italic"}, {"color", "GREY"}, "-- locked --", {"font", "normal"}}:toString(), id=d.name, locked=true, desc=d.locked_desc..locktext }
			elseif locked == false then
				local desc = d.desc
				if type(desc) == "table" then desc = table.concat(d.desc, "\n") end
				list[#list+1] = { name = tstring{d.display_name}:toString(), id=d.name, desc=desc }
				if oldsel == d.name then oldsel = #list end
				if d.selection_default then self.default_difficulty = d.name end
			end
		end
	end

	self.all_difficulties = list
	if self.c_difficulty then
		self.c_difficulty.c_list.list = self.all_difficulties
		self.c_difficulty.c_list:generate()
		if type(oldsel) == "number" then self.c_difficulty.c_list.sel = oldsel end
	end
end

function _M:generateRaces()
	local locktext = "\n\n#GOLD#This is a locked birth option. Performing certain actions and completing certain quests will make locked campaigns, races and classes permanently available."

	local oldtree = {}
	for i, t in ipairs(self.all_races or {}) do oldtree[t.id] = t.shown end

	local tree = {}
	local newsel = nil
	for i, d in ipairs(self.birth_descriptor_def.race) do
		if self:isDescriptorAllowed(d) then
			local nodes = {}

			for si, sd in ipairs(self.birth_descriptor_def.subrace) do
				if d.descriptor_choices.subrace[sd.name] == "allow" then
					local locked = self:getLock(sd)
					if locked == true then
						nodes[#nodes+1] = { name = tstring{{"font", "italic"}, {"color", "GREY"}, "-- locked --", {"font", "normal"}}, id=sd.name, pid=d.name, locked=true, desc=sd.locked_desc..locktext }
					elseif locked == false then
						local desc = sd.desc
						if type(desc) == "table" then desc = table.concat(sd.desc, "\n") end
						nodes[#nodes+1] = { name = sd.display_name, basename = sd.display_name, id=sd.name, pid=d.name, desc=desc }
						if self.sel_race and self.sel_race.id == sd.name then newsel = nodes[#nodes] end
					end
				end
			end

			local locked = self:getLock(d)
			if locked == true then
				tree[#tree+1] = { name = tstring{{"font", "italic"}, {"color", "GREY"}, "-- locked --", {"font", "normal"}}, id=d.name, shown = oldtree[d.name], nodes = nodes, locked=true, desc=d.locked_desc..locktext }
			elseif locked == false then
				local desc = d.desc
				if type(desc) == "table" then desc = table.concat(d.desc, "\n") end
				tree[#tree+1] = { name = tstring{{"font", "italic"}, {"color", "LIGHT_SLATE"}, d.display_name, {"font", "normal"}}, id=d.name, shown = oldtree[d.name], nodes = nodes, desc=desc }
			end
		end
	end

	self.all_races = tree
	if self.c_race then
		self.c_race.tree = self.all_races
		self.c_race:generate()
		if newsel then self:raceUse(newsel)
		else
			self.sel_race = nil
			self:setDescriptor("race", nil)
			self:setDescriptor("subrace", nil)
		end
		if self.descriptors_by_type.difficulty == "Tutorial" then
			self:raceUse(tree[1], 1)
			self:raceUse(tree[1].nodes[1], 2)
		end
	end
end

function _M:generateClasses()
	local locktext = "\n\n#GOLD#This is a locked birth option. Performing certain actions and completing certain quests will make locked campaigns, races and classes permanently available."

	local oldtree = {}
	for i, t in ipairs(self.all_classes or {}) do oldtree[t.id] = t.shown end

	local tree = {}
	local newsel = nil
	for i, d in ipairs(self.birth_descriptor_def.class) do
		if self:isDescriptorAllowed(d) then
			local nodes = {}

			for si, sd in ipairs(self.birth_descriptor_def.subclass) do
				if d.descriptor_choices.subclass[sd.name] == "allow" then
					local locked = self:getLock(sd)
					if locked == true then
						nodes[#nodes+1] = { name = tstring{{"font", "italic"}, {"color", "GREY"}, "-- locked --", {"font", "normal"}}, id=sd.name, pid=d.name, locked=true, desc=sd.locked_desc..locktext }
					elseif locked == false then
						local desc = sd.desc
						if type(desc) == "table" then desc = table.concat(sd.desc, "\n") end
						nodes[#nodes+1] = { name = sd.display_name, basename=sd.display_name, id=sd.name, pid=d.name, desc=desc }
						if self.sel_class and self.sel_class.id == sd.name then newsel = nodes[#nodes] end
					end
				end
			end

			local locked = self:getLock(d)
			if locked == true then
				tree[#tree+1] = { name = tstring{{"font", "italic"}, {"color", "GREY"}, "-- locked --", {"font", "normal"}}, id=d.name, shown=oldtree[d.name], nodes = nodes, locked=true, desc=d.locked_desc..locktext }
			elseif locked == false then
				local desc = d.desc
				if type(desc) == "table" then desc = table.concat(d.desc, "\n") end
				tree[#tree+1] = { name = tstring{{"font", "italic"}, {"color", "LIGHT_SLATE"}, d.display_name, {"font", "normal"}}, id=d.name, shown=oldtree[d.name], nodes = nodes, desc=desc }
			end
		end
	end

	self.all_classes = tree
	if self.c_class then
		self.c_class.tree = self.all_classes
		self.c_class:generate()
		if newsel then self:classUse(newsel)
		else
			self.sel_class = nil
			self:setDescriptor("class", nil)
			self:setDescriptor("subclass", nil)
		end
		if self.descriptors_by_type.difficulty == "Tutorial" then
			self:classUse(tree[1], 1)
			self:classUse(tree[1].nodes[1], 2)
		end
	end
end

function _M:loadPremade(pm)
	local fallback = pm.force_fallback

	-- Load the entities directly
	if not fallback and pm.module_version and pm.module_version[1] == game.__mod_info.version[1] and pm.module_version[2] == game.__mod_info.version[2] and pm.module_version[3] == game.__mod_info.version[3] then
		savefile_pipe:ignoreSaveToken(true)
		local qb = savefile_pipe:doLoad(pm.short_name, "entity", "engine.CharacterVaultSave", "character")
		savefile_pipe:ignoreSaveToken(false)

		-- Load the player directly
		if qb then
			game.party = qb
			game.player = nil
			game.party:setPlayer(1, true)
			self.c_name:setText(game.player.name)
			self:atEnd("loaded")
		else
			fallback = true
		end
	else
		fallback = true
	end

	-- Fill in the descriptors and validate
	if fallback then
		local ok = 0

		-- Name
		self.c_name:setText(pm.short_name)

		-- Sex
		self.c_male.checked = pm.descriptors.sex == "Male"
		self.c_female.checked = pm.descriptors.sex == "Female"
		self:setDescriptor("sex", pm.descriptors.sex and "Male" or "Female")

		-- Campaign
		for i, item in ipairs(self.all_campaigns) do if not item.locked and item.id == pm.descriptors.world then
			self:campaignUse(item)
			self.c_campaign.c_list.sel = i
			ok = ok + 1
			break
		end end

		-- Difficulty
		for i, item in ipairs(self.all_difficulties) do if not item.locked and item.id == pm.descriptors.difficulty then
			self:difficultyUse(item)
			self.c_difficulty.c_list.sel = i
			ok = ok + 1
			break
		end end

		-- Race
		for i, pitem in ipairs(self.all_races) do
			for j, item in ipairs(pitem.nodes) do
				if not item.locked and item.id == pm.descriptors.subrace and pitem.id == pm.descriptors.race then
					self:raceUse(pitem)
					self:raceUse(item)
					ok = ok + 1
					break
				end
			end
		end

		-- Class
		for i, pitem in ipairs(self.all_classes) do
			for j, item in ipairs(pitem.nodes) do
				if not item.locked and item.id == pm.descriptors.subclass and pitem.id == pm.descriptors.class then
					self:classUse(pitem)
					self:classUse(item)
					ok = ok + 1
					break
				end
			end
		end

		if ok == 4 then self:atEnd("created") end
	end
end

function _M:loadPremadeUI()
	local lss = Module:listVaultSavesForCurrent()
	local d = Dialog.new("Characters Vault", 600, 550)

	local sel = nil
	local desc = TextzoneList.new{width=220, height=400}
	local list list = List.new{width=350, list=lss, height=400,
		fct=function(item)
			local oldsel, oldscroll = list.sel, list.scroll
			if sel == item then self:loadPremade(sel) game:unregisterDialog(d) end
			if sel then sel.color = nil end
			item.color = colors.simple(colors.LIGHT_GREEN)
			sel = item
			list:generate()
			list.sel, list.scroll = oldsel, oldscroll
		end,
		select=function(item) desc:switchItem(item, item.description) end
	}
	local sep = Separator.new{dir="horizontal", size=400}

	local load = Button.new{text=" Load ", fct=function() if sel then self:loadPremade(sel) game:unregisterDialog(d) end end}
	local del = Button.new{text="Delete", fct=function() if sel then
		local vault = CharacterVaultSave.new(sel.short_name)
		vault:delete()
		vault:close()
		lss = Module:listVaultSavesForCurrent()
		list.list = lss
		list:generate()
		sel = nil
	end end}

	d:loadUI{
		{left=0, top=0, ui=list},
		{left=list.w, top=0, ui=sep},
		{right=0, top=0, ui=desc},

		{left=0, bottom=0, ui=load},
		{right=0, bottom=0, ui=del},
	}
	d:setupUI(true, true)
	d.key:addBind("EXIT", function() game:unregisterDialog(d) end)
	game:registerDialog(d)
end

-- Disable stuff from the base Birther
function _M:updateList() end
function _M:selectType(type) end

function _M:on_register()
	if __module_extra_info.auto_quickbirth then
		local lss = Module:listVaultSavesForCurrent()
		for i, pm in ipairs(lss) do
			if pm.short_name == __module_extra_info.auto_quickbirth then
				self:loadPremade(pm)
				break
			end
		end
	end
end

-- Display the player tile
function _M:innerDisplay(x, y, nb_keyframes)
	if self.actor.image then
		self.actor:toScreen(self.tiles, x + self.iw - 64, y, 64, 64)
	elseif self.actor.image and self.actor.add_mos then
		self.actor:toScreen(self.tiles, x + self.iw - 64, y - 64, 128, 64)
	end
end

function _M:setTile(f, w, h)
	if not f then
		if not self.actor.has_custom_tile and self.descriptors_by_type.subrace and self.descriptors_by_type.sex then
			self.actor.image = "player/"..self.descriptors_by_type.subrace:lower().."_"..self.descriptors_by_type.sex:lower()..".png"
			self.actor.add_mos = nil
		end
	else
		self.actor.make_tile = nil
		if h > w then
			self.actor.image = "invis.png"
			self.actor.add_mos = {{image=f, display_h=2, display_y=-1}}
		else
			self.actor.add_mos = nil
			self.actor.image = f
		end
		self.actor.has_custom_tile = f
	end
	if self.actor._mo then self.actor._mo:invalidate() end
	self.actor._mo = nil

	-- Add an example particles if any
	local ps = self.actor:getParticlesList()
	for i, p in ipairs(ps) do self.actor:removeParticles(p) end
	if self.descriptors_by_type.subclass then
		local d = self.birth_descriptor_def.subclass[self.descriptors_by_type.subclass]
		if d and d.birth_example_particles then
			self.actor:addParticles(Particles.new(d.birth_example_particles, 1))
		end
	end
end

function _M:selectTileNoDonations()
	Dialog:simpleLongPopup("Custom tiles",
	[[Custom Tiles have been added as a thank you to everyone that's donated to ToME.
If you'd like to use this (purely cosmetic) feature you should consider donating.
While this is a free game that I am doing for fun, if it can help feeding my family a bit I certainly will not complain.

]], 400)
end

function _M:selectTile()
	if not profile.auth or not tonumber(profile.auth.donated) or tonumber(profile.auth.donated) <= 1 then return self:selectTileNoDonations() end

	local d = Dialog.new("Select a Tile", 600, 550)

	local list = {
		"npc/alchemist_golem.png",
		"npc/armored_skeleton_warrior.png",
		"npc/barrow_wight.png",
		"npc/construct_golem_alchemist_golem.png",
		"npc/degenerated_skeleton_warrior.png",
		"npc/elder_vampire.png",
		"npc/emperor_wight.png",
		"npc/forest_wight.png",
		"npc/golem.png",
		"npc/grave_wight.png",
		"npc/horror_corrupted_dremling.png",
		"npc/horror_corrupted_drem_master.png",
		"npc/horror_eldritch_headless_horror.png",
		"npc/horror_eldritch_luminous_horror.png",
		"npc/horror_eldritch_worm_that_walks.png",
		"npc/horror_temporal_cronolith_clone.png",
		"npc/humanoid_dwarf_dwarven_earthwarden.png",
		"npc/humanoid_dwarf_dwarven_guard.png",
		"npc/humanoid_dwarf_dwarven_paddlestriker.png",
		"npc/humanoid_dwarf_dwarven_summoner.png",
		"npc/humanoid_dwarf_lumberjack.png",
		"npc/humanoid_dwarf_norgan.png",
		"npc/humanoid_dwarf_ziguranth_warrior.png",
		"npc/humanoid_elenulach_thief.png",
		"npc/humanoid_elf_anorithil.png",
		"npc/humanoid_elf_elven_archer.png",
		"npc/humanoid_elf_elven_sun_mage.png",
		"npc/humanoid_elf_fillarel_aldaren.png",
		"npc/humanoid_elf_limmir_the_jeweler.png",
		"npc/humanoid_elf_star_crusader.png",
		"npc/humanoid_halfling_derth_guard.png",
		"npc/humanoid_halfling_halfling_citizen.png",
		"npc/humanoid_halfling_halfling_gardener.png",
		"npc/humanoid_halfling_halfling_guard.png",
		"npc/humanoid_halfling_halfling_slinger.png",
		"npc/humanoid_halfling_master_slinger.png",
		"npc/humanoid_halfling_protector_myssil.png",
		"npc/humanoid_halfling_sm_halfling.png",
		"npc/humanoid_human_alchemist.png",
		"npc/humanoid_human_aluin_the_fallen.png",
		"npc/humanoid_human_apprentice_mage.png",
		"npc/humanoid_human_arcane_blade.png",
		"npc/humanoid_human_argoniel.png",
		"npc/humanoid_human_assassin.png",
		"npc/humanoid_human_bandit_lord.png",
		"npc/humanoid_human_bandit.png",
		"npc/humanoid_human_ben_cruthdar__the_cursed.png",
		"npc/humanoid_human_blood_mage.png",
		"npc/humanoid_human_cryomancer.png",
		"npc/humanoid_human_cutpurse.png",
		"npc/humanoid_human_derth_guard.png",
		"npc/humanoid_human_enthralled_slave.png",
		"npc/humanoid_human_fallen_sun_paladin_aeryn.png",
		"npc/humanoid_human_fire_wyrmic.png",
		"npc/humanoid_human_fryjia_loren.png",
		"npc/humanoid_human_geomancer.png",
		"npc/humanoid_human_gladiator.png",
		"npc/humanoid_human_great_gladiator.png",
		"npc/humanoid_human_harno__herald_of_last_hope.png",
		"npc/humanoid_human_hexer.png",
		"npc/humanoid_human_high_gladiator.png",
		"npc/humanoid_human_high_slinger.png",
		"npc/humanoid_human_high_sun_paladin_aeryn.png",
		"npc/humanoid_human_high_sun_paladin_rodmour.png",
		"npc/humanoid_human_human_citizen.png",
		"npc/humanoid_human_human_farmer.png",
		"npc/humanoid_human_human_guard.png",
		"npc/humanoid_human_human_sun_paladin.png",
		"npc/humanoid_human_ice_wyrmic.png",
		"npc/humanoid_human_last_hope_guard.png",
		"npc/humanoid_human_linaniil_supreme_archmage.png",
		"npc/humanoid_human_lumberjack.png",
		"npc/humanoid_human_martyr.png",
		"npc/humanoid_human_master_alchemist.png",
		"npc/humanoid_human_multihued_wyrmic.png",
		"npc/humanoid_human_necromancer.png",
		"npc/humanoid_human_pyromancer.png",
		"npc/humanoid_human_reaver.png",
		"npc/humanoid_human_rej_arkatis.png",
		"npc/humanoid_human_riala_shalarak.png",
		"npc/humanoid_human_rogue.png",
		"npc/humanoid_human_sand_wyrmic.png",
		"npc/humanoid_human_shadowblade.png",
		"npc/humanoid_human_shady_cornac_man.png",
		"npc/humanoid_human_slave_combatant.png",
		"npc/humanoid_human_slinger.png",
		"npc/humanoid_human_spectator02.png",
		"npc/humanoid_human_spectator03.png",
		"npc/humanoid_human_spectator.png",
		"npc/humanoid_human_storm_wyrmic.png",
		"npc/humanoid_human_subject_z.png",
		"npc/humanoid_human_sun_paladin_guren.png",
		"npc/humanoid_human_tannen.png",
		"npc/humanoid_human_tempest.png",
		"npc/humanoid_human_thief.png",
		"npc/humanoid_human_trickster.png",
		"npc/humanoid_human_urkis__the_high_tempest.png",
		"npc/humanoid_human_valfred_loren.png",
		"npc/humanoid_human_ziguranth_wyrmic.png",
		"npc/humanoid_orc_brotoq_the_reaver.png",
		"npc/humanoid_orc_fiery_orc_wyrmic.png",
		"npc/humanoid_orc_golbug_the_destroyer.png",
		"npc/humanoid_orc_gorbat__supreme_wyrmic_of_the_pride.png",
		"npc/humanoid_orc_grushnak__battlemaster_of_the_pride.png",
		"npc/humanoid_orc_icy_orc_wyrmic.png",
		"npc/humanoid_orc_krogar.png",
		"npc/humanoid_orc_massok_the_dragonslayer.png",
		"npc/humanoid_orc_orc_archer.png",
		"npc/humanoid_orc_orc_assassin.png",
		"npc/humanoid_orc_orc_berserker.png",
		"npc/humanoid_orc_orc_blood_mage.png",
		"npc/humanoid_orc_orc_corruptor.png",
		"npc/humanoid_orc_orc_cryomancer.png",
		"npc/humanoid_orc_orc_elite_berserker.png",
		"npc/humanoid_orc_orc_elite_fighter.png",
		"npc/humanoid_orc_orc_fighter.png",
		"npc/humanoid_orc_orc_grand_master_assassin.png",
		"npc/humanoid_orc_orc_grand_summoner.png",
		"npc/humanoid_orc_orc_high_cryomancer.png",
		"npc/humanoid_orc_orc_high_pyromancer.png",
		"npc/humanoid_orc_orc_mage_hunter.png",
		"npc/humanoid_orc_orc_master_assassin.png",
		"npc/humanoid_orc_orc_master_wyrmic.png",
		"npc/humanoid_orc_orc_necromancer.png",
		"npc/humanoid_orc_orc_pyromancer.png",
		"npc/humanoid_orc_orc_soldier.png",
		"npc/humanoid_orc_orc_summoner.png",
		"npc/humanoid_orc_orc_warrior.png",
		"npc/humanoid_orc_rak_shor_cultist.png",
		"npc/humanoid_orc_rak_shor__grand_necromancer_of_the_pride.png",
		"npc/humanoid_orc_ukruk_the_fierce.png",
		"npc/humanoid_orc_vor__grand_geomancer_of_the_pride.png",
		"npc/humanoid_orc_warmaster_gnarg.png",
		"npc/humanoid_shalore_archmage_tarelion.png",
		"npc/humanoid_shalore_elandar.png",
		"npc/humanoid_shalore_elvala_guard.png",
		"npc/humanoid_shalore_elven_blood_mage.png",
		"npc/humanoid_shalore_elven_corruptor.png",
		"npc/humanoid_shalore_elven_cultist.png",
		"npc/humanoid_shalore_elven_elite_warrior.png",
		"npc/humanoid_shalore_elven_guard.png",
		"npc/humanoid_shalore_elven_mage.png",
		"npc/humanoid_shalore_elven_tempest.png",
		"npc/humanoid_shalore_elven_warrior.png",
		"npc/humanoid_shalore_grand_corruptor.png",
		"npc/humanoid_shalore_mean_looking_elven_guard.png",
		"npc/humanoid_shalore_rhaloren_inquisitor.png",
		"npc/humanoid_shalore_shalore_rune_master.png",
		"npc/humanoid_thalore_thalore_hunter.png",
		"npc/humanoid_thalore_thalore_wilder.png",
		"npc/humanoid_thalore_ziguranth_summoner.png",
		"npc/humanoid_yaech_blood_master.png",
		"npc/humanoid_yaech_murgol__the_yaech_lord.png",
		"npc/humanoid_yaech_slaver.png",
		"npc/humanoid_yaech_yaech_diver.png",
		"npc/humanoid_yaech_yaech_hunter.png",
		"npc/humanoid_yaech_yaech_mindslayer.png",
		"npc/humanoid_yaech_yaech_psion.png",
		"npc/humanoid_yeek_yeek_wayist.png",
		"npc/jawa_01.png",
		"npc/lesser_vampire.png",
		"npc/master_skeleton_archer.png",
		"npc/master_skeleton_warrior.png",
		"npc/master_vampire.png",
		"npc/skeleton_archer.png",
		"npc/skeleton_mage.png",
		"npc/skeleton_warrior.png",
		"npc/undead_skeleton_cowboy.png",
		"npc/the_master.png",
		"npc/vampire_lord.png",
		"npc/vampire.png",
		"npc/snaproot_pimp.png",
		"player/ascii_player_dorfhelmet_01_64.png",
		"player/ascii_player_fedora_feather_04_64.png",
		"player/ascii_player_helmet_02_64.png",
		"player/ascii_player_mario_01_64.png",
		"player/ascii_player_rogue_cloak_01_64.png",
		"player/ascii_player_wizardhat_01_64.png",
	}
	local remove = Button.new{text="Use default tile", width=500, fct=function()
		game:unregisterDialog(d)
		self.actor.has_custom_tile = nil
		self:setTile()
	end}
	local list = ImageList.new{width=500, height=500, tile_w=64, tile_h=64, padding=10, list=list, fct=function(item)
		game:unregisterDialog(d)
		self:setTile(item.f, item.w, item.h)
	end}
	d:loadUI{
		{left=0, top=0, ui=list},
		{left=0, bottom=0, ui=remove},
	}
	d:setupUI(true, true)
	d.key:addBind("EXIT", function() game:unregisterDialog(d) end)
	game:registerDialog(d)
end