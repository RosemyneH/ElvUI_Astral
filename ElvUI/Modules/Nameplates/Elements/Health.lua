local E, L, V, P, G = unpack(ElvUI)
local NP = E:GetModule('NamePlates')
local UF = E:GetModule('UnitFrames')
local LSM = E.Libs.LSM

local ipairs = ipairs
local unpack = unpack
local UnitPlayerControlled = UnitPlayerControlled
local UnitClass = UnitClass
local UnitReaction = UnitReaction
local UnitIsConnected = UnitIsConnected
local CreateFrame = CreateFrame
local UnitIsTapped = UnitIsTapped
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsPlayer = UnitIsPlayer
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax

-- Shared absorb detection engine (Core/AbsorbEngine.lua) replaces the buff
-- scanning, tooltip discovery and caching that used to live in this file.
local Engine = E.AbsorbEngine
local Settings = Engine.Settings

NP.HealCommRevision = 5 -- shown by /eabsorb; bump when this file changes


function NP:Health_UpdateColor(_, unit)
	if not unit or self.unit ~= unit then return end
	local element = self.Health

	local r, g, b, t
	if element.colorDisconnected and not UnitIsConnected(unit) then
		t = self.colors.disconnected
	elseif (element.colorClass and self.isPlayer) or (element.colorClassNPC and not self.isPlayer) or (element.colorClassPet and UnitPlayerControlled(unit) and not self.isPlayer) then
		local _, class = UnitClass(unit)
		t = self.colors.class[class]
	elseif element.colorReaction and UnitReaction(unit, 'player') then
		local reaction = UnitReaction(unit, 'player')
		t = NP.db.colors.reactions[reaction == 4 and 'neutral' or reaction <= 3 and 'bad' or 'good']
	elseif element.colorSmooth then
		r, g, b = self:ColorGradient(element.cur or 1, element.max or 1, unpack(element.smoothGradient or self.colors.smooth))
	elseif element.colorHealth then
		t = NP.db.colors.health
	end

	if t then
		r, g, b = t.r, t.g, t.b
		element.r, element.g, element.b = r, g, b -- save these for the style filter to switch back
	end

	local db = NP:PlateDB(self)
	if db.greyTappedTargets and UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) and not UnitIsPlayer(unit) and not UnitIsDeadOrGhost(unit) then
		r, g, b = 0.5, 0.5, 0.5
		element.r, element.g, element.b = r, g, b
	end

	local sf = NP:StyleFilterChanges(self)
	if sf.HealthColor then
		r, g, b = sf.HealthColor.r, sf.HealthColor.g, sf.HealthColor.b
	end

	if b then
		element:SetStatusBarColor(r, g, b)

		if element.bg then
			element.bg:SetVertexColor(r * NP.multiplier, g * NP.multiplier, b * NP.multiplier)
		end
	end

	if element.PostUpdateColor then
		element:PostUpdateColor(unit, r, g, b)
	end
end

function NP:Construct_Health(nameplate)
	local Health = CreateFrame('StatusBar', nameplate:GetName()..'Health', nameplate)
	Health:SetParent(nameplate)
	Health:CreateBackdrop('Transparent', nil, nil, nil, nil, true, true)
	Health:SetStatusBarTexture(LSM:Fetch('statusbar', NP.db.statusbar))
	Health.considerSelectionInCombatHostile = true
	Health.UpdateColor = NP.Health_UpdateColor

	NP.StatusBars[Health] = true

	local statusBarTexture = Health:GetStatusBarTexture()
	local healthFlashTexture = Health:CreateTexture(nameplate:GetName()..'FlashTexture', 'OVERLAY')
	healthFlashTexture:SetTexture(LSM:Fetch('background', 'ElvUI Blank'))
	healthFlashTexture:Point('BOTTOMLEFT', statusBarTexture, 'BOTTOMLEFT')
	healthFlashTexture:Point('TOPRIGHT', statusBarTexture, 'TOPRIGHT')
	healthFlashTexture:Hide()
	nameplate.HealthFlashTexture = healthFlashTexture

	local clipFrame = CreateFrame("Frame", nil, Health)
	clipFrame:SetScript("OnUpdate", UF.HealthClipFrame_OnUpdate)
	clipFrame:SetAllPoints()
	clipFrame:EnableMouse(false)
	clipFrame.__frame = Health
	Health.ClipFrame = clipFrame

	return Health
