--[[

********************************************************************************
*                               自动化魂武水晶                                 *
*                                版本  1.0.1  CN-1.00                          *
********************************************************************************

自动化魂武刷取脚本，旨在与Fate_Farming_CN.lua配合使用。
该脚本会按照魂武水晶刷取区域列表依次刷Fate，
直到你的背包中拥有足够数量的所需水晶为止，
然后传送至下一个区域并重新启动刷Fate脚本。

原作者: pot0to (https://ko-fi.com/pot0to)
汉化: QianChang 联系方式:2318933089(QQ) 主页(https://github.com/QianChangUwU)
        
    -> 1.0.1    Added mounted character condition
                首次发布

--#region Settings

--[[
********************************************************************************
*                                   Settings                                   *
********************************************************************************
]]

FateMacro = "Fate Farming"      -- 主脚本SND名称
NumberToFarm = 1                -- 每个地图刷多少个魂武水晶

--#endregion Settings

------------------------------------------------------------------------------------------------------------------------------------------------------

--[[
********************************************************************************
*           这里是代码：除非你知道你在做什么不然不要动它                        *
********************************************************************************
]]
Atmas =
{
    {zoneName = "库尔扎斯西部高地", zoneId = 397, itemName = "流光冰之水晶", itemId = 13569},
    {zoneName = "龙堡参天高地", zoneId = 398, itemName = "流光土之水晶", itemId = 13572},
    {zoneName = "龙堡内陆低地", zoneId = 399, itemName = "流光水之水晶", itemId = 13574},
    {zoneName = "翻云雾海", zoneId = 400, itemName = "流光雷之水晶", itemId = 13573},
    {zoneName = "阿巴拉提亚云海", zoneId = 401, itemName = "流光风之水晶", itemId = 13570},
    {zoneName = "魔大陆阿济兹拉", zoneId = 402, itemName = "流光火之水晶", itemId = 13571}
}

CharacterCondition = {
    mounted=4,
    casting=27,
    betweenAreas=45
}

function GetNextAtmaTable()
    for _, atmaTable in pairs(Atmas) do
        if GetItemCount(atmaTable.itemId) < NumberToFarm then
            return atmaTable
        end
    end
end

function TeleportTo(aetheryteName)
    yield("/tp "..aetheryteName)
    yield("/wait 1") -- wait for casting to begin
    while GetCharacterCondition(CharacterCondition.casting) do
        LogInfo("[FATE] Casting teleport...")
        yield("/wait 1")
    end
    yield("/wait 1") -- wait for that microsecond in between the cast finishing and the transition beginning
    while GetCharacterCondition(CharacterCondition.betweenAreas) do
        LogInfo("[FATE] Teleporting...")
        yield("/wait 1")
    end
    yield("/wait 1")
end

function GoToDravanianHinterlands()
    if GetCharacterCondition(CharacterCondition.betweenAreas) then
        return
    elseif IsInZone(478) then
        if not GetCharacterCondition(CharacterCondition.mounted) then
            State = CharacterState.mounting
            LogInfo("[DailyHunts] State Change: Mounting")
        elseif not PathIsRunning() and not PathfindInProgress() then
            PathfindAndMoveTo(148.51, 207.0, 118.47)
        end
    else
        TeleportTo("田园郡")
    end
end

NextAtmaTable = GetNextAtmaTable()
while NextAtmaTable ~= nil do
    if not IsPlayerOccupied() and not IsMacroRunningOrQueued(FateMacro) then
        if GetItemCount(NextAtmaTable.itemId) >= NumberToFarm then
            NextAtmaTable = GetNextAtmaTable()
        elseif not IsInZone(NextAtmaTable.zoneId) then
            if NextAtmaTable.zoneId == 399 then
                GoToDravanianHinterlands()
            else
                TeleportTo(GetAetheryteName(GetAetherytesInZone(NextAtmaTable.zoneId)[0]))
            end
        else
            yield("/snd run "..FateMacro)
        end
    end
    yield("/wait 1")
end