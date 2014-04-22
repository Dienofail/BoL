local version = "1.05"
--[[

Free Jinx!

by Dienofail

Changelog:

v0.01 - release

v0.02 - Draw other Q circles added. Temporary solution to R overkill problems. 

v0.03 - Added collision for R, added min W slider.

v0.04 - now defaults to fishbones if no enemies around.

v0.05 - Small fixes to default Q swapping

v0.06 - reverted to v0.04 for now until issues are resolved. 

v0.07 - small fixes

v0.08 - Added toggle for R overkill checks

v0.09 - Fixed typo

v0.10 - R fixes. 

v0.11 - Deleted orbwalker check. 

v0.12 - Typo fix

v0.13 - Fixed draw options

v1.00 - added option to auto E immobile/stunned/gapclosing enemies (vpred math, not custom math). Swapped colors back again, and added checks for last
waypoints in E mode. Added lag free circles. 

v1.01 - Now defaults to pow pow when farming

v1.02 - Fixed pow pow farm 

v1.03 - Added farm press requirement for pow pow

v1.04 - Github

v1.05 - Fixes to Q swapping

]]

if myHero.charName ~= "Jinx" then return end
require 'VPrediction'
require 'Collision'
--Honda7
local autoupdateenabled = true
local UPDATE_SCRIPT_NAME = "Jinx"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/Dienofail/BoL/master/Jinx.lua"
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

local ServerData
if autoupdateenabled then
	GetAsyncWebResult(UPDATE_HOST, UPDATE_PATH.."?rand="..math.random(1,1000), function(d) ServerData = d end)
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
				DownloadFile(UPDATE_URL.."?rand="..math.random(1,1000), UPDATE_FILE_PATH, function () print("<font color=\"#FF0000\"><b>"..UPDATE_SCRIPT_NAME..":</b> successfully updated. Reload (double F9) Please. ("..version.." => "..ServerVersion..")</font>") end)     
			elseif ServerVersion then
				print("<font color=\"#FF0000\"><b>"..UPDATE_SCRIPT_NAME..":</b> You have got the latest version: <u><b>"..ServerVersion.."</b></u></font>")
			end		
			ServerData = nil
		end
	end
	AddTickCallback(update)
end
local Config = nil
local VP = VPrediction()
local Col = Collision(3000, 1700, 0.316, 140)
local SpellW = {Speed = 2000, Range = 1450, Delay = 0.066 + 0.251, Width = 60}
local SpellE = {Speed = 1750, Delay = 0.5 + 0.2658, Range = 900, Width = 120}
local SpellR = {Speed = 1700, Delay = 0.066 + 0.250, Range = 25750, Width = 140}
local QReady, WReady, EReady, RReady = nil, nil, nil, nil 
local QObject = nil
local QEndPos = nil
local LastDistance = nil
local TargetQPos = nil
local isFishBones = true
local FishStacks = 0
local Walking = false
local QRange
function OnLoad()
	Menu()
	Init()
end

function Init()
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1575, DAMAGE_PHYSICAL)
	ts.name = "Ranged Main"
	Config:addTS(ts)
	EnemyMinions = minionManager(MINION_ENEMY, 1100, myHero, MINION_SORT_MAXHEALTH_DEC)
    print('Dienofail Jinx ' .. tostring(version) .. ' loaded!')
    initDone = true
end


