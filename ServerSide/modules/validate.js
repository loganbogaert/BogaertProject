module.exports = {
    isPropertyValid: function (object, property) {
        // get property 
        let item = object[property];
        // if unvalid return false 
        if (item == null || item == "" || item == undefined) return false;
        // if not return true
        return true;
    }
}