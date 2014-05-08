local version = "0.08"
--[[


FREE ELISE 

BY DIENOFAIL

CHANGELOG

v0.01 - RELEASE


v0.02 - Improved Human E usage in combo, added options for using E before swapping. Added draw options


v0.02a - Added packets for human E.


v0.03 - Added VPrediction for human E, added auto updater. 

v0.04 - added vprediction requirement

v0.05 - Fixes for v81 reborn

v0.06 - Github

v0.07 - Changed default jump distance

v0.08 - fixes to rappel
]]--
require "Prodiction"
require "Collision"
require "VPrediction"
if myHero.charName ~= "Elise" then return end
local AUTOUPDATE = true
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/Dienofail/BoL/master/common/SidasAutoCarryPlugin%20-%20Elise.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = LIB_PATH.."SidasAutoCarryPlugin - Elise.lua"
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>SAC ELISE:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
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

------------------------
if AutoCarry.Skills then IsSACReborn = true else IsSACReborn = false end
if IsSACReborn then
	AutoCarry.Skills:DisableAll()
end
if IsSACReborn then
	SkillE = AutoCarry.Skills:NewSkill(false, _E, 975, "Elise E", AutoCarry.SPELL_LINEAR_COL, 0, false, false, 1.45, 250, 70, true)
else
	SkillE = {spellKey = _E, range = 975, speed = 1.45, delay = 250, width = 70, configName = "Elise E", displayName = "Elise E", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = false }
end

--if IsSACReborn then AutoCarry.Skills:DisableAll() end
--local Prodict = ProdictManager.GetInstance()
local VP = VPrediction()
-- local ProdictE = Prodict:AddProdictionObject(_E, 975, 1450, 0.250, 70)
local Col = Collision(975, 1450, 0.250, 70)
-- local ProdictSpiderE = Prodict:AddProdictionObject(_E, 1100, math.huge, 0.250, 0)
-- local ProdictSpiderE2 = Prodict:AddProdictionObject(_E, 1100, math.huge, 0.250, 0)
-- local ProdictW = Prodict:AddProdictionObject(_W, 950, 800, 0.250, 120)
local isSpider = false
local isRappel = false
local RappelTimer = 0
local RappelStartTimer = 0
local RappelMaxTimer = 2000 
local SpiderQcd, SpiderWcd, SpiderEcd = 0, 0, 0
local HumanQcd, HumanWcd, HumanEcd = 0, 0, 0
local HumanQready, HumanWready, HumanEready = false, false, false
local SpiderQready, SpiderWready, SpiderEready = false, false, false
local EliseRready = nil
local isSafe = true
local QBuffer = false
local Target
local HumanSkillQ = {spellkey = _Q, range = 625, speed = math.huge, delay = 250, width = 0}
local HumanSkillE = {spellkey = _E, range = 1075, speed = 130, delay = 151.5, width = 70}
local HumanSkillW = {spellkey = _W, range = 950, speed = math.huge, delay = 300, width = 0}
local SpiderSkillQ = {spellkey = _Q, range = 475, speed = math.huge, delay = 250, width = 0}
local SpiderSkillW = {spellkey = _W, range = math.huge, speed = math.huge, delay = 250, width = 0}
local SpiderSkillE = {spellkey = _E, range = 1000 ,speed = math.huge, delay = 250, width = 0}
local HumanTrueQcd, SpiderTrueQcd = 6000, 6000
local HumanTrueWcd, SpiderTrueWcd = 12000, 12000
local HumanTrueEcd = {14000, 13000, 12000, 11000, 10000}
local SpiderTrueEcd = {26000, 24000, 22000, 20000, 18000}
local RTruecd = 4000
local Rcd = 0
local range = 800
local RReady = nil
local KeyV = string.byte("V")
local KeyX = string.byte("X")
local KeyC = string.byte("C")
local KeyN = string.byte("N")
local KSoverride = false
local HumanReady, HumanCombatReady, SpiderReady, SpiderCombatReady = false, false, false, false
local Vilemaw,Nashor,Dragon,Golem1,Golem2,Lizard1,Lizard2 = nil,nil,nil,nil,nil,nil,nil
--Smite from BotHappy--
local SmiteSlot = nil
local SmiteDamage, CanUseSmite = nil, false
local JungleMobs = {}
local JungleFocusMobs = {}
local informationTable = {}
local spellExpired = true
local allMinions = minionManager(MINION_ALL, SpiderSkillE.range, player, MINION_SORT_HEALTH_ASC)
local qDamage = 0
local ECastPosition, ETime, EHitChance = nil, nil, nil
local GlobalEDelay = 250
if IsSACReborn then
	AutoCarry.Crosshair:SetSkillCrosshairRange(1100)
else
	AutoCarry.SkillsCrosshair.range = 1100
