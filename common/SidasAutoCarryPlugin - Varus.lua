--[[

Simple Varus


by Dienofal and lots of assistance from Kain


REBORN ONLY. VPREDICTION REQUIRED



Changelog


v0.01 - release


v0.02 - added Q itself as manual aim key as well. Commented out debug text


v0.03 - added toggle for only max range Qs. Small bug fixes


v0.03a - added mtmoon's suggested fixes to manual Q

]]


if myHero.charName ~= "Varus" then return end
class 'Plugin'
require 'VPrediction'


local HKX = string.byte("X")
local HKZ = string.byte("Z")
local HKC = string.byte("C")
local HKT = string.byte("T")
local KeySlowE = string.byte("E")
local CurrentMS = myHero.ms
local CurrentAS = myHero.attackSpeed
local Skills, Keys, Items, Data, Jungle, Helper, MyHero, Minions, Crosshair, Orbwalker = AutoCarry.Helper:GetClasses()
Crosshair:SetSkillCrosshairRange(2000)
PrintChat('Simple Varus by Dienofal and Kain loading')
if AutoCarry.Skills then IsSACReborn = true else IsSACReborn = false end
if IsSACReborn then AutoCarry.Skills:DisableAll() end
--PrintChat('Debug1')
local qmaxRange = 1600
local qminRange = 850
local qWidth = 55
local qSpeed = 1900
local qDelay = 500
local qChargeTime = 1500
local eRange = 1000
local eCastTime = 0.251
local eWidth = 240
local eDelay = 0.251
local eSpeed = 1500
local qRadius = 55
local eSpeed = 1400
local QREADY = false
local WREADY = false
local EREADY = false
local RREADY = false
local MovePoint = nil
local BlockQ = false
local time_difference = 0
local CurrentRange = 0
local isPressedQ = false   
local Qstartcasttime = 0
local Qcasttime = 0         
local ProcStacks = {}
local rRange = 1200
local Qlastcast = 0
local Qdifftime = 0 
local force2Q

for _, enemy in pairs(Helper.EnemyTable) do
	ProcStacks[enemy.networkID] = 0
end

SkillE = AutoCarry.Skills:NewSkill(false, _E, 1000, "Varus E", AutoCarry.SPELL_LINEAR, 0, false, false, 1.500, 266, 270, false)
SkillR = AutoCarry.Skills:NewSkill(false, _R, 1200, "Varus R", AutoCarry.SPELL_LINEAR, 0, false, false, 1.950, 251, 100, false)

if VIP_USER then 
	AdvancedCallback:bind('OnGainBuff', function(unit, buff) OnGainBuff(unit, buff) end)
    AdvancedCallback:bind('OnLoseBuff', function(unit, buff) OnLoseBuff(unit, buff) end)
    AdvancedCallback:bind('OnUpdateBuff', function(unit, buff) OnUpdateBuff(unit, buff) end)
end
--PrintChat('Debug2')

--ignite = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)
--PrintChat('Debug3')


function Plugin:__init()
VP = VPrediction()
Crosshair:SetSkillCrosshairRange(1600)
end

