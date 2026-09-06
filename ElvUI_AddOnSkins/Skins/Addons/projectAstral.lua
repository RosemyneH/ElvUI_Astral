local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")
local AS = E:GetModule("AddOnSkins")

if not AS:IsAddonLODorEnabled("ProjectAstral") then return end

local _G = _G
local unpack, pairs, ipairs, type, getmetatable = unpack, pairs, ipairs, type, getmetatable
local upper = string.upper
local GetItemQualityColor = GetItemQualityColor
local hooksecurefunc = hooksecurefunc

local function MediaColor()
	local vr, vg, vb = unpack(E.media.rgbvaluecolor)
	local br, bg, bb = unpack(E.media.bordercolor)
	local dr, dg, db, da = unpack(E.media.backdropfadecolor)
	local pr, pg, pb = unpack(E.media.backdropcolor)
	return {
		bgDeep    = {dr, dg, db, da},
		bgPanel   = {pr, pg, pb, 1},
		bgRowAlt  = {pr, pg, pb, 0.35},
		bgHover   = {vr, vg, vb, 0.15},
		borderDim  = {br, bg, bb, 1},
		borderMid  = {br, bg, bb, 1},
		borderHot  = {vr, vg, vb, 1},
		textTitle    = {1, 1, 1},
		textPrimary  = {0.9, 0.9, 0.9},
		textMuted    = {0.6, 0.6, 0.6},
		textAccent   = {vr, vg, vb},
		textHi       = {1, 1, 1},
		textGood     = {0.3, 1, 0.3},
		textBad      = {1, 0.2, 0.2},
		textWarn     = {1, 0.8, 0.1},
		accent       = {vr, vg, vb},
		accentSoft   = {vr, vg, vb},
	}
end

local function ApplyFont(fs, size)
	if fs and fs.FontTemplate then
		fs:FontTemplate(nil, size or 12, "OUTLINE")
	end
end

local function BorderAPI(frame)
	local idx = getmetatable(frame) and getmetatable(frame).__index
	if type(idx) ~= "table" then return end
	return idx.SetBackdropBorderColor, idx.SetBackdropColor
end

local function LockTemplate(frame, template)
	if not frame or not frame.SetTemplate then return end
	frame:SetTemplate(template or "Transparent")
	local _, origColor = BorderAPI(frame)
	if origColor then
		frame.SetBackdropColor = function(self)
			if template == "Transparent" then
				origColor(self, unpack(E.media.backdropfadecolor))
			else
				origColor(self, unpack(E.media.backdropcolor))
			end
		end
	end
end

local function ApplyHover(frame, opts)
	if not frame or frame.__elvPAHover then return end
	frame.__elvPAHover = true
	frame:EnableMouse(true)

	local setBorder = BorderAPI(frame)
	local hl = frame:CreateTexture(nil, "OVERLAY")
	hl:SetTexture(E.media.blankTex)
	hl:SetAllPoints()
	hl:SetBlendMode("ADD")
	hl:SetAlpha(0)
	frame.__elvPAHighlight = hl

	frame:HookScript("OnEnter", function(self)
		if setBorder then setBorder(self, unpack(E.media.rgbvaluecolor)) end
		hl:SetVertexColor(unpack(E.media.rgbvaluecolor))
		hl:SetAlpha((opts and opts.alpha) or 0.35)
		if self.text and not self.__elvPA_selected then
			self.text:SetTextColor(unpack(E.media.rgbvaluecolor))
		end
	end)
	frame:HookScript("OnLeave", function(self)
		if setBorder then
			if self.__elvPA_selected then
				setBorder(self, unpack(E.media.rgbvaluecolor))
			else
				setBorder(self, unpack(E.media.bordercolor))
			end
		end
		hl:SetAlpha(0)
		if self.text then
			if self.__elvPA_selected then
				self.text:SetTextColor(unpack(E.media.rgbvaluecolor))
			else
				self.text:SetTextColor(1, 1, 1)
			end
		end
	end)
end

