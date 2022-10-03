/*

--- sp que finaliza un servicio, con un item en especifico de tarja , 
  -- libera el contenedor 
  -- actualiza el estatus del contenedor 
  --- actualizar peso del contenedor 
  --- inserta/ elimina peso del contenedor 
  --- agrega imo en caso de aplicarlo , pero solo si la tarja solicitda lo tiene 

DROP PROCEDURE spFinalizeItemServiceTicketHH

*/

CREATE PROCEDURE spFinalizeItemServiceTicketHH  @intServiceOrder udtIdentifier,
												@intServiceOrderItem udtIdentifier,
												@intYVTicketItem  udtIdentifier,
												@blnFull          udtIdentifier,
												@intPhyscalStatus udtIdentifier,
												@istrUserName     udtStringIdentifier
as

	DECLARE @strError udtStringIdentifier
	DECLARE @intIMOCodeId udtIdentifier
	DECLARE @StatErrSP udtIdentifier
	DECLARE @intUniversalId udtIdentifier
    DECLARE @int_ticket udtIdentifier
    DECLARE @str_service udtStringIdentifier
    DECLARE @int_YardServiceProgramId udtIdentifier 
    DECLARE @int_YardServicePrgmItem  udtIdentifier
    DECLARE @int_TicketQuantity  udtIdentifier
    DECLARE @int_TicketQuantitysum  udtIdentifier
    DECLARE @int_TicketDecimal   udtDecimal
    DECLARE @dec_TicketDecimalsum   udtDecimal
    DECLARE @lbit_PendingContainer bit
    DECLARE @aint_ErrorCode int
    DECLARE @ReturnedYardPosId varchar(32)
    DECLARE @lint_ServiceId udtIdentifier
    DECLARE @lstr_TransacType udtStringIdentifier
    DECLARE @lstr_HistComments VARCHAR(150)
    DECLARE @lint_VesselVoyageId udtIdentifier
    DECLARE @lstr_IMOCodeiNFO udtStringIdentifier
    DECLARE @lstr_IMOComments udtStringIdentifier
    DECLARE @lstr_Container   udtStringIdentifier
    DECLARE @lint_FiscalMovSO udtIdentifier
    DECLARE @lint_TicketProduct udtIdentifier
    DECLARE @lint_TicketPacking udtIdentifier
    DECLARE @lint_TicketCustomerType udtIdentifier
    DECLARE @lint_TicketCustomer udtIdentifier
    DECLARE @lstr_TicketsMarks udtStringIdentifier
    DECLARE @lstr_TicketNumbers udtStringIdentifier
    DECLARE @lstr_DischargePortInv udtStringIdentifier
    DECLARE @lstr_FinalPortInv udtStringIdentifier
    DECLARE @lstr_OriginPortInv udtStringIdentifier
    DECLARE @lint_GCReturnedUniversal udtIdentifier
    DECLARE @lint_TicketRequiredBy  udtIdentifier
    DECLARE @lint_TicketRequiredByType udtIdentifier
    DECLARE @lint_MaxGCIdMasterRet udtIdentifier
    DECLARE @lint_MaxGCUniversalIdItemRet udtIdentifier
    DECLARE @lint_FlagHasIMO udtIdentifier
    DECLARE @ldtm_CurrentDate  Datetime     
    DECLARE @lint_FlagWasProcessed udtIdentifier
    DECLARE @lstr_PhyscalStatusId udtStringIdentifier


    
    --jcadena 20160217
    DECLARE @dtmMinDate DateTime
    DECLARE @dtMaxmDate DateTime
    DECLARE @dtmInDate  DateTime
    DECLARE @dtmOutDate DateTime
    DECLARE @strcoms udtStringIdentifier
    DECLARE @retval udtStringIdentifier
    DECLARE @intVisitId  udtIdentifier
    DECLARE @strTodayMonthY VARCHAR(18)
    DECLARE @SHour  VARCHAR(5)
    DECLARE @SMinute  VARCHAR(5)
    DECLARE @SSecond  VARCHAR(5)
    DECLARE @SealTem  varchar(100), @s_fetch   varchar(100) , @Seal varchar(80)
    DECLARE @tempStringA varchar(100) , @tempStringB varchar(100)


    
      --- solo ver si ya se termino el servicio 
      IF EXISTS (
                  SELECT tblclsServiceOrderItem.intServiceOrderItemId
                  FROM tblclsServiceOrderItem
                   INNER JOIN tblclsServiceOrderStatus ON tblclsServiceOrderStatus.intSOStatusId =tblclsServiceOrderItem.intSOStatusId
                  WHERE tblclsServiceOrderItem.intServiceOrderId = @intServiceOrder
                  AND tblclsServiceOrderItem.intServiceOrderItemId = @intServiceOrderItem
                  AND tblclsServiceOrderStatus.strSOStatusIdentifier IN ('TER','CAN')
                 )
                 BEGIN 
                  PRINT 'El estado de la maniobra esta terminada'
                  RETURN 1
                 END 
      
     --- obtener la fecha actual 
          SET @ldtm_CurrentDate = GETDATE()
          
     ---- obtener diaMesAnio
          SET @strTodayMonthY = CONVERT(VARCHAR(10),GETDATE(),112)
         
     --- jcadena -- 19-01-2015 , obtener el identificador del estatus fisico
         SELECT  @lstr_PhyscalStatusId = tblclsContainerPhysicalStatus.strContPhyStatIdentifier
         FROM tblclsContainerPhysicalStatus
         WHERE tblclsContainerPhysicalStatus.intContPhyStatId = @intPhyscalStatus
        

                
	-- obtener el universal del item de la solicitud de servicio 
		  SELECT @intUniversalId  = ISNULL(tblclsServiceOrderItem.intContainerUniversalId,0),
		          @lstr_Container = ISNULL(tblclsServiceOrderItem.strContainerId,'') 
		          
		  FROM  tblclsServiceOrderItem
		  WHERE tblclsServiceOrderItem.intServiceOrderId = @intServiceOrder
		  AND tblclsServiceOrderItem.intServiceOrderItemId = @intServiceOrderItem		

		  
	  -- obtener el servicio y otros datos 
	     SELECT  @str_service =  tblclsService.strServiceIdentifier,
	             @lint_ServiceId = tblclsServiceOrder.intServiceId,
	             @lint_VesselVoyageId = tblclsServiceOrder.intServiceOrderVesselVoyageId,
	             @lint_FiscalMovSO = tblclsServiceOrder.intFiscalMovementId	             
	     
	     FROM tblclsServiceOrder 
	      INNER JOIN tblclsService  ON tblclsService.intServiceId = tblclsServiceOrder.intServiceId
	     WHERE tblclsServiceOrder.intServiceOrderId = @intServiceOrder
	  
	  
	  -- obtener el programa de maniobras y el item, que esten activos 
         SELECT  @int_YardServicePrgmItem =  ISNULL(MAX(tblclsYardServiceProgramItem.intYardSPItemId),0)  
         FROM tblclsYardServiceProgramItem         
           INNER JOIN tblclsServiceOrderItem ON tblclsYardServiceProgramItem.intServiceOrderId = tblclsServiceOrderItem.intServiceOrderId
                                            AND tblclsYardServiceProgramItem.intServiceOrderItemId = tblclsServiceOrderItem.intServiceOrderItemId
                                            
           INNER JOIN tblclsServiceOrderStatus ON tblclsYardServiceProgramItem.intSOStatusId = tblclsServiceOrderStatus.intSOStatusId
         WHERE tblclsServiceOrderItem.intServiceOrderId = @intServiceOrder
         AND   tblclsServiceOrderItem.intServiceOrderItemId = @intServiceOrderItem
         AND tblclsServiceOrderStatus.strSOStatusIdentifier NOT IN ( 'TER','CAN'  )
         

         SELECT  @int_YardServiceProgramId = ISNULL(tblclsYardServiceProgramItem.intYardServProgId,0)
         FROM tblclsYardServiceProgramItem
         WHERE tblclsYardServiceProgramItem.intYardSPItemId = @int_YardServicePrgmItem

       --- obtener el peso  y cantidad de la tarja 
         SELECT   @int_TicketQuantity =  tblclsYardVerifTicketItem.intYVerifTItemProdPackingQty , 
                  @int_TicketDecimal  = tblclsYardVerifTicketItem.decYVerifTItemProdGrossWeight,
                  @lint_TicketProduct = tblclsYardVerifTicketItem.intProductId , 
                  @lint_TicketPacking = tblclsYardVerifTicketItem.intProductPackingId,
                  @int_ticket = ISNULL(tblclsYardVerifTicketItem.intYardVerifTicketId,0),
                  @lstr_TicketsMarks = tblclsYardVerifTicketItem.strYVerifTItemMarks,
                  @lstr_TicketNumbers = tblclsYardVerifTicketItem.strYVerifTItemNumbers
                  
         FROM  tblclsYardVerifTicketItem
         WHERE tblclsYardVerifTicketItem.intYardVTItemId = @intYVTicketItem

         
      --- informacion del master de la tarja 
         SELECT @lint_TicketCustomerType  = tblclsYardVerificationTicket.intYVerifTicketInvoiceToTypeId , 
                @lint_TicketCustomer = tblclsYardVerificationTicket.intYVerifTicketInvoiceToId , 
                @lint_TicketRequiredBy = tblclsYardVerificationTicket.intYVerifTicketRequiredById ,
                @lint_TicketRequiredByType = tblclsYardVerificationTicket.intYVerifTicketReqByTypeId
                
         FROM tblclsYardVerificationTicket
         WHERE tblclsYardVerificationTicket.intYardVerifTicketId = @int_ticket
         
         
       -- peso y cantidad sumadas                            
         SELECT  @int_TicketQuantitysum = ISNULL(SUM(tblclsYardVerifTicketItem.intYVerifTItemProdPackingQty),0),
                 @dec_TicketDecimalsum  = ISNULL(SUM(tblclsYardVerifTicketItem.decYVerifTItemProdGrossWeight),0)
                          
         FROM  tblclsYardVerifTicketItem
         WHERE tblclsYardVerifTicketItem.intServiceOrderId = @intServiceOrder
         AND   tblclsYardVerifTicketItem.intServiceOrderItemId  = @intServiceOrderItem         
         

	 -- saber si hay maniobras pendientes por terminar y guardarlos en bandera 
	     SET @lbit_PendingContainer =0
         EXECUTE spContainerManueverPendingNoSO  @aint_UniversalId=@intUniversalId, @aint_SOrderId=@intServiceOrder, @aint_SOrderItem=@intServiceOrderItem, @abln_Pending=@lbit_PendingContainer output, @aint_ErrorCode=@aint_ErrorCode output

        SET @lint_FlagWasProcessed  = 0 
     
       print @str_service   
      
	 ---- implementar el case de servicios
	 
  -- para consolidacion 
	  IF @str_service = 'CONS'
	    BEGIN
	        
	         -- actualizar el vb , del contenedor, basandome al de la maniobra 
	             execute @StatErrSP = spUpdateVessVoyStuff  @UnivId=@intUniversalId, @SOrderId=@intServiceOrder, @SOrderItemId=@intServiceOrderItem, @User=@istrUserName
	             
	             IF @StatErrSP <> 0
	                BEGIN
	                      print 'Error al ejecutar el SP de Actualizar datos del buque-viaje'
	                      RETURN (1) 
	                END

               print ' se va a ctualizar lleno'
	           -- actualizar que sea lleno el contenedor 
                execute @StatErrSP = spUpdateContainerInventoryFull  @intContainerUniversalId=@intUniversalId, @intContainerIsFull=@blnFull
                
                IF @StatErrSP <> 0 
                   BEGIN
                		  print 'Error al marcar lleno el contenedor'
	                      RETURN (1) 
                   END 

            /* JCADENA 17 NOV 2015
             -- actualizacion del producto de contenedor 
                execute spUpdateProductsContCFS  @intUnivId=@intUniversalId, @intSOrderId=@intServiceOrder, @intServiceId=@lint_ServiceId, @intSOrderItemId=@intServiceOrderItem, @strUser=@istrUserName, @strTextFree='', @intYardVerificationId=@int_ticket, @intYardVTItemId=@intYVTicketItem, @intErrorCode=@StatErrSP output

				 IF @StatErrSP <> 0 
				    BEGIN
				       	  print 'Error al ejecutar el SP actualizar los productos del contenedor '
	                      RETURN (1) 
				    END -- IF @StatErrSP <> 0 
			 */	    
				    	    
			  print 'actualizacin de historico' 
               -- actualizar la solicitud de servicio y el historico 
                SET @lstr_TransacType='CCONS'
                SET @lstr_HistComments = 'EJEC. DE CONSOLIDACION('+@str_service+'), Servicio #' + convert(varchar(12),@lint_ServiceId)
                 
                execute @StatErrSP = spUpdateHistoryServiceOrder  @TransType=@lstr_TransacType, @UniversalId=@intUniversalId, @ServiceId=@lint_ServiceId, @ServiceOrderId=@intServiceOrder, @ServiceOrderItemId=@intServiceOrderItem, @Comments=@lstr_HistComments, @User=@istrUserName
                
                IF @StatErrSP <> 0 
                  BEGIN
                   		  print 'Error registrar el historico del contenedor '
	                      RETURN (1) 
                  END 
                  
              -- actualizar el estado fisico del contenedor 
               ---- jcadena 19-01-2016 , si  hay estatus fisico encontrado 
                   IF LEN( @lstr_PhyscalStatusId )> 2
                     BEGIN 
                       print 'se va a actualizar estatus fisico'
                        --execute @StatErrSP = spUpdateContainerStatus  @intUniversalId, 3, 'CONS', 'CCONS'-- 'CONLIBMAN'
                          execute @StatErrSP = spUpdateContainerStatus  @intUniversalId, 3, @lstr_PhyscalStatusId , 'CCONS'-- 'CONLIBMAN'
		        
		   				 IF @StatErrSP <> 0 
						    BEGIN
						       	  print 'Error en el cambio de estatus fisico del contenedor'
			                      RETURN (1) 
						    END -- IF @StatErrSP <> 0 			
			         END 
			    --- <<< jcadena 19-01-2016  			    				
			    
			  -- actualizar contenedores pendientes 
			    -- si hay bv @lint_VesselVoyageId, @lint_VesselVoyageId
                execute spRefreshPendingContainers  @intVesselVoyageId=@lint_VesselVoyageId, @strUser=@istrUserName
              
              --- JCADENA 19-01-2016 , se comenta que la asociacion del historico del imo, ya que se guarda en cada guardada de detalle
              /*  
              -- actualizar imos con historico 
              	  -- sigue saber si tiene imo la tarja final 
			       SELECT @intIMOCodeId =  ISNULL(tblclsYardVerifTicketItem.intIMOCodeId,0)
			       FROM tblclsYardVerifTicketItem			        
			       WHERE tblclsYardVerifTicketItem.intYardVTItemId = @intYVTicketItem	       
		       	 
		       	 --- inserta imos 
		         IF @intIMOCodeId > 0 
		          BEGIN 
		             execute spCMInsertIMOS  @UnivId=@intUniversalId , @IMO=@intIMOCodeId, @User=@istrUserName
		             
		             SELECT @lstr_IMOCodeiNFO = ISNULL(tblclsIMOCode.strIMOCodeIdentifier,'')
		             FROM tblclsIMOCode
		             WHERE tblclsIMOCode.intIMOCodeId = @intIMOCodeId
		             
		             
		             SET @lstr_IMOComments = ' IMO :' + @lstr_IMOCodeiNFO
		             execute @StatErrSP =  spUpdateHistoryIMOCode  @UniversalId=@intUniversalId, @IMOId=@intIMOCodeId, @Comments=@lstr_IMOComments, @User=@istrUserName
	
	   				 IF @StatErrSP <> 0 
				      BEGIN
				       	  print 'Error al actualizar el historico de IMOS '
	                      RETURN (1) 
				      END -- IF @StatErrSP <> 0 			
        
		          END --- inserta imos 
		        */
		          print 'ok1'
		          --- si fue procesado sin problemas 
		          SET @lint_FlagWasProcessed  = 1          
		          
      END ---IF @str_service = 'CONS'

