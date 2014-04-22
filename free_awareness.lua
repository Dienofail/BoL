local version = "0.12"

--[[

Free awareness by Dienofail and Xetrok, with credits to [TRUS] and vadash



v0.01 - release

v0.02 - I can't do math in seconds pls. 

v0.03 - Fixed autoupdater 

v0.04 - improved drawing 

v0.05 - Hidden objects added (traps/shrooms)

v0.06 - Jungler ping beta

v0.07 - Fixes by xetrok :D

v0.08 - Adjusted ping timer to 1 minute

v0.09 - Added slider for ping interval

v0.10 -	Added toggle key for showing vision (default = u)
	Added basic pink ward deletion while coming up with a better solution

v0.11 - Improved pink ward deletion and added crosses (credit = mtmoon)

--Credits

Honda7 for autoupdater


]]

local AUTOUPDATE = false
local UPDATE_NAME = "FreeAwareness"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/Dienofail/BoL/master/free_awareness.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>Free Awareness:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
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
--end Honda7


local LastPinged = 0
local CL = ChampionLane()
local blackColor  = 4278190080
local purpleColor = 4294902015
local greenColor  = 4278255360
local yellowColor = 4294967040
local vangaColor = 4294967295
local aquaColor = ARGB(255,102, 205, 170)
local dangerousobjects = {		
		{ name = "Jack In The Box", objectType = "boxes", spellName = "JackInTheBox", charName = "ShacoBox", color = 0x00FF0000, range = 300, duration = 60000},
		{ name = "Cupcake Trap", objectType = "traps", spellName = "CaitlynYordleTrap", charName = "CaitlynTrap", color = 0x00FF0000, range = 300, duration = 240000},
		{ name = "Noxious Trap", objectType = "traps", spellName = "Bushwhack", charName = "Nidalee_Spear", color = 0x00FF0000, range = 300, duration = 240000},
		{ name = "Noxious Trap", objectType = "traps", spellName = "BantamTrap", charName = "TeemoMushroom", color = 0x00FF0000, range = 300, duration = 600000}}
local drawobjects = {}
local drawtraps = {}
local pinkwards = {}

function OnBugSplat()
	Serialization.saveTable({wards = placedWards}, SCRIPT_PATH .. 'Common/HiddenWards_BugSplat.lua')
end


function OnCreateObj(object)
	if object ~= nil and object.type == "obj_AI_Minion" then
		for idx, table1 in ipairs(dangerousobjects) do
			if object.name == table1.name then
				local current_tick = GetTickCount()
				local temp_table = {object = object, name = table1.name, duration = table1.duration, start_tick = current_tick, end_tick = current_tick+table1.duration, range = table1.range, color = table1.color}
				--rint(temp_table)
				table.insert(drawobjects, temp_table)
			end
		end
	end
end


function OnDeleteObj(object)

	if object.name == 'Ward_Vision_Idle.troy' then
		for idx, ward in pairs(pinkwards) do
			if GetDistance(ward, object) < 400 then
				pinkwards[idx].alive = 0
			end
		end
	end

	if object ~= nil and object.name ~= nil and object.type == "obj_AI_Minion" then
		for idx, table1 in ipairs(drawobjects) do
			if object.valid and table1.object.valid and table1.object.networkID == object.networkID then
				drawobjects[idx] = nil
				
			end
		end
		for idx, table1 in ipairs(drawtraps) do
			if object.networkID == table1.obnid then
				drawtraps[idx] = nil
			end
		end
		if object.name == 'Ward_Vision_Idle.troy' then
			for idx, table1 in ipairs(pinkwards) do
				if object.x == table1.x and object.y == table1.y and object.z == wable1.z then
					pinkwards[idx] = nil
				end
			end
		end
	end
end


function CheckTimer()
	for idx, table in ipairs(drawobjects) do
		if table.object.valid and table.end_tick < GetTickCount() then
			drawobjects[idx] = nil
		end
	end
end

function CheckLane()
	local enemy_jungler = CL:GetJungler()
	--local my_lane = CL:GetMyLane()
	--local champs_in_lane = CL:GetHeroArray(my_lane)
	--for idx, champ in ipairs(champs_in_lane) do
		--if champ.networkID == enemy_jungler.networkID then
		if enemy_jungler ~= nil then
			local bool = false
			for i = enemy_jungler.pathIndex, enemy_jungler.pathCount do
				path = enemy_jungler:GetPath(i)
				if path ~= nil and path.x then
					if GetDistance(path,myHero) < WardsHater.pingdistance then
						bool = true
					end
				end
			end
			if bool and GetTickCount() - LastPinged > WardsHater.pinginterval*1000 then
				RecPing(enemy_jungler.x, enemy_jungler.z)
				LastPinged = GetTickCount()
			end
		--end
	end

