--[=====[
[[SND Metadata]]
author: 'pot0to || Updated by: Minnu || translator: QianChang'
version: 2.2.0 CN-1.2.1
description: "Multi Zone Farming(多区域Fate Farming) - Fate Farming 配套脚本"
plugin_dependencies:
- Lifestream
- vnavmesh
- TextAdvance
configs:
  FateMacro:
    description: "Fate Farming脚本在SND中的名字(如果你用GitHub导入，默认为'Fate Farming')"
    default: Fate Farming
  奥阔帕恰山:
    description: "是否在奥阔帕恰山刷FATE（7.0区域）"
    default: true
  克扎玛乌卡湿地:
    description: "是否在克扎玛乌卡湿地刷FATE（7.0区域）"
    default: true
  亚克特尔树海:
    description: "是否在亚克特尔树海刷FATE（7.0区域）"
    default: true
  夏劳尼荒野:
    description: "是否在夏劳尼荒野刷FATE（7.0区域）"
    default: true
  遗产之地:
    description: "是否在遗产之地刷FATE（7.0区域）"
    default: true
  活着的记忆:
    description: "是否在活着的记忆刷FATE（7.0区域）"
    default: true
  迷津:
    description: "是否在迷津刷FATE（6.0区域）"
    default: false
  萨维奈岛:
    description: "是否在萨维奈岛刷FATE（6.0区域）"
    default: false
  加雷马:
    description: "是否在加雷马刷FATE（6.0区域）"
    default: false
  叹息海:
    description: "是否在叹息海刷FATE（6.0区域）"
    default: false
  天外天垓:
    description: "是否在天外天垓刷FATE（6.0区域）"
    default: false
  厄尔庇斯:
    description: "是否在厄尔庇斯刷FATE（6.0区域）"
    default: false
  雷克兰德:
    description: "是否在雷克兰德刷FATE（5.0区域）"
    default: false
  珂露西亚岛:
    description: "是否在珂露西亚岛刷FATE（5.0区域）"
    default: false
  安穆·艾兰:
    description: "是否在安穆·艾兰刷FATE（5.0区域）"
    default: false
  伊尔美格:
    description: "是否在伊尔美格刷FATE（5.0区域）"
    default: false
  拉凯提卡大森林:
    description: "是否在拉凯提卡大森林刷FATE（5.0区域）"
    default: false
  黑风海:
    description: "是否在黑风海刷FATE（5.0区域）"
    default: false

[[End Metadata]]
--]=====]

