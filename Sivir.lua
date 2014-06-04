local version = "0.1"
--[[

Free Sivir!

by Dienofail

Changelog:

v0.01 - release

v0.02 - fixed menu toggles 

v0.03 - Adopted Honda7's method for checking aoe hits in line. 

v0.04 - fixed MMA issues

v0.05 - Error fixes

v0.06 - Fixed printing 

v0.07 - Added range limiter for Q and updated autoupdater. 

v0.08 - Added range limiter for Q in harass

v0.09 - Github

v0.1 - Fixes to KS
]]

if myHero.charName ~= "Sivir" then return end
require 'VPrediction'

--Honda7
local autoupdateenabled = true
local UPDATE_NAME = "Sivir"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/Dienofail/BoL/master/Sivir.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>Sivir:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
if AUTOUPDATE then
    local ServerData = GetWebResult(UPDATE_HOST, UPDATE_PATH)
    if ServerData then
        local ServerVersion = string.match(ServerData, "local version = \"%d+.%d+\"")
        ServerVersion = string.match(ServerVersion and ServerVersion or "", "%d+.%d+")
        if ServerVersion then
            ServerVersion = tonumber(ServerVersion)
            if tonumber(version) < ServerVersion then
                AutoupdaterMsg("New version available"..ServerVersion)
                AutoupdaterMsg("Updating, please don't press F9")
                DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () AutoupdaterMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end) end, 3)
            else
                AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
            end
        end
    else
        AutoupdaterMsg("Error downloading version info")
    end
end
local Config = nil
local VP = VPrediction()
local SpellQ = {Speed = 1350, Range = 1075, Delay = 0.250, Width = 85}
local SpellQ2 = {Speed = 1350, Range = 1100, Delay = 1.04, Width = 90}
local QReady, EReady = nil, nil
local QObject = nil
local QEndPos = nil
local LastDistance = nil
local TargetQPos = nil
local Walking = false
function OnLoad()
	Menu()
	Init()
end

function Init()
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1100, DAMAGE_PHYSICAL)
	ts.name = "Ranged Main"
	Config:addTS(ts)
	EnemyMinions = minionManager(MINION_ENEMY, 1100, myHero, MINION_SORT_MAXHEALTH_DEC)
    print('Dienofail Sivir ' .. tostring(version) .. ' loaded!')

    initDone = true
end


