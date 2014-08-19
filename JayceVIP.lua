local version = "1.05"
--[[
Jayce, Hammer Time - VIP Version

by Dienofail

Changelog:




v1.0 - MAJOR REWRITE - VIP ONLY COMPATIBLE. OLD SCRIPT CAN BE FOUND AS JAYCE.LUA

v1.01 - Added delay action for detection of orbwalkers. 

v1.02 - Fixed collision and stuff. 

v1.03 - Fixed dash check errors

v1.04 - Added Q+E mana checks for ranged form

v1.05 - Added Hammer E before Q...had maknoon combo wrong the whole time.
]]

if myHero.charName ~= "Jayce" then return end
require 'VPrediction'


local ProdOneLoaded = false
local ProdFile = LIB_PATH .. "Prodiction.lua"
local fh = io.open(ProdFile, 'r')
if fh ~= nil then
  local line = fh:read()
  local Version = string.match(line, "%d+.%d+")
  if Version == nil or tonumber(Version) == nil then
    ProdOneLoaded = false
  elseif tonumber(Version) > 0.8 then
    ProdOneLoaded = true
  end
  if ProdOneLoaded then
    require 'Prodiction'
    print("<font color=\"#FF0000\">Prodiction 1.0+ Loaded for DienoJayce, 1.0+ option is usable</font>")
  else
    print("<font color=\"#FF0000\">Prodiction 1.0+ not detected for DienoJayce, 1.0+ is not usable (will cause errors if checked)</font>")
  end
else
  print("<font color=\"#FF0000\">No Prodiction.lua detected, using only VPRED</font>")
end

function checkOrbwalker()
    if _G.MMA_Loaded ~= nil and _G.MMA_Loaded then
        IsMMALoaded = true
        print('MMA detected')
    elseif _G.AutoCarry then
        IsSACLoaded = true
        print('SAC detected')
    elseif FileExist(LIB_PATH .."SOW.lua") then
        require "SOW"
        SOWi = SOW(VP)
        IsSowLoaded = true
        SOWi:RegisterAfterAttackCallback(AutoAttackReset)
        print('SOW loaded')
    else
        print('Please use SAC, MMA, or SOW for your orbwalker')
    end
end

math.randomseed(os.time()+GetInGameTimer()+GetTickCount())
local AUTOUPDATE = true
local UPDATE_NAME = "Jayce"
local UPDATE_HOST = "raw.github.com"
local VERSION_PATH = "/Dienofail/BoL/master/versions/Jayce.version" .."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_FILE_PATH = string.gsub(UPDATE_FILE_PATH, "\\", "/")
local UPDATE_URL = "https://raw.github.com/Dienofail/BoL/master/JayceVIP.lua" .. "?rand=" .. math.random(1,100000)
function Download()
  DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () print("<font color=\"#FF0000\">Dieno JayceVIP Download Finished</font>") end)
end
if AUTOUPDATE then
    local ServerData = GetWebResult(UPDATE_HOST, VERSION_PATH)
    if ServerData then
        local ServerVersion = string.match(ServerData, "%d+.%d+")
        if ServerVersion then
            ServerVersion = tonumber(ServerVersion)
            if tonumber(version) < ServerVersion then
                print("<font color=\"#FF0000\">New version available "..ServerVersion .."</font>")
                print("<font color=\"#FF0000\">Updating, please don't press F9</font>")
                DelayAction(Download, 2)
                --DelayAction(function () print("Successfully updated. ("..version.." => "..ServerVersion..") press F9 twice to load the updated version after auth.") end, 3)
            else
                print("<font color=\"#FF0000\">You have got the latest version ("..ServerVersion..")</font>")
            end
        end
    else
        print("<font color=\"#FF0000\">Error downloading version info</font>")
    end
end

--Start Vadash Credit
class 'Kalman' -- {
function Kalman:__init()
        self.current_state_estimate = 0
        self.current_prob_estimate = 0
        self.Q = 1
        self.R = 15
end
function Kalman:STEP(control_vector, measurement_vector)
        local predicted_state_estimate = self.current_state_estimate + control_vector
        local predicted_prob_estimate = self.current_prob_estimate + self.Q
        local innovation = measurement_vector - predicted_state_estimate
        local innovation_covariance = predicted_prob_estimate + self.R
        local kalman_gain = predicted_prob_estimate / innovation_covariance
        self.current_state_estimate = predicted_state_estimate + kalman_gain * innovation
        self.current_prob_estimate = (1 - kalman_gain) * predicted_prob_estimate
        return self.current_state_estimate
end
--[[ Velocities ]]
local kalmanFilters = {}
local velocityTimers = {}
local oldPosx = {}
local oldPosz = {}
local oldTick = {}
local velocity = {}
local lastboost = {}
local velocity_TO = 10
local CONVERSATION_FACTOR = 975
local MS_MIN = 500
local MS_MEDIUM = 750
--End Vadash Credit

local SpellRangedQ1 = {Range = 1150, Speed = 1300, Delay = 0.1515, Width = 70}
local SpellRangedQ2 = {Range = 1750, Speed = 2350, Delay = 0.1515, Width = 70}
local SpellHammerQ = {Range = 600, Speed = math.huge, Delay = 0.250, Width = 0}
local SpellRangedW = {Range = math.huge, Speed = math.huge, Delay = 0.250, Width = 0}
local SpellHammerW = {Range = 350, Speed = math.huge, Delay = 0.264, Width = 0}
local SpellRangedE = {Range = 600, Speed = math.huge, Delay = 0.100, Width = 120}
local SpellHammerE = {Range = 240, Speed = math.huge, Delay = 0.250, Width = 80}
local RangedQReady, RangedWReady, RangedEReady = false, false, false
local HammerQReady, HammerWReady, HammerEready = false, false, false 
local isHammer = true 
local RangedTrueQcd = 8000
local HammerTrueQcd = {16000, 14000, 12000, 10000, 8000}
local RangedTrueWcd = {14000, 12000, 10000, 8000, 6000}
local HammerTrueWcd = 10000
local RangedTrueEcd = 16000
local HammerTrueEcd = {14000, 12000, 12000, 11000, 10000}
local RTruecd = 6000
local smoothness = 50
local RangedAllReady, RangedCombatReady = nil, nil
local HammerAllReady, HammerCombatReady = nil, nil
local HammerQcd, HammerWcd, HammerEcd = 0, 0, 0
local RangedQcd, RangedWcd, RangedEcd, Rcd = 0, 0, 0, 0
local initDone, target1, target2, target3 = false, nil, nil, nil
local lastAnimation = nil
local lastAttack = 0
local lastAttackCD = 0
local ignite
local lastWindUpTime = 0
local Target 
local eneplayeres = {}
local Config
local QReady, WReady, EReady, RReady = false, false, false, false
local GateObject = nil
local JayceWBuffed = false
local informationTable = {}
local animation_time = 0.9
local spellExpired = true
local IsSowLoaded = false
local ignite, igniteReady = nil, nil
VP = VPrediction()
local ToInterrupt = {
    { charName = "Caitlyn", spellName = "CaitlynAceintheHole"},
    { charName = "FiddleSticks", spellName = "Crowstorm"},
    { charName = "FiddleSticks", spellName = "DrainChannel"},
    { charName = "Galio", spellName = "GalioIdolOfDurand"},
    { charName = "Karthus", spellName = "FallenOne"},
    { charName = "Katarina", spellName = "KatarinaR"},
    { charName = "Lucian", spellName = "LucianR"},
    { charName = "Malzahar", spellName = "AlZaharNetherGrasp"},
    { charName = "MissFortune", spellName = "MissFortuneBulletTime"},
    { charName = "Nunu", spellName = "AbsoluteZero"},
    { charName = "Pantheon", spellName = "Pantheon_GrandSkyfall_Jump"},
    { charName = "Shen", spellName = "ShenStandUnited"},
    { charName = "Urgot", spellName = "UrgotSwap2"},
    { charName = "Varus", spellName = "VarusQ"},
    { charName = "Warwick", spellName = "InfiniteDuress"}
}

function Init()
    --print('Init called')
    --Start Vadash Credit
    for i = 1, heroManager.iCount do
            local hero = heroManager:GetHero(i)
            if hero.team ~= player.team then
                    table.insert(eneplayeres, hero)
                    kalmanFilters[hero.networkID] = Kalman()
                    velocityTimers[hero.networkID] = 0
                    oldPosx[hero.networkID] = 0
                    oldPosz[hero.networkID] = 0
                    oldTick[hero.networkID] = 0
                    velocity[hero.networkID] = 0
                    lastboost[hero.networkID] = 0
            end
    end
    --End Vadash Credit
    ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 650, DAMAGE_PHYSICAL)
    ts2 = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1750, DAMAGE_PHYSICAL)
    ts3 = TargetSelector(TARGET_LESS_CAST_PRIORITY, 600, DAMAGE_PHYSICAL)
    ts.name = "Ranged Main"
    ts2.name = "Ranged Q"
    ts3.name = "Hammer Main"
    Config:addTS(ts3)
    Config:addTS(ts2)
    Config:addTS(ts)
    EnemyMinions = minionManager(MINION_ENEMY, 1400, myHero, MINION_SORT_MAXHEALTH_DEC)
    JungleMinions = minionManager(MINION_JUNGLE, 1400, myHero, MINION_SORT_MAXHEALTH_DEC)
    initDone = true
    print('Dienofail VIP Jayce ' .. tostring(version) .. ' loaded!')
    -- if VIP_USER then
    --  AdvancedCallback:bind('OnGainBuff', function(unit, buff) OnGainBuff(unit, buff) end)
    --  AdvancedCallback:bind('OnLoseBuff', function(unit, buff) OnLoseBuff(unit, buff) end)
    -- end
