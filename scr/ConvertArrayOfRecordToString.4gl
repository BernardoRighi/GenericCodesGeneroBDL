options short circuit

import util

#+
#+ Converts an ARRAY OF RECORD || ARRAY || RECORD into a concatenated string,
#+ using a specified separator, and optionally selecting specific properties for concatenation.
#+
public function ConvertArrayOfRecordToString(
    ## array of record string, created through util.JSON.stringify(array), to convert into a concatenated string. ( import util )
    ## EX: ConvertArrayOfRecordToString(util.JSON.stringify(employees), ", ", "id")
    jsonString string, 
    ## string used to separate values in the output string. Ex: ", " -> Output: "1, 2, 3"
    separator string, 
    ## A semicolon-separated list of properties to concatenate from the records.
    ## If set to null, all properties will be considered.
    ## Ex: "id;name" -> Output: "1, John..."
    properties string 
) returns(string) ## Concatenated string from the array of record, with values separated by the specified separator.

    define i integer,
           positionValueWithSeparator  string,
           numberInt integer,
           jsonArray util.JSONArray,
           positionJsonArray util.JSONArray,
           positionJsonArrayString string

    define concatenatedString string = ""

    whenever any error raise

    ## Try transforming it into a JSONArray, if you can't, transform it into a JSONObject
    ## to transform into a JSONArray with just the values.
    ## If the JSON is not valid, it returns null
    try
        let jsonArray = util.JSONArray.parse(jsonString)
    catch
        try
            let jsonArray = GetValuesByProperties(util.JSONObject.parse(jsonString), properties)
        catch
            return null
        end try
    end try

    for i = 1 to jsonArray.getLength()
        case jsonArray.getType(i)
            when "NULL"
                continue for
                
            when "OBJECT"
                ## Transforms the object into an array of values for call the function again
                let positionJsonArray = GetValuesByProperties(
                    jsonArray.get(i), 
                    properties
                )
                let positionJsonArrayString = positionJsonArray.toString()
                let positionValueWithSeparator = ConvertArrayOfRecordToString(
                    positionJsonArrayString,
                    separator,
                    properties
                )

            when "ARRAY"
                ## Call the function again to return the string with the values within the array
                let positionJsonArray = jsonArray.get(i)
                let positionJsonArrayString = positionJsonArray.toString()
                let positionValueWithSeparator = ConvertArrayOfRecordToString(
                    positionJsonArrayString, 
                    separator,
                    properties
                )
                
            when "NUMBER"
                ## Tests whether the variable is integer or decimal, 
                ## if it is integer it will cut the decimal place
                ## NOTE: Integers are displayed with ".0" which is why this test is necessary
                if (numberInt := jsonArray.get(i)) = jsonArray.get(i) then
                    let positionValueWithSeparator = numberInt using "<<<<<<<<<<<<<<<<<<<<<<<<"
                else
                    let positionValueWithSeparator = replace_string(",", ".", jsonArray.get(i), 0)
                end if
                
            otherwise ## STRING || BOOLEAN 
                let positionValueWithSeparator = jsonArray.get(i)
        
        end case

        ## It will get null here if the object or array is empty
        ## Ex: { employeeId: 1, contacts: [] }
        ## The "contacts" property will return positionValueWithSeparator = null
        ## Without the test below, in the example above it ends up
        ## the string with the x2 separator -> "1, , "
        if not positionValueWithSeparator.getLength() then
            let concatenatedString = concatenatedString, positionValueWithSeparator, separator
        end if
    end for

    ## Remove the last separator
    return concatenatedString.subString(1, length(concatenatedString) - length(separator))

end function


#+
#+ Extracts values from a JSON object based on specified properties.
#+
private function GetValuesByProperties(
    ## The JSON object to extract values from. created through util.JSONObject.fromFGL(record) 
    jsonObject util.JSONObject, 
    ## A semicolon-separated list of properties to retrieve values for.
    ## If set to null, all properties will be considered.
    ## Ex: "id;firstName" -> Output: [1, "John"]
    properties string
) returns(util.JSONArray) ## An JSONArray of values from the JSONObject based on the specified properties.

    define i, k integer,
           propertiesArray dynamic array of string

    define jsonArray util.JSONArray

    whenever any error raise

    ## Transform into an array to be able to use the search method
    call SplitStringToArray(properties, ";") returning propertiesArray

    let jsonArray = util.JSONArray.create()

    for i = 1 to jsonObject.getLength()
        if propertiesArray.search(null, jsonObject.name(i)) > 0 or
           properties is null then
            call jsonArray.put(k := k + 1, jsonObject.get(jsonObject.name(i)))
        end if
    end for

    return jsonArray

end function


#+
#+ Splits a string into an array of substrings using a specified separator.
#+
private function SplitStringToArray(
    ## string to be split
    string string, 
    ## separator used to split the input string into substrings.
    separator string
) returns (dynamic array of string ) ## An array of substrings extracted from the input string.
    
    define stringTokenizer base.StringTokenizer,
           i integer = 0

    define splitResult dynamic array of string

    whenever any error raise

    let stringTokenizer = base.StringTokenizer.create(string, separator)
   
    while stringTokenizer.hasMoreTokens()
        let splitResult[i := i + 1] = stringTokenizer.nextToken()
    end while

    return splitResult

end function