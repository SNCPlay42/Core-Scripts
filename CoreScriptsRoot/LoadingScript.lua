-- Creates the generic "ROBLOX" loading screen on startup
-- Written by ArceusInator & Ben Tkacheff, 2014
--

-- Constants
local PLACEID = Game.PlaceId

local MPS = Game:GetService 'MarketplaceService'
local UIS = Game:GetService 'UserInputService'
local CP = Game:GetService 'ContentProvider'

local startTime = tick()

local COLORS = {
	BLACK = Color3.new(0, 0, 0),
	BACKGROUND_COLOR = Color3.new(45/255, 45/255, 45/255),
	WHITE = Color3.new(1, 1, 1),
	ERROR = Color3.new(253/255,68/255,72/255)
}

local function getViewportSize()
	while not game.Workspace.CurrentCamera do
		game.Workspace.Changed:wait()
	end

	while game.Workspace.CurrentCamera.ViewportSize == Vector2.new(0,0) do
		game.Workspace.CurrentCamera.Changed:wait()
	end

	return game.Workspace.CurrentCamera.ViewportSize
end

--
-- Variables
local GameAssetInfo -- loaded by InfoProvider:LoadAssets()
local currScreenGui = nil
local renderSteppedConnection = nil
local fadingBackground = false
local destroyingBackground = false
local destroyedLoadingGui = false
local hasReplicatedFirstElements = false
local backgroundImageTransparency = 0
local isMobile = (UIS.TouchEnabled == true and UIS.MouseEnabled == false and getViewportSize().Y <= 500)
local isTenFootInterface = nil

spawn(function()
	while not Game:GetService("CoreGui") do
		wait()
	end
	local RobloxGui = Game:GetService("CoreGui"):WaitForChild("RobloxGui")
	isTenFootInterface = require(RobloxGui:WaitForChild("Modules"):WaitForChild("TenFootInterface")):IsEnabled()
end)

-- Fast Flags
local topbarSuccess, topbarFlagValue = pcall(function() return settings():GetFFlag("UseInGameTopBar") end)
local useTopBar = (topbarSuccess and topbarFlagValue == true)
local bgFrameOffset = useTopBar and 36 or 20
local offsetPosition = useTopBar and UDim2.new(0, 0, 0, -36) or UDim2.new(0, 0, 0, 0)

--
-- Utility functions
local create = function(className, defaultParent)
	return function(propertyList)
		local object = Instance.new(className)

		for index, value in next, propertyList do
			if type(index) == 'string' then
				object[index] = value
			else
				if type(value) == 'function' then
					value(object)
				elseif type(value) == 'userdata' then
					value.Parent = object
				end
			end
		end

		if object.Parent == nil then
			object.Parent = defaultParent
		end

		return object
	end
end

--
-- Create objects

local MainGui = {}
local InfoProvider = {}


function InfoProvider:GetGameName()
	if GameAssetInfo ~= nil then
		return GameAssetInfo.Name
	else
		return ''
	end
end

function InfoProvider:GetCreatorName()
	if GameAssetInfo ~= nil then
		return GameAssetInfo.Creator.Name
	else
		return ''
	end
end

function InfoProvider:LoadAssets()
	Spawn(function() 
		if PLACEID <= 0 then
			while Game.PlaceId <= 0 do
				wait()
			end
			PLACEID = Game.PlaceId
		end

		-- load game asset info
		coroutine.resume(coroutine.create(function()
			local success, result = pcall(function()
				GameAssetInfo = MPS:GetProductInfo(PLACEID)
			end)
			if not success then
				print("LoadingScript->InfoProvider:LoadAssets:", result)
			end
		end))
	end)
end

function MainGui:tileBackgroundTexture(frameToFill)
	if not frameToFill then return end
	frameToFill:ClearAllChildren()
	if backgroundImageTransparency < 1 then
		local backgroundTextureSize = Vector2.new(512, 512)
		for i = 0, math.ceil(frameToFill.AbsoluteSize.X/backgroundTextureSize.X) do
			for j = 0, math.ceil(frameToFill.AbsoluteSize.Y/backgroundTextureSize.Y) do
				create 'ImageLabel' {
					Name = 'BackgroundTextureImage',
					BackgroundTransparency = 1,
					ImageTransparency = backgroundImageTransparency,
					Image = 'rbxasset://textures/loading/darkLoadingTexture.png',
					Position = UDim2.new(0, i*backgroundTextureSize.X, 0, j*backgroundTextureSize.Y),
					Size = UDim2.new(0, backgroundTextureSize.X, 0, backgroundTextureSize.Y),
					ZIndex = 1,
					Parent = frameToFill
				}
			end
		end
	end