end

function Menu()
    Config = scriptConfig("Jayce", "Jayce")
    Config:addParam("Combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
    Config:addParam("Harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('C'))
    Config:addParam("Farm", "Farm", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('V'))
    Config:addParam("CastQ", "Cast Q to mouse cursor", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('T'))
    Config:addParam("Escape", "Emergency Escape", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('X'))
    --Config:addParam("ManualQSplit", "QSplit", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('T'))
    Config:addSubMenu("Combo options", "ComboSub")
    Config:addSubMenu("Harass options", "HarassSub")
    Config:addSubMenu("Farm", "FarmSub")
    Config:addSubMenu("KS", "KS")
    Config:addSubMenu("Extra Config", "Extras")
    Config:addSubMenu("Draw", "Draw")
    --Combo options
    Config.ComboSub:addParam("useRangedQ", "Use Ranged Q", SCRIPT_PARAM_ONOFF, true)
    Config.ComboSub:addParam("useRangedW", "Use Ranged W", SCRIPT_PARAM_ONOFF, true)
    Config.ComboSub:addParam("useRangedE", "Use Ranged E", SCRIPT_PARAM_ONOFF, true)
    Config.ComboSub:addParam("useHammerQ", "Use Hammer Q", SCRIPT_PARAM_ONOFF, true)
    Config.ComboSub:addParam("useHammerW", "Use Hammer W", SCRIPT_PARAM_ONOFF, true)
    Config.ComboSub:addParam("useHammerE", "Use Hammer E", SCRIPT_PARAM_ONOFF, true)
    Config.ComboSub:addParam("useHammerEKnockback", "Only use Hammer E before Transform", SCRIPT_PARAM_ONOFF, false)
    Config.ComboSub:addParam("ConsumeW", "Consume W in range beforeswap", SCRIPT_PARAM_ONOFF, true)
    Config.ComboSub:addParam("MinEnemies", "Min enemies for always Hammer", SCRIPT_PARAM_SLICE, 3, 0, 5, 0)
    Config.ComboSub:addParam("MaxDistance", "Distance before Hammer Swap", SCRIPT_PARAM_SLICE, 500, 100, 600, 0)
    Config.ComboSub:addParam("useR", "Use R (auto transform)", SCRIPT_PARAM_ONOFF, true)
    Config.ComboSub:addParam("useWReset", "Use W as auto reset", SCRIPT_PARAM_ONOFF, true)
    Config.ComboSub:addParam("Orbwalk", "Orbwalk", SCRIPT_PARAM_ONOFF, false)
    --Farm
    Config.FarmSub:addParam("useQ", "Use Q both forms", SCRIPT_PARAM_ONOFF, true)
    Config.FarmSub:addParam("useW", "Use W both forms", SCRIPT_PARAM_ONOFF, true)
    Config.FarmSub:addParam("useR", "Use R (auto transform)", SCRIPT_PARAM_ONOFF, true)
    --Harass
    Config.HarassSub:addParam("Orbwalk", "Orbwalk", SCRIPT_PARAM_ONOFF, false)
    --KS
    Config.KS:addParam("useRangedQ", "Use Ranged Q", SCRIPT_PARAM_ONOFF, true)
    Config.KS:addParam("useHammerQ", "Use Hammer Q", SCRIPT_PARAM_ONOFF, true)
    Config.KS:addParam("useHammerE", "Use Hammer E", SCRIPT_PARAM_ONOFF, true)
    Config.KS:addParam("useR", "Swap form to KS", SCRIPT_PARAM_ONOFF, true)
    Config.KS:addParam("Ignite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)
    --Draw 
    Config.Draw:addParam("DrawQ", "Draw Ranged Q Normal Range", SCRIPT_PARAM_ONOFF, true)
    Config.Draw:addParam("DrawQ2", "Draw Ranged Q Boosted Range", SCRIPT_PARAM_ONOFF, true)
    Config.Draw:addParam("DrawQ3", "Draw Hammer Q Range", SCRIPT_PARAM_ONOFF, false)
    Config.Draw:addParam("DrawTarget", "Draw Ranged Q Target", SCRIPT_PARAM_ONOFF, true)
    Config.Draw:addParam("DrawTarget2", "Draw Orbwalker Target", SCRIPT_PARAM_ONOFF, true)
    Config.Draw:addParam("DrawCDCircles", "Draw CD Circles", SCRIPT_PARAM_ONOFF, false)
    Config.Draw:addParam("DrawCDText", "Draw CD Text", SCRIPT_PARAM_ONOFF, true)
    Config.Draw:addParam("DrawKSText", "Draw Hammer KS Text", SCRIPT_PARAM_ONOFF, true)
    --Extras
    Config.Extras:addParam("Debug", "Debug", SCRIPT_PARAM_ONOFF, false)
    Config.Extras:addParam("GateDistance", "Gate Distance", SCRIPT_PARAM_SLICE, 275, 50, 600, 0)
    Config.Extras:addParam("EGapClosers", "E Gapclosers(Hammer only)", SCRIPT_PARAM_ONOFF, false)
    Config.Extras:addParam("MinHitchance", "Minimum Hit Chance", SCRIPT_PARAM_SLICE, 1, 0, 5, 0)
    Config.Extras:addParam("mManager", "W and E mana slider", SCRIPT_PARAM_SLICE, 0, 0, 100, 0)
    Config.Extras:addParam("ForceE", "Force Gate before Q", SCRIPT_PARAM_ONOFF, false)
    Config.Extras:addParam("CheckAOE", "Check for AOE with ranged EQ", SCRIPT_PARAM_ONOFF, true)
    Config.Extras:addParam("SmartE", "Smart E for Melee E", SCRIPT_PARAM_ONOFF, true)
    Config.Extras:addParam("WallKnock", "(SmartE) Check for wall", SCRIPT_PARAM_ONOFF, true)
    Config.Extras:addParam("PushHealth", "(SmartE) E push min health", SCRIPT_PARAM_SLICE, 80, 0, 100, 0)
    Config.Extras:addParam("PushAlly", "(SmartE) E push to allies", SCRIPT_PARAM_ONOFF, true)
    Config.Extras:addParam("PushNum", "(SmartE) min allies for push",  SCRIPT_PARAM_SLICE, 2, 1, 5, 0)
    Config.Extras:addParam("ESpells", "Use E to interrupt", SCRIPT_PARAM_ONOFF, true)
    if ProdOneLoaded then
        Config.Extras:addParam("Prodiction", "Use Prodiction 1.1/1.0 instead of VPred", SCRIPT_PARAM_ONOFF, false)
    end
    --Permashow
    Config:permaShow("Combo")
    Config:permaShow("Farm")
    Config:permaShow("Harass")
    if IsSowLoaded then
        Config:addSubMenu("Orbwalker", "SOWiorb")
        SOWi:LoadToMenu(Config.SOWiorb)
    end
end

function checkOrbwalker()
    if _G.MMA_Loaded ~= nil and _G.MMA_Loaded then
        IsMMALoaded = true
        print('MMA detected')
    elseif _G.AutoCarry then
        IsSACLoaded = true
        print('SAC detected')
    elseif FileExist(LIB_PATH .."SOW.lua") then
        require "SOW"
        SOWi = SOW(VP)
        IsSowLoaded = true
        SOWi:RegisterAfterAttackCallback(AutoAttackReset)
        print('SOW loaded')
    else
        print('Please use SAC, MMA, or SOW for your orbwalker')
    end
end

--Credit Trees
function GetCustomTarget()
    ts:update()
    ts2:update()
    ts3:update()
    if _G.MMA_Target and _G.MMA_Target.type == myHero.type then return _G.MMA_Target end
    if _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then return _G.AutoCarry.Attack_Crosshair.target end
    if isHammer then
        return ts3.target
    else
        return ts.target
    end
end
--End Credit Trees

function OnLoad()
    DelayAction(checkOrbwalker,4)
    DelayAction(Menu,4.5)
    DelayAction(Init,4.5)
end

function WReset()
    if Config.ComboSub.useWReset then
        if _G.MMA_Target ~= nil and _G.MMA_AbleToMove and not _G.MMA_AttackAvailable and _G.MMA_NextAttackAvailability < 0.5 then
            return true
        elseif _G.AutoCarry and (_G.AutoCarry.shotFired or _G.AutoCarry.Orbwalker:IsAfterAttack()) then 
            if Config.Extras.Debug then
                print('SAC shot fired')
            end
            return true
        else
            return false
        end
    else
        return true
    end
end


function OnTick()
    if initDone then
        CheckSpellState()
        CheckStatesReady()
        CheckForm()
        UpdateSpeed()
        Checks()
        target = GetCustomTarget()
        Qtarget = ts2.target
        KillSteal()
        EnemyMinions:update()
        JungleMinions:update()
        if Config.CastQ then
            CastRangedQMouse()
        end
        if Config.Combo then
            if target ~= nil and ValidTarget(target) then
                if ValidTarget(target) and target ~= nil then
                    Combo(target)
                end
            end
            if Qtarget ~= nil and ValidTarget(Qtarget) and not Qtarget.dead then
                if GetDistance(Qtarget) > 600 and isHammer and HammerAllReady and RangedAllReady and Config.ComboSub.useR and Config.ComboSub.MinEnemies >= CountEnemyNearPerson(myHero, 750) then
                    CastR('Ranged')
                end
                if ValidTarget(Qtarget) and Config.ComboSub.useRangedQ and Qtarget ~= nil and ValidTarget(Qtarget, 1750) then
                    CastRangedQ(Qtarget)
                end
            else
                if isHammer and HammerAllReady and RangedAllReady and Config.ComboSub.useR and Config.ComboSub.MinEnemies >= CountEnemyNearPerson(myHero, 750) then
                    CastR('Ranged')
                end
            end

        end

        if Config.Harass then
            if Qtarget ~= nil and ValidTarget(Qtarget) then
                Harass(Qtarget)
            end
        end
        
        if Config.Farm then
            Farm()
        end

        if Config.Escape then
            Escape()
        end

        if Config.Extras.EGapClosers then
            EGapClosers()
        end
        -- if Config.Extras.EGapClosers then
        --     if not spellExpired and (GetTickCount() - informationTable.spellCastedTick) <= (informationTable.spellRange/informationTable.spellSpeed)*1000 then
        --         local spellDirection     = (informationTable.spellEndPos - informationTable.spellStartPos):normalized()
        --         local spellStartPosition = informationTable.spellStartPos + spellDirection
        --         local spellEndPosition   = informationTable.spellStartPos + spellDirection * informationTable.spellRange
        --         local heroPosition = Point(myHero.x, myHero.z)

        --         local lineSegment = LineSegment(Point(spellStartPosition.x, spellStartPosition.y), Point(spellEndPosition.x, spellEndPosition.y))
        --         --lineSegment:draw(ARGB(255, 0, 255, 0), 70)

        --         if lineSegment:distance(heroPosition) <= 200 and HammerEReady and isHammer then
        --          --print('Dodging dangerous spell with E')
        --             CastSpell(_E, spellSource)
        --         end
        --     else
        --         spellExpired = true
        --         informationTable = {}
        --     end
        -- end
    end
end

function EGapClosers()
    local Enemies = GetEnemyHeroes()
    for idx, val in ipairs(Enemies) do
        if isHammer and ValidTarget(val) and not val.dead and GetDistance(val) < 600 then
            local IsDashing, CanHit, Position = VP:IsDashing(val, 0.250, 10, math.huge, myHero)
            if IsDashing and CanHit and GetDistance(val) < SpellHammerE.Range and EReady then
                CastSpell(_E, val)
            end
        end
    end
end

function ShouldCastHammerE(Target)
    if not Config.Extras.SmartE and not CheckWBuffStatus() then
        return true
    elseif not Config.Extras.SmartE and CheckWBuffStatus() then
        return false
    else

        if CheckWBuffStatus() then 
            return false
        end

        if GetDistance(Target) < SpellHammerE.Range and EReady and isHammer then 
            if getDmg("EM", Target, myHero) > Target.health then
                return true
            end

            if RangedCombatReady then
                return true
            end


            if CheckWallStun(Target) then
                return true
            end


            if Config.Extras.PushAlly then
                if PushAllyCheck(Target) then
                    return true
                end
            end


            if GetTickCount() - HammerQcd > -500 then
                return true
            end

            if Target.health / Target.maxHealth > (Config.Extras.PushHealth)/100 then
                return false
            end

            local TimeToDisplacedPos = (300/myHero.ms)*1000 
            local TimeForAttack = lastWindUpTime + lastAttackCD
            local NumAttacks = math.floor(TimeToDisplacedPos/TimeForAttack)
            if Config.Extras.Debug then
                print(NumAttacks)
            end

            if getDmg("AD", Target, myHero)*NumAttacks >= getDmg("EM", Target, myHero) then
                return false
            end
        end
    end
end

function PushAllyCheck(Target)
    local Allies = GetAllyHeroes()
    local numallies = 0
    for idx, val in ipairs(Allies) do
        if val ~= nil and not val.dead and val.health/val.maxHealth > Target.health/Target.maxHealth then
            local PredictedPos, HitChance, Position = CombinedPos(Target, 0.250, math.huge, myHero, false)
            local PushedPos = Vector(Position) + Vector(Vector(Position) - Vector(myHero)):normalized()*300
            if GetDistance(PushedPos, val) < 600 then
                numallies = numallies + 1
            end
        end
    end

    if numallies >= Config.Extras.PushNum then
        return true
    else 
        return false
    end

end

function CheckWBuffStatus()
    if JayceWBuffed and Config.ComboSub.ConsumeW then 
        return true
    else
        return false
    end
end

function AutoAttackReset()
    if target ~= nil and ValidTarget(target) and GetDistance(target) < 500 + VP:GetHitBox(target) and not isHammer and WReady and not IsMyManaLow() and (Config.Combo or Config.Harass) and (Config.ComboSub.useRangedW or Config.HarassSub.useRangedW) then
        CastRangedW()
    end 
end

function CheckWallStun(Target)
    local function CheckWall(Position1, Position2)
        local EndInitalVector = Vector(Vector(Position2) - Vector(Position1)):normalized()
        local Mulitplier = 15
        local WallCount = 0 
        for i = 1, 50, 1 do
            local current_multiplier = 6 * i 
            local CurrentCheckVector = Vector(Position1) + EndInitalVector*current_multiplier
            if IsWall(D3DXVECTOR3(CurrentCheckVector.x, CurrentCheckVector.y, CurrentCheckVector.z)) then
              WallCount = WallCount + 1
            end
        end

        if WallCount >= 1 then
            return true
        else
            return false
        end
    end

    if Target ~= nil and ValidTarget(Target) and isHammer and EReady and GetDistance(Target) < SpellHammerE.Range and Config.Extras.WallKnock then 
        local PredictedPos, HitChance, Position = CombinedPos(Target, 0.250, math.huge, myHero, false)
        local PushedPos = Vector(Position) + Vector(Vector(Position) - Vector(myHero)):normalized()*300
        if Position ~= nil and PushedPos ~= nil and CheckWall(Position, PushedPos) then
            return true
        else
            return false
        end
    end 

    return false
end


function Combo(Target)
    if isHammer then

        if Config.ComboSub.useHammerE and HammerEReady then
            CastHammerE(Target)
        end

        if Config.ComboSub.useHammerQ then
            CastHammerQ(Target)
        end

        if Config.ComboSub.useHammerW then
            CastHammerW(Target)
        end

        if Config.ComboSub.useHammerE then
            if ShouldCastHammerE(Target) then
                CastHammerE(Target)
            elseif Config.ComboSub.useHammerEKnockback and RangedCombatReady then
                CastHammerE(Target)
            end
        end

        if Config.ComboSub.useR then
            if not HammerAllReady and RangedCombatReady and Config.ComboSub.MinEnemies >= CountEnemyNearPerson(myHero, 750) then
                CastR('Ranged')
            end
        end
    else
        if Config.ComboSub.useRangedQ then
            CastRangedQ(Target)
        end

        if Config.ComboSub.useRangedW and GetDistance(Target) < 600 and WReset() then
            CastRangedW()
        end

        if Config.ComboSub.useR then
            if not RangedAllReady and HammerAllReady and not CheckWBuffStatus() and GetDistance(Target) < Config.ComboSub.MaxDistance then
                CastR('Hammer')
            elseif CountEnemyNearPerson(myHero, 750) > Config.ComboSub.MinEnemies and not RangedAllReady and not CheckWBuffStatus() and GetDistance(Target) < Config.ComboSub.MaxDistance then
                CastR('Hammer')
            elseif not RangedCombatReady and HammerCombatReady and not CheckWBuffStatus and GetDistance(Target) < 300 then 
                CastR('Hammer')
            end
        end
    end
end

function Harass(Target)
    if isHammer then 
        CastR('Ranged')
    end
    if not isHammer and HaveLowVelocity(Target, 750) then
        CastRangedQ(Target)
    end
end

function Escape()
    if isHammer then
        if HammerEReady and EReady and target ~= nil then
            CastSpell(_E, target)
        else
            CastR('Ranged')
        end
    else
        CastSpell(_E, myHero.x, myHero.z)
    end
end

function OnGainBuff(unit, buff)
    if unit.isMe and buff.name == 'jaycehypercharge' then
        JayceWBuffed = true
    end
end

function OnLoseBuff(unit, buff)
    if unit.isMe and buff.name == 'jaycehypercharge' then
        JayceWBuffed = false
    end
end


function Farm()
    if Config.FarmSub.useQ then
        FarmQ()
    end

    if Config.FarmSub.useW then
        CastSpell(_W)
    end

    if Config.FarmSub.useR then
        if isHammer and not HammerCombatReady and RangedCombatReady then
            CastR('Ranged')
        elseif not isHammer and HammerCombatReady and not RangedCombatReady then
            CastR('Hammer')
        end

    end
end

function FarmQ()
    if QReady and #EnemyMinions.objects > 0 then
        local QPos = GetBestQPositionFarm()
        if QPos then
            if not isHammer then
                CastEQFarm(QPos)
            elseif GetDistance(QPos) < SpellHammerQ.Range then
                CastSpell(_Q, QPos.x, QPos.z)
            end
        end
    end
end

--Honda7
function GetBestQPositionFarm()
    local MaxQ = 0 
    local MaxQPos 
    if Config.Extras.Debug then
        print('GetBestQPositionFarm')
    end
    for i, minion in pairs(EnemyMinions.objects) do
        local hitQ = countminionshitQ(minion)
        if hitQ ~= nil and hitQ > MaxQ or MaxQPos == nil then
            MaxQPos = minion
            MaxQ = hitQ
        end
    end

    if MaxQPos then
        local CastPosition = MaxQPos
        return CastPosition
    else
        return nil
    end
end


function countminionshitQ(pos)
    local n = 0
    for i, minion in ipairs(EnemyMinions.objects) do
        if GetDistance(minion, pos) < SpellRangedQ1.Width then
            n = n +1
        end
    end
    return n
end

function CastEQFarm(pos)
    if not isHammer and RangedQReady then
        if Config.Extras.Debug then
            print('Generating Gate Vector')
        end
        local GateVector = Vector(myHero) + Vector(Vector(pos) - Vector(myHero)):normalized()*Config.Extras.GateDistance
        if Config.Extras.Debug then
            print(GateVector)
        end
        if EReady then
            CastSpell(_E, GateVector.x, GateVector.z)
        end
        CastSpell(_Q, pos.x, pos.z)
        
    end
end



function KillSteal()
    local Enemies = GetEnemyHeroes()
    for idx, champ in ipairs(Enemies) do
        if champ.health < getDmg("QM", champ, myHero) and Config.KS.useHammerQ and not champ.dead and ValidTarget(champ, 1500) then
            if isHammer and GetDistance(champ) < SpellHammerQ.Range then
                CastSpell(_Q, champ)
            elseif not isHammer and GetDistance(champ) < 600 and Config.KS.useR then
                CastR('Hammer')
            end
        end

        if champ.health < getDmg("EM", champ, myHero) and Config.KS.useHammerE and not champ.dead and ValidTarget(champ, 1500) then
            if isHammer and GetDistance(champ) < SpellHammerE.Range and Config.KS.useHammerE then
                CastSpell(_E, champ)
            elseif not isHammer and GetDistance(champ) < 400 and Config.KS.useR and Config.KS.useHammerE then
                CastR('Hammer')
            end
        end

        if champ.health < getDmg("Q", champ, myHero) and Config.KS.useRangedQ and not champ.dead and ValidTarget(champ, 1500) then
            if isHammer and GetDistance(champ) < SpellRangedQ1.Range-150 and Config.KS.useR then
                CastR('Ranged')
            elseif not isHammer and GetDistance(champ) < SpellRangedQ1.Range then
                CastRangedQ(champ)
            end
        end
    end

    if Config.KS.Ignite then
        IgniteKS()
    end
end


function IgniteKS()
    if igniteReady then
        local Enemies = GetEnemyHeroes()
        for idx,val in ipairs(Enemies) do
            if ValidTarget(val, 600) then
                if getDmg("IGNITE", val, myHero) > val.health and GetDistance(val) <= 600 then
                        CastSpell(ignite, val)
                end
            end
        end
    end
end


function CastRangedQ(Target)
    if VIP_USER and QReady and not isHammer and EReady and Target ~= nil and ValidTarget(Target) and myHero.mana > myHero:GetSpellData(_Q).mana + myHero:GetSpellData(_E).mana then
        local targetpos, hitchance, realpos = CombinedPredict(Target, SpellRangedQ2.Delay, SpellRangedQ2.Width, SpellRangedQ2.Range, SpellRangedQ2.Speed, myHero, true)
        if targetpos ~= nil and hitchance ~= nil and hitchance >= Config.Extras.MinHitchance then
            local GateVector = Vector(myHero) + Vector(Vector(targetpos) - Vector(myHero)):normalized()*Config.Extras.GateDistance
            --double check
            local additional_delay = GetDistance(GateVector)/SpellRangedQ1.Speed + SpellRangedQ1.Delay + 0.250
            local Final_Vector, Final_Hitchance, Final_Pos = CombinedPredict(Target, additional_delay, SpellRangedQ2.Width, SpellRangedQ2.Range, SpellRangedQ2.Speed, GateVector, true)
            if Final_Vector ~= nil and Final_Hitchance ~= nil and EReady and GetDistance(Final_Vector) < SpellRangedQ2.Range and Final_Hitchance >= Config.Extras.MinHitchance then
                local GateVector2 = Vector(myHero) + Vector(Vector(Final_Vector) - Vector(myHero)):normalized()*Config.Extras.GateDistance
                CastSpell(_E, GateVector2.x, GateVector2.z)
                local Speed = (GetDistance(GateVector2)/GetDistance(Target))*SpellRangedQ1.Speed + (GetDistance(GateVector2)/GetDistance(Target))*SpellRangedQ2.Speed
                local CastPosition, HitChance3, Position = CombinedPredict(Target, SpellRangedQ2.Delay, SpellRangedQ2.Width, SpellRangedQ2.Range, Speed, myHero, true)
                if CastPosition ~= nil and GetDistance(CastPosition) < SpellRangedQ2.Range + 150 then
                    CastSpell(_Q, CastPosition.x, CastPosition.z)
                    DelayAction(function() if QReady and GateObject ~= nil then CastSpell(_Q, CastPosition.x, CastPosition.z) end end, 0.1)
                end
            end
        end
    elseif not VIP_USER and QReady and not isHammer and (EReady or GateObject ~= nil) and Target ~= nil then
        local Predicted_Pos, a, b = tp2:GetPrediction(Target)
        if EReady and GetDistance(Predicted_Pos) < SpellRangedQ2.Range then
            local GateVector2 = Vector(myHero) + Vector(Vector(Predicted_Pos) - Vector(myHero)):normalized()*Config.Extras.GateDistance
            if not Config.Extras.ForceE then
                CastSpell(_Q, Predicted_Pos.x, Predicted_Pos.z)
            end
            CastSpell(_E, GateVector2.x, GateVector2.z)
        end
        if GateObject ~= nil and GetDistance(Predicted_Pos) < SpellRangedQ2.Range  then 
            CastSpell(_Q, Predicted_Pos.x, Predicted_Pos.z)
        end
    end
    if VIP_USER and QReady and not EReady and GateObject == nil and not isHammer then
        local predicted_pos, predicted_hitchance, predicted_loc = CombinedPredict(Target, SpellRangedQ1.Delay, SpellRangedQ1.Width, SpellRangedQ1.Range, SpellRangedQ1.Speed, myHero, true)
        if predicted_pos ~= nil and predicted_hitchance ~= nil and predicted_hitchance >= Config.Extras.MinHitchance and GetDistance(predicted_pos) < SpellRangedQ1.Range then
            CastSpell(_Q, predicted_pos.x, predicted_pos.z)
        end
    elseif not VIP_USER and QReady and not EReady and GateObject == nil and not isHammer then
        local Predicted_Pos, a, b = tp1:GetPrediction(Target)
        if GetDistance(Predicted_Pos) < SpellRangedQ1.Range then
            CastSpell(_Q, Predicted_Pos.x, Predicted_Pos.z)
        end
    end 

end

function CastRangedQMouse()
    -- if Config.Extras.Debug then
    --  print('Cast Ranged Q mouse called')
    -- end
    if isHammer and RangedQReady then
        CastR('Ranged')
        if Config.Extras.Debug then
            print('Cast Ranged Q mouse conversion called')
        end
    end

    if not isHammer and RangedQReady then
        if Config.Extras.Debug then
            print('Generating Gate Vector')
        end
        local GateVector = Vector(myHero) + Vector(Vector(mousePos) - Vector(myHero)):normalized()*Config.Extras.GateDistance
        if Config.Extras.Debug then
            print(GateVector)
        end
        CastSpell(_E, GateVector.x, GateVector.z)
        CastSpell(_Q, mousePos.x, mousePos.z)
        DelayAction(function() if QReady and GateObject ~= nil then CastSpell(_Q, mousePos.x, mousePos.z) end end, 0.1)
    end
end

function CastRangedW()
    if WReady and not isHammer and not IsMyManaLow() then
        CastSpell(_W)
    end
end

function CastHammerQ(Target)
    if QReady and isHammer and GetDistance(Target) < 600 and not IsMyManaLow() then
        CastSpell(_Q, Target)
    end
end

function CastHammerW(Target)
    if WReady and isHammer and GetDistance(Target) < 300 and not IsMyManaLow() then
        CastSpell(_W)
    end
end

function CastHammerE(Target)
    if EReady and isHammer and GetDistance(Target) < 250 and not IsMyManaLow()  then
        CastSpell(_E, Target)
    end
end

function round(num, idp)
    return string.format("%." .. (idp or 0) .. "f", num)
end


function OnDraw()
    if not initDone then return end
    if Config.Extras.Debug then
        DrawText3D("Current JayceWBuffed status is " .. tostring(JayceWBuffed), myHero.x+200, myHero.y, myHero.z+200, 25,  ARGB(255,255,0,0), true)
        DrawText('Hammer Q ready is ' .. tostring(HammerQReady) .. ' ' .. tostring(RangedQReady) .. ' ' .. tostring(HammerWReady) .. ' ' .. tostring(RangedWReady) .. ' ' .. tostring(HammerEReady) .. ' ' .. tostring(RangedEReady) .. ' RReady ' .. tostring(RReady), 15, 300, 300, ARGB(255,0,255,0))
        DrawText('RangedCombatReady ' .. tostring(RangedCombatReady) .. ' Hammer Combat Status ' .. tostring(HammerAllReady) .. ' ' .. tostring(CountEnemyNearPerson(myHero, 750)), 25, 200, 200, ARGB(255,0,255,0))
        -- DrawText(tostring(GetTickCount()), 25, 450, 450, ARGB(255,0,255,0))
        DrawText('HammerQcd ' .. tostring(HammerQcd) .. ' ' .. tostring(HammerWcd), 25, 350, 350, ARGB(255,0,255,0))
        DrawText('RangedQcd ' .. tostring(RangedQcd) .. ' ' .. tostring(RangedWcd), 25, 400, 400, ARGB(255,0,255,0))
        if GateObject ~= nil then
            DrawCircle3D(GateObject.x, GateObject.y, GateObject.z, 100, 1, ARGB(255, 0, 255, 255))
        end
    end

    if Config.Draw.DrawCDCircles then
        for i = 0, 30 do
            if isHammer then
                if RangedQReady then
                    DrawCircle(myHero.x, myHero.y, myHero.z, 100+i, ARGB(255,0,255,0) )
                else
                    DrawCircle(myHero.x, myHero.y, myHero.z, 100+i, ARGB(255,255,0,0) )
                end
            else
                if HammerQReady then
                    DrawCircle(myHero.x, myHero.y, myHero.z, 100+i, ARGB(255,0,255,0) )
                else
                    DrawCircle(myHero.x, myHero.y, myHero.z, 100+i, ARGB(255,255,0,0) )
                end
            end
        end
        for i = 31, 60 do
            if isHammer then
                if RangedWReady then
                    DrawCircle(myHero.x, myHero.y, myHero.z, 100+i, ARGB(255,0,255,0) )
                else
                    DrawCircle(myHero.x, myHero.y, myHero.z, 100+i, ARGB(255,255,0,0) )
                end
            else
                if HammerWReady then
                    DrawCircle(myHero.x, myHero.y, myHero.z, 100+i, ARGB(255,0,255,0) )
                else
                    DrawCircle(myHero.x, myHero.y, myHero.z, 100+i, ARGB(255,255,0,0) )
                end
            end
        end
        for i = 61, 90 do
            if isHammer then
                if RangedEReady then
                    DrawCircle(myHero.x, myHero.y, myHero.z, 100+i, ARGB(255,0,255,0) )
                else
                    DrawCircle(myHero.x, myHero.y, myHero.z, 100+i, ARGB(255,255,0,0) )
                end
            else
                if HammerEReady then
                    DrawCircle(myHero.x, myHero.y, myHero.z, 100+i, ARGB(255,0,255,0) )
                else
                    DrawCircle(myHero.x, myHero.y, myHero.z, 100+i, ARGB(255,255,0,0) )
                end
            end
        end
    end

    if Config.Draw.DrawCDText then
        local current_tick = GetTickCount()
        if isHammer then 
            if RangedQReady then
                DrawText3D('QReady', myHero.x-100, myHero.y, myHero.z, 15, ARGB(255,0,255,0), true)
            else
                local remaining_cd = (RangedQcd - current_tick)/1000
                DrawText3D(round(remaining_cd, 1), myHero.x-100, myHero.y, myHero.z, 15, ARGB(255,255,0,0), true)
            end
            if RangedWReady then
                DrawText3D('WReady', myHero.x, myHero.y, myHero.z, 15, ARGB(255,0,255,0), true)
            else
                local remaining_cd = (RangedWcd - current_tick)/1000
                DrawText3D(round(remaining_cd, 1), myHero.x, myHero.y, myHero.z, 15, ARGB(255,255,0,0), true)
            end
            if RangedEReady then
                DrawText3D('EReady', myHero.x+100, myHero.y, myHero.z, 15, ARGB(255,0,255,0), true)
            else
                local remaining_cd = (RangedEcd - current_tick)/1000
                DrawText3D(round(remaining_cd, 1), myHero.x+100, myHero.y, myHero.z, 15, ARGB(255,255,0,0), true)
            end
        else
            if HammerQReady then
                DrawText3D('QReady', myHero.x-100, myHero.y, myHero.z, 15, ARGB(255,0,255,0), true)
            else
                local remaining_cd = (HammerQcd - current_tick)/1000
                DrawText3D(round(remaining_cd, 1), myHero.x-100, myHero.y, myHero.z, 15, ARGB(255,255,0,0), true)
            end
            if HammerWReady then
                DrawText3D('WReady', myHero.x, myHero.y, myHero.z, 15, ARGB(255,0,255,0), true)
            else
                local remaining_cd = (HammerWcd - current_tick)/1000
                DrawText3D(round(remaining_cd, 1), myHero.x, myHero.y, myHero.z, 15, ARGB(255,255,0,0), true)
            end
            if HammerEReady then
                DrawText3D('EReady', myHero.x+100, myHero.y, myHero.z, 15, ARGB(255,0,255,0), true)
            else
                local remaining_cd = (HammerEcd - current_tick)/1000
                DrawText3D(round(remaining_cd, 1), myHero.x+100, myHero.y, myHero.z, 15, ARGB(255,255,0,0), true)
            end
        end

    end


    if Config.Draw.DrawKSText then
    local Enemies = GetEnemyHeroes()
        for idx, champ in ipairs(Enemies) do
            if champ.health < getDmg("QM", champ, myHero) + getDmg("EM", champ, myHero) and not champ.dead and ValidTarget(champ, 1500) then
                DrawText3D('Killable with Hammer Q+E', champ.x, champ.y, champ.z, 15,  ARGB(255,255,0,0), true)
            end
        end
    end

    if Config.Draw.DrawQ then
        DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellRangedQ1.Range, 1, ARGB(255, 0, 255, 255))
    end

    if Config.Draw.DrawQ2 then
        DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellRangedQ2.Range, 1, ARGB(255, 0, 255, 255))
    end

    if Config.Draw.DrawQ3 then
        DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellHammerQ.Range, 1, ARGB(255, 0, 255, 255))
    end

    if Config.DrawTarget and ValidTarget(target) then
        DrawCircle3D(target.x, target.y, target.z, 50, 1, ARGB(255, 255, 255, 255))
    end

    if Config.DrawTarget2 and ValidTarget(Qtarget) then
        DrawCircle3D(Qtarget.x, Qtarget.y, Qtarget.z, 50, 1, ARGB(255, 255, 255, 255))
    end

