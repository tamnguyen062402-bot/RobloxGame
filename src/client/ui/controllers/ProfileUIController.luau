-- ProfileUIController.luau
-- Modular profile modal UI for scalability

local Players = game:GetService("Players")
local ProfileUIController = {}

function ProfileUIController.Show(mainUI)
    local player = Players.LocalPlayer
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local statsUpdatedEvent = ReplicatedStorage:FindFirstChild("StatsUpdatedEvent")
    local profileModal = mainUI:FindFirstChild("ProfileModal")
    if not profileModal then
        profileModal = Instance.new("Frame")
        profileModal.Name = "ProfileModal"
        profileModal.Size = UDim2.fromOffset(340, 420)
        profileModal.Position = UDim2.fromOffset(380, 40)
        profileModal.AnchorPoint = Vector2.new(0, 0)
        profileModal.BackgroundColor3 = Color3.fromRGB(32, 32, 48)
        profileModal.BackgroundTransparency = 0.08
        profileModal.BorderSizePixel = 0
        profileModal.ZIndex = 50
        profileModal.Parent = mainUI
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 18)
        corner.Parent = profileModal
        local avatar = Instance.new("ImageLabel")
        avatar.Name = "Avatar"
        avatar.Size = UDim2.fromOffset(96, 96)
        avatar.Position = UDim2.new(0.5, -48, 0, 32)
        avatar.BackgroundTransparency = 1
        avatar.Image = "rbxasset://textures/ui/PlayerAvatar.png"
        avatar.ZIndex = 51
        avatar.Parent = profileModal
        local usernameLabel = Instance.new("TextLabel")
        usernameLabel.Name = "UsernameLabel"
        usernameLabel.Size = UDim2.new(1, -32, 0, 32)
        usernameLabel.Position = UDim2.fromOffset(16, 140)
        usernameLabel.BackgroundTransparency = 1
        usernameLabel.Text = player.Name
        usernameLabel.Font = Enum.Font.GothamBold
        usernameLabel.TextSize = 22
        usernameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        usernameLabel.ZIndex = 51
        usernameLabel.Parent = profileModal
        -- Stats content
        local statsContent = Instance.new("Frame")
        statsContent.Name = "StatsContent"
        statsContent.Size = UDim2.new(1, -32, 1, -240)
        statsContent.Position = UDim2.fromOffset(16, 230)
        statsContent.BackgroundTransparency = 1
        statsContent.ZIndex = 55
        statsContent.Parent = profileModal
        local luckLabel = Instance.new("TextLabel")
        luckLabel.Name = "LuckLabel"
        luckLabel.Size = UDim2.new(1, 0, 0, 32)
        luckLabel.Position = UDim2.new(0, 0, 0, 0)
        luckLabel.BackgroundTransparency = 1
        luckLabel.Text = "Luck: 0"
        luckLabel.Font = Enum.Font.GothamMedium
        luckLabel.TextSize = 18
        luckLabel.TextColor3 = Color3.fromRGB(255,255,255)
        luckLabel.ZIndex = 56
        luckLabel.Parent = statsContent
        local rollSpeedLabel = Instance.new("TextLabel")
        rollSpeedLabel.Name = "RollSpeedLabel"
        rollSpeedLabel.Size = UDim2.new(1, 0, 0, 32)
        rollSpeedLabel.Position = UDim2.fromOffset(32, 0)
        rollSpeedLabel.BackgroundTransparency = 1
        rollSpeedLabel.Text = "Roll Speed: 1x"
        rollSpeedLabel.Font = Enum.Font.GothamMedium
        rollSpeedLabel.TextSize = 18
        rollSpeedLabel.TextColor3 = Color3.fromRGB(255,255,255)
        rollSpeedLabel.ZIndex = 56
        rollSpeedLabel.Parent = statsContent
        -- Allocate content
        local allocateContent = Instance.new("Frame")
        allocateContent.Name = "AllocateContent"
        allocateContent.Size = statsContent.Size
        allocateContent.Position = statsContent.Position
        allocateContent.BackgroundTransparency = 1
        allocateContent.ZIndex = 55
        allocateContent.Parent = profileModal
        local pointsLabel = Instance.new("TextLabel")
        pointsLabel.Name = "PointsLabel"
        pointsLabel.Size = UDim2.new(1, 0, 0, 32)
        pointsLabel.Position = UDim2.new(0, 0, 0, 0)
        pointsLabel.BackgroundTransparency = 1
        pointsLabel.Text = "Points: 0"
        pointsLabel.Font = Enum.Font.GothamMedium
        pointsLabel.TextSize = 18
        pointsLabel.TextColor3 = Color3.fromRGB(255,255,255)
        pointsLabel.ZIndex = 56
        pointsLabel.Parent = allocateContent
        -- Allocation logic
        local function updateStats(stats)
            if stats then
                luckLabel.Text = "Luck: " .. tostring(stats.Luck or 0)
                rollSpeedLabel.Text = "Roll Speed: " .. tostring(stats.RollSpeed or 1) .. "x"
                pointsLabel.Text = "Points: " .. tostring(stats.Points or 0)
            end
        end
        -- Listen for stats update event
        if statsUpdatedEvent then
            statsUpdatedEvent.OnClientEvent:Connect(function(stats)
                if profileModal.Visible then
                    updateStats(stats)
                end
            end)
        end
        local closeBtn = Instance.new("TextButton")
        closeBtn.Name = "CloseButton"
        closeBtn.Size = UDim2.fromOffset(32, 32)
        closeBtn.Position = UDim2.new(1, -40, 0, 8)
        closeBtn.AnchorPoint = Vector2.new(1, 0)
        closeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        closeBtn.Text = "X"
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 18
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.ZIndex = 52
        closeBtn.Parent = profileModal
        closeBtn.MouseButton1Click:Connect(function()
            print("[ProfileUIController] CloseButton clicked")
            profileModal.Visible = false
        end)

        -- Tabs
        local tabBar = Instance.new("Frame")
        tabBar.Name = "TabBar"
        tabBar.Size = UDim2.new(1, -32, 0, 36)
        tabBar.Position = UDim2.fromOffset(16, 190)
        tabBar.BackgroundTransparency = 1
        tabBar.ZIndex = 53
        tabBar.Parent = profileModal
        local statsTab = Instance.new("TextButton")
        statsTab.Name = "StatsTab"
        statsTab.Size = UDim2.new(0.5, -4, 1, 0)
        statsTab.Position = UDim2.new(0, 0, 0, 0)
        statsTab.BackgroundColor3 = Color3.fromRGB(44, 126, 72)
        statsTab.Text = "Stats"
        statsTab.Font = Enum.Font.GothamBold
        statsTab.TextSize = 16
        statsTab.TextColor3 = Color3.fromRGB(255,255,255)
        statsTab.ZIndex = 54
        statsTab.Parent = tabBar
        local allocateTab = Instance.new("TextButton")
        allocateTab.Name = "AllocateTab"
        allocateTab.Size = UDim2.new(0.5, -4, 1, 0)
        allocateTab.Position = UDim2.new(0.5, 4, 0, 0)
        allocateTab.BackgroundColor3 = Color3.fromRGB(52, 92, 158)
        allocateTab.Text = "Allocate Points"
        allocateTab.Font = Enum.Font.GothamBold
        allocateTab.TextSize = 16
        allocateTab.TextColor3 = Color3.fromRGB(255,255,255)
        allocateTab.ZIndex = 54
        allocateTab.Parent = tabBar

        -- Allocate content
        
        local luckBtn = Instance.new("TextButton")
        luckBtn.Name = "LuckBtn"
        luckBtn.Size = UDim2.new(1, 0, 0, 32)
        luckBtn.Position = UDim2.fromOffset(0, 40)
        luckBtn.BackgroundColor3 = Color3.fromRGB(44, 126, 72)
        luckBtn.Text = "+ Add Luck"
        luckBtn.Font = Enum.Font.GothamBold
        luckBtn.TextSize = 16
        luckBtn.TextColor3 = Color3.fromRGB(255,255,255)
        luckBtn.ZIndex = 56

        luckBtn.Parent = allocateContent
        local rollSpeedBtn = Instance.new("TextButton")
        rollSpeedBtn.Name = "RollSpeedBtn"
        rollSpeedBtn.Size = UDim2.new(1, 0, 0, 32)
        rollSpeedBtn.Position = UDim2.fromOffset(0, 80)
        rollSpeedBtn.BackgroundColor3 = Color3.fromRGB(52, 92, 158)
        rollSpeedBtn.Text = "+ Add Roll Speed"
        rollSpeedBtn.Font = Enum.Font.GothamBold
        rollSpeedBtn.TextSize = 16
        rollSpeedBtn.TextColor3 = Color3.fromRGB(255,255,255)
        rollSpeedBtn.ZIndex = 56
        rollSpeedBtn.Parent = allocateContent

        -- Reset Points button
        local resetBtn = Instance.new("TextButton")
        resetBtn.Name = "ResetBtn"
        resetBtn.Size = UDim2.new(1, 0, 0, 32)
        resetBtn.Position = UDim2.fromOffset(0, 128)
        resetBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 120)
        resetBtn.Text = "Reset Points"
        resetBtn.Font = Enum.Font.GothamBold
        resetBtn.TextSize = 16
        resetBtn.TextColor3 = Color3.fromRGB(255,255,255)
        resetBtn.ZIndex = 56
        resetBtn.Parent = allocateContent

        -- Allocation logic
        local allocateRemote
        -- Wait for AllocatePointsRemote with timeout (5s)
        local waited = 0
        while not allocateRemote and waited < 5 do
            allocateRemote = ReplicatedStorage:FindFirstChild("AllocatePointsRemote")
            if not allocateRemote then
                waited = waited + 0.1
                wait(0.1)
            end
        end
        if allocateRemote then
            print("[ProfileUIController] Found AllocatePointsRemote in ReplicatedStorage")
        else
            warn("[ProfileUIController] AllocatePointsRemote NOT found in ReplicatedStorage after waiting")
        end
        local function fetchStats()
            if allocateRemote then
                local stats = allocateRemote:InvokeServer({})
                updateStats(stats)
            end
        end
        luckBtn.MouseButton1Click:Connect(function()
            print("[ProfileUIController] LuckBtn clicked")
            if allocateRemote then
                local stats = allocateRemote:InvokeServer({stat = "Luck"})
                updateStats(stats)
            else
                warn("AllocatePointsRemote not available")
            end
        end)
        rollSpeedBtn.MouseButton1Click:Connect(function()
            print("[ProfileUIController] RollSpeedBtn clicked")
            if allocateRemote then
                local stats = allocateRemote:InvokeServer({stat = "RollSpeed"})
                updateStats(stats)
            else
                warn("AllocatePointsRemote not available")
            end
        end)
        resetBtn.MouseButton1Click:Connect(function()
            print("[ProfileUIController] ResetBtn clicked")
            if allocateRemote then
                local stats = allocateRemote:InvokeServer({reset = true})
                updateStats(stats)
            else
                warn("AllocatePointsRemote not available")
            end
        end)
        fetchStats()

        -- Tab switching logic
        local function showStats()
            statsContent.Visible = true
            allocateContent.Visible = false
            statsTab.BackgroundColor3 = Color3.fromRGB(44, 126, 72)
            allocateTab.BackgroundColor3 = Color3.fromRGB(52, 92, 158)
        end
        local function showAllocate()
            statsContent.Visible = false
            allocateContent.Visible = true
            statsTab.BackgroundColor3 = Color3.fromRGB(32, 32, 48)
            allocateTab.BackgroundColor3 = Color3.fromRGB(44, 126, 72)
        end
        statsTab.MouseButton1Click:Connect(function()
            print("[ProfileUIController] StatsTab clicked")
            showStats()
        end)
        allocateTab.MouseButton1Click:Connect(function()
            print("[ProfileUIController] AllocateTab clicked")
            showAllocate()
        end)
        showStats()
    end
    profileModal.Visible = true
end

return ProfileUIController
