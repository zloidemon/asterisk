local log    = require('log')
local uri    = require('uri')
local socket = require('socket')
local agivar = require('asterisk.agi.variables')
local apps   = require('asterisk.agi.app')
local fiber  = require('fiber')


local function get_vars(data, out)
    local key, val = string.match(data, "^([%a%d_]+): (.*)\n$")
    if key and val then
        out[key] = val
    end
    for _, v in pairs(agivar) do
        if out[v] == nil then
            return false
        end
    end
    return true
end

-- Dirty parser
local function get_result(data, out)
    local code, s, r, d
    --code, res = string.match(data, "^(%d+) result=([-]?%d+)\n$")
    code, d = string.match(data, "^(%d+) (.+)\n$")
    if code then
        out.code = code
        for str in string.gmatch(d, "[^%s]+") do
            r, s = string.match(str, "(.+)=(.+)")
            if r and s then
                out[r] = s
            else
                r = string.match(str, "%((.+)%)")
                if r then
                    out.data = r
                end
            end
        end

        return true
    end
    return false 
end

local function run(self, command, opts)
    local res = {}
    local req = nil
    if not opts then
        opts = {}
    end

    while true do
        if self.channel:is_empty() and not self.st.cmd then
            req = ''
        else
            req = self.channel:get()
        end

        if string.match(req, "HANGUP") or self.st.hangup then
            break
        elseif get_result(req, res) then
            log.info('Asterisk answer code: %s resp: %s', res.code, res.result)
            if res.result == -2 then
                log.error('Can not run: %s', command)
                self.s:write("HANGUP\n")
                self.st.cmd = true
                self.st.hangup = true
            elseif res.result == -1 then
                if type(opts.error) == 'function' then
                    opts.error(self, res)
                end
            else
                if type(opts.success) == 'function' then
                    opts.success(self, res)
                end
            end
            res = {}
            self.st.cmd = false
            break
        end

        if not self.st.cmd and not self.st.hangup then
            self.s:write(string.format("%s\n", command))
            self.st.cmd = true
        end
    end
    return self
end

local function read_stream(self)
    while true do
        local req = self.s:read({delimiter='\n'})
        if not req then
            log.error('No data, hangup')
            self.channel:put("HANGUP")
            break
        else
            self.channel:put(req)
        end
    end
end

local function process_call(self, s, peer)
    local call = {}
    local required = nil
    while true do
        local req = s:read({delimiter='\n'}, self.options.timeout)

        if not req then
            break
        end

        if get_vars(req, call) then
            required = true
        end
    end

    if required then
        call.p = peer
        call.s = s
        call.st = {
            cmd = nil,
            hangup = false,
        }
        call.run = run
        call.channel = fiber.channel(1)
        call.reader  = fiber.create(read_stream, call)

        setmetatable(call, {__index=apps})

        local res = {}
        local snd = false
        local hangup = false
      
        local script = uri.parse(call['agi_request']).path

        for _, v in pairs(self.scripts) do
            if script == v.path then
                v.sub(call)
            end
        end
        call.reader:cancel()
        call.channel:close()
    end
    log.info('Close connection')
end

local function add_script(self, opts, sub)
    if type(opts) ~= 'table' or type(self) ~= 'table' then
        error("Usage: agi:script({...}, function(cx) ... end)")
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

local function agi_stop(self)
    if type(self) ~= 'table' then
        error('agi cannot stop')
    end

    if self.is_run then
        self.is_run = false
    else
        error('server is already stopped')
    end
    
    if self.tcp_server ~= nil then
        self.tcp_server:close()
        self.tcp_server = nil
    end
    return self
end

local function agi_start(self)
    if type(self) ~= 'table' then
        error('agi cannot start')
    end

    local server = socket.tcp_server(self.host, self.port, { name = 'agi',
        handler = function(...) process_call(self, ...) end})

    rawset(self, 'is_run',     true)
    rawset(self, 'tcp_server', server)
    rawset(self, 'stop',       agi_stop)

    return self
end

local export = {
    new = function(host, port, options)
        if options == nil then
            options = {
                timeout = 1,
            }
        end
        if type(options) ~= 'table' then
            error('Options is not table')
        end
        local self = {
            host    = host,
            port    = port,
            is_run  = false,
            scripts = {},
            start   = agi_start,
            stop    = agi_stop,
            options = options,
            script  = add_script,
        }

        return self
    end
}

return export
