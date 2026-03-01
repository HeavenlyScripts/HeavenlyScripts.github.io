local Heavenly = {}
Heavenly.Flags = {}
Heavenly.SaveCfg = false
Heavenly.Folder = "Heavenly"
Heavenly._CfgFile = ""
Heavenly.Binds = {}
Heavenly._BindListGui = nil
Heavenly._TopbarGui = nil
Heavenly._RadialGui = nil

Heavenly.ShowKeybindList = false
Heavenly.ShowTopbar = false
Heavenly.TopbarBind = nil
Heavenly.ShowRadial = false
Heavenly.RadialHotkey = nil
Heavenly.RadialMode = "hold"

Heavenly._Tabs = {}
Heavenly.TabOrder = false
Heavenly._ElementRegistry = {}

Heavenly._MainWindowRef = nil
Heavenly._MinimizedRef = nil
Heavenly._RestoreRef = nil

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local Themes = {}
Heavenly.Themes = Themes

do
	local defaultColors = {
		Main = Color3.fromRGB(25, 25, 25),
		Second = Color3.fromRGB(32, 32, 32),
		Stroke = Color3.fromRGB(60, 60, 60),
		Divider = Color3.fromRGB(60, 60, 60),
		Text = Color3.fromRGB(240, 240, 240),
		TextDark = Color3.fromRGB(150, 150, 150),
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
	})

	Themes:Add("Light", {
		Main = Color3.fromRGB(235, 235, 240),
		Second = Color3.fromRGB(248, 248, 252),
		Stroke = Color3.fromRGB(200, 200, 210),
		Divider = Color3.fromRGB(200, 200, 210),
		Text = Color3.fromRGB(30, 30, 35),
		TextDark = Color3.fromRGB(100, 100, 115),
	})
end

local function tweenObj(instance, duration, style, direction, props)
	TweenService:Create(
		instance,
		TweenInfo.new(duration, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		props
	):Play()
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

local function makeDraggable(dragHandle, targetFrame)
	local isDragging = false
	local dragStartMouse = Vector2.new()
	local dragStartFramePos = UDim2.new()
	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDragging = true
			dragStartMouse = input.Position
			dragStartFramePos = targetFrame.Position
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
			tweenObj(targetFrame, 0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
				Position = UDim2.new(
					dragStartFramePos.X.Scale,
					dragStartFramePos.X.Offset + delta.X,
					dragStartFramePos.Y.Scale,
					dragStartFramePos.Y.Offset + delta.Y
				),
			})
		end
	end)
end

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
	[Enum.KeyCode.LeftMeta] = "Meta", -- win butons??
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
			gui.Parent = game:GetService("CoreGui") -- idek if this works i hope so
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
	progressFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
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
--[[
local notifGuiClassic = nil
local function getNotifGuiClassic()
	if notifGuiClassic and notifGuiClassic.Parent then return notifGuiClassic end
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HeavenlyNotificationsClassic"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 999
	secGui(screenGui)
	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(1, 1)
	holder.Position = UDim2.new(1, -25, 1, -25)
	holder.Size = UDim2.new(0, 300, 1, -25)
	holder.Parent = screenGui
	local holderLayout = addListLayout(holder, 5)
	holderLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	holderLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	notifGuiClassic = screenGui
	return screenGui
end

function Heavenly:NotifyClassic(configOrText, durationArg)
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
	local screenGui = getNotifGuiClassic()
	local holder = screenGui:FindFirstChild("Holder")
	if not holder then return end
	task.spawn(function()
		local sideBarWidth = 6
		local sideBarGap = 6
		local wrapper = Instance.new("Frame")
		wrapper.BackgroundTransparency = 1
		wrapper.Size = UDim2.new(1, 0, 0, 0)
		wrapper.ClipsDescendants = true
		wrapper.Parent = holder
		local card = Instance.new("Frame")
		card.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
		card.BorderSizePixel = 0
		card.Size = UDim2.new(1, -(sideBarWidth + sideBarGap), 0, 0)
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.Position = UDim2.new(1, 10, 0, 0)
		card.Parent = wrapper
		addCorner(card, 0, 8)
		addStroke(card, Color3.fromRGB(55, 55, 60), 1)
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
		timerTrack.AnchorPoint = Vector2.new(1, 0)
		timerTrack.Size = UDim2.new(0, sideBarWidth, 0, 0)
		timerTrack.Position = UDim2.new(1, 0, 0, 0)
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
			wrapper.Size = UDim2.new(1, 0, 0, cardHeight + 5)
			timerTrack.Size = UDim2.new(0, sideBarWidth, 0, cardHeight)
			tweenObj(card, 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
				{Position = UDim2.new(0, 0, 0, 0)})
		end)
		task.wait(0.45)
		local drainDuration = math.max(duration - 0.45, 0.1)
		tweenObj(timerFill, drainDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out,
			{Size = UDim2.new(1, 0, 0, 0)})
		task.wait(drainDuration)
		wrapper.ClipsDescendants = false
		tweenObj(card, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In, {Position = UDim2.new(1, 400, 0, 0)})
		tweenObj(timerTrack, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In, {Position = UDim2.new(1, 400, 0, 0)})
		task.wait(0.38)
		wrapper.ClipsDescendants = true
		tweenObj(wrapper, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Size = UDim2.new(1, 0, 0, 0)})
		task.wait(0.28)
		wrapper:Destroy()
	end)
end --]] -- This "Classicc" is the same als :Notify i think? kept in there just in case

