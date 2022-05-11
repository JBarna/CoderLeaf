data "aws_region" "main" {}
data "aws_caller_identity" "current" {}

resource "aws_ses_template" "candidate_invite" {
  provider = aws.ses
  count = var.candidate_email_template_name == null ? 1 : 0
  name    = "coderleaf_candidate_email_invite"
  subject = "Details on your pair programming with {{interviewer_name}}"
  html    = file("${path.module}/email_templates/candidate_invite.html")
  text    = file("${path.module}/email_templates/candidate_invite.txt")
}

resource "aws_ses_template" "interviewer_invite" {
  provider = aws.ses
  count = var.interviewer_email_template_name == null ? 1 : 0
  name    = "coderleaf_interviewer_email_invite"
  subject = "Details on your interview with {{candidate_name}}"
  html    = file("${path.module}/email_templates/interviewer_invite.html")
  text    = file("${path.module}/email_templates/interviewer_invite.txt")
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
                "arn:aws:ses:${data.aws_region.main.name}:${data.aws_caller_identity.current.account_id}:template/${var.candidate_email_template_name == null ? aws_ses_template.candidate_invite[0].name : var.candidate_email_template_name}",
                "arn:aws:ses:${data.aws_region.main.name}:${data.aws_caller_identity.current.account_id}:template/${var.interviewer_email_template_name == null ? aws_ses_template.interviewer_invite[0].name : var.interviewer_email_template_name}",
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
  filename      = "${path.module}/functions/sendCoderleafEmail.zip"
  function_name = "coderleaf_send_email"
  role          = aws_iam_role.lambda_role.arn
  handler       = "sendCoderleafEmail.handler"
  timeout = 20 # SES emails take a bit longer than the usual 3 second timeout

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "nodejs14.x"

  # environment {
  #   variables = {
  #     foo = "bar"
  #   }
  # }
}

data "archive_file" "lambda" {
  type             = "zip"
  source_file      = "${path.module}/functions/sendCoderleafEmail.js"
  output_file_mode = "0666"
  output_path      = "${path.module}/functions/sendCoderleafEmail.zip"
}
