local f = CreateFrame("Frame")

function f:OnEvent(event, ...)
	self[event](self, event, ...)
end

function f:ADDON_LOADED(event, addonName)
	if addonName == "MyAddon" then
		-- Disable profanity filter.
		BNSetMatureLanguageFilter(false)
	end
end

function f:BAG_UPDATE(event, bagSlot)
	local lootNum = 0                  -- Number of looted items this update.

	if CursorHasItem() or SpellIsTargeting() then
		print("Cursor busy, can't loot to leftmost.")
		return
	end

	for i = 0, GetContainerNumSlots(bagSlot), 1 do
		if C_NewItems.IsNewItem(bagSlot, i) then
			local itemLink = select(7, GetContainerItemInfo(bagSlot, i))
			C_NewItems.RemoveNewItem(bagSlot, i)
			print("Looted:", itemLink, ".")

			for newBag = 23, 20, -1 do
				local bagID = newBag - 19
				--print("Looking at bag:", newBag)
				-- If we'd put the item in a bag that is to the right of the
				-- current one, just abort.
				if bagID < bagSlot then
					break
				-- Otherwise we check if the bag has free slots to put
				-- the new item in.
				elseif f:CanPlaceInBag(itemLink, bagID, lootNum) then
					C_NewItems.RemoveNewItem(bagSlot, i)
					PickupContainerItem(bagSlot, i)
					PutItemInBag(newBag)
					break
				end
			end

			lootNum = lootNum + 1
		end
	end
end

function f:CanPlaceInBag(item, bagID, lootNum)
	local freeSlots, itemFamily = GetContainerNumFreeSlots(bagID)
	return freeSlots > lootNum and bit.band(itemFamily, GetItemFamily(item))
end

local events = {
	"ADDON_LOADED",
	"BAG_UPDATE"
}

for _, event in ipairs(events) do
	f:RegisterEvent(event)
end
f:SetScript("OnEvent", f.OnEvent)
