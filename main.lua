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
	if CursorHasItem() or SpellIsTargeting() then
		print("Cursor busy, can't loot to leftmost.")
		return
	end

	for i = 0, GetContainerNumSlots(bagSlot), 1 do
		if C_NewItems.IsNewItem(bagSlot, i) then
			--print("Looted:", select(7, GetContainerItemInfo(bagSlot, i)), ".")

			for newBag = 23, 20, -1 do
				--print("Looking at bag:", newBag)
				if select(1, GetContainerNumFreeSlots(newBag - 19)) > 0 then
					--print("Found free bag for it:", newBag)
					C_NewItems.RemoveNewItem(bagSlot, i)
					PickupContainerItem(bagSlot, i)
					PutItemInBag(newBag)
					return
				end
			end
		end
	end
end

local events = {
	"ADDON_LOADED",
	"BAG_UPDATE"
}

for _, event in ipairs(events) do
	f:RegisterEvent(event)
end
f:SetScript("OnEvent", f.OnEvent)