function Menu()
	Config = scriptConfig("Sivir", "Sivir")
	Config:addParam("Combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("Harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('C'))
	Config:addParam("Farm", "Farm", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('V'))
	Config:addSubMenu("Combo options", "ComboSub")
	Config:addSubMenu("Harass options", "HarassSub")
	Config:addSubMenu("Farm", "FarmSub")
	Config:addSubMenu("Extra Config", "Extras")
	Config:addSubMenu("Draw", "Draw")

	--Combo
	Config.ComboSub:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("useE", "Use E to spellshield (evadeee only)", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("MaxQRange", "Max Q Range", SCRIPT_PARAM_SLICE, 1075, 100, 1075, 0)
	Config.ComboSub:addParam("Orbwalk", "Orbwalk to Q best position", SCRIPT_PARAM_ONOFF, true)
	--Harass
	Config.HarassSub:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.HarassSub:addParam("useE", "Use E to spellshield (evadeee only)", SCRIPT_PARAM_ONOFF, true)
	Config.HarassSub:addParam("MaxQRange", "Max Q Range", SCRIPT_PARAM_SLICE, 1075, 100, 1075, 0)
	Config.HarassSub:addParam("Orbwalk", "Orbwalk to Q best position", SCRIPT_PARAM_ONOFF, true)
	--Farm
	Config.FarmSub:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.FarmSub:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	--Draw 
	Config.Draw:addParam("DrawQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawQCalculations", "Draw Q Calculations", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawMouse", "Draw Mouse Orbwalk Distance Circle", SCRIPT_PARAM_ONOFF, false)
	--Extras
	Config.Extras:addParam("Debug", "Debug", SCRIPT_PARAM_ONOFF, false)
	Config.Extras:addParam("OrbwalkDistance", "Orbwalk to Q Max Cursor Distance", SCRIPT_PARAM_SLICE, 600, 0, 1000, 0)
	Config.Extras:addParam("OrbwalkAngle", "Orbwalk to Q Max Cursor Angle", SCRIPT_PARAM_SLICE, 60, 1, 180, 0)
	Config.Extras:addParam("MaxAngle", "Max Angle for Q Check",  SCRIPT_PARAM_SLICE, 15, 1, 90, 0)
	Config.Extras:addParam("AngleIncrement", "Increment Angle Degree",  SCRIPT_PARAM_SLICE, 2, 1, 90, 0)
	Config.Extras:addParam("DoubleQ", "Check Double Q", SCRIPT_PARAM_ONOFF, true)
	--Permashow
	Config:permaShow("Combo")
	Config:permaShow("Farm")
	Config:permaShow("Harass")
end

--Credit Trees
function GetCustomTarget()
	ts:update()
    if _G.MMA_Target and _G.MMA_Target.type == myHero.type then return _G.MMA_Target end
    if _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then return _G.AutoCarry.Attack_Crosshair.target end
    return ts.target
end
--End Credit Trees

function OnTick()
	if initDone then
		EnemyMinions:update()
		Check()
		local target = GetCustomTarget()
		if Config.Combo and target ~= nil then
			Combo(target)
		end

		if Config.Harass then
			Harass(target)
		end

		if Config.Farm then
			Farm(target)
		end
	end
end

function Combo(Target)
		-- if Config.Extras.Debug then
		-- 	print('Combo called')
		-- end	
	if EReady then
		CastE()
	end

	if QReady and Config.ComboSub.useQ and GetDistance(Target) < Config.ComboSub.MaxQRange then
		-- if Config.Extras.Debug then
		-- 	print('Cast Q called')
		-- end	
		CastQ(Target)
	end

	if QObject ~= nil and Config.ComboSub.Orbwalk then
		OrbwalkQ(Target)
	end

	if GetDistance(Target) < 600 and Config.ComboSub.useW then
		CastW()
	end

	KS(Target)

end


function KS(Target)
	if QReady and getDmg("Q", Target, myHero) > Target.health then
		CastQ(Target)
	end
end



function Harass(Target)
	if QReady and Config.HarassSub.useQ and GetDistance(Target) < Config.HarassSub.MaxQRange then
		CastQ(Target)
	end

	if QObject ~= nil and Config.HarassSub.Orbwalk then
		OrbwalkQ(Target)
	end
end

function CastQ(Target)
	-- print(CountEnemyNearPerson(Target,800))
	-- print(ValidTarget(Target, 1300))
	if ValidTarget(Target, 1300) and not Target.dead and CountEnemyNearPerson(Target,800) > 1 then
		local CastPosition, HitChance, Hits = VP:GetLineAOECastPosition(Target, SpellQ.Delay, SpellQ.Width, SpellQ.Range, SpellQ.Speed, myHero)
		if CastPosition ~= nil and GetDistance(CastPosition) < SpellQ.Range + 10 and HitChance >= 2 then
			CastSpell(_Q, CastPosition.x, CastPosition.z)
		end
		if Config.Extras.Debug then
			print('Returning CastQ2')
		end	
	elseif  ValidTarget(Target, 1300) and not Target.dead then
		if Config.Extras.Debug then
			print('Returning CastQ1')
		end		
		local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, SpellQ.Delay, SpellQ.Width, SpellQ.Range, SpellQ.Speed, myHero, false)
		local _, HitChance2, _ = VP:GetLineCastPosition(Target, SpellQ2.Delay, SpellQ2.Width, SpellQ2.Range, SpellQ2.Speed, myHero, false)
		if HitChance >= 2 and (HitChance2 >= 1 and Config.Extras.DoubleQ) and GetDistance(CastPosition) < SpellQ.Range + 10 then
			CastSpell(_Q, CastPosition.x, CastPosition.z)
		end
	end
end

function OrbwalkQ(Target)
	if Config.Extras.Debug then
		print('Q Orbwalking calling')
	end		
	if GetDistance(Target) < 1400 then
		if Config.Extras.Debug then
			print('Q Orbwalking called')
		end		
		MouseVector = Vector(Vector(mousePos) - Vector(myHero)):normalized()
		local HitChance, Position = nil, nil 
		local TimeLeft = nil
		local Intersect = nil
		if IsReturning() then
			local Delay = GetDistance(QObject, Target)/SpellQ.Speed
			_, HitChance, Position = VP:GetLineCastPosition(Target, Delay, SpellQ.Width, SpellQ.Range, SpellQ.Speed, myHero, false)
			TimeLeft = GetDistance(QObject, Position)/SpellQ.Speed
			temp = VectorIntersection(Vector(QObject), Vector(Position), Vector(myHero), Vector(mousePos))
			if GetDistance(QObject) > GetDistance(Position) then
				Intersect = temp
			end
		else
			local Delay = GetDistance(QObject, QEndPos)/SpellQ.Speed + GetDistance(QEndPos, Target)/SpellQ.Speed
			_, HitChance, Position = VP:GetLineCastPosition(Target, Delay, SpellQ.Width, SpellQ.Range, SpellQ.Speed, myHero, false)
			TimeLeft = GetDistance(QObject, QEndPos)/SpellQ.Speed + GetDistance(QEndPos, Position)/SpellQ.Speed
			Intersect= VectorIntersection(Vector(QEndPos), Vector(Position), Vector(myHero), Vector(mousePos))
		end
		-- if Config.Extras.Debug then
		-- 	print('QEndPos')
		-- 	print(Vector(QEndPos))
		-- 	print('Pos')
		-- 	print(Vector(Position))
		-- 	print('myHero')
		-- 	print(Vector(myHero))
		-- 	print('mousePos')
		-- 	print(Vector(mousePos))
		-- end	
		if Intersect ~= nil then
			local Intersect3D = {x=Intersect.x, y=myHero.y, z=Intersect.y}
			if Config.Extras.Debug then
				print(Intersect3D)
			end	
			--Calculate distance and angle between intersect point and my hero
			local AngleVec1 = Vector(Vector(Intersect3D) - Vector(myHero)):normalized()
			local RealAngle = AngleVec1:angle(MouseVector)*57.2957795
			TargetQPos = Intersect3D
			local DistanceToIntersect = GetDistance(Intersect3D)/myHero.ms < TimeLeft
			if GetDistance(Intersect3D, mousePos) < Config.Extras.OrbwalkDistance and GetDistance(Intersect3D) < 750 and RealAngle < Config.Extras.OrbwalkAngle and GetDistance(Intersect3D)/myHero.ms < TimeLeft-0.05 then
				OrbwalkToPosition(Intersect3D)
				Walking = true
			else
				OrbwalkToPosition(nil)
				Walking = false
			end
		end
	else
		Walking = false
		TargetQPos = nil
		MouseVector = nil
	end
end

function CastE()
	if _G.Evadeee_impossibleToEvade then
		CastSpell(_E)
	end
end

function CastW()
	if WReset() and WReady then
		CastSpell(_W)
	end
end

function Farm()
	if Config.FarmSub.useQ then
		FarmQ()
	end
	if WReady and #EnemyMinions.objects > 3 and Config.FarmSub.useW then
		CastSpell(_W)
	end
end

function GetEnemiesHitByQ(startpos, endpos, delay)
	if startpos ~= nil and endpos ~= nil and delay ~= nil then
		local count = 0
		local Enemies = GetEnemyHeroes()
		for idx, enemy in ipairs(Enemies) do
			if enemy ~= nil and ValidTarget(enemy, 1600) and not enemy.dead and GetDistance(enemy, startpos) < SpellQ.Range + 100 then
				local throwaway, HitChance, PredictedPos = VP:GetLineCastPosition(enemy, delay, SpellQ.Width, SpellQ.Range, SpellQ.Speed, myHero, false)
				local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(Vector(startpos), Vector(endpos), Vector(PredictedPos))
				local pointSegment3D = {x=pointSegment.x, y=enemy.y, z=pointSegment.y}
				if isOnSegment and pointSegment3D ~= nil and GetDistance(pointSegment3D, PredictedPos) < VP:GetHitBox(enemy) + SpellQ.Width and HitChance >= 1 then
					count = count + 1
				end
			end
		end
		if Config.Extras.Debug then
			print('Returning GetEnemiesByQ with ' .. tostring(count))
		end
		return count
	end
end

function WReset()
	if Config.ComboSub.useWReset then
		if _G.MMA_Target ~= nil and _G.MMA_AbleToMove and not _G.MMA_AttackAvailable then
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

function OnDraw()
	if Config.Extras.Debug and QObject ~= nil then
		DrawText3D("Current IsReturning status is " .. tostring(IsReturning()), myHero.x+200, myHero.y, myHero.z+200, 25,  ARGB(255,255,0,0), true)
	end

	if Config.Draw.DrawQ then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellQ.Range, 1,  ARGB(255, 0, 255, 255))
		if QObject ~= nil then
			DrawCircle3D(QObject.x, QObject.y, QObject.z, SpellQ.Width, 1, ARGB(255, 0, 255, 255))
		end
		if QEndPos ~= nil then
			DrawCircle3D(QEndPos.x, QEndPos.y, QEndPos.z, SpellQ.Width, 1, ARGB(255, 255, 0, 0))
		end
	end

	if Config.Draw.DrawQCalculations then
		if TargetQPos ~= nil and QEndPos ~= nil and mousePos ~= nil then
			if Walking then
				DrawCircle3D(TargetQPos.x, TargetQPos.y, TargetQPos.z, 100, 1,  ARGB(255, 255, 0, 0))
				DrawLine3D(myHero.x, myHero.y, myHero.z, TargetQPos.x, TargetQPos.y, TargetQPos.z,  1, ARGB(255, 255, 0, 0))
				DrawLine3D(QEndPos.x, QEndPos.y, QEndPos.z, TargetQPos.x, TargetQPos.y, TargetQPos.z, 1, ARGB(255, 255, 0, 0))
			else
				DrawCircle3D(TargetQPos.x, TargetQPos.y, TargetQPos.z, 100, 1,  ARGB(255, 0, 255, 0))
				DrawLine3D(myHero.x, myHero.y, myHero.z, TargetQPos.x, TargetQPos.y, TargetQPos.z,  1, ARGB(255, 0, 255, 0))
				DrawLine3D(QEndPos.x, QEndPos.y, QEndPos.z, TargetQPos.x, TargetQPos.y, TargetQPos.z, 1, ARGB(255, 0, 255, 0))
			end
		end
	end

	if Config.Draw.DrawMouse then
		DrawCircle3D(mousePos.x, mousePos.y, mousePos.z, Config.Extras.OrbwalkDistance, 1, ARGB(255, 255, 0, 0))
	end
