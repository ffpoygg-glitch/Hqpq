-- =====================================================
-- HONKUKI DEEP VALIDATOR SCANNER (ALL-IN-ONE)
-- [เวอร์ชันแก้ทางค้างลื่นไหลพิเศษ 100% - ปรับปรุงระบบลูปอัปเดต]
-- ระบบดึงเพลง/เจาะ ID ยังคงทำงานแบบเรียลไทม์ไม่มีดีเลย์
-- =====================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local CurrentSelectedPlayer = nil
local WhitelistPlayers = {}

-- ==================== บล็อค ID ปลอม (ใช้กับปุ่มเจาะ) ====================
local BlockedIDs = {
    ["00106800577264015"] = true, ["00109462618039650"] = true,
    ["00112583972042063"] = true, ["00113841533670628"] = true,
    ["00116872955970254"] = true, ["00117424747387525"] = true,
    ["00117628371363749"] = true, ["00121320825772761"] = true,
    ["00125329595131078"] = true, ["00129043827992035"] = true,
    ["00134076916421685"] = true, ["00134523838494464"] = true,
    ["00137058099826867"] = true, ["00138763959207625"] = true,
    ["0070567654933546"] = true, ["0079688020178596"] = true,
    ["0083260119948695"] = true, ["0083681471562121"] = true,
    ["0083848201981900"] = true, ["0090308298517537"] = true,
    ["0093338918256962"] = true, ["0093932829347443"] = true,
    ["00"] = true, ["4"] = true, ["62"] = true, ["7"] = true,
    ["78899"] = true, ["83260119948695"] = true, ["9"] = true,
    ["00120104871360327"] = true, ["00129060362076134"] = true,
    ["101631982347841"] = true, ["112210298860778"] = true,
    ["115819698454027"] = true, ["116331922770563"] = true,
    ["117391349741339"] = true, ["117871196330268"] = true,
    ["120313493879944"] = true, ["134216333534795"] = true,
    ["137555839480738"] = true, ["140497415402103"] = true,
    ["54410081542"] = true, ["70999314371231"] = true,
    ["71352236"] = true, ["76500780055460"] = true,
    ["78515442941510"] = true, ["90533928572341"] = true,
    ["99721399503975"] = true,
    ["00101020203030404"] = true, ["00112233445566778"] = true,
    ["00123456789012345"] = true, ["00135791357913579"] = true,
    ["00159260374815926"] = true, ["00246802468024680"] = true,
    ["00405060708090001"] = true, ["00543210987654321"] = true,
    ["00731959731959731"] = true, ["00864208642086420"] = true,
    ["00887766554433221"] = true, ["00975319753197531"] = true,
    ["00987654321098765"] = true, ["00998877665544332"] = true,
    ["129569049476734"] = true, ["81067084464165"] = true,
    ["00159837264918375"] = true,
    ["115897193508594"] = true,
    ["123728962822472"] = true,
    ["0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"] = true
}

-- ==================== ฟังก์ชัน Helper ====================
local function getHttpRequest()
    if request then return request end
    if http_request then return http_request end
    if syn and type(syn) == "table" and syn.request then return syn.request end
    if http and type(http) == "table" and http.request then return http.request end
    return nil
end

