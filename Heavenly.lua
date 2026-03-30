local Isotope = {}
Isotope.Version = "1.3.0h"
Isotope.Flags = {}
Isotope.SaveCfg = false
Isotope.Folder = "Isotope"
Isotope._CfgFile = ""
Isotope.Binds = {}
Isotope._BindListGui = nil
Isotope._TopbarGui = nil
Isotope._RadialGui = nil

Isotope.ShowKeybindList = false
Isotope.ShowTopbar = false
Isotope.TopbarBind = nil
Isotope.ShowRadial = false
Isotope.RadialHotkey = nil
Isotope.RadialMode = "hold"
Isotope.RadialAnim = "Scale"

Isotope._Tabs = {}
Isotope.TabOrder = false
Isotope._ElementRegistry = {}

Isotope._ScriptKey = ""

Isotope._MainWindowRef = nil
Isotope._MinimizedRef = nil
Isotope._RestoreRef = nil

Isotope.OwnerButtons = {}
Isotope.HoverMaximizeEnabled = true
Isotope.HoverMaximizeDelay = 3 

Isotope.UserSection = false 
Isotope.UserSectionRightClick = false
Isotope.USI = {}
Isotope.UserSectionItems = Isotope.USI

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local Themes = {}
Isotope.Themes = Themes

do
	local defaultColors = {
		Main = Color3.fromRGB(25, 25, 25),
		Second = Color3.fromRGB(32, 32, 32),
		Stroke = Color3.fromRGB(60, 60, 60),
		Divider = Color3.fromRGB(60, 60, 60),
		Text = Color3.fromRGB(240, 240, 240),
		TextDark = Color3.fromRGB(150, 150, 150),
		Accent = Color3.fromRGB(0, 170, 255),
	}

	function Themes:Add(name, cfg)
		cfg = cfg or {}
		local result = {}
		for key, value in pairs(defaultColors) do
			result[key] = cfg[key] ~= nil and cfg[key] or value
		end
		self[name] = result
		return result
	end

	Themes:Add("Dark", {
		Main = Color3.fromRGB(25, 25, 25),
		Second = Color3.fromRGB(32, 32, 32),
		Stroke = Color3.fromRGB(60, 60, 60),
		Divider = Color3.fromRGB(60, 60, 60),
		Text = Color3.fromRGB(240, 240, 240),
		TextDark = Color3.fromRGB(150, 150, 150),
		Accent = Color3.fromRGB(0, 170, 255),
	})

	Themes:Add("Light", {
		Main = Color3.fromRGB(235, 235, 240),
		Second = Color3.fromRGB(248, 248, 252),
		Stroke = Color3.fromRGB(200, 200, 210),
		Divider = Color3.fromRGB(200, 200, 210),
		Text = Color3.fromRGB(30, 30, 35),
		TextDark = Color3.fromRGB(100, 100, 115),
		Accent = Color3.fromRGB(0, 120, 255),
	})

	Themes:Add("Midnight", {
		Main = Color3.fromRGB(15, 15, 25),
		Second = Color3.fromRGB(25, 25, 40),
		Stroke = Color3.fromRGB(60, 60, 90),
		Divider = Color3.fromRGB(60, 60, 90),
		Text = Color3.fromRGB(230, 230, 255),
		TextDark = Color3.fromRGB(140, 140, 180),
		Accent = Color3.fromRGB(100, 80, 255),
	})

	Themes:Add("Crimson", {
		Main = Color3.fromRGB(30, 15, 15),
		Second = Color3.fromRGB(45, 20, 20),
		Stroke = Color3.fromRGB(90, 50, 50),
		Divider = Color3.fromRGB(90, 50, 50),
		Text = Color3.fromRGB(255, 230, 230),
		TextDark = Color3.fromRGB(180, 140, 140),
		Accent = Color3.fromRGB(255, 60, 60),
	})

	Themes:Add("Forest", {
		Main = Color3.fromRGB(15, 25, 15),
		Second = Color3.fromRGB(20, 35, 20),
		Stroke = Color3.fromRGB(50, 80, 50),
		Divider = Color3.fromRGB(50, 80, 50),
		Text = Color3.fromRGB(230, 255, 230),
		TextDark = Color3.fromRGB(140, 180, 140),
		Accent = Color3.fromRGB(60, 200, 100),
	})
end

local function tweenObj(instance, duration, style, direction, props)
	if not instance or not instance.Parent then return end
	TweenService:Create(
		instance,
		TweenInfo.new(duration, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		props
	):Play()
end

local function playSound(soundId)
	if not soundId or soundId == "" then return end
	local sound = Instance.new("Sound")
	sound.SoundId = (tonumber(soundId) and "rbxassetid://" .. soundId) or soundId
	sound.Volume = 0.5
	sound.Parent = game:GetService("SoundService")
	sound:Play()
	sound.Ended:Connect(function() sound:Destroy() end)
end

local function addCorner(parent, scale, offset)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(scale or 0, offset or 10)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.fromRGB(60, 60, 60)
	stroke.Thickness = thickness or 1
	stroke.Parent = parent
	return stroke
end

local function addListLayout(parent, padding)
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, padding or 0)
	layout.Parent = parent
	return layout
end

local function addPadding(parent, top, bottom, left, right)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, top or 0)
	padding.PaddingBottom = UDim.new(0, bottom or 0)
	padding.PaddingLeft = UDim.new(0, left or 0)
	padding.PaddingRight = UDim.new(0, right or 0)
	padding.Parent = parent
	return padding
end

local function makeDraggable(DragPoint, Main)
	pcall(function()
		local Dragging, DragInput, MousePos, FramePos = false
		DragPoint.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Dragging = true
				MousePos = Input.Position
				FramePos = Main.Position

				Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End then
						Dragging = false
					end
				end)
			end
		end)
		DragPoint.InputChanged:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseMovement then
				DragInput = Input
			end
		end)
		UserInputService.InputChanged:Connect(function(Input)
			if Input == DragInput and Dragging then
				local Delta = Input.Position - MousePos
				TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position  = UDim2.new(FramePos.X.Scale,FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)}):Play()
			end
		end)
	end)
end

local function makeRes(mainWindow, options)
	options = options or {}
	local minW = options.minWidth or 400
	local minH = options.minHeight or 250
	local hSz = options.handleSize or 8
	local onRes = options.onResize or function() end
	
	local hs = {
		{ name = "SE", ax = 0, ay = 0, xd =  1, yd =  1 },
		{ name = "SW", ax = 1, ay = 0, xd = -1, yd =  1 },
		{ name = "NE", ax = 0, ay = 1, xd =  1, yd = -1 },
		{ name = "NW", ax = 1, ay = 1, xd = -1, yd = -1 },
		{ name = "E",  ax = 0, ay = 0, xd =  1, yd =  0, fullY = true },
		{ name = "W",  ax = 1, ay = 0, xd = -1, yd =  0, fullY = true },
		{ name = "S",  ax = 0, ay = 0, xd =  0, yd =  1, fullX = true },
		{ name = "N",  ax = 0, ay = 1, xd =  0, yd = -1, fullX = true },
	}
	
	local cs = {}
	local handleFrames = {}
	
	local function conn(signal, fn)
		local c = signal:Connect(fn)
		table.insert(cs, c)
		return c
	end
	
	for _, h in ipairs(hs) do
		local isCorner = not h.fullX and not h.fullY
		local handle = Instance.new("TextButton")
		handle.Name = "__ResizeHandle_" .. h.name
		handle.Text = ""
		handle.AutoButtonColor = false
		handle.BackgroundColor3 = Color3.new(1, 1, 1)
		handle.BackgroundTransparency = 1
		handle.BorderSizePixel = 0
		handle.ZIndex = 200
		handle.Active = true
		
		if isCorner then
			handle.Size = UDim2.new(0, hSz * 2, 0, hSz * 2)
			handle.AnchorPoint = Vector2.new(h.ax, h.ay)
			handle.Position = UDim2.new(h.ax, 0, h.ay, 0)
		elseif h.fullY then
			handle.Size = UDim2.new(0, hSz, 1, -hSz * 4)
			handle.AnchorPoint = Vector2.new(h.ax, 0.5)
			handle.Position = UDim2.new(h.ax, 0, 0.5, 0)
		else
			handle.Size = UDim2.new(1, -hSz * 4, 0, hSz)
			handle.AnchorPoint = Vector2.new(0.5, h.ay)
			handle.Position = UDim2.new(0.5, 0, h.ay, 0)
		end
		--test
		handle.Parent = mainWindow
		table.insert(handleFrames, handle)

		conn(handle.MouseEnter, function()
			handle.BackgroundTransparency = 0.85
		end)
		conn(handle.MouseLeave, function()
			handle.BackgroundTransparency = 1
		end)

		local dragging   = false
		local startMouse = Vector2.new()
		local startPos   = UDim2.new()
		local startSize  = UDim2.new()

		conn(handle.InputBegan, function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			dragging   = true
			startMouse = input.Position
			startPos   = mainWindow.Position
			startSize  = mainWindow.Size
			conn(input.Changed, function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end)

		conn(UserInputService.InputChanged, function(input)
			if not dragging then return end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

			local delta = input.Position - startMouse
			local baseW  = startSize.X.Offset
			local baseH  = startSize.Y.Offset
			local basePX = startPos.X.Offset
			local basePY = startPos.Y.Offset
			local newW, newH, newPX, newPY = baseW, baseH, basePX, basePY

			if h.xd == 1 then
				newW = math.max(minW, baseW + delta.X)
			elseif h.xd == -1 then
				local cd = math.min(delta.X, baseW - minW)
				newW  = baseW  - cd
				newPX = basePX + cd
			end

			if h.yd == 1 then
				newH = math.max(minH, baseH + delta.Y)
			elseif h.yd == -1 then
				local cd = math.min(delta.Y, baseH - minH)
				newH  = baseH  - cd
				newPY = basePY + cd
			end

			mainWindow.Size     = UDim2.new(0, newW, 0, newH)
			mainWindow.Position = UDim2.new(startPos.X.Scale, newPX, startPos.Y.Scale, newPY)
			pcall(onResize, newW, newH)
		end)
	end

	return function()
		for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
		for _, f in ipairs(handleFrames) do pcall(function() f:Destroy() end) end
	end
end -- test


local function normalModifiers(mod)
	if mod == nil then return {} end
	if type(mod) == "table" then return mod end
	return {mod}
end

local ModifierNames = {
	[Enum.KeyCode.LeftShift] = "Shift",
	[Enum.KeyCode.RightShift] = "Shift",
	[Enum.KeyCode.LeftControl] = "Ctrl",
	[Enum.KeyCode.RightControl] = "Ctrl",
	[Enum.KeyCode.LeftAlt] = "Alt",
	[Enum.KeyCode.RightAlt] = "Alt",
	[Enum.KeyCode.LeftMeta] = "Meta",
	[Enum.KeyCode.RightMeta] = "Meta",
}

local function bBindLabel(modifiers, keyName)
	local parts = {}
	local seen = {}
	for _, modifier in ipairs(modifiers) do
		local shortName = ModifierNames[modifier] or tostring(modifier.Name)
		if not seen[shortName] then
			seen[shortName] = true
			table.insert(parts, shortName)
		end
	end
	if keyName and keyName ~= "" and keyName ~= "Unknown" then
		table.insert(parts, keyName)
	end
	return #parts > 0 and table.concat(parts, "+") or "-"
end

local function modifiersHeld(modifiers)
	for _, modifier in ipairs(modifiers) do
		if not UserInputService:IsKeyDown(modifier) then return false end
	end
	return true
end

local function secGui(gui)
	local parented = false
	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(gui)
			gui.Parent = game:GetService("CoreGui")
			parented = true
		end
	end)
	if not parented then
		pcall(function()
			gui.Parent = gethui() or game:GetService("CoreGui")
			parented = true
		end)
	end
	if not parented then
		gui.Parent = LocalPlayer.PlayerGui
	end
end

local Animations = {}

Animations.Blob = function(mainWindow, screenGui, theme, startupText, startupIcon)
	local finalWidth = 615
	local finalHeight = 344
	local popupSize = math.max(finalWidth, finalHeight) * 1.15

	local morphFrame = Instance.new("Frame")
	morphFrame.BackgroundColor3 = theme.Main
	morphFrame.BorderSizePixel = 0
	morphFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	morphFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	morphFrame.Size = UDim2.new(0, 0, 0, 0)
	morphFrame.ZIndex = 10
	morphFrame.Parent = screenGui

	local morphCorner = Instance.new("UICorner")
	morphCorner.CornerRadius = UDim.new(0.5, 0)
	morphCorner.Parent = morphFrame

	if startupIcon and startupIcon ~= "" then
		local iconLabel = Instance.new("ImageLabel")
		iconLabel.Image = startupIcon
		iconLabel.BackgroundTransparency = 1
		iconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		iconLabel.Size = UDim2.new(0, 56, 0, 56)
		iconLabel.Position = (startupText and startupText ~= "")
			and UDim2.new(0.5, 0, 0.42, 0)
			or UDim2.new(0.5, 0, 0.5, 0)
		iconLabel.ZIndex = 11
		iconLabel.Parent = morphFrame
	end

	if startupText and startupText ~= "" then
		local textLabel = Instance.new("TextLabel")
		textLabel.Text = startupText
		textLabel.Font = Enum.Font.GothamBold
		textLabel.TextSize = 18
		textLabel.TextColor3 = theme.Text
		textLabel.BackgroundTransparency = 1
		textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		textLabel.Position = UDim2.new(0.5, 0, 0.62, 0)
		textLabel.Size = UDim2.new(0.85, 0, 0, 28)
		textLabel.TextXAlignment = Enum.TextXAlignment.Center
		textLabel.ZIndex = 11
		textLabel.Parent = morphFrame
	end

	local expandTween = TweenService:Create(morphFrame,
		TweenInfo.new(0.75, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, popupSize, 0, popupSize)})
	expandTween:Play()
	expandTween.Completed:Wait()

	local morphTween = TweenService:Create(morphFrame,
		TweenInfo.new(0.55, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, finalWidth, 0, finalHeight)})
	TweenService:Create(morphCorner,
		TweenInfo.new(0.55, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
		{CornerRadius = UDim.new(0, 12)}):Play()
	morphTween:Play()
	morphTween.Completed:Wait()

	mainWindow.Visible = true
	mainWindow.Size = UDim2.new(0, finalWidth + 6, 0, finalHeight + 6)
	TweenService:Create(mainWindow,
		TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, finalWidth, 0, finalHeight)}):Play()
	morphFrame:Destroy()
end

Animations.Fade = function(mainWindow)
	mainWindow.BackgroundTransparency = 1
	mainWindow.Visible = true
	TweenService:Create(mainWindow,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 0}):Play()
end

Animations.Typewriter = function(mainWindow, screenGui, theme, startupText, startupIcon)
	local displayText = (startupText and startupText ~= "") and startupText or "Loading..."

	local overlayFrame = Instance.new("Frame")
	overlayFrame.BackgroundColor3 = theme.Main
	overlayFrame.BackgroundTransparency = 0
	overlayFrame.BorderSizePixel = 0
	overlayFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	overlayFrame.Size = UDim2.new(0, 615, 0, 344)
	overlayFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	overlayFrame.ZIndex = 12
	overlayFrame.Parent = screenGui
	addCorner(overlayFrame, 0, 10)

	if startupIcon and startupIcon ~= "" then
		local iconLabel = Instance.new("ImageLabel")
		iconLabel.Image = startupIcon
		iconLabel.BackgroundTransparency = 1
		iconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		iconLabel.Size = UDim2.new(0, 44, 0, 44)
		iconLabel.Position = UDim2.new(0.5, 0, 0.35, 0)
		iconLabel.ZIndex = 13
		iconLabel.Parent = overlayFrame
	end

	local typingLabel = Instance.new("TextLabel")
	typingLabel.Text = ""
	typingLabel.Font = Enum.Font.Code
	typingLabel.TextSize = 16
	typingLabel.TextColor3 = theme.Text
	typingLabel.BackgroundTransparency = 1
	typingLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	typingLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	typingLabel.Size = UDim2.new(0.75, 0, 0, 24)
	typingLabel.TextXAlignment = Enum.TextXAlignment.Center
	typingLabel.ZIndex = 13
	typingLabel.Parent = overlayFrame

	local progressTrack = Instance.new("Frame")
	progressTrack.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	progressTrack.BorderSizePixel = 0
	progressTrack.AnchorPoint = Vector2.new(0.5, 0.5)
	progressTrack.Size = UDim2.new(0, 200, 0, 3)
	progressTrack.Position = UDim2.new(0.5, 0, 0.62, 0)
	progressTrack.ClipsDescendants = true
	progressTrack.ZIndex = 13
	progressTrack.Parent = overlayFrame
	addCorner(progressTrack, 0, 2)

	local progressFill = Instance.new("Frame")
	progressFill.BackgroundColor3 = theme.Accent or Color3.fromRGB(0, 170, 255)
	progressFill.BorderSizePixel = 0
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.ZIndex = 14
	progressFill.Parent = progressTrack
	addCorner(progressFill, 0, 2)

	local charDelay = 0.055

	for charIndex = 1, #displayText do
		typingLabel.Text = string.sub(displayText, 1, charIndex) .. "|"
		progressFill.Size = UDim2.new(charIndex / #displayText, 0, 1, 0)
		task.wait(charDelay)
	end
	typingLabel.Text = displayText
	progressFill.Size = UDim2.new(1, 0, 1, 0)
	task.wait(0.35)

	mainWindow.Visible = true
	TweenService:Create(overlayFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 1}):Play()
	task.wait(0.45)
	overlayFrame:Destroy()
end

Animations.Bounce = function(mainWindow, screenGui, theme, startupText, startupIcon)
	local finalWidth = 615
	local finalHeight = 344
	local centreX = 0.5
	local centreY = 0.5

	mainWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	mainWindow.Position = UDim2.new(centreX, 0, 0, -finalHeight)
	mainWindow.Size = UDim2.new(0, finalWidth, 0, finalHeight)
	mainWindow.Visible = true

	local function tweenToY(yScale, duration, style, direction)
		local tween = TweenService:Create(mainWindow,
			TweenInfo.new(duration, style, direction),
			{Position = UDim2.new(centreX, 0, yScale, 0)})
		tween:Play()
		tween.Completed:Wait()
	end

	tweenToY(centreY, 0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tweenToY(centreY - 0.07, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	tweenToY(centreY, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tweenToY(centreY - 0.03, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	tweenToY(centreY, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	mainWindow.AnchorPoint = Vector2.new(0, 0)
	mainWindow.Position = UDim2.new(0.5, -finalWidth / 2, 0.5, -finalHeight / 2)
end

Animations.Unfold = function(mainWindow, screenGui, theme, startupText, startupIcon)
	local finalWidth = 615
	local finalHeight = 344

	mainWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	mainWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainWindow.Size = UDim2.new(0, finalWidth, 0, 1)
	mainWindow.ClipsDescendants = true
	mainWindow.Visible = true

	local widthTween = TweenService:Create(mainWindow,
		TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, finalWidth, 0, 1)})
	widthTween:Play()
	widthTween.Completed:Wait()

	local heightTween = TweenService:Create(mainWindow,
		TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, finalWidth, 0, finalHeight)})
	heightTween:Play()
	heightTween.Completed:Wait()

	mainWindow.AnchorPoint = Vector2.new(0, 0)
	mainWindow.Position = UDim2.new(0.5, -finalWidth / 2, 0.5, -finalHeight / 2)
	mainWindow.ClipsDescendants = false
end

Animations.ElasticMaximize = function(minimizedFrame, targetSize, targetPos, onComplete)
	local elasticFrame = Instance.new("Frame")
	elasticFrame.BackgroundColor3 = minimizedFrame.BackgroundColor3
	elasticFrame.BorderSizePixel = 0
	elasticFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	elasticFrame.Position = UDim2.new(0.5, minimizedFrame.AbsolutePosition.X + minimizedFrame.AbsoluteSize.X/2, 0, minimizedFrame.AbsolutePosition.Y + minimizedFrame.AbsoluteSize.Y/2)
	elasticFrame.Size = UDim2.new(0, minimizedFrame.AbsoluteSize.X, 0, minimizedFrame.AbsoluteSize.Y)
	elasticFrame.ZIndex = 100
	elasticFrame.Parent = minimizedFrame.Parent

	local elasticCorner = addCorner(elasticFrame, 0, 10)
	addStroke(elasticFrame, Color3.fromRGB(0, 170, 255), 2)

	minimizedFrame.Visible = false

	local anticipationTween = TweenService:Create(elasticFrame,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, minimizedFrame.AbsoluteSize.X * 0.9, 0, minimizedFrame.AbsoluteSize.Y * 0.9)})
	anticipationTween:Play()
	anticipationTween.Completed:Wait()

	local expandTween = TweenService:Create(elasticFrame,
		TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 1, 0.3),
		{Size = targetSize, Position = targetPos})
	expandTween:Play()

	local ripple = Instance.new("Frame")
	ripple.BackgroundTransparency = 0.8
	ripple.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	ripple.BorderSizePixel = 0
	ripple.AnchorPoint = Vector2.new(0.5, 0.5)
	ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
	ripple.Size = UDim2.new(0, 0, 0, 0)
	ripple.ZIndex = 99
	ripple.Parent = elasticFrame
	addCorner(ripple, 1, 0)

	TweenService:Create(ripple,
		TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{Size = UDim2.new(1.5, 0, 1.5, 0), BackgroundTransparency = 1}):Play()

	expandTween.Completed:Connect(function()
		elasticFrame:Destroy()
		if onComplete then onComplete() end
	end)
end

local notifGui = nil
local notifStack = {}

local notifWidth = 300
local notifGap = 8
local notifRightMargin = 25
local notifBottomMargin = 25

local function getNotifTheme()
	return Isotope._activeTheme or Isotope.Themes.Dark
end

local function getNotifGui()
	if notifGui and notifGui.Parent then return notifGui end
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "IsotopeNotifications"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 999
	screenGui.IgnoreGuiInset = true
	secGui(screenGui)
	notifGui = screenGui
	return screenGui
end

local function refNotifs(skipIndex)
	local screenHeight = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 768
	local currentY = screenHeight - notifBottomMargin

	for index = #notifStack, 1, -1 do
		local entry = notifStack[index]
		if not entry then continue end
		local entryHeight = entry.frame.AbsoluteSize.Y > 0 and entry.frame.AbsoluteSize.Y or entry.estimatedHeight
		currentY = currentY - entryHeight
		local targetY = currentY
		currentY = currentY - notifGap
		if index ~= skipIndex then
			tweenObj(entry.frame, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
				{Position = UDim2.new(1, -(notifWidth + notifRightMargin), 0, targetY)})
		end
		entry.targetY = targetY
	end
end

function Isotope:Notify(configOrText, durationArg)
	local title, content, image, duration, barColor
	if type(configOrText) == "table" then
		title = configOrText.Name or "Notification"
		content = configOrText.Content or ""
		image = configOrText.Image or "rbxassetid://4384403532"
		duration = configOrText.Time or 5
		barColor = configOrText.DurationColor or Color3.fromRGB(0, 170, 255)
	else
		title = tostring(configOrText or "Notification")
		content = ""
		image = "rbxassetid://4384403532"
		duration = durationArg or 5
		barColor = Color3.fromRGB(0, 170, 255)
	end

	local onClick = type(configOrText) == "table" and configOrText.OnClick or nil
	local soundId = type(configOrText) == "table" and configOrText.SoundId or nil

	if soundId then playSound(soundId) end

	local screenGui = getNotifGui()

	task.spawn(function()
		local sideBarWidth = 6
		local sideBarGap = 6
		local estimatedHeight = content ~= "" and 76 or 46
		local screenHeight = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 768

		local wrapper = Instance.new("Frame")
		wrapper.BackgroundTransparency = 1
		wrapper.Size = UDim2.new(0, notifWidth + sideBarWidth + sideBarGap, 0, 0)
		wrapper.ClipsDescendants = true
		wrapper.AnchorPoint = Vector2.new(0, 0)
		wrapper.Position = UDim2.new(1, notifRightMargin + 60, 0, screenHeight - notifBottomMargin - estimatedHeight)
		wrapper.ZIndex = 10
		wrapper.Parent = screenGui
		
		local stackEntry = {frame = wrapper, estimatedHeight = estimatedHeight, targetY = 0}
		table.insert(notifStack, 1, stackEntry)
		
		wrapper.AncestryChanged:Connect(function()
			if not wrapper.Parent then
				for i, entry in ipairs(notifStack) do
					if entry.frame == wrapper then
						table.remove(notifStack, i)
						break
					end
				end
			end
		end)

		local notifTheme = getNotifTheme()
		local card = Instance.new("Frame")
		card.BackgroundColor3 = notifTheme.Second
		card.BorderSizePixel = 0
		card.Size = UDim2.new(0, notifWidth, 0, 0)
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.Position = UDim2.new(1, 10, 0, 0)
		card.Parent = wrapper
		addCorner(card, 0, 8)
		addStroke(card, notifTheme.Stroke, 1)
		
		local dismissBtn = Instance.new("TextButton")
		dismissBtn.Text = ""
		dismissBtn.BackgroundTransparency = 1
		dismissBtn.Size = UDim2.new(1, 0, 1, 0)
		dismissBtn.ZIndex = 6
		dismissBtn.Parent = card
		dismissBtn.MouseButton2Click:Connect(function()
			for index, ent in ipairs(notifStack) do
				if ent == stackEntry then
					table.remove(notifStack, index)
					break
				end
			end
			local currentY = wrapper.Position.Y.Offset
			tweenObj(card, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In,
				{Position = UDim2.new(1, 10, 0, 0)})
			tweenObj(timerTrack, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In,
				{Position = UDim2.new(0, notifWidth + sideBarGap + 50, 0, 0)})
			refNotifs(nil)
			task.wait(0.32)
			wrapper:Destroy()
		end)

		if onClick then
			local clickBtn = Instance.new("TextButton")
			clickBtn.Text = ""
			clickBtn.BackgroundTransparency = 1
			clickBtn.Size = UDim2.new(1, 0, 1, 0)
			clickBtn.ZIndex = 5
			clickBtn.Parent = card
			clickBtn.MouseButton1Click:Connect(function()
				pcall(onClick)
			end)
		end

		local innerPadding = Instance.new("UIPadding")
		innerPadding.PaddingLeft = UDim.new(0, 12)
		innerPadding.PaddingRight = UDim.new(0, 12)
		innerPadding.PaddingTop = UDim.new(0, 11)
		innerPadding.PaddingBottom = UDim.new(0, 11)
		innerPadding.Parent = card

		local headerRow = Instance.new("Frame")
		headerRow.BackgroundTransparency = 1
		headerRow.Size = UDim2.new(1, 0, 0, 18)
		headerRow.Parent = card

		local iconLabel = Instance.new("ImageLabel")
		iconLabel.Image = image
		iconLabel.BackgroundTransparency = 1
		iconLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
		iconLabel.AnchorPoint = Vector2.new(0, 0.5)
		iconLabel.Size = UDim2.new(0, 15, 0, 15)
		iconLabel.Position = UDim2.new(0, 0, 0.5, 0)
		iconLabel.ZIndex = 2
		iconLabel.Parent = headerRow

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Text = title
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 14
		titleLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
		titleLabel.BackgroundTransparency = 1
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.AnchorPoint = Vector2.new(0, 0.5)
		titleLabel.Size = UDim2.new(1, -22, 1, 0)
		titleLabel.Position = UDim2.new(0, 21, 0.5, 0)
		titleLabel.ZIndex = 2
		titleLabel.Parent = headerRow

		if content ~= "" then
			local dividerLine = Instance.new("Frame")
			dividerLine.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
			dividerLine.BorderSizePixel = 0
			dividerLine.Size = UDim2.new(1, 0, 0, 1)
			dividerLine.Position = UDim2.new(0, 0, 0, 23)
			dividerLine.ZIndex = 2
			dividerLine.Parent = card

			local contentLabel = Instance.new("TextLabel")
			contentLabel.Text = content
			contentLabel.Font = Enum.Font.Gotham
			contentLabel.TextSize = 13
			contentLabel.TextColor3 = Color3.fromRGB(150, 150, 158)
			contentLabel.BackgroundTransparency = 1
			contentLabel.TextXAlignment = Enum.TextXAlignment.Left
			contentLabel.TextYAlignment = Enum.TextYAlignment.Top
			contentLabel.TextWrapped = true
			contentLabel.AutomaticSize = Enum.AutomaticSize.Y
			contentLabel.Size = UDim2.new(1, 0, 0, 0)
			contentLabel.Position = UDim2.new(0, 0, 0, 29)
			contentLabel.ZIndex = 2
			contentLabel.Parent = card
		end

		local timerTrack = Instance.new("Frame")
		timerTrack.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
		timerTrack.BorderSizePixel = 0
		timerTrack.AnchorPoint = Vector2.new(0, 0)
		timerTrack.Size = UDim2.new(0, sideBarWidth, 0, 0)
		timerTrack.Position = UDim2.new(0, notifWidth + sideBarGap, 0, 0)
		timerTrack.ClipsDescendants = true
		timerTrack.ZIndex = 2
		timerTrack.Parent = wrapper
		addCorner(timerTrack, 1, 0)

		local timerFill = Instance.new("Frame")
		timerFill.BackgroundColor3 = barColor
		timerFill.BorderSizePixel = 0
		timerFill.AnchorPoint = Vector2.new(0, 0)
		timerFill.Size = UDim2.new(1, 0, 1, 0)
		timerFill.ZIndex = 3
		timerFill.Parent = timerTrack
		addCorner(timerFill, 1, 0)


		task.defer(function()
			local cardHeight = card.AbsoluteSize.Y
			if cardHeight == 0 then cardHeight = estimatedHeight end
			wrapper.Size = UDim2.new(0, notifWidth + sideBarWidth + sideBarGap, 0, cardHeight + 5)
			timerTrack.Size = UDim2.new(0, sideBarWidth, 0, cardHeight)
			stackEntry.estimatedHeight = cardHeight + 5
			refNotifs(1)
			local destinationY = stackEntry.targetY
			wrapper.Position = UDim2.new(1, notifRightMargin + 60, 0, destinationY)
			tweenObj(wrapper, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
				{Position = UDim2.new(1, -(notifWidth + sideBarWidth + sideBarGap + notifRightMargin), 0, destinationY)})
			tweenObj(card, 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
				{Position = UDim2.new(0, 0, 0, 0)})
		end)

		task.wait(0.5)
		local drainDuration = math.max(duration - 0.5, 0.1)
		tweenObj(timerFill, drainDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out,
			{Size = UDim2.new(1, 0, 0, 0)})
		task.wait(drainDuration)

		for index, entry in ipairs(notifStack) do
			if entry == stackEntry then
				table.remove(notifStack, index)
				break
			end
		end

		wrapper.ClipsDescendants = false
		tweenObj(card, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In,
			{Position = UDim2.new(1, 10, 0, 0)})
		tweenObj(timerTrack, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In,
			{Position = UDim2.new(0, notifWidth + sideBarGap + 50, 0, 0)})
		refNotifs(nil)
		task.wait(0.38)
		wrapper.ClipsDescendants = true
		tweenObj(wrapper, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
			{Size = UDim2.new(0, notifWidth + sideBarWidth + sideBarGap, 0, 0)})
		task.wait(0.28)
		wrapper:Destroy()
	end)
end

