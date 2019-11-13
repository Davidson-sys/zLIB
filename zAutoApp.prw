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



#include 'protheus.ch'
#include 'zlib.ch' 

/* ======================================================

Execucao automatica de aplicativo MCV SmartClient

====================================================== */

CLASS ZAUTOAPP FROM LONGNAMECLASS
 
   DATA bDefFactory 

   METHOD New() 					// Construtor 
   METHOD SetDefFactory()
   METHOD RunMVC()					// Roda a Aplica��o 
  
ENDCLASS



METHOD New() CLASS ZAUTOAPP 
Return self

METHOD SetDefFactory(bDefBlock) CLASS ZAUTOAPP
::bDefFactory := bDefBlock
Return


METHOD RunMVC(cDefName,aCoords) CLASS ZAUTOAPP
Local oEnv
Local oApp

// Cria o ambiente e inicializa��es necess�rias 
oEnv := ZLIBENV():New()
oEnv:SetEnv()
oEnv:InitMemCache()
oEnv:InitDBConn()
oEnv:InitMVCFactory(::bDefFactory)

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

