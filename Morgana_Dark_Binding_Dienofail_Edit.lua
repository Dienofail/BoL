require "FastCollision"
require "Prodiction"

if myHero.charName ~= "Morgana" then return end
local QREADY, WREADY, EREADY, RREADY = false, false, false, false
local Prodict = ProdictManager.GetInstance()
local ProdictQ
local ProdictQCol

local ts = {}
local MorganaConfig = {}
--SHARED--
local function getHitBoxRadius(target)
	return GetDistance(target, target.minBBox)
	--return GetDistance(target.minBBox, target.maxBBox)/4
end
--END SHARED--


-- local function CastQ(unit, pos, spell)
-- 	if GetDistance(pos) - getHitBoxRadius(unit)/2 < 1300 and myHero:GetSpellData(_Q).name == "DarkBindingMissile" then
-- 		CastSpell(_Q, pos.x, pos.z)
-- 	end
-- end

function OnLoad()
	ts = TargetSelector(TARGET_LESS_CAST, 1300, DAMAGE_MAGIC)
	MorganaConfig = scriptConfig("Morganalabawss", "MorganaAdv")
	local HKQ = string.byte("X")
	local HKW = string.byte("C")
	MorganaConfig:addParam("Q", "Cast Q", SCRIPT_PARAM_ONKEYDOWN, false, HKQ)
	MorganaConfig:addTS(ts)
	ts.name = "Morganalabawss"
	
	ProdictQ = Prodict:AddProdictionObject(_Q, 1300, 1200, 0.250, 60)
	Collision = FastCol(ProdictQ)
	-- ProdictQCol = Collision(1300, 1200, 0.250, 60)
	-- for I = 1, heroManager.iCount do
	-- 	local hero = heroManager:GetHero(I)
	-- 	if hero.team ~= myHero.team then
	-- 		ProdictQ:CanNotMissMode(true, hero)
	-- 	end
	-- end
end

function OnTick()
	ts:update()
	if ts.target ~= nil and MorganaConfig.Q and myHero:CanUseSpell(_Q) == READY then
		local PredictPos = ProdictQ:GetPrediction(ts.target)
		local WillCollide = Collision:GetMinionCollision(PredictPos, myHero)
		if not WillCollide then 
			CastSpell(_Q, PredictPos.x, PredictPos.z)
		end
	end
	
	WREADY = (myHero:CanUseSpell(_W) == READY)
	 
end

function OnGainBuff(unit, buff)
  if ts.target and WREADY and GetDistance(ts.target) < 900 and unit == ts.target and buff.type == 11 then
    CastSpell(_W, unit.x, unit.z)
  end
end

function OnDraw()
	if ts.target ~= nil then
		local dist = getHitBoxRadius(ts.target)/2
		DrawCircle(myHero.x, myHero.y, myHero.z, 1300, 0x7F006E)
		if GetDistance(ts.target) - dist < 1300 then
			DrawCircle(ts.target.x, ts.target.y, ts.target.z, dist, 0x7F006E)
		end
	end
end
