variable "candidate_name" {
  description = "The name of the candidate"
  type = string
}

variable "candidate_email" {
    type = string
}

variable "interviewer_email" {
    type = string
}

variable "interviewer_name" {
    type = string
}

variable "fromEmail" {
    type = string
}

variable "interviewer_arn" {
    description = "The ARN of the interviewer, so they can have access to the Cloud9 Instance"
    type = string
}

variable interviews {
    type = list(object({
        candidate_name = string
        candidate_email = string
        interviewer_name = string
        interviewer_email = string
        interviewer_arn = string
    }))
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