--------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------

  ---- para consolidacion  DIRECTA 
	  IF @str_service = 'CONSD'
	    BEGIN
       	         -- ingresar el producto al inventario de carga genera l 
       	         
	             execute @StatErrSP = spUpdateVessVoyStuff  @UnivId=@intUniversalId, @SOrderId=@intServiceOrder, @SOrderItemId=@intServiceOrderItem, @User=@istrUserName
	             
	             IF @StatErrSP <> 0
	                BEGIN
	                      print 'Error al ejecutar el SP de Actualizar datos del buque-viaje'
	                      RETURN (1) 
	                END
	                
	             -- obtener informacion del contenedor 
	             
	              SELECT @lstr_DischargePortInv=  tblclsContainerInventory.strContainerInvDischargePortId, 
	                     @lstr_FinalPortInv = tblclsContainerInventory.strContainerInvFinalPortId, 
	                     @lstr_OriginPortInv = tblclsContainerInventory.strContainerInvPortOfOriginId
	              FROM tblclsContainerInventory
	              WHERE intContainerUniversalId = @intUniversalId  
	              

              	  -- sigue saber si tiene imo la tarja final 
			       SELECT @intIMOCodeId =  ISNULL(tblclsYardVerifTicketItem.intIMOCodeId,0)
			       FROM tblclsYardVerifTicketItem			        
			       WHERE tblclsYardVerifTicketItem.intYardVTItemId = @intYVTicketItem	       
		       	   
		       	   
               /*
				execute @StatErrSP = spGCStrippConsolidation  @ServiceTypeId= @lint_ServiceId, @GCUnivId=0, @ContUnivId=@intUniversalId,
    	                                          @ContainerId=@lstr_Container, @ServiceOrderId=@intServiceOrder, 
        	                                      @ServiceOrderItemId=@intServiceOrderItem, @FisMovId=@lint_FiscalMovSO, 
            	                                  @ProductId=@lint_TicketProduct, @ProductPackingId=@lint_TicketPacking , @GCTypeId=1,
                	                              @GCDamTypeId=NULL, @WarehouseId=NULL,@CustomerTypeId=@lint_TicketCustomerType,
                    	                          @CustomerId=@lint_TicketCustomer, @IsOutDoor=0,@Qty=@int_TicketQuantitysum,
                        	                      @Marks=@lstr_TicketsMarks, @Numbers=@lstr_TicketNumbers, @Weight=@dec_TicketDecimalsum,
                            	                  @Volume=0, @CommValue=0, @PositionId='',@VessVoyId=@lint_VesselVoyageId ,
                                	              @OriginPort=@lstr_OriginPortInv, @DischargePort=@lstr_DischargePortInv,
                                    	          @FinalPort=@lstr_FinalPortInv, @Comments='', @User=@istrUserName, 
                                        	      @ExecDate=@ldtm_CurrentDate, @GCInvItem=0, @IMOId=@intIMOCodeId, @RetGCUnivId=@lint_MaxGCIdMasterRet output,
                                            	  @ReqById=@lint_TicketRequiredBy, @ReqByTypeId=@lint_TicketRequiredByType



				IF @StatErrSP <> 0 
				  BEGIN 
				  	    print 'Error al ejecutar el SP de Consolidacion de Carga general'
			            RETURN @StatErrSP			 
				  END
				  
				 -- validar que se hayaa retornado el gc universal 
				 IF ISNULL(@lint_MaxGCIdMasterRet,0)  <1   
				  BEGIN
				      	print 'Error no se genero el universal '
			            RETURN @StatErrSP			 
				  END 
				  		       	   
			-------------------items---------------
				execute @StatErrSP =  spGCInInvItemsConsD  @ServiceType=@str_service, @GCUnivId=@lint_MaxGCIdMasterRet, @ContUnivId=@intUniversalId,
						   @ContainerId=@lstr_Container , @ServiceOrderId=@intServiceOrder, @ServiceOrderItemId=@intServiceOrderItem,
						   @FisMovId=@lint_FiscalMovSO, @WarehouseId=NULL, @CustomerTypeId=@lint_TicketCustomerType,
						   @CustomerId=@lint_TicketCustomer, @IsOutDoor=0, @Qty=@int_TicketQuantitysum , @Marks=@lstr_TicketsMarks,
						   @Numbers=@lstr_TicketNumbers, @Weight=@dec_TicketDecimalsum, @Volume=0, @CommValue=0, 
						   @PositionId='', @VessVoyId=@lint_VesselVoyageId, @OriginPort=@lstr_OriginPortInv, 
						   @DischargePort=@lstr_DischargePortInv, @FinalPort=@lstr_FinalPortInv, 
						   @HasIMO=lint_FlagHasIMO, @Comments='', @User=@istrUserName, @ExecDate=@ldtm_CurrentDate,
						   @ProductId=@lint_TicketProduct, @ProductPackingId=@lint_TicketPacking

				IF @StatErrSP <> 0 
				 BEGIN 
				  	print 'Error  al consolidar item de gc '
					RETURN @StatErrSP			 
				END 
				
				-- actualiar productos e inventario				
				execute @StatErrSP = spCompleteStrippStuffCMVisit  @intUnivId = @intUniversalId, @intSOrderId = @intServiceOrder,
																   @intServiceId = @lint_ServiceId, @intSOrderItemId = @intServiceOrderItem,
																    @strUser = @istrUserName , @intErrorCode=@StatErrSP output

                IF @StatErrSP <> 0 
				  BEGIN 
				   	print 'Error  al consolidar item de gc '
				 	RETURN @StatErrSP			 
				  END 				
			  */
			  
			  
   		        -- actualizar que sea lleno el contenedor 
                execute @StatErrSP = spUpdateContainerInventoryFull  @intContainerUniversalId=@intUniversalId, @intContainerIsFull=@blnFull
                
                	IF @StatErrSP <> 0 
				    BEGIN
				       	  print 'Error en el cambio de estatus administrativo del contenedor'
	                      RETURN (1) 
				    END -- IF @StatErrSP <> 0 			


			  /* -- JCADENA 17 NOV 2015
			   -- actualizacion del producto de contenedor 
                execute spUpdateProductsContCFS  @intUnivId=@intUniversalId, @intSOrderId=@intServiceOrder, @intServiceId=@lint_ServiceId, @intSOrderItemId=@intServiceOrderItem, @strUser=@istrUserName, @strTextFree='', @intYardVerificationId=@int_ticket, @intYardVTItemId=@intYVTicketItem, @intErrorCode=@StatErrSP output

				 IF @StatErrSP <> 0 
				    BEGIN
				       	  print 'Error al ejecutar el SP actualizar el conteenido '
	                      RETURN (1) 
				    END -- IF @StatErrSP <> 0 
			   */ 

		         
		         --- inserta imos 
		         --- JCADENA 19-01-2016 , se comenta que la asociacion del historico del imo, ya que se guarda en cada guardada de detalle
		         /*
		         IF @intIMOCodeId > 0 
		          BEGIN 
		             execute spCMInsertIMOS  @UnivId=@intUniversalId , @IMO=@intIMOCodeId, @User=@istrUserName
		             
		             SELECT @lstr_IMOCodeiNFO = ISNULL(tblclsIMOCode.strIMOCodeIdentifier,'')
		             FROM tblclsIMOCode
		             WHERE tblclsIMOCode.intIMOCodeId = @intIMOCodeId
		             
		             
		             SET @lstr_IMOComments = ' IMO :' + @lstr_IMOCodeiNFO
		             execute @StatErrSP =  spUpdateHistoryIMOCode  @UniversalId=@intUniversalId, @IMOId=@intIMOCodeId, @Comments=@lstr_IMOComments, @User=@istrUserName
	
	   				 IF @StatErrSP <> 0 
				      BEGIN
				       	  print 'Error al actualizar el historico de IMOS '
	                      RETURN (1) 
				      END -- IF @StatErrSP <> 0 			
        
		          END --- inserta imos 
		          */
		          
		          -- actualizar la solicitud de servicio y el historico 
                SET @lstr_TransacType='CCONS'
                SET @lstr_HistComments = 'EJEC. DE CONS. DIRECTA('+@str_service+'), Servicio #' + convert(varchar(12),@lint_ServiceId)
                 
                execute @StatErrSP = spUpdateHistoryServiceOrder  @TransType=@lstr_TransacType, @UniversalId=@intUniversalId, @ServiceId=@lint_ServiceId, @ServiceOrderId=@intServiceOrder, @ServiceOrderItemId=@intServiceOrderItem, @Comments=@lstr_HistComments, @User=@istrUserName
                                     
                IF @StatErrSP <> 0 
                  BEGIN
                   		  print 'Error registrar el historico del contenedor '
	                      RETURN (1) 
                  END 
                  
                ---->> jcadena 19-01-2016 , si  hay estatus fisico encontrado 
                   IF LEN( @lstr_PhyscalStatusId )> 2
                     BEGIN                   
		              -- actualizar el estado fisico del contenedor 
		                --execute @StatErrSP = spUpdateContainerStatus  @intUniversalId, 3, 'CONS', 'CCONS'-- 'CONLIBMAN'
		                execute @StatErrSP = spUpdateContainerStatus  @intUniversalId, 3, @lstr_PhyscalStatusId , 'CCONS'-- 'CONLIBMAN'
				        
		   				 IF @StatErrSP <> 0 
						    BEGIN
						       	  print 'Error en el cambio de estatus fisico del contenedor'
			                      RETURN (1) 
						    END -- IF @StatErrSP <> 0 			
				     END
                 ----<<< jcadena 19-01-2016 , si  hay estatus fisico encontrado 
				     		    
              -- actualiza el estado administrativo del contenedor 
                execute @StatErrSP = spUpdateContainerStatus  @intUniversalId, 1, 'PATIO', 'CCONS'-- 'patio'
		        
   				 IF @StatErrSP <> 0 
				    BEGIN
				       	  print 'Error en el cambio de estatus administrativo del contenedor'
	                      RETURN (1) 
				    END -- IF @StatErrSP <> 0 			
			  
  
			  -- actualizar contenedores pendientes 
			   -- si hay bv @lint_VesselVoyageId, @lint_VesselVoyageId
                execute spRefreshPendingContainers  @intVesselVoyageId=@lint_VesselVoyageId, @strUser=@istrUserName

                   ---- jcadena 201600217

												
					   --- obtener la fecha menor de las tarjas 
                             SELECT @dtmMinDate= ISNULL(MIN(tblclsYardVerifTicketItem.tmeYVerifTItemInitialTime),GETDATE() )
                             FROM tblclsYardVerifTicketItem
                             WHERE tblclsYardVerifTicketItem.intServiceOrderId = @intServiceOrder
                             AND   tblclsYardVerifTicketItem.intServiceOrderItemId = @intServiceOrderItem

                       --- obtener la fecha final del servicio 	
                             SELECT @dtMaxmDate= ISNULL(MAX(tblclsYardVerifTicketItem.tmeYVerifTItemFinalTime),GETDATE() )
                             FROM tblclsYardVerifTicketItem
                             WHERE tblclsYardVerifTicketItem.intServiceOrderId = @intServiceOrder
                             AND   tblclsYardVerifTicketItem.intServiceOrderItemId = @intServiceOrderItem
                             
                                                          ---- obtener la visita de la solicitud e item actual 

							SELECT  @intVisitId = tblclsVisit.intVisitId ,
							        @dtmInDate  = ISNULL(tblclsVisit.dtmVisitDatetimeIn,'19000101 00:00'),
							        @dtmOutDate = ISNULL(tblclsVisit.dtmVisitDatetimeOut,'19000101 00:00')
							FROM  tblclsVisit
							  INNER JOIN tblclsVisitServiceOrder ON tblclsVisit.intVisitId = tblclsVisitServiceOrder.intVisitId
							WHERE tblclsVisitServiceOrder.intServiceOrderId =@intServiceOrder
							AND   tblclsVisitServiceOrder.intServiceOrderItemId = @intServiceOrderItem
							
						
							
                             --- check-in. si ya tiene salida no tendria caso darle check in , solo validar 
                             IF  @dtmInDate =  '19000101 00:00' 
                              begin
                               --SET @strcoms = 'prev inout1 V=' + CONVERT(VARCHAR(11), @intVisitId) + '@dtmMinDate=' + CONVERT(VARCHAR(35), @dtmMinDate) + '@strUser'+ CONVERT(VARCHAR(11), @strUser	)
 							    --print @strcoms
 							    ---  ajustar la hora 
 							      -- poner el dia hoy
 							      
 							        SET @SHour   = CONVERT(VARCHAR(5),DATEPART(HOUR,@dtmMinDate  ))
 							        SET @SMinute  = CONVERT(VARCHAR(5),DATEPART(MINUTE,@dtmMinDate  ))
 							        SET @SSecond  = CONVERT(VARCHAR(5),DATEPART(SECOND,@dtmMinDate  ))
 							        
 							        IF (LEN(@SHour) = 1)
 							            SET @SHour = '0'+@SHour
 							        
 							        IF (LEN(@SMinute) = 1)
 							            SET @SMinute = '0'+@SMinute
 							           
 							        IF (LEN(@SSecond) = 1)
 							            SET @SSecond = '0'+@SSecond
   
 							       							      
 							      SET @dtmMinDate = CONVERT(DATETIME,@strTodayMonthY  +' '+  @SHour +':'  + @SMinute +':'  + @SSecond ,120) 
 							      
                                  EXECUTE @retval =  spInOutVisit  @intVisitId=@intVisitId, @dtmReceptionDate=@dtmMinDate, @strService='REC', @strUser=@istrUserName
                              end 
                                 --  SET @strcoms = ' @retval'+ convert(varchar(11),@retval)
                                 --- print @strcoms 

                             --- check-OUT. si ya tiene salida no tendria caso darle check OUT , solo validar 
                             IF  @dtmOutDate =  '19000101 00:00' 
                              BEGIN
                                
                                 --SET @strcoms = 'prev inout2 V=' + CONVERT(VARCHAR(11), @intVisitId) + '@dtMaxmDate=' + CONVERT(VARCHAR(35), @dtMaxmDate) + '@strUser'+ CONVERT(VARCHAR(11), @strUser	)
 							     -- print @strcoms
 							     
   							        SET @SHour   = CONVERT(VARCHAR(5),DATEPART(HOUR,@dtMaxmDate  ))
 							        SET @SMinute  = CONVERT(VARCHAR(5),DATEPART(MINUTE,@dtMaxmDate  ))
 							        SET @SSecond  = CONVERT(VARCHAR(5),DATEPART(SECOND,@dtMaxmDate  ))
 							        
 							        IF (LEN(@SHour) = 1)
 							            SET @SHour = '0'+@SHour
 							        
 							        IF (LEN(@SMinute) = 1)
 							            SET @SMinute = '0'+@SMinute
 							           
 							        IF (LEN(@SSecond) = 1)
 							            SET @SSecond = '0'+@SSecond

 							     
 							     ---- poner fecha, anio, mes y dia de hoy ,pero hora de la variable 
 							     SET @dtMaxmDate = CONVERT(DATETIME, @strTodayMonthY +' '+  @SHour+':'  + @SMinute+':'  + @SSecond ,120) 
 							     
 							     EXECUTE  spInOutVisit  @intVisitId=@intVisitId, @dtmReceptionDate=@dtMaxmDate, @strService='ENT', @strUser=@istrUserName
                              END 


                   ---<<<< jcadena 20160216


		          --- si fue procesado sin problemas 
		          SET @lint_FlagWasProcessed  = 1          
         
    END  -- @str_service = 'CONSD'
		          
