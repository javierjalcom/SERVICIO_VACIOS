/*

DROP PROCEDURE spUpdateProductsContCFS

*/

CREATE PROCEDURE spUpdateProductsContCFS (
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
                DESCONSOLIDACION NORMAL  / DESCONSOLIDACION DIRECTA  
                   - DEJA EN 0 EL PESO NETO
                   - ELIMINA DE CONTAINER PRODUCT                 
                CONSOLIDACION NORMAL 
                   -- ACTUALIZAR EL PESO 
                   -- INSERTAR EL PRODUCTO
                CONSOLIDACION DIRECTA 
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

  FECHA CREACION: 08-JUNIO-2015 javier cadena
  FECHA CREACION: 08-JUNIO-2015 javier cadena
  AUTOR : javier cadena 
  CORRECCION:     
*/



DECLARE @SUCCESS INTEGER,  @FAILURE INTEGER
DECLARE @Count           INTEGER
DECLARE @ServIdentifier  udtStringIdentifier

DECLARE @lintDAT_Container         udtIdentifier ,@lintYV_ContainerUniv    udtIdentifier
DECLARE @lintDAT_CustomerId        udtIdentifier ,@lintYV_CustomerId       udtIdentifier
DECLARE @lintDAT_CustomerTypeId    udtIdentifier ,@lintYV_CustomerTypeId   udtIdentifier
DECLARE @lintDAT_ProductId         udtIdentifier ,@lintYV_ProductId        udtIdentifier
DECLARE @lintDAT_ProductPackingId  udtIdentifier ,@lintYV_ProductPackingId udtIdentifier
DECLARE @lint_SOId                 udtIdentifier ,@lint_SOItemId           udtIdentifier
DECLARE @CustType                  udtIdentifier ,@CustId                  udtIdentifier
DECLARE @lint_product              udtIdentifier ,@lint_packingId          udtIdentifier
DECLARE @lint_contproductitem      udtIdentifier, @lintDAT_ProdQty         udtIdentifier 
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
DECLARE @lstr_ProductName          varchar(100)
DECLARE @lstr_ProductDescription   udtShortString

--- actualizar el peso,en la desconsolidacion , si es negativa o menor que cero, eliminar renglon, crear dos variablaes decimales 
 --- una tarja y otra para contarinerproduct
 
--RETURN  0 --@SUCCESS

  BEGIN 

 
		  SELECT @SUCCESS = 0
		  SELECT @FAILURE = 1
		  SELECT @lint_CFSActive = 0 
		  
		  SELECT @lint_addingPlus = 0 
		  SELECT @lstr_SOItemStatus = '' 
		  
		  --Checa si las Transacciones estan Encadenadas  
		  IF @@TRANCHAINED=1   
		     --Si estan Encadenadas Aborta el SP       
		     RETURN @FAILURE 
		    
		  --Evitar Dirty Reads  
		  SET TRANSACTION ISOLATION LEVEL 1
		  		
		  SELECT @ServIdentifier = RTRIM(strServiceIdentifier)  
		  FROM   tblclsService
		  WHERE  intServiceId = @intServiceId
		  
		
		  IF @@RowCount=0
		  BEGIN
		    RAISERROR 99999 'El Servicio no Existe'
		    SELECT @intErrorCode=4   --Error 4: El Servicio no Existe
		    RETURN @FAILURE
		  END 
       
		  --- saber si esta habilitada la configuracion para que CFS , afecte el inventario 
		  SELECT @lint_CFSActive =  ISNULL(tblclsSystemConfig.intSystemConfigCFSActive ,0)
		  FROM tblclsSystemConfig
		  WHERE intSystemConfigId =1
		  
          --  si no esta activada la configuracion de cfs, marcar error
          IF @lint_CFSActive  =0
          BEGIN
               --->>> MODIFICACION TEMPORAL JCADENA -10-10-2015 , de actualizar estatus 
                  --- si el servicio es consolidacion normal o directa
                   IF (@ServIdentifier = 'DESC' or  @ServIdentifier = 'DESCD')
                      BEGIN 
                             BEGIN TRANSACTION 					                     
								UPDATE tblclsContainerInventory
								SET tblclsContainerInventory.intContRecepRequiredById = NULL,
								   tblclsContainerInventory.intContRecepRequiredTypeId = NULL,
								   tblclsContainerInventory.intCustomerId = NULL
								WHERE tblclsContainerInventory.intContainerUniversalId =   @intUnivId
								 
						     IF @@Error = 0  
							       BEGIN  
							         COMMIT TRANSACTION   
							       END  	
							 ELSE --si hubo error  
						       BEGIN  
							         ROLLBACK TRANSACTION 
							         RETURN @FAILURE  
							   END     
					  END 
					  
                  --- si es desconoslidacion normal o directa      
                   IF (@ServIdentifier = 'CONS' or  @ServIdentifier = 'CONSD')
                     BEGIN
                     
                        BEGIN TRANSACTION 					                     
		          
				          UPDATE tblclsContainerInventory
						   SET tblclsContainerInventory.intContRecepRequiredById = tblclsServiceOrder.intServiceOrderRequiredById , 
							   tblclsContainerInventory.intContRecepRequiredTypeId = tblclsServiceOrder.intServiceOrderRequiredTypeId,
							   tblclsContainerInventory.intCustomerId = tblclsServiceOrder.intServiceOrderInvoiceToId
								
						  FROM  tblclsContainerInventory
								 INNER JOIN tblclsServiceOrderItem on tblclsContainerInventory.intContainerUniversalId = tblclsServiceOrderItem.intContainerUniversalId
								 INNER JOIN tblclsServiceOrder ON tblclsServiceOrder.intServiceOrderId = tblclsServiceOrderItem.intServiceOrderId
		
						   WHERE tblclsContainerInventory.intContainerUniversalId =   @intUnivId
						   AND tblclsServiceOrder.intServiceOrderId = @intSOrderId
						   
										 
						IF @@Error = 0  
						    BEGIN  
						         COMMIT TRANSACTION   
						     END  	
						ELSE --si hubo error  
						    BEGIN  
							    ROLLBACK TRANSACTION 
						        RETURN @FAILURE  
						  END        
                     END 
 
               ---<<<< MODIFICACION TEMPORAL JCADENA -10-10-2015 , de actualizar estatus 
             RETURN  999
          END 
            
            
           --- obtener el item , so , por la tarja, y aprovechando el producto y embalaje 
           SELECT @lint_SOItemId   = tblclsYardVerifTicketItem.intServiceOrderItemId, 
           		  @lint_SOId = tblclsYardVerifTicketItem.intServiceOrderId,
           		  @lintYV_ProductId = tblclsYardVerifTicketItem.intProductId  , 
           		  @lintYV_ProductPackingId = tblclsYardVerifTicketItem.intProductPackingId ,
           		  @ldec_YVProductdWeight = tblclsYardVerifTicketItem.decYVerifTItemProdGrossWeight,
           		  @lintYV_ProdQty  = tblclsYardVerifTicketItem.intYVerifTItemProdPackingQty
           		  
           FROM tblclsYardVerifTicketItem
           WHERE tblclsYardVerifTicketItem.intYardVerifTicketId = @intYardVerificationId
           AND tblclsYardVerifTicketItem.intYardVTItemId = @intYardVTItemId
  
           ------ obtener el numero de universal del contenedor 
           ---- tambien su estatus 
           SELECT @lintYV_ContainerUniv = tblclsServiceOrderItem.intContainerUniversalId
                 ,@lstr_SOItemStatus    = tblclsServiceOrderStatus.strSOStatusIdentifier
           FROM tblclsServiceOrderItem
                INNER JOIN tblclsServiceOrderStatus ON tblclsServiceOrderStatus.intSOStatusId = tblclsServiceOrderItem.intSOStatusId
           WHERE tblclsServiceOrderItem.intServiceOrderId     = @lint_SOId
           AND   tblclsServiceOrderItem.intServiceOrderItemId = @lint_SOItemId 

		   SELECT @ldec_InvWeight = decContainerInventoryWeight		          
		   FROM tblclsContainerInventory
		   WHERE intContainerUniversalId = @lintYV_ContainerUniv
		   
		   SELECT @lstr_ProductDescription = tblclsProduct.strProductDescription
		   FROM tblclsProduct
		   WHERE tblclsProduct.intProductId = @lintYV_ProductId 
		   
		   IF @lstr_SOItemStatus = 'TER' OR  @lstr_SOItemStatus = 'CAN'
		        SET @lint_addingPlus =0
		   ELSE
		       SET  @lint_addingPlus = 1 
      
	IF (@ServIdentifier = 'DESC' or  @ServIdentifier = 'DESCD')
    BEGIN
      PRINT 'desconsolidacion '     
      --DESCONSOLIDACION NORMAL  / DESCONSOLIDACION DIRECTA  
        --  --- contar el numero de items totales completados o terminados en la solicitud , si son los totales terminar , si no restar 
         ------ items completados 
          SELECT @lint_SOItemsCounter =   COUNT(  tblclsServiceOrderItem.intContainerUniversalId )
          FROM tblclsServiceOrderItem
           INNER JOIN tblclsServiceOrderStatus ON  tblclsServiceOrderItem.intSOStatusId = tblclsServiceOrderStatus.intSOStatusId
          WHERE  tblclsServiceOrderItem.intServiceOrderId =     @intSOrderId 
         -- AND    tblclsServiceOrderItem.intServiceOrderItemId   = @lint_SOItemId 
          AND    tblclsServiceOrderItem.intContainerUniversalId = @intUnivId
          AND   tblclsServiceOrderStatus.strSOStatusIdentifier = 'TER'
         
         -------- items totales para ese contenedor 
          SELECT  @lint_SOTotalITems =  COUNT(  tblclsServiceOrderItem.intContainerUniversalId )
          FROM tblclsServiceOrderItem
            INNER JOIN tblclsServiceOrderStatus ON  tblclsServiceOrderItem.intSOStatusId = tblclsServiceOrderStatus.intSOStatusId
          WHERE  tblclsServiceOrderItem.intServiceOrderId =     @intSOrderId 
          --AND    tblclsServiceOrderItem.intServiceOrderItemId   = @lint_SOItemId 
          AND    tblclsServiceOrderItem.intContainerUniversalId = @intUnivId
          AND    tblclsServiceOrderStatus.strSOStatusIdentifier <> 'CAN'
         
               
          --- obtener el item , so , por la tarja, y aprovechando el producto y embalaje 
           SELECT @lint_SOItemId   = tblclsYardVerifTicketItem.intServiceOrderItemId, 
           		  @lint_SOId = tblclsYardVerifTicketItem.intServiceOrderId,
           		  @lintYV_ProductId = tblclsYardVerifTicketItem.intProductId  , 
           		  @lintYV_ProductPackingId = tblclsYardVerifTicketItem.intProductPackingId ,
           		  @ldec_YVProductdWeight = tblclsYardVerifTicketItem.decYVerifTItemProdGrossWeight,
           		  @lintYV_ProdQty  = tblclsYardVerifTicketItem.intYVerifTItemProdPackingQty 
           		  
           FROM tblclsYardVerifTicketItem
           WHERE tblclsYardVerifTicketItem.intYardVerifTicketId = @intYardVerificationId
           AND tblclsYardVerifTicketItem.intYardVTItemId = @intYardVTItemId
             
      --- obtener el cliente, se acordo con luis que fuera de la solicitud 
       SELECT @CustType  = intServiceOrderInvoiceToTypeId,
              @CustId    = intServiceOrderInvoiceToId
       FROM tblclsServiceOrder
       WHERE tblclsServiceOrder.intServiceOrderId =   @lint_SOId          

 
      --  SET @lint_Sumar = @lint_SOItemsCounter +1 
      ---- sumarle el item actual, solo si tiene item pendiente por terminar 
          SET @lint_Sumar = @lint_SOItemsCounter + @lint_addingPlus
         ---- revisar los contadores de la solicitud , +1 por el actual 
          --IF @lint_SOItemsCounter  >= @lint_SOTotalITems     

          IF @lint_Sumar  >= @lint_SOTotalITems          
            BEGIN 
                  --- entrara caundo sea el ultimo ?
                   SET @ldec_NewWeight = 0   
                                
            END 
          ELSE 
            BEGIN
              
                 -- ver si el peso que se esta desconsolidando es menor que el peso del inventario
                 IF @ldec_YVProductdWeight < @ldec_InvWeight 
                  BEGIN 
                    SET @ldec_NewWeight =  @ldec_InvWeight - @ldec_YVProductdWeight                 
                  END
                  ELSE    
                    SET @ldec_NewWeight = 0
            END 
            
        ----------------------    
             
       --- obtener el embalaje y producto de la tarja 
     
       --- se consultara la container product, solo si el peso nuevo es mayor a 0 
        IF ( @ldec_NewWeight >0 )
        
         BEGIN 
           
           --buscar por cliente ,tipo embalaje 
		       SELECT @lint_contproductitem =  ISNULL(MAX(tblclsContainerProduct.intItemId),0)
		       FROM  tblclsContainerProduct
		       WHERE tblclsContainerProduct.intContainerUniversalId = @lintYV_ContainerUniv
		       AND   tblclsContainerProduct.intCustomerId = @CustId
		       AND   tblclsContainerProduct.intCustomerTypeId = @CustType
		       AND   tblclsContainerProduct.intProductId = @lintYV_ProductId
		       AND   tblclsContainerProduct.intProductPackingId = @lintYV_ProductPackingId
		     

		       --- VER SI EXISTE , SI EXSITE , SUMAS 
		IF ( @@ROWCOUNT=1)
		   BEGIN
		            print 'se encontro producto'
		            
		            SELECT  @ldec_ContainerProdWeight =  tblclsContainerProduct.decContInvProdWeight, 
	                        @lintDAT_ProdQty          =  tblclsContainerProduct.intContInvProdQuantity
	                FROM tblclsContainerProduct
	                WHERE tblclsContainerProduct.intContainerUniversalId = @intUnivId
	                AND   tblclsContainerProduct.intItemId = @lint_contproductitem
	                AND   tblclsContainerProduct.intProductId = @lintYV_ProductId
				
				    --comparar cantidad
				     IF @lintDAT_ProdQty > @lintYV_ProdQty  
				        SET @lint_NewProdQty     = @lintDAT_ProdQty - @lintYV_ProdQty  				       
				    ELSE
				       SET @lint_NewProdQty =0 
				       
				    IF @lint_NewProdQty =0 
				       BEGIN
				         SET @ldec_NewProdWeight  = 0 
				         SET @lint_NewProdQty =0 
				        END
				    ELSE --- hacer la diferencia del peso
				       BEGIN
				          IF @ldec_ContainerProdWeight > @ldec_YVProductdWeight
				             SET @ldec_NewProdWeight  = @ldec_ContainerProdWeight - @ldec_YVProductdWeight
				          ELSE
				           BEGIN -- poner en 0s los 2
				             SET @ldec_NewProdWeight  = 0
				             SET @lint_NewProdQty =0 
				           END
				       END 
				       
		          END  --- rowcount
		       ELSE  -- rowcount SI NO EXISTE INSERTAR NUEVO          
		          BEGIN 
		           print ' no se encontro producto'
		           SET @lint_contproductitem =0 
		           SET @ldec_NewProdWeight  = 0 
				   SET @lint_NewProdQty     = 0
				    
		          END 
		   END 
		ELSE  ----      IF ( @ldec_NewWeight >0 )
		   BEGIN 
		     SET @ldec_NewProdWeight  =0 ---  -1
		     SET @lint_NewProdQty     =0---   -1
		    
		  END 
        -------------------    
        -- ELIMINA DE CONTAINER PRODUCT                 
     
         
     BEGIN TRANSACTION 
      -- solo actualizar si el peso si es desconoslidacion , o si el peso final es 0 , aunque sea  la desconsolidacion parcial, que se actualize 
	IF (@ServIdentifier = 'DESC' OR @ldec_NewWeight =0) 
	  BEGIN       
	  
	    IF (@ldec_NewWeight > 0 )
	    BEGIN
	     --actualiza el peso
	       UPDATE tblclsContainerInventory
	        SET tblclsContainerInventory.decContainerInventoryWeight = @ldec_NewWeight
	           ,tblclsContainerInventory.strContainerInvComments =  tblclsContainerInventory.strContainerInvComments+ @lstr_Coms
	       WHERE tblclsContainerInventory.intContainerUniversalId = @intUnivId
	     END 
       ELSE -- IF (@ldec_NewWeight > 0 )
         BEGIN 
           UPDATE tblclsContainerInventory
	        SET tblclsContainerInventory.decContainerInventoryWeight = 0
	           ,tblclsContainerInventory.blnContainerIsFull= 0 
	       WHERE tblclsContainerInventory.intContainerUniversalId = @intUnivId
           
         END   --ELSE IF (@ldec_NewWeight > 0 )
	        
	       IF @@Error <> 0  
	         BEGIN  
		             ROLLBACK TRANSACTION 
		             RETURN @FAILURE  
		     END     
	  END		     
	     
       --- ahora se modificara la informacion de la containerproduct 

        IF @ldec_NewWeight > 0 
           BEGIN 
         ------ si  el peso del contenedor en inventario es mayor a 0
             IF @lint_contproductitem > 0
              --- si existe el item del select, 
               BEGIN
                 --- si tiene peso y cantidad mayores a 0 
                   IF @ldec_NewProdWeight > 0 
                   
                   -- actualizar a nuevo peso
                      UPDATE tblclsContainerProduct
                      SET  tblclsContainerProduct.decContInvProdWeight =   @ldec_NewProdWeight
                         , tblclsContainerProduct.intContInvProdQuantity = @lint_NewProdQty
                      WHERE tblclsContainerProduct.intContainerUniversalId = @intUnivId
                      AND tblclsContainerProduct.intItemId = @lint_contproductitem
                       AND   tblclsContainerProduct.intProductId = @lintYV_ProductId
                   --- es mejor actualizar ?? -->> no es mas chido el mio:P
                   --- o es mejor usar el sp 
                           --EXECUTE @SPStat = spUpdateContProdDescQty @intUnivId,@ProdId,
                             --                    @Qty,@strUser,@CustId,
                               --                  @CustType,@ProdPackId ,@Weight

              END
             ELSE   --- IF @ldec_NewProdWeight > 0 
               BEGIN 
                 --- si no borrar el producto de ese item    
                      DELETE  tblclsContainerProduct
                      WHERE tblclsContainerProduct.intContainerUniversalId = @intUnivId
                      AND tblclsContainerProduct.intItemId = @lint_contproductitem
                      AND tblclsContainerProduct.intProductId = @lintYV_ProductId
               
               END
               		 ---- si no  tiene items , no se modifica ningun item 
               		             
           END --- IF @ldec_InvWeight > 0 
         ELSE 
            BEGIN 
		        --- si no tiene peso en inventario 
        	    --- borrar todos los productos    
        	    ---- solo si ya compltaron todos los items
        	     IF @lint_Sumar  >= @lint_SOTotalITems           	      
        	        DELETE  tblclsContainerProduct
                    WHERE tblclsContainerProduct.intContainerUniversalId = @intUnivId
                   
            END  -- FIN DEL ELSE @ldec_InvWeight > 0 
     
       
       IF @@Error = 0  
	           BEGIN  
	             COMMIT TRANSACTION   
	           END  
	    ELSE --si hubo error  
	           BEGIN  
	             ROLLBACK TRANSACTION 
	             RETURN @FAILURE  
	           END     
  

   END --	IF (@ServIdentifier = 'DESC' or  @ServIdentifier = 'DESCD')
   

   IF (@ServIdentifier = 'CONS' OR 	 @ServIdentifier = 'CONSD')
   BEGIN 
   
       
        --- insertar el producto como spinsertcontconsolproduct usar el codigo 
           --- proceso de insercioon de un registo  a la tabla de historyproduct, por cada renglon que se ejecute
        
        --- obtener informaccion pendiente 
              --- obtener el cliente, se acordo con luis que fuera de la solicitud 
		       SELECT @CustType  = intServiceOrderInvoiceToTypeId,
		              @CustId    = intServiceOrderInvoiceToId
		       FROM tblclsServiceOrder
		       WHERE tblclsServiceOrder.intServiceOrderId =   @lint_SOId                
		       
		       --- obtener el peso en el inventario 
		            --actualiza el peso
		           SELECT @ldec_NewWeight =  tblclsContainerInventory.decContainerInventoryWeight
		           FROM tblclsContainerInventory
		           WHERE tblclsContainerInventory.intContainerUniversalId = @intUnivId

		       -- buscar si el conteendor tiene el mismo producto y mismo empaque , y obtene su cantidad 
		        --- primero ver cuantos items hay con esa misma informacion 
		          SET @lint_contproductitem =  0
		          
		        --buscar por cliente ,tipo embalaje 		          
		       	   SELECT @lint_contproductitem =  ISNULL(MAX(tblclsContainerProduct.intItemId),0)
			       FROM  tblclsContainerProduct
			       WHERE tblclsContainerProduct.intContainerUniversalId = @lintYV_ContainerUniv
			       AND   tblclsContainerProduct.intCustomerId = @CustId
			       AND   tblclsContainerProduct.intCustomerTypeId = @CustType
			       AND   tblclsContainerProduct.intProductId = @lintYV_ProductId
			       AND   tblclsContainerProduct.intProductPackingId = @lintYV_ProductPackingId
			       
                   IF ( @@ROWCOUNT=1)
                    BEGIN -- obtener informacion                        
			            SELECT  @ldec_ContainerProdWeight =  tblclsContainerProduct.decContInvProdWeight, 
		                        @lintDAT_ProdQty          =  tblclsContainerProduct.intContInvProdQuantity
		                FROM tblclsContainerProduct
		                WHERE tblclsContainerProduct.intContainerUniversalId = @intUnivId
		                AND   tblclsContainerProduct.intItemId = @lint_contproductitem
		                AND   tblclsContainerProduct.intProductId = @lintYV_ProductId		
                    END
                   ELSE -- no hay items previos --- IF ( @@ROWCOUNT=1)
	                    SET @lint_contproductitem =0
	                    
	                --- validar que la informacion de cantidad y peso del producto e inventario sean positivas 
	                 -- valida peso inventario 
	                 IF ( @ldec_NewWeight < 0  ) 
	                    SET @ldec_NewWeight = 0 
	                 -- valida peso producto 
	                 IF (  @ldec_ContainerProdWeight < 0 ) 
	                    SET  @ldec_ContainerProdWeight  = 0 
	                 -- valida cantidad  producto  
	                 IF ( @lintDAT_ProdQty < 0 ) 
	                    SET @lintDAT_ProdQty  = 0
	                    
	                    
	                  ---------- 19-agosto--- incrementar el peso en todas las tarjas que se suman para le mismo item 
	                   --------<<<<<<
	                      SELECT @ldec_YVProductdWeight = SUM(tblclsYardVerifTicketItem.decYVerifTItemProdGrossWeight)
	                      FROM tblclsYardVerifTicketItem
	                      WHERE tblclsYardVerifTicketItem.intServiceOrderId = @intSOrderId
	                      AND   tblclsYardVerifTicketItem.intServiceOrderItemId = @intSOrderItemId
	                      
	                   ------- >>>>> 19 AGOSTO
	                  ------------------------    
	               ---
		--- aumentar el peso en el inventario        
          SET @ldec_NewWeight = @ldec_NewWeight + @ldec_YVProductdWeight
        
        --- si no se econtro items insertar el producto nuevo 
          IF ( @lint_contproductitem = 0  ) 
           BEGIN 
                --- se insertara esa transaccion  
		        EXECUTE @StatErrSP = spGetContProdItemId @lintYV_ProductId, @intUnivId, @lint_contproductitem OUTPUT
		        
		        --- obtener la descripccion del tipo de producto 
		          --SELECT @lstr_ProductDescription = tblclsProduct.strProductIdentifier
		          SELECT @lstr_ProductName  = tblclsProduct.strProductName
		          FROM tblclsProduct
		          WHERE tblclsProduct.intProductId =  @lintYV_ProductId
		          
		          IF LEN(@lstr_ProductName ) > 15
		           BEGIN
		              SET  @lstr_ProductDescription = SUBSTRING( @lstr_ProductName, 1, 10)
		           END 
		          ELSE
		            BEGIN  
		              SET  @lstr_ProductDescription =  @lstr_ProductName
		            END 
		          
		          
		        --IF ( @lintYV_ProductId <1  OR LEN(@lstr_ProductDescription) <2 )
		        IF ( LEN(@lstr_ProductDescription) <2 )
		         BEGIN 
		          SET @lstr_ProductDescription = 'SIN PRODUCT0-' + convert(varchar(10),@lintYV_ProductId)
		         END 
		          
		        --- se agrega el producto 
		        SET @lstr_ProductDescription ='Se Agrego:'+ @lstr_ProductDescription
		       -- print @lstr_ProductDescription
		        --***********************************************************
		        BEGIN TRANSACTION ContProduct
		
		
		        --Inserta el Producto en la Tabla de Container Product
		        INSERT INTO tblclsContainerProduct (
		                intContainerUniversalId,
		                intProductId,
		                intProductPackingId,
		                intCustomerId,
		                intCustomerTypeId,
		                intItemId,
		                intGeneralCargoUniversalId,
		                intGCInventoryItemId,
		                intContInvProdQuantity,
		                strContInvProdMarks,
		                strContInvProdNumbers,
		                decContInvProdWeight,
		                intDocumentId,
		                strContInvProdComments,
		                dtmContInvProdCreationStamp,
		                strContInvProdCreatedBy,
		                dtmContInvProdLastModified,
		                strContInvProdLastModifiedBy
		        )
		        VALUES( @intUnivId, --@UnivId, 
		                @lintYV_ProductId,--@ProductId,
		                @lintYV_ProductPackingId,--@ProdPackingId,
		                @CustId,--@CustomerId,
		                @CustType,--@CustType,
		                @lint_contproductitem,--@ProdItemId, 
		                0,--,@GCUnivId,
		                0,--,@GCUnivItemId,
		                @lintYV_ProdQty,--@Qty,
		                '',--@Marks,
		                '',--@Numbers,
		                @ldec_YVProductdWeight,--@Weight,
		                0,
		                @lstr_ProductDescription ,
		                GETDATE(),@strUser ,GETDATE(),@strUser )
		        
		        SELECT @StatErrSP = @@error
		        
		        IF @StatErrSP <> 0  --Validacion al Insertar el producto
		          BEGIN
		              print 'Error al actualizar el Inv. de contenedor'
		              ROLLBACK TRANSACTION ContProduct
		              RETURN (1) 
		          END
		        ELSE 
		            COMMIT TRANSACTION ContProduct      
		        
		        --Actualiza el historico del producto
		        EXECUTE @ReturnCode = spUpdateHistoryProduct @intUnivId , @lintYV_ProductId, 0,@lstr_ProductDescription, @strUser
		        
		        --Si hubo algun Error devuelve 1 y sale del SP
		        IF @ReturnCode != 0  
		          BEGIN 
		               RETURN(1)
		          END		                
		     ----- fin de proceso de insercion del registro  en la container product---------------             
           END
         ELSE -- IF ( @lint_contproductitem = 0  ) 
           BEGIN --- se suma al producto existente 
           
            SET @ldec_NewProdWeight = @ldec_ContainerProdWeight + @ldec_YVProductdWeight
            SET @lint_NewProdQty    = @lintDAT_ProdQty + @lintYV_ProdQty
            
            --- actualizar el peso y cantidad de un mismo producto 
            BEGIN TRANSACTION 
            	
	             UPDATE tblclsContainerProduct
	             SET tblclsContainerProduct.intContInvProdQuantity = @lint_NewProdQty
	               , tblclsContainerProduct.decContInvProdWeight = @ldec_NewProdWeight
	             WHERE tblclsContainerProduct.intContainerUniversalId = @lintYV_ContainerUniv
			       AND   tblclsContainerProduct.intCustomerId = @CustId
			       AND   tblclsContainerProduct.intCustomerTypeId = @CustType
			       AND   tblclsContainerProduct.intProductId = @lintYV_ProductId
			       AND   tblclsContainerProduct.intProductPackingId = @lintYV_ProductPackingId
			       AND   tblclsContainerProduct.intItemId = @lint_contproductitem
                         
	             SELECT @StatErrSP = @@error
			        
			     IF @StatErrSP <> 0  --Validacion al Insertar el producto
			        BEGIN
			              print 'Error al actualizar el Inv. de contenedor'
			              ROLLBACK TRANSACTION ContProduct
			              RETURN (1) 
			        END
			     ELSE 
			        COMMIT TRANSACTION ContProduct      		        
		       
           END -- ELSE -- IF ( @lint_contproductitem = 0  )
            
         -- se agrega el peso el inventario del contenedor 
        
         -- actaualizar el peso en el inventario
            --- solo es sumar 
             IF ( @ServIdentifier = 'CONS') 
             BEGIN 
		            BEGIN TRANSACTION 
		            
				            UPDATE tblclsContainerInventory
				            SET tblclsContainerInventory.decContainerInventoryWeight = @ldec_NewWeight
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
		    END
   END 
   
 
  /* IF (@ServIdentifier = 'CONSD' )
   BEGIN 
     --- acutalizar el peso  en inventario
     	UPDATE tblclsContainerInventory
		SET tblclsContainerInventory.decContainerInventoryWeight = tblclsContainerInventory.decContainerInventoryWeight + @ldec_YVProductdWeight 
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
    END --  IF (@ServIdentifier = 'CONSD' )
*/
  END









