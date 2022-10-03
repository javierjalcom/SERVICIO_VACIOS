/*

DROP PROCEDURE spUpdateSOContWeight

*/

CREATE PROCEDURE spUpdateSOContWeight (
                                         @intUnivId              udtIdentifier,
                                         @intSOrderId            udtIdentifier,
                                         @intServiceId           udtIdentifier,
                                         @intSOrderItemId        udtIdentifier,
                                         @strUser                udtStringIdentifier,
                                         @strTextFree            udtStringIdentifier,
                                         @intYardVerificationId  udtIdentifier,
                                         @intYardVTItemId        udtIdentifier,                                        
                                         @intErrorCode     INTEGER OUTPUT) 

AS 
/*
  DESCRIPCION: SP que finaliza el servicio de consolidacion o desconsolidacion ya sea normal o directa 
                para 
                CONSOLIDACION NORMAL /CONSOLIDACION DIRECTA 
                   -- ACTUALIZAR EL PESO 

                  
  PARAMETROS:  
               @intUnivId       : Id Universal el Contenedor
               @intSOrderId     : Id de la Orden de Servicio
               @intServiceId    : Id del Servicio
               @intSOrderItemId : Id del Item de la Orden de Servicio
               @strUser         : Usuario
               @strTextFree     : Es un texto libre 
               @intErrorCode    : Bandera que Indica el Tipo de Error que Ocurrio

  TABLAS :     tblclsServiceOrder
               tblclsServiceOrderItem           
               tblclsContainerProduct 
               tblclsContainerInventory
             
  VALORES DE RETORNO:  
              OUTPUT  @intErrorCode    : solo si hubo error al ejecutar la sentenecia sql


  FECHA CREACION: 11-AGOSTO-2016 javier cadena
  AUTOR : javier cadena 
  CORRECCION:     
*/



DECLARE @SUCCESS INTEGER,  @FAILURE INTEGER
DECLARE @Count           INTEGER
DECLARE @ServIdentifier  udtStringIdentifier

DECLARE @lintDAT_Container         udtIdentifier ,@lintYV_ContainerUniv    udtIdentifier

DECLARE @lint_SOId                 udtIdentifier ,@lint_SOItemId           udtIdentifier

DECLARE @lintYV_ProdQty            udtIdentifier, @ldec_ContainerProdWeight  udtIdentifier 
DECLARE @ldec_YVProductdWeight     udtDecimal ,   @ldec_SOItemWeight        udtDecimal 
DECLARE @ldec_InvWeight            udtDecimal ,   @ldec_NewWeight   udtDecimal,  @ldec_NewProdWeight  udtDecimal
DECLARE @lint_SOItemQty            udtIdentifier ,@lint_YVItemQty           udtIdentifier
DECLARE @lint_SOItemsCounter       udtIdentifier ,@lint_SOTotalITems        udtIdentifier 
DECLARE @lint_NewProdQty           udtIdentifier , @lint_CFSActive            udtIdentifier
DECLARE @StatErrSP                 udtIdentifier, @ReturnCode  udtIdentifier

DECLARE @lstr_Coms                 varchar(200)
DECLARE @lint_Sumar                udtIdentifier , @lint_addingPlus  udtIdentifier
DECLARE @lstr_SOItemStatus         varchar(12)
DECLARE @lint_ShipConv             udtIdentifier
DECLARE @lstr_Service              varchar(15)
DECLARE @lint_TransactType         udtIdentifier
DECLARE @lstr_intTransactType      varchar(10)
DECLARE @intTransId  udtIdentifier,   
        @intError    udtIdentifier  

