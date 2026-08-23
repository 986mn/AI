local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/finendss/VowLibrary/refs/heads/main/WINDUI.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Window = WindUI:CreateWindow({
    Title = "完美![木工!]script",
    Icon = "sparkles",
    Author = "完美![木工!]script",
    Folder = "完美![木工!]script",
    Size = UDim2.fromOffset(420, 420),
    Theme = "Pink",
    HideSearchBar = false,
})

Window:Tag({
    Title = "完美![木工!]script",
    Color = Color3.fromHex("#7FDBFF")
})

Window:EditOpenButton({
    Title = "完美![木工!]script",
    Icon = "monitor",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF6B6B")),
    Draggable = true,
})

local Tab = Window:Tab({
    Title = "自动刷钱",
    Icon = "settings",
    Locked = false,
})

Tab:Section({ Title = "功能", TextXAlignment = "Left", TextSize = 17 })

Tab:Paragraph({
    Title = "自动刷钱说明",
    Desc = "使用前请在服务器内设置里开启Disable Witch来保持游戏环境(否则无法使用)",
})

getgenv().BobuxAutoFarm = false
getgenv().BobuxFarmRunning = false
getgenv().BobuxLock = false
getgenv().BobuxLockRunning = false
getgenv().BobuxSuccessCount = 0
getgenv().SafeFly = false
getgenv().SafeFlyRunning = false
getgenv().OldTeleport = false

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
    if getgenv().OldTeleport then
        startOldTeleport()
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
    local map = workspace:FindFirstChild("Map")
    if not map then
        for _, v in ipairs(workspace:GetChildren()) do
            if v.Name:lower() == "map" then
                return v
            end
        end
    end
    return map
end

local function getCharactersFolder()
    local chars = workspace:FindFirstChild("Characters")
    if chars then return chars end
    for _, v in ipairs(workspace:GetChildren()) do
        if v.Name:lower() == "characters" then
            return v
        end
    end
    return nil
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
    local ok, pos = pcall(function() return instance.Position end)
    if ok and pos and typeof(pos) == "Vector3" then
        return pos
    end
    local ok2, cf = pcall(function() return instance.CFrame end)
    if ok2 and cf and typeof(cf) == "CFrame" then
        return cf.Position
    end
    local part = instance:FindFirstChildWhichIsA("BasePart", true)
    if part then return part.Position end
    return nil
end

getgenv().BobuxFlightSpeed = 35
getgenv().BobuxIsFlying = false
getgenv().BobuxAutoTarget = nil
local flightConnection = nil
local oldTeleportConn = nil

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

local function startOldTeleport()
    if oldTeleportConn then return end

    oldTeleportConn = RunService.Heartbeat:Connect(function()
        if not getgenv().OldTeleport then return end

        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local targetPos = nil

        if hasFishAccessory() then
            local doors = findAllDoors()
            if #doors > 0 then
                local doorPos = getNearestTarget(doors)
                if doorPos then
                    targetPos = getDoorFrontPos(doorPos)
                end
            end
        else
            local fishes = findAllFish()
            if #fishes > 0 then
                targetPos = getNearestTarget(fishes)
            end
        end

        if targetPos then
            hrp.CFrame = CFrame.new(targetPos)
        end
    end)
end

local function stopOldTeleport()
    getgenv().OldTeleport = false
    if oldTeleportConn then
        oldTeleportConn:Disconnect()
        oldTeleportConn = nil
    end
end

local function getPlayerCharInCharacters()
    local charsFolder = getCharactersFolder()
    if not charsFolder then return nil end
    
    local char = player.Character
    if char and char:IsDescendantOf(charsFolder) then
        return char
    end
    
    for _, v in ipairs(charsFolder:GetDescendants()) do
        if v:IsA("Model") then
            local plr = Players:GetPlayerFromCharacter(v)
            if plr and plr == player then
                return v
            end
        end
    end
    
    for _, v in ipairs(charsFolder:GetDescendants()) do
        if v:IsA("Model") and v.Name == player.Name then
            if v:FindFirstChildOfClass("Humanoid") then
                return v
            end
        end
    end
    
    return nil
