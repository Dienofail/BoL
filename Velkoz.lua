local version = "1.15"
--[[

Velkoz, The Geometry Nightmare
by Dienofail


Changelog 

v0.01 - release

v0.02 - Hotfixes to W and etc. Turned autoupdate on. 

v0.03 - more hotfixes

v0.04 - Q fixes

v0.05 - Few more fixes

v0.06 - Battlecast skin particles added. If it doesn't work, revert back to normal skin. 

v0.07 - Added Harass Options

v0.08 - Added R packet block option (will block R packets while R is casting), lowered W max range, and made fixes for W farm. Split Q farm added. Added max distance slider for Q splits

v1.00 - Added additional hit chance slider for initial Q split casts (will not affect normal non-collision casts). Added Double Q code checks. Added Mancusizz orbwalker and ignite KS. Should be usable standalone now.

v1.01 - E delay fixes. Should now cast more often and feel more responsive

v1.02 - updated with correct Q split speeds

v1.03 - Draw R kill text and kalman filter implemented, added AOE skill shot position for VPrediction v2.34

v1.04 - Fixed ignite KS. 

v1.05 - Added better R killtext. Added drawing Q split calculations to Q draw (red -> not detonating, blue -> detonating). Added secondary Q split algorithm. Added Q split target locking

v1.06 - Fixed debug info

v1.07 - Fixed critical error in Q angle collision calculations. Also lowered debug font. 

v1.08 - Added some buffer distance to Q projectile, should now detonate more often and faster. Let me know what you think of accuracy vs 1.07.

v1.09 - Some minor fixes to split Q calculations.

v1.10 - Small bug fixes to farm calculations

v1.11 - Added E dashes

v1.12 - Fixed E and Q range

v1.13 - Added option to disable autoattacks. Added toggle mode. 

v1.14 - Fixed compatibility with VPred 2.404

Todo:


]]--

--Start Honda7 credit
if myHero.charName ~= "Velkoz" then return end
require 'VPrediction'

local autoupdateenabled = true
local UPDATE_SCRIPT_NAME = "Velkoz"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/Dienofail/BoL/master/Velkoz.lua"
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

local ServerData
if autoupdateenabled then
	GetAsyncWebResult(UPDATE_HOST, UPDATE_PATH, function(d) ServerData = d end)
	function update()
		if ServerData ~= nil then
			local ServerVersion
			local send, tmp, sstart = nil, string.find(ServerData, "local version = \"")
			if sstart then
				send, tmp = string.find(ServerData, "\"", sstart+1)
			end
			if send then
				ServerVersion = tonumber(string.sub(ServerData, sstart+1, send-1))
			end

			if ServerVersion ~= nil and tonumber(ServerVersion) ~= nil and tonumber(ServerVersion) > tonumber(version) then
				DownloadFile(UPDATE_URL.."?nocache"..myHero.charName..os.clock(), UPDATE_FILE_PATH, function () print("<font color=\"#FF0000\"><b>"..UPDATE_SCRIPT_NAME..":</b> successfully updated. Reload (double F9) Please. ("..version.." => "..ServerVersion..")</font>") end)     
			elseif ServerVersion then
				print("<font color=\"#FF0000\"><b>"..UPDATE_SCRIPT_NAME..":</b> You have got the latest version: <u><b>"..ServerVersion.."</b></u></font>")
			end		
			ServerData = nil
		end
	end
	AddTickCallback(update)
end
--End Honda7 credit
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



local VP = VPrediction()
local OriginalCastVector1 = nil
local OriginalCastVector2 = nil
local RotatedUnitVector1 = nil
local RotatedUnitVector2 = nil
local RotatedVector1 = nil
local RotatedVector2 = nil
local QObject = nil
local QEndObject = nil
local ToRotateVector = nil
local isPressedR = false
local BlockQ = false
local ignite = nil
local igniteReady = nil
local QAdditionalDistance = 435
local SpellQ = {Range = 1050, Speed = 1300, Delay = 0.066, Width = 50}
local SpellW = {Range = 1050, Speed = 1700, Delay = 0.064, Width = 65}
local SpellE = {Range = 850, Speed = 1500, Delay = 0.333, Width = 120}
local SpellR = {Range = 1500, Speed = 20000, Delay = 0.250, Width = 50}
local QSplitSpeed = 2100
local InitialTarget = nil
local LastPacketSend = 0
local LastPacketBlock = false
initDone = false
local buffer = false
target = nil
local DoubleCast = false
local StoredPosition = nil
local QStartPos = nil
local DeflectedPosition = nil
local pointLine, pointSegment = nil, nil
local current_distance = nil
local EndPos1, EndPos2 = nil, nil
local SplitQPosition, SplitQHitChance = nil, nil
local pointSegment2, pointLine2, isOnSegment2 = nil, nil, nil
local pointSegment3, pointLine3, isOnSegment3 = nil, nil, nil
local AngleTable = nil
local VectorTable = nil
local VectorTable2 = nil
local CheckPoint = nil
local DoubleQTarget = nil
local lastAnimation = nil
local lastAttack = 0
local lastAttackCD = 0
local ignite
local lastWindUpTime = 0
local eneplayeres = {}
local lastdistance = nil
local LastUnitVector1 = nil
local LastUnitVector2 = nil
local LastDetonateTime = nil
local detonate1 = false
local Qlocktarget = nil
local detonate2 = false
-- if VIP_USER then 
-- 	AdvancedCallback:bind('OnSendPacket', function(packet) OnSendPacket(packet) end)
--     AdvancedCallback:bind('OnLoseBuff', function(unit, buff) OnLoseBuff(unit, buff) end)
--     AdvancedCallback:bind('OnCreateObj', function(unit, buff) OnCreateObj(unit, buff) end)
--     AdvancedCallback:bind('OnDeleteObj', function(unit, buff) OnDeleteObj(unit, buff) end)
-- end

function OnLoad()



    Menu()
    Init()
 --   	ts = TargetSelector(TARGET_NEAR_MOUSE, 1500, DAMAGE_MAGICAL)
	-- ts.name = "Vel'Koz"
	-- Config:addTS(ts)
	-- EnemyMinions = minionManager(MINION_ENEMY, 1200, myHero, MINION_SORT_MAXHEALTH_DEC)
	-- JungleMinions = minionManager(MINION_JUNGLE, 1200, myHero, MINION_SORT_MAXHEALTH_DEC)
	if VP.version < 2.404 then
		print('You need latest version of VPREDICTION (2.404 or above) for this script to function')
	end
end

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
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1200, DAMAGE_MAGICAL)
	ts2 = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1600, DAMAGE_MAGICAL)
	ts3 = TargetSelector(TARGET_NEAR_MOUSE, 1500, DAMAGE_MAGICAL)
	ts.name = "Vel'Koz main"
	ts2.name = "Q SPLITTING"
	ts3.name = "R TARGETTING"
	Config:addTS(ts3)
	Config:addTS(ts2)
	Config:addTS(ts)
	EnemyMinions = minionManager(MINION_ENEMY, 1200, myHero, MINION_SORT_MAXHEALTH_DEC)
	JungleMinions = minionManager(MINION_JUNGLE, 1200, myHero, MINION_SORT_MAXHEALTH_DEC)
	initDone = true
	print('Dienofail Velkoz ' .. tostring(version) .. ' loaded!')
end

function OnWndMsg(msg,key)
	if key == string.byte("Q") and msg == KEY_DOWN and QObject ~= nil and QObject then
		-- mark Q key is release
		if Config.Extras.Debug then
			print('Q key override enabled')
		end 
		Cast2ndQPacket(myHero)
	end
end

