local Auth = require("../lib/auth")

local function AuthGuard(req)
    return Auth.bearerToken(req.headers and req.headers["authorization"]) ~= nil
end

return AuthGuard