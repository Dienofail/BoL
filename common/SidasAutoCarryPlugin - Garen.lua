--[[

Complex Garen - by dienofail


v0.01 - release

v0.02 - added non-VIP non interrupt support

v0.03 - Fixes

v0.04 - fixes

]]

if myHero.charName ~= "Garen" then return end

local Qbeingcast = false
local Ebeingcast = false
local LastECastTime = 0
function PluginOnLoad()
	--Menu
	mainLoad()
	mainMenu()
	if VIP_USER then 
		AdvancedCallback:bind('OnGainBuff', function(unit, buff) OnGainBuff(unit, buff) end)
	    AdvancedCallback:bind('OnLoseBuff', function(unit, buff) OnLoseBuff(unit, buff) end)
	end
end


function PluginOnTick()
	Checks()
	ScanBuffs()
	if not VIP_USER then
		NonVIPChecks()
	end
	if Target then
		if Menu.useQ and Menu.killsteal then
			CastQ()
		end
		if Menu.useR and Menu.killsteal then
			CastRignite()
			CastR()
			AutoIgnite()
		end

		if AutoCarry.MainMenu.AutoCarry then
			if Menu.useQ and GetDistance(Target) <= qRange and QREADY and not Ebeingcast then
				if IsSACReborn then
					SkillQ:Cast(Target)
				else
					CastSpell(_Q)
				end
			end

			for I = 1, heroManager.iCount do
				local hero = heroManager:GetHero(I)
				currentdistance = GetDistance(hero, myHero)
				if currentdistance <= 1001 and Menu.qdistance <= currentdistance and QREADY and not Ebeingcast then
					CastSpell(_Q)
				end
			end

			if Menu.useQ and Menu.qdistance <= GetDistance(Target) and GetDistance(Target) <= 1000 and QREADY and not Ebeingcast then
				CastSpell(_Q)
			end

			if Menu.useW and WREADY and GetDistance(Target) <= rRange and not Ebeingcast then
				CastSpell(_W)
			end

			if VIP_USER then 
				if Menu.useE and GetDistance(Target) <= eRange and EREADY and not Qbeingcastand and not QREADY then
					CastSpell(_E)
				end
			else
				if Menu.useE and GetDistance(Target) <= eRange and EREADY and not Qbeingcastand and not QREADY then
					CastSpell(_E)
				end
			end
		end
	end
end


function CastR()
	if not RREADY then return true end

	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if ValidTarget(enemy, rRange) and getDmg("R", enemy, myHero) >= enemy.health then CastSpell(_R, enemy) end
	end
end

function CastQ()

	if not QREADY then return true end

	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if ValidTarget(enemy, qRange) and getDmg("Q", enemy, myHero) >= enemy.health then CastSpell(_Q, enemy) end
	end
end

function PluginOnProcessSpell(unit, spell)
	if unit.isMe and spell.name == 'GarenE' then
		LastECastTime = GetTickCount()
	end
end


function CheckE()
	if GetTickCount - LastECastTime > 3000 then
		Ebeingcast = false
	else
		Ebeingcast = true
	end
end

function CastRignite()
	if not RREADY then return true end
	if not IGNITEReady then return true end
	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if ValidTarget(enemy, rRange) and getDmg("R", enemy, myHero) + getDmg("IGNITE", enemy, myHero) >= enemy.health then
			CastSpell(_R, enemy)
			CastSpell(ignite, enemy)
		end
	end
end

function AutoIgnite()
	if not IGNITEReady then return true end

	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if ValidTarget(enemy, 600) then
			if getDmg("IGNITE",enemy,myHero) >= enemy.health then
				CastSpell(ignite, enemy)
			end
		end
	end
end

function mainLoad()
	if AutoCarry.Skills then IsSACReborn = true else IsSACReborn = false end
	if IsSACReborn then AutoCarry.Skills:DisableAll() end
	Carry = AutoCarry.MainMenu
	Menu = AutoCarry.PluginMenu
	qRange = 300
	eRange = 560
	rRange = 400
	QREADY = false
	WREADY = false
	EREADY = false
	RREADY = false
	if IsSACReborn then
		SkillQ = AutoCarry.Skills:NewSkill(false, _Q, qRange, "Decisive Strike", AutoCarry.SPELL_TARGETED, 0, true, true, math.huge, 240, 0, 0)
		SkillR = AutoCarry.Skills:NewSkill(false, _R, rRange, "Demacian Justice", AutoCarry.SPELL_TARGETED, 0, false, false, math.huge, 240, 0, 0)
	end
	ignite = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)
	PrintChat("Sidas Autocarry Garen Plugin by Dienofail loaded")
	if VIP_USER then 
		AdvancedCallback:bind('OnGainBuff', function(unit, buff) OnGainBuff(unit, buff) end)
	    AdvancedCallback:bind('OnLoseBuff', function(unit, buff) OnLoseBuff(unit, buff) end)
	end
end

