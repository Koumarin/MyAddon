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
	local lootNum = {0, 0, 0, 0, 0}    -- No of looted items/bag this update.

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

				-- If we'd put the item in a bag that is to the right of the
				-- current one, or in the current one, we just abort.
				if bagID <= bagSlot then
					break
				-- Otherwise we try to place it in the new bag.
				elseif f:CanPlaceInBag(itemLink, bagID, lootNum[bagID]) then
					-- GetContainerNumFreeSlots() doesn't seem to update
					-- inbetween calls in a single update, so we need to
					-- keep track of how much we looted this update so we put
					-- items in the correct bags.
					lootNum[bagID] = lootNum[bagID] + 1
					C_NewItems.RemoveNewItem(bagSlot, i)
					PickupContainerItem(bagSlot, i)
					PutItemInBag(newBag)
					break
				end
			end
		end
	end
end

			lootNum = lootNum + 1
		end
	end
end

function f:CanPlaceInBag(item, bagID, lootNum)
	local freeSlots  = GetContainerNumFreeSlots(bagID)
	local bagFamily  = GetItemFamily(GetBagName(bagID))
	local itemFamily = GetItemFamily(item)
	-- We check if there is free space in the bag and if the bag actually
	-- allows us to place the item we want to put in there.
	return freeSlots > lootNum
	       and (bagFamily == 0 or bit.band(bagFamily, itemFamily) ~= 0)
end

local events = {
	"ADDON_LOADED",
	"BAG_UPDATE"
}

for _, event in ipairs(events) do
	f:RegisterEvent(event)
end
f:SetScript("OnEvent", f.OnEvent)
