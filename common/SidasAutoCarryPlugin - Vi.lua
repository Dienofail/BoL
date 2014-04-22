local version = "0.09"
--[[
Changelog

v0.01 - release

v0.02 - jungle farm and manual Q added

v0.03 - Q cancel added (default button = 'C')

v0.04 - Ward casting bug fixed

v0.05 - Revamped support added

v0.06 - Changed manual Q logic slightly. MAKE SURE YOU HOLD THE BUTTON FOR AIM.

v0.07 - Added failsafes for enemy going out of range, should now cast if enemy goes back into range while Q is charging (if they were initially out of range)

v0.08 - now will use E when killable and not wait for a reset.

v0.09 - autoupdater
]]--


if myHero.charName ~= "Vi" then return end
local AUTOUPDATE = true
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/Dienofail/BoL/master/common/SidasAutoCarryPlugin%20-%20Vi.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = LIB_PATH.."SidasAutoCarryPlugin - Vi.lua"
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>SAC VI:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
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
				DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () AutoupdaterMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end)	 
			else
				AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
			end
		end
	else
		AutoupdaterMsg("Error downloading version info")
	end
end
require "Collision"
require "VPrediction"

function PluginOnLoad()
	--Menu
	mainLoad()
	mainMenu()
end
    
function CastSpellQ1(posx, posz)
	if myHero:CanUseSpell(_Q) == READY then
		if not isPressedQ then
			--CastSpell(_Q, x, z)
			Packet("S_CAST", {spellId = _Q, x = posx, y = posz}):send()
			qTick = GetTickCount()
			--PrintChat("Cast phase 1")
		end
	end
end


function CastSpellQ2(x, y)
	if isPressedQ then
		qTick = GetTickCount()
		--PrintChat("2nd phase called")
		Send2ndQPacket(x, y)
	end
end

function CheckQstatus()
	if isPressedQ then
		--PrintChat('Q is pressed Q current casttime is ' .. tostring(Qcasttime) .. ' Qstart time is ' .. tostring(Qstartcasttime))
	end
end

function CheckQCastTime()
	if os.clock() - Qstartcasttime > 1.250 then
		Qcasttime = 1.250
	end
	if os.clock() - Qstartcasttime > 5 then
		Qcasttime = 0
		isPressedQ = false
	end
end

function ConvertQCastTime()
	if isPressedQ then 
		--PrintChat("Q is being updated!")
		range = 250
		if Qcasttime < 0.250 then
			range = 250
		end
		if Qcasttime > 1.250 then
			range = 715
		end
		if Qcasttime > 0.250 and Qcasttime < 1.250 then
			--PrintChat("Middle calculation being done!")
			range = (Qcasttime - 0.250 / 1.250)*465 + 250
			--PrintChat("middle calculation result " .. tostring(range))
		end
		return range
	end
end

function UpdateQCasttime()
	if isPressedQ then
		Qcasttime = os.clock() - Qstartcasttime
	end
	if not isPressedQ then
		Qcasttime = 0
	end
end

