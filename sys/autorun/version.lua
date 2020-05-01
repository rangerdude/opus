local Config = require('opus.config')
local Util   = require('opus.util')

local fs    = _G.fs
local shell = _ENV.shell

local URL = 'https://raw.githubusercontent.com/kepler155c/opus/%s/.opus_version'

if fs.exists('.opus_version') then
    local f = fs.open('.opus_version', 'r')
    local date = f.readLine()
    f.close()
    date = type(date) == 'string' and Util.split(date)[1]

    if type(date) == 'string' and #date > 0 then
        local today = os.date('%j')
        local config = Config.load('version', {
            opus = date,
            packages = date,
            checked = today,
        })

        -- check if packages need an update
        if config.opus ~= config.packages then
            config.packages = config.opus
            Config.update('version', config)
            print('Updating packages')
            shell.run('package updateall')
            os.reboot()
        end

        if config.checked ~= today then
            config.checked = today
            Config.update('version', config)
            print('Checking for new version')
            pcall(function()
                local c = Util.httpGet(string.format(URL, _G.OPUS_BRANCH))
                if c then
                    c = Util.split(c)[1]
                    if config.opus ~= c and config.skip ~= c then
                        config.current = c
                        Config.update('version', config)
                        print('New version available')
                        if _ENV.multishell then
                            shell.openForegroundTab('sys/apps/Version.lua')
                        end
                    end
                end
            end)
        end
    end
end