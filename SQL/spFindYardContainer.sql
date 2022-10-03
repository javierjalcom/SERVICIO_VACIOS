/*
Highlight and execute the following statement to drop the procedure
before executing the create statement.

DROP PROCEDURE dbo.spFindYardContainer

*/

CREATE PROCEDURE spFindYardContainer( @strContainerId udtStringIdentifier )
AS

BEGIN

	--DESCRIPCION: SP que busca un contenedor en el inventario
	
	--TABLAS :  --  tblclsContainerInventory
                
     -- ARGUMENTOS:
                -- strContainer .- Nombre del contenedor
                
	--VALORES DE RETORNO:  
	
	--FECHA : Enero 2017
	--AUTOR : lislas


	SELECT tblclsContainerInventory.intContainerUniversalId,   
	tblclsContainerInventory.strContainerId,
	tblclsContainerInventory.strContainerInvYardPositionId,   
	tblclsContainerInventory.blnContainerIsFull,
	tblclsContainerType.strContainerTypeIdentifier,   
	tblclsContainerSize.strContainerSizeIdentifier,   
	tblclsShippingLine.strShippingLineIdentifier,  
	(CASE ISNULL(tblclsContainerInventory.intContainerUniversalId, 0)   
	    WHEN 0 THEN 'SIN ESTATUS'   
	    ELSE tblclsContainerFiscalStatus.strContFisStatusIdentifier   
	 END) AS 'strContFisStatusIdentifier'
	FROM tblclsContainerInventory   
	LEFT OUTER JOIN tblclsContainerFiscalStatus ON tblclsContainerInventory.intContFisStatusId = tblclsContainerFiscalStatus.intContFisStatusId   
	LEFT JOIN tblclsContainer ON tblclsContainerInventory.strContainerId = tblclsContainer.strContainerId   
	LEFT JOIN tblclsContainerISOCode ON tblclsContainer.intContISOCodeId = tblclsContainerISOCode.intContISOCodeId   
	LEFT JOIN tblclsContainerType ON tblclsContainerISOCode.intContainerTypeId = tblclsContainerType.intContainerTypeId   
	LEFT JOIN tblclsContainerSize ON tblclsContainerISOCode.intContainerSizeId  = tblclsContainerSize.intContainerSizeId   
	LEFT JOIN tblclsShippingLine  ON tblclsContainerInventory.intContainerInvOperatorId = tblclsShippingLine.intShippingLineId   
	WHERE tblclsContainerInventory.blnContainerInvActive = 1
	AND tblclsContainerInventory.strContainerId = @strContainerId
	
END



