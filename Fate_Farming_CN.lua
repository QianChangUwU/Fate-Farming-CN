--[=====[
[[SND Metadata]]
author: 原作者：pot0to/汉化：QianChang
version: 3.0.1 CN-1.10
plugin_dependencies:
- YesAlready
- vnavmesh
- RotationSolver
- BossMod
- TextAdvance
- TeleporterPlugin
- Lifestream

[[End Metadata]]
--]=====]
--[[

********************************************************************************
*                                 Fate农场                                     *
*                           版本号: 3.0.1 CN-1.10                              *
********************************************************************************

作者: pot0to (https://ko-fi.com/pot0to)
原github库: https://github.com/pot0to/pot0to-SND-Scripts/blob/main/Fate%20Farming/Fate%20Farming.lua
汉化: QianChang 联系方式:2318933089(QQ) 主页(https://github.com/QianChangUwU)
    -> 2.22.2   Added option to turn off auto return on death
                Fixed to pick between /vnav flyflag and /vnav moveflag
                Updated vnav to use flag navigation, since it works better in
                    occult. Updated to prevent textadvance spam
                Added more logging for FlyBackToAetheryte
    -> 2.21.11  在上坐骑后添加1秒等待，这样你就可以牢牢地固定在坐骑上。似乎是
                    像中文这样的语言执行log和echo
                    消息速度比英语快，导致下一个Pathfind步骤
                    在正确安装之前，发生得太快，而
                    你正处在跳跃的中间。这迫使vnav给予
                    你是一条步行道，而不是一条飞行道，所以你
                    有时会卡住。
    -> 2.21.10  修复对vbmai预设的调用              
    -> 2.21.9   By Allison
            增加了检查到FATE距离的优先级，考虑到传送后可能的更短距离。
            增加了FatePriority设置。默认设置与之前相同，但增加了上述的新检查。
            优先级为：进度 -> 奖励 -> 剩余时间 -> 距离。
            增加了设置选项，用于在没有找到FATE时是否在以太之光处等待。如果禁用，你将在FATE完成的地方等待。
            增加了MinWait设置，因为有时3秒感觉太长了。
            更改了WaitUpTo的名称以匹配MinWait。
            增加了在使用RSR进行循环插件时禁用VBM目标选择的检查。
            对选择下一个FATE后的等待时间进行了小幅调整，结果是在接近FATE时会降落在离中心更远的地方。
            在移动中增加了新的额外检查，以防止施法取消。
            可能在从FATE中被推出时搞砸了一些东西。
            修复了“should it to Turn” -> “should it do Turn”的拼写错误。
        

********************************************************************************
*                                    必要插件                                   *
********************************************************************************

需要以下插件才能正常工作：

    -> Something Need Doing [Expanded Edition] : (核心插件)   https://puni.sh/api/repository/croizat   
    -> VNavmesh :   (用于规划路线和移动)    https://puni.sh/api/repository/veyn       
    -> RotationSolver Reborn :  (用于打自动循环)  https://raw.githubusercontent.com/FFXIV-CombatReborn/CombatRebornRepo/main/pluginmaster.json       
    -> RotationSolver Reborn配置：
        -> 在Target选项卡 -> 勾选 "Select only Fate targets in Fate" and DESELECT "Target Fate priority" (不然会攻击fate外的敌人)
        -> 在Target选项卡 -> 将"Engage settings" 设置为 "All targets that are in range for any abilities (Tanks/Autoduty)" 不管你用什么职业
        -> 在List选项卡 -> Map Specific Settings内 -> 添加 "Forlorn Maiden" 和 "The Forlorn" 为优先目标
        ->如果你用的是近战职业建议将 Target -> Configuration 内的-> gapcloser distance 设置为 20y
    -> TextAdvance: (用来和fate里的NPC互动)
    -> Teleporter :  (用来传送)
    -> Lifestream :  (用于更改实例[ChangeInstance][Exchange]（看不懂）) https://raw.githubusercontent.com/NightmareXIV/MyDalamudPlugins/main/pluginmaster.json
********************************************************************************
*                                    可选插件                                   *
********************************************************************************

This Plugins are Optional and not needed unless you have it enabled in the settings:

    -> AutoRetainer : (for Retainers [Retainers])   https://love.puni.sh/ment.json
    -> Deliveroo : (对于gc turn in [TurnIn])   https://plugins.carvel.li/
    -> Bossmod/BossModReborn: (用于AI躲避，如果是红职可能不开这个可能会死)  https://puni.sh/api/repository/veyn
                                                https://raw.githubusercontent.com/FFXIV-CombatReborn/CombatRebornRepo/main/pluginmaster.json
    -> ChatCoordinates : (用来在小地图标记下一个fate) available via base /xlplugins

--------------------------------------------------------------------------------------------------------------------------------------------------------------
]]

--#region Settings

--[[
********************************************************************************
*                                   设置                                   *
********************************************************************************
]]

Food                                = ""            --如果不想用任何食物，就将 "" 内留空. 如果想自动使用HQ食物就添加 <hq> 在食物后面，例如 "烧烤暗色茄子 <hq>"
Potion                              = ""            --如果不想用任何药就将 "" 内留空.
ShouldSummonChocobo                 = true         --是否召唤陆行鸟？
    ResummonChocoboTimeLeft         = 3 * 60        --如果陆行鸟剩余时间少于这个秒数，则重新召唤，以免在FATE中途消失。
    ChocoboStance                   = "治疗战术"      --陆行鸟选项: 跟随/自由战术/防护战术/治疗战术/进攻战术
    ShouldAutoBuyGysahlGreens       = true          --如果野菜用完了，自动从利姆萨·罗敏萨的商人处购买99个。
MountToUse                          = "随机飞行坐骑"       --在FATE之间飞行时使用的坐骑
FatePriority                        = {"DistanceTeleport", "Progress", "DistanceTeleport", "Bonus", "TimeLeft", "Distance"}

--Fate Combat Settings
CompletionToIgnoreFate              = 80            --设置一个阈值，如果当前地区已完成的fate数量高于这个阈值，则跳过
MinTimeLeftToIgnoreFate             = 3*60          --设置一个时间，如果fate剩余时间比这个时间少，则跳过（几个*60秒）
CompletionToJoinBossFate            = 0             --设置一个数字，如果fate的进度低于这个数字，则跳过 (用于避免单挑boss)
    CompletionToJoinSpecialBossFates = 20           --对于特殊FATE，如Serpentlord Seethes或Mascot Murder
    ClassForBossFates               = ""            --如果你想用特定的职业单挑boss，就在""内设置为三个字母的职业缩写（英文缩写）
                                                        --例如骑士为"PLD"
JoinCollectionsFates                = true          --设置为false表示永远不做收集FATE
BonusFatesOnly                      = false         --如果为true，则只做奖励提升FATE，忽略其他所有FATE

MeleeDist                           = 2.5           --近战距离。近战攻击（自动攻击）的最大距离为2.59y，2.60为“目标超出范围”
RangedDist                          = 20            --远程距离。远程攻击和法术的最大可用距离为25.49y，25.5为“目标超出范围”

RotationPlugin                      = "RSR"         --选项: RSR/BMR/VBM/Wrath/None，自动循环插件
    RSRAoeType                      = "Full"        --Options: Cleave/Full/Off，RSR的AOE方式

    -- 仅适用于BMR/VBM/Wrath
    RotationSingleTargetPreset      = ""            --单目标策略的预设名称（用于forlorns）。
    RotationAoePreset               = ""            --AOE + Buff策略的预设。
    RotationHoldBuffPreset          = ""            --在FATE进度达到指定百分比时保留120s爆发技能
    PercentageToHoldBuff            = 65            --理想情况下，你希望充分利用你的增益，高于70%仍然会浪费几秒，如果进度太快。
DodgingPlugin                       = "VBM"         --选项: BMR/VBM/None。自动躲避插件，如果你的RotationPlugin是BMR/VBM，则此设置将被覆盖。

IgnoreForlorns                      = false         --无视迷失少女
    IgnoreBigForlornOnly            = false         --仅忽略迷失者

--Post Fate Settings
MinWait                             = 3             --在下一个FATE前等待的最短秒数。
MaxWait                             = 10            --在下一个FATE前等待的最长秒数。
                                                        --实际等待时间将是MinWait和MaxWait之间的随机数。
DownTimeWaitAtNearestAetheryte      = false         --当等待FATE出现时，是否飞到最近的以太水晶并等待？
EnableChangeInstance                = true          --当没有FATE时是否切换副本区（仅适用于DT FATE）
    WaitIfBonusBuff                 = true          --如果你有fate奖励增益，则不切换副本区
    NumberOfInstances               = 2
ShouldExchangeBicolorGemstones      = true          --是否自动兑换物品
    ItemToPurchase                  = "图拉尔双色宝石的收据"        -- 双色票据：旧萨雷安填写 "双色宝石的收据" 九号解决方案则填写 "图拉尔双色宝石的收据" 其余物品也可以写名字（仅限非完成度物品）
SelfRepair                          = true         --是否自己修理，如果设置为 false, 就去 海都找修理工
    RemainingDurabilityToRepair                    = 20            --设置一个阈值，低于此阈值将会自动修理装备 (如果不需要自动修理，请将其设置为0)
    ShouldAutoBuyDarkMatter         = true          --如果你没有8级暗物质，则会自动从利姆萨的商人购买一组99个
ShouldExtractMateria                = true          --是否要自动精炼魔晶石？
Retainers                           = false         --是否自动收雇员 (需要AutoRetainers插件)
ShouldGrandCompanyTurnIn            = false         --是否自动交军票 (需要 Deliveroo 插件)
    InventorySlotsLeft              = 5             --在执行上交前剩余多少空余的背包空间

ReturnOnDeath                       = true          --自动接受死亡后返回

Echo                                = "All"         
--修改这个值来控制你在聊天中希望显示多少echo消息。
--None 不需要任何消息
--Gems 每个FATE结束后会显示当前双色宝石数量
--All 显示双色宝石数量，并提示下一个要前往的FATE名称

CompanionScriptMode                 = false         --Set to true if you are using the fate script with a companion script (such as the Atma Farmer)


--#endregion Settings

--[[
********************************************************************************
*           这里是代码：除非你知道你在做什么不然不要动它                           *
********************************************************************************
]]

--#region Plugin Checks and Setting Init

import("System.Numerics")

if DodgingPlugin == "None" then
    -- do nothing
elseif RotationPlugin == "BMR" and DodgingPlugin ~= "BMR" then
    DodgingPlugin = "BMR"
elseif RotationPlugin == "VBM" and DodgingPlugin ~= "VBM"  then
    DodgingPlugin = "VBM"
end

if not IPC.IsInstalled("vnavmesh") then
    yield("/echo [FATE]请安装 vnavmesh")
end

if not IPC.IsInstalled("TextAdvance") then
    yield("/echo [FATE]请安装 TextAdvance")
end

if EnableChangeInstance and not IPC.IsInstalled("Lifestream") then
    yield("/echo [FATE]请安装 Lifestream，或禁用 ChangeInstance")
end

if Retainers and not IPC.IsInstalled("AutoRetainer") then
    yield("/echo [FATE]请安装 AutoRetainer")
end

if ShouldGrandCompanyTurnIn and not IPC.IsInstalled("Deliveroo") then
    yield("/echo [FATE]请安装Deliveroo")
end

if not IPC.IsInstalled("YesAlready") then
    yield("/echo [FATE]请安装 YesAlready")
end

if not CompanionScriptMode then
    yield("/at y")
end

--#endregion Plugin Checks and Setting Init

--#region Data

CharacterCondition = {
    dead=2,
    mounted=4,
    inCombat=26,
    casting=27,
    occupiedInEvent=31,
    occupiedInQuestEvent=32,
    occupied=33,
    boundByDuty34=34,
    occupiedMateriaExtractionAndRepair=39,
    betweenAreas=45,
    jumping48=48,
    jumping61=61,
    occupiedSummoningBell=50,
    betweenAreasForDuty=51,
    boundByDuty56=56,
    mounting57=57,
    mounting64=64,
    beingMoved=70,
    flying=77
}

ClassList =
{
    gla = { classId=1, className="Gladiator", isMelee=true, isTank=true },
    pgl = { classId=2, className="Pugilist", isMelee=true, isTank=false },
    mrd = { classId=3, className="Marauder", isMelee=true, isTank=true },
    lnc = { classId=4, className="Lancer", isMelee=true, isTank=false },
    arc = { classId=5, className="Archer", isMelee=false, isTank=false },
    cnj = { classId=6, className="Conjurer", isMelee=false, isTank=false },
    thm = { classId=7, className="Thaumaturge", isMelee=false, isTank=false },
    pld = { classId=19, className="骑士",         isMelee=true,  isTank=true },
    mnk = { classId=20, className="武僧",         isMelee=true,  isTank=false },
    war = { classId=21, className="战士",           isMelee=true,  isTank=true },
    drg = { classId=22, className="龙骑士",         isMelee=true,  isTank=false },
    brd = { classId=23, className="吟游诗人",       isMelee=false, isTank=false },
    whm = { classId=24, className="白魔法师",       isMelee=false, isTank=false },
    blm = { classId=25, className="黑魔法师",       isMelee=false, isTank=false },
    smn = { classId=27, className="召唤师",         isMelee=false, isTank=false },
    sch = { classId=28, className="学者",           isMelee=false, isTank=false },
    nin = { classId=30, className="忍者",           isMelee=true,  isTank=false },
    mch = { classId=31, className="机工士",         isMelee=false, isTank=false},
    drk = { classId=32, className="暗黑骑士",       isMelee=true,  isTank=true },
    ast = { classId=33, className="占星术士",       isMelee=false, isTank=false },
    sam = { classId=34, className="武士",             isMelee=true,  isTank=false },
    rdm = { classId=35, className="赤魔法师",       isMelee=false, isTank=false },
    blu = { classId=36, className="青魔法师",       isMelee=false, isTank=false },
    gnb = { classId=37, className="绝枪战士", isMelee=true,  isTank=true },
    dnc = { classId=38, className="舞者",         isMelee=false, isTank=false },
    rpr = { classId=39, className="钐镰客",       isMelee=true,  isTank=false },
    sge = { classId=40, className="贤者",           isMelee=false, isTank=false },
    vpr = { classId=41, className="蝰蛇剑士",     isMelee=true,  isTank=false },
    pct = { classId=42, className="绘灵法师", isMelee=false, isTank=false }
}

BicolorExchangeData =
{
    {
        shopKeepName = "广域交易商 加德弗里德",
        zoneName = "旧萨雷安",
        zoneId = 962,
        aetheryteName = "旧萨雷安",
        position=Vector3(78, 5, -37),
        shopItems =
        {
            { itemName = "双色宝石的收据", itemIndex = 8, price = 100 },
            { itemName = "Ovibos Milk", itemIndex = 9, price = 2 },
            { itemName = "Hamsa Tenderloin", itemIndex = 10, price = 2 },
            { itemName = "Yakow Chuck", itemIndex = 11, price = 2 },
            { itemName = "Bird of Elpis Breast", itemIndex = 12, price = 2 },
            { itemName = "Egg of Elpis", itemIndex = 13, price = 2 },
            { itemName = "Amra", itemIndex = 14, price = 2 },
            { itemName = "Dynamis Crystal", itemIndex = 15, price = 2 },
            { itemName = "Almasty Fur", itemIndex = 16, price = 2 },
            { itemName = "Gaja Hide", itemIndex = 17, price = 2 },
            { itemName = "Luncheon Toad Skin", itemIndex = 18, price = 2 },
            { itemName = "Saiga Hide", itemIndex = 19, price = 2 },
            { itemName = "Kumbhira Skin", itemIndex = 20, price = 2 },
            { itemName = "Ophiotauros Hide", itemIndex = 21, price = 2 },
            { itemName = "Berkanan Sap", itemIndex = 22, price = 2 },
            { itemName = "Dynamite Ash", itemIndex = 23, price = 2 },
            { itemName = "Lunatender Blossom", itemIndex = 24, price = 2 },
            { itemName = "Mousse Flesh", itemIndex = 25, price = 2 },
            { itemName = "Petalouda Scales", itemIndex = 26, price = 2 },
        }
    },
    {
        shopKeepName = "广域交易商 贝瑞尔",
        zoneName = "九号解决方案",
        zoneId = 1186,
        aetheryteName = "九号解决方案",
        position=Vector3(-198.47, 0.92, -6.95),
        miniAethernet = {
            name = "联合商城",
            position=Vector3(-157.74, 0.29, 17.43)
        },
        shopItems =
        {
            { itemName = "图拉尔双色宝石的收据", itemIndex = 6, price = 100 },
            { itemName = "羊驼的里脊肉", itemIndex = 7, price = 3 },
            { itemName = "沼泽鬼鱼的腿肉", itemIndex = 8, price = 3 },
            { itemName = "犎牛肩肉", itemIndex = 9, price = 3 },
            { itemName = "巨龙舌兰的球茎", itemIndex = 10, price = 3 },
            { itemName = "拟鸟枝的果实", itemIndex = 11, price = 3 },
            { itemName = "Nopalitender Tuna", itemIndex = 12, price = 3 },
            { itemName = "Rroneek Fleece", itemIndex = 13, price = 3 },
            { itemName = "Silver Lobo Hide", itemIndex = 14, price = 3 },
            { itemName = "Hammerhead Crocodile Skin", itemIndex = 15, price = 3 },
            { itemName = "Br'aax Hide", itemIndex = 16, price = 3 },
            { itemName = "Gomphotherium Skin", itemIndex = 17, price = 3 },
            { itemName = "Gargantua Hide", itemIndex = 18, price = 3 },
            { itemName = "Ty'aitya Wingblade", itemIndex = 19, price = 3 },
            { itemName = "Poison Frog Secretions", itemIndex = 20, price = 3 },
            { itemName = "Alexandrian Axe Beak Wing", itemIndex = 21, price = 3 },
            { itemName = "Lesser Apollyon Shell", itemIndex = 22, price = 3 },
            { itemName = "Tumbleclaw Weeds", itemIndex = 23, price = 3 },
        }
    }
}

FatesData = {
    {
        zoneName = "库尔札斯中央高地",
        zoneId = 155,
        fatesList= {
            collectionsFates= {},
            otherNpcFates= {},
            fatesWithContinuations = {},
            blacklistedFates= {}
        }
    },
    {
        zoneName = "库尔札斯西部高地",
        zoneId = 397,
        fatesList= {
            collectionsFates= {},
            otherNpcFates= {},
            fatesWithContinuations = {},
            blacklistedFates= {}
        }
    },
    {
        zoneName = "摩杜纳",
        zoneId = 156,
        fatesList= {
            collectionsFates= {},
            otherNpcFates= {},
            fatesWithContinuations = {},
            blacklistedFates= {}
        }
    },
    {
        zoneName = "阿巴拉提亚云海",
        zoneId = 401,
        fatesList= {
            collectionsFates= {},
            otherNpcFates= {},
            fatesWithContinuations = {},
            blacklistedFates= {}
        }
    },
    {
        zoneName = "魔大陆阿济兹拉",
        zoneId = 402,
        fatesList= {
            collectionsFates= {},
            otherNpcFates= {},
            fatesWithContinuations = {},
            blacklistedFates= {}
        }
    },
    {
        zoneName = "龙堡参天高地",
        zoneId = 398,
        fatesList= {
            collectionsFates= {},
            otherNpcFates= {},
            fatesWithContinuations = {},
            blacklistedFates= {}
        }
    },
    {
        zoneName = "龙堡内陆低地",
        zoneId=399,
        tpZoneId = 478,
        fatesList= {
            collectionsFates= {},
            otherNpcFates= {},
            fatesWithContinuations = {},
            blacklistedFates= {}
        }
    },
    {
        zoneName = "翻云雾海",
        zoneId=400,
        fatesList= {
            collectionsFates= {},
            otherNpcFates= {},
            fatesWithContinuations = {},
            blacklistedFates= {}
        }
    },
    {
        zoneName = "雷克兰德",
        zoneId = 813,
        fatesList= {
            collectionsFates= {
                { fateName="樵夫之歌", npcName="雷克兰德的樵夫" }
            },
            otherNpcFates= {
                { fateName="与紫叶团的战斗之卑鄙陷阱", npcName="像是旅行商人的男子" }, --24 防御
                { fateName="污秽之血", npcName="乔布要塞的卫兵" } --24 防御
            },
            fatesWithContinuations = {
                "高度进化"
            },
            blacklistedFates= {}
        }
    },
    {
        zoneName = "珂露西亚岛",
        zoneId = 814,
        fatesList= {
            collectionsFates= {
                { fateName="制作战士之自走人偶", npcName="图尔家族的技师" }
            },
            otherNpcFates= {},
            fatesWithContinuations = {},
            specialFates = {
                "激斗畏惧装甲之秘密武器" -- 畏惧装甲（特殊FATE）
            },
            blacklistedFates= {}
        }
    },
    {
        zoneName = "安穆·艾兰",
        zoneId = 815,
        fatesList= {
            collectionsFates= {},
            otherNpcFates= {},
            fatesWithContinuations = {},
            blacklistedFates= {
                "托尔巴龟最棒" -- 去的的路上难打
            }
        }
    },
    {
        zoneName = "伊尔美格",
        zoneId = 816,
        fatesList= {
            collectionsFates= {
                { fateName="仙子尾巴之金黄花蜜", npcName="寻找花蜜的仙子" }
            },
            otherNpcFates= {
                { fateName="仙子尾巴之魔物包围网", npcName="寻找花蜜的仙子" }
            },
            fatesWithContinuations = {},
            blacklistedFates= {}
        }
    },
    {
        zoneName = "拉凯提卡大森林",
        zoneId = 817,
        fatesList= {
            collectionsFates= {
                { fateName="粉红鹳", npcName="夜之民导师" },
                { fateName="缅楠的巡逻之补充弓箭", npcName="散弓音 缅楠" },
                { fateName="传说诞生", npcName="法诺的看守人" }
            },
            otherNpcFates= {
                { fateName="吉梅与萨梅", npcName="血红枪 吉梅" }, --24 防御
                { fateName="死相陆鸟——刻莱诺", npcName="法诺的猎人" } --22 boss
            },
            fatesWithContinuations = {},
            blacklistedFates= {}
        }
    },
    {
        zoneName = "黑风海",
        zoneId = 818,
        fatesList= {
            collectionsFates= {
                { fateName="灾厄的古塔尼亚之收集红血珊瑚", npcName="提乌嘶·澳恩" },
                { fateName="珍珠永恒", npcName="鳍人族捕鱼人" }
            },
            otherNpcFates= {
                { fateName="灾厄的古塔尼亚之开始追踪", npcName="提乌嘶·澳恩" }, --23 一般
                { fateName="灾厄的古塔尼亚之兹姆嘶登场", npcName="提乌嘶·澳恩" }, --23 一般
                { fateName="灾厄的古塔尼亚之保护提乌嘶", npcName="提乌嘶·澳恩" }, --24 防御
                { fateName="灾厄的古塔尼亚之护卫提乌嘶", npcName="提乌嘶·澳恩" }, --护送
                { fateName="灾厄的古塔尼亚之准备决战", npcName="提乌嘶·澳恩" } --24 防御
            },
            fatesWithContinuations = {},
            specialFates = {
                "灾厄的古塔尼亚之深海讨伐战" -- 古塔尼亚（特殊FATE）
            },
            blacklistedFates= {
                "贝汁物语", --护送
                "灾厄的古塔尼亚之护卫提乌嘶" --护送
            }
        }
    },
    {
        zoneName = "迷津",
        zoneId = 956,
        fatesList= {
            collectionsFates= {
                { fateName="迷津风玫瑰", npcName="束手无策的研究员" },
                { fateName="纯天然保湿护肤品", npcName="皮肤很好的研究员" }
            },
            otherNpcFates= {
                { fateName="牧羊人的日常", npcName="种畜研究所的驯兽人" } --24 タワーディフェンス
            },
            fatesWithContinuations = {},
            blacklistedFates= {}
        }
    },
    {
        zoneName = "萨维奈岛",
        zoneId = 957,
        fatesList= {
            collectionsFates= {
                { fateName="芳香的炼金术士：危险的芬芳", npcName="调香师 萨加巴缇" }
            },
            otherNpcFates= {
                { fateName="少年与海", npcName="渔夫的儿子" } --24 防御
            },
            fatesWithContinuations = {},
            specialFates = {
                "兽道诸神信仰：伪神降临" -- 兽道神明灯天王（特殊FATE）
            },
            blacklistedFates= {}
        }
    },
    {
        zoneName = "加雷马",
        zoneId = 958,
        fatesList= {
            collectionsFates= {
                { fateName="资源回收分秒必争", npcName="沦为难民的魔导技师" }
            },
            otherNpcFates= {
                { fateName="魔导技师的归乡之旅：启程", npcName="柯尔特隆纳协漩尉" }, --22 boss
                { fateName="魔导技师的归乡之旅：落入陷阱", npcName="埃布雷尔诺" }, --24 防御
                { fateName="魔导技师的归乡之旅：实弹射击", npcName="柯尔特隆纳协漩尉" }, --23 一般
                { fateName="雪原的巨魔", npcName="幸存的难民" } --24 防御
            },
            fatesWithContinuations = {
                { fateName="魔导技师的归乡之旅：指挥机梅塔特隆", continuationIsBoss=true }
            },
            blacklistedFates= {}
        }
    },
    {
        zoneName = "叹息海",
        zoneId = 959,
        fatesList= {
            collectionsFates= {
                { fateName="如何追求兔生刺激", npcName="担惊威" }
            },
            otherNpcFates= {
                { fateName="叹息的白兔之轰隆隆大爆炸", npcName="战兵威" }, --24 タワーディフェンス
                { fateName="叹息的白兔之乱糟糟大失控", npcName="落名威" }, --23 通常
                { fateName="叹息的白兔之怒冲冲大处理", npcName="落名威" } --22 ボス
            },
            fatesWithContinuations = {},
            blacklistedFates= {
                "跨海而来的老饕", --由于斜坡上视野不佳，可能什么都做不了就呆站着
            }
        }
    },
    {
        zoneName = "天外天垓",
        zoneId = 960,
        fatesList= {
            collectionsFates= {
                { fateName="侵略兵器召回指令：扩建通信设备", npcName="N-6205" }
            },
            otherNpcFates= {
                { fateName="荣光之翼——阿尔·艾因", npcName="阿尔·艾因的朋友" }, --22 boss
                { fateName="侵略兵器召回指令：保护N-6205", npcName="N-6205"}, --24 防御
                { fateName="走向永恒的结局", npcName="米克·涅尔" } --24 防御
            },
            fatesWithContinuations = {},
            specialFates = {
                "	侵略兵器召回指令：破坏侵略兵器希" -- 希（特殊FATE）
            },
            blacklistedFates= {}
        }
    },
    {
        zoneName = "厄尔庇斯",
        zoneId = 961,
        fatesList= {
            collectionsFates= {
                { fateName="望请索克勒斯先生谅解", npcName="负责植物的观察者" }
            },
            otherNpcFates= {
                { fateName="创造计划：过于新颖的理念", npcName="神秘莫测 莫勒图斯" }, --23 一般
                { fateName="创造计划：伊娥观察任务", npcName="神秘莫测 莫勒图斯" }, --23 一般
                { fateName="告死鸟", npcName="一角兽的观察者" }, --24 防御
            },
            fatesWithContinuations = {
                { fateName="创造计划：过于新颖的理念", continuationIsBoss=true },
                { fateName="创造计划：伊娥观察任务", continuationIsBoss=true }
            },
            blacklistedFates= {}
        }
    },
    {
        zoneName = "奥阔帕恰山",
        zoneId = 1187,
        fatesList= {
            collectionsFates= {},
            otherNpcFates= {
                { fateName="牧场关门", npcName="健步如飞 基维利" }, --23 一般
                { fateName="跃动的火热——山火", npcName="健步如飞 基维利" }, --22 boss
                { fateName="不死之人", npcName="扫墓的尤卡巨人" }, --23 一般
                { fateName="失落的山顶都城", npcName="守护遗迹的尤卡巨人" }, --24 防御
                { fateName="咖啡豆岌岌可危", npcName="咖啡农园的工作人员" }, --24 防御
                { fateName="千年孤独", npcName="其瓦固佩刀者" }, --23 一般
                { fateName="飞天魔厨——佩鲁的天敌", npcName="佩鲁佩鲁的旅行商人" }, --22 boss
                { fateName="狼之家族", npcName="佩鲁佩鲁的旅行商人" }  --23 一般
            },
            fatesWithContinuations = {
                { fateName="不死之人", continuationIsBoss=true },
                { fateName="千年孤独", continuationIsBoss=true }
            },
            blacklistedFates= {
                "只有爆炸", -- 不知道为什么过不去
                "狼之家族", -- 由于同一地点有多个同名NPC存在
                "飞天魔厨——佩鲁的天敌" -- 由于同一地点有多个同名NPC存在
            }
        }
    },
    {
        zoneName="克扎玛乌卡湿地",
        zoneId=1188,
        fatesList={
            collectionsFates={
                { fateName="密林淘金", npcName="莫布林族采集者" },
                { fateName="巧若天工", npcName="哈努族手艺人" },
                
            },
            otherNpcFates= {
                { fateName="怪力大肚王——非凡飔戮龙", npcName="哈努族捕鱼人" }, --22 boss
                { fateName="芦苇荡的时光", npcName="哈努族农夫" }, --23 一般
                { fateName="贡品小偷", npcName="哈努族巫女" }, --24 防御
                { fateName="横征暴敛？", npcName="佩鲁佩鲁族商人" }, --24 防御
                { fateName="美丽菇世界", npcName="贴心巧匠 巴诺布罗坷" }  --23 一般
            },
            fatesWithContinuations = {
                { fateName="美丽菇世界", continuationIsBoss=true }
            },
            blacklistedFates= {
                "横征暴敛？" -- 由于同一地点有多个同名NPC存在
            }
        }
    },
    {
        zoneName="亚克特尔树海",
        zoneId=1189,
        fatesList= {
            collectionsFates= {
                { fateName="逃离恐怖菇", npcName="霍比格族采集者" }
            },
            otherNpcFates= {
                { fateName="顶击大貒猪", npcName="灵豹之民猎人" }, --23 一般
                { fateName="血染利爪——米尤鲁尔", npcName="灵豹之民猎人" }, --22 boss
                { fateName="致命螳螂", npcName="灵豹之民猎人" }, --23 一般
                { fateName="辉鳞族不法之徒袭击事件", npcName="朵普罗族枪手" }, --23 一般
                { fateName="守护秘药之战", npcName="霍比格族运货人" }  --24 防御
            },
            fatesWithContinuations = {
                { fateName="顶击大貒猪", continuationIsBoss=false },
                { fateName="辉鳞族不法之徒袭击事件", continuationIsBoss=true }
            },
            blacklistedFates= {
                "顶击大貒猪", -- 由于同一地点有多个同名NPC存在
                "血染利爪——米尤鲁尔", -- 由于同一地点有多个同名NPC存在
                "致命螳螂" -- 由于同一地点有多个同名NPC存在
            }
        }
    },
    {
        zoneName="夏劳尼荒野",
        zoneId=1190,
        fatesList= {
            collectionsFates= {
                { fateName="剃毛时间", npcName="迎曦之民采集者" },
                { fateName="蛇王得酷热涅：狩猎的杀手锏", npcName="蛇王得酷热涅" }
            },
            otherNpcFates= {
                { fateName="死而复生的恶棍——阴魂不散 扎特夸", npcName="迎曦之民劳动者" }, --22 boss
                { fateName="不甘的冲锋者——灰达奇", npcName="崇灵之民男性" }, --22 boss
                { fateName="和牛一起旅行", npcName="崇灵之民女性" }, --23 一般
                { fateName="大湖之恋", npcName="崇灵之民渔夫" }, --24 防御
                { fateName="神秘翼龙荒野奇谈", npcName="佩鲁佩鲁族的旅行商人" }  --23 一般
            },
            fatesWithContinuations = {
                { fateName="蛇王得酷热涅：狩猎的杀手锏", continuationIsBoss=false }
            },
            specialFates = {
                "蛇王得酷热涅：荒野的死斗" -- 得酷热涅（特殊FATE）
            },
            blacklistedFates= {}
        }
    },
    {
        zoneName="遗产之地",
        zoneId=1191,
        fatesList= {
            collectionsFates= {
                { fateName="药师的工作", npcName="迎曦之民栽培者" },
                { fateName="亮闪闪的可回收资源", npcName="英姿飒爽的再造者" }
            },
            otherNpcFates= {
                { fateName="机械迷城", npcName="初出茅庐的狩猎者" }, --23 一般
                { fateName="你来我往", npcName="初出茅庐的狩猎者" }, --23 一般
                { fateName="剥皮行者", npcName="陷入危机的狩猎者" }, --23 一般
                { fateName="机械公敌", npcName="走投无路的再造者" }, --23 一般
                { fateName="铭刻于灵魂中的恐惧", npcName="终流地的再造者" }, --23 一般
                { fateName="前路多茫然", npcName="害怕的运送者" }  --23 一般
            },
            fatesWithContinuations = {
                { fateName="机械公敌", continuationIsBoss=false }
            },
            blacklistedFates= {}
        }
    },
    {
        zoneName="活着的记忆",
        zoneId=1192,
        fatesList= {
            collectionsFates= {
                { fateName="良种难求", npcName="无失哨兵GX" },
                { fateName="记忆的碎片", npcName="无失哨兵GX" }
            },
            otherNpcFates= {
                { fateName="为了运河镇的安宁", npcName="无失哨兵GX" }, --24 防御
                { fateName="亩鼠米卡：盛装巡游开始", npcName="滑稽巡游主宰" }  --23 一般
            },
            fatesWithContinuations =
            {
                { fateName="水城噩梦", continuationIsBoss=ture },
                { fateName="亩鼠米卡：盛装巡游开始", continuationIsBoss=ture }
            },
            specialFates =
            {
                "亩鼠米卡：盛装巡游皆大欢喜"
            },
            blacklistedFates= {
            }
        }
    }
}

--#endregion Data

-- TODO
function mysplit(inputstr)
  for str in string.gmatch(inputstr, "[^%.]+") do
    return str
  end
end

function load_type(type_path)
    local assembly = mysplit(type_path)
    luanet.load_assembly(assembly)
    local type_var = luanet.import_type(type_path)
    return type_var
end

EntityWrapper = load_type('SomethingNeedDoing.LuaMacro.Wrappers.EntityWrapper')

function GetBuddyTimeRemaining()
    return Instances.Buddy.CompanionInfo.TimeLeft
end

function SetMapFlag(zoneId, position)
    Dalamud.Log("[FATE] Setting map flag to zone #"..zoneId..", (X: "..position.X..", "..position.Z.." )")
    Instances.Map.Flag:SetFlagMapMarker(zoneId, position.X, position.Z)
end

function GetZoneInstance()
    return InstancedContent.PublicInstance.InstanceId
end

function GetTargetName()
    if Svc.Targets.Target == nil then
        return ""
    else
        return Svc.Targets.Target.Name:GetText()
    end
end

function AttemptToTargetClosestFateEnemy()
    Dalamud.Log("[FATE] Check 24")
    --Svc.Targets.Target = Svc.Objects.OrderBy(DistanceToObject).FirstOrDefault(o => o.IsTargetable && o.IsHostile() && !o.IsDead && (distance == 0 || DistanceToObject(o) <= distance) && o.Struct()->FateId > 0);
    local closestTarget = nil
    local closestTargetDistance = math.maxinteger
    for i=0, Svc.Objects.Length-1 do
        local obj = Svc.Objects[i]
        if obj ~= nil and obj.IsTargetable and obj:IsHostile() and
            not obj.IsDead and EntityWrapper(obj).FateId > 0
        then
                local dist = GetDistanceToPoint(obj.Position)
                if dist < closestTargetDistance then
                    closestTargetDistance = dist
                    closestTarget = obj
                end
        end
    end
    if closestTarget ~= nil then
        Svc.Targets.Target = closestTarget
    end
    Dalamud.Log("[FATE] Check 36")
end

-- Calculates a point on the line from 'start' to 'end',
-- stopping 'd' units before reaching 'end'
function MoveToTargetHitbox()
    Dalamud.Log("[FATE] Check 51")
    if Svc.Targets.Target == nil then
        return
    end

    Dalamud.Log("[FATE] Check 52")
    -- Vector from start to end
    local distance = GetDistanceToTarget()

    -- Distance between start and end
    if distance == 0 then
        return
    end

    Dalamud.Log("[FATE] Check 53")
    -- Scale direction vector to (distance - d)
    local newDistance = distance - GetTargetHitboxRadius()
    if newDistance <= 0 then
        return
    end

    Dalamud.Log("[FATE] Check 54")
    -- Calculate normalized direction vector
    local norm = (Svc.Targets.Target.Position - Svc.ClientState.LocalPlayer.Position) / distance
    local edgeOfHitbox = (norm*newDistance) + Svc.ClientState.LocalPlayer.Position
    local newPos = nil
    local halfExt = 10
    while newPos == nil do
        Dalamud.Log("[FATE] Check 55")
        newPos = IPC.vnavmesh.PointOnFloor(edgeOfHitbox, false, halfExt)
        halfExt = halfExt + 10
    end
    yield("/vnav moveto "..newPos.X.." "..newPos.Y.." "..newPos.Z)

    Dalamud.Log("[FATE] Check 56")
end


--#region Fate Functions
function IsCollectionsFate(fateName)
    for i, collectionsFate in ipairs(SelectedZone.fatesList.collectionsFates) do
        if collectionsFate.fateName == fateName then
            return true
        end
    end
    return false
end

function IsBossFate(fate)
    return fate.IconId == 60722
end

function IsOtherNpcFate(fateName)
    for i, otherNpcFate in ipairs(SelectedZone.fatesList.otherNpcFates) do
        if otherNpcFate.fateName == fateName then
            return true
        end
    end
    return false
end

function IsSpecialFate(fateName)
    if SelectedZone.fatesList.specialFates == nil then
        return false
    end
    for i, specialFate in ipairs(SelectedZone.fatesList.specialFates) do
        if specialFate == fateName then
            return true
        end
    end
end

function IsBlacklistedFate(fateName)
    for i, blacklistedFate in ipairs(SelectedZone.fatesList.blacklistedFates) do
        if blacklistedFate == fateName then
            return true
        end
    end
    if not JoinCollectionsFates then
        for i, collectionsFate in ipairs(SelectedZone.fatesList.collectionsFates) do
            if collectionsFate.fateName == fateName then
                return true
            end
        end
    end
    return false
end

function GetFateNpcName(fateName)
    for i, fate in ipairs(SelectedZone.fatesList.otherNpcFates) do
        if fate.fateName == fateName then
            return fate.npcName
        end
    end
    for i, fate in ipairs(SelectedZone.fatesList.collectionsFates) do
        if fate.fateName == fateName then
            return fate.npcName
        end
    end
end

function IsFateActive(fate)
    return fate.State ~= FateState.Ending and fate.State ~= FateState.Ended and fate.State ~= FateState.Failed
end

function InActiveFate()
    Dalamud.Log("[FATE] Check 28")
    local activeFates = Fates.GetActiveFates()
    for i=0, activeFates.Count-1 do
        if activeFates[i].InFate and IsFateActive(activeFates[i]) then
            Dalamud.Log("[FATE] Check 29")
            return true
        end
    end
    Dalamud.Log("[FATE] Check 30")
    return false
end

function SelectNextZone()
    local nextZone = nil
    local nextZoneId = Svc.ClientState.TerritoryType

    for i, zone in ipairs(FatesData) do
        if nextZoneId == zone.zoneId then
            nextZone = zone
        end
    end
    if nextZone == nil then
        yield("/echo [FATE] Current zone is only partially supported. No data on npc fates.")
        nextZone = {
            zoneName = "",
            zoneId = nextZoneId,
            fatesList= {
                collectionsFates= {},
                otherNpcFates= {},
                bossFates= {},
                blacklistedFates= {},
                fatesWithContinuations = {}
            }
        }
    end

    nextZone.zoneName = nextZone.zoneName
    nextZone.aetheryteList = {}
    local aetherytes = GetAetherytesInZone(nextZone.zoneId)
    for _, aetheryte in ipairs(aetherytes) do
        local aetherytePos = Instances.Telepo:GetAetherytePosition(aetheryte.AetheryteId)
        local aetheryteTable = {
            aetheryteName = GetAetheryteName(aetheryte),
            aetheryteId = aetheryte.AetheryteId,
            position = aetherytePos,
            aetheryteObj = aetheryte
        }
        table.insert(nextZone.aetheryteList, aetheryteTable)
    end

    if nextZone.flying == nil then
        nextZone.flying = true
    end

    return nextZone
end

function BuildFateTable(fateObj)
    Dalamud.Log("[FATE] Enter->BuildFateTable")
    local fateTable = {
        fateObject = fateObj,
        fateId = fateObj.Id,
        fateName = fateObj.Name,
        duration = fateObj.Duration,
        startTime = fateObj.StartTimeEpoch,
        position = fateObj.Location,
        isBonusFate = fateObj.IsBonus,
    }

    Dalamud.Log("[FATE] Check 5")
    fateTable.npcName = GetFateNpcName(fateTable.fateName)

    Dalamud.Log("[FATE] Check 6")
    local currentTime = EorzeaTimeToUnixTime(Instances.Framework.EorzeaTime)
    if fateTable.startTime == 0 then
        fateTable.timeLeft = 900
    else
        fateTable.timeElapsed = currentTime - fateTable.startTime
        fateTable.timeLeft = fateTable.duration - fateTable.timeElapsed
    end

    Dalamud.Log("[FATE] Check 7")
    fateTable.isCollectionsFate = IsCollectionsFate(fateTable.fateName)
    Dalamud.Log("[FATE] Check 7.1")
    fateTable.isBossFate = IsBossFate(fateTable.fateObject)
    Dalamud.Log("[FATE] Check 7.2")
    fateTable.isOtherNpcFate = IsOtherNpcFate(fateTable.fateName)
    Dalamud.Log("[FATE] Check 7.3")
    fateTable.isSpecialFate = IsSpecialFate(fateTable.fateName)
    Dalamud.Log("[FATE] Check 7.4")
    fateTable.isBlacklistedFate = IsBlacklistedFate(fateTable.fateName)

    Dalamud.Log("[FATE] Check 8")
    fateTable.continuationIsBoss = false
    fateTable.hasContinuation = false
    for _, continuationFate in ipairs(SelectedZone.fatesList.fatesWithContinuations) do
        if fateTable.fateName == continuationFate.fateName then
            fateTable.hasContinuation = true
            fateTable.continuationIsBoss = continuationFate.continuationIsBoss
        end
    end

    return fateTable
end

--[[
    Selects the better fate based on the priority order defined in FatePriority.
    Default Priority order is "Progress" -> "DistanceTeleport" -> "Bonus" -> "TimeLeft" -> "Distance"
]]
function SelectNextFateHelper(tempFate, nextFate)
    if nextFate == nil then
        Dalamud.Log("[FATE] nextFate is nil")
        return tempFate
    elseif BonusFatesOnly then
        --Check if WaitForBonusIfBonusBuff is true, and have eithe buff, then set BonusFatesOnlyTemp to true
        if not tempFate.isBonusFate and nextFate ~= nil and nextFate.isBonusFate then
            return nextFate
        elseif tempFate.isBonusFate and (nextFate == nil or not nextFate.isBonusFate) then
            return tempFate
        elseif not tempFate.isBonusFate and (nextFate == nil or not nextFate.isBonusFate) then
            return nil
        end
        -- if both are bonus fates, go through the regular fate selection process
    end

    if tempFate.timeLeft < MinTimeLeftToIgnoreFate or tempFate.fateObject.Progress > CompletionToIgnoreFate then
        Dalamud.Log("[FATE] Ignoring fate #"..tempFate.fateId.." due to insufficient time or high completion.")
        return nextFate
    elseif nextFate == nil then
        Dalamud.Log("[FATE] Selecting #"..tempFate.fateId.." because no other options so far.")
        return tempFate
    elseif nextFate.timeLeft < MinTimeLeftToIgnoreFate or nextFate.fateObject.Progress > CompletionToIgnoreFate then
        Dalamud.Log("[FATE] Ignoring fate #"..nextFate.fateId.." due to insufficient time or high completion.")
        return tempFate
    end

    -- Evaluate based on priority (Loop through list return first non-equal priority)
    for _, criteria in ipairs(FatePriority) do
        if criteria == "Progress" then
            Dalamud.Log("[FATE] Comparing progress: "..tempFate.fateObject.Progress.." vs "..nextFate.fateObject.Progress)
            if tempFate.fateObject.Progress > nextFate.fateObject.Progress then return tempFate end
            if tempFate.fateObject.Progress < nextFate.fateObject.Progress then return nextFate end
        elseif criteria == "Bonus" then
            Dalamud.Log("[FATE] Checking bonus status: "..tostring(tempFate.isBonusFate).." vs "..tostring(nextFate.isBonusFate))
            if tempFate.isBonusFate and not nextFate.isBonusFate then return tempFate end
            if nextFate.isBonusFate and not tempFate.isBonusFate then return nextFate end
        elseif criteria == "TimeLeft" then
            Dalamud.Log("[FATE] Comparing time left: "..tempFate.timeLeft.." vs "..nextFate.timeLeft)
            if tempFate.timeLeft > nextFate.timeLeft then return tempFate end
            if tempFate.timeLeft < nextFate.timeLeft then return nextFate end
        elseif criteria == "Distance" then
            local tempDist = GetDistanceToPoint(tempFate.position)
            local nextDist = GetDistanceToPoint(nextFate.position)
            Dalamud.Log("[FATE] Comparing distance: "..tempDist.." vs "..nextDist)
            if tempDist < nextDist then return tempFate end
            if tempDist > nextDist then return nextFate end
        elseif criteria == "DistanceTeleport" then
            local tempDist = GetDistanceToPointWithAetheryteTravel(tempFate.position)
            local nextDist = GetDistanceToPointWithAetheryteTravel(nextFate.position)
            Dalamud.Log("[FATE] Comparing distance: "..tempDist.." vs "..nextDist)
            if tempDist < nextDist then return tempFate end
            if tempDist > nextDist then return nextFate end
        end
    end

    -- Fallback: Select fate with the lower ID
    Dalamud.Log("[FATE] Selecting lower ID fate: "..tempFate.fateId.." vs "..nextFate.fateId)
    return (tempFate.fateId < nextFate.fateId) and tempFate or nextFate
end

--Gets the Location of the next Fate. Prioritizes anything with progress above 0, then by shortest time left
function SelectNextFate()
    local fates = Fates.GetActiveFates()
    if fates == nil then
        return
    end

    local nextFate = nil
    for i = 0, fates.Count-1 do
        Dalamud.Log("[FATE] Building fate table")
        local tempFate = BuildFateTable(fates[i])
        Dalamud.Log("[FATE] Considering fate #"..tempFate.fateId.." "..tempFate.fateName)
        Dalamud.Log("[FATE] Time left on fate #:"..tempFate.fateId..": "..math.floor(tempFate.timeLeft//60).."min, "..math.floor(tempFate.timeLeft%60).."s")

        if not (tempFate.position.X == 0 and tempFate.position.Z == 0) then -- sometimes game doesn't send the correct coords
            if not tempFate.isBlacklistedFate then -- check fate is not blacklisted for any reason
                if tempFate.isBossFate then
                    if (tempFate.isSpecialFate and tempFate.fateObject.Progress >= CompletionToJoinSpecialBossFates) or
                        (not tempFate.isSpecialFate and tempFate.fateObject.Progress >= CompletionToJoinBossFate) then
                        nextFate = SelectNextFateHelper(tempFate, nextFate)
                    else
                        Dalamud.Log("[FATE] Skipping fate #"..tempFate.fateId.." "..tempFate.fateName.." due to boss fate with not enough progress.")
                    end
                elseif (tempFate.isOtherNpcFate or tempFate.isCollectionsFate) and tempFate.startTime == 0 then
                    if not Dalamud.Log("[FATE] SelectNextFate->nextFate is nil") and nextFate == nil then -- pick this if there's nothing else
                        nextFate = tempFate
                    elseif not Dalamud.Log("[FATE] SelectNextFate->check tempFate.isBonsuFate") and tempFate.isBonusFate then
                        nextFate = SelectNextFateHelper(tempFate, nextFate)
                    elseif not Dalamud.Log("[FATE] SelectNextFate->check nextFate.startTime") and nextFate.startTime == 0 then -- both fates are unopened npc fates
                        nextFate = SelectNextFateHelper(tempFate, nextFate)
                    end
                elseif tempFate.duration ~= 0 then -- else is normal fate. avoid unlisted talk to npc fates
                    nextFate = SelectNextFateHelper(tempFate, nextFate)
                end
                Dalamud.Log("[FATE] Finished considering fate #"..tempFate.fateId.." "..tempFate.fateName)
            else
                Dalamud.Log("[FATE] Skipping fate #"..tempFate.fateId.." "..tempFate.fateName.." due to blacklist.")
            end
        end
    end

    Dalamud.Log("[FATE] Finished considering all fates")

    if nextFate == nil then
        Dalamud.Log("[FATE] 没有找到合适的FATE")
        if Echo == "All" then
            yield("/echo [FATE] 没有找到合适的FATE.")
        end
    else
        Dalamud.Log("[FATE] Final selected fate #"..nextFate.fateId.." "..nextFate.fateName)
    end
    yield("/wait 0.211")

    return nextFate
end

function AcceptNPCFateOrRejectOtherYesno()
    if Addons.GetAddon("SelectYesno").Ready then
        Dalamud.Log("[FATE] Check 45")
        local dialogBox = GetNodeText("SelectYesno", 1, 2)
        Dalamud.Log("[FATE] Check 46")
        if type(dialogBox) == "string" and dialogBox:find("这个FATE的推荐等级是") then
            yield("/callback SelectYesno true 0") --accept fate
        else
            yield("/callback SelectYesno true 1") --decline all other boxes
        end
    end
end

--#endregion Fate Functions

--#region Movement Functions

function DistanceBetween(pos1, pos2)
    return Vector3.Distance(pos1, pos2)
end

function GetDistanceToPoint(vec3)
    return DistanceBetween(Svc.ClientState.LocalPlayer.Position, vec3)
end

function GetDistanceToTarget()
    if Svc.Targets.Target ~= nil then
        return GetDistanceToPoint(Svc.Targets.Target.Position)
    else
        return math.maxinteger
    end
end

function RandomAdjustCoordinates(position, maxDistance)
    local angle = math.random() * 2 * math.pi
    local x_adjust = maxDistance * math.random()
    local z_adjust = maxDistance * math.random()

    local randomX = position.X + (x_adjust * math.cos(angle))
    local randomY = position.Y + maxDistance
    local randomZ = position.Z + (z_adjust * math.sin(angle))

    return Vector3(randomX, randomY, randomZ)
end

function GetAetherytesInZone(zoneId)
    local aetherytesInZone = {}
    for _, aetheryte in ipairs(Svc.AetheryteList) do
        if aetheryte.TerritoryId == zoneId then
            table.insert(aetherytesInZone, aetheryte)
        end
    end
    return aetherytesInZone
end

function GetAetheryteName(aetheryte)
    local name = aetheryte.AetheryteData.Value.PlaceName.Value.Name:GetText()
    if name == nil then
        return ""
    else
        return name
    end
end

function DistanceFromClosestAetheryteToPoint(vec3, teleportTimePenalty)
    local closestAetheryte = nil
    local closestTravelDistance = math.maxinteger
    for _, aetheryte in ipairs(SelectedZone.aetheryteList) do
        local distanceAetheryteToFate = DistanceBetween(aetheryte.position, vec3)
        local comparisonDistance = distanceAetheryteToFate + teleportTimePenalty
        Dalamud.Log("[FATE] Distance via "..aetheryte.aetheryteName.." adjusted for tp penalty is "..tostring(comparisonDistance))

        if comparisonDistance < closestTravelDistance then
            Dalamud.Log("[FATE] Updating closest aetheryte to "..aetheryte.aetheryteName)
            closestTravelDistance = comparisonDistance
            closestAetheryte = aetheryte
        end
    end

    return closestTravelDistance
end

function GetDistanceToPointWithAetheryteTravel(vec3)
    -- Get the direct flight distance (no aetheryte)
    local directFlightDistance = GetDistanceToPoint(vec3)
    Dalamud.Log("[FATE] Direct flight distance is: " .. directFlightDistance)
    
    -- Get the distance to the closest aetheryte, including teleportation penalty
    local distanceToAetheryte = DistanceFromClosestAetheryteToPoint(vec3, 200)
    Dalamud.Log("[FATE] Distance via closest Aetheryte is: " .. (distanceToAetheryte or "nil"))

    -- Return the minimum distance, either via direct flight or via the closest aetheryte travel
    if distanceToAetheryte == nil then
        return directFlightDistance
    else
        return math.min(directFlightDistance, distanceToAetheryte)
    end
end

function GetClosestAetheryte(position, teleportTimePenalty)
    local closestAetheryte = nil
    local closestTravelDistance = math.maxinteger
    for _, aetheryte in ipairs(SelectedZone.aetheryteList) do
        Dalamud.Log("[FATE] Considering aetheryte "..aetheryte.aetheryteName)
        local distanceAetheryteToFate = DistanceBetween(aetheryte.position, position)
        local comparisonDistance = distanceAetheryteToFate + teleportTimePenalty
        Dalamud.Log("[FATE] Distance via "..aetheryte.aetheryteName.." adjusted for tp penalty is "..tostring(comparisonDistance))

        if comparisonDistance < closestTravelDistance then
            Dalamud.Log("[FATE] Updating closest aetheryte to "..aetheryte.aetheryteName)
            closestTravelDistance = comparisonDistance
            closestAetheryte = aetheryte
        end
    end
    if closestAetheryte ~= nil then
        Dalamud.Log("[FATE] Final selected aetheryte is: "..closestAetheryte.aetheryteName)
    else
        Dalamud.Log("[FATE] Closest aetheryte is nil")
    end

    return closestAetheryte
end

function GetClosestAetheryteToPoint(position, teleportTimePenalty)
    local directFlightDistance = GetDistanceToPoint(position)
    Dalamud.Log("[FATE] Direct flight distance is: "..directFlightDistance)
    local closestAetheryte = GetClosestAetheryte(position, teleportTimePenalty)
    if closestAetheryte ~= nil then
        local closestAetheryteDistance = DistanceBetween(position, closestAetheryte.position) + teleportTimePenalty

        if closestAetheryteDistance < directFlightDistance then
            return closestAetheryte
        end
    end
    return nil
end

function TeleportToClosestAetheryteToFate(nextFate)
    local aetheryteForClosestFate = GetClosestAetheryteToPoint(nextFate.position, 200)
    if aetheryteForClosestFate ~=nil then
        TeleportTo(aetheryteForClosestFate.aetheryteName)
        return true
    end
    return false
end

function AcceptTeleportOfferLocation(destinationAetheryte)
    if Addons.GetAddon("_NotificationTelepo").Ready then
        local location = GetNodeText("_NotificationTelepo", 3, 4)
        yield("/callback _Notification true 0 16 "..location)
        yield("/wait 1")
    end

    if Addons.GetAddon("SelectYesno").Ready then
        local teleportOfferMessage = GetNodeText("SelectYesno", 1, 2)
        if type(teleportOfferMessage) == "string" then
            local teleportOfferLocation = teleportOfferMessage:match("Accept Teleport to (.+)%?")
            if teleportOfferLocation ~= nil then
                if string.lower(teleportOfferLocation) == string.lower(destinationAetheryte) then
                    yield("/callback SelectYesno true 0") -- accept teleport
                    return
                else
                    Dalamud.Log("Offer for "..teleportOfferLocation.." and destination "..destinationAetheryte.." are not the same. Declining teleport.")
                end
            end
            yield("/callback SelectYesno true 2") -- decline teleport
            return
        end
    end
end

function TeleportTo(aetheryteName)
    AcceptTeleportOfferLocation(aetheryteName)

    while EorzeaTimeToUnixTime(Instances.Framework.EorzeaTime) - LastTeleportTimeStamp < 5 do
        Dalamud.Log("[FATE] Too soon since last teleport. Waiting...")
        yield("/wait 5.001")
    end

    yield("/li tp "..aetheryteName)
    yield("/wait 1") -- wait for casting to begin
    while Svc.Condition[CharacterCondition.casting] do
        Dalamud.Log("[FATE] Casting teleport...")
        yield("/wait 1")
    end
    yield("/wait 1") -- wait for that microsecond in between the cast finishing and the transition beginning
    while Svc.Condition[CharacterCondition.betweenAreas] do
        Dalamud.Log("[FATE] Teleporting...")
        yield("/wait 1")
    end
    yield("/wait 1")
    LastTeleportTimeStamp = EorzeaTimeToUnixTime(Instances.Framework.EorzeaTime)
end

function ChangeInstance()
    if SuccessiveInstanceChanges >= NumberOfInstances then
        if CompanionScriptMode then
            local shouldWaitForBonusBuff = WaitIfBonusBuff and (HasStatusId(1288) or HasStatusId(1289))
            if WaitingForFateRewards == nil and not shouldWaitForBonusBuff then
                StopScript = true
            else
                Dalamud.Log("[Fate Farming] Waiting for buff or fate rewards")
                yield("/wait 3")
            end
        else
            yield("/wait 10")
            SuccessiveInstanceChanges = 0
        end
        return
    end

    yield("/target 以太之光") -- search for nearby aetheryte
    if Svc.Targets.Target == nil or GetTargetName() ~= "以太之光" then -- if no aetheryte within targeting range, teleport to it
        Dalamud.Log("[FATE] Aetheryte not within targetable range")
        local closestAetheryte = nil
        local closestAetheryteDistance = math.maxinteger
        for i, aetheryte in ipairs(SelectedZone.aetheryteList) do
            -- GetDistanceToPoint is implemented with raw distance instead of distance squared
            local distanceToAetheryte = GetDistanceToPoint(aetheryte.position)
            if distanceToAetheryte < closestAetheryteDistance then
                closestAetheryte = aetheryte
                closestAetheryteDistance = distanceToAetheryte
            end
        end
        if closestAetheryte ~= nil then
            TeleportTo(closestAetheryte.aetheryteName)
        end
        return
    end

    if WaitingForFateRewards ~= nil then
        yield("/wait 10")
        return
    end

    if GetDistanceToTarget() > 10 then
        Dalamud.Log("[FATE] Targeting aetheryte, but greater than 10 distance")
        if not (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()) then
            if Svc.Condition[CharacterCondition.flying] and SelectedZone.flying then
                yield("/vnav flytarget")
            else
                yield("/vnav movetarget")
            end
        elseif GetDistanceToTarget() > 20 and not Svc.Condition[CharacterCondition.mounted] then
            State = CharacterState.mounting
            Dalamud.Log("[FATE] State Change: Mounting")
        end
        return
    end

    Dalamud.Log("[FATE] Within 10 distance")
    if IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() then
        yield("/vnav stop")
        return
    end

    if Svc.Condition[CharacterCondition.mounted] then
        State = CharacterState.changeInstanceDismount
        Dalamud.Log("[FATE] State Change: ChangeInstanceDismount")
        return
    end

    Dalamud.Log("[FATE] Transferring to next instance")
    local nextInstance = (GetZoneInstance() % 2) + 1
    yield("/li "..nextInstance) -- start instance transfer
    yield("/wait 1") -- wait for instance transfer to register
    State = CharacterState.ready
    SuccessiveInstanceChanges = SuccessiveInstanceChanges + 1
    Dalamud.Log("[FATE] State Change: Ready")
end

function WaitForContinuation()
    if InActiveFate() then
        Dalamud.Log("WaitForContinuation IsInFate")
        local nextFateId = Fates.GetNearestFate()
        if nextFateId ~= CurrentFate.fateObject then
            CurrentFate = BuildFateTable(nextFateId)
            State = CharacterState.doFate
            Dalamud.Log("[FATE] State Change: DoFate")
        end
    elseif os.clock() - LastFateEndTime > 30 then
        Dalamud.Log("WaitForContinuation Abort")
        Dalamud.Log("Over 30s since end of last fate. Giving up on part 2.")
        TurnOffCombatMods()
        State = CharacterState.ready
        Dalamud.Log("State Change: Ready")
    else
        Dalamud.Log("WaitForContinuation Else")
        if BossFatesClass ~= nil then
            local currentClass = Player.Job.Id
            Dalamud.Log("WaitForContinuation "..CurrentFate.fateName)
            if not Player.IsPlayerOccupied then
                if CurrentFate.continuationIsBoss and currentClass ~= BossFatesClass.classId then
                    Dalamud.Log("WaitForContinuation SwitchToBoss")
                    yield("/gs change "..BossFatesClass.className)
                elseif not CurrentFate.continuationIsBoss and currentClass ~= MainClass.classId then
                    Dalamud.Log("WaitForContinuation SwitchToMain")
                    yield("/gs change "..MainClass.className)
                end
            end
        end

        yield("/wait 1")
    end
end

function FlyBackToAetheryte()
    NextFate = SelectNextFate()
    if NextFate ~= nil then
        yield("/vnav stop")
        State = CharacterState.ready
        Dalamud.Log("[FATE] State Change: Ready")
        return
    end

    local closestAetheryte = GetClosestAetheryte(Svc.ClientState.LocalPlayer.Position, 0)
    if closestAetheryte == nil then
        DownTimeWaitAtNearestAetheryte = false
        yield("/echo Could not find aetheryte in the area. Turning off feature to fly back to aetheryte.")
        return
    end
    -- if you get any sort of error while flying back, then just abort and tp back
    if Addons.GetAddon("_TextError").Ready and GetNodeText("_TextError", 1) == "Your mount can fly no higher." then
        yield("/vnav stop")
        TeleportTo(closestAetheryte.aetheryteName)
        return
    end

    yield("/target 以太之光")

    if Svc.Targets.Target ~= nil and GetTargetName() == "以太之光" and GetDistanceToTarget() <= 20 then
        if IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() then
            yield("/vnav stop")
        end

        if Svc.Condition[CharacterCondition.flying] then
            yield("/mount") -- land but don't actually dismount, to avoid running chocobo timer
        elseif Svc.Condition[CharacterCondition.mounted] then
            State = CharacterState.ready
            Dalamud.Log("[FATE] State Change: Ready")
        else
            if MountToUse == "随机飞行坐骑" then
                yield('/gaction "随机飞行坐骑"')
            else
                yield('/mount "' .. MountToUse)
            end
        end
        return
    end
    
    if not (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()) then
        Dalamud.Log("[FATE] ClosestAetheryte.y: "..closestAetheryte.position.Y)
        if closestAetheryte ~= nil then
            SetMapFlag(SelectedZone.zoneId, closestAetheryte.position)
            IPC.vnavmesh.PathfindAndMoveTo(closestAetheryte.position, Svc.Condition[CharacterCondition.flying] and SelectedZone.flying)
        end
    end

    if not Svc.Condition[CharacterCondition.mounted] then
        Mount()
        return
    end
end

function Mount()
    if MountToUse == "随机飞行坐骑" then
        yield('/gaction "随机飞行坐骑"')
    else
        yield('/mount "' .. MountToUse)
    end
    yield("/wait 1")
end

function MountState()
    if Svc.Condition[CharacterCondition.mounted] then
        yield("/wait 1") -- wait a second to make sure you're firmly on the mount
        State = CharacterState.moveToFate
        Dalamud.Log("[FATE] State Change: MoveToFate")
    else
        Mount()
    end
end

function Dismount()
    if Svc.Condition[CharacterCondition.flying] then
        yield('/mount')

        local now = os.clock()
        if now - LastStuckCheckTime > 1 then

            if Svc.Condition[CharacterCondition.flying] and GetDistanceToPoint(LastStuckCheckPosition) < 2 then
                Dalamud.Log("[FATE] Unable to dismount here. Moving to another spot.")
                local random = RandomAdjustCoordinates(Svc.ClientState.LocalPlayer.Position, 10)
                local nearestFloor = IPC.vnavmesh.PointOnFloor(random, true, 100)
                if nearestFloor ~= nil then
                    IPC.vnavmesh.PathfindAndMoveTo(nearestFloor, Svc.Condition[CharacterCondition.flying] and SelectedZone.flying)
                    yield("/wait 1")
                end
            end

            LastStuckCheckTime = now
            LastStuckCheckPosition = Svc.ClientState.LocalPlayer.Position
        end
    elseif Svc.Condition[CharacterCondition.mounted] then
        yield('/mount')
    end
end

function MiddleOfFateDismount()
    if not IsFateActive(CurrentFate.fateObject) then
        State = CharacterState.ready
        Dalamud.Log("[FATE] State Change: Ready")
        return
    end

    if Svc.Targets.Target ~= nil then
        if GetDistanceToTarget() > (MaxDistance + GetTargetHitboxRadius() + 5) then
            if not (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()) then
                Dalamud.Log("[FATE] MiddleOfFateDismount IPC.vnavmesh.PathfindAndMoveTo")
                if Svc.Condition[CharacterCondition.flying] then
                    yield("/vnav flytarget")
                else
                    yield("/vnav movetarget")
                end
            end
        else
            if Svc.Condition[CharacterCondition.mounted] then
                Dalamud.Log("[FATE] MiddleOfFateDismount Dismount()")
                Dismount()
            else
                yield("/vnav stop")
                State = CharacterState.doFate
                Dalamud.Log("[FATE] State Change: DoFate")
            end
        end
    else
        AttemptToTargetClosestFateEnemy()
    end
end

function NpcDismount()
    if Svc.Condition[CharacterCondition.mounted] then
        Dismount()
    else
        State = CharacterState.interactWithNpc
        Dalamud.Log("[FATE] State Change: InteractWithFateNpc")
    end
end

function ChangeInstanceDismount()
    if Svc.Condition[CharacterCondition.mounted] then
        Dismount()
    else
        State = CharacterState.changingInstances
        Dalamud.Log("[FATE] State Change: ChangingInstance")
    end
end

--Paths to the Fate NPC Starter
function MoveToNPC()
    yield("/target "..CurrentFate.npcName)
    if Svc.Targets.Target ~= nil and GetTargetName()==CurrentFate.npcName then
        if GetDistanceToTarget() > 5 then
            yield("/vnav movetarget")
        end
    end
end

--Paths to the Fate. CurrentFate is set here to allow MovetoFate to change its mind,
--so CurrentFate is possibly nil.
function MoveToFate()
    Dalamud.Log("[FATE] Check 9")
    SuccessiveInstanceChanges = 0

    if not Player.Available then
        return
    end

    if CurrentFate~=nil and not IsFateActive(CurrentFate.fateObject) then
        Dalamud.Log("[FATE] Next Fate is dead, selecting new Fate.")
        yield("/vnav stop")
        State = CharacterState.ready
        Dalamud.Log("[FATE] State Change: Ready")
        return
    end

    NextFate = SelectNextFate()
    Dalamud.Log("[FATE] Check 13")
    if NextFate == nil then -- when moving to next fate, CurrentFate == NextFate
        Dalamud.Log("[FATE] Check 14")
        yield("/vnav stop")
        State = CharacterState.ready
        Dalamud.Log("[FATE] State Change: Ready")
        return
    elseif CurrentFate == nil or NextFate.fateId ~= CurrentFate.fateId then
        Dalamud.Log("[FATE] Check 15")
        yield("/vnav stop")
        CurrentFate = NextFate
        SetMapFlag(SelectedZone.zoneId, CurrentFate.position)
        return
    end

    Dalamud.Log("[FATE] Check 11")

    -- change to secondary class if it's a boss fate
    if BossFatesClass ~= nil then
        local currentClass = Player.Job.Id
        if CurrentFate.isBossFate and currentClass ~= BossFatesClass.classId then
            yield("/gs change "..BossFatesClass.className)
            return
        elseif not CurrentFate.isBossFate and currentClass ~= MainClass.classId then
            yield("/gs change "..MainClass.className)
            return
        end
    end

    Dalamud.Log("[FATE] Check 21")
    -- upon approaching fate, pick a target and switch to pathing towards target
    if GetDistanceToPoint(CurrentFate.position) < 60 then
        Dalamud.Log("[FATE] Check 22")
        if Svc.Targets.Target ~= nil then
            Dalamud.Log("[FATE] Found FATE target, immediate rerouting")
            yield("/wait 0.1")
            MoveToTargetHitbox()
            if (CurrentFate.isOtherNpcFate or CurrentFate.isCollectionsFate) then
                State = CharacterState.interactWithNpc
                Dalamud.Log("[FATE] State Change: Interact with npc")
            -- if GetTargetName() == CurrentFate.npcName then
            --     State = CharacterState.interactWithNpc
            -- elseif GetTargetFateID() == CurrentFate.fateId then
            --     State = CharacterState.middleOfFateDismount
            --     Dalamud.Log("[FATE] State Change: MiddleOfFateDismount")
            else
                State = CharacterState.MiddleOfFateDismount
                Dalamud.Log("[FATE] State Change: MiddleOfFateDismount")
            end
            return
        else
            Dalamud.Log("[FATE] Check 23")
            if (CurrentFate.isOtherNpcFate or CurrentFate.isCollectionsFate) and not InActiveFate() then
                yield("/target "..CurrentFate.npcName)
            else
                AttemptToTargetClosestFateEnemy()
            end
            yield("/wait 0.5") -- give it a moment to make sure the target sticks
            return
        end
    end

    Dalamud.Log("[FATE] Check 16")
    -- check for stuck
    if (IPC.vnavmesh.IsRunning() or IPC.vnavmesh.PathfindInProgress()) and Svc.Condition[CharacterCondition.mounted] then
        Dalamud.Log("[FATE] Check 17")
        local now = os.clock()
        if now - LastStuckCheckTime > 10 then

            if GetDistanceToPoint(LastStuckCheckPosition) < 3 then
                yield("/vnav stop")
                yield("/wait 1")
                Dalamud.Log("[FATE] Antistuck")
                local up10 = Svc.ClientState.LocalPlayer.Position + Vector3(0, 10, 0)
                IPC.vnavmesh.PathfindAndMoveTo(up10, Svc.Condition[CharacterCondition.flying] and SelectedZone.flying) -- fly up 10 then try again
            end
            
            LastStuckCheckTime = now
            LastStuckCheckPosition = Svc.ClientState.LocalPlayer.Position
        end
        return
    end

    Dalamud.Log("[FATE] Check 18")
    if not MovingAnnouncementLock then
        Dalamud.Log("[FATE] 移动到FATE #"..CurrentFate.fateId.." "..CurrentFate.fateName)
        MovingAnnouncementLock = true
        if Echo == "All" then
            yield("/echo [FATE] 移动到FATE #"..CurrentFate.fateId.." "..CurrentFate.fateName)
        end
    end

    if TeleportToClosestAetheryteToFate(CurrentFate) then
        Dalamud.Log("Executed teleport to closer aetheryte")
        return
    end

    local nearestFloor = CurrentFate.position
    if not (CurrentFate.isCollectionsFate or CurrentFate.isOtherNpcFate) then
        nearestFloor = RandomAdjustCoordinates(CurrentFate.position, 10)
    end

    Dalamud.Log("[FATE] Check 10")
    if GetDistanceToPoint(nearestFloor) > 5 then
        Dalamud.Log("[FATE] Check 11")
        if not Svc.Condition[CharacterCondition.mounted] then
            Dalamud.Log("[FATE] Check 12")
            State = CharacterState.mounting
            Dalamud.Log("[FATE] State Change: Mounting")
            return
        elseif not IPC.vnavmesh.PathfindInProgress() and not IPC.vnavmesh.IsRunning() then
            if Player.CanFly and SelectedZone.flying then
                yield("/vnav flyflag")
            else
                yield("/vnav moveflag")
            end
        end
    else
        State = CharacterState.MiddleOfFateDismount
    end
end

function InteractWithFateNpc()
    Dalamud.Log("[FATE] Check 20")
    if InActiveFate() or CurrentFate.startTime > 0 then
        Dalamud.Log("[FATE] Check 31")
        yield("/vnav stop")
        State = CharacterState.doFate
        Dalamud.Log("[FATE] State Change: DoFate")
        yield("/wait 1") -- give the fate a second to register before dofate and lsync
    elseif not IsFateActive(CurrentFate.fateObject) then
        State = CharacterState.ready
        Dalamud.Log("[FATE] State Change: Ready")
    elseif IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() then
        if Svc.Targets.Target ~= nil and GetTargetName() == CurrentFate.npcName and GetDistanceToTarget() < (5*math.random()) then
            yield("/vnav stop")
        end
        return
    else
        Dalamud.Log("[FATE] Check 27")
        -- if target is already selected earlier during pathing, avoids having to target and move again
        if (Svc.Targets.Target == nil or GetTargetName()~=CurrentFate.npcName) then
            Dalamud.Log("[FATE] Check 35")
            yield("/target "..CurrentFate.npcName)
            return
        end

        Dalamud.Log("[FATE] Check 32")
        if Svc.Condition[CharacterCondition.mounted] then
            State = CharacterState.npcDismount
            Dalamud.Log("[FATE] State Change: NPCDismount")
            return
        end

        Dalamud.Log("[FATE] Check 33")
        if GetDistanceToPoint(Svc.Targets.Target.Position) > 5 then
            MoveToNPC()
            return
        end

        Dalamud.Log("[FATE] Check 34")
        if Addons.GetAddon("SelectYesno").Ready then
            Dalamud.Log("[FATE] Check 44")
            AcceptNPCFateOrRejectOtherYesno()
        elseif not Svc.Condition[CharacterCondition.occupied] then
            yield("/interact")
        end
    end
end

function CollectionsFateTurnIn()
    AcceptNPCFateOrRejectOtherYesno()

    if CurrentFate ~= nil and not IsFateActive(CurrentFate.fateObject) then
        CurrentFate = nil
        State = CharacterState.ready
        Dalamud.Log("[FATE] State Change: Ready")
        return
    end

    if (Svc.Targets.Target == nil or GetTargetName()~=CurrentFate.npcName) then
        TurnOffCombatMods()
        yield("/target "..CurrentFate.npcName)
        yield("/wait 1")

        -- if too far from npc to target, then head towards center of fate
        if (Svc.Targets.Target == nil or GetTargetName()~=CurrentFate.npcName and CurrentFate.fateObject.Progress ~= nil and CurrentFate.fateObject.Progress < 100) then
            if not IPC.vnavmesh.PathfindInProgress() and not IPC.vnavmesh.IsRunning() then
                IPC.vnavmesh.PathfindAndMoveTo(CurrentFate.position, false)
            end
        else
            yield("/vnav stop")
        end
        return
    end

    if GetDistanceToTarget() > 5 then
        if not (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()) then
            MoveToNPC()
        end
    else
        if Inventory.GetItemCount(CurrentFate.fateObject.EventItem) >= 7 then
            GotCollectionsFullCredit = true
        end

        yield("/vnav stop")
        yield("/interact")
        yield("/wait 3")

        if CurrentFate.fateObject.Progress < 100 then
            TurnOnCombatMods()
            State = CharacterState.doFate
            Dalamud.Log("[FATE] State Change: DoFate")
        else
            if GotCollectionsFullCredit then
                State = CharacterState.unexpectedCombat
                Dalamud.Log("[FATE] State Change: UnexpectedCombat")
            end
        end

        if CurrentFate ~=nil and CurrentFate.npcName ~=nil and GetTargetName() == CurrentFate.npcName then
            Dalamud.Log("[FATE] Attempting to clear target.")
            ClearTarget()
            yield("/wait 1")
        end
    end
end

--#endregion

--#region Combat Functions

function GetClassJobTableFromName(classString)
    if classString == nil or classString == "" then
        return nil
    end

    for classJobId=1, 42 do
        local job = Player.GetJob(classJobId)
        if job.Name == classString then
            return job
        end
    end
    
    Dalamud.Log("[FATE] Cannot recognize combat job for boss fates.")
    return nil
end

function SummonChocobo()
    if Svc.Condition[CharacterCondition.mounted] then
        Dismount()
        return
    end

    if ShouldSummonChocobo and GetBuddyTimeRemaining() <= ResummonChocoboTimeLeft then
        if Inventory.GetItemCount(4868) > 0 then
            yield("/item 基萨尔野菜")
            yield("/wait 3")
            yield('/cac '..ChocoboStance..'')
        elseif ShouldAutoBuyGysahlGreens then
            State = CharacterState.autoBuyGysahlGreens
            Dalamud.Log("[FATE] State Change: AutoBuyGysahlGreens")
            return
        end
    end
    State = CharacterState.ready
    Dalamud.Log("[FATE] State Change: Ready")
end

function AutoBuyGysahlGreens()
    if Inventory.GetItemCount(4868) > 0 then -- don't need to buy
        if Addons.GetAddon("Shop").Ready then
            yield("/callback Shop true -1")
        elseif Svc.ClientState.TerritoryType == SelectedZone.zoneId then
            yield("/item 基萨尔野菜")
        else
            State = CharacterState.ready
            Dalamud.Log("State Change: ready")
        end
        return
    else
        if Svc.ClientState.TerritoryType ~=  129 then
            yield("/vnav stop")
            TeleportTo("利姆萨·罗敏萨下层甲板")
            return
        else
            local gysahlGreensVendor = { position=Vector3(-62.1, 18.0, 9.4), npcName="班戈·赞戈" }
            if GetDistanceToPoint(gysahlGreensVendor.position) > 5 then
                if not (IPC.vnavmesh.IsRunning() or IPC.vnavmesh.PathfindInProgress()) then
                    IPC.vnavmesh.PathfindAndMoveTo(gysahlGreensVendor.position, false)
                end
            elseif Svc.Targets.Target ~= nil and GetTargetName() == gysahlGreensVendor.npcName then
                yield("/vnav stop")
                if Addons.GetAddon("SelectYesno").Ready then
                    yield("/callback SelectYesno true 0")
                elseif Addons.GetAddon("SelectIconString").Ready then
                    yield("/callback SelectIconString true 0")
                    return
                elseif Addons.GetAddon("Shop").Ready then
                    yield("/callback Shop true 0 2 99")
                    return
                elseif not Svc.Condition[CharacterCondition.occupied] then
                    yield("/interact")
                    yield("/wait 1")
                    return
                end
            else
                yield("/vnav stop")
                yield("/targetnpc "..gysahlGreensVendor.npcName)
            end
        end
    end
end

function ClearTarget()
    Svc.Targets.Target = nil
end

function GetTargetHitboxRadius()
    if Svc.Targets.Target ~= nil then
        return Svc.Targets.Target.HitboxRadius
    else
        return 0
    end
end

function TurnOnAoes()
    Dalamud.Log("[FATE] Check 37")
    if not AoesOn then
        if RotationPlugin == "RSR" then
            yield("/rotation off")
            yield("/rotation auto on")
            Dalamud.Log("[FATE] TurnOnAoes /rotation auto on")

            if RSRAoeType == "Off" then
                yield("/rotation settings aoetype 0")
            elseif RSRAoeType == "Cleave" then
                yield("/rotation settings aoetype 1")
            elseif RSRAoeType == "Full" then
                yield("/rotation settings aoetype 2")
            end
        elseif RotationPlugin == "BMR" then
            yield("/bmrai setpresetname "..RotationAoePreset)
        elseif RotationPlugin == "VBM" then
            yield("/vbm ar toggle "..RotationAoePreset)
        end
        AoesOn = true
    end
    Dalamud.Log("[FATE] Check 38")
end

function TurnOffAoes()
    if AoesOn then
        if RotationPlugin == "RSR" then
            yield("/rotation settings aoetype 1")
            yield("/rotation manual")
            Dalamud.Log("[FATE] TurnOffAoes /rotation manual")
        elseif RotationPlugin == "BMR" then
            yield("/bmrai setpresetname "..RotationSingleTargetPreset)
        elseif RotationPlugin == "VBM" then
            yield("/vbm ar toggle "..RotationSingleTargetPreset)
        end
        AoesOn = false
    end
end

function TurnOffRaidBuffs()
    if AoesOn then
        if RotationPlugin == "BMR" then
            yield("/bmrai setpresetname "..RotationHoldBuffPreset)
        elseif RotationPlugin == "VBM" then
            yield("/vbm ar toggle "..RotationHoldBuffPreset)
        end
    end
end

function SetMaxDistance()
    MaxDistance = MeleeDist --default to melee distance
    --ranged and casters have a further max distance so not always running all way up to target
    if not Player.Job.IsMelee then
        MaxDistance = RangedDist
    end
end

function TurnOnCombatMods(rotationMode)
    if not CombatModsOn then
        CombatModsOn = true
        -- turn on RSR in case you have the RSR 30 second out of combat timer set
        if RotationPlugin == "RSR" then
            if rotationMode == "manual" then
                yield("/rotation manual")
                Dalamud.Log("[FATE] TurnOnCombatMods /rotation manual")
            else
                yield("/rotation off")
                yield("/rotation auto on")
                Dalamud.Log("[FATE] TurnOnCombatMods /rotation auto on")
            end
        elseif RotationPlugin == "BMR" then
            yield("/bmrai setpresetname "..RotationAoePreset)
        elseif RotationPlugin == "VBM" then
            yield("/vbm ar toggle "..RotationAoePreset)
        elseif RotationPlugin == "Wrath" then
            yield("/wrath auto on")
        end
        
        if not AiDodgingOn then
            SetMaxDistance()
            
            if DodgingPlugin == "BMR" then
                yield("/bmrai on")
                yield("/bmrai followtarget on") -- overrides navmesh path and runs into walls sometimes
                yield("/bmrai followcombat on")
                -- yield("/bmrai followoutofcombat on")
                yield("/bmrai maxdistancetarget " .. MaxDistance)
            elseif DodgingPlugin == "VBM" then
                yield("/vbmai on")
                yield("/vbmai followtarget on") -- overrides navmesh path and runs into walls sometimes
                yield("/vbmai followcombat on")
                -- yield("/bmrai followoutofcombat on")
                yield("/vbmai maxdistancetarget " .. MaxDistance)
                if RotationPlugin ~= "VBM" then
                    yield("/vbmai ForbidActions on") --This Disables VBM AI Auto-Target
                end
            end
            AiDodgingOn = true
        end
    end
end

function TurnOffCombatMods()
    if CombatModsOn then
        Dalamud.Log("[FATE] Turning off combat mods")
        CombatModsOn = false

        if RotationPlugin == "RSR" then
            yield("/rotation off")
            Dalamud.Log("[FATE] TurnOffCombatMods /rotation off")
        elseif RotationPlugin == "BMR" or RotationPlugin == "VBM" then
            yield("/bmrai setpresetname nil")
        elseif RotationPlugin == "Wrath" then
            yield("/wrath auto off")
        end

        -- turn off BMR so you don't start following other mobs
        if AiDodgingOn then
            if DodgingPlugin == "BMR" then
                yield("/bmrai off")
                yield("/bmrai followtarget off")
                yield("/bmrai followcombat off")
                yield("/bmrai followoutofcombat off")
            elseif DodgingPlugin == "VBM" then
                yield("/vbm ar disable")
                yield("/vbmai off")
                yield("/vbmai followtarget off")
                yield("/vbmai followcombat off")
                yield("/vbmai followoutofcombat off")
                if RotationPlugin ~= "VBM" then
                    yield("/vbmai ForbidActions off") --This Enables VBM AI Auto-Target
                end
            end
            AiDodgingOn = false
        end
    end
end

function HandleUnexpectedCombat()
    TurnOnCombatMods("manual")

    local nearestFate = Fates.GetNearestFate()
    if InActiveFate() and nearestFate.Progress < 100 then
        CurrentFate = BuildFateTable(nearestFate)
        State = CharacterState.doFate
        Dalamud.Log("[FATE] State Change: DoFate")
        return
    elseif not Svc.Condition[CharacterCondition.inCombat] then
        yield("/vnav stop")
        ClearTarget()
        TurnOffCombatMods()
        State = CharacterState.ready
        Dalamud.Log("[FATE] State Change: Ready")
        local randomWait = (math.floor(math.random()*MaxWait * 1000)/1000) + MinWait -- truncated to 3 decimal places
        yield("/wait "..randomWait)
        return
    end

    -- if Svc.Condition[CharacterCondition.mounted] then
    --     if not (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()) then
    --         IPC.vnavmesh.PathfindAndMoveTo(Svc.ClientState.Location, true)
    --     end
    --     yield("/wait 10")
    --     return
    -- end

    -- targets whatever is trying to kill you
    if Svc.Targets.Target == nil then
        yield("/battletarget")
    end

    -- pathfind closer if enemies are too far
    if Svc.Targets.Target ~= nil then
        if GetDistanceToTarget() > (MaxDistance + GetTargetHitboxRadius()) then
            if not (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()) then
                if Player.CanFly and SelectedZone.flying then
                    yield("/vnav flytarget")
                else
                    MoveToTargetHitbox()
                end
            end
        else
            if IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() then
                yield("/vnav stop")
            elseif not Svc.Condition[CharacterCondition.inCombat] then
                --inch closer 3 seconds
                if Svc.Condition[CharacterCondition.flying] and SelectedZone.flying then
                    yield("/vnav flytarget")
                else
                    MoveToTargetHitbox()
                end
                yield("/wait 3")
            end
        end
    end
    yield("/wait 1")
end

function DoFate()
    Dalamud.Log("[FATE] Check 61")
    if WaitingForFateRewards == nil or WaitingForFateRewards.fateId ~= CurrentFate.fateId then
        WaitingForFateRewards = CurrentFate
        Dalamud.Log("[FATE] WaitingForFateRewards DoFate: "..tostring(WaitingForFateRewards.fateId))
    end
    local currentClass = Player.Job
    -- switch classes (mostly for continutation fates that pop you directly into the next one)
    if CurrentFate.isBossFate and BossFatesClass ~= nil and currentClass ~= BossFatesClass.classId and not Player.IsBusy then
        TurnOffCombatMods()
        yield("/gs change "..BossFatesClass.className)
        yield("/wait 1")
        return
    elseif not CurrentFate.isBossFate and BossFatesClass ~= nil and currentClass ~= MainClass.classId and not Player.IsBusy then
        TurnOffCombatMods()
        yield("/gs change "..MainClass.className)
        yield("/wait 1")
        return
    elseif not Dalamud.Log("[FATE] Check 62") and InActiveFate() and (CurrentFate.fateObject.MaxLevel < Player.Job.Level) and not Player.IsLevelSynced then
        Dalamud.Log("[FATE] Check 60")
        yield("/lsync")
        yield("/wait 0.5") -- give it a second to register
    elseif not Dalamud.Log("[FATE] Check 63") and IsFateActive(CurrentFate.fateObject) and not InActiveFate() and CurrentFate.fateObject.Progress ~= nil and CurrentFate.fateObject.Progress < 100 and
        (GetDistanceToPoint(CurrentFate.position) < CurrentFate.fateObject.Radius + 10) and
        not Svc.Condition[CharacterCondition.mounted] and not (IPC.vnavmesh.IsRunning() or IPC.vnavmesh.PathfindInProgress())
    then -- got pushed out of fate. go back
        yield("/vnav stop")
        yield("/wait 1")
        Dalamud.Log("[FATE] pushed out of fate going back!")
        IPC.vnavmesh.PathfindAndMoveTo(CurrentFate.position, Svc.Condition[CharacterCondition.flying] and SelectedZone.flying)
        return
    elseif not IsFateActive(CurrentFate.fateObject) or CurrentFate.fateObject.Progress == 100 then
        yield("/vnav stop")
        ClearTarget()
        if not Dalamud.Log("[FATE] HasContintuation check") and CurrentFate.hasContinuation then
            LastFateEndTime = os.clock()
            State = CharacterState.waitForContinuation
            Dalamud.Log("[FATE] State Change: WaitForContinuation")
            return
        else
            DidFate = true
            Dalamud.Log("[FATE] No continuation for "..CurrentFate.fateName)
            local randomWait = (math.floor(math.random() * (math.max(0, MaxWait - 3)) * 1000)/1000) + MinWait -- truncated to 3 decimal places
            yield("/wait "..randomWait)
            TurnOffCombatMods()
            State = CharacterState.ready
            Dalamud.Log("[FATE] State Change: Ready")
        end
        return
    elseif Svc.Condition[CharacterCondition.mounted] then
        State = CharacterState.MiddleOfFateDismount
        Dalamud.Log("[FATE] State Change: MiddleOfFateDismount")
        return
    elseif CurrentFate.isCollectionsFate then
        yield("/wait 1") -- needs a moment after start of fate for GetFateEventItem to populate
        if Inventory.GetItemCount(CurrentFate.fateObject.EventItem) >= 7 or (GotCollectionsFullCredit and CurrentFate.fateObject.Progress == 100) then
            yield("/vnav stop")
            State = CharacterState.collectionsFateTurnIn
            Dalamud.Log("[FATE] State Change: CollectionsFatesTurnIn")
        end
    end

    Dalamud.Log("[FATE] DoFate->Finished transition checks")

    -- do not target fate npc during combat
    if CurrentFate.npcName ~=nil and GetTargetName() == CurrentFate.npcName then
        Dalamud.Log("[FATE] Attempting to clear target.")
        ClearTarget()
        yield("/wait 1")
    end

    TurnOnCombatMods("auto")

    GemAnnouncementLock = false

    -- switches to targeting forlorns for bonus (if present)
    if not IgnoreForlorns then
        yield("/target 迷失少女")
        if not IgnoreBigForlornOnly then
            yield("/target 迷失者")
        end
    end

    if (GetTargetName() == "迷失少女" or GetTargetName() == "迷失者") then
        if IgnoreForlorns or (IgnoreBigForlornOnly and GetTargetName() == "迷失者") then
            ClearTarget()
        elseif not Svc.Targets.Target.IsDead then
            if not ForlornMarked then
                yield("/enemysign attack1")
                if Echo == "All" then
                    yield("/echo 发现迷失者! <se.3>")
                end
                TurnOffAoes()
                ForlornMarked = true
            end
        else
            ClearTarget()
            TurnOnAoes()
        end
    else
        TurnOnAoes()
    end

    Dalamud.Log("[FATE] Check 39")
    -- targets whatever is trying to kill you
    if Entity.Target == nil then
        yield("/battletarget")
    end

    -- clears target
    Dalamud.Log("[FATE] Check 40")
    if Entity.Target ~= nil and Entity.Target.FateId ~= CurrentFate.fateId and not Entity.Target.IsInCombat then
        Dalamud.Log("[FATE] Check 41")
        Entity.Target:ClearTarget()
    end

    Dalamud.Log("[FATE] Check 42")
    -- do not interrupt casts to path towards enemies
    if Svc.Condition[CharacterCondition.casting] then
        return
    end

    Dalamud.Log("[FATE] Check 49")
    --hold buff thingy
    if CurrentFate.fateObject.Progress ~= nil and CurrentFate.fateObject.Progress >= PercentageToHoldBuff then
        TurnOffRaidBuffs()
    end

    Dalamud.Log("[FATE] Check 43")
    -- pathfind closer if enemies are too far
    if not Svc.Condition[CharacterCondition.inCombat] then
        Dalamud.Log("[FATE] Check 47")
        if Svc.Targets.Target ~= nil then
            Dalamud.Log("[FATE] Check 57")
            if GetDistanceToTarget() <= (MaxDistance + GetTargetHitboxRadius()) then
                if IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() then
                    yield("/vnav stop")
                    yield("/wait 5.002") -- wait 5s before inching any closer
                elseif (GetDistanceToTarget() > (1 + GetTargetHitboxRadius())) and not Svc.Condition[CharacterCondition.casting] then -- never move into hitbox
                    yield("/vnav movetarget")
                    yield("/wait 1") -- inch closer by 1s
                end
            elseif not (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()) then
                yield("/wait 5.003") -- give 5s for enemy AoE casts to go off before attempting to move closer
                if (Svc.Targets.Target ~= nil and not Svc.Condition[CharacterCondition.inCombat]) and not Svc.Condition[CharacterCondition.casting] then
                    MoveToTargetHitbox()
                end
            end
            Dalamud.Log("[FATE] Check 59")
            return
        else
            Dalamud.Log("[FATE] Check 58")
            AttemptToTargetClosestFateEnemy()
            yield("/wait 1") -- wait in case target doesn't stick
            if (Svc.Targets.Target == nil) and not Svc.Condition[CharacterCondition.casting] then
                IPC.vnavmesh.PathfindAndMoveTo(CurrentFate.position, false)
            end
        end
    else
        Dalamud.Log("[FATE] Check 48")
        if Svc.Targets.Target ~= nil and (GetDistanceToTarget() <= (MaxDistance + GetTargetHitboxRadius())) then
            if IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() then
                yield("/vnav stop")
            end
        elseif not CurrentFate.isBossFate then
            if not (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()) then
                yield("/wait 5.004")
                if Svc.Targets.Target ~= nil and not Svc.Condition[CharacterCondition.casting] then
                    if Svc.Condition[CharacterCondition.flying] and SelectedZone.flying then
                        yield("/vnav flytarget")
                    else
                        MoveToTargetHitbox()
                    end
                end
            end
        end
    end

    Dalamud.Log("[FATE] Check 50")
end

--#endregion

--#region State Transition Functions

function Ready()
    Dalamud.Log("[FATE] Check 1")
    FoodCheck()
    PotionCheck()

    CombatModsOn = false -- expect RSR to turn off after every fate
    GotCollectionsFullCredit = false
    ForlornMarked = false
    MovingAnnouncementLock = false

    Dalamud.Log("[FATE] Check 2")
    local shouldWaitForBonusBuff = WaitIfBonusBuff and (HasStatusId(1288) or HasStatusId(1289))
    local needsRepair = Inventory.GetItemsInNeedOfRepairs(RemainingDurabilityToRepair)
    local spiritbonded = Inventory.GetSpiritbondedItems()

    Dalamud.Log("[FATE] Check 3")
    NextFate = SelectNextFate()
    Dalamud.Log("[FATE] Check 4")
    if CurrentFate ~= nil and not IsFateActive(CurrentFate.fateObject) then
        CurrentFate = nil
    end

    if CurrentFate == nil then
        Dalamud.Log("[FATE] CurrentFate is nil")
    else
        Dalamud.Log("[FATE] CurrentFate is "..CurrentFate.fateName)
    end

    if NextFate == nil then
        Dalamud.Log("[FATE] NextFate is nil")
    else
        Dalamud.Log("[FATE] NextFate is "..NextFate.fateName)
    end

    if not Dalamud.Log("[FATE] Ready -> Player.Available") and not Player.Available then
        return
    elseif not Dalamud.Log("[FATE] Ready -> Repair") and RemainingDurabilityToRepair > 0 and needsRepair.Count > 0 and
        (not shouldWaitForBonusBuff or (SelfRepair and Inventory.GetItemCount(33916) > 0)) then
        State = CharacterState.repair
        Dalamud.Log("[FATE] State Change: Repair")
    elseif not Dalamud.Log("[FATE] Ready -> ExtractMateria") and ShouldExtractMateria and spiritbonded.Count > 0 and Inventory.GetFreeInventorySlots() > 1 then
        State = CharacterState.extractMateria
        Dalamud.Log("[FATE] State Change: ExtractMateria")
    elseif (not Dalamud.Log("[FATE] Ready -> WaitBonusBuff") and NextFate == nil and shouldWaitForBonusBuff) and DownTimeWaitAtNearestAetheryte then
        if Svc.Targets.Target == nil or GetTargetName() ~= "以太之光" or GetDistanceToTarget() > 20 then
            State = CharacterState.flyBackToAetheryte
            Dalamud.Log("[FATE] State Change: FlyBackToAetheryte")
        else
            yield("/wait 10")
        end
        return
    elseif not Dalamud.Log("[FATE] Ready -> ExchangingVouchers") and WaitingForFateRewards == nil and
        ShouldExchangeBicolorGemstones and (BicolorGemCount >= 1400) and not shouldWaitForBonusBuff
    then
        State = CharacterState.exchangingVouchers
        Dalamud.Log("[FATE] State Change: ExchangingVouchers")
    elseif not Dalamud.Log("[FATE] Ready -> ProcessRetainers") and WaitingForFateRewards == nil and
        Retainers and ARRetainersWaitingToBeProcessed() and Inventory.GetFreeInventorySlots() > 1  and not shouldWaitForBonusBuff
    then
        State = CharacterState.processRetainers
        Dalamud.Log("[FATE] State Change: ProcessingRetainers")
    elseif not Dalamud.Log("[FATE] Ready -> GC TurnIn") and ShouldGrandCompanyTurnIn and
        Inventory.GetFreeInventorySlots() < InventorySlotsLeft and not shouldWaitForBonusBuff
    then
        State = CharacterState.gcTurnIn
        Dalamud.Log("[FATE] State Change: GCTurnIn")
    elseif not Dalamud.Log("[FATE] Ready -> TeleportBackToFarmingZone") and Svc.ClientState.TerritoryType ~=  SelectedZone.zoneId then
        TeleportTo(SelectedZone.aetheryteList[1].aetheryteName)
        return
    elseif not Dalamud.Log("[FATE] Ready -> SummonChocobo") and ShouldSummonChocobo and GetBuddyTimeRemaining() <= ResummonChocoboTimeLeft and
        (not shouldWaitForBonusBuff or Inventory.GetItemCount(4868) > 0) then
        State = CharacterState.summonChocobo
    elseif not Dalamud.Log("[FATE] Ready -> NextFate nil") and NextFate == nil then
        if EnableChangeInstance and GetZoneInstance() > 0 and not shouldWaitForBonusBuff then
            State = CharacterState.changingInstances
            Dalamud.Log("[FATE] State Change: ChangingInstances")
            return
        elseif CompanionScriptMode and not shouldWaitForBonusBuff then
            if WaitingForFateRewards == nil then
                StopScript = true
                Dalamud.Log("[FATE] StopScript: Ready")
            else
                Dalamud.Log("[FATE] Waiting for fate rewards")
            end
        elseif (Svc.Targets.Target == nil or GetTargetName() ~= "以太之光" or GetDistanceToTarget() > 20) and DownTimeWaitAtNearestAetheryte then
            State = CharacterState.flyBackToAetheryte
            Dalamud.Log("[FATE] State Change: FlyBackToAetheryte")
        else
            if not Svc.Condition[CharacterCondition.mounted] then
                Mount()
            end
            yield("/wait 10")
        end
        return
    elseif CompanionScriptMode and DidFate and not shouldWaitForBonusBuff then
        if WaitingForFateRewards == nil then
            StopScript = true
            Dalamud.Log("[FATE] StopScript: DidFate")
        else
            Dalamud.Log("[FATE] Waiting for fate rewards")
        end
    elseif not Dalamud.Log("[FATE] Ready -> MovingToFate") then -- and ((CurrentFate == nil) or (GetFateProgress(CurrentFate.fateId) == 100) and NextFate ~= nil) then
        CurrentFate = NextFate
        SetMapFlag(SelectedZone.zoneId, CurrentFate.position)
        State = CharacterState.moveToFate
        Dalamud.Log("[FATE] State Change: MovingtoFate "..CurrentFate.fateName)
    end

    if not GemAnnouncementLock and (Echo == "All" or Echo == "Gems") then
        GemAnnouncementLock = true
        if BicolorGemCount >= 1400 then
            yield("/echo [FATE] 你已经有了 "..tostring(BicolorGemCount).."/1500 gems! <se.3>")
        else
            yield("/echo [FATE] 双色宝石: "..tostring(BicolorGemCount).."/1500")
        end
    end
end


function HandleDeath()
    CurrentFate = nil

    if CombatModsOn then
        TurnOffCombatMods()
    end

    if IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() then
        yield("/vnav stop")
    end

    if Svc.Condition[CharacterCondition.dead] then --Condition Dead
        if ReturnOnDeath then
            if Echo and not DeathAnnouncementLock then
                DeathAnnouncementLock = true
                if Echo == "All" then
                    yield("/echo [FATE] 你死了，回家吧孩子.")
                end
            end

            if Addons.GetAddon("SelectYesno").Ready then --rez addon yes
                yield("/callback SelectYesno true 0")
                yield("/wait 0.1")
            end
        else
            if Echo and not DeathAnnouncementLock then
                DeathAnnouncementLock = true
                if Echo == "All" then
                    yield("/echo [FATE] 你已经死了。等待脚本检测到您复活...")
                end
            end
            yield("/wait 1")
        end
    else
        State = CharacterState.ready
        Dalamud.Log("[FATE] State Change: Ready")
        DeathAnnouncementLock = false
    end
end

function ExecuteBicolorExchange()
    CurrentFate = nil

    if BicolorGemCount >= 1400 then
        if Addons.GetAddon("SelectYesno").Ready then
            yield("/callback SelectYesno true 0")
            return
        end

        if Addons.GetAddon("ShopExchangeCurrency").Ready then
            yield("/callback ShopExchangeCurrency false 0 "..SelectedBicolorExchangeData.item.itemIndex.." "..(BicolorGemCount//SelectedBicolorExchangeData.item.price))
            return
        end

        if Svc.ClientState.TerritoryType ~=  SelectedBicolorExchangeData.zoneId then
            TeleportTo(SelectedBicolorExchangeData.aetheryteName)
            return
        end
    
        if SelectedBicolorExchangeData.miniAethernet ~= nil and
            GetDistanceToPoint(SelectedBicolorExchangeData.position) > (DistanceBetween(SelectedBicolorExchangeData.miniAethernet.position, SelectedBicolorExchangeData.position) + 10) then
            Dalamud.Log("Distance to shopkeep is too far. Using mini aetheryte.")
            yield("/li "..SelectedBicolorExchangeData.miniAethernet.name)
            yield("/wait 1") -- give it a moment to register
            return
        elseif Addons.GetAddon("TelepotTown").Ready then
            Dalamud.Log("TelepotTown open")
            yield("/callback TelepotTown false -1")
        elseif GetDistanceToPoint(SelectedBicolorExchangeData.position) > 5 then
            Dalamud.Log("Distance to shopkeep is too far. Walking there.")
            if not (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()) then
                Dalamud.Log("Path not running")
                IPC.vnavmesh.PathfindAndMoveTo(SelectedBicolorExchangeData.position, false)
            end
        else
            Dalamud.Log("[FATE] Arrived at Shopkeep")
            if IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() then
                yield("/vnav stop")
            end
    
            if Svc.Targets.Target == nil or GetTargetName() ~= SelectedBicolorExchangeData.shopKeepName then
                yield("/target "..SelectedBicolorExchangeData.shopKeepName)
            elseif not Svc.Condition[CharacterCondition.occupiedInQuestEvent] then
                yield("/interact")
            end
        end
    else
        if Addons.GetAddon("ShopExchangeCurrency").Ready then
            Dalamud.Log("[FATE] Attemping to close shop window")
            yield("/callback ShopExchangeCurrency true -1")
            return
        elseif Svc.Condition[CharacterCondition.occupiedInEvent] then
            Dalamud.Log("[FATE] Character still occupied talking to shopkeeper")
            yield("/wait 0.5")
            return
        end

        State = CharacterState.ready
        Dalamud.Log("[FATE] State Change: Ready")
        return
    end
end

function ProcessRetainers()
    CurrentFate = nil

    Dalamud.Log("[FATE] Handling retainers...")
    if ARRetainersWaitingToBeProcessed() and Inventory.GetFreeInventorySlots() > 1 then
    
        if IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() then
            return
        end

        if Svc.ClientState.TerritoryType ~=  129 then
            yield("/vnav stop")
            TeleportTo("利姆萨·罗敏萨下层甲板")
            return
        end

        local summoningBell = {
            name="传唤铃",
            position=Vector3(-122.72, 18.00, 20.39)
        }
        if GetDistanceToPoint(summoningBell.position) > 4.5 then
            IPC.vnavmesh.PathfindAndMoveTo(summoningBell.position, false)
            return
        end

        if Svc.Targets.Target == nil or GetTargetName() ~= summoningBell.name then
            yield("/target "..summoningBell.name)
            return
        end

        if not Svc.Condition[CharacterCondition.occupiedSummoningBell] then
            yield("/interact")
            if Addons.GetAddon("RetainerList").Ready then
                yield("/ays e")
                if Echo == "All" then
                    yield("/echo [FATE] Processing retainers")
                end
                yield("/wait 1")
            end
        end
    else
        if Addons.GetAddon("RetainerList").Ready then
            yield("/callback RetainerList true -1")
        elseif not Svc.Condition[CharacterCondition.occupiedSummoningBell] then
            State = CharacterState.ready
            Dalamud.Log("[FATE] State Change: Ready")
        end
    end
end

function GrandCompanyTurnIn()
    if Inventory.GetFreeInventorySlots() <= InventorySlotsLeft then
        local gcZoneIds = {
            129, --利姆萨·罗敏萨下层甲板
            132, --格里达尼亚新街
            130 --"乌尔达哈现世回廊"
        }
        if Svc.ClientState.TerritoryType ~=  gcZoneIds[Player.GrandCompany] then
            yield("/li gc")
            yield("/wait 1")
        elseif IPC.Deliveroo.IsTurnInRunning() then
            return
        else
            yield("/deliveroo enable")
        end
    else
        State = CharacterState.ready
        Dalamud.Log("State Change: Ready")
    end
end

function Repair()
    local needsRepair = Inventory.GetItemsInNeedOfRepairs(RemainingDurabilityToRepair)
    if Addons.GetAddon("SelectYesno").Ready then
        yield("/callback SelectYesno true 0")
        return
    end

    if Addons.GetAddon("Repair").Ready then
        if needsRepair.Count == nil or needsRepair.Count == 0 then
            yield("/callback Repair true -1") -- if you don't need repair anymore, close the menu
        else
            yield("/callback Repair true 0") -- select repair
        end
        return
    end

    -- if occupied by repair, then just wait
    if Svc.Condition[CharacterCondition.occupiedMateriaExtractionAndRepair] then
        Dalamud.Log("[FATE] Repairing...")
        yield("/wait 1")
        return
    end

    local hawkersAlleyAethernetShard = { x=-213.95, y=15.99, z=49.35 }
    if SelfRepair then
        if Inventory.GetItemCount(33916) > 0 then
            if Addons.GetAddon("Shop") then
                yield("/callback Shop true -1")
                return
            end

            if Svc.ClientState.TerritoryType ~=  SelectedZone.zoneId then
                TeleportTo(SelectedZone.aetheryteList[1].aetheryteName)
                return
            end

            if Svc.Condition[CharacterCondition.mounted] then
                Dismount()
                Dalamud.Log("[FATE] State Change: Dismounting")
                return
            end

            if needsRepair.Count > 0 then
                if not Addons.GetAddon("Repair").Ready then
                    Dalamud.Log("[FATE] Opening repair menu...")
                    yield("/generalaction 修理")
                end
            else
                State = CharacterState.ready
                Dalamud.Log("[FATE] State Change: Ready")
            end
        elseif ShouldAutoBuyDarkMatter then
            if Svc.ClientState.TerritoryType ~=  129 then
                if Echo == "All" then
                    yield("/echo 没有暗物质了！去海都买点吧")
                end
                TeleportTo("利姆萨·罗敏萨下层甲板")
                return
            end

            local darkMatterVendor = { npcName="乌恩辛雷尔", x=-257.71, y=16.19, z=50.11, wait=0.08 }
            if GetDistanceToPoint(darkMatterVendor.position) > (DistanceBetween(hawkersAlleyAethernetShard.position, darkMatterVendor.position) + 10) then
                yield("/li 市场（国际广场）")
                yield("/wait 1") -- give it a moment to register
            elseif Addons.GetAddon("TelepotTown").Ready then
                yield("/callback TelepotTown false -1")
            elseif GetDistanceToPoint(darkMatterVendor.position) > 5 then
                if not (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()) then
                    IPC.vnavmesh.PathfindAndMoveTo(darkMatterVendor.position, false)
                end
            else
                if Svc.Targets.Target == nil or GetTargetName() ~= darkMatterVendor.npcName then
                    yield("/targetnpc "..darkMatterVendor.npcName)
                elseif not Svc.Condition[CharacterCondition.occupiedInQuestEvent] then
                    yield("/interact")
                elseif Addons.GetAddon("SelectYesno").Ready then
                    yield("/callback SelectYesno true 0")
                elseif Addons.GetAddon("Shop") then
                    yield("/callback Shop true 0 40 99")
                end
            end
        else
            if Echo == "All" then
                yield("/echo Out of Dark Matter and ShouldAutoBuyDarkMatter is false. Switching to Limsa mender.")
            end
            SelfRepair = false
        end
    else
        if needsRepair.Count > 0 then
            if Svc.ClientState.TerritoryType ~= 129 then
                TeleportTo("利姆萨·罗敏萨下层甲板")
                return
            end
            
            local mender = { npcName="阿里斯特尔", x=-246.87, y=16.19, z=49.83 }
            if GetDistanceToPoint(mender.position) > (DistanceBetween(hawkersAlleyAethernetShard.position, mender.position) + 10) then
                yield("/li 市场（国际广场）")
                yield("/wait 1") -- give it a moment to register
            elseif Addons.GetAddon("TelepotTown").Ready then
                yield("/callback TelepotTown false -1")
            elseif GetDistanceToPoint(mender.position) > 5 then
                if not (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()) then
                    IPC.vnavmesh.PathfindAndMoveTo(mender.position, false)
                end
            else
                if Svc.Targets.Target == nil or GetTargetName() ~= mender.npcName then
                    yield("/targetnpc "..mender.npcName)
                elseif not Svc.Condition[CharacterCondition.occupiedInQuestEvent] then
                    yield("/interact")
                end
            end
        else
            State = CharacterState.Ready
            Dalamud.Log("[FATE] State Change: Ready")
        end
    end
end

function ExtractMateria()
    if Svc.Condition[CharacterCondition.mounted] then
        Dismount()
        Dalamud.Log("[FATE] State Change: Dismounting")
        return
    end

    if Svc.Condition[CharacterCondition.occupiedMateriaExtractionAndRepair] then
        return
    end

    if Inventory.GetSpiritbondedItems().Count > 0 and Inventory.GetFreeInventorySlots() > 1 then
        if not Addons.GetAddon("Materialize").Ready then
            yield("/generalaction \"精制魔晶石\"")
            return
        end

        Dalamud.Log("[FATE] Extracting materia...")
            
        if Addons.GetAddon("MaterializeDialog").Ready then
            yield("/callback MaterializeDialog true 0")
        else
            yield("/callback Materialize true 2 0")
        end
    else
        if Addons.GetAddon("Materialize").Ready then
            yield("/callback Materialize true -1")
        else
            State = CharacterState.ready
            Dalamud.Log("[FATE] State Change: Ready")
        end
    end
end

--#endregion State Transition Functions

--#region Misc Functions

function EorzeaTimeToUnixTime(eorzeaTime)
    return eorzeaTime/(144/7) -- 24h Eorzea Time equals 70min IRL
end

function HasStatusId(statusId)
    local statusList = Svc.ClientState.LocalPlayer.StatusList
    if statusList == nil then
        return false
    end
    for i=0, statusList.Length-1 do
        if statusList[i].StatusId == statusId then
            return true
        end
    end
    return false
end

function FoodCheck()
    --food usage
    if not HasStatusId(48) and Food ~= "" then
        yield("/item " .. Food)
    end
end

function PotionCheck()
    --pot usage
    if not HasStatusId(49) and Potion ~= "" then
        yield("/item " .. Potion)
    end
end

function GetNodeText(addonName, nodePath, ...)
    local addon = Addons.GetAddon(addonName)
    repeat
        yield("/wait 0.1")
    until addon.Ready
    return addon:GetNode(nodePath, ...).Text
end

function ARRetainersWaitingToBeProcessed()
    local offlineCharacterData = IPC.AutoRetainer.GetOfflineCharacterData(Svc.ClientState.LocalContentId)
    for i=0, offlineCharacterData.RetainerData.Count-1 do
        local retainer = offlineCharacterData.RetainerData[i]
        if retainer.HasVenture and retainer.VentureEndsAt <= os.time() then
            return true
        end
    end
    return false
end

--#endregion Misc Functions

CharacterState = {
    ready = Ready,
    dead = HandleDeath,
    unexpectedCombat = HandleUnexpectedCombat,
    mounting = MountState,
    npcDismount = NpcDismount,
    MiddleOfFateDismount = MiddleOfFateDismount,
    moveToFate = MoveToFate,
    interactWithNpc = InteractWithFateNpc,
    collectionsFateTurnIn = CollectionsFateTurnIn,
    doFate = DoFate,
    waitForContinuation = WaitForContinuation,
    changingInstances = ChangeInstance,
    changeInstanceDismount = ChangeInstanceDismount,
    flyBackToAetheryte = FlyBackToAetheryte,
    extractMateria = ExtractMateria,
    repair = Repair,
    exchangingVouchers = ExecuteBicolorExchange,
    processRetainers = ProcessRetainers,
    gcTurnIn = GrandCompanyTurnIn,
    summonChocobo = SummonChocobo,
    autoBuyGysahlGreens = AutoBuyGysahlGreens
}

--#region Main

Dalamud.Log("[FATE] Starting fate farming script.")

StopScript = false
DidFate = false
GemAnnouncementLock = false
DeathAnnouncementLock = false
MovingAnnouncementLock = false
SuccessiveInstanceChanges = 0
LastInstanceChangeTimestamp = 0
LastTeleportTimeStamp = 0
GotCollectionsFullCredit = false -- needs 7 items for  full
-- variable to track collections fates that you have completed but are still active.
-- will not leave area or change instance if value ~= 0
WaitingForFateRewards = nil
LastFateEndTime = os.clock()
LastStuckCheckTime = os.clock()
LastStuckCheckPosition = Player.Entity.Position
MainClass = Player.Job
BossFatesClass = nil
if ClassForBossFates ~= "" then
    BossFatesClass = GetClassJobTableFromName(ClassForBossFates)
end
SetMaxDistance()

SelectedZone = SelectNextZone()
if SelectedZone.zoneName ~= "" and Echo == "All" then
    yield("/echo [FATE]前往 "..SelectedZone.zoneName)
end
Dalamud.Log("[FATE] Farming Start for "..SelectedZone.zoneName)

for _, shop in ipairs(BicolorExchangeData) do
    for _, item in ipairs(shop.shopItems) do
        if item.itemName == ItemToPurchase then
            SelectedBicolorExchangeData = {
                shopKeepName = shop.shopKeepName,
                zoneId = shop.zoneId,
                aetheryteName = shop.aetheryteName,
                miniAethernet = shop.miniAethernet,
                position = shop.position,
                item = item
            }
        end
    end
end
if SelectedBicolorExchangeData == nil then
    yield("/echo [FATE] 无法识别："..ItemToPurchase..". 请确保它在兑换表中！")
    StopScript = true
end

State = CharacterState.ready
CurrentFate = nil
if InActiveFate() then
    CurrentFate = BuildFateTable(Fates.GetNearestFate())
end

if ShouldSummonChocobo and GetBuddyTimeRemaining() > 0 then
    yield('/cac '..ChocoboStance..'')
end

while not StopScript do
    local nearestFate = Fates.GetNearestFate()
    if not IPC.vnavmesh.IsReady() then
        yield("/echo [FATE] 正在等待构建路线")
        Dalamud.Log("[FATE] Waiting for vnavmesh to build...")
        repeat
            yield("/wait 1")
        until IPC.vnavmesh.IsReady()
    end
    if State ~= CharacterState.dead and Svc.Condition[CharacterCondition.dead] then
        State = CharacterState.dead
        Dalamud.Log("[FATE] State Change: Dead")
    elseif State ~= CharacterState.unexpectedCombat and State ~= CharacterState.doFate and
        State ~= CharacterState.waitForContinuation and State ~= CharacterState.collectionsFateTurnIn and
        (not InActiveFate() or (InActiveFate() and IsCollectionsFate(nearestFate.Name) and nearestFate.Progress == 100)) and
        Svc.Condition[CharacterCondition.inCombat]
    then
        State = CharacterState.unexpectedCombat
        Dalamud.Log("[FATE] State Change: UnexpectedCombat")
    end
    
    BicolorGemCount = Inventory.GetItemCount(26807)

    if not (Player.Entity.IsCasting or
        Svc.Condition[CharacterCondition.betweenAreas] or
        Svc.Condition[CharacterCondition.jumping48] or
        Svc.Condition[CharacterCondition.jumping61] or
        Svc.Condition[CharacterCondition.mounting57] or
        Svc.Condition[CharacterCondition.mounting64] or
        Svc.Condition[CharacterCondition.beingMoved] or
        Svc.Condition[CharacterCondition.occupiedMateriaExtractionAndRepair] or
        IPC.Lifestream.IsBusy())
    then
        if WaitingForFateRewards ~= nil and not WaitingForFateRewards.fateObject.State == FateState.Ended then
            WaitingForFateRewards = nil
            Dalamud.Log("[FATE] WaitingForFateRewards: "..tostring(WaitingForFateRewards.fateId))
        end
        State()
    end
    yield("/wait 0.1")
end
yield("/vnav stop")

if Player.Job.Id ~= MainClass.Id then
    yield("/gs change "..MainClass.Name)
end
--#endregion Main