end

--
-- Declare member functions
function MainGui:GenerateMain()
	local screenGui = create 'ScreenGui' {
		Name = 'RobloxLoadingGui'
	}
	
	--
	-- create descendant frames
	local mainBackgroundContainer = create 'Frame' {
		Name = 'BlackFrame',
		BackgroundColor3 = COLORS.BACKGROUND_COLOR,
		BackgroundTransparency = 0,
		Size = UDim2.new(1, 0, 1, bgFrameOffset),
		Position = offsetPosition,
		Active = true,

		create 'ImageButton' {
				Name = 'CloseButton',
				Image = 'rbxasset://textures/loading/cancelButton.png',
				ImageTransparency = 1,
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -37, 0, 5 + bgFrameOffset),
				Size = UDim2.new(0, 32, 0, 32),
				Active = false,
				ZIndex = 10
		},
		
		create 'Frame' {
			Name = 'GraphicsFrame',
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, (isMobile == true and -65 or -225), 1, (isMobile == true and -65 or -165)),
			Size = UDim2.new(0, (isMobile == true and 60 or 120), 0, (isMobile == true and 60 or 120)),
			ZIndex = 2,

			create 'ImageLabel' {
				Name = 'LoadingImage',
				BackgroundTransparency = 1,
				Image = 'rbxasset://textures/loading/loadingCircle.png',
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 1, 0),
				ZIndex = 2
			},

			create 'TextLabel' {
				Name = 'LoadingText',
				BackgroundTransparency = 1,
				Size = UDim2.new(1, (isMobile == true and -14 or -56), 1, 0),
				Position = UDim2.new(0, (isMobile == true and 7 or 28), 0, 0),
				Font = Enum.Font.SourceSans,
				FontSize = (isMobile == true and Enum.FontSize.Size12 or Enum.FontSize.Size18),
				TextWrapped = true,
				TextColor3 = COLORS.WHITE,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = "Loading...",
				ZIndex = 2
			},
		},
		
		create 'Frame' {
			Name = 'UiMessageFrame',
			BackgroundTransparency = 1,
			Position = UDim2.new(0.25, 0, 1, -120),
			Size = UDim2.new(0.5, 0, 0, 80),
			ZIndex = 2,

			create 'TextLabel' {
				Name = 'UiMessage',
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Font = Enum.Font.SourceSansBold,
				FontSize = Enum.FontSize.Size18,
				TextWrapped = true,
				TextColor3 = COLORS.WHITE,
				Text = "",
				ZIndex = 2
			},
		},
		
		create 'Frame' {
			Name = 'InfoFrame',
			BackgroundTransparency = 1,
			Position = UDim2.new(0, (isMobile == true and 20 or 100), 1, (isMobile == true and -120 or -150)),
			Size = UDim2.new(0.4, 0, 0, 110),
			ZIndex = 2,

			create 'TextLabel' {
				Name = 'PlaceLabel',
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 80),
				Position = UDim2.new(0, 0, 0, 0),
				Font = Enum.Font.SourceSans,
				FontSize = Enum.FontSize.Size24,
				TextWrapped = true,
				TextScaled = true,
				TextColor3 = COLORS.WHITE,
				TextStrokeTransparency = 0,
				Text = "",
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Bottom,
				ZIndex = 2
			},

			create 'TextLabel' {
				Name = 'CreatorLabel',
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 30),
				Position = UDim2.new(0, 0, 0, 80),
				Font = Enum.Font.SourceSans,
				FontSize = Enum.FontSize.Size18,
				TextWrapped = true,
				TextScaled = true,
				TextColor3 = COLORS.WHITE,
				TextStrokeTransparency = 0,
				Text = "",
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				ZIndex = 2
			},
		},
		
		create 'Frame' {
			Name = 'BackgroundTextureFrame',
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, bgFrameOffset), 
			Position = offsetPosition,
			ClipsDescendants = true,
			ZIndex = 1,
			BackgroundTransparency = 1,
		},
		
		Parent = screenGui
	}

	create 'Frame' {
			Name = 'ErrorFrame',
			BackgroundColor3 = COLORS.ERROR,
			BorderSizePixel = 0,
			Position = UDim2.new(0.25,0,0,0),
			Size = UDim2.new(0.5, 0, 0, 80),
			ZIndex = 8,
			Visible = false,

			create 'TextLabel' {
				Name = "ErrorText",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Font = Enum.Font.SourceSansBold,
				FontSize = Enum.FontSize.Size14,
				TextWrapped = true,
				TextColor3 = COLORS.WHITE,
				Text = "",
				ZIndex = 8
			},

		Parent = screenGui
	}

	while not Game:GetService("CoreGui") do
		wait()
	end
	screenGui.Parent = Game:GetService("CoreGui")
	currScreenGui = screenGui
