// require socketcluster Library
const SCWorker = require('socketcluster/scworker');
// load mssql library 
const mssql = require("mssql");
// require jwt
const jwt = require('jsonwebtoken');
const secret = 'qfafezqz';
// require nodemailer
const nodemailer = require("nodemailer");
// require express
const express = require('express');
// require path
const path = require('path');
// require bcrypt
const bcrypt = require('bcrypt');
// require custom made modules
const mail = require('./modules/mail');
const validate = require('./modules/validate');
// DB config
let config = { user: "TombolaAdmin", password: "LJJ1234", server: "localhost\\SQLEXPRESS", database: "TombolaDB", port: 1433, options: { encrypt: false } };
// creating connection pool
let pool = new mssql.ConnectionPool(config).connect();

//***********************<Worker class>***********************
class Worker extends SCWorker {
  //*******<Run method>*********
  run() {
    // default console log 
    console.log('   >> Worker PID:', process.pid);
    // get socketcluster instance
    var scServer = this.scServer;
    let app = express();

    app.set('view engine', 'ejs');
    app.set('views', path.join(__dirname, 'views'));

    app.get('/verify', (req, res) => {
      let token = req.query.token;

      pool.then(pool => {
        return pool.query`select Id, Name, Email, AccessToken from AppConnections where AccessToken = ${token}`
      }).then(result => {
        let tok = result.recordset[0].AccessToken;
        let id = result.recordset[0].Id;
        let valid;

        let data = {
          email: result.recordset[0].Email,
          name: result.recordset[0].Name
        }

        jwt.verify(tok, secret, (err, decoded) => {
          if (err) {
            console.log(err);
            valid = false;

            // Make new token
            let token = jwt.sign({
              data: data.email,
              exp: Math.floor(Date.now() / 1000) + 60 * 30
            }, secret);

            // Resent new mail with new token
            mail.sendMail(data, token);

          } else {
            console.log(decoded);
            valid = true;

            // update validated bit to 1, so the user is verified
            pool.then(pool => {
              return pool.query`update Users set Validated=1 where IdAppUserConnection=${id}`
            }).then(result => {
              console.log(result);

            }).catch(err => {
              console.log(err);
            })
          }

          res.render('verify', {
            valid: valid
          })

        })

      }).catch(err => {
        console.log(err);
      })



    });

    app.listen(80);




    //*************<event when new socket connects>*************
    scServer.on('connection', function (socket) {
      //*********<event when socket wants to create new user>*********
      socket.on('serverCall', function (data, respond) {
        console.log(data);
        if (validate.isPropertyValid(data, 'type')) {
          if (data.type == 'newUser') {
            console.log('new user');
            let props = ['name', 'pwd', 'email'];
            // Look if each prop is valid
            for (const prop of props) {
              console.log(prop);
              let res = validate.isPropertyValid(data, prop);
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
            let token = jwt.sign({
              data: data.email,
              exp: Math.floor(Date.now() / 1000) + 60 * 30
            }, secret);

            return pool.then((pool) => {
              pool.request()
                .input('AccessToken', mssql.VarChar(300), token)
                .input('UserType', mssql.Char(), 'a')
                .input('Username', mssql.VarChar(50), data.name)
                .input('Email', mssql.VarChar(80), data.email)
                .input('Password', mssql.VarChar(50), data.pwd)
                .input('FacebookId', mssql.VarChar(300), null)
                .execute('AddUser', (err, result) => {
                  if (err) throw err;
                  console.log(result);

                  if (result.returnValue == 0) {
                    respond();
                    mssql.close();

                    // Send mail
                    mail.sendMail(data, token);
                  } else {
                    respond('Procedure failed');
                  }
                  mssql.close();
                });
              mssql.close();
            })
          }
        }
      });

      socket.on('login', (data, respond) => {
        let { email, pwd } = data;

        // Hash password
        bcrypt.genSalt(10, (err, salt) => {
          if (err) throw err;
          bcrypt.hash(pwd, salt, (err, hash) => {
            if (err) throw err;
            pwd = hash;
          });
        });

        // Search user in app table
        pool.then(pool => {
          return pool.query`select Id, Password from AppConnections where Email = ${email}`
        }).then((result) => {
          let pwdFromDb = result.recordset[0].Password;
          let appId = result.recordset[0].Id;

          // Get id from user in user table
          pool.then(pool => {
            return pool.query`select Id from Users where IdAppUserConnection = ${appId}`
          }).then(result => {
            let userId = result.recordset[0].Id;

            // Compare passwords
            if (pwdFromDb === pwd) {
              respond();
              socket.setAuthToken({id:  userId, email: email});
            }
            else {
              respond('Login has failed');
            }
          });
        });
      })
    });
  }
}
new Worker();