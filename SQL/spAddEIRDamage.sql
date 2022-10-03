/*
Highlight and execute the following statement to drop the procedure
before executing the create statement.

DROP PROCEDURE dbo.spAddEIRDamage

*/

CREATE PROCEDURE spAddEIRDamage  @intEIRId udtIdentifier,
							   @strContDamTypeId udtStringIdentifier,
							   @strContainerPositionId udtStringIdentifier,
							   @decEIRContDamQuantity udtDecimal,
                               @strUser udtStringIdentifier

as

DECLARE @intEIRContainerDamageId udtIdentifier
DECLARE @strError udtStringIdentifier
DECLARE @intContDamTypeId udtIdentifier
DECLARE @intContainerPositionId udtIdentifier
declare @strEIRContDamDescription udtStringIdentifier


SELECT 	@intContDamTypeId = intContDamTypeId,
		@strEIRContDamDescription =  strContDamTypeDescription  
FROM 	tblclsContainerDamageType
WHERE  	strContDamTypeIdentifier = @strContDamTypeId

SELECT @intContainerPositionId = intContainerPositionId
from dbo.tblclsContainerPosition
WHERE strContainerPosIdentifier = @strContainerPositionId

IF NOT EXISTS(SELECT intEIRContainerDamageId FROM tblclsEIRContainerDamage WHERE intEIRId = @intEIRId AND intContDamTypeId = @intContDamTypeId AND intContainerPositionId = @intContainerPositionId )
BEGIN
	
	SELECT @intEIRContainerDamageId = ISNULL(MAX(intEIRContainerDamageId),0)+ 1 FROM tblclsEIRContainerDamage
	BEGIN TRAN
	insert into dbo.tblclsEIRContainerDamage ( 
	intEIRContainerDamageId, 
	intEIRId, 
	intContDamTypeId, 
	intContainerPositionId, 
	strEIRContDamDescription, 
	decEIRContDamQuantity, 
	dtmEIRContDamCreationStamp, 
	strEIRContDamCreatedBy, 
	dtmEIRContDamLastModified, 
	strEIRContDamLastModifiedBy )
	values ( 
	@intEIRContainerDamageId, 
	@intEIRId, 
	@intContDamTypeId, 
	@intContainerPositionId, 
	@strEIRContDamDescription, 
	@decEIRContDamQuantity, 
	GETDATE(), 
	@strUser, 
	GETDATE(), 
	@strUser )
	
	IF @@Error = 1  --Validacion al Insertar el Registro   
	BEGIN   
	  ROLLBACK TRAN    --Aborta los Cambios   
	  SELECT @strError = '>>--ERROR: Al agregar el daño'   
	  RETURN 1  --ERROR: Al Ingresar el Contenedor a Inventario   
	END 
	COMMIT TRAN 
END 
ELSE 
	SELECT @strError = 'El daño ya se había ingresado al EIR'

SELECT @strError strError
	
	
	