local function urlDecode(str)
    if not str then return "" end
    str = string.gsub(str, "+", " ")
    return (string.gsub(str, "%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
end

local function hexDecode(str)
    if not str then return "" end
    str = string.gsub(str, "0x", "")
    str = string.gsub(str, "\\x", "")
    str = string.gsub(str, "%%", "")
    if string.match(str, "^%x+$") and #str % 2 == 0 then
        local decoded = ""
        for i = 1, #str, 2 do
            local byteStr = string.sub(str, i, i+1)
            local byte = tonumber(byteStr, 16)
            if byte and byte >= 32 and byte <= 126 then decoded = decoded .. string.char(byte) end
        end
        if #decoded > 0 then return decoded end
    end
    return str
end

local function deepDecode(str)
    if type(str) ~= "string" then return str end
    local prev
    repeat
        prev = str
        str = urlDecode(str)
        str = hexDecode(str)
    until str == prev
    return str
end

local function extractIDsFromPattern(text)
    local ids = {}
    local patterns = {
        "69%%64=([^&]*)", "&id=([^&]*)", "id=([^&]*)",
        "audio=([^&]*)", "song=([^&]*)", "music=([^&]*)",
        "%%69%%64=([^&]*)", "&%%69%%64=([^&]*)"
    }
    for _, pat in ipairs(patterns) do
        for capture in string.gmatch(text, pat) do
            for num in string.gmatch(capture, "%d+") do
                table.insert(ids, num)
            end
        end
    end
    return ids
end

local function getPlayerVehicle(player)
    if not player then return nil end
    local character = player.Character
    if not character then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    local seatPart = humanoid.SeatPart
    if not seatPart then return nil end
    local vehicle = seatPart.Parent
    while vehicle and not vehicle:IsA("Model") do
        vehicle = vehicle.Parent
    end
    if vehicle and vehicle:IsA("Model") then
        return vehicle
    end
    return nil
end

local function checkPlayerAllSounds(targetPlayer)
    if not targetPlayer then return {} end

    local scanTargets = {}
    if targetPlayer.Character then table.insert(scanTargets, targetPlayer.Character) end
    local backpack = targetPlayer:FindFirstChild("Backpack")
    if backpack then table.insert(scanTargets, backpack) end
    local pGui = targetPlayer:FindFirstChild("PlayerGui")
    if pGui then table.insert(scanTargets, pGui) end

    local vehicle = getPlayerVehicle(targetPlayer)
    if vehicle then
        table.insert(scanTargets, vehicle)
    end

    local validSounds = {}
    local soundMap = {}

    local NameBlacklist = {
        ["gettingup"] = true, ["died"] = true, ["freefalling"] = true,
        ["jumping"] = true, ["landing"] = true, ["running"] = true,
        ["splash"] = true, ["swimming"] = true, ["climbing"] = true,
        ["skateboard"] = true, ["skate"] = true, ["board"] = true,
        ["car"] = true, ["vehicle"] = true, ["bike"] = true,
        ["scooter"] = true, ["bicycle"] = true, ["motorcycle"] = true,
        ["engine"] = true, ["motor"] = true, ["horn"] = true,
        ["tire"] = true, ["wheel"] = true, ["brake"] = true,
        ["squeak"] = true, ["driving"] = true, ["road"] = true,
        ["crash"] = true, ["impact"] = true, ["bump"] = true
    }

    for _, folder in ipairs(scanTargets) do
        local success, descendants = pcall(function() return folder:GetDescendants() end)
        if success and descendants then
            for _, obj in ipairs(descendants) do
                if obj:IsA("Sound") and obj.SoundId ~= "" and obj.IsPlaying then
                    local soundNameLower = string.lower(obj.Name)
                    local isBlacklisted = false
                    for blockedName, _ in pairs(NameBlacklist) do
                        if string.find(soundNameLower, blockedName) then
                            isBlacklisted = true
                            break
                        end
                    end
                    if not isBlacklisted then
                        local key = obj.SoundId
                        if not soundMap[key] then
                            soundMap[key] = true
                            table.insert(validSounds, obj)
                        end
                    end
                end
            end
        end
    end
    return validSounds
end

local function copyToClipboard(text)
    local setclip = setclipboard or toclipboard or (Clipboard and Clipboard.set)
    if setclip then setclip(text) end
end

-- ==================== ฟังก์ชันเล่นเพลง (ระบบยิงรีโมทเบิ้ลคู่เด็ดขาด) ====================
local function playMusicFromId(musicId)
    if not musicId or musicId == "" then
        return false
    end
    
    local re = ReplicatedStorage:FindFirstChild("RE")
    if re then
        local success1, success2 = false, false
        
        local event1 = re:FindFirstChild("PlayerToolEvent")
        if event1 then
            local args1 = { "ToolMusicText", musicId, "", [4] = true }
            success1 = pcall(function() event1:FireServer(unpack(args1)) end)
        end
        
        local event2 = re:FindFirstChild("1NoMoto1rVehicle1s")
        if event2 then
            local args2 = { "ToolMusicText", musicId, "", [4] = true }
            success2 = pcall(function() event2:FireServer(unpack(args2)) end)
        end
        
        return success1 or success2
    end
    return false
end

-- ==================== ปุ่มขยะ (เล่น + คัดลอกทั้งหมด + กรอง 2 ID) ====================
local function directLogRawJunk(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    local soundObjects = checkPlayerAllSounds(targetPlayer)
    if #soundObjects == 0 then return false end

    local firstCleanId = nil
    local allCleanIds = {}

    local junkBlockedIDs = {
        ["123728962822472"] = true,
        ["115897193508594"] = true
    }

    for i, soundObj in ipairs(soundObjects) do
        local rawId = soundObj.SoundId or ""
        local cleanId = string.gsub(rawId, "^rbxassetid://", "")
        if string.find(cleanId, "rbxassetid://") then
            cleanId = string.match(cleanId, "rbxassetid://(%d+)") or cleanId
        end
        if not junkBlockedIDs[cleanId] then
            if not firstCleanId and cleanId ~= "" then
                firstCleanId = cleanId
            end
            if cleanId ~= "" then
                table.insert(allCleanIds, cleanId)
            end
        end
    end

    if not firstCleanId then
        StatusLabel.Text = "❌ ไม่พบ ID ในขยะ"
        return false
    end

    local played = playMusicFromId(firstCleanId)
    if played then
        StatusLabel.Text = "✅ เล่นเพลงสำเร็จ: " .. firstCleanId
    else
        StatusLabel.Text = "❌ เล่นเพลงไม่สำเร็จ (ดู Console)"
    end

    local clipboardText = table.concat(allCleanIds, "\n")
    copyToClipboard(clipboardText)
    StatusLabel.Text = "📋 คัดลอก " .. #allCleanIds .. " ID ไปคลิปบอร์ดแล้ว"

    return true
end

-- ==================== ปุ่มเจาะ (ดึงปุ๊บได้ปั๊บ ไม่เช็ค API / ไม่เช็ค 60 วิ) ====================
local function directLogMusicID(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    local soundObjects = checkPlayerAllSounds(targetPlayer)
    if #soundObjects == 0 then return false end

    local finalIds = {}
    local seenIds = {}
    local totalBlocked = 0

    for _, soundObj in ipairs(soundObjects) do
        local rawId = soundObj.SoundId or ""
        local decoded = deepDecode(rawId)
        local searchText = (decoded ~= "" and decoded) or rawId

        local extractedIds = extractIDsFromPattern(searchText)
        if #extractedIds == 0 then
            for num in string.gmatch(searchText, "%d+") do
                table.insert(extractedIds, num)
            end
        end

        if #extractedIds > 0 then
            for _, id in ipairs(extractedIds) do
                if BlockedIDs[id] then
                    totalBlocked = totalBlocked + 1
                else
                    if not seenIds[id] then
                        seenIds[id] = true
                        table.insert(finalIds, id)
                    end
                end
            end
        end
    end

    if #finalIds == 0 then
        StatusLabel.Text = "ไม่พบ ID ที่ต้องการ (ถูกบล็อค " .. totalBlocked .. " ตัว)"
        return false
    end

    local copyText = table.concat(finalIds, " ")
    copyToClipboard(copyText)

    StatusLabel.Text = "📋 ดึงเสร็จทันที! คัดลอก " .. #finalIds .. " ID ไปคลิปบอร์ดแล้ว"
    return true
end

-- =====================================================
-- ส่วน UI ทั้งหมด (สร้างโครงสร้างหน้าต่างหลัก + หน้าต่าง RAW)
-- =====================================================
if PlayerGui:FindFirstChild("Honkuki_DeepSoundSpy") then PlayerGui.Honkuki_DeepSoundSpy:Destroy() end

local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.Name = "Honkuki_DeepSoundSpy"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local function setDrag(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ==================== UI หลัก ====================
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 435)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -217)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.ZIndex = 1
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local mStroke = Instance.new("UIStroke", MainFrame)
mStroke.Color = Color3.fromRGB(60, 60, 60)
mStroke.Thickness = 1

local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)
setDrag(MainFrame, TopBar)

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1, -10, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "HONKUKI DEEP VALIDATOR SCANNER"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left

local ListScroll = Instance.new("ScrollingFrame", MainFrame)
ListScroll.Size = UDim2.new(0.9, 0, 0, 160)
ListScroll.Position = UDim2.new(0.05, 0, 0.11, 0)
ListScroll.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ListScroll.BorderSizePixel = 0
ListScroll.ScrollBarThickness = 4
ListScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
Instance.new("UICorner", ListScroll).CornerRadius = UDim.new(0, 5)

local Layout = Instance.new("UIListLayout", ListScroll)
Layout.Padding = UDim.new(0, 4)

StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(0.9, 0, 0, 35)
StatusLabel.Position = UDim2.new(0.05, 0, 0.50, 0)
StatusLabel.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
StatusLabel.BackgroundTransparency = 0.9
StatusLabel.Text = "ระบบดึงส่งตรงทำงานปกติ"
StatusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11
StatusLabel.TextWrapped = true
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 5)

local GetIDBtn = Instance.new("TextButton", MainFrame)
GetIDBtn.Size = UDim2.new(0.9, 0, 0, 34)
GetIDBtn.Position = UDim2.new(0.05, 0, 0.59, 0)
GetIDBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
GetIDBtn.Text = "เจาะและดึงไอดีทันที (Instant Log)"
GetIDBtn.Font = Enum.Font.GothamBold
GetIDBtn.TextSize = 11
GetIDBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
Instance.new("UICorner", GetIDBtn).CornerRadius = UDim.new(0, 6)

local GetJunkBtn = Instance.new("TextButton", MainFrame)
GetJunkBtn.Size = UDim2.new(0.9, 0, 0, 34)
GetJunkBtn.Position = UDim2.new(0.05, 0, 0.67, 0)
GetJunkBtn.BackgroundColor3 = Color3.fromRGB(230, 90, 40)
GetJunkBtn.Text = "ดึงขยะ (เล่นเพลง + คัดลอกทั้งหมด)"
GetJunkBtn.Font = Enum.Font.GothamBold
GetJunkBtn.TextSize = 11
GetJunkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", GetJunkBtn).CornerRadius = UDim.new(0, 6)

local ViewRawJunkBtn = Instance.new("TextButton", MainFrame)
ViewRawJunkBtn.Size = UDim2.new(0.9, 0, 0, 34)
ViewRawJunkBtn.Position = UDim2.new(0.05, 0, 0.75, 0)
ViewRawJunkBtn.BackgroundColor3 = Color3.fromRGB(140, 20, 230)
ViewRawJunkBtn.Text = "ดูข้อความ RAW ดิบของผู้เล่น (หน้าต่างสี่เหลี่ยม)"
ViewRawJunkBtn.Font = Enum.Font.GothamBold
ViewRawJunkBtn.TextSize = 11
ViewRawJunkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", ViewRawJunkBtn).CornerRadius = UDim.new(0, 6)

local WhitelistBtn = Instance.new("TextButton", MainFrame)
WhitelistBtn.Size = UDim2.new(0.9, 0, 0, 32)
WhitelistBtn.Position = UDim2.new(0.05, 0, 0.83, 0)
WhitelistBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
WhitelistBtn.Text = "เพิ่ม / ลบ รายชื่อไวริส (Whitelist)"
WhitelistBtn.Font = Enum.Font.GothamBold
WhitelistBtn.TextSize = 11
WhitelistBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", WhitelistBtn).CornerRadius = UDim.new(0, 6)

local RefreshBtn = Instance.new("TextButton", MainFrame)
RefreshBtn.Size = UDim2.new(0.9, 0, 0, 26)
RefreshBtn.Position = UDim2.new(0.05, 0, 0.91, 0)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
RefreshBtn.Text = "รีเฟรชรายชื่อผู้เล่น"
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.TextSize = 11
RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 6)

