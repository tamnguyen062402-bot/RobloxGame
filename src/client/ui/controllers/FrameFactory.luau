-- FrameFactory.luau
-- Provides reusable frame creation functions for UI

local FrameFactory = {}

function FrameFactory.getOrCreateDeckFrame(mainUI, frameName, fallbackPosition)
    local existing = mainUI:FindFirstChild(frameName)
    if existing and existing:IsA("ScrollingFrame") then
        return existing
    end
    if existing then
        existing:Destroy()
    end
    local frame = Instance.new("ScrollingFrame")
    frame.Name = frameName
    frame.Size = fallbackPosition or UDim2.fromOffset(760, 320)
    frame.Position = fallbackPosition or UDim2.fromOffset(0, 0)
    frame.AnchorPoint = Vector2.new(0, 0)
    frame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    frame.BackgroundTransparency = 0.08
    frame.BorderSizePixel = 0
    frame.ScrollBarThickness = 8
    frame.CanvasSize = UDim2.new(0, 0, 0, 0)
    frame.Visible = false
    frame.ZIndex = 2
    frame.ClipsDescendants = true
    frame.Parent = mainUI
    return frame
end

function FrameFactory.getOrCreateBoolValue(name, defaultValue)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local valueObj = ReplicatedStorage:FindFirstChild(name)
    if not (valueObj and valueObj:IsA("BoolValue")) then
        if valueObj then
            valueObj:Destroy()
        end
        valueObj = Instance.new("BoolValue")
        valueObj.Name = name
        valueObj.Value = defaultValue == true
        valueObj.Parent = ReplicatedStorage
    end
    return valueObj
end

