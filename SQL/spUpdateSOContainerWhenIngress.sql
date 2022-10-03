
--- drop procedure spUpdateSOContainerWhenIngress

CREATE PROCEDURE spUpdateSOContainerWhenIngress 
     (
    @ContUniversalId        udtIdentifier, 
    @UserName               udtUserName,
    @ErrorCode              int OUTPUT)

AS 
/*IF EXISTS (SELECT 1
          FROM  sysobjects
          WHERE name = 'spUpdateESigns
          AND   type = 'P')
   DROP PROCEDURE dbo.spUpdateESigns
GO
*/

/*
DESCRIPCION: 
            Actualiza el Id Universal del Contenedor en las Ordenes de Servicio de DESC
            en donde se capturó un # contenedor sin existir el contendor en el inventario.
*/

/*          
PARAMETROS:  
            ContUniversalId:     udtIdentifier, 
            strContainerId:      udtStringIdentifier, 
            UserName:            Nombre de Usuario que generó las firmas electrónicas.
            Returned:            Variable de Salida que indica si hubo fallos en el StoredProcedure:
                0: Sin errores
                1: Hubo algún error.
            ErrorCode:          Variable de Salida con un código que indica la causa del error si lo hubo:
                    0: Sin errores.
                    1: No se encontró el Id Universal de Contenedor.
                    2: No se encotró algun servicio sin universal Id para asignar.
                    3: No se pudo actualizar en contenedor en el Servicio.
*/

/*
TABLAS:                     
            tblclsServiceOrderItem
            tblclsService
            tblclsContainerInventory
*/

/*
VALORES DE RETORNO: 
*/

