exports.handler = async (event) => {
    
    const {
        ses_region,
        toAddress,
        bccAddress,
        sesTemplateName,
        fromEmail,
        emailTemplateData
    } = event
    
    const AWS = require('aws-sdk');
    AWS.config.update({region: ses_region});
    
    // Create sendTemplatedEmail params 
    const params = {
      Destination: {
        ToAddresses: [toAddress],
        BccAddresses: bccAddress == null ? [] : [bccAddress]
      },
      Source: fromEmail, //'no-reply@codenotifications.thesmartbasket.com',
      Template: sesTemplateName, //'DefaultCodingInterviewTemplate'
      TemplateData: JSON.stringify(emailTemplateData)
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