--[[

Xerath, Reworked!

by Dienofail

This is a SAC Reborn or Revamped Plugin, Prodiction required.

Your smart cast must be off for Q E and R, or rebind them. 

Manual Q and Spacebar must be HELD. 

v0.00 - release, alpha, very likely not functional. 

v0.00a - Pre-stable build: still likely non-functional. Code for killsteal, jungle farm, and lane clear added. 

v0.01 - core combo now functional. Jungle clear and wave clear unstable. 

v0.01a - core combo confirmed functional. Manual keys remapped. 

v0.02 - Jungle Clear and Wave Clear now functional. It will cast Q and W at minion nearest mouse position

]]
require "Prodiction"
require "Collision"
if myHero.charName ~= "Xerath" then return end
if AutoCarry.Skills then IsSACReborn = true else IsSACReborn = false end

if IsSACReborn then
	AutoCarry.Skills:DisableAll()
end
--Wall of prodiction objects incoming--
local Prod = ProdictManager.GetInstance()
local ProdQ1 = Prod:AddProdictionObject(_Q, 1400, 3000, 0.250, 45)
local ProdQ2 = Prod:AddProdictionObject(_Q, 1400, 3000, 0.750, 45)
local ProdW = Prod:AddProdictionObject(_W, 1100, math.huge, 0.620, 80)
local ProdE = Prod:AddProdictionObject(_E, 1050, 1400, 0.275, 50) 
local ProdR1 = Prod:AddProdictionObject(_R, 5600, math.huge, 0.550, 90) 
local ProdR2 = Prod:AddProdictionObject(_R, 5600, math.huge, 0.300, 0) 
local Col = Collision(1050, 1400, 0.266, 60)
local Qlastcast = 0
local Qdifftime = 0 
local Qcasttime = 0
local Qstartcasttime = 0
local isPressedQ = false 
local CurrentRange = 0
local QTick = 0
local Rstacks = 0
local isPressedR = false
local CurrentRRange = 0
local CurrentRLevel = 0
local RSafe = false
local spellExpired = false
local QRange = 1400
local WRange = 1100
local ERange = 1050
local HKX = string.byte("X")
local HKC = string.byte("C")
local HKZ = string.byte("Z")
local HKR = string.byte("R")
local HKE = string.byte("E")
local HKQ = string.byte("Q")
local HKJ = string.byte("J")
local HKW = string.byte("W")
local HKV = string.byte("V")
local KeyQ = string.byte("Q")
local allMinions = minionManager(MINION_ENEMY, 800, player, MINION_SORT_HEALTH_ASC)
local jungleMinions = minionManager(MINION_JUNGLE, 800, player, MINION_SORT_HEALTH_ASC)
local KSing = false
AutoCarry.PluginMenu:addParam("sep", "----- [ Core/Combo ] -----",  SCRIPT_PARAM_INFO, "")
AutoCarry.PluginMenu:addParam("JungleFarm", "Farm Jungle", SCRIPT_PARAM_ONKEYDOWN, false, HKJ)
AutoCarry.PluginMenu:addParam("LaneClear", "Lane Clear", SCRIPT_PARAM_ONKEYDOWN, false, HKV)
AutoCarry.PluginMenu:addParam("ManualQ", "Cast Q at target near cursor", SCRIPT_PARAM_ONKEYDOWN, false, HKZ)
AutoCarry.PluginMenu:addParam("ManualW", "Cast W at target near cursor", SCRIPT_PARAM_ONKEYDOWN, false, HKW)
AutoCarry.PluginMenu:addParam("ManualE", "Cast E at target near cursor", SCRIPT_PARAM_ONKEYDOWN, false, HKE)
AutoCarry.PluginMenu:addParam("ManualR", "Cast R at target near cursor", SCRIPT_PARAM_ONKEYDOWN, false, HKX)
AutoCarry.PluginMenu:addParam("UseRCombo", "Use R in Combo", SCRIPT_PARAM_ONOFF, true)
AutoCarry.PluginMenu:addParam("sep", "----- [ KS ] -----",  SCRIPT_PARAM_INFO, "")
AutoCarry.PluginMenu:addParam("UseRKS", "Use R KS", SCRIPT_PARAM_ONOFF, true)
AutoCarry.PluginMenu:addParam("RKSDistance", "R KS Maximum Distance", SCRIPT_PARAM_SLICE, 1500, 0, 5600, 0)
AutoCarry.PluginMenu:addParam("RKSHits", "R KS Hits", SCRIPT_PARAM_SLICE, 2, 1, 3, 0)
AutoCarry.PluginMenu:addParam("KillstealQ", "Use Q KS", SCRIPT_PARAM_ONOFF, true) -- KS with all skills
AutoCarry.PluginMenu:addParam("KillstealE", "Use E KS", SCRIPT_PARAM_ONOFF, true) -- KS with all skills
AutoCarry.PluginMenu:addParam("KillstealW", "Use W KS", SCRIPT_PARAM_ONOFF, true)
AutoCarry.PluginMenu:addParam("sep", "----- [ Misc ] -----",  SCRIPT_PARAM_INFO, "")
AutoCarry.PluginMenu:addParam("QMaxBuffer", "Q maximum time buffer", SCRIPT_PARAM_SLICE, 1500, 300, 1500, 0) -- Max time to hold Q
AutoCarry.PluginMenu:addParam("QBuffer", "Q minimum time buffer", SCRIPT_PARAM_SLICE, 100, 0, 500, 0)
AutoCarry.PluginMenu:addParam("EGapClosers", "E gap closers", SCRIPT_PARAM_ONOFF, false)
AutoCarry.PluginMenu:addParam("BlockRMovement", "Block movement packets during R", SCRIPT_PARAM_ONOFF, true)
AutoCarry.PluginMenu:addParam("FullRangeQ", "Full Range Manual Q only", SCRIPT_PARAM_ONOFF, false)
AutoCarry.PluginMenu:addParam("SafeRDistance", "Safe R Distance", SCRIPT_PARAM_SLICE, 600, 0, 2000, 0)
AutoCarry.PluginMenu:addParam("Debug", "Debug", SCRIPT_PARAM_ONOFF, false)
AutoCarry.PluginMenu:addParam("sep", "----- [ Draw ] -----",  SCRIPT_PARAM_INFO, "")
AutoCarry.PluginMenu:addParam("DrawR", "Draw R", SCRIPT_PARAM_ONOFF, false)
AutoCarry.PluginMenu:addParam("DrawQ", "Draw Q", SCRIPT_PARAM_ONOFF, false)
AutoCarry.PluginMenu:addParam("DrawE", "Draw E/W", SCRIPT_PARAM_ONOFF, false)
AutoCarry.PluginMenu:addParam("DrawQCurrent", "Draw Q Current", SCRIPT_PARAM_ONOFF, false)
AutoCarry.PluginMenu:addParam("sep", "----- [ Hitchances Coming Soon ] -----",  SCRIPT_PARAM_INFO, "")
if IsSACReborn then
	AutoCarry.Crosshair:SetSkillCrosshairRange(1600)
