local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/finendss/VowLibrary/refs/heads/main/WINDUI.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Window = WindUI:CreateWindow({
    Title = "No Safety Needed",
    Icon = "sparkles",
    Author = "No Safety Needed",
    Folder = "NoSafetyNeeded",
    Size = UDim2.fromOffset(420, 420),
    Theme = "Pink",
    HideSearchBar = false,
})

Window:Tag({
    Title = "No Safety Needed",
    Color = Color3.fromHex("#7FDBFF")
})

Window:EditOpenButton({
    Title = "No Safety Needed",
    Icon = "monitor",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF6B6B")),
    Draggable = true,
})

local Tab = Window:Tab({
    Title = "自动刷钱/经验",
    Icon = "settings",
    Locked = false,
})

Tab:Section({ Title = "功能", TextXAlignment = "Left", TextSize = 17 })

Tab:Paragraph({
    Title = "自动刷钱/经验说明",
    Desc = "使用前请在服务器内设置里开启禁用建造者身份来保持游戏环境(否则无法使用)",
})

getgenv().BobuxAutoFarm = false
getgenv().BobuxFarmRunning = false
getgenv().BobuxLock = false
getgenv().BobuxLockRunning = false
getgenv().BobuxSuccessCount = 0
getgenv().SafeFly = false
getgenv().SafeFlyRunning = false
getgenv().OldTeleport = false

local TARGET_ASSET_ID = "130396712201457"

local KEY_CODE = "FSNB666"
getgenv().BobuxKeyUnlocked = false

local startFlight, stopFlight

if _G.NoClipStepped and _G.NoClipStepped.Connected then
    _G.NoClipStepped:Disconnect()
    _G.NoClipStepped = nil
end
if _G.NoClipHeartbeat and _G.NoClipHeartbeat.Connected then
    _G.NoClipHeartbeat:Disconnect()
    _G.NoClipHeartbeat = nil
end
if getgenv().BobuxFlightConn and getgenv().BobuxFlightConn.Connected then
    getgenv().BobuxFlightConn:Disconnect()
end
if getgenv().BobuxSafeFlyConn and getgenv().BobuxSafeFlyConn.Connected then
    getgenv().BobuxSafeFlyConn:Disconnect()
end

local safeFlyConnection = nil

local function startSafeFly()
    if safeFlyConnection then safeFlyConnection:Disconnect() end
    safeFlyConnection = RunService.Stepped:Connect(function()
        local char = player.Character
        if char and char.Parent then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if getgenv().SafeFly then
                        part.Transparency = 1
                    else
                        part.Transparency = 0
                    end
                end
            end
        end
    end)
    getgenv().BobuxSafeFlyConn = safeFlyConnection
end

startSafeFly()

local function setupCharacter(char)
    task.wait(0.5)
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            stopFlight()
        end)
    end
    if getgenv().BobuxAutoFarm and not getgenv().OldTeleport then
        task.wait(0.5)
        startFlight()
    end
end

if player.Character then
    task.spawn(function() setupCharacter(player.Character) end)
end
player.CharacterAdded:Connect(function(char)
    task.spawn(function() setupCharacter(char) end)
end)

local function getHRP()
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getMapFolder()
    local map = workspace:FindFirstChild("map")
    if not map then
        for _, v in ipairs(workspace:GetChildren()) do
            if v:IsA("Folder") and v.Name:lower() == "map" then
                return v
            end
        end
    end
    return map
end

local function getInstancePosition(instance)
    if not instance then return nil end
    if instance:IsA("BasePart") then
        return instance.Position
    end
    if instance:IsA("Model") then
        if instance.PrimaryPart then
            return instance.PrimaryPart.Position
        end
        local hrp = instance:FindFirstChild("HumanoidRootPart", true)
        if hrp then return hrp.Position end
        local part = instance:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.Position end
    end
    local part = instance:FindFirstChildWhichIsA("BasePart", true)
    if part then return part.Position end
    return nil
end

getgenv().BobuxFlightSpeed = 35
getgenv().BobuxIsFlying = false
getgenv().BobuxAutoTarget = nil
local flightConnection = nil

