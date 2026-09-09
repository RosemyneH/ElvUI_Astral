local E, L, V, P, G = unpack(select(2, ...))
local NP = E:GetModule("NamePlates")
local LSM = E.Libs.LSM

local CreateFrame = CreateFrame
local GetTime = GetTime
local GetRuneCooldown = GetRuneCooldown
local GetRuneType = GetRuneType
local UnitClass = UnitClass
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local function Runes_OnUpdate(rune, elapsed)
	rune.duration = rune.duration + elapsed
	rune:SetValue(rune.duration)
end

function NP:Runes_GetTargetFrame()
	for frame in pairs(self.VisiblePlates) do
		if frame.isTarget then
			return frame
		end
	end
end

function NP:Runes_SetBarColor(bar, r, g, b)
	bar:SetStatusBarColor(r, g, b)
	if bar.bg then
		bar.bg:SetVertexColor(r * 0.35, g * 0.35, b * 0.35)
	end
end

function NP:Runes_GetColor(runeType, classColor)
	local classResources = NP.db.colors.classResources or P.nameplates.colors.classResources
	local colors = classResources.DEATHKNIGHT
	if classColor then
		return classColor.r, classColor.g, classColor.b
	end
	local color = colors[runeType or 1] or colors[1]
	return color.r, color.g, color.b
end

function NP:Runes_GetWidth(frame, db, scale)
	if db.autoWidth ~= false then
		return self.db.units[frame.UnitType].health.width * scale
	end

	return db.width * scale
end

function NP:Layout_Runes(runes, width, height)
	local spacing = runes.spacing or 1
	local barWidth = (width - (spacing * 5)) / 6

	for i = 1, 6 do
		local rune = runes[i]
		rune:SetSize(barWidth, height)
		rune:ClearAllPoints()

		if i == 1 then
			rune:Point("LEFT", runes, "LEFT", 0, 0)
		else
			rune:Point("LEFT", runes[i - 1], "RIGHT", spacing, 0)
		end
	end
end

function NP:Configure_RunesScale(frame, scale, noPlayAnimation)
	if E.myclass ~= "DEATHKNIGHT" then return end
	if frame.UnitType == "FRIENDLY_PLAYER" or frame.UnitType == "FRIENDLY_NPC" then return end

	local db = self.db.units.TARGET.classpower
	if not db or not db.enable or not frame.Runes then return end

	local runes = frame.Runes
	local width = self:Runes_GetWidth(frame, db, scale)
	local height = db.height * scale
	runes.spacing = scale

	if noPlayAnimation then
		runes:SetSize(width, height)
		self:Layout_Runes(runes, width, height)
	else
		if runes.scale:IsPlaying() then
			runes.scale:Stop()
		end

		runes.scale.width:SetChange(width)
		runes.scale.height:SetChange(height)
		runes.scale:Play()
	end
end

function NP:Configure_Runes(frame, configuring)
	if E.myclass ~= "DEATHKNIGHT" then return end
	if frame.UnitType == "FRIENDLY_PLAYER" or frame.UnitType == "FRIENDLY_NPC" then return end

	local db = self.db.units.TARGET.classpower
	local runes = frame.Runes
	if not db or not runes then return end

	if not db.enable then
		runes:Hide()
		return
	end

	local texture = LSM:Fetch("statusbar", self.db.statusbar)
	for i = 1, 6 do
		local rune = runes[i]
		rune:SetStatusBarTexture(texture)
		rune.bg:SetTexture(texture)
	end

	local healthShown = self.db.units[frame.UnitType].health.enable or (frame.isTarget and self.db.alwaysShowTargetHealth)

	runes:ClearAllPoints()
	if healthShown then
		runes:Point("CENTER", frame.Health, "BOTTOM", db.xOffset, db.yOffset)
	else
		runes:Point("CENTER", frame, "TOP", db.xOffset, db.yOffset)
	end

	self:Configure_RunesScale(frame, frame.currentScale or 1, configuring)

	if frame.isTarget then
		self:Update_Runes(frame)
	else
		runes:Hide()
	end
end

function NP:Update_Runes(frame)
	if E.myclass ~= "DEATHKNIGHT" then return end
	if frame.UnitType == "FRIENDLY_PLAYER" or frame.UnitType == "FRIENDLY_NPC" then return end

	local db = self.db.units.TARGET.classpower
	if not db or not db.enable then
		if frame.Runes then frame.Runes:Hide() end
		return
	end

	if not frame.isTarget then
		if frame.Runes then frame.Runes:Hide() end
		return
	end

	local runes = frame.Runes
	if not runes then return end

	runes:Show()

	local _, class = UnitClass("player")
	local classColor = db.classColor and RAID_CLASS_COLORS[class]

	for i = 1, 6 do
		local rune = runes[i]
		local start, duration, runeReady = GetRuneCooldown(i)
		local runeType = GetRuneType(i)
		local r, g, b = self:Runes_GetColor(runeType, classColor)

		self:Runes_SetBarColor(rune, r, g, b)

		if runeReady then
			rune:SetMinMaxValues(0, 1)
			rune:SetValue(1)
			rune:SetScript("OnUpdate", nil)
		elseif start and duration and duration > 0 then
			rune.duration = GetTime() - start
			rune:SetMinMaxValues(0, duration)
			rune:SetValue(rune.duration)
			rune:SetScript("OnUpdate", Runes_OnUpdate)
		else
			rune:SetMinMaxValues(0, 1)
			rune:SetValue(0)
			rune:SetScript("OnUpdate", nil)
		end
	end
end

function NP:Construct_Runes(frame)
	local runes = CreateFrame("Frame", nil, frame)
	runes:Hide()

	runes.scale = CreateAnimationGroup(runes)
	runes.scale.width = runes.scale:CreateAnimation("Width")
	runes.scale.width:SetDuration(0.2)
	runes.scale.height = runes.scale:CreateAnimation("Height")
	runes.scale.height:SetDuration(0.2)

	runes:SetScript("OnSizeChanged", function(self, width, height)
		NP:Layout_Runes(self, width, height)
	end)

	local texture = LSM:Fetch("statusbar", NP.db.statusbar)
	for i = 1, 6 do
		local rune = CreateFrame("StatusBar", nil, runes)
		rune:SetStatusBarTexture(texture)
		rune.bg = rune:CreateTexture(nil, "BORDER")
		rune.bg:SetAllPoints()
		rune.bg:SetTexture(texture)
		runes[i] = rune
	end

	return runes
end

function NP:Runes_OnEvent()
	if E.myclass ~= "DEATHKNIGHT" then return end

	local frame = NP:Runes_GetTargetFrame()
	if frame then
		NP:Update_Runes(frame)
	end
end

local runeFrame = CreateFrame("Frame")
runeFrame:RegisterEvent("RUNE_POWER_UPDATE")
runeFrame:RegisterEvent("RUNE_TYPE_UPDATE")
runeFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
runeFrame:SetScript("OnEvent", function()
	NP:Runes_OnEvent()
end)
