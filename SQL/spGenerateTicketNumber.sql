/*
Highlight and execute the following statement to drop the procedure
before executing the create statement.

DROP PROCEDURE spGenerateTicketNumber
  -- procedimiento que da de alta la tarja del master en el sistema 

*/

CREATE PROCEDURE spGenerateTicketNumber @aintServiceOrderId udtIdentifier,
                                        @aintShiftId udtIdentifier,
                                        @aintVerifierId udtIdentifier,
                                        @aintYVerifTicketFolio udtIdentifier,
                                        @astrYardBlockIdentifier udtStringIdentifier,
                                        @ablnYVerifTicketIsStuffing udtIdentifier,                                                                                
                                        @astrYVerifTicketComments udtStringIdentifier,                                       
                                        @astrInitalDate   udtStringIdentifier, -- @adtmYVerifTicketExecutionDate udtStringIdentifier,
                                        @astrFinalDate    udtStringIdentifier,                                          
                                        @strUser udtStringIdentifier

--- sp, usado en HH 
AS 
--										
  DECLARE @lintServiceId udtIdentifier,
          @lintYardVerifTicketId udtIdentifier,
          @lintServiceMovTypeId  udtIdentifier,
          @lintFiscalMovementId  udtIdentifier,
          @lintVesselVoyageId  udtIdentifier,
          @lintYVerifTicketRelatedId udtIdentifier,
          @lintYVerifTicketRelatedSeq udtIdentifier,
          @lintYVerifTicketRequiredById  udtIdentifier,
          @lintYVerifTicketReqByTypeId  udtIdentifier,
          @lintYVerifTicketInvoiceToId   udtIdentifier,
          @lintYVTicketInvoToTypeId udtIdentifier,
          @blnYVerifTicketReadOnly  udtIdentifier,
          @llng_TicketMaxRel  udtIdentifier,
          @llng_TicketCount   udtIdentifier
          

    -- valiar los argumentos 
 
 	    SELECT @aintServiceOrderId = ISNULL(@aintServiceOrderId,0)
	     
	     IF ( @aintServiceOrderId=0)
	       BEGIN
	         RETURN 0
	       END 
	       
 	    SELECT @aintShiftId = ISNULL(@aintShiftId,0)
   	    SELECT @aintVerifierId = ISNULL(@aintVerifierId,0)
   	    
 	    SELECT @astrYardBlockIdentifier = ISNULL(@astrYardBlockIdentifier,'')
   	    SELECT @ablnYVerifTicketIsStuffing = ISNULL(@ablnYVerifTicketIsStuffing,0)

   	    SELECT @astrYVerifTicketComments = ISNULL(@astrYVerifTicketComments,'')
   	    
   	    -- @astrInitalDate   udtStringIdentifier, -- @adtmYVerifTicketExecutionDate udtStringIdentifier,
        -- @astrFinalDate    udtStringIdentifier,    

 ------------------
 --- obtener la informacion de la SO
        
        SELECT @lintServiceId = tblclsServiceOrder.intServiceId,
        	   @lintServiceMovTypeId = tblclsServiceOrder.intServiceMovTypeId,
               @lintFiscalMovementId = tblclsServiceOrder.intFiscalMovementId ,
               @lintVesselVoyageId = tblclsServiceOrder.intServiceOrderVesselVoyageId,
               @lintYVerifTicketInvoiceToId =tblclsServiceOrder.intServiceOrderInvoiceToId,
               @lintYVTicketInvoToTypeId = tblclsServiceOrder.intServiceOrderInvoiceToTypeId,
               @lintYVerifTicketRequiredById = tblclsServiceOrder.intServiceOrderRequiredById,
               @lintYVerifTicketReqByTypeId = tblclsServiceOrder.intServiceOrderRequiredTypeId               
               
        FROM tblclsServiceOrder
        WHERE tblclsServiceOrder.intServiceOrderId = @aintServiceOrderId

        SELECT @blnYVerifTicketReadOnly =0         
         
         --- BUSCAR ASOCIADA               
           
           SELECT   @lintYVerifTicketRelatedId   = ISNULL(MAX(tblclsYardVerificationTicket.intYardVerifTicketId),0)
           FROM tblclsYardVerificationTicket
           WHERE tblclsYardVerificationTicket.intServiceOrderId = @aintServiceOrderId
 
           IF @lintYVerifTicketRelatedId >0 
            BEGIN
            
               SELECT @llng_TicketCount = ISNULL(COUNT(tblclsYardVerificationTicket.intServiceOrderId),0)
               FROM tblclsYardVerificationTicket
               WHERE tblclsYardVerificationTicket.intServiceOrderId = @aintServiceOrderId
               
               SELECT  @lintYVerifTicketRelatedSeq = @llng_TicketCount +1 
               
            END 


 -----------------

	BEGIN TRAN
	
		
		SELECT @lintYardVerifTicketId = ISNULL(MAX(intYardVerifTicketId),0) +1 FROM tblclsYardVerificationTicket
		         
		INSERT INTO tblclsYardVerificationTicket
			(intYardVerifTicketId, intShiftId, intServiceMovTypeId, intVerifierId, 
			intServiceId, intServiceOrderId, intFiscalMovementId, intVesselVoyageId, 
			strYardBlockIdentifier, intYVerifTicketFolio, blnYVerifTicketIsStuffing,
			intYVerifTicketRequiredById, intYVerifTicketReqByTypeId, intYVerifTicketInvoiceToId,
			intYVerifTicketInvoiceToTypeId, dtmYVerifTicketExecutionDate, intYVerifTicketRelatedId, 
			intYVerifTicketRelatedSeq, blnYVerifTicketReadOnly, strYVerifTicketComments, 
			dtmYVerifTicketCreationStamp, strYVerifTicketCreatedBy, dtmYVerifTicketLastModified, strYVerifTicketLastModifiedBy,
			dtmYVerifTicketInitialDate, dtmYVerifTicketFinalDate)
		VALUES 
			(@lintYardVerifTicketId, @aintShiftId , @lintServiceMovTypeId , @aintVerifierId ,
			 @lintServiceId , @aintServiceOrderId ,@lintFiscalMovementId ,@lintVesselVoyageId ,
			 @astrYardBlockIdentifier, @aintYVerifTicketFolio ,@ablnYVerifTicketIsStuffing ,
			 @lintYVerifTicketRequiredById , @lintYVerifTicketReqByTypeId ,@lintYVerifTicketInvoiceToId ,
			 @lintYVTicketInvoToTypeId ,@astrInitalDate , @lintYVerifTicketRelatedId ,
			 @lintYVerifTicketRelatedSeq ,0 , @astrYVerifTicketComments,
			 GETDATE() , @strUser , GETDATE(), @strUser ,
			 @astrInitalDate,@astrFinalDate)

	--Estatus del Insert   
				 
			IF @@Error = 1  --Validacion al Insertar el Registro   
			BEGIN   
			  ROLLBACK TRAN    --Aborta los Cambios   
			  SET @lintYardVerifTicketId = -1 
			  SELECT '>>--ERROR: Al Generar el Tarja'
			  RETURN 1  --ERROR: Al Ingresar el Contenedor a Inventario   
			END 
		COMMIT TRAN 
	
SELECT @lintYardVerifTicketId  lintYardVerifTicketId