local notifGui = nil
local notifStack = {}

local notifWidth = 300
local notifGap = 8
local notifRightMargin = 25
local notifBottomMargin = 25

local function getNotifGui()
	if notifGui and notifGui.Parent then return notifGui end
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HeavenlyNotifications"
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

function Heavenly:Notify(configOrText, durationArg)
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

		local card = Instance.new("Frame")
		card.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
		card.BorderSizePixel = 0
		card.Size = UDim2.new(0, notifWidth, 0, 0)
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.Position = UDim2.new(1, 10, 0, 0)
		card.Parent = wrapper
		addCorner(card, 0, 8)
		addStroke(card, Color3.fromRGB(55, 55, 60), 1)

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

		local stackEntry = {frame = wrapper, estimatedHeight = estimatedHeight, targetY = 0}
		table.insert(notifStack, 1, stackEntry)

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

local function saveFlags(folder, file)
	if not (writefile and isfolder and makefolder) then return end
	pcall(function()
		if not isfolder(folder) then makefolder(folder) end
		local saveData = {}
		for key, flagObj in pairs(Heavenly.Flags) do -- this is all red idk i dont think it will work :(
			if flagObj.Save then saveData[key] = flagObj.Value end
		end
		writefile(folder .. "/" .. file .. ".json", HttpService:JSONEncode(saveData))
	end)
end

function Heavenly:Topbar()
	if not Heavenly.ShowTopbar then return end
	if Heavenly._TopbarGui and Heavenly._TopbarGui.Parent then
		Heavenly._TopbarGui:Destroy()
	end

	local tabs = Heavenly._Tabs
	local tabCount = #tabs
	if tabCount == 0 then return end

	local buttonSize = 34
	local buttonGap = 5
	local horizontalPad = 8
	local verticalPad = 7
	local maxPerRow = 6
	local expandButtonWidth = 26
	local accentColor = Color3.fromRGB(0, 170, 255)
	local panelBgColor = Color3.fromRGB(20, 20, 26)
	local buttonBgColor = Color3.fromRGB(30, 30, 40)
	local strokeColor = Color3.fromRGB(50, 50, 65)

	local rowCount = math.ceil(tabCount / maxPerRow)
	local MultipleRows = rowCount > 1
	local firstRowCount = math.min(tabCount, maxPerRow)

	local firstRowWidth = firstRowCount * buttonSize + (firstRowCount - 1) * buttonGap
	local panelWidth = horizontalPad + firstRowWidth + buttonGap + buttonSize + horizontalPad + (MultipleRows and (buttonGap + expandButtonWidth) or 0)

	local collapsedHeight = verticalPad + buttonSize + verticalPad
	local expandedHeight = verticalPad + (rowCount * buttonSize + (rowCount - 1) * buttonGap) + verticalPad
	local isExpanded = false

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HeavenlyTopbar"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 997
	screenGui.IgnoreGuiInset = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	secGui(screenGui)
	Heavenly._TopbarGui = screenGui

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

	if MultipleRows then -- after 6 icons give a new row + button to expand
		local expandBtn = Instance.new("TextButton")
		expandBtn.Text = "..."
		expandBtn.Font = Enum.Font.GothamBold
		expandBtn.TextSize = 13
		expandBtn.TextColor3 = Color3.fromRGB(130, 130, 155)
		expandBtn.AutoButtonColor = false
		expandBtn.BackgroundColor3 = buttonBgColor
		expandBtn.BorderSizePixel = 0
		expandBtn.AnchorPoint = Vector2.new(0, 0)
		expandBtn.Size = UDim2.new(0, expandButtonWidth, 0, buttonSize)
		expandBtn.Position = UDim2.new(0, horizontalPad + firstRowWidth + buttonGap + buttonSize + buttonGap, 0, verticalPad)
		expandBtn.ZIndex = 5
		expandBtn.Parent = topbarPanel
		addCorner(expandBtn, 0, 6)
		addStroke(expandBtn, strokeColor, 1)

		expandBtn.MouseEnter:Connect(function()
			tweenObj(expandBtn, 0.15, nil, nil, {TextColor3 = Color3.fromRGB(210, 210, 235)}) 
		end)
		expandBtn.MouseLeave:Connect(function()
			tweenObj(expandBtn, 0.15, nil, nil, {TextColor3 = Color3.fromRGB(130, 130, 155)})
		end)
		expandBtn.MouseButton1Click:Connect(function()
			isExpanded = not isExpanded
			expandBtn.Text = isExpanded and "x" or "..." -- ic
			local targetHeight = isExpanded and expandedHeight or collapsedHeight
			tweenObj(topbarPanel, 0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
				{Size = UDim2.new(0, panelWidth, 0, targetHeight)})
		end)
	end

	local activeTooltip = nil -- tab name above icon

	local function showTooltip(tabName, absoluteX, absoluteY)
		if activeTooltip then
			activeTooltip:Destroy()
			activeTooltip = nil
		end
		local tooltip = Instance.new("TextLabel")
		tooltip.Text = tabName
		tooltip.Font = Enum.Font.GothamSemibold -- red underline?
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
			activeTooltip:Destroy() -- dont hide or buggy
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
		tabIcon.ImageColor3 = Color3.fromRGB(165, 165, 190)
		tabIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		tabIcon.Size = UDim2.new(0, 18, 0, 18)
		tabIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		tabIcon.ZIndex = 4
		tabIcon.Parent = tabButton

		tabButton.MouseEnter:Connect(function()
			tweenObj(tabButton, 0.12, nil, nil, {BackgroundColor3 = Color3.fromRGB(45, 45, 60)})
			tweenObj(tabIcon, 0.12, nil, nil, {ImageColor3 = Color3.fromRGB(220, 220, 240)})
			local absPos = tabButton.AbsolutePosition
			showTooltip(tabEntry.name, absPos.X + buttonSize / 2, absPos.Y)
		end)
		tabButton.MouseLeave:Connect(function()
			tweenObj(tabButton, 0.12, nil, nil, {BackgroundColor3 = buttonBgColor})
			tweenObj(tabIcon, 0.12, nil, nil, {ImageColor3 = Color3.fromRGB(165, 165, 190)})
			hideTooltip()
		end)
		tabButton.MouseButton1Click:Connect(function()
			hideTooltip()
			tweenObj(tabButton, 0.07, nil, nil, {BackgroundColor3 = accentColor})
			tweenObj(tabButton, 0.22, nil, nil, {BackgroundColor3 = buttonBgColor})
			if Heavenly._RestoreRef then pcall(Heavenly._RestoreRef) end -- sum other stuff
			pcall(tabEntry.selectFn)
		end)
	end

	local searchOpen = false
	local searchButton = Instance.new("TextButton")
	searchButton.Text = ""
	searchButton.AutoButtonColor = false
	searchButton.BackgroundColor3 = buttonBgColor
	searchButton.BorderSizePixel = 0
	searchButton.AnchorPoint = Vector2.new(0, 0)
	searchButton.Size = UDim2.new(0, buttonSize, 0, buttonSize)
	searchButton.Position = UDim2.new(0, horizontalPad + firstRowWidth + buttonGap, 0, verticalPad)
	searchButton.ZIndex = 5
	searchButton.Parent = topbarPanel
	addCorner(searchButton, 0, 7)
	addStroke(searchButton, strokeColor, 1)

	local searchIcon = Instance.new("ImageLabel")
	searchIcon.Image = "rbxassetid://91129038063259"
	searchIcon.BackgroundTransparency = 1
	searchIcon.ImageColor3 = Color3.fromRGB(130, 130, 155)
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

	local function syncPanel() -- helper cuz i cant do it any other wasy
		searchPanel.Position = UDim2.new(
			0, topbarPanel.AbsolutePosition.X,
			0, topbarPanel.AbsolutePosition.Y + topbarPanel.AbsoluteSize.Y + 6
		)
	end

	topbarPanel:GetPropertyChangedSignal("Position"):Connect(syncPanel)
	topbarPanel:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncPanel)

	local searchBoxWrapper = Instance.new("Frame")
	searchBoxWrapper.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
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

	local function buildIndex() -- for search
		local index = {}
		local seen = {}
		for flagName, flagObj in pairs(Heavenly.Flags) do
			local tabRef = nil
			for _, entry in ipairs(Heavenly._ElementRegistry) do
				if entry.obj == flagObj then
					tabRef = entry.tab
					break
				end
			end
			table.insert(index, {key = flagName, obj = flagObj, tab = tabRef})
			seen[flagObj] = true
		end
		for _, entry in ipairs(Heavenly._ElementRegistry) do
			if not seen[entry.obj] then
				table.insert(index, {key = entry.name, obj = entry.obj, tab = entry.tab})
				seen[entry.obj] = true
			end
		end
		for _, bindEntry in ipairs(Heavenly.Binds) do
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
			{ImageColor3 = Color3.fromRGB(130, 130, 155)})
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
						if Heavenly._RestoreRef then pcall(Heavenly._RestoreRef) end
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
			{ImageColor3 = Color3.fromRGB(0, 170, 255)})
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
			tweenObj(searchIcon, 0.15, nil, nil, {ImageColor3 = Color3.fromRGB(130, 130, 155)})
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

