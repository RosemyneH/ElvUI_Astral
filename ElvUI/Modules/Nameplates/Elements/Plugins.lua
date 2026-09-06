local E, L, V, P, G = unpack(ElvUI)
local NP = E:GetModule('NamePlates')
local LSM = E.Libs.LSM

local strfind = strfind
local ipairs, unpack = ipairs, unpack
local CreateFrame = CreateFrame

local targetIndicators = {'Spark', 'TopIndicator', 'LeftIndicator', 'RightIndicator'}

local function HasNameplateHealth(db)
	return db.health.enable and not db.nameOnly
end

local function GetTargetGlowAnchor(nameplate, db)
	return HasNameplateHealth(db) and nameplate.Health or nameplate.Name
end

local function ResolveNameOnlyGlowStyle(style, db)
	if HasNameplateHealth(db) then return style end
	if style == 'style2' then return 'style1'
	elseif style == 'style6' then return 'style5'
	elseif style == 'style8' then return 'style7'
	end
	return style
end

function NP:Construct_QuestIcons(nameplate)
	local QuestIcons = CreateFrame('Frame', nameplate:GetName() .. 'QuestIcons', nameplate)
	QuestIcons:Size(20)
	QuestIcons:Hide()

	for _, object in ipairs(NP.QuestIcons.iconTypes) do
		local icon = QuestIcons:CreateTexture(nil, 'BORDER', nil, 1)
		icon.Text = QuestIcons:CreateFontString(nil, 'OVERLAY')
		icon.Text:FontTemplate()
		icon:Hide()

		QuestIcons[object] = icon
	end

	QuestIcons.Item:SetTexCoord(unpack(E.TexCoords))
	QuestIcons.Chat:SetTexture([[Interface\WorldMap\ChatBubble_64.PNG]])
	QuestIcons.Chat:SetTexCoord(0, 0.5, 0.5, 1)

	return QuestIcons
end

function NP:Update_QuestIcons(nameplate)
	local plateDB = NP:PlateDB(nameplate)
	local db = plateDB.questIcon

	if db and db.enable and (nameplate.frameType == 'FRIENDLY_NPC' or nameplate.frameType == 'ENEMY_NPC') then
		if not nameplate:IsElementEnabled('QuestIcons') then
			nameplate:EnableElement('QuestIcons')
		end

		nameplate.QuestIcons:ClearAllPoints()
		nameplate.QuestIcons:Point(E.InversePoints[db.position], nameplate, db.position, db.xOffset, db.yOffset)

		for _, object in ipairs(NP.QuestIcons.iconTypes) do
			local icon = nameplate.QuestIcons[object]
			icon:Size(db.size, db.size)
			icon:SetAlpha(db.hideIcon and 0 or 1)

			local xoffset = strfind(db.textPosition, 'LEFT') and -2 or 2
			local yoffset = strfind(db.textPosition, 'BOTTOM') and 2 or -2
			icon.Text:ClearAllPoints()
			icon.Text:Point('CENTER', icon, db.textPosition, xoffset, yoffset)
			icon.Text:FontTemplate(LSM:Fetch('font', db.font), db.fontSize, db.fontOutline)
			icon.Text:SetJustifyH('CENTER')

			icon.size, icon.position = db.size, db.position
		end
	elseif nameplate:IsElementEnabled('QuestIcons') then
		nameplate:DisableElement('QuestIcons')
	end
end

function NP:Construct_ClassificationIndicator(nameplate)
	return nameplate:CreateTexture(nameplate:GetName() .. 'ClassificationIndicator', 'OVERLAY')
end

function NP:Update_ClassificationIndicator(nameplate)
	local plateDB = NP:PlateDB(nameplate)
	local db = plateDB.eliteIcon

	if db and db.enable and (nameplate.frameType == 'FRIENDLY_NPC' or nameplate.frameType == 'ENEMY_NPC') then
		if not nameplate:IsElementEnabled('ClassificationIndicator') then
			nameplate:EnableElement('ClassificationIndicator')
		end

		nameplate.ClassificationIndicator:ClearAllPoints()
		nameplate.ClassificationIndicator:Size(db.size, db.size)
		nameplate.ClassificationIndicator:Point(E.InversePoints[db.position], nameplate, db.position, db.xOffset, db.yOffset)
	elseif nameplate:IsElementEnabled('ClassificationIndicator') then
		nameplate:DisableElement('ClassificationIndicator')
	end
