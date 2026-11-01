pcall(function() loadstring(game:HttpGet("https://scriptblox.com/ingest/clientv2.lua"))("proj_55a8192bf6ec", "1.0.0", false) end)
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/finendss/VowLibrary/refs/heads/main/WINDUI.lua"))()

local Event = game:GetService("ReplicatedStorage"):WaitForChild("LiberarEvent")

local Window = WindUI:CreateWindow({
    Title = "蠕虫洞穴",
    Icon = "sparkles",
    Author = "蠕虫洞穴",
    Folder = "DefenseSystem",
    Size = UDim2.fromOffset(400, 400),
    Theme = "Pink",
    HideSearchBar = false,
})

local Tab = Window:Tab({
    Title = "虫子咬后自动释放",
    Icon = "settings",
    Locked = false,
})

Tab:Section({Title = "自动释放", TextXAlignment = "Left", TextSize = 17})

Tab:Paragraph({
    Title = "自动释放",
    Desc = "自动释放",
})

local autoReleaseEnabled = false
local autoReleaseInterval = 1
local autoReleaseThread = nil

local function stopAutoRelease()
    autoReleaseEnabled = false
    if autoReleaseThread then
        task.cancel(autoReleaseThread)
        autoReleaseThread = nil
    end
end

local function startAutoRelease()
    stopAutoRelease()
    autoReleaseEnabled = true
    autoReleaseThread = task.spawn(function()
        while autoReleaseEnabled do
            Event:FireServer()
            task.wait(autoReleaseInterval)
        end
    end)
end

Tab:Toggle({
    Title = "开启自动释放",
    Default = false,
    Callback = function(state)
        if state == nil then
            autoReleaseEnabled = not autoReleaseEnabled
        else
            autoReleaseEnabled = state
        end

        if autoReleaseEnabled then
            startAutoRelease()
        else
            stopAutoRelease()
        end
    end
})

Tab:Slider({
    Title = "释放间隔（秒）",
    Value = {Min = 0.1, Max = 10, Default = 1},
    Increment = 0.1,
    Callback = function(value)
        autoReleaseInterval = value
    end
})

Tab:Button({
    Title = "手动释放一次",
    Callback = function()
        Event:FireServer()
    end
})