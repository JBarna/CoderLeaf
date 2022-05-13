locals {
  snakecase_candidate_names = { for candidate_name, interview_info in var.candidates: candidate_name => join("_", concat(["candidate"], [for namePart in regexall("[a-zA-Z]+", candidate_name): lower(namePart)]))}

  # Creates a map with an index for each individual relationship between a candidate
  # And their interviewer, which is necessary to create all resources for the interviewers
  flattened_relationships = {for relationship in flatten(
    [for candidate_name, interview_info in var.candidates:
      [for interviewer_name, interviewer_info in interview_info.interviewers: {
        candidate_name: candidate_name,
        interviewer_name: interviewer_name
        interviewer_arn: interviewer_info.arn
      }]
    ]
  ): "${relationship.candidate_name}.${relationship.interviewer_name}" => relationship}

  # Create an index for candidates with start times specified to avoid 
  # Creating unused resources 
  # candidates_with_times = {for candidate_name in flatten(
  #   [for candidate_name, interview_info in var.candidates: interview_info.start_time == null ? [] : [candidate_name]]
  # ): candidate_name => true}
}

data "aws_region" "main" {}

resource "aws_cloud9_environment_ec2" "main" {
  for_each = var.candidates
  instance_type = "t2.micro"
  name          = each.key
  description = "Coding environment for the candidate ${each.key}"
  automatic_stop_time_minutes = 30
}

# PGP shtuff
resource "pgp_key" "main" {
  for_each = var.candidates
  name    = local.snakecase_candidate_names[each.key]
  email   = "${local.snakecase_candidate_names[each.key]}@gmail.com"
  comment = "Generated PGP Key for Candidate ${each.key}"
}

resource "aws_iam_user" "main" {
    for_each = var.candidates
    name = local.snakecase_candidate_names[each.key]
}

resource "aws_iam_user_policy" "main" {
    for_each = var.candidates
    name ="cloud9_policy_${local.snakecase_candidate_names[each.key]}"
    user = aws_iam_user.main[each.key].name

    # Limited the Resource to the cloud 9 instance which works when going to the URL directly, but
    # Ruins the UI for some reason. But we don't want the candidate to see all the other cloud9 instances
    # In the Account so this is the interm solution.
    policy = templatefile("${path.module}/permissions/${var.candidates[each.key].start_time == null ? "basic" : "withTime"}.json.tmpl",
      {
        cloud9_arn = aws_cloud9_environment_ec2.main[each.key].arn
        start_time = var.candidates[each.key].start_time
        end_time = var.candidates[each.key].start_time == null ? "" : timeadd(var.candidates[each.key].start_time, var.candidates[each.key].duration)
      }
    )
}

resource "aws_iam_user_login_profile" "main" {
  for_each = var.candidates
  user    = aws_iam_user.main[each.key].name
  password_length = 12
  password_reset_required = false
  pgp_key = pgp_key.main[each.key].public_key_base64
}

# will have to see if we have to add membership to the other user too...
resource "aws_cloud9_environment_membership" "candidate" {
  for_each = var.candidates
  environment_id = aws_cloud9_environment_ec2.main[each.key].id
  permissions    = "read-write"
  user_arn       = aws_iam_user.main[each.key].arn
}

resource "aws_cloud9_environment_membership" "interviewer" {
  for_each = local.flattened_relationships
  environment_id = aws_cloud9_environment_ec2.main[each.value.candidate_name].id
  permissions    = "read-write"
  user_arn       = each.value.interviewer_arn
}

# ========== USER PASSWORD ==========================
data "pgp_decrypt" "main" {
  for_each = var.candidates
  ciphertext  = aws_iam_user_login_profile.main[each.key].encrypted_password
  private_key = pgp_key.main[each.key].private_key
  ciphertext_encoding = "base64"
}