end

function OnCreateObj(obj)
    if not initDone then return end
    if obj.name == 'jayce_accel_gate_start.troy' and obj.team ~= TEAM_ENEMY and GetDistance(obj) < 700 then
        GateObject = obj
        -- if GateObject ~= nil and target ~= nil and ValidTarget(target) and Config.Combo and QReady and not isHammer and Config.ComboSub.useRangedQ then
        --     local Speed = (GetDistance(GateObject)/GetDistance(target))*SpellRangedQ1.Speed + (GetDistance(GateObject,target)/GetDistance(target))*SpellRangedQ2.Speed
        --     local CastPosition, HitChance, Position = CombinedPredict(target, SpellRangedQ2.Delay, SpellRangedQ2.Width, SpellRangedQ2.Range, Speed, myHero, true)
        --     if CastPosition ~= nil and GetDistance(CastPosition) < SpellRangedQ2.Range + 150 then
        --         CastSpell(_Q, CastPosition.x, CastPosition.z)
        --     end
        -- elseif Qtarget ~= nil and ValidTarget(Qtarget) and Config.Combo and QReady and not isHammer and Config.ComboSub.useRangedQ then
        --     local Speed = (GetDistance(GateObject)/GetDistance(Qtarget))*SpellRangedQ1.Speed + (GetDistance(GateObject,Qtarget)/GetDistance(target))*SpellRangedQ2.Speed
        --     local CastPosition, HitChance, Position = CombinedPredict(Qtarget, SpellRangedQ2.Delay, SpellRangedQ2.Width, SpellRangedQ2.Range, Speed, myHero, true)
        --     if CastPosition ~= nil and GetDistance(CastPosition) < SpellRangedQ2.Range + 150 then
        --         CastSpell(_Q, CastPosition.x, CastPosition.z)
        --     end
        -- elseif target ~= nil and ValidTarget(target) and Config.Harass and QReady and not isHammer and Config.HarassSub.useRangedQ then
        --     local Speed = (GetDistance(GateObject)/GetDistance(target))*SpellRangedQ1.Speed + (GetDistance(GateObject,target)/GetDistance(target))*SpellRangedQ2.Speed
        --     local CastPosition, HitChance, Position = CombinedPredict(target, SpellRangedQ2.Delay, SpellRangedQ2.Width, SpellRangedQ2.Range, Speed, myHero, true)
        --     if CastPosition ~= nil and GetDistance(CastPosition) < SpellRangedQ2.Range + 150 then
        --         CastSpell(_Q, CastPosition.x, CastPosition.z)
        --     end
        -- elseif Qtarget ~= nil and ValidTarget(Qtarget) and Config.Harass and QReady and not isHammer and Config.HarassSub.useRangedQ then
        --     local Speed = (GetDistance(GateObject)/GetDistance(Qtarget))*SpellRangedQ1.Speed + (GetDistance(GateObject,Qtarget)/GetDistance(target))*SpellRangedQ2.Speed
        --     local CastPosition, HitChance, Position = CombinedPredict(Qtarget, SpellRangedQ2.Delay, SpellRangedQ2.Width, SpellRangedQ2.Range, Speed, myHero, true)
        --     if CastPosition ~= nil and GetDistance(CastPosition) < SpellRangedQ2.Range + 150 then
        --         CastSpell(_Q, CastPosition.x, CastPosition.z)
        --     end
        -- end
    end
