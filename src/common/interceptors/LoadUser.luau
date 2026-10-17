local Auth = require("../../lib/auth")
local exception = require("common").exception

local function LoadUser(req, next)
    local user = Auth.getUser(req)

    if not user then
        error(exception.Unauthorized())
    end

    req.user = user
    next()
end

return LoadUser