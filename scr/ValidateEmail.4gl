IMPORT JAVA java.util.regex.Pattern
IMPORT JAVA java.util.regex.Matcher

#+ Checks if email is valied
PUBLIC FUNCTION checkIsEmailValid(p_email STRING) RETURNS BOOLEAN

  DEFINE regex_pattern STRING
  DEFINE p Pattern
  DEFINE m Matcher

  IF NVL(p_email, " ") = " " THEN
    RETURN FALSE
  END IF 

  LET regex_pattern = "^[a-zA-Z0-9._%+-]+@([a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,}$"
  LET p = Pattern.compile(regex_pattern)
  LET m = p.matcher(p_email)
  IF NOT m.matches() THEN
    RETURN FALSE
  END IF   

  RETURN TRUE
  
END FUNCTION
