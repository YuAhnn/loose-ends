local common = require("common")
local response = common.response
local Auth = require("../../../lib/auth")

local Logout = {}

function Logout.Post(req)
    local body = req.body
    local token = body and body.token or ""

    if token ~= "" then
        Auth.logout(token)
    end

    return response.json({ ok = true })
end

return Logout