end

function NP:Construct_TargetIndicator(nameplate)
	local TargetIndicator = CreateFrame('Frame', nameplate:GetName() .. 'TargetIndicator', nameplate)
	TargetIndicator:SetFrameLevel(nameplate:GetFrameLevel()-1)

	TargetIndicator.Shadow = CreateFrame('Frame', nil, TargetIndicator)
	TargetIndicator.Shadow:SetBackdrop({edgeFile = LSM:Fetch('border', 'ElvUI GlowBorder'), edgeSize = E:Scale(5)})
	TargetIndicator.Shadow:Hide()

	for _, object in ipairs(targetIndicators) do
		local indicator = TargetIndicator:CreateTexture(nil, 'BACKGROUND')
		indicator:Hide()

		if object == 'Spark' then
			indicator:SetTexture(E.Media.Textures.Spark)
		end

		TargetIndicator[object] = indicator
	end

	return TargetIndicator
end

function NP:Update_TargetIndicator(nameplate)
	local enabled = nameplate:IsElementEnabled('TargetIndicator')
	if nameplate.frameType == 'PLAYER' then
		if enabled then
			nameplate:DisableElement('TargetIndicator')
		end

		return
	elseif not enabled then
		nameplate:EnableElement('TargetIndicator')
	end

	local tdb = NP.db.units.TARGET
	local indicator = nameplate.TargetIndicator
	indicator.arrow = E.Media.Textures[NP.db.units.TARGET.arrow] or E.Media.Textures.TopIndicator
	indicator.lowHealthThreshold = NP.db.lowHealthThreshold
	indicator.preferGlowColor = NP.db.colors.preferGlowColor
	indicator.style = tdb.glowStyle

	if indicator.style ~= 'none' then
		local style, color, size, scale, spacing = tdb.glowStyle, NP.db.colors.glowColor, tdb.arrowSize, tdb.arrowScale, tdb.arrowSpacing
		local r, g, b, a = color.r, color.g, color.b, color.a
		local db = NP:PlateDB(nameplate)
		local anchor = GetTargetGlowAnchor(nameplate, db)
		scale = scale or 1
		size = size * scale
		style = ResolveNameOnlyGlowStyle(style, db)
		indicator.style = style

		if indicator.TopIndicator and (style == 'style3' or style == 'style5' or style == 'style6') then
			indicator.TopIndicator:ClearAllPoints()
			indicator.TopIndicator:Point('BOTTOM', anchor, 'TOP', 0, spacing)
			indicator.TopIndicator:SetVertexColor(r, g, b, a)
			indicator.TopIndicator:SetSize(size, size)
		end

		if indicator.LeftIndicator and indicator.RightIndicator and (style == 'style4' or style == 'style7' or style == 'style8') then
			indicator.LeftIndicator:ClearAllPoints()
			indicator.RightIndicator:ClearAllPoints()
			indicator.LeftIndicator:Point('LEFT', anchor, 'RIGHT', spacing, 0)
			indicator.RightIndicator:Point('RIGHT', anchor, 'LEFT', -spacing, 0)
			indicator.LeftIndicator:SetVertexColor(r, g, b, a)
			indicator.RightIndicator:SetVertexColor(r, g, b, a)
			indicator.LeftIndicator:SetSize(size, size)
			indicator.RightIndicator:SetSize(size, size)
		end

		if indicator.Shadow and (style == 'style1' or style == 'style5' or style == 'style7') then
			indicator.Shadow:ClearAllPoints()
			indicator.Shadow:SetOutside(anchor, E.PixelMode and 4 or 6, E.PixelMode and 4 or 6, nil, true)
			indicator.Shadow:SetBackdropBorderColor(r, g, b, a)
			indicator.Shadow:SetAlpha(a)
		end

		if indicator.Spark and (style == 'style2' or style == 'style6' or style == 'style8') then
			local sparkSize = HasNameplateHealth(db) and ((E.Border + 14) * scale) or ((E.Border + 8) * scale)
			indicator.Spark:ClearAllPoints()
			indicator.Spark:Point('TOPLEFT', anchor, 'TOPLEFT', -(sparkSize * 2), sparkSize)
			indicator.Spark:Point('BOTTOMRIGHT', anchor, 'BOTTOMRIGHT', (sparkSize * 2), -sparkSize)
			indicator.Spark:SetVertexColor(r, g, b, a)
		end
	end
