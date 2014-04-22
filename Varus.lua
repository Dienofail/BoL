local version = "0.05"
--[[

Free Varus!

by Dienofail and Kain, with assistance from Andreluis034

Changelog:

v0.01 - release

v0.02 - Now uses DFG along with ult (manual and auto)

v0.03 - Bug fixes to E closest enemy. Changed default map for E closest enemy as well

v0.04 - small fixes

]]
if myHero.charName ~= "Varus" then return end
require 'VPrediction'

--Honda7
local autoupdateenabled = true
local UPDATE_SCRIPT_NAME = "Varus"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/Dienofail/BoL/master/Varus.lua"
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

local enemyTable
local HKX = string.byte("X")
local HKZ = string.byte("Y")
local HKC = string.byte("C")
local HKT = string.byte("T")
local KeySlowE = string.byte("Z")
local CurrentMS = myHero.ms
local CurrentAS = myHero.attackSpeed
--local Skills, Keys, Items, Data, Jungle, Helper, MyHero, Minions, Crosshair, Orbwalker = AutoCarry.Helper:GetClasses()
--Crosshair:SetSkillCrosshairRange(2000)
PrintChat('Simple Varus by Dienofal and Kain loading')
--if AutoCarry.Skills then IsSACReborn = true else IsSACReborn = false end
--if IsSACReborn then AutoCarry.Skills:DisableAll() end
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
local rRange = 800
local Qlastcast = 0
local Qdifftime = 0 
local force2Q
local loaded = false
local dfgSlot, dfgReady = nil, false


--SkillE = AutoCarry.Skills:NewSkill(false, _E, 1000, "Varus E", AutoCarry.SPELL_LINEAR, 0, false, false, 1.500, 266, 270, false)
--SkillR = AutoCarry.Skills:NewSkill(false, _R, 1200, "Varus R", AutoCarry.SPELL_LINEAR, 0, false, false, 1.950, 251, 100, false)
--PrintChat('Debug2')

--ignite = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)
--PrintChat('Debug3')


function OnLoad()
	Menu()
	VP = VPrediction()
	enemyTable = GetEnemyHeroes()
	--Crosshair:SetSkillCrosshairRange(1600)
	for i, enemy in pairs(enemyTable) do
		ProcStacks[enemy.networkID] = 0
	end
	if _G.MMA_Loaded then
		loaded = true
	else
		DelayAction(delayed, 10)
	end
end

-- To make sure no error because SAC takes 9001 years to load
function delayed()
	PrintChat("Simple Varus Script now fully loaded with SAC")
	loaded = true
	SACloaded = true
	Skills, Keys, Items, Data, Jungle, Helper, MyHero, Minions, Crosshair, Orbwalker = AutoCarry.Helper:GetClasses()
end

function OnTick()
	--print(Qdifftime)
	Checks()
	UpdateQCasttime()
	CheckQCastTime()
	CurrentRange = ConvertQCastTime(Qcasttime)
	-- if TargetHaveBuff("varuswdebuff", Target) then
	-- 	print('Target have buff is functioning on ' .. tostring(Target.charName))
	-- end

	if Menu.combo.combo and ValidTarget(Target) then
		if Menu.wsettings.PrioritizeQ then
			if not isPressedQ and Menu.combo.useQ then
        		Cast1stQTarget(Target)
        	elseif Menu.combo.useQ then
				Cast2ndQTarget(Target)
			end
			if (not QREADY or not Menu.combo.useQ) and Menu.combo.useE then
				CastE(Target)
			end
		else 
			CastE(Target)
			if not isPressedQ and Menu.combo.useQ then
        		Cast1stQTarget(Target)
        	elseif Menu.combo.useQ then
				Cast2ndQTarget(Target)
			end
		end

		if Menu.combo.useR and ProcStacks[Target.networkID] > 2  then
			CastR(Target)
		end

	end

	if isPressedQ and Menu.qsettings.CastQManual then
		Send2ndQPacket(mousePos.x, mousePos.z)
	end

	--Credit to Chancey/Smart Nerdy
	if Menu.qsettings.CastQHarass then
		local closestchamp = nil
		--print('Cast Q harass called')
        for _, champ in pairs(enemyTable) do
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
        		Cast1stQTargetManual(closestchamp)
        	else
        		if Menu.qsettings.MaxRangeManualQ then
					if CurrentRange >= 1550 then
						Cast2ndQTargetManual(closestchamp)
					end
				else
					Cast2ndQTargetManual(closestchamp)
				end
			end
		end
	end

	--Slow E
	if Menu.esettings.SlowE then
		SlowClosestEnemy()
	end

	if Menu.rsettings.CastRManual then
		--print('Cast R Manual called')
        for _, champ in pairs(enemyTable) do
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
			CastR(closestchamp)
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
	if closestEnemy == nil then return end
	if EREADY and ValidTarget(closestEnemy, eRange) then
		local AOECastPosition, MainTargetHitChance, nTargets = VP:GetCircularAOECastPosition(closestEnemy, 0.5, (eWidth/2), eRange, 1500, myHero)
		CastSpell(_E, AOECastPosition.x, AOECastPosition.z)
	end