--------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------

    -----------------------------------------------------------------------------------------
    -----------------SELLLOS 


      IF  @str_service = 'DESC' OR @str_service = 'DESCD' OR @str_service = 'PREV' OR  @str_service = 'ROCUL' OR @str_service = 'CONSDESC' OR @str_service = '2oREV' OR @str_service ='2oREVMC'
         BEGIN 
          declare @lint_lengA int
          declare @lint_tempA int
          declare @lstr_tempc varchar(100)
          declare @lstr_tempd varchar(100)
          
            print 'emtrara a revisar sellos '
           
                  --- 18-OCT-2016 JCADENA -- obtener el sello del inventario
                 ----------------------------------
                  declare aux_crsr cursor 
                  	 for  
                  	    SELECT isnull(tblclsContainerSeal.strContainerSealNumber, '') + ','
                  	    FROM tblclsContainerSeal 
                  	    WHERE intContainerUniversalId =  @intUniversalId
                  	    AND tblclsContainerSeal.strContainerSealNumber NOT LIKE '%-->hh%'
                  	 	       
                 	 for read only  
                 	 
                 	 open aux_crsr
                 	 while 1=1 
                 	  	 begin 
                 	  	 	 fetch aux_crsr into @s_fetch 
                 	  	 	  if @@sqlstatus <> 0 break 
                 	  	 	      --- longitud de la cadena 
                 	  	 	       SET @lint_lengA = LEN( @s_fetch )
                 	  	 	       
                 	  	 	       ----- noviembre 2016
                 	  	 	       If  @lint_lengA > 5
                 	  	 	        BEGIN 
                 	  	 	         	-- buscar el substring 
	                 	  	 	         SET @lstr_tempc = SUBSTRING(@s_fetch, @lint_lengA - 5,@lint_lengA)
	                 	  	 	                        	  	 	         
	                 	  	 	         IF @lstr_tempc = '-->hh,'
	                 	  	 	           BEGIN
	                 	  	 	             --- obtener la cadena sin el texto de operacion 
	                 	  	 	             SET  @lstr_tempd = SUBSTRING(@s_fetch,1 , @lint_lengA - 6)
	                 	  	 	             --- asignarlo de nuevo al fetch 
	                 	  	 	             SET   @s_fetch  = @lstr_tempd +','
	                 	  	 	              
	                 	  	 	           END --  IF @lstr_tempc = '-->hh,'
                 	  	 	            -----
                 	  	 	        END  --- If @lint_lengA > 5

                 	  	 	  select @SealTem = @SealTem + @s_fetch
                 	  	 end 
                 	 close aux_crsr
                 	 deallocate cursor aux_crsr
                 	
                 	--        SELECT  @Seal = @Seal + tblclsEIRContainerSeal.strEIRContSealNumber + ','               
                 	--        FROM    tblclsEIRContainerSeal             
                 	--        WHERE   ( tblclsEIRContainerSeal.intEIRId = @EIR) 
                 	-- 
                 	
                 	/*Elimina la ultima coma de la cadena generada(la ultima coma es un error*/  
                 	  IF char_length (rtrim(@SealTem)) > 0              
                 	     SELECT @Seal = substring (@SealTem,1,(char_length (rtrim(@SealTem)) - 1))             
                 	  ELSE           
                 	     SELECT @Seal = ''
                 	   ----------------------
                 	   -- PRINT @Seal
                 	   -- DECLARE @lstr_Val VARCHAR(20)
                 	   -- SET  @lstr_Val = convert(varchar(10), @intYVTicketItem ) 
                 	   -- print @lstr_Val 
                 	   
                 	    -- si hay sellos en inventario
                 	    ----------------------         
                 	   IF LEN(@Seal)>1 
                 	   BEGIN
                 	        --- actualizar la tarja en el campo de sellos eliminados 
                 	        UPDATE tblclsYardVerifTicketItem
                 	        SET tblclsYardVerifTicketItem.strEliminatedSeals = @Seal
                 	        WHERE tblclsYardVerifTicketItem.intYardVTItemId = @intYVTicketItem 

                 	       
                 	   END                  	   
                 	   --------------------- SELLOS                  
                 --------------------------------------

         END 
     ---------- SELLOS 
    -- print 'antes de ifs'
   -- return 10      
    ------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------

 IF @str_service = 'DESC'
	    BEGIN 
	    
      			-- actualizar que sea lleno el contenedor 
                execute @StatErrSP = spUpdateContainerInventoryFull  @intContainerUniversalId=@intUniversalId, @intContainerIsFull=@blnFull
                
           		-- actualizar el estatus administrativo
      		    ---- jcadena 19-01-2016 , si  hay estatus fisico encontrado 
                   IF LEN( @lstr_PhyscalStatusId )> 2
                     BEGIN 
		        		--execute @StatErrSP = spUpdateContainerStatus  @UniversalId=@intUniversalId, @Status=1, @Identifier='PATIO', @Evento='CCONS'-- 'CONLIBMAN'
		        		  execute @StatErrSP = spUpdateContainerStatus  @UniversalId=@intUniversalId, @Status=1, @Identifier=@lstr_PhyscalStatusId, @Evento='CCONS'-- 'CONLIBMAN'
				        
		   				 IF @StatErrSP <> 0 
						    BEGIN
						       	  print 'Error en el cambio de estatus administrativo del contenedor'
			                      RETURN (1) 
						    END -- IF @StatErrSP <> 0 			
				     END 
      		    ---- jcadena 19-01-2016 , si  hay estatus fisico encontrado 						    
		
	            /* JCADENA 17 NOV 2015  COMENTADO , PARA QUE SE HAGA EN EL SP 
	            -- actualizacion del producto de contenedor 
                execute spUpdateProductsContCFS  @intUnivId=@intUniversalId, @intSOrderId=@intServiceOrder, @intServiceId=@lint_ServiceId, @intSOrderItemId=@intServiceOrderItem, @strUser=@istrUserName, @strTextFree='', @intYardVerificationId=@int_ticket, @intYardVTItemId=@intYVTicketItem, @intErrorCode=@StatErrSP output

				 IF @StatErrSP <> 0 
				    BEGIN
				       	  print 'Error al ejecutar el SP actualizar el conte'
	                      RETURN (1) 
				    END -- IF @StatErrSP <> 0 
				
			
			  -- actualizar cantidaddes de desconsolidacion 
			  
			   execute @StatErrSP = spUpdateContProdDescQty  @UnivId=@intUniversalId , @ProductId = @lint_TicketProduct , @Qty = @int_TicketQuantitysum,
			           									     @User=@istrUserName, @CustomerId=@lint_TicketCustomer, @CustType=TicketCustomerType,
			           									     @ProdPackingId=@lint_TicketPacking, @Weight=@dec_TicketDecimalsum	
			           									   
			  IF  @StatErrSP > 0 
			      BEGIN 
			           	  print 'Error en actualizacion del valores de cantidad'
	                      RETURN @StatErrSP
			      END
			   ------------------------  COMENTADO 
			   */
	         
	         -- actualizar la solicitud de servicio y el historico 
              SET @lstr_TransacType='CDESC'
              SET @lstr_HistComments = 'EJEC. DE DESCONSOLIDACION('+@str_service+'), Servicio #' + convert(varchar(12),@lint_ServiceId)
                            
                execute @StatErrSP = spUpdateHistoryServiceOrder  @TransType=@lstr_TransacType, @UniversalId=@intUniversalId, @ServiceId=@lint_ServiceId, @ServiceOrderId=@intServiceOrder, @ServiceOrderItemId=@intServiceOrderItem, @Comments=@lstr_HistComments, @User=@istrUserName
                
                IF @StatErrSP <> 0 
                  BEGIN
                   		  print 'Error registrar el historico del contenedor '
	                      RETURN (1) 
                  END 
				
               -- actualizar el estado fisico del contenedor 
               ---- jcadena 19-01-2016 , si  hay estatus fisico encontrado 
                   IF LEN( @lstr_PhyscalStatusId )> 2
                     BEGIN 
			                --execute @StatErrSP = spUpdateContainerStatus  @intUniversalId, 3, 'DESC', 'CDESC'-- 'CONLIBMAN'
			                execute @StatErrSP = spUpdateContainerStatus  @intUniversalId, 3,  @lstr_PhyscalStatusId, 'CDESC'-- 'CONLIBMAN'
					        
			   				IF @StatErrSP <> 0 
							    BEGIN
							       	  print 'Error en el cambio de estatus fisico del contenedor'
				                      RETURN (1) 
							    END -- IF @StatErrSP <> 0				    
				     END ------ jcadena 19-01-2016 , si  hay estatus fisico encontrado 
							    
              -- actualzar el estatus administativo del contenedor 
                execute @StatErrSP = spUpdateContainerStatus  @intUniversalId, 1, 'PATIO', 'CDESC'-- 'patio'		        
   				 IF @StatErrSP <> 0 
				    BEGIN
				       	  print 'Error en el cambio de estatus administrativo del contenedor'
	                      RETURN (1) 
				    END -- IF @StatErrSP <> 0 			
                 
                 ---- si es vacio 
                 IF @blnFull= 0 
                 BEGIN 
                 
                   BEGIN TRANSACTION 
                   
                    --- borrar sellos 
                       DELETE
                       FROM tblclsContainerSeal
                       WHERE intContainerUniversalId =  @intUniversalId
                       
	                --- quitar productos 
	                  DELETE 
	                  FROM tblclsContainerProduct
	                  WHERE tblclsContainerProduct.intContainerUniversalId = @intUniversalId
	                
	                --- invetario quitar peso , cliente , puerto origen
	                  UPDATE tblclsContainerInventory
	                  SET decContainerInventoryWeight = 0 ,
	                      tblclsContainerInventory.intCustomerId = NULL , 
	                      tblclsContainerInventory.strContainerInvPortOfOriginId=''	                      
	                  WHERE intContainerUniversalId  = @intUniversalId
	                  
	                  --- quitar el bl
	                  DELETE tblclsContainerInventoryDoc
	                  FROM tblclsContainerInventoryDoc
	                   INNER JOIN tblclsDocument on tblclsDocument.intDocumentId = tblclsContainerInventoryDoc.intDocumentId
	                    INNER JOIN tblclsDocumentType on tblclsDocumentType.intDocumentTypeId = tblclsDocument.intDocumentTypeId 
	                  WHERE tblclsContainerInventoryDoc.intContainerUniversalId = @intUniversalId
	                  AND  tblclsDocumentType.strDocumentTypeIdentifier = 'BL'

	                  
                      IF @@Error = 1  --Validacion al Insertar el Registro   
							 BEGIN   
							   ROLLBACK TRAN    --Aborta los Cambios   
							   SELECT @strError = '>>--ERROR: Al guardar detalle tarja '
							   RETURN -4  --ERROR: Al Ingresar el Contenedor a Inventario   
							 END 						 
							 
						COMMIT TRAN 	

                   
                 END  --IF @intContainerIsFull= 0 
                 
			  -- actualizar contenedores pendientes 
                execute spRefreshPendingContainers  @intVesselVoyageId=@lint_VesselVoyageId, @strUser=@istrUserName

	          --- si fue procesado sin problemas 
		        SET @lint_FlagWasProcessed  = 1          

	    END -- @str_service = 'DESC'