function PluginOnTick()
	Checks()
	UpdateQCasttime()
	CheckQCastTime()
	CheckQstatus()
	JungleClear()
	CurrentRange = ConvertQCastTime(Qcasttime)
	if Menu.manualQ then
		--PrintChat('Current range is ' .. tostring(CurrentRange))
		CastSpellQ1(myHero.x, myHero.z)
	end


	if Target and Menu.manualQ and ValidTarget(Target) and isPressedQ then
		--print('Manual q part 2 getting called')
		local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, 0.483, 55, CurrentRange, qSpeed, myHero, false)
		if GetDistance(CastPosition) < CurrentRange and HitChance > 0 then
			CastSpellQ2(CastPosition.x, CastPosition.z)
		end 
	end

	--PrintChat(tostring(isPressedQ))
	if Menu.CancelQ then
		local CastPosition, HitChance, Position = nil
		if ValidTarget(Target) then
			CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, 0.483, 55, CurrentRange, qSpeed, myHero, false)
		end
		if CastPosition ~= nil and GetDistance(CastPosition) < CurrentRange and ValidTarget(Target) then
			CastSpellQ2(CastPosition.x, CastPosition.z)
		else
			CastSpellQ2(mousePos.x, mousePos.z)
		end
	end



	if Target and AutoCarry.MainMenu.AutoCarry then
		if getDmg("E", Target, myHero) > Target.health and EREADY and GetDistance(Target) < 250 then
			CastSpell(_E, Target)
		end

		if not isPressedQ then
			local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, 1, 55, 725, qSpeed, myHero)
			if QREADY and GetDistance(CastPosition) < 700 and GetDistance(Target) > Menu.qdistance and HitChance > 1 then
				CastSpellQ1(CastPosition.x, CastPosition.z)
			end
		end
		if isPressedQ then
			--PrintChat('2nd part ready')
			local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, 0.483, 55, CurrentRange, qSpeed, myHero)
			--PrintChat(tostring(HitChance) .. ' ' .. tostring(CastPosition.x) .. ' ' .. tostring(CastPosition.z))
			if GetDistance(CastPosition) < CurrentRange and HitChance > 0 then
				CastSpellQ2(CastPosition.x, CastPosition.z)
			end
		end
		--if QREADY and Menu.useQ and GetDistance(Target) < 800 and GetDistance(Target) > 300 and not isPressedQ and AutoCarry.MainMenu.AutoCarry and Qcasttime == 0 then
			--print("Debug")
			--PrintChat('Calculating Q')
			--calculating delay = sample every value from 0 --> 500 ms
			--[[for i=0, qtotalcasttime, 10 do
				current_range = (qmaxRange - qminRange)/ (i/qtotalcasttime) 
				current_range = current_range + qminRange
				current_cast_time = i + 250 / 1000
				CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, current_cast_time, 55, current_range, qSpeed)
				if HitChance > min_hit_chance then
					CastSpell(_Q, CastPosition.x, CastPosition.z)
					CastSpell(10)
				end
			end]]
			--CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, current_cast_time, 55, current_range, qSpeed)
			--CastSpell(_Q, Target.x, Target.z)
			--isPressedQ = true
		--end

		--if isPressedQ then
			--print("Debug2")
			--[[PrintChat(tostring(Qcasttime))
			--check to see if current cast time and position intersects with enemy vector
			if Qcasttime > qtotalcasttime then
				Qcasttime = qtotalcasttime
			else 
				Qcasttime = os.clock() - Qstarttime
			end
			print("Debug3")
			current_range = qminRange + Qcasttime*(qmaxRange-qminRange/qtotalcasttime)
			CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, 0.250, 55, current_range, qSpeed)
			if HitChance > min_hit_chance then
				Qshouldcast = true
				PrintChat("Sending packet")
				Send2ndQPacket(myHero.networkID, CastPosition.x, CastPosition.z)
			end]]
		--else
			--Qshouldcast = false
		--end
		if RREADY and Menu.useR and GetDistance(Target) < rRange and AutoCarry.MainMenu.AutoCarry and Menu.useRfirst then
			CastSpell(_R, Target)
		end 
		if RREADY and GetDistance(Target) < rRange and killsteal and GetDmg("R", Target, myHero) > Target.health then
			CastSpell(_R, Target)
		end 
		if AutoCarry.MainMenu.AutoCarry and EREADY and GetDistance(Target) < eRange and Menu.useE then
			if IsSACReborn then
				SkillE:Cast(Target)
			else
				AutoCarry.CastSkillshot(SkillE, Target)
			end
		end 
	end

	if isPressedQ and not AutoCarry.MainMenu.AutoCarry and not Menu.manualQ and ValidTarget(Target, 800) and not IsKeyDown(KeyQ) then
		local CastPosition, HitChance, Position = nil
		if ValidTarget(Target) then
			CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, 0.483, 55, CurrentRange, qSpeed, myHero)
		end
		if CastPosition ~= nil and GetDistance(CastPosition) < CurrentRange and ValidTarget(Target) then
			CastSpellQ2(CastPosition.x, CastPosition.z)
		else
			CastSpellQ2(mousePos.x, mousePos.z)
		end	
	end
end

function JungleClear()
	if IsSACReborn then
		JungleMob = AutoCarry.Jungle:GetAttackableMonster()
	else
		JungleMob = AutoCarry.GetMinionTarget()
	end
	if JungleMob ~= nil then
		if Menu.JungleKey and GetDistance(JungleMob) < 250 then 
			AutoCarry.Orbwalker:Orbwalk(JungleMob)
			if IsSACReborn then
				SkillE:Cast(JungleMob)
			else
				AutoCarry.CastSkillshot(SkillE, JungleMob)
			end
			if QREADY and not isPressedQ then
				CastSpell(_Q, JungleMob.x, JungleMob.z)
			end
			if isPressedQ then
				CastSpell(_Q, JungleMob.x, JungleMob.z)
			end
		end
	end
end


