locals {
  snakecase_candidate_names = { for candidate_name, value in var.interviews: candidate_name => join("_", concat(["candidate"], [for namePart in regexall("[a-zA-Z]+", candidate_name): lower(namePart)]))}
}

data "aws_region" "main" {}

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
  email   = "${local.snakecase_candidate_names[each.key]}@gmail.com"
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