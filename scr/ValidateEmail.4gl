IMPORT JAVA java.util.regex.Pattern
IMPORT JAVA java.util.regex.Matcher

MAIN
  -- Define a variable to store the email
  DEFINE email STRING

  -- Assign an email value to test the function
  LET email = "teste@teste.com"

  -- Check if the email is valid. If not, display an error message
  IF NOT checkIsEmailValid(email) THEN
    DISPLAY %"Invalid e-mail"
  END IF

END MAIN

-- Public function to check if an email is valid
PUBLIC FUNCTION checkIsEmailValid(p_email STRING) RETURNS BOOLEAN

  -- Define variables for the regex pattern, the pattern, and the matcher
  DEFINE regex_pattern STRING
  DEFINE p Pattern
  DEFINE m Matcher

  -- Check if the email is null or empty. If it is, return FALSE
  IF NVL(p_email, " ") = " " THEN
    RETURN FALSE
  END IF 

  -- Define the regex pattern to validate the email
  LET regex_pattern = "^[a-zA-Z0-9._%+-]+(?<!\\.)@[a-zA-Z0-9-]+(\\.[a-zA-Z0-9-]+)*\\.[a-zA-Z]{2,}$"

  -- Compile the regex pattern into a pattern
  LET p = Pattern.compile(regex_pattern)

  -- Apply the pattern to the given email
  LET m = p.matcher(p_email)

  -- Check if the email matches the regex pattern. If not, return FALSE
  IF NOT m.matches() THEN
    RETURN FALSE
  END IF   

  -- If all checks pass, return TRUE indicating the email is valid
  RETURN TRUE
  
END FUNCTION