else
	AutoCarry.SkillsCrosshair.range = 1600
end

if VIP_USER then 
	AdvancedCallback:bind('OnGainBuff', function(unit, buff) OnGainBuff(unit, buff) end)
    AdvancedCallback:bind('OnLoseBuff', function(unit, buff) OnLoseBuff(unit, buff) end)
    AdvancedCallback:bind('OnUpdateBuff', function(unit, buff) OnUpdateBuff(unit, buff) end)
end

function PluginOnTick()
	-- if AutoCarry.PluginMenu.Debug then
	-- 	if IsKeyDown(KeyQ) then
	-- 		print('Key Q is down')
	-- 	elseif not IsKeyDown(KeyQ) then
	-- 		print('Key Q not down')
	-- 	end
	-- 	if IsKeyPressed(KeyQ) then
	-- 		print('Key Q is pressed')
	-- 	end
	-- end
	allMinions:update()
	jungleMinions:update()
	SpellCheck()
	UpdateQCasttime()
	CheckQCastTime()
	CurrentRange = ConvertQCastTime(Qcasttime)
	CheckRSafety()
	ClosestTarget = nil
	KillSteal()
	if ValidTarget(Target) and Target ~= nil then
		QCastPosition, QTime, QHitChance = ProdQ1:GetPrediction(Target)
		Q2CastPosition, Q2Time, Q2HitChance = ProdQ2:GetPrediction(Target)		
		-- print(QCastPosition)
		-- print(Q2CastPosition)
	end

	--Check for Q cancel
	-- if isPressedQ and (AutoCarry.MainMenu.AutoCarry == false and AutoCarry.PluginMenu.ManualQ == false and AutoCarry.MainMenu.MixedMode == false and AutoCarry.PluginMenu.JungleFarm == false and AutoCarry.PluginMenu.LaneClear == false) and not IsKeyDown(KeyQ) and not KSing then
	-- 	print(CurrentRange)
	-- 	if ValidTarget(Target) and GetDistance(Target) < CurrentRange then
	-- 		Cast2ndQTarget(Target)
	-- 	else
	-- 		Send2ndQPacket(mousePos.x, mousePos.z)
	-- 		if AutoCarry.PluginMenu.Debug then
	-- 			print('Sending 2nd Q cancel packet')
	-- 		end
	-- 	end
	-- end


	if AutoCarry.PluginMenu.ManualQ and ValidTarget(Target) and GetDistance(Target) < 1400 then
		if not isPressedQ then
			Cast1stQTargetManual(Target)
		elseif AutoCarry.PluginMenu.FullRangeQ and CurrentRange > 1380 and isPressedQ then
			Cast2ndQTargetManual(Target)
		elseif AutoCarry.PluginMenu.FullRangeQ == false and isPressedQ then
			Cast2ndQTargetManual(Target)
		end
	end

	if AutoCarry.MainMenu.AutoCarry and Target ~= nil then
		Combo()
	end

	if AutoCarry.MainMenu.MixedMode and Target ~= nil then
		Harass()
	end

	if AutoCarry.PluginMenu.LaneClear then
		LaneClear()
	end

	if AutoCarry.PluginMenu.ManualE then
		local closestchamp = nil

		--Chancey Credit
        for _, champ in pairs(AutoCarry.EnemyTable) do
            if closestchamp and closestchamp.valid and champ and champ.valid then
                if GetDistance(champ, mousePos) < GetDistance(closestchamp, mousePos) then
                    closestchamp = champ
                end
            else
                closestchamp = champ
            end
        end

        if closestchamp ~= nil and ValidTarget(closestchamp) and EReady then
        	CastE(closestchamp)
        end
    end

    if AutoCarry.PluginMenu.ManualR then
		local closestchamp = nil
		if AutoCarry.PluginMenu.Debug then
			print('Manual R called')
		end 
		--Chancey Credit
        for _, champ in pairs(AutoCarry.EnemyTable) do
            if closestchamp and closestchamp.valid and champ and champ.valid then
                if GetDistance(champ, mousePos) < GetDistance(closestchamp, mousePos) then
                    closestchamp = champ
                end
            else
                closestchamp = champ
            end
        end

        if closestchamp ~= nil and ValidTarget(closestchamp) and RReady then
        	CastR(closestchamp)
        	if AutoCarry.PluginMenu.Debug then
				print('Casting R at closestchamp')
			end
        end
    end

    if AutoCarry.PluginMenu.ManualW then
		local closestchamp = nil

		--Chancey Credit
        for _, champ in pairs(AutoCarry.EnemyTable) do
            if closestchamp and closestchamp.valid and champ and champ.valid then
                if GetDistance(champ, mousePos) < GetDistance(closestchamp, mousePos) then
                    closestchamp = champ
                end
            else
                closestchamp = champ
            end
        end

        if closestchamp ~= nil and ValidTarget(closestchamp) and WReady then
        	CastW(closestchamp)
        end
    end

	if AutoCarry.PluginMenu.JungleFarm then
		JungleFarm()
	end

	if AutoCarry.PluginMenu.UseRKS and RSafe then 
		RKS()
	end

	if isPressedR then
		if AutoCarry.PluginMenu.Debug then
			print('R alternative called with ' .. tostring(#AutoCarry.EnemyTable))
		end
		local lowestchamp = nil
		for _, champ in pairs(AutoCarry.EnemyTable) do
            if lowestchamp and lowestchamp.valid and lowestchamp and lowestchamp.valid and GetDistance(lowestchamp) < CurrentRRange then
                if GetDistance(champ) < CurrentRRange and champ.health < lowestchamp.health and not champ.dead then
                    lowestchamp = champ
                end
            else
                lowestchamp = champ
            end
		end

		if lowestchamp ~= nil and GetDistance(lowestchamp) < CurrentRRange then
			--CastR(lowestchamp)
			local RCastPosition, RTime, RHitChance = ProdR1:GetPrediction(lowestchamp)
			if AutoCarry.PluginMenu.Debug then
				print('R alternative champion found called with ' .. tostring(lowestchamp.charName))
			end
			if GetDistance(RCastPosition, myHero) < CurrentRRange then
				if RCastPosition ~= nil and RHitChance > 0.2 and GetDistance(RCastPosition, myHero) <= CurrentRRange then 
					if AutoCarry.PluginMenu.Debug then
						print('Cast R alternative called')
					end
					CastR(lowestchamp)
				end
			end
		end
	end

end

function PluginOnDraw()
	if AutoCarry.PluginMenu.Debug then
		DrawText3D("Current isPressedR status is " .. tostring(isPressedR), myHero.x, myHero.y, myHero.z, 25,  ARGB(255,255,0,0), true)
		DrawText3D("Current isPressedQ status is " .. tostring(isPressedQ), myHero.x+100, myHero.y+100, myHero.z+100, 25,  ARGB(255,255,0,0), true)
		DrawText3D("Current R Range is " .. tostring(CurrentRRange), myHero.x+200, myHero.y+200, myHero.z+200, 25,  ARGB(255,255,0,0), true)
	end

	if AutoCarry.PluginMenu.DrawR then
		DrawCircle(myHero.x, myHero.y, myHero.z, CurrentRRange, 0xFF0000)
	end
	if AutoCarry.PluginMenu.DrawQ then
		DrawCircle(myHero.x, myHero.y, myHero.z, 1400, 0x00FF00)
	end
	if AutoCarry.PluginMenu.DrawE then
		DrawCircle(myHero.x, myHero.y, myHero.z, 1000, 0x9933FF)
	end
	if AutoCarry.PluginMenu.DrawQCurrent then
		DrawCircle(myHero.x, myHero.y, myHero.z, CurrentRange, 0x0033FF)
	end
end



function Combo()
	CastE(Target)
	CastW(Target)
	CastQ(Target)
	if RReady and AutoCarry.PluginMenu.UseRCombo and ValidTarget(Target) and not isPressedQ then
		CastR(Target)
	end
end

function CastQ(Target)
	if QReady and ValidTarget(Target) and not isPressedR then
		if not isPressedQ then
			Cast1stQTarget(Target)
		else
			Cast2ndQTarget(Target)
		end
	end
end

function CastW(Target)
	if WReady and ValidTarget(Target) and not isPressedR and not isPressedQ then
		local WCastPosition, WTime, WHitchance = ProdW:GetPrediction(Target)
		if WCastPosition ~= nil and WHitchance ~= nil and GetDistance(WCastPosition, myHero) < 1100 and WHitchance > 0.40 then
			CastSpell(_W, WCastPosition.x, WCastPosition.z)
		end
	end
end

function CastE(Target)
	if EReady and ValidTarget(Target) and not isPressedR and not isPressedQ then
		local ECastPosition, ETime, EHitchance = ProdE:GetPrediction(Target)
		local WillCollide = Col:GetMinionCollision(myHero, ECastPosition)
		if ECastPosition ~= nil and WillCollide ~= nil and EHitchance ~= nil and GetDistance(ECastPosition, myHero) < 1050 and not WillCollide and EHitchance >= 0.4 then
			CastSpell(_E, ECastPosition.x, ECastPosition.z)
		end
	end

end

function Harass()
	if QReady and ValidTarget(Target) and GetDistance(Target) < 1400 then
		if not isPressedQ then
			Cast1stQTargetManual(Target)
		else
			Cast2ndQTargetManual(Target)
		end
	end
	if WReady and ValidTarget(Target) and not isPressedR and not isPressedQ then
		CastW(Target)
	end
end


function CheckRSafety()
	closestchamp = nil
	--Chancey Credit
    for _, champ in pairs(AutoCarry.EnemyTable) do
        if closestchamp and closestchamp.valid and champ and champ.valid then
            if GetDistance(champ, myHero) < GetDistance(closestchamp, myHero) then
                closestchamp = champ
            end
        else
            closestchamp = champ
        end
    end
	--End Chancey Credit
    if closestchamp ~= nil and GetDistance(closestchamp, myHero) > AutoCarry.PluginMenu.SafeRDistance then
    	RSafe = true
    else
    	RSafe = false
    end

end


function RKS()
	for _, champ in pairs(AutoCarry.EnemyTable) do
		if getDmg("R", champ, myHero) * AutoCarry.PluginMenu.RKSHits > champ.health and GetDistance(champ, myHero) < CurrentRRange and GetDistance(champ, myHero) < AutoCarry.PluginMenu.RKSDistance then
			local target = champ
			CastR(target)
		end
	end
end


function CastR(target)
	if target ~= nil and ValidTarget(target) then
		local ShouldRPosition, ShouldRTime, ShouldRHitchance = ProdR2:GetPrediction(target)
		local RCastPosition, RTime, RHitChance = ProdR1:GetPrediction(target)
		if ShouldRHitchance ~= nil and RCastPosition ~= nil and not isPressedR and not isPressedQ and RSafe and ShouldRHitchance > 0.4 then
			CastSpell(_R, RCastPosition.x, RCastPosition.z)
		elseif isPressedR then
			if GetDistance(RCastPosition, myHero) < CurrentRRange then
				if RCastPosition ~= nil and RHitChance > 0.2 and GetDistance(RCastPosition, myHero) <= CurrentRRange then 
					print('Cast R called')
					CastSpell(_R, RCastPosition.x, RCastPosition.z)
				end
			end
		end
	end
end


--Credit Kain
function QMovePos(target)
	--AutoCarry.CanMove = false
	local moveDistance = 100
	local targetDistance = GetDistance(target)
	movetoPos = { x = myHero.x + ((target.x - myHero.x) * (moveDistance) / targetDistance), z = myHero.z + ((target.z - myHero.z) * (moveDistance) / targetDistance)}
	myHero:MoveTo(movetoPos.x, movetoPos.z)
end
--End Credit Kain

function Cast1stQTarget(Target)
	--print('Cast1stQTarget called! with ' .. tostring(Q2HitChance) .. ' ' .. tostring(Q2CastPosition.x) .. ' ' .. tostring(Q2CastPosition.z))
	if QReady and ValidTarget(Target) and not isPressedQ and Q2HitChance ~= nil and Q2CastPosition ~= nil then
		if Q2HitChance > 0.10 and GetDistance(Q2CastPosition, myHero) < 1400 then
			--Packet("S_CAST", {spellId = _Q, x = Q2CastPosition.x, y = Q2CastPosition.z}):send()
			CastSpell(_Q, Q2CastPosition.x, Q2CastPosition.z)
			isPressedQ = true
		    AutoCarry.CanAttack = false
		end
	end
end

function Cast2ndQTarget(Target)
	if QCastPosition ~= nil and QHitChance ~= nil then
		if AutoCarry.PluginMenu.Debug then
		    print('Cast2ndQTarget called! with ' .. tostring(QHitChance) .. ' ' .. tostring(QCastPosition.x) .. ' ' .. tostring(QCastPosition.z) .. ' ' ..tostring(AutoCarry.CanAttack))
		end
		if QReady and ValidTarget(Target) and 1400 >= GetDistance(myHero, Target) and isPressedQ and Qcasttime >= AutoCarry.PluginMenu.QBuffer then
			--to_move_position = myHero + (Vector(QCastPosition) - myHero):normalized()*10 
			--print(to_move_position)
			if QHitChance > 0.45 and GetDistance(QCastPosition, myHero) < CurrentRange then
				QMovePos(Target)
				--print('Move 1 to called at ' .. tostring(to_move_position))
				Send2ndQPacket(QCastPosition.x, QCastPosition.z)
				AutoCarry.CanAttack = true
			elseif Qcasttime >= AutoCarry.PluginMenu.QMaxBuffer/2 and QHitChance >= 0.15 and GetDistance(QCastPosition, myHero) < CurrentRange then
				QMovePos(Target)
				Send2ndQPacket(QCastPosition.x, QCastPosition.z)
				AutoCarry.CanAttack = true
				--print('Move 2 to called at ' .. tostring(to_move_position))
			elseif Qcasttime >= AutoCarry.PluginMenu.QMaxBuffer and GetDistance(QCastPosition, myHero) < CurrentRange then
				QMovePos(Target)
				Send2ndQPacket(QCastPosition.x, QCastPosition.z)
				AutoCarry.CanAttack = true
				--print('Move 3 to called at ' .. tostring(to_move_position))
			end
		end
	end
end


function Cast1stQTargetManual(Target)
	--print('Cast1stQTargetManual called!')
	if QReady and ValidTarget(Target) and not isPressedQ and Q2HitChance ~= nil and Q2CastPosition ~= nil then
		if Q2HitChance > 0.40 and GetDistance(Q2CastPosition, myHero) < 1400 then
			--Packet("S_CAST", {spellId = _Q, x = Q2CastPosition.x, y = Q2CastPosition.z}):send()
			CastSpell(_Q, Q2CastPosition.x, Q2CastPosition.z)
			isPressedQ = true
			AutoCarry.CanAttack = false
		end
	end
end

function Cast2ndQTargetManual(Target)
	--print('Cast2ndQTargetManual called!')
	if QReady and ValidTarget(Target) and GetDistance(myHero, Target) < 1400 and isPressedQ then
		--print(to_move_position)
		if QHitChance > 0.50 and GetDistance(QCastPosition, myHero) < CurrentRange then
			QMovePos(Target)
			--print('Move 1 to called at ' .. tostring(to_move_position))
			Send2ndQPacket(QCastPosition.x, QCastPosition.z)
			AutoCarry.CanAttack = true
			--print('Move 3 to called at ' .. tostring(to_move_position))
			if AutoCarry.PluginMenu.Debug then
			    print('Cast2ndManualQTarget called! with ' .. tostring(QHitChance) .. ' ' .. tostring(QCastPosition.x) .. ' ' .. tostring(QCastPosition.z) .. ' ' ..tostring(AutoCarry.CanAttack))
			end
		end
	end
end

function Send2ndQPacket(xpos, zpos)
	--PrintChat("Packet Called!")
	if isPressedQ then
		packet = CLoLPacket(0xE6)
		packet:EncodeF(myHero.networkID)
		packet:Encode1(128)
		packet:EncodeF(xpos)
		packet:EncodeF(myHero.y)
		packet:EncodeF(zpos)
		packet.dwArg1 = 1
		packet.dwArg2 = 0
		SendPacket(packet)
	end
	--PrintChat("Packet Sent!")
--nID, spell, x, y, z
end


function CheckQCastTime()
	if GetTickCount() - Qstartcasttime > 1500 then
		Qcasttime = 1500
	end
	if GetTickCount()- Qstartcasttime > 3000 then
		Qcasttime = 0
		isPressedQ = false
		AutoCarry.CanAttack = true
		--AutoCarry.CanMove = true
	end
end

function ConvertQCastTime()
	local range = 0
	if isPressedQ then 
		--PrintChat("Q is being updated!")
		range = 750
		if Qcasttime >= 1500 then
			range = 1400
		end
		if Qcasttime > 0 and Qcasttime < 1500 then
			--PrintChat("Middle calculation being done!")
			range = (Qcasttime / 1500)*650 + 750
			--PrintChat("middle calculation result " .. tostring(range))
		end
		return range
	else
		return 0
	end
end


function UpdateQCasttime()
	if isPressedQ then
		Qcasttime = GetTickCount() - Qstartcasttime
	end
	if not isPressedQ then
		Qcasttime = 0
	end
end

function OnGainBuff(unit, buff)
	if unit.isMe and (buff.name == 'xerathqlaunch'or buff.name == 'XerathQ' or buff.name == 'xerathqlaunchsound' or buff.name == 'XerathArcanopulseChargeUp')  then
		--PrintChat("Gained")
		isPressedQ = true
		Qstartcasttime = GetTickCount()
	end
	if unit.isMe and (buff.name == 'XerathLocusOfPower2' or buff.name == 'xerathrshots') then
		--PrintChat("Gained")
		isPressedR = true
		Rstacks = buff.stack
		AutoCarry.CanAttack = false
		--AutoCarry.CanMove = false
	end
end

function OnUpdateBuff(unit, buff)
	if unit.isMe and buff.name == 'xerathrshots' then
		--PrintChat("Gained")
		Rstacks = buff.stack
	end
end


function JungleFarm()
	if AutoCarry.PluginMenu.Debug then
		print('Jungle Farm called')
	end

	local closestmob = nil
	for index, mob in ipairs(jungleMinions.objects) do
		if ValidTarget(closestmob) and closestmob.valid and GetDistance(closestmob, myHero) < 800 and closestmob.team ~= myHero.team then
			if GetDistance(mob, mousePos) < GetDistance(closestmob, mousePos) then
				closestmob = mob
			end
		else 
			closestmob = mob
		end
	end
	if closestmob ~= nil and GetDistance(closestmob, myHero) < 750 then
		if AutoCarry.PluginMenu.Debug then
		    print('Minion Found')
		end
		if QReady then
			if not isPressedQ then
				CastSpell(_Q, closestmob.x, closestmob.z)
			else
				Send2ndQPacket(closestmob.x, closestmob.z)
			end
		end
		if WReady then
			CastW(closestmob)
		end

	end
	--myHero:Attack(TargetJungleMob)
end

function LaneClear()
	if AutoCarry.PluginMenu.Debug then
		print('Lane Clear called')
	end

	--chancey/kain
	local closestmob = nil
	for index, mob in ipairs(allMinions.objects) do
		if ValidTarget(closestmob) and closestmob.valid and GetDistance(closestmob, myHero) < 800 and closestmob.team ~= myHero.team then
			if GetDistance(mob, mousePos) < GetDistance(closestmob, mousePos) then
				closestmob = mob
			end
		else 
			closestmob = mob
		end
	end


	if closestmob ~= nil and GetDistance(closestmob, myHero) < 750 then
		if AutoCarry.PluginMenu.Debug then
		    print('Minion Found')
		end
		if QReady then
			if not isPressedQ then
				CastSpell(_Q, closestmob.x, closestmob.z)
			else
				Send2ndQPacket(closestmob.x, closestmob.z)
			end
		end
		if WReady then
			CastW(closestmob)
		end

	end


end


function KillSteal()
	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if ValidTarget(enemy, QRange) and AutoCarry.PluginMenu.KillstealQ and getDmg("Q", enemy, myHero) > enemy.health then
			CastQ(Target)
			KSing = true
		else
			KSing = false
		end

		if ValidTarget(enemy, WRange) and AutoCarry.PluginMenu.KillStealW and getDmg("W", enemy, myHero) >= enemy.health then
			CastW(Target)
		end

		if ValidTarget(enemy,ERange) and AutoCarry.PluginMenu.KillStealE and getDmg("E", enemy, myHero) >= enemy.health then
			CastE(Target)
		end
	end
end


function OnLoseBuff(unit, buff)
	if unit.isMe and (buff.name == 'XerathQ' or buff.name == 'XerathArcanopulseChargeUp'  or buff.name == 'xerathqlaunchsound') then
		--PrintChat("Lost")
		isPressedQ  = false
		Qcasttime = 0
		QTick = GetTickCount()
		AutoCarry.CanAttack = true
		--AutoCarry.CanMove = true
	end
	if unit.isMe and (buff.name == 'XerathLocusOfPower2' or buff.name == 'xerathrshots') then
		--PrintChat("Gained")
		isPressedR = false
		Rstacks = 0
		AutoCarry.CanAttack = true
		--AutoCarry.CanMove = true
	end
end


function PluginOnSendPacket(packet)
	-- New handler for SAC: Reborn
	local p = Packet(packet)
	--if p:get("spellId") == SkillE.spellKey and not (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.LaneClear or AutoCarry.MainMenu.MixedMode or AutoCarry.PluginMenu.SlowE) then
		--p:block()
	--end
    if packet.header == 0xE6 and isPressedQ and not IsKeyDown(KeyQ) then --and Cast then -- 2nd cast of channel spells packet2
		packet.pos = 5
        spelltype = packet:Decode1()
        if spelltype == 0x80 then -- 0x80 == Q
            packet.pos = 1
            packet:Block()
            if AutoCarry.PluginMenu.Debug then
            	PrintChat("Packet 0xE6 blocked")
            end
        end
    end
    if packet.header == 0x9A then --and Cast then -- 2nd cast of channel spells packet2
        if isPressedQ then
	        packet:Block()
	        if AutoCarry.PluginMenu.Debug then
	        	PrintChat("Packet 0x99 blocked")
	        end
    	end

    	if isPressedR then
	        result = {
	            dwArg1 = packet.dwArg1,
	            dwArg2 = packet.dwArg2,
	            sourceNetworkId = packet:DecodeF(),
	            spellId = packet:Decode1(),
	            fromX = packet:DecodeF(),
	            fromY = packet:DecodeF(),
	            toX = packet:DecodeF(),
	            toY = packet:DecodeF(),
	            --targetNetworkId = p:DecodeF()
	        }

	        if result.spellId ~= 0x83 then
	        	if AutoCarry.PluginMenu.Debug then
	        		PrintChat("Packet 0x83 blocked")
	        	end
	        end
    	end

	end



	if packet.header == 0x71 and isPressedR and AutoCarry.PluginMenu.BlockRMovement then
        packet:Block()
        if AutoCarry.PluginMenu.Debug then
        	PrintChat("Packet 0x71 blocked")
        end
	end
end

function PluginOnProcessSpell(unit, spell)
	if AutoCarry.PluginMenu.EGapClosers then
	    local jarvanAddition = unit.charName == "JarvanIV" and unit:CanUseSpell(_Q) ~= READY and _R or _Q -- Did not want to break the table below.
	    local isAGapcloserUnit = {
	--        ['Ahri']        = {true, spell = _R, range = 450,   projSpeed = 2200},
	        ['Aatrox']      = {true, spell = _Q,                  range = 1000,  projSpeed = 1200, },
	        ['Akali']       = {true, spell = _R,                  range = 800,   projSpeed = 2200, }, -- Targeted ability
	        ['Alistar']     = {true, spell = _W,                  range = 650,   projSpeed = 2000, }, -- Targeted ability
	        ['Diana']       = {true, spell = _R,                  range = 825,   projSpeed = 2000, }, -- Targeted ability
	        ['Gragas']      = {true, spell = _E,                  range = 600,   projSpeed = 2000, },
	        ['Hecarim']     = {true, spell = _R,                  range = 1000,  projSpeed = 1200, },
	        ['Irelia']      = {true, spell = _Q,                  range = 650,   projSpeed = 2200, }, -- Targeted ability
	        ['JarvanIV']    = {true, spell = jarvanAddition,      range = 770,   projSpeed = 2000, }, -- Skillshot/Targeted ability
	        ['Jax']         = {true, spell = _Q,                  range = 700,   projSpeed = 2000, }, -- Targeted ability
	        ['Jayce']       = {true, spell = 'JayceToTheSkies',   range = 600,   projSpeed = 2000, }, -- Targeted ability
	        ['Khazix']      = {true, spell = _E,                  range = 900,   projSpeed = 2000, },
	        ['Leblanc']     = {true, spell = _W,                  range = 600,   projSpeed = 2000, },
	        ['LeeSin']      = {true, spell = 'blindmonkqtwo',     range = 1300,  projSpeed = 1800, },
	        ['Leona']       = {true, spell = _E,                  range = 900,   projSpeed = 2000, },
	        ['Malphite']    = {true, spell = _R,                  range = 1000,  projSpeed = 1500 + unit.ms},
	        ['Maokai']      = {true, spell = _Q,                  range = 600,   projSpeed = 1200, }, -- Targeted ability
	        ['MonkeyKing']  = {true, spell = _E,                  range = 650,   projSpeed = 2200, }, -- Targeted ability
	        ['Pantheon']    = {true, spell = _W,                  range = 600,   projSpeed = 2000, }, -- Targeted ability
	        ['Poppy']       = {true, spell = _E,                  range = 525,   projSpeed = 2000, }, -- Targeted ability
	        --['Quinn']       = {true, spell = _E,                  range = 725,   projSpeed = 2000, }, -- Targeted ability
	        ['Renekton']    = {true, spell = _E,                  range = 450,   projSpeed = 2000, },
	        ['Sejuani']     = {true, spell = _Q,                  range = 650,   projSpeed = 2000, },
	        ['Shen']        = {true, spell = _E,                  range = 575,   projSpeed = 2000, },
	        ['Tristana']    = {true, spell = _W,                  range = 900,   projSpeed = 2000, },
	        ['Tryndamere']  = {true, spell = 'Slash',             range = 650,   projSpeed = 1450, },
	        ['XinZhao']     = {true, spell = _E,                  range = 650,   projSpeed = 2000, }, -- Targeted ability
	    }
	    if unit.type == 'obj_AI_Hero' and unit.team == TEAM_ENEMY and isAGapcloserUnit[unit.charName] and GetDistance(unit) < 2000 and spell ~= nil then
	        if spell.name == (type(isAGapcloserUnit[unit.charName].spell) == 'number' and unit:GetSpellData(isAGapcloserUnit[unit.charName].spell).name or isAGapcloserUnit[unit.charName].spell) then
	            if spell.target ~= nil and spell.target.name == myHero.name or isAGapcloserUnit[unit.charName].spell == 'blindmonkqtwo' then
					----print('Gapcloser: ',unit.charName, ' Target: ', (spell.target ~= nil and spell.target.name or 'NONE'), " ", spell.name, " ", spell.projectileID)
	        		if not isPressedR and not isPressedQ and EReady then
	        			CastSpell(_E, spell.endPos.x, spell.endPos.z)
	        			print('Trying to dodge gapclosing spell ' .. tostring(spell.name) .. ' with E!')
	        		end
	            else
	                spellExpired = false
	                informationTable = {
	                    spellSource = unit,
	                    spellCastedTick = GetTickCount(),
	                    spellStartPos = Point(spell.startPos.x, spell.startPos.z),
	                    spellEndPos = Point(spell.endPos.x, spell.endPos.z),
	                    spellRange = isAGapcloserUnit[unit.charName].range,
	                    spellSpeed = isAGapcloserUnit[unit.charName].projSpeed
	                }
	            end
	        end
	    end
	end
end

function SpellCheck()
	if IsSACReborn then Target = AutoCarry.Crosshair:GetTarget() else Target = AutoCarry.GetAttackTarget() end
	current_R = myHero:GetSpellData(_R)
	CurrentRLevel = current_R.level
	if CurrentRLevel == 1 then
		CurrentRRange = 3200
	elseif CurrentRLevel == 2 then
		CurrentRRange = 4400 
	elseif CurrentRLevel == 3 then
		CurrentRRange = 5600
	end
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
end


---Start AOESkillShotPosition by Monogato--
function GetCenter(points)
	local sum_x = 0
	local sum_z = 0
	
	for i = 1, #points do
		sum_x = sum_x + points[i].x
		sum_z = sum_z + points[i].z
	end
	
	local center = {x = sum_x / #points, y = 0, z = sum_z / #points}
	
	return center
end

function ContainsThemAll(circle, points)
	local radius_sqr = circle.radius*circle.radius
	local contains_them_all = true
	local i = 1
	
	while contains_them_all and i <= #points do
		contains_them_all = GetDistanceSqr(points[i], circle.center) <= radius_sqr
		i = i + 1
	end
	
	return contains_them_all
end

-- The first element (which is gonna be main_target) is untouchable.
function FarthestFromPositionIndex(points, position)
	local index = 2
	local actual_dist_sqr
	local max_dist_sqr = GetDistanceSqr(points[index], position)
	
	for i = 3, #points do
		actual_dist_sqr = GetDistanceSqr(points[i], position)
		if actual_dist_sqr > max_dist_sqr then
			index = i
			max_dist_sqr = actual_dist_sqr
		end
	end
	
	return index
end

function RemoveWorst(targets, position)
	local worst_target = FarthestFromPositionIndex(targets, position)
	
	table.remove(targets, worst_target)
	
	return targets
end

function GetInitialTargets(radius, main_target)
	local targets = {main_target}
	local diameter_sqr = 4 * radius * radius
	
	for i=1, heroManager.iCount do
		target = heroManager:GetHero(i)
		if target.networkID ~= main_target.networkID and ValidTarget(target) and GetDistanceSqr(main_target, target) < diameter_sqr then table.insert(targets, target) end
	end
	
	return targets
end

function GetPredictedInitialTargets(radius, main_target, delay)
	-- VIP_USER and not vip_target_predictor then vip_target_predictor = TargetPredictionVIP(nil, nil, delay/1000) end
	local predicted_main_target, time, hitchance = ProdW:GetPrediction(main_target)
	local predicted_targets = {predicted_main_target}
	local diameter_sqr = 4 * radius * radius
	
	for i=1, heroManager.iCount do
		target = heroManager:GetHero(i)
		if ValidTarget(target) then
			predicted_target, time, hitchance = ProdW:GetPrediction(target)
			if target.networkID ~= main_target.networkID and GetDistanceSqr(predicted_main_target, predicted_target) < diameter_sqr then table.insert(predicted_targets, predicted_target) end
		end
	end
	
	return predicted_targets
end

-- I don't need range since main_target is gonna be close enough. You can add it if you do.
function GetAoESpellPosition(radius, main_target, delay)
	local targets = GetPredictedInitialTargets(radius, main_target, delay)
	local position = GetCenter(targets)
	local best_pos_found = true
	local circle = Circle(position, radius)
	circle.center = position
	
	if #targets > 2 then best_pos_found = ContainsThemAll(circle, targets) end
	
	while not best_pos_found do
		targets = RemoveWorst(targets, position)
		position = GetCenter(targets)
		circle.center = position
		best_pos_found = ContainsThemAll(circle, targets)
	end
	
	return position
end
