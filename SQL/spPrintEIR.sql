/*
Highlight and execute the following statement to drop the procedure
before executing the create statement.

DROP PROCEDURE spPrintEIR

*/

CREATE PROCEDURE dbo.spPrintEIR (@EIR udtIdentifier           )with RECOMPILE 
AS   
 
/* 
Nombre :spPrintEIR  
Fec.Modificacion : Se corrigio que no aparecian los IMOS y los Sellos BLOERA 6-MAR-2006  BLOERA  
Fec.Modificacion : Se Reemplazo el nombre asociado a la linea trasportista por el nombre de la linea trasportista del Catalogo BLOERA 14-JUL-2006  BLOERA  
*/         
DECLARE             
    @SealTem            varchar(100), 
    @s_fetch            varchar(100),
    @ImoTem             varchar(100),
    @VisitId udtIdentifier,                    
    @Contar             integer,             
    @UniversalId        numeric(18),             
    @ServiceId          numeric(18),             
    @strTipoMov         char(60),             
    @strServiceName     char(60),             
    @EIRFolio           udtIdentifier,           
    @StatusPhysical		char(32),         /*Estado Fisico del Contendor(Lleno, Vacio)*/             
    @Date               datetime,      /*Fecha de creación del EIR*/             
    @Weight             decimal(18,2),         /*Peso Neto del Producto*/             
    @Tare       decimal(18,2),         /*Peso de la Tara*/              
    @GrossWeight        decimal(18,2),         /*Peso Bruto del contenedor(Tara + Peso-Producto)*/             
    @Steel              char(32),/*Estado físico del acero*/             
    @ShippingLine       char(80),         /*Nombre de la linea naviera*/             
    @Vessel             char(80),         /*Nombre del Buque*/             
    @VesselN            udtStringIdentifier,       /*Numero de Viaje*/              
    @Destino char(80),         /*puerto Destino*/             
    @CustomBroker       char(80),         /*Nombre de la Agencia Aduanal*/             
    @Customer           char(80),         /*NOmbre del Cliente*/           
    @Position           char(32),         /*Ubicación del Contenedor*/             
    @Product            varchar(80),         /*Nombre del Producto que contiene el contenedor*/             
    @IMO                varchar(32),         /*Indentificador del IMO*/             
    @Seal varchar(255),         /*Sello*/             
    @Temperature        decimal(18,2),         /*Temperatura del contenedor*/             
    @Pedimento          varchar(18),--varchar(60),             
    @Comments varchar(255),        /*Comentarios que estan registrados enEIR*/             
    @ServiceOrder       udtIdentifier,           
    @Recibio            char(32),          /*Persona que genera el EIR*/           
    @Danado             char(32), --Constante de Daños           
    @Varios             char(32),     --Constante; 'Dañado'           
    @Ninguno            char(32),             --Constante; 'Ninguno'            
    @Name               Char(32),             --Nombre del campo            
    @intReturn          udtIdentifier,         --Almacena el valor que retorna el sp de spGetCalathusMsg             
    @Booking            udtStringIdentifier,           
    @ContainerId        udtStringIdentifier,           
    @TypeId        udtIdentifier,             
    @SizeId             udtIdentifier,       
    @CategoryId         udtIdentifier,           
    @strType            udtStringIdentifier,            
    @strSizeId          udtStringIdentifier,              
    @straCategoryId     udtStringIdentifier, 
    @strCarrierLine     VARCHAR(255), 
    @strCarrierName     VARCHAR(255),
    @strAdmStatusSICREFIS 		VARCHAR(128),
    @strOpHistCommentsSICREFIS 	VARCHAR(256),
    @strAuthorizationSICREFIS	VARCHAR(32),
	@intCheckInUniversalId NUMERIC(18),
	@intExistdbCalathusWEB NUMERIC(18),
	@lint_IdSicrefis NUMERIC(18),
	@lstr_Sicrefissrv varchar(30)
            
                 
         
             
     if @@trancount = 0           
    begin           
        set chained off           
    end           
               
    set transaction isolation level 1            
               
    --Inicializa Constantes           
    SELECT @Danado  = 'Dañado'           
    SELECT @Ninguno = 'Ninguno'           
    SELECT @Varios  = 'Varios'           
    SELECT @Steel   = '------'   
    SELECT @Seal    = ''
    SELECT @SealTem = ''
    SELECT @lint_IdSicrefis = 0--51901
    SELECT @lstr_Sicrefissrv= ' ' --'Salida por Ruta Federal'
           
    /*Valida si es Recepción o entrega de contenedor*/             
    SELECT  @strTipoMov=LTRIM(RTRIM(tblclsService.strServiceIdentifier)),           
            @strServiceName=tblclsService.strServiceName               
    FROM    tblclsEIR,              
      tblclsVisitContainer,              
            tblclsService             
    WHERE   ( tblclsEIR.intVisitId *= tblclsVisitContainer.intVisitId) and             
   ( tblclsVisitContainer.intServiceId *= tblclsService.intServiceId) and             
         ( tblclsEIR.strContainerId *= tblclsVisitContainer.strContainerId) and   
            ( ( tblclsEIR.intEIRId = @EIR ) )               
           
         
              
    /*Si EIR Pertenece a una Salida de Contenedor por Ruta Federal*/             
    IF rTrim(lTrim(@strTipoMov))='ENTLL' OR  rTrim(lTrim(@strTipoMov))='ENTV'            
    BEGIN    
  
        SELECT   top 1 @EIR=tblclsEIR.intEIRId,              
                 @UniversalId=tblclsEIR.intContainerUniversalId,        
              @TypeId = tblclsContainerISOCode.intContainerTypeId,       
                 @SizeId = tblclsContainerISOCode.intContainerSizeId,       
                 @CategoryId = tblclsContainerInventory.intContainerCategoryId,
                 @Date=tblclsEIR.dtmEIRCreationStamp,              
                 @CustomBroker=tblclsCompany_a.strCompanyName,              
                 @Customer=tblclsCompany_b.strCompanyName,              
                 @Vessel=tblclsVessel.strVesselName,            
                 @VesselN=tblclsVesselVoyage.strVesselVoyageNumIdentifier,
                 @ShippingLine=tblclsCOperator.strCompanyName,              
                 @Tare=tblclsContainerType.decContainerTypeTare,              
                 @Comments=tblclsEIR.strEIRComments,           
                 @Destino=tblclsPort.strPortName,             
                 @Position=tblclsContainerInventory.strContainerInvBlockIdentifier,           
                 @Weight=tblclsContainerInventory.decContainerInventoryWeight,              
                 @StatusPhysical=tblclsContainerPhysicalStatus.strContPhyStatDescription,           
                 @Recibio=tblclsEIR.strEIRCreatedBy,           
                 @EIRFolio=tblclsEIR.intEIRFolio,           
                 @ServiceId=tblclsVisitContainer.intServiceOrderId,
                 @ContainerId=tblclsEIR.strContainerId,              
                 @Booking=tblclsContainerDelivery.strBookingId , 
                 @VisitId=tblclsVisitContainer.intVisitId,
                 @Temperature = tblclsEIR.decContainerInvOptTemp

  
        FROM tblclsEIR,              
             tblclsVisitContainer,              
             tblclsContainerDelivery,         
             tblclsCompany tblclsCompany_a,              
             tblclsCompanyEntity tblclsCompanyEntity_a,            
             tblclsCompany tblclsCompany_b,              
             tblclsCompanyEntity tblclsCompanyEntity_b,    
             tblclsVesselVoyage,              
             tblclsVessel,              
             --tblclsConsigmentAgency,              
             tblclsCompany tblclsCOperator,              
             tblclsCompanyEntity tblclsCEntity_Operator,       
             tblclsContainerType,              
             tblclsContainerInventory,              
             tblclsPort,       
             tblclsContainer,       
             tblclsContainerISOCode,                 
             tblclsContainerPhysicalStatus             
       WHERE ( tblclsCompany_a.intCompanyId =* tblclsCompanyEntity_a.intCompanyId) and    
             ( tblclsContainerDelivery.intContDelRequiredById *= tblclsCompanyEntity_a.intCompanyEntityId) and             
             ( tblclsContainerDelivery.intContDelRequiredTypeId *= tblclsCompanyEntity_a.intCustomerTypeId) and             
             ( tblclsCompany_b.intCompanyId =* tblclsCompanyEntity_b.intCompanyId) and             
             ( tblclsContainerDelivery.intContDelInvoiceToId *= tblclsCompanyEntity_b.intCompanyEntityId) and             
             ( tblclsContainerDelivery.intContDelInvoiceToTypeId *= tblclsCompanyEntity_b.intCustomerTypeId) and             
             ( tblclsContainerInventory.intContainerInvOperatorId  *= tblclsCEntity_Operator.intCompanyEntityId )and       
             ( tblclsContainerInventory.intContainerInvOperatorTypeId *= tblclsCEntity_Operator.intCustomerTypeId )and       
             ( tblclsCEntity_Operator.intCompanyId *=  tblclsCOperator.intCompanyId ) and       
             /*( tblclsConsigmentAgency.intConsigAgencyId =* tblclsVesselVoyage.intConsigAgencyId) and             
             ( tblclsConsigmentAgency.intCompanyId *= tblclsCompany_c.intCompanyId) and      */       
             ( tblclsVesselVoyage.intVesselId *= tblclsVessel.intVesselId) and             
             ( tblclsContainerType.intContainerTypeId =* tblclsEIR.intContainerTypeId) and             
             ( tblclsVesselVoyage.intVesselVoyageId =* tblclsContainerDelivery.intVesselVoyageId) and             
             ( tblclsContainerInventory.intContPhyStatId *= tblclsContainerPhysicalStatus.intContPhyStatId) and             
             ( tblclsContainerInventory.intContainerUniversalId =* tblclsEIR.intContainerUniversalId ) and             
             ( tblclsEIR.intVisitId *= tblclsVisitContainer.intVisitId ) and             
             ( tblclsEIR.intContainerUniversalId *= tblclsVisitContainer.intContainerUniversalId ) and             
             ( tblclsVisitContainer.intServiceOrderId *= tblclsContainerDelivery.intContainerDeliveryId ) and             
        ( tblclsContainerInventory.strContainerInvFinalPortId *= tblclsPort.strPortId ) and             
             ( tblclsContainerInventory.strContainerId *= tblclsContainer.strContainerId ) and       
             ( tblclsContainer.intContISOCodeId *= tblclsContainerISOCode.intContISOCodeId )and       
             ( tblclsEIR.intEIRId = @EIR)              
             /*( ( tblclsEIR.intVisitId = @VisitId  ) AND             
             ( tblclsEIR.strContainerId = @ContainerId ) ) */           
         
         SELECT @strCarrierLine=tblclsCarrierLine.strCarrierLineIdentifier +'/' + tblclsCarrierLine.strCarrierLineName
         FROM tblclsVisit V
         	 JOIN tblclsCarrierLine ON tblclsCarrierLine.intCarrierLineId=V.intCarrierLineId
         	 --JOIN tblclsCompany ON tblclsCompany.intCompanyId=tblclsCarrierLine.intCarrierLineId
	     WHERE V.intVisitId=@VisitId

        SELECT @strCarrierName=V.strVisitDriver 
		FROM tblclsVisit V 
		WHERE V.intVisitId=@VisitId 
               
        --Inicializa la varible @SealTem           
        select @SealTem = ''  
        select @Seal = ''         
           
        declare aux_crsr cursor
		 for 
		 SELECT isnull(tblclsEIRContainerSeal.strEIRContSealNumber, 'Sin Sellos') + ',' 
		 FROM tblclsEIR, 
			 tblclsEIRContainerSeal 
		 WHERE tblclsEIRContainerSeal.intEIRId=* tblclsEIR.intEIRId and 
		 	tblclsEIR.intEIRId = @EIR 
		 for read only
		 open aux_crsr
		 
		 while 1=1
		 begin
			 fetch aux_crsr into @s_fetch 
			 if @@sqlstatus <> 0 break
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
            SELECT @Seal = 'No hay sellos.'             
            --Modifica el mensaje, según el Idioma 
            --EXECUTE @intReturn=spGetCalathusMsg  20125, @Seal output          
                 
                
        --Inicializa la variable ImoTem           
        SELECT @ImoTem = '' 
        IF EXISTS(SELECT * FROM tblIMOCode_EIR WHERE tblIMOCode_EIR.intEIRId = @EIR )  
        BEGIN          
            --Obtiene la listade Impos del contenedor           
            SELECT @ImoTem = @ImoTem + ISNULL(tblclsIMOCode.strIMOCodeDescription,'') + ','            
            FROM tblIMOCode_EIR,              
                 tblclsIMOCode             
           WHERE ( tblclsIMOCode.intIMOCodeId = tblIMOCode_EIR.intIMOCodeId ) and             
                 ( tblIMOCode_EIR.intEIRId = @EIR)             
                                                
       END                         
     
            --Depura la Cadena           
            IF char_length (rtrim(@ImoTem)) > 0              
                SELECT @IMO = substring (@ImoTem,1,(char_length (rtrim(@ImoTem)) - 1))             
            ELSE           
             SELECT @IMO = 'No hay IMOS.'           
                --Modifica el mensaje, según el Idioma           
                --EXECUTE spGetCalathusMsg  20125, @IMO output      
               
        --Inicializa la variable de productos       
        SELECT @Product= ''       
        SELECT  @Contar=count(*)            
        FROM    tblclsContainerInventory Inventory,                
       tblclsContainerProduct CProduct,                
                tblclsProduct  Product             
        WHERE   ( CProduct.intContainerUniversalId =* Inventory.intContainerUniversalId ) and               
                ( Product.intProductId =* CProduct.intProductId ) and               
                 ( ( Inventory.intContainerUniversalId= @UniversalId) )             
               
        --Valida el numero de productos que tiene el Contenedor           
        IF @Contar=1            
        BEGIN 
            SELECT  @Product = @Product + Product.strProductName    +      ',' 
            FROM    tblclsContainerInventory Inventory,                
                    tblclsContainerProduct CProduct,                
                    tblclsProduct  Product    
            WHERE   ( CProduct.intContainerUniversalId =* Inventory.intContainerUniversalId ) and               
                    ( Product.intProductId =* CProduct.intProductId ) and               
                    ( ( Inventory.intContainerUniversalId= @UniversalId) )             
        END           
           
 
         --Obtiene el nombre del campo Varios        
          /*       execute @intReturn=spGetControlName  @ControlName='sp_Varios', @Name=@Name output           
        SELECT @Varios=@Name  */      
        IF @Contar > 1           
            SELECT @Product='Varios' 
           
        --Obtiene el nombre del campo Niguno          
        /*        execute @intReturn=spGetControlName  @ControlName='sp_Ninguno', @Name=@Name output           
         SELECT @Ninguno=@Name  */         
        IF @Contar = 0     
           SELECT @Product='Ninguno'    
 
    
               
        --Obtiene el numero de pedimento que esta asociado a este contenedor           
        SELECT  @Pedimento = @Pedimento + tblclsDocument.strDocumentFolio   + ','          
        FROM tblclsContainerInventory,              
                tblclsContainerInventoryDoc,              
                tblclsDocument,              
                tblclsDocumentType             
        WHERE   ( tblclsContainerInventory.intContainerUniversalId *= tblclsContainerInventoryDoc.intContainerUniversalId) and             
                ( tblclsContainerInventoryDoc.intDocumentId *= tblclsDocument.intDocumentId) and             
                ( tblclsDocument.intDocumentTypeId *= tblclsDocumentType.intDocumentTypeId) and             
                ( ( tblclsContainerInventory.intContainerUniversalId = @UniversalId) AND             
                ( tblclsDocumentType.strDocumentTypeIdentifier= 'PIMPO' ) )           
                  
        --Depura la Cadena           
        IF char_length (rtrim(@Pedimento)) > 0              
            SELECT @Pedimento = substring (@Pedimento,1,(char_length (rtrim(@Pedimento)) - 1))             
        ELSE           
            SELECT @Pedimento = 'No hay Pedimentos.'          
            --Modifica el mensaje, según el Idioma           
            --EXECUTE spGetCalathusMsg  20125, @Pedimento output             
                               
        
        --Calcula el peso Neto del producto que se encuentra almacenado en el contenedor           
        SELECT @GrossWeight= ISNULL(@Weight,0) + ISNULL(@Tare,0)                   
           
        --Obtiene el numero de Daños que tiene el contenedor           
        SELECT  @Contar=COUNT(tblclsEIRContainerDamage.intEIRContainerDamageId)           
        FROM    tblclsEIR,              
                tblclsEIRContainerDamage             
        WHERE   ( tblclsEIR.intEIRId = tblclsEIRContainerDamage.intEIRId ) and             
                ( tblclsEIR.intEIRId = @EIR)               
                   
                                 
        --Valida que el Numero de Daños           
        IF isnull(@Contar,0) > 0            
          BEGIN           
            --Obtiene el nombre del campo       
           -- execute dbo.spGetControlName  @ControlName='sp_Dañado', @Danado=@Danado output           
            SELECT @Steel='Dañado'               
        END           
 
               
  END --Fin del if que valida el tipo de servicio                
               
           
    ELSE              
    IF rTrim(lTrim(@strTipoMov))='RECV' OR  rTrim(lTrim(@strTipoMov))='RECLL'  OR rTrim(lTrim(@strTipoMov))='RECVOS'   OR  rTrim(lTrim(@strTipoMov))='RECAUTHO'
    BEGIN           
        SELECT top 1 @EIR=tblclsEIR.intEIRId,              
                @EIRFolio=tblclsEIR.intEIRFolio,              
                @UniversalId=tblclsEIR.intContainerUniversalId,           
                @TypeId = tblclsEIR.intContainerTypeId,           
                @SizeId = tblclsEIR.intContainerSizeId, 
                @CategoryId = tblclsEIR.intContainerCategoryId,                  
                @Comments=tblclsEIR.strEIRComments,              
                @Date=tblclsEIR.dtmEIRCreationStamp,       
                @Tare=tblclsContainer.decContainerTare,              
                @CustomBroker=tblclsCompany_a.strCompanyName,              
                @Customer=tblclsCompany_b.strCompanyName,              
                @Weight=tblclsContainerRecepDetail.decContRecDetailWeight,      
                @ShippingLine=tblclsCompany_Operator.strCompanyName,              
                @Vessel=tblclsVessel.strVesselName,              
                @VesselN=tblclsVesselVoyage.strVesselVoyageNumIdentifier, 
                 @Destino=tblclsPort.strPortName,              
                @StatusPhysical=tblclsContainerRecepDetail.blnContRecDetailIsFull,             
                @ServiceId=tblclsVisitContainer.intServiceOrderId,    
                 @ContainerId=tblclsEIR.strContainerId,             
                @Booking=tblclsContainerRecepDetail.strBookingId,           
                @Recibio=tblclsEIR.strEIRCreatedBy  , 
				@VisitId=tblclsVisitContainer.intVisitId    ,
				@Temperature = tblclsEIR.decContainerInvOptTemp
				
        FROM tblclsEIR,              
             tblclsVisitContainer,              
            tblclsContainerReception,              
             tblclsVessel,              
             tblclsVesselVoyage,              
             tblclsContainerType,              
             tblclsCompany tblclsCompany_a,           
             tblclsCompanyEntity tblclsCompanyEntity_a,              
             tblclsCompany tblclsCompany_b,              
             tblclsCompanyEntity tblclsCompanyEntity_b,              
             tblclsContainerRecepDetail,  
             tblclsCompany tblclsCompany_Operator,           
			 tblclsCompanyEntity  tblclsCEntityOperator,           
			 tblclsContainer,               
             tblclsPort             
            WHERE   ( tblclsEIR.strContainerId = tblclsVisitContainer.strContainerId) and       
                    ( tblclsEIR.intVisitId = tblclsVisitContainer.intVisitId ) and              
                    ( tblclsVisitContainer.intServiceOrderId *= tblclsContainerReception.intContainerReceptionId ) and
                    ( tblclsEIR.intEIRId = tblclsContainerRecepDetail.intEIRId) and    
                    ( tblclsEIR.strContainerId = tblclsContainerRecepDetail.strContainerId) and             
                    ( tblclsContainerType.intContainerTypeId =* tblclsEIR.intContainerTypeId) and             
                    ( tblclsVessel.intVesselId =* tblclsVesselVoyage.intVesselId ) and             
                    ( tblclsContainerReception.intVesselVoyageId *= tblclsVesselVoyage.intVesselVoyageId ) and             
                    ( tblclsCompany_a.intCompanyId =* tblclsCompanyEntity_a.intCompanyId ) and             
                    ( tblclsContainerReception.intContRecepRequiredById *= tblclsCompanyEntity_a.intCompanyEntityId ) and             
                    ( tblclsContainerReception.intContRecepRequiredTypeId *= tblclsCompanyEntity_a.intCustomerTypeId ) and         
                    ( tblclsCompany_b.intCompanyId =* tblclsCompanyEntity_b.intCompanyId ) and             
                    ( tblclsContainerReception.intContRecepInvoiceToId *= tblclsCompanyEntity_b.intCompanyEntityId ) and          
                    ( tblclsContainerReception.intContRecepInvoiceToTypeId *= tblclsCompanyEntity_b.intCustomerTypeId ) and             
                    ( tblclsContainerReception.strContRecepFinalPortId *= tblclsPort.strPortId ) and             
                    ( tblclsContainerRecepDetail.intContRecDetailOperatorTypeId *= tblclsCEntityOperator.intCustomerTypeId) and	           
                    ( tblclsContainerRecepDetail.intContRecDetailOperatorId *= tblclsCEntityOperator.intCompanyEntityId)	 and           
                    ( tblclsCEntityOperator.intCompanyId  *= tblclsCompany_Operator.intCompanyId )	and           
                    (tblclsEIR.strContainerId =  tblclsContainer.strContainerId ) and           
                    ( tblclsEIR.intEIRId = @EIR) 
					/*LISLAS Enero 2009: Se estaban generando un producto cartesiano con la tabla tblclsContainerRecepDetail 
					y por consecuencia se detecto que mostraba la línea naviera mal  */
					
					/*            WHERE   ( tblclsContainerType.intContainerTypeId =* tblclsEIR.intContainerTypeId) and             
					                    ( tblclsVessel.intVesselId =* tblclsVesselVoyage.intVesselId ) and             
					                    ( tblclsContainerRecepDetail.intContainerReceptionId =* tblclsContainerReception.intContainerReceptionId ) and             
					                    ( tblclsContainerReception.intVesselVoyageId *= tblclsVesselVoyage.intVesselVoyageId ) and             
					                    ( tblclsCompany_a.intCompanyId =* tblclsCompanyEntity_a.intCompanyId ) and             
					               ( tblclsContainerReception.intContRecepRequiredById *= tblclsCompanyEntity_a.intCompanyEntityId ) and             
					                    ( tblclsContainerReception.intContRecepRequiredTypeId *= tblclsCompanyEntity_a.intCustomerTypeId ) and         
					                    ( tblclsCompany_b.intCompanyId =* tblclsCompanyEntity_b.intCompanyId ) and             
					                    ( tblclsContainerReception.intContRecepInvoiceToId *= tblclsCompanyEntity_b.intCompanyEntityId ) and          
					              ( tblclsContainerReception.intContRecepInvoiceToTypeId *= tblclsCompanyEntity_b.intCustomerTypeId ) and             
					                    ( tblclsEIR.strContainerId *= tblclsVisitContainer.strContainerId) and       
					                 ( tblclsEIR.intVisitId *= tblclsVisitContainer.intVisitId ) and             
					                    ( tblclsVisitContainer.intServiceOrderId *= tblclsContainerReception.intContainerReceptionId ) and             
					                    ( tblclsContainerReception.strContRecepFinalPortId *= tblclsPort.strPortId ) and             
					                    ( tblclsContainerRecepDetail.intContRecDetailOperatorTypeId *= tblclsCEntityOperator.intCustomerTypeId) and	           
					                    ( tblclsContainerRecepDetail.intContRecDetailOperatorId *= tblclsCEntityOperator.intCompanyEntityId)	 and           
					                    ( tblclsCEntityOperator.intCompanyId  *= tblclsCompany_Operator.intCompanyId )	and           
					                    (tblclsEIR.strContainerId =  tblclsContainer.strContainerId ) and           
					                    ( tblclsEIR.intEIRId = @EIR)  */
					                    
     SELECT @strCarrierLine=tblclsCarrierLine.strCarrierLineIdentifier +'/' + tblclsCarrierLine.strCarrierLineName
     FROM tblclsVisit V
	 JOIN tblclsCarrierLine ON tblclsCarrierLine.intCarrierLineId=V.intCarrierLineId
	 --JOIN tblclsCompany ON tblclsCompany.intCompanyId=tblclsCarrierLine.intCarrierLineId
	 WHERE V.intVisitId=@VisitId

    SELECT @strCarrierName=V.strVisitDriver 
					 FROM tblclsVisit V 
					 WHERE V.intVisitId=@VisitId 
              
         --Inicializa la varible @SealTem     
        select @SealTem = ''        
        SELECT @Seal =  ''          
      
		declare aux_crsr cursor
		 for 
			 SELECT ISNULL(tblclsEIRContainerSeal.strEIRContSealNumber, 'Sin Sello') + ','
			 FROM tblclsEIR, 
			 tblclsEIRContainerSeal 
			 WHERE tblclsEIRContainerSeal.intEIRId=* tblclsEIR.intEIRId and 
			 tblclsEIR.intEIRId = @EIR
		 for read only
		 open aux_crsr
		 
		 while 1=1
		 begin
			 fetch aux_crsr into @s_fetch 
			 if @@sqlstatus <> 0 break
			 select @SealTem=@SealTem + @s_fetch
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
            SELECT @Seal = 'No hay sellos.'             
            --Modifica el mensaje, según el Idioma 
            --EXECUTE @intReturn=spGetCalathusMsg  20125, @Seal output                         
                 
                
        --Inicializa la variable ImoTem           
        SELECT @ImoTem = ''  
       IF EXISTS(SELECT * FROM tblIMOCode_EIR WHERE tblIMOCode_EIR.intEIRId = @EIR )    
        BEGIN       
            --Obtiene la listade Impos del contenedor           
            SELECT @ImoTem = @ImoTem + tblclsIMOCode.strIMOCodeDescription + ','            
            FROM tblIMOCode_EIR,              
                 tblclsIMOCode             
           WHERE ( tblclsIMOCode.intIMOCodeId = tblIMOCode_EIR.intIMOCodeId ) and             
                 ( tblIMOCode_EIR.intEIRId = @EIR)                 
                         
                   
            --Depura la Cadena           
            IF char_length (rtrim(@ImoTem)) > 0              
                SELECT @IMO= substring (@ImoTem,1,(char_length (rtrim(@ImoTem)) - 1))             
            ELSE           
                SELECT @IMO = 'No hay IMOS.'           
                --Modifica el mensaje, según el Idioma           
                --EXECUTE spGetCalathusMsg  20125, @IMO output            
        END                        
               
        SELECT @Contar=count( Product.strProductName     )        
            FROM tblclsContainerRecepProduct,         
				 tblclsProduct  Product              
            WHERE   ( tblclsContainerRecepProduct.intContainerReceptionId =@ServiceId) and         
                    ( Product.intProductId =* tblclsContainerRecepProduct.intProductId ) and               
                    ( tblclsContainerRecepProduct.strContainerId = @ContainerId)      
 
            
               
        --Valida el numero de productos que tiene el Contenedor           
        IF @Contar<> 0            
        BEGIN           
            SELECT @Product = @Product + Product.strProductName + ',' 
            FROM tblclsContainerRecepProduct,         
				 tblclsProduct  Product              
            WHERE   ( tblclsContainerRecepProduct.intContainerReceptionId =@ServiceId) and         
                    ( Product.intProductId =* tblclsContainerRecepProduct.intProductId ) and               
                    ( tblclsContainerRecepProduct.strContainerId = @ContainerId)          
           
                     
        END           
           
         --Obtiene el nombre del campo           
       /* execute @intReturn=spGetControlName  @ControlName='sp_Varios', @Name=@Name output           
        SELECT @Varios=@Name*/           
        IF @Contar > 1          
            SELECT @Product='Varios'      
           
        --Obtiene el nombre del campo           
   /*execute @intReturn=spGetControlName  @ControlName='sp_Ninguno', @Name=@Name output           
        SELECT @Ninguno=@Name*/           
        IF @Contar = 0            
        BEGIN      
            SELECT @Product='Ninguno' 
        END      
              
          
        --Obtiene el numero de pedimento que esta asociado a este contenedor           
        SELECT @Pedimento=' '           
                   
        --Calcula el peso Neto del producto que se encuentra almacenado en el contenedor           
        SELECT @GrossWeight= ISNULL(@Weight,0) + ISNULL(@Tare,0)                 
           
        --Obtiene el numero de Daños que tiene el contenedor           
        SELECT  @Contar=COUNT(tblclsEIRContainerDamage.intEIRContainerDamageId)           
      FROM    --tblclsEIR,              
                tblclsEIRContainerDamage             
        WHERE  -- ( tblclsEIR.intEIRId = tblclsEIRContainerDamage.intEIRId ) and             
                ( tblclsEIRContainerDamage.intEIRId = @EIR)        
                   
                    
        --Valida que el Numero de Daños           
        IF isnull(@Contar,0) > 0            
        BEGIN           
            --Obtiene el nombre del campo           
            --execute dbo.spGetControlName  @ControlName='sp_Dañado', @Danado=@Danado output           
            SELECT @Steel='Dañado'               
        END           
                  
                   
           
    END            
         
      
         --->>> 	
	--Obtiene el Tipo de Contenedor           
	SELECT @strType = strContainerTypeIdentifier from tblclsContainerType where intContainerTypeId = @TypeId                 
	--Obtiene el Tamaño   
	SELECT @strSizeId = strContainerSizeIdentifier from tblclsContainerSize where intContainerSizeId = @SizeId        
	--Obtien el estado fiscal del contenedor          
	IF @StatusPhysical='1'           
	BEGIN               
	    SELECT @StatusPhysical='Lleno'           
	    --execute dbo.spGetControlName  'sp_lleno', @StatusPhysical output        
	END           
        
	IF @StatusPhysical='0'           
	BEGIN           
	    SELECT @StatusPhysical='Vacío'           
	    --execute dbo.spGetControlName  'sp_vacio', @StatusPhysical output           
	end            
         
       	  
	SELECT @strTipoMov=tblclsService.strServiceDescription            
	FROM tblclsService            
	WHERE tblclsService.strServiceIdentifier=@strTipoMov        
	     
	select @strTipoMov=@strServiceName  
	
	--LISLAS ENERO 2016
	SELECT @intExistdbCalathusWEB = isnull(db_id('dbCalathusWEB'),0)
	
	--select  @intExistdbCalathusWEB = 0
	
	IF @intExistdbCalathusWEB > 0
	BEGIN
		
		--print 'hay web'
		
		SELECT @intCheckInUniversalId = dbCalathusWEB..tblclsContainerInventory.intCheckInUniversalId FROM dbCalathusWEB..tblclsContainerInventory
		WHERE dbCalathusWEB..tblclsContainerInventory.intContainerUniversalId = @UniversalId
		
		
		SELECT
		     @strAuthorizationSICREFIS 	= dbCalathusWEB..tblclsContOperationHistory.strContOperationHistAuth,   
		     @strOpHistCommentsSICREFIS = dbCalathusWEB..tblclsContOperationHistory.strContOperationHistComments,
		     @strAdmStatusSICREFIS 		=dbCalathusWEB..tblclsContainerAdmStatus.strContAdmStatusDescription  
		FROM dbCalathusWEB..tblclsContOperationHistory   
		     JOIN dbCalathusWEB..tblclsOperationType ON  dbCalathusWEB..tblclsOperationType.intOperationTypeId = dbCalathusWEB..tblclsContOperationHistory.intOperationTypeId 
		     JOIN (SELECT MAX(dbCalathusWEB..tblclsContOperationHistory.intConOperationHistId)AS intConOperationHistId FROM dbCalathusWEB..tblclsContOperationHistory WHERE dbCalathusWEB..tblclsContOperationHistory.intCheckInUniversalId = @intCheckInUniversalId) AS tblclsMaxContOperationHistory
		     	ON tblclsMaxContOperationHistory.intConOperationHistId = dbCalathusWEB..tblclsContOperationHistory.intConOperationHistId
		     JOIN dbCalathusWEB..tblclsContainerInventory ON dbCalathusWEB..tblclsContainerInventory.intCheckInUniversalId = dbCalathusWEB..tblclsContOperationHistory.intCheckInUniversalId
		     JOIN dbCalathusWEB..tblclsContainerAdmStatus ON dbCalathusWEB..tblclsContainerAdmStatus.intContAdmStatusId = dbCalathusWEB..tblclsContainerInventory.intContAdmStatusId
		    
		     
		  select @lint_IdSicrefis =   @lint_IdSicrefis 
		  select @lstr_Sicrefissrv =@lstr_Sicrefissrv 
		  
		  -- create table id
		  CREATE TABLE #tabsicrefis
		  (
		    strContainerId varchar(18) NULL,
		    intContainerUniversalId numeric(18) NULL,
		    intId numeric(18) NULL,
		    strService varchar(40) NULL
		  )
		  
		  INSERT INTO #tabsicrefis ( strContainerId, intContainerUniversalId ,  intId , strService  )
		  SELECT top 1 tblclsIdSICREFIS.strContainerId , tblclsIdSICREFIS.intContainerUniversalId , tblclsIdSICREFIS.intId , tblclsIdSICREFIS.strService
		  FROM 
				(
					 select 'Transferencia'as strService,
					  dbCalathusWEB..tblclsContainerInventory.strContainerId as strContainerId,
					  dbCalathusWEB..tblclsContainerInventory.intContainerUniversalId as intContainerUniversalId,
					  dbCalathusWEB..tblclsContTransItemCheckOut.intContainerTransferId as intId
					  from  dbCalathusWEB..tblclsContainerInventory 
					  join  dbCalathusWEB..tblclsContTransItemCheckOut on dbCalathusWEB..tblclsContainerInventory.intCheckInUniversalId = dbCalathusWEB..tblclsContTransItemCheckOut.intCheckInUniversalId
					  where dbCalathusWEB..tblclsContTransItemCheckOut.strCTItemStatusIdentifier in ('PTRANS','TRANSFERED')
					
					 union  
					 
					 select 'Ruta Federal' as strService, 
					   dbCalathusWEB..tblclsContainerInventory.strContainerId as strContainerId,
					   dbCalathusWEB..tblclsContainerInventory.intContainerUniversalId as intContainerUniversalId,
					   dbCalathusWEB..tblclsContainerReleaseItem.intContReleaseId as intId
					 from dbCalathusWEB..tblclsContainerInventory 
					 join dbCalathusWEB..tblclsContainerReleaseItem on dbCalathusWEB..tblclsContainerReleaseItem.intCheckInUniversalId = dbCalathusWEB..tblclsContainerInventory.intCheckInUniversalId
					 left join dbCalathusWEB..tblclsOperationStatus on    dbCalathusWEB..tblclsOperationStatus.intOperationStatusId = dbCalathusWEB..tblclsContainerReleaseItem.intOperationStatusId 
					where dbCalathusWEB..tblclsOperationStatus.strOperationStatusIdentifier in ('AUT','TER')
										
				 ) as tblclsIdSICREFIS
				where tblclsIdSICREFIS.intContainerUniversalId =  @UniversalId	     
		     
		     --- obtener la informacion  que se inserto en la tabla recien creada
		     SELECT   @lstr_Sicrefissrv  = #tabsicrefis.strService
		            , @lint_IdSicrefis   = #tabsicrefis.intId
		     FROM  #tabsicrefis 
		     		    
		    --  SELECT MAX
		    -- select @lint_IdSicrefis =   @lint_IdSicrefis 
		    
		    --  select @lstr_Sicrefissrv =@lstr_Sicrefissrv 
		  
		  DROP TABLE #tabsicrefis
	END	
	
	
	--ELSE
	-- BEGIN
	--    PRINT 'no hay sicrefis'
	-- END 