end

function NP:Health_SetColors(nameplate, threatColors)
	if threatColors then -- managed by ThreatIndicator_PostUpdate
		nameplate.Health:SetColorTapping(nil)
		nameplate.Health:SetColorSelection(nil)
		nameplate.Health.colorReaction = nil
		nameplate.Health.colorClass = nil
	else
		local db = NP:PlateDB(nameplate)
		nameplate.Health:SetColorTapping(true)
		nameplate.Health:SetColorSelection(true)
		nameplate.Health.colorReaction = true
		nameplate.Health.colorClass = db.health and db.health.useClassColor
	end
end

function NP:Update_Health(nameplate, skipUpdate)
	local db = NP:PlateDB(nameplate)

	NP:Health_SetColors(nameplate)

	if skipUpdate then return end

	if db.health.enable then
		if not nameplate:IsElementEnabled('Health') then
			nameplate:EnableElement('Health')
		end

		nameplate.Health:Point('CENTER')
		nameplate.Health:Point('LEFT')
		nameplate.Health:Point('RIGHT')

		E:SetSmoothing(nameplate.Health, NP.db.smoothbars)
	elseif nameplate:IsElementEnabled('Health') then
		nameplate:DisableElement('Health')
	end

	nameplate.Health.width = db.health.width
	nameplate.Health.height = db.health.height
	nameplate.Health:Height(db.health.height)
end

function NP:Update_HealComm(nameplate)
	local db = NP:PlateDB(nameplate)

	if db.health.enable and db.health.healPrediction then
		if not nameplate:IsElementEnabled('HealCommBar') then
			nameplate:EnableElement('HealCommBar')
		end

		nameplate.HealCommBar.myBar:SetStatusBarColor(NP.db.colors.healPrediction.personal.r, NP.db.colors.healPrediction.personal.g, NP.db.colors.healPrediction.personal.b)
		nameplate.HealCommBar.otherBar:SetStatusBarColor(NP.db.colors.healPrediction.others.r, NP.db.colors.healPrediction.others.g, NP.db.colors.healPrediction.others.b)
	elseif nameplate:IsElementEnabled('HealCommBar') then
		nameplate:DisableElement('HealCommBar')
	end
end

function NP.HealthClipFrame_HealComm(frame)
	local pred = frame.HealCommBar
	if pred then
		NP:SetAlpha_HealComm(pred, true)
		NP:SetVisibility_HealComm(pred)
	end
end

function NP:SetAlpha_HealComm(obj, show)
	obj.myBar:SetAlpha(show and 1 or 0)
	obj.otherBar:SetAlpha(show and 1 or 0)
	if obj.shieldPool then
		for _, bar in ipairs(obj.shieldPool) do
			bar:SetAlpha(show and 1 or 0)
		end
	end
end

function NP:SetVisibility_HealComm(obj)
	-- the first update is from `HealthClipFrame_HealComm`
	-- we set this variable to allow `Configure_HealComm` to
	-- update the elements overflow lock later on by option
	if not obj.allowClippingUpdate then
		obj.allowClippingUpdate = true
	end

	local parent = obj.maxOverflow > 1 and obj.health or obj.parent
	obj.myBar:SetParent(parent)
	obj.otherBar:SetParent(parent)
	if obj.shieldPool then
		for _, bar in ipairs(obj.shieldPool) do
			bar:SetParent(parent)
		end
	end
end