local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Size = UDim2.new(0, 45, 0, 45)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleBtn.Text = "🎵"
ToggleBtn.TextSize = 20
ToggleBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
ToggleBtn.ZIndex = 2
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 22)
local tStroke = Instance.new("UIStroke", ToggleBtn)
tStroke.Color = Color3.fromRGB(255, 215, 0)
tStroke.Thickness = 1.5
setDrag(ToggleBtn, ToggleBtn)

-- ==================== หน้าต่างดูขยะแบบเต็มๆ (โชว์หมดไม่ตัดทิ้ง) ====================
local JunkFrame = Instance.new("Frame", ScreenGui)
JunkFrame.Size = UDim2.new(0, 340, 0, 360)
JunkFrame.Position = UDim2.new(0.5, -170, 0.5, -180)
JunkFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
JunkFrame.Visible = false
JunkFrame.ZIndex = 5
Instance.new("UICorner", JunkFrame).CornerRadius = UDim.new(0, 8)
local jStroke = Instance.new("UIStroke", JunkFrame)
jStroke.Color = Color3.fromRGB(140, 20, 230)
jStroke.Thickness = 1.5

local JunkTopBar = Instance.new("Frame", JunkFrame)
JunkTopBar.Size = UDim2.new(1, 0, 0, 35)
JunkTopBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Instance.new("UICorner", JunkTopBar).CornerRadius = UDim.new(0, 8)
setDrag(JunkFrame, JunkTopBar)

