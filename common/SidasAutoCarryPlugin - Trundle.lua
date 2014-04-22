local version = "0.02"

--Changelog 

--v0.01 Updated with VPrediction and added autoupdater. 

local AUTOUPDATE = true
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/Dienofail/BoL/master/common/SidasAutoCarryPlugin%20-%20Trundle.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = LIB_PATH.."SidasAutoCarryPlugin - Trundle.lua"
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>SAC TRUNDLE:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
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

if myHero.charName ~= "Trundle" then return end

	-- require "Prodiction"
	-- Prodict = ProdictManager.GetInstance()
	-- ProdictE = Prodict:AddProdictionObject(_E, 1000, 1600, 0.266, 62.5)
function PluginOnLoad()
	--Menu
	if VIP_USER then
		-- require "Prodiction"
		-- Prod = ProdictManager.GetInstance()
		-- ProdictE = Prod:AddProdictionObject(_E, 1600, 1000, 0.266, 63)
		require "VPrediction"
		VP = VPrediction()
	end
	mainLoad()
	mainMenu()
	PrintChat("loaded")
end

function PluginOnTick()
	if myHero.dead then return end
	--PrintChat("Ontick")
	Checks()
	CastQ()
	CastW()
	CastE()
	CastR()
	JungleClear()
end

function CastQ()
	if AutoCarry.MainMenu.AutoCarry and Menu.useQ and ValidTarget(Target) and GetDistance(Target, myHero) < 250 then
		if VIP_USER then
			SkillQ:Cast(Target)
		else
			AutoCarry.CastSkillshot(SkillQ, Target)
		end
	end
end

function CastW()
	if AutoCarry.MainMenu.AutoCarry and ValidTarget(Target) and WREADY then
		if GetDistance(Target, myHero) >= Menu.Wdistance then
			current_half_distance = GetDistance(Target, myHero)/2
			ShouldCastPosition = Vector(myHero) + (Vector(Target) - Vector(myHero)):normalized() * (current_half_distance)
			CastSpell(_W, ShouldCastPosition.x, ShouldCastPosition.z)
		end
	end
end

function CastE()
	if ValidTarget(Target) and not myHero.isdead and EREADY and Menu.useE then
		if VIP_USER then
			--CastPosition, HitChance, Time = ProdictE:GetPrediction(Target)
			CastPosition, HitChance, _ = VP:GetLineCastPosition(Target, 0.266, 63, 1000, 1600, myHero, false)
		else
			CastPosition = Vector(Target.x, Target.z)
		end
		if Menu.CastEFront and GetDistance(myHero, Target) > Menu.Edistance then
			--print("CastEfront called")
			current_distance = GetDistance(CastPosition, myHero) * 0.8
			ShouldCastPosition = Vector(myHero) + (Vector(CastPosition) - Vector(myHero)):normalized() * (current_distance)
			if GetDistance(ShouldCastPosition, myHero) < eRange then
				CastSpell(_E, ShouldCastPosition.x, ShouldCastPosition.z)
				--print("Casting E from front called")
			end
		end
		if Menu.CastEBack and GetDistance(myHero, Target) > Menu.Edistance then
			--print("CastEback called")
			current_distance = GetDistance(CastPosition, myHero) * 1.2
			ShouldCastPosition = Vector(myHero) + (Vector(CastPosition) - Vector(myHero)):normalized() * (current_distance)
			if GetDistance(ShouldCastPosition, myHero) < eRange then
				CastSpell(_E, ShouldCastPosition.x, ShouldCastPosition.z)
				--print("Casting E from front back")
			end
		end
	end
end

function CastR()
	if ValidTarget(Target) and RREADY and Menu.useR and AutoCarry.MainMenu.AutoCarry and GetDistance(myHero, Target) < rRange then
		if Menu.useRtarget then
			CastSpell(_R, Target)
		elseif Menu.useRtanky then
			EnemyTable = AutoCarry.Helper.EnemyTable
			current_table = {}
			max_power = 0
			max_power_hero = nil
			for i, enemy in ipairs(EnemyTable) do
				if GetDistance(enemy, myHero) < rRange then
					power = enemy.armor + enemy.magicArmor + enemy.health/10 + enemy.maxHealth/10
					if power > max_power then
						max_power = power
						max_power_hero = enemy
					end
				end
			end
			CastSpell(_R, max_power_hero)
		else
			CastSpell(_R, Target)
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
			SkillQ:Cast(JungleMob) 
			if WREADY and Menu.useW then
				CastSpell(_W, JungleMob.x, JungleMob.z)
			end
		end
	end
