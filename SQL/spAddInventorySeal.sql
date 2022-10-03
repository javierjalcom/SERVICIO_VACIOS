/*
Highlight and execute the following statement to drop the procedure
before executing the create statement.

DROP PROCEDURE spAddInventorySeal

*/

CREATE PROCEDURE spAddInventorySeal  @intContainerUniversal udtIdentifier,
							   @strContSealNumber udtStringIdentifier,
							   @blnContainerSealApTerm udtIdentifier,
							   @strSealComments udtStringIdentifier,
                               @strUser udtStringIdentifier

as

DECLARE @intContainerInvSealId udtIdentifier
DECLARE @strError udtStringIdentifier
DECLARE @StatErrSP      INTEGER 


IF NOT EXISTS(SELECT tblclsContainerSeal.strContainerSealNumber FROM tblclsContainerSeal WHERE intContainerUniversalId = @intContainerUniversal AND strContainerSealNumber = @strContSealNumber )
BEGIN
	
	SELECT @intContainerInvSealId = ISNULL(MAX(intContainerSealId),0)+1 FROM tblclsContainerSeal
		
	BEGIN TRAN
	
	INSERT INTO tblclsContainerSeal
	(intContainerSealId, intContainerUniversalId, strContainerSealNumber, blnContainerSealApTerm, 
	strContainerSealComments, dtmContainerSealCreationStamp, strContainerSealCreatedBy, 
	dtmContainerSealLastModified, strContainerSealLastModifiedBy)
	VALUES 
		( @intContainerInvSealId , @intContainerUniversal , @strContSealNumber, @blnContainerSealApTerm ,
		 @strSealComments, GETDATE(), @strUser,GETDATE() , @strUser
		)
		
	
	IF @@Error = 1  --Validacion al Insertar el Registro   
	BEGIN   
	  ROLLBACK TRAN    --Aborta los Cambios   
	  SELECT @strError = '>>--ERROR: Al guardar sello'
	  RETURN 1  --ERROR: Al Ingresar el Contenedor a Inventario   
	END 
	COMMIT TRAN 
	
	---llamar al  historico de sellos
	
	EXECUTE @StatErrSP = spUpdateHistorySeal @intContainerUniversal, @strContSealNumber , @strSealComments , @strUser
     IF @StatErrSP  = 1 --Validacion del SP 
        BEGIN 
       	  SELECT @strError = '>>--ERROR: Al guardar historico sellos '
          RETURN (1) --ERROR: Al Insertar en el Inventario   
        END  
	
END 
ELSE 
	SELECT @strError = 'El sello ya se había ingresado al contenedor'

SELECT @intContainerInvSealId intContainerInvSealId