end

function FindClosestEnemy()
	local closestchamp = nil
	for _, champ in pairs(enemyTable) do
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

	for _, enemy in pairs(enemyTable) do
		if enemy and not enemy.dead and GetDistance(point, enemy) <= range then
			count = count + 1
		end
	end            

	return count
end

---End Credits to Kain



--Credit to mtmoon
function OnWndMsg(msg,key)
	if key == string.byte("Q") and msg == KEY_UP then
		-- mark Q key is release
		force2Q = true
	end
end




function OnDraw()
	--DrawText3D("Current isPressedQ status is " .. tostring(isPressedQ), myHero.x, myHero.y, myHero.z, 25,  ARGB(255,255,0,0), true)
	if isPressedQ then
		DrawCircle(myHero.x,myHero.y,myHero.z, CurrentRange, ARGB(255,255,0,0))
		--DrawCircle(QCastPosition.x,QCastPosition.y,QCastPosition.z, qRadius, ARGB(255,0,255,0))
	end

	if Menu.wsettings.DrawStacks then
		for i, enemy in pairs(enemyTable) do
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
		if SACloaded then 
			MyHero:AttacksEnabled(false)
		end
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

		if SACloaded then 
			MyHero:AttacksEnabled(true)
		else
			_G.MMA_ResetAutoAttack()
		end

		Qlastcast = GetTickCount()
	end

	if buff.name == 'varuswdebuff' and unit.team ~= myHero.team then
		ProcStacks[unit.networkID] = 0
	end
end


function OnSendPacket(packet)
	-- New handler for SAC: Reborn
	local p = Packet(packet)
	--if p:get("spellId") == SkillE.spellKey and not (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.LaneClear or AutoCarry.MainMenu.MixedMode or AutoCarry.PluginMenu.esettings.SlowE) then
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
	if QREADY and ValidTarget(Target) and GetDistance(myHero, Target) < 1700 and not isPressedQ and ProcStacks[Target.networkID] >= Menu.wsettings.CarryMinWForQ then
		local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, 0.500, qWidth, 1600, qSpeed, myHero)
		if HitChance > 0 then
			Packet("S_CAST", {spellId = _Q, x = CastPosition.x, y = CastPosition.z}):send()
			if SACloaded then 
				MyHero:AttacksEnabled(false)
			end
			isPressedQ = true
		end
	end
end


function Cast1stQTargetManual(Target)
	if QREADY and ValidTarget(Target) and GetDistance(myHero, Target) < 1700 and not isPressedQ then
		local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, 0.500, qWidth, 1600, qSpeed, myHero)
		if HitChance > 0 and CastPosition ~= nil then
			Packet("S_CAST", {spellId = _Q, x = CastPosition.x, y = CastPosition.z}):send()
			if SACloaded then
				MyHero:AttacksEnabled(false)
			end	
			isPressedQ = true
		end
	end
end

