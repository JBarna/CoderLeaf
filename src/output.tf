output "interviews" {
  description = "Cloud9 instance and candidate login information for interviews"
  value = {for key, value in var.interviews: key => {
      cloud9_url = "https://${data.aws_region.main.name}.console.aws.amazon.com/cloud9/ide/${aws_cloud9_environment_ec2.main[key].id}"
      candidate_iam_user_name = aws_iam_user.main[key].name
      candidate_iam_user_password = data.pgp_decrypt.main[key].plaintext
    }
  }
}