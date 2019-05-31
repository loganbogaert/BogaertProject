const io = require('socket.io')(3000);

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
        else {
            callback(true);
            socket.username = username;
            users[socket.username] = socket;
            updateUsernames();
        }
    })

    socket.on('send-message', (data, callback) => {
        // Send to receiver
        users[data.to].emit('new-message', {msg: data.msg, username: socket.username});
        // Send to sender
        users[socket.username].emit('new-message', {msg: data.msg, username: socket.username});
    });

});


function updateUsernames() {
    io.emit('usernames', Object.keys(users));
}