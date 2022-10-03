/*
	Highlight and execute the following statement to drop the procedure
	before executing the create statement.
	
	DROP PROCEDURE spSaveTicketItemHH
	
	-- sp que se llama desde hh , y genera un nuevo detalle para la tarja 
	-- retorna intYardVTItemId
*/


CREATE PROCEDURE spSaveTicketItemHH     @intYardVerifTicketId udtIdentifier ,
										@intServiceOrderId udtIdentifier,
										@intServiceOrderItemId udtIdentifier ,
										@intProductId  udtIdentifier , 
										@intProductPackingId udtIdentifier ,
										@intYVerifTItemProdPackingQty udtIdentifier ,
										@decYVerifTItemProdGrossWeight udtDecimal ,
										@strYVerifTItemMarks udtStringIdentifier ,
										@strYVerifTItemNumbers udtStringIdentifier ,
										@strYVerifTItemComments VARCHAR(150) ,
										@intIMOCodeId udtIdentifier ,
										@tmeYVerifTItemInitialTime udtStringIdentifier,
										@tmeYVerifTItemFinalTime udtStringIdentifier,
										@dtmYVerifTItemLastModified  udtStringIdentifier,
										@strYVerifTItemCreatedBy udtStringIdentifier,
										@intContPhyStatId udtIdentifier ,
										@intContainerTypeId udtIdentifier ,
										@intContainerSizeId udtIdentifier ,
										@decYVerifTItemContainerTare udtDecimal , 
										@strYVerifTItemProdPackingSp udtStringIdentifier ,
										@decYVerifTItemTempMeasure udtDecimal, 
										@decYVerifTItemTempVentPrtg udtDecimal ,
										@strYVerifTItemContSealNumber udtStringIdentifier ,
										@blnYVerifTItemReadOnly udtIdentifier  ,
										@intYardVerificationType udtIdentifier , 
										@strDescriptionEquipment udtStringIdentifier , 
										@strEliminatedSeals  udtStringIdentifier, 
										@strAppliedSeals udtStringIdentifier 



 --tblclsYardVerifTicketItem
  ----------------

  --- @decInvContainerOverQuantity udtDecimal,