end



function OnDeleteObj(obj)
    if not initDone then return end
    if obj.name == 'jayce_accel_gate_start.troy' and obj.team ~= TEAM_ENEMY then
        GateObject = nil
    end
end

function CheckStatesReady()
    if myHero.level == 1 or myHero.level == 2 then
        if HammerQReady or HammerWReady or HammerEReady then
            HammerCombatReady = true
            HammerAllReady = true
        else
            HammerCombatReady = false
            HammerAllReady = false
        end

        if RangedQReady or RangedWReady or RangedEReady then
            RangedCombatReady = true
            RangedAllReady = true
        else
            RangedCombatReady = false
            RangedAllReady = false
        end
    else
        if HammerQReady and (HammerWReady or HammerEReady) then
            HammerCombatReady = true
        else
            HammerCombatReady = false
        end

        if HammerQReady and HammerWReady and HammerEReady then
            HammerAllReady = true
        else
            HammerAllReady = false
        end

        if RangedQReady and (RangedWReady or RangedEReady) then
            RangedCombatReady = true
        else
            RangedCombatReady = false
        end

        if RangedQReady and RangedWReady and RangedEReady then
            RangedAllReady = true
        else
            RangedAllReady = false
        end
    end
end

function CalculateRealCD(total_cd)
    current_cd = myHero.cdr
    real_cd = total_cd - total_cd * current_cd
    return real_cd
