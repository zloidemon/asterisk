local socket = require('socket')
local uuid   = require('uuid')
local fiber  = require('fiber')
local fun    = require('fun')
local log    = require('log')
local actions= require('asterisk.ami.actions')

local function fwrite(k, v)
    log.debug("C: key: %s, val: %s", k, v)
    return string.format("%s:%s\r\n", k, v)
end

local function read_stream(self)
    local data = {}
    local init = false

    while true do
        local resp = self.tcp_client:read({delimiter='\r\n'})
        if not resp then
            log.error('No data, close connection')
            self:disconnect()
        else
            if resp == '\r\n' then
                if data.event then
                    self.events(data)
                elseif data.response then
                    if data.actionid and self.channels[data.actionid] then
                        self.channels[data.actionid]:put(data)
                    end
                end
                data = {}
            else
                local k, v = string.match(resp, "^(%g+):%s*(.+)\r\n$")
--                local k = string.match(resp, "^(%g+):[%g%s]+\r\n$")
                if k then
--                    local v = string.match(resp, "^%g+:%s(.+)\r\n$")
                    if not v then
                        v = ''
                    end
                    log.debug("S: key: %s, val: %s", k, v)
                    data[string.lower(k)] = v
                else
                    -- First message from Asterisk is banner
                    if not init then
                        init = true
                    else
                        log.error("can not parse resp: '%s'", resp)
                        self:disconnect()
                    end
                end
            end
        end
    end
end

local function disconnect(self)
    if type(self) ~= 'table' then
        error('ami can not stop')
    end

    if self.is_run then
        self.is_run = false
    else
        error('server is already stopped')
    end
    
    if self.read_stream ~= nil then
        self.read_stream:cancel()
        self.read_steram = nil
    end

    if self.tcp_client ~= nil then
        self.tcp_client:close()
        self.tcp_client = nil
    end

    return self
end

local function connect(self, user, secret)
    if type(self) ~= 'table' then
        error('ami can not start')
    end

    if user == nil or type(user) ~= 'string' then
        error('incorrect user login')
    end

    if secret == nil or type(secret) ~= 'string' then
        error('incorrect password')
    end

    rawset(self, 'user', user)
    rawset(self, 'secret', secret)

    local server = socket.tcp_connect(self.host, self.port)

    if not server then
        error("can not connect to the server: " .. self.host .. ":" .. self.port)
    end

    fiber.create(function (server, name)
        fiber.name(name)
        rawset(self, 'is_run', true)
        rawset(self, 'tcp_client', server)
        rawset(self, 'read_stream', fiber.self())
        read_stream(self)
    end, server, self.options.name)

    self:run('login', user, secret)

    return self
end

local function on_event(self, sub)
    if sub == nil or type(sub) ~= 'function' then
        error("event halper is not function")
    end

    self.events = sub

    return self
end

local function add_script(self, opts, sub)
    if type(opts) ~= 'table' or type(self) ~= 'table' then
        error("Usage: :script({...}, function(cx) ... end)")
    end

    if opts.path == nil then
        error("path is not defined")
    end

    if sub == nil or type(sub) ~= 'function' then
        error("script is not function")
    end

    opts.sub = sub

    table.insert(self.scripts, opts)

    return self
end

local function run_action(self, data)
    local actionid = uuid.str()
    self.channels[actionid] = fiber.channel(1)

    data.ActionID = actionid

    fun.each(function(...) self.s:write(...) end,
        fun.map(fwrite, data))
    self.s:write('\r\n')

    local resp = self.channels[actionid]:get(self.timeout)
    self.channels[actionid]:close()
    self.channels[actionid] = nil

    return resp
end

local function run_script(self, path, ...)
    if not self.is_run and path ~= 'login' then
        if path ~= 'login' then
            log.info("connection lost reconnecting to %s:%s", self.host, self.port)
            self:connect(self.user, self.secret)
        end
    end

    local req = {
        s = self.tcp_client,
        run = run_action,
        channels = self.channels,
        timeout = self.options.ipc.timeout,
    }

    setmetatable(req, {__index=actions})

    for _, v in pairs(self.scripts) do
        if v.path == path then
            v.sub(req, ...)
        end
    end
end

local function default_login(self, user, secret)
    local hs   = self:challenge()
    local resp = {}

    if hs.response == 'Success' then
        resp = self:login(user, secret, hs.challenge)
    else
        resp = self:login(user, secret)
    end

    if resp.response ~= 'Success' then
        log.error(resp.message)
    end

    return resp
end

local function default_logoff(self)
    self:logoff()
end

local export = {
    new = function(host, port, opts)
        local options = {
            name = uuid.str(),
            ipc  = {
                timeout = 5, -- AMI slow responses if Response: Error
            }
        }

        if opts ~= nil and type(opts) == 'table' then
            if opts.name and type(opts.name) == 'string' then
                options.name = opts.name
            end
            if opts.ipc and type(opts.ipc) == 'table' then
                if opts.ipc.timeout and type(opts.ipc.timeout) == 'number' then
                    options.ipc.timeout = opts.ipc.timeout
                end
            end
        end

        if type(host) ~= 'string' then
            error('host must to be string')
        end
        if type(port) ~= 'number' then
            error('port must to be number')
        end

        local self = {
            host = host,
            port = port,
            is_run = false,
            connect = connect,
            disconnect = disconnect,
            options = options,
            events = function (data) end,
            event = on_event,
            scripts = {
                {path = 'login',  sub = default_login},
                {path = 'logoff', sub = default_logoff},
            },
            channels = {},
            script = add_script,
            run = run_script,
        }
        return self
    end
}

return export