------------------             
  
SELECT           
    @ContainerId as ContainerId,           
   @UniversalId as UniversalId,           
    @ServiceId as ServiceId,             
    @strTipoMov as strTipoMov,            
    @EIR as EIR,           
    @EIRFolio as EIRFolio,              
    @StatusPhysical as StatusPhysical,           
    @Date as Date, 
    ISNULL(@Weight,0) as Weight,                   
    ISNULL(@Tare,0) as Tare,                     
    ISNULL(@GrossWeight,0) as GrossWeight,              
    @Steel as Steel,                    
    @ShippingLine as ShippingLine,             
    @Vessel as Vessel,                   
    @VesselN as VesselN,                  
  @Destino as Destino,                  
    @CustomBroker as CustomBroker,             
    @Customer as Customer,                 
    @Position as Position,              
    @Product Product,                  
    @IMO as IMO,                      
    @Seal as Seal,                     
--    convert(varchar(10),@Temperature) as Temperature,              
        '-18.99' as Temperature,              
    @Pedimento as Pedimento,                
    @Comments as Comments,           
    @Recibio as Recibio,           
    @Booking as Booking,  
    @strType as Tipo,  
    @strSizeId as strSizeId, 
	@strCarrierLine as strCarrierLine, 
	@strCarrierName as strCarrierName,
	@strAdmStatusSICREFIS as strAdmStatusSICREFIS,
	@strOpHistCommentsSICREFIS as strOpHistCommentsSICREFIS,
    @strAuthorizationSICREFIS as strAuthorizationSICREFIS
    ,@lint_IdSicrefis AS IdSicrefis
    ,@lstr_Sicrefissrv as strServiceSicrefis

