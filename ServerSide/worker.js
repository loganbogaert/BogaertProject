// require socketcluster Library
const SCWorker = require('socketcluster/scworker');
// load mssql library 
const mssql = require("mssql");
// require jwt
const jwt = require('jsonwebtoken');
// require nodemailer
const nodemailer = require("nodemailer");
// DB config
let config = { user: "TombolaAdmin", password: "LJJ1234", server: "localhost\\SQLEXPRESS", database: "TombolaDB", port: 1433, options: { encrypt: false } };
//***********************<Functions>***********************
function isPropertyValid(object, property) {
  // get property 
  let item = object[property];
  // if unvalid return false 
  if (item == null || item == "" || item == undefined) return false;
  // if not return true
  return true;
}

//***********************<Worker class>***********************
class Worker extends SCWorker {
  //*******<Run method>*********
  run() {
    // default console log 
    console.log('   >> Worker PID:', process.pid);
    // get socketcluster instance
    var scServer = this.scServer;
    //*************<event when new socket connects>*************
    scServer.on('connection', function (socket) {
      //*********<event when socket wants to create new user>*********
      socket.on('serverCall', function (data, respond) {
        console.log(data);
        if (isPropertyValid(data, 'type')) {
          if (data.type == 'newUser') {
            console.log('new user');
            let props = ['name', 'pwd', 'email'];
            // Look if each prop is valid
            for (const prop of props) {
              console.log(prop);
              let res = isPropertyValid(data, prop);
              if (res == false) {
                // Let the client know that not all the right props are given
                respond('Not the right props');
                console.log('Not the right props');
                return;
              }
            }
            // When all props are valid we continue
            // Generate token based on the user his email
            let token = jwt.sign({ data: data.email, exp: 60 * 30 }, 'qfa8f3');
            // Procedure to register user
            mssql.connect(config, err => {
              if (err) throw err;
              new mssql.Request()
                .input('AccessToken', mssql.VarChar(300), token)
                .input('UserType', mssql.Char(), 'a')
                .input('Username', mssql.VarChar(50), data.name)
                .input('Email', mssql.VarChar(80), data.email)
                .input('Password', mssql.VarChar(50), data.pwd)
                .input('FacebookId', mssql.VarChar(300), null)
                .execute('AddUser', (err, result) => {
                  if (err) throw err;
                  if (result.returnValue == 0) {
                    respond();
                    // Send mail
                    let transporter = nodemailer.createTransport({
                      service: 'gmail',
                      auth: {
                        user: 'jarnobog@gmail.com',
                        pass: '04121999'
                      }
                    });

                    const mailOptions = {
                      from: 'jarnobog@gmail.com', // sender address
                      to: `${data.email}`, // list of receivers
                      subject: 'Confirm', // Subject line
                      html: '<p>Your html here</p>'// plain text body
                    };

                    transporter.sendMail(mailOptions, function (err, info) {
                      if(err)
                        console.log(err);
                      else
                        console.log(info);
                   });
                  } else {
                    respond('Procedure failed');
                  }
                  mssql.close();
                });
            })
          }
        }
      });
    });
  }
}
new Worker();