function Cast2ndQTargetManual(Target)
	if QREADY and ValidTarget(Target) and GetDistance(myHero, Target) < 1700 and isPressedQ and Qcasttime > Menu.qsettings.QBuffer then
		QCastPosition, QHitChance, QPosition = VP:GetLineCastPosition(Target, 0.250, qWidth, CurrentRange, qSpeed, myHero)
		to_move_position = myHero + (Vector(QCastPosition) - myHero):normalized()*60 
		--print(to_move_position)
		if QCastPosition ~= nil and QHitChance > 1 and GetDistance(QCastPosition, myHero) < CurrentRange then
			--MyHero:Move(to_move_position)
			--print('Move 1 to called at ' .. tostring(to_move_position))
			Send2ndQPacket(QCastPosition.x, QCastPosition.z)
			if SACloaded then 
				MyHero:AttacksEnabled(true)
			else
				_G.MMA_ResetAutoAttack()
			end
			--print('Move 3 to called at ' .. tostring(to_move_position))
		end
	end
end




function Cast2ndQTarget(Target)
	if Target ~= nil and QREADY and ValidTarget(Target) and GetDistance(myHero, Target) < 1700 and isPressedQ and Qcasttime > Menu.qsettings.QBuffer then
		QCastPosition, QHitChance, QPosition = VP:GetLineCastPosition(Target, 0.250, qWidth, CurrentRange, qSpeed, myHero)
		--to_move_position = myHero + (Vector(QCastPosition) - myHero):normalized()*60 
		--print(to_move_position)
		if (QCastPosition == nil or QHitChance == nil) then
			return
		end
		to_move_position = myHero + (Vector(QCastPosition) - myHero):normalized()*60 
		if QHitChance > 1 and GetDistance(QCastPosition, myHero) < CurrentRange then
			--MyHero:Move(to_move_position)
			--print('Move 1 to called at ' .. tostring(to_move_position))
			Send2ndQPacket(QCastPosition.x, QCastPosition.z)
			if SACloaded then 
				MyHero:AttacksEnabled(true)
			else
				_G.MMA_ResetAutoAttack()
			end
		elseif Qcasttime > Menu.qsettings.QMaxBuffer/2 and QHitChance > 0 and GetDistance(QCastPosition, myHero) < CurrentRange then
			--myHero:Move(to_move_position)
			Send2ndQPacket(QCastPosition.x, QCastPosition.z)
			if SACloaded then 
				MyHero:AttacksEnabled(true)
			else
				_G.MMA_ResetAutoAttack()
			end
			--print('Move 2 to called at ' .. tostring(to_move_position))
		elseif Qcasttime > Menu.qsettings.QMaxBuffer and GetDistance(QCastPosition, myHero) < CurrentRange then
			--MyHero:Move(to_move_position)
			Send2ndQPacket(QCastPosition.x, QCastPosition.z)
			if SACloaded then 
				MyHero:AttacksEnabled(true)
			else
				_G.MMA_ResetAutoAttack()
			end
			--print('Move 3 to called at ' .. tostring(to_move_position))
		end
	end
end



function CastE(Target)
	--print('CastE called')
	if EREADY and ValidTarget(Target) and ProcStacks[Target.networkID] >= Menu.wsettings.CarryMinWForE and GetTickCount() - Qlastcast > 500 then
		local AOECastPosition, MainTargetHitChance, nTargets = VP:GetCircularAOECastPosition(Target, 0.5, (eWidth/2), eRange, 1500, myHero)
		CastSpell(_E, AOECastPosition.x, AOECastPosition.z)
	end
end

function CastR(Target)
	if RREADY and Target and not Target.dead and ValidTarget(Target, rRange) then
		CastDFG(Target)
		local  CastPosition,  HitChance,  Position = VP:GetLineCastPosition(Target, 0.5, 100, 800, 1500, myHero, false)
		if HitChance < 2  then return end
			CastSpell(_R, CastPosition.x, CastPosition.z)
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
	IGNITEReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then 
		ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
		ignite = SUMMONER_2 
	end
	if loaded then
		if _G.MMA_Loaded then
			Target = _G.MMA_Target
		else Target = AutoCarry.Crosshair:GetTarget()
		end
	end
	dfgSlot = GetInventorySlotItem(3128)
	dfgReady = (dfgSlot ~= nil and myHero:CanUseSpell(dfgSlot) == READY)
