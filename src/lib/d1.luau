local common = require("common")
local exception = common.exception
local D1Client = require("d1client")
local process = require("@lute/process")

local D1 = {}
local client = nil

local function config()
    local account = process.env.ACCOUNTID
    local token = process.env.API_TOKEN
    local db = process.env.ID

    if not account or not token or not db then
        error("D1 is not configured (ACCOUNTID, API_TOKEN, ID in .env)")
    end

    return account, token, db
end

local function clientFor()
    if client == nil then
        local account, token, db = config()
        client = D1Client.new(account, db, token)
            :andThen(function() 
                print("D1 Database initialized")
            end)
            :catch(function(err)
                error(err) 
            end)
    end
    return client
end

function D1.query(sql, params)
    local res = clientFor():query(sql, params or {})

    if not res.success then
        local err = res.errors and res.errors[1]
        error(exception.InternalServerError(`D1 error: {if err then err.message else "unknown"}`))
    end

    return {
        rows = res.results or {},
    }
end

return D1