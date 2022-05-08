exports.handler = async (event) => {
    
    const {
        ses_region,
        candidate_name,
        candidate_email,
        interviewer_name,
        interviewer_email,
        cloud9_url,
        account_id,
        iam_user_name,
        iam_user_password,
        sesTemplateName,
        fromEmail
    } = event
    
    const AWS = require('aws-sdk');
    AWS.config.update({region: ses_region});
    
    const templateData = JSON.stringify({
        candidate_name,
        interviewer_name,
        cloud9_url,
        account_id,
        iam_user_name,
        iam_user_password
    })
    
    // Create sendTemplatedEmail params 
    const params = {
      Destination: {
        ToAddresses: [candidate_email],
        BccAddresses: [interviewer_email]
      },
      Source: fromEmail, //'no-reply@codenotifications.thesmartbasket.com',
      Template: sesTemplateName, //'DefaultCodingInterviewTemplate'
      TemplateData: templateData
    };
    
    let sendPromise = null
    const response = {
        statusCode: 200,
        body: 'Success',
    };

    // Create the promise and SES service object
    try {
        sendPromise = await (new AWS.SES({apiVersion: '2010-12-01'}).sendTemplatedEmail(params).promise());
        response.body = JSON.stringify(sendPromise)
    } catch (e) {
        console.log('houston, we have a problem', e)
        response.body = JSON.stringify(e)
    }

    return response;
};