end

--Honda7
function RecPing(X, Y)
	Packet("R_PING", {x = X, y = Y, type = PING_FALLBACK}):receive()
end

function OnRecvPacket(p)
	if p.header == 49 then
		p.pos = 1
		local deaddid = p:DecodeF()
		local killerid = p:DecodeF()
		for networkID, ward in pairs(placedWards) do
			if ward and deaddid and networkID == deaddid and ward.vanga == 1 and (GetTickCount() - ward.spawnTime) > 200 then
				placedWards[networkID] = nil
			elseif ward and deaddid and networkID == deaddid and ward.vanga == 2 and killerid == 0 then
				placedWards[networkID] = nil
			end
		end
	end
	
	if p.header == 0xB4 then
		
		p.pos = 12

		local wardtype2 = p:Decode1()
		p.pos = 1
		local creatorID = p:DecodeF()
		p.pos = p.pos + 20
		local creatorID2 = p:DecodeF()
		p.pos = 37
		local objectID = p:DecodeF()
		local objectX = p:DecodeF()
		local objectY = p:DecodeF()
		local objectZ = p:DecodeF()
		local objectX2 = p:DecodeF()
		local objectY2 = p:DecodeF()
		local objectZ2 = p:DecodeF()
		p:DecodeF()
		local warddet = p:Decode1()
		p.pos = p.pos + 4
		local warddet2 = p:Decode1()
		p.pos = 13
		local wardtype = p:Decode1()
		--[[ 
			8 - Vision ward
			229 - Sight Stone 
			161 - normal wards
			56 trinket1
			56 - trinket1 green upgrade
			137 = trink1 pink
			48 - teemo shroom
			]]
		local visionColor

		--if wardtype==8 or wardtype2==0x7E then return end -- Dont show pinks

		local objectID = DwordToFloat(AddNum(FloatToDword(objectID), 2))
		local creatorchamp = objManager:GetObjectByNetworkId(creatorID)
		local duration
		local range

		if creatorchamp and creatorchamp.team == myHero.team and not WardsHater.ownteam then return end
		
		visionColor = (wardtype == 229 and yellowColor or greenColor)
		
		if (warddet == 0x3E or (warddet == 0x3F and wardtype == 0x3F)) then ---objects
			if wardtype == 0x30 and wardtype2 == 0xD0 and creatorchamp.charName == "Teemo" then
				duration = 600000 range = 200 -- shroom
			elseif (wardtype == 0x09 and wardtype2 == 0x5B  and creatorchamp.charName == "Nidalee" ) or (wardtype == 62 and wardtype2 == 0xB0  and creatorchamp.charName == "Caitlyn" ) then
				duration = 240000 range = 100 -- Nidalee trap / cait
			elseif (wardtype == 0x02 and wardtype2 == 0x68  and creatorchamp.charName == "Shaco" ) then

				duration = 60000 range = 100 -- Shaco
			else return
			end
			
			--placedWards[objectID] = {x = objectX2, y = objectY2, z = objectZ2, visionRange = range, color = yellowColor, spawnTime = GetTickCount(), duration = duration, vanga = 2}
			tmpdrawtraps = {x = objectX2, y = objectY2, z = objectZ2, visionRange = range, color = yellowColor, spawnTime = GetTickCount(), duration = duration, vanga = 2, obnid = objectID }
			table.insert(drawtraps, tmpdrawtraps)

		end
		
		if warddet == 0x3F and warddet2 == 0x33 and wardtype ~= 12 and wardtype ~= 48 then --wards 116 | wardtype 48 -> riven E
			if wardtype2 == 0x6E then
				placedWards[objectID] = {x = objectX2, y = objectY2, z = objectZ2, visionRange = 1100, color = aquaColor, spawnTime = GetTickCount(), duration = 60000, vanga = 1 }	-- WARDING TOTEM
			elseif wardtype2 == 0x2E then
				placedWards[objectID] = {x = objectX2, y = objectY2, z = objectZ2, visionRange = 1100, color = aquaColor, spawnTime = GetTickCount(), duration = 120000, vanga = 1 }	-- GREATER TOTEM
			elseif wardtype == 8 then
				tmppnk = {x = objectX2, y = objectY2, z = objectZ2, visionRange = 1100, color = purpleColor, vanga = 2, alive = 1, owner = creatorchamp.name } --Pink ward
				table.insert(pinkwards, tmppnk)
			elseif wardtype == 137 then
				tmppnk = {x = objectX2, y = objectY2, z = objectZ2, visionRange = 1100, color = purpleColor, vanga = 2, alive = 1, owner = creatorchamp.name }
				table.insert(pinkwards, tmppnk)
			elseif wardtype2 == 0xAE then
				placedWards[objectID] = {x = objectX2, y = objectY2, z = objectZ2, visionRange = 1100, color = aquaColor, spawnTime = GetTickCount(), duration = 180000, vanga = 1 }	-- GREATER STEALTH TOTEM
			elseif wardtype2 == 0xEE then
				placedWards[objectID] = {x = objectX2, y = objectY2, z = objectZ2, visionRange = 1100, color = greenColor, spawnTime = GetTickCount(), duration = 180000, vanga = 1 }	-- WRIGGLES LANTERN
			else
				placedWards[objectID] = {x = objectX2, y = objectY2, z = objectZ2, visionRange = 1100, color = visionColor, spawnTime = GetTickCount(), duration = ((wardtype2 == 0xB4 or wardtype2 == 0x6E) and 60000) or 180000, vanga = 1 }
			end
		end
	end
	p.pos = 1