end

function NP:Construct_Highlight(nameplate)
	local frame = CreateFrame('Frame', nameplate:GetName() .. 'HoverHighlight', nameplate)
	frame:SetFrameLevel(nameplate.Health:GetFrameLevel() + 2)
	frame:Hide()

	local glow = CreateFrame('Frame', nil, frame)
	glow:SetAllPoints(frame)
	glow:SetBackdrop({edgeFile = LSM:Fetch('border', 'ElvUI GlowBorder'), edgeSize = E:Scale(4)})

	local spark = frame:CreateTexture(nil, 'BACKGROUND')
	spark:SetAllPoints(frame)
	spark:SetTexture(E.Media.Textures.Spark)

	local fill = frame:CreateTexture(nil, 'BACKGROUND')
	fill:SetAllPoints(frame)

	frame.Glow = glow
	frame.Spark = spark
	frame.Fill = fill

	return frame
end

function NP:Update_Highlight(nameplate, nameOnlySF)
	local db = NP:PlateDB(nameplate)

	if NP.db.highlight and db.enable then
		if not nameplate:IsElementEnabled('Highlight') then
			nameplate:EnableElement('Highlight')
		end

		local highlight = nameplate.Highlight
		local style = NP.db.highlightStyle or 'GLOW'
		local color = NP.db.highlightColor or P.nameplates.highlightColor
		local hasHealth = db.health.enable and not (db.nameOnly or nameOnlySF)
		local anchor = hasHealth and nameplate.Health or nameplate.Name

		highlight:ClearAllPoints()
		if hasHealth then
			highlight:SetPoint('TOPLEFT', nameplate.Health, 'TOPLEFT', -3, 3)
			highlight:SetPoint('BOTTOMRIGHT', nameplate.Health, 'BOTTOMRIGHT', 3, -3)
		else
			highlight:SetPoint('TOPLEFT', anchor, 'TOPLEFT', -10, 8)
			highlight:SetPoint('BOTTOMRIGHT', anchor, 'BOTTOMRIGHT', 10, -8)
		end

		highlight.Glow:Hide()
		highlight.Spark:Hide()
		highlight.Fill:Hide()

		if style == 'GLOW' then
			highlight.Glow:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
			highlight.Glow:Show()
		elseif style == 'SPARK' then
			highlight.Spark:SetAlpha(hasHealth and 0.75 or 0.5)
			highlight.Spark:Show()
		elseif style == 'FILL' then
			highlight.Fill:SetTexture(LSM:Fetch('statusbar', NP.db.statusbar))
			highlight.Fill:SetVertexColor(color.r, color.g, color.b, color.a * 0.35)
			highlight.Fill:Show()
		end
	elseif nameplate:IsElementEnabled('Highlight') then
		nameplate:DisableElement('Highlight')
	end
end

function NP:Construct_PVPRole(nameplate)
	local texture = nameplate:CreateTexture(nameplate:GetName() .. 'PVPRole', 'OVERLAY', nil, 1)
	texture:Size(40)
	texture.HealerTexture = E.Media.Textures.Healer
	texture.TankTexture = E.Media.Textures.Tank
	texture:SetTexture(texture.HealerTexture)

	texture:Hide()

	return texture
end

