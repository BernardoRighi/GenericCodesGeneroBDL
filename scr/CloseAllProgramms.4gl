# This function terminates all programs related to fglrun that are running on the system.
# It lists the running processes, gets information such as PID, system user, command and arguments,
# and offers the user the option of terminating all programs. If confirmed, the function terminates the processes
# using the 'kill -9' command. This action should be carried out with care, as any unsaved data may be lost.
FUNCTION closeAllProgramsSystem()

  DEFINE l_cmd STRING            
  DEFINE l_channel base.Channel 
  DEFINE l_line STRING          
  DEFINE l_tok base.StringTokenizer 
  DEFINE l_i SMALLINT            
  DEFINE l_message STRING
  
  DEFINE arr_result DYNAMIC ARRAY OF RECORD 
    pid INTEGER,                 
    user_system STRING,      
    command STRING,              
    arg1 STRING,                 
    arg2 STRING                  
  END RECORD 
  
  -- Command to list processes related to fglrun
  LET l_cmd = "ps -eo pid,user,cmd --no-headers | grep fglrun | grep -v grep | awk '{print $1 \"|\" $2 \"|\" $3 \"|\" $4 \"|\" $5}'"

  -- Create a communication channel
  LET l_channel = base.Channel.create()
  -- Set the delimiter to empty to read the command output as a single string
  CALL l_channel.setDelimiter("")
  -- Open the pipe to execute the command
  CALL l_channel.openPipe(l_cmd, "r")

  LET l_i = 1
  
  -- Read and process each line of command output
  WHILE l_channel.read(l_line)
    -- Create a tokenizer to parse the line
    LET l_tok = base.StringTokenizer.create(l_line, "|")

    LET arr_result[l_i].pid = l_tok.nextToken()
    LET arr_result[l_i].user_system = l_tok.nextToken()
    LET arr_result[l_i].command = l_tok.nextToken()
    LET arr_result[l_i].arg1 = l_tok.nextToken()
    LET arr_result[l_i].arg2 = l_tok.nextToken()
   
    LET l_i = l_i + 1
  END WHILE
  
  -- Close the communication channel
  CALL l_channel.close()

  LET l_message = %"Do you want to close all system programs?", "\n\n", %"Unsaved data may be lost."
  
  -- Asking the user if they want to close the programs
  IF lib_messages.askQuestion(l_message, %"Warning", NULL) THEN
    
    FOR l_i = 1 TO arr_result.getLength()
      -- Check that the PID is valid
      IF NVL(arr_result[l_i].pid, 0) = 0 THEN 
        CONTINUE FOR
      END IF 
      
      -- Set up the command to terminate the process
      LET l_cmd = SFMT("sudo /sbin/runuser -l root -c 'kill -9 %1' 2>/dev/null &", arr_result[l_i].pid)
      
      -- Execute the command to terminate the process
      RUN l_cmd
    END FOR
  END IF

END FUNCTION
