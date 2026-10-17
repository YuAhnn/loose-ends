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
            required = false,
            min = 1,
            max = 100,
        },
        completed = {
            type = "boolean",
            required = false,
        },
    },
}
