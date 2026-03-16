-- UIManager.client.luau
-- Central manager for scalable UI modules

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainUI = playerGui:WaitForChild("MainUI")

local ShopUI = require(script.Parent.ShopUI)
local InventoryUIController = require(script.Parent.InventoryUIController)
-- Add more UI modules as needed

local UIManager = {}

function UIManager.Init()
    -- Initialize each UI module
    ShopUI.Create(mainUI)
    InventoryUIController.Create(mainUI)
    -- Add more as needed
end

return UIManager