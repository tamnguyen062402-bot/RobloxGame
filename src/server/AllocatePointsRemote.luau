-- AllocatePointsRemote server handler
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Diagnostic: print all RemoteFunction instances in ReplicatedStorage
for _, obj in ipairs(ReplicatedStorage:GetChildren()) do
    if obj:IsA("RemoteFunction") then
        print("[AllocatePointsRemote] Found RemoteFunction:", obj.Name, obj)
    end
end
local PlayerStatsService = nil
if script.Parent:FindFirstChild("PlayerStatsService") then
    PlayerStatsService = require(script.Parent:FindFirstChild("PlayerStatsService"))
else
    PlayerStatsService = require(ReplicatedStorage:WaitForChild("Server"):WaitForChild("PlayerStatsService"))
end
local SaveManager = nil
if script.Parent:FindFirstChild("SaveManager") then
    SaveManager = require(script.Parent:FindFirstChild("SaveManager"))
end

-- Ensure RemoteFunction exists
local allocateRemote = ReplicatedStorage:FindFirstChild("AllocatePointsRemote")
if not allocateRemote or not allocateRemote:IsA("RemoteFunction") then
    if allocateRemote then
        allocateRemote:Destroy()
    end
    allocateRemote = Instance.new("RemoteFunction")
    allocateRemote.Name = "AllocatePointsRemote"
    allocateRemote.Parent = ReplicatedStorage
end

allocateRemote.OnServerInvoke = function(player, action)
    print("[AllocatePointsRemote] OnServerInvoke called")
    if not player then
        print("[AllocatePointsRemote] No player provided!")
        return nil
    end
    if type(action) ~= "table" then
        print("[AllocatePointsRemote] action is not a table:", action)
        return nil
    end
    local stat = action.stat
    local reset = action.reset
    print("[AllocatePointsRemote] Invoke from", player.Name, "action=", action)
    if reset then
        local level = 1
        if SaveManager and SaveManager.playerData and SaveManager.playerData[player.UserId] then
            level = tonumber(SaveManager.playerData[player.UserId].level) or level
        end
        print("[AllocatePointsRemote] ResetPoints called for", player.Name, "level=", level)
        PlayerStatsService.ResetPoints(player, level)
    elseif stat == "Luck" or stat == "RollSpeed" then
        print("[AllocatePointsRemote] AllocatePoint called for", player.Name, "stat=", stat)
        local ok = PlayerStatsService.AllocatePoint(player, stat)
        print("[AllocatePointsRemote] AllocatePoint result:", ok)
    else
        print("[AllocatePointsRemote] Unknown stat or action:", stat, reset)
    end
    local stats = PlayerStatsService.GetStats(player)
    print("[AllocatePointsRemote] Returning stats:", stats)
    return {
        Luck = stats.Luck,
        RollSpeed = stats.RollSpeed,
        Points = stats.Points
    }
end