function NP:Construct_HealComm(frame)
	local health = frame.Health
	local parent = health.ClipFrame

	local myBar = CreateFrame("StatusBar", nil, parent)
	local otherBar = CreateFrame("StatusBar", nil, parent)
	-- NOTE: deliberately NO absorbBar here. oUF_HealComm4 force-Shows
	-- element.absorbBar with the native absorb value on every update, which
	-- fought this file's shield pool when pool[1] doubled as the absorbBar
	-- (ghost shields on target swaps, leftover icons after expiry). Without
	-- the key, the library skips its absorbBar handling entirely and the
	-- shield pool is exclusively ours.

	myBar:SetFrameLevel(health:GetFrameLevel()+1)
	otherBar:SetFrameLevel(health:GetFrameLevel()+1)

	NP.StatusBars[myBar] = true
	NP.StatusBars[otherBar] = true

	local shieldPool = {}
	for k = 1, 5 do
		local sBar = CreateFrame("StatusBar", nil, parent)
		sBar:SetFrameLevel(health:GetFrameLevel()+1)
		NP.StatusBars[sBar] = true

		-- Create icon texture overlay
		local icon = sBar:CreateTexture(nil, "OVERLAY")
		icon:SetSize(Settings.IconSize, Settings.IconSize)
		sBar.icon = icon

		-- Create boundary separator line
		local separator = sBar:CreateTexture(nil, "OVERLAY")
		separator:SetWidth(Settings.SeparatorWidth)
		separator:SetTexture(Settings.SeparatorColor.r, Settings.SeparatorColor.g, Settings.SeparatorColor.b, Settings.SeparatorColor.a)
		sBar.separator = separator

		-- Create absorb value text overlay
		local text = sBar:CreateFontString(nil, "OVERLAY")
		text:SetFont(LSM:Fetch("font", "PT Sans Narrow"), 8, "OUTLINE")
		sBar.text = text

		-- Create outline frame
		local outline = CreateFrame("Frame", nil, sBar)
		outline:SetAllPoints(sBar)
		outline:Hide()
		sBar.outline = outline

		outline.top = outline:CreateTexture(nil, "OVERLAY")
		outline.top:SetTexture("Interface\\Buttons\\WHITE8x8")
		outline.top:SetHeight(1)
		outline.top:SetPoint("TOPLEFT", sBar, "TOPLEFT", 0, 0)
		outline.top:SetPoint("TOPRIGHT", sBar, "TOPRIGHT", 0, 0)

		outline.bottom = outline:CreateTexture(nil, "OVERLAY")
		outline.bottom:SetTexture("Interface\\Buttons\\WHITE8x8")
		outline.bottom:SetHeight(1)
		outline.bottom:SetPoint("BOTTOMLEFT", sBar, "BOTTOMLEFT", 0, 0)
		outline.bottom:SetPoint("BOTTOMRIGHT", sBar, "BOTTOMRIGHT", 0, 0)

		outline.left = outline:CreateTexture(nil, "OVERLAY")
		outline.left:SetTexture("Interface\\Buttons\\WHITE8x8")
		outline.left:SetWidth(1)
		outline.left:SetPoint("TOPLEFT", sBar, "TOPLEFT", 0, 0)
		outline.left:SetPoint("BOTTOMLEFT", sBar, "BOTTOMLEFT", 0, 0)

		outline.right = outline:CreateTexture(nil, "OVERLAY")
		outline.right:SetTexture("Interface\\Buttons\\WHITE8x8")
		outline.right:SetWidth(1)
		outline.right:SetPoint("TOPRIGHT", sBar, "TOPRIGHT", 0, 0)
		outline.right:SetPoint("BOTTOMRIGHT", sBar, "BOTTOMRIGHT", 0, 0)

		local glowTex = E.media.glowTex or "Interface\\AddOns\\ElvUI\\Media\\Textures\\GlowTex"
		local glow = CreateFrame("Frame", nil, outline)
		glow:SetBackdrop({
			edgeFile = glowTex,
			edgeSize = 4,
		})
		glow:SetPoint("TOPLEFT", sBar, "TOPLEFT", -3, 3)
		glow:SetPoint("BOTTOMRIGHT", sBar, "BOTTOMRIGHT", 3, -3)
		outline.glow = glow

		shieldPool[k] = sBar
	end

	local healPrediction = {
		myBar = myBar,
		otherBar = otherBar,
		shieldPool = shieldPool,
		PostUpdate = NP.UpdateHealComm,
		maxOverflow = 1,
		health = health,
		parent = parent,
		frame = frame
	}

	NP:SetAlpha_HealComm(healPrediction)

	return healPrediction
end

