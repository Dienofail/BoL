local version = "1.01"
--[[

Free Lucian!

by Dienofail

Changelog:

v0.01 - release

v0.02 - Fixed farm toggles

v0.03 - Fixes to W usage

v0.04 - Now should reset properly

v0.05 - Bug fixes

v0.06 - Fixes to spellweave

v0.07 - Further fixes to spellweave

v0.08 - Github

v0.09 - Moved minion update to Q function

v1.00 - Fixed spellweaving logic a bit, fixed SAC compatibility, added killsteal, improved minion Q cast

v1.01 - Futher fixes to spellweaving

]]

if myHero.charName ~= "Lucian" then return end
require 'VPrediction'

--Honda7
local autoupdateenabled = true
local UPDATE_SCRIPT_NAME = "Lucian"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/Dienofail/BoL/master/Lucian.lua"
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
local SpellQ = {Speed = math.huge, Range = 550, Delay = 0.320, Width = 65, ExtendedRange = 1100}
local SpellW = {Speed = 1600, Range = 1000, Delay = 0.300, Width = 55}
local SpellR = {Range = 1400, Width = 110, Speed = 2800, Delay= 0}
local QReady, WReady, EReady, RReady = nil, nil, nil, nil 
local RObject = nil
local REndPos = nil
local rendname = 'lucianrdisable'
local isBuffed = false
local LastSpellCast = 0
local isPressedR = false
local target = nil

function OnLoad()
	Menu()
	Init()
end

function Init()
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1100, DAMAGE_PHYSICAL)
	ts.name = "Ranged Main"
	Config:addTS(ts)
	EnemyMinions = minionManager(MINION_ENEMY, 1100, myHero, MINION_SORT_MAXHEALTH_DEC)
    -- print('Dienofail Lucian ' .. tostring(version) .. ' loaded!')
    -- if _G.MMA_Loaded then
    -- 	print('MMA detected, using MMA compatibility')
    -- elseif _G.AutoCarry.Orbwalker then
    -- 	print('SAC detected, using SAC compatibility')
    -- end
    initDone = true
end


