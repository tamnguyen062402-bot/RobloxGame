-- LayoutController: Handles toggle/button layout and positioning
local LayoutController = {}

function LayoutController.positionsEqual(a, b)
	if not a or not b then
		return false
	end
	return a.X.Scale == b.X.Scale and a.X.Offset == b.X.Offset and a.Y.Scale == b.Y.Scale and a.Y.Offset == b.Y.Offset
end

function LayoutController.setPositionRespectingManualMove(button, desiredPos)
	if not (button and desiredPos) then
		return
	end
	if button:GetAttribute("AutoLayoutDisabled") == true then
		return
	end
	local lastApplied = button:GetAttribute("LastAppliedLayoutPosition")
	local currentPos = button.Position
	if type(lastApplied) == "string" then
		local ok, parsed = pcall(function()
			return game:GetService("HttpService"):JSONDecode(lastApplied)
		end)
		if ok and parsed then
			local lastUDim2 = UDim2.new(parsed.X.Scale, parsed.X.Offset, parsed.Y.Scale, parsed.Y.Offset)
			if not LayoutController.positionsEqual(currentPos, lastUDim2) then
				button:SetAttribute("AutoLayoutDisabled", true)
				return
			end
		end
	end
	button.Position = desiredPos
	local stored = {
		X = { Scale = desiredPos.X.Scale, Offset = desiredPos.X.Offset },
		Y = { Scale = desiredPos.Y.Scale, Offset = desiredPos.Y.Offset },
	}
	button:SetAttribute("LastAppliedLayoutPosition", game:GetService("HttpService"):JSONEncode(stored))
end

return LayoutController