function Plugin:OnTick()
	--print(Qdifftime)
	Checks()
	UpdateQCasttime()
	CheckQCastTime()
	CurrentRange = ConvertQCastTime(Qcasttime)
	-- if TargetHaveBuff("varuswdebuff", Target) then
	-- 	print('Target have buff is functioning on ' .. tostring(Target.charName))
	-- end

	if Keys.AutoCarry and ValidTarget(Target) then
		if Menu.PrioritizeQ then
			if not isPressedQ then
        		Cast1stQTarget(Target)
        	else
				Cast2ndQTarget(Target)
			end
			if Qdifftime > 750 then
				CastE(Target)
			end
		else
			if Qdifftime > 750 then
				CastE(Target)
			end
			if not isPressedQ then
        		Cast1stQTarget(Target)
        	else
				Cast2ndQTarget(Target)
			end
		end

		if Menu.useR then
			CastR(Target)
		end

	end

	if isPressedQ and Menu.CastQManual then
		Send2ndQPacket(mousePos.x, mousePos.z)
	end

	--Credit to Chancey/Smart Nerdy
	if Menu.CastQHarass then
		local closestchamp = nil
		--print('Cast Q harass called')
        for _, champ in pairs(Helper.EnemyTable) do
                if closestchamp and closestchamp.valid and champ and champ.valid then
                        if GetDistance(champ, mousePos) < GetDistance(closestchamp, mousePos) then
                            closestchamp = champ
                        end
                else
                    closestchamp = champ
                end
        end
        if ValidTarget(closestchamp) and GetDistance(closestchamp, myHero) < 1600 and QREADY then
        	--print(closestchamp.name)
			if not isPressedQ then
        		Cast1stQTargetManual(Target)
        	else
        		if Menu.MaxRangeManualQ then
					if CurrentRange >= 1500 then
						Cast2ndQTargetManual(Target)
					end
				else
					Cast2ndQTargetManual(Target)
				end
			end
		end
	end

	--Slow E
	if Menu.SlowE then
		SlowClosestEnemy()
	end

	if Menu.CastRManual then
		--print('Cast R Manual called')
        for _, champ in pairs(Helper.EnemyTable) do
                if closestchamp and closestchamp.valid and champ and champ.valid then
                        if GetDistance(champ, mousePos) < GetDistance(closestchamp, mousePos) then
                            closestchamp = champ
                        end
                else
                    closestchamp = champ
                end
        end
        if ValidTarget(closestchamp) and GetDistance(closestchamp, myHero) < rRange and RREADY then
        	--print(closestchamp.name)
			SkillR:Cast(Target)
		end
	end
	if isPressedQ == false then force2Q = false end
	if force2Q == true and isPressedQ then
		if Target then
			Cast2ndQTargetManual(Target)
		else
			Send2ndQPacket(mousePos.x, mousePos.z)
		end
	end
end


--Credits to Kain
function SlowClosestEnemy()
	local closestEnemy = FindClosestEnemy()
	if closestEnemy == nil then return false end
	if EREADY and ValidTarget(closestEnemy, eRange) then
		if SkillE:Cast(Target) then return true end
	end
end
function FindClosestEnemy()
	local closestchamp = nil
	for _, champ in pairs(Helper.EnemyTable) do
	    if closestchamp and closestchamp.valid and champ and champ.valid then
	        if GetDistance(champ, mousePos) < GetDistance(closestchamp, mousePos) then
	            closestchamp = champ
	        end
	    else
	        closestchamp = champ
	    end
	end
	return closestchamp
end
function EnemyCount(point, range)
	local count = 0

	for _, enemy in pairs(Helper.EnemyTable) do
		if enemy and not enemy.dead and GetDistance(point, enemy) <= range then
			count = count + 1
		end
	end            

	return count
end

---End Credits to Kain



--Credit to mtmoon
function Plugin:OnWndMsg(msg,key)
	if key == string.byte("Q") and msg == KEY_UP then
		-- mark Q key is release
		force2Q = true
	end
end




function Plugin:OnDraw()
	--DrawText3D("Current isPressedQ status is " .. tostring(isPressedQ), myHero.x, myHero.y, myHero.z, 25,  ARGB(255,255,0,0), true)
	if isPressedQ then
		Helper:DrawCircleObject(myHero, CurrentRange, ARGB(255,255,0,0), 1)
		Helper:DrawCircleObject(QCastPosition, qRadius, ARGB(255,0,255,0), 3)
	end

	if Menu.DrawStacks then
		for i, enemy in pairs(AutoCarry.EnemyTable) do
			if ValidTarget(enemy, eRange) then
				if ProcStacks[enemy.networkID] > 0 then
					-- DrawCircle(enemy.x, enemy.y, enemy.z, (60+(20 * ProcStacks[enemy.networkID])), 0xFF0000)
					if ProcStacks[enemy.networkID] == 1 then
						DrawText3D("1", enemy.x, enemy.y, enemy.z, 35,  ARGB(255,255,0,0), true)
					elseif ProcStacks[enemy.networkID] == 2 then
						DrawText3D("2", enemy.x, enemy.y, enemy.z, 35,  ARGB(255,255,0,0), true)
					elseif ProcStacks[enemy.networkID] == 3 then
						DrawText3D("3", enemy.x, enemy.y, enemy.z, 35,  ARGB(255,255,0,0), true)
					end
				end
			end
		end
	end