end
AdvancedCallback:bind('OnGainBuff', function(unit, buff) OnGainBuff(unit, buff) end)
AdvancedCallback:bind('OnLoseBuff', function(unit, buff) OnLoseBuff(unit, buff) end)
--End Credit Skeem
local JungleMobNames = { 
        ["wolf8.1.1"] = true,
        ["wolf8.1.2"] = true,
        ["YoungLizard7.1.2"] = true,
        ["YoungLizard7.1.3"] = true,
        ["LesserWraith9.1.1"] = true,
        ["LesserWraith9.1.2"] = true,
        ["LesserWraith9.1.4"] = true,
        ["YoungLizard10.1.2"] = true,
        ["YoungLizard10.1.3"] = true,
        ["SmallGolem11.1.1"] = true,
        ["wolf2.1.1"] = true,
        ["wolf2.1.2"] = true,
        ["YoungLizard1.1.2"] = true,
        ["YoungLizard1.1.3"] = true,
        ["LesserWraith3.1.1"] = true,
        ["LesserWraith3.1.2"] = true,
        ["LesserWraith3.1.4"] = true,
        ["YoungLizard4.1.2"] = true,
        ["YoungLizard4.1.3"] = true,
        ["SmallGolem5.1.1"] = true,
}

local FocusJungleNames = {
        ["Dragon6.1.1"] = true,
        ["Worm12.1.1"] = true,
        ["GiantWolf8.1.1"] = true,
        ["AncientGolem7.1.1"] = true,
        ["Wraith9.1.1"] = true,
        ["LizardElder10.1.1"] = true,
        ["Golem11.1.2"] = true,
        ["GiantWolf2.1.1"] = true,
        ["AncientGolem1.1.1"] = true,
        ["Wraith3.1.1"] = true,
        ["LizardElder4.1.1"] = true,
        ["Golem5.1.2"] = true,
		["GreatWraith13.1.1"] = true,
		["GreatWraith14.1.1"] = true,
}

