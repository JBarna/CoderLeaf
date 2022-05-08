variable "candidate_name" {
  description = "The name of the candidate"
  type = string
}


variable "interviewer_arn" {
    description = "The ARN of the interviewer, so they can have access to the Cloud9 Instance"
    type = string
}

variable candidate {
    type = list(object({
        name = string
        email = optional(string)
    }))
}

variable email_template_name {
    type = string
    default = "DefaultCodingInterviewTemplate"
}