end

function OrbwalkToPosition(position)
	if position ~= nil then
		if _G.MMA_Loaded then
			_G.moveToCursor(position.x, position.z)
		elseif _G.AutoCarry and _G.AutoCarry.Orbwalker then
			_G.AutoCarry.Orbwalker:OverrideOrbwalkLocation(position)
		end
	else
		if _G.MMA_Loaded then
			return
		elseif _G.AutoCarry and _G.AutoCarry.Orbwalker then
			_G.AutoCarry.Orbwalker:OverrideOrbwalkLocation(nil)
		end
	end
end

function OnProcessSpell(unit, spell)
	if unit.isMe and spell.name == 'SivirQ' then
		QTempEndPos = {x=spell.endPos.x, y=myHero.y, z=spell.endPos.z}
		QEndPos = Vector(myHero) + Vector(Vector(QTempEndPos) - Vector(myHero)):normalized()*SpellQ.Range
		--print(QEndPos)
	end
end


function OnCreateObj(obj)
	if obj.name == "Sivir_Base_Q_mis.troy" and  obj.team ~= TEAM_ENEMY then
		QObject = obj
	end
end


function OnDeleteObj(obj)
	if obj.name == "Sivir_Base_Q_mis.troy" and GetDistance(obj) < 250 and  obj.team ~= TEAM_ENEMY then
		QObject = nil
	end
