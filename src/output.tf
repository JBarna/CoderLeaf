## TODO once we get the region
# output "cloud9_url" {
#   value = "https://${var.region}.console.aws.amazon.com/cloud9/ide/${aws_cloud9_environment_ec2.example.id}"
# }

# URL of the cloud9 url
output "cloud9_url" {
  value = "https://${data.aws_region.main.name}.console.aws.amazon.com/cloud9/ide/${aws_cloud9_environment_ec2.main.id}"
}

output "candidate_password" {
    value = data.pgp_decrypt.main.plaintext
}

# output "email_result" {
#   value = jsondecode(aws_lambda_invocation.send_email.result)["body"]
# }