end

function Checks()
    QReady = (myHero:CanUseSpell(_Q) == READY)
    WReady = (myHero:CanUseSpell(_W) == READY)
    EReady = (myHero:CanUseSpell(_E) == READY)
    RReady = (myHero:CanUseSpell(_R) == READY)
    if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
            ignite = SUMMONER_1
    elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
            ignite = SUMMONER_2
    end
    igniteReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)

    if myHero.dead then
        JayceWBuffed = false
    end
end

function CastR(form)
    if RReady and form == 'Hammer' then
        if not isHammer then
            if WReady and target ~= nil and ValidTarget(target) and GetDistance(target) < 600 and not IsMyManaLow() then 
                CastSpell(_W)
                DelayAction(function() CastSpell(_R) end, 0.1)
                if Config.Extras.Debug then
                    print('Calling transform to ranged 1')
                end
            else
                CastSpell(_R)
                if Config.Extras.Debug then
                    print('Calling transform to ranged 2')
                end
            end
        end
    elseif RReady and form == 'Ranged' then 
        if isHammer then
            CastSpell(_R)
        end
    end
end


function OnProcessSpell(unit, spell)
    if not initDone then return end
    if unit == myHero then
        if spell.name:lower():find("attack") then
            lastAttack = GetTickCount() - GetLatency()/2
            lastWindUpTime = spell.windUpTime*1000
            lastAttackCD = spell.animationTime*1000
            animation_time = lastWindUpTime

        end
    end
    if #ToInterrupt > 0 then
        for _, ability in pairs(ToInterrupt) do
            if isHammer and spell.name == ability and unit.team ~= myHero.team and GetDistance(unit) < SpellHammerE.Range and EReady and Config.Extras.ESpells then
                CastSpell(_E, unit)
            end
        end
    end
    if isHammer then
        if unit.isMe and spell.name == 'JayceToTheSkies' then
            HammerQcd = GetTickCount() + CalculateRealCD(HammerTrueQcd[myHero:GetSpellData(_Q).level])
        end
        if unit.isMe and spell.name == 'JayceStaticField' then
            HammerWcd = GetTickCount() + CalculateRealCD(HammerTrueWcd)
            --print('Hammer W Cast')
        end
        if unit.isMe and spell.name =='JayceThunderingBlow' then
            HammerEcd = GetTickCount() + CalculateRealCD(HammerTrueEcd[myHero:GetSpellData(_E).level])
        end
        if unit.isMe and spell.name == 'Jayce StanceHTG' then
            Rcd = GetTickCount() + CalculateRealCD(RTruecd)
        end
    elseif not isHammer then
        if unit.isMe and spell.name =='jayceshockblast' then
            RangedQcd = GetTickCount() + CalculateRealCD(RangedTrueQcd)
        end
        if unit.isMe and spell.name == 'jaycehypercharge' then
            --print('Ranged W Cast')
            JayceWBuffed = true
            RangedWcd = GetTickCount() + CalculateRealCD(RangedTrueWcd[myHero:GetSpellData(_W).level])
            if IsSowLoaded then
                DelayAction(function() SOWi:resetAA() end, 0.25) 
            end
        end
        if unit.isMe and spell.name == 'jayceaccelerationgate' then
            RangedEcd = GetTickCount() + CalculateRealCD(RangedTrueEcd)
            --print(CalculateRealCD(RangedTrueEcd[myHero:GetSpellData(_E).level]))
        end
        if unit.isMe and spell.name == 'jaycestancegth' then
            Rcd = GetTickCount() + CalculateRealCD(RTruecd)
        end
    end

    --Mancusizz
    -- if Config.Extras.EGapClosers then
    --     local jarvanAddition = unit.charName == "JarvanIV" and unit:CanUseSpell(_Q) ~= READY and _R or _Q -- Did not want to break the table below.
    --     local isAGapcloserUnit = {
    -- --        ['Ahri']        = {true, spell = _R, range = 450,   projSpeed = 2200},
    --         ['Aatrox']      = {true, spell = _Q,                  range = 1000,  projSpeed = 1200, },
    --         ['Akali']       = {true, spell = _R,                  range = 800,   projSpeed = 2200, }, -- Targeted ability
    --         ['Alistar']     = {true, spell = _W,                  range = 650,   projSpeed = 2000, }, -- Targeted ability
    --         ['Diana']       = {true, spell = _R,                  range = 825,   projSpeed = 2000, }, -- Targeted ability
    --         ['Gragas']      = {true, spell = _E,                  range = 600,   projSpeed = 2000, },
    --         ['Hecarim']     = {true, spell = _R,                  range = 1000,  projSpeed = 1200, },
    --         ['Irelia']      = {true, spell = _Q,                  range = 650,   projSpeed = 2200, }, -- Targeted ability
    --         ['JarvanIV']    = {true, spell = jarvanAddition,      range = 770,   projSpeed = 2000, }, -- Skillshot/Targeted ability
    --         ['Jax']         = {true, spell = _Q,                  range = 700,   projSpeed = 2000, }, -- Targeted ability
    --         ['Jayce']       = {true, spell = 'JayceToTheSkies',   range = 600,   projSpeed = 2000, }, -- Targeted ability
    --         ['Khazix']      = {true, spell = _E,                  range = 900,   projSpeed = 2000, },
    --         ['Leblanc']     = {true, spell = _W,                  range = 600,   projSpeed = 2000, },
    --         ['LeeSin']      = {true, spell = 'blindmonkqtwo',     range = 1300,  projSpeed = 1800, },
    --         ['Leona']       = {true, spell = _E,                  range = 900,   projSpeed = 2000, },
    --         ['Malphite']    = {true, spell = _R,                  range = 1000,  projSpeed = 1500 + unit.ms},
    --         ['Maokai']      = {true, spell = _Q,                  range = 600,   projSpeed = 1200, }, -- Targeted ability
    --         ['MonkeyKing']  = {true, spell = _E,                  range = 650,   projSpeed = 2200, }, -- Targeted ability
    --         ['Pantheon']    = {true, spell = _W,                  range = 600,   projSpeed = 2000, }, -- Targeted ability
    --         ['Poppy']       = {true, spell = _E,                  range = 525,   projSpeed = 2000, }, -- Targeted ability
    --         --['Quinn']       = {true, spell = _E,                  range = 725,   projSpeed = 2000, }, -- Targeted ability
    --         ['Renekton']    = {true, spell = _E,                  range = 450,   projSpeed = 2000, },
    --         ['Sejuani']     = {true, spell = _Q,                  range = 650,   projSpeed = 2000, },
    --         ['Shen']        = {true, spell = _E,                  range = 575,   projSpeed = 2000, },
    --         ['Tristana']    = {true, spell = _W,                  range = 900,   projSpeed = 2000, },
    --         ['Tryndamere']  = {true, spell = 'Slash',             range = 650,   projSpeed = 1450, },
    --         ['XinZhao']     = {true, spell = _E,                  range = 650,   projSpeed = 2000, }, -- Targeted ability
    --     }
    --     if unit.type == 'obj_AI_Hero' and unit.team == TEAM_ENEMY and isAGapcloserUnit[unit.charName] and GetDistance(unit) < 2000 and spell ~= nil then
    --         if spell.name == (type(isAGapcloserUnit[unit.charName].spell) == 'number' and unit:GetSpellData(isAGapcloserUnit[unit.charName].spell).name or isAGapcloserUnit[unit.charName].spell) then
    --             if spell.target ~= nil and spell.target.name == myHero.name or isAGapcloserUnit[unit.charName].spell == 'blindmonkqtwo' then
    --              ----print('Gapcloser: ',unit.charName, ' Target: ', (spell.target ~= nil and spell.target.name or 'NONE'), " ", spell.name, " ", spell.projectileID)
    --              if isHammer and HammerEReady then
    --                  CastSpell(_E, unit)
    --                  print('Trying to dodge gapclosing spell ' .. tostring(spell.name) .. ' with E!')
    --              end
    --             else
    --                 spellExpired = false
    --                 informationTable = {
    --                     spellSource = unit,
    --                     spellCastedTick = GetTickCount(),
    --                     spellStartPos = Point(spell.startPos.x, spell.startPos.z),
    --                     spellEndPos = Point(spell.endPos.x, spell.endPos.z),
    --                     spellRange = isAGapcloserUnit[unit.charName].range,
    --                     spellSpeed = isAGapcloserUnit[unit.charName].projSpeed
    --                 }
    --             end
    --         end
    --     end
    -- end