function Menu()
	Config = scriptConfig("Lucian", "Lucian")
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
	Config.ComboSub:addParam("lockR", "Lock on R (not functional)", SCRIPT_PARAM_ONOFF, true)
	--Harass
	Config.HarassSub:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.HarassSub:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, false)
	--Farm
	Config.FarmSub:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.FarmSub:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	--Draw 
	Config.Draw:addParam("DrawQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawW", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
	--Extras
	Config.Extras:addParam("Debug", "Debug", SCRIPT_PARAM_ONOFF, false)
	Config.Extras:addParam("ExtendE", "Extend E to mouse direction", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("ESlows", "E Slows", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("CheckQ", "Check Q Using Minions", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("AoEQ", "Check AoE Q", SCRIPT_PARAM_ONOFF, true)
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
		Check()
		target = GetCustomTarget()
		Qtarget = ts.target
		if Config.Combo and Qtarget ~= nil then
			Combo(Qtarget)
		end

		if Config.Harass and Qtarget ~= nil then
			Harass(Qtarget)
		end

		if Config.Farm then
			Farm()
		end
	end
end

function OnWndMsg(msg,key)
	if key == string.byte("E") and msg == KEY_DOWN and EReady and Config.Extras.ExtendE then
		-- mark Q key is release
		if Config.Extras.Debug then
			print('E key override enabled')
		end 
		CastE()
	end
end


function Combo(Target)
	if QReady and Config.ComboSub.useQ then
		-- if Config.Extras.Debug then
		-- 	print('Cast Q called')
		-- end	
		CastQ(Target)
	end

	if WReady and Config.ComboSub.useW then
		CastW(Target)
	end

	if isPressedR and Config.ComboSub.lockR then
		--LockR(Target)
	end
end


function Harass(Target)
	if QReady and Config.HarassSub.useQ then
		CastQ(Target)
	end

	if WReady and Config.HarassSub.useW then
		CastW(Target)
	end
end

function CastQ(Target)
	EnemyMinions:update()
	-- print(CountEnemyNearPerson(Target,800))
	-- print(ValidTarget(Target, 1300))
	if ValidTarget(Target, 1300) and not Target.dead and GetDistance(Target) > 550 and GetDistance(Target) < SpellQ.ExtendedRange then
		local CastPosition = FindBestCastPosition(Target)
		if CastPosition ~= nil and GetDistance(CastPosition) < SpellQ.Range + 100 then
			CastSpell(_Q, CastPosition)
		end
		-- if Config.Extras.Debug then
		-- 	print('Returning CastQ2')
		-- end	
	elseif ValidTarget(Target, 1300) and not Target.dead and GetDistance(Target) < 550 and ShouldCast(Target) then
		-- if Config.Extras.Debug then
		-- 	print('Returning CastQ1')
		-- end		
		CastSpell(_Q, Target)
	end
end


function LockR(Target)
	if isPressedR then
		local _, _, TargetPos =  VP:GetLineCastPosition(enemy, SpellR.Delay, SpellR.Width, SpellR.Range, SpellR.Speed, myHero, false)
		local UnitVector1 = Vector(myHero) + Vector(REndPos):perpendicular()*650
		local UnitVector2 = Vector(myHero) + Vector(REndPos):perpendicular2()*650
		local pointSegment1, pointLine1, isOnSegment = VectorPointProjectionOnLineSegment(Vector(myHero), Vector(UnitVector1), Vector(TargetPos))
		local pointSegment2, pointLine2, isOnSegment2 = VectorPointProjectionOnLineSegment(Vector(myHero), Vector(UnitVector1), Vector(TargetPos))
		local pointSegment13D = {x=pointSegment1.x, y= myHero.y, z=pointSegment1.y}
		local pointSegment23D = {x=pointSegment2.x, y= myHero.y, z=pointSegment2.y}
		if GetDistance(pointLine23D) >= GetDistance(pointLine13D) then
			OrbwalkToPosition(pointLine13D)
		else
			OrbwalkToPosition(pointLine23D)
		end
	else
		OrbwalkToPosition(nil)
	end
end
function CastE()
	if EReady then
		local CastPoint = Vector(myHero) + Vector(Vector(mousePos) - Vector(myHero)):normalized()*445
		CastSpell(_E, CastPoint.x, CastPoint.z)
	end
end

function CastW(Target)
	if WReady and ShouldCast(Target) then
		local CastPoint, HitChance, pos =  VP:GetCircularCastPosition(Target, SpellW.Delay, SpellW.Width, SpellW.Range, SpellW.Speed, myHero, true)
		if GetDistance(CastPoint) < SpellW.Range and HitChance >= 1 then
			CastSpell(_W, CastPoint.x, CastPoint.z)
		end
	end
end

function Farm()
	EnemyMinions:update()
	if Config.FarmSub.useQ then
		FarmQ()
	end
	if Config.FarmSub.useW then
		FarmW()
	end
end

function GetEnemiesHitByQ(startpos, endpos)
	if startpos ~= nil and endpos ~= nil then
		local count = 0
		local HitMainTarget = false
		local Enemies = GetEnemyHeroes()
		--print(endpos)
		local realendpos = Vector(myHero) + Vector(Vector(endpos)-Vector(myHero)):normalized()*SpellQ.ExtendedRange
		if Config.Extras.Debug then
			print('Printing realendpos')
			print(realendpos)
		end
		for idx, enemy in ipairs(Enemies) do
			if enemy ~= nil and ValidTarget(enemy, 1600) and not enemy.dead and GetDistance(enemy, startpos) < SpellQ.ExtendedRange then
				local throwaway, HitChance, PredictedPos = VP:GetLineCastPosition(enemy, SpellQ.Delay, SpellQ.Width, SpellQ.ExtendedRange, SpellQ.Speed, myHero, false)
				local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(Vector(startpos), Vector(realendpos), Vector(PredictedPos))
				local pointSegment3D = {x=pointSegment.x, y=enemy.y, z=pointSegment.y}
				if isOnSegment and pointSegment3D ~= nil and GetDistance(pointSegment3D, PredictedPos) < VP:GetHitBox(enemy) + SpellQ.Width - 20 and HitChance >= 1 then
					count = count + 1
					if enemy.networkID == target.networkID then
						HitMainTarget = true
					end
				end
			end
		end
		if Config.Extras.Debug then
			print('Returning GetEnemiesByQ with ' .. tostring(count))
		end
		return count, HitMainTarget
	end
end

function FindBestCastPosition(Target)
	if QReady then
		if Config.Extras.Debug then
			print('FindBestCastPosition called')
		end

		if Config.Extras.Debug then
			print('EnemyMinions called ' .. tostring(#EnemyMinions.objects))
		end
		local Enemies = GetEnemyHeroes()
		local BestPosition = nil
		local BestHit = 0
		for idx, enemy in ipairs(Enemies) do
			if not enemy.dead and ValidTarget(enemy) and GetDistance(enemy) < SpellQ.Range then
				local position, hitchance = VP:GetPredictedPos(enemy, SpellQ.Delay, math.huge, myHero, false)
				--print(position)
				local count, hitmain = GetEnemiesHitByQ(myHero, position)
				if hitmain and hitchance >= 1 then 
					if count > BestHit then
						BestHit = count
						BestPosition = enemy
					end
				end
			end
		end
		if BestPosition ~= nil then
			return BestPosition
		end

		if #EnemyMinions.objects >= 1 then
			if Config.Extras.Debug then
				print('EnemyMinions called 2')
			end
			for i, minion in ipairs(EnemyMinions.objects) do
				if GetDistance(minion) < SpellQ.Range then
					local position, hitchance = VP:GetPredictedPos(minion, SpellQ.Delay, math.huge, myHero, false)
					-- local waypoints = VP:GetCurrentWayPoints(minion)
					-- local MPos, CastPosition = #waypoints == 1 and Vector(minion.visionPos) or VP:CalculateTargetPosition(minion, SpellQ.Delay, SpellQ.Width, SpellQ.Speed, myHero, "line")
					local count, hitmain = GetEnemiesHitByQ(myHero, Vector(position))
					
					if Config.Extras.Debug then
						print('Minions iterating ' .. tostring(count))
					end
					if hitmain and hitchance >= 1 and count > BestHit then
						BestHit = count
						BestPosition = minion
					end
				end
			end
		end
		if BestPosition ~= nil then
			return BestPosition
		end
	end
end

--Credit AWA

function KillSteal()
	local Enemies = GetEnemyHeroes()
	for i, enemy in pairs(Enemies) do
	if getDmg("Q", enemy, myHero)  > enemy.health and  Config.KS.useQ and GetDistance(enemy) < SpellQ.Range then
			CastQ(enemy)
		end
	if getDmg("W", enemy, myHero)  > enemy.health and  Config.KS.useW and GetDistance(enemy) < SpellW.Range then
			CastW(enemy)
		end
	end
end



function Reset(Target)
	if GetDistance(Target) > 600 then
		return true
	elseif _G.MMA_Loaded and _G.MMA_NextAttackAvailability < 0.6 then
		return true
	elseif _G.AutoCarry and (_G.AutoCarry.shotFired or _G.AutoCarry.Orbwalker:IsAfterAttack()) then 
		if Config.Extras.Debug then
			print('SAC shot fired')
		end
		return true
	else
		return false
	end
end

function OnDraw()
	if Config.Extras.Debug and Qtarget ~= nil then
		DrawText3D("Current IsPressedR status is " .. tostring(isPressedR), myHero.x+200, myHero.y, myHero.z+200, 25,  ARGB(255,255,0,0), true)
		DrawText3D("Current isBuffed status is " .. tostring(isBuffed), myHero.x, myHero.y, myHero.z, 25,  ARGB(255,255,0,0), true)
		DrawText3D("Current isReset status is " .. tostring(Reset(Qtarget)), myHero.x-100, myHero.y, myHero.z-100, 25,  ARGB(255,255,0,0), true)
		DrawText3D("Current ShouldCast status is " .. tostring(ShouldCast(Qtarget)), myHero.x-150, myHero.y, myHero.z-159, 25,  ARGB(255,255,0,0), true)
		DrawText3D("Current time since last cast is " .. tostring(GetTickCount() - LastSpellCast), myHero.x-250, myHero.y, myHero.z-259, 25,  ARGB(255,255,0,0), true)
		DrawCircle3D(Qtarget.x, Qtarget.y, Qtarget.z, 150, 1,  ARGB(255, 0, 255, 255))
	end

	if Config.Draw.DrawQ then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellQ.Range, 1,  ARGB(255, 0, 255, 255))
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellQ.ExtendedRange, 1,  ARGB(255, 0, 255, 255))
	end

	if Config.Draw.DrawW then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellW.Range, 1,  ARGB(255, 0, 255, 255))
	end
end

function OnGainBuff(unit, buff)
	if unit.isMe and buff.name == 'lucianpassivebuff' then
		isBuffed = true
	end

	if unit.isMe and buff.name == 'LucianR' then
		isPressedR = true
	end

	if unit.isMe and (buff.type == 5 or buff.type == 10 or buff.type == 11) and EReady and Config.Extras.ESlows then
		CastE()
	end
end

function OnLoseBuff(unit, buff)
	if unit.isMe and buff.name == 'lucianpassivebuff' then
		isBuffed = false
	end

	if unit.isMe and buff.name == 'LucianR' then
		isPressedR = true
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

function OnProcessSpell(unit, spell)
	if unit.isMe and spell.name == 'LucianQ' then
		LastSpellCast = GetTickCount()
	end

	if unit.isMe and spell.name == 'LucianW' then
		LastSpellCast = GetTickCount()
	end

	if unit.isMe and spell.name == 'LucianE' then
		LastSpellCast = GetTickCount()
	end

	if unit.isMe and spell.name == 'LucianR' then
		LastSpellCast = GetTickCount()
		RTempEndPos = {x=spell.endPos.x, y=myHero.y, z=spell.endPos.z}
		REndPos = Vector(Vector(RTempEndPos) - Vector(myHero)):normalized()
		isPressedR = true
	end
end

function ShouldCast(Target)
	if not isBuffed and Reset(Target) then
		return true
	else
		return false
	end
end


function Check()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
	if not RReady then
		QEndPos = nil
		LastDistance = nil
		isPressedR = false
		RendPos = nil
	end
end


function GetBestQPositionFarm()
	local MaxQ = 0 
	local MaxQPos 
	for i, minion in pairs(EnemyMinions.objects) do
		if GetDistance(minion) < SpellQ.Range then
			local hitQ = countminionshitQ(minion)
			if hitQ > MaxQ or MaxQPos == nil then
				MaxQPos = minion
				MaxQ = hitQ
			end
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
	local ExtendedVector = Vector(myHero) + Vector(Vector(pos) - Vector(myHero)):normalized()*SpellQ.ExtendedRange
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
		return MaxWPos
	else
		return nil
	end
end



function countminionshitW(pos)
	local n = 0
	for i, minion in ipairs(EnemyMinions.objects) do
		if GetDistance(minion, pos) < SpellW.Width then
			n = n +1
		end
	end
	return n
end


function FarmW()
	if WReady and #EnemyMinions.objects > 0 then
		local WPos = GetBestWPositionFarm()
		if WPos then
			CastSpell(_W, WPos.x, WPos.z)
		end
	end
end

function FarmQ()
	if QReady and #EnemyMinions.objects > 0 then
		local QPos = GetBestQPositionFarm()
		if QPos then
			CastSpell(_Q, QPos)
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
