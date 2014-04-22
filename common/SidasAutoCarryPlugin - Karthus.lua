if myHero.charName ~= "Karthus" then return end
require 'Prodiction'
local Prodict = {}

function PluginOnLoad()
	--Menu
	mainLoad()
	mainMenu()
end
function PluginOnTick()
	Checks()
	local enemyTable = {}
	for I = 1, heroManager.iCount do
		local hero = heroManager:GetHero(I)
		if hero.team ~= myHero.team and not hero.dead then
			table.insert(enemyTable, hero)
		end
	end
	current_E_counter = 0
	current_R_counter = 0
	current_R_distance = math.huge
	if Target and AutoCarry.MainMenu.AutoCarry then
		--PrintChat("Debug 1")
		if GetDistance(Target) < 850 and QREADY then
				--PrintChat("Can Cast Q")
				ProdictQ:GetPredictionCallBack(Target, CastQ)

		end
		--PrintChat("Debug 2")
		if GetDistance(Target) < 1050 and WREADY then
				--PrintChat("Can Cast W")
				ProdictW:GetPredictionCallBack(Target, CastW)
		end
		--PrintChat("Debug 3")
		if EREADY and Menu.useE then 
			for i, enemyHero in ipairs(enemyTable) do
				if GetDistance(enemyHero, myHero) < 550 then
					current_E_counter = current_E_counter + 1
				end
			end
		end
		--PrintChat("Current E counter is " .. tostring(current_E_counter))

		if current_E_counter >= Menu.minE and not isPressedE then
			--PrintChat("Can Cast E " .. tostring(isPressedE))
			CastSpell(_E)
		--[[elseif current_E_counter < Menu.minE and isPressedE then
			CastSpell(_E)
			--PrintChat("Can 2nd Cast E " .. tostring(isPressedE))
		end]]
		end
	end

	if current_E_counter < Menu.minE and isPressedE then
		CastSpell(_E)
		--PrintChat("Can 2nd Cast E " .. tostring(isPressedE))
	end

	if RREADY then
		for i, enemyHero in ipairs(enemyTable) do
			if getDmg("R", enemyHero, myHero) > enemyHero.health and not enemyHero.dead then
				current_R_counter = current_R_counter + 1
				PrintChat("R counter incremented " .. tostring(current_R_counter))
			end
			--[[if GetDistance(enemyHero, myHero) < current_R_distance then
				current_R_distance = GetDistance(enemyHero, myHero)
				--PrintChat("R distance incremented " .. tostring(current_R_distance))
			end]]
		end
	end


	if Target and Carry.MixedMode then
		if GetDistance(Target) < 850 and QREADY then
			ProdictQ:GetPredictionCallBack(Target, CastQ)
		end
	end
	--PrintChat("Debug 4")
	if current_R_counter >= Menu.minR and Menu.useRks and Menu.useR and current_R_distance > Menu.minRdistance and RREADY then
		--PrintChat("Can Cast R")
		CastSpell(_R)
	end
	--[[PrintChat(tostring(current_R_counter) .. ' ' .. tostring(RREADY))
	if Menu.Ralert and RREADY and current_R_counter > 0 then
		if current_R_counter == 1 then
			PrintAlert("1 ENEMY KILLALBE", 1, 255, 255, 255)
		elseif current_R_counter == 2 then
			PrintAlert("2 ENEMIES KILLALBE", 1, 255, 255, 255)
		elseif current_R_counter == 3 then
			PrintAlert("3 ENEMIES KILLALBE", 1, 255, 255, 255)
		elseif current_R_counter == 4 then
			 PrintAlert("4 ENEMIES KILLALBE", 1, 255, 255, 255)
		elseif current_R_counter == 5 then
			PrintAlert("5 ENEMIES KILLALBE", 1, 255, 255, 255)
		end
	end]]

	if Menu.qFarm then
		Farm()
	end
end

local function getHitBoxRadius(target)
	return GetDistance(target, target.minBBox)
end

function CastQ(unit, pos)
	if GetDistance(pos) - getHitBoxRadius(unit)/2 < qmaxRange then
			CastSpell(_Q, pos.x, pos.z)
	end
end

function CastW(unit, pos)
	if GetDistance(pos) - getHitBoxRadius(unit)/2 < wRange then
			CastSpell(_W, pos.x, pos.z)
	end
end