--------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------

  IF @str_service = 'DESCD'
	    BEGIN 
	    
	    -- obtener informacion del contenedor 
	             
	              SELECT @lstr_DischargePortInv=  tblclsContainerInventory.strContainerInvDischargePortId, 
	                     @lstr_FinalPortInv = tblclsContainerInventory.strContainerInvFinalPortId, 
	                     @lstr_OriginPortInv = tblclsContainerInventory.strContainerInvPortOfOriginId
	              FROM tblclsContainerInventory
	              WHERE intContainerUniversalId = @intUniversalId  
	              

              	  -- sigue saber si tiene imo la tarja final 
			       SELECT @intIMOCodeId =  ISNULL(tblclsYardVerifTicketItem.intIMOCodeId,0)
			       FROM tblclsYardVerifTicketItem			        
			       WHERE tblclsYardVerifTicketItem.intYardVTItemId = @intYVTicketItem	       
			       
			       
                 -- actualizar que sea lleno el contenedor 
                 execute @StatErrSP = spUpdateContainerInventoryFull  @intContainerUniversalId=@intUniversalId, @intContainerIsFull=@blnFull
                 
     				 IF @StatErrSP <> 0 
				    BEGIN
				       	  print 'Error en el cambio de estatus fisico del contenedor'
	                      RETURN (1) 
				    END -- IF @StatErrSP <> 0 			


		---------------------------------------------------       	 
   				execute @StatErrSP = spGCStrippConsolidation  @ServiceTypeId= @lint_ServiceId, @GCUnivId=0, @ContUnivId=@intUniversalId,
    	                                          @ContainerId=@lstr_Container, @ServiceOrderId=@intServiceOrder, 
        	                                      @ServiceOrderItemId=@intServiceOrderItem, @FisMovId=@lint_FiscalMovSO, 
            	                                  @ProductId=@lint_TicketProduct, @ProductPackingId=@lint_TicketPacking , @GCTypeId=1,
                	                              @GCDamTypeId=NULL, @WarehouseId=NULL,@CustomerTypeId=@lint_TicketCustomerType,
                    	                          @CustomerId=@lint_TicketCustomer, @IsOutDoor=0,@Qty=@int_TicketQuantitysum,
                        	                      @Marks=@lstr_TicketsMarks, @Numbers=@lstr_TicketNumbers, @Weight=@dec_TicketDecimalsum,
                            	                  @Volume=0, @CommValue=0, @PositionId='',@VessVoyId=@lint_VesselVoyageId ,
                                	              @OriginPort=@lstr_OriginPortInv, @DischargePort=@lstr_DischargePortInv,
                                    	          @FinalPort=@lstr_FinalPortInv, @Comments='', @User=@istrUserName, 
                                        	      @ExecDate=@ldtm_CurrentDate, @GCInvItem=0, @IMOId=@intIMOCodeId, @RetGCUnivId=@lint_MaxGCIdMasterRet output,
                                            	  @ReqById=@lint_TicketRequiredBy, @ReqByTypeId=@lint_TicketRequiredByType

				IF @StatErrSP <> 0 
				  BEGIN 
				  	    print 'Error al ejecutar el SP de Consolidacion de Carga general'
			            RETURN @StatErrSP			 
				  END
				  
				 -- validar que se hayaa retornado el gc universal 
				 IF ISNULL(@lint_MaxGCIdMasterRet,0)  <1   
				  BEGIN
				      	print 'Error no se genero el universal '
			            RETURN @StatErrSP			 
				  END 
				  		       	   
			-------------------items---------------					   
	             execute @StatErrSP = spGCInInvItemsDesc  @ServiceType= @str_service , @GCUnivId=@lint_MaxGCIdMasterRet,
	                                              @ContUnivId=@intUniversalId, @ContainerId=@lstr_Container, 
	                                              @ServiceOrderId=@intServiceOrder,@ServiceOrderItemId=@intServiceOrderItem, 
	                                              @FisMovId=@lint_FiscalMovSO, @WarehouseId=NULL, @IsOutDoor=0, 
	                                              @Qty=@int_TicketQuantitysum, @Marks=@lstr_TicketsMarks, 
	                                              @Numbers=@lstr_TicketNumbers, @Weight=@dec_TicketDecimalsum, 
	                                              @Volume=0, @CommValue=0, @PositionId='', @VessVoyId=@lint_VesselVoyageId,
	                                              @OriginPort=@lstr_OriginPortInv, @DischargePort=@lstr_DischargePortInv,
	                                              @FinalPort=@lstr_FinalPortInv,  @HasIMO=0, @Comments='',
	                                              @User=@istrUserName, @ExecDate=@ldtm_CurrentDate,
	                                              @ProductId=@lint_TicketProduct, @ProductPackingId=@lint_TicketPacking

				IF @StatErrSP <> 0 
				 BEGIN 
				  	print 'Error  al consolidar item de gc '
					RETURN @StatErrSP			 
				END 

               /**** JCADENA 17-NOV-2015 COMENTADO 				
				-- actualiar productos e inventario				
				execute @StatErrSP = spCompleteStrippStuffCMVisit  @intUnivId = @intUniversalId, @intSOrderId = @intServiceOrder,
				   											       @intServiceId = @lint_ServiceId, @intSOrderItemId = @intServiceOrderItem,
																   @strUser = @istrUserName , @intErrorCode=@StatErrSP output

                IF @StatErrSP <> 0 
				  BEGIN 
				   	print 'Error  al consolidar item de gc '
				 	RETURN @StatErrSP			 
				  END 				
			   
   			   -- actualizacion del producto de contenedor 
                execute spUpdateProductsContCFS  @intUnivId=@intUniversalId, @intSOrderId=@intServiceOrder, @intServiceId=@lint_ServiceId, @intSOrderItemId=@intServiceOrderItem, @strUser=@istrUserName, @strTextFree='', @intYardVerificationId=@int_ticket, @intYardVTItemId=@intYVTicketItem, @intErrorCode=@StatErrSP output

				 IF @StatErrSP <> 0 
				    BEGIN
				       	  print 'Error al ejecutar el SP actualizar el conteenido '
	                      RETURN (1) 
				    END -- IF @StatErrSP <> 0 
				    
				  */

				-- actualizar el estado fisico del contenedor 
		               ---- jcadena 19-01-2016 , si  hay estatus fisico encontrado 
                   IF LEN( @lstr_PhyscalStatusId )> 2
                     BEGIN 
		                  --execute @StatErrSP = spUpdateContainerStatus  @intUniversalId, 3, 'DESC', 'CDESC'-- 'CONLIBMAN'
		                  execute @StatErrSP = spUpdateContainerStatus  @intUniversalId, 3, @lstr_PhyscalStatusId , 'CDESC'-- 'CONLIBMAN'
				        
		   				  IF @StatErrSP <> 0 
						    BEGIN
						       	  print 'Error en el cambio de estatus fisico del contenedor'
			                      RETURN (1) 
						    END -- IF @StatErrSP <> 0				
				     END	---- jcadena 19-01-2016 , si  hay estatus fisico encontrado 
				     --?????????????????****				 --- se comentara ??? ., si , es actualiza conforme se vaya guardadno cada detalle 

