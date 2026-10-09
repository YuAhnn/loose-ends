local common = require("common")
local response = common.response

local Health = {}

function Health.Get()
    return response.json({
        data = {
            service = "Mayari-Todo-Api",
            status = "Ok",
        },
    })
end

return Health