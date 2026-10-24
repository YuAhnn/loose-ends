local common = require("common")
local response = common.response

local Health = {}

function Health.Get()
    return response.json({
        api = {
            msg = "Mayari-Todo-Api",
            status = "ok",
        },
    })
end

return Health