local version = "0.10"
--[[

Free KogMaw!

by Dienofail

Changelog:

v0.01 - release

v0.02 - Adjusted R Delay 

v0.03 - W usage fixes.

v0.04 - Fixed E collision

v0.05 - Added killsteal. Fixed R collision some more. Added separate R stacks meter for harass/combo per request.

v0.06 - Added separate mana managers for combo/harass per request. 

v0.07 - Added minimum range slider for R

v0.08 - Github

v0.09 - Added auto ult on 100% hit

v0.10 - Corrected ult values - credit to acomma for helping me find better values!
]]

if myHero.charName ~= "KogMaw" then return end
require 'VPrediction'

--Honda7
local autoupdateenabled = true
local UPDATE_SCRIPT_NAME = "KogMaw"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/Dienofail/BoL/master/KogMaw.lua"
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
--end Honda7

local Config = nil
local VP = VPrediction()
local SpellQ = {Speed = 1550, Range = 925, Delay = 0.3667, Width = 60}
local SpellW = {Speed = 1600, Range = 1000, Delay = 0.111, Width = 55}
local SpellE = {Speed = 1400, Range = 1280, Delay = 0.066, Width = 120}
local SpellR = {Width = 10, Speed = math.huge, Delay= 0.8}
local RRangeTable = {1400, 1700, 2200}
local WRange, RRange = nil, nil 
local QReady, WReady, EReady, RReady = nil, nil, nil, nil 
local RStacks = 0
local WRangeTable = {130, 150, 170, 190, 210}
function OnLoad()
	Menu()
	Init()
end

function Init()
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1300, DAMAGE_PHYSICAL)
	ts2 = TargetSelector(TARGET_LESS_CAST_PRIORITY, 2200, DAMAGE_PHYSICAL)
	ts.name = "Ranged Main"
	ts2.name = "R target selector"
	Config:addTS(ts)
	Config:addTS(ts2)
	EnemyMinions = minionManager(MINION_ENEMY, 1100, myHero, MINION_SORT_MAXHEALTH_DEC)
    -- print('Dienofail KogMaw ' .. tostring(version) .. ' loaded!')
    -- if _G.MMA_Loaded then
    -- 	print('MMA detected, using MMA compatibility')
    -- elseif _G.AutoCarry.Orbwalker then
    -- 	print('SAC detected, using SAC compatibility')
    -- end
    initDone = true
end


