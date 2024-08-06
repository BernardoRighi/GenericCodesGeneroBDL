OPTIONS SHORT CIRCUIT

IMPORT util
IMPORT com

MAIN
  DEFINE l_str STRING

  LET l_str = "Hello World"

  CALL translateString(l_str, NULL, "DE") RETURNING l_str
  IF NVL(l_str, " ") = " " THEN
    ERROR "The translation cannot be performed"
  ELSE
    DISPLAY l_str
  END IF 

END MAIN

# https://developers.deepl.com/docs/v/pt-br/api-reference/translate
PUBLIC FUNCTION translateString(p_string STRING, p_from CHAR(2), p_to CHAR(2)) RETURNS STRING

  DEFINE l_translation STRING 
  DEFINE request com.HTTPRequest
  DEFINE response com.HTTPResponse
  DEFINE status_code SMALLINT
  DEFINE response_text STRING
  DEFINE json_parameter STRING
  DEFINE auth_key STRING

  DEFINE json_data RECORD 
    text DYNAMIC ARRAY OF STRING,
    source_lang STRING,
    target_lang STRING  
  END RECORD  
  
  DEFINE json_response RECORD
    translations DYNAMIC ARRAY OF RECORD
      detected_source_language STRING,
      text STRING
    END RECORD
  END RECORD  

  -- DeepL API authentication key
  LET auth_key = "[your key]"

  -- Create the JSON request body
  LET json_data.text[1] = p_string
  LET json_data.target_lang = p_to
  
  IF NVL(p_from, " ") != " " THEN 
    LET json_data.source_lang = p_from
  END IF

  TRY
    -- Create the HTTPRequest object for the DeepL API endpoint
    LET request = com.HTTPRequest.Create("https://api.deepl.com/v2/translate")

    -- Set the request method to POST
    CALL request.setMethod("POST")

    -- Set the request headers
    CALL request.setHeader("Content-Type", "application/json")
    CALL request.setHeader("Authorization", SFMT("DeepL-Auth-Key %1", auth_key))

    -- Convert the request body to a JSON string
    LET json_parameter = util.JSON.stringify(json_data)

    -- Make the HTTP request with the JSON body
    CALL request.doTextRequest(json_parameter)

    -- Get the response from the request
    LET response = request.getResponse()
    LET status_code = response.getStatusCode()
    LET response_text = response.getTextResponse()

    -- Parse the JSON response    
    CALL util.JSON.parse(response_text, json_response)
  CATCH
    RETURN NULL
  END TRY

  -- Check if the response was successful
  IF status_code = 200 THEN
    LET l_translation = json_response.translations[1].text
  ELSE
    DISPLAY "Translation error: ", status_code, " - ", response_text
    RETURN NULL
  END IF

  RETURN l_translation

END FUNCTION