function mainMenu()
	Menu:addParam("useQ", "Use (Q)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useW", "Use (W)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useE", "Use (E)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useR", "Use (R)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useQE", "Use E after Q", SCRIPT_PARAM_ONOFF, false)
	Menu:addParam("qdistance", "Use (Q) Chase Distance", SCRIPT_PARAM_SLICE, 150, 0, 1000, 150)
	Menu:addParam("killsteal", "Kill Steal with R, Q, or R and Ignite", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("drawQ", "Draw (Q)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("drawR", "Draw (R)", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("Qslows", "Cast Q on slows", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("drawtoggle", "Draw Text On Champion Toggle", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("Debug", "Debug", SCRIPT_PARAM_ONOFF, false)
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
	if QREADY then
		Qbeingcast = false
	end
	local E_spell = myHero:GetSpellData(_E)
end

function PluginOnAnimation(object, animation)
	if object.isMe and animation == "Spell1" then
		if Menu.useQE and EREADY then CastSpell(_E) end
	end
end

function PluginOnDraw()

	if Menu.Debug then
		DrawText3D("Current Qbeingcast status is " .. tostring(Qbeingcast), myHero.x, myHero.y, myHero.z, 25,  ARGB(255,255,0,0), true)
		DrawText3D("Current Ebeingcast status is " .. tostring(Ebeingcast), myHero.x+100, myHero.y+100, myHero.z+100, 25,  ARGB(255,255,0,0), true)
		--DrawText3D("current LastDetonateTime is " .. tostring(LastDetonateTime), myHero.x-100, myHero.y-100, myHero.z-100, 25, ARGB(255,255,0,0), true )

	end

	if RREADY and Menu.drawQ then
		DrawCircle(myHero.x, myHero.y, myHero.z, rRange, 0x7F006E)
	end

	if QREADY and Menu.drawQ then
		DrawCircle(myHero.x, myHero.y, myHero.z, qRange, 0x7F006E)
	end

	if Menu.drawtoggle then
	    for _, enemy in pairs(GetEnemyHeroes()) do
	        local pos= WorldToScreen(D3DXVECTOR3(enemy.x, enemy.y, enemy.z))
	        local posX = pos.x - 35
	        local posY = pos.y - 50
	        if getDmg("R", enemy, myHero) >= enemy.health and RREADY and not enemy.dead then
	        	DrawText("R HIM!", 25 , posX ,posY  , ARGB(255,0,255,0))    
	        end
	        if getDmg("R", enemy, myHero) + getDmg("IGNITE", enemy, myHero) >= enemy.health and RREADY and IGNITEReady  and not enemy.dead then
	        	DrawText("R+IGNITE HIM!", 25 , posX ,posY  , ARGB(255,0,255,0))    
	        end
	        if getDmg("R", enemy, myHero) + getDmg("IGNITE", enemy, myHero) >= enemy.health and RREADY and IGNITEReady and QREADY  and not enemy.dead then
	        	DrawText("R+Q+IGNITE HIM!", 25 , posX ,posY  , ARGB(255,0,255,0))    
	        end
	        if getDmg("Q", enemy, myHero) >= enemy.health and QREADY  and not enemy.dead then
	        	DrawText("Q HIM!", 25 , posX ,posY  , ARGB(255,0,255,0))    
	        end
	    end
	end
end

function OnGainBuff(unit, buff)
    if buff.name == 'GarenQ' and unit.isMe then
    	Qbeingcast = true
    end

    if buff.name == 'GarenE' and unit.isMe then
    	Ebeingcast = true
    end 
    if buff.type == 10 and myHero:CanUseSpell(_Q) == READY and unit.isMe then
    	CastSpell(_Q)
    end
end

function OnLoseBuff(unit, buff)
    if buff.name == 'GarenQ' and unit.isMe then
    	Qbeingcast = false

		-- if Menu.Debug then
		-- 	print('Garen Q buff return true')
		-- end
    end

    if buff.name == 'GarenE' and unit.isMe then
    	Ebeingcast = false

    end
end


function ScanBuffs()
-- 	for i = 1, myHero.buffCount, 1 do
-- 		local buff = myHero:getBuff(i)
-- 		if buff.name == "GarenQ" and buff.valid then
-- 			if Menu.Debug then
-- 				print('Garen Q buff return true')
-- 			end
-- 			Qbeingcast = true
-- 		end
-- 		if buff.name == 'GarenE' and buff.valid then
-- 			Ebeingcast = true
-- 			if Menu.Debug then
-- 				print('Garen E buff return true')
-- 			end
-- 		end
-- 	end
end


function NonVIPChecks()
	for i = 1, myHero.buffCount, 1 do
		local buff = myHero:getBuff(i)
		if buff.valid then
			if buff.name == "Wither" and Menu.Qslows and myHero:CanUseSpell(_Q)==READY then
				CastSpell(_Q)
			end
			if buff.name == "IceBlast" and Menu.Qslows and myHero:CanUseSpell(_Q)==READY then
				CastSpell(_Q)
			end
			if buff.name == "LuluWTwo" and Menu.Qslows and myHero:CanUseSpell(_Q)==READY then
				CastSpell(_Q)
			end
			if buff.name == "EnchantedCrystalArrow" and Menu.Qslows and myHero:CanUseSpell(_Q)==READY then
				CastSpell(_Q)
			end
			if buff.type == 10 and Menu.Qslows and myHero:CanUseSpell(_Q)==READY then
				CastSpell(_Q)
			end
		end
	end
end
