local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Reference your new folder
local VFXTemplates = ReplicatedStorage:WaitForChild("VFXTemplates")

local function playSpriteAnimation(targetUI, spriteName, duration)
    -- 1. Find the template
    local template = VFXTemplates:FindFirstChild(spriteName)
    if not template then
        warn("VFX Template not found: " .. spriteName)
        return
    end
    if not template:IsA("ImageLabel") then
        warn("VFX Template is not an ImageLabel: " .. spriteName)
        return
    end
    if not targetUI or not targetUI:IsA("GuiObject") then
        warn("Target UI is not a valid GuiObject")
        return
    end
    if not template.Image or template.Image == "" then
        warn("VFX Template Image property is missing or empty")
        return
    end

    -- 2. Clone it and put it on the slot that gets hit
    local fx = template:Clone()
    fx.Parent = targetUI
    fx.Position = UDim2.fromScale(0.5, 0.5)
    fx.AnchorPoint = Vector2.new(0.5, 0.5)
    fx.Size = UDim2.fromScale(3, 3)
    fx.ImageTransparency = 0
    fx.BackgroundTransparency = 1
    fx.ZIndex = 999

    -- Play explosion sound effect if spriteName is FlameAnimation
    if spriteName == "FlameAnimation" then
        local player = game.Players.LocalPlayer
        local playerGui = player and player:FindFirstChild("PlayerGui")
        local npcBattleGui = playerGui and playerGui:FindFirstChild("NpcBattleGui")
        local soundParent = npcBattleGui or playerGui or fx
        local sound = Instance.new("Sound")
        sound.Name = "ExplosionSound"
        sound.SoundId = "rbxassetid://1843529270" -- Public explosion sound
        sound.Volume = 0.35
        sound.Parent = soundParent
        sound:Play()
        game:GetService("Debris"):AddItem(sound, 2)
    end

    task.spawn(function()
        local GRID_SIZE = 8
        local TOTAL_FRAMES = 64
        local FRAME_SIZE = 128
        fx.ImageRectSize = Vector2.new(FRAME_SIZE, FRAME_SIZE)
        local frameIndex = 0
        while fx.Parent do
            local col = frameIndex % GRID_SIZE
            local row = math.floor(frameIndex / GRID_SIZE)
            fx.ImageRectOffset = Vector2.new(col * FRAME_SIZE, row * FRAME_SIZE)
            frameIndex = (frameIndex + 1) % TOTAL_FRAMES
            task.wait(1/50)
        end
        if fx and fx.Parent then
            local fade = TweenService:Create(fx, TweenInfo.new(0.3), {ImageTransparency = 1})
            fade:Play()
            fade.Completed:Wait()
            fx:Destroy()
        end
    end)

    -- 3. Run the 8x8 Animation
    task.spawn(function()
        local GRID_SIZE = 8
        local TOTAL_FRAMES = 64
        local FRAME_SIZE = 128 -- Since your sheet is 1024x1024

        fx.ImageRectSize = Vector2.new(FRAME_SIZE, FRAME_SIZE)

        -- Loop the animation for the specified duration
        local startTime = tick()
        local frameIndex = 0

        while tick() - startTime < duration do
            local col = frameIndex % GRID_SIZE
            local row = math.floor(frameIndex / GRID_SIZE)

            fx.ImageRectOffset = Vector2.new(col * FRAME_SIZE, row * FRAME_SIZE)

            frameIndex = (frameIndex + 1) % TOTAL_FRAMES
            task.wait(1/50) -- 50 FPS, faster
        end

        -- 4. Clean up: Fade and Destroy
        local fade = TweenService:Create(fx, TweenInfo.new(0.3), {ImageTransparency = 1})
        fade:Play()
        fade.Completed:Wait()
        fx:Destroy()
    end)
end

local function playMultiSpriteSequence(targetUI, spriteInfos)
    -- spriteInfos: array of {imageId, gridCols, gridRows, totalFrames, frameSize}
    if not targetUI or not targetUI:IsA("GuiObject") then
        warn("Target UI is not a valid GuiObject")
        return
    end
    local fx = Instance.new("ImageLabel")
    fx.Parent = targetUI
    fx.Position = UDim2.fromScale(0.5, 0.5)
    fx.AnchorPoint = Vector2.new(0.5, 0.5)
    fx.Size = UDim2.fromScale(1.2, 1.2) -- Smaller overlay
    fx.ImageTransparency = 0
    fx.BackgroundTransparency = 1
    fx.ZIndex = 10000
    fx.BorderSizePixel = 0
    fx.Visible = true
    task.spawn(function()
        while fx.Parent do
            for _, info in ipairs(spriteInfos) do
                fx.Image = info.imageId
                fx.ImageRectSize = Vector2.new(info.frameSize, info.frameSize)
                for frameIndex = 0, info.totalFrames - 1 do
                    local col = frameIndex % info.gridCols
                    local row = math.floor(frameIndex / info.gridCols)
                    fx.ImageRectOffset = Vector2.new(col * info.frameSize, row * info.frameSize)
                    task.wait(1/10) -- Even slower: 10 FPS
                    if not fx.Parent then
                        break
                    end
                end
                if not fx.Parent then
                    break
                end
            end
        end
        if fx and fx.Parent then
            local fade = TweenService:Create(fx, TweenInfo.new(0.3), {ImageTransparency = 1})
            fade:Play()
            fade.Completed:Wait()
            fx:Destroy()
        end
    end)
end

local function playMultiSpriteSequenceOnce(targetUI, spriteInfos, frameDelay)
    if not targetUI or not targetUI:IsA("GuiObject") then
        warn("Target UI is not a valid GuiObject")
        return
    end
    local fx = Instance.new("ImageLabel")
    fx.Parent = targetUI
    fx.Position = UDim2.fromScale(0.5, 0.5)
    fx.AnchorPoint = Vector2.new(0.5, 0.5)
    fx.Size = UDim2.fromScale(2.2, 2.2)
    fx.ImageTransparency = 0
    fx.BackgroundTransparency = 1
    fx.ZIndex = 10000
    fx.BorderSizePixel = 0
    fx.Visible = true
    task.spawn(function()
        local delay = frameDelay or 1/30
        for _, info in ipairs(spriteInfos) do
            fx.Image = info.imageId
            fx.ImageRectSize = Vector2.new(info.frameSize, info.frameSize)
            for frameIndex = 0, info.totalFrames - 1 do
                local col = frameIndex % info.gridCols
                local row = math.floor(frameIndex / info.gridCols)
                fx.ImageRectOffset = Vector2.new(col * info.frameSize, row * info.frameSize)
                task.wait(delay)
                if not fx.Parent then
                    break
                end
            end
            if not fx.Parent then
                break
            end
        end
        if fx and fx.Parent then
            local fade = TweenService:Create(fx, TweenInfo.new(0.3), {ImageTransparency = 1})
            fade:Play()
            fade.Completed:Wait()
            fx:Destroy()
        end
    end)
end

return {
    playSpriteAnimation = playSpriteAnimation,
    playMultiSpriteSequence = playMultiSpriteSequence,
    playMultiSpriteSequenceOnce = playMultiSpriteSequenceOnce
}
