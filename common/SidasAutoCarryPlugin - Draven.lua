local version = "0.05"

--[[

Sida's AutoCarry Plugin - Draven 

by Dienofail

WITH HUGE CREDIT TO SIDA FOR HELPING AND ADDING NECESSARY FUNCTIONS TO REBORN


Currently requires Reborn v48 or above, and Prodiction. 


v0.00 - release


v0.01 - animation canceling fixed


v0.02 - All modes for SAC added. Mana manager for E and W added. R KS options added. Drawing options changed. Moved to beta phase. 


v0.03 - Movement near reticle adjusted back something similar to v0.01. If this issue presists I'll do a full revert to alpha code. 
R and prodiction dependency removed until lib issues are resolved - R KS option disabled for now.


v0.03b - Changed reticle object and fixed some typos. 


v0.03c - Added slider for reticle catch position 


v0.03d - Added disable movement near reticle option


v0.04 - Added github autoupdater.


v0.05 - Updated Q name 

]]

local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/Dienofail/BoL/master/common/SidasAutoCarryPlugin%20-%20Draven.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = LIB_PATH.."SidasAutoCarryPlugin - Draven.lua"
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>SAC DRAVEN:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
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
if myHero.charName ~= "Draven" then return end

class 'Plugin'
--require 'Prodiction'
function Plugin:__init()

end
local HKX = string.byte("X")
local HKZ = string.byte("Z")
local HKX = string.byte("X")
local HKC = string.byte("C")
local CurrentMS = myHero.ms
local CurrentAS = myHero.attackSpeed
local Skills, Keys, Items, Data, Jungle, Helper, MyHero, Minions, Crosshair, Orbwalker = AutoCarry.Helper:GetClasses()
PrintChat('Main load called')
if AutoCarry.Skills then IsSACReborn = true else IsSACReborn = false end
if IsSACReborn then AutoCarry.Skills:DisableAll() end
--PrintChat('Debug1')
local eRange = 1100
local eCastTime = 0.251
local eRadius = 130
local qRadius = 90
local eSpeed = 1400
local QREADY = false
local WREADY = false
local EREADY = false
local RREADY = false
local qTime = 1800
local qStacks = 0
local closestReticle = nil
local closestmouseReticle = nil
local baseAS = 0.679
local qBuff = 0
local reticles = {}
local MovePoint = nil
local BlockQ = false
local time_difference = 0
local Draven_Rs = {}
local Prodict = {}
local Qlastendtime = 0                        
--PrintChat('Debug2')
if IsSACReborn then
	SkillE = AutoCarry.Skills:NewSkill(false, _E, 1100, "DRAVEN E", AutoCarry.SPELL_LINEAR, 0, false, false, 1.400, 251, 130, false)
	SkillR = AutoCarry.Skills:NewSkill(false, _R, 2000, "DRAVEN R", AutoCarry.SPELL_LINEAR, 0, false, false, 2.000, 500, 160, false)
else
	SkillE = {spellKey = _E, range = 1100, speed = 1.400, delay = 251, width = 130, configName = "DRAVEN E", displayName = "DRAVEN E", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = false }
	SkillR = {spellKey = _R, range = 2500, speed = 2.000, delay = 500, width = 160, configName = "DRAVEN R", displayName = "DRAVEN R", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = false }
end
--ignite = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)
--PrintChat('Debug3')
if VIP_USER then 

end

function Plugin:__init()
Crosshair:SetSkillCrosshairRange(2500)
-- Prodict = ProdictManager.GetInstance()
-- ProdictR = Prodict:AddProdictionObject(_R, 10000, 2000, 0.500, 160)
end

function CalculateBonusQ(minion)
	--print('Calculate bonus Q called')
	current_Q = myHero:GetSpellData(_Q)
	--print(getDmg("Q", minion, myHero))
	if qBuff > 0 then 
		bonus_damage = 0.80 * (myHero.damage+myHero.addDamage) * (0.35 + current_Q.level * 0.1)
		--bonus_damage = getDmg("Q", minion, myHero)
		--print('Applying bonus_damage of ' .. tostring(bonus_damage))
		return bonus_damage
	else
		--print('Not applying bonus damage, returning 0')
		return 0
	end
