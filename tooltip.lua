local lineAdded = false
local function OnTooltipSetItem(tooltip, ...)
	-- Make sure we don't append our line twice.
	if not lineAdded then
		local name, linkA = tooltip:GetItem()
		local amt  = 0
		-- Search bag for stacks of the same item.
		for bag = 0, 4, 1 do
			for slot = 0, GetContainerNumSlots(bag), 1 do
				stack = select(2, GetContainerItemInfo(bag, slot))
				linkB = select(7, GetContainerItemInfo(bag, slot))
				if stack and linkA == linkB then
					amt = amt + stack
				end
			end
		end
		tooltip:AddLine("Total in bag: "..amt, 1, 1, 1)
		tooltip:Show()
		lineAdded = true
	end
end

local function OnTooltipCleared(tooltip, ...)
	lineAdded = false
end

GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
