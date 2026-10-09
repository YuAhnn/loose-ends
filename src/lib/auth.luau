local common = require("common")
local exception = common.exception
local crypto = require("@lute/crypto")
local D1 = require("./d1")
local Password = require("./password")

local Auth = {}

local LOGIN_BUDGET = 20
local FAIL_MESSAGE = "invalid username or password"
local BEARER_PREFIX = "Bearer "

local function toHex(bytes)
    local out = table.create(buffer.len(bytes))
    for i = 1, buffer.len(bytes) do
        out[i] = string.format("%02x", buffer.readu8(bytes, i - 1))
    end
    return table.concat(out)
end

local function sha256(text)
    return toHex(crypto.digest(crypto.hash.sha256, text))
end

local dummyHash
local function dummyHashValue()
    if not dummyHash then
        dummyHash = Password.hash("dummy-password")
    end
    return dummyHash
end

local attempts = {}
local attemptsMinute = 0

local function limited(key)
    local minute = math.floor(os.time() / 60)
    if minute ~= attemptsMinute then
        attempts = {}
        attemptsMinute = minute
    end

    attempts[key] = (attempts[key] or 0) + 1
    return attempts[key] > LOGIN_BUDGET
end

local function mint(userId)
    local token = toHex(crypto.secretbox.keygen())
    D1.query(
        "INSERT INTO sessions (token_hash, user_id, created_at, expires_at) VALUES (?, ?, datetime('now'), datetime('now', '+30 days'))",
        { sha256(token), userId }
    )
    return token
end

function Auth.bearerToken(header)
    if not header then
        return nil
    end
    if string.sub(header, 1, #BEARER_PREFIX) == BEARER_PREFIX then
        return string.sub(header, #BEARER_PREFIX + 1)
    end
    return nil
end

local function trim(value)
    return value:gsub("^%s+", ""):gsub("%s+$", "")
end

function Auth.register(username, password)
    local name = username and trim(username) or ""

    if #name < 3 or #name > 32 then
        error(exception.BadRequest("username must be 3-32 characters"))
    end
    if not password or #password < Password.MIN or #password > Password.MAX then
        error(exception.BadRequest(`password must be {Password.MIN}-{Password.MAX} characters`))
    end
    if D1.query("SELECT 1 FROM users WHERE username = ?", { name }).rows[1] then
        error(exception.BadRequest("username is taken"))
    end

    local id = D1.query(
        "INSERT INTO users (username, password) VALUES (?, ?) RETURNING id",
        { name, Password.hash(password) }
    ).rows[1].id

    return mint(id), { id = id, username = name }
end

function Auth.login(req, username, password)
    local ip = req.headers and req.headers["x-forwarded-for"] or "local"
    if limited("ip:" .. ip) or limited("user:" .. tostring(username or "")) then
        error(exception.TooManyRequests("too many attempts, try again later"))
    end

    if not username or not password or #password > Password.MAX then
        error(exception.Unauthorized(FAIL_MESSAGE))
    end

    local row = D1.query("SELECT id, username, password FROM users WHERE username = ?", { username }).rows[1]

    local stored
    if row then
        stored = row.password
    else
        stored = dummyHashValue()
    end
    local ok = Password.verify(stored, password)

    if not row or not ok then
        error(exception.Unauthorized(FAIL_MESSAGE))
    end

    local token = mint(row.id)
    Auth.cleanup()
    return token, { id = row.id, username = row.username }
end

function Auth.cleanup()
    D1.query("DELETE FROM sessions WHERE expires_at <= datetime('now')")
end

function Auth.logout(token)
    D1.query("DELETE FROM sessions WHERE token_hash = ?", { sha256(token) })
end

function Auth.getUser(req)
    local token = Auth.bearerToken(req.headers and req.headers["authorization"])
    if not token then
        return nil
    end

    return D1.query(
        "SELECT u.id, u.username FROM sessions s JOIN users u ON u.id = s.user_id "
            .. "WHERE s.token_hash = ? AND s.expires_at > datetime('now')",
        { sha256(token) }
    ).rows[1]
end

return Auth