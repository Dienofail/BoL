local version = "0.07"
--[[

Anivia, The Bird is the Word

by Dienofail

Changelog:

v0.01 - release

v0.02 - small fixes to wall distance setting

v0.03 - Small fixes to a number of functions based on suggestions by gent

v0.04 - Small fixes to R usage. 

v0.05 - Rewrote R farm

v0.06 - Github

v0.07 - Fixes to chilled detection

]]

if myHero.charName ~= "Anivia" then return end
require 'VPrediction'

local AUTOUPDATE = true
local UPDATE_NAME = "Anivia"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/Dienofail/BoL/master/Anivia.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>"..UPDATE_NAME..":</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
if AUTOUPDATE then
	local ServerData = GetWebResult(UPDATE_HOST, UPDATE_PATH, "", 5)
	if ServerData then
		local ServerVersion = string.match(ServerData, "local version = \"%d+.%d+\"")
		ServerVersion = string.match(ServerVersion and ServerVersion or "", "%d+.%d+")
		if ServerVersion then
			ServerVersion = tonumber(ServerVersion)
			if tonumber(version) < ServerVersion then
				AutoupdaterMsg("New version available"..ServerVersion)
				AutoupdaterMsg("Updating, please don't press F9")
				DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () AutoupdaterMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end)	 
			else
				AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
			end
		end
	else
		AutoupdaterMsg("Error downloading version info")
	end
end

