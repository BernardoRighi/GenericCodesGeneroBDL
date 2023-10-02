import util

private type KeyValueLookup record
    keys dynamic array of string,
    values string,
    error boolean
end record

#+
#+ Função para retornar, em um json object (record) uma concatenação do que é chave e do que
#+   é o restante dos campos. As chaves e os campos desse record são passados por parâmetro.
#+
#+ @param   obj           = JSONObject do record sendo verificado
#+ @param   attributes_key = Array dos campos que são considerados chave
#+
#+ @return  string  Concatenação dos valores da chave
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
#+ Função para retornar, em um json object (record) o valor do campo passado por parâmetro,
#+   em formato json stringificado
#+
#+ @param   obj         = JSONObject sendo verificado
#+ @param   attribute   = Nome do campo para buscar o valor
#+
#+ @return  string      Valor desse campo em json stringificado
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
#+ Função para retornar, em um json object (record) todos seus campos em uma lista
#+
#+ @param   obj   JSONObject sendo verificado
#+
#+ @return          Lista de campos desse JSONObject (apenas as "key" do conjunto "key":"value")
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
#+ Funcao que verifica a matriz para encontrar uma ou mais chaves que corresponda ao parâmetro de pesquisa.
#+
#+ @param   la_arr          = xml do array criado através de um { util.JSONArray.fromFGL(array) }
#+ @param   lr_valor        = xml do array criado através de um { util.JSONObject.fromFGL(array) }
#+ @param   l_chave_campos  = Campos separados por ponto-e-vírgula, para que a função identifique o que sera buscado
#+
#+ @return  integer  Indice encontrado do array
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

    -- INÍCIO
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
#+ Funcao que verifica a matriz para encontrar a quantidade de indices com as mesmas chaves que corresponda ao parâmetro de pesquisa.
#+
#+ @param   la_arr          = xml do array criado através de um { util.JSONArray.fromFGL(array) }
#+ @param   lr_valor        = xml do array criado através de um { util.JSONObject.fromFGL(array) }
#+ @param   l_chave_campos  = Campos separados por ponto-e-vírgula, para que a função identifique o que sera buscado
#+
#+ @return  integer  Quantidade de indices encontrados do array
#+
public function countKeyOccurrencesInArray(la_arr util.JSONArray, values util.JSONObject, keys string)
    returns (integer)

    define keyValue KeyValueLookup

    define i integer,
           keyOccurrencesCount integer,
           content string

    whenever any error stop

    if not keyValue.fillKeyValue(la_arr, values, keys) then
        return iif(keyValue.error, null, 0)
    end if

    let keyOccurrencesCount = 0

    for i = 1 to la_arr.getLength()
        if la_arr.getType(i) <> "OBJECT" then
            error "Array não é do tipo objeto no registro "||i
            return null
        end if

        call retornar_strings_chave_e_restante_json_obj(la_arr.get(i), keyValue.keys)
            returning content

        if content = keyValue.values then
            let keyOccurrencesCount = keyOccurrencesCount + 1
        end if
    end for

    return keyOccurrencesCount

end function


#+
#+ Função que valida os arrays para criar os parametros necessarios para validar os indices do array
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

    -- Verifica se todas as chaves passadas realmente estão na estrutura (colunas) dos arrays
    for i = 1 to keyValue.keys.getLength()
        if (lengthArray > 0 and
            attributesArr.search(null, keyValue.keys[i]) < 1) or
           (attributesValues.search(null, keyValue.keys[i]) < 1) then
            error "Chave "||keyValue.keys[i]||" não encontrada na estrutura"
            let keyValue.error = true
            return false
        end if
    end for

    call retornar_strings_chave_e_restante_json_obj(values, keyValue.keys)
        returning keyValue.values

    return true

end function