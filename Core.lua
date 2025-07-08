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
		BackgroundColor = "FF202020",
		BorderColor = "FF000000",
		BarColor = "QUALITY",
		TextColor = "FFFFFFFF",
		BarTexture = "Blizzard Raid Bar",
		BackgroundTexture = "Solid",
		BorderTexture = "White8X8",
		TextFont = "Friz Quadrata TT",
		TextSize = 12,
		BorderSize = 1,
		FrameHeight = 24,
		FrameWidth = 400,
		FrameAnchor = {"CENTER", nil, "CENTER", 0, 225},
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