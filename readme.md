# CoderLeaf
An open source alternative to online coding interview tools using AWS Cloud9.

## Basic Usage
Pass the candidate's name to this Terraform module, then `terraform apply`. A new Cloud9 instance will be created alongside a unique IAM User which only has permissions to access Cloud9.

```
module "interview_john_brown" {
    source = "git@github.com:jbarna/CoderLeaf.git"
    candidate_name = "John Brown"
}
```

The default values for the IAM User Name will be "JohnBrownInterview", and the password will be "JohnBrownInterview1!". The Cloud9 instance will be called "John Brown Interview"

## Email log-in instructions
CoderLeaf can send log-in instructions via email by utilizing Amazon SES. A default template is provided, however a custom email template can also be provided assuming it has the correct variables.

```
module "interview_john_brown" {
    ...
    candidateEmail = "johnbrown@gmail.com"

    # Optionally provide the interviewer's name in the email 
    # And send a copy to the interviewer as well
    interviewerEmail = "intervierwer@mycompany.com"
    interviewerName = "Richard Brandson"
    
    # Optional email template
    emailTemplate = aws_ses_template.my_custom_interview_email_template
}
```

## Creating a Shared Terminal
Terminal executions are not sharable to others in the Cloud9 session, making it difficult for the interviewer to view what the candidate is receiving from the program as they execute their code. The terminal also removes the output from previous executions, making it difficult for the candidate to view previous executions.

These issues can be solved by instead running the program through [this bash script](utilities/run.sh), which saves all output to `out.log`.

```bash
#!/bin/bash

command="node js/index.js" # <== Change this
log_file="./out.log"
timestamp=$(TZ=EST date +%T_%Z)

echo "" >> $log_file
echo "============================ $timestamp ============================" >> $log_file

$command 2>&1 | tee -a "$log_file"

```

## All Options
```
module "interview_john_brown" {
    source = "git@github.com:jbarna/CoderLeaf.git"
    candidate_name = "John Brown"

    # IAM User Permission Options
    username = <>
    password = <>
    start_time = <> # When start time and length are specified the candidate's permissions
    length = <>     # will automatically expire when the interview is over

    # Config Options
    cloud9_instance_name = <>
    ec2_size = <>
    vpc = <>
    subnet = <>
    
    # Email options
    emails = ["johnbrown@gmail.com", "interviewer@yourcompany.com"]
    emailTemplate = emailTemplate = aws_ses_template.my_custom_interview_email_template
}
```