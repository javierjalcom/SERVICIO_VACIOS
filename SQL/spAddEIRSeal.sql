/*
Highlight and execute the following statement to drop the procedure
before executing the create statement.

DROP PROCEDURE dbo.spAddEIRSeal

*/

CREATE PROCEDURE spAddEIRSeal  @intEIRId udtIdentifier,
							   @strEIRContSealNumber udtStringIdentifier,
							   @blnEIRContSealApTerm udtIdentifier,
                               @strUser udtStringIdentifier

as

DECLARE @intEIRContainerSealId udtIdentifier
DECLARE @strError udtStringIdentifier
IF NOT EXISTS(SELECT strEIRContSealNumber FROM tblclsEIRContainerSeal WHERE intEIRId = @intEIRId AND strEIRContSealNumber = @strEIRContSealNumber )
BEGIN
	
	SELECT @intEIRContainerSealId = ISNULL(MAX(intEIRContainerSealId),0)+1 FROM tblclsEIRContainerSeal
	BEGIN TRAN
	INSERT INTO tblclsEIRContainerSeal ( 
	intEIRContainerSealId, 
	intEIRId, 
	strEIRContSealNumber, 
	blnEIRContSealApTerm, 
	dtmEIRContSealCreationStamp, 
	strEIRContSealCreatedBy, 
	dtmEIRContSealLastModified, 
	strEIRContSealLastModifiedBy )
	VALUES ( 
	@intEIRContainerSealId, 
	@intEIRId, 
	@strEIRContSealNumber, 
	0, 
	GETDATE(), 
	@strUser, 
	GETDATE(), 
	@strUser)
	
	IF @@Error = 1  --Validacion al Insertar el Registro   
	BEGIN   
	  ROLLBACK TRAN    --Aborta los Cambios   
	  SELECT @strError = '>>--ERROR: Al Generar el EIR'   
	  RETURN 1  --ERROR: Al Ingresar el Contenedor a Inventario   
	END 
	COMMIT TRAN 
END 
ELSE 
	SELECT @strError = 'El sello ya se había ingresado al contenedor'

SELECT @strError strError
	
	
	



