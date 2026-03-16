-- DecksLayer.luau
-- Handles creation and visibility of the Decks UI layer

local DecksLayer = {}

function DecksLayer.Create(mainUI)
    local layer = Instance.new("Frame")
    layer.Name = "DecksLayer"
    layer.Size = UDim2.fromScale(1, 1)
    layer.Position = UDim2.fromScale(0, 0)
    layer.BackgroundTransparency = 1
    layer.BorderSizePixel = 0
    layer.ZIndex = 2
    layer.Visible = false
    layer.Active = false
    layer.Parent = mainUI
    return layer
end

function DecksLayer.SetVisible(layer, isVisible)
    if layer then
        layer.Visible = isVisible
    end
end

return DecksLayer