#include  'Protheus.ch'
#include  'zLib.ch'

/* ======================================================

Classe de encapsulamento de acesso ao DBAccess 

Cria ou recupera do Pool uma conex�o para uso. 
Usa contador de referencias para reaproveitar a conexao na aplica��o 

Observa��o : Cada GetDBConn deve estar acompanhado do seu ReleaseDBConn
             para n�o furar o contador e a conex�o ser desfeita 
             antes da hora, ou n�o ser desfeita apos o uso 
             
O objetivo desta classe, al�m de compartilhar conex�es usando um POOL 
� fazer com que a aplica��o apenas obtenha uma conex�o quando 
seja realmente necess�rio, evitando conex�es ociosas. 

====================================================== */

CLASS ZDBACCESS FROM LONGNAMECLASS

   DATA nTopConn      // Handler da conexao com o DBAccess
   DATA cDatabase     // Database da conexao ( MSSQL, ORACLE, MYSQL, etc ) 
   DATA cDbAlias      // Alias / DSN da Conex�o 
   DATA cTopServer    // IP ou Host do DBACcess
   DATA nTopPort      // Porta do DBAccess
   DATA lUsePool      // Usa pool de conex�o do Protheus ?
   DATA cPoolId       // Nome do identificador do POOL 
   DATA nRefs         // Contador de refer�ncias
   DATA cErrorStr     // Ultimo erro registrado 

   METHOD NEW()           // Construtor
   METHOD SETPOOL()       // LIga ou desliga o Pool 
   METHOD GETDBConn()     // Pega uma conex�o para uso 
   METHOD RELEASEDBConn() // Devolve uma conex�o 
   METHOD GetErrorStr()   // Retorna string com ultimo erro 

ENDCLASS

// ------------------------------------------------------
// Construtor 
// Recebe os dados para estabelecer a conexao com o DBACCESS
// Obrigatorio database e alias 
// Server e porta do dbaccess DEFAULT = localhost

METHOD NEW( cDatabase , cAlias, cTopServer, nTopPort) CLASS ZDBACCESS
::nTopConn   := -1
::cDatabase  := cDatabase
::cDbAlias   := cAlias
::cTopServer := "localhost"
::nTopPort   := 7890
::lUsePool   := .F. 
::cPoolId    := ''
::nRefs      := 0 

IF cTopServer != NIL
	::cTopServer := cTopServer
Endif
If nTopPort != NIL 
	::nTopPort   := nTopPort
Endif

Return

// ------------------------------------------------------
// Permite habilitar ou desabilitar o pool de conex�es
// usando no Protheus a fun��o TCGetPool e TCSetPool

METHOD SETPOOL(lSet,cPoolId) CLASS ZDBACCESS
::lUsePool   := lSet
::cPoolId    := cPoolId
Return

// ------------------------------------------------------
// Conecta ou recupera do Pool uma conex�o com o DBAccess

METHOD GETDBConn() CLASS ZDBACCESS

::cErrorStr := ''

If ::nTopConn >= 0 

	// J� estou conectado, verifica se a conex�o est� OK 
	If !TCISCONNECTED(::nTopConn)
		UserException("*** DBACCESS CONNECTION LOST ***")
	Endif

	// Seta a conexcao como ativa e incrementa contador 
	TCSetConn(::nTopConn)
	::nRefs++
	Return .T. 

Endif

// Ainda nao estou conectado 
// Verifica se recupera conexao do pool ou cria nova 

IF ::lUsePool

	// Tenta recupera do POOL
	::nTopConn := TCGetPool(::cPoolId)
	
	If ::nTopConn >= 0 
		// Em caso de sucesso, 
		// Seta a conexcao como ativa e incrementa contador 
		conout("[ZDBACCESS] DBConnection from POOL - "+cValToChar(::nTopConn))
		TCSetConn(::nTopConn)
		::nRefs++
		Return .T. 
	Endif
	
Endif

// Se eu nao estou usando o pool, ou nao deu pra recuperar 
// uma conex�o do pool ... Cria uma nova 

::nTopConn := TCLink(::cDatabase+"/"+::cDBAlias,::cTopServer,::nTopPort)
	
If ::nTopConn >= 0 
	// Em caso de sucesso, 
	// Seta a conexcao como ativa e incrementa contador 
	conout("[ZDBACCESS] New DBConnection Created - "+cValToChar(::nTopConn))
	TCSetConn(::nTopConn)
	::nRefs++
	Return .T.
Endif

::cErrorStr := "TCLINK ERROR ("+cValToChar(::nTopConn)+")"

Return .F. 

// ------------------------------------------------------
// Desconecta ou devolve ao Pool uma conex�o com o DBAccess

METHOD ReleaseDBConn() CLASS ZDBACCESS

::cErrorStr := ''

IF ::nTopConn < 0
	// J� est� desconectado
	Return
Endif

// Decrementa contador de referencias 
::nRefs--

If ::nRefs < 1

	// N�o h� mais uso da conex�o, 
	// devolve ao POOL ou desconecta 
	
	If ::lUsePool
		
		conout("[ZDBACCESS] SEND DBConnection TO POOL - "+cValToChar(::nTopConn))
		tcSetConn(::nTopConn)
		xRet := TCSetPool(::cPoolId)
		conout(xRet)
		
	Else
		
		conout("[ZDBACCESS] UNLINK DBConnection - "+cValToChar(::nTopConn))
		tcUnlink(::nTopConn)
		
	Endif
	
	::nTopConn := -1
	
Endif

Return


METHOD GetErrorStr() CLASS ZDBACCESS
Return ::cErrorStr