S:AddCallbackForAddon("ProjectAstral", "ProjectAstral", function()
	if not E.private.addOnSkins.ProjectAstral then return end

	local PA = _G.ProjectAstral
	if not PA or not PA.UI then return end
	local UI = PA.UI

	UI.Color = MediaColor()
	UI.CosmicCorners = E.noop
	UI.AddStarfield = E.noop
	UI.AddInnerGlow = E.noop
	UI.PulseChip = E.noop

	function UI.AstralBackdrop(frame)
		if not frame then return end
		if frame.StripTextures then frame:StripTextures() end
		LockTemplate(frame, "Transparent")
	end

	function UI.CosmicButton(b)
		if not b or b.isSkinned then return end
		S:HandleButton(b, true)
		ApplyHover(b)
		local fs = b.GetFontString and b:GetFontString()
		ApplyFont(fs, 12)
	end

	function UI.CosmicCloseButton(btn)
		if not btn then return end
		S:HandleCloseButton(btn)
		btn:SetScript("OnClick", function(self)
			local parent = self:GetParent()
			if parent and parent.AnimatedHide then
				parent:AnimatedHide()
			elseif parent then
				parent:Hide()
			end
		end)
	end

	function UI.MakeButton(parent, label, opts)
		opts = opts or {}
		local b = CreateFrame("Button", nil, parent)
		b:SetSize(opts.w or 160, opts.h or 22)
		S:HandleButton(b, true)
		ApplyHover(b)

		local txt = b:CreateFontString(nil, "OVERLAY")
		ApplyFont(txt, 12)
		txt:SetPoint("CENTER")
		txt:SetText(label or "")
		b.text = txt

		if opts.onClick then b:SetScript("OnClick", opts.onClick) end

		function b:SetDisabledLook(off)
			self._disabled = off
			if off then
				self:Disable()
				self.text:SetTextColor(0.5, 0.5, 0.5)
			else
				self:Enable()
				self.text:SetTextColor(1, 1, 1)
			end
		end

		function b:SetLabel(s)
			self.text:SetText(s)
		end

		return b
	end

	function UI.MakeHeader(frame, title, subtitle)
		local h = CreateFrame("Frame", nil, frame)
		h:SetHeight(40)
		h:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
		h:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)

		local t = h:CreateFontString(nil, "OVERLAY")
		ApplyFont(t, 16)
		t:SetPoint("TOPLEFT", h, "TOPLEFT", 4, -2)
		t:SetText(title or "")
		t:SetTextColor(1, 1, 1)
		h.title = t

		if subtitle and subtitle ~= "" then
			local s = h:CreateFontString(nil, "OVERLAY")
			ApplyFont(s, 11)
			s:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -2)
			s:SetText(subtitle)
			s:SetTextColor(unpack(E.media.rgbvaluecolor))
			h.subtitle = s
		end

		local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
		closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
		UI.CosmicCloseButton(closeBtn)
		h.closeBtn = closeBtn

		return h
	end

	function UI.MakeFooter(frame, opts)
		opts = opts or {}
		local f = CreateFrame("Frame", nil, frame)
		f:SetHeight(22)
		f:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 6)
		f:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 6)
		f.text = f:CreateFontString(nil, "OVERLAY")
		ApplyFont(f.text, 11)
		f.text:SetPoint("LEFT")
		f.text:SetTextColor(0.6, 0.6, 0.6)
		f.text:SetText(opts.text or "")
		return f
	end

	function UI.MakeSectionLabel(parent, text, opts)
		opts = opts or {}
		local host = CreateFrame("Frame", nil, parent)
		host:SetHeight(16)

		local label = host:CreateFontString(nil, "OVERLAY")
		ApplyFont(label, 11)
		label:SetPoint("LEFT", host, "LEFT", 0, 0)
		label:SetText(upper(text or ""))
		label:SetTextColor(unpack(E.media.rgbvaluecolor))
		host.label = label

		function host:SetText(s)
			self.label:SetText(upper(s or ""))
		end
		return host
	end

	function UI.MakeStatBox(parent, w, h, label)
		local box = CreateFrame("Frame", nil, parent)
		box:SetSize(w or 160, h or 48)
		LockTemplate(box, "Transparent")

		local lbl = box:CreateFontString(nil, "OVERLAY")
		ApplyFont(lbl, 10)
		lbl:SetPoint("TOP", 0, -6)
		lbl:SetText(label or "")
		lbl:SetTextColor(0.6, 0.6, 0.6)

		local val = box:CreateFontString(nil, "OVERLAY")
		ApplyFont(val, 16)
		val:SetPoint("BOTTOM", 0, 8)
		val:SetText("--")
		val:SetTextColor(1, 1, 1)

		box.label = lbl
		box.value = val
		ApplyHover(box, { alpha = 0.22 })
		return box
	end

	function UI.MakeChip(parent, label, value)
		local c = CreateFrame("Frame", nil, parent)
		c:SetHeight(20)
		LockTemplate(c, "Default")

		local txt = c:CreateFontString(nil, "OVERLAY")
		ApplyFont(txt, 11)
		txt:SetPoint("CENTER")
		if value ~= nil then
			txt:SetText(label.."  "..tostring(value))
		else
			txt:SetText(label)
		end
		c.text = txt

		local minW, pad = 54, 16
		c:SetWidth(math.max(minW, txt:GetStringWidth() + pad))
		function c:SetText(s)
			self.text:SetText(s)
			self:SetWidth(math.max(minW, self.text:GetStringWidth() + pad))
		end
		ApplyHover(c, { alpha = 0.25 })
		return c
	end

	function UI.MakeSearchBox(parent, opts)
		opts = opts or {}
		local w = opts.width or 160
		local h = opts.height or 20

		local container = CreateFrame("Frame", nil, parent)
		container:SetSize(w, h)

		local edit = CreateFrame("EditBox", nil, container)
		edit:SetPoint("TOPLEFT", 4, 0)
		edit:SetPoint("BOTTOMRIGHT", -4, 0)
		edit:SetAutoFocus(false)
		edit:SetMaxLetters(48)
		ApplyFont(edit, 12)
		S:HandleEditBox(edit)

		local ghost = container:CreateFontString(nil, "OVERLAY")
		ApplyFont(ghost, 11)
		ghost:SetPoint("LEFT", edit, "LEFT", 6, 0)
		ghost:SetText(opts.placeholder or "Search...")
		ghost:SetTextColor(0.5, 0.5, 0.5)

		local function refreshGhost()
			if edit:HasFocus() or (edit:GetText() or "") ~= "" then
				ghost:Hide()
			else
				ghost:Show()
			end
		end

		edit:SetScript("OnEditFocusGained", refreshGhost)
		edit:SetScript("OnEditFocusLost", refreshGhost)
		edit:SetScript("OnEscapePressed", function(self)
			self:SetText("")
			self:ClearFocus()
			refreshGhost()
			if opts.onChanged then opts.onChanged("") end
		end)
		edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
		edit:SetScript("OnTextChanged", function(self)
			refreshGhost()
			if opts.onChanged then opts.onChanged(self:GetText() or "") end
		end)

		container.edit = edit
		function container:GetText() return edit:GetText() or "" end
		function container:SetText(s) edit:SetText(s or ""); refreshGhost() end
		function container:Clear() edit:SetText(""); refreshGhost() end
		function container:ResetPlaceholder() refreshGhost() end
		ApplyHover(edit.backdrop or container, { alpha = 0.2 })
		return container
	end

	function UI.MakeIconFrame(parent, opts)
		opts = opts or {}
		local size = opts.size or 26
		local f = CreateFrame("Frame", nil, parent)
		f:SetSize(size, size)
		LockTemplate(f, "Default")

		local icon = f:CreateTexture(nil, "OVERLAY")
		icon:SetInside(f)
		icon:SetTexCoord(unpack(E.TexCoords))
		f.icon = icon
		f.ring = icon

		function f:SetTexture(path)
			self.icon:SetTexture(path or "Interface\\Icons\\INV_Misc_QuestionMark")
		end
		function f:SetQuality(q)
			local r, g, b = GetItemQualityColor(q or 1)
			local idx = getmetatable(self) and getmetatable(self).__index
			if idx and idx.SetBackdropBorderColor then
				idx.SetBackdropBorderColor(self, r, g, b)
			end
		end
		f:SetTexture()
		ApplyHover(f, { alpha = 0.28 })
		return f
	end

	function UI.MakeTabBar(parent, tabs, onSelect, opts)
		opts = opts or {}
		local bar = CreateFrame("Frame", nil, parent)
		bar.buttons = {}
		bar.activeId = nil
		local ROW_H = 24

		for i, t in ipairs(tabs) do
			local row = CreateFrame("Button", nil, bar)
			row:SetHeight(ROW_H)
			if opts.bottomAnchor then
				row:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, (i - 1) * (ROW_H + 1))
				row:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, (i - 1) * (ROW_H + 1))
			else
				row:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, -((i - 1) * (ROW_H + 1)))
				row:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, -((i - 1) * (ROW_H + 1)))
			end
			row:SetTemplate("Default", true)
			row:RegisterForClicks("AnyUp")
			ApplyHover(row)

			local lbl = row:CreateFontString(nil, "OVERLAY")
			ApplyFont(lbl, 12)
			lbl:SetPoint("LEFT", 8, 0)
			lbl:SetText(t.label)
			row.text = lbl
			row.id = t.id
			row.hl = { SetAlpha = E.noop }
			row.active = { SetAlpha = E.noop }
			row.marker = { SetAlpha = E.noop }
			row.chevron = { SetAlpha = E.noop, SetTextColor = E.noop }

			row:SetScript("OnClick", function(self)
				bar:SelectTab(self.id)
				if onSelect then onSelect(self.id) end
			end)

			bar.buttons[t.id] = row
		end

		function bar:SelectTab(id)
			self.activeId = id
			for tid, b in pairs(self.buttons) do
				b.__elvPA_selected = tid == id
				if tid == id then
					b:SetBackdropBorderColor(unpack(E.media.rgbvaluecolor))
					b.text:SetTextColor(unpack(E.media.rgbvaluecolor))
				else
					b:SetBackdropBorderColor(unpack(E.media.bordercolor))
					b.text:SetTextColor(1, 1, 1)
				end
			end
		end

		return bar
	end

	function UI.MakeRowChrome(row)
		if not row then return row end
		row:SetTemplate("Transparent")
		ApplyHover(row)
		return row
	end

	local function SkinPAText(fs, size)
		if not fs then return end
		ApplyFont(fs, size or 12)
		if fs.SetShadowColor then
			fs:SetShadowColor(0, 0, 0, 1)
			fs:SetShadowOffset(1, -1)
		end
	end

	local origGainPopup = UI.GainPopup
	if origGainPopup then
		UI.GainPopup = function(text, kind, opts)
			local f = origGainPopup(text, kind, opts)
			if f then
				if f.SetTemplate then f:SetTemplate("Transparent") end
				SkinPAText(f.label, (opts and opts.fontSize) or 12)
				if f.label then f.label:SetTextColor(1, 1, 1) end
			end
			return f
		end
		UI.Toast = UI.GainPopup
	end

	local origLoading = UI.MakeLoadingOverlay
	if origLoading then
		UI.MakeLoadingOverlay = function(parent, opts)
			local o = origLoading(parent, opts)
			if o then
				if o.SetTemplate then o:SetTemplate("Transparent") end
				SkinPAText(o.label, 16)
				if o.label then o.label:SetTextColor(unpack(E.media.rgbvaluecolor)) end
			end
			return o
		end
	end

	local function IsAstralPopup(which)
		if type(which) ~= "string" then return false end
		return which:find("^PA_") or which:find("^AT_") or which:find("^ASTRAL_")
			or which:find("^TRANSMOG") or which:find("^NO_ITEM")
	end

	hooksecurefunc("StaticPopup_Show", function(which)
		if not IsAstralPopup(which) then return end
		for i = 1, 4 do
			local frame = _G["StaticPopup"..i]
			if frame and frame:IsShown() and frame.which == which then
				if frame.SetTemplate then frame:SetTemplate("Transparent") end
				SkinPAText(_G["StaticPopup"..i.."Text"], 12)
				local text = _G["StaticPopup"..i.."Text"]
				if text then text:SetTextColor(1, 1, 1) end
				for j = 1, 3 do
					local btn = _G["StaticPopup"..i.."Button"..j]
					if btn then
						if not btn.isSkinned then S:HandleButton(btn) end
						SkinPAText(btn:GetFontString(), 12)
					end
				end
				local edit = _G["StaticPopup"..i.."EditBox"]
				if edit then ApplyFont(edit, 12) end
			end
		end
	end)

	if _G.PAMainMenuFrame then
		UI.AstralBackdrop(_G.PAMainMenuFrame)
		if _G.PAMainMenuFrame.sidebar then
			UI.AstralBackdrop(_G.PAMainMenuFrame.sidebar)
		end
	end

	local mini = _G.PAMinimapButton
	if mini and not mini.__elvPA then
		mini.__elvPA = true
		mini:SetTemplate("Default")
		local icon = mini:GetRegions()
		if icon and icon.SetTexCoord then
			icon:SetTexCoord(unpack(E.TexCoords))
			if icon.SetInside then icon:SetInside() end
		end
	end
end)
