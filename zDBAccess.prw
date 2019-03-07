#include  'Protheus.ch'
#include  'zLib.ch'

/* ======================================================

Classe de encapsulamento de acesso ao DBAccess 

Cria ou recupera do Pool uma conex�o para uso. 
Usa contador de referencias para reaproveitar a conexao na aplica��o 

Observa��o : Cada Connect deve estar acompanhado do seu Disconnect
             para n�o furar o contador e a conex�o ser desfeita 
             antes da hora, ou n�o ser desfeita apos o uso 
             
O objetivo desta classe, al�m de compartilhar conex�es usando um POOL 
� fazer com que a aplica��o apenas obtenha uma conex�o quando 
seja realmente necess�rio, evitando conex�es ociosas. 

Cada instancia do ZDBACCESS controla e mantem ativa apenas 
uma conexao com o DBACCESS. Para abrir duas conexoes, sao necessarias
duas instancias da classe no ambiente 

[TODO] Rever questao de transacionamento em multiplas conexoes 
       a TCCommit abre transacionamento em todas as conexoes ativas do dbaccess

====================================================== */

CLASS ZDBACCESS FROM LONGNAMECLASS

   DATA nTopConn      // Handler da conexao com o DBAccess
   DATA cDBDatabase   // Database da conexao ( MSSQL, ORACLE, MYSQL, etc ) 
   DATA cDbAlias      // Alias / DSN da Conex�o 
   DATA cDBServer     // IP ou Host do DBACcess
   DATA nDBPort       // Porta do DBAccess
   DATA lUsePool      // Usa pool de conex�o do Protheus ?
   DATA cPoolId       // Nome do identificador do POOL 
   DATA nRefs         // Contador de refer�ncias
   DATA nTrnCount     // Contador de transa��es 
   DATA cError        // Ultimo erro registrado 
   DATA oLogger       // Objeto de log 
   DATA aCfgDefault   // Configura��es DEFAULT ( INI ) 

   METHOD NEW()           // Construtor
   METHOD SETPOOL()       // LIga ou desliga o Pool 
   METHOD Connect()       // Cionecta ou Pega uma conex�o do pool para uso 
   METHOD Disconnect()    // Desconecta ou Devolve uma conex�o ao pool 
   METHOD SetActive()     // Seta esta conexao como ativa no ambiente 
   METHOD GetErrorStr()   // Retorna string com ultimo erro 
   METHOD GetTable()      // Retorna um objeto de tabela a partir da defini��o 
   METHOD IsConnected()   // Retorna .T. se eu estou conectado 
   METHOD Done()          // Fecha e encerra tudo 

   METHOD BeginTran()     // Inicia transacao 
   METHOD CommitTran()    // Commita e encerra a transa��o 
   METHOD RollbackTran()  // Faz rollback e encerra a transa��o 
   METHOD InTransact()    // Reetorna .T. caso esteja em transa��o 
   
   METHOD _SetError()     // Seta ocorrencia de erro 
   METHOD _ReadCfg()      // Le configuracao default no appserver.ini

ENDCLASS

// ------------------------------------------------------
// Construtor 
// Recebe os dados para estabelecer a conexao com o DBACCESS
// Obrigatorio database e alias 
// Server e porta do dbaccess DEFAULT = localhost

METHOD NEW( cDBDatabase , cAlias, cDBServer, nDBPort) CLASS ZDBACCESS
::nTopConn   := -1
::cDBDatabase  := cDBDatabase
::cDbAlias   := cAlias
::cDBServer := cDBServer
::nDBPort   := nDBPort
::lUsePool   := .F. 
::cPoolId    := ''
::nRefs      := 0 
::nTrnCount  := 0 
::cError     := ''

// Le configura��o default 
::_ReadCfg()

// Todas as configura��es s�o opcionais
// As configura��es que n�o forem informadas 
// ser�o obtidas ano appserver.ini

If empty(::cDBDatabase)
	::cDBDatabase  := ::aCfgDefault[1]
Endif
If empty(::cDbAlias )
	::cDbAlias   := ::aCfgDefault[2]
Endif
If empty(::cDBServer)
	::cDBServer  := ::aCfgDefault[3]
Endif
If empty(::nDBPort  )
	::nDBPort    := ::aCfgDefault[4]
Endif

// Cria uma instancia de Logger para a classe DBAccess
::oLogger := ZLOGGER():New("ZDBACCESS")
::oLogger:Write("NEW","DBDatabase'="+cValToChar(cDBDatabase)+",DBAlias="+cValToChar(cAlias)+",DBServer="+cValToChar(cDBServer)+",DBPort="+cValToChar(nDBPort)+";")

Return

// ------------------------------------------------------
// Permite habilitar ou desabilitar o pool de conex�es
// usando no Protheus a fun��o TCGetPool e TCSetPool

METHOD SETPOOL(lSet,cPoolId) CLASS ZDBACCESS
If ::oLogger != NIL 
	::oLogger:Write("SETPOOL","Set="+cValToChar(lSet)+",PoolID="+cPoolId+";")
