local crypto = require("@lute/crypto")

local Password = {}

Password.MIN = 8
Password.MAX = 128

function Password.hash(password)
    if #password > Password.MAX then
        error(`password too long (max {Password.MAX} characters)`, 2)
    end

    local stored = buffer.tostring(crypto.password.hash(password))
    local nul = string.find(stored, "\0", 1, true)

    if nul then
        stored = string.sub(stored, 1, nul - 1)
    end

    return stored
end

function Password.verify(stored, password)
    return crypto.password.verify(buffer.fromstring(stored), password)
end

return Password