function FrameFactory.createToggleBar(mainUI, buttonConfigs)
    local toggleBar = Instance.new("Frame")
    toggleBar.Name = "ToggleBar"
    toggleBar.Size = UDim2.fromOffset(340, 440)
    toggleBar.Position = UDim2.fromOffset(16, 16)
    toggleBar.BackgroundTransparency = 1
    toggleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    toggleBar.BorderSizePixel = 0
    toggleBar.Parent = mainUI

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.fromOffset(100, 100)
    gridLayout.CellPadding = UDim2.fromOffset(12, 12)
    gridLayout.FillDirection = Enum.FillDirection.Vertical
    gridLayout.StartCorner = Enum.StartCorner.TopLeft
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = toggleBar
    gridLayout.FillDirectionMaxCells = 3

    local palettes = {
        {bg = Color3.fromRGB(52, 92, 158), glow = Color3.fromRGB(0, 170, 255), grad = {Color3.fromRGB(0, 170, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(52, 92, 158)}}, -- Inventory
        {bg = Color3.fromRGB(44, 126, 72), glow = Color3.fromRGB(0, 255, 120), grad = {Color3.fromRGB(0, 255, 120), Color3.fromRGB(255, 255, 255), Color3.fromRGB(44, 126, 72)}}, -- Shop
        {bg = Color3.fromRGB(180, 60, 120), glow = Color3.fromRGB(255, 0, 120), grad = {Color3.fromRGB(255, 0, 120), Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 60, 120)}}, -- Profile
        {bg = Color3.fromRGB(255, 170, 0), glow = Color3.fromRGB(255, 255, 0), grad = {Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 170, 0)}}, -- Quests
        {bg = Color3.fromRGB(120, 0, 255), glow = Color3.fromRGB(120, 0, 255), grad = {Color3.fromRGB(120, 0, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(60, 0, 120)}}, -- Settings
        {bg = Color3.fromRGB(0, 200, 255), glow = Color3.fromRGB(0, 200, 255), grad = {Color3.fromRGB(0, 200, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 100, 200)}}, -- Teleport
    }
    -- TweenService is now only used inside the button loop
    for i, config in ipairs(buttonConfigs) do
        local palette = palettes[i] or palettes[1]
        local btn = Instance.new("TextButton")
        btn.Name = config.name .. "Button"
        btn.Text = config.text
        btn.Size = UDim2.fromOffset(100, 100)
        btn.BackgroundColor3 = palette.bg
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 18
        btn.BorderSizePixel = 0
        btn.LayoutOrder = i
        btn.Parent = toggleBar
        btn.TextYAlignment = Enum.TextYAlignment.Bottom
        btn.TextWrapped = true
            -- Add visual symbol/icon
            local iconAssets = {
                "rbxassetid://6031763426", -- Inventory: backpack
                "rbxassetid://6031280882", -- Shop: money
                "rbxassetid://6031071050", -- Profile: user
                "rbxassetid://6031071053", -- Quests: star
                "rbxassetid://6031280882", -- Settings: gear
                "rbxassetid://6031094678", -- Teleport: arrow
            }
            local icon = Instance.new("ImageLabel")
            icon.Name = "ButtonIcon"
                icon.Size = UDim2.fromOffset(68, 68)
                icon.Position = UDim2.new(0.5, -34, 0, 8)
            icon.BackgroundTransparency = 1
            icon.ZIndex = btn.ZIndex - 1
            icon.ImageTransparency = 0
            icon.Image = iconAssets[i] or iconAssets[1]
            -- Improve icon visibility: use strong white for icon
            icon.ImageColor3 = Color3.new(1, 1, 1)
            -- Add a thick black outline to icon
            local iconOutline = Instance.new("UIStroke")
            iconOutline.Thickness = 3
            iconOutline.Color = Color3.new(0, 0, 0)
            iconOutline.Transparency = 0.1
            iconOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            iconOutline.Parent = icon
            -- Add a subtle drop shadow for extra contrast
            local iconShadow = Instance.new("ImageLabel")
            iconShadow.Name = "IconShadow"
            iconShadow.Size = icon.Size
            iconShadow.Position = icon.Position + UDim2.fromOffset(2, 2)
            iconShadow.BackgroundTransparency = 1
            iconShadow.ZIndex = icon.ZIndex - 2
            iconShadow.Image = icon.Image
            iconShadow.ImageColor3 = Color3.new(0,0,0)
            iconShadow.ImageTransparency = 0.7
            iconShadow.Parent = btn
            icon.Parent = btn
            -- Animate icon pulse
            local TweenService = game:GetService("TweenService")
            local iconPulse = TweenService:Create(icon, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {ImageTransparency = 0.15})
            iconPulse:Play()
        -- Soft glowing outline
        local outline = Instance.new("ImageLabel")
        outline.Name = "GlowOutline"
        outline.Size = UDim2.new(1, 12, 1, 12)
        outline.Position = UDim2.fromOffset(-6, -6)
        outline.BackgroundTransparency = 1
        outline.Image = "rbxassetid://466659280"
        outline.ImageColor3 = palette.glow
        outline.ImageTransparency = 0.3
        outline.ZIndex = btn.ZIndex + 10
        outline.Parent = btn
        -- Flowing horizontal gradient
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, palette.grad[1]),
            ColorSequenceKeypoint.new(0.5, palette.grad[2]),
            ColorSequenceKeypoint.new(1, palette.grad[3])
        }
        gradient.Rotation = 0
        gradient.Parent = btn
        -- Animate gradient offset left-to-right (seamless loop)
        spawn(function()
            local offset = 0
            local step = 0.01
            while true do
                offset = (offset + step) % 1
                gradient.Offset = Vector2.new(offset, 0)
                wait(0.003)
            end
        end)
        -- Gentle pulsing outline glow
        -- ...existing code...
        local pulseTween = TweenService:Create(outline, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {ImageTransparency = 0.15})
        pulseTween:Play()
        if config.onClick then
            btn.MouseButton1Click:Connect(config.onClick)
        end
        -- Modern rounded corners
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 18)
        corner.Parent = btn
            -- Visually appealing border outline
            local border = Instance.new("UIStroke")
            border.Thickness = 2
            border.Color = palette.glow:lerp(Color3.new(0,0,0), 0.25)
            border.Transparency = 0.2
            border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            border.Parent = btn
        -- Text shadow/outline effect
            btn.TextStrokeColor3 = Color3.new(0, 0, 0)
            btn.TextStrokeTransparency = 0
    end
    return toggleBar
end

return FrameFactory