end


function CalculateBonusQ(minion)
	local bonusDamage = getDmg("W", minion, myHero)
	--print('Bonus W damage called, with bonus damage of ' .. tostring(bonusDamage))
	if bonusDamage ~= nil then
		return bonusDamage
	end
end

function CastDFG(Target)
	if Target ~= nil and dfgReady and GetDistance(Target) < 750 then
		CastSpell(dfgSlot, Target)
	end
end



function Menu()
	Menu = scriptConfig("Varus", "Varus")
	Menu:addSubMenu("Combo Settings", "combo")
		Menu.combo:addParam("combo", "Combo key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
		Menu.combo:addParam("useQ", "Use (Q)", SCRIPT_PARAM_ONOFF, true)
		--Menu.combo:addParam("useW", "Use (W)", SCRIPT_PARAM_ONOFF, true)
		Menu.combo:addParam("useE", "Use (E)", SCRIPT_PARAM_ONOFF, true)
		Menu.combo:addParam("useR", "Use (R)", SCRIPT_PARAM_ONOFF, false)
	--Menu:addParam("LastHitE", "Smart Last hit with E", SCRIPT_PARAM_ONOFF, true) -- MMA Last hit with E Not ImplementedW
	--Menu:addParam("LastHitMinimumMinions", "Min minions for E last hit", SCRIPT_PARAM_SLICE, 2, 1, 10, 0) -- minion slider, MMA Not Implemented
	Menu:addSubMenu("Q Settings", "qsettings")
		Menu.qsettings:addParam("CastQManual","Cancel Q to mouse cursor", SCRIPT_PARAM_ONKEYDOWN, false, HKX)
		Menu.qsettings:addParam("CastQHarass","Cast Q to target near mouse cursor", SCRIPT_PARAM_ONKEYDOWN, false, HKT)
		Menu.qsettings:addParam("MaxRangeManualQ", "Max Range Only for Manual Q", SCRIPT_PARAM_ONOFF, true)
		Menu.qsettings:addParam("QBuffer", "Q minimum time buffer", SCRIPT_PARAM_SLICE, 100, 0, 500, 0)
		Menu.qsettings:addParam("QMaxBuffer", "Q maximum time buffer", SCRIPT_PARAM_SLICE, 1450, 500, 1450, 0)
	Menu:addSubMenu("W Settings", "wsettings")
		Menu.wsettings:addParam("CarryMinWForQ", "Min W to Q", SCRIPT_PARAM_SLICE, 3, 0, 3, 0) -- W stacks to Q
		Menu.wsettings:addParam("CarryMinWForE", "Min W to E", SCRIPT_PARAM_SLICE, 2, 0, 3, 0) -- W stacks to E
		Menu.wsettings:addParam("PrioritizeQ", "Priotize Q", SCRIPT_PARAM_ONOFF, true) -- W stacks to E
		Menu.wsettings:addParam("DrawStacks", "Draw Blighted Quiver Stacks", SCRIPT_PARAM_ONOFF, true)
	Menu:addSubMenu("E Settings", "esettings")
		Menu.esettings:addParam("SlowE", "Slow nearest enemy with E", SCRIPT_PARAM_ONKEYDOWN, false, KeySlowE)
	Menu:addSubMenu("R Settings", "rsettings")
		Menu.rsettings:addParam("CastRManual","Cast R to target near mouse cursor", SCRIPT_PARAM_ONKEYDOWN, false, HKZ)
		Menu.rsettings:addParam("LastRbounces", "Min R bounces", SCRIPT_PARAM_SLICE, 0, 0, 3, 0)
	Menu:addParam("ManaManager", "Mana Manager", SCRIPT_PARAM_SLICE, 0, 0, 100, 0)	

end
