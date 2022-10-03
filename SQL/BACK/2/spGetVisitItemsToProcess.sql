/*
Highlight and execute the following statement to drop the procedure
before executing the create statement.

DROP PROCEDURE spGetVisitItemsToProcess

*/

CREATE PROCEDURE spGetVisitItemsToProcess ( @intVisitid udtIdentifier, @strService udtStringIdentifier ) 
  
 
AS  
 
 
    BEGIN  
     
         SELECT tblclsVisitContainer.strContainerId as 'Contenedor',    
                       tblclsContainerSize.strContainerSizeIdentifier as 'Tam', 
                       tblclsContainerType.strContainerTypeIdentifier as 'Tipo', 
 
                       CASE WHEN tblclsService.strServiceIdentifier IN ('RECLL','RECV','RECVOS') THEN 
 
                               ( SELECT ISNULL(tblclsShippingLine.strShippingLineIdentifier,'0') 
                                 FROM tblclsContainerRecepDetail, tblclsShippingLine 
                                 WHERE tblclsVisitContainer.intServiceOrderId = tblclsContainerRecepDetail.intContainerReceptionId 
                                     AND tblclsVisitContainer.strContainerId = tblclsContainerRecepDetail.strContainerId 
                                     AND tblclsContainerRecepDetail.intContRecDetailOperatorId = tblclsShippingLine.intShippingLineId ) 
 
                            WHEN tblclsService.strServiceIdentifier IN ('ENTLL','ENTV') THEN 
                             ( CASE WHEN  ISNULL(tblclsVisitContainer.intContainerUniversalId,0) > 0 THEN 
                                    ( 
                                      SELECT ISNULL(tblclsShippingLine.strShippingLineIdentifier,'0') 
                                      FROM tblclsContainerInventory, tblclsShippingLine 
                                      WHERE tblclsVisitContainer.intContainerUniversalId = tblclsContainerInventory.intContainerUniversalId  
                                      AND tblclsContainerInventory.intContainerInvOperatorId = tblclsShippingLine.intShippingLineId  
                                     
                                    ) 
                                  ELSE  
                                      '0' 
                                  END  
                             ) 
                       ELSE 
                            '0' 
 
                       END  AS 'Linea', 
 
                       CASE 	WHEN  ISNULL(tblclsVisitContainer.intContainerUniversalId,0) > 0 AND tblclsService.strServiceIdentifier LIKE 'REC%' THEN  
                                0 
                    WHEN  EXISTS(SELECT strContainerId  
                                            FROM tblclsContainerInventory  
                                          WHERE blnContainerInvActive = 1 AND 
                                                  strContainerId = tblclsVisitContainer.strContainerId) and tblclsService.strServiceIdentifier LIKE 'REC%' THEN  
                                0 
                    WHEN  EXISTS(SELECT strContainerId  
                                       FROM tblclsContainerInventory  
                                      WHERE blnContainerInvActive = 0 AND 
                                              intContainerUniversalId = tblclsVisitContainer.intContainerUniversalId) and tblclsService.strServiceIdentifier LIKE 'ENT%' THEN 
                                0 
                    ELSE  
                                1  
                    END  AS 'Valido',  
                     CASE WHEN tblclsService.strServiceIdentifier IN ('RECLL','RECV','RECVOS') THEN  
                                1 
                           WHEN (SELECT ISNULL(strContFisStatusIdentifier,'NADA')  
                                    FROM 	tblclsContainerInventory, 
                                            tblclsContainerFiscalStatus  
                                    where 	tblclsContainerInventory.intContFisStatusId = tblclsContainerFiscalStatus.intContFisStatusId and 
                                                tblclsContainerInventory.intContainerUniversalId = isnull(tblclsVisitContainer.intContainerUniversalId,0) ) = 'LIBERADO' THEN  
                                1 
                            ELSE 
                                0		 
                    END AS 'Fiscal' ,   
                    CASE  WHEN NOT ISNULL(tblclsEIR.intEIRId,0) = 0 THEN 
                                1 
                           ELSE 
                                0 
                    END AS 'EIR', 
                    tblclsEIR.intEIRId , 
                    CASE WHEN tblclsService.strServiceIdentifier IN ('RECLL','RECV','RECVOS') THEN 
                    	(SELECT  RD.strContRecDetailSealNumber  
						FROM    tblclsContainerReception R, 
								tblclsContainerRecepDetail RD      
						WHERE   R.intContainerReceptionId = RD.intContainerReceptionId and 
								RD.strContainerId         = tblclsVisitContainer.strContainerId AND 
								RD.intVisitId             = @intVisitid ) 
					ELSE '' 
                    END AS 'Seals' 
 
            FROM tblclsVisitContainer,    
                tblclsContainer,    
                tblclsContainerISOCode,    
                tblclsService , 
                 tblclsContainerSize,   
                  tblclsContainerType, 
                tblclsEIR  
 
            WHERE ( tblclsContainerISOCode.intContISOCodeId = tblclsContainer.intContISOCodeId ) and   
                    ( tblclsVisitContainer.strContainerId = tblclsContainer.strContainerId ) and   
                    ( tblclsVisitContainer.intServiceId = tblclsService.intServiceId ) and  
                    ( tblclsEIR.intVisitId =* tblclsVisitContainer.intVisitId )  AND 
                    ( tblclsEIR.strContainerId =*  tblclsVisitContainer.strContainerId) and 
                    ( tblclsContainerISOCode.intContainerSizeId = tblclsContainerSize.intContainerSizeId) AND 
                    ( tblclsContainerISOCode.intContainerTypeId = tblclsContainerType.intContainerTypeId) and 
                    ( tblclsVisitContainer.blnVisitContainerIsCancelled = 0) AND 
                    ( blnVisitContainerIsCancelled = 0 )	AND 
                    ( tblclsVisitContainer.intVisitId = @intVisitid) AND 
                   ( tblclsService.strServiceIdentifier LIKE @strService +'%' ) 
     
         
END



