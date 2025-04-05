--[[

********************************************************************************
*                                自动化古武魂晶                                *
*                                  版本  1.0.1  CN-1.00                        *
********************************************************************************

古武魂晶刷取脚本，旨在与Fate_Farming_CN.lua配合使用。
该脚本会按照古武魂晶刷取区域列表依次刷Fate，
直到你的背包中拥有12个所需的古武魂晶为止，
然后传送至下一个区域并重新启动刷Fate脚本。

原作者: pot0to (https://ko-fi.com/pot0to)
汉化: QianChang 联系方式:2318933089(QQ) 主页(https://github.com/QianChangUwU)
        
    -> 1.0.0    首次发布

--#region Settings

--[[
********************************************************************************
*                                   设置                                       *
********************************************************************************
]]

FateMacro = "Fate Farming"      -- 主脚本SND名称
NumberToFarm = 1                -- 每个地图刷多少个古武魂晶

--#endregion Settings

------------------------------------------------------------------------------------------------------------------------------------------------------

--[[
********************************************************************************
*           这里是代码：除非你知道你在做什么不然不要动它                        *
********************************************************************************
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

NextAtmaTable = GetNextAtmaTable()
while NextAtmaTable ~= nil do
    if not IsPlayerOccupied() and not IsMacroRunningOrQueued(FateMacro) then
        if GetItemCount(NextAtmaTable.itemId) >= NumberToFarm then
            NextAtmaTable = GetNextAtmaTable()
        elseif not IsInZone(NextAtmaTable.zoneId) then
            TeleportTo(GetAetheryteName(GetAetherytesInZone(NextAtmaTable.zoneId)[0]))
        else
            yield("/snd run "..FateMacro)
        end
    end
    yield("/wait 1")
end