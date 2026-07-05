--[=====[
[[SND Metadata]]
author: 'QianChang'
version: 1.0.0 CN
description: "半魂晶 Farming - Fate Farming 配套脚本（7.0区域）"
plugin_dependencies:
- Lifestream
- vnavmesh
- TextAdvance
configs:
  FateMacro:
    description: "Fate Farming脚本在SND中的名字(如果你用GitHub导入，默认为'Fate Farming')"
    default: Fate Farming
  青色半魂晶:
    description: "需要刷取的青色半魂晶数量（0=不刷，最多3个）"
    default: 3
    min: 0
    max: 3
  碧色半魂晶:
    description: "需要刷取的碧色半魂晶数量（0=不刷，最多3个）"
    default: 3
    min: 0
    max: 3
  绿色半魂晶:
    description: "需要刷取的绿色半魂晶数量（0=不刷，最多3个）"
    default: 3
    min: 0
    max: 3
  橙色半魂晶:
    description: "需要刷取的橙色半魂晶数量（0=不刷，最多3个）"
    default: 3
    min: 0
    max: 3
  紫色半魂晶:
    description: "需要刷取的紫色半魂晶数量（0=不刷，最多3个）"
    default: 3
    min: 0
    max: 3
  黄色半魂晶:
    description: "需要刷取的黄色半魂晶数量（0=不刷，最多3个）"
    default: 3
    min: 0
    max: 3

[[End Metadata]]
--]=====]