startFlight = function()
    if getgenv().BobuxIsFlying then return end
    getgenv().BobuxIsFlying = true
    local char = player.Character
    local humanoid = char and char:FindFirstChild("Humanoid")
    if humanoid then humanoid.PlatformStand = true end

    flightConnection = RunService.RenderStepped:Connect(function()
        local hrp = getHRP()
        if not hrp or not hrp.Parent then return end
        local target = getgenv().BobuxAutoTarget
        if target then
            local dir = target - hrp.Position
            if dir.Magnitude > 0 then
                hrp.Velocity = dir.Unit * (getgenv().BobuxFlightSpeed or 35)
            end
        else
            hrp.Velocity = Vector3.zero
        end
        hrp.RotVelocity = Vector3.zero
    end)
    getgenv().BobuxFlightConn = flightConnection
end

stopFlight = function()
    if not getgenv().BobuxIsFlying then return end
    getgenv().BobuxIsFlying = false
    if flightConnection then flightConnection:Disconnect() end
    flightConnection = nil
    local char = player.Character
    local humanoid = char and char:FindFirstChild("Humanoid")
    if humanoid then humanoid.PlatformStand = false end
    local hrp = getHRP()
    if hrp then hrp.Velocity = Vector3.zero end
    getgenv().BobuxAutoTarget = nil
end

local function findInMap(name)
    local map = getMapFolder()
    if not map then return nil end
    return map:FindFirstChild(name, true)
end

local function hasAttachBobux()
    local char = player.Character
    if not char then return false end
    return char:FindFirstChild("attachbobux", true) ~= nil
end

local function getLockBox()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local current = pg
    for _, name in ipairs({"settings", "Frame", "main", "scroll", "stopbuilder", "bool", "box"}) do
        current = current:FindFirstChild(name)
        if not current then return nil end
    end
    return current
end

local function checkUnlockCondition()
    local box = getLockBox()
    if not box then return false end

    local img = box.Image
    if type(img) == "string" and img:find(TARGET_ASSET_ID) then
        return true
    end

    local ok, ic = pcall(function() return box.ImageContent end)
    if ok and ic then
        local s = tostring(ic)
        if s and s:find(TARGET_ASSET_ID) then
            return true
        end
        local ok2, uri = pcall(function() return ic.Uri end)
        if ok2 and type(uri) == "string" and uri:find(TARGET_ASSET_ID) then
            return true
        end
    end

    return false
end

local function startLockLoop()
    if getgenv().BobuxLockRunning then return end
    getgenv().BobuxLockRunning = true

    local notifiedDisabled = false
    local notifiedEnabled = false

    task.spawn(function()
        while getgenv().BobuxAutoFarm do
            if not getgenv().BobuxKeyUnlocked then
                if checkUnlockCondition() then
                    getgenv().BobuxLock = false
                    if not notifiedEnabled then
                        WindUI:Notify({
                            Title = "已解锁",
                            Content = "检测到禁用建筑者身份已开启,自动刷钱/经验开始传送",
                            Duration = 4
                        })
                        notifiedEnabled = true
                        notifiedDisabled = false
                    end
                else
                    getgenv().BobuxLock = true
                    if not notifiedDisabled then
                        WindUI:Notify({
                            Title = "已锁定",
                            Content = "检测到禁用建筑者身份未开启,请前往设置开启后使用",
                            Duration = 4
                        })
                        notifiedDisabled = true
                        notifiedEnabled = false
                    end
                end
            end
            task.wait(0.001)
        end
        getgenv().BobuxLockRunning = false
    end)
end

local function startFarmLoop()
    if getgenv().BobuxFarmRunning then return end
    getgenv().BobuxFarmRunning = true

    task.spawn(function()
        while getgenv().BobuxAutoFarm do
            task.wait(0.001)

            if getgenv().BobuxLock and not getgenv().BobuxKeyUnlocked then
                getgenv().BobuxAutoTarget = nil
                continue
            end

            if hasAttachBobux() then
                local exitInst = findInMap("exit")
                if exitInst then
                    local pos = getInstancePosition(exitInst)
                    if pos then
                        if getgenv().OldTeleport then
                            local hrp = getHRP()
                            if hrp then
                                hrp.CFrame = CFrame.new(pos)
                                getgenv().BobuxSuccessCount = getgenv().BobuxSuccessCount + 1
                            end
                        else
                            getgenv().BobuxAutoTarget = pos
                            local hrp = getHRP()
                            if hrp and (hrp.Position - pos).Magnitude < 3 then
                                getgenv().BobuxSuccessCount = getgenv().BobuxSuccessCount + 1
                            end
                        end
                    end
                else
                    getgenv().BobuxAutoTarget = nil
                end
            else
                local bobuxInst = findInMap("bobux")
                if bobuxInst then
                    local pos = getInstancePosition(bobuxInst)
                    if pos then
                        if getgenv().OldTeleport then
                            local hrp = getHRP()
                            if hrp then
                                hrp.CFrame = CFrame.new(pos)
                            end
                        else
                            getgenv().BobuxAutoTarget = pos
                        end
                    end
                else
                    getgenv().BobuxAutoTarget = nil
                end
            end
        end
        getgenv().BobuxAutoTarget = nil
        getgenv().BobuxFarmRunning = false
    end)