end

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

---------------------------------------------------------
-- Main Script (show something now + setup connections)

-- start loading assets asap
InfoProvider:LoadAssets()
MainGui:GenerateMain()

local guiService = Game:GetService("GuiService")

local removedLoadingScreen = false
local setVerb = true
local lastRenderTime = nil
local fadeCycleTime = 1.7
local turnCycleTime = 2
local lastAbsoluteSize = Vector2.new(0, 0)
local loadingDots = "..."
local lastDotUpdateTime = nil
local dotChangeTime = .2
local brickCountChange = nil
local lastBrickCount = 0

renderSteppedConnection = Game:GetService("RunService").RenderStepped:connect(function()
	if not currScreenGui then return end
	if not currScreenGui:FindFirstChild("BlackFrame") then return end

	if setVerb then
		currScreenGui.BlackFrame.CloseButton:SetVerb("Exit")
		setVerb = false
	end
	
	if currScreenGui.BlackFrame:FindFirstChild("BackgroundTextureFrame") and currScreenGui.BlackFrame.BackgroundTextureFrame.AbsoluteSize ~= lastAbsoluteSize then
		lastAbsoluteSize = currScreenGui.BlackFrame.BackgroundTextureFrame.AbsoluteSize
		MainGui:tileBackgroundTexture(currScreenGui.BlackFrame.BackgroundTextureFrame)
	end 

	if currScreenGui.BlackFrame.InfoFrame.PlaceLabel.Text == "" then
		currScreenGui.BlackFrame.InfoFrame.PlaceLabel.Text = InfoProvider:GetGameName()
	end

	if currScreenGui.BlackFrame.InfoFrame.CreatorLabel.Text == "" then
		local creatorName = InfoProvider:GetCreatorName()
		if creatorName ~= "" then
			currScreenGui.BlackFrame.InfoFrame.CreatorLabel.Text = "By " .. creatorName
		end
	end

	if not lastRenderTime then
		lastRenderTime = tick()
		lastDotUpdateTime = lastRenderTime
		return
	end

	local currentTime = tick()
	local fadeAmount = (currentTime - lastRenderTime) * fadeCycleTime
	local turnAmount = (currentTime - lastRenderTime) * (360/turnCycleTime)
	lastRenderTime = currentTime

	currScreenGui.BlackFrame.GraphicsFrame.LoadingImage.Rotation = currScreenGui.BlackFrame.GraphicsFrame.LoadingImage.Rotation + turnAmount
	
	local updateLoadingDots =  function()
		loadingDots = loadingDots.. "."
		if loadingDots == "...." then
			loadingDots = ""
		end
		currScreenGui.BlackFrame.GraphicsFrame.LoadingText.Text = "Loading" ..loadingDots
	end
	
	if currentTime - lastDotUpdateTime >= dotChangeTime and InfoProvider:GetCreatorName() == "" then
		lastDotUpdateTime = currentTime
		updateLoadingDots()
	else
		if guiService:GetBrickCount() > 0 then  
			if brickCountChange == nil then
				brickCountChange = guiService:GetBrickCount()
			end
			if guiService:GetBrickCount() - lastBrickCount >= brickCountChange then
				lastBrickCount = guiService:GetBrickCount()
				updateLoadingDots()
			end
		end
	end
	
	-- fade in close button after 5 seconds unless we are running on a console
	if  not isTenFootInterface then
		if currentTime - startTime > 5 and currScreenGui.BlackFrame.CloseButton.ImageTransparency > 0 then
			currScreenGui.BlackFrame.CloseButton.ImageTransparency = currScreenGui.BlackFrame.CloseButton.ImageTransparency - fadeAmount

			if currScreenGui.BlackFrame.CloseButton.ImageTransparency <= 0 then
				currScreenGui.BlackFrame.CloseButton.Active = true
			end
		end
	end
end)

