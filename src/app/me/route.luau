local common = require("common")
local response = common.response

local Me = {}

--@Guard(AuthGuard)
--@Interceptor(LoadUser)
function Me.Get(req)
    local user = req.user

    return response.json({
        id = user.id,
        username = user.username,
    })
end

return Me