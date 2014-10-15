-- Change autoUpdate to false if you wish to not receive auto updates.
-- Change silentUpdate to true if you wish not to receive any message regarding updates
local autoUpdate   = false
local silentUpdate = false

local version = 1.2 -- 1.2 by dienofail to fix bilbao's fix of other people's fix of honda's stuff

--[[
    Introduction:
        We were tired of updating every single script we developed so far so we decided to have it a little bit
        more dynamic with a custom library which we can update instead and every script using it will automatically
        be updated (of course only the parts which are in this lib). So let's say packet casting get's fucked up
        or we want to change the way some drawing is done, we just need to update it here and all scripts will have
        the same tweaks then.

    Contents:
        Require         -- A basic but powerful library downloader
        SourceUpdater   -- One of the most basic functions for every script we use
        Spell           -- Spells handled the way they should be handled
        DrawManager     -- Easy drawing of all kind of things, comes along with some other classes such as Circle
        DamageLib       -- Calculate the damage done do others and even print it on their healthbar
        STS             -- SimpleTargetSelector is a simple and yet powerful target selector to provide very basic target selecting
        MenuWrapper     -- Easy menu creation with only a few lines
        Interrupter     -- Easy way to handle interruptable spells
        AntiGetcloser   -- Never let them get close to you

]]

-- Namespace by pqmailer, added for Prodiction support reasons
-- Used for several things in the future, like menues etc.
_G.srcLib = {}