function Menu()
	Config = scriptConfig("KogMaw", "KogMaw")
	Config:addParam("Combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("Harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('C'))
	Config:addParam("Farm", "Farm", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('V'))
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
	Config.ComboSub:addParam("RStacks", "R Max Stacks", SCRIPT_PARAM_SLICE, 4, 1, 10, 0)
	Config.ComboSub:addParam("mManager", "Mana slider", SCRIPT_PARAM_SLICE, 0, 0, 100, 0)
	--Harass
	Config.HarassSub:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.HarassSub:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	Config.HarassSub:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, false)
	Config.HarassSub:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, true)
	Config.HarassSub:addParam("RStacks", "R Max Stacks", SCRIPT_PARAM_SLICE, 4, 1, 10, 0)
	Config.HarassSub:addParam("mManager", "Mana slider", SCRIPT_PARAM_SLICE, 0, 0, 100, 0)
	--Farm
	Config.FarmSub:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
	Config.FarmSub:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	
	--KS
	Config.KS:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.KS:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
	Config.KS:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, true)

	--Draw 
	Config.Draw:addParam("DrawQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawW", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawE", "Draw E Range", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawR", "Draw R Range", SCRIPT_PARAM_ONOFF, true)
	--Extras
	Config.Extras:addParam("Debug", "Debug", SCRIPT_PARAM_ONOFF, false)
	Config.Extras:addParam("RStacks", "R Max Stacks", SCRIPT_PARAM_SLICE, 4, 1, 10, 0)
	Config.Extras:addParam("RMinRange", "R Minimum Range", SCRIPT_PARAM_SLICE, 500, 0, 1800, 0)
	Config.Extras:addParam("EGapClosers", "E Gap Closers", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("AutoUlt", "Auto Ult at 100% hitchance", SCRIPT_PARAM_ONOFF, true)

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
		target = GetCustomTarget()
		Qtarget = ts2.target
		if Config.Combo and target ~= nil then
			Combo(target)
		elseif  Config.Combo and Qtarget ~= nil then
			Combo(Qtarget)
		end

		if Config.Harass and target ~= nil then
			Harass(target)
		elseif Config.Harass and Qtarget ~= nil then
			Harass(Qtarget)
		end

		if Config.Farm then
			Farm()
		end

		if Config.Extras.EGapClosers then
			CheckDashes()
		end

		if Config.Extras.AutoUlt then
			AutoUlt()
		end
		KillSteal()
	end
end


function Combo(Target)
	if QReady and Config.ComboSub.useQ and not IsMyManaLowCombo() then
		-- if Config.Extras.Debug then
		-- 	print('Cast Q called')
		-- end	
		CastQ(Target)
	end

	if WReady and Config.ComboSub.useW then
		CastW(Target)
	end

	if EReady and Config.ComboSub.useE and not IsMyManaLowCombo()then
		CastE(Target)
	end

	if RReady and Config.ComboSub.useR and RStacks < Config.ComboSub.RStacks and not IsMyManaLowCombo() and GetDistance(Target) > Config.Extras.RMinRange then
		CastR(Target)
	end
end


function Harass(Target)
	if QReady and Config.HarassSub.useQ and not IsMyManaLowHarass() then
		CastQ(Target)
	end

	if EReady and Config.HarassSub.useE and not IsMyManaLowHarass() then
		CastE(Target)
	end

	if RReady and Config.HarassSub.useR and RStacks < Config.HarassSub.RStacks and not IsMyManaLowHarass() and GetDistance(Target) > Config.Extras.RMinRange then
		CastR(Target)
	end

	if WReady and Config.HarassSub.useW then
		CastW(Target)
	end
end

function CastQ(Target)
	if Target ~= nil and ValidTarget(Target, 1300) and QReady then
		local CastPosition, HitChance, Pos = VP:GetLineCastPosition(Target, SpellQ.Delay, SpellQ.Width, SpellQ.Range, SpellQ.Speed, myHero, true)
		if HitChance >= 2 and GetDistance(CastPosition) < SpellQ.Range then
			CastSpell(_Q, CastPosition.x, CastPosition.z)
		end
	end
end

function CastW(Target)
	if Target ~= nil and ValidTarget(Target, 1300) and WReady and GetDistance(Target) < WRange then
		CastSpell(_W)
	end
end

function CastE(Target)
	if Target ~= nil and ValidTarget(Target, 1300) and EReady then
		local CastPosition, HitChance, Pos = VP:GetLineAOECastPosition(Target, SpellE.Delay, SpellE.Width, SpellE.Range, SpellE.Speed, myHero)
		if HitChance >= 2 and GetDistance(CastPosition) < SpellE.Range then
			CastSpell(_E, CastPosition.x, CastPosition.z)
		end
	end
end

function CastR(Target)
	if RReady and Target ~= nil and ValidTarget(Target, 1800) then
		local CastPosition, HitChance, Pos = VP:GetCircularCastPosition(Target, SpellR.Delay, SpellR.Width, RRange, SpellR.Speed, myHero, false)
		if HitChance >= 2 and GetDistance(CastPosition) < RRange and RStacks < Config.ComboSub.RStacks and not IsMyManaLowCombo() then
			CastSpell(_R, CastPosition.x, CastPosition.z)
		end
	end
end

function AutoUlt()
	local Enemies = GetEnemyHeroes()
	for i, enemy in ipairs(Enemies) do
		 if ValidTarget(enemy, 1800) and not enemy.dead and GetDistance(enemy) < 1800 then
			local CastPosition, HitChance, Pos = VP:GetCircularCastPosition(enemy, SpellR.Delay, SpellR.Width, RRange, SpellR.Speed, myHero, false)
			if HitChance > 2 and GetDistance(CastPosition) < RRange then
				CastSpell(_R, CastPosition.x, CastPosition.z)
			end
		 end
	end
end

function Farm()
	if Config.FarmSub.useE then
		FarmE()
	end
	if Config.FarmSub.useW then
		FarmW()
	end
end


function Reset()
	if _G.MMA_Loaded and _G.MMA_NextAttackAvailability < 0.6 then
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



function KillSteal()
	local Enemies = GetEnemyHeroes()
	for i, enemy in pairs(Enemies) do
		if ValidTarget(enemy, 1800) and not enemy.dead and GetDistance(enemy) < 1800 then
			if getDmg("Q", enemy, myHero) > enemy.health and  Config.KS.useQ then
				CastQ(enemy)
			end

			if getDmg("E", enemy, myHero) > enemy.health and Config.KS.useE then
				CastE(enemy)
			end

			if getDmg("R", enemy, myHero) > enemy.health and  Config.KS.useR then
				CastR(enemy)
			end
		end
	end

end

function OnDraw()
	-- if Config.Extras.Debug and Qtarget ~= nil then
	-- 	DrawText3D("Current IsPressedR status is " .. tostring(isPressedR), myHero.x+200, myHero.y, myHero.z+200, 25,  ARGB(255,255,0,0), true)
	-- 	DrawText3D("Current isBuffed status is " .. tostring(isBuffed), myHero.x, myHero.y, myHero.z, 25,  ARGB(255,255,0,0), true)
	-- 	DrawCircle3D(Qtarget.x, Qtarget.y, Qtarget.z, 150, 1,  ARGB(255, 0, 255, 255))
	-- end

	if Config.Draw.DrawQ then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellQ.Range, 1,  ARGB(255, 0, 255, 255))
	end

	if Config.Draw.DrawW then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, WRange, 1,  ARGB(255, 0, 255, 255))
	end

	if Config.Draw.DrawE then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellE.Range, 1,  ARGB(255, 0, 255, 255))
	end

	if Config.Draw.DrawR then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, RRange, 1,  ARGB(255, 0, 255, 255))
	end