function mainLoad()
	if AutoCarry.Skills then IsSACReborn = true else IsSACReborn = false end
	if IsSACReborn then AutoCarry.Skills:DisableAll() end
	Carry = AutoCarry.MainMenu
	Menu = AutoCarry.PluginMenu
	min_hit_chance = 1
	qtotalcasttime = 400 --not sure about this value yet
	qmaxRange = 875
	qminRange = 250
	qWidth = 60
	qSpeed = 1500
	eRange = 550
	wWidth = 150
	wRange = 1000
	rRange = 800
	QREADY = false
	WREADY = false 
	EREADY = false
	RREADY = false
	isPressedE = false 
	Prodict = ProdictManager.GetInstance()
	ProdictQ = Prodict:AddProdictionObject(_Q, 875, 1750, 0.61, 50)
	ProdictW = Prodict:AddProdictionObject(_W, 1000, math.huge, 0.656, 0)
	ignite = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)
	PrintChat("Sidas Autocarry Karthus Plugin v0.02 by Dienofail loaded")
	AutoCarry.Crosshair:SetSkillCrosshairRange(1100) -- Set the spell target selector range
	AdvancedCallback:bind('OnGainBuff', function(unit, buff) OnGainBuff(unit, buff) end)
	AdvancedCallback:bind('OnLoseBuff', function(unit, buff) OnLoseBuff(unit, buff) end)
end

function mainMenu()
	local HKC = string.byte("T")
	local HKZ = string.byte("Z")
	Menu:addParam("useQ", "Use (Q)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useW", "Use (W)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useE", "Use (E)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useR", "Use (R)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useRks", "Use (R) ks", SCRIPT_PARAM_ONOFF, false)
	Menu:addParam("drawQ", "Draw (Q)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("drawW", "Draw (W)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("minE", "Minimum heroes on (E) cast", SCRIPT_PARAM_SLICE, 1, 0, 5, 0)
	Menu:addParam("minR", "Minimum heroes on (R) cast", SCRIPT_PARAM_SLICE, 1, 0, 5, 0)
	Menu:addParam("minRdistance", "Minimum distance on closest enemy on (R) cast", SCRIPT_PARAM_SLICE, 0, 0, 2000, 0)
	Menu:addParam("Ralert", "R alert on or off", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("drawW", "Draw (W)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("qFarm","Farm with Q-Skill", SCRIPT_PARAM_ONOFF, false, HKZ)
	Menu:addParam("mManager", "Farm Q mana slider", SCRIPT_PARAM_SLICE, 1, 0, 100, 0)
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

function PluginOnDraw()
	if Menu.drawQ then
		DrawCircle(myHero.x, myHero.y, myHero.z, qmaxRange, 0x7F006E)
	end
	if Menu.drawW then
		DrawCircle(myHero.x, myHero.y, myHero.z, wRange, 0x7F006E)
	end

	if Menu.drawtoggle then
	    for _, enemy in pairs(GetEnemyHeroes()) do
	        local pos= WorldToScreen(D3DXVECTOR3(enemy.x, enemy.y, enemy.z))
	        local posX = pos.x - 35
	        local posY = pos.y - 50
	        local pos2 = WorldToScreen(D3DXVECTOR3(myHero.x, myHero.y, myHero.z))
	        local posX2 = pos2.x - 35
	        local posY2 = pos2.y - 50
	        if getDmg("R", enemy, myHero) >= enemy.health and RREADY then
	        	DrawText("R HIM!", 25 , posX ,posY  , ARGB(255,0,255,0))    
	        	DrawText('Can kill'  .. tostring(enemy.charName) .. ' with R!', 25, posX2, posY2, ARGB(255,0,255,0))
	        end
	    end
	end
end


function OnGainBuff(unit, buff)
	if unit.isMe and buff.name == 'Defile' then
		----PrintChat("Gained")
		isPressedE= true
		Qstartcasttime = os.clock()
	end
end

function OnLoseBuff(unit, buff)
	if unit.isMe and buff.name == 'Defile' then
		----PrintChat("Lost")
		isPressedE = false
		Qcasttime = 0
	end
end

function Farm()
	if not Menu.qFarm then end
	if IsMyManaLow() then end 
	if myHero.dead then end
	--PrintChat("Farm getting called")
	local minions = {}
	for i, minion in pairs(AutoCarry.EnemyMinions().objects) do
		--PrintChat("Iterating on " ..tostring(i))
		local counter = 0
		if minion.health < getDmg("Q", minion, myHero) then
			CastSpell(_Q, minion)
			--PrintChat("Casting Q  " .. tostring(getDmg("Q", minion, myHero)))
			--[[for j, minion2 in pairs(AutoCarry.EnemyMinions().objects) do
				if minion2 ~= minion1 and GetDistance(minion1, minion2) < qWidth then
					if getDmg("Q", minion, myHero) / 2 > minion.health then
						CastSpell(_Q, minion)
						counter = counter + 1
					end
				end
			end
			if counter == 0 then
				CastSpell(_Q, minion)
			end]]
		end
    end
end

function IsMyManaLow()
    if myHero.mana < (myHero.maxMana * ( Menu.mManager / 100)) then
        return true
    else
        return false
    end
end