function Isotope:CNotify(config)
	config = config or {}
	local title = config.Name or "Advanced Notification"
	local content = config.Content or ""
	local additional = config.Additional or ""
	local image = config.Image or "rbxassetid://4384403532"
	local duration = config.Time or 5
	local barColor = config.DurationColor or Color3.fromRGB(0, 255, 170)
	local soundId = config.SoundId
	local onClick = config.OnClick

	if soundId then playSound(soundId) end

	local screenGui = getNotifGui()

	task.spawn(function()
		local sideBarWidth = 6
		local sideBarGap = 6
		local estimatedHeight = content ~= "" and 76 or 46
		local screenHeight = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 768

		local wrapper = Instance.new("Frame")
		wrapper.BackgroundTransparency = 1
		wrapper.Size = UDim2.new(0, notifWidth + sideBarWidth + sideBarGap, 0, 0)
		wrapper.ClipsDescendants = true
		wrapper.AnchorPoint = Vector2.new(0, 0)
		wrapper.Position = UDim2.new(1, notifRightMargin + 60, 0, screenHeight - notifBottomMargin - estimatedHeight)
		wrapper.ZIndex = 11
		wrapper.Parent = screenGui
		
		local stackEntry = {frame = wrapper, estimatedHeight = estimatedHeight, targetY = 0}
		table.insert(notifStack, 1, stackEntry)
		
		wrapper.AncestryChanged:Connect(function()
			if not wrapper.Parent then
				for i, entry in ipairs(notifStack) do
					if entry.frame == wrapper then
						table.remove(notifStack, i)
						break
					end
				end
			end
		end)

		local notifTheme = getNotifTheme()
		local card = Instance.new("Frame")
		card.BackgroundColor3 = notifTheme.Second
		card.BorderSizePixel = 0
		card.Size = UDim2.new(0, notifWidth, 0, 0)
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.Position = UDim2.new(1, 10, 0, 0)
		card.Parent = wrapper
		addCorner(card, 0, 10)
		addStroke(card, notifTheme.Stroke, 1)

		local innerPadding = Instance.new("UIPadding")
		innerPadding.PaddingLeft = UDim.new(0, 14)
		innerPadding.PaddingRight = UDim.new(0, 14)
		innerPadding.PaddingTop = UDim.new(0, 12)
		innerPadding.PaddingBottom = UDim.new(0, 12)
		innerPadding.Parent = card

		local headerRow = Instance.new("Frame")
		headerRow.BackgroundTransparency = 1
		headerRow.Size = UDim2.new(1, 0, 0, 20)
		headerRow.Parent = card

		local iconLabel = Instance.new("ImageLabel")
		iconLabel.Image = image
		iconLabel.BackgroundTransparency = 1
		iconLabel.AnchorPoint = Vector2.new(0, 0.5)
		iconLabel.Size = UDim2.new(0, 16, 0, 16)
		iconLabel.Position = UDim2.new(0, 0, 0.5, 0)
		iconLabel.ZIndex = 2
		iconLabel.Parent = headerRow

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Text = title
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 14
		titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLabel.BackgroundTransparency = 1
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.AnchorPoint = Vector2.new(0, 0.5)
		titleLabel.Size = UDim2.new(1, -24, 1, 0)
		titleLabel.Position = UDim2.new(0, 23, 0.5, 0)
		titleLabel.ZIndex = 2
		titleLabel.Parent = headerRow

		if content ~= "" then
			local contentLabel = Instance.new("TextLabel")
			contentLabel.Text = content
			contentLabel.Font = Enum.Font.Gotham
			contentLabel.TextSize = 13
			contentLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
			contentLabel.BackgroundTransparency = 1
			contentLabel.TextXAlignment = Enum.TextXAlignment.Left
			contentLabel.TextYAlignment = Enum.TextYAlignment.Top
			contentLabel.TextWrapped = true
			contentLabel.AutomaticSize = Enum.AutomaticSize.Y
			contentLabel.Size = UDim2.new(1, 0, 0, 0)
			contentLabel.Position = UDim2.new(0, 0, 0, 26)
			contentLabel.ZIndex = 2
			contentLabel.Parent = card
		end

		local additionalFrame = nil
		local isExpanded = false

		if additional ~= "" then
			additionalFrame = Instance.new("Frame")
			additionalFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
			additionalFrame.BorderSizePixel = 0
			additionalFrame.Size = UDim2.new(1, 0, 0, 0)
			additionalFrame.ClipsDescendants = true
			additionalFrame.Position = UDim2.new(0, 0, 0, content ~= "" and 60 or 34)
			additionalFrame.Parent = wrapper
			additionalFrame.Visible = false
			addCorner(additionalFrame, 0, 8)
			addStroke(additionalFrame, Color3.fromRGB(50, 50, 60), 1)

			local addlPadding = Instance.new("UIPadding")
			addlPadding.PaddingLeft = UDim.new(0, 12)
			addlPadding.PaddingRight = UDim.new(0, 12)
			addlPadding.PaddingTop = UDim.new(0, 10)
			addlPadding.PaddingBottom = UDim.new(0, 10)
			addlPadding.Parent = additionalFrame

			local addLabel = Instance.new("TextLabel")
			addLabel.Text = additional
			addLabel.Font = Enum.Font.Gotham
			addLabel.TextSize = 12
			addLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
			addLabel.BackgroundTransparency = 1
			addLabel.TextXAlignment = Enum.TextXAlignment.Left
			addLabel.TextYAlignment = Enum.TextYAlignment.Top
			addLabel.TextWrapped = true
			addLabel.AutomaticSize = Enum.AutomaticSize.Y
			addLabel.Size = UDim2.new(1, 0, 0, 0)
			addLabel.Parent = additionalFrame

			local arrow = Instance.new("ImageLabel")
			arrow.Image = "rbxassetid://3944604212"
			arrow.BackgroundTransparency = 1
			arrow.ImageColor3 = Color3.fromRGB(120, 120, 130)
			arrow.AnchorPoint = Vector2.new(1, 0.5)
			arrow.Size = UDim2.new(0, 14, 0, 14)
			arrow.Position = UDim2.new(1, -5, 0.5, 0)
			arrow.Visible = false
			arrow.Parent = card
		end

		local timerTrack = Instance.new("Frame")
		timerTrack.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
		timerTrack.BorderSizePixel = 0
		timerTrack.Size = UDim2.new(0, sideBarWidth, 0, 0)
		timerTrack.Position = UDim2.new(0, notifWidth + sideBarGap, 0, 0)
		timerTrack.ClipsDescendants = true
		timerTrack.ZIndex = 2
		timerTrack.Parent = wrapper
		addCorner(timerTrack, 1, 0)

		local timerFill = Instance.new("Frame")
		timerFill.BackgroundColor3 = barColor
		timerFill.BorderSizePixel = 0
		timerFill.Size = UDim2.new(1, 0, 1, 0)
		timerFill.ZIndex = 3
		timerFill.Parent = timerTrack
		addCorner(timerFill, 1, 0)


		local isHovering = false
		local timeRemaining = duration

		local hoverDetector = Instance.new("TextButton")
		hoverDetector.Text = ""
		hoverDetector.BackgroundTransparency = 1
		hoverDetector.Size = UDim2.new(1, 0, 1, 0)
		hoverDetector.ZIndex = 10
		hoverDetector.Parent = card

		hoverDetector.MouseEnter:Connect(function() isHovering = true end)
		hoverDetector.MouseLeave:Connect(function() isHovering = false end)
		
		hoverDetector.MouseButton2Click:Connect(function()
			for index, ent in ipairs(notifStack) do
				if ent == stackEntry then
					table.remove(notifStack, index)
					break
				end
			end
			timeRemaining = 0
			tweenObj(card, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In,
				{Position = UDim2.new(1, 10, 0, 0)})
			tweenObj(timerTrack, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In,
				{Position = UDim2.new(0, notifWidth + sideBarGap + 50, 0, 0)})
			refNotifs(nil)
		end)

		hoverDetector.MouseButton1Click:Connect(function()
			if onClick then pcall(onClick) end
			if not additional or additional == "" then return end
			
			local mGui = Instance.new("ScreenGui")
			mGui.Name = "IsotopeModal"
			mGui.ResetOnSpawn = false
			mGui.DisplayOrder = 1000
			mGui.IgnoreGuiInset = true
			secGui(mGui)
			
			local backdrop = Instance.new("Frame")
			backdrop.BackgroundColor3 = Color3.new(0, 0, 0)	
			backdrop.BackgroundTransparency = 1
			backdrop.BorderSizePixel = 0
			backdrop.Size = UDim2.new(1, 0, 1, 0)
			backdrop.ZIndex = 1
			backdrop.Parent = mGui
			
			local blur = Instance.new("BlurEffect")
			blur.Size = 0
			blur.Parent = game:GetService("Lighting")
			TweenService:Create(blur, TweenInfo.new(0.3), {Size = 20}):Play()
			tweenObj(backdrop, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.45})
			
			local modalcard = Instance.new("Frame")
			modalcard.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
			modalcard.BorderSizePixel = 0
			modalcard.AnchorPoint = Vector2.new(0.5, 0.5)
			modalcard.Size = UDim2.new(0, 0, 0, 0)
			modalcard.Position = UDim2.new(0.5, 0, 0.5, 0)
			modalcard.ZIndex = 2
			modalcard.Parent = mGui
			addCorner(modalcard, 0, 12)
			addStroke(modalcard, Color3.fromRGB(60, 60, 70), 1)
			
			local animStyle = "Blob"
			if animStyle == "Blob" or animStyle == "Bounce" then
				TweenService:Create(modalcard, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{Size = UDim2.new(0, 420, 0, 0)}):Play()
				task.wait(0.1)
				TweenService:Create(modalcard, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{Size = UDim2.new(0, 420, 0, 220)}):Play()
			else
				TweenService:Create(modalcard, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					{Size = UDim2.new(0, 420, 0, 220)}):Play()
			end
			
			addPadding(modalcard, 20, 20, 24, 24)
			
			local titleLbl = Instance.new("TextLabel")
			titleLbl.Text = title
			titleLbl.Font = Enum.Font.GothamBold
			titleLbl.TextSize = 18
			titleLbl.TextColor3 = Color3.fromRGB(240, 240, 240)
			titleLbl.BackgroundTransparency = 1
			titleLbl.TextXAlignment = Enum.TextXAlignment.Left
			titleLbl.Size = UDim2.new(1, 0, 0, 24)
			titleLbl.Position = UDim2.new(0, 0, 0, 0)
			titleLbl.ZIndex = 3
			titleLbl.Parent = modalcard
			
			local contentLbl = Instance.new("TextLabel")
			contentLbl.Text = additional
			contentLbl.Font = Enum.Font.Gotham
			contentLbl.TextSize = 14
			contentLbl.TextColor3 = Color3.fromRGB(180, 180, 190)
			contentLbl.BackgroundTransparency = 1
			contentLbl.TextXAlignment = Enum.TextXAlignment.Left
			contentLbl.TextYAlignment = Enum.TextYAlignment.Top
			contentLbl.TextWrapped = true
			contentLbl.Size = UDim2.new(1, 0, 1, -60)
			contentLbl.Position = UDim2.new(0, 0, 0, 34)
			contentLbl.ZIndex = 3
			contentLbl.Parent = modalcard

			local dismissLbl = Instance.new("TextLabel")
			dismissLbl.Text = "Click anywhere to dismiss"
			dismissLbl.Font = Enum.Font.Gotham
			dismissLbl.TextSize = 11
			dismissLbl.TextColor3 = Color3.fromRGB(100, 100, 115)
			dismissLbl.BackgroundTransparency = 1
			dismissLbl.AnchorPoint = Vector2.new(0.5, 1)
			dismissLbl.Size = UDim2.new(1, 0, 0, 16)
			dismissLbl.Position = UDim2.new(0.5, 0, 1, -4)
			dismissLbl.ZIndex = 3
			dismissLbl.Parent = modalcard

			local closeBtn = Instance.new("TextButton")
			closeBtn.Text = ""
			closeBtn.BackgroundTransparency = 1
			closeBtn.Size = UDim2.new(1, 0, 1, 0)
			closeBtn.ZIndex = 4
			closeBtn.Parent = mGui
			
			local function dismissM()
				TweenService:Create(blur, TweenInfo.new(0.25), {Size = 0}):Play()
				tweenObj(backdrop, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 1})
				TweenService:Create(modalcard, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In),
					{Size = UDim2.new(0, 0, 0, 0)}):Play()
				task.wait(0.28)
				blur:Destroy()
				mGui:Destroy()
			end
			
			closeBtn.MouseButton1Click:Connect(dismissM)
		end)

		task.defer(function()
			local cardHeight = card.AbsoluteSize.Y
			if cardHeight == 0 then cardHeight = estimatedHeight end
			wrapper.Size = UDim2.new(0, notifWidth + sideBarWidth + sideBarGap, 0, cardHeight + 5)
			timerTrack.Size = UDim2.new(0, sideBarWidth, 0, cardHeight)
			stackEntry.estimatedHeight = cardHeight + 5
			refNotifs(1)
			local destinationY = stackEntry.targetY
			wrapper.Position = UDim2.new(1, notifRightMargin + 60, 0, destinationY)
			tweenObj(wrapper, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
				{Position = UDim2.new(1, -(notifWidth + sideBarWidth + sideBarGap + notifRightMargin), 0, destinationY)})
			tweenObj(card, 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
				{Position = UDim2.new(0, 0, 0, 0)})
		end)

		task.wait(0.5)

		while timeRemaining > 0 do
			if not wrapper.Parent then break end
			if not isHovering and not isExpanded then
				timeRemaining = timeRemaining - 0.1
				if timerFill.Parent then
					timerFill.Size = UDim2.new(1, 0, timeRemaining / duration, 0)
				end
			end
			task.wait(0.1)
		end

		for index, entry in ipairs(notifStack) do
			if entry == stackEntry then
				table.remove(notifStack, index)
				break
			end
		end

		wrapper.ClipsDescendants = false
		tweenObj(card, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In,
			{Position = UDim2.new(1, 10, 0, 0)})
		if additionalFrame then
			tweenObj(additionalFrame, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In, {Position = UDim2.new(1, 10, 0, 0)})
		end
		tweenObj(timerTrack, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In,
			{Position = UDim2.new(0, notifWidth + sideBarGap + 50, 0, 0)})
		refNotifs(nil)
		task.wait(0.38)
		wrapper.ClipsDescendants = true
		tweenObj(wrapper, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
			{Size = UDim2.new(0, notifWidth + sideBarWidth + sideBarGap, 0, 0)})
		task.wait(0.28)
		wrapper:Destroy()
	end)
end

function Isotope:Modal(config)
	config = config or {}
	local title = config.Name or "Notice"
	local content = config.Content or ""
	local additional = config.Additional or ""
	local onClose = config.OnClose or function() end

	local bodyText = additional ~= "" and (content .. "\n\n" .. additional) or content

	local mGui = Instance.new("ScreenGui")
	mGui.Name = "IsotopeModal"
	mGui.ResetOnSpawn = false
	mGui.DisplayOrder = 1000
	mGui.IgnoreGuiInset = true
	secGui(mGui)

	local backdrop = Instance.new("Frame")
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 1
	backdrop.BorderSizePixel = 0
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.ZIndex = 1
	backdrop.Parent = mGui

	local blur = Instance.new("BlurEffect")
	blur.Size = 0
	blur.Parent = game:GetService("Lighting")
	TweenService:Create(blur, TweenInfo.new(0.3), {Size = 20}):Play()
	tweenObj(backdrop, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.45})

	local notifTheme = getNotifTheme()
	local accentColor = config.DurationColor or notifTheme.Accent or Color3.fromRGB(0, 170, 255)

	local modalcard = Instance.new("Frame")
	modalcard.BackgroundColor3 = notifTheme.Main
	modalcard.BorderSizePixel = 0
	modalcard.AnchorPoint = Vector2.new(0.5, 0.5)
	modalcard.Size = UDim2.new(0, 0, 0, 0)
	modalcard.Position = UDim2.new(0.5, 0, 0.5, 0)
	modalcard.ZIndex = 2
	modalcard.Parent = mGui
	addCorner(modalcard, 0, 12)
	addStroke(modalcard, accentColor, 1.5)

	TweenService:Create(modalcard, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 440, 0, 0)}):Play()
	task.wait(0.1)
	TweenService:Create(modalcard, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 440, 0, 240)}):Play()

	addPadding(modalcard, 24, 20, 24, 24)

	local accentBar = Instance.new("Frame")
	accentBar.BackgroundColor3 = accentColor
	accentBar.BorderSizePixel = 0
	accentBar.Size = UDim2.new(1, 0, 0, 3)
	accentBar.Position = UDim2.new(0, 0, 0, 0)
	accentBar.ZIndex = 3
	accentBar.Parent = modalcard
	addCorner(accentBar, 0, 2)
	
	local pulseTask = task.spawn(function()
		while mGui and mGui.Parent do
			tweenObj(accentBar, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, {
				BackgroundTransparency = 0.5,
				Size = UDim2.new(1, 0, 0, 5),
			})
			task.wait(0.8)
			tweenObj(accentBar, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, {
				BackgroundTransparency = 0,
				Size = UDim2.new(1, 0, 0, 3),
			})
			task.wait(0.8)
		end
	end)

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Text = title
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 18
	titleLbl.TextColor3 = notifTheme.Text
	titleLbl.BackgroundTransparency = 1
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Size = UDim2.new(1, 0, 0, 24)
	titleLbl.Position = UDim2.new(0, 0, 0, 8)
	titleLbl.ZIndex = 3
	titleLbl.Parent = modalcard

	local divider = Instance.new("Frame")
	divider.BackgroundColor3 = notifTheme.Stroke
	divider.BorderSizePixel = 0
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.new(0, 0, 0, 38)
	divider.ZIndex = 3
	divider.Parent = modalcard

	local contentLbl = Instance.new("TextLabel")
	contentLbl.Text = content
	contentLbl.Font = Enum.Font.GothamSemibold
	contentLbl.TextSize = 14
	contentLbl.TextColor3 = notifTheme.Text
	contentLbl.BackgroundTransparency = 1
	contentLbl.TextXAlignment = Enum.TextXAlignment.Left
	contentLbl.TextYAlignment = Enum.TextYAlignment.Top
	contentLbl.TextWrapped = true
	contentLbl.Size = UDim2.new(1, 0, 0, 20)
	contentLbl.Position = UDim2.new(0, 0, 0, 48)
	contentLbl.ZIndex = 3
	contentLbl.Parent = modalcard

	if additional ~= "" then
		local additionalLbl = Instance.new("TextLabel")
		additionalLbl.Text = additional
		additionalLbl.Font = Enum.Font.Gotham
		additionalLbl.TextSize = 13
		additionalLbl.TextColor3 = notifTheme.TextDark
		additionalLbl.BackgroundTransparency = 1
		additionalLbl.TextXAlignment = Enum.TextXAlignment.Left
		additionalLbl.TextYAlignment = Enum.TextYAlignment.Top
		additionalLbl.TextWrapped = true
		additionalLbl.Size = UDim2.new(1, 0, 0, 60)
		additionalLbl.Position = UDim2.new(0, 0, 0, 74)
		additionalLbl.ZIndex = 3
		additionalLbl.Parent = modalcard
	end

	local dismissLbl = Instance.new("TextLabel")
	dismissLbl.Text = "Click anywhere to dismiss"
	dismissLbl.Font = Enum.Font.Gotham
	dismissLbl.TextSize = 11
	dismissLbl.TextColor3 = Color3.fromRGB(100, 100, 115)
	dismissLbl.BackgroundTransparency = 1
	dismissLbl.AnchorPoint = Vector2.new(0.5, 1)
	dismissLbl.Size = UDim2.new(1, 0, 0, 16)
	dismissLbl.Position = UDim2.new(0.5, 0, 1, -4)
	dismissLbl.ZIndex = 3
	dismissLbl.Parent = modalcard

	local function dismissM()
		task.cancel(pulseTask)
		TweenService:Create(blur, TweenInfo.new(0.25), {Size = 0}):Play()
		tweenObj(backdrop, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 1})
		TweenService:Create(modalcard, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{Size = UDim2.new(0, 0, 0, 0)}):Play()
		task.wait(0.28)
		blur:Destroy()
		mGui:Destroy()
		pcall(onClose)
	end

	local closeBtn = Instance.new("TextButton")
	closeBtn.Text = ""
	closeBtn.BackgroundTransparency = 1
	closeBtn.Size = UDim2.new(1, 0, 1, 0)
	closeBtn.ZIndex = 4
	closeBtn.Parent = mGui
	closeBtn.MouseButton1Click:Connect(dismissM)
end

local function saveFlags(folder, file)
	if not (writefile and isfolder and makefolder) then return end
	pcall(function()
		if not isfolder(folder) then makefolder(folder) end
		local saveData = {
			__version = Isotope.Version,
			__gameId = game.GameId,
			__scriptKey = Isotope._ScriptKey,
		}
		for key, flagObj in pairs(Isotope.Flags) do
			if Isotope.SaveCfg or flagObj.Save then
				saveData[key] = flagObj.Value
			end
		end
		writefile(folder .. "/" .. file .. ".json", HttpService:JSONEncode(saveData))
	end)
end

function Isotope:AddOwnerButton(config)
	config = config or {}
	local buttonConfig = {
		Name = config.Name or "Button",
		Icon = config.Icon or "",
		Tooltip = config.Tooltip or "",
		Callback = config.Callback or function() end,
		Order = config.Order or 100,
		Color = config.Color or nil, 
		Dropdown = config.Dropdown or nil 
	}
	table.insert(Isotope.OwnerButtons, buttonConfig)
	return buttonConfig
end


function Isotope:ClearOwnerButtons()
	Isotope.OwnerButtons = {}
end

function Isotope:Topbar(theme)
	if not Isotope.ShowTopbar then return end
	if Isotope._TopbarGui and Isotope._TopbarGui.Parent then
		Isotope._TopbarGui:Destroy()
	end

	local tabs = Isotope._Tabs
	local tabCount = #tabs
	if tabCount == 0 then return end

	local buttonSize = 34
	local buttonGap = 5
	local horizontalPad = 8
	local verticalPad = 7
	local maxPerRow = 6
	local expandButtonWidth = 26

	local accentColor = theme.Accent or Color3.fromRGB(0, 170, 255)
	local panelBgColor = theme.Second or Color3.fromRGB(25, 25, 25)
	local buttonBgColor = theme.Main or Color3.fromRGB(32, 32, 32)
	local strokeColor = theme.Stroke or Color3.fromRGB(60, 60, 60)
	local textColor = theme.Text or Color3.fromRGB(240, 240, 240)
	local textDarkColor = theme.TextDark or Color3.fromRGB(150, 150, 150)

	local rowCount = math.ceil(tabCount / maxPerRow)
	local MultipleRows = rowCount > 1
	local firstRowCount = math.min(tabCount, maxPerRow)

	local firstRowWidth = firstRowCount * buttonSize + (firstRowCount - 1) * buttonGap

	-- calcing
	local ownerButtonWidth = 0
	local ownerButtonCount = #Isotope.OwnerButtons
	if ownerButtonCount > 0 then
		ownerButtonWidth = ownerButtonCount * (buttonSize + buttonGap)
	end

	local baseWidth = horizontalPad + firstRowWidth + buttonGap + buttonSize + horizontalPad
	local ownerSectionWidth = ownerButtonCount > 0 and (ownerButtonWidth + 20) or 0
	local searchX = horizontalPad + firstRowWidth + buttonGap + (ownerButtonCount > 0 and (ownerSectionWidth + buttonSize + buttonGap) or 0)
	
	local expandWidth = MultipleRows and (buttonGap + expandButtonWidth) or 0
	local panelWidth = searchX + buttonSize + horizontalPad + expandWidth

	local collapsedHeight = verticalPad + buttonSize + verticalPad
	local expandedHeight = verticalPad + (rowCount * buttonSize + (rowCount - 1) * buttonGap) + verticalPad
	local isExpanded = false

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "IsotopeTopbar"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 997
	screenGui.IgnoreGuiInset = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	secGui(screenGui)
	Isotope._TopbarGui = screenGui

	local topbarPanel = Instance.new("Frame")
	topbarPanel.Name = "TopbarPanel"
	topbarPanel.BackgroundColor3 = panelBgColor
	topbarPanel.BackgroundTransparency = 0.06
	topbarPanel.BorderSizePixel = 0
	topbarPanel.AnchorPoint = Vector2.new(0.5, 0)
	topbarPanel.Size = UDim2.new(0, panelWidth, 0, collapsedHeight)
	topbarPanel.ClipsDescendants = true
	topbarPanel.Position = UDim2.new(0.5, 0, 0, 14)
	topbarPanel.Parent = screenGui
	addCorner(topbarPanel, 0, 10)
	addStroke(topbarPanel, strokeColor, 1)

	topbarPanel.Position = UDim2.new(0.5, 0, 0, -(collapsedHeight + 20))
	tweenObj(topbarPanel, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
		{Position = UDim2.new(0.5, 0, 0, 14)})

	do
		local isDragging = false
		local dragStartMouse = Vector2.new()
		local dragStartPos = UDim2.new()
		topbarPanel.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				isDragging = true
				dragStartMouse = input.Position
				dragStartPos = topbarPanel.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						isDragging = false
					end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = input.Position - dragStartMouse
				topbarPanel.Position = UDim2.new(
					dragStartPos.X.Scale,
					dragStartPos.X.Offset + delta.X,
					dragStartPos.Y.Scale,
					dragStartPos.Y.Offset + delta.Y
				)
			end
		end)
	end

	if MultipleRows then
		local expandBtn = Instance.new("TextButton")
		expandBtn.Text = "..."
		expandBtn.Font = Enum.Font.GothamBold
		expandBtn.TextSize = 13
		expandBtn.TextColor3 = textDarkColor
		expandBtn.AutoButtonColor = false
		expandBtn.BackgroundColor3 = buttonBgColor
		expandBtn.BorderSizePixel = 0
		expandBtn.AnchorPoint = Vector2.new(0, 0)
		expandBtn.Size = UDim2.new(0, expandButtonWidth, 0, buttonSize)
		expandBtn.Position = UDim2.new(0, searchX + buttonSize + buttonGap, 0, verticalPad)
		expandBtn.ZIndex = 5
		expandBtn.Parent = topbarPanel
		addCorner(expandBtn, 0, 6)
		addStroke(expandBtn, strokeColor, 1)

		expandBtn.MouseEnter:Connect(function()
			tweenObj(expandBtn, 0.15, nil, nil, {TextColor3 = Color3.fromRGB(210, 210, 235)})
		end)
		expandBtn.MouseLeave:Connect(function()
			tweenObj(expandBtn, 0.15, nil, nil, {TextColor3 = textDarkColor})
		end)
		expandBtn.MouseButton1Click:Connect(function()
			isExpanded = not isExpanded
			expandBtn.Text = isExpanded and "x" or "..."
			local targetHeight = isExpanded and expandedHeight or collapsedHeight
			tweenObj(topbarPanel, 0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
				{Size = UDim2.new(0, panelWidth, 0, targetHeight)})
		end)
	end

	local activeTooltip = nil

	local function showTooltip(tabName, absoluteX, absoluteY)
		if activeTooltip then
			activeTooltip:Destroy()
			activeTooltip = nil
		end
		local tooltip = Instance.new("TextLabel")
		tooltip.Text = tabName
		tooltip.Font = Enum.Font.GothamSemibold
		tooltip.TextSize = 11
		tooltip.TextColor3 = Color3.fromRGB(220, 220, 235)
		tooltip.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
		tooltip.BackgroundTransparency = 0.05
		tooltip.BorderSizePixel = 0
		tooltip.AnchorPoint = Vector2.new(0.5, 0)
		tooltip.AutomaticSize = Enum.AutomaticSize.X
		tooltip.Size = UDim2.new(0, 0, 0, 20)
		tooltip.Position = UDim2.new(0, absoluteX, 0, absoluteY + buttonSize + 6)
		tooltip.ZIndex = 100
		tooltip.Parent = screenGui
		addCorner(tooltip, 0, 4)
		addStroke(tooltip, strokeColor, 1)
		local tooltipPadding = Instance.new("UIPadding")
		tooltipPadding.PaddingLeft = UDim.new(0, 6)
		tooltipPadding.PaddingRight = UDim.new(0, 6)
		tooltipPadding.Parent = tooltip
		activeTooltip = tooltip
	end

	local function hideTooltip()
		if activeTooltip then
			activeTooltip:Destroy()
			activeTooltip = nil
		end
	end

	for tabIndex, tabEntry in ipairs(tabs) do
		local row = math.floor((tabIndex - 1) / maxPerRow)
		local col = (tabIndex - 1) % maxPerRow
		local buttonX = horizontalPad + col * (buttonSize + buttonGap)
		local buttonY = verticalPad + row * (buttonSize + buttonGap)

		local tabButton = Instance.new("TextButton")
		tabButton.Text = ""
		tabButton.AutoButtonColor = false
		tabButton.BackgroundColor3 = buttonBgColor
		tabButton.BorderSizePixel = 0
		tabButton.AnchorPoint = Vector2.new(0, 0)
		tabButton.Size = UDim2.new(0, buttonSize, 0, buttonSize)
		tabButton.Position = UDim2.new(0, buttonX, 0, buttonY)
		tabButton.ZIndex = 3
		tabButton.Parent = topbarPanel
		addCorner(tabButton, 0, 7)

		local tabIcon = Instance.new("ImageLabel")
		tabIcon.Image = tabEntry.icon or ""
		tabIcon.BackgroundTransparency = 1
		tabIcon.ImageColor3 = textDarkColor
		tabIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		tabIcon.Size = UDim2.new(0, 18, 0, 18)
		tabIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		tabIcon.ZIndex = 4
		tabIcon.Parent = tabButton

		tabButton.MouseEnter:Connect(function()
			tweenObj(tabButton, 0.12, nil, nil, {BackgroundColor3 = Color3.fromRGB(
				math.clamp(buttonBgColor.R * 255 + 13, 0, 255),
				math.clamp(buttonBgColor.G * 255 + 13, 0, 255),
				math.clamp(buttonBgColor.B * 255 + 13, 0, 255))})
			tweenObj(tabIcon, 0.12, nil, nil, {ImageColor3 = textColor})
			local absPos = tabButton.AbsolutePosition
			showTooltip(tabEntry.name, absPos.X + buttonSize / 2, absPos.Y)
		end)
		tabButton.MouseLeave:Connect(function()
			tweenObj(tabButton, 0.12, nil, nil, {BackgroundColor3 = buttonBgColor})
			tweenObj(tabIcon, 0.12, nil, nil, {ImageColor3 = textDarkColor})
			hideTooltip()
		end)
		tabButton.MouseButton1Click:Connect(function()
			hideTooltip()
			tweenObj(tabButton, 0.07, nil, nil, {BackgroundColor3 = accentColor})
			tweenObj(tabButton, 0.22, nil, nil, {BackgroundColor3 = buttonBgColor})
			if Isotope._RestoreRef then pcall(Isotope._RestoreRef) end
			pcall(tabEntry.selectFn)
		end)
	end

	local ownerStartX = horizontalPad + firstRowWidth + buttonGap + buttonSize + buttonGap + 10

	if ownerButtonCount > 0 then
		local ownerDivider = Instance.new("Frame")
		ownerDivider.BackgroundColor3 = strokeColor
		ownerDivider.BorderSizePixel = 0
		ownerDivider.Size = UDim2.new(0, 1, 0, buttonSize - 8)
		ownerDivider.Position = UDim2.new(0, ownerStartX - 5, 0, verticalPad + 4)
		ownerDivider.Parent = topbarPanel

		table.sort(Isotope.OwnerButtons, function(a, b) return a.Order < b.Order end)

		for idx, btnConfig in ipairs(Isotope.OwnerButtons) do
			local btnX = ownerStartX + ((idx - 1) * (buttonSize + buttonGap))

			local ownerBtn = Instance.new("TextButton")
			ownerBtn.Text = ""
			ownerBtn.AutoButtonColor = false
			ownerBtn.BackgroundColor3 = btnConfig.Color and btnConfig.Color or buttonBgColor
			ownerBtn.BorderSizePixel = 0
			ownerBtn.Size = UDim2.new(0, buttonSize, 0, buttonSize)
			ownerBtn.Position = UDim2.new(0, btnX, 0, verticalPad)
			ownerBtn.ZIndex = 3
			ownerBtn.Parent = topbarPanel
			addCorner(ownerBtn, 0, 7)

			if btnConfig.Color then
				addStroke(ownerBtn, btnConfig.Color, 1)
			else
				addStroke(ownerBtn, strokeColor, 1)
			end

			local ownerIcon = Instance.new("ImageLabel")
			ownerIcon.Image = btnConfig.Icon
			ownerIcon.BackgroundTransparency = 1
			ownerIcon.ImageColor3 = textColor
			ownerIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			ownerIcon.Size = UDim2.new(0, 18, 0, 18)
			ownerIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
			ownerIcon.ZIndex = 4
			ownerIcon.Parent = ownerBtn

			ownerBtn.MouseEnter:Connect(function()
				tweenObj(ownerBtn, 0.12, nil, nil, {BackgroundColor3 = Color3.fromRGB(
					math.clamp((btnConfig.Color or buttonBgColor).R * 255 + 20, 0, 255),
					math.clamp((btnConfig.Color or buttonBgColor).G * 255 + 20, 0, 255),
					math.clamp((btnConfig.Color or buttonBgColor).B * 255 + 20, 0, 255))})
				if btnConfig.Tooltip and btnConfig.Tooltip ~= "" then
					local absPos = ownerBtn.AbsolutePosition
					showTooltip(btnConfig.Tooltip, absPos.X + buttonSize / 2, absPos.Y)
				end
			end)

			ownerBtn.MouseLeave:Connect(function()
				tweenObj(ownerBtn, 0.12, nil, nil, {BackgroundColor3 = btnConfig.Color or buttonBgColor})
				hideTooltip()
			end)

			ownerBtn.MouseButton1Click:Connect(function()
				hideTooltip()
				tweenObj(ownerBtn, 0.07, nil, nil, {Size = UDim2.new(0, buttonSize * 0.9, 0, buttonSize * 0.9)})
				tweenObj(ownerBtn, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
					{Size = UDim2.new(0, buttonSize, 0, buttonSize)})

				if btnConfig.Dropdown then
					local existing = topbarPanel:FindFirstChild("__OwnerDropdown")
					if existing then
						existing:Destroy()
						return
					end

					local dropMenu = Instance.new("Frame")
					dropMenu.Name = "__OwnerDropdown"
					dropMenu.BackgroundColor3 = panelBgColor
					dropMenu.BorderSizePixel = 0
					dropMenu.AutomaticSize = Enum.AutomaticSize.Y
					dropMenu.Size = UDim2.new(0, 120, 0, 0)
					dropMenu.Position = UDim2.new(0, btnX, 0, collapsedHeight + 4)
					dropMenu.ZIndex = 20
					dropMenu.ClipsDescendants = true
					dropMenu.Parent = topbarPanel
					addCorner(dropMenu, 0, 6)
					addStroke(dropMenu, strokeColor, 1)

					local dropLayout = addListLayout(dropMenu, 0)
					addPadding(dropMenu, 4, 4, 0, 0)

					for optIndex, option in ipairs(btnConfig.Dropdown) do
						local optBtn = Instance.new("TextButton")
						optBtn.Text = ""
						optBtn.BackgroundColor3 = buttonBgColor
						optBtn.BackgroundTransparency = 1
						optBtn.BorderSizePixel = 0
						optBtn.Size = UDim2.new(1, 0, 0, 28)
						optBtn.AutoButtonColor = false
						optBtn.ZIndex = 21
						optBtn.LayoutOrder = optIndex
						optBtn.Parent = dropMenu

						local optLbl = Instance.new("TextLabel")
						optLbl.Text = tostring(option)
						optLbl.Font = Enum.Font.GothamSemibold
						optLbl.TextSize = 12
						optLbl.TextColor3 = textColor
						optLbl.TextTransparency = 0.2
						optLbl.BackgroundTransparency = 1
						optLbl.TextXAlignment = Enum.TextXAlignment.Left
						optLbl.Size = UDim2.new(1, -20, 1, 0)
						optLbl.Position = UDim2.new(0, 10, 0, 0)
						optLbl.ZIndex = 22
						optLbl.Parent = optBtn

						optBtn.MouseEnter:Connect(function()
							tweenObj(optBtn, 0.12, nil, nil, {BackgroundTransparency = 0.5})
							tweenObj(optLbl, 0.12, nil, nil, {TextTransparency = 0})
						end)
						optBtn.MouseLeave:Connect(function()
							tweenObj(optBtn, 0.12, nil, nil, {BackgroundTransparency = 1})
							tweenObj(optLbl, 0.12, nil, nil, {TextTransparency = 0.2})
						end)
						optBtn.MouseButton1Click:Connect(function()
							dropMenu:Destroy()
							pcall(btnConfig.Callback, option)
						end)
					end

					local closeConn
					closeConn = UserInputService.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							task.defer(function()
								if dropMenu and dropMenu.Parent then
									local mp = UserInputService:GetMouseLocation()
									local ap = dropMenu.AbsolutePosition
									local as = dropMenu.AbsoluteSize
									if not (mp.X >= ap.X and mp.X <= ap.X + as.X and
										mp.Y >= ap.Y and mp.Y <= ap.Y + as.Y) then
										dropMenu:Destroy()
										closeConn:Disconnect()
									end
								end
							end)
						end
					end)
				else
					pcall(btnConfig.Callback)
				end
			end)
		end
	end



	local searchOpen = false
	local searchButton = Instance.new("TextButton")
	searchButton.Text = ""
	searchButton.AutoButtonColor = false
	searchButton.BackgroundColor3 = buttonBgColor
	searchButton.BorderSizePixel = 0
	searchButton.AnchorPoint = Vector2.new(0, 0)
	searchButton.Size = UDim2.new(0, buttonSize, 0, buttonSize)
	searchButton.Position = UDim2.new(0, searchX, 0, verticalPad)
	searchButton.ZIndex = 5
	searchButton.Parent = topbarPanel
	addCorner(searchButton, 0, 7)
	addStroke(searchButton, strokeColor, 1)

	local searchIcon = Instance.new("ImageLabel")
	searchIcon.Image = "rbxassetid://91129038063259"
	searchIcon.BackgroundTransparency = 1
	searchIcon.ImageColor3 = textDarkColor
	searchIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	searchIcon.Size = UDim2.new(0, 16, 0, 16)
	searchIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	searchIcon.ZIndex = 6
	searchIcon.Parent = searchButton

	local searchPanel = Instance.new("Frame")
	searchPanel.BackgroundColor3 = panelBgColor
	searchPanel.BackgroundTransparency = 0
	searchPanel.BorderSizePixel = 0
	searchPanel.AnchorPoint = Vector2.new(0, 0)
	searchPanel.Size = UDim2.new(0, panelWidth, 0, collapsedHeight)
	searchPanel.Position = UDim2.new(0, 0, 0, 0)
	searchPanel.ZIndex = 50
	searchPanel.ClipsDescendants = false
	searchPanel.Visible = false
	searchPanel.Parent = screenGui
	addCorner(searchPanel, 0, 8)
	addStroke(searchPanel, strokeColor, 1)

	local function syncPanel()
		if not searchPanel or not topbarPanel then return end
		local topbarAbsPos = topbarPanel.AbsolutePosition
		local topbarAbsSize = topbarPanel.AbsoluteSize
		searchPanel.Position = UDim2.new(
			0, topbarAbsPos.X,
			0, topbarAbsPos.Y + topbarAbsSize.Y + 6
		)
	end

	topbarPanel:GetPropertyChangedSignal("Position"):Connect(syncPanel)
	topbarPanel:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncPanel)

	local searchBoxWrapper = Instance.new("Frame")
	searchBoxWrapper.BackgroundColor3 = theme.Main or Color3.fromRGB(28, 28, 36)
	searchBoxWrapper.BorderSizePixel = 0
	searchBoxWrapper.AnchorPoint = Vector2.new(0.5, 0)
	searchBoxWrapper.Size = UDim2.new(1, -16, 0, 26)
	searchBoxWrapper.Position = UDim2.new(0.5, 0, 0, (collapsedHeight - 26) / 2)
	searchBoxWrapper.ZIndex = 51
	searchBoxWrapper.Parent = searchPanel
	addCorner(searchBoxWrapper, 0, 6)
	addStroke(searchBoxWrapper, Color3.fromRGB(55, 55, 70), 1)

	local searchBox = Instance.new("TextBox")
	searchBox.BackgroundTransparency = 1
	searchBox.PlaceholderText = "search..."
	searchBox.PlaceholderColor3 = Color3.fromRGB(75, 75, 95)
	searchBox.Text = ""
	searchBox.Font = Enum.Font.GothamSemibold
	searchBox.TextSize = 12
	searchBox.TextColor3 = Color3.fromRGB(210, 210, 230)
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.ClearTextOnFocus = false
	searchBox.Size = UDim2.new(1, -12, 1, 0)
	searchBox.Position = UDim2.new(0, 8, 0, 0)
	searchBox.ZIndex = 52
	searchBox.Parent = searchBoxWrapper

	local searchHolder = Instance.new("Frame")
	searchHolder.BackgroundTransparency = 1
	searchHolder.BorderSizePixel = 0
	searchHolder.Size = UDim2.new(1, -12, 0, 0)
	searchHolder.Position = UDim2.new(0, 6, 0, collapsedHeight)
	searchHolder.ZIndex = 51
	searchHolder.AutomaticSize = Enum.AutomaticSize.Y
	searchHolder.Parent = searchPanel
	local searchResultLayout = addListLayout(searchHolder, 3)
	addPadding(searchHolder, 4, 6, 0, 0)
	searchResultLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		local resultsHeight = searchResultLayout.AbsoluteContentSize.Y + 14
		tweenObj(searchPanel, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
			{Size = UDim2.new(0, panelWidth, 0, collapsedHeight + resultsHeight)})
	end)

	local function buildIndex()
		local index = {}
		local seen = {}
		for flagName, flagObj in pairs(Isotope.Flags) do
			local tabRef = nil
			for _, entry in ipairs(Isotope._ElementRegistry) do
				if entry.obj == flagObj then
					tabRef = entry.tab
					break
				end
			end
			table.insert(index, {key = flagName, obj = flagObj, tab = tabRef})
			seen[flagObj] = true
		end
		for _, entry in ipairs(Isotope._ElementRegistry) do
			if not seen[entry.obj] then
				table.insert(index, {key = entry.name, obj = entry.obj, tab = entry.tab})
				seen[entry.obj] = true
			end
		end
		for _, bindEntry in ipairs(Isotope.Binds) do
			if not seen[bindEntry.Bind] then
				table.insert(index, {key = bindEntry.Name, obj = bindEntry.Bind, tab = bindEntry.tab})
				seen[bindEntry.Bind] = true
			end
		end
		return index
	end

	local function closeSearch(onComplete)
		searchOpen = false
		local closeTween = TweenService:Create(searchPanel,
			TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{BackgroundTransparency = 1, Size = UDim2.new(0, panelWidth, 0, 0)})
		tweenObj(searchIcon, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
			{ImageColor3 = textDarkColor})
		tweenObj(searchButton, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
			{BackgroundColor3 = buttonBgColor})
		closeTween.Completed:Connect(function()
			searchPanel.Visible = false
			searchBox.Text = ""
			for _, child in ipairs(searchHolder:GetChildren()) do
				if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
					child:Destroy()
				end
			end
			if onComplete then
				onComplete()
			end
		end)
		closeTween:Play()
	end

	local function runSearch(query)
		for _, child in ipairs(searchHolder:GetChildren()) do
			if child:IsA("TextButton") or child:IsA("Frame") then
				child:Destroy()
			end
		end
		if query == "" then return end
		local lowerQuery = query:lower()
		local searchIndex = buildIndex()
		local exactMatches = {}
		local partialMatches = {}
		for _, entry in ipairs(searchIndex) do
			local lowerName = entry.key:lower()
			if lowerName == lowerQuery then
				table.insert(exactMatches, entry)
			elseif lowerName:find(lowerQuery, 1, true) then
				table.insert(partialMatches, entry)
			end
		end
		local results = {}
		for _, match in ipairs(exactMatches) do table.insert(results, match) end
		for _, match in ipairs(partialMatches) do table.insert(results, match) end

		for resultIndex = 1, math.min(#results, 4) do
			local entry = results[resultIndex]
			local resultRow = Instance.new("TextButton")
			resultRow.Text = ""
			resultRow.AutoButtonColor = false
			resultRow.BackgroundColor3 = buttonBgColor
			resultRow.BackgroundTransparency = 0.3
			resultRow.BorderSizePixel = 0
			resultRow.Size = UDim2.new(1, 0, 0, buttonSize - 4)
			resultRow.ZIndex = 7
			resultRow.Parent = searchHolder
			addCorner(resultRow, 0, 5)

			local resultNameLabel = Instance.new("TextLabel")
			resultNameLabel.Text = entry.key
			resultNameLabel.Font = Enum.Font.GothamSemibold
			resultNameLabel.TextSize = 11
			resultNameLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
			resultNameLabel.BackgroundTransparency = 1
			resultNameLabel.TextXAlignment = Enum.TextXAlignment.Left
			resultNameLabel.Size = UDim2.new(1, -12, 1, 0)
			resultNameLabel.Position = UDim2.new(0, 8, 0, 0)
			resultNameLabel.ZIndex = 8
			resultNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
			resultNameLabel.Parent = resultRow

			if entry.obj and entry.obj.Type == "Toggle" then
				local valueBadge = Instance.new("TextLabel")
				valueBadge.Text = entry.obj.Value and "on" or "off"
				valueBadge.Font = Enum.Font.GothamBold
				valueBadge.TextSize = 10
				valueBadge.TextColor3 = entry.obj.Value and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(150, 150, 165)
				valueBadge.BackgroundTransparency = 1
				valueBadge.TextXAlignment = Enum.TextXAlignment.Right
				valueBadge.Size = UDim2.new(0, 30, 1, 0)
				valueBadge.Position = UDim2.new(1, -10, 0, 0)
				valueBadge.ZIndex = 8
				valueBadge.Parent = resultRow
			elseif entry.obj and entry.obj.Type == "Slider" then
				local valueBadge = Instance.new("TextLabel")
				valueBadge.Text = tostring(entry.obj.Value)
				valueBadge.Font = Enum.Font.GothamBold
				valueBadge.TextSize = 10
				valueBadge.TextColor3 = Color3.fromRGB(150, 150, 165)
				valueBadge.BackgroundTransparency = 1
				valueBadge.TextXAlignment = Enum.TextXAlignment.Right
				valueBadge.Size = UDim2.new(0, 30, 1, 0)
				valueBadge.Position = UDim2.new(1, -10, 0, 0)
				valueBadge.ZIndex = 8
				valueBadge.Parent = resultRow
			end

			resultRow.MouseEnter:Connect(function()
				tweenObj(resultRow, 0.1, nil, nil, {BackgroundTransparency = 0.1})
			end)
			resultRow.MouseLeave:Connect(function()
				tweenObj(resultRow, 0.1, nil, nil, {BackgroundTransparency = 0.3})
			end)

			resultRow.MouseButton1Click:Connect(function()
				local targetTab = entry.tab
				if targetTab then
					closeSearch(function()
						if Isotope._RestoreRef then pcall(Isotope._RestoreRef) end
						pcall(targetTab.selectFn)
					end)
				elseif entry.obj and entry.obj.Type == "Toggle" and entry.obj.Set then
					entry.obj:Set(not entry.obj.Value)
				end
			end)
		end
	end

	local function openSearch()
		searchOpen = true
		syncPanel()
		searchPanel.Size = UDim2.new(0, panelWidth, 0, 0)
		searchPanel.BackgroundTransparency = 1
		searchPanel.Visible = true
		tweenObj(searchPanel, 0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
			{BackgroundTransparency = 0, Size = UDim2.new(0, panelWidth, 0, collapsedHeight)})
		tweenObj(searchIcon, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
			{ImageColor3 = accentColor})
		tweenObj(searchButton, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
			{BackgroundColor3 = Color3.fromRGB(18, 28, 48)})
		task.defer(function() searchBox:CaptureFocus() end)
	end

	searchButton.MouseEnter:Connect(function()
		if not searchOpen then
			tweenObj(searchIcon, 0.15, nil, nil, {ImageColor3 = Color3.fromRGB(210, 210, 235)})
		end
	end)
	searchButton.MouseLeave:Connect(function()
		if not searchOpen then
			tweenObj(searchIcon, 0.15, nil, nil, {ImageColor3 = textDarkColor})
		end
	end)
	searchButton.MouseButton1Click:Connect(function()
		if searchOpen then closeSearch(nil) else openSearch() end
	end)

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		runSearch(searchBox.Text)
	end)

	searchBox.FocusLost:Connect(function(pressedEnter)
		if not pressedEnter then
			task.wait(0.15)
			if searchOpen then closeSearch(nil) end
		end
	end)

	return screenGui
