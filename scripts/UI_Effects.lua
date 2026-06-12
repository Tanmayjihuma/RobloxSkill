--OK LISSION THIS CODE IS JUST EXAMPLE Of EFFECTS 
-- WE MOSTLY NOT CREATE UI USING SCRIPTS 
-- THIE IS FOR COMMAND PANNEL SCRIPTS

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local UIManager = {}
UIManager.__index = UIManager

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Animation presets
local ANIMATION_PRESETS = {
    fadeIn = {
        duration = 0.3,
        properties = {BackgroundTransparency = 0, TextTransparency = 0},
        easingStyle = Enum.EasingStyle.Quad,
        easingDirection = Enum.EasingDirection.Out
    },
    fadeOut = {
        duration = 0.3,
        properties = {BackgroundTransparency = 1, TextTransparency = 1},
        easingStyle = Enum.EasingStyle.Quad,
        easingDirection = Enum.EasingDirection.Out
    },
    slideUp = {
        duration = 0.4,
        properties = {Position = UDim2.fromScale(0.5, 0.5)},
        easingStyle = Enum.EasingStyle.Back,
        easingDirection = Enum.EasingDirection.Out,
        startPosition = UDim2.fromScale(0.5, 1.2)
    },
    slideDown = {
        duration = 0.4,
        properties = {Position = UDim2.fromScale(0.5, 1.2)},
        easingStyle = Enum.EasingStyle.Back,
        easingDirection = Enum.EasingDirection.In
    },
    scaleIn = {
        duration = 0.3,
        properties = {Size = UDim2.fromScale(1, 1)},
        easingStyle = Enum.EasingStyle.Back,
        easingDirection = Enum.EasingDirection.Out,
        startSize = UDim2.fromScale(0, 0)
    },
    scaleOut = {
        duration = 0.2,
        properties = {Size = UDim2.fromScale(0, 0)},
        easingStyle = Enum.EasingStyle.Back,
        easingDirection = Enum.EasingDirection.In
    }
}

-- Color themes
local THEMES = {
    dark = {
        background = Color3.fromRGB(25, 25, 25),
        surface = Color3.fromRGB(35, 35, 35),
        primary = Color3.fromRGB(100, 150, 255),
        secondary = Color3.fromRGB(150, 100, 255),
        text = Color3.fromRGB(255, 255, 255),
        textSecondary = Color3.fromRGB(200, 200, 200),
        accent = Color3.fromRGB(255, 100, 100)
    },
    light = {
        background = Color3.fromRGB(245, 245, 245),
        surface = Color3.fromRGB(255, 255, 255),
        primary = Color3.fromRGB(25, 100, 255),
        secondary = Color3.fromRGB(100, 25, 255),
        text = Color3.fromRGB(25, 25, 25),
        textSecondary = Color3.fromRGB(75, 75, 75),
        accent = Color3.fromRGB(255, 50, 50)
    }
}

local currentTheme = "dark"
local activeScreens = {}
local notifications = {}

function UIManager:SetTheme(themeName)
    if THEMES[themeName] then
        currentTheme = themeName
        self:RefreshAllScreens()
    end
end

function UIManager:GetTheme()
    return THEMES[currentTheme]
end



function UIManager:ShowScreen(name, animation)
    local screen = activeScreens[name]
    if not screen then return end
    
    screen.screenGui.Enabled = true
    
    if animation then
        self:AnimateElement(screen.frame, animation)
    end
end

function UIManager:HideScreen(name, animation, callback)
    local screen = activeScreens[name]
    if not screen then return end
    
    if animation then
        self:AnimateElement(screen.frame, animation, function()
            screen.screenGui.Enabled = false
            if callback then callback() end
        end)
    else
        screen.screenGui.Enabled = false
        if callback then callback() end
    end
end


function UIManager:ShowNotification(text, duration, notificationType)
    duration = duration or 3
    notificationType = notificationType or "info"
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.fromOffset(400, 80)
    notification.Position = UDim2.new(1, -20, 0, 20 + (#notifications * 90))
    notification.AnchorPoint = Vector2.new(1, 0)
    notification.BackgroundColor3 = self:GetTheme().surface
    notification.BorderSizePixel = 0
    notification.Parent = playerGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notification
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.Position = UDim2.fromScale(0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = self:GetTheme().text
    label.TextSize = 16
    label.Font = Enum.Font.SourceSans
    label.TextWrapped = true
    label.Parent = notification
    
    table.insert(notifications, notification)
    
    -- Slide in animation
    self:AnimateElement(notification, "slideIn", function()
        wait(duration)
        -- Slide out animation
        self:AnimateElement(notification, "slideOut", function()
            notification:Destroy()
            -- Remove from notifications list
            for i, notif in ipairs(notifications) do
                if notif == notification then
                    table.remove(notifications, i)
                    break
                end
            end
            -- Reposition remaining notifications
            self:RepositionNotifications()
        end)
    end)
end

function UIManager:RepositionNotifications()
    for i, notification in ipairs(notifications) do
        TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Position = UDim2.new(1, -20, 0, 20 + ((i-1) * 90))
        }):Play()
    end
end

function UIManager:AnimateElement(element, animation, callback)
    if type(animation) == "string" then
        animation = ANIMATION_PRESETS[animation]
    end
    
    if not animation then return end
    
    -- Set starting properties if specified
    if animation.startPosition then
        element.Position = animation.startPosition
    end
    if animation.startSize then
        element.Size = animation.startSize
    end
    
    local tween = TweenService:Create(
        element,
        TweenInfo.new(
            animation.duration,
            animation.easingStyle,
            animation.easingDirection
        ),
        animation.properties
    )
    
    if callback then
        tween.Completed:Connect(callback)
    end
    
    tween:Play()
    return tween
end


function UIManager:RefreshAllScreens()
    -- Refresh theme for all active screens
    for name, screen in pairs(activeScreens) do
        if screen.config.backgroundColor then
            screen.frame.BackgroundColor3 = self:GetTheme().background
        end
    end
end

return UIManager
