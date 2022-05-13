module "interviews" {

  # Specify the "basic" branch
  source = "git@github.com:jbarna/CoderLeaf.git?ref=basic"

  # The key in the candidates map is the name of the candidate
  # This directly influeces the IAM user name and Cloud9 instance name
  candidates = {
    "John Doe" = {

      # The key in the interviewers map is the name of the interviewer
      # With basic usage, the interviewer's name is never shown to the candidate
      # Only the ARN of the interviewers (required for Cloud9 access)
      interviewers = {
        "Michael Scott" = {
          arn = "interviewer_iam_user_arn"
        }

        "Jim Halpert" = {
          arn = "interviewer_iam_user_arn_2"
        }
      }
    }
  }
}

/* Here are the outputs from the module based on the above configuration

candidates = {
  "John Doe" = {
    "candidate_iam_user_name" = "candidate_john_doe"
    "candidate_iam_user_password" = "PLAINTEXT_PASSWORD"
    "cloud9_url" = "https://<REGION>.console.aws.amazon.com/cloud9/ide/<CLOUD9_ID>"
  }
} */