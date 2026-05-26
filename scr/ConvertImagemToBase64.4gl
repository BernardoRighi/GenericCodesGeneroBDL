PRIVATE FUNCTION convertUrlImagemToBase64(p_url_image STRING) RETURNS STRING

  DEFINE l_request com.HTTPRequest
  DEFINE l_response com.HTTPResponse
  DEFINE l_img_data BYTE
  DEFINE l_http_status SMALLINT
  DEFINE l_img_base64 STRING
  DEFINE l_mime_type STRING
  DEFINE l_tmp_file STRING

  LET l_tmp_file = SFMT("/tmp/img_%1.tmp", lib_string_helper.removeSpecialCharactersString(CURRENT YEAR TO SECOND))
  
  TRY
    LET l_request = com.HTTPRequest.Create(p_url_image)
    CALL l_request.setMethod("GET")

    CALL l_request.doRequest()
    LET l_response = l_request.getResponse()
    LET l_http_status = l_response.getStatusCode()

    IF l_http_status = 200 THEN
      LOCATE l_img_data IN MEMORY
      CALL l_response.getDataResponse(l_img_data)
      LET l_mime_type = NVL(l_response.getHeader("Content-Type"), "image/png")
      CALL l_img_data.writeFile(l_tmp_file)
      LET l_img_base64 = security.Base64.LoadBinary(l_tmp_file)
    END IF 

    IF os.Path.exists(l_tmp_file) THEN
      IF NOT os.Path.delete(l_tmp_file) THEN
        DISPLAY SFMT("Konnte die Datei %1 nicht löschen!", l_tmp_file))
      END IF
    END IF 
    
    IF l_http_status >= 400 OR NVL(l_img_base64, " ") == " " THEN
      DISPLAY SFMT(%"Das Bild konnte nicht über den Link %1 heruntergeladen werden. Erros: %2 %3", l_base_url, l_http_status, l_response.getTextResponse()))
      RETURN NULL
    END IF 
  CATCH
    DISPLAY SFMT(%"Das Bild konnte nicht über den Link %1 heruntergeladen werden. Erros: %2 %3", l_base_url,  sqlca.sqlcode, sqlca.sqlerrm))
    RETURN NULL
  END TRY

  RETURN SFMT("data:%1;base64,%2", l_mime_type CLIPPED, l_img_base64 CLIPPED)   

END FUNCTION
