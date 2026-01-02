-- az_welcome_firstcar / server.lua
-- Requires ox_lib
-- Identity & cooldown storage uses Az-CharacterUI active char id

local Config = Config or {}

---------------------------------------------------------------------
-- CONFIG DEFAULTS (safe fallbacks)
---------------------------------------------------------------------

Config.Welcome = Config.Welcome or {}
Config.FirstCar = Config.FirstCar or {}

-- Your intent:
-- "MAKE THE UI ALWAYS APPEAR WHEN THEY WALK AROUND WHEN THEY JOIN FOR THE SESSION"
-- So default true.
Config.Welcome.ShowEverySession = (Config.Welcome.ShowEverySession ~= false)

-- legacy flag still supported if you ever disable ShowEverySession
Config.Welcome.PersistOncePerPlayer = (Config.Welcome.PersistOncePerPlayer ~= false)

Config.FirstCar.CooldownSeconds = Config.FirstCar.CooldownSeconds or (24 * 60 * 60)

---------------------------------------------------------------------
-- CHARACTER ID (Az-CharacterUI)
---------------------------------------------------------------------

Config.GetPlayerCharId = Config.GetPlayerCharId or function(src)
    local ui = exports['Az-CharacterUI']
    if not ui then return nil end

    local ok, charId = pcall(function()
        return ui:getActiveCharacter(src)
    end)

    if ok and charId then
        return tostring(charId)
    end

    return nil
end

---------------------------------------------------------------------
-- FALLBACK IDENTIFIER
---------------------------------------------------------------------

local function getPrimaryIdentifier(src)
    local license = GetPlayerIdentifierByType(src, 'license')
    if license and license ~= '' then
        return license
    end

    local ids = GetPlayerIdentifiers(src)
    return ids[1] or ("src:" .. tostring(src))
end

-- Identity priority: charid -> license
local function getIdentity(src)
    local charid = Config.GetPlayerCharId(src)
    if charid and charid ~= '' then
        return ("char:%s"):format(charid)
    end

    return ("license:%s"):format(getPrimaryIdentifier(src))
end

local function welcomeKey(identity)
    return ("az_welcome_seen_%s"):format(identity)
end

local function firstCarKey(identity)
    return ("az_firstcar_lastclaim_%s"):format(identity)
end

---------------------------------------------------------------------
-- WELCOME SHOULD SHOW?
---------------------------------------------------------------------

lib.callback.register('az_welcome_firstcar:shouldShowWelcome', function(src)
    -- New desired behavior: show every session
    if Config.Welcome.ShowEverySession then
        return true
    end

    -- If you ever turn off ShowEverySession, this legacy mode applies
    if not Config.Welcome.PersistOncePerPlayer then
        return true
    end

    local identity = getIdentity(src)
    local key = welcomeKey(identity)

    local seen = GetResourceKvpInt(key)
    if seen and seen == 1 then
        return false
    end

    return true
end)

---------------------------------------------------------------------
-- MARK WELCOME SEEN (legacy only)
---------------------------------------------------------------------

RegisterNetEvent('az_welcome_firstcar:markWelcomeSeen', function()
    local src = source

    -- In session mode, we do not store KVP for welcome
    if Config.Welcome.ShowEverySession then
        return
    end

    if not Config.Welcome.PersistOncePerPlayer then return end

    local identity = getIdentity(src)
    local key = welcomeKey(identity)

    SetResourceKvpInt(key, 1)
end)

---------------------------------------------------------------------
-- FIRST CAR CLAIM (charid-based cooldown)
---------------------------------------------------------------------

lib.callback.register('az_welcome_firstcar:claimFirstCar', function(src)
    local identity = getIdentity(src)
    local key = firstCarKey(identity)

    local last = GetResourceKvpInt(key) or 0
    local now = os.time()

    local elapsed = now - last
    local remaining = (Config.FirstCar.CooldownSeconds or 0) - elapsed

    if remaining > 0 then
        return {
            ok = false,
            remaining = remaining
        }
    end

    -- Approve claim, store timestamp
    SetResourceKvpInt(key, now)

    return {
        ok = true,
        remaining = 0
    }
end)


---------------------------------------------------------------------
-- TEST / ADMIN: RESET KVP FOR A SOURCE
-- Usage:
--   /az_resetkvp                (resets for yourself)
--   /az_resetkvp 12             (resets for target server ID)
--
-- NOTE:
-- Uses the same identity system:
--   charid (Az-CharacterUI active char) -> license fallback
---------------------------------------------------------------------

RegisterCommand('az_resetkvp', function(src, args)
    -- Determine target
    local target = tonumber(args[1] or '') or src

    if target == 0 then
        print('[az_welcome_firstcar] Console must provide a target id: /az_resetkvp <id>')
        return
    end

    -- Optional: restrict to admins / command / ACE if you want
    -- if src ~= 0 and not IsPlayerAceAllowed(src, 'az.admin') then
    --     return
    -- end

    local identity = getIdentity(target)
    local wKey     = welcomeKey(identity)
    local cKey     = firstCarKey(identity)

    -- Delete keys cleanly
    DeleteResourceKvp(wKey)
    DeleteResourceKvp(cKey)

    print(('[az_welcome_firstcar] Reset KVP for target=%d identity=%s')
        :format(target, tostring(identity)))

    -- Feedback to player if in-game
    if src ~= 0 then
        TriggerClientEvent('chat:addMessage', src, {
            args = { '^2KVP', ('Reset done for ID %d (%s)'):format(target, identity) }
        })
    end

    if target ~= src then
        TriggerClientEvent('chat:addMessage', target, {
            args = { '^2KVP', 'Your welcome/firstcar KVP was reset by staff.' }
        })
    end
end, false)
