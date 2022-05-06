variable "candidate_name" {
  description = "The name of the candidate"
  type = string
}

variable "interviewer_arn" {
    description = "The ARN of the interviewer, so they can have access to the Cloud9 Instance"
    type = string
}
