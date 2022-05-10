module "interview" {

  # Specify the "basic" branch
  source = "git@github.com:jbarna/CoderLeaf.git?ref=withEmail"

  # SES quota limitations are per region, and generally result in SES resources
  # Being located in a specific region that is different than other resources.
  # To support this, a separate AWS provider for SES resources is required by the module.
  providers = {
    aws.ses = aws # If SES resources are in the same region as everything else, just pass the default aws provider
  }

  # (Optional if aws.ses is default aws provider)
  # The SES region to send emails from
  ses_region = "us-east-2"

  # The email address to send email invitations from
  # The domain must be a verified identiy on SES
  fromEmail = "no-reply@codenotifications.thesmartbasket.com"

  # The interviews to configure Cloud9 for. All items are required.
  interviews = {
    
    # The key in the interviews map is the name of the candidate
    # This directly influeces the IAM user name and Cloud9 instance name
    "John Doe" = {

      # The email address of the candidate
      candidate_email = "candidate_email@domain.com"

      # The name of the interviewer (used in the email invite)
      interviewer_name = "Jane Doe"

      # The email address of the interviewer for the email invite
      interviewer_email = "interviewer_email@your_company_domain.com"

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