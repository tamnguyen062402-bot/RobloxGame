-- ShopUI.client.luau
-- Dedicated module for future-proof, tabbed shop UI

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EconomyCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("EconomyCatalog"))
local EconomyProtocol = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("EconomyProtocol"))
local BoosterPackSystem = require(script.Parent:WaitForChild("BoosterPackSystem"))
local CardDatabase = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CardDatabase"))
local EconomyClient = require(script.Parent:WaitForChild("services"):WaitForChild("EconomyClient"))

local ShopUI = {}

-- ShopUI.Create(mainUI)
-- Creates the shop frame with tabbed navigation for Packs, Items, Cards
function ShopUI.Create(mainUI)
    -- Create Shop toggle button
    local shopToggleButton = mainUI:FindFirstChild("ShopToggleButton")
    if not shopToggleButton or not shopToggleButton:IsA("TextButton") then
        if shopToggleButton then
            shopToggleButton:Destroy()
        end
        shopToggleButton = Instance.new("TextButton")
        shopToggleButton.Name = "ShopToggleButton"
        shopToggleButton.Parent = mainUI
    end
    -- Create ShopFrame
    local shopFrame = mainUI:FindFirstChild("ShopFrame")
    if shopFrame then
        shopFrame:Destroy()
    end
    shopFrame = Instance.new("Frame")
    shopFrame.Name = "ShopFrame"
    shopFrame.Size = UDim2.fromOffset(430, 340)
    shopFrame.Position = UDim2.new(1, -110, 0, 20)
    shopFrame.AnchorPoint = Vector2.new(1, 0)
    shopFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    shopFrame.BackgroundTransparency = 0.15
    shopFrame.BorderSizePixel = 0
    shopFrame.Visible = false
    shopFrame.Parent = mainUI

    -- Toggle handler
    shopToggleButton.MouseButton1Click:Connect(function()
        shopFrame.Visible = not shopFrame.Visible
    end)

    -- Tab bar
    local tabBar = Instance.new("Frame")
    tabBar.Name = "ShopTabBar"
    tabBar.Size = UDim2.new(1, -20, 0, 36)
    tabBar.Position = UDim2.fromOffset(10, 8)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = shopFrame

    local tabNames = {"Packs", "Items", "Cards"}
    local tabButtons = {}
    local selectedTab = "Packs"

    for i, tabName in ipairs(tabNames) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = tabName .. "TabButton"
        tabBtn.Size = UDim2.new(0, 110, 1, 0)
        tabBtn.Position = UDim2.fromOffset((i-1)*120, 0)
        tabBtn.BackgroundColor3 = Color3.fromRGB(44, 44, 54)
        tabBtn.Text = tabName
        tabBtn.TextColor3 = Color3.new(1, 1, 1)
        tabBtn.Font = Enum.Font.SourceSansBold
        tabBtn.TextSize = 18
        tabBtn.Parent = tabBar
        tabButtons[tabName] = tabBtn
    end

    -- Content frame
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "ShopContentFrame"
    contentFrame.Size = UDim2.new(1, -20, 1, -58)
    contentFrame.Position = UDim2.fromOffset(10, 46)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 8
    contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentFrame.Parent = shopFrame

    local function clearContent()
        for _, child in ipairs(contentFrame:GetChildren()) do
            if not child:IsA("UIListLayout") then
                child:Destroy()
            end
        end
    end

    local function showPacks()
        clearContent()
        for _, pack in ipairs(BoosterPackSystem.GetPacks()) do
            local row = Instance.new("Frame")
            row.Name = pack.Id .. "ShopRow"
            row.Size = UDim2.new(1, 0, 0, 64)
            row.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            row.BorderSizePixel = 0
            row.Parent = contentFrame

            local icon = Instance.new("ImageLabel")
            icon.Name = "Icon"
            icon.Size = UDim2.fromOffset(56, 56)
            icon.Position = UDim2.fromOffset(4, 4)
            icon.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
            icon.BorderSizePixel = 0
            icon.Image = pack.Image
            icon.Parent = row

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -190, 0, 30)
            nameLabel.Position = UDim2.fromOffset(68, 4)
            nameLabel.BackgroundTransparency = 1
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextColor3 = Color3.new(1, 1, 1)
            nameLabel.Font = Enum.Font.SourceSansBold
            nameLabel.TextSize = 20
            nameLabel.Text = pack.Name
            nameLabel.Parent = row

            local infoLabel = Instance.new("TextLabel")
            infoLabel.Size = UDim2.new(1, -190, 0, 24)
            infoLabel.Position = UDim2.fromOffset(68, 34)
            infoLabel.BackgroundTransparency = 1
            infoLabel.TextXAlignment = Enum.TextXAlignment.Left
            infoLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
            infoLabel.Font = Enum.Font.SourceSans
            infoLabel.TextSize = 18
            infoLabel.Text = "Price: " .. tostring(pack.Price) .. " | Cards: " .. tostring(pack.CardsPerOpen or pack.CardsPerPack or 10)
            infoLabel.Parent = row

            local buyButton = Instance.new("TextButton")
            buyButton.Name = "BuyButton"
            buyButton.Size = UDim2.fromOffset(110, 36)
            buyButton.Position = UDim2.new(1, -116, 0.5, -18)
            buyButton.BackgroundColor3 = Color3.fromRGB(35, 120, 55)
            buyButton.BorderSizePixel = 0
            buyButton.TextColor3 = Color3.new(1, 1, 1)
            buyButton.Font = Enum.Font.SourceSansBold
            buyButton.TextSize = 18
            buyButton.Text = "Buy"
            buyButton.Parent = row

            buyButton.MouseButton1Click:Connect(function()
                local ok, responseOrErr = EconomyClient.Request(EconomyProtocol.ActionType.BuyPack, {
                    packId = pack.Id,
                    amount = 1,
                })
                if ok then
                    buyButton.Text = "Bought!"
                    task.delay(0.6, function()
                        if buyButton and buyButton.Parent then
                            buyButton.Text = "Buy"
                        end
                    end)
                else
                    buyButton.Text = "Failed"
                    task.delay(0.6, function()
                        if buyButton and buyButton.Parent then
                            buyButton.Text = "Buy"
                        end
                    end)
                    warn("Failed to buy pack: " .. tostring(responseOrErr))
                end
            end)
        end
    end

    local function showItems()
        clearContent()
        for itemId, item in pairs(EconomyCatalog.Items or {}) do
            local row = Instance.new("Frame")
            row.Name = itemId .. "ShopRow"
            row.Size = UDim2.new(1, 0, 0, 64)
            row.BackgroundColor3 = Color3.fromRGB(44, 44, 50)
            row.BorderSizePixel = 0
            row.Parent = contentFrame

            local itemIcon = Instance.new("ImageLabel")
            itemIcon.Name = "Icon"
            itemIcon.Size = UDim2.fromOffset(56, 56)
            itemIcon.Position = UDim2.fromOffset(4, 4)
            itemIcon.BackgroundColor3 = Color3.fromRGB(60, 60, 66)
            itemIcon.BorderSizePixel = 0
            itemIcon.Image = "rbxassetid://72066453841625"
            itemIcon.Parent = row

            local itemNameLabel = Instance.new("TextLabel")
            itemNameLabel.Size = UDim2.new(1, -190, 0, 30)
            itemNameLabel.Position = UDim2.fromOffset(68, 4)
            itemNameLabel.BackgroundTransparency = 1
            itemNameLabel.TextXAlignment = Enum.TextXAlignment.Left
            itemNameLabel.TextColor3 = Color3.new(1, 1, 1)
            itemNameLabel.Font = Enum.Font.SourceSansBold
            itemNameLabel.TextSize = 20
            itemNameLabel.Text = itemId
            itemNameLabel.Parent = row

            local itemInfoLabel = Instance.new("TextLabel")
            itemInfoLabel.Size = UDim2.new(1, -190, 0, 24)
            itemInfoLabel.Position = UDim2.fromOffset(68, 34)
            itemInfoLabel.BackgroundTransparency = 1
            itemInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
            itemInfoLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
            itemInfoLabel.Font = Enum.Font.SourceSans
            itemInfoLabel.TextSize = 18
            itemInfoLabel.Text = string.format("Price: %d", item.Price)
            itemInfoLabel.Parent = row

            local buyItemButton = Instance.new("TextButton")
            buyItemButton.Name = "BuyButton"
            buyItemButton.Size = UDim2.fromOffset(110, 36)
            buyItemButton.Position = UDim2.new(1, -116, 0.5, -18)
            buyItemButton.BackgroundColor3 = Color3.fromRGB(35, 120, 55)
            buyItemButton.BorderSizePixel = 0
            buyItemButton.TextColor3 = Color3.new(1, 1, 1)
            buyItemButton.Font = Enum.Font.SourceSansBold
            buyItemButton.TextSize = 18
            buyItemButton.Text = "Buy"
            buyItemButton.Parent = row

            buyItemButton.MouseButton1Click:Connect(function()
                local ok, responseOrErr = EconomyClient.Request(EconomyProtocol.ActionType.BuyItem, {
                    itemId = itemId,
                    amount = 1,
                })
                if not ok then
                    buyItemButton.Text = "Failed"
                    warn("Failed to buy item: " .. tostring(responseOrErr))
                else
                    buyItemButton.Text = "Bought!"
                end
                task.delay(0.6, function()
                    if buyItemButton and buyItemButton.Parent then
                        buyItemButton.Text = "Buy"
                    end
                end)
            end)
        end
    end

    local function showCards()
        clearContent()
        for cardId, cardOffer in pairs(EconomyCatalog.DirectCards or {}) do
            local row = Instance.new("Frame")
            row.Name = cardId .. "ShopRow"
            row.Size = UDim2.new(1, 0, 0, 64)
            row.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
            row.BorderSizePixel = 0
            row.Parent = contentFrame
            row.Active = true

            local cardIcon = Instance.new("ImageLabel")
            cardIcon.Name = "Icon"
            cardIcon.Size = UDim2.fromOffset(56, 56)
            cardIcon.Position = UDim2.fromOffset(4, 4)
            cardIcon.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
            cardIcon.BorderSizePixel = 0
            cardIcon.Image = "rbxassetid://77873660521351"
            cardIcon.Parent = row

            local cardData = CardDatabase.GetCardData(cardId)
            local cardName = Instance.new("TextLabel")
            cardName.Size = UDim2.new(1, -190, 0, 30)
            cardName.Position = UDim2.fromOffset(68, 4)
            cardName.BackgroundTransparency = 1
            cardName.TextXAlignment = Enum.TextXAlignment.Left
            cardName.TextColor3 = Color3.new(1, 1, 1)
            cardName.Font = Enum.Font.SourceSansBold
            cardName.TextSize = 20
            cardName.Text = (cardData and cardData.Name) or cardId
            cardName.Parent = row

            local cardInfo = Instance.new("TextLabel")
            cardInfo.Size = UDim2.new(1, -190, 0, 24)
            cardInfo.Position = UDim2.fromOffset(68, 34)
            cardInfo.BackgroundTransparency = 1
            cardInfo.TextXAlignment = Enum.TextXAlignment.Left
            cardInfo.TextColor3 = Color3.fromRGB(220, 220, 220)
            cardInfo.Font = Enum.Font.SourceSans
            cardInfo.TextSize = 18
            local rarityLabel = (cardData and cardData.Rarity) or "Special"
            cardInfo.Text = string.format("%s Card | Price: %d", rarityLabel, cardOffer.Price)
            cardInfo.Parent = row

            local buyCardButton = Instance.new("TextButton")
            buyCardButton.Name = "BuyButton"
            buyCardButton.Size = UDim2.fromOffset(110, 36)
            buyCardButton.Position = UDim2.new(1, -116, 0.5, -18)
            buyCardButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            buyCardButton.BorderSizePixel = 0
            buyCardButton.TextColor3 = Color3.new(1, 1, 1)
            buyCardButton.Font = Enum.Font.SourceSansBold
            buyCardButton.TextSize = 18
            buyCardButton.Text = "Buy"
            buyCardButton.Parent = row

            buyCardButton.MouseButton1Click:Connect(function()
                local ok, responseOrErr = EconomyClient.Request(EconomyProtocol.ActionType.BuyDirectCard, {
                    cardId = cardId,
                    amount = 1,
                })
                if not ok then
                    buyCardButton.Text = "Failed"
                    warn("Failed to buy card: " .. tostring(responseOrErr))
                else
                    buyCardButton.Text = "Bought!"
                end
                task.delay(0.6, function()
                    if buyCardButton and buyCardButton.Parent then
                        buyCardButton.Text = "Buy"
                    end
                end)
            end)
        end
    end

    -- Tab switching
    for tabName, tabBtn in pairs(tabButtons) do
        tabBtn.MouseButton1Click:Connect(function()
            selectedTab = tabName
            for _, btn in pairs(tabButtons) do
                btn.BackgroundColor3 = Color3.fromRGB(44, 44, 54)
            end
            tabBtn.BackgroundColor3 = Color3.fromRGB(65, 118, 195)
            if tabName == "Packs" then
                showPacks()
            elseif tabName == "Items" then
                showItems()
            elseif tabName == "Cards" then
                showCards()
            end
        end)
    end
    -- Default tab
    tabButtons[selectedTab].BackgroundColor3 = Color3.fromRGB(65, 118, 195)
    showPacks()

    -- Layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 8)
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    listLayout.Parent = contentFrame

    return shopFrame
end

return ShopUI
