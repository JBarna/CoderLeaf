variable "fromEmail" {
    type = string
}

variable candidate_email_template_name {
    type = string
    default = null
}

variable interviewer_email_template_name {
    type = string
    default = null
}

variable ses_region {
    type = string
    default = null
}

variable candidates {
    type = map(object({
        candidate_email = string
        interviewers = map(object({
            arn = string
            email = string
        }))
    }))
}