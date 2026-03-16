local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local CardDatabase = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CardDatabase"))

local HoverPreview = {}

local PREVIEW_NAME_FONT = Enum.Font.Fantasy
local PREVIEW_STAT_FONT = Enum.Font.Arcade
local PREVIEW_META_FONT = Enum.Font.SciFi

local PREVIEW_WIDTH = 320
local PREVIEW_HEIGHT = 460
local PREVIEW_RIGHT_OFFSET = -340
local PREVIEW_HALF_HEIGHT = math.floor(PREVIEW_HEIGHT * 0.5)
local PREVIEW_POP_WIDTH = PREVIEW_WIDTH - 20
local PREVIEW_POP_HEIGHT = PREVIEW_HEIGHT - 30
local PREVIEW_POP_RIGHT_OFFSET = PREVIEW_RIGHT_OFFSET + 30

local PREVIEW_ART_HEIGHT = 258
local PREVIEW_NAME_Y = 274
local PREVIEW_NAME_HEIGHT = 48
local PREVIEW_ATTACK_Y = 326
local PREVIEW_ATTACK_HEIGHT = 38
local PREVIEW_META_HEIGHT = 22
local PREVIEW_META_GAP = 4
local PREVIEW_HEALTH_Y = PREVIEW_ATTACK_Y + PREVIEW_ATTACK_HEIGHT + PREVIEW_META_GAP
local PREVIEW_ATTACK_SPEED_Y = PREVIEW_HEALTH_Y + PREVIEW_META_HEIGHT + PREVIEW_META_GAP
local PREVIEW_RARITY_Y = PREVIEW_ATTACK_SPEED_Y + PREVIEW_META_HEIGHT + PREVIEW_META_GAP
local PREVIEW_BASE_ZINDEX = 260

local PREVIEW_RARITY_PUNCH = {
	Common = 1.015,
	Uncommon = 1.03,
	Rare = 1.055,
	Epic = 1.085,
	Legendary = 1.125,
	God = 1.165,
	Transcendent = 1.22,
}

local FLASH_RARITY_ENABLED = {
	Epic = true,
	Legendary = true,
	God = true,
	Transcendent = true,
}



local function getPreviewPunchScale(rarity)
	return PREVIEW_RARITY_PUNCH[rarity] or PREVIEW_RARITY_PUNCH.Common
end

local function buildPreviewFrameGoals(scale)
	local width = math.floor((PREVIEW_WIDTH * scale) + 0.5)
	local height = math.floor((PREVIEW_HEIGHT * scale) + 0.5)
	local rightOffset = PREVIEW_RIGHT_OFFSET - (width - PREVIEW_WIDTH)
	local halfHeight = math.floor(height * 0.5)
	return {
		Position = UDim2.new(1, rightOffset, 0.5, -halfHeight),
		Size = UDim2.fromOffset(width, height),
		BackgroundTransparency = 0.06,
	}
end

local preloadedPreviewVideoAssets = {}
local HOVER_VIDEO_LOOP_START_OFFSET_SECONDS = 1.0

local function getOrCreateHoverVideoPreviewActiveValue()
	local valueObj = ReplicatedStorage:FindFirstChild("HoverVideoPreviewActive")
	if not (valueObj and valueObj:IsA("BoolValue")) then
		if valueObj then
			valueObj:Destroy()
		end
		valueObj = Instance.new("BoolValue")
		valueObj.Name = "HoverVideoPreviewActive"
		valueObj.Value = false
		valueObj.Parent = ReplicatedStorage
	end
	return valueObj
end

local function ensurePreviewVideoPlayback(videoFrame, videoAssetId)
	if not (videoFrame and videoFrame:IsA("VideoFrame")) then
		return
	end

	local function forcePlay()
		videoFrame.Playing = true
		pcall(function()
			videoFrame:Play()
		end)
	end

	if not preloadedPreviewVideoAssets[videoAssetId] then
		preloadedPreviewVideoAssets[videoAssetId] = true
		task.spawn(function()
			pcall(function()
				ContentProvider:PreloadAsync({videoAssetId})
			end)
		end)
	end

	local shouldRestart = (videoFrame.Video ~= videoAssetId)
	videoFrame.Looped = true
	videoFrame.Video = videoAssetId
	videoFrame.Visible = true
	if shouldRestart then
		videoFrame.TimePosition = HOVER_VIDEO_LOOP_START_OFFSET_SECONDS
	end
	forcePlay()

	-- Re-assert after frame becomes visible and tweens settle.
	task.defer(function()
		if videoFrame.Parent and videoFrame.Visible and videoFrame.Video == videoAssetId then
			forcePlay()
		end
	end)
	task.delay(0.15, function()
		if videoFrame.Parent and videoFrame.Visible and videoFrame.Video == videoAssetId then
			forcePlay()
		end
	end)
	task.delay(0.35, function()
		if videoFrame.Parent and videoFrame.Visible and videoFrame.Video == videoAssetId then
			forcePlay()
		end
	end)
end

