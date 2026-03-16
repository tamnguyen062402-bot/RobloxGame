-- ToggleController.luau
-- Handles creation and management of UI toggles

local StyleConfig = require(script.Parent.Parent.styles.StyleConfig)

local ToggleController = {}

function ToggleController.CreateToggle(mainUI, def)
    local button = mainUI:FindFirstChild(def.name)
    if not button or not button:IsA("TextButton") then
        if button then
            button:Destroy()
        end
        button = Instance.new("TextButton")
        button.Name = def.name
        button.Parent = mainUI
    end
    if def.position then
        button.Position = def.position
    end
    button.Size = StyleConfig.Sizes.ToggleButton
    button.BackgroundColor3 = def.color or StyleConfig.Colors.Primary
    button.BackgroundTransparency = 0.08
    button.BorderSizePixel = 0
    button.Text = def.label or ""
    button.AutoButtonColor = true
    button.Visible = true
    button.ZIndex = 60
    -- ...existing code for icon, label, gradient, etc...
    return button
end

return ToggleController