const io = require('socket.io')(3000);
const bcrypt = require('bcryptjs');

let users = {};

io.on('connection', (socket) => {
    console.log('connected');

    socket.on('new-user', (username, callback) => {
        console.log(username);
        // Check if username is taken
        if (username in users) {
            callback(false);
            console.log('username already taken');
        }
        // If username is not taken
        else {
            callback(true);
            socket.username = username;
            users[socket.username] = socket;
            updateUsernames();
        }
    })

    // Listen to when a message is sent
    socket.on('send-message', (data, callback) => {
        // Send to receiver
        users[data.to].emit('new-message', { msg: data.msg, username: socket.username });
        // Send to sender
        users[socket.username].emit('new-message', { msg: data.msg, username: socket.username });
    });

    socket.on('registerUser', (data, callback) => {
        // function that inserts user
        callback(registerUser(data));
    });

    socket.on('loginUser', (data, callback) => {
        // function that checks credentials
        callback(loginUser(data));
    });

    socket.on('addItem', (data, callback) => {
        if (checkUser(data.email, data.pwd)) {
            // check in db if credentials are correct
            // if correct add item
            callback(addItem(data));
        }
        else {
            callback({msg: 'Not a valid user'});
        }
    })


});

// updates all users in front end
function updateUsernames() {
    io.emit('usernames', Object.keys(users));
}

// function that inserts user 
function registerUser(user) {
    console.log(user);
    if (isObjectValid(user)) {
        console.log('ok');
        // check if user of fb
        if (user.fb == true) {
            console.log('fb user');
        }
        // or app
        else {
            console.log('normal user');
            if (user.pwd == user.pwd2) {
                console.log('same pwd');
                let salt = bcrypt.genSaltSync(10);
                let hash = bcrypt.hashSync(user.pwd, salt);
                console.log(hash);
            } 
            else {
                console.log('not same pwd');
            }
        }
        return true;
    } else {
        console.log('niet ok');
        return false;
    }
}

// function that checks credentials
function loginUser(user) {
    if (isObjectValid(user)) {
        console.log('ok');
        // check if user of fb
        if (user.fb == true) {
            console.log('fb user');
        }
        // or app
        else {
            console.log('normal user');
        }
        return true;
    } else {
        console.log('niet ok');
        return false;
    }
}

function addItem(item) {

}

function checkUser(email, pwd) {
    // check in db if email & pwd are correct
}

// function to check if object is valid
function isObjectValid(user) {
    for (const key in user) {
        let item = user[key];
        if (item == null || item == "" || item == undefined) return false;
    }
    return true;
}

console.log('running server...');