local JunkTitle = Instance.new("TextLabel", JunkTopBar)
JunkTitle.Size = UDim2.new(1, -10, 1, 0)
JunkTitle.Position = UDim2.new(0, 12, 0, 0)
JunkTitle.BackgroundTransparency = 1
JunkTitle.Text = "RAW JUNK VIEWER (ขยะดิบทั้งหมด 100%)"
JunkTitle.TextColor3 = Color3.fromRGB(200, 100, 255)
JunkTitle.Font = Enum.Font.GothamBold
JunkTitle.TextSize = 12
JunkTitle.TextXAlignment = Enum.TextXAlignment.Left

local JunkScroll = Instance.new("ScrollingFrame", JunkFrame)
JunkScroll.Size = UDim2.new(0.92, 0, 0, 220)
JunkScroll.Position = UDim2.new(0.04, 0, 0.13, 0)
JunkScroll.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
JunkScroll.BorderSizePixel = 0
JunkScroll.ScrollBarThickness = 5
JunkScroll.ScrollBarImageColor3 = Color3.fromRGB(140, 20, 230)
Instance.new("UICorner", JunkScroll).CornerRadius = UDim.new(0, 5)

local JunkTextLabel = Instance.new("TextLabel", JunkScroll)
JunkTextLabel.Size = UDim2.new(1, -10, 0, 0)
JunkTextLabel.Position = UDim2.new(0, 5, 0, 5)
JunkTextLabel.BackgroundTransparency = 1
JunkTextLabel.Text = "ไม่มีข้อมูล..."
JunkTextLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
JunkTextLabel.Font = Enum.Font.Code
JunkTextLabel.TextSize = 11
JunkTextLabel.TextXAlignment = Enum.TextXAlignment.Left
JunkTextLabel.TextYAlignment = Enum.TextYAlignment.Top
JunkTextLabel.TextWrapped = true