end
function CheckQCastTime()
	if GetTickCount() - Qstartcasttime > 1450 then
		Qcasttime = 1450
	end
	if GetTickCount()- Qstartcasttime > 5000 then
		Qcasttime = 0
		isPressedQ = false
	end
end
function ConvertQCastTime()
	local range = 0
	if isPressedQ then 
		--PrintChat("Q is being updated!")
		range = 850
		if Qcasttime >= 1450 then
			range = 1600
		end
		if Qcasttime > 0 and Qcasttime < 1450 then
			--PrintChat("Middle calculation being done!")
			range = (Qcasttime / 2000)*1150 + 850
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
function IsMyManaLow()
	if myHero.mana < (myHero.maxMana * ( Menu.ManaManager / 100)) then
		return true
	else
		return false
	end
end

function OnGainBuff(unit, buff)
	if unit.isMe and (buff.name == 'varusqlaunch'or buff.name == 'VarusQ' or buff.name == 'varusqlaunchsound')  then
		--PrintChat("Gained")
		isPressedQ = true
		Qstartcasttime = GetTickCount()
		MyHero:AttacksEnabled(false)
	end

	if buff.name == 'varuswdebuff' and unit.team ~= myHero.team then
		ProcStacks[unit.networkID] = 1
	end
end

function OnUpdateBuff(unit, buff)
	if buff.name == 'varuswdebuff' then
		ProcStacks[unit.networkID] = buff.stack
	end
end

function OnLoseBuff(unit, buff)
	if unit.isMe and buff.name == 'VarusQ' then
		--PrintChat("Lost")
		isPressedQ  = false
		Qcasttime = 0
		MyHero:AttacksEnabled(true)
		Qlastcast = GetTickCount()
	end

	if buff.name == 'varuswdebuff' and unit.team ~= myHero.team then
		ProcStacks[unit.networkID] = 0
	end
end


function Plugin:OnSendPacket(packet)
	-- New handler for SAC: Reborn
	local p = Packet(packet)
	--if p:get("spellId") == SkillE.spellKey and not (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.LaneClear or AutoCarry.MainMenu.MixedMode or AutoCarry.PluginMenu.SlowE) then
		--p:block()
	--end
    if packet.header == 0xE5 and isPressedQ then --and Cast then -- 2nd cast of channel spells packet2
		packet.pos = 5
        spelltype = packet:Decode1()
        if spelltype == 0x80 then -- 0x80 == Q
            packet.pos = 1
            packet:Block()
            --PrintChat("Packet blocked")
        end
    end
    if packet.header == 0x99 and isPressedQ then --and Cast then -- 2nd cast of channel spells packet2
        packet:Block()
	end
end

function Cast1stQTarget(Target)
	if QREADY and ValidTarget(Target) and GetDistance(myHero, Target) < 1700 and not isPressedQ and ProcStacks[Target.networkID] >= Menu.CarryMinWForQ then
		local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, 0.500, qWidth, 1600, qSpeed, myHero)
		if HitChance > 0 then
			Packet("S_CAST", {spellId = _Q, x = CastPosition.x, y = CastPosition.z}):send()
			MyHero:AttacksEnabled(false)
			isPressedQ = true
		end
	end
end


function Cast1stQTargetManual(Target)
	if QREADY and ValidTarget(Target) and GetDistance(myHero, Target) < 1700 and not isPressedQ then
		local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, 0.500, qWidth, 1600, qSpeed, myHero)
		if HitChance > 0 and CastPosition ~= nil then
			Packet("S_CAST", {spellId = _Q, x = CastPosition.x, y = CastPosition.z}):send()
			MyHero:AttacksEnabled(false)
			isPressedQ = true
		end
	end
end

