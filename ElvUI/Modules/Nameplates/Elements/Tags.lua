local E, L, V, P, G = unpack(ElvUI)
local NP = E:GetModule('NamePlates')
local LSM = E.Libs.LSM

local gsub, format, strfind, strsplit, select = gsub, format, strfind, strsplit, select
local UnitExists, UnitLevel, UnitEffectiveLevel = UnitExists, UnitLevel, UnitEffectiveLevel
local GetQuestDifficultyColor = GetQuestDifficultyColor

local legacyHealthTags = {
	{'health:current%-max%-percent%-nostatus', 'CURRENT_MAX_PERCENT'},
	{'health:current%-max%-percent', 'CURRENT_MAX_PERCENT'},
	{'health:current%-percent%-nostatus', 'CURRENT_PERCENT'},
	{'health:current%-percent', 'CURRENT_PERCENT'},
	{'health:current%-max%-nostatus', 'CURRENT_MAX'},
	{'health:current%-max', 'CURRENT_MAX'},
	{'health:percent%-nostatus', 'PERCENT'},
	{'health:percent:nostatus', 'PERCENT'},
	{'health:percent', 'PERCENT'},
	{'health:current', 'CURRENT'},
	{'health:max', 'MAX'},
	{'perhp', 'PERCENT'},
}

function NP:UsesNameOnlyLayout(nameplate, db, nameOnlySF)
	if nameOnlySF ~= nil then return nameOnlySF end
	return db.nameOnly
end

function NP:GetLegacyHealth(nameplate)
	local hb = nameplate.nameplateAnchor and nameplate.nameplateAnchor.HealthBar
	local val, mx = 0, 1
	if hb and hb.GetMinMaxValues then
		local _, maxv = hb:GetMinMaxValues()
		mx = maxv or 1
		val = hb:GetValue() or 0
	end
	if not mx or mx == 0 then mx = 1 end
	return val, mx
end

function NP:GetTagRelative(nameplate, db)
	if db.parent == 'Health' and nameplate.Health then
		return nameplate.Health
	elseif db.parent and db.parent ~= 'Nameplate' and nameplate[db.parent] then
		return nameplate[db.parent]
	end
	return nameplate
end

function NP:Construct_TagText(nameplate)
	local Text = nameplate:CreateFontString(nil, 'OVERLAY')
	Text:FontTemplate(E.LSM:Fetch('font', NP.db.font), NP.db.fontSize, NP.db.fontOutline)

	return Text
end

function NP:EvalLegacyTag(nameplate, tagFormat)
	local name = nameplate.unitName or ''
	local text = tagFormat or ''
	if text == '' then return name end

	local color = nameplate.classColor
	local hex = (color and E:RGBToHex(color.r, color.g, color.b)) or '|cffffffff'
	local abbrev = (name ~= '' and strfind(name, '%s') and E.TagFunctions.Abbrev(name)) or name

	text = gsub(text, '%[classcolor%]', hex)
	text = gsub(text, '%[name:abbrev:veryshort%]', E:ShortenString(abbrev, 5) or '')
	text = gsub(text, '%[name:abbrev:short%]', E:ShortenString(abbrev, 10) or '')
	text = gsub(text, '%[name:abbrev:medium%]', E:ShortenString(abbrev, 15) or '')
	text = gsub(text, '%[name:abbrev:long%]', E:ShortenString(abbrev, 20) or '')
	text = gsub(text, '%[name:abbrev%]', abbrev)
	text = gsub(text, '%[name:veryshort%]', E:ShortenString(name, 5) or '')
	text = gsub(text, '%[name:short%]', E:ShortenString(name, 10) or '')
	text = gsub(text, '%[name:medium%]', E:ShortenString(name, 15) or '')
	text = gsub(text, '%[name:long%]', E:ShortenString(name, 20) or '')
	text = gsub(text, '%[name:last%]', (strfind(name, '%s') and name:match('([%S]+)$')) or name)
	text = gsub(text, '%[name:first%]', (select(1, strsplit(' ', name))) or name)
	text = gsub(text, '%[name%]', name)

	local val, mx = NP:GetLegacyHealth(nameplate)
	for i = 1, #legacyHealthTags do
		local pattern, style = legacyHealthTags[i][1], legacyHealthTags[i][2]
		text = gsub(text, '%['..pattern..']', function()
			if style == 'MAX' then
				return E:GetFormattedText('CURRENT', mx, mx) or format('%.0f', mx)
			end
			return E:GetFormattedText(style, val, mx) or ''
		end)
	end

	local levelStr = '??'
	if nameplate.unit and UnitExists(nameplate.unit) then
		local level = UnitLevel(nameplate.unit)
		levelStr = (level and level > 0) and tostring(level) or '??'
	end
	text = gsub(text, '%[smartlevel%]', levelStr)
	text = gsub(text, '%[level%]', levelStr)

	local diffHex = hex
	if nameplate.unit and UnitExists(nameplate.unit) then
		local diffColor = GetQuestDifficultyColor(UnitEffectiveLevel(nameplate.unit))
		diffHex = E:RGBToHex(diffColor.r, diffColor.g, diffColor.b)
	end
	text = gsub(text, '%[difficultycolor%]', diffHex)
	text = gsub(text, '%[reactioncolor%]', hex)
	text = gsub(text, '%[classificationcolor%]', hex)

	text = gsub(text, '%[[^%]]+%]', '')
	return text
end

function NP:Update_TagText(nameplate, element, db, hide)
	if not db then return end

	if db.enable and not hide then
		element:FontTemplate(LSM:Fetch('font', db.font), db.fontSize, db.fontOutline)
		if nameplate.unit then
			nameplate:Tag(element, db.format or '')
			element:UpdateTag()
		else
			nameplate:Untag(element)
			element:SetText(NP:EvalLegacyTag(nameplate, db.format))
		end

		local relative = NP:GetTagRelative(nameplate, db)
		element:ClearAllPoints()
		element:Point(E.InversePoints[db.position] or 'CENTER', relative, db.position or 'CENTER', db.xOffset or 0, db.yOffset or 0)
		element:Show()
	else
		nameplate:Untag(element)
		element:Hide()
	end
end

function NP:Update_Tags(nameplate, nameOnlySF)
	local db = NP:PlateDB(nameplate)
	local hide = NP:UsesNameOnlyLayout(nameplate, db, nameOnlySF)

	NP:Update_TagText(nameplate, nameplate.Name, db.name)
	NP:Update_TagText(nameplate, nameplate.Title, db.title)
	NP:Update_TagText(nameplate, nameplate.Level, db.level, hide)
	NP:Update_TagText(nameplate, nameplate.Health.Text, db.health and db.health.text, hide)
	--NP:Update_TagText(nameplate, nameplate.Power.Text, db.power and db.power.text, hide)
end
