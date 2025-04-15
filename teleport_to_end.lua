-- Aliases cho hàm string và bit
local xor_key = string.char
local byte = string.byte
local sub = string.sub
local bit = bit32 or bit
local xor = bit.bxor
local concat = table.concat
local insert = table.insert

local function decrypt(ciphertext, key)
    local decrypted = {}
    for i = 1, #ciphertext do
        local c = byte(sub(ciphertext, i, i + 1))
        local k = byte(sub(key, 1 + (i % #key), 1 + (i % #key) + 1))
        insert(decrypted, xor_key(xor(c, k) % 256))
    end
    return concat(decrypted)
end

local player = game:GetService("Players").LocalPlayer

local tracked = {}
local isFiring = false
local originalFire = getfenv().fireproximityprompt

if originalFire then
    pcall(function()
        task.spawn(function()
            local prompt = Instance.new("ProximityPrompt", workspace)
            prompt.Triggered:Connect(function()
                originalFire(prompt)
                isFiring = true
                prompt.Parent = nil
                task.wait(0.1)
                prompt:Destroy()
            end)
            task.wait(0.1)
            originalFire(prompt)
        end)
    end)
end

-- Đo thời gian trung bình giữa các khung hình
math.round = math.round or function(n)
    return n >= 0 and math.floor(n + 0.5) or math.ceil(n - 0.5)
end

local function measurePerformance(iterations)
    iterations = math.max(math.round(tonumber(iterations) or 1), 1)
    local total = 0
    for _ = 1, iterations do
        total = total + game:GetService("RunService").RenderStepped:Wait()
    end
    return total / iterations
end

local function manipulatePrompt(prompt)
    tracked[prompt] = true
    local originalProps = {
        prompt.MaxActivationDistance,
        prompt.Enabled,
        prompt.Parent,
        prompt.HoldDuration,
        prompt.RequiresLineOfSight
    }

    local fakeParent = Instance.new("Part", workspace)
    fakeParent.Transparency = 1
    fakeParent.CanCollide = false
    fakeParent.Size = Vector3.new(0.1, 0.1, 0.1)
    fakeParent.Anchored = true

    prompt.Parent = fakeParent
    prompt.MaxActivationDistance = math.huge
    prompt.Enabled = true
    prompt.HoldDuration = 0
    prompt.RequiresLineOfSight = false

    fakeParent:PivotTo(workspace.CurrentCamera.CFrame + workspace.CurrentCamera.CFrame.LookVector / 10)
    measurePerformance()
    prompt:InputHoldBegin()
    measurePerformance()
    fakeParent:PivotTo(workspace.CurrentCamera.CFrame + workspace.CurrentCamera.CFrame.LookVector / 5)
    prompt:InputHoldEnd()
    measurePerformance()

    if prompt.Parent == fakeParent then
        prompt.Parent = originalProps[3]
        prompt.MaxActivationDistance = originalProps[1]
        prompt.Enabled = originalProps[2]
        prompt.HoldDuration = originalProps[4]
        prompt.RequiresLineOfSight = originalProps[5]
    end

    fakeParent:Destroy()
    tracked[prompt] = false
end

-- Tự động kích hoạt Prompt
local function firePrompt(prompt)
    if isFiring then return originalFire(prompt) end
    task.spawn(manipulatePrompt, prompt)
end

-- Giả lập va chạm (touch)
local isTouching = false
local originalTouch = getfenv().firetouchinterest

task.spawn(function()
    if originalTouch then
        local part = Instance.new("Part", workspace)
        part.Position = Vector3.new(0, 0, 0)
        part.Touched:Connect(function()
            part:Destroy()
            isTouching = true
        end)
        originalTouch(part, player.Character.HumanoidRootPart, 0)
        task.wait()
        originalTouch(part, player.Character.HumanoidRootPart, 1)
    end
end)

-- Hàm mô phỏng va chạm
local function simulateTouch(target, part, toggle)
    if isTouching then return originalTouch(target, part, toggle) end
    if tracked[target] or tracked[part] then return end
    tracked[target] = true
    if not toggle then
        local original = part.CanTouch
        part.CanTouch = false
        task.wait(0.015)
        part.CanTouch = original
    else
        -- Complex touch simulation logic
    end
    tracked[target] = false
end

-- (Phần dưới bị lược bỏ trong đoạn gốc - có nhắc đến vũ khí và nhặt đồ)

return function(mainConfig)
    local noclipEnabled = true
    local weapon = getCurrentWeapon()
    while true do
        local target = findNearestEnemy()
        if target then
            while target.Parent and target.Humanoid.Health > 0.01 do
                autoShoot(weapon, target)
                teleportToSafeZone()
            end
        end
        collectItems()
        manageInventory()
        task.wait(mainConfig.updateInterval or 0.01)
    end
end