Endif
::lUsePool   := lSet
::cPoolId    := cPoolId
Return

// ------------------------------------------------------
// Conecta ou recupera do Pool uma conex�o com o DBAccess

METHOD Connect() CLASS ZDBACCESS

If ::oLogger != NIL 
	::oLogger:Write("CONNECT","Create Database Connection")
Endif

::cError := ''

If ::nTopConn >= 0 

	If ::oLogger != NIL 
		::oLogger:Write("CONNECT","Connection already established")
	Endif

	// Seta a conexao corrente baseado no handler 
	If !::SetActive()
		Return .F.
	Endif
	
	::nRefs++
	Return .T. 

Endif

// Ainda nao estou conectado 
// Verifica se recupera conexao do pool ou cria nova 

IF ::lUsePool

	// Tenta recuperar do POOL de Conexoes
	::nTopConn := TCGetPool(::cPoolId)
	
	If ::nTopConn >= 0 
		// Em caso de sucesso, 
		// Seta a conexcao como ativa e incrementa contador 
		If ::oLogger != NIL 
			::oLogger:Write("CONNECT","DBConnection from POOL - Handler "+cValToChar(::nTopConn))
		Endif

		// Seta a conexao corrente baseado no handler 
		If !::SetActive()
			Return .F.
		Endif
		
		::nRefs++
		Return .T. 
	Endif
	
Endif

// Se eu nao estou usando o pool, ou nao deu pra recuperar 
// uma conex�o do pool ... Cria uma nova 

::nTopConn := TCLink(::cDBDatabase+"/"+::cDBAlias,::cDBServer,::nDBPort)
	
If ::nTopConn >= 0 
	// Em caso de sucesso, 
	// Seta a conexcao como ativa e incrementa contador 
	If ::oLogger != NIL 
		::oLogger:Write("CONNECT","New DBConnection Created - Handler "+cValToChar(::nTopConn))
	Endif
	TCSetConn(::nTopConn)
	::nRefs++
	Return .T.
Endif

::_SetError("TCLINK ERROR ("+cValToChar(::nTopConn)+")")

Return .F. 

// ------------------------------------------------------
// Desconecta ou devolve ao Pool uma conex�o com o DBAccess

METHOD Disconnect() CLASS ZDBACCESS
Local lOk

::cError := ''

IF ::nTopConn < 0
	// J� est� desconectado ?! ... 
	::nRefs := 0 
	Return
Endif

If ::oLogger != NIL 
	::oLogger:Write("DISCONNECT","Release current connection - Handler "+cValToChar(::nTopConn))
Endif

// Decrementa contador de referencias
::nRefs--

If ::nRefs < 1

	// N�o h� mais uso da conex�o, 
	// devolve ao POOL ou desconecta 
	
	If ::lUsePool
		
		If ::oLogger != NIL 
			::oLogger:Write("DISCONNECT","SEND DBConnection TO POOL - Handler "+cValToChar(::nTopConn))
		Endif
		
		// Seleciona a conexao e manda pro POOL 
		tcSetConn(::nTopConn)
		lOk := TCSetPool(::cPoolId)
		
		IF !lOk
			If ::oLogger != NIL 
				::oLogger:Write("DISCONNECT","Failed to SEND DBConnection TO POOL -- UNLINKING ...")
			Endif
			tcUnlink(::nTopConn)
		Endif
		
	Else
		
		If ::oLogger != NIL 
			::oLogger:Write("DISCONNECT","UNLINK DBConnection - Handler "+cValToChar(::nTopConn))
		Endif

		tcUnlink(::nTopConn)
		
	Endif
	
	::nTopConn := -1
	
Endif

Return


// ----------------------------------------------------------
// Seta a conexao do Handler atual como ativa

METHOD SetActive() CLASS ZDBACCESS

::cError := ''

If ::oLogger != NIL 
	::oLogger:Write("SETACTIVE","Set Active Connection - Handler "+cValToChar(::nTopConn))
Endif

IF !::IsConnected()
	Return .F. 
Endif

// Seta a conexao atual como ativa 
TCSetConn(::nTopConn)

Return .T. 

// ----------------------------------------------------------
// Recupera a ultima mensagem de erro 

METHOD GetErrorStr() CLASS ZDBACCESS
Return ::cError

// ----------------------------------------------------------
// Cria o objeto da tabela a partir da defini��o 
// O Driver DBAccess gera uma tabela ZTOPFILE 

METHOD GetTable(cTable,oTableDef)   CLASS ZDBACCESS
Local oTopTable 

If ::oLogger != NIL 
	::oLogger:Write("GETTABLE","Get Table Object|Table="+cTable+";")
Endif

// Cria o objeto da tabela
oTopTable := ZTOPFILE():New(cTable,oTableDef)

// O objeto da tabela est� amarrado a esta conexao 
oTopTable:SetDBConn(self)

Return oTopTable

// ----------------------------------------------------------

