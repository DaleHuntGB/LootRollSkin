local addonName, Private = ...
local LRS = Private.Addon

local framePool = {}
LRS.anchoring = false

LRS.IDtoFrame = {}

local startMoving = function(self)
	self:StartMoving()
end
local stopMoving = function(self)
	self:StopMovingOrSizing()
	LRS.db.FrameAnchor = { self:GetPoint() }
end

local voteButtons = {
	"need",
	"greed",
	"disenchant",
	"transmog",
	[0] = "pass",
}

local function createVoteButton(parent, roll)
	local frame = CreateFrame("Button", nil, parent)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetSize(24, 24)
	local buttonName = string.format("lootroll-toast-icon-%s", voteButtons[roll])

	frame:SetNormalAtlas(string.format("%s-up", buttonName))
	frame:SetPushedAtlas(string.format("%s-down", buttonName))
	frame:SetHighlightAtlas(string.format("%s-highlight", buttonName))
	frame:SetDisabledAtlas(string.format("%s-highlight", buttonName))
	frame:SetScript("OnClick", function()
		local rollID = frame:GetParent().bar.rollID
		RollOnLoot(rollID, roll)
	end)
	return frame
end

local function createNewFrame()
	local container = CreateFrame("Frame", nil, UIParent)
	container:SetFrameStrata("DIALOG")
	container:SetPoint("CENTER", 0, #framePool * LRS.db.FrameHeight)
	container.bar = CreateFrame("StatusBar", nil, container, "BackdropTemplate")
	container.bar:SetMinMaxValues(0, 300)
	container.bar:SetValue(1)
	container.bar:SetScript("OnUpdate", function(self)
		if not self.rollID and not LRS.anchoring then
			self:GetParent():Hide()
			container.used = false
			return
		end
		local timeLeft = LRS.anchoring and 150000 or GetLootRollTimeLeft(self.rollID)
		self:SetValue(timeLeft) -- 300s duration
		if self:GetValue() <= 0 then
			self:GetParent():Hide()
			container.used = false
		end
	end)
	container.bar:SetAllPoints()
	container.icon = container.bar:CreateTexture(nil, "OVERLAY")
	container.icon:SetPoint("RIGHT", container.bar, "LEFT")
	container.iconBg = CreateFrame("Frame", nil, container, "BackdropTemplate")
	container.iconiLvlText = container:CreateFontString(nil, "OVERLAY")
	container.iconiLvlText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	container.iconiLvlText:SetPoint("CENTER", container.icon, "CENTER", 0, 0)
	container.iconiLvlText:SetTextColor(1, 1, 1, 1)
	container.iconiLvlText:SetText("")
	container.iconiLvlText:SetJustifyH("CENTER")
	container.itemName = container.bar:CreateFontString()
	container.itemName:SetPoint("LEFT", 3, 0)
	container.spark = container.bar:CreateTexture(nil, "ARTWORK", nil, 1)
	container.spark:SetBlendMode("BLEND")
	container.spark:SetPoint("RIGHT", container.bar:GetStatusBarTexture())
	container.border = CreateFrame("Frame", nil, container.bar, "BackdropTemplate")
	container.border:SetAllPoints()

	container.pass = createVoteButton(container, 0)
	container.pass:SetPoint("RIGHT", -3, 0)
	container.transmog = createVoteButton(container, 4)
	container.transmog:SetPoint("RIGHT", container.pass, "LEFT", -3, 0)
	container.disenchant = createVoteButton(container, 3)
	container.disenchant:SetPoint("RIGHT", container.transmog, "LEFT", -3, 0)
	container.greed = createVoteButton(container, 2)
	container.greed:SetPoint("RIGHT", container.disenchant, "LEFT", -3, 0)
	container.need = createVoteButton(container, 1)
	container.need:SetPoint("RIGHT", container.greed, "LEFT", -3, 0)

	tinsert(framePool, container)
	return container
end

local function updateFrame(frame, rollID)
	-- Icon, Name, Count(0-x), Quality(1-5), BoP(true,false), Need(true,false), Greed(true,false), Disenchant(true,false), resonNeed(0-5), reasonGreed(0-5), reasonDisenchant(0-5), deSkillReq(0-x), Transmog(0,1)
	local rollItemInfo = (LRS.anchoring and rollID == 0) and { 5205711, "Fyr'alath the Dreamrender", 1, 5, true, true, true, true, 0, 0, 0, 0, 1} or { GetLootRollItemInfo(rollID) }
	if not rollItemInfo[1] then return end
	local quality = ITEM_QUALITY_COLORS[rollItemInfo[4]].color
	local backgroundColor = LRS.db.BackgroundColor == "QUALITY" and quality or CreateColorFromHexString(LRS.db.BackgroundColor)
	local borderColor = LRS.db.BorderColor == "QUALITY" and quality or CreateColorFromHexString(LRS.db.BorderColor)
	local barColor = LRS.db.BarColor == "QUALITY" and quality or CreateColorFromHexString(LRS.db.BarColor)
	local textColor = LRS.db.TextColor == "QUALITY" and quality or CreateColorFromHexString(LRS.db.TextColor)
	local textSize = LRS.db.TextSize
	local textFont = Private.LSM:Fetch("font", LRS.db.TextFont)
	local barTexture = Private.LSM:Fetch("statusbar", LRS.db.BarTexture)
	local backgroundTexture = Private.LSM:Fetch("background", LRS.db.BackgroundTexture)
	local borderTexture = Private.LSM:Fetch("border", LRS.db.BorderTexture)
	local height, width = LRS.db.FrameHeight, LRS.db.FrameWidth
	local borderSize = LRS.db.BorderSize

	frame:ClearAllPoints()
	frame:SetPoint(unpack(LRS.db.FrameAnchor))
	frame.bar:SetBackdrop({ bgFile = backgroundTexture, })
	frame.border:SetBackdrop({ edgeFile = borderTexture, edgeSize = borderSize, })
	frame.iconBg:SetBackdrop({ edgeFile = borderTexture, edgeSize = borderSize, })
	frame.iconBg:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -borderSize, borderSize)
	frame.iconBg:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", borderSize, -borderSize)
	frame.icon:SetWidth(height - (borderSize * 2))
	frame.icon:SetHeight(height - (borderSize * 2))
	frame.icon:SetPoint("RIGHT", frame.bar, "LEFT", 0, 0)
	frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	frame:SetSize(width, height)
	frame.spark:SetWidth(borderSize)
	frame.spark:SetHeight(height)

	frame.bar:SetBackdropColor(backgroundColor:GetRGBA()) -- Background
	frame.border:SetBackdropBorderColor(borderColor:GetRGBA()) -- Border
	frame.bar:SetStatusBarTexture(barTexture) -- Statusbar Texture
	frame.bar:SetStatusBarColor(barColor:GetRGBA()) -- Statusbar Color
	frame.itemName:SetFont(textFont, tonumber(textSize), "OUTLINE") -- Text
	frame.itemName:SetTextColor(textColor:GetRGBA()) -- Text
	frame.itemName:SetText(rollItemInfo[2]) -- Text
	frame.iconBg:SetBackdropBorderColor(borderColor:GetRGBA()) -- Border
	frame.icon:SetTexture(rollItemInfo[1]) -- Set To Item Icon ID

	frame.bar.rollID = rollID
	frame.bar.itemInfo = rollItemInfo

	local function ItemTip(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
		GameTooltip:SetLootRollItem(self:GetParent().bar.rollID)
	end

	frame.icon:SetScript("OnEnter", ItemTip)
	frame.icon:SetScript("OnLeave", function() GameTooltip:Hide() end)

	local itemName, _, _, itemLevel = C_Item.GetItemInfo(rollItemInfo[1])
	frame.iconiLvlText:SetText(itemLevel or "")

	frame.need:SetEnabled(rollItemInfo[6])
	frame.greed:SetEnabled(rollItemInfo[7])
	frame.disenchant:SetEnabled(rollItemInfo[8])
	frame.transmog:SetEnabled(rollItemInfo[13])

	frame:SetMovable((LRS.anchoring and rollID == 0) or false)
	frame:SetScript("OnMouseDown", (LRS.anchoring and rollID == 0) and startMoving or nil)
	frame:SetScript("OnMouseUp", (LRS.anchoring and rollID == 0) and stopMoving or nil)
	frame:EnableMouse((LRS.anchoring and rollID == 0) or false)
	frame.bar:SetMinMaxValues(0, (C_Loot.GetLootRollDuration(rollID) or 240000))
	frame.used = true

	LRS:HideOtherLootFrames()
	LRS.IDtoFrame[rollID] = frame
end

local function instaHide(self)
	self:Hide()
end

function LRS:HideOtherLootFrames()
	GroupLootContainer:HookScript("OnShow", function(self) self:Hide() end)
	UIParentBottomManagedFrameContainer:HookScript("OnShow", function(self) self:Hide() end)
	UIParentBottomManagedFrameContainer:Hide()
	GroupLootContainer:EnableMouse(false)
	UIParentBottomManagedFrameContainer:EnableMouse(false)
	for i = 1, 100 do
		local elvLR = _G["ElvUI_LootRollFrame" .. i]
		local blizzLR = _G["GroupLootFrame" .. i]
		if not elvLR and not blizzLR then return end
		if elvLR then elvLR:Hide() end
		if elvLR and not elvLR.rasuHooked then
			elvLR:HookScript("OnShow", instaHide)
			elvLR.rasuHooked = true
		end
		if blizzLR then blizzLR:Hide() end
		if blizzLR and not blizzLR.rasuHooked then
			blizzLR:HookScript("OnShow", instaHide)
			blizzLR.rasuHooked = true
		end
	end
end

function LRS:GetRollFrame(rollId)
	local rollFrame
	-- for _, frame in pairs(framePool) do
	-- 	if not frame.used then
	-- 		rollFrame = frame
	-- 		break
	-- 	end
	-- end

	for _, frame in ipairs(framePool) do
		if not frame:IsShown() and not frame.used then
			rollFrame = frame
			break
		end
	end

	if not rollFrame then
		rollFrame = createNewFrame()
	end
	rollFrame:Show()
	updateFrame(rollFrame, rollId)
	self:SetFramePoints()
	return rollFrame
end

function LRS:ToggleAnchor(force)
	self.anchoring = force or not self.anchoring
	self:GetRollFrame(0)
end

function LRS:SetFramePoints()
	local p, _, rP, oX, oY = unpack(self.db.FrameAnchor)
	local frameHeight = self.db.FrameHeight
	local frameWidth = self.db.FrameWidth
	local frameGrow = self.db.FrameGrow
	local frameSpacing = self.db.FrameSpacing
	for index, frame in pairs(framePool) do
		frame:ClearAllPoints()
		if frameGrow == "DOWN" then
			frame:SetPoint(p, UIParent, rP, oX, oY + (((index - 1) * (frameHeight + frameSpacing)) * -1))
		elseif frameGrow == "UP" then
			frame:SetPoint(p, UIParent, rP, oX, oY + ((index - 1) * (frameHeight + frameSpacing)))
		elseif frameGrow == "LEFT" then
			frame:SetPoint(p, UIParent, rP, oX + (((index - 1) * (frameWidth + frameHeight + frameSpacing)) * -1), oY)
		elseif frameGrow == "RIGHT" then
			frame:SetPoint(p, UIParent, rP, oX + ((index - 1) * (frameWidth + frameHeight + frameSpacing)), oY)
		end
	end
end

function LRS:ChangeSetting(settingName, settingValue)
	self.db[settingName] = settingValue
	for _, frame in pairs(framePool) do
		if frame.used then
			updateFrame(frame, frame.bar.rollID)
		end
	end
end

-- Settings frame from here
function LRS.CreateSettings()
	local function createSetting(offsetX, offsetY, anchor, sType, sName, ddValues, ddSelection)
		local frame = CreateFrame("Frame", nil, anchor)
		frame:SetPoint("TOPLEFT", offsetX + 25, (offsetY * -1) - 30)
		frame:SetSize(150, 20)
		frame.Text = frame:CreateFontString()
		frame.Text:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		frame.Text:SetPoint("LEFT")
		frame.Text:SetText(sName:gsub("%u", " %1"))
		frame.Text:SetTextColor(1, 1, 1, 1)
		if sType == "COLOR" then
			frame.cb = CreateFrame("CheckButton", nil, frame, "SettingsCheckBoxTemplate")
			frame.cb:SetChecked(LRS.db[sName] == "QUALITY")
			frame.cb:SetPoint("RIGHT")
			frame.cb:SetSize(20, 20)
			frame.cb:SetScript("OnClick", function(self)
				frame.btn:SetEnabled(not self:GetChecked())
				LRS:ChangeSetting(sName, self:GetChecked() and "QUALITY" or "FFFFFFFF")
			end)
			frame.btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
			frame.btn:SetEnabled(not frame.cb:GetChecked())
			frame.btn:SetText("Pick Color")
			frame.btn:SetPoint("LEFT", frame.cb, "RIGHT", 10, 0)
			frame.btn:SetSize(100, 20)

			frame.btn:SetScript("OnClick", function()
				local hex, r, g, b, a = LRS.db[sName], 1, 1, 1, 1
				if hex ~= "QUALITY" then
					r, g, b, a = CreateColorFromHexString(hex):GetRGBA()
				end
				local info = {}
				info.swatchFunc = function() end
				info.opacityFunc = function() end
				info.hasOpacity = true
				info.opacity = a
				info.r = r
				info.g = g
				info.b = b
				ColorPickerFrame:SetupColorPickerAndShow(info)
				ColorPickerFrame.db = sName
				ColorPickerFrame.Footer.OkayButton:HookScript("OnClick", function()
					if LRS.db[ColorPickerFrame.db] then
						local nr, ng, nb = ColorPickerFrame:GetColorRGB()
						local na = ColorPickerFrame:GetColorAlpha()
						local colorHex = CreateColor(nr, ng, nb, na):GenerateHexColor()
						LRS:ChangeSetting(ColorPickerFrame.db, colorHex)
					end
				end)
			end)
		elseif sType == "NUMBER" then
			frame.eb = CreateFrame("EditBox", nil, frame, "NumericInputBoxTemplate")
			frame.eb:SetText(LRS.db[sName])
			frame.eb:SetAutoFocus(false)
			frame.eb:SetMaxLetters(3)
			frame.eb:SetSize(30, 20)
			frame.eb:SetPoint("LEFT", frame, "RIGHT", -15, 0)
			frame.eb:SetScript("OnTextChanged", function()
				LRS:ChangeSetting(sName, tonumber(frame.eb:GetText()) or 1)
			end)
		elseif sType == "DROPDOWN" then
			frame.dd = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate")
			frame.dd:SetPoint("LEFT", frame, "RIGHT", 17, 0)
			UIDropDownMenu_SetWidth(frame.dd, 150)
			UIDropDownMenu_SetText(frame.dd, ddValues[ddSelection].label)

			UIDropDownMenu_Initialize(frame.dd, function(self, level, menuList)
				if not level then return end
				for index, value in ipairs(ddValues) do
					local info = UIDropDownMenu_CreateInfo()
					info.text = value.label
					info.value = value.value
					info.func = function()
						UIDropDownMenu_SetText(frame.dd, value.label)
						LRS:ChangeSetting(sName, value.value)
					end
					UIDropDownMenu_AddButton(info, level)
				end
			end)
		end
	end

	local frame = CreateFrame("Frame", nil, UIParent, "DefaultPanelFlatTemplate")
	frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButtonDefaultAnchors")
	frame.TitleContainer.TitleText:SetText(addonName)
	frame:SetFrameStrata("FULLSCREEN")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:SetScript("OnMouseDown", function(self)
		self:StartMoving()
	end)
	frame:SetScript("OnMouseUp", function(self)
		self:StopMovingOrSizing()
	end)
	frame:SetSize(480, 330)
	frame:SetPoint("CENTER")

	createSetting(0, 0, frame, "COLOR", "BackgroundColor")
	createSetting(0, 25, frame, "COLOR", "BarColor")
	createSetting(0, 50, frame, "COLOR", "BorderColor")
	createSetting(0, 75, frame, "COLOR", "TextColor")

	local bgs, borders, fonts, bars, bgSel, brSel, foSel, baSel = {}, {}, {}, {}, 1, 1, 1, 1

	for _, value in ipairs(Private.LSM:List("background")) do
		tinsert(bgs, { label = value, value = value })
		if value == LRS.db.BackgroundTexture then
			bgSel = #bgs
		end
	end
	for _, value in ipairs(Private.LSM:List("border")) do
		tinsert(borders, { label = value, value = value })
		if value == LRS.db.BorderTexture then
			brSel = #borders
		end
	end
	for _, value in ipairs(Private.LSM:List("font")) do
		tinsert(fonts, { label = value, value = value })
		if value == LRS.db.TextFont then
			foSel = #fonts
		end
	end
	for _, value in ipairs(Private.LSM:List("statusbar")) do
		tinsert(bars, { label = value, value = value })
		if value == LRS.db.BarTexture then
			baSel = #bars
		end
	end

	local growDirections = { "UP", "DOWN", "LEFT", "RIGHT" }
	local grows, grSel = {}, 1
	for _, value in ipairs(growDirections) do
		tinsert(grows, { label = value, value = value })
		if value == LRS.db.FrameGrow then
			grSel = #grows
		end
	end

	createSetting(0, 125, frame, "DROPDOWN", "BackgroundTexture", bgs, bgSel)
	createSetting(0, 160, frame, "DROPDOWN", "BorderTexture", borders, brSel)
	createSetting(0, 195, frame, "DROPDOWN", "BarTexture", bars, baSel)
	createSetting(0, 230, frame, "DROPDOWN", "TextFont", fonts, foSel)
	createSetting(0, 265, frame, "DROPDOWN", "FrameGrow", grows, grSel)

	createSetting(265, 0, frame, "NUMBER", "FrameWidth")
	createSetting(265, 25, frame, "NUMBER", "FrameHeight")
	createSetting(265, 50, frame, "NUMBER", "BorderSize")
	createSetting(265, 75, frame, "NUMBER", "TextSize")
	createSetting(265, 100, frame, "NUMBER", "FrameSpacing")

	frame:Hide()
	frame:SetScript("OnHide", function()
		LRS:ToggleAnchor(false)
	end)
	LRS.SettingsFrame = frame
end

function LRS:ToggleSettings(force)
	if self.SettingsFrame:IsVisible() and not force then
		self.SettingsFrame:Hide()
	else
		self.SettingsFrame:Show()
		self:ToggleAnchor(true)
	end
end
