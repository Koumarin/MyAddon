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

	if bagSlot > 5 then                -- Slots greater than 5 are bank bags,
		return                         -- which we ignore;
	elseif f:IsProfessionBag(bagSlot) then -- if our item is in a profession
		return                             -- bag, it's in the correct place;
	elseif CursorHasItem() or SpellIsTargeting() then -- And if our cursor is
		print("Cursor busy, can't loot to leftmost.") -- is busy, we cannot do
		return                                        -- anything.
	end

	for i = 0, GetContainerNumSlots(bagSlot), 1 do
		if C_NewItems.IsNewItem(bagSlot, i) then
			local itemLink = select(7, GetContainerItemInfo(bagSlot, i))
			local itemID   = GetContainerItemID(bagSlot, i)
			C_NewItems.RemoveNewItem(bagSlot, i)

			-- If the new item isn't in a previously free slot, we know it was
			-- looted to a pre-existing stack, so we keep it where it is.
			if not tContains(bagFreeSlots[bagSlot], i) then
				--
			-- If we looted a bag, we don't want to place in a bagSlot, or it
			-- will try to equip the bag.
			elseif f:IsBag(itemID) then
				--
			else
				for newBag = 4, 1, -1 do
					local invID = ContainerIDToInventoryID(newBag)
					-- If we'd put the item in a bag that is to the right of
					-- the current one, or in the current one, we just abort.
					if newBag <= bagSlot then
						break
					-- Otherwise we try to place it in the new bag.
					elseif f:CanPlaceInBag(itemID, newBag, lootNum[newBag]) then
						-- GetContainerNumFreeSlots() doesn't seem to update
						-- inbetween calls in a single update, so we need to
						-- keep track of how much we looted this update so we
						-- put items in the correct bags.
						lootNum[newBag]      = lootNum[newBag] + 1
						lootNum[bagSlot + 1] = lootNum[bagSlot + 1] - 1
						C_NewItems.RemoveNewItem(bagSlot, i)
						PickupContainerItem(bagSlot, i)
						PutItemInBag(invID)
						break
					end
				end
			end
		end
	end

	f:UpdateBagFreeSlots(bagSlot)
	-- If the bag that received an update is a profession bag, we know that
	-- the item is in its correct place. Profession bags have higher priority.
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

function f:GetBagItemFamily(bagID)
	if bagID == 0 then
		return 0
	end
	local invID  = ContainerIDToInventoryID(bagID)
	local itemID = GetInventoryItemID("player", invID)
	return GetItemFamily(itemID)
end

function f:UpdateBagFreeSlots(bagID)
	if bagFreeSlots[bagID] then
		wipe(bagFreeSlots[bagID])
	end
	bagFreeSlots[bagID] = GetContainerFreeSlots(bagID)
end

local events = {
	"ADDON_LOADED",
	"BAG_UPDATE"
}

for _, event in ipairs(events) do
	f:RegisterEvent(event)
end
f:SetScript("OnEvent", f.OnEvent)
