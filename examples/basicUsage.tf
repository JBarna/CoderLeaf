module "interview" {

  # Specify the "basic" branch
  source = "git@github.com:jbarna/CoderLeaf.git?ref=basic"

  # The interviews to configure Cloud9 for. All items are required.
  interviews = {

    # The key in the interviews map is the name of the candidate
    # This directly influeces the IAM user name and Cloud9 instance name
    "John Doe" = {

      # The ARN of the interviewers (required for Cloud9 access)
      interviewer_arn = "interviewer_iam_user_arn"
    }
  }
}

/* Here are the outputs from the module based on the above configuration

candidates = {
  "John Doe" = {
    "candidate_iam_user_name" = "candidate_john_doe"
    "candidate_iam_user_password" = "PLAINTEXT_PASSWORD"
    "cloud9_url" = "https://<REGION>.console.aws.amazon.com/cloud9/ide/<CLOUD9_URL>"
  }
} */