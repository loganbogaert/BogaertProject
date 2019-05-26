//*****************************<vars>*****************************
var data = [{"output" : "say hello", "sentence" : "Hello how are you doing"}, {"output" : "say hello", "sentence" : "Hello how are you feeling today"}];
var singleObjects;
//****************************<function>***************************
function getEveryWordOnce(splitter,data) 
{
    // create array
    var singleWords = []; var singleObjects = []
    // loop through data
    for(i=0;i<data.length;i++)
    {
        // create array
        var sentenceInArray = data[i].sentence.split(splitter);
        // loop trough array, add in array if needed
        for(b=0;b<sentenceInArray.length;b++)
        { 
            // add intp array
            if(!singleWords.includes(sentenceInArray[b])) 
            { 
                // create multiarray
                var array = []; 
                // add to arrays
                singleObjects.push({"word" : sentenceInArray[b], "tf" : array, "idf" : ""}); singleWords.push(sentenceInArray[b]);
            }
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
            singleObjects[i].tf.push((aantal/array.length).toFixed(2));
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
        singleObjects[i].idf =  Math.log(data.length / aantal).toFixed(2);
    }
    // return object
    return singleObjects;
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
    // return array
    return singleObjects;
}
// call method
singleObjects = tfIdf(data);
console.log(singleObjects);






