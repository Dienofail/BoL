local version = "0.02"
--[[Based: By Biggest Butt NA (boboben1)]]--
--[[Inspired By Based On a True Story]]--
--[[Completely Rewritten by Biggest Butt NA (boboben1)]]--
--[[Rewritten once again by Dienofail

Changelog

v0.01 - release

v0.02 - removed chat

Description

Uses global ults on recalling enemies: supports draven, jinx, ashe, ezreal 

All credit to original writers; I'm responsible for updating with jinx/draven and plugging in autoupdater

]]--
local AUTOUPDATE = true
local UPDATE_SCRIPT_NAME = "TrueStory"
local UPDATE_NAME = "TrueStory"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/Dienofail/BoL/master/TrueStory.lua".."?rand="..math.random(1,10000)
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

local player = GetMyHero()

local Champions = {["Ezreal"] = {Speed = 2000, Delay = 1.0}, ["Ashe"] = {Speed = 1600, Delay = 0.125}, ["Jinx"] = {Delay = 0.250, Speed = 1700}, ["Draven"] = {Delay = 0.500, Speed = 2000}}
if player.charName ~= "Ezreal" and player.charName ~= "Ashe" and player.charName ~= "Jinx" and player.charName ~= "Draven" then return end

local BasedConfig = nil
local SpellData = nil
local BaseLoc = nil
local TargetData = {}
local BaseSpots = {
    ["Red"] = { x = 514.287109375,    y = -35.081577301025, z = 4149.9916992188  }, -- LEFT BASE              [4]
	["Blue"] = { x = 13311.96484375,    y = -37.369071960449, z = 4161.232421875  }  -- RIGHT BASE             [6]
}

local BaseSpots1 = {
    ["Red"] = { x = 27, z = 265  }, -- LEFT BASE              [4]
	["Blue"] = { x = 13953, z = 14162  }  -- RIGHT BASE  
}
--GetGame().map.index

local DrawData = {
	["Text"] = "Stand Still!",
	["Time"] = 0,
	["prevTick"] = 0,
	["DrawTextWithBorder"] = nil
}

function DrawData.DrawTextWithBorder(textToDraw, textSize, x, y, textColor, backgroundColor)
        DrawText(textToDraw, textSize, x + 1, y, backgroundColor)
        DrawText(textToDraw, textSize, x - 1, y, backgroundColor)
        DrawText(textToDraw, textSize, x, y - 1, backgroundColor)
        DrawText(textToDraw, textSize, x, y + 1, backgroundColor)
        DrawText(textToDraw, textSize, x , y, textColor)
end

local function GetEnemyTeam()
	return (player.team == TEAM_BLUE and "Blue" or "Red")
end


local function DONOTUSE()
	return GetDistance(BaseLoc) / SpellData.Speed/1000 + SpellData.Delay*1000 + GetLatency()*2
end

local function GetHitTime()
	return GetDistance(BaseLoc) / (SpellData.Speed/1000) + SpellData.Delay*1000 + GetLatency()
end

local function JinxGetHitTime()
	local Distance = GetDistance(BaseLoc)
	local Speed = (Distance > 1350 and (1350*1700+((Distance-1350)*2200))/Distance or 1700)
	return Distance / (Speed/1000) + SpellData.Delay*1000 + GetLatency()
end

local function IsInBounds()
	local temp = GetHitTime()
	--PrintChat(temp)
	return temp < 5000
end

function OnLoad()
	BasedConfig = scriptConfig("Based!", "Based2.0")
	BasedConfig:addParam("enabled", "Enable", SCRIPT_PARAM_ONOFF, true)
	
	SpellData = Champions[player.charName]
	local map = GetGame().map.index
	BaseLoc = map == 1 and BaseSpots1[GetEnemyTeam()] or BaseSpots[GetEnemyTeam()]
end



function OnTick()
	if TargetData.Target ~= nil and BasedConfig.enabled then
		TargetData.RecallTime = TargetData.RecallTime - (GetTickCount() - TargetData.Time)
		TargetData.Time = GetTickCount()
		local hittime = nil
		if myHero.charName ~= Jinx then 
			hittime = GetHitTime()
		else
			hittime = GetJinxHitTime()
		end
		--PrintChat("HitTime ".. hittime)
		if hittime >= TargetData.RecallTime and hittime < TargetData.RecallTime + 30 and player:CanUseSpell(_R) == READY then
			--PrintChat("FIRE")
			CastSpell(_R, BaseLoc.x, BaseLoc.z)
			for i, k in pairs(TargetData) do
				TargetData[i] = nil
			end
		end
	end
end
--(GetDistance({ x = 514.287109375,z = 4149.9916992188}) / 2 + 1000 + GetLatency()*2) / 2000 < GetDistance({ x = 514.287109375,z = 4149.9916992188})
function OnDraw()

	local bound = IsInBounds()
	if bound then
		for I = 0, 5 do
			DrawCircle(player.x, player.y, player.z, 90+I, 0xFFFF0000)
		end
	end
	if DrawData.Time > 0 then
		DrawData.Time = DrawData.Time - (GetTickCount() - DrawData.prevTick)
		DrawData.prevTick = GetTickCount()
		
		--DrawData.DrawTextWithBorder(DrawData.Text, 30, 0, 200, ColorARGB.Red, ColorARGB.Black)
		
		if DrawData.Time <= 0 then
			DrawData.prevTick = 0
		end
	end
end

--[[function OnProcessSpell(unit, spell)
	if spell.name == "OdinRecall" then
		if getDmg("R", unit, player) > unit.health then
			TargetData.Target = unit
			TargetData.Time = GetTickCount()
			TargetData.RecallTime = 4000
			DrawData.prevTick = GetTickCount()
			DrawData.Time = 1000
		end
	elseif spell.name == "OdinRecallImproved" then
		if getDmg("R", unit, player) > unit.health then
			TargetData.Target = unit
			TargetData.Time = GetTickCount()
			TargetData.RecallTime = 3500
			DrawData.prevTick = GetTickCount()
			DrawData.Time = 1000
		end
	end
	
end]]--
-- Thanks Vadash --
function OnRecall(hero, channelTimeInMs)    -- gets triggered when somebody starts to recall
    if hero.team ~= player.team then
		if getDmg("R", hero, player) > hero.health and TargetData.Target == nil then
			TargetData.Target = hero
			TargetData.Time = GetTickCount()
			TargetData.RecallTime = channelTimeInMs+450
			TargetData.RecallTimeStatic = channelTimeInMs+450
			DrawData.prevTick = GetTickCount()
			DrawData.Time = 1000
			PrintChat("Queued")
		end
    end
end

function OnAbortRecall(hero)                -- gets triggered when somebody aborts a recall
    if TargetData.Target ~= nil and hero.networkID == TargetData.Target.networkID then
        TargetData.Target = nil
    end
end
function OnFinishRecall(hero)               -- gets triggered when somebody finishes a recall
    --if TargetData.Target ~= nil and hero.networkID == TargetData.Target.networkID then
    --    TargetData.Target = nil
   -- end
end