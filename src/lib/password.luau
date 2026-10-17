local crypto = require("@lute/crypto")
local process = require("@lute/process")

local Password = {}

Password.MIN = 8
Password.MAX = 128

local ITERATIONS = tonumber(process.env.PASSWORD_ITERATIONS) or 60000
local SALT_BYTES = 16
local KEY_BYTES = 32
local BLOCK_BYTES = 64
local SHA256 = crypto.hash.sha256

local function toHex(bytes)
    local hex = {}
    for i = 0, buffer.len(bytes) - 1 do
        table.insert(hex, string.format("%02x", buffer.readu8(bytes, i)))
    end
    return table.concat(hex)
end

local function fromHex(hex)
    local bytes = buffer.create(#hex // 2)
    for i = 0, buffer.len(bytes) - 1 do
        buffer.writeu8(bytes, i, tonumber(string.sub(hex, i * 2 + 1, i * 2 + 2), 16))
    end
    return bytes
end

local function concat(a, b)
    local out = buffer.create(buffer.len(a) + buffer.len(b))
    buffer.copy(out, 0, a, 0, buffer.len(a))
    buffer.copy(out, buffer.len(a), b, 0, buffer.len(b))
    return out
end

local function hmac(key, message)
    key = buffer.fromstring(key)
    if buffer.len(key) > BLOCK_BYTES then
        key = crypto.digest(SHA256, key)
    end

    local ipad = buffer.create(BLOCK_BYTES)
    local opad = buffer.create(BLOCK_BYTES)
    buffer.fill(ipad, 0, 0x36, BLOCK_BYTES)
    buffer.fill(opad, 0, 0x5c, BLOCK_BYTES)
    for i = 0, buffer.len(key) - 1 do
        local byte = buffer.readu8(key, i)
        buffer.writeu8(ipad, i, bit32.bxor(byte, 0x36))
        buffer.writeu8(opad, i, bit32.bxor(byte, 0x5c))
    end

    local inner = crypto.digest(SHA256, concat(ipad, message))
    return crypto.digest(SHA256, concat(opad, inner))
end

local function pbkdf2(password, salt, iterations)
    local seed = concat(salt, buffer.fromstring("\0\0\0\1"))
    local step = hmac(password, seed)
    local derived = buffer.create(KEY_BYTES)
    buffer.copy(derived, 0, step, 0, KEY_BYTES)

    for _ = 2, iterations do
        step = hmac(password, step)
        for i = 0, KEY_BYTES // 4 - 1 do
            local offset = i * 4
            buffer.writeu32(derived, offset, bit32.bxor(buffer.readu32(derived, offset), buffer.readu32(step, offset)))
        end
    end

    return derived
end

function Password.hash(password)
    if #password > Password.MAX then
        error(`password too long (max {Password.MAX} characters)`, 2)
    end

    local salt = buffer.create(SALT_BYTES)
    buffer.copy(salt, 0, crypto.secretbox.keygen(), 0, SALT_BYTES)
    local derived = pbkdf2(password, salt, ITERATIONS)

    return table.concat({ "pbkdf2-sha256", ITERATIONS, toHex(salt), toHex(derived) }, "$")
end

function Password.verify(stored, password)
    if type(stored) ~= "string" or type(password) ~= "string" then
        return false
    end

    local iterations, saltHex, keyHex = string.match(stored, "^pbkdf2%-sha256%$(%d+)%$([0-9a-f]+)%$([0-9a-f]+)$")
    if not iterations or #keyHex ~= KEY_BYTES * 2 then
        return false
    end

    local derived = pbkdf2(password, fromHex(saltHex), tonumber(iterations))
    local expected = fromHex(keyHex)

    local diff = 0
    for i = 0, KEY_BYTES // 4 - 1 do
        diff = bit32.bor(diff, bit32.bxor(buffer.readu32(derived, i * 4), buffer.readu32(expected, i * 4)))
    end
    return diff == 0
end

return Password