--[[

'||''|.                              ||                  
 ||   ||    ....    ... .  ... ...  ...  ... ..    ....  
 ||''|'   .|...|| .'   ||   ||  ||   ||   ||' '' .|...|| 
 ||   |.  ||      |.   ||   ||  ||   ||   ||     ||      
.||.  '|'  '|...' '|..'||   '|..'|. .||. .||.     '|...' 
                       ||                                
                      ''''                               

    Require - A simple library downloader

    Introduction:
        If you want to use this class you need to put this at the beginning of you script.
        Example:
            -------------------------------------
            if player.charName ~= "Brand" then return end
            require "SourceLib"

            local libDownloader = Require("Brand script")
            libDownloader:Add("VPrediction", "https://bitbucket.org/honda7/bol/raw/master/Common/VPrediction.lua")
            libDownloader:Add("SOW",         "https://bitbucket.org/honda7/bol/raw/master/Common/SOW.lua")
            libDownloader:Check()

            if libDownloader.downloadNeeded then return end
            -------------------------------------

    Functions:
        Require(myName)

    Members:
        Require.downloadNeeded

    Methods:
        Require:Add(name, url)
        Require:Check()
]]
class 'Require'

function __require_afterDownload(requireInstance)

    requireInstance.downloadCount = requireInstance.downloadCount - 1
    if requireInstance.downloadCount == 0 then
        print("<font color=\"#6699ff\"><b>" .. requireInstance.myName .. ":</b></font> <font color=\"#FFFFFF\">Required libraries downloaded! Please reload!</font>")
    end

end

function Require:__init(myName)

    self.myName = myName or GetCurrentEnv().FILE_NAME
    self.downloadNeeded = false

    self.requirements = {}

end

function Require:Add(name, url)

    assert(name and type(name) == "string" and url and type(url) == "string", "Require:Add(): Some or all arguments are invalid.")
    
    self.requirements[name] = url

    return self

end

function Require:Check()

    for scriptName, scriptUrl in pairs(self.requirements) do
        local scriptFile = LIB_PATH .. scriptName .. ".lua"
        if FileExist(scriptFile) then
            require(scriptName)
        else
            self.downloadNeeded = true
            self.downloadCount = self.downloadCount and self.downloadCount + 1 or 1
            DownloadFile(scriptUrl, scriptFile, function() __require_afterDownload(self) end)
        end
    end

    return self

end


--[[

 .|'''.|                                           '||'  '|'               '||            .                   
 ||..  '    ...   ... ...  ... ..    ....    ....   ||    |  ... ...     .. ||   ....   .||.    ....  ... ..  
  ''|||.  .|  '|.  ||  ||   ||' '' .|   '' .|...||  ||    |   ||'  ||  .'  '||  '' .||   ||   .|...||  ||' '' 
.     '|| ||   ||  ||  ||   ||     ||      ||       ||    |   ||    |  |.   ||  .|' ||   ||   ||       ||     
|'....|'   '|..|'  '|..'|. .||.     '|...'  '|...'   '|..'    ||...'   '|..'||. '|..'|'  '|.'  '|...' .||.    
                                                              ||                                              
                                                             ''''                                             


    SourceUpdater - a simple updater class

    Introduction:
        Scripts that want to use this class need to have a version field at the beginning of the script, like this:
            local version = YOUR_VERSION (YOUR_VERSION can either be a string a a numeric value!)
        It does not need to be exactly at the beginning, like in this script, but it has to be within the first 100
        chars of the file, otherwise the webresult won't see the field, as it gathers only about 100 chars

    Functions:
        SourceUpdater(scriptName, version, host, updatePath, filePath, versionPath)

    Members:
        SourceUpdater.silent | bool | Defines wheather to print notifications or not

    Methods:
        SourceUpdater:SetSilent(silent)
        SourceUpdater:CheckUpdate()

]]
class 'SourceUpdater'

--[[
    Create a new instance of SourceUpdater

    @param scriptName  | string        | Name of the script which should be used when printed in chat
    @param version     | float/string  | Current version of the script
    @param host        | string        | Host, for example "bitbucket.org" or "raw.github.com"
    @param updatePath  | string        | Raw path to the script which should be updated
    @param filePath    | string        | Path to the file which should be replaced when updating the script
    @param versionPath | string        | (optional) Path to a version file to check against. The version file may only contain the version.
]]
function SourceUpdater:__init(scriptName, version, host, updatePath, filePath, versionPath)

    self.printMessage = function(message) if not self.silent then print("<font color=\"#6699ff\"><b>" .. self.UPDATE_SCRIPT_NAME .. ":</b></font> <font color=\"#FFFFFF\">" .. message .. "</font>") end end
    self.getVersion = function(version) return tonumber(string.match(version or "", "%d+%.?%d*")) end

    self.UPDATE_SCRIPT_NAME = scriptName
    self.UPDATE_HOST = host
    self.UPDATE_PATH = updatePath .. "?rand="..math.random(1,10000)
    self.UPDATE_URL = "https://"..self.UPDATE_HOST..self.UPDATE_PATH

    -- Used for version files
    self.VERSION_PATH = versionPath and versionPath .. "?rand="..math.random(1,10000)
    self.VERSION_URL = versionPath and "https://"..self.UPDATE_HOST..self.VERSION_PATH

    self.UPDATE_FILE_PATH = filePath

    self.FILE_VERSION = self.getVersion(version)
    self.SERVER_VERSION = nil

    self.silent = false

end

--[[
    Allows or disallows the updater to print info about updating

    @param  | bool   | Message output or not
    @return | class  | The current instance
]]
function SourceUpdater:SetSilent(silent)

    self.silent = silent
    return self

end

--[[
    Check for an update and downloads it when available
]]
function SourceUpdater:CheckUpdate()

    local webResult = GetWebResult(self.UPDATE_HOST, self.VERSION_PATH or self.UPDATE_PATH)
    if webResult then
        if self.VERSION_PATH then
            self.SERVER_VERSION = webResult
        else
            self.SERVER_VERSION = string.match(webResult, "%s*local%s+version%s+=%s+.*%d+%.%d+")
        end
        if self.SERVER_VERSION then
            self.SERVER_VERSION = self.getVersion(self.SERVER_VERSION)
            if not self.SERVER_VERSION then
                print("SourceLib: Please contact the developer of the script \"" .. (GetCurrentEnv().FILE_NAME or "DerpScript") .. "\", since the auto updater returned an invalid version.")
                return
            end
            if self.FILE_VERSION < self.SERVER_VERSION then
                self.printMessage("New version available: v" .. self.SERVER_VERSION)
                self.printMessage("Updating, please don't press F9")
                DelayAction(function () DownloadFile(self.UPDATE_URL, self.UPDATE_FILE_PATH, function () self.printMessage("Successfully updated, please reload!") end) end, 2)
            else
                self.printMessage("You've got the latest version: v" .. self.SERVER_VERSION)
            end
        else
            self.printMessage("Something went wrong! Please manually update the script!")
        end
    else
        self.printMessage("Error downloading version info!")
    end

end


--[[

 .|'''.|                   '||  '||  
 ||..  '  ... ...    ....   ||   ||  
  ''|||.   ||'  || .|...||  ||   ||  
.     '||  ||    | ||       ||   ||  
|'....|'   ||...'   '|...' .||. .||. 
           ||                        
          ''''                       

    Spell - Handled with ease!

    Functions:
        Spell(spellId, range, packetCast)

    Members:
        Spell.range          | float  | Range of the spell, please do NOT change this value, use Spell:SetRange() instead
        Spell.rangeSqr       | float  | Squared range of the spell, please do NOT change this value, use Spell:SetRange() instead
        Spell.packetCast     | bool   | Set packet cast state
        -- This only applies for skillshots
        Spell.sourcePosition | vector | From where the spell is casted, default: player
        Spell.sourceRange    | vector | From where the range should be calculated, default: player
        -- This only applies for AOE skillshots
        Spell.minTargetsAoe  | int    | Set minimum targets for AOE damage

    Methods:
        Spell:SetRange(range)
        Spell:SetSource(source)
        Spell:SetSourcePosition(source)
        Spell:SetSourceRange(source)

        Spell:SetSkillshot(VP, skillshotType, width, delay, speed, collision)
        Spell:SetAOE(useAoe, radius, minTargetsAoe)

        Spell:SetCharged(spellName, chargeDuration, maxRange, timeToMaxRange, abortCondition)
        Spell:IsCharging()
        Spell:Charge()

        Spell:SetHitChance(hitChance)
        Spell:ValidTarget(target)

        Spell:GetPrediction(target)
        Spell:CastIfDashing(target)
        Spell:CastIfImmobile(target)
        Spell:Cast(param1, param2)

        Spell:AddAutomation(automationId, func)
        Spell:RemoveAutomation(automationId)
        Spell:ClearAutomations()

        Spell:TrackCasting(spellName)
        Spell:WillHitTarget()
        Spell:RegisterCastCallback(func)

        Spell:GetLastCastTime()

        Spell:IsInRange(target, from)
        Spell:IsReady()
        Spell:GetManaUsage()
        Spell:GetCooldown()
        Spell:GetLevel()
        Spell:GetName()

]]
class 'Spell'

-- Class related constants
SKILLSHOT_LINEAR   = 0
SKILLSHOT_CIRCULAR = 1
SKILLSHOT_CONE     = 2

-- Different SpellStates returned when Spell:Cast() is called
SPELLSTATE_TRIGGERED          = 0
SPELLSTATE_OUT_OF_RANGE       = 1
SPELLSTATE_LOWER_HITCHANCE    = 2
SPELLSTATE_COLLISION          = 3
SPELLSTATE_NOT_ENOUGH_TARGETS = 4
SPELLSTATE_NOT_DASHING        = 5
SPELLSTATE_DASHING_CANT_HIT   = 6
SPELLSTATE_NOT_IMMOBILE       = 7
SPELLSTATE_INVALID_TARGET     = 8
SPELLSTATE_NOT_TRIGGERED      = 9

-- Spell identifier number used for comparing spells
local spellNum = 1

--[[
    New instance of Spell

    @param spellId    | int          | Spell ID (_Q, _W, _E, _R)
    @param range      | float        | Range of the spell
    @param packetCast | bool         | (optional) Enable packet casting
    @param menu       | scriptCofnig | (Sub)Menu to add the spell casting menu to
]]
function Spell:__init(spellId, range, packetCast, menu)

    assert(spellId ~= nil and range ~= nil and type(spellId) == "number" and type(range) == "number", "Spell: Can't initialize Spell without valid arguments.")

    if _G.srcLib.spellMenu == nil then
        DelayAction(function(menu)
            if _G.srcLib.spellMenu == nil and not _G.srcLib.informedOutdated and Prodiction then
                if tonumber(Prodiction.GetVersion()) < 1.1 then
                    print("<b></font> <font color=\"#FF0000\">Please update your Prodiction to at least version 1.1 if you want to use it with SourceLib!</font></b>")
                    _G.srcLib.informedOutdated = true
                else
                    menu = menu or scriptConfig("[SourceLib] SpellClass", "srcSpellClass")
                    menu:addParam("predictionType", "Prediction Type",     SCRIPT_PARAM_LIST, 1, { "VPrediction", "Prodiction" })
                    _G.srcLib.spellMenu = menu
                    print("SourceLib: Prodiction support enabled, but it's highly recommended to use VPrediction at the moment due to error spamming related to Prodiction!")
                end
            end
        end, 3, { menu })
    end

    self.spellId = spellId
    self:SetRange(range)
    self.packetCast = packetCast or false

    self:SetSource(player)

    self._automations = {}

    self._spellNum = spellNum
    spellNum = spellNum + 1

    -- VPredicion default
    self.predictionType = 1

    AddTickCallback(function()
        -- Prodiction found, apply value
        if _G.srcLib.spellMenu ~= nil then
            self:SetPredictionType(_G.srcLib.spellMenu.predictionType)
        end
    end)

end

--[[
    Update the spell range with the new given value

    @param range | float | Range of the spell
    @return      | class | The current instance
]]
function Spell:SetRange(range)

    assert(range and type(range) == "number", "Spell: range is invalid")

    self.range = range
    self.rangeSqr = math.pow(range, 2)

    return self

end

--[[
    Update both the sourcePosition and sourceRange from where everything will be calculated

    @param source | Cunit | Source position, for example player
    @return       | class | The current instance
]]
function Spell:SetSource(source)

    assert(source, "Spell: source can't be nil!")

    self.sourcePosition = source
    self.sourceRange    = source

    return self

end

--[[
    Update the source posotion from where the spell will be shot

    @param source | Cunit | Source position from where the spell will be shot, player by default
    @ return      | class | The current instance
]]
function Spell:SetSourcePosition(source)

    assert(source, "Spell: source can't be nil!")

    self.sourcePosition = source

    return self

end

--[[
    Update the source unit from where the range will be calculated

    @param source | Cunit | Source object unit from where the range should be calculed
    @return       | class | The current instance
]]
function Spell:SetSourceRange(source)

    assert(source, "Spell: source can't be nil!")

    self.sourceRange = source

    return self

end

--[[
    Define this spell as skillshot (can't be reversed)

    @param VP            | class | Instance of VPrediction
    @param skillshotType | int   | Type of this skillshot
    @param width         | float | Width of the skillshot
    @param delay         | float | (optional) Delay in seconds
    @param speed         | float | (optional) Speed in units per second
    @param collision     | bool  | (optional) Respect unit collision when casting
    @rerurn              | class | The current instance
]]
function Spell:SetSkillshot(VP, skillshotType, width, delay, speed, collision)

    assert(skillshotType ~= nil, "Spell: Need at least the skillshot type!")

    self.VP = VP
    self.skillshotType = skillshotType
    self.width = width or 0
    self.delay = delay or 0
    self.speed = speed
    self.collision = collision

    if not self.hitChance then self.hitChance = 2 end

    return self

end

--[[
    Sets the prediction type

    @param typeId | int | type ID (1 = VPrediction (default), 2 = Prodiction)
]]
function Spell:SetPredictionType(typeId)

    assert(typeId and type(typeId) == 'number', 'Spell:SetPredictionType(): typeId is invalid!')
    self.predictionType = typeId

end

--[[
    Set the AOE status of this spell, this can be changed later

    @param useAoe        | bool  | New AOE state
    @param radius        | float | Radius of the AOE damage
    @param minTargetsAoe | int   | Minimum targets to be hitted by the AOE damage
    @rerurn              | class | The current instance
]]
function Spell:SetAOE(useAoe, radius, minTargetsAoe)

    self.useAoe = useAoe or false
    self.radius = radius or self.width
    self.minTargetsAoe = minTargetsAoe or 0

    return self

end

--[[
    Define this spell as charged spell

    @param spellName      | string   | Name of the spell, example: VarusQ
    @param chargeDuration | float    | Seconds of the spell to charge, after the time the charge expires
    @param maxRage        | float    | Max range the spell will have after fully charging
    @param timeToMaxRange | float    | Time in seconds to reach max range after casting the spell
    @param abortCondition | function | (optional) A function which returns true when the charge process should be stopped.
]]
function Spell:SetCharged(spellName, chargeDuration, maxRange, timeToMaxRange, abortCondition)

    assert(self.skillshotType, "Spell:SetCharged(): Only skillshots can be defined as charged spells!")
    assert(spellName and type(spellName) == "string" and chargeDuration and type(chargeDuration) == "number", "Spell:SetCharged(): Some or all arguments are invalid!")
    assert(self.__charged == nil, "Spell:SetCharged(): Already marked as charged spell!")

    self.__charged           = true
    self.__charged_aborted   = true
    self.__charged_spellName = spellName
    self.__charged_duration  = chargeDuration

    self.__charged_maxRange       = maxRange
    self.__charged_chargeTime     = timeToMaxRange
    self.__charged_abortCondition = abortCondition or function () return false end

    self.__charged_active   = false
    self.__charged_castTime = 0

    -- Register callbacks
    if not self.__tickCallback then
        AddTickCallback(function() self:OnTick() end)
        self.__tickCallback = true
    end

    if not self.__sendPacketCallback then
        AddSendPacketCallback(function(p) self:OnSendPacket(p) end)
        self.__sendPacketCallback = true
    end

    if not self.__processSpellCallback then
        AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
        self.__processSpellCallback = true
    end

    return self

end

--[[
    Returns whether the spell is currently charging or not

    @return | bool | Spell charging or not
]]
function Spell:IsCharging()
    return self.__charged_abortCondition() == false and self.__charged_active
end

--[[
    Charges the spell
]]
function Spell:Charge()

    assert(self.__charged, "Spell:Charge(): Spell is not defined as chargeable spell!")

    if not self:IsCharging() then
        CastSpell(self.spellId, mousePos.x, mousePos.z)
    end

end

-- Internal function, do not use!
function Spell:_AbortCharge()
    if self.__charged and self.__charged_active then
        self.__charged_aborted = true
        self.__charged_active  = false
        self:SetRange(self.__charged_initialRange)
    end
end

--[[
    Set the hitChance of the predicted target position when to cast

    @param hitChance | int   | New hitChance for predicted positions
    @rerurn          | class | The current instance
]]
function Spell:SetHitChance(hitChance)

    self.hitChance = hitChance or 2

    return self

end

--[[
    Checks if the given target is valid for the spell

    @param target | userdata | Target to be checked if valid
    @return       | bool     | Valid target or not
]]
function Spell:ValidTarget(target, range)

    return ValidTarget(target, range or self.range)

end

--[[
    Returns the prediction results from VPrediction/Prodiction in a VPrediction result layout

    @return | various data | Prediction result in VPrediction layout
]]
function Spell:GetPrediction(target)

    if self.skillshotType ~= nil then
        -- VPrediction
        if self.predictionType == 1 then
            if self.skillshotType == SKILLSHOT_LINEAR then
                if self.useAoe then
                    return self.VP:GetLineAOECastPosition(target, self.delay, self.radius, self.range, self.speed, self.sourcePosition)
                else
                    return self.VP:GetLineCastPosition(target, self.delay, self.width, self.range, self.speed, self.sourcePosition, self.collision)
                end
            elseif self.skillshotType == SKILLSHOT_CIRCULAR then
                if self.useAoe then
                    return self.VP:GetCircularAOECastPosition(target, self.delay, self.radius, self.range, self.speed, self.sourcePosition)
                else
                    return self.VP:GetCircularCastPosition(target, self.delay, self.width, self.range, self.speed, self.sourcePosition, self.collision)
                end
             elseif self.skillshotType == SKILLSHOT_CONE then
                if self.useAoe then
                    return self.VP:GetConeAOECastPosition(target, self.delay, self.radius, self.range, self.speed, self.sourcePosition)
                else
                    return self.VP:GetLineCastPosition(target, self.delay, self.width, self.range, self.speed, self.sourcePosition, self.collision)
                end
            end
        -- Prodiction
        elseif self.predictionType == 2 then
            if self.useAoe then
                if self.skillshotType == SKILLSHOT_LINEAR then
                    local pos, info, objects = Prodiction.GetLineAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    local hitChance = self.collision and info.collision() and -1 or info.hitchance
                    return pos, hitChance, #objects
                elseif self.skillshotType == SKILLSHOT_CIRCULAR then
                    local pos, info, objects = Prodiction.GetCircularAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    local hitChance = self.collision and info.collision() and -1 or info.hitchance
                    return pos, hitChance, #objects
                 elseif self.skillshotType == SKILLSHOT_CONE then
                    local pos, info, objects = Prodiction.GetConeAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    local hitChance = self.collision and info.collision() and -1 or info.hitchance
                    return pos, hitChance, #objects
                end
            else
                local pos, info = Prodiction.GetPrediction(target, self.range, self.speed, self.delay, self.width, self.sourcePosition)
                local hitChance = self.collision and info.collision() and -1 or info.hitchance
                return pos, hitChance, info.pos
            end

            -- Someday it will look the same as with VPrediction ;D
            --[[
            if self.skillshotType == SKILLSHOT_LINEAR then
                if self.useAoe then
                    local pos, info, objects = Prodiction.GetLineAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, type(objects) == "table" and #objects or 10
                else
                    local pos, info = Prodiction.GetPrediction(target, self.range, self.speed, self.delay, self.width, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, info.pos
                end
            elseif self.skillshotType == SKILLSHOT_CIRCULAR then
                if self.useAoe then
                    local pos, info, objects = Prodiction.GetCircularAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, type(objects) == "table" and #objects or 10
                else
                    local pos, info = Prodiction.GetPrediction(target, self.range, self.speed, self.delay, self.width, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, info.pos
                end
             elseif self.skillshotType == SKILLSHOT_CONE then
                if self.useAoe then
                    local pos, info, objects = Prodiction.GetConeAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, type(objects) == "table" and #objects or 10
                else
                    local pos, info = Prodiction.GetPrediction(target, self.range, self.speed, self.delay, self.width, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, info.pos
                end
            end
            ]]
        end
    end

end

--[[
    Tries to cast the spell when the target is dashing

    @param target | Cunit | Dashing target to attack
    @param return | int   | SpellState of the current spell
]]
function Spell:CastIfDashing(target)

    -- Don't calculate stuff when target is invalid
    if not ValidTarget(target) then return SPELLSTATE_INVALID_TARGET end

    if self.skillshotType ~= nil then
        local isDashing, canHit, position = self.VP:IsDashing(target, self.delay + 0.07 + GetLatency() / 2000, self.width, self.speed, self.sourcePosition)

        -- Out of range
        if self.rangeSqr < _GetDistanceSqr(self.sourceRange, position) then return SPELLSTATE_OUT_OF_RANGE end

        if isDashing and canHit then

            -- Collision
            if not self.collision or self.collision and not self.VP:CheckMinionCollision(target, position, self.delay + 0.07 + GetLatency() / 2000, self.width, self.range, self.speed, self.sourcePosition, false, true) then
                return self:__Cast(self.spellId, position.x, position.z)
            else
                return SPELLSTATE_COLLISION
            end

        elseif not isDashing then return SPELLSTATE_NOT_DASHING
        else return SPELLSTATE_DASHING_CANT_HIT end
    else
        local isDashing, canHit, position = self.VP:IsDashing(target, 0.25 + 0.07 + GetLatency() / 2000, 1, math.huge, self.sourcePosition)

        -- Out of range
        if self.rangeSqr < _GetDistanceSqr(self.sourceRange, position) then return SPELLSTATE_OUT_OF_RANGE end

        if isDashing and canHit then
            return self:__Cast(position.x, position.z)
        elseif not isDashing then return SPELLSTATE_NOT_DASHING
        else return SPELLSTATE_DASHING_CANT_HIT end
    end

    return SPELLSTATE_NOT_TRIGGERED

end

--[[
    Tries to cast the spell when the target is immobile

    @param target | Cunit | Immobile target to attack
    @param return | int   | SpellState of the current spell
]]
function Spell:CastIfImmobile(target)

    -- Don't calculate stuff when target is invalid
    if not ValidTarget(target) then return SPELLSTATE_INVALID_TARGET end

    if self.skillshotType ~= nil then
        local isImmobile, position = self.VP:IsImmobile(target, self.delay + 0.07 + GetLatency() / 2000, self.width, self.speed, self.sourcePosition)

        -- Out of range
        if self.rangeSqr < _GetDistanceSqr(self.sourceRange, position) then return SPELLSTATE_OUT_OF_RANGE end

        if isImmobile then

            -- Collision
            if not self.collision or (self.collision and not self.VP:CheckMinionCollision(target, position, self.delay + 0.07 + GetLatency() / 2000, self.width, self.range, self.speed, self.sourcePosition, false, true)) then
                return self:__Cast(position.x, position.z)
            else
                return SPELLSTATE_COLLISION
            end

        else return SPELLSTATE_NOT_IMMOBILE end
    else
        local isImmobile, position = self.VP:IsImmobile(target, 0.25 + 0.07 + GetLatency() / 2000, 1, math.huge, self.sourcePosition)

        -- Out of range
        if self.rangeSqr < _GetDistanceSqr(self.sourceRange, target) then return SPELLSTATE_OUT_OF_RANGE end

        if isImmobile then
            return self:__Cast(target)
        else
            return SPELLSTATE_NOT_IMMOBILE
        end
    end

    return SPELLSTATE_NOT_TRIGGERED

end

--[[
    Cast the spell, respecting previously made decisions about skillshots and AOE stuff

    @param param1 | userdata/float | When param2 is nil then this can be the target object, otherwise this is the X coordinate of the skillshot position
    @param param2 | float          | Z coordinate of the skillshot position
    @param return | int            | SpellState of the current spell
]]
function Spell:Cast(param1, param2)

    if self.skillshotType ~= nil and param1 ~= nil and param2 == nil then

        -- Don't calculate stuff when target is invalid
        if not ValidTarget(param1) then return SPELLSTATE_INVALID_TARGET end

        local castPosition, hitChance, position, nTargets
        if self.skillshotType == SKILLSHOT_LINEAR or self.skillshotType == SKILLSHOT_CONE then
            if self.useAoe then
                castPosition, hitChance, nTargets = self:GetPrediction(param1)
            else
                castPosition, hitChance, position = self:GetPrediction(param1)
                -- Out of range
                if self.rangeSqr < _GetDistanceSqr(self.sourceRange, position) then return SPELLSTATE_OUT_OF_RANGE end
            end
        elseif self.skillshotType == SKILLSHOT_CIRCULAR then
            if self.useAoe then
                castPosition, hitChance, nTargets = self:GetPrediction(param1)
            else
                castPosition, hitChance, position = self:GetPrediction(param1)
                -- Out of range
                if math.pow(self.range + self.width + self.VP:GetHitBox(param1), 2) < _GetDistanceSqr(self.sourceRange, position) then return SPELLSTATE_OUT_OF_RANGE end
            end
        end

        -- Validation (for Prodiction)
        if not castPosition then return SPELLSTATE_NOT_TRIGGERED end

        -- AOE not enough targets
        if nTargets and nTargets < self.minTargetsAoe then return SPELLSTATE_NOT_ENOUGH_TARGETS end

        -- Collision detected
        if hitChance == -1 then return SPELLSTATE_COLLISION end

        -- Hitchance too low
        if hitChance and hitChance < self.hitChance then return SPELLSTATE_LOWER_HITCHANCE end

        -- Out of range
        if self.rangeSqr < _GetDistanceSqr(self.sourceRange, castPosition) then return SPELLSTATE_OUT_OF_RANGE end

        param1 = castPosition.x
        param2 = castPosition.z
    end

    -- Cast charged spell
    if param1 ~= nil and param2 ~= nil and self.__charged and self:IsCharging() then
        --print("Sending xerath Q")
        local p = CLoLPacket(0xE6) 
        p:EncodeF(myHero.networkID)
        p:Encode1(0xEA)
        p:Encode1(0)
        p:EncodeF(param1)
        p:EncodeF(0)
        p:EncodeF(param2)
        SendPacket(p)
        return SPELLSTATE_TRIGGERED
    end

    -- Cast the spell
    return self:__Cast(param1, param2)

end

--[[
    Internal function, do not use this!
]]
function Spell:__Cast(param1, param2)

    if self.packetCast then
        if param1 ~= nil and param2 ~= nil then
            if type(param1) ~= "number" and type(param2) ~= "number" and VectorType(param1) and VectorType(param2) then
                Packet("S_CAST", {spellId = self.spellId, toX = param2.x, toY = param2.z, fromX = param1.x, fromY = param1.z}):send()
            else
                Packet("S_CAST", {spellId = self.spellId, toX = param1, toY = param2, fromX = param1, fromY = param2}):send()
            end
        elseif param1 ~= nil then
            Packet("S_CAST", {spellId = self.spellId, toX = param1.x, toY = param1.z, fromX = param1.x, fromY = param1.z, targetNetworkId = param1.networkID}):send()
        else
            Packet("S_CAST", {spellId = self.spellId, toX = player.x, toY = player.z, fromX = player.x, fromY = player.z, targetNetworkId = player.networkID}):send()
        end
    else
        if param1 ~= nil and param2 ~= nil then
            if type(param1) ~= "number" and type(param2) ~= "number" and VectorType(param1) and VectorType(param2) then
                Packet("S_CAST", {spellId = self.spellId, toX = param2.x, toY = param2.z, fromX = param1.x, fromY = param1.z}):send()
            else
                CastSpell(self.spellId, param1, param2)
            end
        elseif param1 ~= nil then
            CastSpell(self.spellId, param1)
        else
            CastSpell(self.spellId)
        end
    end

    return SPELLSTATE_TRIGGERED

end

--[[
    Add an automation to the spell to let it cast itself when a certain condition is met

    @param automationId | string/int | The ID of the automation, example "AntiGapCloser"
    @param func         | function   | Function to be called when checking, should return a bool value indicating if it should be casted and optionally the cast params (ex: target or x and z)
]]
function Spell:AddAutomation(automationId, func)

    assert(automationId, "Spell: automationId is invalid!")
    assert(func and type(func) == "function", "Spell: func is invalid!")

    for index, automation in ipairs(self._automations) do
        if automation.id == automationId then return end
    end

    table.insert(self._automations, { id == automationId, func = func })

    -- Register callbacks
    if not self.__tickCallback then
        AddTickCallback(function() self:OnTick() end)
        self.__tickCallback = true
    end

end

--[[
    Remove and automation by it's id

    @param automationId | string/int | The ID of the automation, example "AntiGapCloser"
]]
function Spell:RemoveAutomation(automationId)

    assert(automationId, "Spell: automationId is invalid!")

    for index, automation in ipairs(self._automations) do
        if automation.id == automationId then
            table.remove(self._automations, index)
            break
        end
    end

end

--[[
    Clear all automations assinged to this spell
]]
function Spell:ClearAutomations()
    self._automations = {}
end

--[[
    Track the spell like in OnProcessSpell to add more features to this Spell instance

    @param spellName | string/table | Case insensitive name(s) of the spell
    @return          | class        | The current instance
]]
function Spell:TrackCasting(spellName)

    assert(spellName, "Spell:TrackCasting(): spellName is invalid!")
    assert(self.__tracked_spellNames == nil, "Spell:TrackCasting(): This spell is already tracked!")
    assert(type(spellName) == "string" or type(spellName) == "table", "Spell:TrackCasting(): Type of spellName is invalid: " .. type(spellName))

    self.__tracked_spellNames = type(spellName) == "table" and spellName or { spellName }

    -- Register callbacks
    if not self.__processSpellCallback then
        AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
        self.__processSpellCallback = true
    end

    return self

end

--[[
    When the spell is casted and about to hit a target, this will return the following

    @return | CUnit,float | The target unit, the remaining time in seconds it will take to hit the target, otherwise nil
]]
function Spell:WillHitTarget()

    -- TODO: VPrediction expert's work ;D

end

--[[
    Register a function which will be triggered when the spell is being casted the function will be given the spell object as parameter

    @param func | function | Function to be called when the spell is being processed (casted)
]]
function Spell:RegisterCastCallback(func)

    assert(func and type(func) == "function" and self.__tracked_castCallback == nil, "Spell:RegisterCastCallback(): func is either invalid or a callback is already registered!")

    self.__tracked_castCallback = func

end

--[[
    Returns the os.clock() time when the spell was last casted

    @return | float | Time in seconds when the spell was last casted or nil if the spell was never casted or spell is not tracked
]]
function Spell:GetLastCastTime()
    return self.__tracked_lastCastTime or 0
end

--[[
    Get if the target is in range

    @return | bool | In range or not
]]
function Spell:IsInRange(target, from)
    return self.rangeSqr >= _GetDistanceSqr(target, from or self.sourcePosition)
end

--[[
    Get if the spell is ready or not

    @return | bool | Spell state ready or not
]]
function Spell:IsReady()
    return player:CanUseSpell(self.spellId) == READY
end

--[[
    Get the mana usage of the spell

    @return | float | Mana usage of the spell
]]
function Spell:GetManaUsage()
    return player:GetSpellData(self.spellId).mana
end

--[[
    Get the CURRENT cooldown of the spell

    @return | float | Current cooldown of the spell
]]
function Spell:GetCooldown(current)
    return current and player:GetSpellData(self.spellId).currentCd or player:GetSpellData(self.spellId).totalCooldown
end

--[[
    Get the stat points assinged to this spell (level)

    @return | int | Stat points assinged to this spell (level)
]]
function Spell:GetLevel()
    return player:GetSpellData(self.spellId).level
end

--[[
    Get the name of the spell

    @return | string | Name of the the spell
]]
function Spell:GetName()
    return player:GetSpellData(self.spellId).name
end

--[[
    Internal callback, don't use this!
]]
function Spell:OnTick()

    -- Automations
    if self._automations and #self._automations > 0 then
        for _, automation in ipairs(self._automations) do
            local doCast, param1, param2 = automation.func()
            if doCast == true then
                self:Cast(param1, param2)
            end
        end
    end

    -- Charged spells
    if self.__charged then
        if self:IsCharging() then
            self:SetRange(math.min(self.__charged_initialRange + (self.__charged_maxRange - self.__charged_initialRange) * ((os.clock() - self.__charged_castTime) / self.__charged_chargeTime), self.__charged_maxRange))
        elseif not self.__charged_aborted and os.clock() - self.__charged_castTime > 0.1 then
            self:_AbortCharge()
        end
    end

end

--[[
    Internal callback, don't use this!
]]
function Spell:OnProcessSpell(unit, spell)

    if unit and unit.valid and unit.isMe and spell and spell.name then

        -- Tracked spells
        if self.__tracked_spellNames then
            for _, trackedSpell in ipairs(self.__tracked_spellNames) do
                if trackedSpell:lower() == spell.name:lower() then
                    self.__tracked_lastCastTime = os.clock()
                    self.__tracked_castCallback(spell)
                end
            end
        end

        -- Charged spells
        if self.__charged and self.__charged_spellName:lower() == spell.name:lower() then
            self.__charged_active       = true
            self.__charged_aborted      = false
            self.__charged_initialRange = self.range
            self.__charged_castTime     = os.clock()
            self.__charged_count        = self.__charged_count and self.__charged_count + 1 or 1
            DelayAction(function(chargeCount)
                if self.__charged_count == chargeCount then
                    self:_AbortCharge()
                end
            end, self.__charged_duration, { self.__charged_count })
        end

    end

end

--[[
    Internal callback, don't use this!
]]
function Spell:OnSendPacket(p)

    -- Charged spells
    if self.__charged then
        if p.header == 0xE6 then
            if os.clock() - self.__charged_castTime <= 0.1 then
                p:Block()
            end
        elseif p.header == Packet.headers.S_CAST then
            local packet = Packet(p)
            if packet:get("spellId") == self.spellId then
                if os.clock() - self.__charged_castTime <= self.__charged_duration then
                    self:_AbortCharge()
                    local newPacket = CLoLPacket(0xE6)
                    newPacket:EncodeF(player.networkID)
                    newPacket:Encode1(0xE2)
                    newPacket:Encode1(0)
                    newPacket:EncodeF(mousePos.x)
                    newPacket:EncodeF(mousePos.y)
                    newPacket:EncodeF(mousePos.z)
                    SendPacket(newPacket)
                    p:Block()
                end
            end
        end
    end

end

function Spell:__eq(other)

    return other and other._spellNum and other._spellNum == self._spellNum or false

end


--[[

'||''|.                               '||    ||'                                                  
 ||   ||  ... ..   ....   ... ... ...  |||  |||   ....   .. ...    ....     ... .   ....  ... ..  
 ||    ||  ||' '' '' .||   ||  ||  |   |'|..'||  '' .||   ||  ||  '' .||   || ||  .|...||  ||' '' 
 ||    ||  ||     .|' ||    ||| |||    | '|' ||  .|' ||   ||  ||  .|' ||    |''   ||       ||     
.||...|'  .||.    '|..'|'    |   |    .|. | .||. '|..'|' .||. ||. '|..'|'  '||||.  '|...' .||.    
                                                                          .|....'                 

    DrawManager - Tired of having to draw everything over and over again? Then use this!

    Functions:
        DrawManager()

    Methods:
        DrawManager:AddCircle(circle)
        DrawManager:RemoveCircle(circle)
        DrawManager:CreateCircle(position, radius, width, color)
        DrawManager:OnDraw()

]]
class 'DrawManager'

--[[
    New instance of DrawManager
]]
function DrawManager:__init()

    self.objects = {}

    AddDrawCallback(function() self:OnDraw() end)

end

--[[
    Add an existing circle to the draw manager

    @param circle | class | _Circle instance
]]
function DrawManager:AddCircle(circle)

    assert(circle, "DrawManager: circle is invalid!")

    for _, object in ipairs(self.objects) do
        assert(object ~= circle, "DrawManager: object was already in DrawManager")
    end

    table.insert(self.objects, circle)

end

--[[
    Removes a circle from the draw manager

    @param circle | class | _Circle instance
]]
function DrawManager:RemoveCircle(circle)

    assert(circle, "DrawManager:RemoveCircle(): circle is invalid!")

    for index, object in ipairs(self.objects) do
        if object == circle then
            table.remove(self.objects, index)
        end
    end

end

--[[
    Create a new circle and add it aswell to the DrawManager instance

    @param position | vector | Center of the circle
    @param radius   | float  | Radius of the circle
    @param width    | int    | Width of the circle outline
    @param color    | table  | Color of the circle in a tale format { a, r, g, b }
    @return         | class  | Instance of the newly create Circle class
]]
function DrawManager:CreateCircle(position, radius, width, color)

    local circle = _Circle(position, radius, width, color)
    self:AddCircle(circle)
    return circle

end

--[[
    DO NOT CALL THIS MANUALLY! This will be called automatically.
]]
function DrawManager:OnDraw()

    for _, object in ipairs(self.objects) do
        if object.enabled then
            object:Draw()
        end
    end

end

--[[

                  ..|'''.|  ||                  '||          
                .|'     '  ...  ... ..    ....   ||    ....  
                ||          ||   ||' '' .|   ''  ||  .|...|| 
                '|.      .  ||   ||     ||       ||  ||      
                 ''|....'  .||. .||.     '|...' .||.  '|...' 

    Functions:
        _Circle(position, radius, width, color)

    Members:
        _Circle.enabled  | bool   | Enable or diable the circle (displayed)
        _Circle.mode     | int    | See circle modes below
        _Circle.position | vector | Center of the circle
        _Circle.radius   | float  | Radius of the circle
        -- These are not changeable when a menu is set
        _Circle.width    | int    | Width of the circle outline
        _Circle.color    | table  | Color of the circle in a tale format { a, r, g, b }
        _Circle.quality  | float  | Quality of the circle, the higher the smoother the circle

    Methods:
        _Circle:AddToMenu(menu, paramText, addColor, addWidth, addQuality)
        _Circle:SetEnabled(enabled)
        _Circle:Set2D()
        _Circle:Set3D()
        _Circle:SetMinimap()
        _Circle:SetQuality(qualtiy)
        _Circle:SetDrawCondition(condition)
        _Circle:LinkWithSpell(spell, drawWhenReady)
        _Circle:Draw()

]]
class '_Circle'

