---Begin AOE skill shot position ---

--Credit to Monogato. Modified by Dienofail--

require 'VPrediction'

local VP = VPrediction()

function GetCenter(points)
    local sum_x = 0
    local sum_z = 0
   
    for i = 1, #points do
            sum_x = sum_x + points[i].x
            sum_z = sum_z + points[i].z
    end
   
    local center = {x = sum_x / #points, y = 0, z = sum_z / #points}
   
    return center
end

function ContainsThemAll(circle, points)
    local radius_sqr = circle.radius*circle.radius
    local contains_them_all = true
    local i = 1
   
    while contains_them_all and i <= #points do
            contains_them_all = GetDistanceSqr(points[i], circle.center) <= radius_sqr
            i = i + 1
    end
   
    return contains_them_all
end

-- The first element (which is gonna be main_target) is untouchable.
function FarthestFromPositionIndex(points, position)
    local index = 2
    local actual_dist_sqr
    local max_dist_sqr = GetDistanceSqr(points[index], position)
   
    for i = 3, #points do
            actual_dist_sqr = GetDistanceSqr(points[i], position)
            if actual_dist_sqr > max_dist_sqr then
                    index = i
                    max_dist_sqr = actual_dist_sqr
            end
    end
   
    return index
end

function RemoveWorst(targets, position)
    local worst_target = FarthestFromPositionIndex(targets, position)
   
    table.remove(targets, worst_target)
   
    return targets
end

function GetInitialTargets(radius, main_target)
    local targets = {main_target}
    local diameter_sqr = 4 * radius * radius
   
    for i=1, heroManager.iCount do
            target = heroManager:GetHero(i)
            if target.networkID ~= main_target.networkID and ValidTarget(target) and GetDistanceSqr(main_target, target) < diameter_sqr then table.insert(targets, target) end
    end
   
    return targets
end

function GetPredictedInitialTargets(radius, main_target, delay, speed, col) --col is true or false
    --if VIP_USER and not vip_target_predictor then vip_target_predictor = TargetPredictionVIP(nil, nil, delay/1000) end
    local predicted_main_target = VP:GetPredictedPos(main_target, delay, speed, myHero, col)
    local predicted_targets = {predicted_main_target}
    local diameter_sqr = 4 * radius * radius
   
    for i=1, heroManager.iCount do
            target = heroManager:GetHero(i)
            if ValidTarget(target) then
                    predicted_target = VP:GetPredictedPos(target, delay, speed, myHero, col)
                    if target.networkID ~= main_target.networkID and GetDistanceSqr(predicted_main_target, predicted_target) < diameter_sqr then table.insert(predicted_targets, predicted_target) end
            end
    end
   
    return predicted_targets
end

-- I don´t need range since main_target is gonna be close enough. You can add it if you do.
function GetAoESpellPosition(radius, main_target, delay, speed)
    local targets = GetPredictedInitialTargets(radius, main_target, delay, speed) 
    local position = GetCenter(targets)
    local best_pos_found = true
    local circle = Circle(position, radius)
    circle.center = position
   
    if #targets > 2 then best_pos_found = ContainsThemAll(circle, targets) end
   
    while not best_pos_found do
            targets = RemoveWorst(targets, position)
            position = GetCenter(targets)
            circle.center = position
            best_pos_found = ContainsThemAll(circle, targets)
    end
   
    return position
end

function GetAoEBounces(radius, main_target, delay, speed)
	local targets = GetPredictedInitialTargets(radius, main_target, delay, speed)
	return #targets
end
--- End AOE skill shot position