end


function Plugin:OnTick()
	--Helper:Debug(CurrentAS)
	current_R = myHero:GetSpellData(_R)
	--print(current_R.name)

	Checks()
	if tablelength(reticles) > 0 then
		for _, particle in pairs(reticles) do
	        if closestReticle and closestReticle.object.valid and particle.object and particle.object.valid then
	            if GetDistance(particle.object) > GetDistance(closestReticle.object) then
	                closestReticle = particle
	            end
	        else
	            closestReticle = particle
	        end
	    end

	    for _, particle in pairs(reticles) do
	        if closestmouseReticle and closestmouseReticle.object.valid and particle.object and particle.object.valid then
	            if GetDistance(particle.object, mousePos) > GetDistance(closestmouseReticle.object, mousePos) then
	                closestmouseReticle = particle
	            end
	        else
	            closestmouseReticle = particle
	        end
	    end
   	end

   	if Keys.AutoCarry or Keys.MixedMode or Keys.LastHit or Keys.LaneClear or Menu.CastQManual then
   		--Orbwalker:OverrideOrbwalkLocation(position)
		if Menu.CastMouse and closestmouseReticle ~= nil and closestmouseReticle.object.valid and tablelength(reticles) > 0 then
	    	if GetDistance(closestmouseReticle.object, mousePos) < Menu.CastMouseDistance and GetDistance(closestmouseReticle.object, mousePos) < Menu.CatchOffset then	
	    		Orbwalker:OverrideOrbwalkLocation(nil)
                if Menu.StopMovement then
                    MyHero:MovementEnabled(false)
                end
	    	elseif GetDistance(closestmouseReticle.object, mousePos) < Menu.CastMouseDistance and GetDistance(closestmouseReticle.object, mousePos) >= Menu.CatchOffset then 
	    		Orbwalker:OverrideOrbwalkLocation(Vector(closestmouseReticle.object.x, 0, closestmouseReticle.object.z))
                if Menu.StopMovement then
                    MyHero:MovementEnabled(true)
                end
	    -- elseif not Menu.CastMouse and closestReticle ~= nil and closestReticle.object.valid and tablelength(reticles) > 0 then
	    -- 	if GetDistance(closestReticle.object, myHero) < 500 then
	    -- 		MyHero:OrbwalkingEnabled(false)
	    -- 		Orbwalker:OrbwalkToPosition(AutoCarry.Crosshair:GetTarget(), Vector(closestReticle.object.x, 0, closestReticle.object.z))
	    -- 	elseif GetDistance(closestReticle.object, myHero) < qRadius then
	    -- 		MyHero:OrbwalkingEnabled(true)
	    -- 		--Orbwalker:OrbwalkToPosition(AutoCarry.Crosshair:GetTarget(), Vector(closestReticle.object.x, 0, closestReticle.object.z))
	    -- 	else
	    -- 		MyHero:OrbwalkingEnabled(true)
	    -- 	end
	   		end
	    else
            if Menu.StopMovement then
                MyHero:MovementEnabled(true)
            end
	    	Orbwalker:OverrideOrbwalkLocation(nil)
	    end

	else
        if Menu.StopMovement then
            MyHero:MovementEnabled(true)
        end
		Orbwalker:OverrideOrbwalkLocation(nil)
   	end

	if Keys.AutoCarry and ValidTarget(Target) and Target ~= nil then
		CheckQ()
		CastE()
		CastW()
		CastR()
	end
	--CheckRreturn()
	--CheckRKS()
end

