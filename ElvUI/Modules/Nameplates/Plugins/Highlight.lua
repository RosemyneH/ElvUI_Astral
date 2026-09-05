local E, L, V, P, G = unpack(ElvUI)
local oUF = E.oUF

local UnitExists = UnitExists
local UnitIsUnit = UnitIsUnit

local function MouseOnUnit(frame)
	if frame and frame:IsVisible() and UnitExists('mouseover') then
		return frame.unit and UnitIsUnit('mouseover', frame.unit)
	end

	return false
end

local activeHighlights = {}
local pooler = CreateFrame("Frame")
pooler:Hide()

pooler:SetScript("OnUpdate", function(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed < 0.1 then return end
	self.elapsed = 0

	for element in pairs(activeHighlights) do
		local owner = element.__owner
		if owner and owner:IsVisible() then
			if not MouseOnUnit(owner) then
				element:Hide()
				element:ForceUpdate()
				activeHighlights[element] = nil
			end
		else
			activeHighlights[element] = nil
		end
	end

	if not next(activeHighlights) then
		self:Hide()
	end
end)

local function Update(self)
	local element = self.Highlight

	if element.PreUpdate then
		element:PreUpdate()
	end

	if MouseOnUnit(self) then
		element:Show()
		activeHighlights[element] = true
		pooler:Show()
	else
		element:Hide()
		activeHighlights[element] = nil
	end

	if element.PostUpdate then
		return element:PostUpdate(element:IsShown())
	end
end

local function Path(self, ...)
	return (self.Highlight.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local element = self.Highlight
	if element then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('UPDATE_MOUSEOVER_UNIT', Path, true)

		return true
	end
end

local function Disable(self)
	local element = self.Highlight
	if element then
		element:Hide()
		activeHighlights[element] = nil

		self:UnregisterEvent('UPDATE_MOUSEOVER_UNIT', Path)
	end
end

oUF:AddElement('Highlight', Path, Enable, Disable)