METHOD IsConnected()  CLASS ZDBACCESS

::cError := ''
IF ::nTopConn < 0 
	::_SetError('DBAccess NOT CONNECTED')
	Return .F. 
Endif

If !TcIsConnected(::nTopConn)
	::_SetError("DBACCESS CONNECTION LOST")
	Return .F. 
Endif

Return .T. 

// ----------------------------------------------------------

METHOD Done() CLASS ZDBACCESS

If ::oLogger != NIL 
	::oLogger:Write("DONE","Finish Object|Refs="+cValToChaR(::nRefs)+";")
Endif

While ::nRefs > 0 
	// Enquanto houver referencias de conexao em uso
	// Solta as conexoes 
	::Disconnect()
Enddo

Return

// ----------------------------------------------------------

METHOD BeginTran() CLASS ZDBACCESS

::cError := ''

If ::oLogger != NIL 
	::oLogger:Write("BEGINTRAN","Begin Transaction|nTrnCount="+cValToChar(::nTrnCount)+";")
Endif

If !::IsConnected()
	::_SetError("ZDBACCESS:BEGINTRAN() ERROR - NOT CONNECTED")
	Return .F.
Endif

::nTrnCount++

If ::nTrnCount == 1
	// Estou abrindo a primeira transa��o 
	// Abre a transa��o na conexao atual 
	TCSetConn(::nTopConn)
	TCCommit(1)
Endif

Return .T. 

// ----------------------------------------------------------

METHOD CommitTran() CLASS ZDBACCESS

If ::oLogger != NIL 
	::oLogger:Write("COMMITTRAN","Commit Transaction|nTrnCount="+cValToChar(::nTrnCount)+";")
Endif

::nTrnCount--

IF ::nTrnCount == 0

	// Estou encerrando a ultima transacao 
	// Faz o Commit efetivamente e encerra a transa��o 
	TCSetConn(::nTopConn)
	
	// Faz flush de tudo que tem pra fazer 
	DBCommitAll()

	// Commita e encerra a transa��o 	
	TCCommit(2)
	TCCommit(4)

	// Agora solta lock de todos mundo 
	// TODO - Rever mecanismo de lock 
	DBUnlockAll()

Endif

Return .T. 


// ----------------------------------------------------------

METHOD RollbackTran() CLASS ZDBACCESS

If ::oLogger != NIL 
	::oLogger:Write("ROLLBACKTRAN","RollBack Transaction|nTrnCount="+cValToChar(::nTrnCount)+";")
Endif

IF ::nTrnCount > 0
   
	// Estou em transacao, e vou fazer rollback 
	// Seleciono a conexao ativa 
	TCSetConn(::nTopConn)
	
	// Faz flush de tudo que tem pra fazer 
	DBCommitAll()

	// Faz Rollback e encerra a transa��o 	
	TCCommit(3)
	TCCommit(4)

	// E Agora solta lock de todos mundo 
	// TODO - Rever mecanismo de lock 
	DBUnlockAll()

	// Decrementa contador de transacoes ativas  
	::nTrnCount-- 
	
	If ::nTrnCount > 0 
		// Se eu estou em transacao encadeada, 
		// OPA ... deu ruim .. j� era ... 
		UserException("*** ROLLBACK IN CASCADE TRANSACTION -- EXIT *** ")
	Endif

Endif

Return


// ----------------------------------------------------------
// Retorna .T. se a conexao atual est� em transa��o 
METHOD InTransact() CLASS ZDBACCESS
Return ::nTrnCount > 0 

// ----------------------------------------------------------
// Seta ocorrencia de erro do Driver 

METHOD _SetError(cError) CLASS ZDBACCESS
::cError := cError
If ::oLogger != NIL 
	::oLogger:Write("SETERROR",cError)
Endif
Return


// ----------------------------------------------------------
// Le as configuracoes default de DBAccess do APPSERVER.INI

METHOD _ReadCfg()  CLASS ZDBACCESS
Local cDatabase
Local cAlias
Local cServer
Local nPort

// Le primeiro as configuracoes da se��o [DBACCESS]

cDatabase := GetPVProfString("DBACCESS","DATABASE","",GETSRVININAME())
cAlias    := GetPVProfString("DBACCESS","ALIAS","",GETSRVININAME())
cServer   := GetPVProfString("DBACCESS","SERVER","localhost",GETSRVININAME())
nPort     := val(GetPVProfString("DBACCESS","PORT","7890",GETSRVININAME()))

// Agora verifica se foi configuraco algo especifico no environment atual 

cDatabase := GetSrvProfString("DBDATABASE",cDatabase)
cAlias    := GetSrvProfString("DBALIAS",cAlias)
cServer   := GetSrvProfString("DBSERVER",cServer)
nPort     := val( GetSrvProfString("DBPORT",cValToChar(nPort)) )

// Monta o array com a configura��o DEFAULT 
::aCfgDefault:= { cDatabase , cAlias , cServer , nPort }

Return 

