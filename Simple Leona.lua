require "Prodiction"

if myHero.charName ~= "Leona" then return end
local QREADY = false
local WREADY = false
local EREADY = false
local RREADY = false
local Prodict = ProdictManager.GetInstance()
local ProdictE
local ProdictR
local triggerbarrel = false
local ts = {}
local LeonaConfig = {}
--SHARED--
local function getHitBoxRadius(target)
	return GetDistance(target, target.minBBox)
	--return GetDistance(target.minBBox, target.maxBBox)/4
end
--END SHARED--


local function CastE(unit, pos, spell)
	if GetDistance(pos) - getHitBoxRadius(unit)/2 < 875 and myHero:GetSpellData(_E).name == "LeonaZenithBlade" then
		CastSpell(_E, pos.x, pos.z)
	end
end

local function CastR(unit, pos, spell)
	if GetDistance(pos) < 1200 and myHero:GetSpellData(_R).name == "LeonaSolarFlare" then
		CastSpell(_R, pos.x, pos.z)
	end
end


function OnLoad()
    print(myHero:GetSpellData(_E).name)
	ts = TargetSelector(TARGET_LESS_CAST, 1200, DAMAGE_MAGIC)
	LeonaConfig = scriptConfig("Simple Leona", "LeonaAdv")
	local HK = string.byte("C")
	local HKC = string.byte("X")
	local HKV = string.byte("Z")
	LeonaConfig:addParam("E", "Cast EQ", SCRIPT_PARAM_ONKEYDOWN, false, HK)
	LeonaConfig:addParam("C", "Cast EWQR", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	LeonaConfig:addParam("R", "Cast R", SCRIPT_PARAM_ONKEYDOWN, false, HKV)
	LeonaConfig:addParam("draw", "Turn Draw on or off", SCRIPT_PARAM_ONOFF, true)
	--LeonaConfig:addParam("dashcallback", "Dash callbacks for E", SCRIPT_PARAM_ONOFF, false)
	--LeonaConfig:addParam("immobilecallback", "AfterImmobile callback for E", SCRIPT_PARAM_ONOFF, false)
	ts.name = "Simple Leona"
	LeonaConfig:addTS(ts)
	ProdictE = Prodict:AddProdictionObject(_E, 900, 1100, 0.250, 0)
	ProdictR = Prodict:AddProdictionObject(_R, 1200, 20000, 0.520, 0)
	-- for I = 1, heroManager.iCount do
	-- 	local hero = heroManager:GetHero(I)
	-- 	if hero.team ~= myHero.team then
	-- 		ProdictE:GetPredictionAfterImmobile(hero,  CastE)
	-- 		ProdictE:GetPredictionOnDash(hero,  CastE)
	-- 		ProdictE:GetPredictionAfterDash(hero, CastE)
	-- 	end
	-- end
end

function OnTick()
	ts:update()

	-- if ValidTarget(ts.target) then
	-- 	if LeonaConfig.dashcallback then
	-- 		ProdictE:GetPredictionAfterOnDash(ts.target, CastE)
	-- 		ProdictE:GetPredictionAfterDash(ts.target, CastE)
	-- 	end
	-- 	if LeonaConfig.immobilecallback then
	-- 		ProdictE:GetPredictionAfterImmobile(ts.target, CastE)
	-- 	end
	-- end

	if ts.target ~= nil and LeonaConfig.E then
		ProdictE:GetPredictionCallBack(ts.target, CastE)
		if GetDistance(ts.target) - getHitBoxRadius(ts.target)/2 < 125 then
			CastSpell(_Q)
		end
	end

	
	if ts.target ~= nil and LeonaConfig.C and GetDistance(ts.target) - getHitBoxRadius(ts.target)/2 < 875 then
		ProdictE:GetPredictionCallBack(ts.target, CastE)
		CastSpell(_W) 
    	CastSpell(_Q)
	end
	
	if ts.target ~= nil and LeonaConfig.R and myHero:CanUseSpell(_R) == READY and GetDistance(ts.target) - getHitBoxRadius(ts.target)/2 < 1300 then
		ProdictR:GetPredictionCallBack(ts.target, CastR)
	end

	QREADY = (myHero:CanUseSpell(_Q) == READY)
	WREADY = (myHero:CanUseSpell(_W) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY)
	
	
end

function OnGainBuff(unit, buff)
	 if unit == ts.target and buff.type == 11 and buff.name == "leonazenithbladeroot" and LeonaConfig.C then
	     CastSpell(_W) 
	     CastSpell(_Q)
     end
        
     if unit == ts.target and buff.type == 5 and buff.name == "Stun" and LeonaConfig.C then
     	CastSpell(_R, unit.x, unit.z)
     end
    
end



function OnDraw()
	if ts.target ~= nil and LeonaConfig.draw then
		local dist = getHitBoxRadius(ts.target)/2
		DrawCircle(myHero.x, myHero.y, myHero.z, 875, 0x7F006E)
		DrawCircle(myHero.x, myHero.y, myHero.z, 1200, 0x7F006E)
		if GetDistance(ts.target) - dist < 875 then
			DrawCircle(ts.target.x, ts.target.y, ts.target.z, dist, 0x7F006E)
		end
	end
end
