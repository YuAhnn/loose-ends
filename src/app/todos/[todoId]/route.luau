local common = require("common")
local response = common.response
local exception = common.exception
local TodoService = require("../todos.service")

local Todo = {}

--@Guard(AuthGuard)
--@Validator(TodoId)
--@Interceptor(LoadUser)
function Todo.Get(req)
    local todo = TodoService.get(req.params.todoId, req.user.id)

    if not todo then
        error(exception.NotFound("Todo not found"))
    end

    return response.json(todo)
end

--@Guard(AuthGuard)
--@Validator(ReplaceTodo)
--@Interceptor(LoadUser)
function Todo.Put(req)
    local todo = TodoService.update(req.params.todoId, req.user.id, req.body)

    if not todo then
        error(exception.NotFound("Todo not found"))
    end

    return response.json(todo)
end

--@Guard(AuthGuard)
--@Validator(PatchTodo)
--@Interceptor(LoadUser)
function Todo.Patch(req)
    if req.body.title == nil and req.body.completed == nil then
        error(exception.BadRequest("Provide title or completed"))
    end

    local todo = TodoService.update(req.params.todoId, req.user.id, req.body)

    if not todo then
        error(exception.NotFound("Todo not found"))
    end

    return response.json(todo)
end

--@Guard(AuthGuard)
--@Validator(TodoId)
--@Interceptor(LoadUser)
function Todo.Delete(req)
    if not TodoService.delete(req.params.todoId, req.user.id) then
        error(exception.NotFound("Todo not found"))
    end

    return response.json({ message = "Todo deleted" }, { status = 200 })
end

return Todo