function HoverPreview.Init(mainUI, artFolder, config)
	local settings = config or {}

	local state = {
		hideTaskId = 0,
		edges = {},
		stripConnection = nil,
		beliodusAuraGeneration = 0,
		hoverVideoGuardGeneration = 0,
		gradientRotationConnection = nil,
	}
		-- Helper to start looping gradient border rotation
			local function startGradientBorderLoop()
				if state.gradientRotationConnection then
					return
				end
				local stroke = mainUI:FindFirstChild("CardHoverPreview")
					and mainUI:FindFirstChild("CardHoverPreview"):FindFirstChildOfClass("UIStroke")
				local gradient = stroke and stroke:FindFirstChild("RarityBorderGradient")
				if not gradient then
					return
				end
				-- Legendary effect: fast, glowing, sharp color transitions
				local pulse = 0
				state.gradientRotationConnection = RunService.RenderStepped:Connect(function(dt)
					gradient.Rotation = (gradient.Rotation + (dt * 220)) % 360
					pulse += dt
					local glow = 0.5 + 0.5 * math.sin(pulse * 3)
					gradient.Offset = Vector2.new(0, 0.22 * math.sin(pulse * 2))
					gradient.Transparency = NumberSequence.new{
						NumberSequenceKeypoint.new(0, 0.08 * glow),
						NumberSequenceKeypoint.new(0.25, 0.02 * glow),
						NumberSequenceKeypoint.new(0.5, 0.01 * glow),
						NumberSequenceKeypoint.new(0.75, 0.02 * glow),
						NumberSequenceKeypoint.new(1, 0.08 * glow)
					}
				end)
			end

		-- Helper to stop looping gradient border rotation
		local function stopGradientBorderLoop()
			if state.gradientRotationConnection then
				state.gradientRotationConnection:Disconnect()
				state.gradientRotationConnection = nil
			end
		end
	local hoverVideoPreviewActiveValue = getOrCreateHoverVideoPreviewActiveValue()

	local function setPreviewArtTransform(previewImage)
		previewImage.ScaleType = Enum.ScaleType.Stretch
		previewImage.AnchorPoint = Vector2.new(0, 0)
		previewImage.Size = UDim2.fromScale(1, 1)
		previewImage.Position = UDim2.fromOffset(0, 0)
	end

	local hoverPreviewFrame = mainUI:FindFirstChild("CardHoverPreview")
	if not hoverPreviewFrame then
		hoverPreviewFrame = Instance.new("Frame")
		hoverPreviewFrame.Name = "CardHoverPreview"
		hoverPreviewFrame.Size = UDim2.fromOffset(PREVIEW_WIDTH, PREVIEW_HEIGHT)
		hoverPreviewFrame.Position = UDim2.new(1, PREVIEW_RIGHT_OFFSET, 0.5, -PREVIEW_HALF_HEIGHT)
		hoverPreviewFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
		hoverPreviewFrame.BackgroundTransparency = 0.9
		hoverPreviewFrame.BorderSizePixel = 0
		hoverPreviewFrame.Visible = false
		hoverPreviewFrame.ZIndex = PREVIEW_BASE_ZINDEX
		hoverPreviewFrame.Parent = mainUI

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = hoverPreviewFrame

		local stroke = Instance.new("UIStroke")
		-- Use a stronger outline that will be tinted per-card rarity.
		stroke.Thickness = 10
		stroke.Color = Color3.fromRGB(200, 200, 200)
		stroke.Transparency = 0
		stroke.Parent = hoverPreviewFrame

		-- Add UIGradient for animated rarity border effect
		local gradient = Instance.new("UIGradient")
		gradient.Name = "RarityBorderGradient"
		-- More vibrant, high-contrast, and visible green
		gradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.08, Color3.fromRGB(0, 255, 80)),
			ColorSequenceKeypoint.new(0.16, Color3.fromRGB(0, 200, 255)),
			ColorSequenceKeypoint.new(0.24, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.32, Color3.fromRGB(255, 80, 0)),
			ColorSequenceKeypoint.new(0.40, Color3.fromRGB(255, 0, 200)),
			ColorSequenceKeypoint.new(0.48, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.56, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.64, Color3.fromRGB(0, 255, 80)),
			ColorSequenceKeypoint.new(0.72, Color3.fromRGB(0, 200, 255)),
			ColorSequenceKeypoint.new(0.80, Color3.fromRGB(255, 0, 200)),
			ColorSequenceKeypoint.new(0.88, Color3.fromRGB(255, 80, 0)),
			ColorSequenceKeypoint.new(0.96, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
		}
		gradient.Rotation = 0
		gradient.Parent = stroke

		local previewArt = Instance.new("Frame")
		previewArt.Name = "PreviewArt"
		previewArt.Size = UDim2.new(1, -20, 0, PREVIEW_ART_HEIGHT)
		previewArt.Position = UDim2.fromOffset(10, 10)
		previewArt.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
		previewArt.BackgroundTransparency = 0.05
		previewArt.BorderSizePixel = 0
		previewArt.ClipsDescendants = true
		previewArt.ZIndex = PREVIEW_BASE_ZINDEX + 1
		previewArt.Parent = hoverPreviewFrame

		local artCorner = Instance.new("UICorner")
		artCorner.CornerRadius = UDim.new(0, 8)
		artCorner.Parent = previewArt

		local previewArtImage = Instance.new("ImageLabel")
		previewArtImage.Name = "PreviewArtImage"
		previewArtImage.BackgroundTransparency = 1
		previewArtImage.BorderSizePixel = 0
		previewArtImage.ZIndex = PREVIEW_BASE_ZINDEX + 2
		previewArtImage.Parent = previewArt
		setPreviewArtTransform(previewArtImage)

		local previewArtVideo = Instance.new("VideoFrame")
		previewArtVideo.Name = "PreviewArtVideo"
		previewArtVideo.Size = UDim2.fromScale(1, 1)
		previewArtVideo.Position = UDim2.fromOffset(0, 0)
		previewArtVideo.BackgroundTransparency = 1
		previewArtVideo.BorderSizePixel = 0
		previewArtVideo.ZIndex = PREVIEW_BASE_ZINDEX + 2
		previewArtVideo.Looped = true
		previewArtVideo.Playing = false
		previewArtVideo.Visible = false
		previewArtVideo.Parent = previewArt

		local previewName = Instance.new("TextLabel")
		previewName.Name = "PreviewName"
		previewName.Size = UDim2.new(1, -20, 0, PREVIEW_NAME_HEIGHT)
		previewName.Position = UDim2.fromOffset(10, PREVIEW_NAME_Y)
		previewName.BackgroundTransparency = 1
		previewName.TextXAlignment = Enum.TextXAlignment.Left
		previewName.TextYAlignment = Enum.TextYAlignment.Top
		previewName.TextWrapped = true
		previewName.Font = PREVIEW_NAME_FONT
		previewName.TextSize = 28
		previewName.TextColor3 = Color3.fromRGB(230, 245, 255)
		previewName.TextStrokeColor3 = Color3.fromRGB(10, 14, 20)
		previewName.TextStrokeTransparency = 0
		previewName.ZIndex = PREVIEW_BASE_ZINDEX + 2
		previewName.Parent = hoverPreviewFrame

		local previewAttack = Instance.new("TextLabel")
		previewAttack.Name = "PreviewAttack"
		previewAttack.Size = UDim2.new(1, -20, 0, PREVIEW_ATTACK_HEIGHT)
		previewAttack.Position = UDim2.fromOffset(10, PREVIEW_ATTACK_Y)
		previewAttack.BackgroundTransparency = 1
		previewAttack.TextXAlignment = Enum.TextXAlignment.Left
		previewAttack.TextYAlignment = Enum.TextYAlignment.Center
		previewAttack.Font = PREVIEW_STAT_FONT
		previewAttack.TextSize = 24
		previewAttack.TextColor3 = Color3.fromRGB(255, 125, 90)
		previewAttack.TextStrokeColor3 = Color3.fromRGB(20, 8, 8)
		previewAttack.TextStrokeTransparency = 0
		previewAttack.ZIndex = PREVIEW_BASE_ZINDEX + 2
		previewAttack.Parent = hoverPreviewFrame

		local previewAttackPadding = Instance.new("UIPadding")
		previewAttackPadding.PaddingLeft = UDim.new(0, 10)
		previewAttackPadding.PaddingRight = UDim.new(0, 10)
		previewAttackPadding.Parent = previewAttack

		local previewHealth = Instance.new("TextLabel")
		previewHealth.Name = "PreviewHealth"
		previewHealth.Size = UDim2.new(1, -20, 0, PREVIEW_META_HEIGHT)
		previewHealth.Position = UDim2.fromOffset(10, PREVIEW_HEALTH_Y)
		previewHealth.BackgroundTransparency = 1
		previewHealth.TextXAlignment = Enum.TextXAlignment.Left
		previewHealth.TextYAlignment = Enum.TextYAlignment.Center
		previewHealth.TextWrapped = false
		previewHealth.Font = PREVIEW_META_FONT
		previewHealth.TextSize = 19
		previewHealth.TextColor3 = Color3.fromRGB(108, 255, 145)
		previewHealth.TextStrokeColor3 = Color3.fromRGB(6, 20, 8)
		previewHealth.TextStrokeTransparency = 0
		previewHealth.ZIndex = PREVIEW_BASE_ZINDEX + 2
		previewHealth.Parent = hoverPreviewFrame

		local previewHealthPadding = Instance.new("UIPadding")
		previewHealthPadding.PaddingLeft = UDim.new(0, 10)
		previewHealthPadding.PaddingRight = UDim.new(0, 10)
		previewHealthPadding.Parent = previewHealth

		local previewAttackSpeed = Instance.new("TextLabel")
		previewAttackSpeed.Name = "PreviewAttackSpeed"
		previewAttackSpeed.Size = UDim2.new(1, -20, 0, PREVIEW_META_HEIGHT)
		previewAttackSpeed.Position = UDim2.fromOffset(10, PREVIEW_ATTACK_SPEED_Y)
		previewAttackSpeed.BackgroundTransparency = 1
		previewAttackSpeed.TextXAlignment = Enum.TextXAlignment.Left
		previewAttackSpeed.TextYAlignment = Enum.TextYAlignment.Center
		previewAttackSpeed.TextWrapped = false
		previewAttackSpeed.Font = PREVIEW_META_FONT
		previewAttackSpeed.TextSize = 19
		previewAttackSpeed.TextColor3 = Color3.fromRGB(120, 196, 255)
		previewAttackSpeed.TextStrokeColor3 = Color3.fromRGB(8, 14, 32)
		previewAttackSpeed.TextStrokeTransparency = 0
		previewAttackSpeed.ZIndex = PREVIEW_BASE_ZINDEX + 2
		previewAttackSpeed.Parent = hoverPreviewFrame

		local previewAttackSpeedPadding = Instance.new("UIPadding")
		previewAttackSpeedPadding.PaddingLeft = UDim.new(0, 10)
		previewAttackSpeedPadding.PaddingRight = UDim.new(0, 10)
		previewAttackSpeedPadding.Parent = previewAttackSpeed

		local previewRarity = Instance.new("TextLabel")
		previewRarity.Name = "PreviewRarity"
		previewRarity.Size = UDim2.new(1, -20, 0, PREVIEW_META_HEIGHT)
		previewRarity.Position = UDim2.fromOffset(10, PREVIEW_RARITY_Y)
		previewRarity.BackgroundTransparency = 1
		previewRarity.TextXAlignment = Enum.TextXAlignment.Left
		previewRarity.TextYAlignment = Enum.TextYAlignment.Center
		previewRarity.TextWrapped = false
		previewRarity.Font = PREVIEW_META_FONT
		previewRarity.TextSize = 18
		previewRarity.TextColor3 = Color3.fromRGB(220, 220, 220)
		previewRarity.TextStrokeColor3 = Color3.fromRGB(12, 12, 16)
		previewRarity.TextStrokeTransparency = 0
		previewRarity.ZIndex = PREVIEW_BASE_ZINDEX + 2
		previewRarity.Parent = hoverPreviewFrame

		local previewRarityPadding = Instance.new("UIPadding")
		previewRarityPadding.PaddingLeft = UDim.new(0, 10)
		previewRarityPadding.PaddingRight = UDim.new(0, 10)
		previewRarityPadding.Parent = previewRarity

	end

	local function enforcePreviewLayering()
		hoverPreviewFrame.ZIndex = PREVIEW_BASE_ZINDEX
		local art = hoverPreviewFrame:FindFirstChild("PreviewArt")
		if art and art:IsA("GuiObject") then
			art.ZIndex = PREVIEW_BASE_ZINDEX + 1
			local artImage = art:FindFirstChild("PreviewArtImage")
			if artImage and artImage:IsA("GuiObject") then
				artImage.ZIndex = PREVIEW_BASE_ZINDEX + 2
			end
		end
		for _, name in ipairs({"PreviewName", "PreviewAttack", "PreviewHealth", "PreviewAttackSpeed", "PreviewRarity"}) do
			local label = hoverPreviewFrame:FindFirstChild(name)
			if label and label:IsA("GuiObject") then
				label.ZIndex = PREVIEW_BASE_ZINDEX + 2
			end
		end
	end

	enforcePreviewLayering()

	
	local function ensureRarityFlash(previewFrame)
		local existing = previewFrame:FindFirstChild("PreviewRarityFlash")
		if existing and existing:IsA("Frame") then
			return existing
		end

		local flash = Instance.new("Frame")
		flash.Name = "PreviewRarityFlash"
		flash.Size = UDim2.fromScale(1, 1)
		flash.Position = UDim2.fromOffset(0, 0)
		flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		flash.BackgroundTransparency = 1
		flash.BorderSizePixel = 0
		flash.ZIndex = hoverPreviewFrame.ZIndex + 3
		flash.Visible = false
		flash.Parent = previewFrame

		local flashCorner = Instance.new("UICorner")
		flashCorner.CornerRadius = UDim.new(0, 12)
		flashCorner.Parent = flash

		return flash
	end

	local function ensureBeliodusAura(previewFrame)
		local existing = previewFrame:FindFirstChild("PreviewBeliodusAura")
		if existing and existing:IsA("Frame") then
			existing.ZIndex = math.max(previewFrame.ZIndex + 20, 120)
			return existing
		end

		local aura = Instance.new("Frame")
		aura.Name = "PreviewBeliodusAura"
		aura.Size = UDim2.new(1, 52, 1, 52)
		aura.Position = UDim2.fromOffset(-26, -26)
		aura.BackgroundTransparency = 1
		aura.BorderSizePixel = 0
		-- Keep aura effects above all preview text/image layers.
		aura.ZIndex = math.max(hoverPreviewFrame.ZIndex + 20, 120)
		aura.ClipsDescendants = false
		aura.Visible = false
		aura.Parent = previewFrame

		return aura
	end

	local function stopBeliodusAura(previewFrame)
		state.beliodusAuraGeneration += 1
		local aura = previewFrame:FindFirstChild("PreviewBeliodusAura")
		if not (aura and aura:IsA("Frame")) then
			return
		end

		aura.Visible = false
		for _, child in ipairs(aura:GetChildren()) do
			if child.Name == "BeliodusParticle" then
				child:Destroy()
			end
		end
	end

	local function startBeliodusAura(previewFrame)
		local aura = ensureBeliodusAura(previewFrame)
		state.beliodusAuraGeneration += 1
		local myGeneration = state.beliodusAuraGeneration
		aura.Visible = true

		task.spawn(function()
			while aura.Parent and previewFrame.Visible and myGeneration == state.beliodusAuraGeneration do
				for _ = 1, 4 do
					local particle = Instance.new("Frame")
					particle.Name = "BeliodusParticle"
					particle.AnchorPoint = Vector2.new(0.5, 0.5)
					particle.BorderSizePixel = 0
					particle.BackgroundColor3 = Color3.fromRGB(6, 6, 6)
					particle.BackgroundTransparency = 0.08 + (math.random() * 0.2)
					particle.ZIndex = aura.ZIndex + 1

					local px = math.random(5, 13)
					particle.Size = UDim2.fromOffset(px, px)

					local side = math.random(1, 4)
					local startX
					local startY
					if side == 1 then
						startX = math.random(4, math.max(5, aura.AbsoluteSize.X - 4))
						startY = 4
					elseif side == 2 then
						startX = aura.AbsoluteSize.X - 4
						startY = math.random(4, math.max(5, aura.AbsoluteSize.Y - 4))
					elseif side == 3 then
						startX = math.random(4, math.max(5, aura.AbsoluteSize.X - 4))
						startY = aura.AbsoluteSize.Y - 4
					else
						startX = 4
						startY = math.random(4, math.max(5, aura.AbsoluteSize.Y - 4))
					end
					particle.Position = UDim2.fromOffset(startX, startY)

					local corner = Instance.new("UICorner")
					corner.CornerRadius = UDim.new(1, 0)
					corner.Parent = particle

					particle.Parent = aura

					local rise = math.random(14, 50)
					local drift = math.random(-36, 36)
					local duration = 0.45 + (math.random() * 0.45)
					TweenService:Create(
						particle,
						TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
						{
							Position = UDim2.fromOffset(startX + drift, startY - rise),
							BackgroundTransparency = 1,
							Size = UDim2.fromOffset(px + 2, px + 2),
						}
					):Play()

					task.delay(duration + 0.05, function()
						if particle and particle.Parent then
							particle:Destroy()
						end
					end)
				end

				task.wait(0.015)
			end
		end)

		-- Secondary orbiting wisps for a richer aura flow.
		task.spawn(function()
			while aura.Parent and previewFrame.Visible and myGeneration == state.beliodusAuraGeneration do
				local wisp = Instance.new("Frame")
				wisp.Name = "BeliodusParticle"
				wisp.AnchorPoint = Vector2.new(0.5, 0.5)
				wisp.BorderSizePixel = 0
				wisp.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
				wisp.BackgroundTransparency = 0.26
				wisp.ZIndex = aura.ZIndex + 2

				local size = math.random(8, 16)
				wisp.Size = UDim2.fromOffset(size, size)

				local cx = math.floor(aura.AbsoluteSize.X * 0.5)
				local cy = math.floor(aura.AbsoluteSize.Y * 0.5)
				local angle = math.random() * (math.pi * 2)
				local radius = math.random(58, 130)
				local sx = cx + math.floor(math.cos(angle) * radius)
				local sy = cy + math.floor(math.sin(angle) * radius)
				wisp.Position = UDim2.fromOffset(sx, sy)

				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(1, 0)
				corner.Parent = wisp

				wisp.Parent = aura

				local spin = angle + ((math.random(0, 1) == 0 and -1 or 1) * math.rad(math.random(65, 125)))
				local endRadius = math.max(26, radius - math.random(24, 56))
				local ex = cx + math.floor(math.cos(spin) * endRadius)
				local ey = cy + math.floor(math.sin(spin) * endRadius)
				local dur = 0.54 + (math.random() * 0.5)

				TweenService:Create(
					wisp,
					TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Position = UDim2.fromOffset(ex, ey),
						BackgroundTransparency = 1,
						Size = UDim2.fromOffset(size + 2, size + 2),
					}
				):Play()

				task.delay(dur + 0.05, function()
					if wisp and wisp.Parent then
						wisp:Destroy()
					end
				end)

				task.wait(0.03)
			end
		end)

		-- Broad smoky shadows to thicken the black aura around Beliodus.
		task.spawn(function()
			while aura.Parent and previewFrame.Visible and myGeneration == state.beliodusAuraGeneration do
				local smoke = Instance.new("Frame")
				smoke.Name = "BeliodusParticle"
				smoke.AnchorPoint = Vector2.new(0.5, 0.5)
				smoke.BorderSizePixel = 0
				smoke.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				smoke.BackgroundTransparency = 0.72
				smoke.ZIndex = aura.ZIndex

				local smokeSize = math.random(18, 34)
				smoke.Size = UDim2.fromOffset(smokeSize, smokeSize)

				local cx = math.floor(aura.AbsoluteSize.X * 0.5)
				local cy = math.floor(aura.AbsoluteSize.Y * 0.5)
				local angle = math.random() * (math.pi * 2)
				local radius = math.random(36, 90)
				local sx = cx + math.floor(math.cos(angle) * radius)
				local sy = cy + math.floor(math.sin(angle) * radius)
				smoke.Position = UDim2.fromOffset(sx, sy)

				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(1, 0)
				corner.Parent = smoke

				smoke.Parent = aura

				local ex = cx + math.floor(math.cos(angle + math.rad(math.random(-25, 25))) * math.max(16, radius - math.random(8, 24)))
				local ey = cy + math.floor(math.sin(angle + math.rad(math.random(-25, 25))) * math.max(16, radius - math.random(8, 24)))
				local dur = 0.75 + (math.random() * 0.55)

				TweenService:Create(
					smoke,
					TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
					{
						Position = UDim2.fromOffset(ex, ey),
						BackgroundTransparency = 1,
						Size = UDim2.fromOffset(smokeSize + 8, smokeSize + 8),
					}
				):Play()

				task.delay(dur + 0.05, function()
					if smoke and smoke.Parent then
						smoke:Destroy()
					end
				end)

				task.wait(0.06)
			end
		end)
	end

	local function playRarityFlash(previewFrame, rarityKey, rarityColor)
		if not FLASH_RARITY_ENABLED[rarityKey] then
			return
		end

		local flash = ensureRarityFlash(previewFrame)
		flash.Visible = true
		flash.BackgroundColor3 = rarityColor:Lerp(Color3.fromRGB(255, 255, 255), 0.7)
		flash.BackgroundTransparency = 1

		TweenService:Create(
			flash,
			TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundTransparency = 0.76}
		):Play()

		task.delay(0.07, function()
			if not flash.Parent then
				return
			end
			local fadeTween = TweenService:Create(
				flash,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{BackgroundTransparency = 1}
			)
			fadeTween:Play()
			fadeTween.Completed:Connect(function()
				if flash and flash.Parent then
					flash.Visible = false
				end
			end)
		end)
	end

	ensureRarityFlash(hoverPreviewFrame)

	local api = {}

	function api.Show(cardId, data, rarityColor)
		state.hideTaskId += 1
		local requestId = state.hideTaskId

		local art = hoverPreviewFrame:FindFirstChild("PreviewArt")
		local artImage = art and art:FindFirstChild("PreviewArtImage")
		local artVideo = art and art:FindFirstChild("PreviewArtVideo")
		local nameLabel = hoverPreviewFrame:FindFirstChild("PreviewName")
		local atkLabel = hoverPreviewFrame:FindFirstChild("PreviewAttack")
		local healthLabel = hoverPreviewFrame:FindFirstChild("PreviewHealth")
		local atkSpeedLabel = hoverPreviewFrame:FindFirstChild("PreviewAttackSpeed")
		if not healthLabel then
			-- Migrate from legacy label name used in older sessions.
			healthLabel = hoverPreviewFrame:FindFirstChild("PreviewCategory")
			if healthLabel and healthLabel:IsA("TextLabel") then
				healthLabel.Name = "PreviewHealth"
			end
		end
		if not atkSpeedLabel then
			atkSpeedLabel = Instance.new("TextLabel")
			atkSpeedLabel.Name = "PreviewAttackSpeed"
			atkSpeedLabel.Size = UDim2.new(1, -20, 0, PREVIEW_META_HEIGHT)
			atkSpeedLabel.Position = UDim2.fromOffset(10, PREVIEW_ATTACK_SPEED_Y)
			atkSpeedLabel.BackgroundTransparency = 1
			atkSpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
			atkSpeedLabel.TextYAlignment = Enum.TextYAlignment.Center
			atkSpeedLabel.TextWrapped = false
			atkSpeedLabel.Font = PREVIEW_META_FONT
			atkSpeedLabel.TextSize = 18
			atkSpeedLabel.TextColor3 = Color3.fromRGB(120, 196, 255)
			atkSpeedLabel.TextStrokeColor3 = Color3.fromRGB(8, 14, 32)
			atkSpeedLabel.TextStrokeTransparency = 0
			atkSpeedLabel.ZIndex = PREVIEW_BASE_ZINDEX + 2
			atkSpeedLabel.Parent = hoverPreviewFrame

			local atkSpeedPadding = Instance.new("UIPadding")
			atkSpeedPadding.PaddingLeft = UDim.new(0, 10)
			atkSpeedPadding.PaddingRight = UDim.new(0, 10)
			atkSpeedPadding.Parent = atkSpeedLabel

		end
		local rarityLabel = hoverPreviewFrame:FindFirstChild("PreviewRarity")
		if not rarityLabel then
			rarityLabel = Instance.new("TextLabel")
			rarityLabel.Name = "PreviewRarity"
			rarityLabel.Size = UDim2.new(1, -20, 0, PREVIEW_META_HEIGHT)
			rarityLabel.Position = UDim2.fromOffset(10, PREVIEW_RARITY_Y)
			rarityLabel.BackgroundTransparency = 1
			rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
			rarityLabel.TextYAlignment = Enum.TextYAlignment.Center
			rarityLabel.TextWrapped = false
			rarityLabel.Font = PREVIEW_META_FONT
			rarityLabel.TextSize = 16
			rarityLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
			rarityLabel.TextStrokeColor3 = Color3.fromRGB(12, 12, 16)
			rarityLabel.TextStrokeTransparency = 0
			rarityLabel.ZIndex = 41
			rarityLabel.Parent = hoverPreviewFrame
		end
		if not (art and artImage and nameLabel and atkLabel and healthLabel and atkSpeedLabel and rarityLabel) then
			return
		end

		art.Size = UDim2.new(1, -20, 0, PREVIEW_ART_HEIGHT)
		art.Position = UDim2.fromOffset(10, 10)
		nameLabel.Size = UDim2.new(1, -20, 0, PREVIEW_NAME_HEIGHT)
		nameLabel.Position = UDim2.fromOffset(10, PREVIEW_NAME_Y)

		healthLabel.Size = UDim2.new(1, -20, 0, PREVIEW_META_HEIGHT)
		healthLabel.Position = UDim2.fromOffset(10, PREVIEW_HEALTH_Y)
		healthLabel.Font = PREVIEW_META_FONT
		healthLabel.TextColor3 = Color3.fromRGB(108, 255, 145)
		healthLabel.TextStrokeColor3 = Color3.fromRGB(6, 20, 8)
		healthLabel.TextStrokeTransparency = 0
		healthLabel.TextSize = 16
		healthLabel.TextWrapped = false

		atkSpeedLabel.Size = UDim2.new(1, -20, 0, PREVIEW_META_HEIGHT)
		atkSpeedLabel.Position = UDim2.fromOffset(10, PREVIEW_ATTACK_SPEED_Y)
		atkSpeedLabel.Font = PREVIEW_META_FONT
		atkSpeedLabel.TextColor3 = Color3.fromRGB(120, 196, 255)
		atkSpeedLabel.TextStrokeColor3 = Color3.fromRGB(8, 14, 32)
		atkSpeedLabel.TextStrokeTransparency = 0
		atkSpeedLabel.TextSize = 16
		atkSpeedLabel.TextWrapped = false

		rarityLabel.Size = UDim2.new(1, -20, 0, PREVIEW_META_HEIGHT)
		rarityLabel.Position = UDim2.fromOffset(10, PREVIEW_RARITY_Y)
		rarityLabel.Font = PREVIEW_META_FONT
		rarityLabel.TextStrokeColor3 = Color3.fromRGB(12, 12, 16)
		rarityLabel.TextStrokeTransparency = 0
		rarityLabel.TextSize = 16
		rarityLabel.TextWrapped = false

		nameLabel.Font = PREVIEW_NAME_FONT
		nameLabel.TextColor3 = Color3.fromRGB(230, 245, 255)
		nameLabel.TextStrokeColor3 = Color3.fromRGB(10, 14, 20)
		nameLabel.TextStrokeTransparency = 0
		nameLabel.TextSize = 28

		atkLabel.Size = UDim2.new(1, -20, 0, PREVIEW_ATTACK_HEIGHT)
		atkLabel.Position = UDim2.fromOffset(10, PREVIEW_ATTACK_Y)
		atkLabel.Font = PREVIEW_STAT_FONT
		atkLabel.TextSize = 24
		atkLabel.TextColor3 = Color3.fromRGB(255, 125, 90)
		atkLabel.TextStrokeColor3 = Color3.fromRGB(20, 8, 8)
		atkLabel.TextStrokeTransparency = 0
		atkLabel.BackgroundTransparency = 1
		atkLabel.TextYAlignment = Enum.TextYAlignment.Center

		setPreviewArtTransform(artImage)
		nameLabel.Text = data.Name or cardId
		atkLabel.Text = "ATK: " .. CardDatabase.FormatAttack(data.Attack or "?")
		healthLabel.Text = "HP: " .. CardDatabase.FormatAttack(data.Health or "?")
		local attackInterval = tonumber(data.AttackIntervalSeconds)
		if attackInterval and attackInterval > 0 then
			atkSpeedLabel.Text = string.format("ATK SPD: %.2f/s", 1 / attackInterval)
		else
			atkSpeedLabel.Text = "ATK SPD: ?"
		end
		healthLabel.TextSize = 18
		healthLabel.BackgroundTransparency = 1
		atkSpeedLabel.TextSize = 18
		atkSpeedLabel.BackgroundTransparency = 1
		rarityLabel.Text = "Rarity: " .. tostring(data.Rarity or "Common")
		rarityLabel.TextSize = 18
		rarityLabel.BackgroundTransparency = 1
		rarityLabel.TextColor3 = rarityColor
		if tostring(data.Rarity) == "God" or tostring(data.Rarity) == "Transcendent" then
			rarityLabel.TextStrokeColor3 = Color3.fromRGB(210, 45, 45)
			rarityLabel.TextStrokeTransparency = 0
		else
			rarityLabel.TextStrokeColor3 = Color3.fromRGB(12, 12, 16)
			rarityLabel.TextStrokeTransparency = 0
		end

		local stroke = hoverPreviewFrame:FindFirstChildOfClass("UIStroke")
		if stroke then
			TweenService:Create(
				stroke,
				TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Color = rarityColor}
			):Play()
			local gradient = stroke:FindFirstChild("RarityBorderGradient")
			if gradient then
				gradient.Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0, rarityColor),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
					ColorSequenceKeypoint.new(1, rarityColor)
				}
				gradient.Rotation = 0
				startGradientBorderLoop()
			end
		end

		TweenService:Create(
			art,
			TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = rarityColor}
		):Play()

		art.BackgroundTransparency = 0.75
		local videoAssetId = nil
		if data then
			if type(data.HoverVideoAssetId) == "string" and data.HoverVideoAssetId ~= "" and data.HoverVideoAssetId ~= "rbxassetid://0" then
				videoAssetId = data.HoverVideoAssetId
			elseif type(data.VideoAssetId) == "string" and data.VideoAssetId ~= "" and data.VideoAssetId ~= "rbxassetid://0" then
				videoAssetId = data.VideoAssetId
			end
		end
		if artVideo and artVideo:IsA("VideoFrame") and type(videoAssetId) == "string" and videoAssetId ~= "" and videoAssetId ~= "rbxassetid://0" then
			hoverVideoPreviewActiveValue.Value = true
			ensurePreviewVideoPlayback(artVideo, videoAssetId)
			state.hoverVideoGuardGeneration += 1
			local guardGeneration = state.hoverVideoGuardGeneration
			task.spawn(function()
				local lastPos = nil
				while guardGeneration == state.hoverVideoGuardGeneration and artVideo.Parent do
					if hoverPreviewFrame.Visible and artVideo.Visible and artVideo.Video == videoAssetId and not artVideo.Playing then
						artVideo.Playing = true
						pcall(function()
							artVideo:Play()
						end)
					end
					if hoverPreviewFrame.Visible and artVideo.Visible and artVideo.Video == videoAssetId then
						local currentPos = tonumber(artVideo.TimePosition) or 0
						if lastPos and currentPos + 0.03 < lastPos and currentPos < HOVER_VIDEO_LOOP_START_OFFSET_SECONDS then
							artVideo.TimePosition = HOVER_VIDEO_LOOP_START_OFFSET_SECONDS
							currentPos = HOVER_VIDEO_LOOP_START_OFFSET_SECONDS
						end
						lastPos = currentPos
					end
					task.wait(0.2)
				end
			end)
			artImage.Image = ""
		else
			hoverVideoPreviewActiveValue.Value = false
			if artVideo and artVideo:IsA("VideoFrame") then
				state.hoverVideoGuardGeneration += 1
				artVideo.Visible = false
				artVideo.Playing = false
			end
			local imageObj = artFolder:FindFirstChild(cardId)
			if imageObj and imageObj:IsA("Decal") then
				artImage.Image = imageObj.Texture
			elseif data and type(data.ArtAssetId) == "string" and data.ArtAssetId ~= "" and data.ArtAssetId ~= "rbxassetid://0" then
				artImage.Image = data.ArtAssetId
			else
				artImage.Image = ""
			end
		end

		hoverPreviewFrame.Visible = true
		hoverPreviewFrame.Position = UDim2.new(1, PREVIEW_POP_RIGHT_OFFSET, 0.5, -PREVIEW_HALF_HEIGHT)
		hoverPreviewFrame.Size = UDim2.fromOffset(PREVIEW_POP_WIDTH, PREVIEW_POP_HEIGHT)
		hoverPreviewFrame.BackgroundTransparency = 0.25
		if artVideo and artVideo:IsA("VideoFrame") and type(videoAssetId) == "string" and videoAssetId ~= "" and videoAssetId ~= "rbxassetid://0" then
			task.defer(function()
				if requestId == state.hideTaskId and hoverPreviewFrame.Visible then
					ensurePreviewVideoPlayback(artVideo, videoAssetId)
				end
			end)
		end

		local rarityKey = tostring(data.Rarity or "Common")
		local isBeliodusPreview = (cardId == "BeliodusX") or (rarityKey == "God") or (rarityKey == "Transcendent")
		if isBeliodusPreview then
			startBeliodusAura(hoverPreviewFrame)
		else
			stopBeliodusAura(hoverPreviewFrame)
		end
		local punchGoals = buildPreviewFrameGoals(getPreviewPunchScale(rarityKey))
		playRarityFlash(hoverPreviewFrame, rarityKey, rarityColor)
		local settleGoals = {
			Position = UDim2.new(1, PREVIEW_RIGHT_OFFSET, 0.5, -PREVIEW_HALF_HEIGHT),
			Size = UDim2.fromOffset(PREVIEW_WIDTH, PREVIEW_HEIGHT),
			BackgroundTransparency = 0.06,
		}

		TweenService:Create(
			hoverPreviewFrame,
			TweenInfo.new(0.17, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			punchGoals
		):Play()

		task.delay(0.17, function()
			if requestId ~= state.hideTaskId or not hoverPreviewFrame.Visible then
				return
			end
			TweenService:Create(
				hoverPreviewFrame,
				TweenInfo.new(0.11, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				settleGoals
			):Play()
		end)
	end

	function api.Hide(delaySeconds)
		local requestId = state.hideTaskId + 1
		state.hideTaskId = requestId

		task.delay(delaySeconds or 0, function()
			if requestId ~= state.hideTaskId then
				return
			end
			stopBeliodusAura(hoverPreviewFrame)
			stopGradientBorderLoop()
			local art = hoverPreviewFrame:FindFirstChild("PreviewArt")
			local artVideo = art and art:FindFirstChild("PreviewArtVideo")
			hoverVideoPreviewActiveValue.Value = false
			if artVideo and artVideo:IsA("VideoFrame") then
				state.hoverVideoGuardGeneration += 1
				artVideo.Visible = false
				artVideo.Playing = false
			end

			local tween = TweenService:Create(
				hoverPreviewFrame,
				TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{
					Position = UDim2.new(1, PREVIEW_POP_RIGHT_OFFSET, 0.5, -PREVIEW_HALF_HEIGHT),
					Size = UDim2.fromOffset(PREVIEW_POP_WIDTH, PREVIEW_POP_HEIGHT),
					BackgroundTransparency = 0.25,
				}
			)
			tween:Play()
			tween.Completed:Wait()
			if requestId == state.hideTaskId then
				hoverPreviewFrame.Visible = false
			end
		end)
	end

	return api
end

return HoverPreview