end

function Isotope:Radial(theme)
	if not Isotope.ShowRadial then return end
	if not Isotope.RadialHotkey then
		warn("Isotope >> ShowRadial = true but RadialHotkey is nil")
		return
	end
	if Isotope._RadialGui and Isotope._RadialGui.Parent then
		Isotope._RadialGui:Destroy()
	end

	local tabs = Isotope._Tabs
	if #tabs == 0 then return end
	local tabCount = #tabs

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "IsotopeRadial"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 999
	screenGui.IgnoreGuiInset = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	secGui(screenGui)
	Isotope._RadialGui = screenGui

	local ringRadius = 150
	local innerRadius = 56
	local cardWidth = 110
	local cardHeight = 64
	local containerSize = (ringRadius + cardHeight) * 2 + 40
	local twoPi = math.pi * 2
	local segmentAngle = twoPi / tabCount

	local accentColor = theme.Accent or Color3.fromRGB(0, 170, 255)
	local mainColor = theme.Main or Color3.fromRGB(15, 15, 20)
	local secondColor = theme.Second or Color3.fromRGB(22, 22, 30)
	local strokeColor = theme.Stroke or Color3.fromRGB(45, 45, 65)
	local textColor = theme.Text or Color3.fromRGB(220, 220, 240)
	local textDarkColor = theme.TextDark or Color3.fromRGB(160, 160, 185)
	
	local spinRing = Instance.new("ImageLabel")
	spinRing.Image = "rbxassetid://4805639000"
	spinRing.BackgroundTransparency = 1
	spinRing.AnchorPoint = Vector2.new(0.5, 0.5)
	spinRing.Size = UDim2.new(0, (innerRadius + 6) * 2, 0, (innerRadius + 6) * 2)
	spinRing.Position = UDim2.new(0.5, 0, 0.5, 0)
	spinRing.ImageTransparency = 0.75
	spinRing.ImageColor3 = accentColor
	spinRing.ZIndex = 7
	spinRing.Visible = false

	local backdrop = Instance.new("Frame")
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 1
	backdrop.BorderSizePixel = 0
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.Visible = false
	backdrop.ZIndex = 1
	backdrop.Parent = screenGui

	local container = Instance.new("Frame")
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
	container.Size = UDim2.new(0, containerSize, 0, containerSize)
	container.Visible = false
	container.ZIndex = 2
	container.Parent = screenGui
	spinRing.Parent = container

	local centerCircle = Instance.new("Frame")
	centerCircle.BackgroundColor3 = mainColor
	centerCircle.BorderSizePixel = 0
	centerCircle.AnchorPoint = Vector2.new(0.5, 0.5)
	centerCircle.Size = UDim2.new(0, innerRadius * 2, 0, innerRadius * 2)
	centerCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
	centerCircle.ZIndex = 8
	centerCircle.Parent = container
	addCorner(centerCircle, 1, 0)
	addStroke(centerCircle, strokeColor, 1.5)

	local centerHint = Instance.new("TextLabel")
	centerHint.Text = Isotope.RadialMode == "hold" and "release\nto cancel" or "click\nto select"
	centerHint.Font = Enum.Font.Gotham
	centerHint.TextSize = 10
	centerHint.TextColor3 = theme.TextDark or Color3.fromRGB(90, 90, 115)
	centerHint.BackgroundTransparency = 1
	centerHint.AnchorPoint = Vector2.new(0.5, 1)
	centerHint.Size = UDim2.new(1, -8, 0.45, 0)
	centerHint.Position = UDim2.new(0.5, 0, 1, -6)
	centerHint.TextXAlignment = Enum.TextXAlignment.Center
	centerHint.TextWrapped = true
	centerHint.ZIndex = 9
	centerHint.Parent = centerCircle

	local centerName = Instance.new("TextLabel")
	centerName.Text = ""
	centerName.Font = Enum.Font.GothamBold
	centerName.TextSize = 13
	centerName.TextColor3 = textColor
	centerName.BackgroundTransparency = 1
	centerName.AnchorPoint = Vector2.new(0.5, 0)
	centerName.Size = UDim2.new(1, -10, 0.5, 0)
	centerName.Position = UDim2.new(0.5, 0, 0.08, 0)
	centerName.TextXAlignment = Enum.TextXAlignment.Center
	centerName.TextWrapped = true
	centerName.ZIndex = 9
	centerName.Parent = centerCircle
	
	local spinTask = nil
	local segmentFinalPositions = {}
	
	local segments = {}
	local hoveredIndex = nil

	local function setHovered(index)
		if hoveredIndex == index then return end
		local prevIndex = hoveredIndex
		hoveredIndex = index
		centerName.Text = index and tabs[index].name or ""
		for segIndex, segment in ipairs(segments) do
			local isActive = (segIndex == index)
			tweenObj(segment.frame, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
				BackgroundColor3 = isActive and accentColor or secondColor,
				BackgroundTransparency = isActive and 0 or 0.12,
			})
			if segment.icon then
				tweenObj(segment.icon, 0.12, nil, nil, {
					ImageColor3 = isActive and Color3.new(1, 1, 1) or textDarkColor,
				})
			end
			if segment.label then
				tweenObj(segment.label, 0.12, nil, nil, {
					TextColor3 = isActive and Color3.new(1, 1, 1) or Color3.fromRGB(180, 180, 205),
					TextTransparency = isActive and 0 or 0.25,
				})
				if isActive then
					tweenObj(segment.frame, 0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
						{Size = UDim2.new(0, cardWidth * 1.08, 0, cardHeight * 1.08)})
				elseif segIndex == prevIndex then
					tweenObj(segment.frame, 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
						{Size = UDim2.new(0, cardWidth, 0, cardHeight)})
				end
			end
		end
	end

	for segIndex = 1, tabCount do
		local tabEntry = tabs[segIndex]
		local angle = -math.pi / 2 + segmentAngle * (segIndex - 1) + segmentAngle / 2
		local posX = ringRadius * math.cos(angle)
		local posY = ringRadius * math.sin(angle)
		segmentFinalPositions[segIndex] = {x = posX, y = posY}

		local card = Instance.new("Frame")
		card.BackgroundColor3 = secondColor
		card.BackgroundTransparency = 0.12
		card.BorderSizePixel = 0
		card.AnchorPoint = Vector2.new(0.5, 0.5)
		card.Size = UDim2.new(0, cardWidth, 0, cardHeight)
		card.Position = UDim2.new(0.5, posX, 0.5, posY)
		card.ZIndex = 3
		card.Parent = container
		addCorner(card, 0, 10)
		addStroke(card, strokeColor, 1)

		local cardIcon = nil
		local cardLabel = nil

		if tabEntry.icon and tabEntry.icon ~= "" then
			cardIcon = Instance.new("ImageLabel")
			cardIcon.Image = tabEntry.icon
			cardIcon.BackgroundTransparency = 1
			cardIcon.ImageColor3 = textDarkColor
			cardIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			cardIcon.Size = UDim2.new(0, 20, 0, 20)
			cardIcon.Position = UDim2.new(0.5, 0, 0, 16)
			cardIcon.ZIndex = 4
			cardIcon.Parent = card

			cardLabel = Instance.new("TextLabel")
			cardLabel.Text = tabEntry.name
			cardLabel.Font = Enum.Font.GothamSemibold
			cardLabel.TextSize = 11
			cardLabel.TextColor3 = Color3.fromRGB(180, 180, 205)
			cardLabel.TextTransparency = 0.25
			cardLabel.BackgroundTransparency = 1
			cardLabel.TextXAlignment = Enum.TextXAlignment.Center
			cardLabel.TextWrapped = true
			cardLabel.TextTruncate = Enum.TextTruncate.AtEnd
			cardLabel.AnchorPoint = Vector2.new(0.5, 1)
			cardLabel.Size = UDim2.new(1, -8, 0, 20)
			cardLabel.Position = UDim2.new(0.5, 0, 1, -6)
			cardLabel.ZIndex = 4
			cardLabel.Parent = card
		else
			cardLabel = Instance.new("TextLabel")
			cardLabel.Text = tabEntry.name
			cardLabel.Font = Enum.Font.GothamSemibold
			cardLabel.TextSize = 12
			cardLabel.TextColor3 = Color3.fromRGB(180, 180, 205)
			cardLabel.TextTransparency = 0.25
			cardLabel.BackgroundTransparency = 1
			cardLabel.TextXAlignment = Enum.TextXAlignment.Center
			cardLabel.TextWrapped = true
			cardLabel.AnchorPoint = Vector2.new(0.5, 0.5)
			cardLabel.Size = UDim2.new(1, -8, 0.8, 0)
			cardLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
			cardLabel.ZIndex = 4
			cardLabel.Parent = card
		end

		table.insert(segments, {frame = card, icon = cardIcon, label = cardLabel, tabEntry = tabEntry})
	end

	local isOpen = false
	local cachedCenterX = 0
	local cachedCenterY = 0
	local generation = 0
	local function openWheel()
		if isOpen then return end
		isOpen = true
		generation = generation + 1
		local myGen = generation

		container.Size = UDim2.new(0, containerSize, 0, containerSize)
		container.Visible = true

		task.defer(function()
			local absPos = container.AbsolutePosition
			local absSize = container.AbsoluteSize
			cachedCenterX = absPos.X + absSize.X / 2
			cachedCenterY = absPos.Y + absSize.Y / 2
		end)

		backdrop.BackgroundTransparency = 1
		backdrop.Visible = true
		spinRing.Visible = true
		spinRing.Rotation = 0
		spinRing.ImageTransparency = 0.75

		if spinTask then task.cancel(spinTask) end
		spinTask = task.spawn(function()
			while isOpen do
				for r = 0, 359 do
					if not isOpen then break end
					spinRing.Rotation = r
					task.wait(1/60)
				end
			end
		end)

		local currentAnim = Isotope.RadialAnim or "Scale"

		if currentAnim == "Spiral" then
			tweenObj(backdrop, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.55})
			centerCircle.Size = UDim2.new(0, 0, 0, 0)
			tweenObj(centerCircle, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
				{Size = UDim2.new(0, innerRadius * 2, 0, innerRadius * 2)})
			for segIndex, segment in ipairs(segments) do
				local fp = segmentFinalPositions[segIndex]
				local prevIndex = ((segIndex - 2) % tabCount) + 1
				local pfp = segmentFinalPositions[prevIndex]
				segment.frame.Position = UDim2.new(0.5, pfp.x * 0.3, 0.5, pfp.y * 0.3)
				segment.frame.BackgroundTransparency = 1
				segment.frame.Size = UDim2.new(0, cardWidth * 0.4, 0, cardHeight * 0.4)
				task.delay(segIndex * 0.06, function()
					if not isOpen or generation ~= myGen then return end
					tweenObj(segment.frame, 0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
						Position = UDim2.new(0.5, fp.x, 0.5, fp.y),
						BackgroundTransparency = 0.12,
						Size = UDim2.new(0, cardWidth, 0, cardHeight),
					})
				end)
			end

		elseif currentAnim == "Fan" then
			tweenObj(backdrop, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.55})
			for segIndex, segment in ipairs(segments) do
				local fp = segmentFinalPositions[segIndex]
				segment.frame.Position = UDim2.new(0.5, 0, 0.5, -ringRadius)
				segment.frame.BackgroundTransparency = 1
				segment.frame.Size = UDim2.new(0, cardWidth * 0.6, 0, cardHeight * 0.6)
				task.delay((segIndex - 1) * 0.05, function()
					if not isOpen or generation ~= myGen then return end
					tweenObj(segment.frame, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
						Position = UDim2.new(0.5, fp.x, 0.5, fp.y),
						BackgroundTransparency = 0.12,
						Size = UDim2.new(0, cardWidth, 0, cardHeight),
					})
				end)
			end

		elseif currentAnim == "Bloom" then
			tweenObj(backdrop, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.55})
			for segIndex, segment in ipairs(segments) do
				local fp = segmentFinalPositions[segIndex]
				segment.frame.Position = UDim2.new(0.5, 0, 0.5, 0)
				segment.frame.BackgroundTransparency = 1
				segment.frame.Size = UDim2.new(0, 6, 0, 6)
				tweenObj(segment.frame, 0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, {
					Position = UDim2.new(0.5, fp.x, 0.5, fp.y),
					BackgroundTransparency = 0.12,
					Size = UDim2.new(0, cardWidth, 0, cardHeight),
				})
			end

		elseif currentAnim == "Unfold" then
			tweenObj(backdrop, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.55})
			for segIndex, segment in ipairs(segments) do
				local fp = segmentFinalPositions[segIndex]
				segment.frame.Position = UDim2.new(0.5, fp.x, 0.5, fp.y - 120)
				segment.frame.BackgroundTransparency = 1
				segment.frame.Size = UDim2.new(0, cardWidth, 0, cardHeight)
				task.delay((segIndex - 1) * 0.055, function()
					if not isOpen or generation ~= myGen then return end
					tweenObj(segment.frame, 0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, {
						Position = UDim2.new(0.5, fp.x, 0.5, fp.y),
						BackgroundTransparency = 0.12,
					})
				end)
			end

		else
			tweenObj(backdrop, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.55})
			for segIndex, segment in ipairs(segments) do
				local fp = segmentFinalPositions[segIndex]
				segment.frame.Position = UDim2.new(0.5, fp.x, 0.5, fp.y)
				segment.frame.BackgroundTransparency = 1
				segment.frame.Size = UDim2.new(0, 0, 0, 0)
				task.delay((segIndex - 1) * 0.045, function()
					if not isOpen or generation ~= myGen then return end
					tweenObj(segment.frame, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
						BackgroundTransparency = 0.12,
						Size = UDim2.new(0, cardWidth, 0, cardHeight),
					})
				end)
			end
		end
	end

	local function closeWheel(selectIndex)
		if not isOpen then return end
		isOpen = false
		setHovered(nil)
		if spinTask then task.cancel(spinTask) spinTask = nil end
		tweenObj(spinRing, 0.18, nil, nil, {ImageTransparency = 1})
		task.delay(0.2, function() spinRing.Visible = false spinRing.ImageTransparency = 0.75 end)

		local currentAnim = Isotope.RadialAnim or "Scale"

		local myCloseGen = generation
		local function afterClose()
			if generation ~= myCloseGen then return end 
			backdrop.Visible = false
			container.Visible = false
			for segIndex, segment in ipairs(segments) do
				local fp = segmentFinalPositions[segIndex]
				segment.frame.Position = UDim2.new(0.5, fp.x, 0.5, fp.y)
				segment.frame.Size = UDim2.new(0, cardWidth, 0, cardHeight)
				segment.frame.BackgroundTransparency = 0.12
				segment.frame.BackgroundColor3 = secondColor
				if segment.icon then segment.icon.ImageColor3 = textDarkColor end
				if segment.label then
					segment.label.TextColor3 = Color3.fromRGB(180, 180, 205)
					segment.label.TextTransparency = 0.25
				end
			end
			centerCircle.Size = UDim2.new(0, innerRadius * 2, 0, innerRadius * 2)
			if selectIndex then
				if Isotope._RestoreRef then pcall(Isotope._RestoreRef) end
				pcall(tabs[selectIndex].selectFn)
			end
		end

		if currentAnim == "Spiral" then
			TweenService:Create(backdrop, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
			tweenObj(centerCircle, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In,
				{Size = UDim2.new(0, 0, 0, 0)})
			for segIndex, segment in ipairs(segments) do
				task.delay((segIndex - 1) * 0.04, function()
					tweenObj(segment.frame, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In, {
						Position = UDim2.new(0.5, 0, 0.5, 0),
						BackgroundTransparency = 1,
						Size = UDim2.new(0, cardWidth * 0.4, 0, cardHeight * 0.4),
					})
				end)
			end
			task.delay(0.04 * #segments + 0.25, afterClose)

		elseif currentAnim == "Fan" then
			TweenService:Create(backdrop, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
			for segIndex, segment in ipairs(segments) do
				task.delay((#segments - segIndex) * 0.03, function()
					tweenObj(segment.frame, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In, {
						Position = UDim2.new(0.5, 0, 0.5, -ringRadius),
						BackgroundTransparency = 1,
						Size = UDim2.new(0, cardWidth * 0.6, 0, cardHeight * 0.6),
					})
				end)
			end
			task.delay(0.03 * #segments + 0.24, afterClose)

		elseif currentAnim == "Bloom" then
			TweenService:Create(backdrop, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
			for _, segment in ipairs(segments) do
				tweenObj(segment.frame, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.In, {
					Position = UDim2.new(0.5, 0, 0.5, 0),
					BackgroundTransparency = 1,
					Size = UDim2.new(0, 6, 0, 6),
				})
			end
			task.delay(0.32, afterClose)

		elseif currentAnim == "Unfold" then
			TweenService:Create(backdrop, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
			for segIndex, segment in ipairs(segments) do
				local fp = segmentFinalPositions[segIndex]
				task.delay((#segments - segIndex) * 0.03, function()
					tweenObj(segment.frame, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In, {
						Position = UDim2.new(0.5, fp.x * 0.1, 0.5, fp.y * 0.1),
						BackgroundTransparency = 1,
						Size = UDim2.new(0, cardWidth, 0, 4),
					})
				end)
			end
			task.delay(0.03 * #segments + 0.25, afterClose)

		else
			TweenService:Create(backdrop, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
			for segIndex, segment in ipairs(segments) do
				task.delay((#segments - segIndex) * 0.03, function()
					tweenObj(segment.frame, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In, {
						Position = UDim2.new(0.5, 0, 0.5, 0),
						BackgroundTransparency = 1,
						Size = UDim2.new(0, cardWidth * 0.4, 0, cardHeight * 0.4),
					})
				end)
			end
			task.delay(0.03 * #segments + 0.25, afterClose)
		end
	end

	UserInputService.InputChanged:Connect(function(input)
		if not isOpen then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

		local deltaX = input.Position.X - cachedCenterX
		local deltaY = input.Position.Y - cachedCenterY
		local distSq = deltaX * deltaX + deltaY * deltaY
		local innerSq = innerRadius * innerRadius
		local outerSq = (ringRadius + cardHeight / 2 + 15) * (ringRadius + cardHeight / 2 + 15)

		if distSq < innerSq or distSq > outerSq then
			setHovered(nil)
			return
		end

		local mouseAngle = math.atan2(deltaY, deltaX)
		local normalizedAngle = ((mouseAngle + math.pi / 2) % twoPi)
		local segmentIndex = math.floor(normalizedAngle / segmentAngle) % tabCount + 1
		setHovered(segmentIndex)
	end)

	if Isotope.RadialMode == "toggle" then
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if not isOpen then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				closeWheel(hoveredIndex)
			end
		end)
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode ~= Isotope.RadialHotkey then return end
		if Isotope.RadialMode == "toggle" then
			if isOpen then closeWheel(nil) else openWheel() end
		else
			openWheel()
		end
	end)

	if Isotope.RadialMode == "hold" then
		UserInputService.InputEnded:Connect(function(input)
			if input.KeyCode ~= Isotope.RadialHotkey then return end
			if isOpen then closeWheel(hoveredIndex) end
		end)
	end

	return screenGui
end

function Isotope:KeybindList(theme)
	if Isotope.ShowKeybindList == false then return end
	if Isotope._BindListGui and Isotope._BindListGui.Parent then
		Isotope._BindListGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "IsotopeKeybindList"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 998
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	secGui(screenGui)
	Isotope._BindListGui = screenGui

	local mainColor = theme.Main or Color3.fromRGB(20, 20, 22)
	local secondColor = theme.Second or Color3.fromRGB(25, 25, 28)
	local strokeColor = theme.Stroke or Color3.fromRGB(55, 55, 62)
	local textColor = theme.Text or Color3.fromRGB(200, 200, 205)
	local textDarkColor = theme.TextDark or Color3.fromRGB(110, 110, 125)
	local accentColor = theme.Accent or Color3.fromRGB(0, 170, 255)

	local keybindPanel = Instance.new("Frame")
	keybindPanel.Name = "KeybindPanel"
	keybindPanel.BackgroundColor3 = mainColor
	keybindPanel.BackgroundTransparency = 0.2
	keybindPanel.BorderSizePixel = 0
	keybindPanel.AnchorPoint = Vector2.new(0, 1)
	keybindPanel.Position = UDim2.new(0, 18, 1, -18)
	keybindPanel.Size = UDim2.new(0, 210, 0, 0)
	keybindPanel.AutomaticSize = Enum.AutomaticSize.Y
	keybindPanel.Visible = false
	keybindPanel.Parent = screenGui
	addCorner(keybindPanel, 0, 8)
	addStroke(keybindPanel, strokeColor, 1)

	local panelLayout = Instance.new("UIListLayout")
	panelLayout.SortOrder = Enum.SortOrder.LayoutOrder
	panelLayout.FillDirection = Enum.FillDirection.Vertical
	panelLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	panelLayout.Padding = UDim.new(0, 0)
	panelLayout.Parent = keybindPanel

	local panelPadding = Instance.new("UIPadding")
	panelPadding.PaddingTop = UDim.new(0, 6)
	panelPadding.PaddingBottom = UDim.new(0, 8)
	panelPadding.Parent = keybindPanel

	local headerBlock = Instance.new("Frame")
	headerBlock.BackgroundTransparency = 1
	headerBlock.BorderSizePixel = 0
	headerBlock.Size = UDim2.new(1, 0, 0, 26)
	headerBlock.LayoutOrder = 0
	headerBlock.Parent = keybindPanel

	local headerLabel = Instance.new("TextLabel")
	headerLabel.Text = "KEYBINDS"
	headerLabel.Font = Enum.Font.GothamBold
	headerLabel.TextSize = 10
	headerLabel.TextColor3 = textDarkColor
	headerLabel.BackgroundTransparency = 1
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.Size = UDim2.new(1, -20, 1, 0)
	headerLabel.Position = UDim2.new(0, 10, 0, 0)
	headerLabel.Parent = headerBlock

	local dividerWrapper = Instance.new("Frame")
	dividerWrapper.BackgroundTransparency = 1
	dividerWrapper.BorderSizePixel = 0
	dividerWrapper.Size = UDim2.new(1, 0, 0, 1)
	dividerWrapper.LayoutOrder = 1
	dividerWrapper.Parent = keybindPanel

	local dividerLine = Instance.new("Frame")
	dividerLine.BackgroundColor3 = strokeColor
	dividerLine.BorderSizePixel = 0
	dividerLine.Size = UDim2.new(1, -20, 1, 0)
	dividerLine.Position = UDim2.new(0, 10, 0, 0)
	dividerLine.Parent = dividerWrapper

	local currentLayoutOrder = 2
	local function refPanelVis()
		local anyRowVisible = false
		for _, child in ipairs(keybindPanel:GetChildren()) do
			if child:IsA("Frame") and child.Name:sub(1, 4) == "Row_" and child.Visible then
				anyRowVisible = true
				break
			end
		end
		keybindPanel.Visible = anyRowVisible
	end

	local function buildKeybindRow(entry)
		local bindObj = entry.Bind
		local bindName = entry.Name
		local bindModifiers = normalModifiers(bindObj._modifiers)

		local currentKeyValue = bindObj.Value
		local displayLabel = bBindLabel(bindModifiers, currentKeyValue)
		local isUnset = (currentKeyValue == nil or currentKeyValue == "Unknown" or currentKeyValue == "")

		local row = Instance.new("Frame")
		row.Name = "Row_" .. bindName
		row.BackgroundTransparency = 1
		row.BorderSizePixel = 0
		row.Size = UDim2.new(1, 0, 0, 24)
		row.LayoutOrder = currentLayoutOrder
		row.Visible = true
		row.Parent = keybindPanel
		currentLayoutOrder += 1

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Text = bindName
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextSize = 12
		nameLabel.TextColor3 = textColor
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.AnchorPoint = Vector2.new(0, 0.5)
		nameLabel.Size = UDim2.new(1, -80, 1, 0)
		nameLabel.Position = UDim2.new(0, 10, 0.5, 0)
		nameLabel.Parent = row

		local keyBadge = Instance.new("Frame")
		keyBadge.BackgroundColor3 = secondColor
		keyBadge.BorderSizePixel = 0
		keyBadge.AnchorPoint = Vector2.new(1, 0.5)
		keyBadge.Size = UDim2.new(0, 60, 0, 17)
		keyBadge.Position = UDim2.new(1, -10, 0.5, 0)
		keyBadge.Parent = row
		addCorner(keyBadge, 0, 4)
		addStroke(keyBadge, strokeColor, 1)

		local keyLabel = Instance.new("TextLabel")
		keyLabel.Name = "KeyLabel"
		keyLabel.Text = (isUnset and #bindModifiers == 0) and "-" or displayLabel
		keyLabel.Font = Enum.Font.GothamBold
		keyLabel.TextSize = 10
		keyLabel.TextColor3 = Color3.fromRGB(175, 175, 190)
		keyLabel.BackgroundTransparency = 1
		keyLabel.TextXAlignment = Enum.TextXAlignment.Center
		keyLabel.Size = UDim2.new(1, -4, 1, 0)
		keyLabel.TextScaled = true
		keyLabel.Parent = keyBadge

		bindObj._row = row

		local originalSet = bindObj.Set
		bindObj.Set = function(self2, key)
			originalSet(self2, key)
			local newValue = bindObj.Value
			local newModifiers = normalModifiers(bindObj._modifiers)
			keyLabel.Text = bBindLabel(newModifiers, newValue)
			task.defer(function()
				if keyBadge.Parent then
					keyBadge.Size = UDim2.new(0, math.clamp(keyLabel.TextBounds.X + 14, 36, 80), 0, 17)
				end
			end)
			refPanelVis()
		end

		task.defer(function()
			if keyBadge.Parent then
				keyBadge.Size = UDim2.new(0, math.clamp(keyLabel.TextBounds.X + 14, 36, 80), 0, 17)
			end
		end)
	end

	for _, entry in ipairs(Isotope.Binds) do
		buildKeybindRow(entry)
	end

	local knownBindCount = #Isotope.Binds
	task.spawn(function()
		while screenGui and screenGui.Parent do
			task.wait(0.5)
			if #Isotope.Binds > knownBindCount then
				for newIndex = knownBindCount + 1, #Isotope.Binds do
					buildKeybindRow(Isotope.Binds[newIndex])
				end
				knownBindCount = #Isotope.Binds
			end
		end
	end)

	refPanelVis()
	return screenGui
end

function Isotope:Window(config)
	Isotope._initDone = false
	config = config or {}

	local targets = {game:GetService("CoreGui"), LocalPlayer.PlayerGui}
	for _, target in pairs(targets) do
		for _, guiName in ipairs({"IsotopeUI", "IsotopeNotifications", "IsotopeNotificationsClassic", "IsotopeKeybindList", "IsotopeTopbar", "IsotopeRadial"}) do
			local guiInstance = target:FindFirstChild(guiName)
			if guiInstance then guiInstance:Destroy() end
		end
	end
	pcall(function()
		local protectedGui = gethui()
		for _, guiName in ipairs({"IsotopeUI", "IsotopeNotifications", "IsotopeNotificationsClassic", "IsotopeKeybindList", "IsotopeTopbar", "IsotopeRadial"}) do
			local guiInstance = protectedGui:FindFirstChild(guiName)
			if guiInstance then guiInstance:Destroy() end
		end
	end)
	table.clear(Isotope.Binds)
	table.clear(Isotope._Tabs)
	table.clear(Isotope._ElementRegistry)
	table.clear(notifStack)
	Isotope._BindListGui = nil
	Isotope._TopbarGui = nil
	Isotope._RadialGui = nil
	Isotope._MainWindowRef = nil
	Isotope._RestoreRef = nil
	Isotope._MinimizedRef = nil

	local windowName = config.Name or "IsotopeUI"
	local theme = Themes[config.Theme] or Themes.Dark
	Isotope._activeTheme = theme
	local doStartup = config.Startup or false
	local startupAnim = config.StartupAnim or "Fade"
	local startupText = config.StartupText or ""
	local startupIcon = config.StartupIcon or ""
	local configFolder = config.ConfigFolder or windowName
	local configFile = config.Config or tostring(game.GameId)
	local doSaveConfig = config.SaveConfig or false
	local closeCallback = config.CloseCallback or function() end
	local showPlayerName = (config.PlayerName ~= false)
	local showDisplayName = (config.ShowDisplayName == true)
	local showUsername = (config.ShowUsername == true)
	local reopenKey    = config.ReopenKey    or Enum.KeyCode.RightShift
	local closeAnim    = config.CloseAnim    or "Shrink"
	local keySystem = config.KeySystem or false
	local keySystemKey = config.Key or config.KeySystemKey or ""
	local keyLink = config.KeyLink or nil
	local keyDeniedCallback = config.KeyDeniedCallback or function() end
	local minimizeAnim = config.MinimizeAnim or "Slide"
	
	local configScriptKey = config.ScriptKey or ""
	if configScriptKey ~= "" then Isotope._ScriptKey = configScriptKey end

	Isotope.SaveCfg = doSaveConfig
	Isotope.Folder = configFolder
	Isotope._CfgFile = configFile

	local accentColor = theme.Accent or Color3.fromRGB(0, 170, 255)
	local accentElements = {}
	local sidebarExpanded = true
	local isMinimized = false
	local isHidden = false
	local activeTabPage = nil
	local activeTabButton = nil
	local allTabs = {}
	local sidebarCount = 0

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "IsotopeUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	secGui(screenGui)

	if keySystem then
		local keyResolved = false
		local keyGui = Instance.new("ScreenGui")
		keyGui.Name = "IsotopeKeySystem"
		keyGui.ResetOnSpawn = false
		keyGui.DisplayOrder = 1000
		keyGui.IgnoreGuiInset = true
		secGui(keyGui)

		local keyFrame = Instance.new("Frame")
		keyFrame.BackgroundColor3 = theme.Main
		keyFrame.BorderSizePixel = 0
		keyFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		keyFrame.Size = UDim2.new(0, 0, 0, 0)
		keyFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		keyFrame.ClipsDescendants = true
		keyFrame.Parent = keyGui
		addCorner(keyFrame, 0, 10)
		addStroke(keyFrame, theme.Stroke, 1.5)

		local expandKey = TweenService:Create(keyFrame,
			TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, 380, 0, 200)})
		expandKey:Play()
		expandKey.Completed:Wait()

		local keyTitle = Instance.new("TextLabel")
		keyTitle.Text = windowName
		keyTitle.Font = Enum.Font.GothamBold
		keyTitle.TextSize = 16
		keyTitle.TextColor3 = theme.Text
		keyTitle.BackgroundTransparency = 1
		keyTitle.AnchorPoint = Vector2.new(0.5, 0)
		keyTitle.Size = UDim2.new(1, -20, 0, 20)
		keyTitle.Position = UDim2.new(0.5, 0, 0, 20)
		keyTitle.TextXAlignment = Enum.TextXAlignment.Center
		keyTitle.Parent = keyFrame

		local keySub = Instance.new("TextLabel")
		keySub.Text = "Enter your key to continue"
		keySub.Font = Enum.Font.Gotham
		keySub.TextSize = 13
		keySub.TextColor3 = theme.TextDark
		keySub.BackgroundTransparency = 1
		keySub.AnchorPoint = Vector2.new(0.5, 0)
		keySub.Size = UDim2.new(1, -20, 0, 16)
		keySub.Position = UDim2.new(0.5, 0, 0, 46)
		keySub.TextXAlignment = Enum.TextXAlignment.Center
		keySub.Parent = keyFrame

		local keyInputFrame = Instance.new("Frame")
		keyInputFrame.BackgroundColor3 = theme.Second
		keyInputFrame.BorderSizePixel = 0
		keyInputFrame.AnchorPoint = Vector2.new(0.5, 0)
		keyInputFrame.Size = UDim2.new(1, -40, 0, 32)
		keyInputFrame.Position = UDim2.new(0.5, 0, 0, 78)
		keyInputFrame.Parent = keyFrame
		addCorner(keyInputFrame, 0, 6)
		addStroke(keyInputFrame, theme.Stroke, 1)

		local keyInput = Instance.new("TextBox")
		keyInput.BackgroundTransparency = 1
		keyInput.PlaceholderText = "Key..."
		keyInput.PlaceholderColor3 = theme.TextDark
		keyInput.Text = ""
		keyInput.Font = Enum.Font.GothamSemibold
		keyInput.TextSize = 13
		keyInput.TextColor3 = theme.Text
		keyInput.TextXAlignment = Enum.TextXAlignment.Left
		keyInput.ClearTextOnFocus = false
		keyInput.Size = UDim2.new(1, -16, 1, 0)
		keyInput.Position = UDim2.new(0, 10, 0, 0)
		keyInput.Parent = keyInputFrame

		local keyConfirmBtn = Instance.new("TextButton")
		keyConfirmBtn.Text = "Confirm"
		keyConfirmBtn.Font = Enum.Font.GothamBold
		keyConfirmBtn.TextSize = 13
		keyConfirmBtn.TextColor3 = theme.Text
		keyConfirmBtn.BackgroundColor3 = theme.Second
		keyConfirmBtn.BorderSizePixel = 0
		keyConfirmBtn.AutoButtonColor = false
		keyConfirmBtn.AnchorPoint = Vector2.new(0, 0)
		keyConfirmBtn.Size = UDim2.new(0.5, -26, 0, 28)
		keyConfirmBtn.Position = UDim2.new(0, 20, 0, 124) 
		keyConfirmBtn.Parent = keyFrame
		addCorner(keyConfirmBtn, 0, 6)
		addStroke(keyConfirmBtn, theme.Stroke, 1)

		local keyCloseBtn = Instance.new("TextButton")
		keyCloseBtn.Text = "Close"
		keyCloseBtn.Font = Enum.Font.GothamBold
		keyCloseBtn.TextSize = 13
		keyCloseBtn.TextColor3 = theme.Text
		keyCloseBtn.BackgroundColor3 = theme.Second 
		keyCloseBtn.BorderSizePixel = 0
		keyCloseBtn.AutoButtonColor = false
		keyCloseBtn.AnchorPoint = Vector2.new(1, 0)
		keyCloseBtn.Size = UDim2.new(0.5, -26, 0, 28)
		keyCloseBtn.Position = UDim2.new(1, -20, 0, 124) 
		keyCloseBtn.Parent = keyFrame
		addCorner(keyCloseBtn, 0, 6)
		addStroke(keyCloseBtn, theme.Stroke, 1)

		if keyLink then
			local keyLinkLabel = Instance.new("TextButton")
			keyLinkLabel.Text = "Get Key ↗"
			keyLinkLabel.Font = Enum.Font.Gotham
			keyLinkLabel.TextSize = 11
			keyLinkLabel.TextColor3 = Color3.fromRGB(80, 160, 255)
			keyLinkLabel.BackgroundTransparency = 1
			keyLinkLabel.BorderSizePixel = 0
			keyLinkLabel.AnchorPoint = Vector2.new(0.5, 0)
			keyLinkLabel.Size = UDim2.new(1, 0, 0, 16)
			keyLinkLabel.Position = UDim2.new(0.5, 0, 0, 172)
			keyLinkLabel.Parent = keyFrame

			keyLinkLabel.MouseButton1Click:Connect(function()
				pcall(function()
					if setclipboard then
						setclipboard(keyLink)
						keyLinkLabel.Text = "Copied!"
						task.wait(1)
						keyLinkLabel.Text = "Get Key ↗"
					end
				end)
			end)
		end

		local keyStatusLabel = Instance.new("TextLabel")
		keyStatusLabel.Text = ""
		keyStatusLabel.Font = Enum.Font.Gotham
		keyStatusLabel.TextSize = 11
		keyStatusLabel.TextColor3 = Color3.fromRGB(224, 96, 96)
		keyStatusLabel.BackgroundTransparency = 1
		keyStatusLabel.AnchorPoint = Vector2.new(0.5, 0)
		keyStatusLabel.Size = UDim2.new(1, 0, 0, 14)
		keyStatusLabel.Position = UDim2.new(0.5, 0, 0, 158)
		keyStatusLabel.TextXAlignment = Enum.TextXAlignment.Center
		keyStatusLabel.Parent = keyFrame

		local function dismissKeyGui(accepted)
			local shrinkTween = TweenService:Create(keyFrame,
				TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In),
				{Size = UDim2.new(0, 0, 0, 0)})
			shrinkTween:Play()
			shrinkTween.Completed:Wait()
			keyGui:Destroy()
			if not accepted then
				pcall(keyDeniedCallback)
			end
		end

		keyConfirmBtn.MouseButton1Click:Connect(function()
			if keyInput.Text == keySystemKey then
				keyResolved = true
				dismissKeyGui(true)
			else
				keyStatusLabel.Text = "Incorrect key."
				tweenObj(keyInputFrame, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundColor3 = Color3.fromRGB(60, 30, 30)})
				task.delay(0.5, function()
					tweenObj(keyInputFrame, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundColor3 = theme.Second})
				end)
			end
		end)

		keyCloseBtn.MouseButton1Click:Connect(function()
			dismissKeyGui(false)
		end)

		while not keyResolved do
			task.wait(0.1)
		end
	end

	if screenGui.Parent then
		for _, child in pairs(screenGui.Parent:GetChildren()) do
			if child.Name == "IsotopeUI" and child ~= screenGui then child:Destroy() end
		end
	end

	local mainWindow = Instance.new("Frame")
	mainWindow.Name = "MainWindow"
	mainWindow.BackgroundColor3 = theme.Main
	mainWindow.BorderSizePixel = 0
	mainWindow.Position = UDim2.new(0.5, -307, 0.5, -172)
	mainWindow.Size = UDim2.new(0, 615, 0, 344)
	mainWindow.ClipsDescendants = true
	mainWindow.Visible = false
	mainWindow.Parent = screenGui
	addCorner(mainWindow, 0, 10)

	local windowStroke = addStroke(mainWindow, theme.Stroke, 1.5)

	Isotope._MainWindowRef = mainWindow

	local topBar = Instance.new("Frame")
	topBar.BackgroundTransparency = 1
	topBar.Size = UDim2.new(1, 0, 0, 50)
	topBar.ZIndex = 3
	topBar.Parent = mainWindow

	local topBarDivider = Instance.new("Frame")
	topBarDivider.BackgroundColor3 = theme.Stroke
	topBarDivider.BorderSizePixel = 0
	topBarDivider.Size = UDim2.new(1, 0, 0, 1)
	topBarDivider.Position = UDim2.new(0, 0, 1, -1)
	topBarDivider.Parent = topBar

	local topBarlbl = Instance.new("TextLabel")
	topBarlbl.Text = windowName
	topBarlbl.TextColor3 = theme.Text
	topBarlbl.TextSize = 16
	topBarlbl.Font = Enum.Font.GothamBold
	topBarlbl.BackgroundTransparency = 1
	topBarlbl.TextXAlignment = Enum.TextXAlignment.Left
	topBarlbl.Position = UDim2.new(0, 10, 0, 0)
	topBarlbl.Size = UDim2.new(1, -120, 1, 0)
	topBarlbl.Parent = topBar

	local windowButtonContainer = Instance.new("Frame")
	windowButtonContainer.BackgroundColor3 = theme.Second
	windowButtonContainer.BorderSizePixel = 0
	windowButtonContainer.Size = UDim2.new(0, 105, 0, 30)
	windowButtonContainer.Position = UDim2.new(1, -115, 0, 10)
	windowButtonContainer.Parent = topBar
	addCorner(windowButtonContainer, 0, 7)
	addStroke(windowButtonContainer, theme.Stroke, 1)

	local buttonDivider1 = Instance.new("Frame")
	buttonDivider1.BackgroundColor3 = theme.Stroke
	buttonDivider1.BorderSizePixel = 0
	buttonDivider1.Size = UDim2.new(0, 1, 1, 0)
	buttonDivider1.Position = UDim2.new(1/3, 0, 0, 0)
	buttonDivider1.Parent = windowButtonContainer

	local buttonDivider2 = Instance.new("Frame")
	buttonDivider2.BackgroundColor3 = theme.Stroke
	buttonDivider2.BorderSizePixel = 0
	buttonDivider2.Size = UDim2.new(0, 1, 1, 0)
	buttonDivider2.Position = UDim2.new(2/3, 0, 0, 0)
	buttonDivider2.Parent = windowButtonContainer

	local minimizeButton = Instance.new("TextButton")
	minimizeButton.Text = ""
	minimizeButton.AutoButtonColor = false
	minimizeButton.BackgroundTransparency = 1
	minimizeButton.BorderSizePixel = 0
	minimizeButton.Size = UDim2.new(1/3, 0, 1, 0)
	minimizeButton.Position = UDim2.new(0, 0, 0, 0)
	minimizeButton.Parent = windowButtonContainer

	local minimizeIcon = Instance.new("ImageLabel")
	minimizeIcon.Image = "rbxassetid://7072719338"
	minimizeIcon.BackgroundTransparency = 1
	minimizeIcon.ImageColor3 = theme.Text
	minimizeIcon.Position = UDim2.new(0, 9, 0, 6)
	minimizeIcon.Size = UDim2.new(0, 18, 0, 18)
	minimizeIcon.Parent = minimizeButton

	local toggleSidebarButton = Instance.new("TextButton")
	toggleSidebarButton.Text = ""
	toggleSidebarButton.AutoButtonColor = false
	toggleSidebarButton.BackgroundTransparency = 1
	toggleSidebarButton.BorderSizePixel = 0
	toggleSidebarButton.Size = UDim2.new(1/3, 0, 1, 0)
	toggleSidebarButton.Position = UDim2.new(1/3, 0, 0, 0)
	toggleSidebarButton.Parent = windowButtonContainer

	local toggleSidebarIcon = Instance.new("TextLabel")
	toggleSidebarIcon.Text = "/"
	toggleSidebarIcon.TextColor3 = theme.Text
	toggleSidebarIcon.Font = Enum.Font.GothamBold
	toggleSidebarIcon.TextSize = 18
	toggleSidebarIcon.BackgroundTransparency = 1
	toggleSidebarIcon.Size = UDim2.new(1, 0, 1, 0)
	toggleSidebarIcon.Parent = toggleSidebarButton

	local closeButton = Instance.new("TextButton")
	closeButton.Text = ""
	closeButton.AutoButtonColor = false
	closeButton.BackgroundTransparency = 1
	closeButton.BorderSizePixel = 0
	closeButton.Size = UDim2.new(1/3, 0, 1, 0)
	closeButton.Position = UDim2.new(2/3, 0, 0, 0)
	closeButton.Parent = windowButtonContainer

	local closeIcon = Instance.new("ImageLabel")
	closeIcon.Image = "rbxassetid://7072725342"
	closeIcon.BackgroundTransparency = 1
	closeIcon.ImageColor3 = theme.Text
	closeIcon.Position = UDim2.new(0, 9, 0, 6)
	closeIcon.Size = UDim2.new(0, 18, 0, 18)
	closeIcon.Parent = closeButton
	
	local resActive = false
	local resCleanup = nil
	
	local resBtn = Instance.new("TextButton")
	resBtn.Text = ""
	resBtn.AutoButtonColor = false
	resBtn.BackgroundTransparency = 1
	resBtn.BorderSizePixel = 0
	resBtn.Size = UDim2.new(0, 30, 0, 30)
	resBtn.Position = UDim2.new(0, -40, 0, 10) -- l
	resBtn.Parent = topBar -- might change - windowbuttoncont
	
	local resIcon = Instance.new("ImageLabel")
	resIcon.Image = "rbxassetid://9307576840"
	resIcon.BackgroundTransparency = 1
	resIcon.ImageColor3 = theme.TextDark
	resIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	resIcon.Size = UDim2.new(0, 16, 0, 16)
	resIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	resIcon.Parent = resBtn
	
	resBtn.MouseEnter:Connect(function()
		tweenObj(resIcon, 0.15, nil, nil, {ImageCoor3 = theme.Text})
	end)
	resBtn.MouseLeave:Connect(function()
		tweenObj(resIcon, 0.15, nil, nil, {
			ImageColor3 = resActive and theme.Accent or theme.TextDark
		})
	end)
	
	resBtn.MouseButton1Click:Connect(function()
		resActive = not resActive
		if resActive then
			resCleanup = makeResizable(mainWindow, {
				minWidth = 400,
				minHeight = 250,
				onRes = function(w, h)
					local sw = sidebarExpanded and 150 or 50
					sidebar.Size = UDim2.new(0, sw, 1, -50)
					if activeTabPage then
						activeTabPage.Size = UDim2.new(1, -sw, 1, -50)
						activeTabPage.Position = UDim2.new(0, sw, 0, 50)
					end
				end,
			})
			tweenObj(resIcon, 0.2, nil, nil, {ImageColor3 = theme.Accent})
			addStroke(resBtn, theme.Accent, 1)
		else
			if resCleanup then resCleanup() resCleanup = nil end
			tweenObj(resIcon, 0.2, nil, nil, {ImageColor3 = theme.TextDark})
			local s = resBtn:FindFirstChildOfClass("UIStroke")
			if s then s:Destroy() end
		end
	end)
	
	local dragHandle = Instance.new("Frame")
	dragHandle.BackgroundTransparency = 1
	dragHandle.Size = UDim2.new(1, 0, 0, 50)
	dragHandle.ZIndex = 3
	dragHandle.Parent = mainWindow
	makeDraggable(dragHandle, mainWindow)

	local toastScreenGui = Instance.new("ScreenGui")
	toastScreenGui.Name = "IsotopeToasts"
	toastScreenGui.ResetOnSpawn = false
	toastScreenGui.DisplayOrder = 998
	toastScreenGui.IgnoreGuiInset = true
	toastScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	secGui(toastScreenGui)

	local lockOverlay = Instance.new("Frame")
	lockOverlay.Name = "LockOverlay"
	lockOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	lockOverlay.BackgroundTransparency = 1
	lockOverlay.BorderSizePixel = 0
	lockOverlay.Size = UDim2.new(1, 0, 1, 0)
	lockOverlay.ZIndex = 50
	lockOverlay.Visible = false
	lockOverlay.Parent = mainWindow
	addCorner(lockOverlay, 0, 10)

	local lockLabel = Instance.new("TextLabel")
	lockLabel.Text = "Loading..."
	lockLabel.Font = Enum.Font.GothamBold
	lockLabel.TextSize = 16
	lockLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	lockLabel.BackgroundTransparency = 1
	lockLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	lockLabel.Size = UDim2.new(0.7, 0, 0, 24)
	lockLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	lockLabel.TextXAlignment = Enum.TextXAlignment.Center
	lockLabel.ZIndex = 51
	lockLabel.Parent = lockOverlay

	local lockInputBlocker = Instance.new("TextButton")
	lockInputBlocker.Text = ""
	lockInputBlocker.AutoButtonColor = false
	lockInputBlocker.BackgroundTransparency = 1
	lockInputBlocker.BorderSizePixel = 0
	lockInputBlocker.Size = UDim2.new(1, 0, 1, 0)
	lockInputBlocker.ZIndex = 52
	lockInputBlocker.Visible = false
	lockInputBlocker.Parent = mainWindow

	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.BackgroundColor3 = theme.Second
	sidebar.BorderSizePixel = 0
	sidebar.Size = UDim2.new(0, 150, 1, -50)
	sidebar.Position = UDim2.new(0, 0, 0, 50)
	sidebar.ZIndex = 3
	sidebar.Parent = mainWindow
	sidebar.ClipsDescendants = true
	addCorner(sidebar, 0, 10)

	local sidebarTopCover = Instance.new("Frame")
	sidebarTopCover.BackgroundColor3 = theme.Second
	sidebarTopCover.BorderSizePixel = 0
	sidebarTopCover.Size = UDim2.new(1, 0, 0, 10)
	sidebarTopCover.Position = UDim2.new(0, 0, 0, 0)
	sidebarTopCover.Parent = sidebar

	local sidebarRightCover = Instance.new("Frame")
	sidebarRightCover.BackgroundColor3 = theme.Second
	sidebarRightCover.BorderSizePixel = 0
	sidebarRightCover.Size = UDim2.new(0, 10, 1, 0)
	sidebarRightCover.Position = UDim2.new(1, -10, 0, 0)
	sidebarRightCover.Parent = sidebar

	local sidebarDivider = Instance.new("Frame")
	sidebarDivider.BackgroundColor3 = theme.Stroke
	sidebarDivider.BorderSizePixel = 0
	sidebarDivider.Size = UDim2.new(0, 1, 1, 0)
	sidebarDivider.Position = UDim2.new(1, -1, 0, 0)
	sidebarDivider.Parent = sidebar

	local tabHolder = Instance.new("ScrollingFrame")
	tabHolder.BackgroundTransparency = 1
	tabHolder.ScrollBarImageColor3 = theme.Divider
	tabHolder.BorderSizePixel = 0
	tabHolder.ScrollBarThickness = 4
	tabHolder.MidImage = "rbxassetid://7445543667"
	tabHolder.BottomImage = "rbxassetid://7445543667"
	tabHolder.TopImage = "rbxassetid://7445543667"
	tabHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
	tabHolder.Size = UDim2.new(1, 0, 1, Isotope.UserSection and -50 or 0)
	tabHolder.ClipsDescendants = true
	tabHolder.Parent = sidebar

	local tabHolderLayout = addListLayout(tabHolder, 0)
	addPadding(tabHolder, 8, 0, 0, 8)
	tabHolderLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tabHolder.CanvasSize = UDim2.new(0, 0, 0, tabHolderLayout.AbsoluteContentSize.Y + 16)
	end)

	local bottomDivider = Instance.new("Frame")
	bottomDivider.BackgroundColor3 = theme.Stroke
	bottomDivider.BorderSizePixel = 0
	bottomDivider.Size = UDim2.new(1, 0, 0, 1)
	bottomDivider.Position = UDim2.new(0, 0, 1, -50)
	bottomDivider.Parent = sidebar

	--if not showPlayerName then
	--	tabHolder.Size = UDim2.new(1, 0, 1, 0)
	--	bottomDivider.Visible = false
	--end

	if not Isotope.UserSection then
		tabHolder.Size = UDim2.new(1, 0, 1, 0)
		bottomDivider.Visible = false
	end

	local bottomBar = Instance.new("Frame")
	bottomBar.BackgroundTransparency = 1
	bottomBar.Size = UDim2.new(1, 0, 0, 50)
	bottomBar.Position = UDim2.new(0, 0, 1, -50)
	bottomBar.Visible = Isotope.UserSection
	bottomBar.Parent = sidebar

	local userSectionContainer = Instance.new("Frame")
	userSectionContainer.Name = "UserSectionContainer"
	userSectionContainer.BackgroundTransparency = 1
	userSectionContainer.Size = UDim2.new(1, 0, 1, 0)
	userSectionContainer.Parent = bottomBar

	local displayNameLabel = nil
	local usernameLabel = nil  
	local avatarSubLabel = nil
	local currentSection = nil

	local windowObject = {}

	if Isotope.UserSection then
		local avatarFrame = Instance.new("TextButton") 
		avatarFrame.Name = "AvatarFrame"
		avatarFrame.Text = ""
		avatarFrame.AutoButtonColor = false
		avatarFrame.BackgroundColor3 = theme.Divider
		avatarFrame.BorderSizePixel = 0
		avatarFrame.AnchorPoint = Vector2.new(0, 0.5)
		avatarFrame.Size = UDim2.new(0, 32, 0, 32)
		avatarFrame.Position = UDim2.new(0, 10, 0.5, 0)
		avatarFrame.Parent = userSectionContainer
		addCorner(avatarFrame, 1, 0)

		local avatarImage = Instance.new("ImageLabel")
		avatarImage.Name = "AvatarImage"
		avatarImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=420&height=420&format=png"
		avatarImage.BackgroundTransparency = 1
		avatarImage.Size = UDim2.new(1, 0, 1, 0)
		avatarImage.Parent = avatarFrame

		local avatarOverlay = Instance.new("ImageLabel")
		avatarOverlay.Name = "AvatarOverlay"
		avatarOverlay.Image = "rbxassetid://4031889928"
		avatarOverlay.BackgroundTransparency = 1
		avatarOverlay.ImageColor3 = theme.Second
		avatarOverlay.Size = UDim2.new(1, 0, 1, 0)
		avatarOverlay.Parent = avatarFrame

		local avatarStrokeFrame = Instance.new("Frame")
		avatarStrokeFrame.Name = "AvatarStroke"
		avatarStrokeFrame.BackgroundTransparency = 1
		avatarStrokeFrame.AnchorPoint = Vector2.new(0, 0.5)
		avatarStrokeFrame.Size = UDim2.new(0, 32, 0, 32)
		avatarStrokeFrame.Position = UDim2.new(0, 10, 0.5, 0)
		avatarStrokeFrame.Parent = userSectionContainer
		addCorner(avatarStrokeFrame, 1, 0)
		addStroke(avatarStrokeFrame, theme.Stroke, 1)

		local avatarMenu = nil
		
		local function openProfileView()
			local pGui = Instance.new("ScreenGui")
			pGui.Name = "IsotopeProfileView"
			pGui.ResetOnSpawn = false
			pGui.DisplayOrder = 300
			pGui.IgnoreGuiInset = true
			secGui(pGui)

			local backdrop = Instance.new("Frame")
			backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
			backdrop.BackgroundTransparency = 1
			backdrop.BorderSizePixel = 0
			backdrop.Size = UDim2.new(1, 0, 1, 0)
			backdrop.ZIndex = 1
			backdrop.Parent = pGui

			local blur = Instance.new("BlurEffect")
			blur.Size = 0
			blur.Parent = game:GetService("Lighting")
			TweenService:Create(blur, TweenInfo.new(0.3), {Size = 16}):Play()
			tweenObj(backdrop, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.5})

			local panel = Instance.new("Frame")
			panel.BackgroundColor3 = theme.Main
			panel.BorderSizePixel = 0
			panel.AnchorPoint = Vector2.new(0.5, 0.5)
			panel.Size = UDim2.new(0, 0, 0, 0)
			panel.Position = UDim2.new(0.5, 0, 0.5, 0)
			panel.ClipsDescendants = true
			panel.ZIndex = 2
			panel.Parent = pGui
			addCorner(panel, 0, 12)
			addStroke(panel, theme.Stroke, 1.5)

			TweenService:Create(panel, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{Size = UDim2.new(0, 310, 0, 0)}):Play()
			task.wait(0.1)
			local smallOpenTween = TweenService:Create(panel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{Size = UDim2.new(0, 310, 0, 380)})
			smallOpenTween:Play()
			smallOpenTween.Completed:Connect(function()
				makeDraggable(panel, panel)
			end)

			local avatarBanner = Instance.new("Frame")
			avatarBanner.BackgroundColor3 = theme.Second
			avatarBanner.BorderSizePixel = 0
			avatarBanner.Size = UDim2.new(1, 0, 0, 120)
			avatarBanner.ZIndex = 3
			avatarBanner.Parent = panel
			addCorner(avatarBanner, 0, 12)

			local bannerBottomCover = Instance.new("Frame")
			bannerBottomCover.BackgroundColor3 = theme.Second
			bannerBottomCover.BorderSizePixel = 0
			bannerBottomCover.Size = UDim2.new(1, 0, 0, 12)
			bannerBottomCover.Position = UDim2.new(0, 0, 1, -12)
			bannerBottomCover.ZIndex = 3
			bannerBottomCover.Parent = avatarBanner

			local bigAvatar = Instance.new("ImageLabel")
			bigAvatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=420&height=420&format=png"
			bigAvatar.BackgroundColor3 = theme.Divider
			bigAvatar.BorderSizePixel = 0
			bigAvatar.AnchorPoint = Vector2.new(0.5, 1)
			bigAvatar.Size = UDim2.new(0, 72, 0, 72)
			bigAvatar.Position = UDim2.new(0.5, 0, 0, 84)
			bigAvatar.ZIndex = 5
			bigAvatar.Parent = panel
			addCorner(bigAvatar, 1, 0)
			addStroke(bigAvatar, theme.Accent or Color3.fromRGB(0, 170, 255), 2)

			local displayLbl = Instance.new("TextLabel")
			displayLbl.Text = LocalPlayer.DisplayName
			displayLbl.Font = Enum.Font.GothamBold
			displayLbl.TextSize = 17
			displayLbl.TextColor3 = theme.Text
			displayLbl.BackgroundTransparency = 1
			displayLbl.AnchorPoint = Vector2.new(0.5, 0)
			displayLbl.Size = UDim2.new(1, -24, 0, 20)
			displayLbl.Position = UDim2.new(0.5, 0, 0, 128)
			displayLbl.TextXAlignment = Enum.TextXAlignment.Center
			displayLbl.ZIndex = 4
			displayLbl.Parent = panel

			local usernameLbl = Instance.new("TextLabel")
			usernameLbl.Text = "@" .. LocalPlayer.Name
			usernameLbl.Font = Enum.Font.Gotham
			usernameLbl.TextSize = 12
			usernameLbl.TextColor3 = theme.TextDark
			usernameLbl.BackgroundTransparency = 1
			usernameLbl.AnchorPoint = Vector2.new(0.5, 0)
			usernameLbl.Size = UDim2.new(1, -24, 0, 14)
			usernameLbl.Position = UDim2.new(0.5, 0, 0, 151)
			usernameLbl.TextXAlignment = Enum.TextXAlignment.Center
			usernameLbl.ZIndex = 4
			usernameLbl.Parent = panel

			local divider = Instance.new("Frame")
			divider.BackgroundColor3 = theme.Stroke
			divider.BorderSizePixel = 0
			divider.Size = UDim2.new(1, -24, 0, 1)
			divider.Position = UDim2.new(0, 12, 0, 176)
			divider.ZIndex = 3
			divider.Parent = panel

			local buttonHolder = Instance.new("Frame")
			buttonHolder.BackgroundTransparency = 1
			buttonHolder.Size = UDim2.new(1, -24, 0, 0)
			buttonHolder.Position = UDim2.new(0, 12, 0, 186)
			buttonHolder.AutomaticSize = Enum.AutomaticSize.Y
			buttonHolder.ZIndex = 3
			buttonHolder.Parent = panel
			addListLayout(buttonHolder, 6)

			local function makeProfileBtn(text, icon, callback)
				local btn = Instance.new("TextButton")
				btn.Text = ""
				btn.AutoButtonColor = false
				btn.BackgroundColor3 = theme.Second
				btn.BorderSizePixel = 0
				btn.Size = UDim2.new(1, 0, 0, 36)
				btn.ZIndex = 4
				btn.Parent = buttonHolder
				addCorner(btn, 0, 6)
				addStroke(btn, theme.Stroke, 1)

				local ico = Instance.new("ImageLabel")
				ico.Image = icon or "rbxassetid://3944703587"
				ico.BackgroundTransparency = 1
				ico.ImageColor3 = theme.TextDark
				ico.AnchorPoint = Vector2.new(0, 0.5)
				ico.Size = UDim2.new(0, 15, 0, 15)
				ico.Position = UDim2.new(0, 12, 0.5, 0)
				ico.ZIndex = 5
				ico.Parent = btn

				local lbl = Instance.new("TextLabel")
				lbl.Text = text
				lbl.Font = Enum.Font.GothamSemibold
				lbl.TextSize = 13
				lbl.TextColor3 = theme.Text
				lbl.BackgroundTransparency = 1
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Size = UDim2.new(1, -38, 1, 0)
				lbl.Position = UDim2.new(0, 34, 0, 0)
				lbl.ZIndex = 5
				lbl.Parent = btn

				btn.MouseEnter:Connect(function()
					tweenObj(btn, 0.15, nil, nil, {BackgroundColor3 = Color3.fromRGB(
						math.clamp(theme.Second.R * 255 + 8, 0, 255),
						math.clamp(theme.Second.G * 255 + 8, 0, 255),
						math.clamp(theme.Second.B * 255 + 8, 0, 255))})
					tweenObj(ico, 0.15, nil, nil, {ImageColor3 = theme.Text})
				end)
				btn.MouseLeave:Connect(function()
					tweenObj(btn, 0.15, nil, nil, {BackgroundColor3 = theme.Second})
					tweenObj(ico, 0.15, nil, nil, {ImageColor3 = theme.TextDark})
				end)
				btn.MouseButton1Click:Connect(function()
					pcall(callback)
				end)
			end

			makeProfileBtn("Copy User ID", "rbxassetid://3944703587", function()
				if setclipboard then
					setclipboard(tostring(LocalPlayer.UserId))
					Isotope:Notify({Name = "Copied", Content = "User ID copied to clipboard.", Time = 3})
				end
			end)

			for _, item in ipairs(Isotope.USI) do
				makeProfileBtn(item.Name or "Option", item.Icon or "rbxassetid://3944703587", item.Callback or function() end)
			end

			local function dismissProfile()
				TweenService:Create(blur, TweenInfo.new(0.25), {Size = 0}):Play()
				tweenObj(backdrop, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 1})
				TweenService:Create(panel, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In),
					{Size = UDim2.new(0, 0, 0, 0)}):Play()
				task.wait(0.38)
				blur:Destroy()
				pGui:Destroy()
			end

			local closeBtn = Instance.new("TextButton")
			closeBtn.Text = "Close"
			closeBtn.Font = Enum.Font.GothamBold
			closeBtn.TextSize = 13
			closeBtn.TextColor3 = theme.TextDark
			closeBtn.BackgroundColor3 = theme.Second
			closeBtn.BorderSizePixel = 0
			closeBtn.AutoButtonColor = false
			closeBtn.Size = UDim2.new(1, 0, 0, 32)
			closeBtn.ZIndex = 4
			closeBtn.Parent = buttonHolder
			addCorner(closeBtn, 0, 6)
			addStroke(closeBtn, theme.Stroke, 1)
			closeBtn.MouseEnter:Connect(function()
				tweenObj(closeBtn, 0.15, nil, nil, {TextColor3 = theme.Text})
			end)
			closeBtn.MouseLeave:Connect(function()
				tweenObj(closeBtn, 0.15, nil, nil, {TextColor3 = theme.TextDark})
			end)
			closeBtn.MouseButton1Click:Connect(dismissProfile)

			local backdropBtn = Instance.new("TextButton")
			backdropBtn.Text = ""
			backdropBtn.BackgroundTransparency = 1
			backdropBtn.Size = UDim2.new(1, 0, 1, 0)
			backdropBtn.ZIndex = 1
			backdropBtn.Parent = pGui

			local isDraggingPanel = false
			panel.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					isDraggingPanel = true
				end
			end)
			panel.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					task.defer(function() isDraggingPanel = false end)
				end
			end)

			backdropBtn.MouseButton1Click:Connect(function()
				if isDraggingPanel then return end
				dismissProfile()
			end)
		end

		avatarFrame.MouseButton2Click:Connect(function()
			if not Isotope.UserSectionRightClick then return end
			openProfileView()
		end)

		-- closeelsewhere
		UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and menuOpen then
				local mousePos = UserInputService:GetMouseLocation()
				if avatarMenu and not (mousePos.X >= avatarMenu.AbsolutePosition.X and mousePos.X <= avatarMenu.AbsolutePosition.X + avatarMenu.AbsoluteSize.X and
					mousePos.Y >= avatarMenu.AbsolutePosition.Y and mousePos.Y <= avatarMenu.AbsolutePosition.Y + avatarMenu.AbsoluteSize.Y) then
					avatarMenu.Visible = false
					menuOpen = false
				end
			end
		end)

		--ref
		windowObject._AvatarFrame = avatarFrame
		windowObject._UserSectionContainer = userSectionContainer

		
		if showDisplayName then
			local displayNameLabel = Instance.new("TextLabel")
			displayNameLabel.Name = "DisplayName"
			displayNameLabel.Text = LocalPlayer.DisplayName
			displayNameLabel.TextColor3 = theme.Text
			displayNameLabel.TextSize = 13
			displayNameLabel.Font = Enum.Font.GothamBold
			displayNameLabel.BackgroundTransparency = 1
			displayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
			displayNameLabel.TextTruncate = Enum.TextTruncate.None
			displayNameLabel.Size = UDim2.new(1, -62, 0, 14)
			displayNameLabel.Position = UDim2.new(0, 50, 0, 8)
			displayNameLabel.Parent = userSectionContainer
			windowObject._DisplayNameLabel = displayNameLabel
		end

		if showUsername then
			local usernameLabel = Instance.new("TextLabel")
			usernameLabel.Name = "Username"
			usernameLabel.Text = "@" .. LocalPlayer.Name
			usernameLabel.TextColor3 = theme.TextDark
			usernameLabel.TextSize = 11
			usernameLabel.Font = Enum.Font.Gotham
			usernameLabel.BackgroundTransparency = 1
			usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
			usernameLabel.TextTruncate = Enum.TextTruncate.None
			usernameLabel.Size = UDim2.new(1, -62, 0, 12)
			usernameLabel.Position = UDim2.new(0, 50, 0, showDisplayName and 24 or 10)
			usernameLabel.Parent = userSectionContainer
			windowObject._UsernameLabel = usernameLabel
		end
	end

	--[[local avatarFrame = Instance.new("Frame")
	avatarFrame.BackgroundColor3 = theme.Divider
	avatarFrame.BorderSizePixel = 0
	avatarFrame.AnchorPoint = Vector2.new(0, 0.5)
	avatarFrame.Size = UDim2.new(0, 32, 0, 32)
	avatarFrame.Position = UDim2.new(0, 10, 0.5, 0)
	avatarFrame.Parent = bottomBar
	addCorner(avatarFrame, 1, 0)

	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId= " .. LocalPlayer.UserId .. "&width=420&height=420&format=png"
	avatarImage.BackgroundTransparency = 1
	avatarImage.Size = UDim2.new(1, 0, 1, 0)
	avatarImage.Parent = avatarFrame

	local avatarOverlay = Instance.new("ImageLabel")
	avatarOverlay.Image = "rbxassetid://4031889928"
	avatarOverlay.BackgroundTransparency = 1
	avatarOverlay.ImageColor3 = theme.Second
	avatarOverlay.Size = UDim2.new(1, 0, 1, 0)
	avatarOverlay.Parent = avatarFrame

	local avatarStrokeFrame = Instance.new("Frame")
	avatarStrokeFrame.BackgroundTransparency = 1
	avatarStrokeFrame.AnchorPoint = Vector2.new(0, 0.5)
	avatarStrokeFrame.Size = UDim2.new(0, 32, 0, 32)
	avatarStrokeFrame.Position = UDim2.new(0, 10, 0.5, 0)
	avatarStrokeFrame.Parent = bottomBar
	addCorner(avatarStrokeFrame, 1, 0)
	addStroke(avatarStrokeFrame, theme.Stroke, 1)

	local displayNameLabel = Instance.new("TextLabel")
	displayNameLabel.Text = LocalPlayer.DisplayName
	displayNameLabel.TextColor3 = theme.Text
	displayNameLabel.TextSize = 13
	displayNameLabel.Font = Enum.Font.GothamBold
	displayNameLabel.BackgroundTransparency = 1
	displayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	displayNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	displayNameLabel.Size = UDim2.new(1, -62, 0, 14)
	displayNameLabel.Position = UDim2.new(0, 50, 0, 8)
	displayNameLabel.Visible = showDisplayName
	displayNameLabel.Parent = bottomBar

	local usernameLabel = Instance.new("TextLabel")
	usernameLabel.Text = "@" .. LocalPlayer.Name
	usernameLabel.TextColor3 = theme.TextDark
	usernameLabel.TextSize = 11
	usernameLabel.Font = Enum.Font.Gotham
	usernameLabel.BackgroundTransparency = 1
	usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
	usernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	usernameLabel.Size = UDim2.new(1, -62, 0, 12)
	usernameLabel.Position = UDim2.new(0, 50, 0, showDisplayName and 24 or 10)
	usernameLabel.Visible = showUsername
	usernameLabel.Parent = bottomBar

	local avatarSubLabel = Instance.new("TextLabel")
	avatarSubLabel.Text = ""
	avatarSubLabel.TextColor3 = theme.TextDark
	avatarSubLabel.TextTransparency = 1
	avatarSubLabel.TextSize = 11
	avatarSubLabel.Font = Enum.Font.Gotham
	avatarSubLabel.BackgroundTransparency = 1
	avatarSubLabel.TextXAlignment = Enum.TextXAlignment.Left
	avatarSubLabel.TextTruncate = Enum.TextTruncate.AtEnd
	avatarSubLabel.AnchorPoint = Vector2.new(0, 0.5)
	avatarSubLabel.Size = UDim2.new(1, -56, 0, 14)
	avatarSubLabel.Position = UDim2.new(0, 50, 0.5, (showDisplayName or showUsername) and 8 or 0)
	avatarSubLabel.Parent = bottomBar --]]

	toggleSidebarButton.MouseButton1Click:Connect(function()
		if sidebarExpanded then
			sidebarExpanded = false
			for _, tabData in ipairs(allTabs) do
				tabData.btn.Title.TextTransparency = 1
				tabData.btn.Ico.AnchorPoint = Vector2.new(0.5, 0.5)
				tabData.btn.Ico.Position = UDim2.new(0.5, 0, 0.5, 0)
			end
			toggleSidebarIcon.Text = "\\"
			tweenObj(sidebar, 0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
				{Size = UDim2.new(0, 50, 1, -50)})
			if activeTabPage then
				tweenObj(activeTabPage, 0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
					{Size = UDim2.new(1, -50, 1, -50), Position = UDim2.new(0, 50, 0, 50)})
			end
			for tabIndex, tabData in ipairs(allTabs) do
				local delayTime = (tabIndex - 1) * 0.025
				task.delay(delayTime, function()
					tweenObj(tabData.btn.Title, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
						{TextTransparency = 1})
				end)
			end
			for _, child in ipairs(tabHolder:GetChildren()) do
				if child:IsA("TextLabel") then
					tweenObj(child, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 1})
				end
				if child:IsA("Frame") then
					child.Visible = false
				end
			end
			local dnl = windowObject._DisplayNameLabel
			local unl = windowObject._UsernameLabel
			if showDisplayName and dnl then
				tweenObj(dnl, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 1})
				task.delay(0.18, function() if not sidebarExpanded then dnl.Visible = false end end)
			end
			if showUsername and unl then
				tweenObj(unl, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 1})
				task.delay(0.18, function() if not sidebarExpanded then unl.Visible = false end end)
			end
			if avatarSubLabel then
				tweenObj(avatarSubLabel, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 1})
				task.delay(0.18, function() if not sidebarExpanded then avatarSubLabel.Visible = false end end)
			end
		else
			sidebarExpanded = true
			toggleSidebarIcon.Text = "/"
			tweenObj(sidebar, 0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
				{Size = UDim2.new(0, 150, 1, -50)})
			if activeTabPage then
				tweenObj(activeTabPage, 0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
					{Size = UDim2.new(1, -150, 1, -50), Position = UDim2.new(0, 150, 0, 50)})
			end
			for tabIndex, tabData in ipairs(allTabs) do
				local delayTime = (tabIndex - 1) * 0.03
				task.delay(delayTime, function()
					tabData.btn.Ico.AnchorPoint = Vector2.new(0, 0.5)
					tweenObj(tabData.btn.Ico, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
						{Position = UDim2.new(0, 10, 0.5, 0)})
					task.wait(0.18)
					tweenObj(tabData.btn.Title, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
						{TextTransparency = 0.4})
				end)
			end
			for _, child in ipairs(tabHolder:GetChildren()) do
				if child:IsA("TextLabel") then
					task.delay(0.2, function()
						tweenObj(child, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 0})
					end)
				end
				if child:IsA("Frame") then
					child.Visible = true
					task.delay(0.2, function()
						for _, secChild in ipairs(child:GetChildren()) do
							if secChild:IsA("TextLabel") then
								tweenObj(secChild, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 0})
							elseif secChild:IsA("ImageLabel") then
								tweenObj(secChild, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {ImageTransparency = 0})
							end
						end
					end)
				end
			end
			if showDisplayName and displayNameLabel then
				displayNameLabel.Visible = true
				task.delay(0.2, function()
					tweenObj(displayNameLabel, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 0})
				end)
			end
			if showUsername and usernameLabel then
				usernameLabel.Visible = true
				task.delay(0.2, function()
					tweenObj(usernameLabel, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 0})
				end)
			end
			if avatarSubLabel and avatarSubLabel.Text ~= "" then
				avatarSubLabel.Visible = true
				task.delay(0.2, function()
					tweenObj(avatarSubLabel, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 0})
				end)
			end
		end
	end)

	local function animClose(onDone)
		local origPos  = mainWindow.Position
		local origSize = mainWindow.Size

		local function finish()
			mainWindow.Visible = false
			mainWindow.Size    = UDim2.new(0, 615, 0, 344)
			mainWindow.Position = origPos
			mainWindow.ClipsDescendants = false
			onDone()
		end

		if closeAnim == "Shrink" then
			mainWindow.ClipsDescendants = true
			TweenService:Create(mainWindow,
				TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
				{
					Size = UDim2.new(0, 0, 0, 0),
					Position = UDim2.new(
						origPos.X.Scale,
						origPos.X.Offset + origSize.X.Offset,
						origPos.Y.Scale,
						origPos.Y.Offset
					),
				}):Play()
			task.delay(0.65, finish)

		elseif closeAnim == "Blob" then
			mainWindow.ClipsDescendants = true
			local cx = origPos.X.Offset + origSize.X.Offset / 2
			local cy = origPos.Y.Offset + origSize.Y.Offset / 2
			TweenService:Create(mainWindow,
				TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.In),
				{
					Size = UDim2.new(0, 0, 0, 0),
					Position = UDim2.new(origPos.X.Scale, cx, origPos.Y.Scale, cy),
				}):Play()
			task.delay(0.70, finish)

		else
			finish()
		end
	end

	local minimizedBar = nil
	local hoverConnection = nil
	local hoverStartTime = 0
	local isHovering = false
	
	local animRestore
	local function createMinimizedBar()
		if minimizedBar then
			minimizedBar:Destroy()
		end

		local bar = Instance.new("Frame")
		bar.Name = "MinimizedBar"
		bar.BackgroundColor3 = theme.Second
		bar.BorderSizePixel = 0
		bar.Size = UDim2.new(0, math.max(topBarlbl.TextBounds.X + 60, 150), 0, 40)
		bar.Position = UDim2.new(0.5, -bar.Size.X.Offset/2, 0, -50)
		bar.Parent = screenGui
		bar.ZIndex = 100
		addCorner(bar, 0, 8)
		addStroke(bar, theme.Stroke, 1)

		local barIcon = Instance.new("ImageLabel")
		barIcon.Image = "rbxassetid://7072719338"
		barIcon.BackgroundTransparency = 1
		barIcon.ImageColor3 = theme.Text
		barIcon.Size = UDim2.new(0, 20, 0, 20)
		barIcon.Position = UDim2.new(0, 10, 0.5, -10)
		barIcon.Parent = bar

		local barText = Instance.new("TextLabel")
		barText.Text = windowName
		barText.Font = Enum.Font.GothamBold
		barText.TextSize = 14
		barText.TextColor3 = theme.Text
		barText.BackgroundTransparency = 1
		barText.Size = UDim2.new(1, -40, 1, 0)
		barText.Position = UDim2.new(0, 35, 0, 0)
		barText.TextXAlignment = Enum.TextXAlignment.Left
		barText.Parent = bar

		tweenObj(bar, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
			{Position = UDim2.new(0.5, -bar.Size.X.Offset/2, 0, 20)})

		do
			local isDraggingBar = false
			local barDragStart = Vector2.new()
			local barStartPos = UDim2.new()
			bar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					isDraggingBar = true
					barDragStart = input.Position
					barStartPos = bar.Position
					input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then
							isDraggingBar = false
						end
					end)
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if isDraggingBar and input.UserInputType == Enum.UserInputType.MouseMovement then
					local delta = input.Position - barDragStart
					bar.Position = UDim2.new(
						barStartPos.X.Scale,
						barStartPos.X.Offset + delta.X,
						barStartPos.Y.Scale,
						barStartPos.Y.Offset + delta.Y
					)
				end
			end)
		end

		local hoverDetector = Instance.new("TextButton")
		hoverDetector.Name = "HoverDetector"
		hoverDetector.Text = ""
		hoverDetector.BackgroundTransparency = 1
		hoverDetector.Size = UDim2.new(1, 20, 1, 20)
		hoverDetector.Position = UDim2.new(0, -10, 0, -10)
		hoverDetector.Parent = bar
		hoverDetector.ZIndex = 101

		local hoverTimer = nil

		hoverDetector.MouseEnter:Connect(function()
			isHovering = true
			tweenObj(bar, 0.2, nil, nil, {BackgroundColor3 = Color3.fromRGB(
				math.clamp(theme.Second.R * 255 + 15, 0, 255),
				math.clamp(theme.Second.G * 255 + 15, 0, 255),
				math.clamp(theme.Second.B * 255 + 15, 0, 255))})

			hoverTimer = task.delay(Isotope.HoverMaximizeDelay, function()
				if isHovering and minimizedBar then
					isHovering = false
					local currentBar = minimizedBar
					minimizedBar = nil

					Animations.ElasticMaximize(currentBar, UDim2.new(0, 615, 0, 344), 
						UDim2.new(0.5, -307, 0.5, -172), function()
							currentBar:Destroy()
							mainWindow.Visible = true
							mainWindow.Size = UDim2.new(0, 615, 0, 344)
							mainWindow.Position = UDim2.new(0.5, -307, 0.5, -172)
							isMinimized = false
							sidebar.Visible = true
							topBarDivider.Visible = true
							minimizeIcon.Image = "rbxassetid://7072719338"
						end)
				end
			end)
		end)

		hoverDetector.MouseLeave:Connect(function()
			isHovering = false
			if hoverTimer then
				task.cancel(hoverTimer)
				hoverTimer = nil
			end
			tweenObj(bar, 0.2, nil, nil, {BackgroundColor3 = theme.Second})
		end)

		hoverDetector.MouseButton1Click:Connect(function()
			isHovering = false
			if hoverTimer then
				task.cancel(hoverTimer)
				hoverTimer = nil
			end
			local currentBar = minimizedBar
			minimizedBar = nil
			currentBar:Destroy()
			isMinimized = false
			animRestore(function()
				sidebar.Visible = true
				topBarDivider.Visible = true
				minimizeIcon.Image = "rbxassetid://7072719338"
			end)
		end)

		minimizedBar = bar
		return bar
	end

	local function animMinimize(onDone)
		if minimizeAnim == "Slide" then
			tweenObj(mainWindow, 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
				{Position = UDim2.new(0.5, -307, 0, -400)})
			task.delay(0.42, function()
				mainWindow.Visible = false
				mainWindow.Size = UDim2.new(0, 615, 0, 344)
				mainWindow.Position = UDim2.new(0.5, -307, 0.5, -172)
				createMinimizedBar()
				onDone()
			end)

		elseif minimizeAnim == "Blob" then
			mainWindow.ClipsDescendants = true
			local cx = mainWindow.Position.X.Offset + 615 / 2
			local cy = mainWindow.Position.Y.Offset + 344 / 2
			TweenService:Create(mainWindow,
				TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In),
				{Size = UDim2.new(0, 0, 0, 0),
					Position = UDim2.new(mainWindow.Position.X.Scale, cx, mainWindow.Position.Y.Scale, cy)}):Play()
			task.delay(0.47, function()
				mainWindow.Visible = false
				mainWindow.ClipsDescendants = false
				mainWindow.Size = UDim2.new(0, 615, 0, 344)
				mainWindow.Position = UDim2.new(0.5, -307, 0.5, -172)
				createMinimizedBar()
				onDone()
			end)

		else
			mainWindow.Visible = false
			createMinimizedBar()
			onDone()
		end
	end

	animRestore = function(onDone)
		mainWindow.AnchorPoint = Vector2.new(0, 0)
		mainWindow.ClipsDescendants = true

		if minimizeAnim == "Slide" then
			mainWindow.Size = UDim2.new(0, 615, 0, 344)
			mainWindow.Position = UDim2.new(0.5, -307, 0, -350)
			mainWindow.Visible = true
			local t = TweenService:Create(mainWindow,
				TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{Position = UDim2.new(0.5, -307, 0.5, -172)})
			t:Play()
			t.Completed:Connect(function()
				mainWindow.ClipsDescendants = false
				onDone()
			end)

		elseif minimizeAnim == "Blob" then
			mainWindow.Size = UDim2.new(0, 0, 0, 0)
			mainWindow.Position = UDim2.new(0.5, -307, 0.5, -172)
			mainWindow.Visible = true
			local t = TweenService:Create(mainWindow,
				TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{Size = UDim2.new(0, 615, 0, 344)})
			t:Play()
			t.Completed:Connect(function()
				mainWindow.ClipsDescendants = false
				onDone()
			end)

		else
			mainWindow.Size = UDim2.new(0, 615, 0, 344)
			mainWindow.Position = UDim2.new(0.5, -307, 0.5, -172)
			mainWindow.Visible = true
			mainWindow.ClipsDescendants = false
			onDone()
		end
	end

	minimizeButton.MouseButton1Up:Connect(function()
		if isMinimized then
			if minimizedBar then
				minimizedBar:Destroy()
				minimizedBar = nil
			end
			animRestore(function()
				sidebar.Visible = true
				topBarDivider.Visible = true
				minimizeIcon.Image = "rbxassetid://7072719338"
			end)
			isMinimized = false
		else
			minimizeIcon.Image = "rbxassetid://7072720870"
			animMinimize(function() end)
			isMinimized = true
		end
	end)

	closeButton.MouseButton1Up:Connect(function()
		animClose(function()
			isHidden = true
			pcall(closeCallback)
			Isotope:Notify({
				Name = "Interface Hidden",
				Content = "Press " .. tostring(reopenKey.Name) .. " to reopen.",
				Time = 5,
			})
		end)
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode ~= reopenKey then return end
		if not isHidden and not isMinimized then return end
		if isMinimized then
			if minimizedBar then minimizedBar:Destroy() minimizedBar = nil end
			animRestore(function()
				sidebar.Visible = true
				topBarDivider.Visible = true
				minimizeIcon.Image = "rbxassetid://7072719338"
			end)
			isMinimized = false
			return
		end
		isHidden = false
		if doStartup and Animations[startupAnim] then
			task.spawn(function()
				Animations[startupAnim](mainWindow, screenGui, theme, startupText, startupIcon)
			end)
		else
			animRestore(function() end)
		end
	end)

	local function restoreWindow()
		if isHidden then
			isHidden = false
			isMinimized = false
			if doStartup and Animations[startupAnim] then
				task.spawn(function()
					Animations[startupAnim](mainWindow, screenGui, theme, startupText, startupIcon)
				end)
			else
				animRestore(function() end)
			end
			return
		end
		if isMinimized then
			if minimizedBar then
				minimizedBar:Destroy()
				minimizedBar = nil
			end
			animRestore(function()
				sidebar.Visible = true
				topBarDivider.Visible = true
				minimizeIcon.Image = "rbxassetid://7072719338"
			end)
			isMinimized = false
		end
	end
	Isotope._RestoreRef = restoreWindow
	Isotope._MinimizedRef = function() return isMinimized end

	local function selectTab(page, button)
		if activeTabPage then activeTabPage.Visible = false end
		if activeTabButton then
			activeTabButton.Title.Font = Enum.Font.GothamSemibold
			tweenObj(activeTabButton.Ico, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {ImageTransparency = 0.4})
			tweenObj(activeTabButton.Title, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TextTransparency = sidebarExpanded and 0.4 or 1})
		end
		activeTabPage = page
		activeTabButton = button
		if page then
			page.Visible = true
			local sidebarWidth = sidebarExpanded and 150 or 50
			page.Size = UDim2.new(1, -sidebarWidth, 1, -50)
			page.Position = UDim2.new(0, sidebarWidth, 0, 50)
		end
		if button then
			button.Title.Font = Enum.Font.GothamBlack
			tweenObj(button.Ico, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {ImageTransparency = 0})
			tweenObj(button.Title, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TextTransparency = sidebarExpanded and 0 or 1})
		end
	end

	function windowObject:SetUserSectionEnabled(enabled)
		Isotope.UserSection = enabled
		if bottomBar then
			bottomBar.Visible = enabled
		end
		if enabled then
			tabHolder.Size = UDim2.new(1, 0, 1, -50)
			bottomDivider.Visible = true
		else
			tabHolder.Size = UDim2.new(1, 0, 1, 0)
			bottomDivider.Visible = false
		end
	end

	function windowObject:SetAvatarMenuEnabled(enabled)
		Isotope.UserSectionRightClick = enabled
	end

	function windowObject:AddAvatarMenuItem(name, callback, icon)
		table.insert(Isotope.USI, {
			Name = name,
			Callback = callback,
			Icon = icon or "rbxassetid://3944703587"
		})
	end

	function windowObject:ClearAvatarMenu()
		table.clear(Isotope.USI)
		table.clear(Isotope.USI)
	end

	function windowObject:SetDisplayName(text)
		if windowObject._DisplayNameLabel then
			windowObject._DisplayNameLabel.Text = tostring(text)
		end
	end

	function windowObject:SetUsername(text)
		if windowObject._UsernameLabel then
			windowObject._UsernameLabel.Text = tostring(text)
		end
	end

	function windowObject:GetAvatarFrame()
		return windowObject._AvatarFrame
	end

	function windowObject:GetUserSectionContainer()
		return windowObject._UserSectionContainer
	end

	function windowObject:Toast(text, icon)
		text = tostring(text or "")
		task.spawn(function()
			local topY = Isotope.ShowTopbar and (14 + 48 + 8) or 14

			local toast = Instance.new("Frame")
			toast.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
			toast.BorderSizePixel = 0
			toast.AutomaticSize = Enum.AutomaticSize.X
			toast.Size = UDim2.new(0, 0, 0, 32)
			toast.AnchorPoint = Vector2.new(0.5, 0)
			toast.Position = UDim2.new(0.5, 0, 0, topY - 8)
			toast.BackgroundTransparency = 1
			toast.ZIndex = 21
			toast.Parent = toastScreenGui
			addCorner(toast, 0, 16)
			addStroke(toast, Color3.fromRGB(55, 55, 72), 1)

			local innerRow = Instance.new("Frame")
			innerRow.BackgroundTransparency = 1
			innerRow.AutomaticSize = Enum.AutomaticSize.X
			innerRow.Size = UDim2.new(0, 0, 1, 0)
			innerRow.Position = UDim2.new(0, 0, 0, 0)
			innerRow.ZIndex = 22
			innerRow.Parent = toast

			local rowLayout = Instance.new("UIListLayout")
			rowLayout.FillDirection = Enum.FillDirection.Horizontal
			rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			rowLayout.Padding = UDim.new(0, 6)
			rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
			rowLayout.Parent = innerRow

			local rowPad = Instance.new("UIPadding")
			rowPad.PaddingLeft = UDim.new(0, 12)
			rowPad.PaddingRight = UDim.new(0, 14)
			rowPad.PaddingTop = UDim.new(0, 0)
			rowPad.PaddingBottom = UDim.new(0, 0)
			rowPad.Parent = innerRow

			if icon and icon ~= "" then
				local ico = Instance.new("ImageLabel")
				ico.Image = icon
				ico.BackgroundTransparency = 1
				ico.ImageColor3 = Color3.fromRGB(190, 190, 210)
				ico.Size = UDim2.new(0, 14, 0, 14)
				ico.ZIndex = 22
				ico.LayoutOrder = 1
				ico.Parent = innerRow
			end

			local lbl = Instance.new("TextLabel")
			lbl.Text = text
			lbl.Font = Enum.Font.GothamSemibold
			lbl.TextSize = 13
			lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
			lbl.BackgroundTransparency = 1
			lbl.AutomaticSize = Enum.AutomaticSize.X
			lbl.Size = UDim2.new(0, 0, 1, 0)
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.ZIndex = 22
			lbl.LayoutOrder = 2
			lbl.Parent = innerRow

			tweenObj(toast, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
				{BackgroundTransparency = 0, Position = UDim2.new(0.5, 0, 0, topY)})

			task.wait(2)

			tweenObj(toast, 0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.In,
				{BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, topY - 8)})
			tweenObj(lbl, 0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.In, {TextTransparency = 1})
			task.wait(0.3)
			toast:Destroy()
		end)
	end

	function windowObject:SetTitle(text)
		topBarlbl.Text = tostring(text or "")
	end

	function windowObject:Lock(message)
		lockLabel.Text = tostring(message or "Loading...")
		lockOverlay.BackgroundTransparency = 1
		lockOverlay.Visible = true
		lockInputBlocker.Visible = true
		tweenObj(lockOverlay, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
			{BackgroundTransparency = 0.45})
		if activeTabPage then activeTabPage.ScrollingEnabled = false end
	end

	function windowObject:Unlock()
		tweenObj(lockOverlay, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
			{BackgroundTransparency = 1})
		lockInputBlocker.Visible = false
		task.delay(0.28, function()
			lockOverlay.Visible = false
		end)
		if activeTabPage then activeTabPage.ScrollingEnabled = true end
	end

	local flashActive = false
	function windowObject:Flash(color)
		if flashActive then return end
		flashActive = true
		local useColor = (type(color) == "userdata" and color) or accentColor
		local origColor = windowStroke.Color
		local origThick = windowStroke.Thickness
		tweenObj(windowStroke, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
			{Color = useColor, Thickness = 4})
		task.delay(0.1, function()
			tweenObj(windowStroke, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
				{Color = useColor, Thickness = 6})
			task.delay(0.15, function()
				tweenObj(windowStroke, 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
					{Color = origColor, Thickness = origThick})
				task.delay(0.4, function()
					flashActive = false
				end)
			end)
		end)
	end

	function windowObject:SetReopenKey(key)
		reopenKey = key
	end

	function windowObject:SetCloseAnim(anim)
		closeAnim = anim
	end

	function windowObject:SetMinimizeAnim(anim)
		minimizeAnim = anim
	end

	function windowObject:SetAvatarText(text)
		if windowObject._UsernameLabel then
			windowObject._UsernameLabel.Text = tostring(text)
		elseif windowObject._DisplayNameLabel then
			windowObject._DisplayNameLabel.Text = tostring(text)
		end
	end

	function windowObject:SetTheme(name)
		local newTheme = Themes[name]
		if not newTheme then return end
		theme = newTheme
		Isotope._activeTheme = newTheme

		mainWindow.BackgroundColor3 = newTheme.Main
		sidebar.BackgroundColor3 = newTheme.Second
		sidebarTopCover.BackgroundColor3 = newTheme.Second
		sidebarRightCover.BackgroundColor3 = newTheme.Second
		sidebarDivider.BackgroundColor3 = newTheme.Stroke
		bottomDivider.BackgroundColor3 = newTheme.Stroke
		topBarDivider.BackgroundColor3 = newTheme.Stroke
		buttonDivider1.BackgroundColor3 = newTheme.Stroke
		buttonDivider2.BackgroundColor3 = newTheme.Stroke
		windowButtonContainer.BackgroundColor3 = newTheme.Second
		topBarlbl.TextColor3 = newTheme.Text
		toggleSidebarIcon.TextColor3 = newTheme.Text
		if displayNameLabel then displayNameLabel.TextColor3 = newTheme.Text end
		if usernameLabel then usernameLabel.TextColor3 = newTheme.TextDark end
		if avatarSubLabel then avatarSubLabel.TextColor3 = newTheme.TextDark end
		if avatarOverlay then avatarOverlay.ImageColor3 = newTheme.Second end
		if avatarFrame then avatarFrame.BackgroundColor3 = newTheme.Divider end
		minimizeIcon.ImageColor3 = newTheme.Text
		closeIcon.ImageColor3 = newTheme.Text
		tabHolder.ScrollBarImageColor3 = newTheme.Divider
		windowStroke.Color = newTheme.Stroke

		accentColor = newTheme.Accent or Color3.fromRGB(0, 170, 255)

		for _, entry in ipairs(Isotope._ElementRegistry) do
			if entry.obj and entry.obj.RefreshTheme then
				pcall(function() entry.obj:RefreshTheme(newTheme) end)
			end
		end

		if Isotope._TopbarGui then Isotope:Topbar(newTheme) end
		if Isotope._RadialGui then Isotope:Radial(newTheme) end
	end

	function windowObject:SetAccentColor(color)
		accentColor = color
		for _, element in pairs(accentElements) do
			if element and element.Parent then
				pcall(function() element.BackgroundColor3 = color end)
			end
		end
	end

	function windowObject:Tab(tabConfig)
		tabConfig = tabConfig or {}
		local tabName = tabConfig.Name or "Tab"
		local tabIcon = tabConfig.Icon or ""

		local tabButton = Instance.new("TextButton")
		tabButton.Text = ""
		tabButton.AutoButtonColor = false
		tabButton.BackgroundTransparency = 1
		tabButton.BorderSizePixel = 0
		tabButton.Size = UDim2.new(1, 0, 0, 30)
		tabButton.Parent = tabHolder
		tabButton.ClipsDescendants = true

		local tabButtonIcon = Instance.new("ImageLabel")
		tabButtonIcon.Name = "Ico"
		tabButtonIcon.Image = tabIcon
		tabButtonIcon.BackgroundTransparency = 1
		tabButtonIcon.ImageColor3 = theme.Text
		tabButtonIcon.ImageTransparency = 0.4
		tabButtonIcon.AnchorPoint = Vector2.new(0, 0.5)
		tabButtonIcon.Size = UDim2.new(0, 18, 0, 18)
		tabButtonIcon.Position = UDim2.new(0, 10, 0.5, 0)
		tabButtonIcon.Parent = tabButton

		local tabButtonTitle = Instance.new("TextLabel")
		tabButtonTitle.Name = "Title"
		tabButtonTitle.Text = tabName
		tabButtonTitle.Font = Enum.Font.GothamSemibold
		tabButtonTitle.TextSize = 14
		tabButtonTitle.TextColor3 = theme.Text
		tabButtonTitle.TextTransparency = 0.4
		tabButtonTitle.BackgroundTransparency = 1
		tabButtonTitle.TextXAlignment = Enum.TextXAlignment.Left
		tabButtonTitle.TextTruncate = Enum.TextTruncate.None
		tabButtonTitle.Size = UDim2.new(1, -35, 1, 0)
		tabButtonTitle.Position = UDim2.new(0, 35, 0, 0)
		tabButtonTitle.Parent = tabButton

		local tabPage = Instance.new("ScrollingFrame")
		tabPage.Name = tabName .. "_Page"
		tabPage.BackgroundTransparency = 1
		tabPage.BorderSizePixel = 0
		tabPage.ScrollBarThickness = 5
		tabPage.ScrollBarImageColor3 = theme.Divider
		tabPage.MidImage = "rbxassetid://7445543667"
		tabPage.BottomImage = "rbxassetid://7445543667"
		tabPage.TopImage = "rbxassetid://7445543667"
		tabPage.CanvasSize = UDim2.new(0, 0, 0, 0)
		tabPage.Size = UDim2.new(1, -150, 1, -50)
		tabPage.Position = UDim2.new(0, 150, 0, 50)
		tabPage.ZIndex = 3
		tabPage.Visible = false
		tabPage.Parent = mainWindow

		local pageLayout = addListLayout(tabPage, 6)
		addPadding(tabPage, 15, 10, 10, 15)
		pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			tabPage.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 30)
		end)

		local tabEntry = {
			name = tabName,
			icon = tabIcon,
			selectFn = function() selectTab(tabPage, tabButton) end,
		}
		table.insert(Isotope._Tabs, tabEntry)
		
		
		sidebarCount += 1
		tabButton.LayoutOrder = sidebarCount
		table.insert(allTabs, {btn = tabButton, page = tabPage})
		if currentSection then
			table.insert(currentSection, tabButton)
		end
		if #allTabs == 1 then selectTab(tabPage, tabButton) end

		tabButton.MouseButton1Click:Connect(function()
			selectTab(tabPage, tabButton)
		end)

		local function makeElementFrame(height, parentOverride)
			local frame = Instance.new("Frame")
			frame.BackgroundColor3 = theme.Second
			frame.BorderSizePixel = 0
			frame.Size = UDim2.new(1, 0, 0, height)
			frame.Parent = parentOverride or tabPage
			addCorner(frame, 0, 5)
			addStroke(frame, theme.Stroke, 1)
			return frame
		end

		local function applyHover(clickButton, targetFrame)
			clickButton.MouseEnter:Connect(function()
				tweenObj(targetFrame, 0.25, nil, nil, {BackgroundColor3 = Color3.fromRGB(
					math.clamp(theme.Second.R * 255 + 3, 0, 255),
					math.clamp(theme.Second.G * 255 + 3, 0, 255),
					math.clamp(theme.Second.B * 255 + 3, 0, 255))})
			end)
			clickButton.MouseLeave:Connect(function()
				tweenObj(targetFrame, 0.25, nil, nil, {BackgroundColor3 = theme.Second})
			end)
			clickButton.MouseButton1Down:Connect(function()
				tweenObj(targetFrame, 0.25, nil, nil, {BackgroundColor3 = Color3.fromRGB(
					math.clamp(theme.Second.R * 255 + 6, 0, 255),
					math.clamp(theme.Second.G * 255 + 6, 0, 255),
					math.clamp(theme.Second.B * 255 + 6, 0, 255))})
			end)
			clickButton.MouseButton1Up:Connect(function()
				tweenObj(targetFrame, 0.25, nil, nil, {BackgroundColor3 = Color3.fromRGB(
					math.clamp(theme.Second.R * 255 + 3, 0, 255),
					math.clamp(theme.Second.G * 255 + 3, 0, 255),
					math.clamp(theme.Second.B * 255 + 3, 0, 255))})
			end)
		end

		local function makeLockedFrame(parent)
			local overlay = Instance.new("Frame")
			overlay.Name = "LockedOverlay"
			overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			overlay.BackgroundTransparency = 1
			overlay.BorderSizePixel = 0
			overlay.Size = UDim2.new(1, 0, 1, 0)
			overlay.ZIndex = 20
			overlay.Visible = false
			overlay.Parent = parent
			addCorner(overlay, 0, 5)

			local lockIcon = Instance.new("ImageLabel")
			lockIcon.Image = "rbxassetid://3944703255"
			lockIcon.BackgroundTransparency = 1
			lockIcon.ImageColor3 = Color3.fromRGB(200, 200, 200)
			lockIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			lockIcon.Size = UDim2.new(0, 16, 0, 16)
			lockIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
			lockIcon.Parent = overlay

			return overlay
		end

		local tabObject = {}
		tabObject._tabEntry = tabEntry
		
		function tabObject:Stepper(config, parentOverride)
			config = type(config) == "table" and config or {}
			local stepName = config.Name or "Stepper"
			local stepOptions = config.Options or {}
			local stepDefault = config.Default or stepOptions[1]
			local stepCallback = config.Callback or function() end
			local stepFlag = config.Flag
			local stepSave = config.Save or false

			local cIndx = 1
			for i, v in ipairs(stepOptions) do
				if v == stepDefault then cIndx = i break end
			end

			local stepObj = {Value = stepOptions[cIndx], Type = "Stepper", Save = stepSave}

			local f = makeElementFrame(38, parentOverride)

			local nameLbl = Instance.new("TextLabel")
			nameLbl.Text = stepName
			nameLbl.Font = Enum.Font.GothamBold
			nameLbl.TextSize = 15
			nameLbl.TextColor3 = theme.Text
			nameLbl.BackgroundTransparency = 1
			nameLbl.TextXAlignment = Enum.TextXAlignment.Left
			nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
			nameLbl.Size = UDim2.new(1, -150, 1, 0)
			nameLbl.Position = UDim2.new(0, 12, 0, 0)
			nameLbl.Parent = f

			local nextBtn = Instance.new("TextButton")
			nextBtn.Text = ">"
			nextBtn.Font = Enum.Font.GothamBold
			nextBtn.TextSize = 14
			nextBtn.TextColor3 = theme.TextDark
			nextBtn.BackgroundColor3 = theme.Main
			nextBtn.BorderSizePixel = 0
			nextBtn.AutoButtonColor = false
			nextBtn.AnchorPoint = Vector2.new(1, 0.5)
			nextBtn.Size = UDim2.new(0, 26, 0, 26)
			nextBtn.Position = UDim2.new(1, -10, 0.5, 0)
			nextBtn.Parent = f
			addCorner(nextBtn, 0, 4)
			addStroke(nextBtn, theme.Stroke, 1)

			local valueLabel = Instance.new("TextLabel")
			valueLabel.Text = tostring(stepOptions[cIndx])
			valueLabel.Font = Enum.Font.GothamSemibold
			valueLabel.TextSize = 13
			valueLabel.TextColor3 = theme.Text
			valueLabel.BackgroundTransparency = 1
			valueLabel.TextXAlignment = Enum.TextXAlignment.Center
			valueLabel.AnchorPoint = Vector2.new(1, 0.5)
			valueLabel.Size = UDim2.new(0, 60, 0, 26)
			valueLabel.Position = UDim2.new(1, -44, 0.5, 0)
			valueLabel.Parent = f

			local prevBtn = Instance.new("TextButton")
			prevBtn.Text = "<"
			prevBtn.Font = Enum.Font.GothamBold
			prevBtn.TextSize = 14
			prevBtn.TextColor3 = theme.TextDark
			prevBtn.BackgroundColor3 = theme.Main
			prevBtn.BorderSizePixel = 0
			prevBtn.AutoButtonColor = false
			prevBtn.AnchorPoint = Vector2.new(1, 0.5)
			prevBtn.Size = UDim2.new(0, 26, 0, 26)
			prevBtn.Position = UDim2.new(1, -112, 0.5, 0)
			prevBtn.Parent = f
			addCorner(prevBtn, 0, 4)
			addStroke(prevBtn, theme.Stroke, 1)

			function stepObj:Set(Indx)
				cIndx = math.clamp(Indx, 1, #stepOptions)
				stepObj.Value = stepOptions[cIndx]
				valueLabel.Text = tostring(stepObj.Value)
				tweenObj(prevBtn, 0.15, nil, nil, {TextColor3 = cIndx == 1 and theme.Stroke or theme.Text})
				tweenObj(nextBtn, 0.15, nil, nil, {TextColor3 = cIndx == #stepOptions and theme.Stroke or theme.Text})
				pcall(stepCallback, stepObj.Value)
			end

			prevBtn.MouseButton1Click:Connect(function()
				stepObj:Set(cIndx - 1)
			end)
			nextBtn.MouseButton1Click:Connect(function()
				stepObj:Set(cIndx + 1)
			end)

			stepObj:Set(cIndx)
			if stepFlag then Isotope.Flags[stepFlag] = stepObj end

			function stepObj:RefreshTheme(t)
				nameLbl.TextColor3 = t.Text
				valueLabel.TextColor3 = t.Text
				f.BackgroundColor3 = t.Second
				prevBtn.BackgroundColor3 = t.Main
				nextBtn.BackgroundColor3 = t.Main
				local s = f:FindFirstChildOfClass("UIStroke") if s then s.Color = t.Stroke end
				local s2 = prevBtn:FindFirstChildOfClass("UIStroke") if s2 then s2.Color = t.Stroke end
				local s3 = nextBtn:FindFirstChildOfClass("UIStroke") if s3 then s3.Color = t.Stroke end
			end

			table.insert(Isotope._ElementRegistry, {name = stepName, obj = stepObj, tab = tabEntry})
			return stepObj
		end
		
		function tabObject:KeyValue(config, parentOverride)
			config = type(config) == "table" and config or {}
			local pairs_l = config.Pairs or {} 
			local kvName = config.Name or ""
			
			local f = makeElementFrame(0, parentOverride)
			f.AutomaticSize = Enum.AutomaticSize.Y
			f.Size = UDim2.new(1, 0, 0, 0)
			
			local layout = addListLayout(f, 0)
			addPadding(f, 8, 8, 12, 12)
			
			local rs = {}
			
			local function addr(key, val) -- if u tryna fork this gl im too lazy to give the vars some names
				local r = Instance.new("Frame")
				r.BackgroundTransparency = 1
				r.Size = UDim2.new(1, 0, 0, 24)
				r.Parent = f
				
				local keyl = Instance.new("TextLabel")
				keyl.Text = tostring(key)
				keyl.Font = Enum.Font.GothamBold
				keyl.TextSize = 13
				keyl.TextColor3 = theme.TextDark
				keyl.BackgroundTransparency = 1
				keyl.TextXAlignment = Enum.TextXAlignment.Left
				keyl.Size = UDim2.new(0.5, 0, 1, 0)
				keyl.Parent = r
				
				local vall = Instance.new("TextLabel")
				vall.Text = tostring(val)
				vall.Font = Enum.Font.GothamBold
				vall.TextSize = 13
				vall.TextColor3 = theme.Text
				vall.BackgroundTransparency = 1
				vall.TextXAlignment = Enum.TextXAlignment.Right
				vall.Size = UDim2.new(0.5, 0, 1, 0)
				vall.Position = UDim2.new(0.5, 0, 0, 0)
				vall.Parent = r
				
				table.insert(rs, {r = r, key = keyl, val = vall})
			end
			
			for _, pair in ipairs(pairs_l) do
				addr(pair[1], pair[2])
			end
			
			local obj = {Type = "KeyValue"}

			function obj:Set(key, val)
				for _, r in ipairs(rs) do
					if r.key.Text == tostring(key) then
						r.val.Text = tostring(val)
						return
					end
				end
			end
			
			function obj:SetAll(newPairs)
				for _, r in ipairs(rs) do r.r:Destroy() end
				table.clear(rs)
				for _, pair in ipairs(newPairs) do
					addr(pair[1], pair[2])
				end
			end
			
			function obj:RefreshTheme(t)
				f.BackgroundColor3 = t.Second
				for _, r in ipairs(rs) do
					r.key.TextColor3 = t.TextDark
					r.val.TextColor3 = t.Text
				end
				local s = f:FindFirstChildOfClass("UIStroke") if s then s.Color = t.Stroke end
			end
			
			table.insert(Isotope._ElementRegistry, {name = kvName, obj = obj, tab = tabEntry})
			return obj
		end

		function tabObject:Section(text, parentOverride)
			local resolvedText = type(text) == "table" and (text.Name or "Section") or tostring(text)
			local targetParent = parentOverride or tabPage

			local sectionFrame = Instance.new("Frame")
			sectionFrame.BackgroundTransparency = 1
			sectionFrame.Size = UDim2.new(1, 0, 0, 26)
			sectionFrame.Parent = targetParent

			local sectionLabel = Instance.new("TextLabel")
			sectionLabel.Text = resolvedText
			sectionLabel.Font = Enum.Font.GothamSemibold
			sectionLabel.TextSize = 14
			sectionLabel.TextColor3 = theme.TextDark
			sectionLabel.BackgroundTransparency = 1
			sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
			sectionLabel.Size = UDim2.new(1, -12, 0, 16)
			sectionLabel.Position = UDim2.new(0, 0, 0, 3)
			sectionLabel.Parent = sectionFrame

			local sectionHolder = Instance.new("Frame")
			sectionHolder.BackgroundTransparency = 1
			sectionHolder.Size = UDim2.new(1, 0, 1, -24)
			sectionHolder.Position = UDim2.new(0, 0, 0, 23)
			sectionHolder.Parent = sectionFrame

			local sectionHolderLayout = addListLayout(sectionHolder, 6)
			sectionHolderLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				sectionFrame.Size = UDim2.new(1, 0, 0, sectionHolderLayout.AbsoluteContentSize.Y + 31)
				sectionHolder.Size = UDim2.new(1, 0, 0, sectionHolderLayout.AbsoluteContentSize.Y)
			end)

			local sectionObject = {}
			function sectionObject:Button(t, cb)           return tabObject:Button(t, cb, sectionHolder) end
			function sectionObject:Toggle(t, d, cb, fl)        return tabObject:Toggle(t, d, cb, fl, sectionHolder) end
			function sectionObject:Label(t)           return tabObject:Label(t, sectionHolder) end
			function sectionObject:TextBox(p, cb)              return tabObject:TextBox(p, cb, sectionHolder) end
			function sectionObject:Slider(t, mn, mx, df, cb, fl) return tabObject:Slider(t, mn, mx, df, cb, fl, sectionHolder) end
			function sectionObject:Paragraph(t, c)             return tabObject:Paragraph(t, c, sectionHolder) end
			function sectionObject:Dropdown(c)            return tabObject:Dropdown(c, sectionHolder) end
			function sectionObject:Bind(c)                  return tabObject:Bind(c, sectionHolder) end
			function sectionObject:Colorpicker(c)          return tabObject:Colorpicker(c, sectionHolder) end
			function sectionObject:MultiDropdown(c)       return tabObject:MultiDropdown(c, sectionHolder) end
			function sectionObject:ProgressBar(t, d)      return tabObject:ProgressBar(t, d, sectionHolder) end
			function sectionObject:Stepper(c)             return tabObject:Stepper(c, sectionHolder) end
			function sectionObject:KeyValue(c)            return tabObject:KeyValue(c, sectionHolder) end
			return sectionObject
		end

		function tabObject:Separator(text, parentOverride)
			local frame = Instance.new("Frame")
			frame.BackgroundTransparency = 1
			frame.BorderSizePixel = 0
			frame.Size = UDim2.new(1, 0, 0, text and 22 or 10)
			frame.Parent = parentOverride or tabPage

			if text then
				local leftLine = Instance.new("Frame")
				leftLine.BackgroundColor3 = theme.Stroke
				leftLine.BorderSizePixel = 0
				leftLine.AnchorPoint = Vector2.new(0, 0.5)
				leftLine.Size = UDim2.new(0.5, -60, 0, 1)
				leftLine.Position = UDim2.new(0, 10, 0.5, 0)
				leftLine.Parent = frame

				local rightLine = Instance.new("Frame")
				rightLine.BackgroundColor3 = theme.Stroke
				rightLine.BorderSizePixel = 0
				rightLine.AnchorPoint = Vector2.new(0, 0.5)
				rightLine.Size = UDim2.new(0.5, -60, 0, 1)
				rightLine.Position = UDim2.new(0.5, 50, 0.5, 0)
				rightLine.Parent = frame

				local lbl = Instance.new("TextLabel")
				lbl.Text = tostring(text)
				lbl.Font = Enum.Font.GothamSemibold
				lbl.TextSize = 10
				lbl.TextColor3 = theme.TextDark
				lbl.BackgroundTransparency = 1
				lbl.BorderSizePixel = 0
				lbl.AutomaticSize = Enum.AutomaticSize.X
				lbl.Size = UDim2.new(0, 0, 0, 14)
				lbl.AnchorPoint = Vector2.new(0.5, 0.5)
				lbl.Position = UDim2.new(0.5, 0, 0.5, 0)
				lbl.Parent = frame
			else
				local line = Instance.new("Frame")
				line.BackgroundColor3 = theme.Stroke
				line.BorderSizePixel = 0
				line.Size = UDim2.new(1, -20, 0, 1)
				line.AnchorPoint = Vector2.new(0.5, 0.5)
				line.Position = UDim2.new(0.5, 0, 0.5, 0)
				line.Parent = frame
			end
		end

		function tabObject:Grid(config, parentOverride)
			config = config or {}
			local cols = config.columns or 2
			local target = parentOverride or tabPage

			local grid = Instance.new("Frame")
			grid.BackgroundTransparency = 1
			grid.Size = UDim2.new(1, 0, 0, 0)
			grid.Parent = target

			local layout = Instance.new("UIGridLayout")
			layout.FillDirection = Enum.FillDirection.Horizontal
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.CellSize = UDim2.new(1/cols, -((cols-1)*8)/cols, 0, 36)
			layout.CellPadding = UDim2.new(0, 8, 0, 8)
			layout.Parent = grid

			layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				grid.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y)
			end)

			local gridObject = {}
			function gridObject:Button(t, cb) return tabObject:Button(t, cb, grid) end
			function gridObject:Toggle(t, d, cb, fl) return tabObject:Toggle(t, d, cb, fl, grid) end
			function gridObject:Label(t) return tabObject:Label(t, grid) end
			return gridObject
		end

		function tabObject:Label(text, parentOverride)
			local resolvedText = type(text) == "table" and (text.Text or "Label") or tostring(text)
			local frame = makeElementFrame(30, parentOverride)
			frame.BackgroundTransparency = 0.7
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0) 

			local label = Instance.new("TextLabel")
			label.Name = "Content"
			label.Text = resolvedText
			label.Font = Enum.Font.GothamBold
			label.TextSize = 15
			label.TextColor3 = theme.Text
			label.BackgroundTransparency = 1
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextWrapped = true
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.Size = UDim2.new(1, -24, 0, 0)
			label.Position = UDim2.new(0, 12, 0, 8)
			label.Parent = frame

			local spacer = Instance.new("Frame")
			spacer.BackgroundTransparency = 1
			spacer.Size = UDim2.new(1, 0, 0, 8)
			spacer.Position = UDim2.new(0, 0, 1, 0)  
			spacer.Parent = frame

			local layout = Instance.new("UIListLayout")
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Parent = frame
			label.LayoutOrder = 1
			spacer.LayoutOrder = 2
			addPadding(frame, 8, 8, 12, 12)

			local obj = {Type = "Label"}
			function obj:Set(t) label.Text = tostring(t) end
			function obj:RefreshTheme(t)
				label.TextColor3 = t.Text
				frame.BackgroundColor3 = t.Second
				local s = frame:FindFirstChildOfClass("UIStroke")
				if s then s.Color = t.Stroke end
			end
			table.insert(Isotope._ElementRegistry, {name = resolvedText, obj = obj, tab = tabEntry})
			return obj
		end

		function tabObject:Button(text, callback, parentOverride)
			local resolvedText = type(text) == "table" and (text.Name or "Button") or tostring(text)
			local resolvedCb = type(text) == "table" and (text.Callback or function() end) or (callback or function() end)

			local frame = makeElementFrame(33, parentOverride)

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Name = "Content"
			nameLabel.Text = resolvedText
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 15
			nameLabel.TextColor3 = theme.Text
			nameLabel.BackgroundTransparency = 1
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Size = UDim2.new(1, -12, 1, 0)
			nameLabel.Position = UDim2.new(0, 12, 0, 0)
			nameLabel.Parent = frame

			local buttonActionIcon = Instance.new("ImageLabel")
			buttonActionIcon.Image = "rbxassetid://3944703587"
			buttonActionIcon.BackgroundTransparency = 1
			buttonActionIcon.ImageColor3 = theme.TextDark
			buttonActionIcon.AnchorPoint = Vector2.new(1, 0.5)
			buttonActionIcon.Size = UDim2.new(0, 16, 0, 16)
			buttonActionIcon.Position = UDim2.new(1, -12, 0.5, 0)
			buttonActionIcon.Parent = frame

			local clickButton = Instance.new("TextButton")
			clickButton.Text = ""
			clickButton.AutoButtonColor = false
			clickButton.BackgroundTransparency = 1
			clickButton.BorderSizePixel = 0
			clickButton.Size = UDim2.new(1, 0, 1, 0)
			clickButton.Parent = frame

			applyHover(clickButton, frame)
			clickButton.MouseButton1Up:Connect(function() task.spawn(resolvedCb) end)

			local obj = {Type = "Button"}
			function obj:Set(t) nameLabel.Text = tostring(t) end
			function obj:RefreshTheme(t)
				nameLabel.TextColor3 = t.Text
				buttonActionIcon.ImageColor3 = t.TextDark
				frame.BackgroundColor3 = t.Second
				local s = frame:FindFirstChildOfClass("UIStroke")
				if s then s.Color = t.Stroke end
			end
			table.insert(Isotope._ElementRegistry, {name = resolvedText, obj = obj, tab = tabEntry})
			return obj
		end

		function tabObject:Toggle(text, default, callback, flagName, parentOverride)
			local resolvedText = type(text) == "table" and (text.Name or "Toggle") or tostring(text)
			local resolvedDefault = type(text) == "table" and (text.Default or false) or (default or false)
			local resolvedCb = type(text) == "table" and (text.Callback or function() end) or (callback or function() end)
			local resolvedFlag = type(text) == "table" and text.Flag or flagName
			local resolvedColor = type(text) == "table" and (text.Color or theme.Accent or Color3.fromRGB(0, 170, 255)) or (theme.Accent or Color3.fromRGB(0, 170, 255))
			local resolvedSave = type(text) == "table" and (text.Save or false) or false
			local resolvedConfirm = type(text) == "table" and (text.Confirm == true) or false
			local resolvedLocked = type(text) == "table" and (text.Locked == true) or false

			local toggleObj = {Value = resolvedDefault, Save = resolvedSave, Type = "Toggle", Locked = resolvedLocked}

			local outerFrame = makeElementFrame(38, parentOverride)
			outerFrame.ClipsDescendants = true

			local lockOverlay = makeLockedFrame(outerFrame)
			if resolvedLocked then
				lockOverlay.Visible = true
				lockOverlay.BackgroundTransparency = 0.5
			end

			local frame = Instance.new("Frame")
			frame.BackgroundTransparency = 1
			frame.BorderSizePixel = 0
			frame.Size = UDim2.new(1, 0, 0, 38)
			frame.Position = UDim2.new(0, 0, 0, 0)
			frame.Parent = outerFrame

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Name = "Content"
			nameLabel.Text = resolvedText
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 15
			nameLabel.TextColor3 = theme.Text
			nameLabel.BackgroundTransparency = 1
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Size = UDim2.new(1, -12, 1, 0)
			nameLabel.Position = UDim2.new(0, 12, 0, 0)
			nameLabel.Parent = frame

			local checkboxFrame = Instance.new("Frame")
			checkboxFrame.BackgroundColor3 = resolvedColor
			checkboxFrame.BorderSizePixel = 0
			checkboxFrame.Size = UDim2.new(0, 24, 0, 24)
			checkboxFrame.Position = UDim2.new(1, -24, 0.5, 0)
			checkboxFrame.AnchorPoint = Vector2.new(0.5, 0.5)
			checkboxFrame.Parent = frame
			addCorner(checkboxFrame, 0, 4)

			local checkboxStroke = Instance.new("UIStroke")
			checkboxStroke.Color = resolvedColor
			checkboxStroke.Transparency = 0.5
			checkboxStroke.Parent = checkboxFrame

			local checkIcon = Instance.new("ImageLabel")
			checkIcon.Image = "rbxassetid://3944680095"
			checkIcon.BackgroundTransparency = 1
			checkIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
			checkIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			checkIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
			checkIcon.Size = UDim2.new(0, 20, 0, 20)
			checkIcon.Parent = checkboxFrame

			local confirmRow = nil
			local confirmPending = false

			if resolvedConfirm then
				confirmRow = Instance.new("Frame")
				confirmRow.BackgroundTransparency = 1
				confirmRow.BorderSizePixel = 0
				confirmRow.Size = UDim2.new(1, 0, 0, 0)
				confirmRow.ClipsDescendants = true
				confirmRow.ZIndex = 5
				confirmRow.Position = UDim2.new(0, 0, 0, 38)
				confirmRow.Parent = outerFrame

				local confirmDivider = Instance.new("Frame")
				confirmDivider.BackgroundColor3 = theme.Stroke
				confirmDivider.BorderSizePixel = 0
				confirmDivider.Size = UDim2.new(1, -24, 0, 1)
				confirmDivider.Position = UDim2.new(0, 12, 0, 0)
				confirmDivider.ZIndex = 6
				confirmDivider.Parent = confirmRow

				local confirmLabel = Instance.new("TextLabel")
				confirmLabel.Text = "Are you sure?"
				confirmLabel.Font = Enum.Font.GothamSemibold
				confirmLabel.TextSize = 12
				confirmLabel.TextColor3 = theme.TextDark
				confirmLabel.BackgroundTransparency = 1
				confirmLabel.AnchorPoint = Vector2.new(0, 0.5)
				confirmLabel.Size = UDim2.new(0.4, 0, 0, 28)
				confirmLabel.Position = UDim2.new(0, -35, 0.5, 0)
				confirmLabel.ZIndex = 6
				confirmLabel.Parent = confirmRow

				local confirmYes = Instance.new("TextButton")
				confirmYes.Text = "Confirm"
				confirmYes.Font = Enum.Font.GothamSemibold
				confirmYes.TextSize = 11
				confirmYes.TextColor3 = theme.Text
				confirmYes.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
				confirmYes.BorderSizePixel = 0
				confirmYes.AnchorPoint = Vector2.new(1, 0.5)
				confirmYes.Size = UDim2.new(0, 58, 0, 22)
				confirmYes.Position = UDim2.new(1, -68, 0.5, 0)
				confirmYes.ZIndex = 6
				confirmYes.AutoButtonColor = false
				confirmYes.Parent = confirmRow
				addCorner(confirmYes, 0, 4)
				addStroke(confirmYes, theme.Stroke, 1)

				local confirmNo = Instance.new("TextButton")
				confirmNo.Text = "Cancel"
				confirmNo.Font = Enum.Font.GothamSemibold
				confirmNo.TextSize = 11
				confirmNo.TextColor3 = theme.TextDark
				confirmNo.BackgroundColor3 = Color3.fromRGB(40, 40, 46)
				confirmNo.BorderSizePixel = 0
				confirmNo.AnchorPoint = Vector2.new(1, 0.5)
				confirmNo.Size = UDim2.new(0, 52, 0, 22)
				confirmNo.Position = UDim2.new(1, -8, 0.5, 0)
				confirmNo.ZIndex = 6
				confirmNo.AutoButtonColor = false
				confirmNo.Parent = confirmRow
				addCorner(confirmNo, 0, 4)
				addStroke(confirmNo, theme.Stroke, 1)

				confirmYes.MouseEnter:Connect(function()
					tweenObj(confirmYes, 0.12, nil, nil, {BackgroundColor3 = Color3.fromRGB(70, 70, 80)})
				end)
				confirmYes.MouseLeave:Connect(function()
					tweenObj(confirmYes, 0.12, nil, nil, {BackgroundColor3 = Color3.fromRGB(55, 55, 62)})
				end)
				confirmNo.MouseEnter:Connect(function()
					tweenObj(confirmNo, 0.12, nil, nil, {BackgroundColor3 = Color3.fromRGB(55, 55, 62)})
				end)
				confirmNo.MouseLeave:Connect(function()
					tweenObj(confirmNo, 0.12, nil, nil, {BackgroundColor3 = Color3.fromRGB(40, 40, 46)})
				end)

				local function closeConfirm()
					confirmPending = false
					tweenObj(confirmRow, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Size = UDim2.new(1, 0, 0, 0)})
					tweenObj(outerFrame, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Size = UDim2.new(1, 0, 0, 38)})
				end

				local function openConfirm()
					confirmPending = true
					tweenObj(confirmRow, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Size = UDim2.new(1, 0, 0, 38)})
					tweenObj(outerFrame, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Size = UDim2.new(1, 0, 0, 76)})
				end

				confirmYes.MouseButton1Click:Connect(function()
					closeConfirm()
					toggleObj.Value = not toggleObj.Value
					tweenObj(checkboxFrame, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
						{BackgroundColor3 = toggleObj.Value and resolvedColor or theme.Divider})
					tweenObj(checkboxStroke, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
						{Color = toggleObj.Value and resolvedColor or theme.Stroke})
					tweenObj(checkIcon, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
						ImageTransparency = toggleObj.Value and 0 or 1,
						Size = toggleObj.Value and UDim2.new(0, 20, 0, 20) or UDim2.new(0, 8, 0, 8),
					})
					pcall(resolvedCb, toggleObj.Value)
					if doSaveConfig then saveFlags(configFolder, configFile) end
				end)

				confirmNo.MouseButton1Click:Connect(closeConfirm)

				local clickButton2 = Instance.new("TextButton")
				clickButton2.Text = ""
				clickButton2.AutoButtonColor = false
				clickButton2.BackgroundTransparency = 1
				clickButton2.BorderSizePixel = 0
				clickButton2.Size = UDim2.new(1, 0, 0, 38)
				clickButton2.Position = UDim2.new(0, 0, 0, 0)
				clickButton2.ZIndex = 4
				clickButton2.Parent = outerFrame

				applyHover(clickButton2, outerFrame)
				clickButton2.MouseButton1Up:Connect(function()
					if confirmPending then return end
					openConfirm()
				end)
			end

			function toggleObj:Set(value)
				toggleObj.Value = value
				tweenObj(checkboxFrame, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
					{BackgroundColor3 = value and resolvedColor or theme.Divider})
				tweenObj(checkboxStroke, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
					{Color = value and resolvedColor or theme.Stroke})
				tweenObj(checkIcon, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
					ImageTransparency = value and 0 or 1,
					Size = value and UDim2.new(0, 20, 0, 20) or UDim2.new(0, 8, 0, 8),
				})
				pcall(resolvedCb, value)
			end

			toggleObj:Set(resolvedDefault)

			if not resolvedConfirm then
				local clickButton = Instance.new("TextButton")
				clickButton.Text = ""
				clickButton.AutoButtonColor = false
				clickButton.BackgroundTransparency = 1
				clickButton.BorderSizePixel = 0
				clickButton.Size = UDim2.new(1, 0, 1, 0)
				clickButton.Parent = outerFrame

				applyHover(clickButton, outerFrame)
				clickButton.MouseButton1Up:Connect(function()
					if toggleObj.Locked then return end
					toggleObj:Set(not toggleObj.Value)
					if doSaveConfig then saveFlags(configFolder, configFile) end
				end)
			end

			function toggleObj:Lock()
				toggleObj.Locked = true
				lockOverlay.Visible = true
				tweenObj(lockOverlay, 0.3, nil, nil, {BackgroundTransparency = 0.5})
			end

			function toggleObj:Unlock()
				toggleObj.Locked = false
				tweenObj(lockOverlay, 0.3, nil, nil, {BackgroundTransparency = 1})
				task.delay(0.3, function() lockOverlay.Visible = false end)
			end

			if resolvedFlag then Isotope.Flags[resolvedFlag] = toggleObj end
			function toggleObj:RefreshTheme(t)
				nameLabel.TextColor3 = t.Text
				outerFrame.BackgroundColor3 = t.Second
				local s = outerFrame:FindFirstChildOfClass("UIStroke")
				if s then s.Color = t.Stroke end
				if confirmRow then
					local cd = confirmRow:FindFirstChild("ConfirmDivider") or confirmRow:FindFirstChild("Line")
					if cd then cd.BackgroundColor3 = t.Stroke end
					local cl = confirmRow:FindFirstChildOfClass("TextLabel")
					if cl then cl.TextColor3 = t.TextDark end
				end
				if not toggleObj.Value then
					checkboxFrame.BackgroundColor3 = t.Divider
					checkboxStroke.Color = t.Stroke
				end
			end
			table.insert(Isotope._ElementRegistry, {name = resolvedText, obj = toggleObj, tab = tabEntry})
			return toggleObj
		end

		function tabObject:TextBox(placeholder, callback, parentOverride)
			local resolvedPlaceholder = type(placeholder) == "table" and (placeholder.Name or "Input") or tostring(placeholder)
			local resolvedCb = type(placeholder) == "table" and (placeholder.Callback or function() end) or (callback or function() end)
			local resolvedDisappear = type(placeholder) == "table" and (placeholder.TextDisappear or false) or false
			local resolvedDefault = type(placeholder) == "table" and (placeholder.Default or "") or ""

			local frame = makeElementFrame(38, parentOverride)

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Name = "Content"
			nameLabel.Text = resolvedPlaceholder
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 15
			nameLabel.TextColor3 = theme.Text
			nameLabel.BackgroundTransparency = 1
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Size = UDim2.new(1, -12, 1, 0)
			nameLabel.Position = UDim2.new(0, 12, 0, 0)
			nameLabel.Parent = frame

			local inputContainer = Instance.new("Frame")
			inputContainer.BackgroundColor3 = theme.Main
			inputContainer.BorderSizePixel = 0
			inputContainer.AnchorPoint = Vector2.new(1, 0.5)
			inputContainer.Size = UDim2.new(0, 24, 0, 24)
			inputContainer.Position = UDim2.new(1, -12, 0.5, 0)
			inputContainer.Parent = frame
			addCorner(inputContainer, 0, 4)
			addStroke(inputContainer, theme.Stroke, 1)

			local inputBox = Instance.new("TextBox")
			inputBox.BackgroundTransparency = 1
			inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
			inputBox.PlaceholderColor3 = Color3.fromRGB(210, 210, 210)
			inputBox.PlaceholderText = "..."
			inputBox.Font = Enum.Font.GothamSemibold
			inputBox.TextXAlignment = Enum.TextXAlignment.Center
			inputBox.TextSize = 14
			inputBox.ClearTextOnFocus = false
			inputBox.Text = resolvedDisappear and "" or resolvedDefault
			inputBox.Size = UDim2.new(1, 0, 1, 0)
			inputBox.Parent = inputContainer

			local clickButton = Instance.new("TextButton")
			clickButton.Text = ""
			clickButton.AutoButtonColor = false
			clickButton.BackgroundTransparency = 1
			clickButton.BorderSizePixel = 0
			clickButton.Size = UDim2.new(1, 0, 1, 0)
			clickButton.Parent = frame

			inputBox:GetPropertyChangedSignal("Text"):Connect(function()
				tweenObj(inputContainer, 0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
					{Size = UDim2.new(0, inputBox.TextBounds.X + 16, 0, 24)})
			end)
			inputBox.FocusLost:Connect(function()
				local t = inputBox.Text
				if resolvedDisappear then
					inputBox.Text = ""
					tweenObj(inputContainer, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Size = UDim2.new(0, 24, 0, 24)})
				end
				if t ~= "" then pcall(resolvedCb, t) end
			end)
			clickButton.MouseButton1Up:Connect(function() inputBox:CaptureFocus() end)
			applyHover(clickButton, frame)

			local obj = {Type = "TextBox"}
			function obj:RefreshTheme(t)
				nameLabel.TextColor3 = t.Text
				frame.BackgroundColor3 = t.Second
				inputContainer.BackgroundColor3 = t.Main
				inputBox.TextColor3 = t.Text
				local s = frame:FindFirstChildOfClass("UIStroke")
				if s then s.Color = t.Stroke end
				local s2 = inputContainer:FindFirstChildOfClass("UIStroke")
				if s2 then s2.Color = t.Stroke end
			end
			table.insert(Isotope._ElementRegistry, {name = resolvedPlaceholder, obj = obj, tab = tabEntry})
			return obj
		end

		function tabObject:Slider(text, sliderMin, sliderMax, sliderDefault, callback, flagName, parentOverride)
			local resolvedText = type(text) == "table" and (text.Name or "Slider") or tostring(text)
			local resolvedMin = type(text) == "table" and (text.Min or 0) or (sliderMin or 0)
			local resolvedMax = type(text) == "table" and (text.Max or 100) or (sliderMax or 100)
			local resolvedDefault = type(text) == "table" and (text.Default or 50) or (sliderDefault or 50)
			local resolvedCb = type(text) == "table" and (text.Callback or function() end) or (callback or function() end)
			local resolvedFlag = type(text) == "table" and text.Flag or flagName
			local resolvedSave = type(text) == "table" and (text.Save or false) or false
			local resolvedIncrement = type(text) == "table" and (text.Increment or 1) or 1
			local resolvedValueName = type(text) == "table" and (text.ValueName or "") or ""
			local resolvedColor = type(text) == "table" and (text.Color or theme.Accent or Color3.fromRGB(0, 170, 255)) or (theme.Accent or Color3.fromRGB(0, 170, 255))

			local sliderObj = {Value = resolvedDefault, Save = resolvedSave, Type = "Slider"}
			local sliderDragging = false

			local function roundToIncrement(number, increment)
				local rounded = math.floor(number / increment + math.sign(number) * 0.5) * increment
				if rounded < 0 then rounded = rounded + increment end
				return rounded
			end

			local frame = makeElementFrame(65, parentOverride)

			local titleLabel = Instance.new("TextLabel")
			titleLabel.Name = "Content"
			titleLabel.Text = resolvedText
			titleLabel.Font = Enum.Font.GothamBold
			titleLabel.TextSize = 15
			titleLabel.TextColor3 = theme.Text
			titleLabel.BackgroundTransparency = 1
			titleLabel.TextXAlignment = Enum.TextXAlignment.Left
			titleLabel.Size = UDim2.new(1, -12, 0, 14)
			titleLabel.Position = UDim2.new(0, 12, 0, 10)
			titleLabel.Parent = frame

			local sliderTrack = Instance.new("Frame")
			sliderTrack.BackgroundColor3 = resolvedColor
			sliderTrack.BackgroundTransparency = 0.9
			sliderTrack.BorderSizePixel = 0
			sliderTrack.Size = UDim2.new(1, -24, 0, 26)
			sliderTrack.Position = UDim2.new(0, 12, 0, 30)
			sliderTrack.Parent = frame
			addCorner(sliderTrack, 0, 5)
			local sliderTrackStroke = Instance.new("UIStroke")
			sliderTrackStroke.Color = resolvedColor
			sliderTrackStroke.Parent = sliderTrack

			local bgValueLabel = Instance.new("TextLabel")
			bgValueLabel.Font = Enum.Font.GothamBold
			bgValueLabel.TextSize = 13
			bgValueLabel.TextColor3 = theme.Text
			bgValueLabel.TextTransparency = 0.8
			bgValueLabel.BackgroundTransparency = 1
			bgValueLabel.TextXAlignment = Enum.TextXAlignment.Left
			bgValueLabel.Size = UDim2.new(1, -12, 0, 14)
			bgValueLabel.Position = UDim2.new(0, 12, 0, 6)
			bgValueLabel.Parent = sliderTrack

			local fillFrame = Instance.new("Frame")
			fillFrame.BackgroundColor3 = resolvedColor
			fillFrame.BackgroundTransparency = 0.3
			fillFrame.BorderSizePixel = 0
			fillFrame.ClipsDescendants = true
			fillFrame.Size = UDim2.new(0, 0, 1, 0)
			fillFrame.Parent = sliderTrack
			addCorner(fillFrame, 0, 5)

			local fillValueLabel = Instance.new("TextLabel")
			fillValueLabel.Font = Enum.Font.GothamBold
			fillValueLabel.TextSize = 13
			fillValueLabel.TextColor3 = theme.Text
			fillValueLabel.TextTransparency = 0
			fillValueLabel.BackgroundTransparency = 1
			fillValueLabel.TextXAlignment = Enum.TextXAlignment.Left
			fillValueLabel.Size = UDim2.new(1, -12, 0, 14)
			fillValueLabel.Position = UDim2.new(0, 12, 0, 6)
			fillValueLabel.Parent = fillFrame

			function sliderObj:Set(value)
				sliderObj.Value = math.clamp(roundToIncrement(value, resolvedIncrement), resolvedMin, resolvedMax)
				local fillScale = (sliderObj.Value - resolvedMin) / (resolvedMax - resolvedMin)
				tweenObj(fillFrame, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
					{Size = UDim2.fromScale(fillScale, 1)})
				local displayText = tostring(sliderObj.Value) .. " " .. resolvedValueName
				bgValueLabel.Text = displayText
				fillValueLabel.Text = displayText
				pcall(resolvedCb, sliderObj.Value)
			end

			local lastClickTime = 0
			sliderTrack.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					local now = tick()
					if now - lastClickTime < 0.35 then
						sliderDragging = false
						local inputBox = Instance.new("TextBox")
						inputBox.BackgroundColor3 = theme.Main
						inputBox.BorderSizePixel = 0
						inputBox.AnchorPoint = Vector2.new(0.5, 0.5)
						inputBox.Size = UDim2.new(0, 80, 0, 22)
						inputBox.Position = UDim2.new(0.5, 0, 0.5, 0)
						inputBox.Text = tostring(sliderObj.Value)
						inputBox.Font = Enum.Font.GothamBold
						inputBox.TextSize = 13
						inputBox.TextColor3 = theme.Text
						inputBox.TextXAlignment = Enum.TextXAlignment.Center
						inputBox.ClearTextOnFocus = false
						inputBox.ZIndex = 10
						inputBox.Parent = sliderTrack
						addCorner(inputBox, 0, 4)
						addStroke(inputBox, resolvedColor, 1.5)
						task.defer(function()
							inputBox:CaptureFocus()
							inputBox.SelectionStart = 1
							inputBox.CursorPosition = #inputBox.Text + 1
						end)
						inputBox.FocusLost:Connect(function(entered)
							local num = tonumber(inputBox.Text)
							if num then
								sliderObj:Set(num)
								if doSaveConfig then saveFlags(configFolder, configFile) end
							end
							inputBox:Destroy()
						end)
					else
						sliderDragging = true
					end
					lastClickTime = now
				end
			end)
			sliderTrack.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then sliderDragging = false end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if sliderDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
					local relativeX = math.clamp((input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
					sliderObj:Set(resolvedMin + (resolvedMax - resolvedMin) * relativeX)
					if doSaveConfig then saveFlags(configFolder, configFile) end
				end
			end)

			sliderObj:Set(resolvedDefault)
			if resolvedFlag then Isotope.Flags[resolvedFlag] = sliderObj end
			function sliderObj:RefreshTheme(t)
				titleLabel.TextColor3 = t.Text
				frame.BackgroundColor3 = t.Second
				bgValueLabel.TextColor3 = t.Text
				fillValueLabel.TextColor3 = t.Text
				local s = frame:FindFirstChildOfClass("UIStroke")
				if s then s.Color = t.Stroke end
			end
			table.insert(Isotope._ElementRegistry, {name = resolvedText, obj = sliderObj, tab = tabEntry})
			return sliderObj
		end

		function tabObject:Paragraph(config, parentOverride)
			local resolvedTitle, resolvedContent, resolvedParent
			if type(config) == "table" then
				resolvedTitle = tostring(config.Name or "Paragraph")
				resolvedContent = tostring(config.Content or "")
				resolvedParent = parentOverride
			else
				resolvedTitle = tostring(config or "Paragraph")
				resolvedContent = tostring(parentOverride or "")
				resolvedParent = nil
			end

			local frame = makeElementFrame(0, resolvedParent or tabPage)

			local titleLabel = Instance.new("TextLabel")
			titleLabel.Name = "Content"
			titleLabel.Text = resolvedTitle
			titleLabel.Font = Enum.Font.GothamBold
			titleLabel.TextSize = 15
			titleLabel.TextColor3 = theme.Text
			titleLabel.BackgroundTransparency = 1
			titleLabel.TextXAlignment = Enum.TextXAlignment.Left
			titleLabel.Size = UDim2.new(1, -24, 0, 18)
			titleLabel.Position = UDim2.new(0, 12, 0, 8)
			titleLabel.Parent = frame

			local dividerLine = Instance.new("Frame")
			dividerLine.BackgroundColor3 = theme.Stroke
			dividerLine.BorderSizePixel = 0
			dividerLine.Size = UDim2.new(1, -24, 0, 1)
			dividerLine.Position = UDim2.new(0, 12, 0, 30)
			dividerLine.Parent = frame

			local bodyLabel = Instance.new("TextLabel")
			bodyLabel.Name = "Content"
			bodyLabel.Text = resolvedContent
			bodyLabel.Font = Enum.Font.Gotham
			bodyLabel.TextSize = 14
			bodyLabel.TextColor3 = theme.TextDark
			bodyLabel.BackgroundTransparency = 1
			bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
			bodyLabel.TextYAlignment = Enum.TextYAlignment.Top
			bodyLabel.TextWrapped = true
			bodyLabel.AutomaticSize = Enum.AutomaticSize.Y
			bodyLabel.Size = UDim2.new(1, -24, 0, 0)
			bodyLabel.Position = UDim2.new(0, 12, 0, 38)
			bodyLabel.Parent = frame

			local bottomSpacer = Instance.new("Frame")
			bottomSpacer.BackgroundTransparency = 1
			bottomSpacer.BorderSizePixel = 0
			bottomSpacer.Size = UDim2.new(1, 0, 0, 12)
			bottomSpacer.Position = UDim2.new(0, 0, 1, 0)
			bottomSpacer.Parent = frame

			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)


			local obj = {Type = "Paragraph"}
			function obj:Set(newTitle, newContent)
				titleLabel.Text = tostring(newTitle or "")
				bodyLabel.Text = tostring(newContent or "")
			end
			function obj:RefreshTheme(t)
				titleLabel.TextColor3 = t.Text
				bodyLabel.TextColor3 = t.TextDark
				dividerLine.BackgroundColor3 = t.Stroke
				frame.BackgroundColor3 = t.Second
				local s = frame:FindFirstChildOfClass("UIStroke")
				if s then s.Color = t.Stroke end
			end
			table.insert(Isotope._ElementRegistry, {name = resolvedTitle, obj = obj, tab = tabEntry})
			return obj
		end

		function tabObject:Dropdown(config, parentOverride)
			config = type(config) == "table" and config or {}
			local dropdownName = config.Name or "Dropdown"
			local dropdownOptions = config.Options or {}
			local dropdownDefault = config.Default or ""
			local dropdownCallback = config.Callback or function() end
			local dropdownFlag = config.Flag
			local dropdownSave = config.Save or false

			local dropdown = {Value = dropdownDefault, Options = dropdownOptions, Buttons = {}, Toggled = false, Type = "Dropdown", Save = dropdownSave}
			local maxVisibleElements = 5

			if not table.find(dropdown.Options, dropdown.Value) then
				dropdown.Value = "..."
			end

			local dropdownListLayout = Instance.new("UIListLayout")
			dropdownListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			dropdownListLayout.Padding = UDim.new(0, 0)

			local dropdownScrollFrame = Instance.new("ScrollingFrame")
			dropdownScrollFrame.BackgroundTransparency = 1
			dropdownScrollFrame.ScrollBarImageColor3 = theme.Divider
			dropdownScrollFrame.ScrollBarThickness = 4
			dropdownScrollFrame.MidImage = "rbxassetid://7445543667"
			dropdownScrollFrame.BottomImage = "rbxassetid://7445543667"
			dropdownScrollFrame.TopImage = "rbxassetid://7445543667"
			dropdownScrollFrame.BorderSizePixel = 0
			dropdownScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
			dropdownScrollFrame.Position = UDim2.new(0, 0, 0, 38)
			dropdownScrollFrame.Size = UDim2.new(1, 0, 1, -38)
			dropdownScrollFrame.ClipsDescendants = true
			dropdownListLayout.Parent = dropdownScrollFrame

			dropdownListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				dropdownScrollFrame.CanvasSize = UDim2.new(0, 0, 0, dropdownListLayout.AbsoluteContentSize.Y)
			end)

			local clickButton = Instance.new("TextButton")
			clickButton.Text = ""
			clickButton.AutoButtonColor = false
			clickButton.BackgroundTransparency = 1
			clickButton.BorderSizePixel = 0
			clickButton.Size = UDim2.new(1, 0, 1, 0)

			local dropdownArrow = Instance.new("ImageLabel")
			dropdownArrow.Name = "Ico"
			dropdownArrow.Image = "rbxassetid://7072706796"
			dropdownArrow.BackgroundTransparency = 1
			dropdownArrow.ImageColor3 = theme.TextDark
			dropdownArrow.Size = UDim2.new(0, 20, 0, 20)
			dropdownArrow.AnchorPoint = Vector2.new(0, 0.5)
			dropdownArrow.Position = UDim2.new(1, -30, 0.5, 0)

			local selectedLabel = Instance.new("TextLabel")
			selectedLabel.Name = "Selected"
			selectedLabel.Text = dropdown.Value
			selectedLabel.Font = Enum.Font.Gotham
			selectedLabel.TextSize = 13
			selectedLabel.TextColor3 = theme.TextDark
			selectedLabel.BackgroundTransparency = 1
			selectedLabel.Size = UDim2.new(1, -40, 1, 0)
			selectedLabel.TextXAlignment = Enum.TextXAlignment.Right

			local dropdownDivider = Instance.new("Frame")
			dropdownDivider.Name = "Line"
			dropdownDivider.BackgroundColor3 = theme.Stroke
			dropdownDivider.BorderSizePixel = 0
			dropdownDivider.Size = UDim2.new(1, 0, 0, 1)
			dropdownDivider.Position = UDim2.new(0, 0, 1, -1)
			dropdownDivider.Visible = false

			local headerFrame = Instance.new("Frame")
			headerFrame.Name = "F"
			headerFrame.BackgroundTransparency = 1
			headerFrame.Size = UDim2.new(1, 0, 0, 38)
			headerFrame.ClipsDescendants = true

			local headerNameLabel = Instance.new("TextLabel")
			headerNameLabel.Text = dropdownName
			headerNameLabel.Font = Enum.Font.GothamBold
			headerNameLabel.TextSize = 15
			headerNameLabel.TextColor3 = theme.Text
			headerNameLabel.BackgroundTransparency = 1
			headerNameLabel.Size = UDim2.new(1, -12, 1, 0)
			headerNameLabel.Position = UDim2.new(0, 12, 0, 0)
			headerNameLabel.TextXAlignment = Enum.TextXAlignment.Left
			headerNameLabel.Parent = headerFrame
			dropdownArrow.Parent = headerFrame
			selectedLabel.Parent = headerFrame
			dropdownDivider.Parent = headerFrame
			clickButton.Parent = headerFrame

			local dropdownFrame = Instance.new("Frame")
			dropdownFrame.BackgroundColor3 = theme.Second
			dropdownFrame.BorderSizePixel = 0
			dropdownFrame.Size = UDim2.new(1, 0, 0, 38)
			dropdownFrame.ClipsDescendants = true
			dropdownFrame.Parent = parentOverride or tabPage
			local dropdownCorner = Instance.new("UICorner")
			dropdownCorner.CornerRadius = UDim.new(0, 5)
			dropdownCorner.Parent = dropdownFrame
			addStroke(dropdownFrame, theme.Stroke, 1)
			headerFrame.Parent = dropdownFrame
			dropdownScrollFrame.Parent = dropdownFrame

			clickButton.MouseEnter:Connect(function()
				tweenObj(dropdownFrame, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {BackgroundColor3 = Color3.fromRGB(
					math.clamp(theme.Second.R * 255 + 3, 0, 255),
					math.clamp(theme.Second.G * 255 + 3, 0, 255),
					math.clamp(theme.Second.B * 255 + 3, 0, 255))})
			end)
			clickButton.MouseLeave:Connect(function()
				tweenObj(dropdownFrame, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {BackgroundColor3 = theme.Second})
			end)
			clickButton.MouseButton1Up:Connect(function()
				tweenObj(dropdownFrame, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {BackgroundColor3 = Color3.fromRGB(
					math.clamp(theme.Second.R * 255 + 3, 0, 255),
					math.clamp(theme.Second.G * 255 + 3, 0, 255),
					math.clamp(theme.Second.B * 255 + 3, 0, 255))})
			end)
			clickButton.MouseButton1Down:Connect(function()
				tweenObj(dropdownFrame, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {BackgroundColor3 = Color3.fromRGB(
					math.clamp(theme.Second.R * 255 + 6, 0, 255),
					math.clamp(theme.Second.G * 255 + 6, 0, 255),
					math.clamp(theme.Second.B * 255 + 6, 0, 255))})
			end)

			local function addDropdownOptions(options)
				for _, option in pairs(options) do
					local optionButton = Instance.new("TextButton")
					optionButton.Text = ""
					optionButton.AutoButtonColor = false
					optionButton.BackgroundColor3 = theme.Main
					optionButton.BackgroundTransparency = 0.5
					optionButton.BorderSizePixel = 0
					optionButton.Size = UDim2.new(1, 0, 0, 32)
					optionButton.ClipsDescendants = false
					optionButton.Parent = dropdownScrollFrame

					local optionLabel = Instance.new("TextLabel")
					optionLabel.Name = "Title"
					optionLabel.Text = tostring(option)
					optionLabel.Font = Enum.Font.GothamSemibold
					optionLabel.TextSize = 14
					optionLabel.TextColor3 = theme.Text
					optionLabel.TextTransparency = 0.3
					optionLabel.BackgroundTransparency = 1
					optionLabel.Size = UDim2.new(1, -20, 1, 0)
					optionLabel.Position = UDim2.new(0, 12, 0, 0)
					optionLabel.TextXAlignment = Enum.TextXAlignment.Left
					optionLabel.Parent = optionButton

					optionButton.MouseEnter:Connect(function()
						if dropdown.Value ~= option then
							tweenObj(optionButton, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.3})
							tweenObj(optionLabel, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 0.1})
						end
					end)
					optionButton.MouseLeave:Connect(function()
						if dropdown.Value ~= option then
							tweenObj(optionButton, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.5})
							tweenObj(optionLabel, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 0.3})
						end
					end)
					optionButton.MouseButton1Click:Connect(function()
						dropdown:Set(option)
					end)
					dropdown.Buttons[option] = optionButton
				end
			end

			function dropdown:Refresh(options, deleteExisting)
				if deleteExisting then
					for _, button in pairs(dropdown.Buttons) do button:Destroy() end
					table.clear(dropdown.Options)
					table.clear(dropdown.Buttons)
				end
				dropdown.Options = options
				addDropdownOptions(dropdown.Options)
			end

			function dropdown:Set(value)
				if not table.find(dropdown.Options, value) then
					dropdown.Value = "..."
					headerFrame.Selected.Text = dropdown.Value
					for _, button in pairs(dropdown.Buttons) do
						tweenObj(button, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.5})
						tweenObj(button.Title, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 0.3})
					end
					return
				end
				dropdown.Value = value
				headerFrame.Selected.Text = dropdown.Value
				for _, button in pairs(dropdown.Buttons) do
					tweenObj(button, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.5})
					tweenObj(button.Title, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 0.3})
				end
				tweenObj(dropdown.Buttons[value], 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0})
				tweenObj(dropdown.Buttons[value].Title, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 0})
				return dropdownCallback(dropdown.Value)
			end

			clickButton.MouseButton1Click:Connect(function()
				dropdown.Toggled = not dropdown.Toggled
				headerFrame.Line.Visible = dropdown.Toggled
				tweenObj(headerFrame.Ico, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Rotation = dropdown.Toggled and 180 or 0})
				if #dropdown.Options > maxVisibleElements then
					tweenObj(dropdownFrame, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = dropdown.Toggled and UDim2.new(1, 0, 0, 38 + (maxVisibleElements * 32)) or UDim2.new(1, 0, 0, 38)})
				else
					tweenObj(dropdownFrame, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = dropdown.Toggled and UDim2.new(1, 0, 0, dropdownListLayout.AbsoluteContentSize.Y + 38) or UDim2.new(1, 0, 0, 38)})
				end
			end)

			dropdown:Refresh(dropdown.Options, false)
			dropdown:Set(dropdown.Value)
			if dropdownFlag then Isotope.Flags[dropdownFlag] = dropdown end
			function dropdown:RefreshTheme(t)
				headerNameLabel.TextColor3 = t.Text
				selectedLabel.TextColor3 = t.TextDark
				dropdownArrow.ImageColor3 = t.TextDark
				dropdownDivider.BackgroundColor3 = t.Stroke
				dropdownFrame.BackgroundColor3 = t.Second
				dropdownScrollFrame.ScrollBarImageColor3 = t.Divider
				local s = dropdownFrame:FindFirstChildOfClass("UIStroke")
				if s then s.Color = t.Stroke end
				for _, btn in pairs(dropdown.Buttons) do
					btn.BackgroundColor3 = t.Main
					if btn:FindFirstChild("Title") then btn.Title.TextColor3 = t.Text end
				end
			end
			table.insert(Isotope._ElementRegistry, {name = dropdownName, obj = dropdown, tab = tabEntry})
			return dropdown
		end

		function tabObject:Bind(config, parentOverride)
			config = type(config) == "table" and config or {}
			local bindName = config.Name or "Bind"
			local bindDefault = config.Default or Enum.KeyCode.Unknown
			local bindHold = config.Hold or false
			local bindCallback = config.Callback or function() end
			local bindFlag = config.Flag
			local bindSave = config.Save or false
			local bindModifiers = normalModifiers(config.Modifier)

			local blacklistedKeys = {Enum.KeyCode.Unknown, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Up, Enum.KeyCode.Left, Enum.KeyCode.Down, Enum.KeyCode.Right, Enum.KeyCode.Slash, Enum.KeyCode.Tab, Enum.KeyCode.Backspace, Enum.KeyCode.Escape}
			local whitelistedMouse = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3}
			local function isKeyInTable(keyTable, key)
				for _, value in next, keyTable do if value == key then return true end end
			end

			local bind = {Value = nil, Binding = false, Type = "Bind", Save = bindSave, _modifiers = bindModifiers}
			local isHolding = false

			local clickButton = Instance.new("TextButton")
			clickButton.Text = ""
			clickButton.AutoButtonColor = false
			clickButton.BackgroundTransparency = 1
			clickButton.BorderSizePixel = 0
			clickButton.Size = UDim2.new(1, 0, 1, 0)

			local bindBox = Instance.new("Frame")
			bindBox.BackgroundColor3 = theme.Main
			bindBox.BorderSizePixel = 0
			bindBox.AutomaticSize = Enum.AutomaticSize.X
			bindBox.Size = UDim2.new(0, 0, 0, 24)
			bindBox.AnchorPoint = Vector2.new(1, 0.5)
			bindBox.Position = UDim2.new(1, -12, 0.5, 0)
			local bindBoxCorner = Instance.new("UICorner")
			bindBoxCorner.CornerRadius = UDim.new(0, 4)
			bindBoxCorner.Parent = bindBox
			addStroke(bindBox, theme.Stroke, 1)

			local bindBoxPadding = Instance.new("UIPadding")
			bindBoxPadding.PaddingLeft = UDim.new(0, 8)
			bindBoxPadding.PaddingRight = UDim.new(0, 8)
			bindBoxPadding.Parent = bindBox

			local bindValueLabel = Instance.new("TextLabel")
			bindValueLabel.Name = "Value"
			bindValueLabel.Font = Enum.Font.GothamBold
			bindValueLabel.TextSize = 12
			bindValueLabel.TextColor3 = theme.Text
			bindValueLabel.BackgroundTransparency = 1
			bindValueLabel.TextXAlignment = Enum.TextXAlignment.Center
			bindValueLabel.AutomaticSize = Enum.AutomaticSize.X
			bindValueLabel.Size = UDim2.new(0, 0, 1, 0)
			bindValueLabel.Parent = bindBox

			local bindFrame = makeElementFrame(38, parentOverride)

			local bindNameLabel = Instance.new("TextLabel")
			bindNameLabel.Name = "Content"
			bindNameLabel.Text = bindName
			bindNameLabel.Font = Enum.Font.GothamBold
			bindNameLabel.TextSize = 15
			bindNameLabel.TextColor3 = theme.Text
			bindNameLabel.BackgroundTransparency = 1
			bindNameLabel.Size = UDim2.new(1, -12, 1, 0)
			bindNameLabel.Position = UDim2.new(0, 12, 0, 0)
			bindNameLabel.TextXAlignment = Enum.TextXAlignment.Left
			bindNameLabel.Parent = bindFrame
			bindBox.Parent = bindFrame
			clickButton.Parent = bindFrame

			clickButton.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					if bind.Binding then return end
					bind.Binding = true
					bindBox.Value.Text = "..."
				end
			end)

			UserInputService.InputBegan:Connect(function(input)
				if UserInputService:GetFocusedTextBox() then return end
				if (input.KeyCode.Name == bind.Value or input.UserInputType.Name == bind.Value) and not bind.Binding then
					if not modifiersHeld(bind._modifiers) then return end
					if bindHold then
						isHolding = true
						bindCallback(isHolding)
					else
						bindCallback()
					end
				elseif bind.Binding then
					if ModifierNames[input.KeyCode] then return end
					local pressedKey
					pcall(function()
						if not isKeyInTable(blacklistedKeys, input.KeyCode) then
							pressedKey = input.KeyCode
						end
					end)
					pcall(function()
						if isKeyInTable(whitelistedMouse, input.UserInputType) and not pressedKey then
							pressedKey = input.UserInputType
						end
					end)
					pressedKey = pressedKey or bind.Value
					local newModifiers = {}
					for modKey, _ in pairs(ModifierNames) do
						if UserInputService:IsKeyDown(modKey) then
							table.insert(newModifiers, modKey)
						end
					end
					bind._modifiers = newModifiers
					bindModifiers = newModifiers
					bind:Set(pressedKey)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.KeyCode.Name == bind.Value or input.UserInputType.Name == bind.Value then
					if bindHold and isHolding then
						isHolding = false
						bindCallback(isHolding)
					end
				end
			end)

			clickButton.MouseEnter:Connect(function()
				tweenObj(bindFrame, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {BackgroundColor3 = Color3.fromRGB(
					math.clamp(theme.Second.R * 255 + 3, 0, 255),
					math.clamp(theme.Second.G * 255 + 3, 0, 255),
					math.clamp(theme.Second.B * 255 + 3, 0, 255))})
			end)
			clickButton.MouseLeave:Connect(function()
				tweenObj(bindFrame, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {BackgroundColor3 = theme.Second})
			end)
			clickButton.MouseButton1Up:Connect(function()
				tweenObj(bindFrame, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {BackgroundColor3 = Color3.fromRGB(
					math.clamp(theme.Second.R * 255 + 3, 0, 255),
					math.clamp(theme.Second.G * 255 + 3, 0, 255),
					math.clamp(theme.Second.B * 255 + 3, 0, 255))})
			end)
			clickButton.MouseButton1Down:Connect(function()
				tweenObj(bindFrame, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {BackgroundColor3 = Color3.fromRGB(
					math.clamp(theme.Second.R * 255 + 6, 0, 255),
					math.clamp(theme.Second.G * 255 + 6, 0, 255),
					math.clamp(theme.Second.B * 255 + 6, 0, 255))})
			end)

			function bind:Set(key)
				bind.Binding = false
				bind.Value = key or bind.Value
				bind.Value = bind.Value.Name or bind.Value
				local displayLabel = bBindLabel(bind._modifiers, bind.Value)
				bindBox.Value.Text = displayLabel
				if bind._row then
					local rowKeyLabel = bind._row:FindFirstChild("KeyLabel")
					if rowKeyLabel then rowKeyLabel.Text = displayLabel end
				end
			end

			bind:Set(bindDefault)
			if bindFlag then Isotope.Flags[bindFlag] = bind end
			function bind:RefreshTheme(t)
				bindNameLabel.TextColor3 = t.Text
				bindFrame.BackgroundColor3 = t.Second
				bindBox.BackgroundColor3 = t.Main
				bindBox.Value.TextColor3 = t.Text
				local s = bindFrame:FindFirstChildOfClass("UIStroke")
				if s then s.Color = t.Stroke end
				local s2 = bindBox:FindFirstChildOfClass("UIStroke")
				if s2 then s2.Color = t.Stroke end
			end
			table.insert(Isotope._ElementRegistry, {name = bindName, obj = bind, tab = tabEntry})
			table.insert(Isotope.Binds, {Name = bindName, Bind = bind, tab = tabEntry})
			return bind
		end

		function tabObject:Colorpicker(config, parentOverride)
			config = type(config) == "table" and config or {}
			local colorName = config.Name or "Colorpicker"
			local colorDefault = config.Default or Color3.fromRGB(255, 255, 255)
			local colorCallback = config.Callback or function() end
			local colorFlag = config.Flag
			local colorSave = config.Save or false

			local hue, saturation, value = Color3.toHSV(colorDefault)
			local colorpicker = {Value = colorDefault, Toggled = false, Type = "Colorpicker", Save = colorSave}

			local colorSelection = Instance.new("ImageLabel")
			colorSelection.Size = UDim2.new(0, 18, 0, 18)
			colorSelection.Position = UDim2.new(saturation, 0, 1 - value, 0)
			colorSelection.ScaleType = Enum.ScaleType.Fit
			colorSelection.AnchorPoint = Vector2.new(0.5, 0.5)
			colorSelection.BackgroundTransparency = 1
			colorSelection.Image = "http://www.roblox.com/asset/?id=4805639000 "
			colorSelection.ZIndex = 3

			local hueSelection = Instance.new("ImageLabel")
			hueSelection.Size = UDim2.new(0, 18, 0, 18)
			hueSelection.Position = UDim2.new(0.5, 0, 1 - hue, 0)
			hueSelection.ScaleType = Enum.ScaleType.Fit
			hueSelection.AnchorPoint = Vector2.new(0.5, 0.5)
			hueSelection.BackgroundTransparency = 1
			hueSelection.Image = "http://www.roblox.com/asset/?id=4805639000 "
			hueSelection.ZIndex = 3

			local colorField = Instance.new("ImageLabel")
			colorField.Size = UDim2.new(1, -25, 1, 0)
			colorField.Visible = false
			colorField.Image = "rbxassetid://4155801252"
			colorField.BackgroundTransparency = 0
			colorField.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
			local colorFieldCorner = Instance.new("UICorner")
			colorFieldCorner.CornerRadius = UDim.new(0, 5)
			colorFieldCorner.Parent = colorField
			colorSelection.Parent = colorField

			local hueStrip = Instance.new("Frame")
			hueStrip.Size = UDim2.new(0, 20, 1, 0)
			hueStrip.Position = UDim2.new(1, -20, 0, 0)
			hueStrip.Visible = false
			hueStrip.BackgroundColor3 = Color3.new(1, 1, 1)
			hueStrip.BackgroundTransparency = 0
			hueStrip.BorderSizePixel = 0
			local hueGradient = Instance.new("UIGradient")
			hueGradient.Rotation = 270
			hueGradient.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 4)),
				ColorSequenceKeypoint.new(0.20, Color3.fromRGB(234, 255, 0)),
				ColorSequenceKeypoint.new(0.40, Color3.fromRGB(21, 255, 0)),
				ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0, 17, 255)),
				ColorSequenceKeypoint.new(0.90, Color3.fromRGB(255, 0, 251)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 4)),
			}
			hueGradient.Parent = hueStrip
			local hueStripCorner = Instance.new("UICorner")
			hueStripCorner.CornerRadius = UDim.new(0, 5)
			hueStripCorner.Parent = hueStrip
			hueSelection.Parent = hueStrip

			local colorpickerContainer = Instance.new("Frame")
			colorpickerContainer.Position = UDim2.new(0, 0, 0, 32)
			colorpickerContainer.Size = UDim2.new(1, 0, 1, -32)
			colorpickerContainer.BackgroundTransparency = 1
			colorpickerContainer.ClipsDescendants = true
			local cpPadding = Instance.new("UIPadding")
			cpPadding.PaddingLeft = UDim.new(0, 35)
			cpPadding.PaddingRight = UDim.new(0, 35)
			cpPadding.PaddingBottom = UDim.new(0, 10)
			cpPadding.PaddingTop = UDim.new(0, 17)
			cpPadding.Parent = colorpickerContainer
			hueStrip.Parent = colorpickerContainer
			colorField.Parent = colorpickerContainer

			local clickButton = Instance.new("TextButton")
			clickButton.Text = ""
			clickButton.AutoButtonColor = false
			clickButton.BackgroundTransparency = 1
			clickButton.BorderSizePixel = 0
			clickButton.Size = UDim2.new(1, 0, 1, 0)

			local colorPreviewBox = Instance.new("Frame")
			colorPreviewBox.BackgroundColor3 = colorDefault
			colorPreviewBox.BorderSizePixel = 0
			colorPreviewBox.Size = UDim2.new(0, 24, 0, 24)
			colorPreviewBox.Position = UDim2.new(1, -12, 0.5, 0)
			colorPreviewBox.AnchorPoint = Vector2.new(1, 0.5)
			local colorPreviewCorner = Instance.new("UICorner")
			colorPreviewCorner.CornerRadius = UDim.new(0, 4)
			colorPreviewCorner.Parent = colorPreviewBox
			addStroke(colorPreviewBox, theme.Stroke, 1)

			local headerDivider = Instance.new("Frame")
			headerDivider.Name = "Line"
			headerDivider.BackgroundColor3 = theme.Stroke
			headerDivider.BorderSizePixel = 0
			headerDivider.Size = UDim2.new(1, 0, 0, 1)
			headerDivider.Position = UDim2.new(0, 0, 1, -1)
			headerDivider.Visible = false

			local headerFrame = Instance.new("Frame")
			headerFrame.Name = "F"
			headerFrame.BackgroundTransparency = 1
			headerFrame.Size = UDim2.new(1, 0, 0, 38)
			headerFrame.ClipsDescendants = true

			local headerNameLabel = Instance.new("TextLabel")
			headerNameLabel.Name = "Content"
			headerNameLabel.Text = colorName
			headerNameLabel.Font = Enum.Font.GothamBold
			headerNameLabel.TextSize = 15
			headerNameLabel.TextColor3 = theme.Text
			headerNameLabel.BackgroundTransparency = 1
			headerNameLabel.Size = UDim2.new(1, -12, 1, 0)
			headerNameLabel.Position = UDim2.new(0, 12, 0, 0)
			headerNameLabel.TextXAlignment = Enum.TextXAlignment.Left
			headerNameLabel.Parent = headerFrame
			colorPreviewBox.Parent = headerFrame
			clickButton.Parent = headerFrame
			headerDivider.Parent = headerFrame

			local colorpickerFrame = makeElementFrame(38, parentOverride)
			headerFrame.Parent = colorpickerFrame
			colorpickerContainer.Parent = colorpickerFrame

			local function updateColor()
				local newColor = Color3.fromHSV(hue, saturation, value)
				colorPreviewBox.BackgroundColor3 = newColor
				colorField.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
				colorpicker.Value = newColor
				pcall(colorCallback, newColor)
			end

			clickButton.MouseButton1Click:Connect(function()
				colorpicker.Toggled = not colorpicker.Toggled
				tweenObj(colorpickerFrame, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
					{Size = colorpicker.Toggled and UDim2.new(1, 0, 0, 148) or UDim2.new(1, 0, 0, 38)})
				colorField.Visible = colorpicker.Toggled
				hueStrip.Visible = colorpicker.Toggled
				headerFrame.Line.Visible = colorpicker.Toggled
				if colorpicker.Toggled then
					task.defer(function()
						colorSelection.Position = UDim2.new(saturation, 0, 1 - value, 0)
						hueSelection.Position = UDim2.new(0.5, 0, 1 - hue, 0)
						colorField.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
					end)
				end
			end)

			local colorInput, hueInput
			colorField.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					if colorInput then colorInput:Disconnect() end
					local cx = math.clamp((input.Position.X - colorField.AbsolutePosition.X) / colorField.AbsoluteSize.X, 0, 1)
					local cy = math.clamp((input.Position.Y - colorField.AbsolutePosition.Y) / colorField.AbsoluteSize.Y, 0, 1)
					colorSelection.Position = UDim2.new(cx, 0, cy, 0)
					saturation = cx
					value = 1 - cy
					updateColor()
					colorInput = UserInputService.InputChanged:Connect(function(input2)
						if input2.UserInputType ~= Enum.UserInputType.MouseMovement then return end
						local cx2 = math.clamp((input2.Position.X - colorField.AbsolutePosition.X) / colorField.AbsoluteSize.X, 0, 1)
						local cy2 = math.clamp((input2.Position.Y - colorField.AbsolutePosition.Y) / colorField.AbsoluteSize.Y, 0, 1)
						colorSelection.Position = UDim2.new(cx2, 0, cy2, 0)
						saturation = cx2
						value = 1 - cy2
						updateColor()
					end)
				end
			end)
			colorField.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					if colorInput then colorInput:Disconnect() end
				end
			end)

			hueStrip.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					if hueInput then hueInput:Disconnect() end
					local hy = math.clamp((input.Position.Y - hueStrip.AbsolutePosition.Y) / hueStrip.AbsoluteSize.Y, 0, 1)
					hueSelection.Position = UDim2.new(0.5, 0, hy, 0)
					hue = 1 - hy
					updateColor()
					hueInput = UserInputService.InputChanged:Connect(function(input2)
						if input2.UserInputType ~= Enum.UserInputType.MouseMovement then return end
						local hy2 = math.clamp((input2.Position.Y - hueStrip.AbsolutePosition.Y) / hueStrip.AbsoluteSize.Y, 0, 1)
						hueSelection.Position = UDim2.new(0.5, 0, hy2, 0)
						hue = 1 - hy2
						updateColor()
					end)
				end
			end)
			hueStrip.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					if hueInput then hueInput:Disconnect() end
				end
			end)

			function colorpicker:Set(newColor)
				colorpicker.Value = newColor
				hue, saturation, value = Color3.toHSV(newColor)
				colorPreviewBox.BackgroundColor3 = newColor
				colorField.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
				if colorField.Visible then
					colorSelection.Position = UDim2.new(saturation, 0, 1 - value, 0)
					hueSelection.Position = UDim2.new(0.5, 0, 1 - hue, 0)
				end
				pcall(colorCallback, newColor)
			end

			colorpicker:Set(colorpicker.Value)
			if colorFlag then Isotope.Flags[colorFlag] = colorpicker end
			function colorpicker:RefreshTheme(t)
				headerNameLabel.TextColor3 = t.Text
				colorpickerFrame.BackgroundColor3 = t.Second
				headerDivider.BackgroundColor3 = t.Stroke
				local s = colorpickerFrame:FindFirstChildOfClass("UIStroke")
				if s then s.Color = t.Stroke end
				local s2 = colorPreviewBox:FindFirstChildOfClass("UIStroke")
				if s2 then s2.Color = t.Stroke end
			end
			table.insert(Isotope._ElementRegistry, {name = colorName, obj = colorpicker, tab = tabEntry})
			return colorpicker
		end

		function tabObject:MultiDropdown(config, parentOverride)
			config = type(config) == "table" and config or {}
			local dropdownName = config.Name or "Multi Dropdown"
			local dropdownOptions = config.Options or {}
			local dropdownDefault = config.Default or {}
			local dropdownCallback = config.Callback or function() end
			local dropdownFlag = config.Flag
			local dropdownSave = config.Save or false

			local dropdown = {Value = dropdownDefault, Options = dropdownOptions, Buttons = {}, Toggled = false, Type = "MultiDropdown", Save = dropdownSave}
			local maxVisibleElements = 5

			local dropdownFrame = makeElementFrame(38, parentOverride)
			dropdownFrame.ClipsDescendants = true
			addStroke(dropdownFrame, theme.Stroke, 1)

			local headerFrame = Instance.new("Frame")
			headerFrame.BackgroundTransparency = 1
			headerFrame.Size = UDim2.new(1, 0, 0, 38)
			headerFrame.Parent = dropdownFrame

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Text = dropdownName
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 15
			nameLabel.TextColor3 = theme.Text
			nameLabel.BackgroundTransparency = 1
			nameLabel.Size = UDim2.new(0.4, -12, 1, 0)
			nameLabel.Position = UDim2.new(0, 12, 0, 0)
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
			nameLabel.Parent = headerFrame

			local selectedLabel = Instance.new("TextLabel")
			selectedLabel.Text = "None"
			selectedLabel.Font = Enum.Font.Gotham
			selectedLabel.TextSize = 13
			selectedLabel.TextColor3 = theme.TextDark
			selectedLabel.BackgroundTransparency = 1
			selectedLabel.Size = UDim2.new(0.6, -40, 1, 0)
			selectedLabel.Position = UDim2.new(0.4, 0, 0, 0)
			selectedLabel.TextXAlignment = Enum.TextXAlignment.Right
			selectedLabel.TextTruncate = Enum.TextTruncate.AtEnd
			selectedLabel.Parent = headerFrame

			local arrow = Instance.new("ImageLabel")
			arrow.Image = "rbxassetid://7072706796"
			arrow.BackgroundTransparency = 1
			arrow.ImageColor3 = theme.TextDark
			arrow.Size = UDim2.new(0, 20, 0, 20)
			arrow.AnchorPoint = Vector2.new(0, 0.5)
			arrow.Position = UDim2.new(1, -30, 0.5, 0)
			arrow.Parent = headerFrame

			local scrollFrame = Instance.new("ScrollingFrame")
			scrollFrame.BackgroundTransparency = 1
			scrollFrame.ScrollBarImageColor3 = theme.Divider
			scrollFrame.ScrollBarThickness = 4
			scrollFrame.BorderSizePixel = 0
			scrollFrame.Position = UDim2.new(0, 0, 0, 38)
			scrollFrame.Size = UDim2.new(1, 0, 1, -38)
			scrollFrame.Parent = dropdownFrame

			local scrollLayout = addListLayout(scrollFrame, 0)
			scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y)
			end)

			local clickBtn = Instance.new("TextButton")
			clickBtn.Text = ""
			clickBtn.BackgroundTransparency = 1
			clickBtn.Size = UDim2.new(1, 0, 0, 38)
			clickBtn.Parent = headerFrame

			applyHover(clickBtn, dropdownFrame)

			function dropdown:UpdateLabel()
				local count = #dropdown.Value
				if count == 0 then
					selectedLabel.Text = "None"
				elseif count > 2 then
					selectedLabel.Text = tostring(count) .. " Selected"
				else
					selectedLabel.Text = table.concat(dropdown.Value, ", ")
				end
			end

			function dropdown:Set(value)
				dropdown.Value = value
				for opt, btn in pairs(dropdown.Buttons) do
					local isSelected = table.find(dropdown.Value, opt)
					tweenObj(btn, 0.15, nil, nil, {BackgroundTransparency = isSelected and 0.2 or 0.5})
					tweenObj(btn.Title, 0.15, nil, nil, {TextTransparency = isSelected and 0 or 0.3})
				end
				dropdown:UpdateLabel()
				pcall(dropdownCallback, dropdown.Value)
			end

			for _, option in ipairs(dropdownOptions) do
				local optBtn = Instance.new("TextButton")
				optBtn.Text = ""
				optBtn.BackgroundColor3 = theme.Main
				optBtn.BackgroundTransparency = 0.5
				optBtn.BorderSizePixel = 0
				optBtn.Size = UDim2.new(1, 0, 0, 32)
				optBtn.Parent = scrollFrame

				local optTitle = Instance.new("TextLabel")
				optTitle.Name = "Title"
				optTitle.Text = tostring(option)
				optTitle.Font = Enum.Font.GothamSemibold
				optTitle.TextSize = 14
				optTitle.TextColor3 = theme.Text
				optTitle.TextTransparency = 0.3
				optTitle.BackgroundTransparency = 1
				optTitle.Size = UDim2.new(1, -20, 1, 0)
				optTitle.Position = UDim2.new(0, 12, 0, 0)
				optTitle.TextXAlignment = Enum.TextXAlignment.Left
				optTitle.Parent = optBtn

				optBtn.MouseButton1Click:Connect(function()
					local idx = table.find(dropdown.Value, option)
					if idx then
						table.remove(dropdown.Value, idx)
					else
						table.insert(dropdown.Value, option)
					end
					dropdown:Set(dropdown.Value)
				end)
				dropdown.Buttons[option] = optBtn
			end

			clickBtn.MouseButton1Click:Connect(function()
				dropdown.Toggled = not dropdown.Toggled
				tweenObj(arrow, 0.15, nil, nil, {Rotation = dropdown.Toggled and 180 or 0})
				local targetHeight = dropdown.Toggled and math.min(38 + #dropdownOptions * 32, 38 + maxVisibleElements * 32) or 38
				tweenObj(dropdownFrame, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Size = UDim2.new(1, 0, 0, targetHeight)})
			end)

			dropdown:Set(dropdownDefault)
			if dropdownFlag then Isotope.Flags[dropdownFlag] = dropdown end
			function dropdown:RefreshTheme(t)
				nameLabel.TextColor3 = t.Text
				selectedLabel.TextColor3 = t.TextDark
				arrow.ImageColor3 = t.TextDark
				dropdownFrame.BackgroundColor3 = t.Second
				scrollFrame.ScrollBarImageColor3 = t.Divider
				local s = dropdownFrame:FindFirstChildOfClass("UIStroke")
				if s then s.Color = t.Stroke end
				for _, btn in pairs(dropdown.Buttons) do
					btn.BackgroundColor3 = t.Main
					if btn:FindFirstChild("Title") then btn.Title.TextColor3 = t.Text end
				end
			end
			table.insert(Isotope._ElementRegistry, {name = dropdownName, obj = dropdown, tab = tabEntry})
			return dropdown
		end

		function tabObject:ProgressBar(text, default, parentOverride)
			local resolvedText = tostring(text or "Progress")
			local resolvedDefault = math.clamp(default or 0, 0, 1)

			local frame = makeElementFrame(50, parentOverride)

			local titleLabel = Instance.new("TextLabel")
			titleLabel.Text = resolvedText
			titleLabel.Font = Enum.Font.GothamBold
			titleLabel.TextSize = 14
			titleLabel.TextColor3 = theme.Text
			titleLabel.BackgroundTransparency = 1
			titleLabel.Size = UDim2.new(1, -24, 0, 14)
			titleLabel.Position = UDim2.new(0, 12, 0, 8)
			titleLabel.Parent = frame

			local barTrack = Instance.new("Frame")
			barTrack.BackgroundColor3 = theme.Main
			barTrack.BorderSizePixel = 0
			barTrack.Size = UDim2.new(1, -24, 0, 12)
			barTrack.Position = UDim2.new(0, 12, 0, 28)
			barTrack.Parent = frame
			addCorner(barTrack, 0, 6)
			addStroke(barTrack, theme.Stroke, 1)

			local barFill = Instance.new("Frame")
			barFill.BackgroundColor3 = theme.Accent
			barFill.BorderSizePixel = 0
			barFill.Size = UDim2.new(resolvedDefault, 0, 1, 0)
			barFill.Parent = barTrack
			addCorner(barFill, 0, 6)

			local progressObj = {Value = resolvedDefault}

			function progressObj:Set(val, label)
				progressObj.Value = math.clamp(math.round((val or 0) * 100) / 100, 0, 1)
				tweenObj(barFill, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Size = UDim2.fromScale(progressObj.Value, 1)})
				if label then titleLabel.Text = tostring(label) end
			end

			function progressObj:RefreshTheme(t)
				titleLabel.TextColor3 = t.Text
				frame.BackgroundColor3 = t.Second
				barTrack.BackgroundColor3 = t.Main
				barFill.BackgroundColor3 = t.Accent
				local s = frame:FindFirstChildOfClass("UIStroke")
				if s then s.Color = t.Stroke end
				local s2 = barTrack:FindFirstChildOfClass("UIStroke")
				if s2 then s2.Color = t.Stroke end
			end
			table.insert(Isotope._ElementRegistry, {name = resolvedText, obj = progressObj, tab = tabEntry})

			return progressObj
		end
		
		-- fdecs
		tabObject.AddSection = tabObject.Section
		tabObject.AddButton = tabObject.Button
		tabObject.AddToggle = tabObject.Toggle
		tabObject.AddColorpicker = tabObject.Colorpicker
		tabObject.AddSlider = tabObject.Slider
		tabObject.AddLabel = tabObject.Label
		tabObject.AddParagraph  = tabObject.Paragraph
		tabObject.AddTextbox = tabObject.TextBox
		tabObject.AddBind = tabObject.Bind
		tabObject.AddDropdown = tabObject.Dropdown
		tabObject.AddMultiDropdown = tabObject.MultiDropdown
		tabObject.AddProgressBar = tabObject.ProgressBar
		tabObject.AddSeparator  = tabObject.Separator
		tabObject.AddGrid = tabObject.Grid
		tabObject.AddStepper = tabObject.Stepper
		tabObject.AddKeyValue = tabObject.KeyValue

		return tabObject
	end
	
	function windowObject:TabSection(name)
		sidebarCount += 1

		local isCollapsed = false
		local sectionTabs = {}

		local secFrame = Instance.new("Frame")
		secFrame.BackgroundTransparency = 1
		secFrame.BorderSizePixel = 0
		secFrame.Size = UDim2.new(1, 0, 0, 20)
		secFrame.LayoutOrder = sidebarCount
		secFrame.ClipsDescendants = false
		secFrame.Parent = tabHolder

		local secBtn = Instance.new("TextButton")
		secBtn.Text = ""
		secBtn.BackgroundTransparency = 1
		secBtn.BorderSizePixel = 0
		secBtn.Size = UDim2.new(1, 0, 1, 0)
		secBtn.AutoButtonColor = false
		secBtn.Parent = secFrame

		local secLabel = Instance.new("TextLabel")
		secLabel.Text = string.upper(tostring(name or ""))
		secLabel.Font = Enum.Font.GothamBold
		secLabel.TextSize = 10
		secLabel.TextColor3 = theme.TextDark
		secLabel.BackgroundTransparency = 1
		secLabel.TextXAlignment = Enum.TextXAlignment.Left
		secLabel.Size = UDim2.new(1, -20, 1, 0)
		secLabel.Position = UDim2.new(0, 0, 0, 0)
		secLabel.Parent = secFrame
		addPadding(secLabel, 0, 0, 12, 0)

		local arrowIcon = Instance.new("ImageLabel")
		arrowIcon.Image = "rbxassetid://7072706796"
		arrowIcon.BackgroundTransparency = 1
		arrowIcon.ImageColor3 = theme.TextDark
		arrowIcon.AnchorPoint = Vector2.new(1, 0.5)
		arrowIcon.Size = UDim2.new(0, 10, 0, 10)
		arrowIcon.Position = UDim2.new(1, -14, 0.5, 0)
		arrowIcon.Rotation = 180
		arrowIcon.Parent = secFrame

		secBtn.MouseEnter:Connect(function()
			tweenObj(secLabel, 0.15, nil, nil, {TextColor3 = theme.Text})
			tweenObj(arrowIcon, 0.15, nil, nil, {ImageColor3 = theme.Text})
		end)
		secBtn.MouseLeave:Connect(function()
			tweenObj(secLabel, 0.15, nil, nil, {TextColor3 = theme.TextDark})
			tweenObj(arrowIcon, 0.15, nil, nil, {ImageColor3 = theme.TextDark})
		end)

		secBtn.MouseButton1Click:Connect(function()
			isCollapsed = not isCollapsed

			tweenObj(arrowIcon, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
				{Rotation = isCollapsed and 0 or 180})
			tweenObj(secLabel, 0.2, nil, nil,
				{TextColor3 = isCollapsed and theme.Stroke or theme.TextDark})

			for _, tabBtn in ipairs(sectionTabs) do
				if isCollapsed then
					if tabBtn:FindFirstChild("Ico") then
						tweenObj(tabBtn.Ico, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
							{ImageTransparency = 1})
					end
					if tabBtn:FindFirstChild("Title") then
						tweenObj(tabBtn.Title, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
							{TextTransparency = 1})
					end
					task.delay(0.22, function()
						if isCollapsed then
							tabBtn.Visible = false
						end
					end)
				else
					tabBtn.Visible = true
					task.defer(function()
						if tabBtn:FindFirstChild("Ico") then
							tweenObj(tabBtn.Ico, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
								{ImageTransparency = 0.4})
						end
						if tabBtn:FindFirstChild("Title") then
							tweenObj(tabBtn.Title, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
								{TextTransparency = sidebarExpanded and 0.4 or 1})
						end
					end)
				end
			end
		end)

		currentSection = sectionTabs
	end
	
	function windowObject:OpenProfileView(btns)
		btns = btns or {}
		local pGui = Instance.new("ScreenGui")
		pGui.Name = "IsotopeProfileView"
		pGui.ResetOnSpawn = false
		pGui.DisplayOrder = 200
		pGui.IgnoreGuiInset = true
		secGui(pGui)
		
		local panel = Instance.new("Frame")
		panel.BackgroundColor3 = theme.Main
		panel.BorderSizePixel = 0
		panel.AnchorPoint = Vector2.new(0.5, 0.5)
		panel.Size = UDim2.new(0, 0, 0, 0)
		panel.Position = UDim2.new(0.5, 0, 0.5, 0)
		panel.ClipsDescendants = true
		panel.Parent = pGui
		addCorner(panel, 0, 10)
		addStroke(panel, theme.Stroke, 1.5)
		
		local openTween = TweenService:Create(panel, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, 615, 0, 344)})
		openTween:Play()
		openTween.Completed:Connect(function()
			makeDraggable(panel, panel)
		end)
		
		local closeBtn = Instance.new("TextButton")
		closeBtn.Text = "Close"
		closeBtn.Font = Enum.Font.GothamBold
		closeBtn.TextSize = 13
		closeBtn.TextColor3 = theme.TextDark
		closeBtn.BackgroundColor3 = theme.Second
		closeBtn.BorderSizePixel = 0
		closeBtn.AutoButtonColor = false
		closeBtn.AnchorPoint = Vector2.new(1, 0)
		closeBtn.Size = UDim2.new(0, 90, 0, 28)
		closeBtn.Position = UDim2.new(1, -10, 0, 10)
		closeBtn.Parent = panel
		addCorner(closeBtn, 0, 6)
		addStroke(closeBtn, theme.Stroke, 1)
		
		local avatarImg = Instance.new("ImageLabel")
		avatarImg.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=420&height=420&format=png"
		avatarImg.BackgroundColor3 = theme.Divider
		avatarImg.BorderSizePixel = 0
		avatarImg.AnchorPoint = Vector2.new(0, 0.5)
		avatarImg.Size = UDim2.new(0, 80, 0, 80)
		avatarImg.Position = UDim2.new(0, 20, 0.5, -20)
		avatarImg.Parent = panel
		addCorner(avatarImg, 1, 0)
		addStroke(avatarImg, theme.Stroke, 1)
		
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Text = LocalPlayer.DisplayName
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextSize = 20
		nameLbl.TextColor3 = theme.Text
		nameLbl.BackgroundTransparency = 1
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.Size = UDim2.new(0, 300, 0, 26)
		nameLbl.Position = UDim2.new(0, 120, 0.5, -50)
		nameLbl.Parent = panel

		local userLbl = Instance.new("TextLabel")
		userLbl.Text = "@" .. LocalPlayer.Name .. "  ·  ID: " .. tostring(LocalPlayer.UserId)
		userLbl.Font = Enum.Font.Gotham
		userLbl.TextSize = 13
		userLbl.TextColor3 = theme.TextDark
		userLbl.BackgroundTransparency = 1
		userLbl.TextXAlignment = Enum.TextXAlignment.Left
		userLbl.Size = UDim2.new(0, 300, 0, 18)
		userLbl.Position = UDim2.new(0, 120, 0.5, -20)
		userLbl.Parent = panel

		local btnHolder = Instance.new("Frame")
		btnHolder.BackgroundTransparency = 1
		btnHolder.Size = UDim2.new(1, -40, 0, 36)
		btnHolder.Position = UDim2.new(0, 20, 0.5, 40)
		btnHolder.Parent = panel
		local btnLayout = Instance.new("UIListLayout")
		btnLayout.FillDirection = Enum.FillDirection.Horizontal
		btnLayout.Padding = UDim.new(0, 8)
		btnLayout.SortOrder = Enum.SortOrder.LayoutOrder
		btnLayout.Parent = btnHolder

		for i, btnConfig in ipairs(btns) do
			local b = Instance.new("TextButton")
			b.Text = btnConfig.Name or "Button"
			b.Font = Enum.Font.GothamBold
			b.TextSize = 13
			b.TextColor3 = theme.Text
			b.BackgroundColor3 = theme.Second
			b.BorderSizePixel = 0
			b.AutoButtonColor = false
			b.Size = UDim2.new(0, 120, 1, 0)
			b.LayoutOrder = i
			b.Parent = btnHolder
			addCorner(b, 0, 6)
			addStroke(b, theme.Stroke, 1)
			b.MouseButton1Click:Connect(function()
				if btnConfig.Callback then pcall(btnConfig.Callback) end
			end)
		end

		closeBtn.MouseButton1Click:Connect(function()
			TweenService:Create(panel, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In),
				{Size = UDim2.new(0, 0, 0, 0)}):Play()
			task.wait(0.38)
			pGui:Destroy()
		end)
	end

	windowObject.MakeTab = windowObject.Tab

	task.defer(function()
    	if Isotope._initDone then return end
    	Isotope._initDone = true
    	if Isotope.ShowKeybindList then Isotope:KeybindList(theme) end
    	if Isotope.ShowTopbar then Isotope:Topbar(theme) end
    	if Isotope.ShowRadial then Isotope:Radial(theme) end
	end)

	if doStartup and Animations[startupAnim] then
		task.spawn(function()
			Animations[startupAnim](mainWindow, screenGui, theme, startupText, startupIcon)
		end)
	else
		mainWindow.Visible = true
	end

	return windowObject
