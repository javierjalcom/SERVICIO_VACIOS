/*
Highlight and execute the following statement to drop the procedure
before executing the create statement.

DROP PROCEDURE spAddInvOverDim

*/

CREATE PROCEDURE spAddInvOverDim  @intUniversalId udtIdentifier,
							   @intContainerPositionId udtIdentifier,
							   @decInvContainerOverQuantity udtDecimal,
                               @strUser udtStringIdentifier

as


DECLARE @strError udtStringIdentifier
DECLARE @intInvContainerOversizeId udtIdentifier
DECLARE @strInvContOverDescription udtStringIdentifier
DECLARE @Comments udtStringIdentifier
DECLARE @StatErrSP      INTEGER 


	IF NOT EXISTS(SELECT intContInvOverId FROM tblclsContainerInventoryOver WHERE intContainerUniversalId = @intUniversalId and intContainerPositionId = @intContainerPositionId)
	BEGIN
		
			SELECT @intInvContainerOversizeId = ISNULL(MAX(intContInvOverId),0) + 1 FROM tblclsContainerInventoryOver
			
			BEGIN TRAN
			
			INSERT INTO tblclsContainerInventoryOver
				(intContInvOverId, intContainerUniversalId, intContainerPositionId, strContInvOverDescription,
				 decContInvOverQuantity, dtmContInvOverCreationStamp, strContInvOverCreatedBy, dtmContInvOverLastModified, strContInvOverLastModifiedBy)
			VALUES 
				( @intInvContainerOversizeId, @intUniversalId , @intContainerPositionId , @strInvContOverDescription,
				  @decInvContainerOverQuantity ,GETDATE() , @strUser,GETDATE() , @strUser)
		
		
			IF @@Error = 1  --Validacion al Insertar el Registro   
			BEGIN   
			  ROLLBACK TRAN    --Aborta los Cambios   
			  SELECT @strError = '>>--ERROR: Al agregar la Sobredimensión'
			  RETURN 1  --ERROR: Al Ingresar el Contenedor a Inventario   
			END 
			COMMIT TRAN 
			
		-- registrar en el historico 
		
		----------
		
         EXECUTE @StatErrSP = spUpdateHistoryOversize @intUniversalId,  @strInvContOverDescription, @intContainerPositionId, @decInvContainerOverQuantity , @Comments , @strUser          
        
		
       	IF @StatErrSP  = 1 --Validacion del SP 
	          BEGIN 
	       	    SELECT @strError = '>>--ERROR: Al guardar historico sobredimensiones '
	            RETURN (1) --ERROR: Al Insertar en el Inventario   
	     END 
		
		
	END 
	ELSE 
		SELECT @strError = 'La Sobredimensión ya se había ingresado '
	
	SELECT @intInvContainerOversizeId  intInvContainerOversizeId