end

function Check()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
	if QObject == nil and not QReady then
		QEndPos = nil
		LastDistance = nil
		OrbwalkToPosition(nil)
	end
	
end

function IsReturning()
	if LastDistance == nil and QObject ~= nil then
		LastDistance = GetDistance(QObject, QEndPos)
		return false
	elseif QObject ~= nil then
		if GetDistance(QObject, QEndPos) >= LastDistance then
			LastDistance = GetDistance(QObject, QEndPos)
			return true
		else
			LastDistance = GetDistance(QObject, QEndPos)
			return false
		end
	else 
		return false
	end
end



function GetBestQPositionFarm()
	local MaxQ = 0 
	local MaxQPos 
	for i, minion in pairs(EnemyMinions.objects) do
		local hitQ = countminionshitQ(minion)
		if hitQ > MaxQ or MaxQPos == nil then
			MaxQPos = minion
			MaxQ = hitQ
		end
	end

	if MaxQPos then
		return MaxQPos
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


function FarmQ()
	if QReady and #EnemyMinions.objects > 0 then
		local QPos = GetBestQPositionFarm()
		if QPos then
			CastSpell(_Q, QPos.x, QPos.z)
		end
	end
end
--Credit Xetrok
function CountEnemyNearPerson(person,vrange)
    count = 0
    for i=1, heroManager.iCount do
        currentEnemy = heroManager:GetHero(i)
        if currentEnemy.team ~= myHero.team then
            if GetDistance(currentEnemy, person) <= vrange and not currentEnemy.dead then count = count + 1 end
        end
    end
    return count
end
--End Credit Xetrok
