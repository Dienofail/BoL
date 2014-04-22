--[[
Class: PPrediction
Methods:
	Position, HitChance	= PPrediction:GetPredictedPos(hero, delay, speed, from)
		Position: Returns where the enemy is going to be after X seconds delay
		Hitchance: Returns a number indicating the hit chance. (read below for more details)
		
	CastPosition,  HitChance,  Position = PPrediction:GetCircularCastPosition(hero, delay, width, range, speed, from)
		CastPosition: Returns the position where a circular skillshot should be casted
		Position: Returns where the enemy is going to be after X seconds delay
		Hitchance: Returns a number indicating the hit chance. (read below for more details)
		
	CastPosition,  HitChance,  Position = PPrediction:GetLineCastPosition(hero, delay, width, range, speed, from)
		CastPosition: Returns the position where a lineal skillshot should be casted
		Position: Returns where the enemy is going to be after X seconds delay
		Hitchance: Returns a number indicating the hit chance. (read below for more details)
	
	-delay and speed in seconds and units per second
	-speed and from 
		
Hitchance:
	The hitchance is a number indicating how likely the hero will be hit:
		- 0: No waypoints found for the target, returning target current position
		- 1: Low hitchance to hit the target
		- 2: Hight hitchance to hit the target
		- 3: Target too slowed or/and too close , (~100% hit chance)
		- 4: Target inmmobile, (~100% hit chace)
		- 5: Target dashing, (~100% hit chance)
		
Basic example:
	local VP = nil
	function OnLoad()
		VP = PPrediction()
	end
	function OnTick()
		for i, target in pairs(GetEnemyHeroes()) do
			CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(target, 0.6, 75, 850)
			if HitChance == 4 and GetDistance(CastPosition) < 850 then --target inmobile
				CastSpell(_Q, CastPosition.x, CastPosition.z)
			end
		end
	end
]]
class 'PPrediction' --{
function PPrediction:__init()
	self.version = "0.01 BETA"

	--[[Table to save the waypoints from enemy heroes from the last 10 seconds]]
	self.EnemiesWaypoints = {}

	--[[Table to save the waypoints from myself from the last 10 seconds]]
	self.MyWaypoints = {}
	
	--[[Table to save if the enemies are CC (inmobilized)]]
	self.EnemiesCC = {}
	
	--[[Table to save slowed enemies ]]
	self.EnemiesSlowed = {}
	
	--[[Table to save if the enemies are dashing]]
	self.EnemiesDashing = {}
	
	--[[If the enemies just become visible prediction fails]]
	self.EnemiesVisible = {}
	
	--[[The time when the hero has been immobile]]
	self.LastImmobileT = {}

