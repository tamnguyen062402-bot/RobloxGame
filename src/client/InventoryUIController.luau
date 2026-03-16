-- InventoryUIController.luau
-- Client-side inventory UI module

local InventoryUIController = {}

function InventoryUIController.Create(mainUI)
    -- Decks modal logic
    local inventoryFrame = mainUI:FindFirstChild("InventoryFrame")
    if not inventoryFrame then
        inventoryFrame = Instance.new("ScrollingFrame")
        inventoryFrame.Name = "InventoryFrame"
        inventoryFrame.Size = UDim2.fromOffset(760, 320)
        inventoryFrame.Position = UDim2.fromOffset(260, 20)
        inventoryFrame.AnchorPoint = Vector2.new(0, 0)
        inventoryFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
        inventoryFrame.BackgroundTransparency = 0.08
        inventoryFrame.BorderSizePixel = 0
        inventoryFrame.ScrollBarThickness = 8
        inventoryFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        inventoryFrame.Visible = false
        inventoryFrame.ZIndex = 10
        inventoryFrame.ClipsDescendants = true
        inventoryFrame.Parent = mainUI
    end

    local combatDeckFrame = mainUI:FindFirstChild("CombatDeckFrame")
    if not combatDeckFrame then
        combatDeckFrame = Instance.new("ScrollingFrame")
        combatDeckFrame.Name = "CombatDeckFrame"
        combatDeckFrame.Size = UDim2.fromOffset(760, 230)
        combatDeckFrame.Position = UDim2.fromOffset(260, 360)
        combatDeckFrame.AnchorPoint = Vector2.new(0, 0)
        combatDeckFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
        combatDeckFrame.BackgroundTransparency = 0.08
        combatDeckFrame.BorderSizePixel = 0
        combatDeckFrame.ScrollBarThickness = 8
        combatDeckFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        combatDeckFrame.Visible = false
        combatDeckFrame.ZIndex = 10
        combatDeckFrame.ClipsDescendants = true
        combatDeckFrame.Parent = mainUI
    end

    local decksLayer = mainUI:FindFirstChild("DecksLayer")
    if not decksLayer then
        decksLayer = Instance.new("Frame")
        decksLayer.Name = "DecksLayer"
        decksLayer.Size = UDim2.fromScale(1, 1)
        decksLayer.Position = UDim2.fromScale(0, 0)
        decksLayer.BackgroundTransparency = 1
        decksLayer.BorderSizePixel = 0
        decksLayer.ZIndex = 1
        decksLayer.Visible = false
        decksLayer.Active = false
        decksLayer.Parent = mainUI
    end

    local content = decksLayer:FindFirstChild("DecksModalContent")
    if not content then
        content = Instance.new("Frame")
        content.Name = "DecksModalContent"
        content.Size = UDim2.fromScale(1, 1)
        content.AnchorPoint = Vector2.new(0.5, 0.5)
        content.Position = UDim2.fromScale(0.5, 0.5)
        content.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        content.BackgroundTransparency = 0.06
        content.BorderSizePixel = 0
        content.ZIndex = decksLayer.ZIndex + 1
        content.Parent = decksLayer
    end

    local closeBtn = content:FindFirstChild("CloseButton")
    if not closeBtn then
        closeBtn = Instance.new("TextButton")
        closeBtn.Name = "CloseButton"
        closeBtn.Size = UDim2.fromOffset(24, 24)
        closeBtn.AnchorPoint = Vector2.new(1, 0)
        closeBtn.Position = UDim2.new(1, -12, 0, 8)
        closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        closeBtn.BorderSizePixel = 0
        closeBtn.Text = "X"
        closeBtn.Font = Enum.Font.SourceSansBold
        closeBtn.TextSize = 16
        closeBtn.TextColor3 = Color3.new(1, 1, 1)
        closeBtn.ZIndex = content.ZIndex + 50
        closeBtn.Parent = content
        closeBtn.MouseButton1Click:Connect(function()
            decksLayer.Visible = false
            inventoryFrame.Visible = false
            combatDeckFrame.Visible = false
            local toggleBar = mainUI:FindFirstChild("ToggleBar")
            if toggleBar then
                toggleBar.Visible = true
            end
        end)
    end

    -- Add Sort button to Decks modal
    local sortBtn = content:FindFirstChild("SortButton")
    if not sortBtn then
        sortBtn = Instance.new("TextButton")
        sortBtn.Name = "SortButton"
        sortBtn.Size = UDim2.fromOffset(80, 32)
        sortBtn.AnchorPoint = Vector2.new(1, 0)
        sortBtn.Position = UDim2.new(1, -100, 0, 8)
        sortBtn.BackgroundColor3 = Color3.fromRGB(52, 92, 158)
        sortBtn.BorderSizePixel = 0
        sortBtn.Text = "Sort"
        sortBtn.Font = Enum.Font.SourceSansBold
        sortBtn.TextSize = 18
        sortBtn.TextColor3 = Color3.new(1, 1, 1)
        sortBtn.ZIndex = content.ZIndex + 100
        sortBtn.Parent = content
        -- Add drop shadow for visibility
        local shadow = Instance.new("ImageLabel")
        shadow.Name = "SortButtonShadow"
        shadow.Size = sortBtn.Size
        shadow.Position = sortBtn.Position + UDim2.fromOffset(2, 2)
        shadow.BackgroundTransparency = 1
        shadow.Image = "rbxassetid://6031302915"
        shadow.ImageColor3 = Color3.new(0,0,0)
        shadow.ImageTransparency = 0.8
        shadow.ZIndex = sortBtn.ZIndex - 1
        shadow.Parent = content
        local sortModes = {"Attack", "Count", "Rarity"}
        local currentSort = 1
        sortBtn.MouseButton1Click:Connect(function()
            -- Cycle sort mode
            currentSort = currentSort % #sortModes + 1
            local mode = sortModes[currentSort]
            sortBtn.Text = "Sort: " .. mode
            -- Get card data
            local CardDatabase = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("CardDatabase"))
            local inventoryFrameUI = mainUI:FindFirstChild("InventoryFrame")
            if not inventoryFrameUI then
                return
            end
            -- Collect card UI and sort
            local cardUIs = {}
            for _, child in ipairs(inventoryFrameUI:GetChildren()) do
                if child:IsA("GuiButton") then
                    table.insert(cardUIs, child)
                end
            end
            local rarityOrder = {
                Common = 1,
                Uncommon = 2,
                Rare = 3,
                Epic = 4,
                Legendary = 5,
                God = 6,
                Transcendent = 7
            }
            table.sort(cardUIs, function(a, b)
                local cardA = CardDatabase.GetCardData and CardDatabase.GetCardData(a.Name) or CardDatabase[a.Name] or {}
                local cardB = CardDatabase.GetCardData and CardDatabase.GetCardData(b.Name) or CardDatabase[b.Name] or {}
                if mode == "Attack" then
                    return (tonumber(cardA.Attack) or 0) > (tonumber(cardB.Attack) or 0)
                elseif mode == "Count" then
                    local countA = tonumber(a.NumberLabel and a.NumberLabel.Text or "1") or 1
                    local countB = tonumber(b.NumberLabel and b.NumberLabel.Text or "1") or 1
                    return countA > countB
                elseif mode == "Rarity" then
                    local rA = rarityOrder[cardA.Rarity] or 0
                    local rB = rarityOrder[cardB.Rarity] or 0
                    return rA > rB
                end
                return false
            end)
            -- Reparent sorted cards
            for i, cardUI in ipairs(cardUIs) do
                cardUI.LayoutOrder = i
            end
        end)
    end

end

return InventoryUIController
