local common = require("common")
local response = common.response
local Auth = require("../../../lib/auth")

local Register = {}

function Register.Post(req)
    local body = req.body
    local token, user = Auth.register(body and body.username, body and body.password)

    return response.json({
        token = token,
        user = user,
    }, { status = 201 })
end

return Register