-- Circle modes
CIRCLE_2D      = 0
CIRCLE_3D      = 1
CIRCLE_MINIMAP = 2

-- Number of currently created circles
local circleCount = 1

--[[
    New instance of Circle

    @param position | vector | Center of the circle
    @param radius   | float  | Radius of the circle
    @param width    | int    | Width of the circle outline
    @param color    | table  | Color of the circle in a tale format { a, r, g, b }
]]
function _Circle:__init(position, radius, width, color)

    assert(position and position.x and (position.y and position.z or position.y), "_Circle: position is invalid!")
    assert(radius and type(radius) == "number", "_Circle: radius is invalid!")
    assert(not color or color and type(color) == "table" and #color == 4, "_Circle: color is invalid!")

    self.enabled   = true
    self.condition = nil

    self.menu        = nil
    self.menuEnabled = nil
    self.menuColor   = nil
    self.menuWidth   = nil
    self.menuQuality = nil

    self.mode = CIRCLE_3D

    self.position = position
    self.radius   = radius
    self.width    = width or 1
    self.color    = color or { 255, 255, 255, 255 }
    self.quality  = radius / 5

    self._circleId  = "circle" .. circleCount
    self._circleNum = circleCount

    circleCount = circleCount + 1

end

--[[
    Adds this circle to a given menu

    @param menu       | scriptConfig | Instance of script config to add this circle to
    @param paramText  | string       | Text for the menu entry
    @param addColor   | bool         | Add color option
    @param addWidth   | bool         | Add width option
    @param addQuality | bool         | Add quality option
    @return           | class        | The current instance
]]
function _Circle:AddToMenu(menu, paramText, addColor, addWidth, addQuality)

    assert(menu, "_Circle: menu is invalid!")
    assert(self.menu == nil, "_Circle: Already bound to a menu!")

    menu:addSubMenu(paramText or "Circle " .. self._circleNum, self._circleId)
    self.menu = menu[self._circleId]

    -- Enabled
    local paramId = self._circleId .. "enabled"
    self.menu:addParam(paramId, "Enabled", SCRIPT_PARAM_ONOFF, self.enabled)
    self.menuEnabled = self.menu._param[#self.menu._param]

    if addColor or addWidth or addQuality then

        -- Color
        if addColor then
            paramId = self._circleId .. "color"
            self.menu:addParam(paramId, "Color", SCRIPT_PARAM_COLOR, self.color)
            self.menuColor = self.menu._param[#self.menu._param]
        end

        -- Width
        if addWidth then
            paramId = self._circleId .. "width"
            self.menu:addParam(paramId, "Width", SCRIPT_PARAM_SLICE, self.width, 1, 5)
            self.menuWidth = self.menu._param[#self.menu._param]
        end

        -- Quality
        if addQuality then
            paramId = self._circleId .. "quality"
            self.menu:addParam(paramId, "Quality", SCRIPT_PARAM_SLICE, math.round(self.quality), 10, math.round(self.radius / 5))
            self.menuQuality = self.menu._param[#self.menu._param]
        end

    end

    return self

end

--[[
    Set the enable status of the circle

    @param enabled | bool  | Enable state of this circle
    @return        | class | The current instance
]]
function _Circle:SetEnabled(enabled)

    self.enabled = enabled
    return self

end

--[[
    Set this circle to be displayed 2D

    @return | class | The current instance
]]
function _Circle:Set2D()

    self.mode = CIRCLE_2D
    return self

end

--[[
    Set this circle to be displayed 3D

    @return | class | The current instance
]]
function _Circle:Set3D()

    self.mode = CIRCLE_3D
    return self

end

--[[
    Set this circle to be displayed on the minimap

    @return | class | The current instance
]]
function _Circle:SetMinimap()

    self.mode = CIRCLE_MINIMAP
    return self

end

--[[
    Set the display quality of this circle

    @return | class | The current instance
]]
function _Circle:SetQuality(qualtiy)

    assert(qualtiy and type(qualtiy) == "number", "_Circle: quality is invalid!")
    self.quality = quality
    return self

end

--[[
    Set the draw condition of this circle

    @return | class | The current instance
]]
function _Circle:SetDrawCondition(condition)

    assert(condition and type(condition) == "function", "_Circle: condition is invalid!")
    self.condition = condition
    return self

end

--[[
    Links the spell range with the circle radius

    @param spell         | class | Instance of Spell class
    @param drawWhenReady | bool  | Decides whether to draw the circle when the spell is ready or not
    @return              | class | The current instance
]]
function _Circle:LinkWithSpell(spell, drawWhenReady)

    assert(spell, "_Circle:LinkWithSpell(): spell is invalid")
    self._linkedSpell = spell
    self._linkedSpellReady = drawWhenReady or false
    return self

end

--[[
    Draw this circle, should only be called from OnDraw()
]]
function _Circle:Draw()

    -- Don't draw if condition is not met
    if self.condition ~= nil and self.condition() == false then return end

    -- Update values if linked spell is given
    if self._linkedSpell then
        -- Temporary error prevention
        if not self._linkedSpell.IsReady then
            if not _G.SourceLibLinkedSpellInformed then
                _G.SourceLibLinkedSpellInformed = true
                print("SourceLib: The script \"" .. GetCurrentEnv().FILE_NAME .. "\" is causing issues with circle drawing. Please contact he developer of the named script so he fixes the issue, thanks.")
            end
            return
        else
            if self._linkedSpellReady and not self._linkedSpell:IsReady() then return end
            -- Update the radius with the spell range
            self.radius = self._linkedSpell.range
        end
    end

    -- Menu found
    if self.menu then 
        if self.menuEnabled ~= nil then
            if not self.menu[self.menuEnabled.var] then return end
        end
        if self.menuColor ~= nil then
            self.color = self.menu[self.menuColor.var]
        end
        if self.menuWidth ~= nil then
            self.width = self.menu[self.menuWidth.var]
        end
        if self.menuQuality ~= nil then
            self.quality = self.menu[self.menuQuality.var]
        end
    end

    local center = WorldToScreen(D3DXVECTOR3(self.position.x, self.position.y, self.position.z))
    if not self:PointOnScreen(center.x, center.y) and self.mode ~= CIRCLE_MINIMAP then
        return
    end

    if self.mode == CIRCLE_2D then
        DrawCircle2D(self.position.x, self.position.y, self.radius, self.width, TARGB(self.color), self.quality)
    elseif self.mode == CIRCLE_3D then
        DrawCircle3D(self.position.x, self.position.y, self.position.z, self.radius, self.width, TARGB(self.color), self.quality)
    elseif self.mode == CIRCLE_MINIMAP then
        DrawCircleMinimap(self.position.x, self.position.y, self.position.z, self.radius, self.width, TARGB(self.color), self.quality)
    else
        print("Circle: Something is wrong with the circle.mode!")
    end

end

function _Circle:PointOnScreen(x, y)
    return x <= WINDOW_W and x >= 0 and y >= 0 and y <= WINDOW_H
end

function _Circle:__eq(other)
    return other._circleId and other._circleId == self._circleId or false
end

--[[

'||''|.                                              '||'       ||  '||      
 ||   ||   ....   .. .. ..    ....     ... .   ....   ||       ...   || ...  
 ||    || '' .||   || || ||  '' .||   || ||  .|...||  ||        ||   ||'  || 
 ||    || .|' ||   || || ||  .|' ||    |''   ||       ||        ||   ||    | 
.||...|'  '|..'|' .|| || ||. '|..'|'  '||||.  '|...' .||.....| .||.  '|...'  
                                     .|....'                                 

    DamageLib - Holy cow, so precise!

    Functions:
        DamageLib(source)

    Members:
        DamageLib.source | Cunit | Source unit for which the damage should be calculated

    Methods:
        DamageLib:RegisterDamageSource(spellId, damagetype, basedamage, perlevel, scalingtype, scalingstat, percentscaling, condition, extra)
        DamageLib:GetScalingDamage(target, scalingtype, scalingstat, percentscaling)
        DamageLib:GetTrueDamage(target, spell, damagetype, basedamage, perlevel, scalingtype, scalingstat, percentscaling, condition, extra)
        DamageLib:CalcSpellDamage(target, spell)
        DamageLib:CalcComboDamage(target, combo)
        DamageLib:IsKillable(target, combo)
        DamageLib:AddToMenu(menu, combo)

    -Available spells by default (not added yet):
        _AA: Returns the auto-attack damage.
        _IGNITE: Returns the ignite damage.
        _ITEMS: Returns the damage dealt by all the items actives.

    -Damage types:
        _MAGIC
        _PHYSICAL
        _TRUE

    -Scaling types: _AP, _AD, _BONUS_AD, _HEALTH, _ARMOR, _MR, _MAXHEALTH, _MAXMANA 
]]
class 'DamageLib'

--Damage types
_MAGIC, _PHYSICAL, _TRUE = 0, 1, 2

--Percentage scale type's 
_AP, _AD, _BONUS_AD, _HEALTH, _ARMOR, _MR, _MAXHEALTH, _MAXMANA = 1, 2, 3, 4, 5, 6, 7, 8

--Percentage scale functions
local _ScalingFunctions = {
    [_AP] = function(x, y) return x * y.source.ap end,
    [_AD] = function(x, y) return x * y.source.totalDamage end,
    [_BONUS_AD] = function(x, y) return x * y.source.addDamage end,
    [_ARMOR] = function(x, y) return x * y.source.armor end,
    [_MR] = function(x, y) return x * y.source.magicArmor end,
    [_MAXHEALTH] = function(x, y) return x * y.source.maxHeath end,
    [_MAXMANA] = function(x, y) return x * y.source.maxMana end,
}

--[[
    New instance of DamageLib

    @param source | Cunit | Source unit (attacker, player by default)
]]
function DamageLib:__init(source)

    self.sources = {}
    self.source = source or player

    --Damage multiplicators:
    self.Magic_damage_m    = 1
    self.Physical_damage_m = 1

    -- Most common damage sources
    self:RegisterDamageSource(_IGNITE, _TRUE, 0, 0, _TRUE, _AP, 0, function() return _IGNITE and (self.source:CanUseSpell(_IGNITE) == READY) end, function() return (50 + 20 * self.source.level) end)
    self:RegisterDamageSource(ItemManager:GetItem("DFG"):GetId(), _MAGIC, 0, 0, _MAGIC, _AP, 0, function() return ItemManager:GetItem("DFG"):GetSlot() and (self.source:CanUseSpell(ItemManager:GetItem("DFG"):GetSlot()) == READY) end, function(target) return 0.15 * target.maxHealth end)
    self:RegisterDamageSource(ItemManager:GetItem("BOTRK"):GetId(), _MAGIC, 0, 0, _MAGIC, _AP, 0, function() return ItemManager:GetItem("BOTRK"):GetSlot() and (self.source:CanUseSpell(ItemManager:GetItem("BOTRK"):GetSlot()) == READY) end, function(target) return 0.15 * target.maxHealth end)
    self:RegisterDamageSource(_AA, _PHYSICAL, 0, 0, _PHYSICAL, _AD, 1)

end

--[[
    Register a new spell

    @param spellId        | int      | (unique) Spell id to add.
    
    @param damagetype     | int      | The type(s) of the base and perlevel damage (_MAGIC, _PHYSICAL, _TRUE).
    @param basedamage     | int      | Base damage(s) of the spell.
    @param perlevel       | int      | Damage(s) scaling per level.

    @param scalingtype    | int      | Type(s) of the percentage scale (_MAGIC, _PHYSICAL, _TRUE).
    @param scalingstat    | int      | Stat(s) that the damage scales with.
    @param percentscaling | int      | Percentage(s) the stat scales with.

    @param condition      | function | (optional) A function that returns true / false depending if the damage will be taken into account or not, the target is passed as param.
    @param extra          | function | (optional) A function returning extra damage, the target is passed as param.
    
    -Example Spells: 
    Teemo Q:  80 / 125 / 170 / 215 / 260 (+ 80% AP) (MAGIC)
    DamageLib:RegisterDamageSource(_Q, _MAGIC, 35, 45, _MAGIC, _AP, 0.8, function() return (player:CanUseSpell(_Q) == READY) end)

    Akalis E: 30 / 55 / 80 / 105 / 130 (+ 30% AP) (+ 60% AD) (PHYSICAL) 
    DamageLib:RegisterDamageSource(_E, _PHYSICAL, 5, 25, {_PHYSICAL,_PHYSICAL}, {_AP, _AD}, {0.3, 0.6}, function() return (player:GetSpellData(_Q).currentCd < 2) or (player:CanUseSpell(_Q) == READY) end)

    * damagetype, basedamage, perlevel and scalingtype, scalingstat, percentscaling can be tables if there are 2 or more damage types.
]]
function DamageLib:RegisterDamageSource(spellId, damagetype, basedamage, perlevel, scalingtype, scalingstat, percentscaling, condition, extra)

    condition = condition or function() return true end
    if spellId then
        self.sources[spellId] = {damagetype = damagetype, basedamage = basedamage, perlevel = perlevel, condition = condition, extra = extra, scalingtype = scalingtype, percentscaling = percentscaling, scalingstat = scalingstat}
    end

end

function DamageLib:GetScalingDamage(target, scalingtype, scalingstat, percentscaling)

    local amount = (_ScalingFunctions[scalingstat] or function() return 0 end)(percentscaling, self)

    if scalingtype == _MAGIC then
        return self.Magic_damage_m * self.source:CalcMagicDamage(target, amount)
    elseif scalingtype == _PHYSICAL then
        return self.Physical_damage_m * self.Physical_damage_m * self.source:CalcDamage(target, amount)
    elseif scalingtype == _TRUE then
        return amount
    end

    return 0

end

function DamageLib:GetTrueDamage(target, spell, damagetype, basedamage, perlevel, scalingtype, scalingstat, percentscaling, condition, extra)

    basedamage = basedamage or 0
    perlevel = perlevel or 0
    condition = condition(target)
    scalingtype = scalingtype or 0
    scalingstat = scalingstat or _AP
    percentscaling = percentscaling or 0
    extra = extra or function() return 0 end
    local ScalingDamage = 0

    if not condition then return 0 end

    if type(scalingtype) == "number" then
        ScalingDamage = ScalingDamage + self:GetScalingDamage(target, scalingtype, scalingstat, percentscaling)
    elseif type(scalingtype) == "table" then
        for i, v in ipairs(scalingtype) do
            ScalingDamage = ScalingDamage + self:GetScalingDamage(target, scalingtype[i], scalingstat[i], percentscaling[i])
        end
    end

    if damagetype == _MAGIC then
        return self.Magic_damage_m * self.source:CalcMagicDamage(target, basedamage + perlevel * (spell < 4 and self.source:GetSpellData(spell).level or 0) + extra(target)) + ScalingDamage
    end
    if damagetype == _PHYSICAL then
        return self.Physical_damage_m * self.source:CalcDamage(target, basedamage + perlevel * (spell < 4 and self.source:GetSpellData(spell).level or 0) + extra(target)) + ScalingDamage
    end
    if damagetype == _TRUE then
        return basedamage + perlevel * (spell < 4 and self.source:GetSpellData(spell).level or 0) + extra(target) + ScalingDamage
    end

    return 0

end

function DamageLib:CalcSpellDamage(target, spell)

    if not spell then return 0 end
    local spelldata = self.sources[spell]
    local result = 0
    assert(spelldata, "DamageLib: The spell has to be added first!")

    local _type = type(spelldata.damagetype)

    if _type == "number" then
        result = self:GetTrueDamage(target, spell, spelldata.damagetype, spelldata.basedamage, spelldata.perlevel, spelldata.scalingtype, spelldata.scalingstat, spelldata.percentscaling, spelldata.condition, spelldata.extra)
    elseif _type == "table" then
        for i = 1, #spelldata.damagetype, 1 do                 
            result = result + self:GetTrueDamage(target, spell, spelldata.damagetype[i], spelldata.basedamage[i], spelldata.perlevel[i], 0, 0, 0, spelldata.condition)
        end
        result = result + self:GetTrueDamage(target, spell, 0, 0, 0, spelldata.scalingtype, spelldata.scalingstat, spelldata.percentscaling, spelldata.condition, spelldata.extra)
    end

    return result

end

function DamageLib:CalcComboDamage(target, combo)

    local totaldamage = 0

    for i, spell in ipairs(combo) do
        if spell == ItemManager:GetItem("DFG"):GetId() and ItemManager:GetItem("DFG"):IsReady() then
            self.Magic_damage_m = 1.2
        end
    end

    for i, spell in ipairs(combo) do
        totaldamage = totaldamage + self:CalcSpellDamage(target, spell)
    end

    self.Magic_damage_m = 1

    return totaldamage

end

--[[
    Returns if the unit will die after taking the combo damage.

    @param target | Cunit | Target.
    @param combo  | table | The combo table.
]]
function DamageLib:IsKillable(target, combo)
    return target.health <= self:CalcComboDamage(target, combo)
end

--[[
    Adds the Health bar indicators to the menu.

    @param menu  | scriptConfig | AllClass menu or submenu instance.
    @param combo | table        | The combo table.
]]
function DamageLib:AddToMenu(menu, combo)

    self.menu = menu
    self.combo = combo
    self.ticklimit = 5 --5 ticks per seccond
    self.barwidth = 100
    self.cachedDamage = {}
    menu:addParam("DrawPredictedHealth", "Draw damage after combo.", SCRIPT_PARAM_ONOFF , true)
    self.enabled = menu.DrawPredictedHealth
    AddTickCallback(function() self:OnTick() end)
    AddDrawCallback(function() self:OnDraw() end)

end

function DamageLib:OnTick()

    if not self.menu["DrawPredictedHealth"] then return end
    self.lasttick = self.lasttick or 0
    if os.clock() - self.lasttick > 1 / self.ticklimit then
        self.lasttick = os.clock()
        for i, enemy in ipairs(GetEnemyHeroes()) do
            if ValidTarget(enemy) then
                self.cachedDamage[enemy.hash] = self:CalcComboDamage(enemy, self.combo)
            end
        end
    end

end

function DamageLib:OnDraw()

    if not self.menu["DrawPredictedHealth"] then return end
    for i, enemy in ipairs(GetEnemyHeroes()) do
        if ValidTarget(enemy) then
            self:DrawIndicator(enemy)
        end
    end

end

function DamageLib:DrawIndicator(enemy)

    local damage = self.cachedDamage[enemy.hash] or 0
    local SPos, EPos = GetEnemyHPBarPos(enemy)

    -- Validate data
    if not SPos then return end

    local barwidth = EPos.x - SPos.x
    local Position = SPos.x + math.max(0, (enemy.health - damage) / enemy.maxHealth) * barwidth

    DrawText("|", 16, math.floor(Position), math.floor(SPos.y + 8), ARGB(255,0,255,0))
    DrawText("HP: "..math.floor(enemy.health - damage), 13, math.floor(SPos.x), math.floor(SPos.y), (enemy.health - damage) > 0 and ARGB(255, 0, 255, 0) or  ARGB(255, 255, 0, 0))

end


--[[

 .|'''.|  |''||''|  .|'''.|  
 ||..  '     ||     ||..  '  
  ''|||.     ||      ''|||.  
.     '||    ||    .     '|| 
|'....|'    .||.   |'....|'  

    Simple Target Selector (STS) - Why using the regular one when you can have it even more simple.

]]
class 'SimpleTS'

function STS_GET_PRIORITY(target)
    if not STS_MENU or not STS_MENU.STS[target.hash] then
        return 1
    else
        return STS_MENU.STS[target.hash]
    end
end

STS_MENU = nil
STS_NEARMOUSE                     = {id = 1, name = "Near mouse", sortfunc = function(a, b) return _GetDistanceSqr(mousePos, a) < _GetDistanceSqr(mousePos, b) end}
STS_LESS_CAST_MAGIC               = {id = 2, name = "Less cast (magic)", sortfunc = function(a, b) return (player:CalcMagicDamage(a, 100) / a.health) > (player:CalcMagicDamage(b, 100) / b.health) end}
STS_LESS_CAST_PHYSICAL            = {id = 3, name = "Less cast (physical)", sortfunc = function(a, b) return (player:CalcDamage(a, 100) / a.health) > (player:CalcDamage(b, 100) / b.health) end}
STS_PRIORITY_LESS_CAST_MAGIC      = {id = 4, name = "Less cast priority (magic)", sortfunc = function(a, b) return STS_GET_PRIORITY(a) * (player:CalcMagicDamage(a, 100) / a.health) > STS_GET_PRIORITY(b) * (player:CalcMagicDamage(b, 100) / b.health) end}
STS_PRIORITY_LESS_CAST_PHYSICAL   = {id = 5, name = "Less cast priority (physical)", sortfunc = function(a, b) return STS_GET_PRIORITY(a) * (player:CalcDamage(a, 100) / a.health) > STS_GET_PRIORITY(b) * (player:CalcDamage(b, 100) / b.health) end}
STS_AVAILABLE_MODES = {STS_NEARMOUSE, STS_LESS_CAST_MAGIC, STS_LESS_CAST_PHYSICAL, STS_PRIORITY_LESS_CAST_MAGIC, STS_PRIORITY_LESS_CAST_PHYSICAL}

function SimpleTS:__init(mode)
    self.mode = mode and mode or STS_LESS_CAST_PHYSICAL
    AddDrawCallback(function() self:OnDraw() end)
    AddMsgCallback(function(msg, key) self:OnMsg(msg, key) end)
end

function SimpleTS:IsValid(target, range, selected)
    if ValidTarget(target) and (_GetDistanceSqr(target) <= range or (self.hitboxmode and (_GetDistanceSqr(target) <= (math.sqrt(range) + self.VP:GetHitBox(myHero) + self.VP:GetHitBox(target)) ^ 2))) then
        if selected or (not (HasBuff(target, "UndyingRage") and (target.health == 1)) and not HasBuff(target, "JudicatorIntervention")) then
            return true
        end
    end
end

function SimpleTS:AddToMenu(menu)
    self.menu = menu
    self.menu:addSubMenu("Target Priority", "STS")
    for i, target in ipairs(GetEnemyHeroes()) do
            self.menu.STS:addParam(target.hash, target.charName, SCRIPT_PARAM_SLICE, 1, 1, 5, 0)
    end
    self.menu.STS:addParam("Info", "Info", SCRIPT_PARAM_INFO, "5 Highest priority")

    local modelist = {}
    for i, mode in ipairs(STS_AVAILABLE_MODES) do
        table.insert(modelist, mode.name)
    end

    self.menu:addParam("mode", "Targetting mode: ", SCRIPT_PARAM_LIST, 1, modelist)
    self.menu["mode"] = self.mode.id

    self.menu:addParam("Selected", "Focus selected target", SCRIPT_PARAM_ONOFF, true)

    STS_MENU = self.menu
end

function SimpleTS:OnMsg(msg, key)
    if msg == WM_LBUTTONDOWN then
        local MinimumDistance = math.huge
        local SelectedTarget
        for i, enemy in ipairs(GetEnemyHeroes()) do
            if ValidTarget(enemy) then
                if _GetDistanceSqr(enemy, mousePos) <= MinimumDistance then
                    MinimumDistance = _GetDistanceSqr(enemy, mousePos)
                    SelectedTarget = enemy
                end
            end
        end
        if SelectedTarget and MinimumDistance < 150 * 150 then
            self.STarget = SelectedTarget
        else
            self.STarget = nil
        end
    end
end

function SimpleTS:SelectedTarget()
    return self.STarget
end

function SimpleTS:GetTarget(range, n, forcemode)
    assert(range, "SimpleTS: range can't be nil")
    range = range * range
    local PosibleTargets = {}
    local selected = self:SelectedTarget()

    if self.menu then
        self.mode = STS_AVAILABLE_MODES[self.menu.mode]
        if self.menu.Selected and selected and selected.type == player.type and self:IsValid(selected, range, true) then
            return selected
        end
    end

    for i, enemy in ipairs(GetEnemyHeroes()) do
        if self:IsValid(enemy, range) then
            table.insert(PosibleTargets, enemy)
        end
    end
    table.sort(PosibleTargets, forcemode and forcemode.sortfunc or self.mode.sortfunc)

    return PosibleTargets[n and n or 1]
end

function SimpleTS:OnDraw()
    local selected = self:SelectedTarget()
    if self.menu and self.menu.Selected and ValidTarget(selected) then
        DrawCircle3D(selected.x, selected.y, selected.z, 100, 2, ARGB(175, 0, 255, 0), 25)
    end
end


--[[

'||'   .                      '||    ||'                                                  
 ||  .||.    ....  .. .. ..    |||  |||   ....   .. ...    ....     ... .   ....  ... ..  
 ||   ||   .|...||  || || ||   |'|..'||  '' .||   ||  ||  '' .||   || ||  .|...||  ||' '' 
 ||   ||   ||       || || ||   | '|' ||  .|' ||   ||  ||  .|' ||    |''   ||       ||     
.||.  '|.'  '|...' .|| || ||. .|. | .||. '|..'|' .||. ||. '|..'|'  '||||.  '|...' .||.    
                                                                  .|....'                 

    ItemManager - Better handle them properly

    Functions:
        _ItemManager()

    Methods:
        _ItemManager:CastOffensiveItems(target)
        _ItemManager:GetItem(name)

]]
class "_ItemManager"

function _ItemManager:__init()
    self.items = {
            ["DFG"] = {id = 3128, range = 650, cancastonenemy = true},
            ["BOTRK"] = {id = 3153, range = 450, cancastonenemy = true}
        }

    self.requesteditems = {}
end

--[[
    Casts all known offensive items on the given target

    @param target | CUnit | Target unit
]]
function _ItemManager:CastOffensiveItems(target)

    for name, itemdata in pairs(self.items) do
        local item = self:GetItem(name)
        if item:InRange(target) then
            item:Cast(target)
        end
    end

end

--[[
    Gets the items by name.

    @param name   | string | Name of the item (not the ingame name, the name used when registering, like DFG)
    @param return | class  | Instance of the item that was requested or nil if not found
]]
function _ItemManager:GetItem(name)
    assert(name and self.items[name], "ItemManager: Item not found")
    if not self.requesteditems[name] then
        self.requesteditems[name] = Item(self.items[name].id, self.items[name].range)
    end
    return self.requesteditems[name]
end

-- Make a global ItemManager instance. This means you don't need to make an instance for yourself.
ItemManager = _ItemManager()


--[[

'||'   .                      
 ||  .||.    ....  .. .. ..   
 ||   ||   .|...||  || || ||  
 ||   ||   ||       || || ||  
.||.  '|.'  '|...' .|| || ||. 

    Item - Best used in ItemManager

    Functions:
        Item(id, range)

    Methods:
        Item:GetId()
        Item:GetRange(sqr)
        Item:GetSlot()
        Item:UpdateSlot()
        Item:IsReady()
        Item:InRange(target)
        Item:Cast(param1, param2)

]]
class "Item"

--[[
    Create a new instance of Item

    @param id    | integer | Item id 
    @param range | float   | (optional) Range of the item
]]
function Item:__init(id, range)

    assert(id and type(id) == "number", "Item: id is invalid!")
    assert(not range or range and type(range) == "number", "Item: range is invalid!")

    self.id = id
    self.range = range
    self.rangeSqr = range and range * range
    self.slot = GetInventorySlotItem(id)

end

--[[
    Returns the id of the item

    @return | integer | Item id
]]
function Item:GetId()
    return self.id
end

--[[
    Returns the range of the item, only working when the item was defined with a range.

    @param sqr | boolean | Range squared or not
    @return    | float   | Range of the item
]]
function Item:GetRange(sqr)
    return sqr and self.rangeSqr or self.range
end

--[[
    Return the slot the item is in

    @return | integer | Slot it
]]
function Item:GetSlot()
    self:UpdateSlot()
    return self.slot
end

--[[
    Updates the item slot to the current one (if changed)
]]
function Item:UpdateSlot()
    self.slot = GetInventorySlotItem(self.id)
end

--[[
    Returns if the item is ready to be casted (only working when it's an active item)

    @return | boolean | State of the item
]]
function Item:IsReady()
    self:UpdateSlot()
    return self.slot and (player:CanUseSpell(self.slot) == READY)
end

--[[
    Returns if the item (actually player) is in range of the target

    @param target | CUnit   | Target unit
    @return       | boolean | In range or not
]]
function Item:InRange(target)
    return _GetDistanceSqr(target) <= self.rangeSqr
end

--[[
    Casts the item

    @param param1 | CUnit/float | Either the target unit itself or as part of the position the X coordinate
    @param param2 | float       | (only use when param1 is given) The Z coordinate
    @return       | integer     | The spell state
]]
function Item:Cast(param1, param2)

    self:UpdateSlot()
    if self.slot then
        if param1 ~= nil and param2 ~= nil then
            CastSpell(self.slot, param1, param2)
        elseif param1 ~= nil then
            CastSpell(self.slot, param1)
        else
            CastSpell(self.slot)
        end
        return SPELLSTATE_TRIGGERED
    end

end


--[[

'||    ||'                           '|| '||'  '|'                                                   
 |||  |||    ....  .. ...   ... ...   '|. '|.  .'  ... ..   ....   ... ...  ... ...    ....  ... ..  
 |'|..'||  .|...||  ||  ||   ||  ||    ||  ||  |    ||' '' '' .||   ||'  ||  ||'  || .|...||  ||' '' 
 | '|' ||  ||       ||  ||   ||  ||     ||| |||     ||     .|' ||   ||    |  ||    | ||       ||     
.|. | .||.  '|...' .||. ||.  '|..'|.     |   |     .||.    '|..'|'  ||...'   ||...'   '|...' .||.    
                                                                    ||       ||                      
                                                                   ''''     ''''                     

    MenuWrapper - Keep it simple!

    Introduction:
        If you want to use the MenuWrapper you must create your menu with it! You cannot add this class to
        an existing menu. Once you have created a new instance, make sure you remember the follwing:
            - Target selector sub-menu name: ts
            - Orbwalker sub-menu name:       orbwalker
            - Drawings sub-menu name:        drawings
        If you want to use these sub menus, simply use something like this:
            MenuWrapper:GetHandle().drawings:addParam("info", "This has been created using MenuWrapper!", SCRIPT_PARAM_INFO, "")
        This means you can get the scriptConfig instance of the wrapped menu by using this:
            local myMenu = MenuWrapper:GetHandle()

    Functions:
        MenuWrapper(menuName, menuId)

    Methods:
        MenuWrapper:SetTargetSelector(targetSelector)
        MenuWrapper:SetOrbwalker(orbwalker)
        MenuWrapper:AddCircle(circle, addColor, addWidth, addQuality)
        MenuWrapper:AddCircles(circleTable, addColor, addWidth, addQuality)
        MenuWrapper:GetHandle()

]]
class 'MenuWrapper'

--[[
    Create a new MenuWrapper instance

    @param menuName | string | Display name of the menu
    @param menuId   | string | (optional) ID of the menu (for saving purposes)
]]
function MenuWrapper:__init(menuName, menuId)

    assert(menuName and type(menuName) == "string", "MenuWrapper: menuName is invalid!")

    self.__menu = scriptConfig(menuName, menuId or menuName)

end

--[[
    Adds a SimpleTS instance to the menu.

    @param targetSelector | class | SimpleTS instance
    @return               | class | scriptConfig target selector sub-menu
]]
function MenuWrapper:SetTargetSelector(targetSelector)

    assert(targetSelector, "MenuWrapper:SetTargetSelector(): targetSelector is not a valid SimpleTS instance!")
    assert(self.__targetSelector == nil, "MenuWrapper:SetTargetSelector(): targetSelector was already set!")

    self.__targetSelector = targetSelector
    self.__menu:addSubMenu("Target Selector", "ts")
    self.__targetSelector:AddToMenu(self.__menu.ts)

    return self.__menu.ts

end

--[[
    Adds a SOW instance to the menu

    @param orbwalker | class | SOW instance
    @return          | class | scritpConfig orbwalker sub-menu
]]
function MenuWrapper:SetOrbwalker(orbwalker)

    assert(orbwalker, "MenuWrapper:SetOrbwalker(): orbwalker is not a valid SOW instance!")
    assert(self.__orbwalker == nil, "MenuWrapper:SetOrbwalker(): orwalker was already set!")

    self.__orbwalker = orbwalker
    self.__menu:addSubMenu("Orbwalker", "orbwalker")
    self.__orbwalker:LoadToMenu(self.__menu.orbwalker)

    return self.__menu.orbwalker

end

--[[
    Adds a circle to the drawings sub-menu

    @param circle      | class | _Circle instance
    @param addColor    | bool  | (optional) Add color option
    @param addWidth    | bool  | (optional) Add width option
    @param addQuality  | bool  | (optional) Add quality option
    @return            | class | scriptConfig drawings sub-menu
]]
function MenuWrapper:AddCircle(circle, name, addColor, addWidth, addQuality)
    return self:AddCircles({ [1] = { circle = circle, name = name } }, addColor, addWidth, addQuality)
end

--[[
    Adds a table of circles to the drawings sub-menu

    @param circleTable | table | Table containing _Circle instances
    @param addColor    | bool  | (optional) Add color option
    @param addWidth    | bool  | (optional) Add width option
    @param addQuality  | bool  | (optional) Add quality option
    @return            | class | scriptConfig drawings sub-menu
]]
function MenuWrapper:AddCircles(circleTable, addColor, addWidth, addQuality)

    assert(circleTable and type(circleTable) == "table", "MenuWrapper:AddCircles(): circleTable is not a valid table!")

    for _, entry in ipairs(circleTable) do

        assert(entry.circle, "MenuWrapper:AddCircles(): circle is not a valid _Circle instance!")
        assert(entry.name, "MenuWarpper:AddCircles(): circle name was not given!")
        assert(self.__circles == nil or not table.contains(self.__circles, entry.circle), "MenuWrapper:AddCircles(): The circle was already added!")

        if not self.__circles then
            self.__circles = {}
        end

        if not self.__drawing then
            self.__menu:addSubMenu("Drawings", "drawings")
            self.__drawing = self.__menu.drawings
        end

        entry.circle:AddToMenu(self.__drawing, entry.name, addColor, addWidth, addQuality)

        table.insert(self.__circles, entry.circle)

    end

    return self.__drawing

end

--[[
    Returns the wrapped scriptConfig

    @return | class | scriptConfig instance
]]
function MenuWrapper:GetHandle()
    return self.__menu
end


--[[

'||'            .                                               .                   
 ||  .. ...   .||.    ....  ... ..  ... ..  ... ...  ... ...  .||.    ....  ... ..  
 ||   ||  ||   ||   .|...||  ||' ''  ||' ''  ||  ||   ||'  ||  ||   .|...||  ||' '' 
 ||   ||  ||   ||   ||       ||      ||      ||  ||   ||    |  ||   ||       ||     
.||. .||. ||.  '|.'  '|...' .||.    .||.     '|..'|.  ||...'   '|.'  '|...' .||.    
                                                      ||                            
                                                     ''''                           

    Interrupter - They will never cast!

    Like alwasy undocumented by honda...
]]
class 'Interrupter'

local _INTERRUPTIBLE_SPELLS = {
    ["KatarinaR"]                          = { charName = "Katarina",     DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["Meditate"]                           = { charName = "MasterYi",     DangerLevel = 1, MaxDuration = 2.5, CanMove = false },
    ["Drain"]                              = { charName = "FiddleSticks", DangerLevel = 3, MaxDuration = 2.5, CanMove = false },
    ["Crowstorm"]                          = { charName = "FiddleSticks", DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["GalioIdolOfDurand"]                  = { charName = "Galio",        DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["MissFortuneBulletTime"]              = { charName = "MissFortune",  DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["VelkozR"]                            = { charName = "Velkoz",       DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["InfiniteDuress"]                     = { charName = "Warwick",      DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["AbsoluteZero"]                       = { charName = "Nunu",         DangerLevel = 4, MaxDuration = 2.5, CanMove = false },
    ["ShenStandUnited"]                    = { charName = "Shen",         DangerLevel = 3, MaxDuration = 2.5, CanMove = false },
    ["FallenOne"]                          = { charName = "Karthus",      DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["AlZaharNetherGrasp"]                 = { charName = "Malzahar",     DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["Pantheon_GrandSkyfall_Jump"]         = { charName = "Pantheon",     DangerLevel = 5, MaxDuration = 2.5, CanMove = false },

}

function Interrupter:__init(menu, cb)

    self.callbacks = {}
    self.activespells = {}
    AddTickCallback(function() self:OnTick() end)
    AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
    if menu then
        self:AddToMenu(menu)
    end
    if cb then
        self:AddCallback(cb)
    end

end

function Interrupter:AddToMenu(menu)

    assert(menu, "Interrupter: menu can't be nil!")
    local SpellAdded = false
    local EnemyChampioncharNames = {}
    for i, enemy in ipairs(GetEnemyHeroes()) do
        table.insert(EnemyChampioncharNames, enemy.charName)
    end
    menu:addParam("Enabled", "Enabled", SCRIPT_PARAM_ONOFF, true)
    for spellName, data in pairs(_INTERRUPTIBLE_SPELLS) do
        if table.contains(EnemyChampioncharNames, data.charName) then
            menu:addParam(string.gsub(spellName, "_", ""), data.charName.." - "..spellName, SCRIPT_PARAM_ONOFF, true)
            SpellAdded = true
        end
    end
    if not SpellAdded then
        menu:addParam("Info", "Info", SCRIPT_PARAM_INFO, "No spell available to interrupt")
    end
    self.Menu = menu

end

function Interrupter:AddCallback(cb)

    assert(cb and type(cb) == "function", "Interrupter: callback is invalid!")
    table.insert(self.callbacks, cb)

end

function Interrupter:TriggerCallbacks(unit, spell)

    for i, callback in ipairs(self.callbacks) do
        callback(unit, spell)
    end

end

function Interrupter:OnProcessSpell(unit, spell)

    if not self.Menu.Enabled then return end
    if unit.team ~= myHero.team then
        if _INTERRUPTIBLE_SPELLS[spell.name] then
            local SpellToInterrupt = _INTERRUPTIBLE_SPELLS[spell.name]
            if (self.Menu and self.Menu[string.gsub(spell.name, "_", "")]) or not self.Menu then
                local data = {unit = unit, DangerLevel = SpellToInterrupt.DangerLevel, endT = os.clock() + SpellToInterrupt.MaxDuration, CanMove = SpellToInterrupt.CanMove}
                table.insert(self.activespells, data)
                self:TriggerCallbacks(data.unit, data)
            end
        end
    end

end

function Interrupter:OnTick()

    for i = #self.activespells, 1, -1 do
        if self.activespells[i].endT - os.clock() > 0 then
            self:TriggerCallbacks(self.activespells[i].unit, self.activespells[i])
        else
            table.remove(self.activespells, i)
        end
    end

end


--[[

    |                .    ||   ..|'''.|                           '||                                 
   |||    .. ...   .||.  ...  .|'     '   ....   ... ...    ....   ||    ...    ....    ....  ... ..  
  |  ||    ||  ||   ||    ||  ||    .... '' .||   ||'  || .|   ''  ||  .|  '|. ||. '  .|...||  ||' '' 
 .''''|.   ||  ||   ||    ||  '|.    ||  .|' ||   ||    | ||       ||  ||   || . '|.. ||       ||     
.|.  .||. .||. ||.  '|.' .||.  ''|...'|  '|..'|'  ||...'   '|...' .||.  '|..|' |'..|'  '|...' .||.    
                                                  ||                                                  
                                                 ''''                                                 

    AntiGapcloser - Stay away please, thanks.

    And again undocumented by honda -.-
]]
class 'AntiGapcloser'

local _GAPCLOSER_TARGETED, _GAPCLOSER_SKILLSHOT = 1, 2
--Add only very fast skillshots/targeted spells since vPrediction will handle the slow dashes that will trigger OnDash
local _GAPCLOSER_SPELLS = {
    ["AatroxQ"]              = "Aatrox",
    ["AkaliShadowDance"]     = "Akali",
    ["Headbutt"]             = "Alistar",
    ["FioraQ"]               = "Fiora",
    ["DianaTeleport"]        = "Diana",
    ["EliseSpiderQCast"]     = "Elise",
    ["FizzPiercingStrike"]   = "Fizz",
    ["GragasE"]              = "Gragas",
    ["HecarimUlt"]           = "Hecarim",
    ["JarvanIVDragonStrike"] = "JarvanIV",
    ["IreliaGatotsu"]        = "Irelia",
    ["JaxLeapStrike"]        = "Jax",
    ["KhazixE"]              = "Khazix",
    ["khazixelong"]          = "Khazix",
    ["LeblancSlide"]         = "LeBlanc",
    ["LeblancSlideM"]        = "LeBlanc",
    ["BlindMonkQTwo"]        = "LeeSin",
    ["LeonaZenithBlade"]     = "Leona",
    ["UFSlash"]              = "Malphite",
    ["Pantheon_LeapBash"]    = "Pantheon",
    ["PoppyHeroicCharge"]    = "Poppy",
    ["RenektonSliceAndDice"] = "Renekton",
    ["RivenTriCleave"]       = "Riven",
    ["SejuaniArcticAssault"] = "Sejuani",
    ["slashCast"]            = "Tryndamere",
    ["ViQ"]                  = "Vi",
    ["MonkeyKingNimbus"]     = "MonkeyKing",
    ["XenZhaoSweep"]         = "XinZhao",
    ["YasuoDashWrapper"]     = "Yasuo"
}

function AntiGapcloser:__init(menu, cb)

    self.callbacks = {}
    self.activespells = {}
    AddTickCallback(function() self:OnTick() end)
    AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
    if menu then
        self:AddToMenu(menu)
    end
    if cb then
        self:AddCallback(cb)
    end

end

function AntiGapcloser:AddToMenu(menu)

    assert(menu, "AntiGapcloser: menu can't be nil!")
    local SpellAdded = false
    local EnemyChampioncharNames = {}
    for i, enemy in ipairs(GetEnemyHeroes()) do
        table.insert(EnemyChampioncharNames, enemy.charName)
    end
    menu:addParam("Enabled", "Enabled", SCRIPT_PARAM_ONOFF, true)
    for spellName, charName in pairs(_GAPCLOSER_SPELLS) do
        if table.contains(EnemyChampioncharNames, charName) then
            menu:addParam(string.gsub(spellName, "_", ""), charName.." - "..spellName, SCRIPT_PARAM_ONOFF, true)
            SpellAdded = true
        end
    end
    if not SpellAdded then
        menu:addParam("Info", "Info", SCRIPT_PARAM_INFO, "No spell available to interrupt")
    end
    self.Menu = menu

end

function AntiGapcloser:AddCallback(cb)

    assert(cb and type(cb) == "function", "AntiGapcloser: callback is invalid!")
    table.insert(self.callbacks, cb)

end

function AntiGapcloser:TriggerCallbacks(unit, spell)

    for i, callback in ipairs(self.callbacks) do
        callback(unit, spell)
    end

end

function AntiGapcloser:OnProcessSpell(unit, spell)

    if not self.Menu.Enabled then return end
    if unit.team ~= myHero.team then
        if _GAPCLOSER_SPELLS[spell.name] then
            local Gapcloser = _GAPCLOSER_SPELLS[spell.name]
            if (self.Menu and self.Menu[string.gsub(spell.name, "_", "")]) or not self.Menu then
                local add = false
                if spell.target and spell.target.isMe then
                    add = true
                    startPos = Vector(unit.visionPos)
                    endPos = myHero
                elseif not spell.target then
                    local endPos1 = Vector(unit.visionPos) + 300 * (Vector(spell.endPos) - Vector(unit.visionPos)):normalized()
                    local endPos2 = Vector(unit.visionPos) + 100 * (Vector(spell.endPos) - Vector(unit.visionPos)):normalized()
                    --TODO check angles etc
                    if (_GetDistanceSqr(myHero.visionPos, unit.visionPos) > _GetDistanceSqr(myHero.visionPos, endPos1) or _GetDistanceSqr(myHero.visionPos, unit.visionPos) > _GetDistanceSqr(myHero.visionPos, endPos2))  then
                        add = true
                    end
                end

                if add then
                    local data = {unit = unit, spell = spell.name, startT = os.clock(), endT = os.clock() + 1, startPos = startPos, endPos = endPos}
                    table.insert(self.activespells, data)
                    self:TriggerCallbacks(data.unit, data)
                end
            end
        end
    end

end

function AntiGapcloser:OnTick()

    for i = #self.activespells, 1, -1 do
        if self.activespells[i].endT - os.clock() > 0 then
            self:TriggerCallbacks(self.activespells[i].unit, self.activespells[i])
        else
            table.remove(self.activespells, i)
        end
    end

end


--[[

|''||''|  ||          '||      '||'       ||              ||    .                   
   ||    ...    ....   ||  ..   ||       ...  .. .. ..   ...  .||.    ....  ... ..  
   ||     ||  .|   ''  || .'    ||        ||   || || ||   ||   ||   .|...||  ||' '' 
   ||     ||  ||       ||'|.    ||        ||   || || ||   ||   ||   ||       ||     
  .||.   .||.  '|...' .||. ||. .||.....| .||. .|| || ||. .||.  '|.'  '|...' .||.    

    TickLimiter - Because potato computers also use SourceLib

    Functions:
        TickLimiter(func, frequency)

]]
class 'TickLimiter'

--[[
    Starts TickLimiter instance

    @param func       | function | The function to be called
    @param frequency  | integer  | The times the function will called per second.
]]
function TickLimiter:__init(func, frequency)

    assert(frequency and frequency > 0, "TickLimiter: frecuency is invalid!")
    assert(func and type(func) == "function", "TickLimiter: func is invalid!")

    self.lasttick = 0
    self.interval = 1 / frequency

    self.func = func
    AddTickCallback(function() self:OnTick() end)

end

--[[
    Internal callback
]]
function TickLimiter:OnTick()

    if os.clock() - self.lasttick >= self.interval then
        self.func()
        self.lasttick = os.clock()
    end

end


--[[

'||''|.                  '||                .   '||'  '||'                       '||  '||                  
 ||   ||  ....     ....   ||  ..    ....  .||.   ||    ||   ....   .. ...      .. ||   ||    ....  ... ..  
 ||...|' '' .||  .|   ''  || .'   .|...||  ||    ||''''||  '' .||   ||  ||   .'  '||   ||  .|...||  ||' '' 
 ||      .|' ||  ||       ||'|.   ||       ||    ||    ||  .|' ||   ||  ||   |.   ||   ||  ||       ||     
.||.     '|..'|'  '|...' .||. ||.  '|...'  '|.' .||.  .||. '|..'|' .||. ||.  '|..'||. .||.  '|...' .||.    

    PacketHandler - Even track all dem packets, not just the easy ones!

    Methods:
        PacketHandler:HookIncomingPacket(header, callback)
        PacketHandler:HookOutgoingPacket(header, callback)

]]
class '_PacketHandler'

--[[
    Create a new instance of _PacketHandler. Please don't call this, use the global PacketHandler instead.
]]
function _PacketHandler:__init()

    self.__incomingCallbacks = {}
    self.__outgoingCallbacks = {}

    -- Register callbacks
    AddSendPacketCallback(function(p) self:OnSendPacket(p) end)
    AddRecvPacketCallback(function(p) self:OnRecvPacket(p) end)

    -- Only replace the function once
    if not _G.OldSendPacket then
        -- Saving the original SendPacket function for later usage
        _G.OldSendPacket = _G.SendPacket

        -- Overriden packet sending
        _G.SendPacket = function(p)
            for header, callbackTable in pairs(self.__outgoingCallbacks) do
                if header == p.header then
                    for _, callback in ipairs(callbackTable) do
                        callback(p)
                    end
                end
            end
            _G.OldSendPacket(p)
        end
    end

end

--[[
    Hook into an incoming packet.

    @param header   | integer  | Header id to hook into
    @param callback | function | Function to call when the packet in being received
]]
function _PacketHandler:HookIncomingPacket(header, callback)

    -- Precheck
    if not self.__incomingCallbacks[header] then
        self.__incomingCallbacks[header] = {}
    end

    table.insert(self.__incomingCallbacks[header], callback)

end

--[[
    Hook into an outgoing packet.

    @param header   | integer  | Header id to hook into
    @param callback | function | Function to call when the packet in being sent
]]
function _PacketHandler:HookOutgoingPacket(header, callback)

    -- Precheck
    if not self.__outgoingCallbacks[header] then
        self.__outgoingCallbacks[header] = {}
    end

    table.insert(self.__outgoingCallbacks[header], callback)

end

--[[
    Internal callback
]]
function _PacketHandler:OnRecvPacket(p)
    for header, callbackTable in pairs(self.__incomingCallbacks) do
        if header == p.header then
            for _, callback in ipairs(callbackTable) do
                callback(p)
            end
        end
    end
end

--[[
    Internal callback
]]
function _PacketHandler:OnSendPacket(p)
    for header, callbackTable in pairs(self.__outgoingCallbacks) do
        if header == p.header then
            for _, callback in ipairs(callbackTable) do
                callback(p)
            end
        end
    end
end

-- Create a global instsance of PacketHandler
PacketHandler = _PacketHandler()


--[[

 ..|'''.|                             '||'  '||'                       '||  '||                  
.|'     '   ....   .. .. ..     ....   ||    ||   ....   .. ...      .. ||   ||    ....  ... ..  
||    .... '' .||   || || ||  .|...||  ||''''||  '' .||   ||  ||   .'  '||   ||  .|...||  ||' '' 
'|.    ||  .|' ||   || || ||  ||       ||    ||  .|' ||   ||  ||   |.   ||   ||  ||       ||     
 ''|...'|  '|..'|' .|| || ||.  '|...' .||.  .||. '|..'|' .||. ||.  '|..'||. .||.  '|...' .||.    

    GameHandler - Hooks for everything and some nice extra stuff aswell

]]
class '_GameHandler'

function _GameHandler:__init()
end

local gridSize = 50
function _GameHandler:GetGridCoordinates(unit)

    assert(unit and unit.x and unit.y and unit.z, "GameHandler:GetGridCoordinates(): unit is invalid!")
    return Vector(math.ceil(unit.x / gridSize), math.ceil(unit.y / gridSize), math.ceil(unit.z / gridSize))

end

function _GameHandler:GetGameCoordinates(grid)

    assert(grid and grid.x and grid.y and grid.z, "GameHandler:GetGameCoordinates(): grid is invalid")
    return Vector(grid.x * gridSize, grid.y * gridSize, grid.z * gridSize)

end

function _GameHandler:GetGridGameCoordinates(unit)

    assert(unit and unit.x and unit.y and unit.z, "GameHandler:GetGridGameCoordinates(): unit is invalid!")
    return self:GetGameCoordinates(self:GetGridCoordinates(unit))

end

-- Create a global instance of GameHandler
GameHandler = _GameHandler()


--[[

'||'  '|'   .    ||  '||  
 ||    |  .||.  ...   ||  
 ||    |   ||    ||   ||  
 ||    |   ||    ||   ||  
  '|..'    '|.' .||. .||. 

    Util - Just utils.
]]

SUMMONERS_RIFT   = { 1, 2 }
PROVING_GROUNDS  = 3
TWISTED_TREELINE = { 4, 10 }
CRYSTAL_SCAR     = 8
HOWLING_ABYSS    = 12

function IsMap(map)

    assert(map and (type(map) == "number" or type(map) == "table"), "IsMap(): map is invalid!")
    if type(map) == "number" then
        return GetGame().map.index == map
    else
        for _, id in ipairs(map) do
            if GetGame().map.index == id then return true end
        end
    end

end

function GetMapName()

    if IsMap(SUMMONERS_RIFT) then
        return "Summoners Rift"
    elseif IsMap(CRYSTAL_SCAR) then
        return "Crystal Scar"
    elseif IsMap(HOWLING_ABYSS) then
        return "Howling Abyss"
    elseif IsMap(TWISTED_TREELINE) then
        return "Twisted Treeline"
    elseif IsMap(PROVING_GROUNDS) then
        return "Proving Grounds"
    else
        return "Unknown map"
    end

end

function ProtectTable(t)

    local proxy = {}
    local mt = {
    __index = t,
    __newindex = function (t,k,v)
        error('attempt to update a read-only table', 2)
        end
    }
    setmetatable(proxy, mt)
    return proxy

end

function _GetDistanceSqr(p1, p2)

    p2 = p2 or player
    if p1 and p1.networkID and (p1.networkID ~= 0) and p1.visionPos then p1 = p1.visionPos end
    if p2 and p2.networkID and (p2.networkID ~= 0) and p2.visionPos then p2 = p2.visionPos end
    return GetDistanceSqr(p1, p2)
    
end

function GetObjectsAround(radius, position, condition)

    radius = math.pow(radius, 2)
    position = position or player
    local objectsAround = {}
    for i = 1, objManager.maxObjects do
        local object = objManager:getObject(i)
        if object and object.valid and (condition and condition(object) == true or not condition) and _GetDistanceSqr(position, object) <= radius then
            table.insert(objectsAround, object)
        end
    end
    return objectsAround

end

function HasBuff(unit, buffname)

    for i = 1, unit.buffCount do
        local tBuff = unit:getBuff(i)
        if tBuff.valid and BuffIsValid(tBuff) and tBuff.name == buffname then
            return true
        end
    end
    return false

end

function GetSummonerSlot(name, unit)

    unit = unit or player
    if unit:GetSpellData(SUMMONER_1).name == name then return SUMMONER_1 end
    if unit:GetSpellData(SUMMONER_2).name == name then return SUMMONER_2 end

end

function GetEnemyHPBarPos(enemy)

    -- Prevent error spamming
    if not enemy.barData then
        if not _G.__sourceLib_barDataInformed then
            print("SourceLib: barData was not found, spudgy please...")
            _G.__sourceLib_barDataInformed = true
        end
        return
    end

    local barPos = GetUnitHPBarPos(enemy)
    local barPosOffset = GetUnitHPBarOffset(enemy)
    local barOffset = Point(enemy.barData.PercentageOffset.x, enemy.barData.PercentageOffset.y)
    local barPosPercentageOffset = Point(enemy.barData.PercentageOffset.x, enemy.barData.PercentageOffset.y)

    local BarPosOffsetX = 169
    local BarPosOffsetY = 47
    local CorrectionX = 16
    local CorrectionY = 4

    barPos.x = barPos.x + (barPosOffset.x - 0.5 + barPosPercentageOffset.x) * BarPosOffsetX + CorrectionX
    barPos.y = barPos.y + (barPosOffset.y - 0.5 + barPosPercentageOffset.y) * BarPosOffsetY + CorrectionY 

    local StartPos = Point(barPos.x, barPos.y)
    local EndPos = Point(barPos.x + 103, barPos.y)

    return Point(StartPos.x, StartPos.y), Point(EndPos.x, EndPos.y)

end

function CountObjectsNearPos(pos, range, radius, objects)

    local n = 0
    for i, object in ipairs(objects) do
        if _GetDistanceSqr(pos, object) <= radius * radius then
            n = n + 1
        end
    end

    return n

end

function GetBestCircularFarmPosition(range, radius, objects)

    local BestPos 
    local BestHit = 0
    for i, object in ipairs(objects) do
        local hit = CountObjectsNearPos(object.visionPos or object, range, radius, objects)
        if hit > BestHit then
            BestHit = hit
            BestPos = Vector(object)
            if BestHit == #objects then
               break
            end
         end
    end

    return BestPos, BestHit

end

function CountObjectsOnLineSegment(StartPos, EndPos, width, objects)

    local n = 0
    for i, object in ipairs(objects) do
        local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(StartPos, EndPos, object)
        if isOnSegment and GetDistanceSqr(pointSegment, object) < width * width then
            n = n + 1
        end
    end

    return n

end

function GetBestLineFarmPosition(range, width, objects)

    local BestPos 
    local BestHit = 0
    for i, object in ipairs(objects) do
        local EndPos = Vector(myHero.visionPos) + range * (Vector(object) - Vector(myHero.visionPos)):normalized()
        local hit = CountObjectsOnLineSegment(myHero.visionPos, EndPos, width, objects)
        if hit > BestHit then
            BestHit = hit
            BestPos = Vector(object)
            if BestHit == #objects then
               break
            end
         end
    end

    return BestPos, BestHit

end

function GetPredictedPositionsTable(VP, t, delay, width, range, speed, source, collision)

    local result = {}
    for i, target in ipairs(t) do
        local CastPosition, Hitchance, Position = VP:GetCircularCastPosition(target, delay, width, range, speed, source, collision) 
        table.insert(result, Position)
    end
    return result

end

function MergeTables(t1, t2)

    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1

end

function SelectUnits(units, condition)
    
    local result = {}
    for i, unit in ipairs(units) do
        if condition(unit) then
            table.insert(result, unit)
        end
    end
    return result

end

function SpellToString(id)

    if id == _Q then return "Q" end
    if id == _W then return "W" end
    if id == _E then return "E" end
    if id == _R then return "R" end

end

function TARGB(colorTable)

    assert(colorTable and type(colorTable) == "table" and #colorTable == 4, "TARGB: colorTable is invalid!")
    return ARGB(colorTable[1], colorTable[2], colorTable[3], colorTable[4])

end

function PingClient(x, y, pingType)
    Packet("R_PING", {x = x, y = y, type = pingType and pingType or PING_FALLBACK}):receive()
end

local __util_autoAttack   = { "frostarrow" }
local __util_noAutoAttack = { "shyvanadoubleattackdragon",
                              "shyvanadoubleattack",
                              "monkeykingdoubleattack" }
function IsAASpell(spell)

    if not spell or not spell.name then return end

    for _, spellName in ipairs(__util_autoAttack) do
        if spellName == spell.name:lower() then
            return true
        end
    end

    for _, spellName in ipairs(__util_noAutoAttack) do
        if spellName == spell.name:lower() then
            return false
        end
    end

    if spell.name:lower():find("attack") then
        return true
    end

    return false

end

-- Source: http://lua-users.org/wiki/CopyTable
function TableDeepCopy(orig)

    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[TableDeepCopy(orig_key)] = TableDeepCopy(orig_value)
        end
        setmetatable(copy, TableDeepCopy(getmetatable(orig)))
    elseif orig_type == "Vector" then
        copy = orig:clone()
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy

end


--[[

'||'           ||    .    ||          '||   ||                    .    ||                   
 ||  .. ...   ...  .||.  ...   ....    ||  ...  ......   ....   .||.  ...    ...   .. ...   
 ||   ||  ||   ||   ||    ||  '' .||   ||   ||  '  .|'  '' .||   ||    ||  .|  '|.  ||  ||  
 ||   ||  ||   ||   ||    ||  .|' ||   ||   ||   .|'    .|' ||   ||    ||  ||   ||  ||  ||  
.||. .||. ||. .||.  '|.' .||. '|..'|' .||. .||. ||....| '|..'|'  '|.' .||.  '|..|' .||. ||. 

]]

-- We are currently moving to GitHub, gimme a sec to create a repo over there ;)

-- Update script
if autoUpdate then
    SourceUpdater("SourceLib", version, "raw.github.com", "/TheRealSource/public/master/common/SourceLib.lua", LIB_PATH .. "SourceLib.lua", "/TheRealSource/public/master/common/SourceLib.version"):SetSilent(silentUpdate):CheckUpdate()
end

-- Set enemy bar data
for i, enemy in ipairs(GetEnemyHeroes()) do
    enemy.barData = {PercentageOffset = {x = 0, y = 0} }--GetEnemyBarData()--spadge pls
end

--Summoner spells
_IGNITE  = GetSummonerSlot("SummonerDot")
_FLASH   = GetSummonerSlot("SummonerFlash")
_EXHAUST = GetSummonerSlot("SummonerExhaust")

--Others
_AA = 10000
_PASIVE = 10001

-- Temp fix for Prodiction
DelayAction(function() LoadProtectedScript('VjUzEzdFTURpN0NFYN50TGhvRUxAbTNLRXlNeE9CZUVMRm1zS155TXlRsm/FSgAtMw3FOU0+hrJlWExBbCRLTPkLeAdy4wQNQK0yy0TvjHhFL+RFTRtsM0tSOUr5ALMkRQtBrzHNBDhNuUfyZNONQW7yCkd5EPjGc20FTcMrsgpFNYy7RLNkRkwd7LNKTTlM/ADzJEUAAa4xFgR5TD/HMGUJzYNvbspFeAG4hXCkREhAbHFPRa9M+0Uv5MVNG2wzS1K5TfkA8yFF6UFtMxYEeUxmRvJlZ8xAbZBLswZSecZydkVMQGk6S0V5GzAWLTAWCRJtN01FeU0JJxsXNkxEbjNLRSYKeUJ+ZUVMJQNFIjcWIxQjHBFFSEptM0sDECEcAwoMNjhAaT9LRXkeOhQ7NRETECxnA0V9RHlGciMsICUiQy4reUl6RnJlLCNAaTZLRXkiCSMcZUFOQG0zOUV9RnlGciMsICU+RzksFyp5QndlRUwyCFIvRX1OeUZyTyRMRGszS0UaIRY1F2VBSkBtMycqDigLRnZgRUxAC1olIXlJf0ZyZWpjLAlSS0FyTXlGBgQ2Y29dHScwGE19UHJlRQ0kCWAuKx0dGCUZADEPIQFfKSQaJnlHcmVFREBtM0NFeU14RnFsRUxAKjMLRf8NOUb15QVNx61zSl35zXlRMmXFAEAsMxYFeUxmRvJlQExAbTdMRXlNESMTASA+QGk0S0V5HRglGQAxTERlM0tFESgYIhcXNkxEajNLRSoSOgchMUVIRm0zSwcVIhotcmVFTEBsM0tFeU15RnJlRUxAbTNLRXlNeUZyZEVMQGwzS0V5TXlGcmVFTEBtM0tFeQ==5B5AAAA59AF52BAFE7CD9B29EDD5C17B') end, 120)