function Menu()
	Config = scriptConfig("Jinx", "Jinx")
	Config:addParam("Combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("Harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('C'))
	Config:addParam("Farm", "Farm", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('V'))
	Config:addSubMenu("Combo options", "ComboSub")
	Config:addSubMenu("Harass options", "HarassSub")
	Config:addSubMenu("KS", "KS")
	Config:addSubMenu("Extra Config", "Extras")
	Config:addSubMenu("Draw", "Draw")

	--Combo
	Config.ComboSub:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, true)

	--Harass
	Config.HarassSub:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.HarassSub:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	Config.HarassSub:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
	
	--Draw 
	Config.Draw:addParam("DrawOtherQ", "Draw Other Q", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawW", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawE", "Draw E Range", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawR", "Draw R Range", SCRIPT_PARAM_ONOFF, true)
	
	--KS
	Config.KS:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	Config.KS:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, true)
	--Extras
	Config.Extras:addParam("Debug", "Debug", SCRIPT_PARAM_ONOFF, false)
	Config.Extras:addParam("RRange", "Max R Range", SCRIPT_PARAM_SLICE, 1700, 0, 3575, 0)
	Config.Extras:addParam("WRange", "Min W Range", SCRIPT_PARAM_SLICE, 300, 0, 1450, 0)
	Config.Extras:addParam("MinRRange", "Min R Range", SCRIPT_PARAM_SLICE, 300, 0, 1800, 0)
	Config.Extras:addParam("REnemies", "Min Enemies for Auto R", SCRIPT_PARAM_SLICE, 4, 1, 5, 0)
	Config.Extras:addParam("ROverkill", "Check R Overkill", SCRIPT_PARAM_ONOFF, false)
	Config.Extras:addParam("EStun", "Auto E Stunned", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("EGapcloser", "Auto E Gapclosers", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("EAutoCast", "Auto E Slow/Immobile/Dash", SCRIPT_PARAM_ONOFF, false)
	Config.Extras:addParam("SwapThree", "Swap Q at three fishbone stacks", SCRIPT_PARAM_ONOFF, false)
	Config.Extras:addParam("SwapDistance", "Swap Q for Distance", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("SwapAOE", "Swap Q for AoE", SCRIPT_PARAM_ONOFF, true)
	--Permashow
	Config:permaShow("Combo")
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
		local Wtarget = ts.target

		if Config.Combo and target ~= nil then
			Combo(target)
		elseif Config.Combo and Wtarget ~= nil then
			Combo(Wtarget)
		end

		if Config.Harass and target ~= nil then
			Harass(target)
		elseif Config.Harass and Wtarget ~= nil then
			Harass(Wtarget)
		end

		if Config.Farm then
			if not isFishBones then
				CastSpell(_Q)
			end
		end

		if Config.Extras.EStun then
			CheckImmobile()
		end

		if Config.Extras.EGapcloser then
			CheckDashes()
		end
		KS()

		if target == nil and Wtarget == nil and not isFishBones and QReady and Config.Farm then
			CastSpell(_Q)
		end
	end
end

function Combo(Target)
		-- if Config.Extras.Debug then
		-- 	print('Combo called')
		-- end	
	if GetDistance(Target) < 1575 and Config.ComboSub.useW then
		CastW(Target)
	end

	if EReady and Config.ComboSub.useE then
		CastE(Target)
	end

	if EReady and Config.Extras.EAutoCast then
		AutoCastE(Target)
	end

	if QReady and Config.ComboSub.useQ then
		-- if Config.Extras.Debug then
		-- 	print('Cast Q called')
		-- end	
		Swap(Target)
	end

	if RReady and Config.ComboSub.useR then
		CastR(Target)
	end
end


function Swap(Target)
	if Target ~= nil and not Target.dead and ValidTarget(Target) and QReady then
		local PredictedPos, HitChance = VP:GetPredictedPos(Target, 0.25, math.huge, myHero, false)
		if isFishBones then
			if Config.Extras.SwapThree and FishStacks == 3 and GetDistance(PredictedPos) < QRange+VP:GetHitBox(Target) then
				CastSpell(_Q)
			end
			if Config.Extras.SwapDistance and GetDistance(PredictedPos) < QRange+VP:GetHitBox(Target) and GetDistance(PredictedPos) > 600+VP:GetHitBox(Target) then
				CastSpell(_Q)
			end
			if Config.Extras.SwapAOE and CountEnemyNearPerson(Target, 150) > 1 and FishStacks > 2 then 
				CastSpell(_Q)
			end
		else
			if Config.Extras.SwapAOE and CountEnemyNearPerson(Target, 150) > 1 then 
				return
			end
			if Config.Extras.SwapThree and FishStacks < 3 and GetDistance(PredictedPos) < 600+VP:GetHitBox(Target) then
				CastSpell(_Q)
			end
			if Config.Extras.SwapDistance and GetDistance(PredictedPos) < 600+VP:GetHitBox(Target) then
				CastSpell(_Q)
			end
		end
	end
end


function Harass(Target)
	if WReady and Config.HarassSub.useW then
		CastW(Target)
	end

	if QReady and Config.HarassSub.useQ then
		Swap(Target)
	end

	if EReady and Config.HarassSub.useE then
		CastE(Target)
	end
end


function CastE(Target)
	if EReady and GetDistance(Target) < 1100 then
		GetWallCollision(Target)
	end
end

function CastW(Target)
	local CastPosition, HitChance, Pos = VP:GetLineCastPosition(Target, SpellW.Delay, SpellW.Width, SpellW.Range, SpellW.Speed, myHero, true)
	if GetDistance(Target) < 600 and WReady and Reset(Target) and HitChance >= 2 and GetDistance(Target) > Config.Extras.WRange then
		CastSpell(_W, CastPosition.x, CastPosition.z)
	elseif GetDistance(Target) > 600 and HitChance >= 2 and GetDistance(Target) > Config.Extras.WRange then
		CastSpell(_W, CastPosition.x, CastPosition.z)
	end
end

function CastR(Target)
	if Target ~= nil and GetDistance(Target) < Config.Extras.RRange and RReady then
		if CountEnemyNearPerson(Target, 250) > Config.Extras.REnemies then
			local RAoEPosition, RHitchance, NumHit = VP:GetCircularAOECastPosition(Target, SpellR.Delay, SpellR.Width, SpellR.Range, SpellR.Speed, myHero)
			if RHitchance >= 2 and RAoEPosition ~= nil and GetDistance(RAoEPosition) < Config.Extras.RRange then
				CastSpell(_R, RAoEPosition.x, RAoEPosition.z)
			end
		end
		if GetDistance(Target) > Config.Extras.MinRRange and Config.Extras.ROverkill and GetDistance(Target) < Config.Extras.RRange then 
			local RDamage = getDmg("R", Target, myHero)
			local ADamage = getDmg("AD", Target, myHero)
			if Target.health < ADamage * 3.5 then 
				return
			elseif Target.health < RDamage then
				local RPosition, HitChance, Pos = VP:GetLineCastPosition(Target, SpellR.Delay, SpellR.Width, Config.Extras.RRange, SpellR.Speed, myHero, false)
				local WillCollide = Col:GetHeroCollision(myHero, RPosition, HERO_ENEMY)
				if HitChance >= 2 and not WillCollide then
					CastSpell(_R, RPosition.x, RPosition.z)
				end
			end
		elseif GetDistance(Target) < Config.Extras.RRange then
			local RDamage = getDmg("R", Target, myHero)
			local ADamage = getDmg("AD", Target, myHero)
			if Target.health < RDamage then
				local RPosition, HitChance, Pos = VP:GetLineCastPosition(Target, SpellR.Delay, SpellR.Width, Config.Extras.RRange, SpellR.Speed, myHero, false)
				local WillCollide = Col:GetHeroCollision(myHero, RPosition, HERO_ENEMY)
				if HitChance >= 2 and not WillCollide then
					CastSpell(_R, RPosition.x, RPosition.z)
				end
			end
		end
	end
end


function KS()
	local Enemies = GetEnemyHeroes()
	for idx, enemy in ipairs(Enemies) do
		if not enemy.dead and ValidTarget(enemy) and GetDistance(enemy) < Config.Extras.RRange and Config.KS.useR then
			if getDmg("R", enemy, myHero) > enemy.health then
				CastR(enemy)
			end
		elseif  not enemy.dead and ValidTarget(enemy) and GetDistance(enemy) < SpellW.Range and Config.KS.useW then
			if getDmg("W", enemy, myHero) > enemy.health then
				CastW(enemy)
			end
		end
	end
end

function CheckImmobile()
	local Enemies = GetEnemyHeroes()
	for idx, enemy in ipairs(Enemies) do
		if not enemy.dead and ValidTarget(enemy) and GetDistance(enemy) < SpellW.Range and Config.Extras.EStun then
			local IsImmobile, pos = VP:IsImmobile(enemy, 0.575, SpellE.Width, SpellW.Speed, myHero)
			if IsImmobile and GetDistance(pos) < SpellE.Range and EReady then
				CastSpell(_E, pos.x, pos.z)
			end
		end
	end
end

function CheckDashes()
	local Enemies = GetEnemyHeroes()
	for idx, enemy in ipairs(Enemies) do
		if not enemy.dead and ValidTarget(enemy) and GetDistance(enemy) < SpellW.Range and Config.Extras.EStun then
			local IsDashing, CanHit, Position = VP:IsDashing(enemy, 0.250, 10, math.huge, myHero)
			if IsDashing and CanHit and GetDistance(Position) < SpellE.Range and EReady then
				local DashVector = Vector(Vector(Position) - Vector(enemy)):normalized()*((SpellE.Delay - 0.250)*enemy.ms)
				local CastPosition = Position + DashVector
				if GetDistance(CastPosition) < SpellE.Range then
					CastSpell(_E, CastPosition.x, CastPosition.z)
				end
			end
		end
	end
end

function Reset(Target)
	if GetDistance(Target) > 580 then
		return true
	elseif _G.MMA_Loaded and _G.MMA_NextAttackAvailability < 0.6 then
		return true
	elseif _G.AutoCarry and (_G.AutoCarry.shotFired or _G.AutoCarry.Orbwalker:IsAfterAttack()) then 
		-- if Config.Extras.Debug then
		-- 	print('SAC shot fired')
		-- end
		return true
	else
		return false
	end
end

function AutoCastE(Target) 
	if Target ~= nil and not Target.dead and ValidTarget(Target, 1500) then
		local CastPosition, HitChance, Position = VP:GetCircularCastPosition(Target, SpellE.Delay+0.1, 60, SpellE.Range, SpellE.Speed, myHero, false)
		if HitChance >= 3 and EReady and GetDistance(CastPosition) < SpellE.Range then
			CastSpell(_E, CastPosition.x, CastPosition.z)
		end
	end
end


function OnDraw()
	if Config.Extras.Debug then
		DrawText3D("Current FishBones status is " .. tostring(isFishBones), myHero.x+200, myHero.y, myHero.z+200, 25,  ARGB(255,255,0,0), true)
		DrawText3D("Current FishBones stacks is " .. tostring(FishStacks), myHero.x, myHero.y, myHero.z, 25,  ARGB(255,255,0,0), true)
		if Wtarget ~= nil then
			DrawCircle2(Wtarget.x, Wtarget.y, Wtarget.z, 150, ARGB(255, 0, 255, 255))
		end
	end

	if Config.Draw.DrawW then
		DrawCircle2(myHero.x, myHero.y, myHero.z, SpellW.Range, ARGB(255, 0, 255, 255))
	end

	if Config.Draw.DrawE then
		DrawCircle2(myHero.x, myHero.y, myHero.z, SpellE.Range, ARGB(255, 0, 255, 255))
	end

	if Config.Draw.DrawR then
		DrawCircle2(myHero.x, myHero.y, myHero.z, Config.Extras.RRange, ARGB(255, 0, 255, 255))
	end

	if Config.Draw.DrawOtherQ then
		if isFishBones then
			DrawCircle2(myHero.x, myHero.y, myHero.z, QRange,ARGB(255, 255, 0, 0))
		else
			DrawCircle2(myHero.x, myHero.y, myHero.z, 600, ARGB(255, 255, 0, 0))
		end
	end
end

function OrbwalkToPosition(position)
	if position ~= nil then
		if _G.AutoCarry.Orbwalker then
			_G.AutoCarry.Orbwalker:OverrideOrbwalkLocation(position)
		elseif _G.MMA_Loaded then 
			moveToCursor(position.x, position.z)
		end
	else
		if _G.AutoCarry.Orbwalker then
			_G.AutoCarry.Orbwalker:OverrideOrbwalkLocation(nil)
		elseif _G.MMA_Loaded then 
			moveToCursor()
		end
	end
end

function OnGainBuff(unit, buff)
	-- if unit.isMe and buff.name == 'JinxQ' then
	-- 	isFishBones = false
	-- end

	if unit.isMe and buff.name == 'jinxqramp' then
		FishStacks = 1
	end
end

function OnUpdateBuff(unit, buff)
	if unit.isMe and buff.name == 'jinxqramp' then
		FishStacks = buff.stack
	end
end

function OnLoseBuff(unit, buff)
	-- if unit.isMe and buff.name == 'JinxQ' then
	-- 	isFishBones = true
	-- end

	if unit.isMe and buff.name == 'jinxqramp' then
		FishStacks = 0
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
	end
	QRange = myHero:GetSpellData(_Q).level*25 + 50 + 600
	if myHero.range == 525.5 then
		isFishBones = true
	else
		isFishBones = false
	end
end

function GenerateWallVector(pos)
	local WallDisplacement = 120
	local HeroToWallVector = Vector(Vector(pos) - Vector(myHero)):normalized()
	local RotatedVec1 = HeroToWallVector:perpendicular()
	local RotatedVec2 = HeroToWallVector:perpendicular2()
	local EndPoint1 = Vector(pos) + Vector(RotatedVec1)*WallDisplacement
	local EndPoint2 = Vector(pos) + Vector(RotatedVec2)*WallDisplacement
	local DiffVector = Vector(EndPoint2 - EndPoint1):normalized()
	return EndPoint1, EndPoint2, DiffVector
end

function GetWallCollision(Target)
	local TargetDestination, HitChance = VP:GetPredictedPos(Target, 1.000, math.huge, myHero, false)
	local TargetDestination2, HitChance2 = VP:GetPredictedPos(Target, 0.250, math.huge, myHero, false)
	local TargetWaypoints = VP:GetCurrentWayPoints(Target)
	local Destination1 = TargetWaypoints[#TargetWaypoints]
	local Destination2 = TargetWaypoints[1]
	local Destination13D = {x=Destination1.x, y=myHero.y, z=Destination1.y}
	if TargetDestination ~= nil and HitChance >= 1 and HitChance2 >= 2 and GetDistance(Destination1, Destination2) > 100 then 
		if GetDistance(TargetDestination, Target) > 5 then
			local UnitVector = Vector(Vector(TargetDestination) - Vector(Target)):normalized()
			Endpoint1, Endpoint2, Diffunitvector = GenerateWallVector(Destination13D)
			local DisplacedVector = Vector(Target) + Vector(Vector(Destination13D) - Vector(Target)):normalized()*((Target.ms)*SpellE.Delay+110)
			local angle = UnitVector:angle(Diffunitvector)
			if angle ~= nil then
				--print('Angle Generated!' .. tostring(angle*57.2957795))
				if angle*57.2957795 < 105 and angle*57.2957795 > 75 and GetDistance(DisplacedVector, myHero) < SpellE.Range and EReady then
					CastSpell(_E, DisplacedVector.x, DisplacedVector.z)
				end
			end
		end
	elseif EReady and GetDistance(Destination2) < SpellE.Range and GetDistance(Destination1, Destination2) < 50 and GetDistance(TargetDestination, Destination13D) < 100 and VP:CountWaypoints(Target.networkID, os.clock() - 0.5) == 0 then
		CastSpell(_E, Destination13D.x, Destination13D.z)
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

--Credit 

function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
	radius = radius or 300
	quality = math.max(8, round(180 / math.deg((math.asin((chordlength / (2 * radius)))))))
	quality = 2 * math.pi / quality
	radius = radius * .92
	local points = {}

	for theta = 0, 2 * math.pi + quality, quality do
		local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
		points[#points + 1] = D3DXVECTOR2(c.x, c.y)
	end

	DrawLines2(points, width or 1, color or 4294967295)
end

function round(num) 
	if num >= 0 then return math.floor(num+.5) else return math.ceil(num-.5) end
end

function DrawCircle2(x, y, z, radius, color)
	local vPos1 = Vector(x, y, z)
	local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
	local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
	local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))

	if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
		DrawCircleNextLvl(x, y, z, radius, 1, color, 100) 
	end
end
