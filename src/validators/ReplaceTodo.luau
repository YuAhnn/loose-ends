return {
    params = {
        todoId = {
            required = true,
            pattern = "^%d+$",
        },
    },
    body = {
        title = {
            type = "string",
            required = true,
            min = 1,
            max = 100,
        },
        completed = {
            type = "boolean",
            required = true,
        },
    },
}
