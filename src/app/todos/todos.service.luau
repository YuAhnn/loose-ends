local D1 = require("../../lib/d1")

local TodoService = {}

local function rowToTodo(row)
    return {
        id = tostring(row.id),
        userId = row.user_id,
        title = row.title,
        completed = row.completed == 1,
    }
end

function TodoService.list(userId)
    local result = {}

    for _, row in D1.query("SELECT id, user_id, title, completed FROM todos WHERE user_id = ?", { userId }).rows do
        table.insert(result, rowToTodo(row))
    end

    return result
end

function TodoService.get(id, userId)
    local rows =
        D1.query("SELECT id, user_id, title, completed FROM todos WHERE id = ? AND user_id = ?", { id, userId }).rows

    if #rows == 0 then
        return nil
    end

    return rowToTodo(rows[1])
end

function TodoService.create(userId, data)
    local rows = D1.query(
        "INSERT INTO todos (user_id, title, completed) VALUES (?, ?, ?) RETURNING id, user_id, title, completed",
        { userId, data.title, if data.completed == true then 1 else 0 }
    ).rows

    return rowToTodo(rows[1])
end

function TodoService.update(id, userId, data)
    local sets = {}
    local params = {}

    if data.title ~= nil then
        table.insert(sets, "title = ?")
        table.insert(params, data.title)
    end

    if data.completed ~= nil then
        table.insert(sets, "completed = ?")
        table.insert(params, if data.completed then 1 else 0)
    end

    if #sets == 0 then
        return TodoService.get(id, userId)
    end

    table.insert(params, id)
    table.insert(params, userId)
    local rows = D1.query(
        `UPDATE todos SET {table.concat(sets, ", ")} WHERE id = ? AND user_id = ? RETURNING id, user_id, title, completed`,
        params
    ).rows

    if #rows == 0 then
        return nil
    end

    return rowToTodo(rows[1])
end

function TodoService.delete(id, userId)
    local rows = D1.query(
        "DELETE FROM todos WHERE id = ? AND user_id = ? RETURNING id, user_id, title, completed",
        { id, userId }
    ).rows

    if #rows == 0 then
        return nil
    end

    return rowToTodo(rows[1])
end

return TodoService