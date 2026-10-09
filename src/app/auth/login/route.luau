local common = require("common")
local response = common.response
local Auth = require("../../../lib/auth")

local Login = {}

function Login.Post(req)
    local body = req.body
    local token, user = Auth.login(req, body and body.username, body and body.password)

    return response.json({
        token = token,
        user = user,
    })
end

return Login