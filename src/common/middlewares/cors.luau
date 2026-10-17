local common = require("common")
local response = common.response

local CORS_HEADERS = {
    ["Access-Control-Allow-Origin"] = "*",
    ["Access-Control-Allow-Methods"] = "GET, POST, PUT, PATCH, DELETE, OPTIONS",
    ["Access-Control-Allow-Headers"] = "Content-Type, Authorization",
    ["Access-Control-Max-Age"] = "86400",
}

local function addCors(headers)
    for name, value in CORS_HEADERS do
        headers[name] = value
    end
    return headers
end

local function cors(req, next)
    if req.method == "OPTIONS" then
        return response.send("", { status = 204, headers = addCors({}) })
    end

    local ok, res = pcall(next)

    if not ok then
        if typeof(res) ~= "table" then
            error(res)
        end

        return response.json(
            { error = res.message or "Internal Server Error" },
            { status = res.statusCode or 500, headers = addCors({ ["Content-Type"] = "application/json" }) }
        )
    end

    res.config.headers = addCors(res.config.headers or {})
    return res
end

return cors