local VP = VPrediction()
local SpellQ = {Speed = 850, Range = 1100, Delay = 0.250, Width = 110}
local SpellW = {Speed = math.huge, Range = 1000, Delay = 0.250}
local WWidth = {400, 500, 600, 700, 800}
local SpellE = {Speed = 1200, Range = 650, Delay = 0.250, Width = 0}
local SpellR = {Speed = math.huge, Range = 625, Delay = 0.250, Width = 400}
local QReady, WReady, EReady, RReady = nil, nil, nil, nil
local QObject = nil 
local RObject = nil 
local target = nil
local target2 = nil
local initDone = false
local EnemyMinions, JungleMinions = nil, nil
local ignite, igniteReady = nil, false
local chilled = {}
local lastAnimation = nil
local lastAttack = 0
local lastAttackCD = 0
local ignite
local lastWindUpTime = 0
local Endpoint1, Endpoint2, Diffunitvector = nil, nil, nil 
local CurrentWall = nil
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
local eneplayeres = {}
local MS_MEDIUM = 750
--End Vadash Credit
--Start Toy
local ToInterrupt = {}
local InterruptList = {
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
--End Toy
function Menu()
	Config = scriptConfig("Anivia", "Anivia")
	Config:addParam("Combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("Harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('C'))
	Config:addParam("Farm", "Farm", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('V'))
	Config:addParam("CastWall", "Cast Wall + Q + R Combo", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('T'))
	--Config:addParam("ManualQSplit", "QSplit", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('T'))
	Config:addSubMenu("Combo options", "ComboSub")
	Config:addSubMenu("Harass options", "HarassSub")
	Config:addSubMenu("Farm", "FarmSub")
	Config:addSubMenu("KS", "KS")
	Config:addSubMenu("Extra Config", "Extras")
	Config:addSubMenu("Draw", "Draw")
	--Combo
	Config.ComboSub:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("Orbwalk", "Orbwalk", SCRIPT_PARAM_ONOFF, false)
	--Harass
	Config.HarassSub:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.HarassSub:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
	Config.HarassSub:addParam("Orbwalk", "Orbwalk", SCRIPT_PARAM_ONOFF, false)
	--Farm
	Config.FarmSub:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.FarmSub:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, true)
	--Draw 
	Config.Draw:addParam("DrawQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawW", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawE", "Draw E Range", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawR", "Draw R Range", SCRIPT_PARAM_ONOFF, false)
	Config.Draw:addParam("Chilled", "Draw Chilled", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawTarget", "Draw Target", SCRIPT_PARAM_ONOFF, true)
	--KS
	Config.KS:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.KS:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
	Config.KS:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, true)
	Config.KS:addParam("useIgnite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)
	--Extras
	Config.Extras:addParam("Debug", "Debug", SCRIPT_PARAM_ONOFF, false)
	Config.Extras:addParam("DetonateQ", "Auto Detonate Q", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("WallGapclosers", "Wall Dashes", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("mManager", "Mana slider", SCRIPT_PARAM_SLICE, 0, 0, 100, 0)
	Config.Extras:addParam("WallR", "Wall Enemies to stay in ult", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("WallDistance", "Wall Distance", SCRIPT_PARAM_SLICE, 100, 0, 300, 0)
	Config.Extras:addParam("WallSpells", "Wall Channelling Spells", SCRIPT_PARAM_ONOFF, true)
	--Permashow
	Config:permaShow("Combo")
	Config:permaShow("Farm")
	Config:permaShow("Harass")
	Config:permaShow("CastWall")
end

function OnLoad()
	Menu()
	Init()
end

function Init()
	--Start Vadash Credit
    for i = 1, heroManager.iCount do
        local hero = heroManager:GetHero(i)
        if hero.team ~= myHero.team then
            table.insert(eneplayeres, hero)
            kalmanFilters[hero.networkID] = Kalman()
            velocityTimers[hero.networkID] = 0
            oldPosx[hero.networkID] = 0
            oldPosz[hero.networkID] = 0
            oldTick[hero.networkID] = 0
            velocity[hero.networkID] = 0
            lastboost[hero.networkID] = 0
            chilled[hero.networkID] = 0
        end

        for _, champ in pairs(InterruptList) do
        	if hero.charName == champ.charName then
        		table.insert(ToInterrupt, champ.spellName)
        	end
        end
    end
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 675, DAMAGE_MAGICAL)
	ts2 = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1100, DAMAGE_MAGICAL)
	ts.name = "Ranged Main"
	ts2.name = "Ranged Distant"
	Config:addTS(ts2)
	Config:addTS(ts)
	EnemyMinions = minionManager(MINION_ENEMY, 1200, myHero, MINION_SORT_MAXHEALTH_DEC)
	JungleMinions = minionManager(MINION_JUNGLE, 1200, myHero, MINION_SORT_MAXHEALTH_DEC)
    print('Dienofail Anivia ' .. tostring(version) .. ' loaded!')
    --End Vadash Credit
    initDone = true
end

--Credit Trees
function GetCustomTarget()
    if _G.MMA_Target and _G.MMA_Target.type == myHero.type then return _G.MMA_Target end
    if _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then return _G.AutoCarry.Attack_Crosshair.target end
    return ts.target
end
--End Credit Trees

function OnTick()
	UpdateSpeed()
	Check()
	if initDone then
		KillSteal()
		ts:update()
		ts2:update()
		target = ts.target
		Qtarget = ts2.target
		EnemyMinions:update()
		JungleMinions:update()
		--print(target.charName)
		-- if Qtarget ~= nil and Config.Extras.Debug then
		-- 	print(Qtarget.charName)
		-- end

		if Qtarget == nil then
			Endpoint1, Endpoint2, Diffunitvector = nil, nil, nil
		end
		if Qtarget ~= nil then
			DetonateQ(Qtarget)
		end
		if Config.Combo then
			if ValidTarget(target, 1200) and not target.dead then
				Combo(target)
			end

			if ValidTarget(Qtarget,1200) and not Qtarget.dead then
				CastQ(Qtarget)
			else
				moveToCursor()
			end
			StopR()
		end

		if Config.Harass and Qtarget ~= nil and ValidTarget(Qtarget, 1300) then
			if target ~= nil and ValidTarget(target, 1300) then
				Harass(target)
			end
			CastQ(Qtarget)
		elseif Config.Harass and Config.HarassSub.Orbwalk then
			moveToCursor()
		end

		if Config.Farm then
			Farm()
		end

		if Config.CastWall and Qtarget ~= nil and ValidTarget(Qtarget, 1500) and not Qtarget.dead then
			CastWallQ(Qtarget)
			StopR()
		end

		if Config.Extras.WallGapclosers then
			CheckDashes()
		end

		if Config.Extras.WallR and Qtarget ~= nil and ValidTarget(Qtarget, 1100) and not Qtarget.dead then
			CheckRWall(Qtarget)
		end
	end
end


function Combo(Target)

	-- if Config.Extras.Debug then
	-- 	print('Combo called')
	-- end

	if QReady then 
		CastQ(Target)
	end

	if EReady then
		CastE(Target)
	end

	if RReady then
		CastR(Target)
	end

	if Config.ComboSub.Orbwalk then
		OrbWalking(Target)
	end
end

function Harass(Target)
	if Target ~= nil and ValidTarget(Target, 1300)  then
		if QReady and HaveLowVelocity(Target, 750) and Config.HarassSub.useQ then 
			CastQ(Target)
		end

		if EReady and Config.HarassSub.useE then
			CastE(Target)
		end

		if Config.HarassSub.Orbwalk then
			OrbWalking(Target)
		end
	end
end

function KillSteal()
	local Enemies = GetEnemyHeroes()
	for i, enemy in pairs(Enemies) do
		if ValidTarget(enemy, 1100) and not enemy.dead and GetDistance(enemy) < 1100 then
			if getDmg("Q", enemy, myHero) > enemy.health and GetDistance(enemy) < SpellQ.Range and QObject == nil and Config.KS.useQ then
				CastQ(enemy)
			end

			if QObject ~= nil and GetDistance(QObject, enemy) < SpellQ.Width + VP:GetHitBox(enemy) and getDmg("Q", enemy, myHero) > enemy.health  then
				CastSpell(_Q)
			end

			if getDmg("E", enemy, myHero) > enemy.health and GetDistance(enemy) < SpellE.Range and Config.KS.useW then
				CastSpell(_E, enemy)
			end

			-- if getDmg("R", enemy, myHero) > enemy.health and GetDistance(enemy) < SpellR.Range and Config.KS.useR then
			-- 	CastR(enemy)
			-- end
		end
	end
	IgniteKS()
end

function CastWallQ(Target)
	if (WReady or CurrentWall) and QReady then
		GetWallCollision(Target)
	end

	if EReady then
		CastSpell(_E)
	end

	if RReady then
		CastR(Target)
		StopR()
	end

	if QObject ~= nil then
		DetonateQ(Target)
	end

end

function CastQ(Target)
	if QReady and QObject == nil and not IsMyManaLow() then
		local CastPosition, HitChance, Position =  VP:GetLineCastPosition(Target, SpellQ.Delay, SpellQ.Width, SpellQ.Range, SpellQ.Speed, myHero, false)
		if HitChance >= 2 then
			CastSpell(_Q, CastPosition.x, CastPosition.z)
		end
	end
end

function CastW(position)
	if WReady and not IsMyManaLow() then
		CastSpell(_W, position.x, position.z)
	end
end

function CastE(Target)
	if GetDistance(Target) < SpellE.Range and not IsMyManaLow() and TargetHaveBuff("chilled", Target) then
		CastSpell(_E, Target)
	end
end

function CastR(Target)
	if RReady and RObject == nil and not IsMyManaLow() then
		if CountEnemyNearPerson(Target, 750) > 0 then
			local CastPosition, HitChance, Position = VP:GetCircularAOECastPosition(Target, SpellR.Delay, SpellR.Width, SpellR.Range, SpellR.Speed, myHero)
			if HitChance >= 1 then
				CastSpell(_R, CastPosition.x, CastPosition.z)
			end
		else
			if GetDistance(Target) < SpellR.Range then
				CastSpell(_R, Target.x, Target.z)
			end
		end
	end
end

function DetonateQ(Target)
	if QObject ~= nil and GetDistance(QObject) < 1500 then
		if GetDistance(QObject, Target) < SpellQ.Width + VP:GetHitBox(Target) then
			CastSpell(_Q)
		end
	end
end

function Farm()
	if Config.FarmSub.useQ then
		FarmQ()
	end
	if Config.FarmSub.useR then
		FarmR()
	end
end

function FarmQ()
	if QReady and #EnemyMinions.objects > 0 and QObject == nil then
		local QPos = GetBestQPositionFarm()
		if QPos then
			CastSpell(_Q, QPos.x, QPos.z)
		end
	elseif QObject ~= nil and QReady then
		if GetCurrentHitQ(QObject) >= 2 then
			CastSpell(_Q)
		end
	end
end

function FarmR()
	if RReady and #EnemyMinions.objects > 0 and RObject == nil then
		local RPos = GetBestRPositionFarm()
		if RPos then
			CastSpell(_R, RPos.x, RPos.z)
		end
	end

	StopRFarm()

end

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


function GetBestRPositionFarm()
	local MaxR = 0 
	local MaxRPos 
	for i, minion in pairs(EnemyMinions.objects) do
		local hitR = countminionshitR(minion)
		if hitR > MaxR or MaxRPos == nil then
			MaxRPos = minion
			MaxR = hitR
		end
	end

	if MaxRPos then
		return MaxRPos
	else
		return nil
	end
end

function countminionshitQ(pos)
	local n = 0
	local ExtendedVector = Vector(myHero) + Vector(Vector(pos) - Vector(myHero)):normalized()*SpellQ.Range
	local EndPoint = Vector(myHero) + ExtendedVector
	for i, minion in ipairs(EnemyMinions.objects) do
		local MinionPointSegment, MinionPointLine, MinionIsOnSegment =  VectorPointProjectionOnLineSegment(Vector(myHero), Vector(EndPoint), Vector(minion)) 
		local MinionPointSegment3D = {x=MinionPointSegment.x, y=pos.y, z=MinionPointSegment.y}
		if MinionIsOnSegment and GetDistance(MinionPointSegment3D, pos) < SpellQ.Width then
			n = n +1
			-- if Config.Extras.Debug then
			-- 	print('count minions W returend ' .. tostring(n))
			-- end
		end
	end
	return n
end

function countminionshitR(pos)
	local n = 0
	for i, minion in ipairs(EnemyMinions.objects) do
		if GetDistance(minion, pos) < 400 then
			n = n +1
		end
	end
	return n
end

function GetCurrentHitR(position)
	local counter = 0
	for i, minion in pairs(EnemyMinions.objects) do
		if GetDistance(minion, position) < 400 then
			counter = counter + 1
		end
	end
	return counter
end

function GetCurrentHitQ(position)
	local counter = 0
	for i, minion in pairs(EnemyMinions.objects) do
		if GetDistance(minion, position) < SpellQ.Width then
			counter = counter + 1
		end
	end
	return counter
end

function StopR()
	if RObject ~= nil then
		local Enemies = GetEnemyHeroes()
		local counter = 0
		for i, enemy in pairs(Enemies) do
			if ValidTarget(enemy, 1500) and not enemy.dead and enemy ~= nil then
				local PredictedPos, HitChance = VP:GetPredictedPos(enemy, 0.725, math.huge, myHero, false)
				if (GetDistance(PredictedPos, RObject) < 400 + VP:GetHitBox(enemy) or GetDistance(enemy, RObject) < 400 + VP:GetHitBox(enemy)) then 
					counter = counter + 1
				end
			end
		end

		if counter == 0 or IsMyManaLow() then
			CastSpell(_R)
		end
	end
end


function StopRFarm()
	if RObject ~= nil then
		local RHitCounter = 0
		for i, minion in pairs(EnemyMinions.objects) do
			if GetDistance(minion, RObject) < 425 then
				RHitCounter = RHitCounter + 1
			end
		end
		if RHitCounter == 0 or IsMyManaLow() then
			CastSpell(_R)
		end
	end
end


function CheckDashes()
	local Enemies = GetEnemyHeroes()
	local counter = 0
	for i, enemy in pairs(Enemies) do
		if ValidTarget(enemy, 1500) and not enemy.dead then
			local TargetDashing, CanHit, Position = VP:IsDashing(enemy, 0.250, 100, math.huge, myHero)
			if TargetDashing and CanHit and GetDistance(Position) < GetDistance(enemy) and WReady and GetDistance(Position) < SpellW.Range then
				CastSpell(_W, Position.x, Position.z)
			end 
		end
	end
end

function GenerateWallVector(pos)
	local Wlevel = myHero:GetSpellData(_Q).level
	local WallDisplacement = WWidth[Wlevel]/2
	local HeroToWallVector = Vector(Vector(pos) - Vector(myHero)):normalized()
	local RotatedVec1 = HeroToWallVector:perpendicular()
	local RotatedVec2 = HeroToWallVector:perpendicular2()
	local EndPoint1 = Vector(pos) + Vector(RotatedVec1)*WallDisplacement
	local EndPoint2 = Vector(pos) + Vector(RotatedVec2)*WallDisplacement
	local DiffVector = Vector(EndPoint2 - EndPoint1):normalized()
	return EndPoint1, EndPoint2, DiffVector
end

function GetWallCollision(Target)
	local TargetDestination, HitChance = VP:GetPredictedPos(Target, 0.500, math.huge, myHero, false)
	local TargetDestination2, HitChance2 = VP:GetPredictedPos(Target, 0.250, math.huge, myHero, false)
	local TargetWaypoints = VP:GetCurrentWayPoints(Target)
	local Destination1 = TargetWaypoints[#TargetWaypoints]
	local Destination2 = TargetWaypoints[1]
	local Destination13D = {x=Destination1.x, y=myHero.y, z=Destination1.y}
	if TargetDestination ~= nil and HitChance >= 2 and HitChance2 >= 2 and GetDistance(Destination1, Destination2) > 100 then 
		if GetDistance(TargetDestination, Target) > 5 then
			local UnitVector = Vector(Vector(TargetDestination) - Vector(Target)):normalized()
			Endpoint1, Endpoint2, Diffunitvector = GenerateWallVector(Destination13D)
			local DisplacedVector = Vector(Target) + Vector(Vector(Destination13D) - Vector(Target)):normalized()*((Target.ms)*0.25 + Config.Extras.WallDistance)
			local angle = UnitVector:angle(Diffunitvector)
			if angle ~= nil then
				--print('Angle Generated!' .. tostring(angle*57.2957795))
				if angle*57.2957795 < 105 and angle*57.2957795 > 75 and GetDistance(DisplacedVector, myHero) < SpellW.Range and (WReady or CurrentWall) and QReady and QObject == nil then
					CastSpell(_W, DisplacedVector.x, DisplacedVector.z)
					local QTravelTime = GetDistance(myHero, DisplacedVector)/SpellQ.Speed 
					local WallTime = GetDistance(Target, DisplacedVector)/Target.ms + 0.080
					local DiffTime = QTravelTime - WallTime
					if DiffTime >= 0 then
						local QPosition = Vector(DisplacedVector) + Diffunitvector*(DiffTime*Target.ms*0.60)
						CastSpell(_Q, QPosition.x, QPosition.z)
					else
						CastSpell(_Q, DisplacedVector.x, DisplacedVector.z)
					end
				end
			end
		end
	end
end

function CheckRWall(Target)
	local TargetDestination, HitChance = VP:GetPredictedPos(Target, 0.500, math.huge, myHero, false)
	local TargetDestination2, HitChance2 = VP:GetPredictedPos(Target, 0.250, math.huge, myHero, false)
	local TargetWaypoints = VP:GetCurrentWayPoints(Target)
	local Destination1 = TargetWaypoints[#TargetWaypoints]
	local Destination2 = TargetWaypoints[1]
	local Destination13D = {x=Destination1.x, y=myHero.y, z=Destination1.y}
	if RObject ~= nil and GetDistance(Target, RObject) < 300 and GetDistance(Destination13D) > 450 and HitChance >= 2 and HitChance2 >= 2 then
		local UnitVector = Vector(Vector(TargetDestination) - Vector(Target)):normalized()
		Endpoint1, Endpoint2, Diffunitvector = GenerateWallVector(Destination13D)
		local DisplacedVector = Vector(Target) + Vector(Vector(Destination13D) - Vector(Target)):normalized()*((Target.ms)*0.25 + Config.Extras.WallDistance)
		local angle = UnitVector:angle(Diffunitvector)
		if angle ~= nil then
			--print('Angle Generated!' .. tostring(angle*57.2957795))
			if angle*57.2957795 < 100 and angle*57.2957795 > 80 and GetDistance(DisplacedVector, myHero) < SpellW.Range and (WReady or CurrentWall) then
				CastSpell(_W, DisplacedVector.x, DisplacedVector.z)
			end
		end
	end
end

function OnProcessSpell(unit, spell)
	if #ToInterrupt > 0 and Config.Extras.WallSpells and WReady then
		for _, ability in pairs(ToInterrupt) do
			if spell.name == ability and unit.team ~= myHero.team and GetDistance(unit) < SpellW.Range then
				CastSpell(_W, unit.x, unit.z)
			end
		end
	end
    if unit == myHero then
        if spell.name:lower():find("attack") then
            lastAttack = GetTickCount() - GetLatency()/2
            lastWindUpTime = spell.windUpTime*1000
            lastAttackCD = spell.animationTime*1000
        end
    end
end


function OnDraw()
	if Config.Extras.Debug and RObject ~= nil then
		DrawCircle3D(RObject.x, RObject.y, RObject.z, 400, 1, ARGB(255, 0, 255, 255))
	end
	-- if Config.Extras.Debug and QObject ~= nil then
	-- 	DrawCircle3D(QObject.x, QObject.y, QObject.z, SpellQ.Width, 1, ARGB(255, 0, 255, 255))
	-- end
	if Config.Draw.Chilled then
		local Enemies = GetEnemyHeroes()
		for i, enemy in pairs(Enemies) do
			if ValidTarget(enemy, 1500) then
				if chilled[enemy.networkID] > 0 and chilled[enemy.networkID] > GetTickCount() then
					DrawText3D("Chilled", enemy.x, enemy.y, enemy.z, 15,  ARGB(255,0,255,0), true)
					DrawCircle3D(enemy.x, enemy.y, enemy.z, VP:GetHitBox(enemy), 1, ARGB(255, 0, 0, 255))
				end
			end
		end
	end
	if Config.Draw.DrawTarget then
		if target ~= nil then
			DrawCircle3D(target.x, target.y, target.z, VP:GetHitBox(target), 1, ARGB(255, 255, 0, 0))
		elseif Qtarget ~= nil then
			DrawCircle3D(Qtarget.x, Qtarget.y, Qtarget.z, VP:GetHitBox(Qtarget), 1, ARGB(255, 255, 0, 0))
		end
	end

	if Config.Draw.DrawQ then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellQ.Range, 1,  ARGB(255, 0, 255, 255))
		if QObject ~= nil then
			DrawCircle3D(QObject.x, QObject.y, QObject.z, SpellQ.Width, 1, ARGB(255, 0, 255, 255))
		end
	end

	if Config.Draw.DrawW then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellW.Range, 1,  ARGB(255, 0, 255, 255))
		if Endpoint1 ~= nil and Endpoint2 ~= nil and Diffunitvector ~= nil then
			DrawLine3D(Endpoint1.x, Endpoint1.y, Endpoint1.z, Endpoint2.x, Endpoint2.y, Endpoint2.z, 1, ARGB(255, 255, 0, 0))
		end
	end

	if Config.Draw.DrawE then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellE.Range, 1,  ARGB(255, 0, 255, 255))
	end

	if Config.Draw.DrawR then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellR.Range, 1,  ARGB(255, 0, 255, 255))
	end

	-- if Config.Extras.Debug then
	-- 	local Enemies = GetEnemyHeroes()
	-- 	for i, enemy in pairs(Enemies) do
	-- 		if enemy ~= nil and not enemy.dead then
	-- 			local TargetWaypoints = VP:GetCurrentWayPoints(enemy)
	-- 			if #TargetWaypoints > 0 then
	-- 				for _, waypoint in pairs(TargetWaypoints) do
	-- 					DrawCircle3D(waypoint.x, myHero.y, waypoint.y, 50, 1,  ARGB(255, 0, 255, 255))
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- end
end


