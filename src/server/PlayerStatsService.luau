-- PlayerStatsService.luau
-- Handles player stats (luck, roll speed, allocation, etc.) securely on the server

local PlayerStatsService = {}


-- Ensure the StatsUpdatedEvent RemoteEvent exists in ReplicatedStorage
local ReplicatedStorage = game:GetService("ReplicatedStorage")
pcall(function()
    if ReplicatedStorage and ReplicatedStorage:FindFirstChild("Shared") then
        pcall(function()
            require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StatsUpdatedEvent"))
        end)
    end
end)

-- Store stats in a table indexed by UserId
local stats = {}

function PlayerStatsService.GetStats(player)
    local userId = player.UserId
    if not stats[userId] then
        stats[userId] = {
            Luck = 0,
            RollSpeed = 1,
            Points = 0,
        }
    end
    -- Points logic now handled externally; no SaveManager require
    return stats[userId]
end

function PlayerStatsService.AllocatePoint(player, statName)
    local s = PlayerStatsService.GetStats(player)
    if s.Points > 0 and (statName == "Luck" or statName == "RollSpeed") then
        s.Points = s.Points - 1
        s[statName] = s[statName] + 1
        -- Fire stats update event
        local event = ReplicatedStorage:FindFirstChild("StatsUpdatedEvent")
        if event then
            event:FireClient(player, s)
        end
        print(string.format("[PlayerStatsService] AllocatePoint: %s allocated to %s (remaining %d)", player.Name, statName, s.Points))
        return true
    end
    print(string.format("[PlayerStatsService] AllocatePoint failed for %s -> %s (points=%s)", player.Name, tostring(statName), tostring(s.Points)))
    return false
end

function PlayerStatsService.SetPoints(player, points)
    local s = PlayerStatsService.GetStats(player)
    s.Points = points
    local event = ReplicatedStorage:FindFirstChild("StatsUpdatedEvent")
    if event then
        print("[PlayerStatsService] Firing StatsUpdatedEvent for", player.Name, "->", s)
        event:FireClient(player, s)
    end
end

function PlayerStatsService.OnLevelUp(player)
    local s = PlayerStatsService.GetStats(player)
    s.Points = (s.Points or 0) + 1
    local event = ReplicatedStorage:FindFirstChild("StatsUpdatedEvent")
    if event then
        print("[PlayerStatsService] Firing StatsUpdatedEvent for", player.Name, "->", s)
        event:FireClient(player, s)
    end
end

function PlayerStatsService.ResetPoints(player, level)
    local s = PlayerStatsService.GetStats(player)
    s.Luck = 0
    s.RollSpeed = 1
    s.Points = level or 1
    local event = ReplicatedStorage:FindFirstChild("StatsUpdatedEvent")
    if event then
        print("[PlayerStatsService] Firing StatsUpdatedEvent for", player.Name, "->", s)
        event:FireClient(player, s)
    end
end

function PlayerStatsService.GetLuck(player)
    return PlayerStatsService.GetStats(player).Luck
end

function PlayerStatsService.GetRollSpeed(player)
    return PlayerStatsService.GetStats(player).RollSpeed
end

-- Example: luck affects rarity roll
function PlayerStatsService.GetRarityByLuck(player)
    local luck = PlayerStatsService.GetLuck(player)
    -- Example: higher luck increases chance for higher rarity
    local baseChances = {
        Common = 0.7,
        Uncommon = 0.2,
        Rare = 0.08,
        Epic = 0.015,
        Legendary = 0.004,
        God = 0.001,
        Transcendent = 0.0001,
    }
    -- Luck modifies chances (simple example)
    local luckFactor = 1 + (luck * 0.02)
    local chances = {}
    for rarity, base in pairs(baseChances) do
        chances[rarity] = base * luckFactor
    end
    -- Normalize
    local total = 0
        for _, v in pairs(chances) do
            total = total + v
        end
        for k, v in pairs(chances) do
            chances[k] = v / total
        end
    -- Roll
    local r = math.random()
    local accum = 0
    for rarity, chance in pairs(chances) do
        accum = accum + chance
        if r <= accum then
            return rarity
        end
    end
    return "Common"
end

return PlayerStatsService
