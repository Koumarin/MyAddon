local f = CreateFrame("Frame")

local bagFreeSlots = {}

function f:OnEvent(event, ...)
	self[event](self, event, ...)
end

function f:ADDON_LOADED(event, addonName)
	if addonName == "MyAddon" then
		-- Disable profanity filter.
		BNSetMatureLanguageFilter(false)
		-- We read the free slots in each bag, so we can keep track of
		-- new items and place looted bags, and so on.
		for i = 0, 4, 1 do
			bagFreeSlots[i] = GetContainerFreeSlots(i)
		end
	end
end

function f:BAG_UPDATE(event, bagSlot)
	local lootNum = {0, 0, 0, 0, 0}    -- No of looted items/bag this update.

	if bagFreeSlots[bagSlot] then
		wipe(bagFreeSlots[bagSlot])
	end
	bagFreeSlots[bagSlot] = GetContainerFreeSlots(bagSlot)
	-- If the bag that received an update is a profession bag, we know that
	-- the item is in its correct place. Profession bags have higher priority.
	if f:IsProfessionBag(bagSlot) then
		return
	end

	if CursorHasItem() or SpellIsTargeting() then
		print("Cursor busy, can't loot to leftmost.")
		return
	end

	for i = 0, GetContainerNumSlots(bagSlot), 1 do
		if C_NewItems.IsNewItem(bagSlot, i) then
			local itemLink = select(7, GetContainerItemInfo(bagSlot, i))
			local itemID   = GetContainerItemID(bagSlot, i)
			C_NewItems.RemoveNewItem(bagSlot, i)

			-- If we looted a bag, we don't want to place in a bagSlot, or it
			-- will try to equip the bag.
			if f:IsBag(itemID) then
				--
			else
				for newBag = 23, 20, -1 do
					local bagID = newBag - 19
					-- If we'd put the item in a bag that is to the right of
					-- the current one, or in the current one, we just abort.
					if bagID <= bagSlot then
						break
					-- Otherwise we try to place it in the new bag.
					elseif f:CanPlaceInBag(itemID, bagID, lootNum[bagID]) then
						-- GetContainerNumFreeSlots() doesn't seem to update
						-- inbetween calls in a single update, so we need to
						-- keep track of how much we looted this update so we
						-- put items in the correct bags.
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
end

function f:CanPlaceInBag(item, bagID, lootNum)
	local freeSlots  = GetContainerNumFreeSlots(bagID)
	local bagFamily  = f:GetBagItemFamily(bagID)
	local itemFamily = GetItemFamily(item)
	-- We check if there is free space in the bag and if the bag actually
	-- allows us to place the item we want to put in there.
	return freeSlots > lootNum
	       and (bagFamily == 0 or bit.band(bagFamily, itemFamily) ~= 0)
end

function f:IsBag(itemID)
	return "INVTYPE_BAG" == select(9, GetItemInfo(itemID))
end

function f:IsProfessionBag(bagID)
	return 0 ~= f:GetBagItemFamily(bagID)
end

function f:ElementInTable(element, table)
	for _, value in ipairs(table) do
		if value == element then
			return true
		end
	end
	return false
end

function f:GetBagItemFamily(bagID)
	if bagID == 0 then
		return 0
	end
	local invID  = ContainerIDToInventoryID(bagID)
	local itemID = GetInventoryItemID("player", invID)
	return GetItemFamily(itemID)
end

local events = {
	"ADDON_LOADED",
	"BAG_UPDATE"
}

for _, event in ipairs(events) do
	f:RegisterEvent(event)
end
f:SetScript("OnEvent", f.OnEvent)