end

local function isPlayerInCharacters()
    return getPlayerCharInCharacters() ~= nil
end

local function hasFishAccessory()
    local char = player.Character
    if char then
        local fishAcc = char:FindFirstChild("FishAccessory", true)
        if fishAcc then return true end
    end
    local playerChar = getPlayerCharInCharacters()
    if playerChar then
        local fishAcc = playerChar:FindFirstChild("FishAccessory", true)
        if fishAcc then return true end
    end
    return false
end

local function findAllFish()
    local map = getMapFolder()
    if not map then return {} end
    local fishes = {}
    for _, v in ipairs(map:GetDescendants()) do
        if v.Name == "Fish" then
            local pos = getInstancePosition(v)
            if pos then
                table.insert(fishes, v)
            end
        end
    end
    return fishes
end

local function findAllDoors()
    local map = getMapFolder()
    if not map then return {} end
    local doors = {}
    for _, v in ipairs(map:GetDescendants()) do
        if v.Name:sub(-4) == "Door" then
            local pos = getInstancePosition(v)
            if pos then
                table.insert(doors, v)
            end
        end
    end
    return doors
end

local function getNearestTarget(targets)
    local hrp = getHRP()
    if not hrp then return nil end
    local nearest = nil
    local nearestDist = math.huge
    for _, target in ipairs(targets) do
        local pos = getInstancePosition(target)
        if pos then
            local dist = (hrp.Position - pos).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = pos
            end
        end
    end
    return nearest
end

local function getDoorFrontPos(doorPos, hrp)
    if not doorPos then return nil end
    if not hrp then hrp = getHRP() end
    if not hrp then return doorPos end
    local success, result = pcall(function()
        local offset = hrp.Position - doorPos
        if offset.Magnitude < 1 then return doorPos end
        local dir = offset.Unit
        return doorPos + dir * 2
    end)
    if success and result then
        return result
    end
    return doorPos
end

local function getDisableWitchButton()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local main = pg:FindFirstChild("Main")
    if not main then return nil end
    local settings = main:FindFirstChild("settings")
    if not settings then return nil end
    local container = settings:FindFirstChild("container")
    if not container then return nil end
    local disableWitch = container:FindFirstChild("DisableWitch")
    if not disableWitch then return nil end
    local button = disableWitch:FindFirstChild("button")
    return button
end

local function checkUnlockCondition()
    local button = getDisableWitchButton()
    if not button then return false end
    return button.Text == "X"
end

