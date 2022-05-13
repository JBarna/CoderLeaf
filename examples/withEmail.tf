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
  fromEmail = "no-reply@yoursubdomain.yourdomain.com"

  # An optional SES template name to use instead of the default emails
  candidate_email_template_name = "my_candidate_template_name"
  interviewer_email_template_name = "my_interviewer_template_name"

  # The key in the candidates map is the name of the candidate
  # This directly influeces the IAM user name and Cloud9 instance name
  candidates = {
    "John Doe" = {

      # The email address of the candidate
      candidate_email = "candidate_email@domain.com"

      # The key in the interviewers map is the name of the interviewer
      # The interviewer's name is used in the emails to the candidate
      interviewers = {
        "Michael Scott" = {
          arn = "interviewer_iam_user_arn" # Used to grant access to Cloud 9

          # Candidate is emailed directly and BCC'd on the email to the candidate
          email = "interviewer_email@your_company_domain.com"
        }

        "Jim Halpert" = {
          arn = "interviewer_iam_user_arn_2"
          email = "second_interviewer@your_company_domain.com"
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