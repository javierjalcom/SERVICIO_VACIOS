/*
Highlight and execute the following statement to drop the procedure
before executing the create statement.

DROP PROCEDURE dbo.spGenerateEIRNumber

*/

CREATE PROCEDURE spGenerateEIRNumber  @intVisitId udtIdentifier,
                                        @strContainerId       udtStringIdentifier,
                                        @intContainerCategoryId udtIdentifier,
                                        @strUser udtStringIdentifier
--										@intEIRtId            udtIdentifier
AS 

DECLARE @intEIRId INTEGER 
DECLARE @intContainerTypeId udtIdentifier,
		@intContainerSizeId udtIdentifier,
		@decContainerInvOptTemp udtDecimal,
		@intContainerInvTempMeasu udtIdentifier,
		@intEIRFolio udtIdentifier,
		@strEIRComments udtStringIdentifier,
		@intContainerUniversalId udtIdentifier,
		@intServiceId udtIdentifier,
		@strServiceId udtStringIdentifier,
		@strTipoManiobra udtStringIdentifier,
		@intServiceOrderId udtIdentifier
		
		
SELECT 	@intContainerUniversalId = ISNULL(intContainerUniversalId,0)
FROM 	tblclsContainerInventory		
WHERE 	strContainerId = @strContainerId AND
		blnContainerInvActive = 1

IF NOT EXISTS (SELECT intEIRId FROM tblclsEIR WHERE intVisitId = @intVisitId AND strContainerId = @strContainerId)
BEGIN
	SELECT @intContainerTypeId =  intContainerTypeId ,
		   @intContainerSizeId =  intContainerSizeId 
	FROM tblclsContainer
		 join tblclsContainerISOCode on  tblclsContainer.intContISOCodeId =  tblclsContainerISOCode.intContISOCodeId 
	WHERE strContainerId = @strContainerId
	
	BEGIN TRAN
	
	SELECT @intEIRId = isnull(MAX(intEIRId),0) + 1 FROM tblclsEIR
	
	insert into dbo.tblclsEIR ( 
	intEIRId, 
	intVisitId, 
	strContainerId, 
	intContainerUniversalId, 
	intContainerTypeId, 
	intContainerSizeId, 
	intContainerCategoryId, 
	decContainerInvOptTemp, 
	intContainerInvTempMeasu, 
	intEIRFolio, 
	strEIRComments, 
	dtmEIRCreationStamp, 
	strEIRCreatedBy, 
	dtmEIRLastModified, 
	strEIRLastModifiedBy, 
	intContReleaseId )
		
	values ( 
	@intEIRId, 
	@intVisitId, 
	@strContainerId, 
	@intContainerUniversalId, 
	@intContainerTypeId, 
	@intContainerSizeId, 
	@intContainerCategoryId, 
	@decContainerInvOptTemp, 
	@intContainerInvTempMeasu, 
	@intEIRFolio, 
	@strEIRComments, 
	GETDATE(), 
	@strUser, 
	GETDATE(), 
	@strUser, 
	0 )
	
	--Estatus del Insert   
		 
	IF @@Error = 1  --Validacion al Insertar el Registro   
	BEGIN   
	  ROLLBACK TRAN    --Aborta los Cambios   
	  SELECT ">>--ERROR: Al Generar el EIR"   
	  RETURN 1  --ERROR: Al Ingresar el Contenedor a Inventario   
	END 
	COMMIT TRAN 
END 
ELSE
	SELECT @intEIRId = intEIRId 
	FROM tblclsEIR 
	WHERE intVisitId = @intVisitId 
	AND strContainerId = @strContainerId



SELECT @intServiceId =intServiceId,
	   @intServiceOrderId  =  intServiceOrderId 
FROM tblclsVisitContainer
WHERE intVisitId     = @intVisitId AND
	  strContainerId = @strContainerId
	  
SELECT 	@strServiceId  = strServiceIdentifier
FROM 	tblclsService
WHERE 	intServiceId = @intServiceId  

--select  SUBSTRING(@strServiceId,1,3) Serv, @intServiceOrderId ServId, @intEIRId EIR
 BEGIN TRAN UPDATESERVICE
IF SUBSTRING(@strServiceId,1,3) = 'REC' 
BEGIN
	UPDATE 	tblclsContainerRecepDetail SET
			intEIRId = @intEIRId
	WHERE intContainerReceptionId = @intServiceOrderId AND 
	      strContainerId = @strContainerId
END	
IF SUBSTRING(@strServiceId,1,3) = 'ENT' 
BEGIN  
	UPDATE tblclsContainerDeliveryDetail SET
	intEIRId = @intEIRId
	WHERE intContainerDeliveryId = @intServiceOrderId AND 
	      strContainerId = @strContainerId

END
IF @@Error = 1  --Validacion al Insertar el Registro   
	BEGIN   
	  ROLLBACK TRAN  UPDATESERVICE  --Aborta los Cambios   
	  SELECT ">>--ERROR: Al Actualizar la maniobra de " + @strTipoManiobra   
	  RETURN 1  --ERROR: Al Ingresar el Contenedor a Inventario   
	END 
 COMMIT TRAN UPDATESERVICE
 
SELECT @intEIRId  intEIRId