local function startLockLoop()
    if getgenv().BobuxLockRunning then return end
    getgenv().BobuxLockRunning = true

    local notifiedDisabled = false
    local notifiedEnabled = false

    task.spawn(function()
        while getgenv().BobuxAutoFarm or getgenv().OldTeleport do
            if not getgenv().BobuxKeyUnlocked then
                if checkUnlockCondition() then
                    getgenv().BobuxLock = false
                    if not notifiedEnabled then
                        WindUI:Notify({
                            Title = "已解锁",
                            Content = "检测到Disable Witch已开启,安全传送开始传送",
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
                            Content = "检测到Disable Witch未开启,请前往设置开启后使用",
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
        local gotFishTime = nil
        local lastHadFish = false

        while getgenv().BobuxAutoFarm do
            task.wait(0.001)

            if getgenv().BobuxLock and not getgenv().BobuxKeyUnlocked then
                getgenv().BobuxAutoTarget = nil
                continue
            end

            if not isPlayerInCharacters() then
                getgenv().BobuxAutoTarget = nil
                continue
            end

            local hasFish = hasFishAccessory()

            if hasFish then
                if not lastHadFish then
                    gotFishTime = tick()
                end
                if gotFishTime and tick() - gotFishTime >= 0.2 then
                    local doors = findAllDoors()
                    if #doors > 0 then
                        local nearestDoor = getNearestTarget(doors)
                        if nearestDoor then
                            local nearest = getDoorFrontPos(nearestDoor)
                            if getgenv().OldTeleport then
                                local char = player.Character
                                if char then
                                    local hrp = char:FindFirstChild("HumanoidRootPart")
                                    if hrp then
                                        hrp.Velocity = Vector3.zero
                                        hrp.RotVelocity = Vector3.zero
                                        hrp.CFrame = CFrame.new(nearest)
                                    end
                                    if not char.PrimaryPart and hrp then
                                        char.PrimaryPart = hrp
                                    end
                                    char:PivotTo(CFrame.new(nearest))
                                end
                            else
                                getgenv().BobuxAutoTarget = nearest
                                local hrp = getHRP()
                                if hrp and (hrp.Position - nearest).Magnitude < 3 then
                                    getgenv().BobuxSuccessCount = getgenv().BobuxSuccessCount + 1
                                    task.wait(1)
                                end
                            end
                        else
                            getgenv().BobuxAutoTarget = nil
                        end
                    else
                        getgenv().BobuxAutoTarget = nil
                    end
                end
            else
                gotFishTime = nil
                local fishes = findAllFish()
                if #fishes > 0 then
                    local nearest = getNearestTarget(fishes)
                    if nearest then
                        if getgenv().OldTeleport then
                            local char = player.Character
                            if char then
                                local hrp = char:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    hrp.Velocity = Vector3.zero
                                    hrp.RotVelocity = Vector3.zero
                                    hrp.CFrame = CFrame.new(nearest)
                                end
                                if not char.PrimaryPart and hrp then
                                    char.PrimaryPart = hrp
                                end
                                char:PivotTo(CFrame.new(nearest))
                            end
                        else
                            getgenv().BobuxAutoTarget = nearest
                        end
                    else
                        getgenv().BobuxAutoTarget = nil
                    end
                else
                    getgenv().BobuxAutoTarget = nil
                end
            end

            lastHadFish = hasFish
        end
        getgenv().BobuxAutoTarget = nil
        getgenv().BobuxFarmRunning = false
    end)
end

Tab:Toggle({
    Title = "安全传送",
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
                Content = "安全传送已锁定,请开启Disable Witch后才可以使用",
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
                Content = "安全传送已停止",
                Duration = 3
            })
        end
    end
})

Tab:Toggle({
    Title = "瞬间传送",
    Default = false,
    Callback = function(Value)
        getgenv().OldTeleport = Value
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
                Title = "瞬间传送已开启",
                Content = "请开启Disable Witch后使用",
                Duration = 3
            })
        else
            WindUI:Notify({
                Title = "瞬间传送已关闭",
                Content = "自动传送已停止",
                Duration = 2
            })
        end
    end


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
    Title = "完美![木工!]script 开启成功",
    Content = "请开始你的表演吧",
    Duration = 6
})
print("本脚本使用AI制作免费开源")

local oldTeleportGlobalConn = nil
if oldTeleportGlobalConn then oldTeleportGlobalConn:Disconnect() end
oldTeleportGlobalConn = RunService.Heartbeat:Connect(function()
    if not getgenv().OldTeleport then return end
    if getgenv().BobuxAutoFarm then return end

    if getgenv().BobuxLock and not getgenv().BobuxKeyUnlocked then
        return
    end

    if not isPlayerInCharacters() then
        return
    end

    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local targetPos = nil

    if hasFishAccessory() then
        local doors = findAllDoors()
        if #doors > 0 then
            local doorPos = getNearestTarget(doors)
            if doorPos then
                targetPos = getDoorFrontPos(doorPos, hrp)
            end
        end
    else
        local fishes = findAllFish()
        if #fishes > 0 then
            targetPos = getNearestTarget(fishes)
        end
    end

    if targetPos then
        hrp.CFrame = CFrame.new(targetPos)
    end
end)