function Heavenly:Radial()
	if not Heavenly.ShowRadial then return end
	if not Heavenly.RadialHotkey then
		warn("Heavenly >> ShowRadial = true but RadialHotkey is nil")
		return
	end
	if Heavenly._RadialGui and Heavenly._RadialGui.Parent then
		Heavenly._RadialGui:Destroy()
	end

	local tabs = Heavenly._Tabs
	if #tabs == 0 then return end
	local tabCount = #tabs

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HeavenlyRadial"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 999
	screenGui.IgnoreGuiInset = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	secGui(screenGui)
	Heavenly._RadialGui = screenGui

	local ringRadius = 150
	local innerRadius = 56
	local cardWidth = 110
	local cardHeight = 64
	local containerSize = (ringRadius + cardHeight) * 2 + 40
	local twoPi = math.pi * 2
	local segmentAngle = twoPi / tabCount
	local accentColor = Color3.fromRGB(0, 170, 255)

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

	local centerCircle = Instance.new("Frame")
	centerCircle.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	centerCircle.BorderSizePixel = 0
	centerCircle.AnchorPoint = Vector2.new(0.5, 0.5)
	centerCircle.Size = UDim2.new(0, innerRadius * 2, 0, innerRadius * 2)
	centerCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
	centerCircle.ZIndex = 8
	centerCircle.Parent = container
	addCorner(centerCircle, 1, 0)
	addStroke(centerCircle, Color3.fromRGB(50, 50, 70), 1.5)

	local centerHint = Instance.new("TextLabel")
	centerHint.Text = Heavenly.RadialMode == "hold" and "release\nto cancel" or "click\nto select"
	centerHint.Font = Enum.Font.Gotham
	centerHint.TextSize = 10
	centerHint.TextColor3 = Color3.fromRGB(90, 90, 115)
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
	centerName.TextColor3 = Color3.fromRGB(220, 220, 240)
	centerName.BackgroundTransparency = 1
	centerName.AnchorPoint = Vector2.new(0.5, 0)
	centerName.Size = UDim2.new(1, -10, 0.5, 0)
	centerName.Position = UDim2.new(0.5, 0, 0.08, 0)
	centerName.TextXAlignment = Enum.TextXAlignment.Center
	centerName.TextWrapped = true
	centerName.ZIndex = 9
	centerName.Parent = centerCircle

	local segments = {}
	local hoveredIndex = nil

	local function setHovered(index)
		if hoveredIndex == index then return end
		hoveredIndex = index
		centerName.Text = index and tabs[index].name or ""
		for segIndex, segment in ipairs(segments) do
			local isActive = (segIndex == index)
			tweenObj(segment.frame, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
				BackgroundColor3 = isActive and accentColor or Color3.fromRGB(22, 22, 30),
				BackgroundTransparency = isActive and 0 or 0.12,
			})
			if segment.icon then
				tweenObj(segment.icon, 0.12, nil, nil, {
					ImageColor3 = isActive and Color3.new(1, 1, 1) or Color3.fromRGB(160, 160, 185),
				})
			end
			if segment.label then
				tweenObj(segment.label, 0.12, nil, nil, {
					TextColor3 = isActive and Color3.new(1, 1, 1) or Color3.fromRGB(180, 180, 205),
					TextTransparency = isActive and 0 or 0.25,
				})
			end
		end
	end

	for segIndex = 1, tabCount do
		local tabEntry = tabs[segIndex]
		local angle = -math.pi / 2 + segmentAngle * (segIndex - 1) + segmentAngle / 2
		local posX = ringRadius * math.cos(angle)
		local posY = ringRadius * math.sin(angle)

		local card = Instance.new("Frame")
		card.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
		card.BackgroundTransparency = 0.12
		card.BorderSizePixel = 0
		card.AnchorPoint = Vector2.new(0.5, 0.5)
		card.Size = UDim2.new(0, cardWidth, 0, cardHeight)
		card.Position = UDim2.new(0.5, posX, 0.5, posY)
		card.ZIndex = 3
		card.Parent = container
		addCorner(card, 0, 10)
		addStroke(card, Color3.fromRGB(45, 45, 65), 1)

		local cardIcon = nil
		local cardLabel = nil

		if tabEntry.icon and tabEntry.icon ~= "" then
			cardIcon = Instance.new("ImageLabel")
			cardIcon.Image = tabEntry.icon
			cardIcon.BackgroundTransparency = 1
			cardIcon.ImageColor3 = Color3.fromRGB(160, 160, 185)
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

	local function openWheel()
		if isOpen then return end
		isOpen = true
		backdrop.BackgroundTransparency = 1
		backdrop.Visible = true
		container.Size = UDim2.new(0, 0, 0, 0)
		container.Visible = true
		tweenObj(backdrop, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
			{BackgroundTransparency = 0.55})
		tweenObj(container, 0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
			{Size = UDim2.new(0, containerSize, 0, containerSize)})
	end

	local function closeWheel(selectIndex)
		if not isOpen then return end
		isOpen = false
		local closeTween = TweenService:Create(backdrop,
			TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{BackgroundTransparency = 1})
		TweenService:Create(container,
			TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
			{Size = UDim2.new(0, 0, 0, 0)}):Play()
		closeTween.Completed:Connect(function()
			backdrop.Visible = false
			container.Visible = false
		end)
		closeTween:Play()
		setHovered(nil)
		if selectIndex then
			if Heavenly._RestoreRef then pcall(Heavenly._RestoreRef) end
			pcall(tabs[selectIndex].selectFn)
		end
	end

	UserInputService.InputChanged:Connect(function(input)
		if not isOpen then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

		local containerAbsPos = container.AbsolutePosition
		local containerAbsSize = container.AbsoluteSize
		local centerX = containerAbsPos.X + containerAbsSize.X / 2
		local centerY = containerAbsPos.Y + containerAbsSize.Y / 2
		local deltaX = input.Position.X - centerX
		local deltaY = input.Position.Y - centerY
		local distance = math.sqrt(deltaX * deltaX + deltaY * deltaY)

		if distance < innerRadius or distance > ringRadius + cardHeight / 2 + 15 then
			setHovered(nil)
			return
		end

		local mouseAngle = math.atan2(deltaY, deltaX)--x7z ur a kat
		local normalizedAngle = ((mouseAngle + math.pi / 2) % twoPi)
		local segmentIndex = math.floor(normalizedAngle / segmentAngle) % tabCount + 1
		setHovered(segmentIndex)
	end)

	if Heavenly.RadialMode == "toggle" then
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if not isOpen then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				closeWheel(hoveredIndex)
			end
		end)
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode ~= Heavenly.RadialHotkey then return end
		if Heavenly.RadialMode == "toggle" then
			if isOpen then closeWheel(nil) else openWheel() end
		else
			openWheel()
		end
	end)

	if Heavenly.RadialMode == "hold" then
		UserInputService.InputEnded:Connect(function(input)
			if input.KeyCode ~= Heavenly.RadialHotkey then return end
			if isOpen then closeWheel(hoveredIndex) end
		end)
	end

	return screenGui
