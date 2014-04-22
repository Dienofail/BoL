--[[

Poppy condemn v0.01

by Dienofail, based on VMA by Manciuszz

Changelog

v0.01 - Official version numbers. VPrediction added.


]]
if myHero.charName ~= "Poppy" then return end
local enemyTable = GetEnemyHeroes()
local maxPushPosition = nil
local initDone = false
function OnLoad()
	require "Prodiction"
	require "VPrediction"
	Prod = ProdictManager.GetInstance()
	ProdE = Prod:AddProdictionObject(_E, 550, math.huge, 0.300, 0)
	VP = VPrediction()
	ePos = nil
	maxPushPosition = nil
	--Menu
	PMenu = scriptConfig("Simple Poppy Condemn", "Poppy_Knockback")
	PMenu:addParam("autoCondemn","Auto-Condemn Toggle:", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	PMenu:addParam("pushDistance", "Push Distance", SCRIPT_PARAM_SLICE, 300, 0, 300, 0)
	PMenu:addParam("accuracy", "Accuracy", SCRIPT_PARAM_SLICE, 30, 1, 50, 0)
	PMenu:addParam("VPrediction", "Use VPrediction", SCRIPT_PARAM_ONOFF, true)
	PMenu:addParam("Draw Predicted Position", "Draw Predicted Position", SCRIPT_PARAM_ONOFF, true)
	PrintChat(" Simple Poppy Condemn by Dienofail loaded! ")
	initDone = true
end


function OnTick()
	if initDone then
		if myHero.dead then return end
		local ePos,Hitchance,predictpos = nil,nil,nil
		if PMenu.autoCondemn and myHero:CanUseSpell(_E) == READY then
			for i, enemyHero in ipairs(enemyTable) do
				if enemyHero ~= nil and enemyHero.valid and not enemyHero.dead and enemyHero.visible and GetDistance(enemyHero) <= 800 and GetDistance(enemyHero) > 0 then
					if PMenu.VPrediction then 
						throwaway, Hitchance, troll = VP:GetLineCastPosition(enemyHero, 0.30, 0, 550, 2200, myHero, false)
						if Hitchance >= 1 then
							ePos = troll
						else
							epos = nil
						end
					else
						ePos = ProdE:GetPrediction(enemyHero)
					end
				else
					ePos = nil
				end
				maxPushPosition = Vector(ePos) + (Vector(ePos) - myHero):normalized()*PMenu.pushDistance
				if ePos ~= nil then
					local checks = math.ceil(PMenu.accuracy)
					local checkDistance = math.ceil(PMenu.pushDistance/checks)
					local InsideTheWall = false
					for k=1, checks, 1 do
						local PushPosition = Vector(ePos) + Vector(Vector(ePos) - Vector(myHero)):normalized()*(checkDistance*k)
						if IsWall(D3DXVECTOR3(PushPosition.x, PushPosition.y, PushPosition.z)) then
							InsideTheWall = true
							break
						end
					end
					if InsideTheWall then
						CastSpell(_E, enemyHero)
					end
				end
			end
		else
			maxPushPosition = nil
		end
	end
end



function OnDraw()
	if maxPushPosition ~= nil then
		DrawCircle3D(maxPushPosition.x, maxPushPosition.y, maxPushPosition.z, 100, 1, ARGB(255, 0, 255, 255))
		DrawLine3D(ePos.x, ePos.y, ePos.z, maxPushPosition.x, maxPushPosition.y, maxPushPosition.z,  1, ARGB(255, 255, 0, 0))
	end
end