/*
 			     -- actualizar cantidaddes de desconsolidacion 			  
			  		execute @StatErrSP = spUpdateContProdDescQty  @UnivId=@intUniversalId , @ProductId = @lint_TicketProduct , @Qty = @int_TicketQuantitysum,
			           									    @User=@istrUserName, @CustomerId=@lint_TicketCustomer, @CustType=TicketCustomerType,
			           									    @ProdPackingId=@lint_TicketPacking, @Weight=@dec_TicketDecimalsum	
			           									   
					IF  @StatErrSP > 0 
					    BEGIN 
					           	  print 'Error en actualizacion del valores de cantidad'
			                      RETURN @StatErrSP
					   END			
					
*/			       
			         -- actualizar la solicitud de servicio y el historico 
            		SET @lstr_TransacType='CDESC'
		            SET @lstr_HistComments = 'EJEC. DE DESC. DIRECTA('+@str_service+'), Servicio #' + convert(varchar(12),@lint_ServiceId)
		                            
                	execute @StatErrSP = spUpdateHistoryServiceOrder  @TransType=@lstr_TransacType, @UniversalId=@intUniversalId, @ServiceId=@lint_ServiceId, @ServiceOrderId=@intServiceOrder, @ServiceOrderItemId=@intServiceOrderItem, @Comments=@lstr_HistComments, @User=@istrUserName
                
               	 	IF @StatErrSP <> 0 
	                  BEGIN
	                   		  print 'Error registrar el historico del contenedor '
		                      RETURN (1) 
	                  END 
	                  
                   -- actualzar el estatus administativo del contenedor 
	                execute @StatErrSP = spUpdateContainerStatus  @intUniversalId, 1, 'PATIO', 'CDESC'-- 'patio'		        
	   				 IF @StatErrSP <> 0 
					    BEGIN
					       	  print 'Error en el cambio de estatus administrativo del contenedor'
		                      RETURN (1) 
					    END -- IF @StatErrSP <> 0 			
				
					    
	               ---- si es vacio 
	                 IF @blnFull= 0 
	                 BEGIN 
	                   BEGIN TRANSACTION 
	                   
	                    --- borrar sellos 
	                       DELETE
	                       FROM tblclsContainerSeal
	                       WHERE intContainerUniversalId =  @intUniversalId
	                       
		                --- quitar productos 
		                  DELETE 
		                  FROM tblclsContainerProduct
		                  WHERE tblclsContainerProduct.intContainerUniversalId = @intUniversalId
		                
		                --- invetario quitar peso 
		                  UPDATE tblclsContainerInventory
		                  SET decContainerInventoryWeight = 0 ,
		                      tblclsContainerInventory.intCustomerId = NULL , 
		                      tblclsContainerInventory.strContainerInvPortOfOriginId=''	                      
		                  WHERE intContainerUniversalId  = @intUniversalId
		                  
		                --- quitar el bl
		                  DELETE tblclsContainerInventoryDoc
		                  FROM tblclsContainerInventoryDoc 
		                  	   INNER JOIN tblclsDocument on tblclsDocument.intDocumentId = tblclsContainerInventoryDoc.intDocumentId
		                  	   INNER JOIN tblclsDocumentType on tblclsDocumentType.intDocumentTypeId = tblclsDocument.intDocumentTypeId 
		                  WHERE tblclsContainerInventoryDoc.intContainerUniversalId = @intUniversalId
		                  AND  tblclsDocumentType.strDocumentTypeIdentifier = 'BL'

		                  
	                      IF @@Error = 1  --Validacion al Insertar el Registro   
								 BEGIN   
								   ROLLBACK TRAN    --Aborta los Cambios   
								   SELECT @strError = '>>--ERROR: Al guardar detalle tarja '
								   RETURN -4  --ERROR: Al Ingresar el Contenedor a Inventario   
								 END 						 
								 
							COMMIT TRAN 	
	
	                   
	                 END  --IF @intContainerIsFull= 0 
	                 					                     
				  -- actualizar contenedores pendientes 
	                execute spRefreshPendingContainers  @intVesselVoyageId=@lint_VesselVoyageId, @strUser=@istrUserName
	                
                  ---- jcadena 201600217
												
					   --- obtener la fecha menor de las tarjas 
                             SELECT @dtmMinDate= ISNULL(MIN(tblclsYardVerifTicketItem.tmeYVerifTItemInitialTime),GETDATE() )
                             FROM tblclsYardVerifTicketItem
                             WHERE tblclsYardVerifTicketItem.intServiceOrderId = @intServiceOrder
                             AND   tblclsYardVerifTicketItem.intServiceOrderItemId = @intServiceOrderItem

                       --- obtener la fecha final del servicio 	
                             SELECT @dtMaxmDate= ISNULL(MAX(tblclsYardVerifTicketItem.tmeYVerifTItemFinalTime),GETDATE() )
                             FROM tblclsYardVerifTicketItem
                             WHERE tblclsYardVerifTicketItem.intServiceOrderId = @intServiceOrder
                             AND   tblclsYardVerifTicketItem.intServiceOrderItemId = @intServiceOrderItem
                             
                        ---- obtener la visita de la solicitud e item actual 

							SELECT  @intVisitId = tblclsVisit.intVisitId ,
							        @dtmInDate  = ISNULL(tblclsVisit.dtmVisitDatetimeIn,'19000101 00:00'),
							        @dtmOutDate = ISNULL(tblclsVisit.dtmVisitDatetimeOut,'19000101 00:00')
							FROM  tblclsVisit
							  INNER JOIN tblclsVisitServiceOrder ON tblclsVisit.intVisitId = tblclsVisitServiceOrder.intVisitId
							WHERE tblclsVisitServiceOrder.intServiceOrderId =@intServiceOrder
							AND   tblclsVisitServiceOrder.intServiceOrderItemId = @intServiceOrderItem
							
						
							
                             --- check-in. si ya tiene salida no tendria caso darle check in , solo validar 
                             IF  @dtmInDate =  '19000101 00:00' 
                              begin
                               --SET @strcoms = 'prev inout1 V=' + CONVERT(VARCHAR(11), @intVisitId) + '@dtmMinDate=' + CONVERT(VARCHAR(35), @dtmMinDate) + '@strUser'+ CONVERT(VARCHAR(11), @strUser	)
 							    --print @strcoms
 							    ---  ajustar la hora 
 							      -- poner el dia hoy
 							      
 							        SET @SHour   = CONVERT(VARCHAR(5),DATEPART(HOUR,@dtmMinDate  ))
 							        SET @SMinute  = CONVERT(VARCHAR(5),DATEPART(MINUTE,@dtmMinDate  ))
 							        SET @SSecond  = CONVERT(VARCHAR(5),DATEPART(SECOND,@dtmMinDate  ))
 							        
 							        IF (LEN(@SHour) = 1)
 							            SET @SHour = '0'+@SHour
 							        
 							        IF (LEN(@SMinute) = 1)
 							            SET @SMinute = '0'+@SMinute
 							           
 							        IF (LEN(@SSecond) = 1)
 							            SET @SSecond = '0'+@SSecond
   
 							       							      
 							      SET @dtmMinDate = CONVERT(DATETIME,@strTodayMonthY  +' '+  @SHour +':'  + @SMinute +':'  + @SSecond ,120) 
 							      
                                  EXECUTE @retval =  spInOutVisit  @intVisitId=@intVisitId, @dtmReceptionDate=@dtmMinDate, @strService='REC', @strUser=@istrUserName
                              end 
                                 --  SET @strcoms = ' @retval'+ convert(varchar(11),@retval)
                                 --- print @strcoms 

                             --- check-OUT. si ya tiene salida no tendria caso darle check OUT , solo validar 
                             IF  @dtmOutDate =  '19000101 00:00' 
                              BEGIN
                                
                                 --SET @strcoms = 'prev inout2 V=' + CONVERT(VARCHAR(11), @intVisitId) + '@dtMaxmDate=' + CONVERT(VARCHAR(35), @dtMaxmDate) + '@strUser'+ CONVERT(VARCHAR(11), @strUser	)
 							     -- print @strcoms
 							     
   							        SET @SHour   = CONVERT(VARCHAR(5),DATEPART(HOUR,@dtMaxmDate  ))
 							        SET @SMinute  = CONVERT(VARCHAR(5),DATEPART(MINUTE,@dtMaxmDate  ))
 							        SET @SSecond  = CONVERT(VARCHAR(5),DATEPART(SECOND,@dtMaxmDate  ))
 							        
 							        IF (LEN(@SHour) = 1)
 							            SET @SHour = '0'+@SHour
 							        
 							        IF (LEN(@SMinute) = 1)
 							            SET @SMinute = '0'+@SMinute
 							           
 							        IF (LEN(@SSecond) = 1)
 							            SET @SSecond = '0'+@SSecond

 							     
 							     ---- poner fecha, anio, mes y dia de hoy ,pero hora de la variable 
 							     SET @dtMaxmDate = CONVERT(DATETIME, @strTodayMonthY +' '+  @SHour+':'  + @SMinute+':'  + @SSecond ,120) 
 							     
 							     EXECUTE  spInOutVisit  @intVisitId=@intVisitId, @dtmReceptionDate=@dtMaxmDate, @strService='ENT', @strUser=@istrUserName
                              END 

                   ---<<<< jcadena 20160216

	              
	              --- si fue procesado sin problemas 
		            SET @lint_FlagWasProcessed  = 1          
			
	    END -- @str_service = 'DESCD'


