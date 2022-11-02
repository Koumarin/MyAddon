local F = CreateFrame("Frame")

function CallRandomMount(mountType)
	local M  = {}                        -- List of our mounts.
	local sz = GetNumCompanions("MOUNT") -- Number of mounts we have.

	for i = 1, sz do M[i] = i end      -- Fill list with mounts.

	-- Creates a predicate that returns true for mounts of matching type.
	local p = function(type)
		return function(elt)
			local eltType = select(6, GetCompanionInfo("MOUNT", elt))
			return 0 ~= bit.band(eltType, type)
		end
	end

	if mountType then                  -- If player is asking for a specific
		M = F:Filter(M, p(mountType))  -- mount type, look for that type.
	elseif F:CanFly() then             -- Otherwise, if we can fly,
		M = F:Filter(M, p(0x2))        -- we take only flying mounts.
	elseif IsSubmerged() then          -- If we are underwater,
		M = F:Filter(M, p(0x8))        -- we take only water mounts.
	else
		M = F:Filter(M, function(elt)
			local eltType = select(6, GetCompanionInfo("MOUNT", elt))
			return 0 == bit.band(0x2, eltType) -- Take NOT flying mounts.
		end)
	end

	CallCompanion("MOUNT", M[random(#M)])
end

function F:CanFly()
	-- 34090 is Expert Riding.
	return FindSpellBookSlotBySpellID(34090) and IsFlyableArea()
end

function F:Filter(A, p)
	local B  = {} -- New array.

	for _, x in ipairs(A) do
		if p(x) then                   -- If x satisfies predicate p,
			table.insert(B, x)         -- we insert x into B.
		end
	end

	return B
end
