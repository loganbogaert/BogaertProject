const socket = io('http://localhost:3000');

$('#register').click((e) => {
    e.preventDefault();
    let form = $('#form').serializeArray();
    let data = {
        name: form[0].value,
        email: form[1].value,
        pwd: form[2].value,
        pwd2: form[3].value
    }
    socket.emit('registerUser', data, (valid) => {
        if (valid) {
            console.log('ok');
        } else {
            console.log('niet ok');
            
        }
    });
    console.log(data);
})