AS
	
	DECLARE @intVerificationItemId udtIdentifier
	DECLARE @lint_ContainerType udtIdentifier
	DECLARE @lint_ContainerSize udtIdentifier
	DECLARE @ldec_ContainerTare udtDecimal
	DECLARE @strError udtStringIdentifier
	DECLARE @StatErrSP      INTEGER 
	DECLARE @lint_UniversalContainer udtIdentifier
    DECLARE @strIMOCodeIdenti udtStringIdentifier
    DECLARE @strServiceIdentifier  udtStringIdentifier
    DECLARE @lint_ItemProductId udtIdentifier
    DECLARE @SPStat  udtIdentifier
    DECLARE @intTransactType  udtIdentifier
    DECLARE @intServiceId udtIdentifier
    DECLARE @strComents varchar(120)
    DECLARE @lint_PhyscalStatus udtIdentifier
    DECLARE @lint_InvisitId udtIdentifier
    DECLARE @ldtm_CheckInDate DATETIME
    DECLARE @ldtm_CheckOutDate DATETIME
    --DECLARE @lint_UniversalContainer udtIdentifier
    DECLARE @ldec_ProdWeight udtDecimal
    DECLARE @ldec_InvWeight udtDecimal
    DECLARE @int_QtyProduct udtIdentifier
    DECLARE @ldtm_Today  DATETIME 
    DECLARE @strUser     udtStringIdentifier 
    DECLARE @llng_ContainerUniv udtIdentifier
    DECLARE @lint_TicketsCounter  udtIdentifier
    DECLARE @lstr_StringTemp  VARCHAR(50)
    DECLARE @lstr_Service VARCHAR(10)
    
     						
   -- select 'holaitemhh'
   -- return 0			                          
	-- validar los argumentos 
	
	IF ISNULL(@intYardVerifTicketId,0)=0 
	 BEGIN 
	  PRINT 'Error, no se ha especificado numero tarja'	   
	  SELECT -1
	  RETURN -1
	 END 
	 
	 IF ISNULL(@intServiceOrderId,0)=0
	 BEGIN 
	  PRINT 'No se tecleo el numero de solicitud'
	  SELECT '-2'
	  RETURN 2 
	 END 
	 
	 IF ISNULL(@intServiceOrderItemId,0)=0
	  BEGIN
	   PRINT 'Bo se tecleo el item de la solicitud'
	   SELECT '-3'
	   RETURN 3 
	  END 

   
	  -- JCADENA comentado CFS- 19-abril-2016, para permitir productos genericos
	 --IF ISNULL(@intProductId,0)=0
	  -- BEGIN
	   --PRINT 'No se tecleo el producto'
	   --SELECT '-4'
	   --RETURN 4 
	  -- END 
	 
	 IF ISNULL(@intProductPackingId,0)=0
	  BEGIN
	    PRINT 'No se tecleo el empaque'
	    SELECT '-5'
	    RETURN 5
	  END 
	  
	   
	 SET @ldtm_Today  = GETDATE() 
	 SET @strYVerifTItemMarks = ISNULL(@strYVerifTItemMarks,'')
	 SET @strYVerifTItemNumbers = ISNULL(@strYVerifTItemNumbers,'')
	 SET @strYVerifTItemComments = ISNULL(@strYVerifTItemComments,'')
	 SET @intIMOCodeId = ISNULL(@intIMOCodeId,0)
	 SET @strServiceIdentifier = '' 
	 SET @strUser = @strYVerifTItemCreatedBy
	 SET @lstr_StringTemp = ''
	 
	-- SET @tmeYVerifTItemInitialTime = ISNULL(@tmeYVerifTItemInitialTime,'19000101 00:00')
	-- SET @tmeYVerifTItemFinalTime  = ISNULL(@tmeYVerifTItemFinalTime, '19000101 00:00')
	   SET @dtmYVerifTItemLastModified = ISNULL(@dtmYVerifTItemLastModified, GETDATE())
	 --SET @strYVerifTItemCreatedBy
	 
	 
     SELECT	 @lint_ContainerSize = tblclsContainerISOCode.intContainerSizeId
            ,@lint_ContainerType = tblclsContainerISOCode.intContainerTypeId
            ,@ldec_ContainerTare = tblclsContainerISOCode.decContISOCodeTare
           
	 FROM tblclsServiceOrderItem
	  INNER JOIN tblclsContainer ON tblclsServiceOrderItem.strContainerId = tblclsContainer.strContainerId
	  INNER JOIN tblclsContainerISOCode ON tblclsContainerISOCode.intContISOCodeId = tblclsContainer.intContISOCodeId
	 WHERE tblclsServiceOrderItem.intServiceOrderId = @intServiceOrderId
	 AND   tblclsServiceOrderItem.intServiceOrderItemId = @intServiceOrderItemId
	 
	 
	 SET @intContPhyStatId  = ISNULL(@intContPhyStatId,0)
	 SET @intContainerTypeId = ISNULL(@intContainerTypeId,@lint_ContainerType)
	 SET @intContainerSizeId = ISNULL(@intContainerSizeId  , @lint_ContainerSize )
	 SET @decYVerifTItemContainerTare = ISNULL(@decYVerifTItemContainerTare   , @ldec_ContainerTare  )
	 
	 ------- 17- noviembre -- 2016
	    --- obtener el servicio para saber si se valida cantidad y peso 
	    	SELECT @lstr_Service = tblclsService.strServiceIdentifier 
	  	    FROM tblclsServiceOrder
	  	         INNER JOIN tblclsService on tblclsService.intServiceId = tblclsServiceOrder.intServiceId 
	  	    WHERE tblclsServiceOrder.intServiceOrderId = @intServiceOrderId

      
	  	------------------------ 
	  	------ si no es cons-desc. ni rocul- y los demas reconocimientos permitir el 0 en cantidad	  
	  	-- 	  	IF @lstr_Service = 'RECVOS'	  	  	 
	  	IF @lstr_Service = 'RECVOS' Or @lstr_Service = 'ROCUL' Or @lstr_Service = 'CONSDESC' Or @lstr_Service = '2oREV' Or @lstr_Service = '2oREVMC'
	  	    BEGIN 
	  	        SET @intYVerifTItemProdPackingQty = 0 
	  	       
	  	    	 IF ISNULL(@intYVerifTItemProdPackingQty,0)=0  
	  	    	  BEGIN  
	  	    	    SET @intYVerifTItemProdPackingQty = 0 
	  	    	  END
	  	    	  
	  	    	IF ISNULL(@decYVerifTItemProdGrossWeight,0)=0
	  	    	   BEGIN
	  	    	      SET @decYVerifTItemProdGrossWeight = 0 
	  	    	   END 
	  	    END
	  	    
	  	 ELSE  --- se requiere validar la cantidad y peso 
	  	  BEGIN
	  	    
	  	         IF ISNULL(@intYVerifTItemProdPackingQty,0)=0  
	  	    	 BEGIN 
	  	    	       PRINT 'No se tecleo cantidad' 
	  	    	       SELECT '-6'
	  	    	       RETURN 6  
	  	    	 END
	  	    	 
  	 	       IF ISNULL(@decYVerifTItemProdGrossWeight,0)=0
	  	 	     BEGIN
	  	 	           PRINT 'No se ha tecleado el peso'
	  	 	           SELECT '-7'
	  	 	           RETURN 7
	  	 	     END 
	  	  END
	  	  
	  	 

      --------------
      ---------------
      
	 ------- JCADENA 12-04-2016 .. validar si el esatus fisico es mayor a 0 
	   IF  @intContPhyStatId =0 
	    BEGIN 
				 ---- obtener el servicio indentificador de la solicitud 	       
				 SELECT @lstr_Service = tblclsService.strServiceIdentifier 
				 FROM tblclsServiceOrder
				  INNER JOIN tblclsService on tblclsService.intServiceId = tblclsServiceOrder.intServiceId
				 WHERE tblclsServiceOrder.intServiceOrderId = @intServiceOrderId
				  
				 IF @lstr_Service = 'CONS' OR @lstr_Service = 'CONSD' 
				  BEGIN
				  
				     SELECT @intContPhyStatId =  tblclsContainerPhysicalStatus.intContPhyStatId
				     FROM tblclsContainerPhysicalStatus
				     WHERE  tblclsContainerPhysicalStatus.strContPhyStatIdentifier = 'PLLENO' 				     
				     
				  END 
				 
				 IF  @lstr_Service = 'DESC' OR @lstr_Service = 'DESCD' 
				 BEGIN
				     SELECT @intContPhyStatId = tblclsContainerPhysicalStatus.intContPhyStatId
				     FROM tblclsContainerPhysicalStatus
				     WHERE  tblclsContainerPhysicalStatus.strContPhyStatIdentifier = 'PVACIO' 				     
				 
				 END			 				 
	    END 
       ------- JCADENA 12-04-2016 ..  poner un estatus parcial en base al servicio 
	   
	  	 ------- JCADENA  14-04-2016 ...
	 
	 --SET @strYVerifTItemProdPackingSpecs ,  @decYVerifTItemTempMeasure, @decYVerifTItemTempVentPerctag , @strYVerifTItemContSealNumber
	 SET @blnYVerifTItemReadOnly =0
	 SET @intYardVerificationType = ISNULL(@intYardVerificationType,2)
	 --SET 	 @strDescriptionEquipment,  @strEliminatedSeals , 	 @strAppliedSeals

    --- contar si ya hay tarjas anteriores 
      SELECT  @lint_TicketsCounter  = ISNULL( tblclsYardVerifTicketItem.intServiceOrderId , 0 )
      FROM tblclsYardVerifTicketItem 
      WHERE tblclsYardVerifTicketItem.intServiceOrderId = @intServiceOrderId
      AND  tblclsYardVerifTicketItem.intServiceOrderItemId = @intServiceOrderItemId
      
      SELECT @lint_UniversalContainer = ISNULL( tblclsServiceOrderItem.intContainerUniversalId ,0 )
		       FROM   tblclsServiceOrderItem
		       WHERE  tblclsServiceOrderItem.intServiceOrderId = @intServiceOrderId
		       AND    tblclsServiceOrderItem.intServiceOrderItemId = @intServiceOrderItemId
		   
		   
	   --SET  @lstr_StringTemp =  'TARJAS:'   + CONVERT(VARCHAR(12),@lint_TicketsCounter)+ '!'
	   --RAISERROR 99999 @lstr_StringTemp

       SELECT @lint_TicketsCounter = ISNULL(@lint_TicketsCounter,0)
      ---  ver si hay mas de una tarja 
      IF ( @lint_TicketsCounter = 0 )
       BEGIN  
       
         IF (@lint_UniversalContainer <=0 ) 
          BEGIN 
             RAISERROR 99999  'NO TIENE UNIV'
          END

        /*  --- 03-nov-2016  no borrar sellos sin antes averiguar el servicio que se esta haciendo 
    	  --SET  @lstr_StringTemp =  'univ='   + CONVERT(VARCHAR(12),@lint_UniversalContainer)+ '!'
	      --RAISERROR 99999 @lstr_StringTemp                 
	    
         -- eliminar los sellos del contenedor 
            BEGIN TRAN 
                
                DELETE tblclsContainerSeal
                WHERE tblclsContainerSeal.intContainerUniversalId =  @lint_UniversalContainer 
         
            IF @@Error = 1  --Validacion al Insertar el Registro   
				BEGIN   
				  ROLLBACK TRAN    --Aborta los Cambios   
				  SELECT @strError = '>>--ERROR: Al guardar detalle tarja '
				  RETURN -20  --ERROR: Al borrar los sellos 
				END 
				
				COMMIT TRAN 
          */
       END 
         
	--- el item fue sugerido en el sp  @intServiceOrderItemId
        
		
		SELECT @intVerificationItemId = ISNULL(MAX(tblclsYardVerifTicketItem.intYardVTItemId),0)+1 FROM tblclsYardVerifTicketItem
			
		BEGIN TRAN


		INSERT INTO tblclsYardVerifTicketItem
		(intYardVTItemId, intYardVerifTicketId, intContPhyStatId, intIMOCodeId, intServiceOrderId,
		 intServiceOrderItemId, intContainerSizeId, intContainerTypeId, intProductId, intProductPackingId, 
		 decYVerifTItemContainerTare, tmeYVerifTItemInitialTime, tmeYVerifTItemFinalTime, 
		 intYVerifTItemProdPackingQty, strYVerifTItemProdPackingSpecs, decYVerifTItemProdGrossWeight, 
		 strYVerifTItemMarks, strYVerifTItemNumbers, decYVerifTItemTempMeasure, decYVerifTItemTempVentPerctage, 
		 strYVerifTItemContSealNumber, blnYVerifTItemReadOnly, strYVerifTItemComments, dtmYVerifTItemCreationStamp, 
		 strYVerifTItemCreatedBy, dtmYVerifTItemLastModified, strYVerifTItemLastModifiedBy, intYardVerificationType, 
		 strDescriptionEquipment, strEliminatedSeals, strAppliedSeals)			

		VALUES 
		 ( @intVerificationItemId, @intYardVerifTicketId, @intContPhyStatId, @intIMOCodeId , @intServiceOrderId,
		   @intServiceOrderItemId, @intContainerSizeId , @intContainerTypeId , @intProductId, @intProductPackingId, 
		   @decYVerifTItemContainerTare , @tmeYVerifTItemInitialTime , @tmeYVerifTItemFinalTime,
		   @intYVerifTItemProdPackingQty , @strYVerifTItemProdPackingSp, @decYVerifTItemProdGrossWeight ,
		   @strYVerifTItemMarks, @strYVerifTItemNumbers, @decYVerifTItemTempMeasure, @decYVerifTItemTempVentPrtg, 
		   @strYVerifTItemContSealNumber , @blnYVerifTItemReadOnly, @strYVerifTItemComments , GETDATE(),
		   @strYVerifTItemCreatedBy ,  GETDATE() , @strYVerifTItemCreatedBy,@intYardVerificationType,
		   @strDescriptionEquipment, @strEliminatedSeals, @strAppliedSeals 
         )
			
		
		IF @@Error = 1  --Validacion al Insertar el Registro   
		BEGIN   
		  ROLLBACK TRAN    --Aborta los Cambios   
		  SELECT @strError = '>>--ERROR: Al guardar detalle tarja '
		  RETURN -2  --ERROR: Al Ingresar ingresar la tarja 
		END 
		COMMIT TRAN 
	 
	 
	  --- si el IMO, recibido como argumento , pues mandar llamar al sp que lo agrega el imo
	  IF @intIMOCodeId > 0 
	   BEGIN
	      	 -- obtener el numero de universal del item 		       
		      
		       SELECT @lint_UniversalContainer = ISNULL( tblclsServiceOrderItem.intContainerUniversalId ,0 )
		       FROM   tblclsServiceOrderItem
		       WHERE  tblclsServiceOrderItem.intServiceOrderId = @intServiceOrderId
		       AND    tblclsServiceOrderItem.intServiceOrderItemId = @intServiceOrderItemId

               -- obtener el identificador IMO del key 
               SELECT @strIMOCodeIdenti = tblclsIMOCode.strIMOCodeIdentifier 
               FROM tblclsIMOCode 
               WHERE intIMOCodeId = @intIMOCodeId
               
		      -- si tiene universal 
		      IF @lint_UniversalContainer > 0 
		        BEGIN 
		         -- print ' se va a insertar imo '
		            EXECUTE @StatErrSP =  spAddInvIMO  @lint_UniversalContainer , @strIMOCodeIdenti , @strYVerifTItemCreatedBy		            
		            
	       	  		IF @StatErrSP  = 1 --Validacion del SP 
			          BEGIN 
			       	    SELECT @strError = '>>--ERROR: Al guardar historico IMO '
			            RETURN (-3) --ERROR: Al Insertar en el Inventario   
			 		END 		            
		            
		        END  -- IF @lint_UniversalContainer > 0 		        
		        
	   END --	  IF @intIMOCodeId > 0 
	
	
	---- AGREGADO --  JCADENA 17 NOV-2015
		
	 DECLARE @lint_BlnFull        udtIdentifier
	 DECLARE @lstr_PhyscalStatus  udtStringIdentifier
	 DECLARE @ldec_Wieght         udtDecimal
     DECLARE @CustType            udtIdentifier
     DECLARE @CustId              udtIdentifier
     DECLARE @lint_SumQtyProd     udtIdentifier
     DECLARE @ldec_SumWeightProd  udtDecimal
     
      SET  @lint_BlnFull = -1
      SET  @lstr_PhyscalStatus = 'Z'
      SET  @ldec_Wieght = -9

      ----->>> analisis de la informacion  para separarla en if para ver siendo de que servicio como se actualiza la informacion 
          SELECT @strServiceIdentifier =  tblclsService.strServiceIdentifier , 
                 @intServiceId = tblclsServiceOrder.intServiceId
          FROM tblclsServiceOrder
           INNER JOIN tblclsService ON tblclsServiceOrder.intServiceId = tblclsService.intServiceId
          WHERE tblclsServiceOrder.intServiceOrderId = @intServiceOrderId  
          
      	 -- obtener el numero de universal del item 		       
	      
	       SELECT @lint_UniversalContainer = ISNULL( tblclsServiceOrderItem.intContainerUniversalId ,0 )
	       FROM   tblclsServiceOrderItem
	       WHERE  tblclsServiceOrderItem.intServiceOrderId = @intServiceOrderId
	       AND    tblclsServiceOrderItem.intServiceOrderItemId = @intServiceOrderItemId
           
           IF @strServiceIdentifier = 'CONS'
             BEGIN
             
               -- obtener peso  -- @decYVerifTItemProdGrossWeight   udtDecimal,
                               
               --.--- buscar producto 
                              
               SELECT @CustType  = intServiceOrderInvoiceToTypeId,
                         @CustId    = intServiceOrderInvoiceToId
               FROM   tblclsServiceOrder SO,
                         tblclsServiceOrderItem SOI
			   WHERE  SO.intServiceOrderId       = SOI.intServiceOrderId   AND   
				         SO.intServiceOrderId       = @intServiceOrderId AND
				         SOI.intServiceOrderItemId  = @intServiceOrderItemId
				         
			   SET @lint_ItemProductId = 0
			   
               ----- definir valor de item 
                              
               SELECT @lint_ItemProductId  = ISNULL(MAX( tblclsContainerProduct.intItemId),0)
			   FROM tblclsContainerProduct 
			   WHERE tblclsContainerProduct.intContainerUniversalId = @lint_UniversalContainer
			   AND tblclsContainerProduct.intProductId = @intProductId    
			   AND   tblclsContainerProduct.intCustomerId = @CustId
			   AND   tblclsContainerProduct.intCustomerTypeId = @CustType
			   AND tblclsContainerProduct.intProductPackingId = @intProductPackingId

               ---- si no existe se agrega 
                 IF ( @lint_ItemProductId = 0  )
                   BEGIN                          
                         
                    --Ejecuta un sp que inserta o actualiza los productos del Contenedor para la Consolidación
                       EXECUTE @SPStat = spInsertContConsolProduct @lint_UniversalContainer,@intProductId,0,
	                                                0,@CustId,@intProductPackingId,
	                                                @intYVerifTItemProdPackingQty,@strYVerifTItemMarks,@strYVerifTItemNumbers,
	                                                @decYVerifTItemProdGrossWeight  ,'', -- ,@strServiceIdentifier , 
	                                                @strUser ,@CustType
                      
                        IF @SPStat <> 0
                           BEGIN     
							       --ROLLBACK  TRAN --Deshace la Transaccion   --LISLAS 15-SEP-2006 Ya tiene Commit/Rollback  el SP anterior
							       RAISERROR 99999 'Ocurrio un Error al Consolidar Directamente la Orden de Servicio'
							       SELECT 71
							       return  7  --ERROR 7 : 'Error al Consolidar Directamente los Productos en el Contenedor'    
							       --RETURN @FAILURE	
						   END 
		            	print 'ya inserto producto'  
                         
                   END -- IF ( @lint_ItemProductId   > 0  )
                ELSE
                   BEGIN --ELSE --IF ( @lint_ItemProductId   > 0  )
                     --- obtener el valor del producto y sumar 

                       --- OBTENER LA SUMA DE CANTIDADDES Y PESOS DE TODAS LAS TARJAS                        
										
					   SELECT @lint_SumQtyProd =    ISNULL(SUM (tblclsYardVerifTicketItem.intYVerifTItemProdPackingQty ) ,0 ),
					          @ldec_SumWeightProd = ISNULL(SUM (tblclsYardVerifTicketItem.decYVerifTItemProdGrossWeight ) ,0 )
					   FROM tblclsYardVerifTicketItem
					   WHERE tblclsYardVerifTicketItem.intServiceOrderId = @intServiceOrderId
					   AND   tblclsYardVerifTicketItem.intServiceOrderItemId = @intServiceOrderItemId
					   AND   tblclsYardVerifTicketItem.intProductId = @intProductId
					   AND   tblclsYardVerifTicketItem.intProductPackingId = @intProductPackingId
					                    
                       /* 
                       SELECT @lint_SumQtyProd =  tblclsContainerProduct.intContInvProdQuantity ,
                              @ldec_SumWeightProd = tblclsContainerProduct.decContInvProdWeight
                       FROM  tblclsContainerProduct
                       WHERE tblclsContainerProduct.intContainerUniversalId = @lint_UniversalContainer
                       AND   tblclsContainerProduct.intProductId = @intProductId 
                       AND   tblclsContainerProduct.intCustomerId = @CustId 
                       AND   tblclsContainerProduct.intCustomerTypeId = @CustType
                       AND   tblclsContainerProduct.intProductPackingId = @intProductPackingId
                       AND   tblclsContainerProduct.intItemId = @lint_ItemProductId

                       SET @lint_SumQtyProd =  @lint_SumQtyProd + @intYVerifTItemProdPackingQty
                       SET @ldec_SumWeightProd = @ldec_SumWeightProd + @decYVerifTItemProdGrossWeight
                       */

										
                     --------------                   
                     --- si existe se suma peso 
	                   BEGIN TRANSACTION 
	                   
	                        UPDATE tblclsContainerProduct
		                    SET tblclsContainerProduct.intContInvProdQuantity =  @lint_SumQtyProd ,
		                        tblclsContainerProduct.decContInvProdWeight =  @ldec_SumWeightProd
		                    WHERE tblclsContainerProduct.intContainerUniversalId = @lint_UniversalContainer
		                    AND  tblclsContainerProduct.intItemId = @lint_ItemProductId
	              
		          	         /* UPDATE tblclsContainerProduct
			                    SET tblclsContainerProduct.intContInvProdQuantity =  tblclsContainerProduct.intContInvProdQuantity + @intYVerifTItemProdPackingQty ,
			                        tblclsContainerProduct.decContInvProdWeight =  tblclsContainerProduct.decContInvProdWeight + @decYVerifTItemProdGrossWeight
			                    WHERE tblclsContainerProduct.intContainerUniversalId = @lint_UniversalContainer
			                    AND  tblclsContainerProduct.intItemId = @lint_ItemProductId
			                   */
	               
					        IF @@Error = 1  --Validacion al Insertar el Registro   
							 BEGIN   
							   ROLLBACK TRAN    --Aborta los Cambios   
							   SELECT @strError = '>>--ERROR: Al guardar detalle tarja '
							   RETURN -4  --ERROR: Al Ingresar el Contenedor a Inventario   
							 END 						 
							 
						COMMIT TRAN 	
				  END --ELSE --IF ( @lint_ItemProductId   > 0  )
				  
				-- obtener el numero de transaccion 
				   SELECT @intTransactType  = tblclsContainerTransacType.intContTransTypeId  
				   FROM  tblclsContainerTransacType 
				   WHERE  tblclsContainerTransacType.strContTransTypeIdentifier = 'CCONS'
                                        
                   -- definir el comentario 
                     SET  @strComents = ' En tarja:' + CONVERT(VARCHAR(12),@intYardVerifTicketId ) + 'Peso:' +  CONVERT(VARCHAR(12), @decYVerifTItemProdGrossWeight) + 'Cantidad:'+ CONVERT(VARCHAR(12),@intYVerifTItemProdPackingQty)
                     
                     --- definir en histico , consolidacion parcial                      
                     -- EXECUTE @SPStat =   spUpdateHistoryServiceOrder @intTransactType , @lint_UniversalContainer, @intServiceId ,  @intServiceOrderId, @intServiceOrderItemId , @strComents, @strUser    
                      EXECUTE @SPStat =   spUpdateHistoryServiceOrder  'CCONS', @lint_UniversalContainer, @intServiceId ,  @intServiceOrderId, @intServiceOrderItemId , @strComents, @strUser    
                      
                        IF @SPStat <> 0
                           BEGIN     
							       --ROLLBACK  TRAN --Deshace la Transaccion   --LISLAS 15-SEP-2006 Ya tiene Commit/Rollback  el SP anterior
							       RAISERROR 99999 'Ocurrio un Error al guardar historico de solicitud'
							      -- SELECT @intErrorCode = 7  --ERROR 7 : 'Error al Consolidar Directamente los Productos en el Contenedor'    
							      SELECT -5 
								RETURN -5  --ERROR 7 : 'Error al Consolidar Directamente los Productos en el Contenedor'    

							       --RETURN @FAILURE	
						   END 
                  
                  --- sumar los pesos de todas las tarjas  con universal 
                      SELECT @llng_ContainerUniv =   tblclsServiceOrderItem.intContainerUniversalId
                      FROM tblclsServiceOrderItem
                      WHERE tblclsServiceOrderItem.intServiceOrderId = @intServiceOrderId
                      AND   tblclsServiceOrderItem.intServiceOrderItemId = @intServiceOrderItemId
                      
                      
                      SELECT  --@lint_SumQtyProd =    ISNULL(SUM (tblclsYardVerifTicketItem.intYVerifTItemProdPackingQty ) ,0 ),
					          @ldec_SumWeightProd = ISNULL(SUM (tblclsYardVerifTicketItem.decYVerifTItemProdGrossWeight ) ,0 )
					          
                      FROM tblclsServiceOrderItem
                       INNER JOIN tblclsYardVerifTicketItem ON tblclsYardVerifTicketItem.intServiceOrderId = tblclsServiceOrderItem.intServiceOrderId
                                                            AND tblclsYardVerifTicketItem.intServiceOrderItemId = tblclsServiceOrderItem.intServiceOrderItemId
                                                            
                      WHERE tblclsServiceOrderItem.intServiceOrderId = @intServiceOrderId
                      AND  tblclsServiceOrderItem.intContainerUniversalId = @llng_ContainerUniv
                      
                      /*SELECT @lint_SumQtyProd =    ISNULL(SUM (tblclsYardVerifTicketItem.intYVerifTItemProdPackingQty ) ,0 ),
					          @ldec_SumWeightProd = ISNULL(SUM (tblclsYardVerifTicketItem.decYVerifTItemProdGrossWeight ) ,0 )
					   FROM tblclsYardVerifTicketItem
					   WHERE tblclsYardVerifTicketItem.intServiceOrderId = @intServiceOrderId
					   AND   tblclsYardVerifTicketItem.intServiceOrderItemId = @intServiceOrderItemId
					   AND   tblclsYardVerifTicketItem.intProductId = @intProductId
					   AND   tblclsContainerProduct.intProductPackingId = @intProductPackingId
					*/
                   
               --- actualizar el peso del contenedor y 
                   BEGIN TRANSACTION 
                   
	                     UPDATE tblclsContainerInventory
	                     --SET  tblclsContainerInventory.decContainerInventoryWeight =  tblclsContainerInventory.decContainerInventoryWeight + @decYVerifTItemProdGrossWeight
	                     SET  tblclsContainerInventory.decContainerInventoryWeight = @ldec_SumWeightProd	                     
	                     WHERE tblclsContainerInventory.intContainerUniversalId = @lint_UniversalContainer
                     
                         SELECT @StatErrSP = @@error
        
				        IF @StatErrSP <> 0  --Validacion al Insertar el producto
				          BEGIN
				              print 'Error al actualizar el Inv. de contenedor'
				              ROLLBACK TRANSACTION 
				              SELECT -8
				              RETURN (-8) 
				          END
				        ELSE 
                         BEGIN
				            	COMMIT TRANSACTION 				        
                         END 
           
               --- dejar el estatus en parcialmente conslodida,
               
               SELECT @lint_PhyscalStatus = tblclsContainerPhysicalStatus.intContPhyStatId
               FROM tblclsContainerPhysicalStatus
               WHERE tblclsContainerPhysicalStatus.strContPhyStatIdentifier = 'PVACIO'
                ---se registrara historico ,, poner comentarios tarja 
               
                    BEGIN TRANSACTION 
                   
	                     UPDATE tblclsContainerInventory
	                     SET  tblclsContainerInventory.intContPhyStatId =  @lint_PhyscalStatus
	                     WHERE tblclsContainerInventory.intContainerUniversalId = @lint_UniversalContainer
                     
                         SELECT @StatErrSP = @@error
        
				        IF @StatErrSP <> 0  --Validacion al Insertar el producto
				          BEGIN
				              print 'Error al actualizar el Inv. de contenedor'
				              ROLLBACK TRANSACTION 
				              SELECT -9
				              RETURN (-9) 
				          END
				        ELSE 
                          BEGIN
   		                                  COMMIT TRANSACTION 				                       
                          END
                                       
             END ------ IF @strServiceIdentifier = 'CONS'

             

           IF @strServiceIdentifier = 'CONSD'
             BEGIN
             
               -- obtener peso  -- @decYVerifTItemProdGrossWeight   udtDecimal,
                 
               --.--- buscar producto 
                              
               SELECT @CustType  = intServiceOrderInvoiceToTypeId,
                         @CustId    = intServiceOrderInvoiceToId
               FROM   tblclsServiceOrder SO,
                         tblclsServiceOrderItem SOI
			   WHERE  SO.intServiceOrderId       = SOI.intServiceOrderId   AND   
				         SO.intServiceOrderId       = @intServiceOrderId AND
				         SOI.intServiceOrderItemId  = @intServiceOrderItemId
				         
			   SET @lint_ItemProductId = 0
			   
               ----- definir valor de item 
                              
               SELECT @lint_ItemProductId  = ISNULL(MAX( tblclsContainerProduct.intItemId),0)
			   FROM tblclsContainerProduct 
			   WHERE tblclsContainerProduct.intContainerUniversalId = @lint_UniversalContainer
			   AND tblclsContainerProduct.intProductId = @intProductId    
			   AND   tblclsContainerProduct.intCustomerId = @CustId
			   AND   tblclsContainerProduct.intCustomerTypeId = @CustType
			   AND tblclsContainerProduct.intProductPackingId = @intProductPackingId
               
               ---- si no existe se agrega 
                 IF ( @lint_ItemProductId = 0  )
                   BEGIN                          
                         
                    --Ejecuta un sp que inserta o actualiza los productos del Contenedor para la Consolidación
                       EXECUTE @SPStat = spInsertContConsolProduct @lint_UniversalContainer,@intProductId,0,
	                                                0,@CustId,@intProductPackingId,
	                                                @intYVerifTItemProdPackingQty,@strYVerifTItemMarks,@strYVerifTItemNumbers,
	                                                @decYVerifTItemProdGrossWeight ,'', --,@strServiceIdentifier , 
	                                                @strUser ,@CustType
                      
                        IF @SPStat <> 0
                           BEGIN     
							       --ROLLBACK  TRAN --Deshace la Transaccion   --LISLAS 15-SEP-2006 Ya tiene Commit/Rollback  el SP anterior
							       RAISERROR 99999 'Ocurrio un Error al Consolidar Directamente la Orden de Servicio'
							       SELECT -10
							       RETURN -10   ----SELECT @intErrorCode = 7  --ERROR 7 : 'Error al Consolidar Directamente los Productos en el Contenedor'    
							       --RETURN @FAILURE	
						   END 
		            	print 'ya inserto producto'  
                         
                   END -- IF ( @lint_ItemProductId   > 0  )
                ELSE
                   BEGIN --ELSE --IF ( @lint_ItemProductId   > 0  )                   

	                       --- OBTENER LA SUMA DE CANTIDADDES Y PESOS DE TODAS LAS TARJAS                        										
						   SELECT @lint_SumQtyProd =    ISNULL(SUM (tblclsYardVerifTicketItem.intYVerifTItemProdPackingQty ) ,0 ),
						          @ldec_SumWeightProd = ISNULL(SUM (tblclsYardVerifTicketItem.decYVerifTItemProdGrossWeight ) ,0 )
						   FROM tblclsYardVerifTicketItem
						   WHERE tblclsYardVerifTicketItem.intServiceOrderId = @intServiceOrderId
						   AND   tblclsYardVerifTicketItem.intServiceOrderItemId = @intServiceOrderItemId
						   AND   tblclsYardVerifTicketItem.intProductId = @intProductId
						   AND   tblclsYardVerifTicketItem.intProductPackingId = @intProductPackingId
                   
                     --- si existe se suma peso 
	                   BEGIN TRANSACTION 
	                   
	                        UPDATE tblclsContainerProduct
		                    SET tblclsContainerProduct.intContInvProdQuantity = @lint_SumQtyProd  ,  
		                        tblclsContainerProduct.decContInvProdWeight =  @ldec_SumWeightProd
		                    WHERE tblclsContainerProduct.intContainerUniversalId = @lint_UniversalContainer
		                    AND  tblclsContainerProduct.intItemId = @lint_ItemProductId
	               
	                   
		                    /*UPDATE tblclsContainerProduct
		                    SET tblclsContainerProduct.intContInvProdQuantity =  tblclsContainerProduct.intContInvProdQuantity + @intYVerifTItemProdPackingQty  ,  
		                        tblclsContainerProduct.decContInvProdWeight =  tblclsContainerProduct.decContInvProdWeight + @decYVerifTItemProdGrossWeight
		                    WHERE tblclsContainerProduct.intContainerUniversalId = @lint_UniversalContainer
		                    AND  tblclsContainerProduct.intItemId = @lint_ItemProductId
		                    */
	               
					        IF @@Error = 1  --Validacion al Insertar el Registro   
							 BEGIN   
							   ROLLBACK TRAN    --Aborta los Cambios   
							   SELECT @strError = '>>--ERROR: Al guardar detalle tarja '
							   SELECT -11							   
							   RETURN -11  --ERROR: Al Ingresar el Contenedor a Inventario   
							 END 						 
							 
						COMMIT TRAN 	
					END	--ELSE --IF ( @lint_ItemProductId   > 0  )
						
				   -- obtener el numero de transaccion 
				     SELECT @intTransactType  = tblclsContainerTransacType.intContTransTypeId  
				     FROM  tblclsContainerTransacType 
				     WHERE  tblclsContainerTransacType.strContTransTypeIdentifier = 'CCONS'
                                        
                   -- definir el comentario 
                     SET  @strComents = ' En tarja:' + CONVERT(VARCHAR(12),@intYardVerifTicketId ) + 'Peso:' +  CONVERT(VARCHAR(12), @decYVerifTItemProdGrossWeight) + 'Cantidad:'+ CONVERT(VARCHAR(12),@intYVerifTItemProdPackingQty)
                     
                     --- definir en histico , consolidacion parcial                      
                      --EXECUTE @SPStat =   spUpdateHistoryServiceOrder @intTransactType , @lint_UniversalContainer, @intServiceId ,
                        --                       @intServiceOrderId, @intServiceOrderItemId , @strComents, @strUser    
                      
                      EXECUTE @SPStat =   spUpdateHistoryServiceOrder 'CCONS' , @lint_UniversalContainer, @intServiceId ,
                                               @intServiceOrderId, @intServiceOrderItemId , @strComents, @strUser    

                        IF @SPStat <> 0
                           BEGIN     
							       --ROLLBACK  TRAN --Deshace la Transaccion   --LISLAS 15-SEP-2006 Ya tiene Commit/Rollback  el SP anterior
							       RAISERROR 99999 'Ocurrio un Error al guardar historico de solicitud'
							       SELECT -12
							       RETURN  -12 -- SELECT @intErrorCode = 7  --ERROR 7 : 'Error al Consolidar Directamente los Productos en el Contenedor'    
							       --RETURN @FAILURE	
						   END 
                   
                   
                       --- sumar los pesos de todas las tarjas  con universal 
                      SELECT @llng_ContainerUniv =   tblclsServiceOrderItem.intContainerUniversalId
                      FROM tblclsServiceOrderItem
                      WHERE tblclsServiceOrderItem.intServiceOrderId = @intServiceOrderId
                      AND   tblclsServiceOrderItem.intServiceOrderItemId = @intServiceOrderItemId
                      
                      
                      SELECT  --@lint_SumQtyProd =    ISNULL(SUM (tblclsYardVerifTicketItem.intYVerifTItemProdPackingQty ) ,0 ),
					          @ldec_SumWeightProd = ISNULL(SUM (tblclsYardVerifTicketItem.decYVerifTItemProdGrossWeight ) ,0 )
					          
                      FROM tblclsServiceOrderItem
                       INNER JOIN tblclsYardVerifTicketItem ON tblclsYardVerifTicketItem.intServiceOrderId = tblclsServiceOrderItem.intServiceOrderId
                                                            AND tblclsYardVerifTicketItem.intServiceOrderItemId = tblclsServiceOrderItem.intServiceOrderItemId
                                                            
                      WHERE tblclsServiceOrderItem.intServiceOrderId = @intServiceOrderId
                      AND  tblclsServiceOrderItem.intContainerUniversalId = @llng_ContainerUniv



                   
               --- actualizar el peso del contenedor y 
                   BEGIN TRANSACTION 
                   
	                     UPDATE tblclsContainerInventory
	                     SET  tblclsContainerInventory.decContainerInventoryWeight =  @decYVerifTItemProdGrossWeight	                     
	                     WHERE tblclsContainerInventory.intContainerUniversalId = @lint_UniversalContainer
                     
                         SELECT @StatErrSP = @@error
        
				        IF @StatErrSP <> 0  --Validacion al Insertar el producto
				          BEGIN
				              print 'Error al actualizar el Inv. de contenedor'
				              ROLLBACK TRANSACTION 
				              SELECT -13
				              RETURN (-13) 
				          END
				        ELSE 
				            COMMIT TRANSACTION 				        
           
               --- dejar el estatus en parcialmente conslodida,
               
               SELECT @lint_PhyscalStatus = tblclsContainerPhysicalStatus.intContPhyStatId
               FROM tblclsContainerPhysicalStatus
               WHERE tblclsContainerPhysicalStatus.strContPhyStatIdentifier = 'PVACIO'
                ---se registrara historico ,, poner comentarios tarja 
               
                    BEGIN TRANSACTION 
                   
	                     UPDATE tblclsContainerInventory
	                     SET  tblclsContainerInventory.intContPhyStatId =  @lint_PhyscalStatus
	                     WHERE tblclsContainerInventory.intContainerUniversalId = @lint_UniversalContainer
                     
                         SELECT @StatErrSP = @@error
        
				        IF @StatErrSP <> 0  --Validacion al Insertar el producto
				          BEGIN
				              print 'Error al actualizar el Inv. de contenedor'
				              ROLLBACK TRANSACTION 
				              SELECT -14
				              RETURN (-14) 
				          END
				        ELSE 
			            COMMIT TRANSACTION 				        

                --- ver si tiene numero de visita 
                   SELECT @lint_InvisitId =  ISNULL(tblclsVisitServiceOrder.intVisitId,0)
                   FROM tblclsVisitServiceOrder
                   WHERE tblclsVisitServiceOrder.intServiceOrderId = @intServiceOrderId
                   AND   tblclsVisitServiceOrder.intServiceOrderItemId = @intServiceOrderItemId
                   
                
                --- ver si hay que dar check in 
                 IF @lint_InvisitId > 0 
	                BEGIN 	                
	                     SELECT  @ldtm_CheckInDate =   ISNULL(tblclsVisit.dtmVisitDatetimeIn, '19000101'),
                                 @ldtm_CheckOutDate =   ISNULL(tblclsVisit.dtmVisitDatetimeOut, '19000101')
	                     FROM tblclsVisit
	                     WHERE tblclsVisit.intVisitId = @lint_InvisitId
	                     
	                     --- si no tiene chec-in
	                     IF (@ldtm_CheckInDate ='19000101')
	                       BEGIN
                                  SET @ldtm_Today  = GETDATE( )
	                          EXECUTE spInOutVisit  @intVisitId=@lint_InvisitId, @dtmReceptionDate=@ldtm_Today , @strService='REC', @strUser=@strUser
	                       END 
	                       
	                END 
	                             
             END -- IF @strServiceIdentifier = 'CONSD'


          --- desconsolidacion de contenedor 
         IF @strServiceIdentifier = 'DESC'
             BEGIN
             
               -- obtener peso  -- @decYVerifTItemProdGrossWeight   udtDecimal,
                                
               --.--- buscar producto 
                              
               SELECT @CustType  = intServiceOrderInvoiceToTypeId,
                         @CustId    = intServiceOrderInvoiceToId
               FROM   tblclsServiceOrder SO,
                         tblclsServiceOrderItem SOI
			   WHERE  SO.intServiceOrderId       = SOI.intServiceOrderId   AND   
				         SO.intServiceOrderId       = @intServiceOrderId AND
				         SOI.intServiceOrderItemId  = @intServiceOrderItemId
				         
			   SET @lint_ItemProductId = 0
			   
               ----- definir valor de item 
                              
               SELECT @lint_ItemProductId  = ISNULL(MAX( tblclsContainerProduct.intItemId),0)
			   FROM tblclsContainerProduct 
			   WHERE tblclsContainerProduct.intContainerUniversalId = @lint_UniversalContainer
			   AND   tblclsContainerProduct.intProductId = @intProductId    
			   AND   tblclsContainerProduct.intCustomerId = @CustId
			   AND   tblclsContainerProduct.intCustomerTypeId = @CustType
			   AND   tblclsContainerProduct.intProductPackingId = @intProductPackingId

               ---- si existe el producto se hace una resta de la cantidad y peso en base a lo de la tarja 
                 IF ( @lint_ItemProductId = 0  )
                   BEGIN                          

                    --- obtener el peso y cantidad actual
                     SET @ldec_ProdWeight=0
                     SET @ldec_InvWeight=0
                     SET @int_QtyProduct=0
                                        
                     
                     SELECT  @ldec_ProdWeight = tblclsContainerProduct.decContInvProdWeight, 
                              @int_QtyProduct = tblclsContainerProduct.intContInvProdQuantity
                     FROM tblclsContainerProduct
                     WHERE tblclsContainerProduct.intContainerUniversalId = @lint_UniversalContainer
                     AND tblclsContainerProduct.intProductId  = @intProductId
                     AND tblclsContainerProduct.intItemId =  @lint_ItemProductId 
                     
                    --- ajustar diferencias 
                     --- en peso 
                     IF @intYVerifTItemProdPackingQty  > @ldec_ProdWeight
                     	 BEGIN 
	                       SET @ldec_ProdWeight = 0
	                      END 
                     ELSE
                         BEGIN
                           SET @ldec_ProdWeight = @ldec_ProdWeight - @intYVerifTItemProdPackingQty
                         END  -- ELSE  IF @intYVerifTItemProdPackingQty  > @ldec_ProdWeight
                         
                     --- en cantidad 
                     IF ( @intYVerifTItemProdPackingQty >  @int_QtyProduct ) 
                      BEGIN 
                         SET  @int_QtyProduct = 0 
                      END
                     ELSE
                      BEGIN 
                         SET  @int_QtyProduct = @int_QtyProduct - @intYVerifTItemProdPackingQty
                      END--- ELSE - IF ( @intYVerifTItemProdPackingQty >  @int_QtyProduct ) 
                       
                      -- SI PESO Y CANTIDAD SON CEROS, SE ELIMINA, SINO SE DEJA 
                      IF @int_QtyProduct = 0 AND  @ldec_ProdWeight  = 0 
                        BEGIN
                        
                            BEGIN TRANSACTION                            
                            
                               DELETE tblclsContainerProduct
                               WHERE tblclsContainerProduct.intContainerUniversalId = @lint_UniversalContainer
                                        AND tblclsContainerProduct.intProductId  = @intProductId 
                                        AND tblclsContainerProduct.intItemId =  @lint_ItemProductId 
                                       
                              SELECT @StatErrSP = @@error
        
					           IF @StatErrSP <> 0  --Validacion al Insertar el producto
						          BEGIN
						              print 'Error al actualizar el Inv. de contenedor'
						              ROLLBACK TRANSACTION 
						              SELECT -151
						              RETURN (-151) 
						          END
						        ELSE 
					            COMMIT TRANSACTION 				        

                        END -- IF @int_QtyProduct = 0 AND  @ldec_ProdWeight  = 0 
                      ELSE
                        BEGIN
                            BEGIN TRANSACTION 

                               UPDATE tblclsContainerProduct
                               SET  tblclsContainerProduct.decContInvProdWeight = @ldec_ProdWeight , 
                                    tblclsContainerProduct.intContInvProdQuantity = @int_QtyProduct
                               WHERE tblclsContainerProduct.intContainerUniversalId = @lint_UniversalContainer
                                        AND tblclsContainerProduct.intProductId  = @intProductId 
                                        AND tblclsContainerProduct.intItemId =  @lint_ItemProductId 
                                       
                              SELECT @StatErrSP = @@error
        
					           IF @StatErrSP <> 0  --Validacion al Insertar el producto
						          BEGIN
						              print 'Error al actualizar el Inv. de contenedor'
						              ROLLBACK TRANSACTION 
						              SELECT -16
						              RETURN (-16) 
						          END
						        ELSE 
					            COMMIT TRANSACTION 				        

                        END  -- ELSE  --- IF @int_QtyProduct = 0 AND  @ldec_ProdWeight  = 0 
                        
                        
                         
                   END -- IF ( @lint_ItemProductId   > 0  )

		   -- obtener el numero de transaccion 
				     SELECT @intTransactType  = tblclsContainerTransacType.intContTransTypeId  
				     FROM  tblclsContainerTransacType 
				     WHERE  tblclsContainerTransacType.strContTransTypeIdentifier = 'CDESC'
                                        
                   -- definir el comentario 
                     SET  @strComents = ' En tarja:' + CONVERT(VARCHAR(12),@intYardVerifTicketId ) + 'Peso:' +  CONVERT(VARCHAR(12), @decYVerifTItemProdGrossWeight) + 'Cantidad:'+ CONVERT(VARCHAR(12),@intYVerifTItemProdPackingQty)
                     
                     --- definir en histico , consolidacion parcial                      
                     -- EXECUTE @SPStat =   spUpdateHistoryServiceOrder @intTransactType , @lint_UniversalContainer, @intServiceId ,
                     --                          @intServiceOrderId, @intServiceOrderItemId , @strComents, @strUser    
                     EXECUTE @SPStat =   spUpdateHistoryServiceOrder 'CDESC' , @lint_UniversalContainer, @intServiceId ,
                                               @intServiceOrderId, @intServiceOrderItemId , @strComents, @strUser                                             
                      
                        IF @SPStat <> 0
                           BEGIN     
							       --ROLLBACK  TRAN --Deshace la Transaccion   --LISLAS 15-SEP-2006 Ya tiene Commit/Rollback  el SP anterior
							       RAISERROR 99999 'Ocurrio un Error al guardar historico de solicitud'
							       SELECT -17
							       RETURN  -17 --SELECT @intErrorCode = 7  --ERROR 7 : 'Error al Consolidar Directamente los Productos en el Contenedor'    
							       --RETURN @FAILURE	
						   END 
                   
               
                   
               --- actualizar el peso del contenedor y 
                  --- obtener el peso del contenedor 
                    SELECT @ldec_InvWeight = ISNULL(tblclsContainerInventory.decContainerInventoryWeight,0)
                    FROM tblclsContainerInventory
                    WHERE tblclsContainerInventory.intContainerUniversalId = @lint_UniversalContainer
                    
                  -- definir el valor que tendra el contenedor en inventario 
                  IF @decYVerifTItemProdGrossWeight > @ldec_InvWeight 
                     BEGIN 
                      SET  @ldec_InvWeight  =  0
                     END   -- IF @decYVerifTItemProdGrossWeight > @ldec_InvWeight 
                  ELSE 
                     BEGIN 
                       SET  @ldec_InvWeight  =  @decYVerifTItemProdGrossWeight -  @ldec_InvWeight  
                     END   -- ELSE -- IF @decYVerifTItemProdGrossWeight > @ldec_InvWeight 
                     
                     
                
                   BEGIN TRANSACTION 
                   
	                     UPDATE tblclsContainerInventory
	                     SET  tblclsContainerInventory.decContainerInventoryWeight = @ldec_InvWeight
	                     WHERE tblclsContainerInventory.intContainerUniversalId = @lint_UniversalContainer
                     
                         SELECT @StatErrSP = @@error
        
				        IF @StatErrSP <> 0  --Validacion al Insertar el producto
				          BEGIN
				              print 'Error al actualizar el Inv. de contenedor'
				              ROLLBACK TRANSACTION 
				              SELECT -18
				              RETURN (-18) 
				          END
				        ELSE 
				            COMMIT TRANSACTION 				        
           
               --- dejar el estatus en parcialmente conslodida,
               
               SELECT @lint_PhyscalStatus = tblclsContainerPhysicalStatus.intContPhyStatId
               FROM tblclsContainerPhysicalStatus
               WHERE tblclsContainerPhysicalStatus.strContPhyStatIdentifier = 'PLLENO'
               
                ---se registrara historico ,, poner comentarios tarja 
               
                    BEGIN TRANSACTION 
                   
	                     UPDATE tblclsContainerInventory
	                     SET  tblclsContainerInventory.intContPhyStatId =  @lint_PhyscalStatus
	                     WHERE tblclsContainerInventory.intContainerUniversalId = @lint_UniversalContainer
                     
                         SELECT @StatErrSP = @@error
        
				        IF @StatErrSP <> 0  --Validacion al Insertar el producto
				          BEGIN
				              print 'Error al actualizar el Inv. de contenedor'
				              ROLLBACK TRANSACTION 
				              SELECT -19
				              RETURN (-19) 
				          END
				        ELSE 
			            COMMIT TRANSACTION 				        

                                 
             END -- IF @strServiceIdentifier = 'DESC'

        
           --- desconsolidacion directa del contenedor 
        IF @strServiceIdentifier = 'DESCD'
             BEGIN
             
               -- obtener peso  -- @decYVerifTItemProdGrossWeight   udtDecimal,
                                
               --.--- buscar producto 
                              
               SELECT @CustType  = intServiceOrderInvoiceToTypeId,
                         @CustId    = intServiceOrderInvoiceToId
               FROM   tblclsServiceOrder SO,
                         tblclsServiceOrderItem SOI
			   WHERE  SO.intServiceOrderId       = SOI.intServiceOrderId   AND   
				         SO.intServiceOrderId       = @intServiceOrderId AND
				         SOI.intServiceOrderItemId  = @intServiceOrderItemId 
				         
			   SET @lint_ItemProductId = 0
			   
               ----- definir valor de item 
                              
               SELECT @lint_ItemProductId  = ISNULL(MAX( tblclsContainerProduct.intItemId),0)
			   FROM tblclsContainerProduct 
			   WHERE tblclsContainerProduct.intContainerUniversalId = @lint_UniversalContainer
			   AND tblclsContainerProduct.intProductId = @intProductId    
			   AND   tblclsContainerProduct.intCustomerId = @CustId
			   AND   tblclsContainerProduct.intCustomerTypeId = @CustType
			   AND tblclsContainerProduct.intProductPackingId = @intProductPackingId

               ---- si existe el producto se hace una resta de la cantidad y peso en base a lo de la tarja 
                 IF ( @lint_ItemProductId > 0  )
                   BEGIN                          

                    --- obtener el peso y cantidad actual
                     SET @ldec_ProdWeight=0
                     SET @ldec_InvWeight=0
                     SET @int_QtyProduct=0
                                        
                     
                     SELECT  @ldec_ProdWeight = tblclsContainerProduct.decContInvProdWeight, 
                              @int_QtyProduct = tblclsContainerProduct.intContInvProdQuantity
                     FROM tblclsContainerProduct
                     WHERE tblclsContainerProduct.intContainerUniversalId = @lint_UniversalContainer
                     AND tblclsContainerProduct.intProductId  = @intProductId
                     AND tblclsContainerProduct.intItemId =  @lint_ItemProductId 
                     
                    --- ajustar diferencias 
                     --- en peso 
                     IF @intYVerifTItemProdPackingQty  > @ldec_ProdWeight
                     	 BEGIN 
	                       SET @ldec_ProdWeight = 0
	                      END 
                     ELSE
                         BEGIN
                           SET @ldec_ProdWeight = @ldec_ProdWeight - @intYVerifTItemProdPackingQty
                         END  -- ELSE  IF @intYVerifTItemProdPackingQty  > @ldec_ProdWeight
                         
                     --- en cantidad 
                     IF ( @intYVerifTItemProdPackingQty >  @int_QtyProduct ) 
                      BEGIN 
                         SET  @int_QtyProduct = 0 
                      END
                     ELSE
                      BEGIN 
                         SET  @int_QtyProduct = @int_QtyProduct - @intYVerifTItemProdPackingQty
                      END--- ELSE - IF ( @intYVerifTItemProdPackingQty >  @int_QtyProduct ) 
                       
                      -- SI PESO Y CANTIDAD SON CEROS, SE ELIMINA, SINO SE DEJA 
                      IF @int_QtyProduct = 0 AND  @ldec_ProdWeight  = 0 
                        BEGIN
                        
                            BEGIN TRANSACTION                            
                            
                               DELETE tblclsContainerProduct
                               WHERE tblclsContainerProduct.intContainerUniversalId = @lint_UniversalContainer
                                        AND tblclsContainerProduct.intProductId  = @intProductId 
                                        AND tblclsContainerProduct.intItemId =  @lint_ItemProductId 
                                       
                              SELECT @StatErrSP = @@error
        
					           IF @StatErrSP <> 0  --Validacion al Insertar el producto
						          BEGIN
						              print 'Error al actualizar el Inv. de contenedor'
						              ROLLBACK TRANSACTION 
						              SELECT -20
						              RETURN (-20) 
						          END
						        ELSE 
					            COMMIT TRANSACTION 				        

                        END -- IF @int_QtyProduct = 0 AND  @ldec_ProdWeight  = 0 
                      ELSE
                        BEGIN
                            BEGIN TRANSACTION 

                               UPDATE tblclsContainerProduct
                               SET  tblclsContainerProduct.decContInvProdWeight = @ldec_ProdWeight , 
                                    tblclsContainerProduct.intContInvProdQuantity = @int_QtyProduct
                               WHERE tblclsContainerProduct.intContainerUniversalId = @lint_UniversalContainer
                                        AND tblclsContainerProduct.intProductId  = @intProductId 
                                        AND tblclsContainerProduct.intItemId =  @lint_ItemProductId 
                                       
                              SELECT @StatErrSP = @@error
        
					           IF @StatErrSP <> 0  --Validacion al Insertar el producto
						          BEGIN
						              print 'Error al actualizar el Inv. de contenedor'
						              ROLLBACK TRANSACTION 
						              SELECT -21
						              RETURN (-21) 
						          END
						        ELSE 
					            COMMIT TRANSACTION 				        

                        END  -- ELSE  --- IF @int_QtyProduct = 0 AND  @ldec_ProdWeight  = 0 
                         
                   END -- IF ( @lint_ItemProductId   > 0  )

		   -- obtener el numero de transaccion 
				     SELECT @intTransactType  = tblclsContainerTransacType.intContTransTypeId  
				     FROM  tblclsContainerTransacType 
				     WHERE  tblclsContainerTransacType.strContTransTypeIdentifier = 'CDESC'
                                        
                   -- definir el comentario 
                     SET  @strComents = ' En tarja:' + CONVERT(VARCHAR(12),@intYardVerifTicketId ) + 'Peso:' +  CONVERT(VARCHAR(12), @decYVerifTItemProdGrossWeight) + 'Cantidad:'+ CONVERT(VARCHAR(12),@intYVerifTItemProdPackingQty)
                     
                     --- definir en histico , consolidacion parcial                      
                     --EXECUTE @SPStat =   spUpdateHistoryServiceOrder @intTransactType , @lint_UniversalContainer, @intServiceId ,
                       --                       @intServiceOrderId, @intServiceOrderItemId , @strComents, @strUser    
                      
                     EXECUTE @SPStat =   spUpdateHistoryServiceOrder 'CDESC' , @lint_UniversalContainer, @intServiceId ,
                                               @intServiceOrderId, @intServiceOrderItemId , @strComents, @strUser    

                        IF @SPStat <> 0
                           BEGIN     
							       --ROLLBACK  TRAN --Deshace la Transaccion   --LISLAS 15-SEP-2006 Ya tiene Commit/Rollback  el SP anterior
							       RAISERROR 99999 'Ocurrio un Error al guardar historico de solicitud'
							      SELECT 7 --- SELECT @intErrorCode = 7  --ERROR 7 : 'Error al Consolidar Directamente los Productos en el Contenedor'    
							                                   SELECT -22
      	                                                       RETURN -22 
							       --RETURN @FAILURE	
						   END 
                   
                  -- END   --ELSE --IF ( @lint_ItemProductId   > 0  )
                   
               --- actualizar el peso del contenedor y 
                  --- obtener el peso del contenedor 
                    SELECT @ldec_InvWeight = ISNULL(tblclsContainerInventory.decContainerInventoryWeight,0)
                    FROM tblclsContainerInventory
                    WHERE tblclsContainerInventory.intContainerUniversalId = @lint_UniversalContainer
                    
                  -- definir el valor que tendra el contenedor en inventario 
                  IF @decYVerifTItemProdGrossWeight > @ldec_InvWeight 
                     BEGIN 
                      SET  @ldec_InvWeight  =  0
                     END   -- IF @decYVerifTItemProdGrossWeight > @ldec_InvWeight 
                  ELSE 
                     BEGIN 
                       SET  @ldec_InvWeight  =  @decYVerifTItemProdGrossWeight -  @ldec_InvWeight  
                     END   -- ELSE -- IF @decYVerifTItemProdGrossWeight > @ldec_InvWeight 
                     
                     
                
                   BEGIN TRANSACTION 
                   
	                     UPDATE tblclsContainerInventory
	                     SET  tblclsContainerInventory.decContainerInventoryWeight = @ldec_InvWeight
	                     WHERE tblclsContainerInventory.intContainerUniversalId = @lint_UniversalContainer
                     
                         SELECT @StatErrSP = @@error
        
				        IF @StatErrSP <> 0  --Validacion al Insertar el producto
				          BEGIN
				              print 'Error al actualizar el Inv. de contenedor'
				              ROLLBACK TRANSACTION 
				              SELECT -23
				              RETURN (-23) 
				          END
				        ELSE 
				            COMMIT TRANSACTION 				        
           
               --- dejar el estatus en parcialmente conslodida,
               
               SELECT @lint_PhyscalStatus = tblclsContainerPhysicalStatus.intContPhyStatId
               FROM tblclsContainerPhysicalStatus
               WHERE tblclsContainerPhysicalStatus.strContPhyStatIdentifier = 'PLLENO'
               
                ---se registrara historico ,, poner comentarios tarja 
               
                    BEGIN TRANSACTION 
                   
	                     UPDATE tblclsContainerInventory
	                     SET  tblclsContainerInventory.intContPhyStatId =  @lint_PhyscalStatus
	                     WHERE tblclsContainerInventory.intContainerUniversalId = @lint_UniversalContainer
                     
                         SELECT @StatErrSP = @@error
        
				        IF @StatErrSP <> 0  --Validacion al Insertar el producto
				          BEGIN
				              print 'Error al actualizar el Inv. de contenedor'
				              ROLLBACK TRANSACTION 
				              SELECT -24
				              RETURN (-24) 
				          END
				        ELSE 
			            COMMIT TRANSACTION 				        
			            
			   
			 --- ver si tiene numero de visita 
                   SELECT @lint_InvisitId =  ISNULL(tblclsVisitServiceOrder.intVisitId,0)
                   FROM tblclsVisitServiceOrder
                   WHERE tblclsVisitServiceOrder.intServiceOrderId = @intServiceOrderId
                   AND   tblclsVisitServiceOrder.intServiceOrderItemId = @intServiceOrderItemId
                   
                
                --- ver si hay que dar check in 
                 IF @lint_InvisitId > 0 
	                BEGIN 	                
	                     SELECT  @ldtm_CheckInDate =   ISNULL(tblclsVisit.dtmVisitDatetimeIn, '19000101'),
                                 @ldtm_CheckOutDate =   ISNULL(tblclsVisit.dtmVisitDatetimeOut, '19000101')
	                     FROM tblclsVisit
	                     WHERE tblclsVisit.intVisitId = @lint_InvisitId
	                     
	                     --- si no tiene chec-in
	                     IF (@ldtm_CheckInDate ='19000101')
	                       BEGIN
                                 SET   @ldtm_Today = GETDATE()
	                          EXECUTE spInOutVisit  @intVisitId=@lint_InvisitId, @dtmReceptionDate=@ldtm_Today , @strService='REC', @strUser=@strUser
	                       END 	                       
	                END  	                
                    
             END -- IF @strServiceIdentifier = 'DESCD'

     IF @strServiceIdentifier = 'CONSDESC'
     BEGIN
        
		   -- obtener el numero de transaccion 
				     SELECT @intTransactType  = tblclsContainerTransacType.intContTransTypeId  
				     FROM  tblclsContainerTransacType 
				     WHERE  tblclsContainerTransacType.strContTransTypeIdentifier = 'CCONDESC'
                                        
                   -- definir el comentario 
                     SET  @strComents = ' En tarja:' + CONVERT(VARCHAR(12),@intYardVerifTicketId ) + 'Peso:' +  CONVERT(VARCHAR(12), @decYVerifTItemProdGrossWeight) + 'Cantidad:'+ CONVERT(VARCHAR(12),@intYVerifTItemProdPackingQty)
                     
                     --- definir en histico , consolidacion parcial                      
                     -- EXECUTE @SPStat =   spUpdateHistoryServiceOrder @intTransactType , @lint_UniversalContainer, @intServiceId ,
                                               --@intServiceOrderId, @intServiceOrderItemId , @strComents, @strUser    
                                               
					 EXECUTE @SPStat =   spUpdateHistoryServiceOrder 'CCONDESC' , @lint_UniversalContainer, @intServiceId ,
                                               @intServiceOrderId, @intServiceOrderItemId , @strComents, @strUser                          
                      
                        IF @SPStat <> 0
                           BEGIN     
							       --ROLLBACK  TRAN --Deshace la Transaccion   --LISLAS 15-SEP-2006 Ya tiene Commit/Rollback  el SP anterior
							       RAISERROR 99999 'Ocurrio un Error al guardar historico de solicitud'
							       SELECT -25
							       RETURN -25 --- SELECT @intErrorCode = 7  --ERROR 7 : 'Error al Consolidar Directamente los Productos en el Contenedor'    
							       --RETURN @FAILURE	
						   END 

     END -- IF @strServiceIdentifier = 'CONSDESC'
     
     IF @strServiceIdentifier = 'ROCUL'
     BEGIN
        
		   -- obtener el numero de transaccion 
				     SELECT @intTransactType  = tblclsContainerTransacType.intContTransTypeId  
				     FROM  tblclsContainerTransacType 
				     WHERE  tblclsContainerTransacType.strContTransTypeIdentifier = 'CCONDESC'
                                        
                   -- definir el comentario 
                     SET  @strComents = ' En tarja:' + CONVERT(VARCHAR(12),@intYardVerifTicketId ) + 'Peso:' +  CONVERT(VARCHAR(12), @decYVerifTItemProdGrossWeight) + 'Cantidad:'+ CONVERT(VARCHAR(12),@intYVerifTItemProdPackingQty)
                     
                     --- definir en histico , consolidacion parcial                      
                     --EXECUTE @SPStat =   spUpdateHistoryServiceOrder @intTransactType , @lint_UniversalContainer, @intServiceId ,
                     --                          @intServiceOrderId, @intServiceOrderItemId , @strComents, @strUser    
                                               
                     EXECUTE @SPStat =   spUpdateHistoryServiceOrder'CCONDESC' , @lint_UniversalContainer, @intServiceId ,
                                               @intServiceOrderId, @intServiceOrderItemId , @strComents, @strUser                              
                      
                        IF @SPStat <> 0
                           BEGIN     
							       --ROLLBACK  TRAN --Deshace la Transaccion   --LISLAS 15-SEP-2006 Ya tiene Commit/Rollback  el SP anterior
							       RAISERROR 99999 'Ocurrio un Error al guardar historico de solicitud'
							       SELECT -26
							      RETURN -26 --- SELECT @intErrorCode = 7  --ERROR 7 : 'Error al Consolidar Directamente los Productos en el Contenedor'    
							       --RETURN @FAILURE	
						   END 
      END -- IF @strServiceIdentifier = 'ROCUL'
     
     IF @strServiceIdentifier = 'ROCUL'
     BEGIN
        
		   -- obtener el numero de transaccion 
				     SELECT @intTransactType  = tblclsContainerTransacType.intContTransTypeId  
				     FROM  tblclsContainerTransacType 
				     WHERE  tblclsContainerTransacType.strContTransTypeIdentifier = 'CCONDESC'
                                        
                   -- definir el comentario 
                     SET  @strComents = ' En tarja:' + CONVERT(VARCHAR(12),@intYardVerifTicketId ) + 'Peso:' +  CONVERT(VARCHAR(12), @decYVerifTItemProdGrossWeight) + 'Cantidad:'+ CONVERT(VARCHAR(12),@intYVerifTItemProdPackingQty)
                     
                     --- definir en histico , consolidacion parcial                      
                     --EXECUTE @SPStat =   spUpdateHistoryServiceOrder @intTransactType , @lint_UniversalContainer, @intServiceId ,
                     --                        @intServiceOrderId, @intServiceOrderItemId , @strComents, @strUser    
                     EXECUTE @SPStat =   spUpdateHistoryServiceOrder 'CCONDESC' , @lint_UniversalContainer, @intServiceId ,
                                               @intServiceOrderId, @intServiceOrderItemId , @strComents, @strUser    

                        IF @SPStat <> 0
                           BEGIN     
							       --ROLLBACK  TRAN --Deshace la Transaccion   --LISLAS 15-SEP-2006 Ya tiene Commit/Rollback  el SP anterior
							       RAISERROR 99999 'Ocurrio un Error al guardar historico de solicitud'
							       SELECT -27
							        RETURN -27 ---SELECT @intErrorCode = 7  --ERROR 7 : 'Error al Consolidar Directamente los Productos en el Contenedor'    
							       --RETURN @FAILURE	
						   END 
      END -- IF @strServiceIdentifier = 'ROCUL'
     
     IF @strServiceIdentifier = 'PREV'
     BEGIN
        
		   -- obtener el numero de transaccion 
				     SELECT @intTransactType  = tblclsContainerTransacType.intContTransTypeId  
				     FROM  tblclsContainerTransacType 
				     WHERE  tblclsContainerTransacType.strContTransTypeIdentifier = 'CCONDESC'
                                        
                   -- definir el comentario 
                     SET  @strComents = ' En tarja:' + CONVERT(VARCHAR(12),@intYardVerifTicketId ) + 'Peso:' +  CONVERT(VARCHAR(12), @decYVerifTItemProdGrossWeight) + 'Cantidad:'+ CONVERT(VARCHAR(12),@intYVerifTItemProdPackingQty)
                     
                     --- definir en histico , consolidacion parcial                      
                     --EXECUTE @SPStat =   spUpdateHistoryServiceOrder @intTransactType , @lint_UniversalContainer, @intServiceId ,
                                               --@intServiceOrderId, @intServiceOrderItemId , @strComents, @strUser    
                                               
                     EXECUTE @SPStat =   spUpdateHistoryServiceOrder 'CCONDESC' , @lint_UniversalContainer, @intServiceId ,
                                               @intServiceOrderId, @intServiceOrderItemId , @strComents, @strUser    
                                               
                      
                        IF @SPStat <> 0
                           BEGIN     
							       --ROLLBACK  TRAN --Deshace la Transaccion   --LISLAS 15-SEP-2006 Ya tiene Commit/Rollback  el SP anterior
							       RAISERROR 99999 'Ocurrio un Error al guardar historico de solicitud'
							       SELECT -28
							       RETURN -28 --- SELECT @intErrorCode = 7  --ERROR 7 : 'Error al Consolidar Directamente los Productos en el Contenedor'    
							       --RETURN @FAILURE	
						   END 
      END -- IF @strServiceIdentifier = 'PREV'
    
      ------------------------------------------------   
      ------------------------------------------------   
      ----------- 
      
       ----- obtencion de la mas reciente informacion del inventario , para posteriormente retornar 
           	
		 SELECT  @lint_UniversalContainer = ISNULL( tblclsServiceOrderItem.intContainerUniversalId ,0 )
		 FROM    tblclsServiceOrderItem
		 WHERE   tblclsServiceOrderItem.intServiceOrderId = @intServiceOrderId
		    AND    tblclsServiceOrderItem.intServiceOrderItemId = @intServiceOrderItemId    	  
       
        IF (  @lint_UniversalContainer ) > 0 
         BEGIN 

               SELECT  @lint_BlnFull =  ISNULL(tblclsContainerInventory.blnContainerIsFull,-1),
                       @ldec_Wieght = tblclsContainerInventory.decContainerInventoryWeight,
                       @lstr_PhyscalStatus = ISNULL(tblclsContainerPhysicalStatus.strContPhyStatIdentifier,'-Z')
                                       
               FROM tblclsContainerInventory
                 INNER JOIN tblclsContainerPhysicalStatus ON tblclsContainerInventory.intContPhyStatId = tblclsContainerPhysicalStatus.intContPhyStatId
               WHERE intContainerUniversalId = @lint_UniversalContainer
         END 
	
	
    ----  JCADENA 17 NOV 2015 ----->>>>>>> 
 
  	--- retorna el numero de tarja peso en inventario, estado fisisco , contenedor en peso actual del contenedor, lleno o vacio
	SELECT @intVerificationItemId 'intVerificationItemId' , @ldec_Wieght 'Weight' ,  @lstr_PhyscalStatus 'Physcal', @lint_BlnFull 'blnFull'
	--SELECT @intVerificationItemId , @ldec_Wieght ,  @lstr_PhyscalStatus , @lint_BlnFull