end

function OnGainBuff(unit, buff)
	if unit.isMe and buff.name == 'kogmawlivingartillerycost' then
		RStacks = 1
	end 
end

function OnUpdateBuff(unit, buff)
	if unit.isMe and buff.name == 'kogmawlivingartillerycost' then
		RStacks = buff.stack
	end 
end

function OnLoseBuff(unit, buff)
	if unit.isMe and buff.name == 'kogmawlivingartillerycost' then
		RStacks = 0
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

-- function OnProcessSpell(unit, spell)
-- 	if unit.isMe and spell.name == 'KogMawQ' then
-- 		LastSpellCast = GetTickCount()
-- 	end

-- 	if unit.isMe and spell.name == 'KogMawW' then
-- 		LastSpellCast = GetTickCount()
-- 	end

-- 	if unit.isMe and spell.name == 'KogMawE' then
-- 		LastSpellCast = GetTickCount()
-- 	end

-- 	if unit.isMe and spell.name == 'KogMawR' then
-- 		LastSpellCast = GetTickCount()
-- 	end
-- end

-- function ShouldCast()
-- 	if GetTickCount() - LastSpellCast > 250 then
-- 		return true
-- 	else
-- 		return false
-- 	end
-- end


function Check()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
	if myHero:GetSpellData(_R).level > 0 then
		RRange = RRangeTable[myHero:GetSpellData(_R).level]
	end
	if myHero:GetSpellData(_W).level > 0 then
		WRange = 500 + WRangeTable[myHero:GetSpellData(_W).level]
	end
end


function countminionshitE(pos)
	local n = 0
	local ExtendedVector = Vector(myHero) + Vector(Vector(pos) - Vector(myHero)):normalized()*SpellE.Range
	for i, minion in ipairs(EnemyMinions.objects) do
		local MinionPointSegment, MinionPointLine, MinionIsOnSegment =  VectorPointProjectionOnLineSegment(Vector(myHero), Vector(ExtendedVector), Vector(minion)) 
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
		return MaxEPos
	else
		return nil
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

function FarmW()
	if WReady and #EnemyMinions.objects > 2 then
		CastSpell(_W)
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

function IsMyManaLowCombo()
    if myHero.mana < (myHero.maxMana * ( Config.ComboSub.mManager / 100)) then
        return true
    else
        return false
    end
end


function IsMyManaLowHarass()
    if myHero.mana < (myHero.maxMana * ( Config.HarassSub.mManager / 100)) then
        return true
    else
        return false
    end
end
