# Esta função encerra todos os programas relacionados ao fglrun que estão em execução no sistema.
# Ela lista os processos em execução, obtém informações como PID, usuário do sistema, comando e argumentos,
# e oferece ao usuário a opção de encerrar todos os programas. Se confirmado, a função encerra os processos
# utilizando o comando 'kill -9'. Esta ação deve ser realizada com cuidado, pois quaisquer dados não salvos podem ser perdidos.
FUNCTION encerrarTodosProgramasSistema()

  DEFINE l_cmd STRING            
  DEFINE l_channel base.Channel 
  DEFINE l_linha STRING          
  DEFINE l_tok base.StringTokenizer 
  DEFINE l_i SMALLINT            
  DEFINE l_mensagem STRING
  
  DEFINE arr_result DYNAMIC ARRAY OF RECORD 
    pid INTEGER,                 -- PID do processo
    usuario_sistema STRING,      -- Usuário do sistema
    comando STRING,              -- Comando associado ao processo
    arg1 STRING,                 -- Argumento 1 do comando
    arg2 STRING                  -- Argumento 2 do comando
  END RECORD 
  
  -- Comando para listar processos relacionados ao fglrun
  LET l_cmd = "ps -eo pid,user,cmd --no-headers | grep fglrun | grep -v SVBV00 | grep -v grep | grep -v /bin/sh | awk '{print $1 \"|\" $2 \"|\" $3 \"|\" $4 \"|\" $5}'"

  -- Criar canal de comunicação
  LET l_channel = base.Channel.create()
  -- Definir o delimitador como vazio para ler a saída do comando como uma única string
  CALL l_channel.setDelimiter("")
  -- Abrir o pipe para executar o comando
  CALL l_channel.openPipe(l_cmd, "r")

  LET l_i = 1
  
  -- Ler e processar cada linha da saída do comando
  WHILE l_channel.read(l_linha)
    -- Criar um tokenizador para analisar a linha
    LET l_tok = base.StringTokenizer.create(l_linha, "|")

    LET arr_result[l_i].pid = l_tok.nextToken()
    LET arr_result[l_i].usuario_sistema = l_tok.nextToken()
    LET arr_result[l_i].comando = l_tok.nextToken()
    LET arr_result[l_i].arg1 = l_tok.nextToken()
    LET arr_result[l_i].arg2 = l_tok.nextToken()
   
    LET l_i = l_i + 1
  END WHILE
  
  -- Fechar o canal de comunicação
  CALL l_channel.close()

  LET l_mensagem = %"Deseja encerrar todos os programas do sistema?", "\n\n", %"Dados não salvos podem ser perdidos."
  
  -- Perguntar ao usuário se deseja encerrar os programas
  IF lib_messages.askQuestion(l_mensagem, %"Aviso", NULL) THEN
    
    FOR l_i = 1 TO arr_result.getLength()
      -- Verificar se o PID é válido
      IF NVL(arr_result[l_i].pid, 0) = 0 THEN 
        CONTINUE FOR
      END IF 
      
      -- Montar o comando para encerrar o processo
      LET l_cmd = SFMT("sudo /sbin/runuser -l root -c 'kill -9 %1' 2>/dev/null &", arr_result[l_i].pid)
      
      -- Executar o comando para encerrar o processo
      RUN l_cmd
    END FOR
  END IF

END FUNCTION
