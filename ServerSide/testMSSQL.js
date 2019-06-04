var mssql = require("mssql");

var dbconfig  = { user : "TombolaAdmin", password : "LJJ1234", server :"localhost\\SQLEXPRESS", database : "TombolaDB", port : 1433, options : {encrypt : false}, 

}

var conn = new mssql.ConnectionPool(dbconfig);

conn.connect(function(err) {

    var req = new mssql.Request(conn);

    if(err) throw err;

    req.query("select * from AppConnections",function(err,recordset){
    
        if(err) throw err;
        console.log(recordset);
    })

    console.log("connected");

    
})