local JunkCopyBtn = Instance.new("TextButton", JunkFrame)
JunkCopyBtn.Size = UDim2.new(0.44, 0, 0, 35)
JunkCopyBtn.Position = UDim2.new(0.04, 0, 0.85, 0)
JunkCopyBtn.BackgroundColor3 = Color3.fromRGB(140, 20, 230)
JunkCopyBtn.Text = "📋 คัดลอกทั้งหมด"
JunkCopyBtn.Font = Enum.Font.GothamBold
JunkCopyBtn.TextSize = 12
JunkCopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", JunkCopyBtn).CornerRadius = UDim.new(0, 6)

local JunkBackBtn = Instance.new("TextButton", JunkFrame)
JunkBackBtn.Size = UDim2.new(0.44, 0, 0, 35)
JunkBackBtn.Position = UDim2.new(0.52, 0, 0.85, 0)
JunkBackBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
JunkBackBtn.Text = "⬅️ ย้อนกลับ"
JunkBackBtn.Font = Enum.Font.GothamBold
JunkBackBtn.TextSize = 12
JunkBackBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", JunkBackBtn).CornerRadius = UDim.new(0, 6)

-- ==================== ฟังก์ชันรีเฟรชผู้เล่น ====================
local function refreshPlayers()
    if not ListScroll or not ListScroll:IsDescendantOf(game) then return end
    for _, item in pairs(ListScroll:GetChildren()) do
        if item:IsA("TextButton") then item:Destroy() end
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local PBtn = Instance.new("TextButton", ListScroll)
            PBtn.Size = UDim2.new(1, -6, 0, 30)
            PBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
            local activeSounds = checkPlayerAllSounds(p)
            if WhitelistPlayers[p.Name] then
                PBtn.Text = "  🛡️ " .. p.DisplayName .. " (@" .. p.Name .. ") [ไวริส]"
                PBtn.TextColor3 = Color3.fromRGB(0, 255, 128)
            elseif #activeSounds > 0 then
                PBtn.Text = "  " .. p.DisplayName .. " (@" .. p.Name .. ") [เล่นเพลงอยู่ 🎵]"
                PBtn.TextColor3 = Color3.fromRGB(0, 255, 0)
            else
                PBtn.Text = "  " .. p.DisplayName .. " (@" .. p.Name .. ")"
                PBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
            end
            PBtn.Font = Enum.Font.Gotham
            PBtn.TextSize = 12
            PBtn.TextXAlignment = Enum.TextXAlignment.Left
            Instance.new("UICorner", PBtn).CornerRadius = UDim.new(0, 4)
            local bStroke = Instance.new("UIStroke", PBtn)
            bStroke.Color = Color3.fromRGB(40, 40, 40)
            
            if CurrentSelectedPlayer == p then
                bStroke.Color = Color3.fromRGB(255, 215, 0)
            end

            PBtn.MouseButton1Click:Connect(function()
                for _, b in pairs(ListScroll:GetChildren()) do
                    if b:IsA("TextButton") then b.UIStroke.Color = Color3.fromRGB(40, 40, 40) end
                end
                bStroke.Color = Color3.fromRGB(255, 215, 0)
                CurrentSelectedPlayer = p
                if WhitelistPlayers[p.Name] then
                    StatusLabel.Text = "เลือก: " .. p.DisplayName .. " (@" .. p.Name .. ") (สถานะ: ไวริสอยู่)"
                else
                    StatusLabel.Text = "เลือก: " .. p.DisplayName .. " (@" .. p.Name .. ")"
                end
                -- อัปเดตข้อมูล RAW ทันทีเมื่อเปลี่ยนคนเลือก
                updateJunkViewerLive()
            end)
        end
    end
    ListScroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y)