function NP:Configure_HealComm(frame)
	if frame.HealCommBar then frame.HealCommBar._sv = nil end -- config changed; force the next shield re-layout
	local db = NP:PlateDB(frame)

	if db.health.enable and db.health.healPrediction then
		if not frame:IsElementEnabled('HealComm4') then
			frame:EnableElement('HealComm4')
		end

		local healPrediction = frame.HealCommBar
		local myBar = healPrediction.myBar
		local otherBar = healPrediction.otherBar
		local c = db.colors.healPrediction
		healPrediction.maxOverflow = 1 + (c.maxOverflow or 0)

		if healPrediction.allowClippingUpdate then
			NP:SetVisibility_HealComm(healPrediction)
		end

		local health = frame.Health
		local orientation = health:GetOrientation()

		myBar:SetOrientation(orientation)
		otherBar:SetOrientation(orientation)
		if healPrediction.shieldPool then
			for _, bar in ipairs(healPrediction.shieldPool) do
				bar:SetOrientation(orientation)
			end
		end

		if orientation == "HORIZONTAL" then
			local width = health:GetWidth()
			width = (width > 0 and width) or health.WIDTH
			local healthTexture = health:GetStatusBarTexture()

			myBar:Size(width, 0)
			myBar:ClearAllPoints()
			myBar:Point("TOP", health, "TOP")
			myBar:Point("BOTTOM", health, "BOTTOM")
			myBar:Point("LEFT", healthTexture, "RIGHT")

			otherBar:Size(width, 0)
			otherBar:ClearAllPoints()
			otherBar:Point("TOP", health, "TOP")
			otherBar:Point("BOTTOM", health, "BOTTOM")
			otherBar:Point("LEFT", myBar:GetStatusBarTexture(), "RIGHT")

			if healPrediction.shieldPool then
				for _, bar in ipairs(healPrediction.shieldPool) do
					bar:Size(width, 0)
				end
			end
		else
			local height = health:GetHeight()
			height = (height > 0 and height) or health.HEIGHT
			local healthTexture = health:GetStatusBarTexture()

			myBar:Size(0, height)
			myBar:ClearAllPoints()
			myBar:Point("LEFT", health, "LEFT")
			myBar:Point("RIGHT", health, "RIGHT")
			myBar:Point("BOTTOM", healthTexture, "TOP")

			otherBar:Size(0, height)
			otherBar:ClearAllPoints()
			otherBar:Point("LEFT", health, "LEFT")
			otherBar:Point("RIGHT", health, "RIGHT")
			otherBar:Point("BOTTOM", myBar:GetStatusBarTexture(), "TOP")

			if healPrediction.shieldPool then
				for _, bar in ipairs(healPrediction.shieldPool) do
					bar:Size(0, height)
				end
			end
		end

		frame.HealCommBar.myBar:SetStatusBarColor(NP.db.colors.healPrediction.personal.r, NP.db.colors.healPrediction.personal.g, NP.db.colors.healPrediction.personal.b)
		frame.HealCommBar.otherBar:SetStatusBarColor(NP.db.colors.healPrediction.others.r, NP.db.colors.healPrediction.others.g, NP.db.colors.healPrediction.others.b)

		if frame:IsElementEnabled('HealComm4') then
			frame:UpdateElement('HealComm4')
		end
	elseif frame:IsElementEnabled('HealComm4') then
		frame:DisableElement('HealComm4')
	end
end

local function UpdateFillBar(frame, previousTexture, bar, amount)
	if amount == 0 then
		bar:Hide()
		return previousTexture
	end

	local orientation = frame:GetOrientation()
	bar:ClearAllPoints()
	if orientation == "HORIZONTAL" then
		bar:SetPoint("TOPLEFT", previousTexture, "TOPRIGHT")
		bar:SetPoint("BOTTOMLEFT", previousTexture, "BOTTOMRIGHT")
	else
		bar:SetPoint("BOTTOMRIGHT", previousTexture, "TOPRIGHT")
		bar:SetPoint("BOTTOMLEFT", previousTexture, "TOPLEFT")
	end

	local totalWidth, totalHeight = frame:GetSize()
	if orientation == "HORIZONTAL" then
		bar:Width(totalWidth)
	else
		bar:Height(totalHeight)
	end

	return bar:GetStatusBarTexture()
end

local function ShieldBar_OnUpdate(self, elapsed)
	-- 30fps cap: the pulse doesn't need per-frame precision
	self._pulseAcc = (self._pulseAcc or 0) + elapsed
	if self._pulseAcc < 0.033 then return end
	elapsed = self._pulseAcc
	self._pulseAcc = 0

	self.pulseTime = (self.pulseTime or 0) + elapsed
	local baseAlpha = self.baseAlpha or 0.6
	local alpha = baseAlpha + 0.2 * math.sin(self.pulseTime * 5)
	if alpha < 0.1 then alpha = 0.1 end
	if alpha > 1 then alpha = 1 end
	local r, g, b = self:GetStatusBarColor()
	self:SetStatusBarColor(r, g, b, alpha)
