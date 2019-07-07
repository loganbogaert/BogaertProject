exports.sendMail = function (data, token) {
    // Prepare transporter
    let transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
            user: 'jarnobog@gmail.com',
            pass: '04121999'
        }
    });
    // Prepare mailoptions
    const mailOptions = {
        from: 'jarnobog@gmail.com', // sender address
        to: `${data.email}`, // list of receivers
        subject: 'Verify account', // Subject line
        html: `
          <p>Hello, ${data.name}</p>
          <p>Go to http://localhost/verify?token=${token} to verify your account.</p>
          <p>Thanks for using our app.</p>
        `
    };
    // Send mail
    transporter.sendMail(mailOptions, function (err, info) {
        if (err)
            console.log(err);
        else
            console.log(info);
    });
};