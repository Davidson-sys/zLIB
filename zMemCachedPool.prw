#include "protheus.ch"

/* ==============================================================================
Classe      ZMEMCACHEDPOOL
Autor       Julio Wittwer
Data        01/2019
Descri��o   Encapsula objeto client do MemCache, usando contador de referencias. 

Os programas que consomem o cache devem obter a inst�ncia usando :

   ZMEMCACHEDPOOL():GetCache( @oMemCache , @cError )

E ap�s o uso, fazer release da instancia usando : 

   ZMEMCACHEDPOOL():ReleaseCache( @oMemCache )

==============================================================================*/


STATIC _oMemCache        // Objeto do Cache em  "Cache"
STATIC _nRefCount := 0   // Contador de referencias 

CLASS ZMEMCACHEDPOOL FROM LONGNAMECLASS

   METHOD GetCache()
   METHOD ReleaseCache()
   METHOD RefCount() 
   
ENDCLASS

// ----------------------------------------------------
// Obtem por referencia uma instancia do cache, e em caso de
// falha, obtem o erro tamb�m por refe�ncia 

METHOD GetCache( oCache , cError ) CLASS ZMEMCACHEDPOOL

// Inicializa parametros passados por refer�ncia
oCache := NIL
cError := ""

IF _oMemCache != NIL
	// J� tenho um objeto de conexao 
	// Verifico se a conex�o est� OK
	IF _oMemCache:IsConnected()
		// Conex�o OK, incremento contador de referencias
		// e retorno 
		_nRefCount++
		oCache := _oMemCache
	Else
		// A conex�o n�o est� OK
		// Limpa o objeto e passa para a proxima parte 
		FreeObj(_oMemCache)
		_oMemCache := NIL
	Endif
Endif

IF _oMemCache == NIL
	// Nao tenho o objeto de conexao
	// Crio o objeto e tento conectar 
	_oMemCache := ZMEMCACHED():New("localhost",11211)
	IF _oMemCache:Connect()
		// Conex�o OK,incrementa contador e atribui o objeto 
		_nRefCount++
		oCache := _oMemCache
	Else
		// Nao conectou, recupera o erro, alimenta cError 
		// e mata este objeto
		cError := _oMemCache:GetErrorStr()
		FreeObj(_oMemCache)
		_oMemCache := NIL
	Endif
Endif

Return 


// ----------------------------------------------------
// Solta a refer�ncia do cache em uso, anula a variavel 
// recebida por referencia, e caso o contador 
// seja menor que um, limpa o objeto da mem�ria 
METHOD ReleaseCache( oCache ) CLASS ZMEMCACHEDPOOL

IF oCache != NIL 
	oCache := NIL
	_nRefCount--
	IF _nRefCount < 1 
		_oMemCache:Disconnect()
		FreeObj(_oMemCache)
		_oMemCache := NIL
	Endif
Endif

Return 


// ----------------------------------------------------
// Retorna o contador de referencias de uso 
// do objeto do Cache 

METHOD RefCount() CLASS ZMEMCACHEDPOOL
Return _nRefCount

