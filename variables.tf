variable candidates {
    type = map(object({
        interviewers = map(object({
            arn = string
        }))
    }))
}