--- solo actualizar el peso en consolidacion de contenedor

 
--RETURN  0 --@SUCCESS

  BEGIN 
  
          SELECT @SUCCESS = 0
		  SELECT @FAILURE = 1
    
    --- obtener el servicio  y el shipconv
        SELECT  @lstr_Service = tblclsService.strServiceIdentifier  , 
                @lint_ShipConv =tblclsServiceOrder.blnIsShipConvenience
        FROM tblclsServiceOrder
          INNER JOIN tblclsService  on tblclsService.intServiceId = tblclsServiceOrder.intServiceId
        WHERE  tblclsServiceOrder.intServiceOrderId =@intSOrderId
      
         -- SET  @lstr_Coms =  'SERVI ='+ @lstr_Service + ',SHIP='+ CONVERT(VARCHAR(12), @lint_ShipConv )
        --  PRINT  @lstr_Coms
          
    ---- validar que sea consolidacion 
       IF @lstr_Service = 'CONS' OR @lstr_Service = 'CONSD'
         BEGIN
    
           --- ver si es ship convience, si es asi , sumar todas las tarjas de todos los renglones de la solicitud 
            IF  @lint_ShipConv = 1 
             BEGIN
                  --- obtener la sumatoria para la solicitud 
                  SELECT @ldec_YVProductdWeight  = SUM(tblclsYardVerifTicketItem.decYVerifTItemProdGrossWeight )
                  FROM tblclsYardVerifTicketItem
                  WHERE tblclsYardVerifTicketItem.intServiceOrderId = @intSOrderId
                  
                  SET @lstr_Coms = 'peso a actualizar =' + CONVERT( VARCHAR(20),@ldec_YVProductdWeight   )
                  PRINT  @lstr_Coms
                  
             END 
           ELSE  --- IF  @lint_ShipConv = 1 
             BEGIN
                   --- obtener la sumatoria  de la misma solicitud para ese item 
                   SELECT @ldec_YVProductdWeight = SUM( tblclsYardVerifTicketItem.decYVerifTItemProdGrossWeight )
                   FROM tblclsYardVerifTicketItem
                   WHERE  tblclsYardVerifTicketItem.intServiceOrderId = @intSOrderId
                   AND    tblclsYardVerifTicketItem.intServiceOrderItemId = @intSOrderItemId

             END 
        
          --- obtener el id de transaaccion para consolidacion directa 
           --SELECT @lint_TransactType = tblclsContainerTransacType.intContTransTypeId 
           --FROM tblclsContainerTransacType
           --WHERE tblclsContainerTransacType.strContTransTypeIdentifier = 'CCONS' 
           
           --SET @lstr_intTransactType= CONVERT(VARCHAR(10), @lint_TransactType)
             SET @lstr_intTransactType= 'CCONS'

          ----- actualizar inv 
          BEGIN TRANSACTION 
            ---- obtener comentarios de peso y tarja 
                  UPDATE tblclsContainerInventory
				  SET tblclsContainerInventory.decContainerInventoryWeight = @ldec_YVProductdWeight
				  WHERE intContainerUniversalId = @intUnivId 
				            
				    IF @@Error = 0  
			           BEGIN  
			             COMMIT TRANSACTION   
			           END  
				    ELSE --si hubo error  
			           BEGIN  
			             ROLLBACK TRANSACTION 
			             RETURN @FAILURE  
			           END     
		     		    --- fin actualizar el peso
                       
              ---- registrar comentarios 
                 SET @lstr_Coms = 'Actualizacion peso por modificacion de tarja='+ CONVERT( VARCHAR(17),@intYardVerificationId ) + 'a peso:'+  CONVERT( VARCHAR(17),@ldec_YVProductdWeight )
           
              --Ejecuta el SP que inserta una Transacción y devuelve el Id que se Inserto   
                 --EXECUTE @ReturnCode = spInsertTransaction @intUnivId,@lint_TransactType,@lstr_Coms,@strUser,@intTransId OUTPUT   
                   EXECUTE @ReturnCode = spInsertTransaction @intUnivId,@lstr_intTransactType,@lstr_Coms,@strUser,@intTransId OUTPUT   
                 
                 
                 
              --- mandar llamar spUpdateHistoryServiceOrder
                   
         --Si hubo algun Error devuelve 1 y sale del SP   
	      	   IF @ReturnCode != 0    
		         BEGIN  
		            SELECT 'TRANSACCIÓN'  
		            RETURN(1)   
		         END  
		         
         --- fin que fuera consolidacion                  
         END
          
       ---- validar que sea consolidacion 
  END  -- fin del procedimiento