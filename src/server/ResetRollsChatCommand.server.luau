-- Server-side chat command handler for /resetrolls
-- Place this in ServerScriptService or src/server/

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ResetAllRollsEvent = ReplicatedStorage:FindFirstChild("ResetAllRollsEvent")
if not ResetAllRollsEvent then
    ResetAllRollsEvent = Instance.new("RemoteEvent")
    ResetAllRollsEvent.Name = "ResetAllRollsEvent"
    ResetAllRollsEvent.Parent = ReplicatedStorage
end

-- List of admin UserIds
local ADMIN_USER_IDS = {
    [12345678] = true, -- Replace with your UserId(s)
    [87654321] = true,
    [6020463235] = true,
}

Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(msg)
        print("[DEBUG] Player chatted:", player.Name, msg)
        local msgLower = msg:lower()
        if msgLower == "/resetrolls" then
            print("[DEBUG] Detected /resetrolls command from", player.Name)
        end
        if msgLower == "/givecoins" then
            print("[DEBUG] Detected /givecoins command from", player.Name)
        end
        if ADMIN_USER_IDS[player.UserId] then
            print("[DEBUG] Player is admin:", player.Name, player.UserId)
        else
            print("[DEBUG] Player is NOT admin:", player.Name, player.UserId)
        end
        if msgLower == "/resetrolls" and ADMIN_USER_IDS[player.UserId] then
            local SaveManager = require(script.Parent:FindFirstChild("SaveManager"))
            SaveManager.ResetAllPlayers(player)
            print("[DEBUG] All player rolls and levels reset by", player.Name)
        end

        if msgLower == "/givecoins" and ADMIN_USER_IDS[player.UserId] then
            print("[DEBUG] Giving 100000 coins to", player.Name)
            local SaveManager = require(script.Parent:FindFirstChild("SaveManager"))
            local playerData = SaveManager.playerData
            local saveEvent = ReplicatedStorage:WaitForChild("SaveDataEvent")
            if playerData[player.UserId] then
                playerData[player.UserId].coins = 100000
                saveEvent:FireClient(player, {
                    coins = 100000,
                    rollCount = playerData[player.UserId].rollCount,
                    level = playerData[player.UserId].level,
                })
                print("[DEBUG] Coins granted to", player.Name)
            else
                print("[DEBUG] No player data found for", player.Name)
            end
        end
    end)
end)
