local addonName, Private = ...

-- Some IDE Stuff
---@class Addon:AceAddon
-- Ace Functions
---@field Print fun(self:Addon, msg:string)
---@field RegisterChatCommand fun(self:Addon, command:string, func:function|string|?, persist:boolean|?)
---@field RegisterEvent fun(self:Addon, event:string, func:function|string|?, persist:boolean|?)
local LRS = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
Private.Addon = LRS
Private.LSM = LibStub("LibSharedMedia-3.0")

function LRS:FPrint(message, ...)
	self:Print(... and string.format(message, ...) or message or "")
end

function LRS:OnInitialize()
    LRSkinDB = LRSkinDB or {
		BackgroundColor = "FF212121",
		BorderColor = "FF333333",
		BarColor = "FFFF800F",
		TextColor = "FFFFFFFF",
		BarTexture = "Solid",
		BackgroundTexture = "Solid",
		BorderTexture = "1 Pixel",
		TextFont = "2002",
		TextSize = 11,
		BorderSize = 1,
		FrameHeight = 20,
		FrameWidth = 200,
		FrameAnchor = {"CENTER", nil, "CENTER", 0, 0},
		FrameGrow = "DOWN",
		FrameSpacing = 1,
	}
	self.db = LRSkinDB

	self:RegisterChatCommand("lrs", "SlashCommand")
	self:RegisterChatCommand("lrskin", "SlashCommand")
	self:RegisterChatCommand("lrollskin", "SlashCommand")
	self:RegisterChatCommand("lootrollskin", "SlashCommand")

	self:RegisterEvent("START_LOOT_ROLL", "ShowRolls")
	hooksecurefunc("RollOnLoot", function(rollID)
		self:SentRoll(rollID)
	   end)
	self.CreateSettings()
end