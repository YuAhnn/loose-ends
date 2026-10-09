local common = require("common")
local response = common.response
local TodoService = require("./todos.service")

local Todos = {}

--@Guard(AuthGuard)
--@Interceptor(LoadUser)
function Todos.Get(req)
    local user = req.user

    return response.json(TodoService.list(user.id))
end

--@Guard(AuthGuard)
--@Validator(CreateTodo)
--@Interceptor(LoadUser)
function Todos.Post(req)
    local user = req.user
    local todo = TodoService.create(user.id, req.body)

    return response.json(todo, { status = 201 })
end

return Todos