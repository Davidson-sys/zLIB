
#ifndef zLibMisc_CH

  #define zLibMisc_CH

  /* Setar observa��es para o processo atual no Monitor do Protheus */

  #xtranslate SetMntObs( <cObs> ) => PtInternal( 1 , <cObs> )

  /* constante PI com 8 casas decimais */

  #DEFINE PI 3.14159265 // ACos(-1)

  /* Pseudo-fun��o para troca de conte�do entre vari�veis */ 

  #TRANSLATE ZSWAP( <X> , <Y> , <S> ) =>  ( <S> := <X> , <X> := <Y> , <Y> := <S> )

#endif