function Menu()
	Config = scriptConfig("Velkoz", "velkoz")
	Config:addParam("Combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('C'))
	Config:addParam("Harass", "Harass (PRESS)", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('T'))
	Config:addParam("Harass2", "Harass (TOGGLE)", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte('Y'))
	Config:addParam("Farm", "Farm", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('V'))
	--Config:addParam("ManualQSplit", "QSplit", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('T'))
	Config:addParam("TrackR", "Track R ON/OFF", SCRIPT_PARAM_ONOFF, true)
	Config:addSubMenu("Combo options", "ComboSub")
	Config:addSubMenu("Harass options", "HarassSub")
	Config:addSubMenu("Farm", "FarmSub")
	Config:addSubMenu("Extra Config", "Extras")
	Config:addSubMenu("Draw", "Draw")
	--Combo options
	Config.ComboSub:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("Orbwalk", "Orbwalk", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("Autoattack", "Autoattack in Orbwalk", SCRIPT_PARAM_ONOFF, true)
	--Farm
	Config.FarmSub:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.FarmSub:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	Config.FarmSub:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
	--Harass
	Config.HarassSub:addParam("UseWHarass", "Use W", SCRIPT_PARAM_ONOFF, true)
	Config.HarassSub:addParam("Orbwalk", "Orbwalk", SCRIPT_PARAM_ONOFF, true)
	Config.HarassSub:addParam("Autoattack", "Autoattack in Orbwalk", SCRIPT_PARAM_ONOFF, true)
	--Draw 
	Config.Draw:addParam("DrawQ", "Draw Q Prediction", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawQ2", "Draw Q Angle Prediction", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawW", "Draw W Range", SCRIPT_PARAM_ONOFF, false)
	Config.Draw:addParam("DrawE", "Draw E Range", SCRIPT_PARAM_ONOFF, false)
	Config.Draw:addParam("DrawR", "Draw R Range", SCRIPT_PARAM_ONOFF, false)
	Config.Draw:addParam("DrawTarget", "Draw Target Range", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawRDamage", "Draw R Damage Counter", SCRIPT_PARAM_ONOFF, true)
	--Extras
	Config.Extras:addParam("Debug", "Debug", SCRIPT_PARAM_ONOFF, false)
	Config.Extras:addParam("DetonateQ", "Auto Detonate Q", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("SplitQ", "Calculate Q splitting", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("SplitQMode", "Check Min Q First", SCRIPT_PARAM_ONOFF, false)
	Config.Extras:addParam("SplitQDistance", "Split Q Extra Distance", SCRIPT_PARAM_SLICE, 700, 100, 900, 0)
	Config.Extras:addParam("SplitQMinimumDistance", "Split Q Minimum Distance", SCRIPT_PARAM_SLICE, 250, 200, 900, 0)
	Config.Extras:addParam("SplitQMaximumDistance", "Split Q Maximum Distance To Check", SCRIPT_PARAM_SLICE, 1000, 500, 1100, 0)
	Config.Extras:addParam("SplitQDelay", "Split Q Delay (miliseconds)",  SCRIPT_PARAM_SLICE, 66, 50, 350, 0)
	Config.Extras:addParam("CheckAngle", "Attempt to Check Angles", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("CheckAngleOnly", "Only use Check Angles Prediction", SCRIPT_PARAM_ONOFF, false)
	Config.Extras:addParam("MaxAngle", "Max Angle for Q Check",  SCRIPT_PARAM_SLICE, 30, 1, 90, 0)
	Config.Extras:addParam("AngleIncrement", "Increment Angle Degree",  SCRIPT_PARAM_SLICE, 5, 1, 90, 0)
	Config.Extras:addParam("DoubleQ", "Attempt multiple target Q checks (WILL LAG)", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("DoubleQDistance", "Multiple Q check distance interval", SCRIPT_PARAM_SLICE, 50, 1, 300, 0) 
	Config.Extras:addParam("FocusRTarget", "Focus Initial R Target", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("MinHitchance", "Minimum Hit Chance", SCRIPT_PARAM_SLICE, 1, 0, 5, 0)
	Config.Extras:addParam("MinSplitQHitchance", "Minimum Initial Split Q Hit Chance", SCRIPT_PARAM_SLICE, 2, 0, 5, 0)
	Config.Extras:addParam("RDelay", "R Delay", SCRIPT_PARAM_SLICE, 100, 0, 500, 0)
	Config.Extras:addParam("BlockR", "Block packets during R cast", SCRIPT_PARAM_ONOFF, false)
	Config.Extras:addParam("EGapClosers", "E Gap Closers", SCRIPT_PARAM_ONOFF, true)
	Config:permaShow("Combo")
	Config:permaShow("Farm")
	Config:permaShow("Harass")
	Config:permaShow("Harass2")
end


function OnTick()
	--print(initDone)
	UpdateSpeed()
	UpdateVector()
	Check()
	CurrentTick = GetTickCount()
	--Cast2ndR()
	if initDone then
		ts:update()
		ts2:update()
		ts3:update()
		EnemyMinions:update()
		JungleMinions:update()
		target = ts.target
		if not target then target = nil end
		target2 = ts2.target
		target3 = ts3.target
		if not target2 then 
			target2 = nil 
			Best_Position = nil
			DoubleQTarget = nil
			Qlocktarget = nil
			--BlockQ = false
		end
		


		if Config.Extras.DoubleQ and QObject ~= nil and Config.Extras.DetonateQ and target2 ~= nil and DoubleQTarget ~= nil then
			SplitQ(target2)
			SplitQ(DoubleQTarget)
		elseif Qlocktarget ~= nil and QObject ~= nil and Config.Extras.DetonateQ then
			SplitQ(Qlocktarget)
		elseif target ~= nil and QObject ~= nil and Config.Extras.DetonateQ then
			SplitQ(target)
		elseif target2 ~= nil and Config.Extras.DetonateQ and QObject ~= nil then
			SplitQ(target2)
		else 
			LastDetonateTime = nil
			LastUnitVector1 = nil
			LastUnitVector2 = nil
			detonate2 = false
			detonate1 = false
			EndPos1 = nil
			EndPos2 = nil
		end

		if target2 ~= nil and Config.Extras.SplitQ and Config.Extras.CheckAngle and Config.Extras.DrawQ2 and not BlockQ then
			DeflectedPosition = CalculateDeflectedCastPosition(target2)
		end
		-- if Config.Extras.Debug and target ~= nil then
		-- 	print(target.charName)
		-- end
		-- ContinueR(mousePos)

		if Config.Combo then
			if ValidTarget(target) then
				Combo(target)
			elseif ValidTarget(target2) then
				CastQ(target2)
			end
		end

		if (Config.Harass or Config.Harass2) and ValidTarget(target) then
			if ValidTarget(target) then
				Harass(target)
			elseif ValidTarget(target2) then
				CastQHarass(target2)
			end
		end

		if Config.Farm then
			Farm()
		end

	    if Config.Combo and Config.ComboSub.Orbwalk and Config.ComboSub.Autoattack then
            if target and ValidTarget(target) and GetDistance(target) < 560 then
                OrbWalking(target)
            else
                moveToCursor()
            end
        end
        if Config.Harass and Config.HarassSub.Orbwalk then
            if target and ValidTarget(target) and GetDistance(target) < 560 and Config.HarassSub.Autoattack then
                OrbWalking(target)
            else
                moveToCursor()
            end
        end
		if Config.Extras.EGapClosers then
			CheckDashes()
		end
	end
	 IgniteKS()
end

function OnProcessSpell(unit, spell)
	if unit.isMe and spell.name == 'VelkozQ' then
		BlockQ = true
		--LastPacketBlock = false
	end
	-- if unit.isMe and spell.name == 'velkozqsplitactive' then
	-- 	BlockQ = false
	-- end
	-- if unit.isMe and spell.name == 'VelkozR' then
	-- 	isPressedR = true
	-- end
    if unit.isMe then
        if spell.name:lower():find("attack") then
            lastAttack = GetTickCount() - GetLatency()/2
            lastWindUpTime = spell.windUpTime*1000
            lastAttackCD = spell.animationTime*1000
        end
    end
end

function Combo(Target)
	if Target ~= nil and ValidTarget(Target, 1500) then
		if EReady and Config.ComboSub.useE then
			CastE(Target)
		elseif WReady and Config.ComboSub.useW then
			CastW(Target)
		elseif QReady and Config.ComboSub.useQ then
			CastQ(Target) 
		-- elseif RReady and Config.ComboSub.useR then
		-- 	--CastRCombo(Target)
		-- end
		end
	end
end

function Harass(Target)
	if Target ~= nil and ValidTarget(Target, 1500) then
		if WReady and Config.HarassSub.UseWHarass then
			CastW(Target)
		elseif QReady then
			CastQHarass(Target) 
		-- elseif RReady and Config.ComboSub.useR then
		-- 	--CastRCombo(Target)
		-- end
		end
	end
end

function Farm()
	if Config.FarmSub.useQ then
		FarmQ()
	end
	if Config.FarmSub.useW then
		FarmW()
	end
	if Config.FarmSub.useE then
		FarmE()
	end

end

function CastQ(Target)
	if not Config.Extras.SplitQ and not BlockQ and HaveMediumVelocity(Target, 600) then
		local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, SpellQ.Delay, SpellQ.Width, SpellQ.Range, SpellQ.Speed, myHero, true)
		if CastPosition ~= nil and HitChance ~= nil and GetDistance(CastPosition, myHero) < SpellQ.Range and HitChance >= Config.Extras.MinHitchance and QReady then
			CastSpell(_Q, CastPosition.x, CastPosition.z)
		end
	elseif not BlockQ and HaveMediumVelocity(Target, 600) then
		local Best_Position = CalculateBestInitialCastPosition(Target)
		if Best_Position ~= nil then
			CastSpell(_Q, Best_Position.x, Best_Position.z)
			Qlocktarget = Target
		end
	end
end

function CastQHarass(Target)
	if not Config.Extras.SplitQ and not BlockQ and HaveLowVelocity(Target, 750) then
		local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, SpellQ.Delay, SpellQ.Width, SpellQ.Range, SpellQ.Speed, myHero, true)
		if CastPosition ~= nil and HitChance ~= nil and GetDistance(CastPosition, myHero) < SpellQ.Range and HitChance >= Config.Extras.MinHitchance and QReady then
			CastSpell(_Q, CastPosition.x, CastPosition.z)
		end
	elseif not BlockQ and HaveLowVelocity(Target, 750) then
		local Best_Position = CalculateBestInitialCastPosition(Target)
		if Best_Position ~= nil then
			CastSpell(_Q, Best_Position.x, Best_Position.z)
		end
	end

end

function CastW(Target)
	local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, SpellW.Delay, SpellW.Width, SpellW.Range, SpellW.Speed, myHero, false)
	if CastPosition ~= nil and HitChance ~= nil and GetDistance(CastPosition, myHero) < SpellW.Range and HitChance >= Config.Extras.MinHitchance and WReady then
		CastSpell(_W, CastPosition.x, CastPosition.z)
	end
end

function CastE(Target)
	local CastPosition, HitChance, Position = VP:GetCircularAOECastPosition(Target, SpellE.Delay, SpellE.Width, SpellE.Range, SpellE.Speed, myHero)
	if CastPosition ~= nil and HitChance ~= nil and GetDistance(CastPosition, myHero) < SpellE.Range and HitChance >= Config.Extras.MinHitchance and EReady then
		CastSpell(_E, CastPosition.x, CastPosition.z)
	end
end

function CastRCombo(Target)
	local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, 1, SpellR.Width, SpellR.Range, SpellR.Speed, myHero, false)
	if HitChance ~= nil and CastPosition ~= nil and ValidTarget(Target) and GetDistance(Target, myHero) < 1500 and not isPressedR and HitChance > 1 then
		Cast1stR(Target)
		InitialTarget = Target
	end
	-- elseif isPressedR then
	-- 	if Target ~= InitialTarget and GetDistance(InitialTarget, myHero) < 1500 and Config.Extras.FocusRTarget then
	-- 		Cast2ndR(InitialTarget)
	-- 	elseif GetDistance(Target, myHero) < 1500 then
	-- 		Cast2ndR(Target)
	-- 	else
	-- 		Cast2ndR(mousePos)
	-- 	end
	-- end
end

function ContinueR(Target)
	-- if Config.Extras.Debug then
	-- 	print('Continuing R')
	-- end 
	--Cast2ndR()
	-- if ValidTarget(Target) and ValidTarget(InitialTarget) and Target ~= InitialTarget and GetDistance(InitialTarget, myHero) < 1500 and Config.Extras.FocusRTarget then
	-- 	Cast2ndR(InitialTarget)
	-- 	if Config.Extras.Debug then
	-- 		print('Continuing R initial target')
	-- 	end 
	-- elseif GetDistance(Target, myHero) < 1500 thenm
	-- 	Cast2ndR(Target)
	-- 	if Config.Extras.Debug then
	-- 		print('Continuing R 2nd target')
	-- 	end 
	-- else
	-- 	Cast2ndR(mousePos)
	-- 	if Config.Extras.Debug then
	-- 		print('Continuing R mouse pos')
	-- 	end 
	-- end
end


function UpdateVector()
	if QObject ~= nil and QEndObject ~= nil then
		-- if Config.Extras.Debug then
		-- 	print('Update Vector called!')
		-- end 
		OriginalCastVector1 = (Vector(QEndObject) - QStartPos):normalized()
		-- if Config.Extras.Debug then
		-- 	print(OriginalCastVector1)
		-- end 
		current_distance = GetDistance(QObject, QEndObject)
		OriginalCastVector2 = Vector(QObject) + OriginalCastVector1*(current_distance+50)
		RotatedUnitVector1 = OriginalCastVector1:perpendicular()
		RotatedUnitVector2 = OriginalCastVector1:perpendicular2()
		RotatedVector1 = Vector(QObject) + RotatedUnitVector1 * Config.Extras.SplitQDistance 
		RotatedVector2 = Vector(QObject) + RotatedUnitVector2 * Config.Extras.SplitQDistance
	end
end

--Credit Honda7
function DrawLine(From, To, Color)
	DrawLine3D(From.x, From.y, From.z, To.x, To.y, To.z, 1, Color)
end

function Cast1stR(Target)
	if GetDistance(Target, myHero) < SpellR.Range and not isPressedR and buffer == false then 
		CastSpell(_R, Target.x, Target.z)
		buffer = true
		DelayAction(function() buffer = false end, 0.5)
		if Config.Extras.Debug then
			print('Cast1stRCalled')
		end 
	end
end





function CalculateDeflectedCastPosition(Target)
	local tempdelay = GetDistance(Target)/SpellQ.Speed
	local PredictedPos3, PredictedHitChance3 = VP:GetPredictedPos(Target, 0.300+tempdelay, math.huge, myHero, false)
	if PredictedPos3 ~= nil and PredictedHitChance3 ~= nil then
		local pointSegment1, pointLine1, isOnSegment1 = VectorPointProjectionOnLineSegment(Vector(Target), Vector(PredictedPos3), Vector(myHero))
		if Config.Extras.Debug then
			--print(pointSegment1)
			--print(pointLine)
			--print(isOnSegment)
			--print(GetDistance(pointLine))
		end 
		local myHeroPoint = { x = myHero.x, y = myHero.z}
		local newpointSegment1 = {x = pointSegment1.x, y = myHero.y, z = pointSegment1.y}
		local newpointLine1 = {x = pointLine1.x, y= myHero.y, z = pointLine1.y}
		local predictedpoint = {x = PredictedPos3.x, y = PredictedPos3.z}
		local refactored_newpointline = Vector(myHero) + Vector(Vector(newpointLine1) - Vector(myHero)):normalized()*SpellQ.Range
		local collision1 = VP:CheckMinionCollision(myHero, newpointLine1, (GetDistance(myHero, newpointSegment1)/SpellQ.Speed) + SpellQ.Delay, SpellQ.Width, GetDistance(myHero, newpointSegment1), SpellQ.Speed, myHero, false)
		local collision2 = VP:CheckMinionCollision(myHero, newpointSegment1, (GetDistance(PredictedPos3, newpointSegment1)/QSplitSpeed) + SpellQ.Delay + (GetDistance(myHero, newpointSegment1)/SpellQ.Speed), SpellQ.Width, GetDistance(PredictedPos3, newpointSegment1), QSplitSpeed, newpointSegment1, false)
		if not collision1 and not collision2 and pointSegment1.x and PredictedHitChance3 >= Config.Extras.MinHitchance and Config.Extras.SplitQMode and GetDistance(PredictedPos3, newpointLine1) < Config.Extras.SplitQDistance and GetDistance(myHero, newpointLine1) < SpellQ.Range and GetDistance(myHero, newpointLine1) >= Config.Extras.SplitQMinimumDistance then
			pointSegment, pointLine, isOnSegment = newpointSegment1, newpointLine1, isOnSegment1 
			if Config.Extras.Debug then
				--print('Case 2 returned value')
			end 
			return refactored_newpointline
			--return nil
		else
			pointSegment, pointLine, isOnSegment = nil, nil, nil
			if Config.Extras.Debug then
				--print('Case 3 called')
			end 
			if Config.Extras.CheckAngle and Config.Extras.MaxAngle > 0 and Config.Extras.AngleIncrement > 0 and PredictedHitChance3 >= Config.Extras.MinSplitQHitchance then
				local iter = math.ceil(Config.Extras.MaxAngle/Config.Extras.AngleIncrement)
				for i= 1, iter do
					if Config.Extras.Debug then
						--print(i*Config.Extras.AngleIncrement*0.0174532925)
					end 
			        table.insert(AngleTable, i*Config.Extras.AngleIncrement*0.0174532925)
			        table.insert(AngleTable, 2*math.pi - i*Config.Extras.AngleIncrement*0.0174532925)
			    end 
			    ToRotateVector = Vector(Vector(PredictedPos3) - Vector(myHero)):normalized()*SpellQ.Range
				if Config.Extras.Debug then
					--print('Rotated vector generated')
					--print(ToRotateVector)
				end 
				if ToRotateVector ~= nil then
				    for idx, val in ipairs(AngleTable) do
				    	if Config.Extras.Debug then
							--print('Rotating at ' .. tostring(val))
						end 
				    	local ToInsertVector = ToRotateVector:rotated(val, 0.001, val)
				    	--CheckPoint = Vector(myHero) + Vector(ToInsertVector)
				    	table.insert(VectorTable2, ToInsertVector)
				  --  		if Config.Extras.Debug then
						-- 	print('insertvector is' .. tostring(ToInsertVector.x) .. "\t" .. tostring(ToInsertVector.z))
						-- 	print(#VectorTable2)
						-- 	print(ToRotateVector:angle(ToInsertVector))
						-- end
						if idx == 3 then
							CheckPoint = Vector(myHero) + Vector(ToInsertVector)
							-- if Config.Extras.Debug then
							-- 	print('insertvector is' .. tostring(ToInsertVector.x) .. "\t" .. tostring(ToInsertVector.z))
							-- 	print(#VectorTable2)
							-- 	print(ToRotateVector:angle(ToInsertVector))
							-- end
							--return CheckPoint
						end
				    	TempSegment, TempLine, TempIsOnSegment = VectorPointProjectionOnLineSegment(Vector(myHero), Vector(Vector(myHero) + ToInsertVector), Vector(PredictedPos3))
				    	local TempSegment3D = {x=TempSegment.x, y=myHero.y, z=TempSegment.y} 
				    	local TempLine3D = {x=TempLine.x, y=myHero.y, z=TempLine.y}
				  --   	local myherotemppos = {x=myHero.x, y=myHero.z}
				  --   	local enemytemppos = {x=Target.x, y=Target.z}
				  --   	local pushvector1 = Vector(myHero) 
				  --   	local pushvector2 = {x=TempSegment.x - myHero.x, y=myHero.y, z=TempSegment.y - myHero.z}
				  --   	local topush = {pushvector1, pushvector2}
				  -- --   	if Config.Extras.Debug then
						-- -- 	print('Pushing to Vector table' .. tostring(topush[1].x))
						-- -- 	print(#VectorTable)
						-- -- end 
				  --   	table.insert(VectorTable, topush)
						-- if Config.Extras.Debug then
						-- 	print(' TempSegment3D is' .. tostring(TempSegment3D.x) .. "\t" .. tostring(TempSegment3D.z))
						-- 	-- print(#VectorTable2)
						-- 	-- print(ToRotateVector:angle(ToInsertVector))
						-- end
						refactored_TempSegment3D = Vector(myHero) + Vector(Vector(TempSegment3D) - Vector(myHero)):normalized()*SpellQ.Range
				    	if TempIsOnSegment and TempSegment3D ~= nil and TempLine3D ~= nil then
				    		if TempIsOnSegment then 
				    			local newdelay = (GetDistance(myHero, TempSegment3D)/SpellQ.Speed) + (GetDistance(TempSegment3D, PredictedPos3))/SpellQ.Speed + Config.Extras.SplitQDelay/1000 + SpellQ.Delay
				    			local col1 = VP:CheckMinionCollision(myHero, TempSegment3D, SpellQ.Delay, SpellQ.Width, GetDistance(myHero, TempSegment3D), SpellQ.Speed, myHero, false)
				    			local col2 = VP:CheckMinionCollision(myHero, PredictedPos3, (GetDistance(myHero, TempSegment3D)/SpellQ.Speed) + Config.Extras.SplitQDelay/1000 + SpellQ.Delay, SpellQ.Width, Config.Extras.SplitQDistance, QSplitSpeed, TempSegment3D, false)
				    			if Config.Extras.Debug then
									--print(' TempSegment3D is' .. tostring(col1) .. "\t" .. tostring(col2) .. "\t" .. tostring(newdelay))
									--print('Refactored TempSegment3D ' .. tostring(GetDistance(refactored_TempSegment3D)))
							-- print(#VectorTable2)
							-- print(ToRotateVector:angle(ToInsertVector))
								end
				    			if not col1 and not col2 and GetDistance(TempSegment3D) > Config.Extras.SplitQMinimumDistance and GetDistance(TempSegment3D, PredictedPos3) < Config.Extras.SplitQDistance and GetDistance(TempSegment3D, myHero) < Config.Extras.SplitQMaximumDistance then
				    				if Config.Extras.Debug then
				    					--print('Case 3 returned')
				    				end
				    				return refactored_TempSegment3D
				    				-- local placeholder2, hitchance2, pos2 = VP:GetPredictedPos(Target, newdelay, math.huge, myHero, false)
				    				-- local TempPos43D = {x=pos2.x, y=myHero.y, z=pos2.y}
				    				-- if hitchance2 >= Config.Extras.MinHitchance then
				    				-- 	local TempSegment2, TempLine2, TempIsOnSegment2 = VectorPointProjectionOnLineSegment(Vector(myHero), Vector(pos2), Vector(refactored_TempSegment3D))
				    				-- 	local TempSegment23D = {x=TempSegment2.x, y=myHero.y, z=TempSegment2.y}
				    				-- 	if TempSegment23D ~= nil and GetDistance(TempSegment23D, myHero) < SpellQ.Range and GetDistance(pos2, TempSegment23D) < Config.Extras.SplitQMinimumDistance then
				    				-- 		return TempSegment23D
				    				-- 	end
				    				-- end
				    			end
				    		end
				    	end
				    end
				end
			end
		end

	-- 	return nil
	end
	-- local col1 = VP:CheckMinionCollision(pointSegment, 0.400, SpellQ.Width, Config.Extras.SplitQDistance, SpellQ.Speed, myHero)
	-- local col2 = VP:CheckMinionCollision(pointLine, 0.400, SpellQ.Width, Config.Extras.SplitQDistance, SpellQ.Speed, myHero)
	-- local col3 = VP:CheckMinionCollision(pointSegment, 0.600, SpellQ.Width, Config.Extras.SplitQDistance, SpellQ.Speed, pointLine)
	-- if Config.Extras.Debug then
	-- 	print(col1)
	-- 	print(col2)
	-- 	print(col3)
	-- end 
	-- if isOnSegment ~= nil and pointSegment ~= nil and isOnSegment and GetDistance(pointSegment) < SpellQ.range and col1 == false and PredictedHitChance >= Config.Extras.MinHitchance then
	-- 	ShouldCastPosition = Vector(myHero) + SpellQ.Range * (Vector(pointSegment) - Vector(myHero)):normalized()
	-- 	StoredPosition = ShouldCastPosition
	-- 	if Config.Extras.Debug then
	-- 		print('Single Q 2nd case found (segment)')
	-- 	end 
	-- 	return ShouldCastPosition 
	-- elseif not isOnSegment and pointLine and GetDistance(pointLine, myHero) < SpellQ.range and col2 == false and col3 == false then
	-- 	ShouldCastPosition = Vector(myHero) + SpellQ.Range * (Vector(pointLine) - Vector(myHero)):normalized() 
	-- 	StoredPosition = ShouldCastPosition
	-- 	if Config.Extras.Debug then
	-- 		print('Single Q 2nd case found (line)')
	-- 	end 
	-- 	return ShouldCastPosition
	-- else
	-- 	return nil
	-- end
end

function CheckQWillHit(startvec, endvec, Target, mode)
	local qpointSegment, qpointLine, qIsOnSegment = VectorPointProjectionOnLineSegment(Vector(startvec), Vector(endvec), Vector(Target))
	if qpointSegment ~= nil and qpointSegment.x and qIsOnSegment then
		local qpointSegment3D = {x=qpointSegment.x, y=Target.y, z=qpointSegment.y}
		if GetDistance(Target,qpointSegment3D) < 45 + VP:GetHitBox(Target) then
			if mode then
				return true
			else
				return qpointSegment3D
			end
		end
	else
		if mode then
			return false
		else
			return nil 
		end
	end
end

function CalculateDoubleQPosition(Target)
	local ShouldCastPosition= nil
	local Enemies = GetEnemyHeroes()
	local tocheckpairs = {}
	if Config.Extras.DoubleQ then
		for index, value in ipairs(Enemies) do
			if value.networkID ~= Target.networkID and GetDistance(Target, value) < 2*Config.Extras.SplitQDistance+150 then
				-- local Throwaway, CollisionChance = VP:GetPredictedPos(value, 0.600, math.huge, Target, true) --check to see if line connecting the two will have minion collision
				-- if CollisionChance >= Config.Extras.MinSplitQHitchance then
					table.insert(tocheckpairs, value)
					if Config.Extras.Debug then
						--print('Double Q champion inserted')
					end 
				--end
			end
		end
		for _, champion in ipairs(tocheckpairs) do
			if Config.Extras.Debug then
				--print(champion.charName)
			end 
			local current_distance = Config.Extras.SplitQMinimumDistance
			while current_distance < SpellQ.Range do
				local current_delay = current_distance/SpellQ.Speed + SpellQ.Delay + Config.Extras.SplitQDelay/1000
				local enemyPos1, enemyHitchance1 = VP:GetPredictedPos(Target, current_delay, math.huge, myHero, false)
				local enemyPos2, enemyHitchance2 = VP:GetPredictedPos(champion, current_delay, math.huge, myHero, false)
				if enemyPos1 ~= nil and enemyPos2 ~= nil and enemyHitchance1 ~= nil and enemyHitchance2 ~= nil and GetDistance(enemyPos1) < 1400 and GetDistance(enemyPos2) < 1400 then
				    local fromposition = Vector(enemyPos1):center(Vector(enemyPos2))
				    local fromposition_refactored = Vector(myHero) + Vector(Vector(fromposition) - Vector(myHero)):normalized()*SpellQ.Range
				   	if Config.Extras.Debug then
						--print(fromposition_refactored)
					end 
					local col = VP:CheckMinionCollision(myHero, fromposition, SpellQ.Delay, SpellQ.Width, GetDistance(myHero, fromposition), SpellQ.Speed, myHero, false)
					if not col then
						local ExtendedQVector = Vector(Vector(fromposition) - Vector(myHero)):normalized()
						local EnemyQUnitVector1 = ExtendedQVector:perpendicular()
						local EnemyQUnitVector2 = ExtendedQVector:perpendicular2()
						local EnemyQVector1 = Vector(fromposition) + EnemyQUnitVector1*Config.Extras.SplitQDistance
						local EnemyQVector2 = Vector(fromposition) + EnemyQUnitVector2*Config.Extras.SplitQDistance
						local col2 = VP:CheckMinionCollision(myHero, EnemyQVector1, SpellQ.Delay + Config.Extras.SplitQDelay/1000 + (GetDistance(myHero,fromposition)/SpellQ.Speed), SpellQ.Width, GetDistance(EnemyQVector1, fromposition), QSplitSpeed, fromposition, false)
						local col3 = VP:CheckMinionCollision(myHero, EnemyQVector2, SpellQ.Delay + Config.Extras.SplitQDelay/1000 + (GetDistance(myHero,fromposition)/SpellQ.Speed), SpellQ.Width, GetDistance(EnemyQVector2, fromposition), QSplitSpeed, fromposition, false)
						if not col2 and not col3 then
							if (CheckQWillHit(fromposition, EnemyQVector1, Target, true) or CheckQWillHit(fromposition, EnemyQVector1, champion, true)) and (CheckQWillHit(fromposition, EnemyQVector2, Target, true) or CheckQWillHit(fromposition, EnemyQVector2, champion, true)) then
								local fromposition_refactored = Vector(myHero) + Vector(Vector(fromposition) - Vector(myHero)):normalized()*SpellQ.Range
								DoubleQTarget = champion
								if Config.Extras.Debug then
									--print('Double Q champion returned with ' .. tostring(champion.charName))
								end 
								return fromposition_refactored
							end
						end
					end
				end

				-- local Pos1, HitChance1 = VP:GetPredictedPos(Target, current_delay, math.huge, fromposition, true)
				-- local Pos2, HitChance2 = VP:GetPredictedPos(champion, current_delay, math.huge, fromposition, true)


				-- if Config.Extras.Debug then
				-- 	print('Double Q Pos Generated at ' .. tostring(Pos1) .. "\t" .. tostring(Pos2) .. "\n")
				-- end 
				-- if HitChance1 >= Config.Extras.MinHitchance and HitChance1 >= Config.Extras.MinHitchance and Pos1 ~= nil and Pos2 ~= nil and GetDistance(Pos1) < SpellQ.Range and GetDistance(Pos2) < SpellQ.Range then
				-- 	local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(Vector(Pos1), Vector(Pos2), Vector(myHero))
				-- 	if isOnSegment and GetDistance(isOnSegment) < SpellQ.Range then
				-- 		ShouldCastPosition = Vector(myHero) + SpellQ.Range * (Vector(pointSegment) - Vector(myHero)):normalized()
				-- 		if Config.Extras.Debug then
				-- 			print('Double Q ShouldCastPositionfound')
				-- 		end 
				-- 		DoubleCast = true
				-- 		StoredPosition = ShouldCastPosition
				-- 		return ShouldCastPosition
				-- 	end
				-- end
				current_distance = current_distance + Config.Extras.DoubleQDistance
			end
		end
	end
	return nil
end


function CalculateBestInitialCastPosition(Target)
	local ShouldCastPosition= nil
	local Enemies = GetEnemyHeroes()
	local tocheckpairs = {}
	if Config.Extras.SplitQ then
		--Trivial Case - Target lies with no collision -> and within Q range
		-- if Config.Extras.Debug then
		-- 	print('Single Q called')
		-- end 
		if Config.Extras.DoubleQ then
			ShouldCastPosition = CalculateDoubleQPosition(Target)
			if ShouldCastPosition ~= nil then
				return ShouldCastPosition
			end
		end
		local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, SpellQ.Delay, SpellQ.Width, SpellQ.Range, SpellQ.Speed, myHero, true)
		if HitChance >= Config.Extras.MinHitchance and not Config.Extras.CheckAngleOnly then
			ShouldCastPosition = Vector(myHero) + SpellQ.Range * (Vector(CastPosition) - Vector(myHero)):normalized() 
			DoubleCast = false
			StoredPosition = nil
			if Config.Extras.Debug then
				print('Single Q trivial case found')
			end 
			return ShouldCastPosition
		else 
			--Easiest case: Find predicted vector -> cast at orthogonal point on infinite line
			local PredictedPos2 = CalculateDeflectedCastPosition(Target)
			--ShouldCastPosition = Vector(myHero) + SpellQ.Range*(Vector(PredictedPos2) - Vector(myHero)):normalized()
			StoredPosition = PredictedPos2
			return PredictedPos2
		end
	end
	return nil
end

function SplitQ(Target)
	Throwaway, SplitQHitChance, SplitQPosition = VP:GetLineCastPosition(Target, Config.Extras.SplitQDelay/1000, 45, Config.Extras.SplitQDistance, QSplitSpeed, QObject, true)
	if SplitQHitChance >= 0 and SplitQPosition ~= nil then 
		EndPos1 = Vector(RotatedVector1)
		EndPos2 = Vector(RotatedVector2)
		pointSegment2, pointLine2, isOnSegment2 = VectorPointProjectionOnLineSegment(Vector(QObject), Vector(EndPos1), Vector(SplitQPosition))
		pointSegment3, pointLine3, isOnSegment3 = VectorPointProjectionOnLineSegment(Vector(QObject), Vector(EndPos2), Vector(SplitQPosition))
		local newPos = {x=SplitQPosition.x, y=SplitQPosition.z}
		if Config.Extras.Debug then
			-- print(GetDistance(newPos, pointSegment2))
			-- print(GetDistance(newPos, pointSegment3))
		end 

		-- if isOnSegment2 then
		-- 	if lastdistance == nil then
		-- 		lastdistance = GetDistance(newPos, pointSegment2)
		-- 	elseif GetDistance(newPos, pointSegment2) - lastdistance < 55 then
		-- 		lastdistance = GetDistance(newPos, pointSegment2)
		-- 	else
		-- 		Cast2ndQPacket(Target)
		-- 		if Config.Extras.Debug then
		-- 			print('Failsafe Split Q 1')
		-- 		end 
		-- 	end
		-- elseif isOnSegment3 then
		-- 	if lastdistance == nil then
		-- 		lastdistance = GetDistance(newPos, pointSegment3)
		-- 	elseif GetDistance(newPos, pointSegment2) - lastdistance < 55 then
		-- 		lastdistance = GetDistance(newPos, pointSegment3)
		-- 	else
		-- 		Cast2ndQPacket(Target)
		-- 		if Config.Extras.Debug then
		-- 			print('Faile Split Q 1')
		-- 		end 
		-- 	end
		-- end




		if isOnSegment2 and GetDistance(newPos, pointSegment2) < 50 + VP:GetHitBox(Target) then
			Cast2ndQPacket(Target)
			detonate1 = true
			BlockQ = false
			CastSpell(_Q)
			if Config.Extras.Debug then
				print('Split Q 1')
			end 

		elseif isOnSegment3 and GetDistance(newPos, pointSegment3) < 50 + VP:GetHitBox(Target) then
			Cast2ndQPacket(Target)
			detonate2 = true
			BlockQ = false
			CastSpell(_Q)
			if Config.Extras.Debug then
				print('Split Q 2')
			end 
		end


		if isOnSegment2 then
			local current_unit_vector1 = Vector(Vector(newPos) - Vector(pointSegment2)):normalized() 
			if LastUnitVector1 ~= nil then
				if Config.Extras.Debug then
					print('Angle1 is ' ..LastUnitVector2:angle(current_unit_vector1))
				end
				if LastUnitVector1:angle(current_unit_vector1) > math.pi/3 then
					Cast2ndQPacket(Target)
					detonate1 = true
					BlockQ = false
					CastSpell(_Q)
					if Config.Extras.Debug then
						print('Split Q 3')
					end
				else
					LastUnitVector1 = current_unit_vector1 
				end
			else
				LastUnitVector1 = current_unit_vector1
			end
		elseif isOnSegment3 then
			local current_unit_vector2 = Vector(Vector(newPos) - Vector(pointSegment3)):normalized() 
			if LastUnitVector2 ~= nil then
				if Config.Extras.Debug then
					print('Angle2 is ' ..LastUnitVector2:angle(current_unit_vector2))
				end
				if LastUnitVector2:angle(current_unit_vector2) > math.pi/3 then
					Cast2ndQPacket(Target)
					detonate2 = true
					BlockQ = false
					CastSpell(_Q)
					if Config.Extras.Debug then
						print('Split Q 4')
					end
				else
					LastUnitVector2 = current_unit_vector2 
				end
			else
				LastUnitVector2 = current_unit_vector2
			end
		end
	end
end

--Farm Stuff--

--Start Credit Honda7
function FarmW()
	if WReady and #EnemyMinions.objects > 0 then
		local WPos = GetBestWPositionFarm()
		if WPos then
			CastSpell(_W, WPos.x, WPos.z)
		end
	end
end

function FarmE()
	if EReady and #EnemyMinions.objects > 0 then
		local EPos = GetBestEPositionFarm()
		if EPos then
			CastSpell(_E, EPos.x, EPos.z)
		end
	end
end

function FarmQ()
	if QReady and #EnemyMinions.objects > 0 then
		local QPos = GetBestQPositionFarm()
		if QPos then
			CastSpell(_Q, QPos.x, QPos.z)
		end
	end
end

function countminionshitW(pos)
	local n = 0
	local ExtendedVector = Vector(myHero) + Vector(Vector(pos) - Vector(myHero)):normalized()*SpellW.Range
	local EndPoint = Vector(myHero) + ExtendedVector
	for i, minion in ipairs(EnemyMinions.objects) do
		local MinionPointSegment, MinionPointLine, MinionIsOnSegment =  VectorPointProjectionOnLineSegment(Vector(myHero), Vector(EndPoint), Vector(minion)) 
		local MinionPointSegment3D = {x=MinionPointSegment.x, y=pos.y, z=MinionPointSegment.y}
		if MinionIsOnSegment and GetDistance(MinionPointSegment3D, pos) < SpellW.Width then
			n = n +1
			-- if Config.Extras.Debug then
			-- 	print('count minions W returend ' .. tostring(n))
			-- end
		end
	end
	return n
end

function countminionshitQ(pos)
	local n = 0
	if Config.Extras.Debug then
		print('count minions Q called')
	end
	local ExtendedQVector = Vector(Vector(pos) - Vector(myHero)):normalized()
	local MinionQUnitVector1 = ExtendedQVector:perpendicular()
	local MinionQUnitVector2 = ExtendedQVector:perpendicular2()
	local MinionQVector1 = Vector(pos) + MinionQUnitVector1*Config.Extras.SplitQDistance
	local MinionQVector2 = Vector(pos) + MinionQUnitVector2*Config.Extras.SplitQDistance
	for i, minion in ipairs(EnemyMinions.objects) do
		local MinionPointSegment1, MinionPointLine1, MinionIsOnSegment1 =  VectorPointProjectionOnLineSegment(Vector(pos), Vector(MinionQVector1), Vector(minion)) 
		local MinionPointSegment2, MinionPointLine2, MinionIsOnSegment2 =  VectorPointProjectionOnLineSegment(Vector(pos), Vector(MinionQVector2), Vector(minion))
		local MinionPointSegment13D = {x=MinionPointSegment1.x, y=pos.y, z=MinionPointSegment1.y}
		local MinionPointSegment23D = {x=MinionPointSegment2.x, y=pos.y, z=MinionPointSegment2.y}
		if MinionIsOnSegment1 and GetDistance(MinionPointSegment13D, pos) < SpellQ.Width then
			n = n +1
			if Config.Extras.Debug then
				print('count minions Q returend ' .. tostring(n))
			end
		end
		if MinionIsOnSegment2 and GetDistance(MinionPointSegment23D, pos) < SpellQ.Width then
			n = n +1
			if Config.Extras.Debug then
				print('count minions Q returend ' .. tostring(n))
			end
		end
	end
	return n
end

function countminionshitE(pos)
	local n = 0
	for i, minion in ipairs(EnemyMinions.objects) do
		if GetDistance(minion, pos) < SpellE.Width then
			n = n +1
		end
	end
	return n
end

function GetBestWPositionFarm()
	local MaxW = 0 
	local MaxWPos 
	for i, minion in pairs(EnemyMinions.objects) do
		local hitW = countminionshitW(minion)
		if hitW > MaxW or MaxWPos == nil then
			MaxWPos = minion
			MaxW = hitW
		end
	end

	if MaxWPos then
		local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(MaxWPos, SpellW.Delay, SpellW.Width, WRange)
		return Position
	else
		return nil
	end
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
		local CastPosition = Vector(myHero) + Vector(Vector(MaxQPos) - Vector(myHero)):normalized()*SpellQ.Range
		return CastPosition
	else
		return nil
	end
end

function GetBestEPositionFarm()
	local MaxE = 0 
	local MaxEPos 
	for i, minion in pairs(EnemyMinions.objects) do
		local hitE = countminionshitE(minion)
		if hitE > MaxE or MaxEPos == nil then
			MaxEPos = minion
			MaxE = hitE
		end
	end

	if MaxEPos then
		local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(MaxEPos, SpellE.Delay, SpellE.Width, ERange)
		return Position
	else
		return nil
	end
end
--End Credit Honda7

function round(num, idp)
	return string.format("%." .. (idp or 0) .. "f", num)
end

function OnDraw()
	if Config.Extras.Debug then
		DrawText3D("Current isPressedR status is " .. tostring(isPressedR), myHero.x, myHero.y, myHero.z, 25,  ARGB(255,255,0,0), true)
		DrawText3D("Current BlockQ status is " .. tostring(BlockQ), myHero.x+100, myHero.y+100, myHero.z+100, 25,  ARGB(255,255,0,0), true)
		--DrawText3D("current LastDetonateTime is " .. tostring(LastDetonateTime), myHero.x-100, myHero.y-100, myHero.z-100, 25, ARGB(255,255,0,0), true )
		if target ~= nil then
			DrawText3D("Current target status is " .. tostring(target2.charName), myHero.x+200, myHero.y+200, myHero.z+200, 25,  ARGB(255,255,0,0), true)
		end
		if LastDetonateTime ~= nil then
		DrawText3D("current LastDetonateTime is " .. tostring(LastDetonateTime), myHero.x-100, myHero.y-100, myHero.z-100, 25, ARGB(255,255,0,0), true )
		end
	end

	if Config.Draw.DrawR and RREady then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellR.Range, 1, ARGB(255, 0, 255, 255))
	end

	if Config.Draw.DrawW then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellW.Range, 1, ARGB(255, 0, 255, 255))
	end

	if Config.Draw.DrawE then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellE.Range, 1, ARGB(255, 0, 255, 255))
	end	

	if Config.Draw.DrawQ then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellQ.Range, 1, ARGB(255, 0, 255, 255))
	end	

	if Config.Draw.DrawTarget and ValidTarget(target) then
		DrawCircle3D(target.x, target.y, target.z, VP:GetHitBox(target), 1, ARGB(255, 0, 255, 255))
	end

	if Config.Draw.DrawRDamage and RReady then
		local Enemies = GetEnemyHeroes()
		for idx, champ in ipairs(Enemies) do
			local pertickdamage = getDmg("R", champ, myHero)
			local total_damage = pertickdamage*8 
			local dps = total_damage/2
			if champ.health < total_damage and GetDistance(champ) < 2500 and ValidTarget(champ, 2500) then
				local time_to_death = champ.health/dps
				local overkill = total_damage - champ.health
				DrawText3D("R time to death: " .. round(time_to_death,2) .. " (" .. round(overkill,1) .. " hp overkill)", champ.x, champ.y, champ.z, 15, ARGB(255,255,0,0), true)
			end
		end
	end

	if Config.Draw.DrawQ then
		if ToRotateVector ~= nil and target2 then
			DrawLine3D(myHero.x, myHero.y, myHero.z, myHero.x + ToRotateVector.x, myHero.y, myHero.z + ToRotateVector.z, 1, ARGB(255, 255, 0, 0))
		end
		if Config.DrawQ2 and VectorTable2 ~= nil and #VectorTable2 >= 0 then
			for idx, val in ipairs(VectorTable2) do
				DrawLine3D(myHero.x, myHero.y, myHero.z, myHero.x+val.x, myHero.y, myHero.z+val.z, 2, ARGB(255, 0, 255, 255))
			end
		end

		if TempSegment2 ~= nil then
			DrawCircle3D(TempSegment2.x, myHero.y, TempSegment2.z, 100, 1, ARGB(255, 255, 255, 0))
		end

		if refactored_TempSegment3D ~= nil then
			DrawCircle3D(refactored_TempSegment3D.x, myHero.y, refactored_TempSegment3D.z, 100, 1, ARGB(255, 255, 255, 255))
		end

		-- if Config.DrawQ2 and VectorTable ~= nil and #VectorTable >= 1 and QObject == nil then
		-- 	for idx, val in ipairs(VectorTable) do
		-- 		DrawLine3D(val[1].x, val[1].y, val[1].z, val[2].x, val[2].y, val[2].z, 2, ARGB(255, 0, 255, 255))
		-- 	end
		-- end

		-- if BestPosition ~= nil and target2 and ValidTarget(target2) then
		-- 	DrawCircle3D(BestPosition.x, myHero.y, BestPosition.z, 50, 1, ARGB(255, 0, 255, 0))
		-- end

		-- -- if Config.DrawQ2 and ToRotateVector ~= nil then
		-- -- 	DrawLine3D(myHero.x, myHero.y, myHero.z, myHero.x + ToRotateVector.x, myHero.y, myHero.z + ToRotateVector.z, 2, ARGB(255, 255, 0, 0))

		-- -- end
		if QObject ~= nil and OriginalCastVector2 ~= nil and EndPos1 ~= nil and EndPos2 ~= nil then
			DrawLine3D(QObject.x, myHero.y, QObject.z, OriginalCastVector2.x, OriginalCastVector2.y, OriginalCastVector2.z, 1, ARGB(255, 255, 255, 255))
			DrawLine3D(QObject.x, myHero.y, QObject.z, EndPos2.x, myHero.y, EndPos2.z, 1, ARGB(255, 255, 255, 255))
			DrawLine3D(QObject.x, myHero.y, QObject.z, EndPos1.x, myHero.y, EndPos1.z, 1, ARGB(255, 255, 255, 255))
			if EndPos1 ~= nil and pointSegment2 ~= nil and pointSegment2.x and pointSegment2.y and not(detonate2 or detonate1)then
				DrawLine3D(SplitQPosition.x, myHero.y, SplitQPosition.z, pointSegment2.x, myHero.y, pointSegment2.y, 2, ARGB(255, 255, 0, 0))
			elseif EndPos1 ~= nil and pointSegment2 ~= nil and pointSegment2.x and pointSegment2.y and (detonate2 or detonate1) then
				DrawLine3D(SplitQPosition.x, myHero.y, SplitQPosition.z, pointSegment2.x, myHero.y, pointSegment2.y, 2, ARGB(255, 0, 0, 255))
			end
			if EndPos2 ~= nil and pointSegment3 ~= nil and pointSegment3.x and pointSegment3.y and not (detonate2 or detonate1) then
				DrawLine3D(SplitQPosition.x, myHero.y, SplitQPosition.z, pointSegment3.x, myHero.y, pointSegment3.y, 2, ARGB(255, 255, 0, 0))
			elseif EndPos2 ~= nil and pointSegment3 ~= nil and pointSegment3.x and pointSegment3.y and (detonate2 or detonate1) then
				DrawLine3D(SplitQPosition.x, myHero.y, SplitQPosition.z, pointSegment3.x, myHero.y, pointSegment3.y, 2, ARGB(255, 0, 0, 255))
			end
		end
		--pointSegment, pointLine, isOnSegment
		-- if pointSegment ~= nil and pointSegment.x and pointSegment.y and target ~= nil and ValidTarget(target, 1500) then
		-- 	DrawLine3D(myHero.x, myHero.y, myHero.z, pointSegment.x, myHero.y, pointSegment.z, 1, ARGB(255, 255, 255, 255))
		-- end
		-- --pointSegment, pointLine, isOnSegment
		-- if pointLine ~= nil and pointLine.x and pointLine.y and target ~= nil and ValidTarget(target, 1500) then
		-- 	DrawLine3D(myHero.x, myHero.y, myHero.z, pointLine.x, myHero.y, pointLine.z, 1, ARGB(255, 255, 0, 0))
		-- end

		-- if SplitQPosition ~= nil then
		-- 	DrawCircle3D(SplitQPosition.x, myHero.y, SplitQPosition.z, 100, 2, ARGB(255, 255, 255, 255))
		-- end

		-- if EndPos2 ~= nil then
		-- 	DrawCircle3D(EndPos2.x, myHero.y, EndPos2.z, 100, 2, ARGB(255, 0, 255, 0))
		-- end

		-- if EndPos1 ~= nil then
		-- 	DrawCircle3D(EndPos1.x, myHero.y, EndPos1.z, 100, 2, ARGB(255, 0, 255, 0))
		-- end

		-- if BestPosition ~= nil then
		-- 	DrawCircle3D(BestPosition.x, myHero.y, BestPosition.z, 50, 1, ARGB(255, 0, 255, 0))
		-- end
		-- if DeflectedPosition ~= nil then
		-- 	DrawCircle3D(DeflectedPosition.x, myHero.y, DeflectedPosition.y, 50, 1, ARGB(255, 0, 0, 0))
		-- end
	end
end

function OnCreateObj(obj)
	if (obj.name == "Velkoz_Base_Q_mis.troy" or obj.name == "Velkoz_Skin01_Q_mis.troy" or obj.name == "Velkoz_Skin01_Q_Mis.troy") and obj.team ~= TEAM_ENEMY and GetDistance(obj, myHero) < 600 then
		QObject = obj
		--BlockQ = true
		QStartPos = Vector(obj)
	end

	if (obj.name == "Velkoz_Base_Q_EndIndicator.troy" or obj.name == 'Velkoz_Skin01_Q_EndIndicator.troy') and obj.team ~= TEAM_ENEMY and GetDistance(obj, myHero) < 1200 then
		QEndObject = obj
		BlockQ = true
	end

	-- if obj.name == "Velkoz_Base_R_Lensbeam.troy" and obj.team ~= TEAM_ENEMY then
	-- 	isPressedR = true
	-- end
end

function OnDeleteObj(obj)
	if (obj.name == "Velkoz_Base_Q_mis.troy" or obj.name == "Velkoz_Skin01_Q_mis.troy" or obj.name == "Velkoz_Skin01_Q_Mis.troy")and obj.team ~= TEAM_ENEMY then
		QObject = nil
		QStartPos = nil
		BlockQ = false
	end

	if (obj.name == "Velkoz_Base_Q_EndIndicator.troy" or obj.name == 'Velkoz_Skin01_Q_EndIndicator.troy') and obj.team ~= TEAM_ENEMY then
		QEndObject = nil
		BlockQ = false
	end

	-- if obj.name == 'Velkoz_Base_R_beam.troy' and obj.team ~= TEAM_ENEMY then
	-- 	isPressedR = false
	-- end
end

function OnGainBuff(unit, buff)
	if unit.isMe and buff.name == 'VelkozR' then
		isPressedR = true
	end
end

function OnLoseBuff(unit, buff)
	if unit.isMe and buff.name == 'VelkozR' then
		isPressedR = false
	end
end


-- function Cast2ndR()
-- 	print('sending 2nd packet')
-- 	local packet = CLoLPacket(0xE5)
-- 	packet.dwArg1 = 1
-- 	packet.dwArg2 = 0
-- 	packet:EncodeF(myHero.networkID)
-- 	packet:Encode1(0x83)
-- 	packet:EncodeF(mousePos.x)
-- 	packet:EncodeF(mousePos.y)
-- 	packet:EncodeF(mousePos.z)
-- 	SendPacket(packet)
-- end

function Cast2ndQPacket(unit)
	Packet("S_CAST", {spellId = _Q, toX=unit.x, toY=unit.z, fromX=unit.x, fromY=unit.z}):send()
end

function CastRPacket(unit)
	Packet("S_CAST", {spellId = _R, toX=unit.x, toY=unit.z, fromX=unit.x, fromY=unit.z}):send()
end

function OnRecvPacket(p)
	-- if p.header == 0x4F then
	-- 	DelayAction(Cast2ndR, 0.1)
	-- -- 	print('0x4f received')
	-- -- 	local result = {
	-- -- 	dwArg1 = p.dwArg1,
	-- -- 	dwArg2 = p.dwArg2,
	-- -- 	pos1 = p.DecodeF(),
	-- -- 	pos2 = p.DecodeF(),
	-- -- 	pos3 = p.DecodeF(),
	-- -- 	pos4 = p.DecodeF(),
	-- -- 	pos5 = p.DecodeF(),
	-- -- 	pos6 = p.DecodeF(),
	-- -- 	pos7 = p.DecodeF(),
	-- -- 	pos8 = p.DecodeF(),
	-- -- 	pos9 = p.DecodeF()
	-- -- }
	-- -- 	print(result)
	-- 	--Cast2ndR()
	-- end
end

function OnSendPacket(p)

	-- if p.header == 0x4F then
	-- 	Cast2ndR()
	-- end
	if p.header == Packet.headers.S_CAST and BlockQ then
		result = {
            dwArg1 = p.dwArg1,
            dwArg2 = p.dwArg2,
            sourceNetworkId = p:DecodeF(),
            spellId = p:Decode1(),
            fromX = p:DecodeF(),
            fromY = p:DecodeF(),
            toX = p:DecodeF(),
            toY = p:DecodeF(),
            targetNetworkId = p:DecodeF()
        }
		if result.spellId == '128'or result.spellId == _Q or result.spellId == "Q" then
			p:Block()
			if Config.Extras.Debug then
				print('Block Q packet blocked')
			end 
		end
	end

	if p.header == 229 and Config.TrackR then
	    -- if Config.Extras.Debug then
     --    	print('p blocked')
   		-- end
		-- p:Block()
		-- Cast2ndR()
		p.pos = 1
        result = {
            dwArg1 = p.dwArg1,
            dwArg2 = p.dwArg2,
            sourceNetworkId = p:DecodeF(),
            spellId = p:Decode1(),
            fromX = p:DecodeF(),
            fromY = p:DecodeF(),
            fromZ = p:DecodeF(),
        }
     --    if Config.Extras.Debug then
     --    	print('p blocked')
   		-- end
        p:Block()

		if ValidTarget(target) and GetDistance(target) < 1500 then
			-- if Config.Extras.Debug then
   --      		print('r_target_acquired')
   -- 			end
    		local packet = CLoLPacket(229)
			packet.dwArg1 = result.dwArg1
			packet.dwArg2 = result.dwArg2
			packet:EncodeF(result.sourceNetworkId)
			packet:Encode1(result.spellId)
			packet:EncodeF(target3.x)
			packet:EncodeF(target3.y)
			packet:EncodeF(target3.z)
			--SendPacket(packet)\
			SendPacket(packet)
		else
    		local packet = CLoLPacket(229)
			packet.dwArg1 = result.dwArg1
			packet.dwArg2 = result.dwArg2
			packet:EncodeF(result.sourceNetworkId)
			packet:Encode1(result.spellId)
			packet:EncodeF(result.fromX)
			packet:EncodeF(result.fromY)
			packet:EncodeF(result.fromZ)
			--SendPacket(packet)\
			SendPacket(packet)
		end
	end

	if p.header == Packet.headers.S_CAST and isPressedR and Config.Extras.BlockR then
	    if Config.Extras.Debug then
			print('Block R Packet Called')
		end
		result = {
            dwArg1 = p.dwArg1,
            dwArg2 = p.dwArg2, 
            sourceNetworkId = p:DecodeF(),
            spellId = p:Decode1(),
            fromX = p:DecodeF(),
            fromY = p:DecodeF(),
            toX = p:DecodeF(),
            toY = p:DecodeF(),
            targetNetworkId = p:DecodeF()
        }
        if result.spellId == '131'or result.spellId == _R or result.spellId == "R" then
        	p:Block()
        	if Config.Extras.Debug then
				print('isPressedR packet 0x99 blocked')
			end
        end
		if Config.Extras.Debug then
			print('isPressedR packet 0x99 blocked')
		end
	end


	-- if p.header == Packet.headers.S_MOVE and isPressedR and not Config.ManualR then
	-- 	p:Block()
	-- 	if Config.Extras.Debug then
	-- 		print('isPressedR packet 0x71 blocked')
	-- 	end
	-- end
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

function Check()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
	-- if not RReady then
	-- 	isPressedR = false
	-- end

	-- if not QReady then
	-- 	BlockQ = false
	-- end
	AngleTable = {}
	VectorTable = {}
	VectorTable2 = {}
    if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
            ignite = SUMMONER_1
    elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
            ignite = SUMMONER_2
    end
    igniteReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)

	-- if not RReady then
	-- 	isPressedR = false
	-- end

	-- if not QReady then
	-- 	BlockQ = false
	-- end

	if not QReady then
		lastdistance = nil
	end
end



function CheckDashes()
	local Enemies = GetEnemyHeroes()
	for idx, enemy in ipairs(Enemies) do
		if not enemy.dead and ValidTarget(enemy) and GetDistance(enemy) < SpellE.Range and Config.Extras.EGapClosers then
			local IsDashing, CanHit, Position = VP:IsDashing(enemy, SpellE.Delay, SpellE.Width, SpellE.Speed, myHero)
			if IsDashing and CanHit and GetDistance(Position) < SpellE.Range and EReady then
				CastSpell(_E, Position.x, Position.z)
			end
		end
	end
end
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