function mainLoad()
	VP = VPrediction()
	if AutoCarry.Skills then IsSACReborn = true else IsSACReborn = false end
	if IsSACReborn then AutoCarry.Skills:DisableAll() end
	Carry = AutoCarry.MainMenu
	min_hit_chance = 1
	Menu = AutoCarry.PluginMenu
	qtotalcasttime = 400 --not sure about this value yet
	qmaxRange = 715
	qminRange = 250
	qWidth = 55
	qSpeed = 1500
	eRange = 300
	rRange = 800
	QREADY = false
	EREADY = false
	RREADY = false
	isPressedQ = false
	Qcasttime = 0 
	Qstartcasttime = 0 
	Qbeingcast = false
	Qshouldcast = false
	invisibleTime   = 300
	Qstarttime = 0
	buffer = 0
	qTick = 0
	if IsSACReborn then
		SkillE = AutoCarry.Skills:NewSkill(false, _E, qRange, "Vi E", AutoCarry.SPELL_TARGETED, 0, true, true, math.huge, 240, 0, 0)
	else
		SkillE = {spellKey = _E, range = 250, speed = math.huge, delay = 0, width = 0, configName = "ViE", displayName = "ViE", enabled = true, skillShot = false, minions = true, reset = true, reqTarget = true }
	end
	ignite = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)
	PrintChat("Sidas Autocarry Vi Plugin by Dienofail loaded v0.09")
	if VIP_USER then 
		AdvancedCallback:bind('OnGainBuff', function(unit, buff) OnGainBuff(unit, buff) end)
	    AdvancedCallback:bind('OnLoseBuff', function(unit, buff) OnLoseBuff(unit, buff) end)
	    AdvancedCallback:bind('OnCreateObj', function(unit, buff) OnCreateObj(unit, buff) end)
	    AdvancedCallback:bind('OnDeleteObj', function(unit, buff) OnDeleteObj(unit, buff) end)
	end
	if IsSACReborn then
		AutoCarry.Crosshair:SetSkillCrosshairRange(900)
	else
		AutoCarry.SkillsCrosshair.range = 900
	end -- Set the spell target selector range
end

function mainMenu()
	HKC = string.byte("T")
	HKX = string.byte("X")
	HKV = string.byte("C")
	KeyQ = string.byte("Q")
	Menu:addParam("useQ", "Use (Q)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useE", "Use (E)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useR", "Use (R)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useRfirst", "Use (R) first", SCRIPT_PARAM_ONOFF, false)
	Menu:addParam("qdistance", "Use (Q) Chase Distance", SCRIPT_PARAM_SLICE, 150, 0, 715, 150)
	Menu:addParam("killsteal", "Kill Steal with R", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("drawQ", "Draw (Q)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("drawR", "Draw (R)", SCRIPT_PARAM_ONOFF, true)
	--Menu:addParam("manualQ", "Q PREDICTION KEY", SCRIPT_PARAM_ONKEYDOWN, false, )
	Menu:addParam("manualQ","Manual Cast Q (YOU MUST HOLD THIS)", SCRIPT_PARAM_ONKEYDOWN, false, HKC)
	Menu:addParam("JungleKey","Jungle Clear", SCRIPT_PARAM_ONKEYDOWN, false, HKX)
	Menu:addParam("CancelQ","Emergency Release Q", SCRIPT_PARAM_ONKEYDOWN, false, HKV)
end

function OnGainBuff(unit, buff)
	if unit.isMe and buff.name == 'ViQ' then
		--PrintChat("Gained")
		isPressedQ = true
		Qstartcasttime = os.clock()
	end
end

function OnLoseBuff(unit, buff)
	if unit.isMe and buff.name == 'ViQ' then
		--PrintChat("Lost")
		isPressedQ  = false
		Qcasttime = 0
	end
end


--[[function OnCreateObj(object)
    if object.name == "Vi_Q_Channel_L.troy" then 
    	iPressedQ = true 
    	PrintChat("Object Gained")
    	Qstarttime = os.clock()
    	Qcasttime = 0
    end
end]]

function PluginOnDeleteObj(object)
    if object.name == "Vi_Q_Channel_L.troy" then 
    	iPressedQ = false 
    	Qcasttime = 0
    end
end
    
--Copied from  
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


function PluginOnSendPacket(packet)
	-- New handler for SAC: Reborn
	local p = Packet(packet)
	--if p:get("spellId") == SkillE.spellKey and not (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.LaneClear or AutoCarry.MainMenu.MixedMode or AutoCarry.PluginMenu.SlowE) then
		--p:block()
	--end
	if Menu.CancelQ == false then 
	    if packet.header == 0xE5 and AutoCarry.MainMenu.AutoCarry then --and Cast then -- 2nd cast of channel spells packet2
			packet.pos = 5
	        spelltype = packet:Decode1()
	        if spelltype == 0x80 then -- 0x80 == Q
	            packet.pos = 1
	            packet:Block()
	            --PrintChat("Packet blocked")
	        end
	    end


	    if packet.header == 0xE5 and isPressedQ and Menu.manualQ then --and Cast then -- 2nd cast of channel spells packet2
			packet.pos = 5
	        spelltype = packet:Decode1()
	        if spelltype == 0x80 then -- 0x80 == Q
	            packet.pos = 1
	            packet:Block()
	            --PrintChat("Packet blocked")
	        end
	    end
	end
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

end
