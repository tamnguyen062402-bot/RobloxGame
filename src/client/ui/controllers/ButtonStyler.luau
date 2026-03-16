-- ButtonStyler.luau
-- Provides reusable button styling for UI toggles

local ButtonStyler = {}

function ButtonStyler.styleToggleButton(button, text, bgColor, iconImage)
    button.AnchorPoint = Vector2.new(0, 0)
    button.BackgroundColor3 = bgColor
    button.BackgroundTransparency = 0.08
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = true
    button.Visible = true
    button.ZIndex = 60
    local corner = button:FindFirstChildOfClass("UICorner")
    if not corner then
        corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = button
    end
    local stroke = button:FindFirstChildOfClass("UIStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Thickness = 1
        stroke.Color = bgColor:lerp(Color3.new(0, 0, 0), 0.25)
        stroke.Transparency = 0.2
        stroke.Parent = button
    end
    local icon = button:FindFirstChild("Icon")
    if not icon then
        icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.fromOffset(20, 20)
        icon.Position = UDim2.new(0, 8, 0.5, -10)
        icon.BackgroundTransparency = 1
        icon.ZIndex = 61
        icon.Parent = button
    end
    icon.Image = iconImage
    local label = button:FindFirstChild("Label")
    if not label then
        label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(1, -34, 1, 0)
        label.Position = UDim2.fromOffset(30, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Font = Enum.Font.SciFi
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextSize = 17
        label.ZIndex = 61
        label.Parent = button
    end
    label.Text = text
    local gradient = button:FindFirstChildOfClass("UIGradient")
    if not gradient then
        gradient = Instance.new("UIGradient")
        gradient.Name = "ToggleGradient"
        gradient.Rotation = 0
        gradient.Parent = button
    end
    local light = bgColor:lerp(Color3.new(1, 1, 1), 0.18)
    local dark = bgColor:lerp(Color3.new(0, 0, 0), 0.12)
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, light),
        ColorSequenceKeypoint.new(1, dark),
    })
    pcall(function()
        local TweenService = game:GetService("TweenService")
        TweenService:Create(gradient, TweenInfo.new(4.0, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false), {Rotation = 360}):Play()
    end)
end

return ButtonStyler