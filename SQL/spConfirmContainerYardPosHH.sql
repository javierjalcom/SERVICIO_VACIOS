/*
Highlight and execute the following statement to drop the procedure
before executing the create statement.

DROP PROCEDURE spConfirmContainerYardPosHH

*/

CREATE PROCEDURE spConfirmContainerYardPosHH @intUniversalId      udtIdentifier,
                                             @strYardPosition     udtStringIdentifier,
                                             @strBlockIdentifier  udtPositionIdentifier,
                                             @strInvPosRow        udtPositionIdentifier,
                                             @strInvPosBay        udtPositionIdentifier,
                                             @strInvPosStow       udtPositionIdentifier,
                                             @astrUserName        udtUserName,
                                             @intErrorCode        INTEGER OUTPUT
AS 
/*
  NOMBRE      : spConfirmContainerYardPos
  DESCRIPCION : Confirma la posición del Contenedor en Patio
  PARAMETROS  : --------------------------------------------------------------------
                   PARAMETROS                   DESCRIPCIÓN
                --------------------------------------------------------------------
                @intUniversalId      : Id Universal del Contendor que se le actualizara la Posición
                @strYardPosition     : Posición de Contenedor Completa
                @strBlockIdentifier  : Bloque de la Posición
                @strInvPosRow        : Fila de la Posición
                @strInvPosBay        : Bahia de la Posición
                @strInvPosStow       : Estiba de la Posición
                
                OUTPUT @intErrorCode         : Especifica el error que ocurrio durante el SP

                Códigos de Error <@intErrorCode> posibles :
                    --Error 1: El Id Universal del Contenedor no tiene informacion valida
                    --Error 2: Error al Actualizar la Posicion del Contenedor  
                    --Error 3: Error al Actualizar el Historico de la Posicion del Contenedor
                    --Error 4: Error al Actualizar el Edo. Admvo. del Contenedor
                    --Error 5: Al Actualizar el Id Universal de Cont en Maniobras de Patio

  TABLAS : 

  VALORES DE RETORNO: 
           VALOR -TIPO DE DATO    -DESCRIPCION 
            0     INTEGER    : Para Caso de Exito del SP 
            1     INTEGER    : Para Caso de Error del SP

  FECHA DE CREACION     :  30-SEP-2005 Alberto Ramirez
  FECHA DE MODIFICACION :  30-SEP-2005 Alberto Ramirez
*/

DECLARE @SUCCESS                INTEGER             -- Caso de Exito del SP
DECLARE @FAILURE                INTEGER             -- Caso de Error del SP

DECLARE @lint_ContUniversalId   udtIdentifier
DECLARE @lintRtnStatus          udtIdentifier
DECLARE @lstrActualYardPos      udtYardPosition
DECLARE @lstrHisPosComments     udtShortString
DECLARE @lintErrorCode          integer

DECLARE @lstrMsg     udtShortString

