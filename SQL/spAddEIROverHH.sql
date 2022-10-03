/*
Highlight and execute the following statement to drop the procedure
before executing the create statement.

DROP PROCEDURE dbo.spAddEIROverHH

*/

CREATE PROCEDURE spAddEIROverHH  @intEIRId udtIdentifier,
							   @intContainerPositionId udtIdentifier,
							   @decEIRContainerOverQuantity udtDecimal,
                               @strUser udtStringIdentifier

as


DECLARE @strError udtStringIdentifier
DECLARE @intEIRContainerOversizeId udtIdentifier
DECLARE @strEIRContOverDescription udtStringIdentifier


IF NOT EXISTS(SELECT intEIRContainerOversizeId FROM tblclsEIRContainerOversize WHERE intEIRId = @intEIRId and intContainerPositionId = @intContainerPositionId)
BEGIN
	
	SELECT @intEIRContainerOversizeId = ISNULL(MAX(intEIRContainerOversizeId),0) + 1 FROM tblclsEIRContainerOversize
	BEGIN TRAN
	INSERT INTO tblclsEIRContainerOversize ( 
	intEIRContainerOversizeId, 
	intEIRId, 
	intContainerPositionId, 
	strEIRContOverDescription, 
	decEIRContainerOverQuantity, 
	dtmEIRContOverCreationStamp, 
	strEIRContainerOverCreatedBy, 
	dtmEIRContOverLastModified, 
	strEIRContOverLastModifiedBy )
	values ( 
	@intEIRContainerOversizeId, 
	@intEIRId, 
	@intContainerPositionId, 
	@strEIRContOverDescription, 
	@decEIRContainerOverQuantity, 
	GETDATE(), 
	@strUser, 
	GETDATE(), 
	@strUser)
	
	IF @@Error = 1  --Validacion al Insertar el Registro   
	BEGIN   
	  ROLLBACK TRAN    --Aborta los Cambios   
	  SELECT @strError = '>>--ERROR: Al agregar la Sobredimensión'
	  RETURN 1  --ERROR: Al Ingresar el Contenedor a Inventario   
	END 
	COMMIT TRAN 
END 
ELSE 
	SELECT @strError = 'La Sobredimensión ya se había ingresado al EIR'

SELECT @strError  strError

