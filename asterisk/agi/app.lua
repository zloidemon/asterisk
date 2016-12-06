--[[
-- AGI commands
]]--

local function hangup(self, opts, channel)
    local command = nil
    if channel ~= nil and type(channel) == 'string' then
        command = string.format("HANGUP %s", channel)
    else
        command = string.format("HANGUP")
    end
    self.st.hangup = true

    return self:run(command, opts)
end

local function answer(self, opts)
    return self:run("ANSWER")
end

local function asyncagi(self)
    return self:run("ASYNCAGI BREAK")
end

local function noop(self)
    return self:run("NOOP")
end

local function set_autohangup(self, opts, time)
    local command = string.format("SET AUTOHANGUP %s", time)
    return self:run(command, opts)
end

local function set_callerid(self, opts, data)
    local command = string.format("SET CALLERID %s", data)
    return self:run(command, opts)
end

local function set_context(self, opts, data)
    local command = string.format("SET CONTEXT %s", data)
    return self:run(command, opts)
end

local function set_extension(self, opts, data)
    local command = string.format("SET EXTENSION %s", data)
    return self:run(command, opts)
end

local function set_music(self, opts, state, class)
    if state ~= 'on' and state ~= 'off' then
        return self
    end
    local command = string.format("SET MUSIC %s", state)
    if class then
        command = string.format("%s %s", command, class)
    end
    return self:run(command, opts)
end

local function set_priority(self, opts, priority)
    local command = string.format("SET PRIORITY %s", priority)
    return self:run(command, opts)
end

local function set_variable(self, opts, var, val)
    local command = string.format("SET VARIABLE %s %s", var, val)
    return self:run(command, opts)
end

local function get_variable(self, opts, data)
    local command = string.format("GET VARIABLE %s", data)
    return self:run(command, opts)
end

local function channel_status(self, opts, data)
    local command = string.format("CHANNEL STATUS %s", data)
    return self:run(command, opts)
end

local function control_stream_file(self, opts, fmt, ...)
    local data    = string.format(fmt, ...)
    local command = string.format("CONTROL STREAM FILE %s", data)
    return self:run(command, opts)
end

local function database_del(self, opts, family, key)
    local command = string.format("DATABASE DEL %s %s", family, key)
    return self:run(command, opts)
end

local function database_deltree(self, opts, family, key)
    local command = string.format("DATABASE DELTREE %s %s", family, key)
    return self:run(command, opts)
end

local function database_get(self, opts, family, key)
    local command = string.format("DATABASE GET %s %s", family, key)
    return self:run(command, opts)
end

local function database_put(self, opts, family, key, value)
    local command = string.format("DATABASE PUT %s %s %s", family, key, value)
    return self:run(command, opts)
end

local function exec(self, opts, fmt, ...)
    local data    = string.format(fmt, ...)
    local command = string.format("EXEC %s", data)
    return self:run(command, opts)
end

local function get_data(self, opts, file, timeout, maxdigits)
    local command = string.format("GET DATA %s %s %s", file, timeout, maxdigits)
    return self:run(command, opts)
end

local function ttd_mode(self, opts, status)
    if status ~= 'on' and status ~= 'off' then
        return self
    end
    local command = string.format("TDD MODE %s", status)
    return self:run(command, opts)
end

local function verbose(self, opts, message, level)
    if type(message) ~= 'string' and type(level) ~= 'number' then
        return self
    end

    if level < 0 or level > 4 then
        return
    end

    local command = string.format("VERBOSE %s %s", message, level)
    return self:run(command, opts)
end

--[[
-- Asterisk applications which calls by EXEC agi command
]]--

local function saydigits(self, opts, data)
    local command = string.format('EXEC SayDigits %d', data)
    return self:run(command, opts)
end

local function dial(self, opts, fmt, ...)
    local data    = string.format(fmt, ...)
    local command = string.format('EXEC Dial "%s"', data)
    return self:run(command, opts)
end

local function wait(self, opts, data)
    local command = string.format('EXEC WAIT %d', data)
    return self:run(command, opts)
end

local function echo(self, opts)
    local command = string.format('EXEC ECHO')
    return self:run(command, opts)
end

local function ringing(self, opts, data)
    local command = string.format('EXEC RINGING')
    return self:run(command, opts)
end

local function authenticate(self, opts, ...)
    local data = {...}
    local _command = nil

    local passwd  = data[1]
    local options = data[2]
    local maxdig  = data[3]
    local prompt  = data[4]

    if type(passwd) == 'number' then
        _command = string.format("%d,", passwd)
    else
        _command = string.format(",")
    end

    if type(options) == 'string' and (
       options == 'a' or options == 'd' or
       options == 'm' or options == 'r') then

        _command = string.format("%s%s,", _command, options)
    else
        _command = string.format("%s,", _command)
    end

    if type(maxdig) == 'number' then
        _command = string.format("%s%d,", _command, maxdig)
    else
        _command = string.format("%s,", _command)
    end

    if type(prompt) == 'string' then
        _command = string.format("%s%s", _command, prompt)
    else
        _command = string.format("%s", _command)
    end

    local command = string.format('EXEC AUTHENTICATE %s', _command)
    return self:run(command, opts)
end

local function playback(self, opts, file, option)
    local command = nil
    if option ~= nil and type(option) == 'string' then
       command = string.format('EXEC PLAYBACK %s, %s', file, option)
    else
       command = string.format('EXEC PLAYBACK %s', file)
    end
    return self:run(command, opts)
end

local function channelredirect(self, opts, ch, ctx, ext, pri)
    local command = string.format('EXEC CHANNELREDIRECT "%s, %s, %s, %s"',
        ch, ctx, ext, pri)

    return self:run(command, opts)
end

local function sipremoveheader(self, opts, data)
    local command = string.format('EXEC SIPRemoveHeader %s', data)
    return self:run(command, opts)
end

local function sipaddheader(self, opts, header, content)
    local data = string.format('%s: %s', header, content)
    local command = string.format('EXEC SIPAddHeader "%s"', data)
    return self:run(command, opts)
end

return {
    answer = answer,
    asyncagi = asyncagi,
    hangup = hangup,
    channel_status = channel_status,
    control_stream_file = control_stream_file,
    database_del = database_del,
    database_deltree = database_deltree,
    database_get = database_get,
    database_put = database_put,
    exec = exec,
    get_data = get_data,
    get_variable = get_variable,
    noop = noop,
    set_autohangup = set_autohangup,
    set_callerid = set_callerid,
    set_context = set_context,
    set_extension = set_extension,
    set_music = set_music,
    set_priority = set_priority,
    set_variable = set_variable,
    tdd_mode = tdd_mode,
    verbose = verbose,

    saydigits = saydigits,
    dial = dial,
    wait = wait,
    echo = echo,
    ringing = ringing,
    playback = playback,
    authenticate = authenticate,
    channelredirect = channelredirect,
    sipremoveheader = sipremoveheader,
    sipaddheader = sipaddheader,
}