local leaveGameButton, leaveGameTextLabel, errorImage = nil

guiService.ErrorMessageChanged:connect(function()
	if guiService:GetErrorMessage() ~= '' then
		if isTenFootInterface then 
			currScreenGui.ErrorFrame.Size = UDim2.new(1, 0, 0, 144)
			currScreenGui.ErrorFrame.Position = UDim2.new(0, 0, 0, 0)
			currScreenGui.ErrorFrame.BackgroundColor3 = COLORS.BLACK
			currScreenGui.ErrorFrame.BackgroundTransparency = 0.5
			currScreenGui.ErrorFrame.ErrorText.FontSize = Enum.FontSize.Size36 
			currScreenGui.ErrorFrame.ErrorText.Position = UDim2.new(.3, 0, 0, 0) 
			currScreenGui.ErrorFrame.ErrorText.Size = UDim2.new(.4, 0, 0, 144)
			if errorImage == nil then
				errorImage = Instance.new("ImageLabel")
				errorImage.Image = "rbxasset://textures/ui/ErrorIconSmall.png"
				errorImage.Size = UDim2.new(0, 96, 0, 79)
				errorImage.Position = UDim2.new(0.228125, 0, 0, 32)
				errorImage.ZIndex = 9
				errorImage.BackgroundTransparency = 1
				errorImage.Parent = currScreenGui.ErrorFrame
			end
			if leaveGameButton == nil then
				local RobloxGui = Game:GetService("CoreGui"):WaitForChild("RobloxGui")
				local utility = require(RobloxGui.Modules.Settings.Utility)
				local textLabel = nil
				leaveGameButton, leaveGameTextLabel = utility:MakeStyledButton("LeaveGame", "Leave", UDim2.new(0, 288, 0, 78))
				leaveGameButton:SetVerb("Exit")
				leaveGameButton.NextSelectionDown = nil
				leaveGameButton.NextSelectionLeft = nil
				leaveGameButton.NextSelectionRight = nil 
				leaveGameButton.NextSelectionUp = nil
				leaveGameButton.ZIndex = 9
				leaveGameButton.Position = UDim2.new(0.771875, 0, 0, 37)
				leaveGameButton.Parent = currScreenGui.ErrorFrame
				leaveGameTextLabel.FontSize = Enum.FontSize.Size36 
				leaveGameTextLabel.ZIndex = 10
				game:GetService("GuiService").SelectedCoreObject = leaveGameButton
			else
				game:GetService("GuiService").SelectedCoreObject = leaveGameButton
			end
		end 
		currScreenGui.ErrorFrame.ErrorText.Text = guiService:GetErrorMessage()
		currScreenGui.ErrorFrame.Visible = true
		local blackFrame = currScreenGui:FindFirstChild('BlackFrame')
		if blackFrame then
			blackFrame.CloseButton.ImageTransparency = 0
			blackFrame.CloseButton.Active = true
		end
	else
		currScreenGui.ErrorFrame.Visible = false
	end
end)

guiService.UiMessageChanged:connect(function(type, newMessage)
	if type == Enum.UiMessageType.UiMessageInfo then
		local blackFrame = currScreenGui and currScreenGui:FindFirstChild('BlackFrame')
		if blackFrame then
			blackFrame.UiMessageFrame.UiMessage.Text = newMessage
			if newMessage ~= '' then
				blackFrame.UiMessageFrame.Visible = true
			else
				blackFrame.UiMessageFrame.Visible = false
			end
		end
	end
end)

if guiService:GetErrorMessage() ~= '' then
	currScreenGui.ErrorFrame.ErrorText.Text = guiService:GetErrorMessage()
	currScreenGui.ErrorFrame.Visible = true
end


function stopListeningToRenderingStep()
	if renderSteppedConnection then
		renderSteppedConnection:disconnect()
		renderSteppedConnection = nil
	end
end

