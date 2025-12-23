--[=====[
[[SND Metadata]]
author: 'pot0to || Updated by: Minnu'
version: 2.0.1
description: Multi Zone Farming - Companion script for Fate Farming
plugin_dependencies:
- Lifestream
- vnavmesh
- TextAdvance
configs:
  FateMacro:
    description: Name of the primary fate macro script.

[[End Metadata]]
--]=====]

--[[

********************************************************************************
*                             Multi Zone Farming                               *
*                                Version 2.0.0                                 *
********************************************************************************

Multi zone farming script meant to be used with `Fate Farming.lua`. This will go
down the list of zones and farm fates until there are no eligible fates left,
then teleport to the next zone and restart the fate farming script.

Created by: pot0to (https://ko-fi.com/pot0to)
Updated by: Minnu

    -> 2.0.1    Switching from Teleporter to Lifestream
    -> 2.0.0    Updated for Latest SnD
    -> 1.0.1    Added check for death and unexpected combat
                First release

--#region Settings

--[[
********************************************************************************
*                                   Settings                                   *
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
*  Code: Don't touch this unless you know what you're doing  *
**************************************************************
]]

CharacterCondition = {
    dead         = 2,
    inCombat     = 26,
    casting      = 27,
    betweenAreas = 45
}

function OnChatMessage()
    local message = TriggerData.message
    local patternToMatch = "%[Fate%] Loop Ended !!"

    if message and message:find(patternToMatch) then
        Dalamud.Log("[MultiZone] OnChatMessage triggered")
        FateMacroRunning = false
        Dalamud.Log("[MultiZone] FateMacro has stopped")
    end
end

function TeleportTo(aetheryteName)
    yield("/li " .. aetheryteName)
    yield("/wait 1")
    while Svc.Condition[CharacterCondition.casting] do
        yield("/wait 1")
    end
    yield("/wait 1")
    while Svc.Condition[CharacterCondition.betweenAreas] do
        yield("/wait 1")
    end
    yield("/wait 1")
end

function GetAetheryteName(ZoneID)
    local territoryData = Excel.GetRow("TerritoryType", ZoneID)

    if territoryData and territoryData.Aetheryte and territoryData.Aetheryte.PlaceName then
        return tostring(territoryData.Aetheryte.PlaceName.Name)
    end
end

FarmingZoneIndex = 1
OldBicolorGemCount = Inventory.GetItemCount(26807)

while true do
    if not Player.IsBusy and not FateMacroRunning then
        if Svc.Condition[CharacterCondition.dead] or Svc.Condition[CharacterCondition.inCombat] or Svc.ClientState.TerritoryType == ZonesToFarm[FarmingZoneIndex].zoneId then
            Dalamud.Log("[MultiZone] Starting FateMacro")
            yield("/snd run " .. FateMacro)
            FateMacroRunning = true

            while FateMacroRunning do
                yield("/wait 3")
            end

            Dalamud.Log("[MultiZone] FateMacro has stopped")
            NewBicolorGemCount = Inventory.GetItemCount(26807)

            if NewBicolorGemCount == OldBicolorGemCount then
                FarmingZoneIndex = (FarmingZoneIndex % #ZonesToFarm) + 1
            else
                OldBicolorGemCount = NewBicolorGemCount
            end
        else
            Dalamud.Log("[MultiZone] Teleporting to " .. ZonesToFarm[FarmingZoneIndex].zoneName)
            local aetheryteName = GetAetheryteName(ZonesToFarm[FarmingZoneIndex].zoneId)

            if aetheryteName then
                TeleportTo(aetheryteName)
            end
        end
    end
    yield("/wait 1")
end
