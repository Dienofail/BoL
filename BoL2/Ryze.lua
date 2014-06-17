--[[DienoRyze - SKILL SPAMMER V0.01 BETA ]]--

isReady = false
local QReady = nil
local WReady = nil
local EReady = nil
local RReady = nil
local QRange = 625
local WRange = 600
local ERange = 600

Callback.Bind("Load", function()
    if myHero.charName ~= 'Ryze' then return end 
    Config = AddonConfig.Create('DienoRyze');
    Config {     
    Config.Section('Keys') {
        Config.KeyBinding('Combo', 'SPACE'),
        Config.KeyBinding('Lane Clear', 'V'),
                        },
    Config.Section('Combo') {
        Config.Boolean('Use Q', true),
        Config.Boolean('Use W', true),
        Config.Boolean('Use E', true),
        Config.Boolean('Use R', true),
        --Config.Boolean('Orbwalk', true),   
                        },
    Config.Section('Draw') {
        Config.Boolean('Draw Q', true),
        Config.Boolean('Draw E', true),
        Config.Boolean('Draw W', true),           
                        },
    Config.Section('Lane Clear') {
        Config.Boolean('Use Q', true),
        Config.Boolean('Use W', true),
        Config.Boolean('Use E', true),
        Config.Boolean('Use R', true),
        --Config.Boolean('Orbwalk', true),      
                        },
    Config.Section('Draw') {
        Config.Boolean('Draw Q', true),
        Config.Boolean('Draw E', true),
        Config.Boolean('Draw W', true),           
                        },
    }
end)


Callback.Bind("GameStart", function() 
    if myHero.charName ~= 'Ryze' then return end
    Game.Chat.Print("DienoRyze 0.01 loaded")
    isReady = true
    Callback.Bind("Tick", function()
        Checks()
        Combo()
        WaveClear()
    end)

    Callback.Bind("Draw", function()
        if myHero == nil or myHero.z == nil or myHero.y == nil or myHero.z == nil then return end
        if QReady and Config.draw.drawQ then
            Graphics.DrawCircle(myHero.x, myHero.y, myHero.z, 625, Graphics.RGB(0, 255, 255):ToNumber())
        end
        if WReady and Config.draw.drawW then
            Graphics.DrawCircle(myHero.x, myHero.y, myHero.z, 600, Graphics.RGB(0, 255, 255):ToNumber())
        end
        if EReady and Config.draw.drawE then
            Graphics.DrawCircle(myHero.x, myHero.y, myHero.z, 600, Graphics.RGB(0, 255, 255):ToNumber())
        end
    end)
end)



function Checks()
    if myHero ~= nil and isReady then
        QReady = (myHero:CanUseSpell(Game.Slots.SPELL_1) == Game.SpellState.READY) 
        WReady = (myHero:CanUseSpell(Game.Slots.SPELL_2) == Game.SpellState.READY) 
        EReady = (myHero:CanUseSpell(Game.Slots.SPELL_3) == Game.SpellState.READY) 
        RReady = (myHero:CanUseSpell(Game.Slots.SPELL_4) == Game.SpellState.READY)
        --Chat.Print(tostring(myHero.x) .. "\t" .. tostring(myHero.y) .. "\t" .. tostring(myHero.z)) 
    end
end

function Combo()
    Target = GetTarget()
    --Chat.Print(tostring(Target.charName))
    if Target ~= nil and Config.keys.combo then 
        if myHero:DistanceTo(Target) < QRange and QReady and Config.combo.useQ then
            myHero:CastSpell(Game.Slots.SPELL_1, Target)
        end
        if myHero:DistanceTo(Target) < WRange and WReady and Config.combo.useW then
            myHero:CastSpell(Game.Slots.SPELL_2, Target)
        end
        if myHero:DistanceTo(Target) < ERange and EReady and not WReady and not QReady and Config.combo.useE then
            myHero:CastSpell(Game.Slots.SPELL_3, Target)
        end
        if RReady and myHero:DistanceTo(Target) < QRange and not QReady and Config.combo.useR then
           myHero:CastSpell(Game.Slots.SPELL_4) 
        end
    end
end

function WaveClear()
    -- if Object.EnemyMinions ~= nil then
    --      for minion in Object.EnemyMinions do
    --         print(minion.charName)
    --      end
    -- end
    if Config.keys.laneClear then
            local TargetMinion, TargetDistance = nil, math.huge
            local MinionCounter = 0
            for minion in Object.Minions do
                if minion ~= nil and myHero:DistanceTo(minion) < 650 and not minion.dead and minion.team ~= myHero.team then 
                    MinionCounter = MinionCounter + 1
                    if myHero:DistanceTo(minion) < TargetDistance then
                        TargetMinion = minion
                        TargetDistance = myHero:DistanceTo(minion)
                    end
                end
            end

            if TargetMinion ~= nil then
                if MinionCounter >= 3 and Config.laneClear.useR then
                    myHero:CastSpell(Game.Slots.SPELL_4) 
                end

                if QReady and myHero:DistanceTo(TargetMinion) < QRange and Config.laneClear.useQ then
                    myHero:CastSpell(Game.Slots.SPELL_1, TargetMinion)
                end

                if WReady and myHero:DistanceTo(TargetMinion) < WRange and Config.laneClear.useW then
                    myHero:CastSpell(Game.Slots.SPELL_2, TargetMinion)
                end

                if EReady and myHero:DistanceTo(TargetMinion) < ERange and Config.laneClear.useE then
                    myHero:CastSpell(Game.Slots.SPELL_3, TargetMinion)
                end
            end
    end
end

--Credit PQ or whatever he's called now :D
function GetTarget()
    local bestT, bestR = nil, 0
    for i=1, Game.HeroCount() do
        local hero = Game.Hero(i)
        if myHero:DistanceTo(hero) < 800 and hero.team ~= myHero.team and not hero.dead then
            local ratio = hero.health / myHero:CalcDamage(hero, myHero.totalDamage)
            if bestT == nil or ratio < bestR then
                bestT, bestR = hero, ratio
            end
        end
    end
    return bestT
end