function fadeBackground()
	if not currScreenGui then return end
	if fadingBackground then return end
	
	if not currScreenGui:findFirstChild("BlackFrame") then return end

	fadingBackground = true

	local lastTime = nil
	local backgroundRemovalTime = 3.2

	while currScreenGui and currScreenGui:FindFirstChild("BlackFrame") and currScreenGui.BlackFrame:FindFirstChild("BackgroundTextureFrame") and backgroundImageTransparency < 1 do
		if lastTime == nil then
			currScreenGui.BlackFrame.Active = false
			
			if currScreenGui.BlackFrame:FindFirstChild("CloseButton") then
				currScreenGui.BlackFrame.CloseButton.Visible = false
				currScreenGui.BlackFrame.CloseButton.Active = false
			end
			lastTime = tick()
		else
			local currentTime = tick()
			local fadeAmount = (currentTime - lastTime) * backgroundRemovalTime
			lastTime = currentTime
			
			backgroundImageTransparency = backgroundImageTransparency + fadeAmount
			currScreenGui.BlackFrame.BackgroundTransparency = backgroundImageTransparency
			local backgroundImages = currScreenGui.BlackFrame.BackgroundTextureFrame:GetChildren()
			for i = 1, #backgroundImages do
				backgroundImages[i].ImageTransparency = backgroundImageTransparency
			end
			
		end

		wait()
	end
end

function fadeAndDestroyBlackFrame(blackFrame)
	if destroyingBackground then return end
	destroyingBackground = true
	Spawn(function()
		local infoFrame = blackFrame:FindFirstChild("InfoFrame")
		local graphicsFrame = blackFrame:FindFirstChild("GraphicsFrame")

		local textChildren = infoFrame:GetChildren()
		local transparency = 0
		local rateChange = 1.8
		local lastUpdateTime = nil

		while transparency < 1 do
			if not lastUpdateTime then
				lastUpdateTime = tick()
			else
				local newTime = tick()
				transparency = transparency + rateChange * (newTime - lastUpdateTime)
				for i =1, #textChildren do
					textChildren[i].TextTransparency = transparency
					textChildren[i].TextStrokeTransparency = transparency
				end
				graphicsFrame.LoadingImage.ImageTransparency = transparency
				blackFrame.BackgroundTransparency = transparency
				
				if backgroundImageTransparency < 1 then
					backgroundImageTransparency = transparency
					local backgroundImages = blackFrame.BackgroundTextureFrame:GetChildren()
					for i = 1, #backgroundImages do
						backgroundImages[i].ImageTransparency = backgroundImageTransparency
					end
				end

				lastUpdateTime = newTime
			end
			wait()
		end
		if blackFrame ~= nil then
			blackFrame:Destroy()
		end
	end)
end

function destroyLoadingElements()
	if not currScreenGui then return end
	if destroyedLoadingGui then return end
	destroyedLoadingGui = true
	
	local guiChildren = currScreenGui:GetChildren()
	for i=1, #guiChildren do
		-- need to keep this around in case we get a connection error later
		if guiChildren[i].Name ~= "ErrorFrame" then
			if guiChildren[i].Name == "BlackFrame" then
				fadeAndDestroyBlackFrame(guiChildren[i])
			else
				guiChildren[i]:Destroy()
			end
		end
	end
end

function handleFinishedReplicating()
	hasReplicatedFirstElements = (#Game:GetService("ReplicatedFirst"):GetChildren() > 0)
	if not hasReplicatedFirstElements then
		fadeBackground()
	else
		wait(20) -- make sure after 20 seconds we remove the default gui, even if the user doesn't
		handleRemoveDefaultLoadingGui()
	end
end

function handleRemoveDefaultLoadingGui()
	destroyLoadingElements()
end

function handleGameLoaded()
	if not hasReplicatedFirstElements then
		destroyLoadingElements()
	end
end

Game:GetService("ReplicatedFirst").FinishedReplicating:connect(handleFinishedReplicating)
if Game:GetService("ReplicatedFirst"):IsFinishedReplicating() then
	handleFinishedReplicating()
end

Game:GetService("ReplicatedFirst").RemoveDefaultLoadingGuiSignal:connect(handleRemoveDefaultLoadingGui)
if Game:GetService("ReplicatedFirst"):IsDefaultLoadingGuiRemoved() then
	handleRemoveDefaultLoadingGui()
	return
end

Game.Loaded:connect(handleGameLoaded)
if Game:IsLoaded() then
	handleGameLoaded()
end