function Cast2ndQTargetManual(Target)
	if QREADY and ValidTarget(Target) and GetDistance(myHero, Target) < 1700 and isPressedQ and Qcasttime > Menu.QBuffer then
		QCastPosition, QHitChance, QPosition = VP:GetLineCastPosition(Target, 0.250, qWidth, CurrentRange, qSpeed, myHero)
		to_move_position = myHero + (Vector(QCastPosition) - myHero):normalized()*60 
		--print(to_move_position)
		if QCastPosition ~= nil and QHitChance > 1 and GetDistance(QCastPosition, myHero) < CurrentRange then
			MyHero:Move(to_move_position)
			--print('Move 1 to called at ' .. tostring(to_move_position))
			Send2ndQPacket(QCastPosition.x, QCastPosition.z)
			MyHero:AttacksEnabled(true)
			--print('Move 3 to called at ' .. tostring(to_move_position))
		end
	end
end




function Cast2ndQTarget(Target)
	if Target ~= nil and QREADY and ValidTarget(Target) and GetDistance(myHero, Target) < 1700 and isPressedQ and Qcasttime > Menu.QBuffer then
		QCastPosition, QHitChance, QPosition = VP:GetLineCastPosition(Target, 0.250, qWidth, CurrentRange, qSpeed, myHero)
		--to_move_position = myHero + (Vector(QCastPosition) - myHero):normalized()*60 
		--print(to_move_position)
		if (QCastPosition == nil or QHitChance == nil) then
			return
		end
		to_move_position = myHero + (Vector(QCastPosition) - myHero):normalized()*60 
		if QHitChance > 1 and GetDistance(QCastPosition, myHero) < CurrentRange then
			MyHero:Move(to_move_position)
			--print('Move 1 to called at ' .. tostring(to_move_position))
			Send2ndQPacket(QCastPosition.x, QCastPosition.z)
			MyHero:AttacksEnabled(true)
		elseif Qcasttime > Menu.QMaxBuffer/2 and QHitChance > 0 and GetDistance(QCastPosition, myHero) < CurrentRange then
			MyHero:Move(to_move_position)
			Send2ndQPacket(QCastPosition.x, QCastPosition.z)
			MyHero:AttacksEnabled(true)
			--print('Move 2 to called at ' .. tostring(to_move_position))
		elseif Qcasttime > Menu.QMaxBuffer and GetDistance(QCastPosition, myHero) < CurrentRange then
			MyHero:Move(to_move_position)
			Send2ndQPacket(QCastPosition.x, QCastPosition.z)
			MyHero:AttacksEnabled(true)
			--print('Move 3 to called at ' .. tostring(to_move_position))
		end
	end
end






function CastE(Target)
	--print('CastE called')
	if EREADY and ValidTarget(Target) and ProcStacks[Target.networkID] >= Menu.CarryMinWForE then
		if EnemyCount(Target, eWidth) > 1 then
			local spellPos = GetAoESpellPosition((eWidth / 2), Target, eDelay, eSpeed)
			--print(spellPos)
			if spellPos and GetDistance(spellPos, myHero) <= eRange then
				CastSpell(_E, spellPos.x, spellPos.z)
				--print('Trying to cast E2')
				return true
			end
		else
			--print('Trying to cast E1')
			SkillE:Cast(Target)
			return true
		end
	end
	return false
end

function CastR(Target)
	if not ValidTarget(Target) then end

	if RREADY and Target and not Target.dead and ValidTarget(Target, rRange) and GetAoEBounces(500, Target, 1, eSpeed) >= Menu.LastRbounces then
		--print('R being called')
		SkillR:Cast(Target)
	end
end


function Send2ndQPacket(xpos, zpos)
	--PrintChat("Packet Called!")
	packet = CLoLPacket(0xE5)
	packet:EncodeF(myHero.networkID)
	packet:Encode1(128)
	packet:EncodeF(xpos)
	packet:EncodeF(myHero.y)
	packet:EncodeF(zpos)
	packet.dwArg1 = 1
	packet.dwArg2 = 0
	SendPacket(packet)
	--PrintChat("Packet Sent!")
--nID, spell, x, y, z
end

function Checks()
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	WREADY = (myHero:CanUseSpell(_W) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY)
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then ignite = SUMMONER_2 end
	IGNITEReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
	if IsSACReborn then Target = AutoCarry.Crosshair:GetTarget() else Target = AutoCarry.GetAttackTarget() end
	Qdifftime = GetTickCount() - Qlastcast
end


function CalculateBonusQ(minion)
	local bonusDamage = getDmg("W", minion, myHero)
	--print('Bonus W damage called, with bonus damage of ' .. tostring(bonusDamage))
	if bonusDamage ~= nil then
		return bonusDamage
	end
