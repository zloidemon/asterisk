package = "asterisk"
version = "scm-1"
source = {
    url    = "git://github.com/zloidemon/asterisk.git",
    branch = "master",
}
description = {
    summary    = "Asterisk Interfaces for Tarantool",
    homepage   = "https://github.com/zloidemon/asterisk",
    license    = "BSD",
    maintainer = "Veniamin Gvozdikov <g.veniamin@googlemail.com>"
}
dependencies = {
    "lua >= 5.1"
}
build = {
    type = "builtin",
    modules = {
        ["asterisk.agi.app"]       = "asterisk/agi/app.lua",
        ["asterisk.agi.init"]      = "asterisk/agi/init.lua",
        ["asterisk.agi.variables"] = "asterisk/agi/variables.lua",
        ["asterisk.ami.actions"]   = "asterisk/ami/actions.lua",
        ["asterisk.ami.init"]      = "asterisk/ami/init.lua",
    }
}

-- vim: syntax=lua