function NP:Update_PVPRole(nameplate)
	local db = NP:PlateDB(nameplate)

	if (nameplate.frameType == 'FRIENDLY_PLAYER' or nameplate.frameType == 'ENEMY_PLAYER') and (db.markHealers or db.markTanks) then
		if not nameplate:IsElementEnabled('PVPRole') then
			nameplate:EnableElement('PVPRole')
		end

		nameplate.PVPRole.ShowHealers = db.markHealers
		nameplate.PVPRole.ShowTanks = db.markTanks

		nameplate.PVPRole:Point('RIGHT', nameplate.Health, 'LEFT', -6, 0)
	elseif nameplate:IsElementEnabled('PVPRole') then
		nameplate:DisableElement('PVPRole')
	end
end

function NP:Update_Fader(nameplate)
	local db = NP:PlateDB(nameplate)
	local vis = db.visibility

	if not vis or vis.showAlways then
		if nameplate:IsElementEnabled('Fader') then
			nameplate:DisableElement('Fader')

			NP:PlateFade(nameplate, 0.5, nameplate:GetAlpha(), 1)
		end
	elseif db.enable then
		if not nameplate.Fader then
			nameplate.Fader = {}
		end

		if not nameplate:IsElementEnabled('Fader') then
			nameplate:EnableElement('Fader')

			nameplate.Fader:SetOption('MinAlpha', 0)
			nameplate.Fader:SetOption('Smooth', 0.3)
			nameplate.Fader:SetOption('Hover', true)
			--nameplate.Fader:SetOption('Power', true)
			nameplate.Fader:SetOption('Health', true)
			nameplate.Fader:SetOption('Casting', true)
		end

		nameplate.Fader:SetOption('Combat', vis.showInCombat)
		nameplate.Fader:SetOption('PlayerTarget', vis.showWithTarget)
		nameplate.Fader:SetOption('DelayAlpha', (vis.alphaDelay > 0 and vis.alphaDelay) or nil)
		nameplate.Fader:SetOption('Delay', (vis.hideDelay > 0 and vis.hideDelay) or nil)

		nameplate.Fader:ForceUpdate()
	end
end

function NP:Construct_Cutaway(nameplate)
	local frameName = nameplate:GetName()
	local Cutaway = {}

	Cutaway.Health = nameplate.Health.ClipFrame:CreateTexture(frameName .. 'CutawayHealth')
	local healthTexture = nameplate.Health:GetStatusBarTexture()
	Cutaway.Health:Point('TOPLEFT', healthTexture, 'TOPRIGHT')
	Cutaway.Health:Point('BOTTOMLEFT', healthTexture, 'BOTTOMRIGHT')

	-- Cutaway.Power = nameplate.Power.ClipFrame:CreateTexture(frameName .. 'CutawayPower')
	-- local powerTexture = nameplate.Power:GetStatusBarTexture()
	-- Cutaway.Power:Point('TOPLEFT', powerTexture, 'TOPRIGHT')
	-- Cutaway.Power:Point('BOTTOMLEFT', powerTexture, 'BOTTOMRIGHT')

	return Cutaway
end

function NP:Update_Cutaway(nameplate)
	local eitherEnabled = NP.db.cutaway.health.enabled or NP.db.cutaway.power.enabled
	if not eitherEnabled then
		if nameplate:IsElementEnabled('Cutaway') then
			nameplate:DisableElement('Cutaway')
		end
	else
		if not nameplate:IsElementEnabled('Cutaway') then
			nameplate:EnableElement('Cutaway')
		end

		nameplate.Cutaway:UpdateConfigurationValues(NP.db.cutaway)

		if NP.db.cutaway.health.forceBlankTexture then
			nameplate.Cutaway.Health:SetTexture(E.media.blankTex)
		else
			nameplate.Cutaway.Health:SetTexture(LSM:Fetch('statusbar', NP.db.statusbar))
		end

		-- if NP.db.cutaway.power.forceBlankTexture then
		-- 	nameplate.Cutaway.Power:SetTexture(E.media.blankTex)
		-- else
		-- 	nameplate.Cutaway.Power:SetTexture(LSM:Fetch('statusbar', NP.db.statusbar))
		-- end
	end
end