end

-- ==================== ฟังก์ชันอัปเดตหน้าต่าง RAW ขยะดึงสด ====================
function updateJunkViewerLive()
    if not JunkFrame.Visible or not CurrentSelectedPlayer then return end
    local targetPlayer = Players:FindFirstChild(CurrentSelectedPlayer.Name)
    if not targetPlayer then return end
    
    local soundObjects = checkPlayerAllSounds(targetPlayer)
    if #soundObjects == 0 then 
        JunkTextLabel.Text = "❌ ไม่พบออบเจกต์เสียงบนตัวผู้เล่นนี้ (เสียงอาจหยุดเล่นแล้ว)"
        return 
    end
    
    local fullJunkText = ""
    for i, obj in ipairs(soundObjects) do
        fullJunkText = fullJunkText .. string.format("[%d] ออบเจกต์: %s\nID ดั้งเดิม: %s\n\n", i, obj:GetFullName(), obj.SoundId)
    end
    
    if JunkTextLabel.Text ~= fullJunkText then
        JunkTextLabel.Text = fullJunkText
        local textBounds = game:GetService("TextService"):GetTextSize(fullJunkText, 11, Enum.Font.Code, Vector2.new(JunkScroll.AbsoluteSize.X - 15, math.huge))
        JunkTextLabel.Size = UDim2.new(1, -10, 0, textBounds.Y + 20)
        JunkScroll.CanvasSize = UDim2.new(0, 0, 0, textBounds.Y + 40)
    end
end