end

function OnLoad()
	lastvanga = 0
	local loadedTable, error = Serialization.loadTable(SCRIPT_PATH .. 'Common/IHateWards_cache.lua')
	if not error and loadedTable.saveTime <= GetInGameTimer() then
		placedWards = loadedTable.placedWards
	else
		placedWards = {}
	end
	WardsHater = scriptConfig("Free Awareness", "FreeAwareness")
	WardsHater:addParam("drawpath", "Draw enemy path", SCRIPT_PARAM_ONOFF, true)
	WardsHater:addParam("drawallypath", "Draw ally path", SCRIPT_PARAM_ONOFF, true)
	WardsHater:addParam("drawpathtime", "Draw path time", SCRIPT_PARAM_ONOFF, true)
	WardsHater:addParam("drawobj", "Draw shrooms + traps", SCRIPT_PARAM_ONOFF, true)
	WardsHater:addParam("drawwards", "Draw wards", SCRIPT_PARAM_ONOFF, true)
	WardsHater:addParam("ownteam", "Display own team objects(testing purpose)", SCRIPT_PARAM_ONOFF, false)
	WardsHater:addParam("ping", "Ping Enemy Jungler (experimental)", SCRIPT_PARAM_ONOFF, true)
	WardsHater:addParam("pingdistance", "Ping Enemy Jungler minimum distance", SCRIPT_PARAM_SLICE, 1500, 100, 4000, 0)
	WardsHater:addParam("pinginterval", "Ping Enemy Jungler minimum time (s)", SCRIPT_PARAM_SLICE, 1, 69, 180, 0)
	WardsHater:addParam("vangamode", "I THINK WARD IS HERE!", SCRIPT_PARAM_ONKEYDOWN, false, GetKey("F4"))
	WardsHater:addParam("showvision", "Show Vision Key", SCRIPT_PARAM_ONKEYDOWN, false, GetKey("U"))
	WardsHater:addParam("crosssize", "adj cross_size", SCRIPT_PARAM_SLICE, 35, 10, 100, 0)
	WardsHater:addParam("crosswidth", "adj cross_width", SCRIPT_PARAM_SLICE, 10, 5, 50, 0)
	WardsHater:addParam("txtsize", "adj Champ Text size", SCRIPT_PARAM_SLICE, 25, 5, 50, 0)
	WardsHater:addParam("txtxpos", "adj Champ Text x pos", SCRIPT_PARAM_SLICE, 0, -300, 300, 0)
	WardsHater:addParam("txtypos", "adj Champ Text y pos", SCRIPT_PARAM_SLICE, -60, -300, 300, 0)
	WardsHater:addParam("timertxtsize", "adj Timer Text Size", SCRIPT_PARAM_SLICE, 20, 5, 50, 0)
	PrintChat(" >> Free Awareness v" .. tostring(version))
end


function OnUnload()
	Serialization.saveTable({placedWards = placedWards, saveTime = GetInGameTimer()}, SCRIPT_PATH .. 'Common/IHateWards_cache.lua')
end