end

function Heavenly:KeybindList()
	if Heavenly.ShowKeybindList == false then return end
	if Heavenly._BindListGui and Heavenly._BindListGui.Parent then
		Heavenly._BindListGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HeavenlyKeybindList"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 998
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	secGui(screenGui)
	Heavenly._BindListGui = screenGui

	local keybindPanel = Instance.new("Frame")
	keybindPanel.Name = "KeybindPanel"
	keybindPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
	keybindPanel.BackgroundTransparency = 0.2
	keybindPanel.BorderSizePixel = 0
	keybindPanel.AnchorPoint = Vector2.new(0, 1)
	keybindPanel.Position = UDim2.new(0, 18, 1, -18)
	keybindPanel.Size = UDim2.new(0, 210, 0, 0)
	keybindPanel.AutomaticSize = Enum.AutomaticSize.Y
	keybindPanel.Visible = false
	keybindPanel.Parent = screenGui
	addCorner(keybindPanel, 0, 8)
	addStroke(keybindPanel, Color3.fromRGB(55, 55, 62), 1)

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
	headerLabel.TextColor3 = Color3.fromRGB(110, 110, 125)
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
	dividerLine.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
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
		nameLabel.TextColor3 = Color3.fromRGB(200, 200, 205)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.AnchorPoint = Vector2.new(0, 0.5)
		nameLabel.Size = UDim2.new(1, -80, 1, 0)
		nameLabel.Position = UDim2.new(0, 10, 0.5, 0)
		nameLabel.Parent = row

		local keyBadge = Instance.new("Frame")
		keyBadge.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
		keyBadge.BorderSizePixel = 0
		keyBadge.AnchorPoint = Vector2.new(1, 0.5)
		keyBadge.Size = UDim2.new(0, 60, 0, 17)
		keyBadge.Position = UDim2.new(1, -10, 0.5, 0)
		keyBadge.Parent = row
		addCorner(keyBadge, 0, 4)
		addStroke(keyBadge, Color3.fromRGB(58, 58, 68), 1)

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

	for _, entry in ipairs(Heavenly.Binds) do
		buildKeybindRow(entry)
	end

	local knownBindCount = #Heavenly.Binds
	task.spawn(function()
		while screenGui and screenGui.Parent do
			task.wait(0.5)
			if #Heavenly.Binds > knownBindCount then
				for newIndex = knownBindCount + 1, #Heavenly.Binds do
					buildKeybindRow(Heavenly.Binds[newIndex])
				end
				knownBindCount = #Heavenly.Binds
			end
		end
	end)

	refPanelVis()
	return screenGui