end

function CheckSpellState()
    Current_Tick = GetTickCount()

    if Current_Tick - HammerQcd > 0 then 
        HammerQReady = true
    else
        HammerQReady = false
    end

    if Current_Tick - HammerWcd > 0 then 
        HammerWReady = true
    else
        HammerWReady = false
    end

    if Current_Tick - HammerEcd > 0 then 
        HammerEReady = true
    else
        HammerEReady = false
    end

    if Current_Tick - RangedQcd > 0 then 
        RangedQReady = true
    else
        RangedQReady = false
    end

    if Current_Tick - RangedWcd > 0 then 
        RangedWReady = true
    else
        RangedWReady = false
    end

    if Current_Tick - RangedEcd > 0 then 
        RangedEReady = true
    else
        RangedEReady = false
    end

    if Current_Tick - Rcd > 0 then 
        RReady = true
    else
        RReady = false
    end
end

function CheckForm()
    local SpellQ = myHero:GetSpellData(_Q)
    if SpellQ.name == 'jayceshockblast' then
        isHammer = false
    else
        isHammer = true
    end
end

--Start Manciuszz orbwalker credit
function TimeToAttack()
    return (GetTickCount() + GetLatency()/2 > lastAttack + lastAttackCD)
end
 
function heroCanMove()
        return (GetTickCount() + GetLatency()/2 > lastAttack + lastWindUpTime + 20)
