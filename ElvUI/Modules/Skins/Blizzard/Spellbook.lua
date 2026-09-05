local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins")

--Lua functions
local _G = _G
local unpack = unpack
--WoW API / Variables
--local SpellBook_GetCurrentPage = SpellBook_GetCurrentPage
--local BOOKTYPE_SPELL = BOOKTYPE_SPELL
local MAX_SKILLLINE_TABS = MAX_SKILLLINE_TABS

S:AddCallback("Skin_Spellbook", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.spellbook then return end
	if not _G.AscensionSpellbookFrame then return end

	-- AscensionSpellbook
	AscensionSpellbookFrame:SetWidth(580)
	AscensionSpellbookFrameNineSlice:StripTextures(true)
	AscensionSpellbookFrameNineSlice:EnableMouse(false)
	AscensionSpellbookFrameNineSlice:SetFrameLevel(1)
	AscensionSpellbookFrame:StripTextures(true)
	AscensionSpellbookFramePortraitFrame:StripTextures(true)
	AscensionSpellbookFrameInsetNineSlice:StripTextures(true)
	AscensionSpellbookFrameInsetNineSlice:EnableMouse(false)
	AscensionSpellbookFrameInsetNineSlice:SetFrameLevel(1)
	AscensionSpellbookFrame:CreateBackdrop("Transparent")

	AscensionSpellbookFrame:RegisterForDrag("LeftButton")
	AscensionSpellbookFrame:SetMovable(true)
	AscensionSpellbookFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
	AscensionSpellbookFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

	for i = 1, 3 do
		local tab = _G["AscensionSpellbookFrameTab"..i]
		tab:Size(122, 32)
		tab:GetRegions():SetPoint("CENTER", 0, 2)
		S:HandleTab(tab)
	end

	AscensionSpellbookFrameTab1:Point("CENTER", AscensionSpellbookFrame, "BOTTOMLEFT", 72, 62)
	AscensionSpellbookFrameTab2:Point("LEFT", AscensionSpellbookFrameTab1, "RIGHT", -15, 0)
	AscensionSpellbookFrameTab3:Point("LEFT", AscensionSpellbookFrameTab2, "RIGHT", -15, 0)

	S:HandleNextPrevButton(AscensionSpellbookFramePreviousPageButton, nil, nil, true)
	S:HandleNextPrevButton(AscensionSpellbookFrameNextPageButton, nil, nil, true)

	S:HandleCloseButton(AscensionSpellbookFrameCloseButton)

	S:HandleCheckBox(AscensionSpellbookFrameContentSpellsShowAllSpellRanks)
	
	S:HandleEditBox(AscensionSpellbookFrameContentSpellsSearch)

	for i = 1, SPELLS_PER_PAGE do
		local button = _G["AscensionSpellbookFrameContentSpellsSpellButton"..i]
		local autoCast = _G["AscensionSpellbookFrameContentSpellsSpellButton"..i.."AutoCastable"]
		button:StripTextures()
		button:CreateBackdrop("Default", true)

		autoCast:SetTexture("Interface\\Buttons\\UI-AutoCastableOverlay")
		autoCast:SetOutside(button, 16, 16)

		_G["AscensionSpellbookFrameContentSpellsSpellButton"..i.."IconTexture"]:SetTexCoord(unpack(E.TexCoords))

		E:RegisterCooldown(_G["AscensionSpellbookFrameContentSpellsSpellButton"..i.."Cooldown"])
	end

	hooksecurefunc("SpellButton_UpdateButton", function(self)
		local name = self:GetName()
		if name then
			local spellName = _G[name.."SpellName"]
			if spellName then
				spellName:SetTextColor(1, 0.80, 0.10)
				spellName:SetWidth(180)
			end
			local subSpellName = _G[name.."SubSpellName"]
			if subSpellName then
				subSpellName:SetTextColor(1, 1, 1)
			end
			local highlight = _G[name.."Highlight"]
			if highlight then
				highlight:SetTexture(1, 1, 1, 0.3)
			end
		end
	end)

	for i = 1, MAX_SKILLLINE_TABS do
		local tab = _G["AscensionSpellbookFrameSideBarTab"..i]

		tab:StripTextures()
		tab:StyleButton(nil, true)
		tab:SetTemplate("Default", true)

		tab:GetNormalTexture():SetInside()
		tab:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
	end

	SpellBookPageText:SetTextColor(1, 1, 1)

	--Professions
	AscensionSpellbookFrameContentProfessions:StripTextures(true)

	local function GetProfessionNameFromButton(button)
		if not button then return nil end
		if button.profName and button.profName ~= "" then return button.profName end
		if button.name and type(button.name) == "string" and button.name ~= "" then return button.name end
		if button.Name and button.Name.GetText then
			local t = button.Name:GetText()
			if t and t ~= "" then return t end
		end
		for i = 1, button:GetNumRegions() do
			local region = select(i, button:GetRegions())
			if region and region:GetObjectType() == "FontString" then
				local text = region:GetText()
				if text and text ~= "" and not text:find("^%d+/%d+$") and text ~= "Apprentice" and text ~= "Journeyman" and text ~= "Expert" and text ~= "Artisan" and text ~= "Master" and text ~= "Grand Master" then
					return text
				end
			end
		end
		return nil
	end

	local function FixProfessionTooltip(tt)
		local owner = tt:GetOwner()
		if owner and owner:GetParent() then
			local parent = owner:GetParent()
			if parent == AscensionSpellbookFrameContentProfessions or (parent:GetParent() and parent:GetParent() == AscensionSpellbookFrameContentProfessions) then
				local profFrame = (parent == AscensionSpellbookFrameContentProfessions) and owner or parent
				if profFrame and profFrame.AbandonButton and owner ~= profFrame.AbandonButton then
					tt:ClearAllPoints()
					tt:SetPoint("TOPLEFT", AscensionSpellbookFrame, "TOPRIGHT", 10, 0)
				end
			end
		end
	end

	hooksecurefunc(GameTooltip, "SetOwner", FixProfessionTooltip)
	GameTooltip:HookScript("OnUpdate", FixProfessionTooltip)

	for _, button in ipairs(AscensionSpellbookFrameContentProfessions.professionButtons) do
		local hl = button:GetHighlightTexture()
		if hl then
			hl:SetTexture(E.media.blankTex)
			hl:SetVertexColor(1, 1, 1, 0.2)
			hl:ClearAllPoints()
			hl:SetAllPoints(button.Icon)
		end
		if button.Highlight and button.Highlight ~= hl then
			button.Highlight:SetTexture(nil)
		end

		if button.AbandonButton then
			S:HandleCloseButton(button.AbandonButton)
			button.AbandonButton:SetHitRectInsets(0, 0, 0, 0)
			button.AbandonButton:SetFrameStrata("HIGH")
			button.AbandonButton:SetFrameLevel(200)
			button.AbandonButton:EnableMouse(true)
			button.AbandonButton:RegisterForClicks("AnyUp")
			button.AbandonButton:HookScript("OnEnter", function(self)
				local parent = self:GetParent()
				local name = GetProfessionNameFromButton(parent) or GetProfessionNameFromButton(self)
				GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
				if name and name ~= "" then
					GameTooltip:SetText(format("Unlearn %s", name), 1, 1, 1)
				else
					GameTooltip:SetText("Unlearn Profession", 1, 1, 1)
				end
				GameTooltip:Show()
			end)
			button.AbandonButton:HookScript("OnLeave", function(self)
				GameTooltip:Hide()
			end)
		end

		hooksecurefunc(button, "SetProfession", function(button, skillID)
			local profName, _, icon = ProfessionUtil.GetProfessionByID(skillID)
			button.profName = profName
			button.skillID = skillID
			if button.AbandonButton then
				button.AbandonButton.profName = profName
				button.AbandonButton.skillID = skillID
			end
			button.Icon:SetTexture(icon)
			button.Icon:SetTexCoord(unpack(E.TexCoords))

			for extraButton in button.ExtraButtonPool:EnumerateActive() do
				local extraIcon = select(3, GetSpellInfo(extraButton.spellID))
				extraButton.Icon:SetTexture(extraIcon)
				extraButton.Icon:SetTexCoord(unpack(E.TexCoords))
				extraButton.IconBorder:StripTextures()
				if extraButton.Highlight then extraButton.Highlight:StripTextures() end
			end

			if button:IsEnabled() == 0 then
				button.Icon:SetAlpha(0.7)
    			button.Icon:SetDesaturated(true)
			else
				button.Icon:SetAlpha(1)
    			button.Icon:SetDesaturated(false)
			end
		end)
		S:HandleIcon(button.Icon)
		button.IconBorder:StripTextures()
		S:HandleStatusBar(button.ProgressBar)
		button.ProgressBar.RankText:SetPoint("CENTER", 0, 0)
	end

	-- Pet Tab
	AscensionSpellbookFrameContentPetSpells:StripTextures(true)
	AscensionSpellbookFrameContentPetSpells:CreateBackdrop("Transparent")

	for i = 1, 12 do
		local button = _G["AscensionSpellbookFrameContentPetSpellsSpellButton"..i]
		button:StripTextures()
		button:CreateBackdrop("Default", true)

		_G["AscensionSpellbookFrameContentPetSpellsSpellButton"..i.."IconTexture"]:SetTexCoord(unpack(E.TexCoords))

		E:RegisterCooldown(_G["AscensionSpellbookFrameContentPetSpellsSpellButton"..i.."Cooldown"])
	end
end)