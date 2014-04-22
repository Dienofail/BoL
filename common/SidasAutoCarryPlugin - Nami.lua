if myHero.charName ~= "Nami" then return end


function PluginOnLoad()
	--Menu
	mainLoad()
	mainMenu()
end

function PluginOnTick()
	--PrintChat("Debug1")
	if myHero.dead then return end
	Checks()
	--PrintChat("Debug2")
	if AutoCarry.MainMenu.AutoCarry and ValidTarget(Target) and QREADY and GetDistance(Target) < Qrange then
		if IsSACReborn then
			SkillQ:Cast(Target)
		else
			AutoCarry.CastSkillshot(SkillQ, Target)
		end
		-- else 
		-- 	if AutoCarry.MainMenu.AutoCarry and myHero:CanUseSpell(_Q) == READY then
		-- 		TargetPrediction__OnTick()
		-- 		local Qpos, minCol, nextHealth = ProdictQreg:GetPrediction(Target)
		-- 		CastSpell(_Q, Qpos.x, Qpos.z)
		-- 	end
	end

	--PrintChat("Debug3")
	if Menu.minbounces == 1 and Menu.useW and AutoCarry.MainMenu.AutoCarry and ValidTarget(Target) and WREADY and Target ~= nil then
		CastSpell(_W, Target)
		--PrintChat("Debug33")
	end
	--PrintChat("Debug4")
	--Convoluted W logic happening. Stand back and watch it fail!
	if ValidTarget(Target) and Menu.minbounces > 1 and Menu.useW and AutoCarry.MainMenu.AutoCarry and WREADY then 
		local currentbounces = 1 
		local bounce1hero
		local bounce2hero
		local bounceteam
		for I = 1, heroManager.iCount do
			local hero = heroManager:GetHero(I)
			if GetDistance(hero) <= Wrange and hero ~= myHero and not hero.dead then
				bounceoneteam = hero.team
				if bounceoneteam == myHero.team then
					if hero.maxHealth - hero.health >= 65 then
						--bouncepos1[x] = hero.x
						--bouncepos1[y] = hero.y
						--bouncepos1[z] = hero.z
						bounce1hero = hero
					end
				else
					bounce1hero = hero
				end
			end
		end
		if bounce1hero ~= nil then
			for I = 1, heroManager.iCount do
				local hero = heroManager:GetHero(I)
				currentdistance = GetDistance(hero, bounce1hero)
				if GetDistance(hero, bounce1hero) <= Wbouncerange and hero.team ~= bounce1hero.team and not hero.dead and hero.charName ~= bounce1hero.charName then
					bounce2hero = hero
					if Menu.minbounces == 2 then
						CastSpell(_W, bounce1hero)
					end
				end
			end
		end

		if bounce1hero ~= nil and bounce2hero ~= nil then
			for I = 1, heroManager.iCount do
				local hero = heroManager:GetHero(I)
				if GetDistance(hero, bounce2hero) <= Wbouncerange and hero.team == bounce1hero.team and not hero.dead and hero.charName ~= bounce1hero.charName and hero.charName ~= bounce2hero.charName then
					if Menu.minbounces == 3 then
						CastSpell(_W, bounce1hero)
					end
				end
			end
		end
	end
	--PrintChat("Debug5")
	if ValidTarget(Target) and Menu.useE and AutoCarry.MainMenu.AutoCarry then
		allytable = GetAllyHeroes()
		local currenthero = myHero
		for i, v in ipairs(allytable) do
			if v.damage > myHero.damage and GetDistance(v) <= Erange and not v.dead then
				currenthero = v
			end
		end 
		CastSpell(_E, currenthero)
	end 
	--PrintChat("Debug6")
end

function PluginOnDraw()
	if Target ~= nil then
		DrawCircle(myHero.x, myHero.y, myHero.z, 725, 0x7F006E)
		DrawCircle(myHero.x, myHero.y, myHero.z, 875, 0xCC0000)
	end
end

function mainLoad()
	if AutoCarry.Skills then IsSACReborn = true else IsSACReborn = false end
	if IsSACReborn then AutoCarry.Skills:DisableAll() end
	Carry = AutoCarry.MainMenu
	Menu = AutoCarry.PluginMenu
	Wrange = 725
	Wbouncerange = 675
	Erange = 800
	Qrange = 850
	if IsSACReborn then
		SkillQ = AutoCarry.Skills:NewSkill(false, _Q, Qrange, "BUBBLE", AutoCarry.SPELL_CIRCLE, 0, false, false, math.huge, 950, 200, false)
	else
		SkillQ = {spellKey = _Q, range = math.huge, speed = math.huge, delay = 950, width = 200, configName = "NamiQ", displayName = "Nami Q", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = false }
	end
	ignite = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)
	PrintChat("Sidas Autocarry Nami Plugin by Dienofail loaded")
    if IsSACReborn then
        AutoCarry.Crosshair:SetSkillCrosshairRange(900)
    else
        AutoCarry.SkillsCrosshair.range = 900
    end
end

function mainMenu()
	Menu:addParam("useQ", "Use (Q)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useW", "Use (W)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useE", "Use (E)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useR", "Use (R)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("drawQ", "Draw (Q)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("drawR", "Draw (R)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("minbounces", "Minimum W Bounces", SCRIPT_PARAM_SLICE, 1, 1, 3, 0)
end

function Checks()
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	WREADY = (myHero:CanUseSpell(_W) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY)
	if IsSACReborn then Target = AutoCarry.Crosshair:GetTarget() else Target = AutoCarry.GetAttackTarget() end
end