--[[

********************************************************************************
*                              半魂晶 Farming                                   *
*                              Version 1.0.0 CN                                 *
********************************************************************************

半魂晶 farming 脚本，需配合 `Fate_Farming_CN.lua` 使用。本脚本会依次
遍历7.0区域的半魂晶列表，在当前区域刷 FATE 直到背包中拥有设定数量的
半魂晶，然后传送到下一个区域并重新启动 Fate Farming 脚本。

每种半魂晶可单独设置刷取数量（0-3），设置为0则跳过该区域。

创建者/汉化: QianChang (https://afdian.com/a/QianChang)

    -> 1.0.0    首个版本
                支持6种半魂晶的自动刷取（7.0区域）
                每种半魂晶可单独设置刷取数量（0-3）

--#region Settings

--[[
********************************************************************************
*                                   设置                                       *
********************************************************************************
]]

FateMacro = Config.Get("FateMacro")

-- 半魂晶数据表（7.0区域）
HalfSouls =
{
    {zoneName = "奥阔帕恰山",   zoneId = 1187, itemName = "青色半魂晶", itemId = 47744, configKey = "青色半魂晶"},
    {zoneName = "克扎玛乌卡湿地", zoneId = 1188, itemName = "碧色半魂晶", itemId = 47745, configKey = "碧色半魂晶"},
    {zoneName = "亚克特尔树海",   zoneId = 1189, itemName = "绿色半魂晶", itemId = 47746, configKey = "绿色半魂晶"},
    {zoneName = "夏劳尼荒野",   zoneId = 1190, itemName = "橙色半魂晶", itemId = 47747, configKey = "橙色半魂晶"},
    {zoneName = "遗产之地",     zoneId = 1191, itemName = "紫色半魂晶", itemId = 47748, configKey = "紫色半魂晶"},
    {zoneName = "活着的记忆",   zoneId = 1192, itemName = "黄色半魂晶", itemId = 47749, configKey = "黄色半魂晶"}
}

-- 读取每种半魂晶的目标数量
for _, halfSoul in ipairs(HalfSouls) do
    halfSoul.targetCount = Config.Get(halfSoul.configKey)
    Dalamud.Log("[HalfSoul Farm] " .. halfSoul.itemName .. " 目标数量: " .. tostring(halfSoul.targetCount))
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

-- 当收到聊天消息时触发，检测主脚本是否已停止
function OnChatMessage()
    local message = TriggerData.message
    local patternToMatch = "%[Fate%] Loop Ended !!"

    if message and message:find(patternToMatch) then
        Dalamud.Log("[HalfSoul Farm] OnChatMessage 触发")
        FateMacroRunning = false
        Dalamud.Log("[HalfSoul Farm] FateMacro 已停止")
    end
end

-- 根据区域ID获取该区域的以太水晶名称
function GetAetheryteName(zoneId)
    for _, aetheryte in ipairs(Svc.AetheryteList) do
        if aetheryte.TerritoryId == zoneId then
            local name = aetheryte.AetheryteData.Value.PlaceName.Value.Name:GetText()
            if name ~= nil then
                return name
            end
        end
    end
    return nil
end

-- 获取下一个需要刷的半魂晶信息
-- 跳过目标数量为0或已刷够的半魂晶
function GetNextHalfSoulTable()
    for _, halfSoul in ipairs(HalfSouls) do
        if halfSoul.targetCount > 0 then
            local currentCount = Inventory.GetItemCount(halfSoul.itemId)
            if currentCount < halfSoul.targetCount then
                Dalamud.Log("[HalfSoul Farm] 下一个目标: " .. halfSoul.itemName ..
                    " (当前 " .. currentCount .. "/" .. halfSoul.targetCount .. ")")
                return halfSoul
            else
                Dalamud.Log("[HalfSoul Farm] " .. halfSoul.itemName .. " 已刷够 (" ..
                    currentCount .. "/" .. halfSoul.targetCount .. ")，跳过")
            end
        else
            Dalamud.Log("[HalfSoul Farm] " .. halfSoul.itemName .. " 目标为0，跳过")
        end
    end
    return nil
end

-- 传送到指定以太水晶，并等待区域加载完成
function TeleportTo(aetheryteName, expectedZoneId)
    yield("/li " .. aetheryteName)
    yield("/wait 1") -- 等待传送施法开始
    while Svc.Condition[CharacterCondition.casting] do
        Dalamud.Log("[HalfSoul Farm] 正在传送施法...")
        yield("/wait 1")
    end
    yield("/wait 1") -- 等待施法结束和区域切换之间的微小间隔
    while Svc.Condition[CharacterCondition.betweenAreas] do
        Dalamud.Log("[HalfSoul Farm] 正在传送...")
        yield("/wait 1")
    end
    -- 等待 TerritoryType 更新为目标区域（最多等10秒）
    local waitCount = 0
    while tonumber(Svc.ClientState.TerritoryType) ~= expectedZoneId and waitCount < 10 do
        Dalamud.Log("[HalfSoul Farm] 等待区域加载... (" .. waitCount .. ")")
        yield("/wait 1")
        waitCount = waitCount + 1
    end
    yield("/wait 1")
end

-- 打印刷取计划摘要
Dalamud.Log("[HalfSoul Farm] === 半魂晶刷取计划 ===")
for _, halfSoul in ipairs(HalfSouls) do
    if halfSoul.targetCount > 0 then
        local currentCount = Inventory.GetItemCount(halfSoul.itemId)
        Dalamud.Log("[HalfSoul Farm] " .. halfSoul.itemName .. ": " ..
            currentCount .. "/" .. halfSoul.targetCount .. " (" .. halfSoul.zoneName .. ")")
    end
end
Dalamud.Log("[HalfSoul Farm] ======================")

-- 启动脚本
yield("/at y")
NextHalfSoul = GetNextHalfSoulTable()

-- 如果所有半魂晶目标都为0，提示并退出
if NextHalfSoul == nil then
    yield("/echo [HalfSoul Farm] 所有半魂晶目标数量均为0，无需刷取。请在设置中调整目标数量。")
    return
end

yield("/echo [HalfSoul Farm] 开始半魂晶 Farming!")

while NextHalfSoul ~= nil do
    -- 防护: 玩家角色未加载时等待
    if Svc.Objects.LocalPlayer == nil then
        Dalamud.Log("[HalfSoul Farm] LocalPlayer 为空，等待中...")
        yield("/wait 1")
    -- 死亡或战斗中时不操作
    elseif Svc.Condition[CharacterCondition.dead] or Svc.Condition[CharacterCondition.inCombat] then
        Dalamud.Log("[HalfSoul Farm] 死亡或战斗中，等待...")
        yield("/wait 1")
    -- 玩家不在目标区域，需要传送
    elseif tonumber(Svc.Objects.LocalPlayer.TerritoryType) ~= NextHalfSoul.zoneId then
        local aetheryteName = GetAetheryteName(NextHalfSoul.zoneId)
        if aetheryteName then
            Dalamud.Log("[HalfSoul Farm] 传送到 " .. NextHalfSoul.zoneName)
            yield("/echo [HalfSoul Farm] 传送到 " .. NextHalfSoul.zoneName .. " 刷取 " .. NextHalfSoul.itemName)
            TeleportTo(aetheryteName, NextHalfSoul.zoneId)
        else
            Dalamud.Log("[HalfSoul Farm] 无法找到区域 " .. NextHalfSoul.zoneName .. " 的以太水晶!")
            yield("/echo [HalfSoul Farm] 错误: 无法找到区域 " .. NextHalfSoul.zoneName .. " 的以太水晶!")
            yield("/wait 1")
        end
    -- 玩家在目标区域且空闲，启动 Fate Farming
    elseif not Player.IsBusy and not FateMacroRunning then
        local currentCount = Inventory.GetItemCount(NextHalfSoul.itemId)
        Dalamud.Log("[HalfSoul Farm] 启动 FateMacro (" .. NextHalfSoul.itemName ..
            " " .. currentCount .. "/" .. NextHalfSoul.targetCount .. ")")
        yield("/snd run " .. FateMacro)
        FateMacroRunning = true

        -- 等待 FateMacro 结束（最多30分钟超时）
        local fateTimeout = 0
        while FateMacroRunning and fateTimeout < 1800 do
            yield("/wait 3")
            fateTimeout = fateTimeout + 3
        end
        if fateTimeout >= 1800 then
            Dalamud.Log("[HalfSoul Farm] FateMacro 超时（30分钟），强制继续")
            yield("/echo [HalfSoul Farm] 警告: FateMacro 运行超时（30分钟），强制继续")
        end
        yield("/wait 1") -- 等待游戏状态稳定

        Dalamud.Log("[HalfSoul Farm] FateMacro 已停止")
        -- 检查是否已刷够当前半魂晶
        currentCount = Inventory.GetItemCount(NextHalfSoul.itemId)
        if currentCount >= NextHalfSoul.targetCount then
            yield("/echo [HalfSoul Farm] " .. NextHalfSoul.itemName .. " 已完成 (" ..
                currentCount .. "/" .. NextHalfSoul.targetCount .. ")")
            NextHalfSoul = GetNextHalfSoulTable()
            if NextHalfSoul == nil then
                Dalamud.Log("[HalfSoul Farm] 所有半魂晶已刷完!")
            end
        else
            Dalamud.Log("[HalfSoul Farm] " .. NextHalfSoul.itemName ..
                " 尚未刷够 (" .. currentCount .. "/" .. NextHalfSoul.targetCount .. ")，继续刷取")
        end
    end
    yield("/wait 1")
end

yield("/echo [HalfSoul Farm] 半魂晶 Farming 全部完成!")
