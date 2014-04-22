--Dev tools by Dienofail - v0.0`

--Changelog:

--v0.01 release 
	
local starttime = nil
local time1 = 0
local time2 = 0
local time3 = 0
local time4 = 0
local Qstarttime = 0
local ZiggsQ = nil
local ZiggsR = nil
function OnLoad()
	HKQ = string.byte("Q")
	HKZ = string.byte("Z")
	HKY = string.byte("Y")
	PrintChat("Dev tools by Dienofail v0.01 loaded")
	Config = scriptConfig("Dev tools settings", "Dev tools")
	Config:addParam("movonoff", "movement recorder on or off", SCRIPT_PARAM_ONOFF, false)
	Config:addParam("TrackZiggsQ", "track ziggs Q", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("TrackZiggsR", "track ziggs R", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("buffonoff", "buff printer on or off", SCRIPT_PARAM_ONOFF, false)
	Config:addParam("packetonoff", "packetonoff", SCRIPT_PARAM_ONKEYDOWN, false, HKY)
	Config:addParam("objects", "objects_on_off", SCRIPT_PARAM_ONKEYDOWN, false, HKZ)
	--Config:addParam("printme", "print my position", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("trackQ", "track Q time", SCRIPT_PARAM_ONKEYDOWN, false, HKQ)
	starttime = os.clock()
	file = io.open(SCRIPT_PATH .. "Movements.txt", "w")
	file2 = io.open(SCRIPT_PATH .. "QCAST.txt", "w")
	file3 = io.open(SCRIPT_PATH .. "ZiggsQ.txt", "w")
	file4 = io.open(SCRIPT_PATH .. "ZiggsR.txt", "w")
	file5 = io.open(SCRIPT_PATH .. "Velkoz.txt", "w")
	file6 = io.open(SCRIPT_PATH .. "packet0xD7.txt", "w")
	file7 = io.open(SCRIPT_PATH .. "packets.txt", "w")
	file8 = io.open(SCRIPT_PATH .. "special_packets.txt", "w")
end

function writeLine(file, line)
	file:write(line.."\n")
end


function writeLine(file2, line)
	file2:write(line.."\n")
end

function OnTick()
	current_tick = os.clock()
	if Config.movonoff then
		local elapsed_time = os.clock() - starttime 
		file:write(tostring(elapsed_time) .. "\n")
		for I = 1, heroManager.iCount do
			local hero = heroManager:GetHero(I)
			if hero.visible then
				file:write(tostring(hero.networkID) .. "\t" .. tostring(hero.x) .. "\t" .. tostring(hero.z) .. "\t" .. tostring(hero.ms) .. "\t" .. tostring(hero.charName) .. "\t" .. tostring(hero.isMe) .. "\n")
			else
				file:write(tostring(hero.networkID) .. "\t" .. "nil" .. "\n")
			end
		end
		file:write("\n")
	end

	if Config.TrackZiggsQ and ZiggsQ and ZiggsQ ~= nil and ZiggsQ.valid then
		local current_distance = GetDistance(ZiggsQ, myHero)
		file3:write(tostring(current_tick) .. "\t" .. tostring(ZiggsQ.x) .. "\t" .. tostring(ZiggsQ.y) .. "\t" ..  tostring(ZiggsQ.z) .. "\t" .. tostring(current_distance) .. "\n")
	end

	if Config.TrackZiggsR and ZiggsR and ZiggsR ~= nil and ZiggsR.valid then
		file4:write(tostring(current_tick) .. "\t" .. tostring(ZiggsR.x) .. "\t" .. tostring(ZiggsR.y) .. "\t" ..  tostring(ZiggsR.z) .. "\n")
	end
	-- if Config.printme then
	-- 	print(tostring(myHero.x) .. ' ' .. tostring(myHero.z))
	-- end
	--if GetTickCount() - Delay > 2000 then releaseQ Delay = GetTickCount() end
end

function OnGainBuff(unit, buff)
    if unit == myHero and Config.buffonoff then
        PrintChat(tostring(buff.name) .. ' gained')
			time1 = os.clock()
    end
end

function OnLoseBuff(unit, buff)
	if unit == myHero and Config.buffonoff then
			PrintChat(tostring(buff.name) .. ' lost')
			time2 = os.clock() - time1
			--PrintChat('took ' .. tostring(time2))
	end
end

function OnProcessSpell(unit, spell)
	-- if unit.isMe and spell.name == 'ZiggsQ' then
	-- 	file3:write('Ziggs Q casted' .. "\n")
	-- 	file3:write(tostring(current_tick) .. "\t" .. tostring(myHero.x).. "\t" .. tostring(myHero.y) .. "\t" ..  tostring(myHero.z) .. "\n")
	-- end
end


function OnCreateObj(object)
	if Config.objects and GetDistance(object) < 1500 then
		print('Obj created ' .. tostring(object.name))
	end

	if (object.name == 'ZiggsQ.troy' or object.name == 'ZiggsQ2.troy' or object.name == 'ZiggsQ3.troy' and Config.TrackZiggsQ) then
		print('Ziggs Q object created')
		-- file3:write('Ziggs Q object created' .. "\n")
		-- file3:write(tostring(current_tick) .. "\t" .. tostring(object.x) .. "\t" .. tostring(object.y) .. "\t" .. tostring(object.z) .. "\n")
		ZiggsQ = object
	end 

	if object.name == 'ZiggsR.troy' and config.TrackZiggsR then
		print('Ziggs R object created')
		ZiggsR = object
	end

	if object.name == 'Draven_Q_tar.troy' and Config.objects then
		print('Qtar')
		print(object.x)
		print(object.z)
	end
	if object.name == 'Draven_Q_reticle_self.troy' and Config.objects  then
		print('Qreticle')
		print(object.x)
		print(object.z)
	end
end

function OnDeleteObj(object)
	if Config.objects and GetDistance(object) < 1500 then
		print('Obj destroyed ' .. tostring(object.name))
	end

	if object.name == 'ZiggsQ3.troy' and Config.TrackZiggsQ then
		-- file3:write('Ziggs Q object destroyed' .. "\n")
		-- file3:write(tostring(current_tick) .. "\t" .. tostring(object.x) .. "\t" .. tostring(object.y) .. "\t" .. tostring(object.z) .. "\n")
		file3:write("\n\n\n")
		ZiggsQ = nil
	end

	if object.name == 'Draven_Q_tar.troy' and Config.objects then
		print('Qtar')
		print(object.x)
		print(object.z)
	end
	if object.name == 'Draven_Q_reticle_self.troy' and Config.objects  then
		print('Qreticle')
		print(object.x)
		print(object.z)
	end
end

function OnRecvPacket(p)

	if p.header ~= nil and Config.packetonoff then
		file7:write('Sent' .. "\t" .. tostring(GetTickCount()) .. "\t" .. tostring(p.header) .. "\t")
	end

	if p.header == 0xD7 then
		PrintChat("0xD7 Received")
		p.pos = 5
		pos5 = p:DecodeF()
		p.pos = 112
		pos112 = p:Decode1()
		file6:write('0XD7 received at ' .. tostring(GetTickCount()))
		-- for i=1,134 do
		-- 	p.pos = i
		-- 	current_pos = p:DecodeF()
		-- 	current_pos2 = p:Decode4()
		-- 	current_pos3 = p:Decode2()
		-- 	current_pos4 = p:Decode1()
		-- 	file6:write('At position ' .. tostring(i) .. "\t" .. tostring(current_pos) .. "\t" .. tostring(current_pos2) .. "\t" .. tostring(current_pos3) .. "\t" .. tostring(current_pos4) .. '\n')
		-- end 
		local Enemies = GetEnemyHeroes()
		local target_enemy = nil
		for idx, champion in ipairs(Enemies) do
			if champion.networkID == pos5 then
				target_enemy = champion
			end
		end
		local enemyhealth = target_enemy.health
		print(enemyhealth)
	end

	if p.header == 0xE8 and Config.packetonoff then
		PrintChat("0xE8 Received printing to text")
		for i=1,88 do
			p.pos = i
			current_pos = p:DecodeF()
			current_pos2 = p:Decode4()
			current_pos3 = p:Decode2()
			current_pos4 = p:Decode1()
			file8:write('0XE8 At position ' .. tostring(i) .. "\t" .. tostring(current_pos) .. "\t" .. tostring(current_pos2) .. "\t" .. tostring(current_pos3) .. "\t" .. tostring(current_pos4) .. '\n')
		end 
	end

	if p.header == 0x62 and Config.packetonoff then
		PrintChat("0x62 Received printing to text")
		for i=1,407 do
			p.pos = i
			current_pos = p:DecodeF()
			current_pos2 = p:Decode4()
			current_pos3 = p:Decode2()
			current_pos4 = p:Decode1()
			file8:write('0x62 At position ' .. tostring(i) .. "\t" .. tostring(current_pos) .. "\t" .. tostring(current_pos2) .. "\t" .. tostring(current_pos3) .. "\t" .. tostring(current_pos4) .. '\n')
		end 
	end

	if p.header == 0xB4 and Config.packetonoff then
		PrintChat("0xB4 Received printing to text")
		for i=1,112 do
			p.pos = i
			current_pos = p:DecodeF()
			current_pos2 = p:Decode4()
			current_pos3 = p:Decode2()
			current_pos4 = p:Decode1()
			file8:write('0xB4 At position ' .. tostring(i) .. "\t" .. tostring(current_pos) .. "\t" .. tostring(current_pos2) .. "\t" .. tostring(current_pos3) .. "\t" .. tostring(current_pos4) .. '\n')
		end 
	end
end

function OnSendPacket(p)
--print("called")
	-- New handler for SAC: Reborn
	--if p:get("spellId") == SkillE.spellKey and not (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.LaneClear or AutoCarry.MainMenu.MixedMode or AutoCarry.PluginMenu.SlowE) then
		--p:block()
	--end

	if p.header ~= nil and Config.packetonoff then
		file7:write('Sent' .. "\t" .. tostring(GetTickCount()) .. "\t" .. tostring(p.header) .. "\t")
	end
		--[[if p.header == 0x9A and Config.packetonoff then
			p.pos = 5
			PrintChat('P.pos 5 for 0x9A is ' .. tostring(p:Decode1()))
		end]]
    if p.header == 0x99 and Config.packetonoff then --and Cast then -- 2nd cast of channel spells packet2
		p.pos = 1
		time3 = GetTickCount()
		PrintChat("0x99 SENT")
        result = {
            dwArg1 = p.dwArg1,
            dwArg2 = p.dwArg2,
            sourceNetworkId = p:DecodeF(),
            spellId = p:Decode1(),
            fromX = p:DecodeF(),
            fromY = p:DecodeF(),
            toX = p:DecodeF(),
            toY = p:DecodeF(),
            targetNetworkId = p:DecodeF()
        }
				--file2:write(result)
        PrintChat(tostring(result.dwArg1))
				PrintChat(tostring(result.dwArg2))
				PrintChat(tostring(result.sourceNetworkId))
				PrintChat(tostring(result.spellId))
				PrintChat(tostring(result.fromX))
				PrintChat(tostring(result.fromY))
				PrintChat(tostring(result.toX))
				PrintChat(tostring(result.toY))
				PrintChat(tostring(result.targetNetWorkId))
				-- file5:write(tostring(result.dwArg1))
				-- file5:write(tostring(result.dwArg2))
				-- file5:write(tostring(result.sourceNetworkId))
				-- file5:write(tostring(result.spellId))
				-- file5:write(tostring(result.fromX))
				-- file5:write(tostring(result.fromY))
				-- file5:write(tostring(result.toX))
				-- file5:write(tostring(result.toY))
				-- file5:write(tostring(result.targetNetWorkId))
    end
		
	  if p.header == 0xE5 and Config.packetonoff then --and Cast then -- 2nd cast of channel spells packet2
		PrintChat("0xE5 SENT")
		print(GetTickCount() - time3)
		p.pos = 1
        result = {
            dwArg1 = p.dwArg1,
            dwArg2 = p.dwArg2,
            sourceNetworkId = p:DecodeF(),
            spellId = p:Decode1(),
            fromX = p:DecodeF(),
            fromY = p:DecodeF(),
            fromZ = p:DecodeF(),
            toY = p:DecodeF(),
            abcd = p:DecodeF()
            --targetNetworkId = p:DecodeF()
        }
        PrintChat(tostring(result.dwArg1))
		PrintChat(tostring(result.dwArg2))
		PrintChat(tostring(result.sourceNetworkId))
		PrintChat(tostring(result.spellId))
		PrintChat(tostring(result.fromX))
		PrintChat(tostring(result.fromY))
		PrintChat(tostring(result.fromZ))
		PrintChat(tostring(result.toY))
        file5:write(tostring(result.dwArg1) .. "\n")
		file5:write(tostring(result.dwArg2) .. "\n")
		file5:write(tostring(result.sourceNetworkId) .. "\n")
		file5:write(tostring(result.spellId) .. "\n")
		file5:write(tostring(result.fromX) .. "\n")
		file5:write(tostring(result.fromY) .. "\n")
		file5:write(tostring(result.fromZ) .. "\n")
		file5:write(tostring(result.toY) .. "\n")
		file5:write(tostring(result.abcd) .. "\n")
		file5:write(tostring(mousePos.x) .. "\t" .. tostring(myHero.y) .. "\t" .. tostring(mousePos.z) .. "\n")
				--PrintChat(tostring(result.targetNetWorkId))
    end

    -- if p.header == 0x71 and Config.packetonoff then
    -- 	str = 0x71
    -- 	PrintChat('0x71 sent')
    -- 	local packetResult = {
    --                     dwArg1 = p.dwArg1,
    --                     dwArg2 = p.dwArg2,
    --                     sourceNetworkId = p:DecodeF(),
    --                     type = p:Decode1(),
    --                     x = p:DecodeF(),
    --                     y = p:DecodeF(),
    --                     targetNetworkId = p:DecodeF(),
    --                     waypointCount = p:Decode1() / 2,
    --                     unitNetworkId = p:DecodeF()
    --                 }
    -- 	PrintChat('Type is ' .. tostring(packetResult.type))
    -- end
end