end

function Heavenly:Window(config)
	config = config or {}
	
	local targets = {game:GetService("CoreGui"), LocalPlayer.PlayerGui}
	for _, target in pairs(targets) do
		for _, guiName in ipairs({"HeavenlyUI", "HeavenlyNotifications", "HeavenlyNotificationsClassic", "HeavenlyKeybindList", "HeavenlyTopbar", "HeavenlyRadial"}) do
			local guiInstance = target:FindFirstChild(guiName)
			if guiInstance then guiInstance:Destroy() end
		end
	end
	pcall(function()
		local protectedGui = gethui()
		for _, guiName in ipairs({"HeavenlyUI", "HeavenlyNotifications", "HeavenlyNotificationsClassic", "HeavenlyKeybindList", "HeavenlyTopbar", "HeavenlyRadial"}) do
			local guiInstance = protectedGui:FindFirstChild(guiName)
			if guiInstance then guiInstance:Destroy() end
		end
	end)
	-- rreset state tabls 
	table.clear(Heavenly.Binds)
	table.clear(Heavenly._Tabs)
	table.clear(Heavenly._ElementRegistry)
	table.clear(notifStack)
	Heavenly._BindListGui = nil
	Heavenly._TopbarGui = nil
	Heavenly._RadialGui = nil
	Heavenly._MainWindowRef = nil
	Heavenly._RestoreRef = nil
	Heavenly._MinimizedRef = nil

	local windowName = config.Name or "HeavenlyUI"
	local theme = Themes[config.Theme] or Themes.Dark
	local doStartup = config.Startup or false
	local startupAnim = config.StartupAnim or "Fade"
	local startupText = config.StartupText or ""
	local startupIcon = config.StartupIcon or ""
	local configFolder = config.ConfigFolder or windowName
	local configFile = config.Config or tostring(game.GameId)
	local doSaveConfig = config.SaveConfig or false
	local closeCallback = config.CloseCallback or function() end
	local showPlayerName = (config.PlayerName ~= false) -- deprecated
	local showDisplayName = (config.ShowDisplayName == true)
	local showUsername = (config.ShowUsername == true)

	Heavenly.SaveCfg = doSaveConfig
	Heavenly.Folder = configFolder
	Heavenly._CfgFile = configFile

	local accentColor = Color3.fromRGB(0, 170, 255)
	local accentElements = {}
	local sidebarExpanded = true
	local isMinimized = false
	local isHidden = false
	local activeTabPage = nil
	local activeTabButton = nil
	local allTabs = {}

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HeavenlyUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	secGui(screenGui)

	if screenGui.Parent then
		for _, child in pairs(screenGui.Parent:GetChildren()) do
			if child.Name == "HeavenlyUI" and child ~= screenGui then child:Destroy() end
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

	Heavenly._MainWindowRef = mainWindow

	local topBar = Instance.new("Frame")
	topBar.BackgroundTransparency = 1
	topBar.Size = UDim2.new(1, 0, 0, 50)
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
	toggleSidebarIcon.TextColor3 = Color3.fromRGB(160, 160, 160)
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

	local dragHandle = Instance.new("Frame")
	dragHandle.BackgroundTransparency = 1
	dragHandle.Size = UDim2.new(1, 0, 0, 50)
	dragHandle.Parent = mainWindow
	makeDraggable(dragHandle, mainWindow)

	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.BackgroundColor3 = theme.Second
	sidebar.BorderSizePixel = 0
	sidebar.Size = UDim2.new(0, 150, 1, -50)
	sidebar.Position = UDim2.new(0, 0, 0, 50)
	sidebar.Parent = mainWindow
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
	tabHolder.Size = UDim2.new(1, 0, 1, -50)
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

	if not showPlayerName then
		tabHolder.Size = UDim2.new(1, 0, 1, 0)
		bottomDivider.Visible = false
	end

	local bottomBar = Instance.new("Frame")
	bottomBar.BackgroundTransparency = 1
	bottomBar.Size = UDim2.new(1, 0, 0, 50)
	bottomBar.Position = UDim2.new(0, 0, 1, -50)
	bottomBar.Visible = showPlayerName
	bottomBar.Parent = sidebar

	local avatarFrame = Instance.new("Frame")
	avatarFrame.BackgroundColor3 = theme.Divider
	avatarFrame.BorderSizePixel = 0
	avatarFrame.AnchorPoint = Vector2.new(0, 0.5)
	avatarFrame.Size = UDim2.new(0, 32, 0, 32)
	avatarFrame.Position = UDim2.new(0, 10, 0.5, 0)
	avatarFrame.Parent = bottomBar
	addCorner(avatarFrame, 1, 0)

	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=420&height=420&format=png"
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
	avatarSubLabel.Parent = bottomBar

	toggleSidebarButton.MouseButton1Click:Connect(function()
		if sidebarExpanded then
			sidebarExpanded = false
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
					task.delay(0.15, function()
						tabData.btn.Ico.AnchorPoint = Vector2.new(0.5, 0.5)
						tweenObj(tabData.btn.Ico, 0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
							{Position = UDim2.new(0.5, 0, 0.5, 0)})
					end)
				end)
			end
			if showDisplayName then
				tweenObj(displayNameLabel, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 1})
			end
			if showUsername then
				tweenObj(usernameLabel, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 1})
			end
			tweenObj(avatarSubLabel, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 1})
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
			if showDisplayName then
				task.delay(0.2, function()
					tweenObj(displayNameLabel, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 0})
				end)
			end
			if showUsername then
				task.delay(0.2, function()
					tweenObj(usernameLabel, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 0})
				end)
			end
			if avatarSubLabel.Text ~= "" then
				task.delay(0.2, function()
					tweenObj(avatarSubLabel, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 0})
				end)
			end
		end
	end)

	minimizeButton.MouseButton1Up:Connect(function()
		if isMinimized then
			mainWindow.Size = UDim2.new(0, 615, 0, 344)
			mainWindow.ClipsDescendants = false
			sidebar.Visible = true
			topBarDivider.Visible = true
			minimizeIcon.Image = "rbxassetid://7072719338"
		else
			mainWindow.ClipsDescendants = true
			topBarDivider.Visible = false
			sidebar.Visible = false
			minimizeIcon.Image = "rbxassetid://7072720870"
			mainWindow.Size = UDim2.new(0, topBarlbl.TextBounds.X + 140, 0, 50)
		end
		isMinimized = not isMinimized
	end)

	closeButton.MouseButton1Up:Connect(function()
		mainWindow.Visible = false
		isHidden = true
		pcall(closeCallback)
		Heavenly:Notify({
			Name = "Interface Hidden",
			Content = "Press RightShift to reopen.",
			Time = 5,
		})
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.RightShift and isHidden then
			mainWindow.Visible = true
			isHidden = false
			isMinimized = false
		end
	end)

	local function restoreWindow()
		if isHidden then
			mainWindow.Visible = true
			isHidden = false
			isMinimized = false
			return
		end
		if isMinimized then
			mainWindow.Size = UDim2.new(0, 615, 0, 344)
			mainWindow.ClipsDescendants = false
			sidebar.Visible = true
			topBarDivider.Visible = true
			minimizeIcon.Image = "rbxassetid://7072719338"
			isMinimized = false
		end
	end
	Heavenly._RestoreRef = restoreWindow
	Heavenly._MinimizedRef = function() return isMinimized end

	local function selectTab(page, button)
		if activeTabPage then activeTabPage.Visible = false end
		if activeTabButton then
			activeTabButton.Title.Font = Enum.Font.GothamSemibold
			tweenObj(activeTabButton.Ico, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {ImageTransparency = 0.4})
			tweenObj(activeTabButton.Title, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TextTransparency = 0.4})
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
			tweenObj(button.Title, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TextTransparency = 0})
		end
	end

	local windowObject = {}

	function windowObject:SetAvatarText(text)
		avatarSubLabel.Text = tostring(text)
		if sidebarExpanded and text ~= "" then
			tweenObj(avatarSubLabel, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 0})
		else
			tweenObj(avatarSubLabel, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 1})
		end
	end

	function windowObject:SetTheme(name)
		local newTheme = Themes[name]
		if not newTheme then return end
		theme = newTheme
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
		displayNameLabel.TextColor3 = newTheme.Text
		usernameLabel.TextColor3 = newTheme.TextDark
		avatarSubLabel.TextColor3 = newTheme.TextDark
		avatarOverlay.ImageColor3 = newTheme.Second
		avatarFrame.BackgroundColor3 = newTheme.Divider
		minimizeIcon.ImageColor3 = newTheme.Text
		closeIcon.ImageColor3 = newTheme.Text
		tabHolder.ScrollBarImageColor3 = newTheme.Divider
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
		table.insert(Heavenly._Tabs, tabEntry)

		table.insert(allTabs, {btn = tabButton, page = tabPage})
		tabButton.LayoutOrder = #allTabs
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

		local tabObject = {}

		tabObject._tabEntry = tabEntry

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
			function sectionObject:Button(t, cb)        return tabObject:Button(t, cb, sectionHolder) end -- looks cleaner dont mind design and variable names figure it out yaself
			function sectionObject:Toggle(t, d, cb, fl)        return tabObject:Toggle(t, d, cb, fl, sectionHolder) end
			function sectionObject:Label(t)                     return tabObject:Label(t, sectionHolder) end
			function sectionObject:TextBox(p, cb)             return tabObject:TextBox(p, cb, sectionHolder) end
			function sectionObject:Slider(t, mn, mx, df, cb, fl)  return tabObject:Slider(t, mn, mx, df, cb, fl, sectionHolder) end
			function sectionObject:Paragraph(t, c)                return tabObject:Paragraph(t, c, sectionHolder) end
			function sectionObject:Dropdown(c)             return tabObject:Dropdown(c, sectionHolder) end
			function sectionObject:Bind(c)               return tabObject:Bind(c, sectionHolder) end
			function sectionObject:Colorpicker(c)   return tabObject:Colorpicker(c, sectionHolder) end
			return sectionObject
		end

		function tabObject:Label(text, parentOverride)
			local resolvedText = type(text) == "table" and (text.Text or "Label") or tostring(text)
			local frame = makeElementFrame(30, parentOverride)
			frame.BackgroundTransparency = 0.7

			local label = Instance.new("TextLabel")
			label.Name = "Content"
			label.Text = resolvedText
			label.Font = Enum.Font.GothamBold
			label.TextSize = 15
			label.TextColor3 = theme.Text
			label.BackgroundTransparency = 1
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Size = UDim2.new(1, -12, 1, 0)
			label.Position = UDim2.new(0, 12, 0, 0)
			label.Parent = frame

			local obj = {}
			function obj:Set(t) label.Text = tostring(t) end
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
			table.insert(Heavenly._ElementRegistry, {name = resolvedText, obj = obj, tab = tabEntry})
			return obj
		end

		function tabObject:Toggle(text, default, callback, flagName, parentOverride)
			local resolvedText = type(text) == "table" and (text.Name or "Toggle") or tostring(text)
			local resolvedDefault = type(text) == "table" and (text.Default or false) or (default or false)
			local resolvedCb = type(text) == "table" and (text.Callback or function() end) or (callback or function() end)
			local resolvedFlag = type(text) == "table" and text.Flag or flagName
			local resolvedColor = type(text) == "table" and (text.Color or Color3.fromRGB(9, 99, 195)) or Color3.fromRGB(9, 99, 195)
			local resolvedSave = type(text) == "table" and (text.Save or false) or false

			local toggleObj = {Value = resolvedDefault, Save = resolvedSave, Type = "Toggle"}

			local frame = makeElementFrame(38, parentOverride)

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

			local clickButton = Instance.new("TextButton")
			clickButton.Text = ""
			clickButton.AutoButtonColor = false
			clickButton.BackgroundTransparency = 1
			clickButton.BorderSizePixel = 0
			clickButton.Size = UDim2.new(1, 0, 1, 0)
			clickButton.Parent = frame

			function toggleObj:Set(value)
				toggleObj.Value = value
				tweenObj(checkboxFrame, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
					{BackgroundColor3 = value and resolvedColor or Themes.Dark.Divider})
				tweenObj(checkboxStroke, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
					{Color = value and resolvedColor or Themes.Dark.Stroke})
				tweenObj(checkIcon, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
					ImageTransparency = value and 0 or 1,
					Size = value and UDim2.new(0, 20, 0, 20) or UDim2.new(0, 8, 0, 8),
				})
				pcall(resolvedCb, value)
			end

			toggleObj:Set(resolvedDefault)
			applyHover(clickButton, frame)
			clickButton.MouseButton1Up:Connect(function()
				toggleObj:Set(not toggleObj.Value)
				if doSaveConfig then saveFlags(configFolder, configFile) end
			end)

			if resolvedFlag then Heavenly.Flags[resolvedFlag] = toggleObj end
			table.insert(Heavenly._ElementRegistry, {name = resolvedText, obj = toggleObj, tab = tabEntry})
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
			inputBox.Text = resolvedDefault
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
				pcall(resolvedCb, inputBox.Text)
				if resolvedDisappear then inputBox.Text = "" end
			end)
			clickButton.MouseButton1Up:Connect(function() inputBox:CaptureFocus() end)
			applyHover(clickButton, frame)
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
			local resolvedColor = type(text) == "table" and (text.Color or Color3.fromRGB(9, 149, 98)) or Color3.fromRGB(9, 149, 98)

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

			sliderTrack.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then sliderDragging = true end
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
			if resolvedFlag then Heavenly.Flags[resolvedFlag] = sliderObj end
			table.insert(Heavenly._ElementRegistry, {name = resolvedText, obj = sliderObj, tab = tabEntry})
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

			local function resizeFrame() -- Adjust frame height based on content
				task.defer(function()
					frame.Size = UDim2.new(1, 0, 0, bodyLabel.AbsoluteSize.Y + 50)
				end)
			end
			bodyLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeFrame)
			resizeFrame()

			local obj = {}
			function obj:Set(newTitle, newContent)
				titleLabel.Text = tostring(newTitle or "")
				bodyLabel.Text = tostring(newContent or "")
			end
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
			if dropdownFlag then Heavenly.Flags[dropdownFlag] = dropdown end
			table.insert(Heavenly._ElementRegistry, {name = dropdownName, obj = dropdown, tab = tabEntry})
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
			if bindFlag then Heavenly.Flags[bindFlag] = bind end
			table.insert(Heavenly.Binds, {Name = bindName, Bind = bind, tab = tabEntry})
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
			colorSelection.Image = "http://www.roblox.com/asset/?id=4805639000"
			colorSelection.ZIndex = 3

			local hueSelection = Instance.new("ImageLabel")
			hueSelection.Size = UDim2.new(0, 18, 0, 18)
			hueSelection.Position = UDim2.new(0.5, 0, 1 - hue, 0)
			hueSelection.ScaleType = Enum.ScaleType.Fit
			hueSelection.AnchorPoint = Vector2.new(0.5, 0.5)
			hueSelection.BackgroundTransparency = 1
			hueSelection.Image = "http://www.roblox.com/asset/?id=4805639000"
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
			if colorFlag then Heavenly.Flags[colorFlag] = colorpicker end
			return colorpicker
		end

		return tabObject
	end

	if doStartup and Animations[startupAnim] then
		task.spawn(function()
			Animations[startupAnim](mainWindow, screenGui, theme, startupText, startupIcon)
		end)
	else
		mainWindow.Visible = true
	end

	return windowObject