function Check()
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
end

function OnCreateObj(obj)
	if obj.name:find("FlashFrost_mis") then
		QObject = obj
	end
	if obj.name:find("cryo_storm") then
		RObject = obj
	end
	if obj.name:find("IceBlock") then
		CurrentWall = obj
	end
end


function OnDeleteObj(obj)
	if obj.name:find("FlashFrost_mis") then
		QObject = nil
	end
	if obj.name:find("cryo_storm") then
		RObject = nil
	end
	if obj.name:find("IceBlock") then
		CurrentWall = nil
	end
end

function OnGainBuff(unit, buff)
	if buff.name == 'chilled' and unit.team ~= myHero.team then
		chilled[unit.networkID] = GetTickCount() + buff.endT
		--print(buff.endT)
	end

	--print(buff.name)

end

function OnUpdateBuff(unit, buff)
	if buff.name == 'chilled'  then
		chilled[unit.networkID] = GetTickCount() + buff.endT
		--print('buffed updated')
	end
end

function OnLoseBuff(unit, buff)
	if buff.name == 'chilled'  and unit.team ~= myHero.team then
		chilled[unit.networkID] = 0
		--print('buffed lost')
	end
end


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
--Start Manciuszz orbwalker credit
function OrbWalking(target)
        if TimeToAttack() and GetDistance(target) <= 565 then
                myHero:Attack(target)
    elseif heroCanMove() then
        moveToCursor()
    end
end
 
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
 
function OnProcessSpell(object, spell)
    if object == myHero then
            if spell.name:lower():find("attack") then
                lastAttack = GetTickCount() - GetLatency()/2
                lastWindUpTime = spell.windUpTime*1000
                lastAttackCD = spell.animationTime*1000
        end
    end
end

 
function OnAnimation(unit,animationName)
    if unit.isMe and lastAnimation ~= animationName then lastAnimation = animationName end
end
--End Manciuszz orbwalker credit 
--Kain
function IsMyManaLow()
    if myHero.mana < (myHero.maxMana * ( Config.Extras.mManager / 100)) then
        return true
    else
        return false
    end
end

--Credit Xetrok
function CountEnemyNearPerson(person,vrange)
    count = 0
    for i=1, heroManager.iCount do
        currentEnemy = heroManager:GetHero(i)
        if currentEnemy.team ~= myHero.team and currentEnemy.networkID ~= person.networkID then
            if person:GetDistance(currentEnemy) <= vrange and not currentEnemy.dead then count = count + 1 end
        end
    end
    return count
end
--End Credit Xetrok

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
