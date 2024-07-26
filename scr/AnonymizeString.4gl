MAIN
  DEFINE l_str STRING

  LET l_str = "Anonymization test"

  -- Call the anonymizeString function to anonymize part of the string
  -- from position 3 to position 5 using "*" as the anonymization symbol
  CALL anonymizeString(l_str, 3, 4, "*") RETURNING l_str
  -- Returned value for l_str should be "An*************est"

END MAIN

#+ Function to anonymize a string
#+
#+ p_str - String to be anonymized
#+ p_pos_initial - Starting position of the string to be anonymized
#+ p_pos_final - End position of the string to be anonymized
#+ p_token - Value or symbol to use for anonymization
#+
#+ Returns the resulting string
PUBLIC FUNCTION anonymizeString(p_str STRING, p_pos_initial SMALLINT, p_pos_final SMALLINT, p_token CHAR(1)) RETURNS STRING 

  DEFINE 
    l_str_result STRING,  -- Resulting anonymized string
    l_i, l_str_length SMALLINT  -- Loop index and length of the input string

  -- Get the length of the input string
  LET l_str_length = LENGTH(p_str CLIPPED)
    
  -- If the initial position is not provided or zero, set it to 1
  IF NVL(p_pos_initial, 0) = 0 THEN 
    LET p_pos_initial = 1
  END IF

  -- If the final position is not provided or zero, set it to the length of the string
  IF NVL(p_pos_final, 0) = 0 THEN 
    LET p_pos_final = l_str_length
  END IF 

  -- Adjust the final position
  LET p_pos_final = l_str_length - p_pos_final

  -- Loop through each character in the input string
  FOR l_i = 1 TO l_str_length
    -- If the current position is within the range to be anonymized, append the token
    IF l_i >= p_pos_initial AND l_i <= p_pos_final THEN 
      LET l_str_result = l_str_result CLIPPED, p_token
    ELSE 
      -- Otherwise, append the original character
      LET l_str_result = l_str_result CLIPPED, p_str.subString(l_i,l_i)
    END IF 
  END FOR 

  -- Return the resulting anonymized string
  RETURN l_str_result CLIPPED
  
END FUNCTION