function OnWndMsg(msg,key)
	if WardsHater.vangamode and lastvanga < GetTickCount() then
		for networkID, ward in pairs(placedWards) do
			if ward and GetDistance(ward,mousePos)<100 and ward.vanga == 3 then
				placedWards[networkID] = nil
				return
			end
		end
		placedWards[GetTickCount()] = {x = mousePos.x, y = myHero.y, z = mousePos.z, visionRange = 1100, color = vangaColor, spawnTime = GetTickCount(), duration = 180000, vanga = 3}
		lastvanga = GetTickCount() + 1000
	end
end

function round(num, idp)
	return string.format("%." .. (idp or 0) .. "f", num)
end

function OnDraw()
	CheckTimer()
	--print(#drawobjects)
	if WardsHater.ping then
		CheckLane()
	end
-- 			tmpdrawtraps = {x = objectX2, y = objectY2, z = objectZ2, visionRange = range, color = yellowColor, spawnTime = GetTickCount(), duration = duration, vanga = 2, obnid = objectID }
	if WardsHater.drawobj then

		for idx, table1 in ipairs(drawobjects) do
			if table1.object ~= nil and table1.object.valid then
				DrawCircle3D(table1.object.x, table1.object.y, table1.object.z, 120, 1,  ARGB(255, 0, 255, 255))
				time_left = (table1.end_tick - GetTickCount())/1000
				timer_text = " " .. TimerText(time_left)
				DrawText3D(timer_text, table1.object.x, myHero.y, table1.object.z, 15, ARGB(255,0,255,255), true)
			end
		end



		for idx, ward in ipairs(drawtraps) do
			if ward.obnid ~= nil then
				if (GetTickCount() - ward.spawnTime) > ward.duration then
					drawtraps[idx] = nil
				else
					local minimapPosition = GetMinimap(ward)
					DrawTextWithBorder('.', 60, minimapPosition.x - 3, minimapPosition.y - 43, ward.color, blackColor)

					local x, y, onScreen = get2DFrom3D(ward.x, ward.y, ward.z)
					DrawTextWithBorder(TimerText((ward.duration - (GetTickCount() - ward.spawnTime)) / 1000), 20, x - 15, y - 11, ward.color, blackColor)

					DrawCircle(ward.x, ward.y, ward.z, 90, ward.color)
					if WardsHater.showvision then
						DrawCircle(ward.x, ward.y, ward.z, ward.visionRange, ward.color)
					end
				end
			end
		end


	end

	if WardsHater.drawwards then
		for idx, ward in pairs(pinkwards) do --Pink Wards
			if ward.alive == 1 then
				local minimapPosition = GetMinimap(ward)
				DrawTextWithBorder('.', 60, minimapPosition.x - 3, minimapPosition.y - 43, ward.color, blackColor)

				local x, y, onScreen = get2DFrom3D(ward.x, ward.y, ward.z)
				DrawTextWithBorder('Pink ward', 20, x - 15, y - 11, ward.color, blackColor)

				DrawCircle(ward.x, ward.y, ward.z, 90, ward.color)
				if WardsHater.showvision then
					DrawCircle(ward.x, ward.y, ward.z, ward.visionRange, ward.color)
				end
			end
		end
		for networkID, ward in pairs(placedWards) do --PacketWards
			if (GetTickCount() - ward.spawnTime) > ward.duration then
				placedWards[networkID] = nil
			else
				local minimapPosition = GetMinimap(ward)
				DrawTextWithBorder('.', 60, minimapPosition.x - 3, minimapPosition.y - 43, ward.color, blackColor)

				local x, y, onScreen = get2DFrom3D(ward.x, ward.y, ward.z)
				DrawTextWithBorder(TimerText((ward.duration - (GetTickCount() - ward.spawnTime)) / 1000), 20, x - 15, y - 11, ward.color, blackColor)

				DrawCircle(ward.x, ward.y, ward.z, 90, ward.color)
				if WardsHater.showvision then
					DrawCircle(ward.x, ward.y, ward.z, ward.visionRange, ward.color)
				end
			end
		end
	end

	if WardsHater.drawpath then
		for idx, champion in ipairs(GetEnemyHeroes()) do
			if champion.visible and not champion.dead then
				local current_waypoints = {}
				table.insert(current_waypoints, Vector(champion.visionPos.x, champion.visionPos.z))
				for i = champion.pathIndex, champion.pathCount do
					path = champion:GetPath(i)
					if path ~= nil and path.x then
						table.insert(current_waypoints, Vector(path.x, path.z))
					end
				end

				local travel_time = 0
				if #current_waypoints > 1 then
					for current_index = 1, #current_waypoints-1 do
						DrawLine3D(current_waypoints[current_index].x, myHero.y, current_waypoints[current_index].y, current_waypoints[current_index+1].x, myHero.y, current_waypoints[current_index+1].y, 2, ARGB(255, 255, 0, 0) )
							if current_index == #current_waypoints-1 then
								local endpoint = current_waypoints[current_index+1]
								DrawText3D(champion.charName, current_waypoints[current_index+1].x+WardsHater.txtxpos, myHero.y, current_waypoints[current_index+1].y+WardsHater.txtypos, WardsHater.txtsize, ARGB(255, 255, 255, 0), true)
								DrawLine3D(endpoint.x-WardsHater.crosssize, myHero.y, endpoint.y+WardsHater.crosssize, endpoint.x+WardsHater.crosssize, myHero.y, endpoint.y-WardsHater.crosssize, WardsHater.crosswidth, ARGB(255, 255, 0, 0) )
								DrawLine3D(endpoint.x+WardsHater.crosssize, myHero.y, endpoint.y+WardsHater.crosssize, endpoint.x-WardsHater.crosssize, myHero.y, endpoint.y-WardsHater.crosssize, WardsHater.crosswidth, ARGB(255, 255, 0, 0) )
							end
						if WardsHater.drawpathtime then
							local current_time = GetDistance(current_waypoints[current_index], current_waypoints[current_index+1])/champion.ms
							travel_time = travel_time + current_time
							DrawText3D(round(travel_time,1) .. " s", current_waypoints[current_index+1].x, myHero.y, current_waypoints[current_index+1].y+100, WardsHater.timertxtsize, ARGB(255,0,255,0), true)
						end
					end
				end
			end
		end
	end

	if WardsHater.drawallypath then
		for idx, champion in ipairs(GetAllyHeroes()) do
			if champion.visible and not champion.dead then
				local current_waypoints = {}
				table.insert(current_waypoints, Vector(champion.visionPos.x, champion.visionPos.z))
				for i = champion.pathIndex, champion.pathCount do
					path = champion:GetPath(i)
					if path ~= nil and path.x then
						table.insert(current_waypoints, Vector(path.x, path.z))
					end
				end

				local travel_time = 0
				if #current_waypoints > 1 then
					for current_index = 1, #current_waypoints-1 do
						DrawLine3D(current_waypoints[current_index].x, myHero.y, current_waypoints[current_index].y, current_waypoints[current_index+1].x, myHero.y, current_waypoints[current_index+1].y, 2, ARGB(255, 0, 255, 0) )
						if current_index == #current_waypoints-1 then
								local endpoint = current_waypoints[current_index+1]
								DrawText3D(champion.charName, current_waypoints[current_index+1].x+WardsHater.txtxpos, myHero.y, current_waypoints[current_index+1].y+WardsHater.txtypos, WardsHater.txtsize, ARGB(255, 255, 255, 0), true)
								DrawLine3D(endpoint.x-WardsHater.crosssize, myHero.y, endpoint.y+WardsHater.crosssize, endpoint.x+WardsHater.crosssize, myHero.y, endpoint.y-WardsHater.crosssize, WardsHater.crosswidth, ARGB(255,0,255,0) )
								DrawLine3D(endpoint.x+WardsHater.crosssize, myHero.y, endpoint.y+WardsHater.crosssize, endpoint.x-WardsHater.crosssize, myHero.y, endpoint.y-WardsHater.crosssize, WardsHater.crosswidth, ARGB(255,0,255,0) )
						end
						if WardsHater.drawpathtime then
							local current_time = GetDistance(current_waypoints[current_index], current_waypoints[current_index+1])/champion.ms
							travel_time = travel_time + current_time
							DrawText3D(round(travel_time,1) .. " s", current_waypoints[current_index+1].x, myHero.y, current_waypoints[current_index+1].y+100, WardsHater.timertxtsize, ARGB(255,0,255,0), true)
						end
					end
				end
			end
		end
	end

end

function DrawTextWithBorder(textToDraw, textSize, x, y, textColor, backgroundColor)
	DrawText(textToDraw, textSize, x + 1, y, backgroundColor)
	DrawText(textToDraw, textSize, x - 1, y, backgroundColor)
	DrawText(textToDraw, textSize, x, y - 1, backgroundColor)
	DrawText(textToDraw, textSize, x, y + 1, backgroundColor)
	DrawText(textToDraw, textSize, x , y, textColor)
end
