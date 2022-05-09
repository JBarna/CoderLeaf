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

variable interviews {
    type = map(object({
        candidate_email = string
        interviewer_name = string
        interviewer_email = string
        interviewer_arn = string
    }))
}