end

function Isotope:Init(theme)
    if not Isotope.SaveCfg then return end
    pcall(function()
        local configPath = Isotope.Folder .. "/" .. Isotope._CfgFile .. ".json"
        if isfile and isfile(configPath) then
            local rawData = readfile(configPath)
            local parsedData = HttpService:JSONDecode(rawData)
            for key, savedValue in pairs(parsedData) do
                if key:sub(1, 2) ~= "__" then
                    if Isotope.Flags[key] then
                        pcall(function() Isotope.Flags[key]:Set(savedValue) end)
                    end
                end
            end
        end
    end)
end

local _wmGui = nil

local _wmGui = nil

function Isotope:Watermark(title)
	if _wmGui and _wmGui.Parent then _wmGui:Destroy() end

	local theme = Isotope._activeTheme or Isotope.Themes.Dark

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "IsotopeWatermark"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 996
	screenGui.IgnoreGuiInset = true
	secGui(screenGui)
	_wmGui = screenGui

	local bar = Instance.new("Frame")
	bar.BackgroundColor3 = theme.Second
	bar.BackgroundTransparency = 0.1
	bar.BorderSizePixel = 0
	bar.AutomaticSize = Enum.AutomaticSize.X
	bar.Size = UDim2.new(0, 0, 0, 28)
	bar.Position = UDim2.new(0, 160, 0, 14) 
	bar.Parent = screenGui
	addCorner(bar, 0, 6)
	addStroke(bar, theme.Stroke, 1)

	do
		local dragging, dragStart, startPos = false
		bar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				dragStart = input.Position
				startPos = bar.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = input.Position - dragStart
				bar.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end)
	end

	local innerRow = Instance.new("Frame")
	innerRow.BackgroundTransparency = 1
	innerRow.AutomaticSize = Enum.AutomaticSize.X
	innerRow.Size = UDim2.new(0, 0, 1, 0)
	innerRow.Parent = bar

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Padding = UDim.new(0, 0)
	rowLayout.Parent = innerRow
	addPadding(innerRow, 0, 0, 10, 10)

	local function makeSeparator(order)
		local sep = Instance.new("TextLabel")
		sep.Text = "  |  "
		sep.Font = Enum.Font.Gotham
		sep.TextSize = 12
		sep.TextColor3 = theme.Stroke
		sep.BackgroundTransparency = 1
		sep.AutomaticSize = Enum.AutomaticSize.X
		sep.Size = UDim2.new(0, 0, 1, 0)
		sep.LayoutOrder = order
		sep.Parent = innerRow
		return sep
	end

	local function makeLabel(text, order, color)
		local lbl = Instance.new("TextLabel")
		lbl.Text = text
		lbl.Font = Enum.Font.GothamSemibold
		lbl.TextSize = 12
		lbl.TextColor3 = color or theme.Text
		lbl.BackgroundTransparency = 1
		lbl.AutomaticSize = Enum.AutomaticSize.X
		lbl.Size = UDim2.new(0, 0, 1, 0)
		lbl.LayoutOrder = order
		lbl.Parent = innerRow
		return lbl
	end

	local titleLbl = makeLabel(tostring(title or ""), 0, theme.Accent or Color3.fromRGB(0, 170, 255))
	titleLbl.Font = Enum.Font.GothamBold

	makeSeparator(1)
	local timeLbl = makeLabel("00:00:00", 2, theme.TextDark)

	makeSeparator(3)
	local fpsLbl = makeLabel("0 FPS", 4, theme.TextDark)

	local fields = {}
	local fieldOrder = 5
	local running = true

	local fpsCounter = 0
	local lastFpsUpdate = tick()
	local RunService = game:GetService("RunService")
	local heartbeatConn = RunService.Heartbeat:Connect(function()
		fpsCounter += 1
	end)

	task.spawn(function()
		while running and screenGui and screenGui.Parent do
			local t = os.date("*t")
			timeLbl.Text = string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)

			local now = tick()
			local elapsed = now - lastFpsUpdate
			if elapsed > 0 then
				fpsLbl.Text = tostring(math.round(fpsCounter / elapsed)) .. " FPS"
			end
			fpsCounter = 0
			lastFpsUpdate = tick()

			for _, field in ipairs(fields) do
				if field.valueFn then
					local ok, result = pcall(field.valueFn)
					if ok and result ~= nil then
						field.label.Text = tostring(result)
					end
				end
			end

			task.wait(1)
		end
		heartbeatConn:Disconnect()
	end)

	local wmObj = {}

	function wmObj:Title(text)
		titleLbl.Text = tostring(text or "")
	end

	function wmObj:Field(name, valueFn)
		local sep = makeSeparator(fieldOrder)
		fieldOrder += 1
		local isStatic = type(valueFn) ~= "function"
		local lbl = makeLabel("", fieldOrder, theme.TextDark)
		fieldOrder += 1

		local entry = {
			name = name,
			label = lbl,
			sep = sep,
			valueFn = not isStatic and valueFn or nil,
		}

		if isStatic then
			lbl.Text = tostring(valueFn)
		else
			local ok, result = pcall(valueFn)
			if ok and result ~= nil then lbl.Text = tostring(result) end
		end

		table.insert(fields, entry)
		return entry
	end

	function wmObj:SetField(name, value)
		for _, field in ipairs(fields) do
			if field.name == name then
				field.label.Text = tostring(value)
				field.valueFn = nil
				break
			end
		end
	end

	function wmObj:Hide()
		tweenObj(bar, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
			{BackgroundTransparency = 1})
		for _, child in ipairs(innerRow:GetChildren()) do
			if child:IsA("TextLabel") then
				tweenObj(child, 0.25, nil, nil, {TextTransparency = 1})
			end
		end
		task.delay(0.27, function() bar.Visible = false end)
	end

	function wmObj:Show()
		bar.Visible = true
		tweenObj(bar, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
			{BackgroundTransparency = 0.1})
		for _, child in ipairs(innerRow:GetChildren()) do
			if child:IsA("TextLabel") then
				tweenObj(child, 0.25, nil, nil, {TextTransparency = 0})
			end
		end
	end

	function wmObj:RefreshTheme(t)
		bar.BackgroundColor3 = t.Second
		titleLbl.TextColor3 = t.Accent or Color3.fromRGB(0, 170, 255)
		timeLbl.TextColor3 = t.TextDark
		fpsLbl.TextColor3 = t.TextDark
		local stroke = bar:FindFirstChildOfClass("UIStroke")
		if stroke then stroke.Color = t.Stroke end
		for _, field in ipairs(fields) do
			field.label.TextColor3 = t.TextDark
			field.sep.TextColor3 = t.Stroke
		end
		for _, child in ipairs(innerRow:GetChildren()) do
			if child:IsA("TextLabel") and child.LayoutOrder % 2 == 1 then
				child.TextColor3 = t.Stroke 
			end
		end
	end

	function wmObj:Destroy()
		running = false
		heartbeatConn:Disconnect()
		screenGui:Destroy()
	end

	bar.BackgroundTransparency = 1
	for _, child in ipairs(innerRow:GetChildren()) do
		if child:IsA("TextLabel") then child.TextTransparency = 1 end
	end
	task.defer(function()
		tweenObj(bar, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
			{BackgroundTransparency = 0.1})
		for _, child in ipairs(innerRow:GetChildren()) do
			if child:IsA("TextLabel") then
				tweenObj(child, 0.35, nil, nil, {TextTransparency = 0})
			end
		end
	end)

	return wmObj