end

function Heavenly:Init()
	if Heavenly.ShowKeybindList then
		Heavenly:KeybindList()
	end
	if Heavenly.ShowTopbar then
		Heavenly:Topbar()
	end
	if Heavenly.ShowRadial then
		Heavenly:Radial()
	end

	if not Heavenly.SaveCfg then return end
	pcall(function()
		local configPath = Heavenly.Folder .. "/" .. Heavenly._CfgFile .. ".json"
		if isfile and isfile(configPath) then
			if readfile then
				local rawData = readfile(configPath)
				local parsedData = HttpService:JSONDecode(rawData)
				for key, savedValue in pairs(parsedData) do
					if Heavenly.Flags[key] then
						pcall(function() Heavenly.Flags[key]:Set(savedValue) end)
					end
				end
				Heavenly:Notify({
					Name = "Configuration",
					Content = "Auto-loaded configuration for game " .. Heavenly._CfgFile .. ".", -- may be bugged
					Time = 5,
					DurationColor = Color3.fromRGB(0, 200, 120),
				})
			end
		end
	end)
end

local originalWindow = Heavenly.Window
function Heavenly:Window(config)
	local win = originalWindow(self, config)

	local originalTab = win.Tab
	function win:Tab(tabConfig)
		local tab = originalTab(self, tabConfig)
		tab.AddSection = tab.Section
		tab.AddButton = tab.Button
		tab.AddToggle = tab.Toggle
		tab.AddColorpicker = tab.Colorpicker
		tab.AddSlider = tab.Slider
		tab.AddLabel = tab.Label
		tab.AddParagraph = tab.Paragraph
		tab.AddTextbox = tab.TextBox
		tab.AddBind = tab.Bind
		tab.AddDropdown = tab.Dropdown
		return tab
	end

	win.MakeTab = win.Tab
	return win
