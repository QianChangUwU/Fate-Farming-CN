--[=====[
[[SND Metadata]]
author: 'pot0to || Updated by: Minnu || translator: QianChang'
version: 2.1.0 CN-1.1.0
description: "Multi Zone Farming(多区域Fate Farming) - Fate Farming 配套脚本"
plugin_dependencies:
- Lifestream
- vnavmesh
- TextAdvance
configs:
  FateMacro:
    description: "Fate Farming脚本在SND中的名字(如果你用GitHub导入，默认为'Fate Farming')"
    default: Fate Farming

[[End Metadata]]
--]=====]

--[[

********************************************************************************
*                             多区域 Fate Farming                               *
*                              Version 2.1.0 CN                                 *
********************************************************************************

多区域 farming 脚本，需配合 `Fate_Farming_CN.lua` 使用。本脚本会依次
遍历区域列表，在当前区域刷 FATE 直到没有可用的 FATE（通过双色宝石数量
是否增加来判断），然后传送到下一个区域并重新启动 Fate Farming 脚本。

创建者: pot0to (https://ko-fi.com/pot0to)
更新者: Minnu
汉化: QianChang (https://afdian.com/a/QianChang)

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

FateMacro   = Config.Get("FateMacro")

ZonesToFarm = {
    --7.0地图
    { zoneName = "奥阔帕恰山", zoneId = 1187 },
    { zoneName = "克扎玛乌卡湿地", zoneId = 1188 },
    { zoneName = "亚克特尔树海", zoneId = 1189 },
    { zoneName = "夏劳尼荒野", zoneId = 1190 },
    { zoneName = "遗产之地", zoneId = 1191 },
    { zoneName = "活着的记忆", zoneId = 1192 }
}


--      6.0地图
--    { zoneName = "迷津", zoneId = 956 },
--    { zoneName = "萨维奈岛", zoneId = 957 },
--    { zoneName = "加雷马", zoneId = 958 },
--    { zoneName = "叹息海", zoneId = 959 },
--    { zoneName = "天外天垓", zoneId = 960 },
--    { zoneName = "厄尔庇斯", zoneId = 961 },

--      5.0地图
--    { zoneName = "雷克兰德", zoneId = 813 },
--    { zoneName = "珂露西亚岛", zoneId = 814 },
--    { zoneName = "安穆·艾兰", zoneId = 815 },
--    { zoneName = "伊尔美格", zoneId = 816 },
--    { zoneName = "拉凯提卡大森林", zoneId = 817 },
--    { zoneName = "黑风海", zoneId = 818 },
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
        Dalamud.Log("[MultiZone] OnChatMessage 触发")
        FateMacroRunning = false
        Dalamud.Log("[MultiZone] FateMacro 已停止")
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

-- 传送到指定以太水晶
function TeleportTo(aetheryteName)
    yield("/li " .. aetheryteName)
    yield("/wait 1") -- 等待传送施法开始
    while Svc.Condition[CharacterCondition.casting] do
        Dalamud.Log("[MultiZone] 正在传送施法...")
        yield("/wait 1")
    end
    yield("/wait 1") -- 等待施法结束和区域切换之间的微小间隔
    while Svc.Condition[CharacterCondition.betweenAreas] do
        Dalamud.Log("[MultiZone] 正在传送...")
        yield("/wait 1")
    end
    yield("/wait 1")
end

-- 启动脚本
yield("/at y")
FarmingZoneIndex = 1
OldBicolorGemCount = Inventory.GetItemCount(26807)

Dalamud.Log("[MultiZone] 开始多区域 Fate Farming")
yield("/echo [MultiZone] 开始多区域 Fate Farming! 起始区域: " .. ZonesToFarm[FarmingZoneIndex].zoneName)

while true do
    -- 防护: 玩家角色未加载时等待
    if Svc.Objects.LocalPlayer == nil then
        Dalamud.Log("[MultiZone] LocalPlayer 为空，等待中...")
        yield("/wait 1")
    elseif not Player.IsBusy and not FateMacroRunning then
        -- 死亡、战斗中、或已在目标区域 → 启动 FateMacro
        if Svc.Condition[CharacterCondition.dead] or Svc.Condition[CharacterCondition.inCombat] or Svc.ClientState.TerritoryType == ZonesToFarm[FarmingZoneIndex].zoneId then
            Dalamud.Log("[MultiZone] 启动 FateMacro (区域: " .. ZonesToFarm[FarmingZoneIndex].zoneName .. ")")
            yield("/snd run " .. FateMacro)
            FateMacroRunning = true

            -- 等待 FateMacro 结束
            while FateMacroRunning do
                yield("/wait 3")
            end

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
                TeleportTo(aetheryteName)
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
