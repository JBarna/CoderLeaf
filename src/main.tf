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
data "aws_caller_identity" "current" {}

resource "aws_ses_template" "main" {
  name    = var.email_template_name
  subject = "Details on your pair programming with {{interviewer_name}}"
  html    = file("${path.module}/email_templates/candidate_invite.html")
  text  = file("${path.module}/email_templates/candidate_invite.txt")
}

resource "aws_iam_policy" "send_email" {
  name = "coderleaf_send_email"
  description = "Policy to allow CoderLeaf's Lambda to send emails to candidates"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "ses:SendTemplatedEmail",
            "Resource": [
                "arn:aws:ses:${data.aws_region.main.name}:${data.aws_caller_identity.current.account_id}:template/${var.email_template_name}",
                "arn:aws:ses:${data.aws_region.main.name}:${data.aws_caller_identity.current.account_id}:identity/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role" "lambda_role" {
  name = "coderleaf_lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "basicExecutionPolicy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "sendEmailPolicy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.send_email.arn
}

resource "aws_lambda_function" "main" {
  # If the file is not in the current working directory you will need to include a 
  # path.module in the filename.
  filename      = "${path.module}/lambda/sendCandidateEmail.zip"
  function_name = "coderleaf_send_email"
  role          = aws_iam_role.lambda_role.arn
  handler       = "sendCandidateEmail.handler"
  timeout = 20 # SES emails take a bit longer than the usual 3 second timeout

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("${path.module}/lambda/sendCandidateEmail.zip")

  runtime = "nodejs14.x"

  # environment {
  #   variables = {
  #     foo = "bar"
  #   }
  # }
}

resource "aws_lambda_invocation" "send_email" {
  function_name = aws_lambda_function.main.function_name

  input = jsonencode({
    ses_region = data.aws_region.main.name, # Assumes they're the same region... I could be wrong here
    candidate_name = var.candidate_name,
    candidate_email = "",
    interviewer_name = "",
    interviewer_email = "",
    cloud9_url = "https://${data.aws_region.main.name}.console.aws.amazon.com/cloud9/ide/${aws_cloud9_environment_ec2.main.id}",
    account_id = data.aws_caller_identity.current.account_id,
    iam_user_name = join("_", concat(["candidate"], [for namePart in regexall("[a-zA-Z]+", var.candidate_name): lower(namePart)])),
    iam_user_password = data.pgp_decrypt.main.plaintext,
    sesTemplateName = var.email_template_name,
    fromEmail = ""
  })
}