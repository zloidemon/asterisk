# Asterisk Interfaces for Tarantool

## `AGI` - Asterisk Gateway Interface

Example:

```
[example]
exten => _X.,1,AGI(agi://127.0.0.1:3000/example)
```

```
require('console').listen(33014)
log = require('log')

box.cfg{
    listen= 33013,
    slab_alloc_arena = 0.3,
}

local function ex(self)
    self:wait(nil, 3)
    	:set_callerid(nil, 12345)
	:dial(nil, 'SIP/%s',  self['agi_extension'])
    return self
end

agid = require('asterisk.agi')
srv = agid.new('0.0.0.0', 3000)
    :script({path = '/example'}, ex)
    :start()
```

# `AMI` - Asterisk Manager API

Example:

```
[tarantool]
secret = tarantool
deny = 0.0.0.0/0.0.0.0
permit = 127.0.0.1/255.255.252.0
read = system,call,log,verbose,command,agent,user,originate
write = system,call,log,verbose,command,agent,user,originate
```

```
require('console').listen(33014)
log = require('log')

box.cfg{
    listen= 33013,
    slab_alloc_arena = 0.3,
}

local function pinger(self)
    local data = self:ping()
    if data then
        for k, v in pairs(data) do
            log.info('[pinger] %s:%s', k, v)
        end
    else
        log.error('nodata')
    end
end

local function catch_event(data)
    for k, v in pairs(data) do
        log.info("[event]: %s:%s", k, v)
    end
end

api = require('asterisk.ami')
srv = api.new('127.0.0.1', 5038, {name='ami_service', ipc={timeout = 6}})
    :script({path='ping'}, pinger)
    :event(catch_event)
    :connect('tarantool','tarantool')
```

Testing:

```
> nc 127.0.0.1 33014
Tarantool 1.6.7-523-g816224e (Lua console)                     
type 'help' for interactive help                               

---
...
s:run('ping')
---
...
```

And see to application logs.
