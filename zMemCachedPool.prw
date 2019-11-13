/* -------------------------------------------------------------------------------------------

Copyright 2015-2019 J�lio Wittwer ( siga0984@gmail.com | http://siga0984.wordpress.com/ )

� permitido, gratuitamente, a qualquer pessoa que obtenha uma c�pia deste software 
e dos arquivos de documenta��o associados (o "Software"), para negociar o Software 
sem restri��es, incluindo, sem limita��o, os direitos de uso, c�pia, modifica��o, fus�o,
publica��o, distribui��o, sublicenciamento e/ou venda de c�pias do Software, 
SEM RESTRI��ES OU LIMITA��ES. 

O SOFTWARE � FORNECIDO "TAL COMO EST�", SEM GARANTIA DE QUALQUER TIPO, EXPRESSA OU IMPL�CITA,
INCLUINDO MAS N�O SE LIMITANDO A GARANTIAS DE COMERCIALIZA��O, ADEQUA��O A UMA FINALIDADE
ESPEC�FICA E N�O INFRAC��O. EM NENHUM CASO OS AUTORES OU TITULARES DE DIREITOS AUTORAIS
SER�O RESPONS�VEIS POR QUALQUER REIVINDICA��O, DANOS OU OUTRA RESPONSABILIDADE, SEJA 
EM A��O DE CONTRATO OU QUALQUER OUTRA FORMA, PROVENIENTE, FORA OU RELACIONADO AO SOFTWARE. 

                    *** USE A VONTADE, POR SUA CONTA E RISCO ***

Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without 
restriction, including without limitation the rights to use, copy, modify, merge, publish, 
distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom 
the Software is furnished to do so, WITHOUT RESTRICTIONS OR LIMITATIONS. 

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT 
OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE. 

                    ***USE AS YOU WISH , AT YOUR OWN RISK ***

------------------------------------------------------------------------------------------- */



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

