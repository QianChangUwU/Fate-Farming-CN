--[=====[
[[SND Metadata]]
author: 'pot0to || Updated by: baanderson40 || translator: QianChang'
version: 2.1.0 CN-1.0.1
description: "古武魂晶 farming - Fate Farming 配套脚本"
plugin_dependencies:
- Lifestream
- vnavmesh
- TextAdvance
configs:
  FateMacro:
    description: "Fate Farming脚本在SND中的名字(如果你用GitHub导入，默认为'Fate Farming')"
    default: Fate Farming
  NumberToFarm:
    description: "每种魂晶需要刷多少个？"
    default: 1

[[End Metadata]]
--]=====]

--[[

********************************************************************************
*                              古武魂晶 Farming                                *
*                              Version 2.1.0 CN                                *
********************************************************************************

古武魂晶 farming 脚本，需配合 `Fate_Farming_CN.lua` 使用。本脚本会依次
遍历魂晶 farming 区域列表，在当前区域刷 FATE 直到背包中拥有12个所需的
魂晶，然后传送到下一个区域并重新启动 Fate Farming 脚本。

创建者: pot0to (https://ko-fi.com/pot0to)
更新者: baanderson40 (https://ko-fi.com/baanderson40)
汉化: QianChang (https://afdian.com/a/QianChang)

    -> CN-1.0.1 修复重复传送问题
                1. 传送命令改为 /li tp（显式指定传送，避免Lifestream误解）
                2. 添加传送冷却（5秒），防止短时间内重复传送导致Lifestream混乱
                3. 添加 AcceptTeleportOffer 处理传送确认弹窗（SelectYesno）
                4. 主循环区域检测改用 Svc.ClientState.TerritoryType（权威来源）
                5. GetAetheryteName 中 aetheryte.TerritoryId 比较添加 tonumber() 防止NLua类型问题
                6. TeleportTo 添加三阶段超时保护（冷却30s/施法60s/区域切换120s）和返回值
                7. 施法等待时间从1秒增加到2秒，给Lifestream更多处理时间
    -> CN-1.0.0 汉化并修复适配当前版本 SND
                1. 修复 Svc.ClientState.LocalPlayer → Svc.Objects.LocalPlayer
                2. 修复 not ... == 运算符优先级 bug（导致区域判断永远失败）
                3. 修复 GetAetheryteName 对返回值用 [0] 索引的 bug
                4. 修复 GetAetheryteName 使用 Excel.GetRow 不可靠的问题，改用 Svc.AetheryteList
                5. 修复获取下一个魂晶后不传送区域的问题（重构主逻辑流程）
                6. 添加 LocalPlayer nil 检查防止脚本崩溃
                7. 添加死亡和战斗状态检查
                8. 使用 /li (Lifestream) 替换 /tp (Teleporter) 保持与 Multi_Zone 一致
                9. 将所有描述、注释、日志汉化
    -> 2.0.1    Updated CharacterCondition
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
NumberToFarm = Config.Get("NumberToFarm")

--#endregion Settings

------------------------------------------------------------------------------------------------------------------------------------------------------

--[[
**************************************************************
*  代码: 除非你知道自己在做什么，否则不要动下面的代码        *
**************************************************************
]]
Atmas =
{
    {zoneName = "中拉诺西亚", zoneId = 134, itemName = "白羊之魂晶", itemId = 7856},
    {zoneName = "拉诺西亚低地", zoneId = 135, itemName = "双鱼之魂晶", itemId = 7859},
    {zoneName = "西拉诺西亚", zoneId = 138, itemName = "巨蟹之魂晶", itemId = 7862},
    {zoneName = "拉诺西亚高地", zoneId = 139, itemName = "宝瓶之魂晶", itemId = 7853},
    {zoneName = "西萨纳兰", zoneId = 140, itemName = "双子之魂晶", itemId = 7857},
    {zoneName = "中萨纳兰", zoneId = 141, itemName = "天秤之魂晶", itemId = 7861},
    {zoneName = "东萨纳兰", zoneId = 145, itemName = "金牛之魂晶", itemId = 7855},
    {zoneName = "南萨纳兰", zoneId = 146, itemName = "天蝎之魂晶", itemId = 7852, flying=false},
    {zoneName = "黑衣森林中央林区", zoneId = 148, itemName = "室女之魂晶", itemId = 7851},
    {zoneName = "黑衣森林东部林区", zoneId = 152, itemName = "摩羯之魂晶", itemId = 7854},
    {zoneName = "黑衣森林北部林区", zoneId = 154, itemName = "人马之魂晶", itemId = 7860},
    {zoneName = "拉诺西亚外地", zoneId = 180, itemName = "狮子之魂晶", itemId = 7858, flying=false}
}
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
        Dalamud.Log("[Atma Farm] OnChatMessage 触发")
        FateMacroRunning = false
        Dalamud.Log("[Atma Farm] FateMacro 已停止")
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

-- 获取下一个需要刷的魂晶信息
function GetNextAtmaTable()
    for _, atmaTable in pairs(Atmas) do
        if Inventory.GetItemCount(atmaTable.itemId) < NumberToFarm then
            return atmaTable
        end
    end
end

-- 传送到指定以太水晶，并等待区域加载完成
function TeleportTo(aetheryteName, expectedZoneId)
    AcceptTeleportOffer()
    local start = os.clock()

    -- 传送冷却检查（防止短时间内重复传送导致Lifestream混乱）
    while os.clock() - LastTeleportTimeStamp < 5 do
        Dalamud.Log("[Atma Farm] 传送冷却中，等待...")
        yield("/wait 1")
        if os.clock() - start > 30 then
            yield("/echo [Atma Farm] 传送失败: 等待冷却超时")
            return false
        end
    end

    yield("/li tp " .. aetheryteName)
    yield("/wait 2") -- 等待Lifestream处理命令并开始施法

    while Svc.Condition[CharacterCondition.casting] do
        Dalamud.Log("[Atma Farm] 正在传送施法...")
        yield("/wait 1")
        if os.clock() - start > 60 then
            yield("/echo [Atma Farm] 传送失败: 施法超时")
            return false
        end
    end
    yield("/wait 1") -- 等待施法结束和区域切换之间的微小间隔
    while Svc.Condition[CharacterCondition.betweenAreas] do
        Dalamud.Log("[Atma Farm] 正在传送...")
        yield("/wait 1")
        if os.clock() - start > 120 then
            yield("/echo [Atma Farm] 传送失败: 区域切换超时")
            return false
        end
    end

    -- 等待 TerritoryType 更新为目标区域
    local waitCount = 0
    while tonumber(Svc.ClientState.TerritoryType) ~= expectedZoneId and waitCount < 15 do
        Dalamud.Log("[Atma Farm] 等待区域加载... (" .. waitCount .. ")")
        yield("/wait 1")
        waitCount = waitCount + 1
    end

    LastTeleportTimeStamp = os.clock()
    yield("/wait 1")
    return true
end

-- 启动脚本
yield("/at y")
NextAtmaTable = GetNextAtmaTable()

while NextAtmaTable ~= nil do
    -- 防护: 玩家角色未加载时等待
    if Svc.Objects.LocalPlayer == nil then
        Dalamud.Log("[Atma Farm] LocalPlayer 为空，等待中...")
        yield("/wait 1")
    -- 死亡或战斗中时不操作
    elseif Svc.Condition[CharacterCondition.dead] or Svc.Condition[CharacterCondition.inCombat] then
        Dalamud.Log("[Atma Farm] 死亡或战斗中，等待...")
        yield("/wait 1")
    -- 玩家不在目标区域，需要传送
    elseif tonumber(Svc.ClientState.TerritoryType) ~= NextAtmaTable.zoneId then
        local aetheryteName = GetAetheryteName(NextAtmaTable.zoneId)
        if aetheryteName then
            Dalamud.Log("[Atma Farm] 传送到 " .. NextAtmaTable.zoneName)
            TeleportTo(aetheryteName, NextAtmaTable.zoneId)
        else
            Dalamud.Log("[Atma Farm] 无法找到区域 " .. NextAtmaTable.zoneName .. " 的以太水晶!")
            yield("/wait 1")
        end
    -- 玩家在目标区域且空闲，启动 Fate Farming
    elseif not Player.IsBusy and not FateMacroRunning then
        Dalamud.Log("[Atma Farm] 启动 FateMacro")
        yield("/snd run " .. FateMacro)
        FateMacroRunning = true

        -- 等待 FateMacro 结束（最多30分钟超时）
        local fateTimeout = 0
        while FateMacroRunning and fateTimeout < 1800 do
            yield("/wait 3")
            fateTimeout = fateTimeout + 3
        end
        if fateTimeout >= 1800 then
            Dalamud.Log("[Atma Farm] FateMacro 超时（30分钟），强制继续")
            yield("/echo [Atma Farm] 警告: FateMacro 运行超时（30分钟），强制继续")
        end
        yield("/wait 1") -- 等待游戏状态稳定

        Dalamud.Log("[Atma Farm] FateMacro 已停止")
        -- 检查是否已刷够当前魂晶
        if Inventory.GetItemCount(NextAtmaTable.itemId) >= NumberToFarm then
            NextAtmaTable = GetNextAtmaTable()
            if NextAtmaTable ~= nil then
                Dalamud.Log("[Atma Farm] 切换到下一个魂晶: " .. NextAtmaTable.itemName .. " (" .. NextAtmaTable.zoneName .. ")")
            else
                Dalamud.Log("[Atma Farm] 所有魂晶已刷完!")
            end
        end
    end
    yield("/wait 1")
end

yield("/echo [Atma Farm] 古武魂晶 Farming 全部完成!")