end

local function FormatAbsorbValue(val, short)
	if not short then return tostring(val) end
	if val >= 1000000 then
		return string.format("%.1fm", val / 1000000)
	elseif val >= 1000 then
		return string.format("%.1fk", val / 1000)
	else
		return tostring(val)
	end
end


-- Correctly resolves boolean options (the old `x and v or default` pattern
-- could never return false, so icon/text toggles were stuck on)
local function GetBoolOption(tbl, key, default)
	if tbl and tbl[key] ~= nil then return tbl[key] end
	return default
end

local function HideShieldBars(obj)
	local shieldPool = obj.shieldPool
	if not shieldPool then return end
	for _, bar in ipairs(shieldPool) do
		bar:Hide()
		bar:SetScript("OnUpdate", nil)
		if bar.text then bar.text:Hide() end
	end
	obj._shieldsVisible = false
end

function NP:UpdateHealComm(unit, myIncomingHeal, allIncomingHeal, absorb)
	local health = self.health
	local previousTexture = health:GetStatusBarTexture()

	previousTexture = UpdateFillBar(health, previousTexture, self.myBar, myIncomingHeal)
	previousTexture = UpdateFillBar(health, previousTexture, self.otherBar, allIncomingHeal)

	local shieldPool = self.shieldPool
	if not shieldPool then return end

	-- Get config DB for this nameplate
	local db = self.frame and NP:PlateDB(self.frame)
	local hpPred = db and db.health and db.health.healPrediction
	local hpPredTable = type(hpPred) == "table" and hpPred or nil

	local absorbsEnable = GetBoolOption(hpPredTable, "absorbsEnable", hpPred ~= false)
	if not absorbsEnable then
		if self._shieldsVisible then HideShieldBars(self) end
		return
	end

	local absorbsPersonalOnly = GetBoolOption(hpPredTable, "absorbsPersonalOnly", false)
	local shields, count, version, totalAmount, nativeTotal = Engine:GetUnitShields(unit, absorbsPersonalOnly)

	if count == 0 then
		if self._shieldsVisible then HideShieldBars(self) end
		return
	end

	local displayTotalAbsorb = absorbsPersonalOnly and totalAmount or math.max(nativeTotal, totalAmount)
	if displayTotalAbsorb <= 0 then
		if self._shieldsVisible then HideShieldBars(self) end
		return
	end

	local healthVal = UnitHealth(unit) or 0
	local maxHealth = UnitHealthMax(unit) or 0
	if maxHealth <= 0 then
		if self._shieldsVisible then HideShieldBars(self) end
		return
	end

	local orientation = health:GetOrientation()
	local totalWidth, totalHeight = health:GetSize()
	local isOverflowing = (healthVal + (myIncomingHeal or 0) + (allIncomingHeal or 0) + displayTotalAbsorb) > maxHealth

	-- Skip the full re-layout when nothing that affects the shield bars changed.
	-- `unit` is part of the signature because nameplates are recycled across units.
	if self._shieldsVisible
		and unit == self._sunit
		and version == self._sv
		and isOverflowing == self._so
		and maxHealth == self._smh
		and totalWidth == self._sw
		and totalHeight == self._sh
		and displayTotalAbsorb == self._sdt
		and previousTexture == self._sat then
		return
	end
	self._sunit, self._sv, self._so, self._smh, self._sw, self._sh, self._sat = unit, version, isOverflowing, maxHealth, totalWidth, totalHeight, previousTexture
	self._sdt = displayTotalAbsorb
	if totalWidth <= 0 then
		self._sv = nil -- frame not sized yet; never skip the next layout
	end


	-- Hide all shield bars and text overlays before the re-layout
	for _, bar in ipairs(shieldPool) do
		bar:Hide()
		bar:SetScript("OnUpdate", nil)
		if bar.text then bar.text:Hide() end
	end
	self._shieldsVisible = true

	local showAbsorbIcons = GetBoolOption(hpPredTable, "showAbsorbIcons", true)
	local absorbIconSize = (hpPredTable and hpPredTable.absorbIconSize) or Settings.IconSize
	local absorbIconXOffset = (hpPredTable and hpPredTable.absorbIconXOffset) or 0
	local absorbIconYOffset = (hpPredTable and hpPredTable.absorbIconYOffset) or 0
	local showAbsorbText = GetBoolOption(hpPredTable, "showAbsorbText", true)
	local shortAbsorbText = GetBoolOption(hpPredTable, "shortAbsorbText", true)
	local absorbTextXOffset = (hpPredTable and hpPredTable.absorbTextXOffset) or 0
	local absorbTextYOffset = (hpPredTable and hpPredTable.absorbTextYOffset) or 0
	local absorbSeparatorWidth = (hpPredTable and hpPredTable.absorbSeparatorWidth) or Settings.SeparatorWidth
	local absorbSeparatorAlpha = (hpPredTable and hpPredTable.absorbSeparatorAlpha) or Settings.SeparatorColor.a
	local absorbPulse = GetBoolOption(hpPredTable, "absorbPulse", false)
	local clampAbsorbs = GetBoolOption(hpPredTable, "clampAbsorbs", false)

	local scaleFactor = 1
	if clampAbsorbs and isOverflowing and totalAmount > maxHealth then
		scaleFactor = maxHealth / totalAmount
	end

	local lastAnchor = previousTexture

	for k = 1, count do
		local shield = shields[k]
		if k > #shieldPool then break end
		local bar = shieldPool[k]

		-- Set Color from Settings
		local color
		local hAbs = E.db.unitframe.colors.healAbsorbs
		if hAbs then
			if shield.isPlayer then
				color = hAbs.absorbPlayer or {r = 0.3, g = 0.7, b = 1.0, a = 0.6}
			else
				color = hAbs.absorbOther or {r = 0.5, g = 0.5, b = 1.0, a = 0.6}
			end
		else
			color = Settings.Colors[((k - 1) % #Settings.Colors) + 1]
		end
		bar:SetStatusBarColor(color.r, color.g, color.b, color.a)
		bar.baseAlpha = color.a

		-- Set Outline
		if bar.outline then
			local style, col
			if hAbs then
				if shield.isPlayer then
					style = hAbs.absorbPlayerOutline or "NONE"
					col = hAbs.absorbPlayerOutlineColor or {r = 1, g = 1, b = 1, a = 1}
				else
					style = hAbs.absorbOtherOutline or "NONE"
					col = hAbs.absorbOtherOutlineColor or {r = 1, g = 1, b = 1, a = 1}
				end
			else
				style = "NONE"
			end
			
			if style == "NONE" then
				bar.outline:Hide()
			else
				bar.outline:Show()
				bar.outline.style = style
				bar.outline.time = 0
				
				if style == "SOLID" then
					bar.outline.top:SetTexture("Interface\\Buttons\\WHITE8x8")
					bar.outline.bottom:SetTexture("Interface\\Buttons\\WHITE8x8")
					bar.outline.left:SetTexture("Interface\\Buttons\\WHITE8x8")
					bar.outline.right:SetTexture("Interface\\Buttons\\WHITE8x8")
					
					bar.outline.top:SetTexCoord(0, 1, 0, 1)
					bar.outline.bottom:SetTexCoord(0, 1, 0, 1)
					bar.outline.left:SetTexCoord(0, 1, 0, 1)
					bar.outline.right:SetTexCoord(0, 1, 0, 1)
					
					bar.outline.top:SetVertexColor(col.r, col.g, col.b, col.a)
					bar.outline.bottom:SetVertexColor(col.r, col.g, col.b, col.a)
					bar.outline.left:SetVertexColor(col.r, col.g, col.b, col.a)
					bar.outline.right:SetVertexColor(col.r, col.g, col.b, col.a)
					
					bar.outline.top:Show()
					bar.outline.bottom:Show()
					bar.outline.left:Show()
					bar.outline.right:Show()
					bar.outline.glow:Hide()
				elseif style == "GLOW" then
					bar.outline.top:Hide()
					bar.outline.bottom:Hide()
					bar.outline.left:Hide()
					bar.outline.right:Hide()
					
					bar.outline.glow:SetBackdropBorderColor(col.r, col.g, col.b, col.a)
					bar.outline.glow:Show()
				end
			end
		end

		-- Set Icon
		if bar.icon then
			bar.icon:SetTexture(shield.icon)
			bar.icon:SetSize(absorbIconSize, absorbIconSize)
			if showAbsorbIcons and not shield.isFallback then
				bar.icon:Show()
			else
				bar.icon:Hide()
			end
		end

		-- Set Separator
		if bar.separator then
			bar.separator:SetWidth(absorbSeparatorWidth)
			bar.separator:SetTexture(Settings.SeparatorColor.r, Settings.SeparatorColor.g, Settings.SeparatorColor.b, absorbSeparatorAlpha)
		end

		bar:ClearAllPoints()

		if orientation == "HORIZONTAL" then
			local width = (shield.amount / maxHealth) * totalWidth * scaleFactor
			if width > totalWidth then width = totalWidth end
			if shield.amount > 0 and width < 3 then width = 3 end -- keep small absorbs visible

			if isOverflowing then
				-- Grow from right to left
				if k == 1 then
					bar:SetPoint("TOPRIGHT", health, "TOPRIGHT")
					bar:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT")
				else
					bar:SetPoint("TOPRIGHT", shieldPool[k - 1], "TOPLEFT")
					bar:SetPoint("BOTTOMRIGHT", shieldPool[k - 1], "BOTTOMLEFT")
				end
				if bar.separator then
					bar.separator:ClearAllPoints()
					bar.separator:SetPoint("TOPLEFT", bar, "TOPLEFT")
					bar.separator:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT")
					bar.separator:Show()
				end
			else
				-- Grow from left to right
				if k == 1 then
					bar:SetPoint("TOPLEFT", lastAnchor, "TOPRIGHT")
					bar:SetPoint("BOTTOMLEFT", lastAnchor, "BOTTOMRIGHT")
				else
					bar:SetPoint("TOPLEFT", shieldPool[k - 1], "TOPRIGHT")
					bar:SetPoint("BOTTOMLEFT", shieldPool[k - 1], "BOTTOMRIGHT")
				end
				if bar.separator then
					bar.separator:ClearAllPoints()
					bar.separator:SetPoint("TOPRIGHT", bar, "TOPRIGHT")
					bar.separator:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT")
					bar.separator:Show()
				end
			end

			-- Position Icon next to separator line
			local iconShown = false
			local iconSide = "LEFT"
			if bar.icon and showAbsorbIcons then
				bar.icon:ClearAllPoints()
				if count == 1 then
					bar.icon:SetPoint("LEFT", bar, "LEFT", 2 + absorbIconXOffset, 0 + absorbIconYOffset)
					iconSide = "LEFT"
				else
					if isOverflowing then
						if k < count then
							bar.icon:SetPoint("LEFT", bar, "LEFT", 2 + absorbIconXOffset, 0 + absorbIconYOffset)
							iconSide = "LEFT"
						else
							bar.icon:SetPoint("RIGHT", bar, "RIGHT", -2 + absorbIconXOffset, 0 + absorbIconYOffset)
							iconSide = "RIGHT"
						end
					else
						if k < count then
							bar.icon:SetPoint("RIGHT", bar, "RIGHT", -2 + absorbIconXOffset, 0 + absorbIconYOffset)
							iconSide = "RIGHT"
						else
							bar.icon:SetPoint("LEFT", bar, "LEFT", 2 + absorbIconXOffset, 0 + absorbIconYOffset)
							iconSide = "LEFT"
						end
					end
				end
				if width >= (absorbIconSize + 4) then -- only when the segment can actually hold the icon
					bar.icon:Show()
					iconShown = true
				else
					bar.icon:Hide()
				end
			end

			-- Position Text
			if bar.text then
				bar.text:ClearAllPoints()
				local textFits = false
				if showAbsorbText then
					bar.text:SetText(FormatAbsorbValue(shield.amount, shortAbsorbText))
					-- show the value only when it genuinely fits inside the segment
					local needed = bar.text:GetStringWidth() + 6 + (iconShown and (absorbIconSize + 2) or 0)
					textFits = width >= needed
				end
				if textFits then
					if iconShown then
						if iconSide == "LEFT" then
							bar.text:SetPoint("LEFT", bar.icon, "RIGHT", 2 + absorbTextXOffset, 0 + absorbTextYOffset)
						else
							bar.text:SetPoint("RIGHT", bar.icon, "LEFT", -2 + absorbTextXOffset, 0 + absorbTextYOffset)
						end
					else
						bar.text:SetPoint("CENTER", bar, "CENTER", absorbTextXOffset, absorbTextYOffset)
					end
					bar.text:Show()
				else
					bar.text:Hide()
				end
			end

			bar:SetWidth(width)
		else
			-- Vertical orientation
			local height = (shield.amount / maxHealth) * totalHeight * scaleFactor
			if height > totalHeight then height = totalHeight end

			if isOverflowing then
				-- Grow from top to bottom
				if k == 1 then
					bar:SetPoint("TOPLEFT", health, "TOPLEFT")
					bar:SetPoint("TOPRIGHT", health, "TOPRIGHT")
				else
					bar:SetPoint("TOPLEFT", shieldPool[k - 1], "BOTTOMLEFT")
					bar:SetPoint("TOPRIGHT", shieldPool[k - 1], "BOTTOMRIGHT")
				end
				if bar.separator then
					bar.separator:ClearAllPoints()
					bar.separator:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT")
					bar.separator:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT")
					bar.separator:Show()
				end
			else
				-- Grow from bottom to top
				if k == 1 then
					bar:SetPoint("BOTTOMLEFT", lastAnchor, "TOPLEFT")
					bar:SetPoint("BOTTOMRIGHT", lastAnchor, "TOPRIGHT")
				else
					bar:SetPoint("BOTTOMLEFT", shieldPool[k - 1], "TOPLEFT")
					bar:SetPoint("BOTTOMRIGHT", shieldPool[k - 1], "TOPRIGHT")
				end
				if bar.separator then
					bar.separator:ClearAllPoints()
					bar.separator:SetPoint("TOPLEFT", bar, "TOPLEFT")
					bar.separator:SetPoint("TOPRIGHT", bar, "TOPRIGHT")
					bar.separator:Show()
				end
			end

			-- Position Icon next to separator line
			local iconShown = false
			local iconSide = "BOTTOM"
			if bar.icon and showAbsorbIcons then
				bar.icon:ClearAllPoints()
				if count == 1 then
					bar.icon:SetPoint("BOTTOM", bar, "BOTTOM", 0 + absorbIconXOffset, 2 + absorbIconYOffset)
					iconSide = "BOTTOM"
				else
					if isOverflowing then
						if k < count then
							bar.icon:SetPoint("TOP", bar, "TOP", 0 + absorbIconXOffset, -2 + absorbIconYOffset)
							iconSide = "TOP"
						else
							bar.icon:SetPoint("BOTTOM", bar, "BOTTOM", 0 + absorbIconXOffset, 2 + absorbIconYOffset)
							iconSide = "BOTTOM"
						end
					else
						if k < count then
							bar.icon:SetPoint("BOTTOM", bar, "BOTTOM", 0 + absorbIconXOffset, 2 + absorbIconYOffset)
							iconSide = "BOTTOM"
						else
							bar.icon:SetPoint("TOP", bar, "TOP", 0 + absorbIconXOffset, -2 + absorbIconYOffset)
							iconSide = "TOP"
						end
					end
				end
				if height >= (absorbIconSize + 2) then -- only when the segment can actually hold the icon
					bar.icon:Show()
					iconShown = true
				else
					bar.icon:Hide()
				end
			end

			-- Position Text
			if bar.text then
				bar.text:ClearAllPoints()
				local textFits = false
				if showAbsorbText then
					bar.text:SetText(FormatAbsorbValue(shield.amount, shortAbsorbText))
					-- show the value only when it genuinely fits inside the segment
					textFits = (height >= 12) and (bar.text:GetStringWidth() + 4 <= totalWidth)
				end
				if textFits then
					if iconShown then
						if iconSide == "BOTTOM" then
							bar.text:SetPoint("BOTTOM", bar.icon, "TOP", 0 + absorbTextXOffset, 2 + absorbTextYOffset)
						else
							bar.text:SetPoint("TOP", bar.icon, "BOTTOM", 0 + absorbTextXOffset, -2 + absorbTextYOffset)
						end
					else
						bar.text:SetPoint("CENTER", bar, "CENTER", absorbTextXOffset, absorbTextYOffset)
					end
					bar.text:Show()
				else
					bar.text:Hide()
				end
			end

			bar:SetHeight(height)
		end

		-- Hide separator on the last shield in the active list
		if k == count and bar.separator then
			bar.separator:Hide()
		end

		bar:SetMinMaxValues(0, shield.amount)
		bar:SetValue(shield.amount)
		bar:Show()

		-- Start pulse animation if enabled
		if absorbPulse then
			bar.pulseTime = 0
			bar:SetScript("OnUpdate", ShieldBar_OnUpdate)
		end
	end
end
