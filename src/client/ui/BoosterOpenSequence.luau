local BoosterOpenSequence = {}

local function getBoosterSlotPosition(index, maxCards, cardWidth, cardHeight)
	local cols = 5
	local rows = math.max(1, math.ceil(maxCards / cols))
	local col = (index - 1) % cols
	local row = math.floor((index - 1) / cols)
	local gapX = 14
	local gapY = 16
	local gridWidth = (cols * cardWidth) + ((cols - 1) * gapX)
	local gridHeight = (rows * cardHeight) + ((rows - 1) * gapY)
	local offsetX = (-gridWidth * 0.5) + (col * (cardWidth + gapX)) + (cardWidth * 0.5)
	local offsetY = (-gridHeight * 0.5) + (row * (cardHeight + gapY)) + (cardHeight * 0.5)
	return UDim2.new(0.5, math.floor(offsetX), 0.5, math.floor(offsetY))
end

function BoosterOpenSequence.Play(cardIds, cardWidth, cardHeight, showCardNotification, delaySeconds, displayOrder)
	if type(cardIds) ~= "table" or #cardIds == 0 then
		return
	end
	if type(showCardNotification) ~= "function" then
		return
	end

	local maxCards = math.min(#cardIds, 10)
	local stepDelay = tonumber(delaySeconds) or 0.09
	stepDelay = math.max(0, stepDelay)

	task.spawn(function()
		for i = 1, maxCards do
			local cardId = cardIds[i]
			if type(cardId) == "string" and cardId ~= "" then
				showCardNotification(cardId, getBoosterSlotPosition(i, maxCards, cardWidth, cardHeight), displayOrder)
				if i < maxCards then
					task.wait(stepDelay)
				end
			end
		end
	end)
end

return BoosterOpenSequence