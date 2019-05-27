//*****************************<vars>*****************************
var data = [{"output" : "say hello", "sentence" : "the best the best american restaurant"}, {"output" : "say hello", "sentence" : "american restaurant enjoy the best hamburger"},{"output" : "say hello", "sentence" : "korean restaurant enjoy the best bibimbap"},{"output" : "say hello", "sentence" : "the best italian restaurant enjoy the best pasta"} ];
var response;
//****************************<function>***************************
function getEveryWordOnce(splitter,data) 
{
    // create array
    var singleWords = []; var singleObjects = [];
    // loop through data
    for(i=0;i<data.length;i++)
    {
        // create array
        var sentenceInArray = data[i].sentence.split(splitter);
        // loop trough array, add in array if needed
        for(b=0;b<sentenceInArray.length;b++)
        { 
            // add intp array
            if(!singleWords.includes(sentenceInArray[b])) { singleObjects.push({"word" : sentenceInArray[b], "tf" : [], "idf" : "", "tfIdf" : []}); singleWords.push(sentenceInArray[b]);}
        }
    }
    // return array 
    return singleObjects;
}
//*****************************<function>*****************************
function calculateTermFrequency(singleObjects,data)
{
    // loop trough objects 
    for(i=0;i<singleObjects.length;i++)
    {
        // loop trough data array
        for(b=0;b<data.length;b++)
        {
            // create var
            var aantal = 0;
            // split string
            var array = data[b].sentence.split(" ");
            // aantal ++ if needed
            for(c=0;c<array.length;c++) {if(array[c] == singleObjects[i].word) aantal++;}
            // push into array 
            singleObjects[i].tf.push((aantal/array.length).toFixed(3));
        }
    }
    // return object 
    return singleObjects;
}
//*****************************<function>*****************************
function calculateInverseDocumentFrequency(data,singleObjects)
{
    // loop trough singleobjects
    for(i=0;i<singleObjects.length;i++)
    {
        // create var
        var aantal = 0;
        // loop trough data
        for(b=0;b<data.length;b++)
        {
            // split sentence
            var array = data[b].sentence.split(" ");
            // loop trough array
            for(c=0;c<array.length;c++) {if(singleObjects[i].word == array[c]) {aantal++; break;}}
        }
        // idf calculation
        singleObjects[i].idf =  Math.log(data.length / aantal).toFixed(3);
    }
    // return object
    return singleObjects;
}
//*****************************<function>*****************************
function calculatetfIdf(singleObjects)
{
    // loop trough objects 
    for(i=0;i<singleObjects.length;i++){ for(b=0;b<singleObjects[i].tf.length;b++){ singleObjects[i].tfIdf.push((singleObjects[i].tf[b] * singleObjects[i].idf).toFixed(3))} delete singleObjects[i].tf; delete singleObjects[i].idf;}
    // return object
    return singleObjects;
}
//*****************************<function>*****************************
function calculateSimilarity(singleObjects, length, data)
{
    // create array for the first sentence and var
    var nlpArray = [];  var aantal = 1;
    // loop trough array 
    for(i=0;i<singleObjects.length;i++){nlpArray.push(singleObjects[i].tfIdf[0]);}
    // throw error if length equals 1 
    if(length <=1) throw "length should be bigger than 1";
    // create vars
    var index,max;
    // give values
    index = -1; max = -1;
    // loop trough
    while(aantal < length)
    {
        // create array
        var compareArray = [];
        // loop trough array 
        for(i=0;i<singleObjects.length;i++) { compareArray.push(singleObjects[i].tfIdf[aantal]);}
        // get library 
        var similarity = require('compute-cosine-similarity');
        // get similarity
        var sim = similarity(nlpArray,compareArray).toFixed(3);
        // max check
        if(max < sim) {max = sim; index = aantal;}
        // ++
        aantal++;
    }
    // return object 
    return data[index];
}
//*****************************<Use functions>*****************************/
function tfIdf(data)
{
    // call method
    var singleObjects = getEveryWordOnce(" ",data);
    // call method
    singleObjects = calculateTermFrequency(singleObjects,data);
    // call method 
    singleObjects = calculateInverseDocumentFrequency(data,singleObjects);
    // call method
    singleObjects = calculatetfIdf(singleObjects);
    // call method 
    return calculateSimilarity(singleObjects, data.length,data);
}
// call method
response = tfIdf(data);
console.log(response);
