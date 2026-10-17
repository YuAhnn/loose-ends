local Mayari = require("mayari")
local process = require("@lute/process")
local cors = require("./common/middlewares/cors")

local PORT = tonumber(process.env.PORT) or 8080

local app = Mayari.new(PORT, { cors })
local Db = require("./config/db")

Db.init()

app:listen(function()
    print(`Mayari is running on Port {PORT}`)
end)
