local digest = require('digest')

local function waitevent(self, timeout)
    return self:run({
        Action = 'WaitEvent',
        Timeout = timeout,
    })
end

local function userevent(self, name, values)
    if not name then
        error('UserEvent is not defined')
    end

    values.Action = 'UserEvent'
    values.UserEvent = name

    return self:run(values)
end

local function hangup(self, channel, cause)
    local req = {
        Action = 'Hangup',
        Channel = channel,
    }

    if cause then
        req.Cause = cause
    end

    return self:run(req)
end

local function agi(self, values)
    if not values.Channel then
        error('Channel is not defined')
    end

    if not values.Command then
        error('Command is not defined')
    end

    if not values.CommandID then
        error('CommandID is not defined')
    end

    values.Action = 'AGI'

    return self:run(values)
end

local function events(self, flag)
    if type(flag) ~= 'string' then
        error('Incorrect type of flag')
    end

    if flag == 'on' or flag == 'off' then
        return self:run({
            Action = 'Events',
            EventMask = flag,
        })
    else
        -- XXX: Fix me after impliment string parser for: system,call,log,...
        error('Sorry, method only supports on/off')
    end
end

local function login(self, user, secret, challenge)
    local req = {
        Action = 'login',
        Username = user,
    }

    if challenge then
        req.AuthType = 'md5'
        req.Key = digest.md5_hex(challenge .. secret)
    else
        req.Secret = secret
    end

    return self:run(req)
end

local function logoff(self)
    return self:run({
        Action = 'Logoff'
    })
end

local function challenge(self)
    return self:run({
        Action = 'Challenge',
        AuthType = 'md5',
    })
end

local function ping(self)
    return self:run({
        Action = 'Ping',
    })
end

local function originate(self, values)
    values.Action = 'Originate'

    return self:run(values)
end

local function coreshowchannels(self)
    return self:run({
        Action = 'CoreShowChannels'
    })
end

local function redirect(self, values)
    values.Action = 'Redirect'

    return self:run(values)
end

return {
    login = login,
    ping = ping,
    logoff = logoff,
    challenge = challenge,
    coreshowchannels = coreshowchannels,
    redirect = redirect,
    originate = originate,
    agi = agi,
    events = events,
    hangup = hangup,
    userevent = userevent,
    waitevent = waitevent,
}