-- ==================== ปุ่มกดทำงาน ====================
GetIDBtn.MouseButton1Click:Connect(function()
    if CurrentSelectedPlayer then
        StatusLabel.Text = "🔍 กำลังดึงข้อมูลทันที..."
        directLogMusicID(CurrentSelectedPlayer.Name)
    else
        StatusLabel.Text = "⚠️ โปรดเลือกชื่อผู้เล่นก่อนกดดึง!"
    end
end)

GetJunkBtn.MouseButton1Click:Connect(function()
    if CurrentSelectedPlayer then
        StatusLabel.Text = "📦 กำลังก็อปขยะและเล่นเพลงตามขยะ..."
        task.wait(0.01)
        local result = directLogRawJunk(CurrentSelectedPlayer.Name)
        if not result then
            StatusLabel.Text = "❌ ไม่พบเสียงใด ๆ บนตัวผู้เล่นนี้"
        end
    else
        StatusLabel.Text = "⚠️ โปรดเลือกชื่อผู้เล่นก่อนกดดึง!"
    end
end)

ViewRawJunkBtn.MouseButton1Click:Connect(function()
    if CurrentSelectedPlayer then
        JunkFrame.Visible = true
        updateJunkViewerLive()
        StatusLabel.Text = "👁️ เปิดหน้าต่างแสดงขยะ RAW เรียลไทม์ 100% แล้ว"
    else
        StatusLabel.Text = "⚠️ โปรดเลือกชื่อผู้เล่นในตารางก่อนกดดูขยะดิบ!"
    end
end)

JunkCopyBtn.MouseButton1Click:Connect(function()
    if JunkTextLabel.Text ~= "ไม่มีข้อมูล..." and not string.find(JunkTextLabel.Text, "❌") then
        copyToClipboard(JunkTextLabel.Text)
        StatusLabel.Text = "📋 คัดลอกขยะ RAW ทั้งหมดไปคลิปบอร์ดแล้ว!"
    end
end)

JunkBackBtn.MouseButton1Click:Connect(function()
    JunkFrame.Visible = false
    StatusLabel.Text = "⬅️ ย้อนกลับมาหน้าต่างหลักแล้ว"
end)

WhitelistBtn.MouseButton1Click:Connect(function()
    if CurrentSelectedPlayer then
        if WhitelistPlayers[CurrentSelectedPlayer.Name] then
            WhitelistPlayers[CurrentSelectedPlayer.Name] = nil
            StatusLabel.Text = "🗑️ ลบ @" .. CurrentSelectedPlayer.Name .. " ออกจากตารางไวริสแล้ว"
        else
            WhitelistPlayers[CurrentSelectedPlayer.Name] = true
            StatusLabel.Text = "✅ เพิ่ม @" .. CurrentSelectedPlayer.Name .. " เข้าตารางไวริสเรียบร้อย!"
        end
        refreshPlayers()
    else
        StatusLabel.Text = "⚠️ โปรดเลือกชื่อผู้เล่นในตารางก่อนกดตั้งค่าไวริส!"
    end
end)

RefreshBtn.MouseButton1Click:Connect(refreshPlayers)

Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(function(p)
    if CurrentSelectedPlayer == p then
        CurrentSelectedPlayer = nil
        StatusLabel.Text = "โปรดเลือกผู้เล่น..."
    end
    if WhitelistPlayers[p.Name] then WhitelistPlayers[p.Name] = nil end
    refreshPlayers()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    if not MainFrame.Visible then 
        JunkFrame.Visible = false 
    else
        refreshPlayers() -- รีเฟรชข้อมูลเมื่อเปิดหน้าจอขึ้นมาใหม่
    end
end)

-- ==================== ระบบจัดการ Event แบบไม่กิน CPU (ลื่นไหล 100%) ====================
-- ลูปตรวจสอบแบบห่างๆ (ทุกๆ 1 วินาที) เผื่อกันการหลุดรอด ป้องกันอาการแลคจากการลูปถี่ยิบ
task.spawn(function()
    while true do
        task.wait(1) 
        if MainFrame.Visible then
            pcall(function()
                refreshPlayers()
                updateJunkViewerLive()
            end)
        end
    end
end)

refreshPlayers()
