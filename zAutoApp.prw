#include 'protheus.ch'
#include 'zlib.ch' 

/* ======================================================

Execucao automatica de aplicativo MCV SmartClient

====================================================== */

CLASS ZAUTOAPP FROM LONGNAMECLASS

   METHOD New() 					// Construtor 
   METHOD RunMVC()					// Roda a Aplica��o 
  
ENDCLASS



METHOD New() CLASS ZAUTOAPP 
Return self


METHOD RunMVC(cDefName,aCoords) CLASS ZAUTOAPP
Local oEnv
Local oApp

// Cria o ambiente e inicializa��es necess�rias 
oEnv := ZLIBENV():New()
oEnv:SetEnv()
oEnv:InitMemCache()
oEnv:InitDBConn()
oEnv:InitMVCFactory()

// Cria a aplica��o Client 
oApp := ZAPP():New(oEnv)

// Roda o MVC baseado na definicao 
oApp:RunMVC(cDefName,aCoords)

// Encerra a aplica��o 
oApp:Done()
FreeObj(oApp)

// Encerra o ambiente -- Junto com os objetos amarrados nele 
// O Done() de cada Factory limpa os objetos 
oEnv:Done()
FreeObj(oEnv)

Return