end
 
function moveToCursor()
        if GetDistance(mousePos) then
                local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()*300
                myHero:MoveTo(moveToPos.x, moveToPos.z)
    end        
end
 
function OnAnimation(unit,animationName)
    if not initDone then return end
    if unit.isMe and lastAnimation ~= animationName then lastAnimation = animationName end
    if unit.isMe and animationName:lower():find("attack") and target ~= nil and ValidTarget(target) and GetDistance(target) < 500 + VP:GetHitBox(target) then
        if not isHammer and WReady and Config.Combo and Config.ComboSub.useRangedW then
            DelayAction(function() CastRangedW() end, animation_time + 0.05)
        end
    end
end
--End Manciuszz orbwalker credit 

--Start Vadash Credit
function HaveLowVelocity(target, time)
        if ValidTarget(target, 1500) then
                return (velocity[target.networkID] < MS_MIN and target.ms < MS_MIN and GetTickCount() - lastboost[target.networkID] > time)
        else
                return nil
        end
end

function HaveMediumVelocity(target, time)
        if ValidTarget(target, 1500) then
                return (velocity[target.networkID] < MS_MEDIUM and target.ms < MS_MEDIUM and GetTickCount() - lastboost[target.networkID] > time)
        else
                return nil
        end
end
 

function _calcHeroVelocity(target, oldPosx, oldPosz, oldTick)
        if oldPosx and oldPosz and target.x and target.z then
                local dis = math.sqrt((oldPosx - target.x) ^ 2 + (oldPosz - target.z) ^ 2)
                velocity[target.networkID] = kalmanFilters[target.networkID]:STEP(0, (dis / (GetTickCount() - oldTick)) * CONVERSATION_FACTOR)
        end