end

Isotope.MakeWindow = Isotope.Window
Isotope.MakeNotification = Isotope.Notify

function Isotope:Destroy()
	local targets = {game:GetService("CoreGui"), LocalPlayer.PlayerGui}
	for _, target in pairs(targets) do
		for _, guiName in ipairs({"IsotopeUI", "IsotopeNotifications", "IsotopeNotificationsClassic", "IsotopeKeybindList", "IsotopeTopbar", "IsotopeRadial"}) do
			local guiInstance = target:FindFirstChild(guiName)
			if guiInstance then guiInstance:Destroy() end
		end
	end
	pcall(function()
		local protectedGui = gethui()
		for _, guiName in ipairs({"IsotopeUI", "IsotopeNotifications", "IsotopeNotificationsClassic", "IsotopeKeybindList", "IsotopeTopbar", "IsotopeRadial"}) do
			local guiInstance = protectedGui:FindFirstChild(guiName)
			if guiInstance then guiInstance:Destroy() end
		end
	end)
	table.clear(Isotope.Binds)
	table.clear(Isotope._Tabs)
	table.clear(Isotope._ElementRegistry)
	table.clear(notifStack)
	table.clear(Isotope.OwnerButtons)
	Isotope._BindListGui = nil
	Isotope._TopbarGui = nil
	Isotope._RadialGui = nil
	Isotope._MainWindowRef = nil
	Isotope._RestoreRef = nil
	Isotope._MinimizedRef = nil
	Isotope._initDone = false
	if _wmGui and _wmGui.Parent then
		_wmGui:Destroy()
		_wmGui = nil
	end
end

return Isotope