--------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
 IF @str_service = 'PREV'
	    BEGIN 
     		    -- actualizar que sea lleno el contenedor 
                execute @StatErrSP = spUpdateContainerInventoryFull  @intContainerUniversalId=@intUniversalId, @intContainerIsFull=1
                
                -- actualiza el estado administrativo del contenedor 
                execute @StatErrSP = spUpdateContainerStatus  @intUniversalId, 1, 'PATIO', 'CROCUL'-- 'patio'
		        
   				 IF @StatErrSP <> 0 
				    BEGIN
				       	  print 'Error en el cambio de estatus administrativo del contenedor'
	                      RETURN (1) 
				    END -- IF @StatErrSP <> 0 			
				 
                -- actualizar el estado fisico del contenedor 
                ---- jcadena 19-01-2016 , si  hay estatus fisico encontrado 
                   IF LEN( @lstr_PhyscalStatusId )> 2
                     BEGIN 
                             --execute @StatErrSP = spUpdateContainerStatus  @intUniversalId, 3, 'LLENO', 'CROCUL'-- 'CONLIBMAN'
                             execute @StatErrSP = spUpdateContainerStatus  @intUniversalId, 3, @lstr_PhyscalStatusId, 'CROCUL'-- 'CONLIBMAN'
		        
		   				 IF @StatErrSP <> 0 
						    BEGIN
						       	  print 'Error en el cambio de estatus fisico del contenedor'
			                      RETURN (1) 
						    END -- IF @StatErrSP <> 0 			   
				     END  -- ---- jcadena 19-01-2016 , si  hay estatus fisico encontrado 

                -- actualizar la solicitud de servicio y el historico 
            		SET @lstr_TransacType='CROCUL'
		            SET @lstr_HistComments = 'EJEC. PREVIO ('+@str_service+'), Servicio #' + convert(varchar(12),@lint_ServiceId)
		                            
                	execute @StatErrSP = spUpdateHistoryServiceOrder  @TransType=@lstr_TransacType, @UniversalId=@intUniversalId, @ServiceId=@lint_ServiceId, @ServiceOrderId=@intServiceOrder, @ServiceOrderItemId=@intServiceOrderItem, @Comments=@lstr_HistComments, @User=@istrUserName
                
               	 	IF @StatErrSP <> 0 
	                  BEGIN
	                   		  print 'Error registrar el historico del contenedor '
		                      RETURN (1) 
	                  END 
	             
	             -- actualizar contenedores pendientes 
	                execute spRefreshPendingContainers  @intVesselVoyageId=@lint_VesselVoyageId, @strUser=@istrUserName
	                
	                --- borrar sellos  no aplicados en terminal 
	                	BEGIN TRANSACTION 
	                   
	                    --- borrar sellos 
	                       DELETE
	                       FROM tblclsContainerSeal
	                       WHERE intContainerUniversalId =  @intUniversalId
	                       --and tblclsContainerSeal.blnContainerSealApTerm = 1
	                       and not tblclsContainerSeal.strContainerSealNumber like '%-->hh%'
	                       

		                  
	                      IF @@Error = 1  --Validacion al Insertar el Registro   
								 BEGIN   
								   ROLLBACK TRAN    --Aborta los Cambios   
								   SELECT @strError = '>>--ERROR: Al guardar detalle tarja '
								   RETURN -4  --ERROR: Al Ingresar el Contenedor a Inventario   
								 END 						 
								 
							COMMIT TRAN 	
	                    ------------
                        ------------
                        --- noviembre 2016
                        --- actualizar  sellos aplicados en terminal
                           UPDATE tblclsContainerSeal
                           SET tblclsContainerSeal.strContainerSealNumber = SUBSTRING (tblclsContainerSeal.strContainerSealNumber,1,LEN(tblclsContainerSeal.strContainerSealNumber)-5)
	                       FROM tblclsContainerSeal
	                       WHERE intContainerUniversalId =  @intUniversalId
	                       and tblclsContainerSeal.blnContainerSealApTerm = 1
	                       and  tblclsContainerSeal.strContainerSealNumber like '%-->hh%'
		                  
	                      IF @@Error = 1  --Validacion al Insertar el Registro   
								 BEGIN   
								   ROLLBACK TRAN    --Aborta los Cambios   
								   SELECT @strError = '>>--ERROR: Al guardar detalle tarja '
								   RETURN -4  --ERROR: Al Ingresar el Contenedor a Inventario   
								 END 						 
								 
							COMMIT TRAN 	
                    ------------




	                --------------
	                
	             --- si fue procesado sin problemas 
		          SET @lint_FlagWasProcessed  = 1          


	    END  --IF @str_service = 'PREV'

