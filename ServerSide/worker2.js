// require socketcluster Library
const SCWorker = require('socketcluster/scworker');
// load mssql library 
const mssql = require("mssql");
// require jwt
const jwt = require('jsonwebtoken');
// require nodemailer
const nodemailer = require("nodemailer");
// require express
const express = require('express');
// require bcryptjs for hashing
const bcrypt = require('bcryptjs');
// require path
const path = require('path');
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
    let app = express();

    //*************<express setup & middleware>*************
    app.set('view engine', 'ejs');
    app.set('views', path.join(__dirname, 'views'));

    //*************<express server>*************
    app.get('/verify', (req, res) => {
        let token = req.query.token;
        let validToken;
        // If token is undefined just say that the token is not valid
        if (token == undefined) {
            validToken = false;
        }
        // Else we will search token in DB & verify it
        else {
            // Search token in DB
            mssql.connect(config, err => {
                if (err) throw err;
                new mssql.Request().query('', (err, result) => {
                    if (err) throw err;
                    console.log(result);
                })
                mssql.close();
            });

            // Verify token
        }

        res.render('verify', {
            valid: false
        });
    });
    app.listen(80);



    //*************<event when new socket connects>*************
    scServer.on('connection', function (socket) {
      //*********<event when socket wants to interact with server>*********
      socket.on('serverCall', function (data, respond) {
        console.log(data);
        if (isPropertyValid(data, 'type')) {

          //*************<action to make new user>*************
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

            // Hash password
            bcrypt.genSalt(10, (err, salt) => {
                if (err) throw err;
                bcrypt.hash(data.pwd, salt, (err, hash) => {
                    if (err) throw err;
                    data.pwd = hash;
                })
            });

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
                      subject: 'Confirm', // Subject line
                      html: '<p>Your html here</p>'// plain text body
                    };
                    // Send mail
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
          } //*************<end of making new user>*************
        }
      });
    });
  }
}
new Worker();