-- function CheckRreturn()
-- 	local mid_point
-- 	if tablelength(Draven_Rs) == 2 then
-- 		mid_point = ReturnMidPoint(Draven_Rs[1], Draven_Rs[2])
-- 		if GetDistance(mid_point, R_target) < 400 then
-- 			--print(GetDistance(mid_point, R_target))
-- 			--print('R return cast!')
-- 			CastSpell(_R)
-- 		end
-- 	end
-- end


-- function CheckRKS()
-- 	if Menu.useR and RREADY and Menu.killsteal then
-- 		local enemyTable = {}
-- 		for I = 1, heroManager.iCount do
-- 			local hero = heroManager:GetHero(I)
-- 			if hero.team ~= myHero.team and not hero.dead then
-- 				table.insert(enemyTable, hero)
-- 			end
-- 		end
-- 		if tablelength(enemyTable) > 0 then
-- 			for i, enemyHero in ipairs(enemyTable) do
-- 				if 2 * getDmg("R", enemyHero, myHero) > enemyHero.health and not enemyHero.dead and RREADY then
-- 					CastPosition, Time, HitChance = ProdictR:GetPrediction(enemyHero)
-- 					--PrintChat("R distance incremented " .. tostring(current_R_distance))
-- 					if GetDistance(CastPosition, myHero) < Menu.Rdistance then
-- 						CastSpell(_R, CastPosition.x, CastPosition.z)
-- 					end
-- 				end
-- 				--[[if GetDistance(enemyHero, myHero) < current_R_distance then
-- 					current_R_distance = GetDistance(enemyHero, myHero)
-- 					--PrintChat("R distance incremented " .. tostring(current_R_distance))
-- 				end]]
-- 			end
-- 		end
-- 	end
-- end

function ReturnMidPoint(pos1, pos2)
	local return_pos 
	xpos = (pos1.x + pos2.x) / 2
	zpos = (pos1.z + pos2.z) / 2
	return_pos = Vector(xpos, 0, zpos)
	--print(return_pos)
	return return_pos
end


function Plugin:OnDraw()
	if Menu.drawQ then
		for _, particle in pairs(reticles) do
			Helper:DrawCircleObject(particle.object, qRadius, ARGB(255, 0, 255, 0), 1)
		end
	end

	if Menu.drawQ and Menu.CastMouse and closestmouseReticle ~= nil and closestmouseReticle.object.valid and GetDistance(closestmouseReticle.object, mousePos) < Menu.CastMouseDistance then
		Helper:DrawCircleObject(mousePos, Menu.CastMouseDistance, ARGB(255, 255, 0, 0), 1)
	elseif Menu.drawQ and Menu.CastMouse then
		Helper:DrawCircleObject(mousePos, Menu.CastMouseDistance, ARGB(255, 0, 0, 255), 1)
	end

	if Menu.drawQ and Menu.Debug3 then
		--DrawText3D("Current autocarry status is " .. tostring(MyHero:AttacksEnabled()), myHero.x, myHero.y, myHero.z, 25,  ARGB(255,0,255,0), true)
	end

	if Menu.CastMouse and closestmouseReticle ~= nil and closestmouseReticle.object.valid and tablelength(reticles) > 0 and Menu.Debug3 then
		Helper:DrawCircleObject(MovePoint, qRadius, ARGB(255, 0, 160, 0), 1)
	end
end


