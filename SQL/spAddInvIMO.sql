/*
Highlight and execute the following statement to drop the procedure
before executing the create statement.

DROP PROCEDURE spAddInvIMO

*/

CREATE PROCEDURE spAddInvIMO   @intUniversalId udtIdentifier,
							   @strIMOCodeIdentifier udtStringIdentifier,
							   @strUserName udtStringIdentifier							   
							   
as


DECLARE @strError udtStringIdentifier
DECLARE @intIMOCodeId udtIdentifier
DECLARE @StatErrSP udtIdentifier


SELECT @intIMOCodeId = intIMOCodeId
FROM  tblclsIMOCode
WHERE strIMOCodeIdentifier = @strIMOCodeIdentifier


IF NOT EXISTS(SELECT intIMOCodeId FROM tblIMOCode_ContainerInventory WHERE intContainerUniversalId = @intUniversalId AND intIMOCodeId = @intIMOCodeId  )
BEGIN
	
	BEGIN TRAN
	
		INSERT INTO tblIMOCode_ContainerInventory
			(intIMOCodeId, intContainerUniversalId, dtmContIMOCodeCreationStamp, strContIMOCodeCreatedBy,
			 dtmContIMOCodeLastModified, strContIMOCodeLastModifiedBy)
		VALUES
		    (@intIMOCodeId, @intUniversalId  ,GETDATE()  , @strUserName ,
		     GETDATE() , @strUserName
			)
			
			
		IF @@Error = 1  --Validacion al Insertar el Registro   
		BEGIN   
		  ROLLBACK TRAN    --Aborta los Cambios   
		  SELECT @strError = '>>--ERROR: Al agregar el IMO'
		  RETURN 1  --ERROR: Al Ingresar el Contenedor a Inventario   
		END 
		COMMIT TRAN 
	
	--tambien llamar al historico de imos 
	
	-- registrar en el historico 		
		----------
 		EXECUTE @StatErrSP = spUpdateHistoryIMOCode  @intUniversalId , @intIMOCodeId , '' , @strUserName      		
		
       		IF @StatErrSP  = 1 --Validacion del SP 
		          BEGIN 
		       	    SELECT @strError = '>>--ERROR: Al guardar historico IMO '
		            RETURN (1) --ERROR: Al Insertar en el Inventario   
		     END 
	
	
END 

/*ELSE 
	SELECT @strError = "El IMO ya se había ingresado al EIR"

	select @strError strError
*/

