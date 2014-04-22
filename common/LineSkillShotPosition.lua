function LineSkillShotPosition(Target, ProdObject, Buffer, DeflectionAngleIncrement, MaxDeflectionAngle, HitChance, fromPos, customRange, customDistFromTarget)
    if fromPos == nil then fromPos = myHero end
    if Buffer == nil then Buffer = 25 end
    if MaxDeflectionAngle == nil then MaxDeflectionAngle = 15 end
    if DeflectionAngleIncrement == nil then DeflectionAngleIncrement = 1 end
    if HitChance == nil then HitChance = 0.2 end
    if customDistFromTarget == nil then customDistFromTarget = 600 end
    local main_target = Target
    local ReturnPos = nil
    local Current_Spell = ProdObject.Spell 
    local Speed = Current_Spell.speed
    local Range = 0
    if customRange ~= nil and customRange > 0 then
        Range = customRange
    else
        Range = Current_Spell.range 
    end
    local Width = Current_Spell.width
    local Delay = Current_Spell.delay 
    local Main_Prediction_Pos, Main_Time, Main_Hitchance = ProdObject:GetPrediction(Target)
    local Predicted_Targets = {}

    if Main_Prediction_Pos ~= nil and Main_Hitchance ~= nil then 
        --print(tostring(Main_Prediction_Pos.x) .. '  ' .. tostring(Main_Prediction_Pos.z) .. '  '  .. tostring(Main_Hitchance))
        if Main_Hitchance >= HitChance then
            table.insert(Predicted_Targets, {pos=Main_Prediction_Pos, hitchance=Main_Hitchance, champ=Target})
            --print('Insertion complete')
        else
            return 
        end
        for i = 1, heroManager.iCount do
            local target = heroManager:GetHero(i)
            ----print(target.charName)
            if target.valid and target.networkID ~= Target.networkID and ValidTarget(target) and target.team ~= myHero.team then
                local Current_Prediction_Pos, Current_Time, Current_Hitchance = ProdObject:GetPrediction(target)
                if Current_Prediction_Pos ~= nil and Current_Hitchance ~= nil and GetDistance(Current_Prediction_Pos, myHero) < Range and Current_Hitchance >= HitChance and GetDistance(Current_Prediction_Pos, Main_Prediction_Pos) < customDistFromTarget then
                    --print(tostring(Current_Prediction_Pos.x) .. '  ' .. tostring(Current_Prediction_Pos.z) .. '  '  .. tostring(Current_Hitchance) .. ' ' .. tostring(target.charName))
                    table.insert(Predicted_Targets, {pos = Current_Prediction_Pos, hitchance = Current_Hitchance, champ = target})
                end
            end
        end
        --print('After insertion we have ' .. tostring(#Predicted_Targets))
        local max_hit_targets = nil 

        if #Predicted_Targets == 1 then
            --print('Main predicted targets 1 returning')
            return Main_Prediction_Pos
        elseif #Predicted_Targets > 1 then
            max_hit_targets = #Predicted_Targets
        end

        local gx1, gy1, gx2, gy2 = GenerateLineSegmentFromCastPosition(Main_Prediction_Pos, myHero, Range)
        local WillHitMainChamp = CheckWillHit(gx1, gy1, gx2, gy2, Main_Prediction_Pos.x, Main_Prediction_Pos.z, Width, Target, Buffer) 
        local counter1 = 0
        for i,predict in ipairs(Predicted_Targets) do
            if CheckWillHit(gx1, gy1, gx2, gy2, predict.pos.x, predict.pos.z, Width, predict.champ, Buffer) then
                counter1 = counter1 + 1
            end
        end

        if counter1 == max_hit_targets and max_hit_targets ~= nil and counter1 > 0 and WillHitMainChamp then
            return Main_Prediction_Pos
        end

        rotation_list = GenerateRotationList(DeflectionAngleIncrement, MaxDeflectionAngle)
        current_best_phi = {0, nil, nil, nil}
        for i, current_phi in ipairs(rotation_list) do
            --print('iterating through phi at ' .. tostring(current_phi))
            ax1, ay1, ax2, ay2 = GenerateRotatedLineSegment(gx1, gy1, gx2, gy2, current_phi)
            local CurrentWillHitMainChamp = CheckWillHit(ax1, ay1, ax2, ay2, Predicted_Targets[1].pos.x, Predicted_Targets[1].pos.z, Width, Predicted_Targets.champ, Buffer)
            local counter2 = 0
            if CurrentWillHitMainChamp then
                for j,predict in ipairs(Predicted_Targets) do
                    if CheckWillHit(ax1, ay1, ax2, ay2, predict.pos.x, predict.pos.z, Width, predict.pos.champ, Buffer) then
                        counter2 = counter2 + 1
                    end 
                end
            end
            if counter2 == max_hit_targets then
                ReturnPos = {x = ax2, y = 0, z = ay2}
                return ReturnPos
            end
            if counter2 > current_best_phi[1] then
                current_best_phi[1] = counter2
                current_best_phi[2] = current_phi
                current_best_phi[3] = ax2
                current_best_phi[4] = ay2
            end
        end
        if current_best_phi[1] ~= nil and current_best_phi[2] ~= nil and current_best_phi[3] ~= nil and current_best_phi[4] ~= nil then
            ReturnPos = {x = current_best_phi[3], y = 0, z = current_best_phi[4]}
            --print('Best phi found at ' .. tostring(current_best_phi[3]) .. ' ' .. current_best_phi[4])
            return ReturnPos
        end
    end
end

function CheckWillHit(x1, y1, x2, y2, x3, y3, width, enemyHero, buffer)
    ----print('Check will hit called')
    local enemyhitbox = getHitBoxRadius(enemyHero)
    local Distance = GetShortestLineDistance(x1, y1, x2, y2, x3, y3)

    if enemyhitbox + width - buffer >= Distance then
            --print('Check will hit called with result true')
        return true
    else
        --print('Check will hit called with result false')
        return false
    end
end

function getHitBoxRadius(target)
    return GetDistance(target, target.minBBox)
    --return GetDistance(target.minBBox, target.maxBBox)/4
end
--returns the shortest distance between a point and a line segment, where x1, y1, x2, y2 define the line segment and x3, y3 define the point
function GetShortestLineDistance(x1, y1, x2, y2, x3, y3)
    local px = x2 - x1
    local py = y2 - y1

    local sqr = px*px + py*py

    local u = ((x3 - x1)*px + (y3-y1)*py) / sqr

    if u>1 then
        u = 1
    elseif u<0 then
        u = 0
    end

    local x = x1 + u*px
    local y = y1 + u*px

    local dx = x - x3
    local dy = y - y3
    local dist = math.sqrt(dx*dx + dy*dy)
    --print('Shortest Line Distance Generated with ' .. tostring(dist))
    return dist
end

--Generates the rotated line segment 
function GenerateRotatedLineSegment(x1, y1, x2, y2, phi)
    local rotated_vector = Vector(x2-x1, y2-y1):rotate(phi, phi)
    local bx, by = rotated_vector:unpack()
    local cx = x1 + bx
    local cy = y1 + by
    --print('Generated rotate line segment complete')
    return x1, y1, cx, cy
end


--Generates the line segment given a cast position
function GenerateLineSegmentFromCastPosition(CastPosition, FromPosition, SkillShotRange)
    ----print('GenerateLineSegmentFromCastPosition')
    local MaxEndPosition = CastPosition + Vector(CastPosition.x - FromPosition.x, 0, CastPosition.z - FromPosition.z):normalized()*SkillShotRange
    --print('Generating current maxendposition from GenerateLineSegment ' .. tostring(MaxEndPosition.x) .. ' ' .. tostring(MaxEndPosition.z))
    return CastPosition.x, CastPosition.z, MaxEndPosition.x, MaxEndPosition.z
end


function GenerateRotationList(DeflectionAngleIncrement, MaxDeflectionAngle)
    --print('generating rotation list')
    local iter = math.ceil(MaxDeflectionAngle/DeflectionAngleIncrement)
    local return_table = {}
    for i=1, iter do
        table.insert(return_table, i*DeflectionAngleIncrement*0.0174532925)
        table.insert(return_table,  2*math.pi - i*DeflectionAngleIncrement*0.0174532925)
    end
    --print('rotation list generated ' .. tostring(#return_table))
    return return_table
end
