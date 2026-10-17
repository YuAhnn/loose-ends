return {
    body = {
        title = {
            type = "string",
            required = true,
            min = 1,
            max = 100,
        },
        completed = {
            type = "boolean",
            required = false,
        },
    },
}
