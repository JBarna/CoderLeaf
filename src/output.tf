output "interviews" {
  description = "Cloud9 instance and candidate login information for interviews"
  value = {for candidate_name, interview_info in var.candidates: candidate_name => {
      cloud9_url = "https://${data.aws_region.main.name}.console.aws.amazon.com/cloud9/ide/${aws_cloud9_environment_ec2.main[candidate_name].id}"
      candidate_iam_user_name = aws_iam_user.main[candidate_name].name
      candidate_iam_user_password = data.pgp_decrypt.main[candidate_name].plaintext
    }
  }
}