function Plugin:OnCreateObj(obj)
	--Credit to Sida
    if obj.name == "Draven_Q_buf.troy" then
        qBuff = qBuff + 1
        if Menu.Debug then
        	print('Upon creation, Qbuff is ')
        	DebugPrint(qBuff)
        end
    end

    -- for _, particle in pairs(qParticles) do
	   --  if obj ~= nil and obj.valid and obj.name:lower():find(particle:lower()) and GetDistance(obj) < 333 then
	   --      attackedSuccessfully()
	   --  end
    -- end
               
    if obj ~= nil and obj.name ~= nil and obj.x ~= nil and obj.z ~= nil then
        if obj.name == "Draven_Q_reticle_self.troy" or obj.name == 'Q_reticle_self' or obj.name == 'Q_reticle_self.troy' then
        	if Menu.Debug then
        		print('Draven Q reticle created')
        	end
            table.insert(reticles, {object = obj, created = GetTickCount()})
            DebugPrint(tablelength(reticles))
        elseif obj.name == "draven_spinning_buff_end_sound.troy" then
            qStacks = 0
        elseif obj.name == "Draven_R_cas.troy" and obj.team ~= TEAM_ENEMY then
        	if Menu.Debug3 then
				print('Draven R mis created')
        	end
            table.insert(Draven_Rs, obj)
        end
    --'Draven_R_cas.troy'
    --'Draven_R_cas_ground.troy'
    end
end


function Plugin:OnDeleteObj(obj)
	--Credit to Sida
	if obj.name == "Draven_Q_reticle_self.troy" or obj.name == 'Q_reticle_self' or obj.name == 'Q_reticle_self.troy' then
        if GetDistance(obj) > qRadius then
            qStacks = qStacks - 1
            if Menu.Debug2 then
            	print('Upon deletion, Qstack is ')
            	DebugPrint(qStacks)
            end
        end
        for i, reticle in ipairs(reticles) do
            if obj and obj.valid and reticle.object and reticle.object.valid and obj.x == reticle.object.x and obj.z == reticle.object.z then
                if Menu.Debug then
                	print('Draven Q reticle removed')
                end
                table.remove(reticles, i)
                DebugPrint(tablelength(reticles))
                current_tick = GetTickCount()
                tick_difference = current_tick - reticle.created
                if Menu.Debug3 then
                	print(tick_difference)
                end
            end
        end
    elseif obj.name == "Draven_Q_buf.troy" then
        qBuff = qBuff - 1
        if Menu.Debug then
	        print('Upon deletion, Qbuff is ')
	        DebugPrint(qBuff)
	    end                      
	elseif obj.name == "Draven_R_cas.troy" then
        for i, Draven_R in ipairs(Draven_Rs) do
            if obj and obj.valid and Draven_R and Draven_R.valid and obj == Draven_R then
                if Menu.Debug3 then
                	print('Draven R removed')
                end
                table.remove(Draven_Rs, i)
                DebugPrint(tablelength(Draven_Rs))
            end
        end
    end
end