end
 
function UpdateSpeed()
        local tick = GetTickCount()
        for i=1, #eneplayeres do
                local hero = eneplayeres[i]
                if ValidTarget(hero) then
                        if velocityTimers[hero.networkID] <= tick and hero and hero.x and hero.z and (tick - oldTick[hero.networkID]) > (velocity_TO-1) then
                                velocityTimers[hero.networkID] = tick + velocity_TO
                                _calcHeroVelocity(hero, oldPosx[hero.networkID], oldPosz[hero.networkID], oldTick[hero.networkID])
                                oldPosx[hero.networkID] = hero.x
                                oldPosz[hero.networkID] = hero.z
                                oldTick[hero.networkID] = tick
                                if velocity[hero.networkID] > MS_MIN then
                                        lastboost[hero.networkID] = tick
                                end
                        end
                end
        end
end
--End Vadash Credit
--Credit Xetrok
function CountEnemyNearPerson(person,vrange)
    count = 0
    for i=1, heroManager.iCount do
        currentEnemy = heroManager:GetHero(i)
        if currentEnemy.team ~= myHero.team then
            if person:GetDistance(currentEnemy) <= vrange and not currentEnemy.dead then count = count + 1 end
        end
    end
    return count
end
--End Credit Xetrok

--Kain credit
function IsMyManaLow()
    if myHero.mana < (myHero.maxMana * ( Config.Extras.mManager / 100)) then
        return true
    else
        return false
    end
end

function CombinedPredict(Target, Delay, Width, Range, Speed, myHero, Collision)
  if Target == nil or Target.dead or not ValidTarget(Target) then return end
  if not ProdOneLoaded or not Config.Extras.Prodiction then
    local CastPosition, Hitchance, Position = VP:GetLineCastPosition(Target, Delay, Width, Range, Speed, myHero, true)
    if CastPosition ~= nil and Hitchance >= 1 then 
      return CastPosition, Hitchance+1, Position
    end
  elseif ProdOneLoaded and Config.Extras.Prodiction then
    CastPosition, info = Prodiction.GetPrediction(Target, Range, Speed, Delay, Width, myHero)
    local isCol = false
    if info ~= nil then
       isCol, _ = info.collision()
    end
    if info ~= nil and info.hitchance ~= nil and CastPosition ~= nil and isCol then
        return CastPosition, 0, CastPosition
    elseif info ~= nil and info.hitchance ~= nil and CastPosition ~= nil and not isCol then 
        Hitchance = info.hitchance
        return CastPosition, Hitchance, CastPosition
    end
  end
end


function CombinedPos(Target, Delay, Speed, myHero, Collision)
  if Target == nil or Target.dead or not ValidTarget(Target) then return end
  if Collision == nil then Collision = false end
    if not ProdOneLoaded or not Config.Extras.Prodiction then
      local PredictedPos, HitChance = VP:GetPredictedPos(Target, Delay, Speed, myHero, false)
      return PredictedPos, HitChance
    elseif ProdOneLoaded and Config.Extras.Prodiction then
      local PredictedPos, info = Prodiction.GetPrediction(Target, 20000, Speed, Delay, 1, myHero)
      local isCol = false
      if info ~= nil then
        isCol, _ = info.collision()
      end
      if PredictedPos ~= nil and info ~= nil and isCol then
        return PredictedPos, 0
      elseif PredictedPos ~= nil and info ~= nil and info.hitchance ~= nil and not isCol then
        return PredictedPos, info.hitchance
      end
    end
  end

