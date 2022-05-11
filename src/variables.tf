variable candidates {
    type = map(object({
        starting_time = optional(string)
        duration = optional(string)

        interviewers = map(object({
            arn = string
        }))
    }))
}