end

Tab:Toggle({
    Title = "自动刷钱/经验",
    Default = false,
    Callback = function(Value)
        getgenv().BobuxAutoFarm = Value
        if Value then
            if not getgenv().BobuxKeyUnlocked then
                if checkUnlockCondition() then
                    getgenv().BobuxLock = false
                else
                    getgenv().BobuxLock = true
                end
            end
            startLockLoop()
            WindUI:Notify({
                Title = "已开启",
                Content = "自动刷钱/经验已锁定,请开启禁用建筑者身份后才可以使用",
                Duration = 4
            })
            if not getgenv().OldTeleport then
                startFlight()
            end
            startFarmLoop()
        else
            getgenv().BobuxAutoFarm = false
            getgenv().BobuxLock = true
            stopFlight()
            WindUI:Notify({
                Title = "已关闭",
                Content = "自动刷钱/经验已停止",
                Duration = 3
            })
        end
    end
})

Tab:Toggle({
    Title = "隐身(没啥用)",
    Default = false,
    Callback = function(Value)
        getgenv().SafeFly = Value
    end
})

Tab:Toggle({
    Title = "穿墙",
    Desc = "启用/禁用穿墙功能",
    Type = "Toggle",
    Default = false,
    Callback = function(state) 
        local player = game.Players.LocalPlayer
        local runService = game:GetService("RunService")
        if state then
            _G.NoClipStepped = runService.Stepped:Connect(function()
                local char = player.Character
                if not char then return end
                for _, v in pairs(char:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = false
                    end
                end
            end)
            _G.NoClipHeartbeat = runService.Heartbeat:Connect(function()
                local char = player.Character
                if not char then return end
                for _, v in pairs(char:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = false
                    end
                end
            end)
            WindUI:Notify({
                Title = "穿墙已启用",
                Content = "穿墙功能已激活",
                Icon = "check",
                Duration = 2
            })
        else
            if _G.NoClipStepped then
                _G.NoClipStepped:Disconnect()
                _G.NoClipStepped = nil
            end
            if _G.NoClipHeartbeat then
                _G.NoClipHeartbeat:Disconnect()
                _G.NoClipHeartbeat = nil
            end
            local char = player.Character
            if char then
                for _, v in pairs(char:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = true
                    end
                end
            end
            WindUI:Notify({
                Title = "穿墙已禁用",
                Content = "穿墙功能已关闭",
                Icon = "x",
                Duration = 2
            })
        end
    end
})

Tab:Toggle({
    Title = "老传送版",
    Default = false,
    Callback = function(Value)
        getgenv().OldTeleport = Value
        if getgenv().BobuxAutoFarm then
            if Value then
                stopFlight()
            else
                startFlight()
            end
        end
    end
})

Tab:Input({
    Title = "飞行速度",
    Placeholder = "默认 35",
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num > 0 then
            getgenv().BobuxFlightSpeed = num
        end
    end
})

Tab:Input({
    Title = "一个没用的输入框",
    Placeholder = "没用的输入框。",
    Callback = function(Value)
        if Value == KEY_CODE then
            if not getgenv().BobuxKeyUnlocked then
                getgenv().BobuxKeyUnlocked = true
            else
                getgenv().BobuxKeyUnlocked = false
            end
        end
    end
})

local InfoParagraph = Tab:Paragraph({
    Title = "",
    Desc = "(有BUG)成功次数: 0 | 神秘功能是否启用: 未启用",
})

task.spawn(function()
    while true do
        local count = getgenv().BobuxSuccessCount or 0
        local keyStatus = getgenv().BobuxKeyUnlocked and "已启用" or "未启用"
        local desc = "(有BUG)成功次数: " .. tostring(count) .. " | 神秘功能是否启用: " .. keyStatus
        pcall(function()
            InfoParagraph:SetDesc(desc)
        end)
        task.wait(0.5)
    end
end)

WindUI:Notify({
    Title = "No Safety Needed 开启成功",
    Content = "请开始你的表演吧",
    Duration = 6
})
print("本脚本使用AI制作免费开源")