--------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
 IF @str_service = 'ROCUL'
      BEGIN
        
     		    -- actualizar que sea lleno el contenedor 
                execute @StatErrSP = spUpdateContainerInventoryFull  @intContainerUniversalId=@intUniversalId, @intContainerIsFull=1
                
                -- actualiza el estado administrativo del contenedor 
                execute @StatErrSP = spUpdateContainerStatus  @intUniversalId, 1, 'PATIO', 'CROCUL'-- 'patio'
		        
   				 IF @StatErrSP <> 0 
				    BEGIN
				       	  print 'Error en el cambio de estatus administrativo del contenedor'
	                      RETURN (1) 
				    END -- IF @StatErrSP <> 0 			
				 
                -- actualizar el estado fisico del contenedor 
                    ---- jcadena 19-01-2016 , si  hay estatus fisico encontrado 
                   IF LEN( @lstr_PhyscalStatusId )> 2
                     BEGIN 
		                --execute @StatErrSP = spUpdateContainerStatus  @intUniversalId, 3, 'LLENO', 'CROCUL'-- 'CONLIBMAN'
		                execute @StatErrSP = spUpdateContainerStatus  @intUniversalId, 3, @lstr_PhyscalStatusId, 'CROCUL'-- 'CONLIBMAN'
				        
		   				 IF @StatErrSP <> 0 
						    BEGIN
						       	  print 'Error en el cambio de estatus fisico del contenedor'
			                      RETURN (1) 
						    END -- IF @StatErrSP <> 0 			   
				    END ---- jcadena 19-01-2016 , si  hay estatus fisico encontrado 

                -- actualizar la solicitud de servicio y el historico 
            		SET @lstr_TransacType='CROCUL'
		            SET @lstr_HistComments = 'EJEC. DE ROCUL ('+@str_service+'), Servicio #' + convert(varchar(12),@lint_ServiceId)
		                            
                	execute @StatErrSP = spUpdateHistoryServiceOrder  @TransType=@lstr_TransacType, @UniversalId=@intUniversalId, @ServiceId=@lint_ServiceId, @ServiceOrderId=@intServiceOrder, @ServiceOrderItemId=@intServiceOrderItem, @Comments=@lstr_HistComments, @User=@istrUserName
                
               	 	IF @StatErrSP <> 0 
	                  BEGIN
	                   		  print 'Error registrar el historico del contenedor '
		                      RETURN (1) 
	                  END 
	             
	             -- actualizar contenedores pendientes 
	                execute spRefreshPendingContainers  @intVesselVoyageId=@lint_VesselVoyageId, @strUser=@istrUserName
	                
                 --- borrar sellos aplicados en terminal
	                       DELETE
	                       FROM tblclsContainerSeal
	                       WHERE intContainerUniversalId =  @intUniversalId
	                       --and tblclsContainerSeal.blnContainerSealApTerm = 1
	                       and not tblclsContainerSeal.strContainerSealNumber like '%-->hh%'
		                  
	                      IF @@Error = 1  --Validacion al Insertar el Registro   
								 BEGIN   
								   ROLLBACK TRAN    --Aborta los Cambios   
								   SELECT @strError = '>>--ERROR: Al guardar detalle tarja '
								   RETURN -4  --ERROR: Al Ingresar el Contenedor a Inventario   
								 END 						 
								 
							COMMIT TRAN 	
                    ------------
                        --- noviembre 2016
                        --- actualizar  sellos aplicados en terminal
                           UPDATE tblclsContainerSeal
                           SET tblclsContainerSeal.strContainerSealNumber = SUBSTRING (tblclsContainerSeal.strContainerSealNumber,1,LEN(tblclsContainerSeal.strContainerSealNumber)-5)
	                       FROM tblclsContainerSeal
	                       WHERE intContainerUniversalId =  @intUniversalId
	                       and tblclsContainerSeal.blnContainerSealApTerm = 1
	                       and  tblclsContainerSeal.strContainerSealNumber like '%-->hh%'
		                  
	                      IF @@Error = 1  --Validacion al Insertar el Registro   
								 BEGIN   
								   ROLLBACK TRAN    --Aborta los Cambios   
								   SELECT @strError = '>>--ERROR: Al guardar detalle tarja '
								   RETURN -4  --ERROR: Al Ingresar el Contenedor a Inventario   
								 END 						 
								 
							COMMIT TRAN 	
                    ------------
                    
	                
	             --- si fue procesado sin problemas 
		          SET @lint_FlagWasProcessed  = 1          
 
	        
	  END  --IF @str_service = 'ROCUL'
	