function Plugin:OnProcessSpell(unit, spell)
	--Credit to Manciuszz and Silent Man. This is literally copy and paste. 
    if unit.isMe and spell.name == "dravenspinning" then
        qStacks = qStacks + 1
    end



    if not Menu.PushAwayGapclosers then return end
    local jarvanAddition = unit.charName == "JarvanIV" and unit:CanUseSpell(_Q) ~= READY and _R or _Q -- Did not want to break the table below.
    local isAGapcloserUnit = {
--        ['Ahri']        = {true, spell = _R, range = 450,   projSpeed = 2200},
        ['Aatrox']      = {true, spell = _Q,                  range = 1000,  projSpeed = 1200, },
        ['Akali']       = {true, spell = _R,                  range = 800,   projSpeed = 2200, }, -- Targeted ability
        ['Alistar']     = {true, spell = _W,                  range = 650,   projSpeed = 2000, }, -- Targeted ability
        ['Diana']       = {true, spell = _R,                  range = 825,   projSpeed = 2000, }, -- Targeted ability
        ['Gragas']      = {true, spell = _E,                  range = 600,   projSpeed = 2000, },
        ['Graves']      = {true, spell = _E,                  range = 425,   projSpeed = 2000, exeption = true },
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
--                print('Gapcloser: ',unit.charName, ' Target: ', (spell.target ~= nil and spell.target.name or 'NONE'), " ", spell.name, " ", spell.projectileID)
        CastSpell(_E, unit.x, unit.z)
            else
                spellExpired = false
                informationTable = {
                    spellSource = unit,
                    spellCastedTick = GetTickCount(),
                    spellStartPos = Point(spell.startPos.x, spell.startPos.z),
                    spellEndPos = Point(spell.endPos.x, spell.endPos.z),
                    spellRange = isAGapcloserUnit[unit.charName].range,
                    spellSpeed = isAGapcloserUnit[unit.charName].projSpeed,
                    spellIsAnExpetion = isAGapcloserUnit[unit.charName].exeption or false,
                }
            end
        end
    end
end

function Plugin:OnSendPacket(packet)
	-- New handler for SAC: Reborn
	local p = Packet(packet)
	--if p:get("spellId") == SkillE.spellKey and not (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.LaneClear or AutoCarry.MainMenu.MixedMode or AutoCarry.PluginMenu.SlowE) then
		--p:block()
	--end
	if Menu.BlockMovement and VIP_USER then 
	    if p.header == 0x71 and AutoCarry.MainMenu.AutoCarry and Menu.BlockQ then --and Cast then -- 2nd cast of channel spells packet2
			p.pos = 1
			local packetResult = {
                dwArg1 = p.dwArg1,
                dwArg2 = p.dwArg2,
                sourceNetworkId = p:DecodeF(),
                type = p:Decode1(),
                x = p:DecodeF(),
                y = p:DecodeF(),
                targetNetworkId = p:DecodeF(),
                waypointCount = p:Decode1() / 2,
                unitNetworkId = p:DecodeF()
            }
	        
	        if packetResult.type == 3 then -- 0x80 == Q
	            p:Block()
	            PrintChat("Packet blocked")
	        end
	    end
	  --   if packet.header == 0xE5 and isPressedQ and Menu.manualQ then --and Cast then -- 2nd cast of channel spells packet2
			-- packet.pos = 5
	  --       spelltype = packet:Decode1()
	  --       if spelltype == 0x80 then -- 0x80 == Q
	  --           packet.pos = 1
	  --           packet:Block()
	  --           --PrintChat("Packet blocked")
	  --       end
	  --   end
	end
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
	if qStacks < qBuff then
		qStacks = qBuff
	end
	if qStacks > qBuff + tablelength(reticles) then
		qStacks = qBuff + tablelength(reticles)
	end
	CurrentMS = myHero.ms
	CurrentAS = 0.679 * myHero.attackSpeed
	R_target = nil    
end


function CheckQ()
	numQs = qBuff + tablelength(reticles)
	if numQs < 2 and ValidTarget(Target) and Menu.useQ and QREADY and not Menu.thirdQ and not Menu.fourthQ then
		CastSpell(_Q)
	end
	if numQs < 3 and ValidTarget(Target) and Menu.useQ and QREADY and Menu.thirdQ and not Menu.FourthQ then
		CastSpell(_Q)
	end
	if numQs < 4 and ValidTarget(Target) and Menu.useQ and QREADY and Menu.fourthQ then
		CastSpell(_Q)
	end

end


function CastW()
	if not TargetHaveBuff("dravenfurybuff" , myHero) and ValidTarget(Target) and WREADY and Menu.useW and GetDistance(Target, myHero) < 1200 and not IsMyManaLow() then
		CastSpell(_W)
	end
end


function CastE()
	if ValidTarget(Target) and GetDistance(Target, myHero) > Menu.Edistance  and GetDistance(Target, myHero) < Menu.Edistance2 and GetDistance(Target, myHero) < eRange and EREADY and Menu.useE and not IsMyManaLow() then
		SkillE:Cast(Target)
	end
end


function CastR()
	if ValidTarget(Target) and GetDistance(Target, myHero) < 2000 and RREADY and Menu.useR and getDmg("R", Target, myHero) * 2 > Target.health then
		SkillR:Cast(Target)
		R_target = Target
	end
end




function CheckQstacks()
	toreturnint = 0
	for i = 1, myHero.buffCount, 1 do
		local buff = myHero:getBuff(i)
		if buff.valid then
			if buff.name == "dravenspinning" then
				toreturnint = buff.stack
				return toreturnint
			end
		end
	end
end




function tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

function DebugPrint(to_print)
	if Menu.Debug then
		print(to_print)
	end
end

--Credit Honda7
-- function MoveToPoint(Point)
-- 	--if (Orbwalker.stage == AutoCarry.STAGE_MOVE) and not Helper:IsEvading() then --We are not attacking/Evading stuff
-- 	if not Helper:IsEvading() and not Orbwalker:IsShooting() then
-- 		if GetDistance(Point) > 20 then
-- 			myHero:MoveTo(Point.x, Point.z)
-- 		end
-- 	end
-- end


function IsMyManaLow()
    if myHero.mana < (myHero.maxMana * ( Menu.mManager / 100)) then
        return true
    else
        return false
    end
end

AutoCarry.Plugins:RegisterBonusLastHitDamage(CalculateBonusQ)
Menu = AutoCarry.Plugins:RegisterPlugin(Plugin(), "Draven") 
Menu:addParam("useQ", "Use (Q)", SCRIPT_PARAM_ONOFF, true)
Menu:addParam("useW", "Use (W)", SCRIPT_PARAM_ONOFF, true)
Menu:addParam("useE", "Use (E)", SCRIPT_PARAM_ONOFF, true)
Menu:addParam("useR", "Use (R)", SCRIPT_PARAM_ONOFF, true)
Menu:addParam("Edistance", "Use (E) Minumum Distance", SCRIPT_PARAM_SLICE, 0, 0, 1100, 0)
Menu:addParam("Edistance2", "Use (E) Maxmium Distance", SCRIPT_PARAM_SLICE, 1100, 0, 1100, 0)
--Menu:addParam("killsteal", "Kill Steal with R", SCRIPT_PARAM_ONOFF, true)
--Menu:addParam("Rdistance", "Use (R) KS Distance", SCRIPT_PARAM_SLICE, 0, 0, 10000, 0)
Menu:addParam("drawQ", "Draw (Q)", SCRIPT_PARAM_ONOFF, true)
Menu:addParam("drawR", "Draw (R)", SCRIPT_PARAM_ONOFF, true)
--Menu:addParam("manualQ", "Q PREDICTION KEY", SCRIPT_PARAM_ONKEYDOWN, false, )
Menu:addParam("thirdQ", "Use Three Qs", SCRIPT_PARAM_ONOFF, false)
Menu:addParam("fourthQ", "USE FOUR Qs WTF", SCRIPT_PARAM_ONOFF, false)
Menu:addParam("PushAwayGapclosers","Push Away Gap Closers", SCRIPT_PARAM_ONOFF, true)
Menu:addParam("CastEManual","Cast E Manual", SCRIPT_PARAM_ONKEYDOWN, false, HKX)
Menu:addParam("CastMouse", "Use mouse position", SCRIPT_PARAM_ONOFF, true)
Menu:addParam("CastMouseDistance", "Use mouse position distance", SCRIPT_PARAM_SLICE, 100, 0, 2000, 0)
Menu:addParam("CatchOffset", "Reticle catch offset", SCRIPT_PARAM_SLICE, 70, 50, 110, 0)
Menu:addParam("StopMovement", "Stop movement near reticle", SCRIPT_PARAM_ONOFF, false)
Menu:addParam("mManager", "W and E mana slider", SCRIPT_PARAM_SLICE, 0, 0, 100, 0)
Menu:addParam("CastQManual","Catch all axes", SCRIPT_PARAM_ONKEYDOWN, false, HKC)
Menu:addParam("Debug", "Debug Mode", SCRIPT_PARAM_ONOFF, false)
Menu:addParam("Debug2", "Debug2 Mode", SCRIPT_PARAM_ONOFF, false)
Menu:addParam("Debug3", "Debug3 Mode", SCRIPT_PARAM_ONOFF, false)