		--[[Spells that don't allow movement (durations approx)]]
	self.spells = {
		{name = "katarinar", duration = 1}, --Katarinas R
		{name = "drain", duration = 1}, --Fiddle W
		{name = "crowstorm", duration = 1}, --Fiddle R
		{name = "consume", duration = 1.5}, --Nunu Q
		{name = "absolutezero", duration = 1}, --Nunu R
		{name = "rocketgrab", duration = 0.5}, --Blitzcrank Q
		{name = "staticfield", duration = 0.5}, --Blitzcrank R
		{name = "cassiopeiapetrifyinggaze", duration = 0.5}, --Cassio's R
		{name = "ezrealtrueshotbarrage", duration = 1}, --Ezreal's R
		{name = "galioidolofdurand", duration = 1}, --Ezreal's R
		{name = "gragasdrunkenrage", duration = 0.5}, --""Gragas W
		{name = "luxmalicecannon", duration = 0.5}, --Lux R
		{name = "reapthewhirlwind", duration = 1}, --Jannas R
		{name = "jinxw", duration = 0.5}, --jinxW
		{name = "jinxr", duration = 0.5}, --jinxR
		{name = "missfortunebullettime", duration = 1}, --MissFortuneR
		{name = "shenstandunited", duration = 1}, --ShenR
		{name = "threshe", duration = 0.4}, --ThreshE
		{name = "threshrpenta", duration = 0.75}, --ThreshR
		{name = "infiniteduress", duration = 0.5}, --Warwick R
		{name = "meditate", duration = 1} --yi W
	}
	
	self.DebugMode = false
	
	self.WayPointManager = WayPointManager()
	self.WayPointManager.AddCallback(function(NetworkID) self:NewWayPoints(NetworkID) end)
	
	AdvancedCallback:bind('OnGainBuff', function(hero, buff) self:OnGainBuff(hero, buff) end)
	AdvancedCallback:bind('OnLoseVision', function(hero) self:OnLoseVision(hero) end)
	--AdvancedCallback:bind('OnGainVision', function(hero) self:OnGainVision(hero) end)
	AdvancedCallback:bind('OnDash', function(hero, dash) self:OnDash(hero, dash) end)
	AddProcessSpellCallback(function() self:OnProcessSpell(unit, spell) end)
	AddTickCallback(function() self:OnTick() end)
	AddDrawCallback(function() self:OnDraw() end)
	
	for i, enemy in ipairs(GetEnemyHeroes()) do
	
		self.LastImmobileT[enemy.networkID] = os.clock()
		
		if enemy.visible then
			self.EnemiesVisible[enemy.networkID] = os.clock()
		else
			self.EnemiesVisible[enemy.networkID] = math.huge
		end
	end
	
	if not self.DebugMode then
		PrintChat("<font color=\"#BF5FFF\">PPrediction "..(self.version).." Loaded</font>")
	else
		PrintChat("<font color=\"#BF5FFF\">[DEBUG] PPrediction "..(self.version).." Loaded</font>")
	end
end

function PPrediction:OnTick()
	self.tickcap = self.tickcap and self.tickcap or 0
	if (os.clock() - self.tickcap) > 0.2 then
		self.tickcap = os.clock()
		self:RemoveOldCC()
		self:RemoveOldDashes()
		self:RemoveOldWayPoints()
		
		
		for _, hero in ipairs(GetEnemyHeroes()) do
			for i = 1, hero.buffCount do
				local buff = hero:getBuff(i)
				if buff.valid and buff.name == "Stun" then
					local found = false
					local CCtable = self.EnemiesCC
					for _, stunned in ipairs(CCtable) do
						if (stunned.networkID == hero.networkID) and (stunned.endT - os.clock() + buff.endT - buff.startT) < 100 then
							found = true
						end
					end
					if not found then
						table.insert(self.EnemiesCC, {endT = os.clock() + (buff.endT - buff.startT), networkID = hero.networkID})
					end
				end
			end
		end
	end
	
end

function PPrediction:pythag(x,y)
	local to_return = math.sqrt(math.pow(x,2) + math.pow(y,2))
	return to_return
end


function PPrediction:return_cartesian_from_polar(theta, r)
	local cartesian_coordinates = {x = r * math.cos(theta), y = r * math.sin(theta)}
	return cartesian_coordinates
end
--[[Gets called when there are new waypoints to be stored]]
function PPrediction:NewWayPoints(NetworkID)	
	--[[Add the new waypoints to the table]]
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if enemy.networkID == NetworkID then
			local waypointstoadd = self.WayPointManager:GetWayPoints(enemy)
			local current_way_point = self.WayPointManager:GetWayPoints(enemy)
			local my_current_position = self.WayPointManager:GetWayPoints(myHero)
			local diff_coordinates = {x = current_way_point.x - my_current_position.x, y = current_way_point.y - my_current_position.y}
			local polar_coordinate = {theta = math.atan2(diff_coordinates.x, diff_coordinates.y), r = self.pythag(diff_coordinates.x, diff_coordinates.y)}
			--[[you can't generate new waypoints if you are stunned]]
			self:RemoveCC(NetworkID)
			table.insert(self.EnemiesWaypoints, {networkID = NetworkID, waypoints = polar_coordinate, time = os.clock()})
			
			--[[New weaypoints meas that the enemy is visible]]
			self.EnemiesVisible[NetworkID] = os.clock()
		end
	end

	if NetworkID == myHero.networkID then
		table.insert(self.MyWaypoints, {waypoints = waypointstoadd, time=os.clock()})
	end
end

--[[Returns all the waypoints set from a hero from X seconds to Y seconds ago]]
function PPrediction:GetWayPoints(hero, from, to)
	local result = {}
	local waypoints = self.EnemiesWaypoints
	for i, waypoint in ipairs(waypoints) do
		if waypoint.networkID == hero.networkID and (os.clock() - waypoint.time) < from and (os.clock() - waypoint.time) > to then
			table.insert(result, waypoint)
		end
	end
	return result
end


function PPrediction:GetMyWayPoints(from, to)
	local result = {}
	local waypoints = self.MyWaypoints
	for i, waypoint in ipairs(waypoints)
		if (os.clock() - waypoint.time) < from and (os.clock() - waypoint.time) > to then
			table.insert(result, waypoint)
		end
	end
	return result
end

--[[Deletes the waypoints older than 10 secs]]
function PPrediction:RemoveOldWayPoints()
	local waypoints = self.EnemiesWaypoints
	local i = 1
	while i <= #waypoints do
		if (os.clock() - waypoints[i].time) >= 10 then
			table.remove(waypoints, i)
		else
			i = i + 1
		end
	end
	self.EnemiesWaypoints = waypoints
end



function PPrediction:RemoveMyWaypoints()
	local waypoints = self.MyWaypoints
	local i = 1
	while i <= #waypoints do
		if (os.clock() - waypoints[i].time) >= 10 then
			table.remove(waypoints, i)
		else
			i = i + 1
		end
	end
	self.MyWaypoints = waypoints
end	


--[[Deletes waypoints from a network id]]
function PPrediction:DeleteWaypoints(NetworkID)
	local waypoints = self.EnemiesWaypoints
	local i = 1
	while i <= #waypoints do
		if waypoints[i].networkID == NetworkID then
			table.remove(waypoints, i)
		else
			i = i + 1
		end
	end
	self.EnemiesWaypoints = waypoints
end


function PPrediction:DeleteMyWaypoints()
	local waypoints = self.MyWaypoints
	table.remove(waypoints, 1)
	self.MyWaypoints = waypoints
end

--[[Track when we lose or gain vision over an enemy]]
function PPrediction:OnGainVision(hero)
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if hero.networkID == enemy.networkID then
			self.EnemiesVisible[hero.networkID] = os.clock()
		end
	end
end

function PPrediction:isVisible(hero)
	return self.EnemiesVisible[hero.networkID] and (self.EnemiesVisible[hero.networkID] < os.clock()) or hero.visible
end

function PPrediction:OnLoseVision(hero)
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if hero.networkID == enemy.networkID then
			self.EnemiesVisible[hero.networkID] = math.huge
			self:DeleteWaypoints(enemy.networkID)
		end
	end
end

function PPrediction:OnDash(hero, dash)
	if hero.type == 'obj_AI_Hero' then
		if not dash.endPos then
			dash.endPos = Vector(dash.target.x, 0, dash.target.z)
		end
		self:DeleteWaypoints(hero.networkID)
		dash.duration = dash.duration <= 2 and dash.duration or 2 --sometimes dahs surations are so long? (riven)
		table.insert(self.EnemiesDashing, {startT = os.clock(), endT = os.clock() + dash.duration, networkID = hero.networkID, from = Vector(dash.startPos.x, 0, dash.startPos.z), to = Vector(dash.endPos.x, 0, dash.endPos.z), speed=dash.speed })
	end
end

--[[Check if the enemy is dashing and returns the position where the spell should be casted depending on the radius and the delay]]
function PPrediction:IsDashing(hero, delay, radius, speed, from)
	local DashList = self.EnemiesDashing 
	local position = nil
	local remainingdistance = nil
	
	for i, dash in ipairs(DashList) do
		if dash.networkID == hero.networkID and (dash.endT - os.clock()) > 0 then
			local remainingtime = (dash.endT - os.clock())
			if speed == nil and from == nil then
				if remainingtime > delay then --mid air
					position = Vector(dash.from.x, 0, dash.from.z) + (os.clock() - dash.startT + delay) * dash.speed * Vector(dash.to.x - dash.from.x, 0, dash.to.z - dash.from.z):normalized()
					remainingdistance = 0
				else	--landed
					remainingdistance = hero.ms * (delay - remainingtime)
					position = Vector(dash.to.x, 0, dash.to.z)
				end
				break
			elseif speed ~= nil and from ~= nil then
				local t1, p1, t2, p2, dist = VectorMovementCollision(dash.from, dash.to, dash.speed, from, speed, delay + os.clock() - dash.startT)
				t1, t2 = (t1 and 0 <= t1 and t1 <= (dash.endT - os.clock() - delay)) and t1 or nil, (t2 and 0 <= t2 and t2 <=  (dash.endT - os.clock() - delay)) and t2 or nil 
            			local t = t1 and t2 and math.min(t1,t2) or t1 or t2
            			if t then --mid air
						position = t==t1 and Vector(p1.x, 0, p1.y) or Vector(p2.x, 0, p2.y)
						remainingdistance = 0
            			else
					position = Vector(dash.to.x, 0, dash.to.z)
					remainingdistance = hero.ms * (delay + GetDistance(from, position)/speed - remainingtime)
				end
			end
		end
	end
	return position, remainingdistance
end

function PPrediction:RemoveOldDashes()
	local Dashes = self.EnemiesDashing 
	local i = 1
	while i <= #Dashes do
		if (os.clock() - Dashes[i].endT) > 5 then
			table.remove(Dashes, i)
		else
			i = i + 1
		end
	end
	self.EnemiesDashing = Dashes
end

function PPrediction:OnGainBuff(hero, buff)
	--[[ Check for CC'd targets ]]
	if (hero.type == 'obj_AI_Hero')  and hero.team ~= myHero.team and (buff.type == BUFF_STUN or buff.type == BUFF_ROOT or buff.type == BUFF_KNOCKUP or buff.type == BUFF_SUPPRESS) then
		--self:DeleteWaypoints(hero.networkID)
		table.insert(self.EnemiesCC, {endT = os.clock() + buff.duration, networkID = hero.networkID})
	elseif (hero.type == 'obj_AI_Hero')  and hero.team ~= myHero.team and (buff.type == BUFF_SLOW or buff.type == BUFF_CHARM or buff.type == BUFF_FEAR or buff.type == BUFF_TAUNT) then
		--Table to save slowed enemies
		table.insert(self.EnemiesSlowed, {endT = os.clock() + buff.duration, networkID = hero.networkID})
	end
end

function PPrediction:OnProcessSpell(hero, spell) 
	if hero and (hero.type == 'obj_AI_Hero') and hero.team ~= myHero.team then
		for i, s in ipairs(self.spells) do
			if spell.name:lower() == s.name then
				--self:DeleteWaypoints(hero.networkID)
				table.insert(self.EnemiesCC, {endT = os.clock() + 5, networkID = hero.networkID})
			end
		end
	end
end

--[[Checks if the hero can move after X seconds delay; returns if the enemy is stunned and the distance that the hero will be able to do after being able to move]]
function PPrediction:Canmove(hero, delay)
	local CCList = self.EnemiesCC
	local remainingdistance = -1
	local canmove = true
	
	for i, CC in pairs(CCList) do
		if CC.networkID == hero.networkID and (CC.endT - os.clock()) > 0 then
			local remainingtime = (CC.endT - os.clock()) --remaining time until the hero can move
			if remainingtime > delay then
				remainingdistance = 0 --hero wont move 
			else
				remainingdistance = hero.ms * (delay - remainingtime) --hero will be able to move this distance
			end
			canmove = false
			break
		end
	end
	return canmove, remainingdistance
end

--[[Returns if the hero is slowed or not]]
function PPrediction:isSlowed(hero)
	local SList = self.EnemiesSlowed
	local isslowed = false
	for i, Slowed in ipairs(SList) do
		if Slowed.networkID == hero.networkID and (Slowed.endT - os.clock()) > 0 then
			isslowed = true
		end
	end
	return isslowed
end

function PPrediction:RemoveCC(networkID)
	local CCS = self.EnemiesCC
	local i = 1
	
	while i <= #CCS do
		if networkID == CCS[i].networkID then
			self.LastImmobileT[networkID] = os.clock()
			table.remove(CCS, i)
		else
			i = i + 1
		end
	end
	self.EnemiesCC = CCS
end

function PPrediction:RemoveOldCC()
	--[[Remove old stunned targets from the table ]]
	local CCS = self.EnemiesCC
	local i = 1
	
	while i <= #CCS do
		if (os.clock() - CCS[i].endT) > 0 then
			self.LastImmobileT[CCS[i].networkID] = os.clock()
			table.remove(CCS, i)
		else
			i = i + 1
		end
	end
	
	--[[Remove slowed]]
	local Slowed = self.EnemiesSlowed
	local j = 1
	while j <= #Slowed do
		if (os.clock() - Slowed[j].endT) > 0 then
			table.remove(Slowed, j)
		else
			j = j + 1
		end
	end
	
	self.EnemiesCC = CCS
	self.EnemiesSlowed = Slowed
end

--[[Get where the hero is going to be after X seconds delay]]
function PPrediction:CalculateHeroPositionCircle(hero, delay, waypoints, radius)
	local remainingtime = delay
	local remainingdistance = delay * hero.ms
	local remainingdistance2 = remainingdistance - radius
	local position = Vector(hero.x, 0, hero.z)
	
	if #waypoints == 1 then -- target not moving
		position = Vector(waypoints[#waypoints].x, 0, waypoints[#waypoints].y)
		castpoint = position
		remainingdistance = 0 --special case
	elseif #waypoints > 1 then
		for i = 1, #waypoints - 1 do
			local A, B = waypoints[i], waypoints[i+1]
			local D = GetDistance(A, B)
			position = Vector(B.x, 0, B.y)
			castpoint = position
			
			if D > remainingdistance2 then
				castpoint =  Vector(A.x, 0, A.y) + remainingdistance2 * Vector(B.x - A.x, 0, B.y - A.y):normalized()
				remainingdistance2 = 0
			else
				remainingdistance2 = remainingdistance2 - D
			end
			
			if D > remainingdistance then
				--[[it will be in this line, calculate the exact position]]
				position = Vector(A.x, 0, A.y) + remainingdistance * Vector(B.x - A.x, 0, B.y - A.y):normalized()
				remainingdistance = 0
				remainingdistance2 = 0
				break
			else
				remainingdistance = remainingdistance - D
			end
		end
	end
	
	if self:isSlowed(hero) then
		castpoint = position
	end
	--[[ Returns the position and the distance that the hero could do if there are not enough waypoints]]
	return position, castpoint, (remainingdistance < radius)
end


function PPrediction:CalculateHeroPositionLine(hero, delay, waypoints, radius, speed, from)
	local remainingtime = delay
	local remainingdistance = delay * hero.ms
	local position = Vector(hero.x, 0, hero.z)
	local castpoint = position
	
	if #waypoints == 1 then -- target not moving
		position = Vector(waypoints[#waypoints].x, 0, waypoints[#waypoints].y)
		castpoint = position
		remainingdistance = 0
	elseif #waypoints > 1 then
		local tA = 0
		radius = radius * 0.8
		for i = 1, #waypoints - 1 do
			local A, B = waypoints[i], waypoints[i+1]
			local t1, p1, t2, p2, D =  VectorMovementCollision(A, B, hero.ms, from, speed)
			local tB = tA + D / hero.ms
            		t1, t2 = (t1 and tA <= t1 and t1 <= tB) and t1 or nil, (t2 and tA <= t2 and t2 <= tB) and t2 or nil
            
            
            		local t = t1 and t2 and math.min(t1,t2) or t1 or t2
            		if t then
            			position = t==t1 and Vector(p1.x, 0, p1.y) or Vector(p2.x, 0, p2.y)
            			remainingdistance = 0
            			castpoint = position - radius * Vector(A.x - position.x, 0, A.y - position.z):normalized()
            			break
            		end
		end
		
		--Logic In Case there is no prediction 'till the last wayPoint
		if i == #waypoints - 1 then
			position = Vector(B.x, 0, B.y)
			remainingdistance = math.huge
			castpoint = Vector(B.x, 0, B.y)
		end
		--no prediction in the current segment, go to next waypoint
		tA = tB		    
	end
	
	if self:isSlowed(hero) then
		castpoint = position
	end
	--[[ Returns the position and the distance that the hero could do if there are not enough waypoints]]
	return position, castpoint, (remainingdistance < radius)
end

--[[Returns all the waypoints from the past mtime seconds]]
function PPrediction:GetWaypointsSet(hero, mtime)
	local waypoints = self.EnemiesWaypoints
	local set = {}
	for i, waypoint in ipairs(waypoints) do
		if waypoint.networkID == hero.networkID and (os.clock() - waypoint.time) <= mtime then
			table.insert(set, waypoint)
		end
	end
	return set
end

function PPrediction:GetSecondLatestWaypoints(hero)
	local waypoints = self.EnemiesWaypoints
	local last = nil
	local slast = nil
	for i, waypoint in ipairs(waypoints) do
		if waypoint.networkID == hero.networkID then
			slast = last and last or nil
			last = waypoint
		end
	end
	return slast
end

function PPrediction:GetLatestWaypoints(hero)
	local waypoints = self.EnemiesWaypoints
	local last = nil
	for i, waypoint in ipairs(waypoints) do
		if waypoint.networkID == hero.networkID then
			last = waypoint
		end
	end
	return last
end

--[[Counts the number of waypoint sets]]
function PPrediction:CountSets(waypointset)
	return #waypointset
end

--[[Returns the mean (center), dispersion (spreadness?) waypoints from the hero waypoints set]]
function PPrediction:CheckCircular(hero, mtime, LastWaypointPoint)
	local waypoints = self:GetWaypointsSet(hero, mtime)
	local dispersion = 0
	local lastwaypointposition = nil
	local points = {}
	
	if #waypoints == 1 then
		return  0, Vector(hero.x, 0, hero.z)
	elseif #waypoints > 1 then
		local meanwaypoint = Vector(0, 0, 0)
		local currentwaypoint = Vector(0, 0, 0)
		for i, cwaypoints in ipairs(waypoints) do
			local waypointset = cwaypoints.waypoints
			currentwaypoint = Vector(waypointset[#waypointset].x, 0, waypointset[#waypointset].y)
			table.insert(points, currentwaypoint)
		end
		
		local meanpoint = Vector(0,0,0)
		for i, point in ipairs(points) do
			meanpoint = meanpoint + point
		end
		meanpoint = Vector(meanpoint.x / #points, 0, meanpoint.z/#points)
		
		local mdispersion = 0
		for i, point in ipairs(points) do
			mdispersion = mdispersion + GetDistance(point, meanpoint)
		end
		
		mdispersion = mdispersion / #points 
		if GetDistance(meanpoint, hero) <= 50 then
			return -1, Vector(0, 0, 0)
		end
		
		mdispersion = 250/GetDistance(meanpoint, hero) * mdispersion
		return mdispersion, meanpoint
	else
		return -1, Vector(0, 0, 0)
	end
end

--[[Returns a number from 0 to 5 depending on the waypoints patterns/enemy status]]
function PPrediction:GetHitChance(target, i)
	local htable = {
		[0] = 0, -- Enemy not visible or no waypoints for that enemy
		[1] = 5, --Enemy dashing
		[2] = 4, --Enemy immobile
		[3] = 3, --Enemy can't dodge
		[4] = 1, --Last two Waypoints too spreaded (
		[5] = 2, --Enemy was immobile 0.5 seconds ago 
		[6] = 1, --Enemy trying to dodge (high APM), increased the projectile speed/decreased the delay
		[7] = 2, --Enemy is standing still #lastwaypoints == 1
		[8] = 2, --Enemy clicking in a circle pattern
		[9] = 2, --Newest waypoint 1.5 seconds old
		[10] = 2, --New waypoint1
		
		--[[
		toadd:
		11 = 2, at max range perpendicular 
		12 = 2, just in range of low health minion 
		13 = 2, just in range of low health ally
		]]
	}
	return target.type == myHero.type and htable[i] or 2
end

--[[ returns the hitbox of an object]]
function PPrediction:GetHitBox(object)
	return 50
end

--[[Returns the best position to cast the spell, also returns if the spell should be casted (hitchance)]]
function PPrediction:GetCircularCastPosition(hero, delay, radius, range, speed, from)
	range = range and range or math.huge
	from = from and from or myHero
	
	if speed ~= nil then
		return self:GetLineCastPosition(hero, delay, radius, range, speed, from)
	end
	
	delay = delay + GetLatency() / 2000 --Take into account the lag
	radius = radius > 1 and radius or 1
	radius = radius + self:GetHitBox(hero)
	radius = radius * 0.8
	--Check if the enemy is dashing
	local DashPos, remainingdistance =  self:IsDashing(hero, delay, radius)
	if DashPos and remainingdistance <= radius then --enemy dashing
		return Vector(DashPos.x, 0, DashPos.z), self:GetHitChance(hero, 1), Vector(DashPos.x, 0, DashPos.z)
	end
	
	--Check if the enemy is stunned
	local canmove, remainingdistance = self:Canmove(hero, delay)
	if not canmove and remainingdistance <= radius then -- hero stunned
		return Vector(hero.x, 0, hero.z), self:GetHitChance(hero, 2), Vector(hero.x, 0, hero.z)
	end
	
	--Enemy not visible
	if not self:isVisible(hero) then
		return Vector(hero.x, 0, hero.z), self:GetHitChance(hero, 0), Vector(hero.x, 0, hero.z)
	end
	
	--[[Get latest simulated waypoints from the waypoint manager]]
	local LastWayPoints = self.WayPointManager:GetSimulatedWayPoints(hero, 0, math.huge)
	
	if #LastWayPoints > 0 and GetDistance({x=hero.x, y=hero.z}, LastWayPoints[1]) > 100 then
		return Vector(hero.x, 0, hero.z), self:GetHitChance(hero, 0), Vector(hero.x, 0, hero.z)
	end
	
	
	local LatestLoggedWaypoint = self:GetLatestWaypoints(hero)
	
	if not LastWayPoints or #LastWayPoints == 0 then
		return Vector(hero.x, 0, hero.z), self:GetHitChance(hero, 0), Vector(hero.x, 0, hero.z)
	end
	
	local PredictedPosition, CastPosition, ShouldCast = self:CalculateHeroPositionCircle(hero, delay, LastWayPoints, radius)
	local IsAtMaxRange = false
	
	if GetDistance(from, CastPosition) > range and GetDistance(from, PredictedPosition) <= (range + radius) then
		--[[Don't shot unless the enemy is stopped or with low ms]]
		if GetDistance(CastPosition, hero) > radius then
			IsAtMaxRange = true
		end
		CastPosition = Vector(from.x, 0, from.z) + range * Vector(PredictedPosition.x - from.x, 0, PredictedPosition.z - from.z):normalized()
	end

	if ShouldCast and not IsAtMaxRange and LatestLoggedWaypoint then
		--Check if the enemy can dodge
		local requiredms = radius / delay  --Required movement speed to dodge a skillshot casted just at the champion
		if requiredms > hero.ms then
			return CastPosition, self:GetHitChance(hero, 3), PredictedPosition
		end

		--[[Get the latest waypoint set's stored from the target from the last second]]
		local TargetWaypoints = self:GetWaypointsSet(hero, 1)
		
		--[[Number of waypoints created in the last second]]
		local Rate1 = self:CountSets(self:GetWayPoints(hero, 1, 0))
		
		--[[The mean waypoints created in the last 4 seconds]]
		local MeanRate = self:CountSets(self:GetWayPoints(hero, 4, 0)) / 4
		local NewTime = 0.1
		local OldTime = 0.6
		
		
		if (#LastWayPoints == 1) and (os.clock() - LatestLoggedWaypoint.time < 0.150) then
			return Vector(hero.x, 0, hero.z), self:GetHitChance(hero, 7), Vector(hero.x, 0, hero.z)
		end
		
		--Check if the enemy has been immobile in the last 0.5 seconds
		if self.LastImmobileT[hero.networkID] and (os.clock() - self.LastImmobileT[hero.networkID]) <= 0.5 and (os.clock() - LatestLoggedWaypoint.time < 0.150) then
			return CastPosition, self:GetHitChance(hero, 5), PredictedPosition
		end

		local SLast = self:GetSecondLatestWaypoints(hero)
		if SLast then
			local SLastPoint = SLast.waypoints
			local LastPoint = LatestLoggedWaypoint.waypoints
			
			if (os.clock() - SLast.time > OldTime*3) and (os.clock() - LatestLoggedWaypoint.time < NewTime) then
				return CastPosition,  self:GetHitChance(hero, 10), PredictedPosition
			end
			
			if GetDistance(SLastPoint[#SLastPoint], LastPoint[#LastPoint]) > 600 and (os.clock() - LatestLoggedWaypoint.time < 0.5) then
				--To test: Make the skillshot faster if they are trying to dodge (high click rate)
				if Rate1 > MeanRate then
					PredictedPosition, CastPosition, ShouldCast = self:CalculateHeroPositionCircle(hero, delay*0.75, LastWayPoints, radius)
					return CastPosition,  self:GetHitChance(hero, 6), PredictedPosition
				end
				
				
				return CastPosition, 1, PredictedPosition
			end
		end
		
		--[[Check if the enemy is clicking in a circular area]]
		local Dispersion, Center = self:CheckCircular(hero, 1, LastWayPoints[#LastWayPoints])
		--[[Probably enemy is trying to escape spamming clicks in one circular area]]
		if (Rate1 > MeanRate) and (Dispersion <= 501) and Dispersion > 0 then
			if (os.clock() - LatestLoggedWaypoint.time < NewTime) or (os.clock() - LatestLoggedWaypoint.time > OldTime) then 
				return CastPosition,  self:GetHitChance(hero, 8), PredictedPosition
			end
		end
		
		if (os.clock() - LatestLoggedWaypoint.time > 1.5) then
			return CastPosition, self:GetHitChance(hero, 9), PredictedPosition
		end
		
		return CastPosition, 1, PredictedPosition
	else
		return CastPosition, 1, PredictedPosition
	end
end

function PPrediction:GetLineCastPosition(hero, delay, radius, range, speed, from)
	from = from and from or myHero
	
	if not speed or speed == math.huge then
		return self:GetCircularCastPosition(hero, delay, radius, range)
	end
	
	delay = delay + GetLatency() / 2000 --Take into account the lag
	radius = radius > 1 and radius or 1 
	radius = radius + self:GetHitBox(hero)

	--Check if the enemy is dashing
	local DashPos, remainingdistance = self:IsDashing(hero, delay, radius, speed, from)
	if DashPos and remainingdistance <= radius then --enemy dashing
		return Vector(DashPos.x, 0, DashPos.z), self:GetHitChance(hero, 1), Vector(DashPos.x, 0, DashPos.z)
	end
	
	--Check if the enemy is stunned
	local canmove, remainingdistance = self:Canmove(hero, delay + GetDistance(from, hero) / speed)
	if not canmove and remainingdistance <= radius then -- hero stunned
		return Vector(hero.x, 0, hero.z), self:GetHitChance(hero, 2), Vector(hero.x, 0, hero.z)
	end
	
	--Enemy not visible
	if not self:isVisible(hero) then
		return Vector(hero.x, 0, hero.z), self:GetHitChance(hero, 0), Vector(hero.x, 0, hero.z)
	end
	
	--[[Get latest simulated waypoints from the waypoint manager]]
	local LastWayPoints = self.WayPointManager:GetSimulatedWayPoints(hero, 0, math.huge)
	
	if #LastWayPoints > 0 and GetDistance({x=hero.x, y=hero.z}, LastWayPoints[1]) > 100 then
		return Vector(hero.x, 0, hero.z), self:GetHitChance(hero, 0), Vector(hero.x, 0, hero.z)
	end
	
	local LatestLoggedWaypoint = self:GetLatestWaypoints(hero)
	
	if #LastWayPoints == 0 then
		return Vector(hero.x, 0, hero.z), self:GetHitChance(hero, 0), Vector(hero.x, 0, hero.z)
	end
	
	local PredictedPosition, CastPosition, ShouldCast = self:CalculateHeroPositionLine(hero, delay, LastWayPoints, radius, speed, from)
	
	if GetDistance(from, CastPosition) > range and GetDistance(from, PredictedPosition) <= (range + radius) then
		--[[Don't shot unless the enemy is stopped or with low ms]]
		if GetDistance(CastPosition, hero) > radius then
			local IsAtMaxRange = true
		end
		CastPosition = Vector(from.x, 0, from.z) + range * Vector(PredictedPosition.x - from.x, 0, PredictedPosition.z - from.z):normalized()
	end

	if ShouldCast and not IsAtMaxRange and LatestLoggedWaypoint then
		--Check if the enemy can dodge
		local requiredms = radius / delay  --Required movement speed to dodge a skillshot casted just behind the champion
		if requiredms > hero.ms then
			return CastPosition, self:GetHitChance(hero, 3), PredictedPosition
		end

		--[[Get the latest waypoint set's stored from the last second]]
		local TargetWaypoints = self:GetWaypointsSet(hero, 1)
		
		if (#LastWayPoints == 1) and (os.clock() - LatestLoggedWaypoint.time < 0.150) then
			return Vector(hero.x, 0, hero.z), self:GetHitChance(hero, 7), Vector(hero.x, 0, hero.z)
		end

		--Check if the enemy has been immobile in the last 0.5 seconds
		if self.LastImmobileT[hero.networkID] and (os.clock() - self.LastImmobileT[hero.networkID]) <= 0.5 and (os.clock() - LatestLoggedWaypoint.time < 0.150) then
			return CastPosition, self:GetHitChance(hero, 5), PredictedPosition
		end
		
		--[[Number of waypoints created in the last second]]
		local Rate1 = self:CountSets(self:GetWayPoints(hero, 1, 0))
		
		--[[The mean waypoints created in the last 4 seconds]]
		local MeanRate = self:CountSets(self:GetWayPoints(hero, 4, 0)) / 4
		local NewTime = 0.1
		local OldTime = 0.6
		
		local SLast = self:GetSecondLatestWaypoints(hero)

		if SLast then
			local SLastPoint = SLast.waypoints
			local LastPoint = LatestLoggedWaypoint.waypoints
			
			if (os.clock() - SLast.time > OldTime*5) and (os.clock() - LatestLoggedWaypoint.time < NewTime) then
				return CastPosition, self:GetHitChance(hero, 10), PredictedPosition
			end
			
			if GetDistance(SLastPoint[#SLastPoint], LastPoint[#LastPoint]) > 600 and (os.clock() - LatestLoggedWaypoint.time < 0.3) then
				return CastPosition, self:GetHitChance(hero, 4), PredictedPosition
			end
		end
		
		--[[Check if the enemy is clicking in a circular area]]
		local Dispersion, Center = self:CheckCircular(hero, 1, LastWayPoints[#LastWayPoints])
		--[[Probably enemy is trying to escape spamming clicks in one circular area]]
		if (Rate1 > MeanRate) and (Dispersion <= 501) and Dispersion > 0 then
			if (os.clock() - LatestLoggedWaypoint.time < NewTime) or (os.clock() - LatestLoggedWaypoint.time > OldTime) then 
				return CastPosition, self:GetHitChance(hero, 8), PredictedPosition
			end
		end
		
		if (os.clock() - LatestLoggedWaypoint.time > 1.5) then
			return CastPosition, self:GetHitChance(hero, 9), PredictedPosition
		end
		
		return CastPosition, 1, PredictedPosition
	else
		return CastPosition, 1, PredictedPosition
	end
end

function PPrediction:GetPredictedPos(hero, delay, speed, from)
	from = from and from or myHero
	local CP, SC, HP
	
	if speed == nil or speed == math.huge then
		CP, SC, HP =  self:GetCircularCastPosition(hero, delay, 1, math.huge)
	else
		CP, SC, HP =  self:GetLineCastPosition(hero, delay, 1, math.huge, speed, from)
	end
	
	return HP, SC
end

function PPrediction:OnDraw()
	if self.DebugMode then
		for _, hero in ipairs(GetEnemyHeroes()) do
			local lastwaypoint = self:GetLatestWaypoints(hero)
			if lastwaypoint then
				lastwaypoint.waypoints = self.WayPointManager:GetWayPoints(hero)
				if lastwaypoint then
					for i, wp in ipairs(lastwaypoint.waypoints) do
						DrawCircle(wp.x, 0, wp.y, 80, ARGB(255, 0, 255, 0))
						DrawText3D(tostring(self:CountSets(self:GetWayPoints(hero, 4, 0))/4), hero.x+100, hero.y, hero.z, 30, ARGB(255,255,0,0), true)
						DrawText3D(tostring(self:CountSets(self:GetWayPoints(hero, 1, 0))), hero.x, hero.y, hero.z, 30, ARGB(255,0,255,0), true)
					end
				end
			end
		end	
	end
end
--}
