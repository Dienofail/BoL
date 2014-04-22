local version = "0.04"
--[[

Perfect Lulu,

By Dienofail

Changelog:

v0.01 - release

v0.02 - changes to autoupdater

v0.03 - some fixes to pix detection. 

]]


if myHero.charName ~= "Lulu" then return end
if VIP_USER then
	require 'VPrediction'
end

local AUTOUPDATE = true
local UPDATE_NAME = "Lulu"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/Dienofail/BoL/master/Lulu.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>"..UPDATE_NAME..":</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
if AUTOUPDATE then
	local ServerData = GetWebResult(UPDATE_HOST, UPDATE_PATH, "", 5)
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
--end Honda7

--Start Vadash Credit
class 'Kalman' -- {
function Kalman:__init()
        self.current_state_estimate = 0
        self.current_prob_estimate = 0
        self.Q = 1
        self.R = 15
end
function Kalman:STEP(control_vector, measurement_vector)
        local predicted_state_estimate = self.current_state_estimate + control_vector
        local predicted_prob_estimate = self.current_prob_estimate + self.Q
        local innovation = measurement_vector - predicted_state_estimate
        local innovation_covariance = predicted_prob_estimate + self.R
        local kalman_gain = predicted_prob_estimate / innovation_covariance
        self.current_state_estimate = predicted_state_estimate + kalman_gain * innovation
        self.current_prob_estimate = (1 - kalman_gain) * predicted_prob_estimate
        return self.current_state_estimate
end
--[[ Velocities ]]
local kalmanFilters = {}
local velocityTimers = {}
local oldPosx = {}
local oldPosz = {}
local oldTick = {}
local velocity = {}
local lastboost = {}
local velocity_TO = 10
local CONVERSATION_FACTOR = 975
local MS_MIN = 500
local MS_MEDIUM = 750
--End Vadash Credit

--Toy
local InterruptList = {
    { charName = "Caitlyn", spellName = "CaitlynAceintheHole"},
    { charName = "FiddleSticks", spellName = "Crowstorm"},
    { charName = "FiddleSticks", spellName = "DrainChannel"},
    { charName = "Galio", spellName = "GalioIdolOfDurand"},
    { charName = "Karthus", spellName = "FallenOne"},
    { charName = "Katarina", spellName = "KatarinaR"},
    { charName = "Lucian", spellName = "LucianR"},
    { charName = "Malzahar", spellName = "AlZaharNetherGrasp"},
    { charName = "MissFortune", spellName = "MissFortuneBulletTime"},
    { charName = "Nunu", spellName = "AbsoluteZero"},
    { charName = "Pantheon", spellName = "Pantheon_GrandSkyfall_Jump"},
    { charName = "Shen", spellName = "ShenStandUnited"},
    { charName = "Urgot", spellName = "UrgotSwap2"},
    { charName = "Varus", spellName = "VarusQ"},
    { charName = "Warwick", spellName = "InfiniteDuress"}
}
--End Toy


local initDone = false
local SpellQ = {Range = 950, Width = 60, Speed = 1600, Delay = 0.250}
local SpellQ2 = {Range = 1600, Width = 60, Speed = 1600, Delay = 0.500}
local SpellW = {Range = 650, Width = 0, Speed = math.huge, Delay = 0.250}
local SpellE = {Range = 650, Width = 0, Speed = math.huge, Delay = 0.250}
local SpellR = {Range = 900, Width = 0, Speed = math.huge, Delay = 0.250}
local ignite, igniteReady = nil, nil
local QReady, WReady, EReady, RReady = false, false, false, false
local Pix = nil
local lastAnimation = nil
local lastAttack = 0
local lastAttackCD = 0
local lastWindUpTime = 0
local PixPosition = nil
local eneplayeres = {}
local ToInterrupt = {}
if VIP_USER then
	VP = VPrediction()
else
	tp1 = TargetPrediction(950, 1.6, 250, 60, 50)
	tp2 = TargetPrediction(1600, 1.6, 500, 60, 50)
	tp3 = TargetPrediction(1600, 1.6, 250, 60, 50)
	tp4 = TargetPrediction(math.huge, math.huge, 250, 10, 50)
end


function OnLoad()
	Menu()
	Init()
end


function Init()
	--print('Init called')
	--Start Vadash Credit
    for i = 1, heroManager.iCount do
        local hero = heroManager:GetHero(i)
        if hero.team ~= player.team then
                table.insert(eneplayeres, hero)
                kalmanFilters[hero.networkID] = Kalman()
                velocityTimers[hero.networkID] = 0
                oldPosx[hero.networkID] = 0
                oldPosz[hero.networkID] = 0
                oldTick[hero.networkID] = 0
                velocity[hero.networkID] = 0
                lastboost[hero.networkID] = 0
        end
        for _, champ in pairs(InterruptList) do
        	if hero.charName == champ.charName then
        		table.insert(ToInterrupt, champ.spellName)
        	end
        end
    end
    --End Vadash Credit
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 950, DAMAGE_MAGICAL)
	ts2 = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1600, DAMAGE_MAGICAL)
	ts.name = "Main"
	ts2.name = "Q Harass"
	Config:addTS(ts2)
	Config:addTS(ts)
	EnemyMinions = minionManager(MINION_ENEMY, 975, myHero, MINION_SORT_MAXHEALTH_DEC)
	JungleMinions = minionManager(MINION_JUNGLE, 1200, myHero, MINION_SORT_MAXHEALTH_DEC)
	AllyMinions = minionManager(MINION_ALLY, 675, myHero, MINION_SORT_MAXHEALTH_DEC)
	initDone = true
	print('Dienofail Lulu ' .. tostring(version) .. ' loaded!')
