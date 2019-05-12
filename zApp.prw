#include 'protheus.ch'
#include 'zlib.ch' 

/* ======================================================

Classe de Abstra��o de Aplica��o ZLIB AdvPL 

Projetada inicialmente para SmartClient 

====================================================== */

CLASS ZAPP FROM LONGNAMECLASS

   DATA oEnv
   DATA oRunObject
   DATA cMainDef
   DATA aDefs
   DATA aModels
   DATA aControls
   
   METHOD New() 					// Construtor 
   METHOD Run()						// Roda a Aplica��o 
   METHOD Done()                    // Finaliza os objetos 
   
   METHOD SetMainDef()
   METHOD RunMVC()
  
ENDCLASS


// ------------------------------------------------------
// Construtor

METHOD NEW(_oEnv) CLASS ZAPP

::oEnv      := _oEnv
::aDefs     := {}
::aModels   := {}
::aControls := {}

Return self


// ------------------------------------------------------
// Executor da aplica��o
// Recebe o componente a ser executado 

METHOD Run(oRunObject) CLASS ZAPP

::oRunObject := oRunObject

If ::oRunObject = NIL
	UserException("ZAPP:Run() -- AppInterface NOT SET ")
Endif

::oRunObject:Run()

Return


// ------------------------------------------------------
// Finalizador / Desrtrutor

METHOD DONE() CLASS ZAPP

Return

// ------------------------------------------------------
//

METHOD SetMainDef(cDefName)  CLASS ZAPP
::cMainDef := cDefName
Return

// ------------------------------------------------------
//


// ------------------------------------------------------
//

METHOD RunMVC(cDefName,aCoords) CLASS ZAPP
Local oMVCDef 
Local oDefFactory
Local oModelFactory
Local oViewFactory
Local oCtrlFactory   
Local aAuxDefs := {}

// Pega os factories do MVC
oDefFactory := ::oEnv:GetObject("ZDEFFACTORY")
oModelFactory := ::oEnv:GetObject("ZMODELFACTORY")
oViewFactory := ::oEnv:GetObject("ZVIEWFACTORY")
oCtrlFactory := ::oEnv:GetObject("ZCONTROLFACTORY")

// Cria a defini��o do componente
// Futuramente ser� possivel obter a defini��o do dicion�rio de dados 
oMVCDef := oDefFactory:GetNewDef(cDefName)

// Acrescenta defini��es auxiliares no array 
aEval( oMVCDef:GetAuxDefs() ,{|x| aadd(aAuxDefs,x ) })

// Cria o objeto de Modelo da Banco
// Passa a defini��o como par�metro
oMVCModel := oModelFactory:GetNewModel(oMVCDef)

// Na inicializa��o precisa passar o ambiente 
If !oMVCModel:Init( ::oEnv )
	MsgStop( oMVCModel:GetErrorStr() , "Failed to Init Model" )
	Return 
Endif

// Cria a View a partir da defini��o
oMVCView := oViewFactory:GetNewView(oMVCDef)

IF aCoords != NIL
	// Top, left, bottom, right
	oMVCView:SetCoords(aCoords)
Endif

// Cria o controle 
// Por enquanto ele faz a ponte direta entre a View e o Modelo 
// Os eventos atomicos da view ficam na View, apenas 
// os macro eventos sao repassados  

oMVCCtrl := oCtrlFactory:GetNewControl(oMVCView)
oMVCCtrl:AddModel(oMVCModel)

While len(aAuxDefs) > 0 

   // Cria definicoes e modeos auxiliares para acrescentar ao contoler

   cDefName := aAuxDefs[1]
   aDel(aAuxDefs,1)
   aSize(aAuxDefs,len(aAuxDefs)-1)
   
   oMVCDef := oDefFactory:GetNewDef(cDefName)
   aEval( oMVCDef:GetAuxDefs() ,{|x| aadd(aAuxDefs,x ) })
   
   oMVCModel := oModelFactory:GetNewModel(oMVCDef)
   oMVCModel:Init( ::oEnv )

   oMVCCtrl:AddModel(oMVCModel)

Enddo

// Roda a View 
oMVCView:Run()

Return