--------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
 IF @str_service = 'CONSDESC'
      BEGIN
     		    -- actualizar que sea lleno el contenedor 
                execute @StatErrSP = spUpdateContainerInventoryFull  @intContainerUniversalId=@intUniversalId, @intContainerIsFull=1
                
                -- actualiza el estado administrativo del contenedor 
                execute @StatErrSP = spUpdateContainerStatus  @intUniversalId, 1, 'PATIO', 'CCONDESC'-- 'patio'
		        
   				 IF @StatErrSP <> 0 
				    BEGIN
				       	  print 'Error en el cambio de estatus administrativo del contenedor'
	                      RETURN (1) 
				    END -- IF @StatErrSP <> 0 			
				 
                -- actualizar el estado fisico del contenedor 
                 ---- jcadena 19-01-2016 , si  hay estatus fisico encontrado 
                   IF LEN( @lstr_PhyscalStatusId )> 2
                     BEGIN 
                            --execute @StatErrSP = spUpdateContainerStatus  @intUniversalId, 3, 'LLENO', 'CCONDESC'-- 'CONLIBMAN'
                            execute @StatErrSP = spUpdateContainerStatus  @intUniversalId, 3, @lstr_PhyscalStatusId, 'CCONDESC'-- 'CONLIBMAN'
		        
			   				 IF @StatErrSP <> 0 
							    BEGIN
							       	  print 'Error en el cambio de estatus fisico del contenedor'
				                      RETURN (1) 
							    END -- IF @StatErrSP <> 0 			
					 END   ---- jcadena 19-01-2016 , si  hay estatus fisico encontrado 

                -- actualizar la solicitud de servicio y el historico 
            		SET @lstr_TransacType='CCONDESC'
		            SET @lstr_HistComments = 'EJEC. DE CCONDESC ('+@str_service+'), Servicio #' + convert(varchar(12),@lint_ServiceId)
		                            
                	execute @StatErrSP = spUpdateHistoryServiceOrder  @TransType=@lstr_TransacType, @UniversalId=@intUniversalId, @ServiceId=@lint_ServiceId, @ServiceOrderId=@intServiceOrder, @ServiceOrderItemId=@intServiceOrderItem, @Comments=@lstr_HistComments, @User=@istrUserName
                
               	 	IF @StatErrSP <> 0 
	                  BEGIN
	                   		  print 'Error registrar el historico del contenedor '
		                      RETURN (1) 
	                  END 
	             
	             -- actualizar contenedores pendientes 
	                execute spRefreshPendingContainers  @intVesselVoyageId=@lint_VesselVoyageId, @strUser=@istrUserName
	                
	                
                    --- borrar sellos aplicados en terminal
	                       DELETE
	                       FROM tblclsContainerSeal
	                       WHERE intContainerUniversalId =  @intUniversalId
	                      -- and tblclsContainerSeal.blnContainerSealApTerm = 1
	                       and not tblclsContainerSeal.strContainerSealNumber like '%-->hh%'
		                  
	                      IF @@Error = 1  --Validacion al Insertar el Registro   
								 BEGIN   
								   ROLLBACK TRAN    --Aborta los Cambios   
								   SELECT @strError = '>>--ERROR: Al guardar detalle tarja '
								   RETURN -4  --ERROR: Al Ingresar el Contenedor a Inventario   
								 END 						 
								 
							COMMIT TRAN 	
                    ------------
                    
                    ------------
                        --- noviembre 2016
                        --- actualizar  sellos aplicados en terminal
                           UPDATE tblclsContainerSeal
                           SET tblclsContainerSeal.strContainerSealNumber = SUBSTRING (tblclsContainerSeal.strContainerSealNumber,1,LEN(tblclsContainerSeal.strContainerSealNumber)-5)
	                       FROM tblclsContainerSeal
	                       WHERE intContainerUniversalId =  @intUniversalId
	                       and tblclsContainerSeal.blnContainerSealApTerm = 1
	                       and  tblclsContainerSeal.strContainerSealNumber like '%-->hh%'
		                  
	                      IF @@Error = 1  --Validacion al Insertar el Registro   
								 BEGIN   
								   ROLLBACK TRAN    --Aborta los Cambios   
								   SELECT @strError = '>>--ERROR: Al guardar detalle tarja '
								   RETURN -4  --ERROR: Al Ingresar el Contenedor a Inventario   
								 END 						 
								 
							COMMIT TRAN 	
                    ------------

	            
	             --- si fue procesado sin problemas 
		          SET @lint_FlagWasProcessed  = 1          
    	              
	        
	  END  --IF @str_service = 'CCONDESC'
--------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
	  print ' revisar si es procesado'
   -- procesos generales , solo hay que validar que se cumplieron sin problemas las condicione s
   IF @lint_FlagWasProcessed  = 1          
     BEGIN 
                      IF @int_YardServiceProgramId >0 
	         			BEGIN 
				             -- obtener posicion 
				             SET @ReturnedYardPosId=''
				             execute spGetContInvYardPosId  @UniversalId=@intUniversalId, @ReturnedYardPosId=@ReturnedYardPosId output
								             
				             ---- completar el programa 				              
				             execute spUpdateYSPICompleted  @YardServProgId=@int_YardServiceProgramId, 
				                                             @YardServProgItemId=@int_YardServicePrgmItem, @YardSPICompleted=1,
				                                             @UserName=@istrUserName, @ErrorCode=@StatErrSP output
				                                             
				              IF @StatErrSP <> 0 
				               BEGIN 
				                PRINT 'Error al completar el programa'
				                RETURN @StatErrSP
				               END 
			             
				         END  -- IF @int_YardServiceProgramId >0 
				         
		 --- finalizar el servicio en maniobra 
		 execute spUpdateSOIStatus  @ServiceOrderId=@intServiceOrder, @ServiceOrderItemId=@intServiceOrderItem,
		 		 @ServiceOrderStatus='TER', @UserName=@istrUserName, @ErrorCode=@StatErrSP output
		 		 
		  IF @StatErrSP <> 0 
			BEGIN 
				PRINT 'Error al finalizar la solicitud '
				RETURN @StatErrSP
         END 
			  
	    --- actualizar el status de la tarja , y ponerla como final 

                   BEGIN TRANSACTION 
                   
	                --- actualizar el status y el tipo de tarja 
	                  UPDATE tblclsYardVerifTicketItem
	                  SET intContPhyStatId = @intPhyscalStatus
	                     , intYardVerificationType = 1
	                     , tblclsYardVerifTicketItem.tmeYVerifTItemFinalTime =  GETDATE()  -- tambien poner fecha de finalizacion 
	                  WHERE intYardVTItemId = @intYVTicketItem 
	                  
	                  --- si hay numero de tarja , finalizar 
	                  
                      IF @@Error = 1  --Validacion al Insertar el Registro   
							 BEGIN   
							   ROLLBACK TRAN    --Aborta los Cambios   
							   SELECT @strError = '>>--ERROR: Al guardar detalle tarja '
							   RETURN -5  --ERROR: Al actualizar la tarja 
							 END 						 
							 
						COMMIT TRAN 	

                  ---  actualizar la fecha de ejecucion de la tarja master 
                    IF (@int_ticket > 0 ) 
                    BEGIN 
                      
                      BEGIN  TRANSACTION 
                      
                        UPDATE tblclsYardVerificationTicket 
                        SET tblclsYardVerificationTicket.dtmYVerifTicketExecutionDate = GETDATE()
                           ,tblclsYardVerificationTicket.dtmYVerifTicketFinalDate = GETDATE()
                        WHERE tblclsYardVerificationTicket.intYardVerifTicketId = @int_ticket
                        
                      
                      IF @@Error = 1  --Validacion al Insertar el Registro   
							 BEGIN   
							   ROLLBACK TRAN    --Aborta los Cambios   
							   SELECT @strError = '>>--ERROR: Al actualizar master tarja '
							   RETURN -5  --ERROR: Al actualizar la tarja 
							 END 						 
							 
						COMMIT TRAN 	
                      
                    END  -- IF (@int_ticket > 0 ) 
                  --- 
                  
     END ----IF @lint_FlagWasProcessed  = 1

