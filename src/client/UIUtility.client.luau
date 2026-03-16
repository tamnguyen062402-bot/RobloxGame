local Players = game:GetService("Players")
-- Toggle layout constants

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainUI = playerGui:WaitForChild("MainUI")
local UIManager = require(script.Parent.UIManager)
UIManager.Init()

-- Create and display the grouped toggle bar with 6 buttons
local FrameFactory = require(script.Parent.ui.controllers.FrameFactory)
local buttonConfigs = {
    { name = "Inventory", text = "Inventory", onClick = function()
        local decksLayer = mainUI:FindFirstChild("DecksLayer")
        if decksLayer then
            decksLayer.Visible = true
        end
        local inventoryFrame = mainUI:FindFirstChild("InventoryFrame")
        if inventoryFrame then
            inventoryFrame.Visible = true
        end
        local combatDeckFrame = mainUI:FindFirstChild("CombatDeckFrame")
        if combatDeckFrame then
            combatDeckFrame.Visible = true
        end
        local shopFrame = mainUI:FindFirstChild("ShopFrame")
        if shopFrame then
            shopFrame.Visible = false
        end
        -- Toggle bar stays visible so all buttons are accessible
        -- Hide other frames (add more as needed)
    end },
    { name = "Shop", text = "Shop", onClick = function()
        local shopFrame = mainUI:FindFirstChild("ShopFrame")
        if shopFrame then
            shopFrame.Visible = not shopFrame.Visible
        end
    end },
    { name = "Profile", text = "Profile", onClick = function()
            local ProfileUIController = require(script.Parent.ui.controllers.ProfileUIController)
            ProfileUIController.Show(mainUI)
        end },
    { name = "Quests", text = "Quests", onClick = function()
            print("Quests toggled")
        end },
    { name = "Settings", text = "Settings", onClick = function()
            print("Settings toggled")
        end },
    { name = "Teleport", text = "Teleport", onClick = function()
            print("Teleport toggled")
        end },
}
FrameFactory.createToggleBar(mainUI, buttonConfigs)

-- Only non-modal UI logic remains
-- Decks modal logic is now managed by InventoryUIController
-- Profile, Quests, and Sort toggles are initialized and styled
-- All modal helpers, constants, and event handlers deleted