/*          
FECHA : 18-AGOSTO-2005
AUTOR : Alberto Ramirez
CORRECCION:  

CORRECION:   -13/Oct/2006 Alberto Ramirez:
              Modificación ya que al ejecutarse este procedimiento no se realizaba acción alguna debido a
              un error del ASE al momento de crearse una tabla temporal dentro de una transaccion activa,
              por lo que se tuvo desactivar cualquier transacción activa que se tuviera para evitar el error.

MODIFICACIÓN -16/Oct/2006 Alberto Ramirez:
              Actualizar el Estado del Contenedor e insertar una transacción en el Histórico del Contenedor
              que permita identificar en que maniobra esta el contenedor si acaso se hizo tal inserción.
           
*/
BEGIN 
    DECLARE 
        @lstr_ServiceIdentifier     udtStringIdentifier,
        @lstr_SOStatusIdentifier    udtStringIdentifier,
        @lstr_ContainerId           udtStringIdentifier,
        @lstr_FiscalMov             udtStringIdentifier,
        @lstr_YardPosition          udtYardPosition,
        @lint_ServiceId             udtIdentifier,
        @lint_SOId                  udtIdentifier,
        @lint_SOItemId              udtIdentifier,
        @lstr_YSPId                 udtIdentifier,
        @lstr_YSPItemId             udtIdentifier,
        @lbln_IsFull                udtYesNo, 
        @lbln_CanUpdate             udtYesNo, 
        @lbln_IsOK                  udtYesNo

    DECLARE @strSOStatusIdentifier  varchar(32)
    DECLARE @strContAdmStatIdent    varchar(32)
    DECLARE @strTransType           varchar(32)
    DECLARE @Comments               varchar(100)
    DECLARE @intExistsTransferProg  int

    DECLARE	@ErrorMsg	    VarChar(100) 	/*recupera referencialmente el mensaje de error*/
    DECLARE	@RtnStatus	    int	 	        /*recupera el status de retorno de otros procedures*/

    SELECT @ErrorCode   = 0

    --Checa si las Transacciones estan Encadenadas  
    IF @@TRANCHAINED >= 1   BEGIN
     SELECT @ErrorCode = -1
    
     --Si estan Encadenadas Aborta el SP  
     GOTO RTNFAILURE
    END

    WHILE @@TranCount > 0
        COMMIT TRAN
    
    PRINT 'Valida la existencia del contenedor en el inventario'

    IF NOT EXISTS (SELECT tblclsContainerInventory.strContainerId
                      FROM tblclsContainerInventory
                     WHERE tblclsContainerInventory.intContainerUniversalId = @ContUniversalId)
    BEGIN
        SELECT @ErrorCode   = 1

        GOTO RTNFAILURE
    END

    PRINT 'Obtenedor datos del contenedor'

    SELECT @lstr_ContainerId = tblclsContainerInventory.strContainerId,
           @lbln_IsFull = tblclsContainerInventory.blnContainerIsFull,
           @lstr_FiscalMov = tblclsFiscalMovement.strFiscalMovementIdentifier,
           @lstr_YardPosition = tblclsContainerInventory.strContainerInvYardPositionId
      FROM tblclsContainerInventory,
           tblclsFiscalMovement 
     WHERE tblclsContainerInventory.intFiscalMovementId = tblclsFiscalMovement.intFiscalMovementId AND
           tblclsContainerInventory.intContainerUniversalId = @ContUniversalId

    IF @@error <> 0 
    BEGIN
        SELECT @ErrorCode   = 1
        
        GOTO RTNFAILURE
    END

    PRINT 'Traer las ordenes de servicio que tienen el campo Contenedor vacio.'

    CREATE TABLE #tblSOContEmpty
    ( 
        intServiceOrderId      numeric(18,0),
        intServiceOrderItemId  numeric(18,0),
        intServiceId           numeric(18,0),
        strServiceIdentifier   varchar(32),
        strSOStatusIdentifier  varchar(32),
        blnCanUpdate           bit
    )

    INSERT INTO #tblSOContEmpty
    SELECT tblclsServiceOrderItem.intServiceOrderId, 
           tblclsServiceOrderItem.intServiceOrderItemId, 
           tblclsService.intServiceId, 
           tblclsService.strServiceIdentifier, 
           tblclsServiceOrderStatus.strSOStatusIdentifier, 
           (CASE WHEN (tblclsServiceOrderItem.intSOStatusId IN (SELECT intSOStatusId 
                     FROM tblclsServiceOrderStatus 
                    WHERE strSOStatusIdentifier IN ('AUT', 'CAP', 'EPR'))) THEN
               1
           ELSE
               0
           END) AS blnCanUpdate
      FROM tblclsServiceOrderItem,
           tblclsServiceOrder,
           tblclsServiceOrderStatus,
           tblclsService
     WHERE tblclsServiceOrderItem.intServiceOrderId = tblclsServiceOrder.intServiceOrderId AND
           tblclsServiceOrder.intServiceId = tblclsService.intServiceId AND
           tblclsServiceOrderItem.intSOStatusId = tblclsServiceOrderStatus.intSOStatusId AND
           (tblclsServiceOrderItem.intContainerUniversalId = 0 OR 
           tblclsServiceOrderItem.intContainerUniversalId = NULL) AND
           tblclsServiceOrderItem.strContainerId LIKE @lstr_ContainerId 

    DECLARE curServices CURSOR FOR
    SELECT intServiceOrderId,
           intServiceOrderItemId,
           intServiceId,
           strServiceIdentifier,
           strSOStatusIdentifier,
           blnCanUpdate
    FROM   #tblSOContEmpty

    OPEN curServices

    FETCH curServices INTO @lint_SOId, @lint_SOItemId, 
                            @lint_ServiceId, @lstr_ServiceIdentifier, @lstr_SOStatusIdentifier, 
                            @lbln_CanUpdate

    IF @@error <> 0 
    BEGIN
        SELECT @ErrorCode   = 2
        
        GOTO RTNFAILURE
    END

    WHILE @@SQLStatus = 0
    BEGIN
       PRINT 'Entro a un ciclo While'

       SELECT @lbln_IsOK = 0

       --El contenedor es un lleno de IMPO 
       --[1]
       IF @lbln_CanUpdate = 1 AND @lbln_IsFull = 1 AND @lstr_FiscalMov IN ('IMPO', 'TRANSB') AND
           @lstr_ServiceIdentifier IN ('CONS', 'CONSD', 'DESC', 'DESCD', 'CONSDESC', '2oREV', 'ROCUL')
        BEGIN
            SELECT @lbln_IsOK = 1
        END
       ELSE -- IF [1]
        BEGIN
           --El contenedor es un lleno de IMPO
           --[2]
           IF @lbln_CanUpdate = 1 AND @lbln_IsFull = 1 AND 
               @lstr_FiscalMov IN ('EXPO', 'TRANSF', 'RET') AND
               @lstr_ServiceIdentifier IN ('CONS', 'CONSD', 'CONSDESC', '2oREV', 'ROCUL')
            BEGIN
                SELECT @lbln_IsOK = 1
            END
           ELSE -- IF [2]
            BEGIN
                --El contenedor es un VACIO de IMPO
                --[3]
                IF @lbln_CanUpdate = 1 AND @lbln_IsFull = 0 AND 
                   @lstr_ServiceIdentifier IN ('CONS', 'CONSD')
                BEGIN
                    SELECT @lbln_IsOK = 1
                END
            END
        END --IF... ELSE [1]
        
        IF @lbln_IsOK = 1
        BEGIN
            PRINT 'Actualizar Contenedor en la orden de servicio.'

            BEGIN TRAN trnUpdateContInSO
            
            UPDATE tblclsServiceOrderItem
               SET intContainerUniversalId = @ContUniversalId
             WHERE tblclsServiceOrderItem.intServiceOrderId = @lint_SOId AND 
                   tblclsServiceOrderItem.intServiceOrderItemId = @lint_SOItemId

            IF @@Error <> 0 
            BEGIN
                ROLLBACK TRAN trnUpdateContInSO

                DROP TABLE #tblSOContEmpty

                SELECT @ErrorCode   = 3 --No se pudo actualizar
                
                GOTO RTNFAILURE
            END

            SELECT @lstr_YSPId = IsNull(tblclsYardServiceProgramItem.intYardServProgId, 0),
                   @lstr_YSPItemId = IsNull(tblclsYardServiceProgramItem.intYardSPItemId, 0)
              FROM tblclsYardServiceProgramItem,
                   tblclsServiceOrderStatus
             WHERE tblclsYardServiceProgramItem.intSOStatusId = tblclsServiceOrderStatus.intSOStatusId
               AND tblclsYardServiceProgramItem.intServiceOrderId = @lint_SOId 
               AND tblclsYardServiceProgramItem.intServiceOrderItemId = @lint_SOItemId
               AND tblclsServiceOrderStatus.strSOStatusIdentifier <> 'CAN'

            IF @lstr_YSPId <> 0
            BEGIN
              UPDATE tblclsYardServiceProgramItem
                 SET strYardSPItemInitialLocation = @lstr_YardPosition
               WHERE tblclsYardServiceProgramItem.intServiceOrderId = @lint_SOId AND 
                     tblclsYardServiceProgramItem.intServiceOrderItemId = @lint_SOItemId

              IF @@Error <> 0 
              BEGIN
                ROLLBACK TRAN trnUpdateContInSO

                DROP TABLE #tblSOContEmpty

                SELECT @ErrorCode   = 3 --No se pudo actualizar
                  
                GOTO RTNFAILURE
              END
            END

            SELECT @intExistsTransferProg = 0

            IF EXISTS (SELECT tblclsContainerInternalMov.intContIntMovId 
                         FROM tblclsContainerInternalMov 
                        WHERE tblclsContainerInternalMov.intYardSPId = @lstr_YSPId 
                          AND tblclsContainerInternalMov.intYardSPItemId = @lstr_YSPItemId 
                          AND tblclsContainerInternalMov.blnContIntMovCompleted = 0 )
            BEGIN
                SELECT @intExistsTransferProg = 1

                UPDATE tblclsContainerInternalMov
                   SET tblclsContainerInternalMov.intContainerUniversalId = @ContUniversalId
                  WHERE tblclsContainerInternalMov.intYardSPId = @lstr_YSPId AND 
                       tblclsContainerInternalMov.intYardSPItemId = @lstr_YSPItemId
                
                IF @@Error <> 0 
                BEGIN
                    ROLLBACK TRAN trnUpdateContInSO
                      
                    DROP TABLE #tblSOContEmpty
                    
                    SELECT @ErrorCode   = 3 --No se pudo actualizar
                      
                    GOTO RTNFAILURE
                END
            END

            COMMIT TRAN trnUpdateContInSO

            --Elegir el tipo de transaccion en el historico del contenedor
            IF @lstr_ServiceIdentifier IN ('CONS', 'CONSD')
                SELECT @strTransType = 'CCONS'
            ELSE IF @lstr_ServiceIdentifier IN ('DESC', 'DESCD')
                SELECT @strTransType = 'CDESC'
            ELSE
                SELECT @strTransType = 'CCONDESC'

            --Obtener el Estado Admvo en que debe estar el contenedor condicionado al Edo de la Orden de Servicio
            IF @lstr_SOStatusIdentifier IN ('CAP', 'AUT')
                SELECT @strContAdmStatIdent = 'SERV'
            ELSE IF @strSOStatusIdentifier = 'EPR'
                SELECT @strContAdmStatIdent = 'PRSERV'
            ELSE IF @strSOStatusIdentifier = 'EJP'
                SELECT @strContAdmStatIdent = 'EJCONS'

            IF @intExistsTransferProg = 1
                SELECT @strContAdmStatIdent = 'PTRAS'

            IF @strContAdmStatIdent <> ''
                EXECUTE spUpdateContainerStatus @ContUniversalId, 1, @strContAdmStatIdent, ''

            SELECT @Comments = 'Contenedor Asignado Automáticamente a una Maniobra ('+@lstr_ServiceIdentifier+', '+CONVERT(VARCHAR(5), @lint_SOId)+')'

            --Registra la Entrega en el Historico
            EXECUTE spUpdateHistoryServiceOrder @strTransType, @ContUniversalId, @lint_ServiceId,
                                                @lint_SOId, @lint_SOItemId,
                                                @Comments,
                                                @UserName
        END

        FETCH curServices INTO @lint_SOId, @lint_SOItemId, 
                                @lint_ServiceId, @lstr_ServiceIdentifier, @lstr_SOStatusIdentifier, 
                                @lbln_CanUpdate
    END --WHILE

    CLOSE curServices 
    DEALLOCATE CURSOR curServices 

    DROP TABLE #tblSOContEmpty

    PRINT 'Fin de SP, sin errores'

    RETURN (0)
END

RTNFAILURE:
    CLOSE curServices 
    DEALLOCATE CURSOR curServices 

    PRINT 'Fin de SP, con errores.'

    RETURN (1)