function PluginOnLoad()
	ASLoadMinions()
	if myHero:GetSpellData(SUMMONER_1).name:find("Smite") then SmiteSlot = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("Smite") then SmiteSlot = SUMMONER_2 end
	AutoCarry.PluginMenu:addParam("JungleFarm", "Farm Jungle", SCRIPT_PARAM_ONKEYDOWN, false, KeyV)
	AutoCarry.PluginMenu:addParam("EmergencySnare", "Emergency Snare near mouse cursor", SCRIPT_PARAM_ONKEYDOWN, false, KeyX)
	AutoCarry.PluginMenu:addParam("EmergencyEscape", "Emergency Escape", SCRIPT_PARAM_ONKEYDOWN, false, KeyC)
	AutoCarry.PluginMenu:addParam("MinEnemies", "Min enemies for always spider", SCRIPT_PARAM_SLICE, 2, 0, 5, 0)
	AutoCarry.PluginMenu:addParam("AutoTransform", "Auto Transform", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("UseECombo", "Use Human E in AutoCarry", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("HumanERequirement", "Use Human E before swapping", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("HumanEHitchance", "Human E Hitchance", SCRIPT_PARAM_SLICE , 0.5, 0, 1, 10)
	AutoCarry.PluginMenu:addParam("UseSpiderECombo", "Use Spider E in AutoCarry", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("EGapCloseDistance", "Spider E minimum distance", SCRIPT_PARAM_SLICE, 800, 0, 1100, 0)
	AutoCarry.PluginMenu:addParam("SmartKS", "Smart KillSteal", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("SwapFormKS", "Swap form in Smart KillSteal", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("QSmite", "Use QSmite on Big Camps", SCRIPT_PARAM_ONKEYTOGGLE, (SmiteSlot ~= nil), 78)
	AutoCarry.PluginMenu:addParam("RappelGapClosers", "Use Rappel on Gapclosers", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("RappelDangerous", "Use Rappel on Dangerous spells", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("QSmiteBuffer", "QSmite extra damage buffer", SCRIPT_PARAM_SLICE, 150, 0, 1000, 0)
	AutoCarry.PluginMenu:addParam("Draw", "Draw E Range", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("Debug", "Debug", SCRIPT_PARAM_ONOFF, false)
end

function CalculateRealCD(total_cd)
	current_cd = myHero.cdr
	real_cd = total_cd + total_cd * current_cd
	return real_cd
end


function PluginOnTick()
	----print('Cd is ' .. tostring(myHero:GetSpellData(_Q).level) .. ' ' .. tostring(myHero:GetSpellData(_Q).currentCd) .. ' ' .. tostring(myHero:GetSpellData(_Q).name))
	----print(myHero:CanUseSpell(_Q))
	----print('CurrentCd is ' .. tostring(SpiderQready) .. ' human ' .. tostring(HumanQready))
	Checks()
	allMinions:update()
	--CheckCDs()
	CheckRappelTimer()
	CheckForm()
	CheckSpellState()
	CheckStatesReady()
	checkDeadMonsters()
	SmiteDamage = math.max(20*myHero.level+370,30*myHero.level+330,40*myHero.level+240,50*myHero.level+100)
	QSmite()

	if ValidTarget(Target) and isRappel and RappeTimer > 500 then
		CastSpell(_E, Target)
	end

	if AutoCarry.MainMenu.AutoCarry then
		Combo()
	end

	if AutoCarry.MainMenu.MixedMode then
		Combo()
	end

	if AutoCarry.PluginMenu.JungleFarm then
		JungleFarm()
	end

	-- if AutoCarry.MainMenu.LaneClear then
	-- 	local MinionTarget = AutoCarry.GetMinionTarget
	-- 	if MinionTarget ~= nil and ValidTarget(MinionTarget, 800) then
	-- 		if isSpider then 
	-- 			CastSpell(_Q, MinionTarget)
	-- 			CastSpell(_W)
	-- 		elseif not isSpider then
	-- 			CastSpell(_W, MinionTarget)
	-- 			CastSpell(_Q, MinionTarget)
	-- 			CastR('Spider')
	-- 		end
	-- 	end
	-- end

	if AutoCarry.PluginMenu.EmergencySnare then 
		if isSpider and HumanEready then
			CastR('Human')
		end
		local closestchamp = nil
		----print('Cast Q harass called')
		--Credit Chancy--
        for _, champ in pairs(AutoCarry.EnemyTable) do
            if closestchamp and closestchamp.valid and champ and champ.valid then
                if GetDistance(champ, mousePos) < GetDistance(closestchamp, mousePos) then
                    closestchamp = champ
                end
            else
                closestchamp = champ
            end
        end
        if closestchamp ~= nil and ValidTarget(closestchamp) and GetDistance(closestchamp) < HumanSkillE.range and HumanEready then
        	CastHumanE(Target)
        end
	end


	if AutoCarry.PluginMenu.EmergencyEscape then
		if not isSpider then
			CastR('Spider')
		end
		--Credit Chancy--
		local closestmob = FindClosestMob()
		if closestmob ~= nil and closestmob.valid and GetDistance(closestmob) < SpiderSkillE.range then
			CastSpiderE(closestmob, 1, 0)
		end
	end
end

function Combo()
	--Human logic--


	if ValidTarget(Target) and not isSpider then

		if AutoCarry.PluginMenu.UseECombo then
			CastHumanE(Target)
		end

		if HumanQready then 
			CastHumanQ(Target)
		end

		if HumanWready then
			CastHumanW(Target, 1)
		end
	end


	--Spider Logic--
	if ValidTarget(Target) and isSpider then
		if SpiderQready then
			CastSpiderQ(Target)
		end
		if SpiderWready and GetDistance(Target) < 300 then
			CastSpiderW()
		end
		if AutoCarry.PluginMenu.UseSpiderECombo and GetDistance(Target) >= AutoCarry.PluginMenu.EGapCloseDistance and SpiderEready then
			CastSpiderE(Target, 1, 0)
		end
	end



	--Swap Logic--
	--Always stay in spider form if enemies 
	if not AutoCarry.PluginMenu.AutoTransform then
		return
	elseif CountEnemyNearPerson(myHero, 650) > AutoCarry.PluginMenu.MinEnemies then
		if not isSpider then
			CastR('Spider')
		end
	elseif SpiderCombatReady and HumanCombatReady and isSpider then
		CastR('Human')
	elseif not HumanCombatReady and SpiderCombatReady and not isSpider and not HumanEBoolean then
		CastR('Spider')
	elseif not SpiderCombatReady and HumanReady and isSpider then
		CastR('Human')
	end
end


-- function Harass()
-- 	if ValidTarget(Target) and not isSpider then
-- 		if HumanQready then 
-- 			CastHumanQ(Target)
-- 		end

-- 		if HumanWready then
-- 			CastHumanW(Target)
-- 		end

-- 		if AutoCarry.PluginMenu.UseECombo and GetDistance(Target, myHero) >= AutoCarry.PluginMenu.HumanEDistance then
-- 			CastHumanE(Target, AutoCarry.PluginMenu.HumanEHitchance)
-- 		end
-- 	end

-- 	if not AutoCarry.PluginMenu.AutoTransform then
-- 		return
-- 	elseif KSoverride then
-- 		return
-- 	elseif CountEnemyNearPerson(myHero, 800) > AutoCarry.PluginMenu.MinEnemies then
-- 		if not isSpider and not KSoverride then
-- 			CastR('Spider')
-- 		end
-- 	elseif isSpider then
-- 		CastR('Human')
-- 	end

-- end


function KillSteal()
	--We have to consider only two spells Q and QM. W is simply too inaccurate to do anything with--
	--Simplest case, we're in spider or human form and we want to ks--
	if not isSpider then
	    for _, champ in pairs(AutoCarry.EnemyTable) do
	        if not champ.dead and ValidTarget(champ) and HumanQready and champ.health < getDmg("Q", champ, myHero) and GetDistance(champ, myHero) < HumanSkillQ.range then
	        	CastHumanQ(champ)
	        	if isSpider and not SpiderCombatReady and AutoCarry.PluginMenu.SwapFormKS then
	        		CastR('Human')
	        	end
	        end
	    end
	elseif isSpider then
	    for _, champ in pairs(AutoCarry.EnemyTable) do
	        if not champ.dead and ValidTarget(champ) and SpiderQready and champ.health < getDmg("QM", champ, myHero) and GetDistance(champ, myHero) < HumanSkillQ.range then
	        	CastSpiderQ(champ)
	        	if not isSpider and not HumanCombatReady and AutoCarry.PluginMenu.SwapFormKS then
	        		CastR('Spider')
	        	end
	        end
	    end
	end
end

function FindClosestMob()
	local closestmob = nil
	----print('CLosest mob called with table ' .. tostring(#table5))
	for index, mob in ipairs(allMinions.objects) do
		if ValidTarget(mob) and mob.valid and GetDistance(mob, myHero) < SpiderSkillE.range and mob.team ~= myHero.team then
			if GetDistance(mob, mousePos) < GetDistance(closestmob, mousePos) then
				closestmob = mob
			end
		else 
			closestmob = mob
		end
	end
	return closestmob
end

local function getHitBoxRadius(target)
	return GetDistance(target, target.minBBox)
	--return GetDistance(target.minBBox, target.maxBBox)/4
end

function CastHumanQ(Target)
	if not isSpider and HumanQready and GetDistance(Target, myHero) < HumanSkillQ.range then
		CastSpell(_Q, Target)
	end
end

function CastHumanW(Target, Hitchance)
	if Hitchance == nil then
		Hitchance = 0.2
	end
	if not isSpider and HumanWready and ValidTarget(Target) then
		--local HumanSkillW = {spellkey = _W, range = 950, speed = math.huge, delay = 300, width = 0}
		local WCastPosition, WHitChance, _ = VP:GetLineCastPosition(Target, 0.300, 10, 950, math.huge, myHero, true)
		--print(WCastPosition)
		if WCastPosition ~= nil and WHitChance ~= nil then
			if WHitChance >= Hitchance and GetDistance(WCastPosition, myHero) < HumanSkillW.range then 
				CastSpell(_W, WCastPosition.x, WCastPosition.z)
			end
		end
	end
end

function CastHumanE(Target)
	local SpellE = myHero:GetSpellData(_E)
	if SpellE.name ~= 'EliseHumanE' then
		return
	end
	if Target ~= nil then
		--ECastPosition, ETime, EHitchance = ProdictE:GetPrediction(Target)
		--975, 1450, 0.250, 70)
		ECastPosition, EHitchance, _ = VP:GetLineCastPosition(Target, 0.250, 60, 975, 1450, myHero, true)
		local WillCollide = Col:GetMinionCollision(myHero, ECastPosition)
		--print(tostring(ECastPosition.x) .. ' ' .. tostring(ECastPosition.z) .. ' ' .. tostring(WillCollide) .. ' ' .. tostring(EHitchance) .. ' ' .. tostring(HumanEready) .. ' ' .. tostring(GetDistance(ECastPosition, myHero)))
		if WillCollide ~= nil and ECastPosition ~= nil and WillCollide == false and EHitchance ~= nil then
			--print('CastE1')
			if myHero:CanUseSpell(_E) and GetDistance(ECastPosition) < 1000 and not isSpider and HumanEready and myHero.mana > 50 and EHitchance > 1 then
				--Packet("S_CAST", {spellId = _E, sourceNetworkId = myHero.networkID, fromX = ECastPosition.x, fromY = ECastPosition.x, toX = ECastPosition.x, toY =  ECastPosition.x}):send()
				--CastSpell(_E, ECastPosition.x, ECastPosition.z)
				CastEPacket(ECastPosition.x, ECastPosition.z)
				if AutoCarry.PluginMenu.Debug then
					print('CastE2')
					print(tostring(ECastPosition.x) .. ' ' .. tostring(ECastPosition.z) .. ' ' .. tostring(WillCollide) .. ' ' .. tostring(EHitchance) .. ' ' .. tostring(HumanEready) .. ' ' .. tostring(GetDistance(ECastPosition, myHero)))
				end
				--AutoCarry.CanAttack = true
				--AutoCarry.CanMove = true
				--SkillE:Cast(Target)
				--CastEPacket(ECastPosition.x, ECastPosition.z)
			end
		else
			AutoCarry.CanAttack = true
			AutoCarry.CanMove =  true
		end
	else
		AutoCarry.CanAttack = true
		AutoCarry.CanMove = true
	end
end

function CastR(form)
	if RReady and form == 'Spider' then
		if not isSpider then
			CastSpell(_R)
		end
	elseif RReady and form == 'Human' then 
		if isSpider then
			CastSpell(_R)
	end
	end
end

function CastSpiderQ(Target)
	if isSpider and SpiderQready and GetDistance(Target, myHero) < SpiderSkillQ.range then
		CastSpell(_Q, Target)
	end

end

function CastSpiderW()
	if isSpider and SpiderWready then
		CastSpell(_W)
	end
end


function CastSpiderE(Target, mode, delay)
	--If mode == 1, cast to target immediately
	--If mode == 2, hide then cast to escape/cast to enemy champion
	--If mode == 3, hide then cast to escape/cast to minion
	-- --If mode == 4, dodge skillshot
	-- local ECastPosition, ETime, EHitChance = ProdictSpiderE:GetPrediction(Target)
	-- local E2CastPosition, E2Time, E2HitChance = ProdictSpiderE2:GetPrediction(Target)

	local SpellE = myHero:GetSpellData(_E)
	if SpellE.name ~= 'EliseSpiderEInitial' then
		return
	end
	if mode == 1 and ValidTarget(Target) and GetDistance(Target, myHero) < SpiderSkillE.range and (delay == 0 or delay == nil) then
		if not isRappel then
			CastSpell(_E, Target)
			CastEPacket(Target.x, Target.z)
		end
	elseif mode == 2 and ValidTarget(Target) and GetDistance(Target, myHero) < SpiderSkillE.range then
		if not isRappel then
			CastSpell(_E)
		elseif RappelTimer >= delay and isRappel then
			CastSpell(_E, Target)
		end
	elseif mode == 3 and ValidTarget(Target) and GetDistance(Target, myHero) < SpiderSkillE.range then
		if not isRappel then
			CastSpell(_E)
		elseif not isRappel and (delay == 0 or delay == nil) then
			CastSpell(_E, Target)
		elseif RappelTimer >= delay and isRappel then
			CastSpell(_E, Target)
		end
	elseif mode == 4 then
		if not isRappel then
			CastSpell(_E)
		elseif isRappel and isSafe and GetDistance(Target, myHero) < SpiderSkillE.range and RappelTimer >= delay then
			CastSpell(_E, Target)
		end 
	end
end

function PluginOnDraw()
	if ECastPosition ~= nil then
		DrawCircle(ECastPosition.x, ECastPosition.y, ECastPosition.z, 80, 0xFF0000)
	end

	if AutoCarry.PluginMenu.Draw then
		DrawCircle(myHero.x, myHero.y, myHero.z, HumanSkillE.range, 0xFF0000)
	end
	if AutoCarry.PluginMenu.Debug then
		DrawText3D("Current isSpider status is " .. tostring(isSpider) .. ' ' .. tostring(isRappel), myHero.x, myHero.y, myHero.z, 25,  ARGB(255,255,0,0), true)
		DrawText('Spider Q ready is ' .. tostring(SpiderQready) .. ' ' .. tostring(HumanQready) .. ' ' .. tostring(SpiderWready) .. ' ' .. tostring(HumanWready) .. ' ' .. tostring(SpiderEready) .. ' ' .. tostring(HumanEready), 15, 300, 300, ARGB(255,0,255,0))
		DrawText('HumanCombatReady ' .. tostring(HumanCombatReady) .. ' Spider Combat Status ' .. tostring(SpiderCombatReady), 25, 200, 200, ARGB(255,0,255,0))
		-- DrawText(tostring(GetTickCount()), 25, 450, 450, ARGB(255,0,255,0))
		DrawText('SpiderQcd ' .. tostring(SpiderQcd) .. ' ' .. tostring(SpiderWcd), 25, 350, 350, ARGB(255,0,255,0))
		DrawText('HumanQcd ' .. tostring(HumanQcd) .. ' ' .. tostring(HumanWcd), 25, 400, 400, ARGB(255,0,255,0))
	end
end

function CastEPacket(xpos, zpos)
	----printChat("Packet Called!")
	packet = CLoLPacket(0x99)
	packet.dwArg1 = 1
	packet.dwArg2 = 0
	packet:EncodeF(myHero.networkID)
	packet:Encode1(2)
	packet:EncodeF(xpos)
	packet:EncodeF(zpos)
	packet:EncodeF(xpos)
	packet:EncodeF(zpos)
	packet:EncodeF(0)
	SendPacket(packet)
	--printChat("E Packet Sent!")
--nID, spell, x, y, z
end
function PluginOnProcessSpell(unit, spell)
	--Credit Mancusizz--


	if isSpider then
		if unit.isMe and spell.name == 'EliseSpiderQCast' then
			SpiderQcd = GetTickCount() + CalculateRealCD(SpiderTrueQcd)
		end
		if unit.isMe and spell.name == 'EliseSpiderW' then
			SpiderWcd = GetTickCount() + CalculateRealCD(SpiderTrueWcd)
			--print('Spider W Cast')
		end
		if unit.isMe and spell.name =='EliseSpiderEInitial' then
			SpiderEcd = GetTickCount() + CalculateRealCD(SpiderTrueEcd[myHero:GetSpellData(_E).level])
			isRappel = true
			RappelStartTimer = GetTickCount()
		end
		if unit.isMe and spell.name == 'EliseRSpider' then
			Rcd = GetTickCount() + CalculateRealCD(RTruecd)
		end
	elseif not isSpider then
		if unit.isMe and spell.name =='EliseHumanQ' then
			HumanQcd = GetTickCount() + CalculateRealCD(HumanTrueQcd)
		end
		if unit.isMe and spell.name == 'EliseHumanW' then
			--print('Human W Cast')
			HumanWcd = GetTickCount() + CalculateRealCD(HumanTrueWcd)
		end
		if unit.isMe and spell.name == 'EliseHumanE' then
			HumanEcd = GetTickCount() + CalculateRealCD(HumanTrueEcd[myHero:GetSpellData(_E).level])
			--print(CalculateRealCD(HumanTrueEcd[myHero:GetSpellData(_E).level]))
				AutoCarry.CanAttack = true
				AutoCarry.CanMove = true
		end
		if unit.isMe and spell.name == 'EliseR' then
			Rcd = GetTickCount() + CalculateRealCD(RTruecd)
		end
	end

	if AutoCarry.PluginMenu.RappelGapClosers then
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
	        		if isSpider and SpiderEready then
	        			CastSpell(_E)
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
	elseif AutoCarry.PluginMenu.RappelDangerous then
		local DangerousSpellList = {
		['Amumu'] = {true, spell = _R, range = 550, projSpeed = math.huge},
		['Annie'] = {true, spell = _R, range = 600, projSpeed = math.huge},
		['Ashe'] = {true, spell= _R, range = 20000, projSpeed = 1600},
		['Fizz'] = {true, spell = _R, range = 1300, projSpeed = 2000},
		['Jinx'] = {true, spell = _R, range = 20000, projSpeed = 1700},
		['Malphite'] = {true, spell = _R, range = 1000,  projSpeed = 1500 + unit.ms},
		['Nautilus'] = {true, spell = _R, range = 825, projSpeed = 1400},
		['Sona'] = {true, spell = _R, range = 1000, projSpeed = 2400},
		['Orianna'] = {true, spell = _R, range = 900, projSpeed = math.huge},
		['Zed'] = {true, spell = _R, range = 625, projSpeed = math.huge},
		['Vi'] = {true, spell = _R, range = 800, projSpeed = math.huge},
		['Yasuo'] = {true, spell = _R, range = 800, projSpeed = math.huge},
		}
	    if unit.type == 'obj_AI_Hero' and unit.team ~= myHero.team and DangerousSpellList[unit.charName] and GetDistance(unit) < 2000 and spell ~= nil then
	        if spell.name == (type(DangerousSpellList[unit.charName].spell) == 'number' and unit:GetSpellData(DangerousSpellList[unit.charName].spell).name or DangerousSpellList[unit.charName].spell) then
	            if spell.target ~= nil and spell.target.name == myHero.name then
					----print('Gapcloser: ',unit.charName, ' Target: ', (spell.target ~= nil and spell.target.name or 'NONE'), " ", spell.name, " ", spell.projectileID)
	        		if isSpider and SpiderEready then
	        			CastSpell(_E)
	        			print('Trying to dodge dangerous spell ' .. tostring(spell.name) .. ' with E!')
	        		end
	            else
	                spellExpired = false
	                informationTable = {
	                    spellSource = unit,
	                    spellCastedTick = GetTickCount(),
	                    spellStartPos = Point(spell.startPos.x, spell.startPos.z),
	                    spellEndPos = Point(spell.endPos.x, spell.endPos.z),
	                    spellRange = DangerousSpellList[unit.charName].range,
	                    spellSpeed = DangerousSpellList[unit.charName].projSpeed
	                }
	            end
	        end
	    end
	end
end

function CheckForm()
	local SpellQ = myHero:GetSpellData(_Q)
	if SpellQ.name == 'EliseHumanQ' then
		isSpider = false
	else
		isSpider = true
	end
end

function OnGainBuff(unit, buff)
	-- if buff.name == 'elisespidere' and unit.isMe then
	-- 	isRappel = true
	-- 	RappelStartTimer = GetTickCount()
	-- end
end

function OnLoseBuff(unit, buff)
	if buff.name == 'elisespidere' and unit.isMe then
		isRappel = false
		RappelTimer = 0
		RappelStartTimer = nil
	end
end

function CheckRappelTimer()
	if isRappel and RappelStartTimer ~= nil then
		RappeTimer = GetTickCount() - RappelStartTimer
	end
end

function Checks()
	if IsSACReborn then Target = AutoCarry.Crosshair:GetTarget() else Target = AutoCarry.GetAttackTarget() end
	if SmiteSlot ~= nil then CanUseSmite = (myHero:CanUseSpell(SmiteSlot) == READY) end
	-- QReady = (myHero:CanUseSpell(_Q) == QReady)
	-- WReady = (myHero:CanUseSpell(_W) == WReady)
	-- EReady = (myHero:CanUseSpell(_E) == EReady)
	-- RReady = (myHero:CanUseSpell(_R) == RReady)
end

-- function CheckCDs()
-- 	if isSpider then
-- 		if myHero:GetSpellData(_Q).name == 'EliseSpiderQCast' then
-- 			SpiderQcd = GetTickCount() + myHero:GetSpellData(_Q).currentCd*1000
-- 		end
-- 		if myHero:GetSpellData(_W).name == 'EliseSpiderW' then
-- 			SpiderWcd = GetTickCount() + myHero:GetSpellData(_W).currentCd*1000
-- 		end
-- 		if myHero:GetSpellData(_E).name == 'EliseSpiderEInitial' then
-- 			SpiderEcd = GetTickCount() + myHero:GetSpellData(_E).currentCd*1000
-- 		end
-- 	elseif not isSpider then
-- 		if myHero:GetSpellData(_Q).name == 'EliseHumanQ' then
-- 			HumanQcd = GetTickCount() + myHero:GetSpellData(_Q).currentCd*1000
-- 		end
-- 		if myHero:GetSpellData(_W).name == 'EliseHumanW' then
-- 			HumanWcd = GetTickCount() + myHero:GetSpellData(_W).currentCd*1000
-- 		end
-- 		if myHero:GetSpellData(_E).name == 'EliseHumanE' then
-- 			HumanEcd = GetTickCount() + myHero:GetSpellData(_E).currentCd*1000
-- 		end		
-- 	end
-- end

--Credit Xetrok
function CountEnemyNearPerson(person,vrange)
    count = 0
    for i=1, heroManager.iCount do
        currentEnemy = heroManager:GetHero(i)
        if currentEnemy.team ~= myHero.team then
            if person:GetDistance(currentEnemy) <= vrange and not currentEnemy.dead then count = count + 1 end
        end
    end
    return count
end

--Credit Sida

-- List stolen from SAC Revamped, by Sida!
--Credit to Skeem's Khazix Script--
-- for i = 0, objManager.maxObjects do
-- 	local object = objManager:getObject(i)
-- 	if object ~= nil then
-- 		if FocusJungleNames[object.name] then
-- 			table.insert(JungleFocusMobs, object)
-- 		elseif JungleMobNames[object.name] then
-- 			table.insert(JungleMobs, object)
-- 		end
-- 	end
-- end

function GetJungleMob()
	if JungleFocusMobs ~= nil and #JungleFocusMobs > 0 then
        for i, Mob in ipairs(JungleFocusMobs) do
                if ValidTarget(Mob, 650) and Mob.name ~= nil then return Mob end
        end
    elseif JungleMobs ~= nil and #JungleMobs > 0 then
        for i, Mob in ipairs(JungleMobs) do
                if ValidTarget(Mob, 650) and Mob.name ~= nil then return Mob end
        end
    else
    	return nil
    end
end


function PluginOnCreateObj(obj)
	if obj ~= nil then
		if FocusJungleNames[obj.name] then
			table.insert(JungleFocusMobs, obj)
		elseif JungleMobNames[obj.name] then
            table.insert(JungleMobs, obj)
		end
	end
	if obj ~= nil and obj.type == "obj_AI_Minion" and obj.name ~= nil then
		if obj.name == "TT_Spiderboss7.1.1" then Vilemaw = obj
		elseif obj.name == "Worm12.1.1" then Nashor = obj
		elseif obj.name == "Dragon6.1.1" then Dragon = obj
		elseif obj.name == "AncientGolem1.1.1" then Golem1 = obj
		elseif obj.name == "AncientGolem7.1.1" then Golem2 = obj
		elseif obj.name == "LizardElder4.1.1" then Lizard1 = obj
		elseif obj.name == "LizardElder10.1.1" then Lizard2 = obj end
	end
end
function PluginOnDeleteObj(obj)
	if obj ~= nil then
		for i, Mob in ipairs(JungleMobs) do
			if obj.name == Mob.name then
				table.remove(JungleMobs, i)
			end
		end
		for i, Mob in ipairs(JungleFocusMobs) do
			if obj.name == Mob.name then
				table.remove(JungleFocusMobs, i)
			end
		end
	end
	if obj ~= nil and obj.name ~= nil then
		if obj.name == "TT_Spiderboss7.1.1" then Vilemaw = nil
		elseif obj.name == "Worm12.1.1" then Nashor = nil
		elseif obj.name == "Dragon6.1.1" then Dragon = nil
		elseif obj.name == "AncientGolem1.1.1" then Golem1 = nil
		elseif obj.name == "AncientGolem7.1.1" then Golem2 = nil
		elseif obj.name == "LizardElder4.1.1" then Lizard1 = nil
		elseif obj.name == "LizardElder10.1.1" then Lizard2 = nil end
	end
end
function checkDeadMonsters()
	if Vilemaw ~= nil then if not Vilemaw.valid or Vilemaw.dead or Vilemaw.health <= 0 then Vilemaw = nil end end
	if Nashor ~= nil then if not Nashor.valid or Nashor.dead or Nashor.health <= 0 then Nashor = nil end end
	if Dragon ~= nil then if not Dragon.valid or Dragon.dead or Dragon.health <= 0 then Dragon = nil end end
	if Golem1 ~= nil then if not Golem1.valid or Golem1.dead or Golem1.health <= 0 then Golem1 = nil end end
	if Golem2 ~= nil then if not Golem2.valid or Golem2.dead or Golem2.health <= 0 then Golem2 = nil end end
	if Lizard1 ~= nil then if not Lizard1.valid or Lizard1.dead or Lizard1.health <= 0 then Lizard1 = nil end end
	if Lizard2 ~= nil then if not Lizard2.valid or Lizard2.dead or Lizard2.health <= 0 then Lizard2 = nil end end
end

function MonsterDraw(object)

end



function ASLoadMinions()
	for i = 1, objManager.maxObjects do
		local obj = objManager:getObject(i)
		if obj ~= nil and obj.type == "obj_AI_Minion" and obj.name ~= nil then
			if obj.name == "TT_Spiderboss7.1.1" then Vilemaw = obj
			elseif obj.name == "Worm12.1.1" then Nashor = obj
			elseif obj.name == "Dragon6.1.1" then Dragon = obj
			elseif obj.name == "AncientGolem1.1.1" then Golem1 = obj
			elseif obj.name == "AncientGolem7.1.1" then Golem2 = obj
			elseif obj.name == "LizardElder4.1.1" then Lizard1 = obj
			elseif obj.name == "LizardElder10.1.1" then Lizard2 = obj end
		end
	end
	for i = 0, objManager.maxObjects do
		local object = objManager:getObject(i)
		if object ~= nil and object.type == "obj_AI_Minion" and object.name ~= nil then
			if FocusJungleNames[object.name] then
				table.insert(JungleFocusMobs, object)
			elseif JungleMobNames[object.name] then
				table.insert(JungleMobs, object)
			end
		end
	end
end
--End
function checkMonster(object)
	if object ~= nil and not object.dead and object.visible and object.x ~= nil then
		local DistanceMonster = GetDistance(object)
		qDamage = getDmg("QM", object, myHero)
		local mixDamage = SmiteDamage + qDamage + AutoCarry.PluginMenu.QSmiteBuffer
		--print('Check monster called with ' .. tostring(mixDamage))
		if CanUseSmite and DistanceMonster <= range and object.health <= SmiteDamage then
			CastSpell(SmiteSlot, object)
		elseif SpiderQready and DistanceMonster <= SpiderSkillQ.range and isSpider then
			if CanUseSmite and object.health <= mixDamage then
				CastSpell(_Q, object)
				-- QBuffer = true
				-- DelayAction(function() buffer = false end, 0.25)
				-- if buffer == false then
				-- 	CastSpell(SmiteSlot, object)
				-- end
			elseif object.health <= qDamage then
				CastSpell(_Q, object)
			end
		elseif object.health <= mixDamage and SpiderQready and DistanceMonster <= SpiderSkillQ.range and not isSpider then
			CastR('Spider')
		end
	end
end

function QSmite()
	if AutoCarry.PluginMenu.QSmite and not myHero.dead and (CanUseSmite or SpiderQready) then
		if Vilemaw ~= nil then checkMonster(Vilemaw) end
		if Nashor ~= nil then checkMonster(Nashor) end
		if Dragon ~= nil then checkMonster(Dragon) end
		if Golem1 ~= nil then checkMonster(Golem1) end
		if Golem2 ~= nil then checkMonster(Golem2) end
		if Lizard1 ~= nil then checkMonster(Lizard1) end
		if Lizard2 ~= nil then checkMonster(Lizard2) end
	end
end


function JungleFarm()
	TargetJungleMob = GetJungleMob()

	if TargetJungleMob ~= nil and ValidTarget(TargetJungleMob, 800) and GetDistance(TargetJungleMob, myHero) < 650 then
		if HumanCombatReady and SpiderCombatReady and isSpider and AutoCarry.PluginMenu.AutoTransform then
			CastR('Human')
		end

		if not isSpider then
			if HumanQready and GetDistance(TargetJungleMob, myHero) < HumanSkillQ.range then
				CastSpell(_Q, TargetJungleMob)
			end
			if HumanWready and GetDistance(TargetJungleMob, myHero) < HumanSkillW.range then
				--print('Cast Human W jungle called')
				CastSpell(_W, TargetJungleMob.x, TargetJungleMob.z)
			end
		end

		if isSpider then
			if SpiderQready and GetDistance(TargetJungleMob, myHero) < SpiderSkillQ.range then
				CastSpell(_Q, TargetJungleMob)
			end
			if SpiderWready and GetDistance(TargetJungleMob, myHero) < 400 then
				--print('Cast Spider W jungle called')
				CastSpell(_W)
			end
		end

		if not isSpider and SpiderCombatReady and not HumanReady and AutoCarry.PluginMenu.AutoTransform then
			CastR('Spider')
		elseif isSpider and not SpiderCombatReady and HumanReady and AutoCarry.PluginMenu.AutoTransform then
			CastR('Human')
		end
	end
end

function CheckSpellState()
	Current_Tick = GetTickCount()

	-- --print(Current_Tick - SpiderQcd)
	-- --print(Current_Tick - HumanQcd)

	if Current_Tick - SpiderQcd > 0 then 
		SpiderQready = true
	else
		SpiderQready = false
	end

	if Current_Tick - SpiderWcd > 0 then 
		SpiderWready = true
	else
		SpiderWready = false
	end

	if Current_Tick - SpiderEcd > 0 then 
		SpiderEready = true
	else
		SpiderEready = false
	end

	if Current_Tick - HumanQcd > 0 then 
		HumanQready = true
	else
		HumanQready = false
	end

	if Current_Tick - HumanWcd > 0 then 
		HumanWready = true
	else
		HumanWready = false
	end

	if Current_Tick - HumanEcd > 0 then 
		HumanEready = true
	else
		HumanEready = false
	end

	if Current_Tick - Rcd > 0 then 
		RReady = true
	else
		RReady = false
	end
end

function CheckStatesReady()
	HumanEBoolean = nil

	if AutoCarry.PluginMenu.HumanERequirement then
		if HumanEready and myHero.mana > 50 then
			HumanEBoolean = true
		else
			HumanEBoolean = false
		end
	end

	if myHero.level == 1 then
		if HumanQready and HumanWready then
			HumanReady = true
			HumanCombatReady = true
		else
			HumanReady = false
			HumanCombatReady = false
		end

		if SpiderQready and SpiderWready then
			SpiderCombatReady = true
		else
			SpiderCombatReady = false
		end

	else
		if HumanQready and HumanWready then
			HumanReady = true
		elseif not HumanQready and not HumanWready then
			HumanReady = false
		end

		if (HumanQready and HumanWready) and HumanEBoolean then
			HumanCombatReady = true
		elseif not HumanQready and not HumanWready and not HumanEBoolean then
			HumanCombatReady = false
		end

		if (SpiderQready or SpiderWready) then
			SpiderReady = true
		else
			SpiderReady = false
		end

		if SpiderQready and SpiderWready then
			SpiderCombatReady = true
		elseif not SpiderQready and not SpiderWready then
			SpiderCombatReady = false
		end
	end

end

function TableJoin(t1, t2)
 
   for k,v in ipairs(t2) do
   		if v ~= nil then
    		table.insert(t1, v)
    	end
   end 
 
   return t1
end

