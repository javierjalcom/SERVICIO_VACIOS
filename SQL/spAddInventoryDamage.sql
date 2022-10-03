/*
Highlight and execute the following statement to drop the procedure
before executing the create statement.

DROP PROCEDURE spAddInventoryDamage

*/

CREATE PROCEDURE spAddInventoryDamage  @intUniversalId udtIdentifier,
							           @strContDamTypeId udtStringIdentifier,
							           @strContainerPositionId udtStringIdentifier,
							           @decInvContDamQuantity udtDecimal,
							           @strInvDamComments udtStringIdentifier,
							           @strUser udtStringIdentifier

as

DECLARE @intInvContainerDamageId udtIdentifier
DECLARE @strError udtStringIdentifier
DECLARE @intContDamTypeId udtIdentifier
DECLARE @intContainerPositionId udtIdentifier
declare @strInvContDamDescription udtStringIdentifier
DECLARE @StatErrSP      INTEGER 


SELECT 	@intContDamTypeId = intContDamTypeId,
		@strInvContDamDescription =  strContDamTypeDescription  
FROM 	tblclsContainerDamageType
WHERE  	strContDamTypeIdentifier = @strContDamTypeId

SELECT @intContainerPositionId = intContainerPositionId
from  tblclsContainerPosition
WHERE strContainerPosIdentifier = @strContainerPositionId



IF NOT EXISTS(SELECT intContInvDamId  FROM tblclsContainerInventoryDam WHERE tblclsContainerInventoryDam.intContainerUniversalId  = @intUniversalId AND tblclsContainerInventoryDam.intContDamTypeId = @intContDamTypeId AND tblclsContainerInventoryDam.intContainerPositionId = @intContainerPositionId )
BEGIN
	
	SELECT @intInvContainerDamageId = ISNULL(MAX(tblclsContainerInventoryDam.intContInvDamId),0)+ 1 FROM tblclsContainerInventoryDam
	BEGIN TRAN
	
	INSERT INTO  tblclsContainerInventoryDam
	(intContInvDamId, intContainerUniversalId, intContDamTypeId, intContainerPositionId, strContInvDamDescription,
	 decContInvDamQuantity, strContInvDamComments, dtmContInvDamCreationStamp, strContInvDamCreatedBy,
	  dtmContInvDamLastModified, strContInvDamLastModifiedBy)
	VALUES 
	(@intInvContainerDamageId, @intUniversalId , @intContDamTypeId ,@intContainerPositionId , @strInvContDamDescription , 
	@decInvContDamQuantity , @strInvDamComments ,GETDATE() , @strUser, GETDATE() , @strUser)
	
	IF @@Error = 1  --Validacion al Insertar el Registro   
	BEGIN   
	  ROLLBACK TRAN    --Aborta los Cambios   
	  SELECT @strError = '>>--ERROR: Al agregar el daño'
	  RETURN 1  --ERROR: Al Ingresar el Contenedor a Inventario   
	END 
	COMMIT TRAN 
	
	
	---llamar al  historico de daños
		
	 EXECUTE @StatErrSP = spUpdateHistoryDamage @intUniversalId , @intContDamTypeId,  @strInvContDamDescription, @intContainerPositionId , @decInvContDamQuantity , @strInvDamComments,  @strUser
	
       IF @StatErrSP  = 1 --Validacion del SP 
          BEGIN 
       	    SELECT @strError = '>>--ERROR: Al guardar historico danios '
            RETURN (1) --ERROR: Al Insertar en el Inventario   
          END 
         
END 
ELSE 
	SELECT @strError = 'El daño ya se había ingresado'

SELECT @intInvContainerDamageId intInvContainerDamageId

