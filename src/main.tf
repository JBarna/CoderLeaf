locals {
  snakecase_candidate_names = { for candidate_name, value in var.interviews: candidate_name => join("_", concat(["candidate"], [for namePart in regexall("[a-zA-Z]+", candidate_name): lower(namePart)]))}
}

resource "aws_cloud9_environment_ec2" "main" {
  for_each = var.interviews
  instance_type = "t2.micro"
  name          = each.key
  description = "Coding environment for the candidate ${each.key}"
  automatic_stop_time_minutes = 30
#   connection-type = "CONNECT_SSM"
}

# PGP shtuff
resource "pgp_key" "main" {
  for_each = var.interviews
  name    = local.snakecase_candidate_names[each.key]
  email   = each.value["candidate_email"] == null ? "${local.snakecase_candidate_names[each.key]}@gmail.com" : each.value["candidate_email"]
  comment = "Generated PGP Key for Candidate ${each.key}"
}

resource "aws_iam_user" "main" {
    for_each = var.interviews
    name = local.snakecase_candidate_names[each.key]
}

resource "aws_iam_user_policy" "main" {
    for_each = var.interviews
    name ="cloud9_policy_${local.snakecase_candidate_names[each.key]}"
    user = aws_iam_user.main[each.key].name

    # Limited the Resource to the cloud 9 instance which works when going to the URL directly, but
    # Ruins the UI for some reason. But we don't want the candidate to see all the other cloud9 instances
    # In the Account so this is the interm solution.
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloud9:ValidateEnvironmentName",
                "cloud9:UpdateUserSettings",
                "cloud9:GetUserSettings",
                "cloud9:DescribeEnvironmentMemberships",
                "cloud9:DescribeEnvironments",
                "cloud9:ListEnvironments"
            ],
            "Resource": "${aws_cloud9_environment_ec2.main[each.key].arn}"
        }
    ]
}
EOF
}

resource "aws_iam_user_login_profile" "main" {
  for_each = var.interviews
  user    = aws_iam_user.main[each.key].name
  password_length = 12
  password_reset_required = false
  pgp_key = pgp_key.main[each.key].public_key_base64
}

# will have to see if we have to add membership to the other user too...
resource "aws_cloud9_environment_membership" "candidate" {
  for_each = var.interviews
  environment_id = aws_cloud9_environment_ec2.main[each.key].id
  permissions    = "read-write"
  user_arn       = aws_iam_user.main[each.key].arn
}

resource "aws_cloud9_environment_membership" "interviewer" {
  for_each = var.interviews
  environment_id = aws_cloud9_environment_ec2.main[each.key].id
  permissions    = "read-write"
  user_arn       = each.value["interviewer_arn"]
}

# ========== USER PASSWORD ==========================
data "pgp_decrypt" "main" {
  for_each = var.interviews
  ciphertext  = aws_iam_user_login_profile.main[each.key].encrypted_password
  private_key = pgp_key.main[each.key].private_key
  ciphertext_encoding = "base64"
}

# resource "aws_lambda_invocation" "send_candidate_email" {
#   function_name = aws_lambda_function.main.function_name

#   input = jsonencode({
#     ses_region = var.ses_region == null ? data.aws_region.main.name : var.ses_region,
#     toAddress = var.candidate_email
#     bccAddress = var.interviewer_email
#     sesTemplateName = var.candidate_email_template_name == null ? aws_ses_template.candidate_invite[0].name : var.candidate_email_template_name,
#     fromEmail = var.fromEmail

#     emailTemplateData = {
#       candidate_name = var.candidate_name
#       interviewer_name = var.interviewer_name
#       cloud9_url = "https://${data.aws_region.main.name}.console.aws.amazon.com/cloud9/ide/${aws_cloud9_environment_ec2.main.id}",
#       account_id = data.aws_caller_identity.current.account_id,
#       iam_user_name = join("_", concat(["candidate"], [for namePart in regexall("[a-zA-Z]+", var.candidate_name): lower(namePart)])),
#       iam_user_password = data.pgp_decrypt.main.plaintext,
#     }
#   })
# }

# resource "aws_lambda_invocation" "send_interviewer_email" {
#   function_name = aws_lambda_function.main.function_name

#   input = jsonencode({
#     ses_region = var.ses_region == null ? data.aws_region.main.name : var.ses_region,
#     toAddress = var.interviewer_email
#     sesTemplateName =var.interviewer_email_template_name == null ? aws_ses_template.interviewer_invite[0].name : var.interviewer_email_template_name,
#     fromEmail = var.fromEmail

#     emailTemplateData = {
#       candidate_name = var.candidate_name
#       interviewer_name = var.interviewer_name
#       cloud9_url = "https://${data.aws_region.main.name}.console.aws.amazon.com/cloud9/ide/${aws_cloud9_environment_ec2.main.id}",
#       account_id = data.aws_caller_identity.current.account_id,
#       iam_user_name = join("_", concat(["candidate"], [for namePart in regexall("[a-zA-Z]+", var.candidate_name): lower(namePart)])),
#       iam_user_password = data.pgp_decrypt.main.plaintext,
#     }
#   })
# }