BEGIN 
  SELECT @intErrorCode = 0

  SELECT @SUCCESS = 0 -- Caso de Exito del SP
  SELECT @FAILURE = 1 -- Caso de Error del SP

  --Checa si las Transacciones estan Encadenadas  
  IF @@TRANCHAINED=1   BEGIN
     SELECT @intErrorCode = -1

     --Si estan Encadenadas Aborta el SP  
     GOTO LBL_END
  END
    
    SELECT @lstrMsg = 'Validar si el contenedor es correcto; Error Code = ' + CONVERT(VARCHAR(32), @intErrorCode)

    PRINT @lstrMsg

  --Validar el Universal Id
  IF IsNull(@intUniversalId, 0) <=0 BEGIN
     SELECT @intErrorCode = 1 --Error 1: El Id Universal del Contenedor no tiene informacion valida

     GOTO LBL_END
  END

  SELECT @lstrMsg = 'Ver si es atado; Error Code = ' + CONVERT(VARCHAR(32), @intErrorCode)

  PRINT @lstrMsg

  IF EXISTS (SELECT tblclsContainerInvAttachedItem.intContInvAttachId
               FROM tblclsContainerInvAttachedItem,
                    tblclsContainerInventory
              WHERE tblclsContainerInvAttachedItem.intContainerUniversalId = tblclsContainerInventory.intContainerUniversalId AND
                    tblclsContainerInventory.blnContainerInvActive = 1 AND 
                    tblclsContainerInvAttachedItem.intContainerUniversalId =  @intUniversalId) 
  BEGIN 
    SELECT @lstrMsg = 'Es atado; Error Code = ' + CONVERT(VARCHAR(32), @intErrorCode)

    PRINT @lstrMsg

    --El contenedor es un Atado, se actualizan las posiciones de todos los contenedores del atado.
    DECLARE curContAttached CURSOR FOR 
    SELECT tblclsContainerInventory.intContainerUniversalId
      FROM tblclsContainerInventory,
           tblclsContainerInvAttachedItem,
           tblclsContainerInvAttached
     WHERE tblclsContainerInventory.intContainerUniversalId = tblclsContainerInvAttachedItem.intContainerUniversalId AND
           tblclsContainerInvAttachedItem.intContInvAttachId = tblclsContainerInvAttached.intContInvAttachId AND
           tblclsContainerInventory.blnContainerInvActive   = 1 AND
           tblclsContainerInvAttached.intContInvAttachId IN (
           SELECT tblclsContainerInvAttachedItem.intContInvAttachId
             FROM tblclsContainerInvAttachedItem
            WHERE intContainerUniversalId =  @intUniversalId )

    OPEN curContAttached

    FETCH curContAttached INTO @lint_ContUniversalId

    SELECT @lstrActualYardPos = tblclsContainerInventory.strContainerInvYardPositionId   
      FROM tblclsContainerInventory
     WHERE tblclsContainerInventory.intContainerUniversalId = @lint_ContUniversalId


    WHILE @@sqlstatus = 0 AND @intErrorCode = 0  BEGIN
      BEGIN TRAN trnConfirmContYardPos

      --Evitar Dirty Reads  
      SET TRANSACTION ISOLATION LEVEL 1 

      --Actualizar la Posicion del Contendor
      UPDATE  tblclsContainerInventory 
      SET     strContainerInvYardPositionId  = @strYardPosition,  
              strContainerInvBlockIdentifier = @strBlockIdentifier, 
              strContainerInvPosRow          = @strInvPosRow,          
              strContainerInvPosBay          = @strInvPosBay,          
              strContainerInvPosStow         = @strInvPosStow          
      WHERE   intContainerUniversalId = @lint_ContUniversalId AND 
              blnContainerInvActive   = 1

      --Valida si ocurrio algun error durante la actualzacion
      IF @@Error<>0 
      BEGIN
        ROLLBACK TRAN trnConfirmContYardPos          --Deshace el Update

        SELECT @intErrorCode = 2 --Error 2 : Error al Actualizar la Posicion del Contenedor

        SELECT @lstrMsg = 'Atado; Error al Actualizar la Posicion del Contenedor : ' + 
            CONVERT(VARCHAR(32), @lint_ContUniversalId)

        PRINT @lstrMsg

        GOTO LBL_END          --Caso de Falla
      END

      COMMIT TRAN trnConfirmContYardPos

      SELECT @lstrMsg = 'ATADOS; ACTUALIZANDO POSICION : ' + CONVERT(VARCHAR(32), @lint_ContUniversalId)

      PRINT @lstrMsg


      SELECT @lstrHisPosComments = 'Se Confirmó la Ubicación en ' + @strYardPosition

      EXECUTE @lintRtnStatus = spUpdateHistoryContPosition @lint_ContUniversalId,
                                                 @strYardPosition,
                                                 @strBlockIdentifier,
                                                 @strInvPosRow,
                                                 @strInvPosBay,
                                                 @strInvPosStow,
                                                 @lstrHisPosComments,
                                                 @astrUserName

      IF @lintRtnStatus <> 0 
      BEGIN
        --ROLLBACK TRAN trnConfirmContYardPos  --Deshace el Update
        SELECT @intErrorCode = 3 --Error 3 : Error al Actualizar el Historico de la Posicion del Contenedor
        PRINT 'Atado; Error al Actualizar el Historico de la Posicion del Contenedor'

        CLOSE curContAttached
        DEALLOCATE CURSOR curContAttached

        GOTO LBL_END        --Caso de Falla
      END

      SELECT @lstrMsg = 'ATADOS; ACTUALIZADO EL HISTORICO: ' + CONVERT(VARCHAR(32), @lint_ContUniversalId)
      PRINT @lstrMsg

      EXECUTE @lintRtnStatus = spUpdateContainerStatus @lint_ContUniversalId, 1, '', 'CONFUBI', @astrUserName

      IF @lintRtnStatus <> 0 
      BEGIN
        --ROLLBACK TRAN          --Deshace el Update
        SELECT @intErrorCode = 4 --Error 4 : Error al Actualizar el Edo. Admvo. del Contenedor
        PRINT 'Atado; Error al Actualizar el Edo. Admvo. del Contenedor'

        CLOSE curContAttached
        DEALLOCATE CURSOR curContAttached

        GOTO LBL_END        --Caso de Falla
      END

      SELECT @lstrMsg = 'ATADOS; ACTUALIZADO EL EDO. ADMVO.: ' + CONVERT(VARCHAR(32), @lint_ContUniversalId)
      PRINT @lstrMsg

      FETCH curContAttached INTO @lint_ContUniversalId
    END

    CLOSE curContAttached
    DEALLOCATE CURSOR curContAttached
  END
  ELSE
  BEGIN
      SELECT @lstrMsg = 'No es atado.'
      
      PRINT @lstrMsg

      --Actualizar la posicion del contenedor
      SELECT @lstrActualYardPos = tblclsContainerInventory.strContainerInvYardPositionId   
        FROM tblclsContainerInventory
       WHERE tblclsContainerInventory.intContainerUniversalId = @intUniversalId

      BEGIN TRAN trnConfirmContYardPos

      --Evitar Dirty Reads  
      SET TRANSACTION ISOLATION LEVEL 1 
    
      --Actualizar la Posicion del Contendor
      UPDATE  tblclsContainerInventory 
      SET     strContainerInvYardPositionId  = @strYardPosition,  
              strContainerInvBlockIdentifier = @strBlockIdentifier, 
              strContainerInvPosRow          = @strInvPosRow,          
              strContainerInvPosBay          = @strInvPosBay,          
              strContainerInvPosStow         = @strInvPosStow          
      WHERE   intContainerUniversalId = @intUniversalId AND 
              blnContainerInvActive   = 1

      --Valida si ocurrio algun error durante la actualizacion
      IF @@Error<>0 
      BEGIN
        ROLLBACK TRAN  trnConfirmContYardPos --Deshace el Update
        SELECT @intErrorCode = 2 --Error 2 : Al Actualizar la Posicion del Contenedor
        PRINT 'Error al Actualizar la Posicion del Contenedor'

        GOTO LBL_END          --Caso de Falla
      END

      COMMIT TRAN trnConfirmContYardPos

      SELECT @lstrHisPosComments = 'Se Confirmó la Ubicación en ' + @strYardPosition

      EXECUTE @lintRtnStatus = spUpdateHistoryContPosDISCHH @intUniversalId,
                                                 @strYardPosition,
                                                 @strBlockIdentifier,
                                                 @strInvPosRow,
                                                 @strInvPosBay,
                                                 @strInvPosStow,
                                                 @lstrHisPosComments,
                                                 @astrUserName

      IF @lintRtnStatus <> 0
      BEGIN
        --ROLLBACK TRAN  trnConfirmContYardPos     --Deshace el Update
        SELECT @intErrorCode = 3 --Error 3 : Al Actualizar el Historico de la Posicion del Contenedor
        PRINT 'Error al Actualizar el Historico de la Posicion del Contenedor'

        GOTO LBL_END        --Caso de Falla
      END

      SELECT @lstrMsg = 'ACTUALIZADO EL HISTORICO: ' + CONVERT(VARCHAR(32), @lint_ContUniversalId)
      PRINT @lstrMsg

      EXECUTE @lintRtnStatus = spUpdateContainerStatus @intUniversalId, 1, '', 'CONFUBI', @astrUserName

      IF @lintRtnStatus <> 0 
      BEGIN
        --ROLLBACK TRAN          --Deshace el Update
        SELECT @intErrorCode = 4 --Error 4 : Error al Actualizar el Edo. Admvo. del Contenedor
        PRINT 'Error al Actualizar el Edo. Admvo. del Contenedor'

        GOTO LBL_END        --Caso de Falla
      END

      SELECT @lstrMsg = 'ACTUALIZADO EL EDO. ADMVO.: ' + CONVERT(VARCHAR(32), @lint_ContUniversalId)

      PRINT @lstrMsg
  END

  SELECT @lstrMsg = 'FIN; Error Code = ' + CONVERT(VARCHAR(32), @intErrorCode)
  PRINT @lstrMsg

LBL_END:

  SELECT @lstrMsg = 'Fin de STORE; Error Code = ' + CONVERT(VARCHAR(32), @intErrorCode)
  PRINT @lstrMsg

  --Valida si ocurrio algun error durante la actualzacion
  IF @intErrorCode = 0
  BEGIN

    RETURN @SUCCESS         --Caso de Exito 
  END
  ELSE
  BEGIN

    RETURN @FAILURE          --Caso de Falla
  END
END