end







---Begin AOE skill shot position ---

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

function GetPredictedInitialTargets(radius, main_target, delay, speed)
    --if VIP_USER and not vip_target_predictor then vip_target_predictor = TargetPredictionVIP(nil, nil, delay/1000) end
    local predicted_main_target = VP:GetPredictedPos(main_target, delay, speed, myHero)
    local predicted_targets = {predicted_main_target}
    local diameter_sqr = 4 * radius * radius
   
    for i=1, heroManager.iCount do
            target = heroManager:GetHero(i)
            if ValidTarget(target) then
                    predicted_target = VP:GetPredictedPos(target, delay, speed, myHero)
                    if target.networkID ~= main_target.networkID and GetDistanceSqr(predicted_main_target, predicted_target) < diameter_sqr then table.insert(predicted_targets, predicted_target) end
            end
    end
   
    return predicted_targets
end

-- I don´t need range since main_target is gonna be close enough. You can add it if you do.
function GetAoESpellPosition(radius, main_target, delay, speed)
    local targets = GetPredictedInitialTargets(radius, main_target, delay, speed)
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

function GetAoEBounces(radius, main_target, delay, speed)
	local targets = GetPredictedInitialTargets(radius, main_target, delay, speed)
	if targets ~= nil then 
		return #targets
	end
end
--- End AOE skill shot position









AutoCarry.Plugins:RegisterBonusLastHitDamage(CalculateBonusQ)
Menu = AutoCarry.Plugins:RegisterPlugin(Plugin(), "Varus") 
Menu:addParam("useQ", "Use (Q)", SCRIPT_PARAM_ONOFF, true)
Menu:addParam("useW", "Use (W)", SCRIPT_PARAM_ONOFF, true)
Menu:addParam("useE", "Use (E)", SCRIPT_PARAM_ONOFF, true)
Menu:addParam("useR", "Use (R)", SCRIPT_PARAM_ONOFF, true)
Menu:addParam("LastHitE", "Smart Last hit with E", SCRIPT_PARAM_ONOFF, true) -- Last hit with E
Menu:addParam("LastHitMinimumMinions", "Min minions for E last hit", SCRIPT_PARAM_SLICE, 2, 1, 10, 0) -- minion slider
Menu:addParam("CastQManual","Cancel Q to mouse cursor", SCRIPT_PARAM_ONKEYDOWN, false, HKX)
Menu:addParam("CastQHarass","Cast Q to target near mouse cursor", SCRIPT_PARAM_ONKEYDOWN, false, HKT)
Menu:addParam("CastRManual","Cast R to target near mouse cursor", SCRIPT_PARAM_ONKEYDOWN, false, HKZ)
Menu:addParam("SlowE", "Slow nearest enemy with E", SCRIPT_PARAM_ONKEYDOWN, false, KeySlowE)
Menu:addParam("ManaManager", "Mana Manager", SCRIPT_PARAM_SLICE, 0, 0, 100, 0)
Menu:addParam("CarryMinWForQ", "Min W to Q", SCRIPT_PARAM_SLICE, 3, 0, 3, 0) -- W stacks to Q
Menu:addParam("CarryMinWForE", "Min W to E", SCRIPT_PARAM_SLICE, 2, 0, 3, 0) -- W stacks to E
Menu:addParam("PrioritizeQ", "Priotize Q", SCRIPT_PARAM_ONOFF, true) -- W stacks to E
Menu:addParam("LastRbounces", "Min R bounces", SCRIPT_PARAM_SLICE, 0, 0, 3, 0)
Menu:addParam("DrawStacks", "Draw Blighted Quiver Stacks", SCRIPT_PARAM_ONOFF, true)
Menu:addParam("MaxRangeManualQ", "Max Range Only for Manual Q", SCRIPT_PARAM_ONOFF, true)
Menu:addParam("QBuffer", "Q minimum time buffer", SCRIPT_PARAM_SLICE, 100, 0, 500, 0)
Menu:addParam("QMaxBuffer", "Q maximum time buffer", SCRIPT_PARAM_SLICE, 1450, 500, 1450, 0)