end

function Menu()
	Config = scriptConfig("Lulu", "Lulu")
	Config:addParam("Combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("Harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('C'))
	Config:addParam("Farm", "Farm", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('V'))
	Config:addParam("Support", "Support Carry (not functional yet)", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('T'))
	--Config:addParam("ManualQSplit", "QSplit", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('T'))
	Config:addSubMenu("Combo options", "ComboSub")
	Config:addSubMenu("Harass options", "HarassSub")
	Config:addSubMenu("Farm options", "FarmSub")
	Config:addSubMenu("Support options", "SupportSub")
	Config:addSubMenu("Extra Config", "Extras")
	Config:addSubMenu("Draw", "Draw")
	--Combo options
	Config.ComboSub:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("MinRHealth", "Min Health % for R", SCRIPT_PARAM_SLICE, 20, 1, 100, 0)
	Config.ComboSub:addParam("Orbwalk", "Orbwalk", SCRIPT_PARAM_ONOFF, true)
	Config.ComboSub:addParam("RKnockup", "Min R Knockups", SCRIPT_PARAM_SLICE, 3, 1, 5, 0)
	--Farm
	Config.FarmSub:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.FarmSub:addParam("useE", "Use E on self", SCRIPT_PARAM_ONOFF, true)
	--Harass
	Config.HarassSub:addParam("UseWHarass", "Use W", SCRIPT_PARAM_ONOFF, true)
	Config.HarassSub:addParam("Orbwalk", "Orbwalk", SCRIPT_PARAM_ONOFF, true)
	--Support
	for i=1, heroManager.iCount do
		local teammate = heroManager:GetHero(i)
		if teammate.team == myHero.team then Config.SupportSub:addParam("support"..i, "Support "..teammate.charName, SCRIPT_PARAM_ONOFF, false) end
	end
	Config.SupportSub:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.SupportSub:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	Config.SupportSub:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
	Config.SupportSub:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, false)
	Config.SupportSub:addParam("RKnockup", "Min R Knockups", SCRIPT_PARAM_SLICE, 3, 1, 5, 0)
	Config.SupportSub:addParam("MinRHealth", "Min Health % for R", SCRIPT_PARAM_SLICE, 20, 1, 100, 0)
	Config.SupportSub:addParam("MinEHealth", "Min Health % for E", SCRIPT_PARAM_SLICE, 75, 1, 100, 0)
	Config.SupportSub:addParam("WGapCloser", "W Enemy Gapclosers on Supported Allies", SCRIPT_PARAM_ONOFF, false)
	--Draw 
	Config.Draw:addParam("DrawQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawQ2", "Draw Extended Q Range", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawW", "Draw W/E Range", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawR", "Draw R Range", SCRIPT_PARAM_ONOFF, false)
	Config.Draw:addParam("DrawTarget", "Draw Target", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawQPrediction", "Draw Q Prediction", SCRIPT_PARAM_ONOFF, true)
	Config.Draw:addParam("DrawPix", "Draw Pix", SCRIPT_PARAM_ONOFF, true)
	--Extras
	Config.Extras:addParam("Debug", "Debug", SCRIPT_PARAM_ONOFF, false)
	Config.Extras:addParam("ExtendQ", "Extend Q with Pix", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("WSpells", "W to interrupt channeling spells", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("AoEQ", "Check for AoE Q (LAG)", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("mManager", "Mana slider", SCRIPT_PARAM_SLICE, 0, 0, 100, 0)
	Config.Extras:addParam("WGapCloser", "W Enemy Gapclosers on Self", SCRIPT_PARAM_ONOFF, true)
	Config.Extras:addParam("Hitchance", "Hitchance", SCRIPT_PARAM_SLICE, 2, 1, 5, 0)
	Config.Extras:addParam("MinPix", "Min More Enemies Hit to Reposition Pix", SCRIPT_PARAM_SLICE, 1, 0, 5, 0)
	--Permashow
	Config:permaShow("Combo")
	Config:permaShow("Farm")
	Config:permaShow("Harass")
	Config:permaShow("Support")
end


--Credit Trees
function GetCustomTarget()
	ts:update()
	ts2:update()
    if _G.MMA_Target and _G.MMA_Target.type == myHero.type then return _G.MMA_Target, ts2.target end
    if _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then return _G.AutoCarry.Attack_Crosshair.target, ts2.target end
    return ts.target, ts2.target
end
--End Credit Trees


function OnTick()
	if initDone then
		Check()
		UpdateSpeed()
		target, Qtarget = GetCustomTarget()
		ProcessPix()
		if Config.Combo then
			if target ~= nil then
				Combo(target)
			elseif Qtarget ~= nil then
				CastQ(Qtarget)
			end

			if target ~= nil and GetDistance(target) < 600 and ValidTarget(target, 600) and Config.ComboSub.Orbwalk then
				OrbWalking(target)
			elseif Config.ComboSub.Orbwalk then
				moveToCursor()
			end
		end

		if Config.Harass then
			if target ~= nil then
				Harass(target)
			elseif Qtarget ~= nil then
				CastQ(Qtarget)
				ExtendedQ(Qtarget, false)
			end

			if target ~= nil and GetDistance(target) < 600 and ValidTarget(target, 600) and Config.HarassSub.Orbwalk then
				OrbWalking(target)
			elseif Config.HarassSub.Orbwalk  then
				moveToCursor()
			end
		end
		CheckDashes()

	end
end

function Combo(Target)
	if Target ~= nil and ValidTarget(Target, 1700) and not Target.dead then

		if Config.ComboSub.useQ then
 			CastQ(Target)
 		end		

		if Config.ComboSub.useE then
			CastE(Target)
		end

 		if Config.ComboSub.useW then
 			CastW(Target)
 		end

 		if Config.ComboSub.useR then
 			CheckRHealth(myHero, (Config.ComboSub.MinRHealth/100)*myHero.maxHealth)
 		end

 		if Config.ComboSub.useR then
 			CheckRAllies(Config.ComboSub.RKnockup)
 		end
	end 
end

function Harass(Target)
	if Target ~= nil then
		CastE(Target)
		CastQ(Target)
	end
end

function Support()

end


function Farm()
	if Config.FarmSub.useQ then
		FarmQ()
	end

	if Config.FarmSub.useE and #EnemyMinions.objects > 3 and EReady then
		CastE(myHero)
	end
end


function CastQ(Target)
	if Target ~= nil and ValidTarget(Target, 1700) and not Target.dead then
		if QReady then
			if Config.Extras.AoEQ and Config.Extras.ExtendQ then
				AoEQ(Target, false)
			end
			if Config.Extras.ExtendQ then
				ExtendedQ(Target, false)
			end
			if not Config.Extras.AoEQ and not Config.Extras.ExtendQ then
				RegularQ(Target)
			end
		end
	end 
end

function CastW(Target)
	if Target ~= nil and not Target.dead and WReady and GetDistance(Target) <  SpellW.Range and not IsMyManaLow() then
		CastSpell(_W, Target)
	elseif GetDistance(Target) > 1100 and Target.ms > myHero.ms + 50 and DirectionalHeading() then
		CastSpell(_W, myHero)
	end
end

function CastE(Target)
	if Target ~= nil and not Target.dead and EReady and GetDistance(Target) < SpellW.Range and not IsMyManaLow() then
		CastSpell(_E, Target)
	end
end

function CastR(Target)
	if Target ~= nil and not Target.dead and RReady and GetDistance(Target) < SpellR.Range and not IsMyManaLow() then
		CastSpell(_R, Target)
	end
end

function ExtendedQ(Target, Mode)
	--One opponent case - searches for Q first then, extended Q. 
	if not QReady then return end
	-- if Config.Extras.Debug then
	-- 	print('ExtendedQ Called')
	-- end	
	local CastPosition1, HitChance1, Position1 = nil, nil, nil
	if VIP_USER and Target ~= nil and ValidTarget(Target, 1700) and not Target.dead then
		CastPosition1, HitChance1, Position1 = VP:GetLineCastPosition(Target, SpellQ.Delay, SpellQ.Width, SpellQ2.Range, SpellQ.Speed, myHero, false)
	elseif not VIP_USER and Target ~= nil and ValidTarget(Target, 1700) and not Target.dead then 
		CastPosition1 = tp3:GetPrediction(Target)
		HitChance1 = 5
	end

	if CastPosition1 ~= nil and HitChance1 ~= nil and GetDistance(CastPosition1, myHero) < SpellQ.Range then
		if VIP_USER and HitChance1 >= Config.Extras.Hitchance then
			CastSpell(_Q, CastPosition1.x, CastPosition1.z)
			if Config.Extras.Debug then
				print('ExtendedQ 1 ')
			end	
		elseif not VIP_USER then
			CastSpell(_Q, CastPosition1.x, CastPosition1.z)
		end
	else
		--Get Prediction from 2nd case
		if Config.Extras.Debug then
			print('ExtendedQ 2 ')
		end
		CastPosition2, HitChance2, Position2 = nil, nil, nil
		if VIP_USER then
			Position2, HitChance2, CastPosition2 = VP:GetLineCastPosition(Target, SpellQ2.Delay, SpellQ2.Width, SpellQ2.Range, SpellQ2.Speed, myHero, false)
		else
			CastPosition2 = tp2:GetPrediction(Target)
			HitChance2 = 5
		end

		if EReady then
			local TargetChampion = nil
			local TargetMinion = nil
			if Mode then
				local EnemyChampions = GetEnemyHeroes()
				for idx, champion in ipairs(EnemyChampions) do
					if GetDistance(champion) < SpellE.Range+150 and not champion.dead then
						if Config.Extras.Debug then
							print('Looping Enemy ExtendedQ with ' .. tostring(champion.charName))
						end		
						if champion.networkID ~= Target.networkID then
							local PredictedPixPos = PredictPixPosition(champion)
							if Config.Extras.Debug then
								print(PredictedPixPos)
							end		
							if GetDistance(PredictedPixPos, CastPosition2) < SpellQ.Range and GetDistance(champion) < SpellE.Range and champion ~= nil and not champion.dead and HitChance2 >= Config.Extras.Hitchance then
								CastSpell(_E, champion)
								TargetChampion = champion
								if Config.Extras.Debug then
									print('ExtendedQ with ' .. tostring(champion.charName))
								end	
								break
							end
						end
					end
				end
			end
			local AllyChampions = GetAllyHeroes()
			for idx, champion in ipairs(AllyChampions) do
				if GetDistance(champion) < SpellE.Range+150  and not champion.dead then
					if Config.Extras.Debug then
						print('Looping Ally ExtendedQ with ' .. tostring(champion.charName))
					end				
					local PredictedPixPos = PredictPixPosition(champion)
					-- print(PredictedPixPos)
					-- print(GetDistance(PredictedPixPos, CastPosition2))
					-- print(GetDistance(champion))
					if GetDistance(PredictedPixPos, CastPosition2) < SpellQ.Range and GetDistance(champion) < SpellE.Range and HitChance2 >= Config.Extras.Hitchance then
						CastSpell(_E, champion)
						if Config.Extras.Debug then
							print('ExtendedQ with ' .. tostring(champion.charName))
						end					
						TargetChampion = champion
						break
					end
				end
			end 
			if #AllyMinions.objects > 0 then
				for i, minion in ipairs(AllyMinions.objects) do
					local PredictedPixPos = PredictPixPosition(minion)
					if GetDistance(PredictedPixPos, CastPosition2) < SpellQ.Range and GetDistance(minion) < SpellE.Range and minion ~= nil and HitChance2 >= Config.Extras.Hitchance then
						CastSpell(_E, minion)
						TargetMinion = minion
						break
					end
				end
			end
		else
		if Pix ~= nil and GetDistance(Pix) > 250 and QReady then
			if VIP_USER then
				local CastPosition, Hitchance, PredictedPos = VP:GetLineCastPosition(Target, SpellQ.Delay, SpellQ.Width, SpellQ2.Range, SpellQ.Speed, myHero, false)
				if GetDistance(CastPosition) < SpellQ.Range and Hitchance >= 2 then
					CastSpell(_Q, CastPosition.x, CastPosition.z)
				elseif Hitchance >= 2 and GetDistance(CastPosition) < SpellQ2.Range then
					local ToCastPosition = Vector(myHero) + Vector(Vector(CastPosition) - Vector(myHero)):normalized()*(SpellQ.Range-10)
					CastSpell(_Q, ToCastPosition.x, ToCastPosition.z)
				end
			else
				local CastPosition = tp2:GetPrediction(Target)
				if GetDistance(CastPosition) < SpellQ.Range and Hitchance >= 2 then
					CastSpell(_Q, CastPosition.x, CastPosition.z)
				elseif GetDistance(CastPosition) < SpellQ2.Range then
					local ToCastPosition = Vector(myHero) + Vector(Vector(CastPosition) - Vector(myHero)):normalized()*(SpellQ.Range-10)
					CastSpell(_Q, ToCastPosition.x, ToCastPosition.z)
				end

			end
		elseif Pix ~= nil and QReady then
			if VIP_USER then
				local CastPosition, Hitchance, PredictedPos = VP:GetLineCastPosition(Target, SpellQ.Delay, SpellQ.Width, SpellQ.Range, SpellQ.Speed, myHero, false)
				if GetDistance(CastPosition) < SpellQ.Range and Hitchance > 1 then
					CastSpell(_Q, CastPosition.x, CastPosition.z)
				end
			else
				local CastPosition = tp1:GetPrediction(Target)
				if GetDistance(CastPosition) < SpellQ.Range then
					CastSpell(_Q, CastPosition.x, CastPosition.z)
				end
			end
		end
		end
	end
end

function AoEQ(Target, Mode)
	if not QReady then return end
	local AlreadyHit = {}
	local MaxHit1 = 0
	local MaxHitTarget1 = nil
	local MaxHit2 = 0 
	local MaxHitTarget2 = nil
	if VIP_USER then
		Position2, HitChance2, CastPosition2 = VP:GetLineCastPosition(Target, SpellQ2.Delay, SpellQ2.Width, SpellQ2.Range, SpellQ2.Speed, myHero, false)
	else
		Position2 = tp2:GetPrediction(Target)
		HitChance2 = 5
	end
	if EReady then
		if Target ~= nil and GetDistance(Target) < 1700 and ValidTarget(Target) and not Target.dead then
			--two cases: either primary Q then decide secondary vector or E then Q 
			local PredictedPos1 = nil

			if VIP_USER then
				PredictedPos1, _ = VP:GetPredictedPos(Target, SpellQ.Delay, math.huge, myHero, false)
			else
				PredictedPos1 = tp1:GetPrediction(Target)
			end

			if GetDistance(PredictedPos1) < SpellQ.Range then
				local CastUnitVector = Vector(Vector(myHero) - Vector(PredictedPos1)):normalized()
				local CastVector = CastUnitVector*SpellQ.Range
				local BestUnit = nil
				local BestCount = 0
				if Mode then
					local EnemyChampions = GetEnemyHeroes()
					for idx, champion in ipairs(EnemyChampions) do

						if GetDistance(champion) < SpellE.Range+100 and not champion.dead then
							if VIP_USER then
								PredictedPos2, _ = VP:GetPredictedPos(champion, SpellE.Delay, math.huge, myHero, false)
							else
								PredictedPos2 = tp1:GetPrediction(champion)
							end
							if Config.Extras.Debug then
								print('Looping Enemy ExtendedQ with ' .. tostring(champion.charName))
							end		
							local PredictedPixPos = PredictPixPosition(champion)
							if Config.Extras.Debug then
								print(PredictedPixPos)
							end		
							if GetDistance(PredictedPixPos, PredictedPos1) < SpellQ.Range and GetDistance(champion) < SpellE.Range and champion ~= nil and not champion.dead then
								CurrentCount = GetEnemiesHitByQ(Vector(PredictedPixPos), Vector(PredictedPixPos) + CastVector, 0.500)
								if CurrentCount > BestCount then
									BestUnit = champion
								end
							end
						end
					end

					if BestUnit ~= nil and GetDistance(BestUnit) < SpellE.Range  then
						CastSpell(_E, BestUnit)
					end

					local AllyChampions = GetAllyHeroes()
					for idx, champion in ipairs(AllyChampions) do
						if GetDistance(champion) < SpellE.Range+100 and not champion.dead then
							if VIP_USER then
								PredictedPos2, _ = VP:GetPredictedPos(champion, SpellE.Delay, math.huge, myHero, false)
							else
								PredictedPos2 = tp1:GetPrediction(champion)
							end
							if Config.Extras.Debug then
								print('Looping Enemy ExtendedQ with ' .. tostring(champion.charName))
							end		
							local PredictedPixPos = PredictPixPosition(champion)
							if Config.Extras.Debug then
								print(PredictedPixPos)
							end		
							if GetDistance(PredictedPixPos, CastPosition2) < SpellQ.Range and GetDistance(champion) < SpellE.Range and champion ~= nil and not champion.dead then
								CurrentCount = GetEnemiesHitByQ(Vector(PredictedPixPos), Vector(PredictedPixPos) + CastVector, 0.500)
								if CurrentCount > BestCount then
									BestUnit = champion
								end
							end
						end
					end
					if BestUnit ~= nil and GetDistance(BestUnit) < SpellE.Range  then
						CastSpell(_E, BestUnit)
					end
				end
			else
				if Mode then
					local EnemyChampions = GetEnemyHeroes()
					for idx, champion in ipairs(EnemyChampions) do
						if GetDistance(champion) < SpellE.Range+500 and not champion.dead then
							if Config.Extras.Debug then
								print('Looping Enemy ExtendedQ with ' .. tostring(champion.charName))
							end		
							if champion.networkID ~= Target.networkID then
								local PredictedPixPos = PredictPixPosition(champion)
								if Config.Extras.Debug then
									print(PredictedPixPos)
								end		
								if GetDistance(PredictedPixPos, CastPosition2) < SpellQ.Range and GetDistance(champion) < SpellE.Range and champion ~= nil and not champion.dead and HitChance2 >= Config.Extras.Hitchance then
									CastSpell(_E, champion)
									TargetChampion = champion
									if Config.Extras.Debug then
										print('ExtendedQ with ' .. tostring(champion.charName))
									end	
									break
								end
							end
						end
					end
					local AllyChampions = GetAllyHeroes()
					for idx, champion in ipairs(AllyChampions) do
						if GetDistance(champion) < SpellE.Range+150  and not champion.dead then
							if Config.Extras.Debug then
								print('Looping Ally ExtendedQ with ' .. tostring(champion.charName))
							end				
							local PredictedPixPos = PredictPixPosition(champion)
							-- print(PredictedPixPos)
							-- print(GetDistance(PredictedPixPos, CastPosition2))
							-- print(GetDistance(champion))
							if GetDistance(PredictedPixPos, CastPosition2) < SpellQ.Range and GetDistance(champion) < SpellE.Range and HitChance2 >= Config.Extras.Hitchance then
								CastSpell(_E, champion)
								if Config.Extras.Debug then
									print('ExtendedQ with ' .. tostring(champion.charName))
								end					
								TargetChampion = champion
								break
							end
						end
					end 
				end
			end
		end
	else 
		if Pix ~= nil and GetDistance(Pix) > 200 and QReady then
			if VIP_USER then
				local CastPosition, Hitchance, PredictedPos = VP:GetLineCastPosition(Target, SpellQ.Delay, SpellQ.Width, SpellQ2.Range, SpellQ.Speed, myHero, false)
				if GetDistance(CastPosition) < SpellQ.Range then
					CastSpell(_Q, CastPosition.x, CastPosition.z)
				else
					local ToCastPosition = Vector(myHero) + Vector(Vector(CastPosition) - Vector(myHero)):normalized()*(SpellQ.Range-10)
					CastSpell(_Q, ToCastPosition.x, ToCastPosition.z)
				end
			else

			end
		elseif Pix ~= nil and QReady then
			if VIP_USER then
				local CastPosition, Hitchance, PredictedPos = VP:GetLineCastPosition(Target, SpellQ.Delay, SpellQ.Width, SpellQ.Range, SpellQ.Speed, myHero, false)
				if GetDistance(CastPosition) < SpellQ.Range then
					CastSpell(_Q, CastPosition.x, CastPosition.z)
				end
			else
				local ToCastPosition = tp1:GetPrediction(Target)
				CastSpell(_Q, ToCastPosition.x, ToCastPosition.z)
			end
		end
	end
end

function RegularQ(Target)
	if not QReady then return end
	if Target ~= nil and GetDistance(Target) < 1100 and ValidTarget(Target) and not Target.dead then
		if VIP_USER then
			local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, SpellQ.Delay, SpellQ.Width, SpellQ.Range, SpellQ.Speed, myHero, false)
			if Hitchance >= Config.Extras.Hitchance and GetDistance(CastPosition) < SpellQ.Range and not IsMyManaLow() then 
				CastSpell(_Q, CastPosition.x, CastPosition.z)
			end
		else
			local CastPosition, a, b = tp1:GetPrediction(Target)
			if CastPosition ~= nil and GetDistance(CastPosition) < SpellQ.Range and not IsMyManaLow() then
				CastSpell(_Q, CastPosition.x, CastPosition.z)
			end
		end
	end
end

function GetRHits(Target)
	local count = 0
	local Enemies = GetEnemyHeroes()
	for idx, enemy in ipairs(Enemies) do
		if VIP_USER then 
			local Pos, HitChance = VP:GetPredictedPos(enemy, 0.250, math.huge, myHero, false)
			if HitChance >= 1 and GetDistance(Pos, Target) < 150 + VP:GetHitBox(enemy) and RReady then
				count = count + 1
			end 
		else
			local Pos = tp4:GetPrediction(enemy)
			if GetDistance(Pos, Target) < 200 and RReady then
				count = count + 1
			end
		end
	end
	return count 
end

function CheckRAllies(Hits)
	local Allies = GetAllyHeroes()
	for idx, champion in ipairs(Allies) do
		local current_hits = GetRHits(champion)
		if current_hits >= Hits then
			CastR(champion)
		end
	end

end

function CheckRHealth(Target, Health)
	if Target.health < Health and RReady and GetDistance(Target) < SpellR.Range then
		CastR(Target)
	end
end


function CheckCarries()

end

function GetDangerousEnemy(Ally)

end

function IsInDanger(Ally)

end

function CheckGapClosersMe()

end

function CheckGapClosersCarries()

end

-- function DirectionalHeading(Target, myHero)
-- 	if Target ~= nil and myHero ~= nil and GetDistance(Target) < 1700 then
-- 		if VIP_USER then
-- 			local TargetWaypoints = VP:GetCurrentWaypoints(Target)
-- 			local MyWayPoints = VP:GetCurrentWaypoints(myHero)
-- 			if #TargetWaypoints > 1 and #MyWayPoints > 1 then
-- 				local TargetVector = TargetWaypoints[#TargetWaypoints] - TargetWaypoint[1]
-- 				local myVector = MyWayPoints[#MyWayPoints] - MyWayPoints[1]
-- 				local Angle = Vector(TargetVector):normalized():angle(Vector(myVector):normalized())
-- 				if Angle*57.2957795 < 105 and Angle*57.2957795 > 75 then
-- 					GetDistance(Target) + Target.ms*time = 
-- 				end
-- 			else
-- 				return true 
-- 			end

-- 		else



-- 		end
-- 	end
-- end


function GetEnemiesHitByQ(startpos, endpos, delay)
	if startpos ~= nil and endpos ~= nil and delay ~= nil then
		local count = 0
		local Enemies = GetEnemyHeroes()
		for idx, enemy in ipairs(Enemies) do
			if enemy ~= nil and ValidTarget(enemy, 1600) and not enemy.dead and GetDistance(enemy, startpos) < SpellQ.Range + 100 then
				if VIP_USER then
					local throwaway, HitChance, PredictedPos = VP:GetLineCastPosition(Target, delay, SpellQ.Width, SpellQ.Range, SpellQ.Speed, myHero, false)
					local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(Vector(startpos), Vector(endpos), Vector(PredictedPos))
					local pointSegment3D = {x=pointSegment.x, y=enemy.y, z=pointSegment.y}
					if isOnSegment and pointSegment3D ~= nil and GetDistance(pointSegment3D, PredictedPos) < VP:GetHitBox(enemy) + SpellQ.Width and HitChance >= 1 then
						count = count + 1
					end
				else
					local PredictedPos, a, b = tp1:GetPrediction(enemy)
					local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(Vector(startpos), Vector(endpos), Vector(PredictedPos))
					local pointSegment3D = {x=pointSegment.x, y=enemy.y, z=pointSegment.y}
					if isOnSegment and pointSegment3D ~= nil and GetDistance(pointSegment3D, PredictedPos) < 50 + SpellQ.Width then
						count = count + 1
					end
				end
			end
		end
		if Config.Extras.Debug then
			print('Returning GetEnemiesByQ with ' .. tostring(count))
		end
		return count
	end
end


function PredictPixPosition(Target)
	if Config.Extras.Debug then
		print('PredictedPixPosition called ' .. tostring(Target.charName))
	end	
	if VIP_USER then
		local TargetWaypoints = VP:GetCurrentWayPoints(Target)
		if #TargetWaypoints > 1 then
			local PredictedPos = VP:GetPredictedPos(Target, 0.250, math.huge, myHero, false)
			local UnitVector = Vector(Vector(PredictedPos) - Vector(Target)):normalized()
			local PixPosition = Vector(PredictedPos) - Vector(UnitVector)*(VP:GetHitBox(Target) + 100)
			if Config.Extras.Debug then
				print('Pix Position returning ' .. tostring(PixPosition.z))
			end
			return PixPosition
		else
			return Target
		end
	else
		local Destination1, a, b = tp4:GetPrediction(Target)
		if Destination1 ~= nil then
			local UnitVector = Vector(Vector(Destination1) - Vector(Target)):normalized()
			--local UnitVector = Vector(Vector(Destination13D) - Vector(Target)):normalized()
			local PixPosition = Vector(Target) - Vector(UnitVector)*(150)
			return PixPosition
		else
			return Target
		end
	end
end

function OnProcessSpell(unit, spell)
	if #ToInterrupt > 0 and Config.Extras.WSpells and WReady then
		for _, ability in pairs(ToInterrupt) do
			if spell.name == ability and unit.team ~= myHero.team and GetDistance(unit) < SpellW.Range then
				CastSpell(_W, unit.x, unit.z)
			end
		end
	end
    if unit == myHero then
        if spell.name:lower():find("attack") then
            lastAttack = GetTickCount() - GetLatency()/2
            lastWindUpTime = spell.windUpTime*1000
            lastAttackCD = spell.animationTime*1000
        end
    end
end

-- function OnCreateObj(object)
--     if object and object.name:lower():find("faerie") then
--         Pix = object
-- 		if Config.Extras.Debug then
-- 			print('Pix Created')
-- 		end
--     end

-- end

-- function OnDeleteObj(object)
--     if object and object.name:lower():find("faerie")  then
--         Pix = nil
-- 		if Config.Extras.Debug then
-- 			print('Pix Destroyed')
-- 		end
--     end
-- end

function FarmQ()
	if QReady and #EnemyMinions.objects > 0 then
		local QPos = GetBestQPositionFarm()
		if QPos then
			CastSpell(_Q, QPos.x, QPos.z)
		end
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

function GetBestQPositionFarm()
	local MaxQ = 0 
	local MaxQPos 
	if Config.Extras.Debug then
		print('GetBestQPositionFarm')
	end
	for i, minion in pairs(EnemyMinions.objects) do
		local hitQ = countminionshitQ(minion)
		if hitQ ~= nil and hitQ > MaxQ or MaxQPos == nil then
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



function CheckDashes()
	local Enemies = GetEnemyHeroes()
	for idx, enemy in ipairs(Enemies) do
		if not enemy.dead and ValidTarget(enemy) and GetDistance(enemy) < SpellW.Range and Config.Extras.WGapClosers then
			local IsDashing, CanHit, Position = VP:IsDashing(enemy, SpellW.Delay, SpellW.Width, SpellW.Speed, myHero)
			if IsDashing and CanHit and GetDistance(Position) < SpellW.Range and WReady then
				CastSpell(_W, Position.x, Position.z)
			end
		end
	end
end



function ProcessPix()
	for i=1, objManager.iCount do
		local object = objManager:getObject(i)
		if object ~= nil and object.name:lower():find("lulu_faerie_idle") and object.valid and object.team == myHero.team then 
			--print(object.name)
			Pix = object
		end
	end
end

function OnDraw()
	if Config.Extras.Debug then
		DrawText3D("Current Pix Distance is " .. tostring(GetDistance(Pix)), myHero.x, myHero.y, myHero.z, 25,  ARGB(255,255,0,0), true)
	end

	if Config.Draw.DrawQ then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellQ.Range, 1,  ARGB(255, 0, 255, 255))
	end

	if Config.Draw.DrawQ2 then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellQ2.Range, 1,  ARGB(255, 0, 255, 255))
	end

	if Config.Draw.DrawW then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellW.Range, 1,  ARGB(255, 0, 255, 255))
	end

	if Config.Draw.DrawR then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellR.Range, 1,  ARGB(255, 0, 255, 255))
	end

	if Config.Draw.DrawTarget then
		if target ~= nil then
			DrawCircle3D(target.x, target.y, target.z, 100, 1, ARGB(255, 255, 0, 0))
		elseif Qtarget ~= nil then
			DrawCircle3D(Qtarget.x, Qtarget.y, Qtarget.z, 100, 1, ARGB(255, 255, 0, 0))
		end
	end

	if Config.Draw.DrawPix then
		if Pix ~= nil then
			DrawCircle3D(Pix.x, Pix.y, Pix.z, 100, 1, ARGB(255, 255, 255, 0))
		end
	end

end

--Start Manciuszz orbwalker credit
function OrbWalking(target)
    if TimeToAttack() and GetDistance(target) <= 565 then
        myHero:Attack(target)
    elseif heroCanMove() then
        moveToCursor()
    end
end
 
function TimeToAttack()
    return (GetTickCount() + GetLatency()/2 > lastAttack + lastAttackCD)
end
 
function heroCanMove()
        return (GetTickCount() + GetLatency()/2 > lastAttack + lastWindUpTime + 20)
end
 
function moveToCursor()
    if GetDistance(mousePos) then
        local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()*300
        myHero:MoveTo(moveToPos.x, moveToPos.z)
    end        
end
 
function OnAnimation(unit,animationName)
    if unit.isMe and lastAnimation ~= animationName then lastAnimation = animationName end
end
--End Manciuszz orbwalker credit 


--Start Vadash Credit
function HaveLowVelocity(target, time)
        if ValidTarget(target, 1500) then
                return (velocity[target.networkID] < MS_MIN and target.ms < MS_MIN and GetTickCount() - lastboost[target.networkID] > time)
        else
                return nil
        end
end

function HaveMediumVelocity(target, time)
        if ValidTarget(target, 1500) then
                return (velocity[target.networkID] < MS_MEDIUM and target.ms < MS_MEDIUM and GetTickCount() - lastboost[target.networkID] > time)
        else
                return nil
        end
end
 

function _calcHeroVelocity(target, oldPosx, oldPosz, oldTick)
        if oldPosx and oldPosz and target.x and target.z then
                local dis = math.sqrt((oldPosx - target.x) ^ 2 + (oldPosz - target.z) ^ 2)
                velocity[target.networkID] = kalmanFilters[target.networkID]:STEP(0, (dis / (GetTickCount() - oldTick)) * CONVERSATION_FACTOR)
        end
end
 
function UpdateSpeed()
        local tick = GetTickCount()
        for i=1, #eneplayeres do
                local hero = eneplayeres[i]
                if ValidTarget(hero) then
                        if velocityTimers[hero.networkID] <= tick and hero and hero.x and hero.z and (tick - oldTick[hero.networkID]) > (velocity_TO-1) then
                                velocityTimers[hero.networkID] = tick + velocity_TO
                                _calcHeroVelocity(hero, oldPosx[hero.networkID], oldPosz[hero.networkID], oldTick[hero.networkID])
                                oldPosx[hero.networkID] = hero.x
                                oldPosz[hero.networkID] = hero.z
                                oldTick[hero.networkID] = tick
                                if velocity[hero.networkID] > MS_MIN then
                                        lastboost[hero.networkID] = tick
                                end
                        end
                end
        end
end

--End Vadash Credit
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
--End Credit Xetrok

--Kain credit
function IsMyManaLow()
    if myHero.mana < (myHero.maxMana * ( Config.Extras.mManager / 100)) then
        return true
    else
        return false
    end
end
--End Kain Credit

function Check()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
    if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
            ignite = SUMMONER_1
    elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
            ignite = SUMMONER_2
    end
    igniteReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
	EnemyMinions:update()
	JungleMinions:update()
	AllyMinions:update()
end

function IgniteKS()
	if igniteReady then
		local Enemies = GetEnemyHeroes()
		for idx,val in ipairs(Enemies) do
			if ValidTarget(val, 600) then
                if getDmg("IGNITE", val, myHero) > val.health and GetDistance(val) <= 600 then
                        CastSpell(ignite, val)
                end
			end
		end
	end
end
