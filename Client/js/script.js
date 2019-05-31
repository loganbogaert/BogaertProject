const socket = io('http://localhost:3000');

let joinBtn = $('#joinBtn');
let joinForm = $('#join-form');
let friendsDiv = $('#friends');

// Click event to join
joinBtn.click((e) => {
    e.preventDefault();
    let name = $('#username').val();
    sessionStorage.setItem('name', name);
    // Check if username already exist
    socket.emit('new-user', name, (data) => {
        if (data) {
            joinForm.hide();
            friendsDiv.show();
        }
        else {
            alert('Username already taken');
        }
    });
});

// Click event to go to private chat
$(document).on('click', '.single-friend', (e) => {
    console.log('send prive msg to ' + e.target.id + ' ...');
    sessionStorage.setItem('to', e.target.id);
    $('#friends').hide();
    $('#private-msg').show();
    $('#active-to').html(e.target.id);
});

// Click event to send message
$(document).on('click', '#send-msg', (e) => {
    e.preventDefault();
    let msg = $('#msg').val();
    let to = sessionStorage.getItem('to');
    socket.emit('send-message', {msg: msg, to: to}, (data) => {

    });
});


// Listen to update usernames
socket.on('usernames', (data) => {
    console.log(data);
    $('#list').html('');
    let tempName = sessionStorage.getItem('name');
    for (const username of data) {
        if (tempName != username) {
            $('#list').append(`
                <li class="single-friend" id="${username}">${username}</li>
            `)
        }
    }
})

// Listen if there is any new message
socket.on('new-message', (data) => {
    let tempName = sessionStorage.getItem('name');
    console.log(tempName);
    console.log(data.username);
    
    if (data.username == tempName) {
        $('#msg-items').append(`<li>
         You: ${data.msg}
        </li>`);
    } else {
        $('#msg-items').append(`<li>
            ${data.username}: ${data.msg}
        </li>`);
    }
});