end


function mainLoad()
	PrintChat('Main load called')
	if AutoCarry.Skills then IsSACReborn = true else IsSACReborn = false end
	if IsSACReborn then AutoCarry.Skills:DisableAll() end
	--PrintChat('Debug1')
	Carry = AutoCarry.MainMenu
	Menu = AutoCarry.PluginMenu
	qRange = 250
	wRange = 900
	wRadius = 1000
	eRange = 1000
	eCastTime = 0.250
	eRadius = 62.5
	rRange = 800
	QREADY = false
	WREADY = false
	EREADY = false
	RREADY = false
	--PrintChat('Debug2')
	if IsSACReborn then
		SkillQ = AutoCarry.Skills:NewSkill(false, _Q, qRange, "Trundle Q", AutoCarry.SPELL_TARGETED, 0, true, true, math.huge, 240, 0, false)
	else
		SkillQ = {spellKey = _Q, range = 250, speed = math.huge, delay = 0, width = 0, configName = "TrundleQ", displayName = "TrundleQ", enabled = true, skillShot = false, minions = true, reset = true, reqTarget = true }
	end
	--ignite = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)
	--PrintChat('Debug3')
	PrintChat("Sidas Autocarry Trundle Plugin by Dienofail loaded v0.01")
	-- if VIP_USER then 
	-- 	AdvancedCallback:bind('OnGainBuff', function(unit, buff) OnGainBuff(unit, buff) end)
	--     AdvancedCallback:bind('OnLoseBuff', function(unit, buff) OnLoseBuff(unit, buff) end)
	--     AdvancedCallback:bind('OnCreateObj', function(unit, buff) OnCreateObj(unit, buff) end)
	--     AdvancedCallback:bind('OnDeleteObj', function(unit, buff) OnDeleteObj(unit, buff) end)
	-- end
	AutoCarry.Crosshair:SetSkillCrosshairRange(1000) -- Set the spell target selector range
end

function mainMenu()
	HKZ = string.byte("Z")
	HKX = string.byte("X")
	HKC = string.byte("C")
	Menu:addParam("useQ", "Use (Q)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useW", "Use (W)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useE", "Use (E)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useR", "Use (R)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useRtanky", "Use (R) tanky", SCRIPT_PARAM_ONOFF, false)
	Menu:addParam("useRtarget", "Use (R) target", SCRIPT_PARAM_ONOFF, false)
	Menu:addParam("Wdistance", "Use (W) Chase Distance", SCRIPT_PARAM_SLICE, 0, 0, 900, 0)
	Menu:addParam("Edistance", "Use (E) Chase Distance", SCRIPT_PARAM_SLICE, 0, 0, 1000, 0)
	Menu:addParam("killsteal", "Kill Steal with R", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("drawQ", "Draw (Q)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("drawR", "Draw (R)", SCRIPT_PARAM_ONOFF, true)
	--Menu:addParam("manualQ", "Q PREDICTION KEY", SCRIPT_PARAM_ONKEYDOWN, false, )
	Menu:addParam("CastEFront","Cast E in front of enemy", SCRIPT_PARAM_ONKEYDOWN, false, HKZ)
	Menu:addParam("CastEBack","Cast E behind the enemy", SCRIPT_PARAM_ONKEYDOWN, false, HKX)
	Menu:addParam("JungleKey", "Jungle Farm", SCRIPT_PARAM_ONKEYDOWN, false, HKC)
end


function Checks()
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	WREADY = (myHero:CanUseSpell(_W) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY)
	-- if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then ignite = SUMMONER_1
	-- elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then ignite = SUMMONER_2 end
	-- IGNITEReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
	if IsSACReborn then Target = AutoCarry.Crosshair:GetTarget() else Target = AutoCarry.GetAttackTarget() end
end
