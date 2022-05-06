resource "aws_cloud9_environment_ec2" "main" {
  instance_type = "t2.micro"
  name          = var.candidate_name
  description = "Coding environment for the candidate ${var.candidate_name}"
  automatic_stop_time_minutes = 30
  owner_arn = aws_iam_user.main.arn
#   connection-type = "CONNECT_SSM"
}

# PGP shtuff
resource "pgp_key" "main" {
  name    = join("_", concat(["candidate"], [for namePart in regexall("[a-zA-Z]+", var.candidate_name): lower(namePart)]))
  email   = "jdoe@exammple.com"
  comment = "Generated PGP Key for Candidate"
}

resource "aws_iam_user" "main" {
    name = join("_", concat(["candidate"], [for namePart in regexall("[a-zA-Z]+", var.candidate_name): lower(namePart)]))
}

resource "aws_iam_user_policy" "main" {
    name ="cloud9_policy"
    user = aws_iam_user.main.name

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
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_user_login_profile" "main" {
  user    = aws_iam_user.main.name
  password_length = 12
  password_reset_required = false
  pgp_key = pgp_key.main.public_key_base64
}


# will have to see if we have to add membership to the other user too...
resource "aws_cloud9_environment_membership" "main" {
  environment_id = aws_cloud9_environment_ec2.main.id
  permissions    = "read-write"
  user_arn       = var.interviewer_arn
}

# ========== USER PASSWORD ==========================
data "pgp_decrypt" "main" {
  ciphertext  = aws_iam_user_login_profile.main.encrypted_password
  private_key = pgp_key.main.private_key
  ciphertext_encoding = "base64"
}

data "aws_region" "main" {}