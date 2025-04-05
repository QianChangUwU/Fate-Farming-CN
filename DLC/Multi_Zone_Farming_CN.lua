--[[

********************************************************************************
*                                多区域自动化Fate                              *
*                                   版本  1.0.2  CN-1.02                       *
********************************************************************************

多区域自动化Fate旨在与Fate_Farming_CN.lua配合使用。
该脚本会按照区域列表依次刷Fate，直到当前区域没有符合条件的Fate为止，
然后传送至下一个区域并重新启动刷Fate脚本。

原作者: pot0to (https://ko-fi.com/pot0to)
汉化: QianChang 联系方式:2318933089(QQ) 主页(https://github.com/QianChangUwU)
        
    -> 1.0.2  添加时间检测
        添加了对死亡和意外战斗的检测

--#region Settings

--[[
********************************************************************************
*                                   设置                                       *
********************************************************************************
]]

FateMacro = "Fate Farming"      -- 你的SND主脚本名称
AfterScriptStopTP = "部队房屋"  -- 脚本达到设置的时间后回哪儿
MaxRunTimeInHours = 6           -- 设置脚本运行的最大时间（支持小数，如1.5表示1小时30分钟）
NotifyBeforeStopMinutes = 5     -- 在停止前多少分钟发出提醒

ScriptStartTime = os.clock()  -- 记录脚本开始运行的时间（不用动）
LastNotificationTime = 0      -- 记录上次通知时间
TimeLimitReached = false      -- 标记是否已达到时间限制
-- 区域列表
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
--    { zoneName = "黑风海", zoneId = 813 },


--#endregion Settings

------------------------------------------------------------------------------------------------------------------------------------------------------

--[[
********************************************************************************
*           这里是代码：除非你知道你在做什么不然不要动它                        *
********************************************************************************
]]


CharacterCondition = {
    casting=27,
    betweenAreas=45,
    dead=2,
    inCombat=26
}

function TeleportTo(aetheryteName)
    yield("/tp "..aetheryteName)
    yield("/wait 1") -- wait for casting to begin
    while GetCharacterCondition(CharacterCondition.casting) do
        yield("/wait 1")
    end
    yield("/wait 1") -- wait for that microsecond in between the cast finishing and the transition beginning
    while GetCharacterCondition(CharacterCondition.betweenAreas) do
        yield("/wait 1")
    end
    yield("/wait 1")
end

function CheckTimeLimit()
    local currentRunTimeInHours = (os.clock() - ScriptStartTime) / 3600
    local remainingMinutes = (MaxRunTimeInHours - currentRunTimeInHours) * 60
    
    -- 提前通知
    if remainingMinutes <= NotifyBeforeStopMinutes and remainingMinutes > 0 and 
       (os.clock() - LastNotificationTime) > 60 then
        yield("/echo [提醒] 脚本将在约 "..math.floor(remainingMinutes).." 分钟后停止运行！")
        LastNotificationTime = os.clock()
    end
    
    -- 达到时间限制
    if currentRunTimeInHours >= MaxRunTimeInHours and not TimeLimitReached then
        TimeLimitReached = true
        yield("/echo [时间到] 脚本已运行 "..MaxRunTimeInHours.." 小时，正在停止...")
        yield("/snd stop "..FateMacro)
        yield("/wait 3")
        TeleportTo(AfterScriptStopTP)
        yield("/echo [完成] 脚本已安全停止并传送至 "..AfterScriptStopTP)
        return true
    end
    return false
end

FarmingZoneIndex = 1
OldBicolorGemCount = GetItemCount(26807)

while true do
    -- 检查时间限制
    if CheckTimeLimit() then
        break  -- 退出主循环
    end
    
    -- 原有逻辑
    if not IsPlayerOccupied() and not IsMacroRunningOrQueued(FateMacro) then
        if GetCharacterCondition(2) or GetCharacterCondition(26) or GetZoneID() == ZonesToFarm[FarmingZoneIndex].zoneId then
            LogInfo("[MultiZone] Starting FateMacro")
            yield("/snd run "..FateMacro)
            repeat
                yield("/wait 3")
                if CheckTimeLimit() then
                    break  -- 如果达到时间限制，提前退出
                end
            until not IsMacroRunningOrQueued(FateMacro)
            
            if TimeLimitReached then break end  -- 如果已超时则完全退出
            
            LogInfo("[MultiZone] FateMacro has stopped")
            NewBicolorGemCount = GetItemCount(26807)
            if NewBicolorGemCount == OldBicolorGemCount then
                yield("/echo 当前双色宝石: "..NewBicolorGemCount)
                FarmingZoneIndex = (FarmingZoneIndex % #ZonesToFarm) + 1
            else
                OldBicolorGemCount = NewBicolorGemCount
            end
        else
            LogInfo("[MultiZone] Teleporting to "..ZonesToFarm[FarmingZoneIndex].zoneName)
            TeleportTo(GetAetheryteName(GetAetherytesInZone(ZonesToFarm[FarmingZoneIndex].zoneId)[0]))
        end
    end
    yield("/wait 1")
end
--#endregion