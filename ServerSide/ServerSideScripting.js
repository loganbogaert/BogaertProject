// get express library
var express = require('express');
// create instase of express library
var app = express();
//*****************<Route to create an account>*****************
app.route('/CreateAccount').get(function(req,res)
{
    // create array 
    var array = []
    // get username
    var name = req.query.Name; array.push(name);
    // get email 
    var email = req.query.Email; array.push(email);
    // get password 
    var password = req.query.Password; array.push(password);
    // get amount 
    var amount = req.query.Amount; array.push(amount);
    // get available amount 
    var availableAmount = req.query.AvailableAmount; array.push(availableAmount);
    //***************<only continue if parameters are correct>***************
    if(!array.includes(undefined))
    {
        // get mmsql library 
        var mssql = require("mssql");
        //********<to be continued>********
    }
});
// make server listen to port 8500
var server=app.listen(8500,function() {});