--[[

********************************************************************************
*                             多区域 Fate Farming                               *
*                              Version 2.2.0 CN                                 *
********************************************************************************

多区域 farming 脚本，需配合 `Fate_Farming_CN.lua` 使用。本脚本会依次
遍历区域列表，在当前区域刷 FATE 直到没有可用的 FATE（通过双色宝石数量
是否增加来判断），然后传送到下一个区域并重新启动 Fate Farming 脚本。

可在设置中自由勾选需要刷取的区域（7.0/6.0/5.0），默认仅启用7.0区域。

创建者: pot0to (https://ko-fi.com/pot0to)
更新者: Minnu
汉化: QianChang (https://afdian.com/a/QianChang)

    -> CN-1.2.1 修复重复传送问题
                1. 传送命令改为 /li tp（显式指定传送，避免Lifestream误解）
                2. 添加传送冷却（5秒），防止短时间内重复传送导致Lifestream混乱
                3. 添加 AcceptTeleportOffer 处理传送确认弹窗（SelectYesno）
                4. GetAetheryteName 中 aetheryte.TerritoryId 比较添加 tonumber() 防止NLua类型问题
                5. TeleportTo 添加三阶段超时保护（冷却30s/施法60s/区域切换120s）和返回值
                6. 施法等待时间从1秒增加到2秒，给Lifestream更多处理时间
    -> CN-1.2.0 添加区域选择功能
                1. 可在设置中自由勾选需要刷取的区域（7.0/6.0/5.0共18个区域）
                2. 默认仅启用7.0区域，6.0和5.0区域默认关闭
                3. 启动时打印已选区域列表
                4. 无已选区域时提示并退出
    -> CN-1.1.0 汉化并修复适配当前版本 SND
                1. 修复 GetAetheryteName 使用 Excel.GetRow 不可靠的问题，改用 Svc.AetheryteList
                2. 添加 LocalPlayer nil 检查防止加载画面时脚本崩溃
                3. 将所有描述、注释、日志汉化
                4. 添加 echo 提示消息（区域切换、FateMacro 启动/停止等）
                5. 在 TeleportTo 中添加日志输出方便调试
    -> 2.0.1    Switching from Teleporter to Lifestream
    -> 2.0.0    Updated for Latest SnD
    -> 1.0.1    Added check for death and unexpected combat
                First release

--#region Settings

--[[
********************************************************************************
*                                   设置                                       *
********************************************************************************
]]

FateMacro = Config.Get("FateMacro")

-- 所有可用区域（7.0/6.0/5.0）
AllZones = {
    -- 7.0地图
    { zoneName = "奥阔帕恰山",     zoneId = 1187, configKey = "奥阔帕恰山" },
    { zoneName = "克扎玛乌卡湿地", zoneId = 1188, configKey = "克扎玛乌卡湿地" },
    { zoneName = "亚克特尔树海",   zoneId = 1189, configKey = "亚克特尔树海" },
    { zoneName = "夏劳尼荒野",     zoneId = 1190, configKey = "夏劳尼荒野" },
    { zoneName = "遗产之地",       zoneId = 1191, configKey = "遗产之地" },
    { zoneName = "活着的记忆",     zoneId = 1192, configKey = "活着的记忆" },
    -- 6.0地图
    { zoneName = "迷津",           zoneId = 956,  configKey = "迷津" },
    { zoneName = "萨维奈岛",       zoneId = 957,  configKey = "萨维奈岛" },
    { zoneName = "加雷马",         zoneId = 958,  configKey = "加雷马" },
    { zoneName = "叹息海",         zoneId = 959,  configKey = "叹息海" },
    { zoneName = "天外天垓",       zoneId = 960,  configKey = "天外天垓" },
    { zoneName = "厄尔庇斯",       zoneId = 961,  configKey = "厄尔庇斯" },
    -- 5.0地图
    { zoneName = "雷克兰德",       zoneId = 813,  configKey = "雷克兰德" },
    { zoneName = "珂露西亚岛",     zoneId = 814,  configKey = "珂露西亚岛" },
    { zoneName = "安穆·艾兰",      zoneId = 815,  configKey = "安穆·艾兰" },
    { zoneName = "伊尔美格",       zoneId = 816,  configKey = "伊尔美格" },
    { zoneName = "拉凯提卡大森林", zoneId = 817,  configKey = "拉凯提卡大森林" },
    { zoneName = "黑风海",         zoneId = 818,  configKey = "黑风海" }
}

-- 根据设置筛选已启用的区域
ZonesToFarm = {}
for _, zone in ipairs(AllZones) do
    if Config.Get(zone.configKey) then
        table.insert(ZonesToFarm, zone)
    end
end

--#endregion Settings

------------------------------------------------------------------------------------------------------------------------------------------------------

--[[
**************************************************************
*  代码: 除非你知道自己在做什么，否则不要动下面的代码        *
**************************************************************
]]

CharacterCondition = {
    dead         = 2,
    inCombat     = 26,
    casting      = 27,
    betweenAreas = 45
}

LastTeleportTimeStamp = 0

-- 当收到聊天消息时触发，检测主脚本是否已停止
function OnChatMessage()
    local message = TriggerData.message
    local patternToMatch = "%[Fate%] Loop Ended !!"

    if message and message:find(patternToMatch) then
        Dalamud.Log("[MultiZone] OnChatMessage 触发")
        FateMacroRunning = false
        Dalamud.Log("[MultiZone] FateMacro 已停止")
    end
end

-- 处理传送确认弹窗
function AcceptTeleportOffer()
    if Addons.GetAddon("SelectYesno").Ready then
        yield("/callback SelectYesno true 0")
        yield("/wait 0.5")
    end
end

-- 根据区域ID获取该区域的以太水晶名称
function GetAetheryteName(zoneId)
    for _, aetheryte in ipairs(Svc.AetheryteList) do
        if tonumber(aetheryte.TerritoryId) == zoneId then
            local name = aetheryte.AetheryteData.Value.PlaceName.Value.Name:GetText()
            if name ~= nil then
                return name
            end
        end
    end
    return nil
end

-- 传送到指定以太水晶，并等待区域加载完成
function TeleportTo(aetheryteName, expectedZoneId)
    AcceptTeleportOffer()
    local start = os.clock()

    -- 传送冷却检查（防止短时间内重复传送导致Lifestream混乱）
    while os.clock() - LastTeleportTimeStamp < 5 do
        Dalamud.Log("[MultiZone] 传送冷却中，等待...")
        yield("/wait 1")
        if os.clock() - start > 30 then
            yield("/echo [MultiZone] 传送失败: 等待冷却超时")
            return false
        end
    end

    yield("/li tp " .. aetheryteName)
    yield("/wait 2") -- 等待Lifestream处理命令并开始施法

    while Svc.Condition[CharacterCondition.casting] do
        Dalamud.Log("[MultiZone] 正在传送施法...")
        yield("/wait 1")
        if os.clock() - start > 60 then
            yield("/echo [MultiZone] 传送失败: 施法超时")
            return false
        end
    end
    yield("/wait 1") -- 等待施法结束和区域切换之间的微小间隔
    while Svc.Condition[CharacterCondition.betweenAreas] do
        Dalamud.Log("[MultiZone] 正在传送...")
        yield("/wait 1")
        if os.clock() - start > 120 then
            yield("/echo [MultiZone] 传送失败: 区域切换超时")
            return false
        end
    end

    -- 等待 TerritoryType 更新为目标区域
    local waitCount = 0
    while tonumber(Svc.ClientState.TerritoryType) ~= expectedZoneId and waitCount < 15 do
        Dalamud.Log("[MultiZone] 等待区域加载... (" .. waitCount .. ")")
        yield("/wait 1")
        waitCount = waitCount + 1
    end

    LastTeleportTimeStamp = os.clock()
    yield("/wait 1")
    return true
end

-- 启动脚本
yield("/at y")

-- 检查是否有已选区域
if #ZonesToFarm == 0 then
    yield("/echo [MultiZone] 错误: 未选择任何区域! 请在设置中至少启用一个区域。")
    return
end

FarmingZoneIndex = 1
OldBicolorGemCount = Inventory.GetItemCount(26807)

-- 打印已选区域列表
Dalamud.Log("[MultiZone] === 已选区域列表 ===")
yield("/echo [MultiZone] 开始多区域 Fate Farming! 共选择 " .. #ZonesToFarm .. " 个区域:")
for i, zone in ipairs(ZonesToFarm) do
    Dalamud.Log("[MultiZone] " .. i .. ". " .. zone.zoneName .. " (ID: " .. zone.zoneId .. ")")
    yield("/echo [MultiZone]   " .. i .. ". " .. zone.zoneName)
end
Dalamud.Log("[MultiZone] ======================")
yield("/echo [MultiZone] 起始区域: " .. ZonesToFarm[FarmingZoneIndex].zoneName)

while true do
    -- 防护: 玩家角色未加载时等待
    if Svc.Objects.LocalPlayer == nil then
        Dalamud.Log("[MultiZone] LocalPlayer 为空，等待中...")
        yield("/wait 1")
    elseif not Player.IsBusy and not FateMacroRunning then
        -- 死亡、战斗中、或已在目标区域 → 启动 FateMacro
        if Svc.Condition[CharacterCondition.dead] or Svc.Condition[CharacterCondition.inCombat] or tonumber(Svc.ClientState.TerritoryType) == ZonesToFarm[FarmingZoneIndex].zoneId then
            Dalamud.Log("[MultiZone] 启动 FateMacro (区域: " .. ZonesToFarm[FarmingZoneIndex].zoneName .. ")")
            yield("/snd run " .. FateMacro)
            FateMacroRunning = true

            -- 等待 FateMacro 结束
            -- 等待 FateMacro 结束（最多30分钟超时）
            local fateTimeout = 0
            while FateMacroRunning and fateTimeout < 1800 do
                yield("/wait 3")
                fateTimeout = fateTimeout + 3
            end
            if fateTimeout >= 1800 then
                Dalamud.Log("[MultiZone] FateMacro 超时（30分钟），强制继续")
                yield("/echo [MultiZone] 警告: FateMacro 运行超时（30分钟），强制继续")
            end
            yield("/wait 1") -- 等待游戏状态稳定

            Dalamud.Log("[MultiZone] FateMacro 已停止")
            NewBicolorGemCount = Inventory.GetItemCount(26807)

            -- 如果双色宝石数量没有增加，说明当前区域没有可做的 FATE，切换到下一个区域
            if NewBicolorGemCount == OldBicolorGemCount then
                FarmingZoneIndex = (FarmingZoneIndex % #ZonesToFarm) + 1
                Dalamud.Log("[MultiZone] 双色宝石无变化，切换到下一个区域: " .. ZonesToFarm[FarmingZoneIndex].zoneName)
                yield("/echo [MultiZone] 当前区域无可用 FATE，切换到: " .. ZonesToFarm[FarmingZoneIndex].zoneName)
            else
                OldBicolorGemCount = NewBicolorGemCount
                Dalamud.Log("[MultiZone] 双色宝石增加 (" .. OldBicolorGemCount .. " → " .. NewBicolorGemCount .. ")，继续当前区域")
            end
        else
            -- 不在目标区域，需要传送
            Dalamud.Log("[MultiZone] 传送到 " .. ZonesToFarm[FarmingZoneIndex].zoneName)
            yield("/echo [MultiZone] 传送到 " .. ZonesToFarm[FarmingZoneIndex].zoneName)
            local aetheryteName = GetAetheryteName(ZonesToFarm[FarmingZoneIndex].zoneId)

            if aetheryteName then
                TeleportTo(aetheryteName, ZonesToFarm[FarmingZoneIndex].zoneId)
            else
                Dalamud.Log("[MultiZone] 无法找到区域 " .. ZonesToFarm[FarmingZoneIndex].zoneName .. " 的以太水晶!")
                yield("/echo [MultiZone] 错误: 无法找到区域 " .. ZonesToFarm[FarmingZoneIndex].zoneName .. " 的以太水晶!")
                -- 跳到下一个区域
                FarmingZoneIndex = (FarmingZoneIndex % #ZonesToFarm) + 1
                yield("/wait 1")
            end
        end
    end
    yield("/wait 1")
end
