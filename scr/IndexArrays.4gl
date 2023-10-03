import util

private type KeyValueLookup record
    keys dynamic array of string,
    values string,
    error boolean
end record

#+
#+ Function to return, in a JSON object (record), a concatenation of what is the key and the rest of the fields. 
#+ The keys and fields of this record are passed as parameters.
#+
#+ @param   obj            = JSON object of the record being checked.
#+ @param   attributes_key = Array of fields that are considered keys.
#+
#+ @return  string  Concatenation of the key values.
#+
private function retornar_strings_chave_e_restante_json_obj(obj util.JSONObject, attributes_key dynamic array of string)
    returns string

    define i smallint,
           key string = null

    for i = 1 to attributes_key.getLength()
        let key = key, iif(key is not null, "|", ""), retornar_string_campo_json_obj(obj, attributes_key[i])
    end for

    return key

end function

#+
#+ Function to return, in a JSON object (record), the value of the field passed as a parameter, in JSON string format.
#+
#+ @param   obj         = JSONObject being checked
#+ @param   attribute   = Field name to retrieve the value.
#+
#+ @return  string      Value of this field in JSON string format.
#+
private function retornar_string_campo_json_obj(props)
    returns (string)

    define props record
        obj util.JSONObject,
        attribute string
    end record

    define obj util.JSONObject,
           arr util.JSONArray

    case props.obj.getType(props.attribute)
        when "OBJECT"
            let obj = props.obj.get(props.attribute)
            return obj.toString()
        when "ARRAY"
            let arr = props.obj.get(props.attribute)
            return arr.toString()
        otherwise
            return props.obj.get(props.attribute)
    end case

end function

#+
#+ Function to return in a JSON object (record), all its fields in a list.
#+
#+ @param   obj  = JSONObject being checked
#+
#+ @return       List of fields from this JSONObject(Just the "keys" of the pair "key":"value")
#+
private function retornar_todos_campos_json_object(obj util.JSONObject)
  returns (dynamic array of string)

    define i smallint
    define attributes dynamic array of string

    for i = 1 to obj.getLength()
        let attributes[i] = obj.name(i)
    end for

    return attributes

end function


#+
#+ Function that checks the array to find one or more keys that match the search parameter
#+
#+ @param   arr    = XML representation of the array created through a{ util.JSONArray.fromFGL(array) }
#+ @param   values = XML representation of the array created through a{ util.JSONObject.fromFGL(array) }
#+ @param   keys   = Fields separated by semicolons, so the function can identify what will be searched
#+
#+ @return  integer  Index found in the array.
#+
public function findKeyIndex(arr util.JSONArray, values util.JSONObject, keys string)
    returns (integer)

    define keyValue KeyValueLookup

    define content string,
           i integer

    whenever any error stop

    if not keyValue.fillKeyValue(arr, values, keys) then
        return iif(keyValue.error, null, 0)
    end if

    for i = 1 to arr.getLength()
        if arr.getType(i) <> "OBJECT" then
            call rot_erro("Array de backup não é do tipo objeto no registro "||i)
            return null
        end if

        call retornar_strings_chave_e_restante_json_obj(arr.get(i), keyValue.keys)
            returning content

        if content = keyValue.values then
            return i
        end if
    end for

    return 0

end function


#+
#+ Function that checks the array to find the number of indices with the same keys that match the search parameter.
#+
#+ @param   arr    = XML representation of the array created through a { util.JSONArray.fromFGL(array) }
#+ @param   values = XML representation of the array created through a { util.JSONObject.fromFGL(array) }
#+ @param   keys   = Fields separated by semicolons, so the function can identify what will be searched
#+
#+ @return  integer  Number of indices found in the array
#+
public function countKeyOccurrencesInArray(la_arr util.JSONArray, values util.JSONObject, keys string)
    returns (integer)

    define keyValue KeyValueLookup

    define i integer,
           keyOccurrencesCount integer,
           content string

    whenever any error stop

    if not keyValue.fillKeyValue(arr, values, keys) then
        return iif(keyValue.error, null, 0)
    end if

    let keyOccurrencesCount = 0

    for i = 1 to arr.getLength()
        if arr.getType(i) <> "OBJECT" then
            error "The array is not of object type in the record "||i
            return null
        end if

        call retornar_strings_chave_e_restante_json_obj(arr.get(i), keyValue.keys)
            returning content

        if content = keyValue.values then
            let keyOccurrencesCount = keyOccurrencesCount + 1
        end if
    end for

    return keyOccurrencesCount

end function


#+
#+ Function that validates arrays to create the necessary parameters for validating array indices.
#+
private function (keyValue KeyValueLookup) fillKeyValue(arr util.JSONArray, values util.JSONObject, keys string) returns(boolean)

    define attributesValues dynamic array of string,
           attributesArr dynamic array of string

    define lengthArray integer,
           countAttributesObj integer,
           i integer

    whenever any error stop

    let lengthArray = arr.getLength()
    let countAttributesObj = arr.getLength()

    if countAttributesObj = 0 or
       lengthArray = 0 then
        return false
    end if

    call retornar_todos_campos_json_object(values) returning attributesValues
    call retornar_todos_campos_json_object(arr.get(1)) returning attributesArr

    if keys is null then
        call attributesValues.copyTo(keyValue.keys)
    else
        let keyValue.keys = string_to_array_separador(keys, ";")
    end if

    -- Checks if all the keys passed are actually in the structure (columns) of the arrays.
    for i = 1 to keyValue.keys.getLength()
        if (lengthArray > 0 and
            attributesArr.search(null, keyValue.keys[i]) < 1) or
           (attributesValues.search(null, keyValue.keys[i]) < 1) then
            error "Key "||keyValue.keys[i]||" not found in the structure."
            let keyValue.error = true
            return false
        end if
    end for

    call retornar_strings_chave_e_restante_json_obj(values, keyValue.keys)
        returning keyValue.values

    return true

end function