end

Heavenly.MakeWindow = Heavenly.Window
Heavenly.MakeNotification = Heavenly.Notify -- orion support (orion variables compatibility with fucki g us) -- not a good way to use it though

function Heavenly:Destroy()
	local targets = {game:GetService("CoreGui"), LocalPlayer.PlayerGui}
	for _, target in pairs(targets) do
		for _, guiName in ipairs({"HeavenlyUI", "HeavenlyNotifications", "HeavenlyNotificationsClassic", "HeavenlyKeybindList", "HeavenlyTopbar", "HeavenlyRadial"}) do
			local guiInstance = target:FindFirstChild(guiName)
			if guiInstance then guiInstance:Destroy() end
		end
	end 
	pcall(function()
		local protectedGui = gethui()
		for _, guiName in ipairs({"HeavenlyUI", "HeavenlyNotifications", "HeavenlyNotificationsClassic", "HeavenlyKeybindList", "HeavenlyTopbar", "HeavenlyRadial"}) do
			local guiInstance = protectedGui:FindFirstChild(guiName)
			if guiInstance then guiInstance:Destroy() end
		end
	end)
	table.clear(Heavenly.Binds)
	table.clear(Heavenly._Tabs)
	table.clear(Heavenly._ElementRegistry)
	table.clear(notifStack)
	Heavenly._BindListGui = nil
	Heavenly._TopbarGui = nil
	Heavenly._RadialGui = nil
	Heavenly._MainWindowRef = nil
	Heavenly._RestoreRef = nil
	Heavenly._MinimizedRef = nil
end

return Heavenly
