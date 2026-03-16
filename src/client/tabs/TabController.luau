local TabController = {}

local ACTIVE_COLOR = Color3.fromRGB(60, 100, 170)
local INACTIVE_COLOR = Color3.fromRGB(40, 40, 40)
local TAB_WIDTH = 116
local TAB_GAP = 8
local HEADER_BUTTON_WIDTH = 108
local HEADER_BUTTON_GAP = 8
local HEADER_TO_TABS_GAP = 12

function TabController.Init(mainUI, inventoryFrame, tabDefs)
	local existingBar = mainUI:FindFirstChild("InventoryTabBar")
	if existingBar then
		existingBar:Destroy()
	end

	local tabBar = Instance.new("Frame")
	tabBar.Name = "InventoryTabBar"
	tabBar.Size = UDim2.fromOffset((#tabDefs * TAB_WIDTH) + ((#tabDefs - 1) * TAB_GAP), 36)
	tabBar.AnchorPoint = Vector2.new(0, 0)
	tabBar.Position = UDim2.new(
		inventoryFrame.Position.X.Scale,
		inventoryFrame.Position.X.Offset + ((HEADER_BUTTON_WIDTH + HEADER_BUTTON_GAP) * 3) + HEADER_TO_TABS_GAP,
		inventoryFrame.Position.Y.Scale,
		inventoryFrame.Position.Y.Offset - 42
	)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent = mainUI
    -- Ensure the tab bar and its buttons render above modal content
    tabBar.ZIndex = 10

	local state = {
		tabBar = tabBar,
		framesById = {},
		buttonsById = {},
		activeTabId = nil,
		isVisible = true,
	}

	local function refreshVisibility()
		state.tabBar.Visible = state.isVisible
		for id, frame in pairs(state.framesById) do
			frame.Visible = state.isVisible and (id == state.activeTabId)
		end
	end

	local function setActive(tabId)
		state.activeTabId = tabId
		refreshVisibility()
		for buttonId, button in pairs(state.buttonsById) do
			button.BackgroundColor3 = (buttonId == tabId) and ACTIVE_COLOR or INACTIVE_COLOR
		end
	end

	local function setVisible(isVisible)
		state.isVisible = isVisible
		refreshVisibility()
	end

	for buttonId, button in pairs(state.buttonsById) do
		button.MouseButton1Click:Connect(function()
			setActive(buttonId)
		end)
	end

	if #tabDefs > 0 then
		setActive(tabDefs[1].GetId())
	end

	return {
		SetActive = setActive,
		SetVisible = setVisible,
		GetFrame = function(frameId)
			return state.framesById[frameId]
		end,
		GetTabBar = function()
			return state.tabBar
		end,
	}
end

return TabController
