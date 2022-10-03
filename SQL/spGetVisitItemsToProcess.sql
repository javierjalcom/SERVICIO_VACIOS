/*
Highlight and execute the following statement to drop the procedure
before executing the create statement.

DROP PROCEDURE dbo.spGetVisitItemsToProcess

*/

CREATE PROCEDURE dbo.spGetVisitItemsToProcess ( @intVisitid udtIdentifier, @strService udtStringIdentifier ) 
  
 
AS  
 
 
    BEGIN  
     
       CREATE TABLE #VisitItem
			       (
			        strContainerId varchar(19) NULL,
			        strContainerSizeIdentifier varchar(15) NULL,
			        strContainerTypeIdentifier varchar(15) NULL,
			        strShippingLineIdentifier  VARCHAR(50) NULL,
			        intValid INT NULL, 
			        intValidFiscal INT NULL,
			        intValidEIR INT NULL,
			        intEIRId NUMERIC(18,0) NULL,
			        strSealNumber varchar(200) NULL
	                 --,PRIMARY KEY (intContainerVisitItemId)
	                 ,intContainerUniversalId numeric(18,0) NULL
	                 ,strServiceIdentifier varchar(20) NULL

			        )
     
         INSERT INTO #VisitItem 
         ( 
          strContainerId ,
		  strContainerSizeIdentifier ,
		  strContainerTypeIdentifier ,
		  strShippingLineIdentifier  ,
		  intValid , 
		  intValidFiscal ,
		  intValidEIR ,
		  intEIRId ,
		  strSealNumber 
		  , intContainerUniversalId
		  ,strServiceIdentifier
         )
         SELECT tblclsVisitContainer.strContainerId ,--as 'Contenedor',    
                tblclsContainerSize.strContainerSizeIdentifier,-- as 'Tam', 
                tblclsContainerType.strContainerTypeIdentifier,-- as 'Tipo', 
 
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
 
                       END ,-- AS 'Linea', 
 
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
                    END  ,--AS 'Valido',  
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
                    END ,-- AS 'Fiscal' ,   
                    CASE  WHEN NOT ISNULL(tblclsEIR.intEIRId,0) = 0 THEN 
                                1 
                           ELSE 
                                0 
                    END,-- AS 'EIR', 
                    tblclsEIR.intEIRId , 
                    CASE WHEN tblclsService.strServiceIdentifier IN ('RECLL','RECV','RECVOS') THEN 
                    	(SELECT  RD.strContRecDetailSealNumber  
						FROM    tblclsContainerReception R, 
								tblclsContainerRecepDetail RD      
						WHERE   R.intContainerReceptionId = RD.intContainerReceptionId and 
								RD.strContainerId         = tblclsVisitContainer.strContainerId AND 
								RD.intVisitId             = @intVisitid ) 
					ELSE '' 
                    END --, AS 'Seals' 
                    ,tblclsVisitContainer.intContainerUniversalId
                    ,tblclsService.strServiceIdentifier
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
     
       ---- si el servicio es entrega y hay contenedores en inventario 
      		IF @strService = 'ENTLL'
      		  BEGIN
      		         
      		         DECLARE @lstrContainer varchar(20)
      		         DECLARE @lstrSealRead varchar(20)
      		         DECLARE @lstrPrevRead varchar(20)
      		         DECLARE @lstrSpace varchar(10)
      		         
      		         SELECT @lstrSpace =''
      		         
      		         -- recorrer el cursor para poner un orden en las regals que faltan 
         			   DECLARE ItemSealCursor CURSOR  
			            FOR  
			                 SELECT tblclsVisitContainer.strContainerId,
			                        tblclsContainerSeal.strContainerSealNumber
			                 FROM tblclsVisitContainer
			                 INNER JOIN #VisitItem ON #VisitItem.strContainerId = tblclsVisitContainer.strContainerId
			                 INNER JOIN tblclsContainerSeal on tblclsContainerSeal.intContainerUniversalId = tblclsVisitContainer.intContainerUniversalId
			                 WHERE  tblclsVisitContainer.intVisitId =  @intVisitid
			                 
			            --abrir cursor
			            OPEN ItemSealCursor
			            -- leer el registro del cursor
			              FETCH ItemSealCursor INTO @lstrContainer , @lstrSealRead
			              
			             -- print 'ciclo 468'
			              
			          
			            -- ciclo
			            WHILE (@@sqlstatus !=2   ) -- mietras no sea fin de lectura
			            BEGIN --while
			              -- incializar valido en -1
			             
			              
			             -- si no hubo error al leer
			              IF ( @@sqlstatus != 1   ) 
			              BEGIN
			
			               -- leer el registro del cursor
			                -- obtener el sello en la tabla actual
			                
			                ---- si el sello, tiene 
			                IF ( LEN(@lstrSealRead) > 1)
			                BEGIN
			                
				                 SELECT  @lstrPrevRead = ISNULL(#VisitItem.strSealNumber,'')
				                 FROM #VisitItem
				                 WHERE #VisitItem.strContainerId =  @lstrContainer
				                 
				                 -- si la longitud de sellos es mayor
				                 IF ( LEN( @lstrPrevRead) > 2 )
				                  BEGIN
				                       SET @lstrSpace =','
				                  END 
				                  
				                  
				                 -- adicionar el sello
				                 UPDATE #VisitItem
				                 SET #VisitItem.strSealNumber = #VisitItem.strSealNumber + @lstrSpace + @lstrSealRead
				                 WHERE  #VisitItem.strContainerId = @lstrContainer
				                 
				                 
			                 -------
			                END --IF ( LEN(@lstrSealRead) > 1)
			                 
			                
			                 
					          FETCH ItemSealCursor INTO @lstrContainer , @lstrSealRead
					                         	
			              END -- IF ( @@sqlstatus != 1   ) 
			             
			             
			            END   -- while
			            -- CERRAR CURSOR
			            CLOSE ItemSealCursor
			
			
			   -- LIMPIAR CURSOR
			            deallocate cursor ItemSealCursor
            
            
      		  END  --IF @strService = 'ENTLL'
      		  
      ---  FIN si el servicio es entrega
      
      -- si el servicio no esta definido solo llenar informacion generica
       IF(  @strService = '0')
       BEGIN
            --
                 
     		
		         INSERT INTO #VisitItem 
		         ( 
		          strContainerId ,
				  strContainerSizeIdentifier ,
				  strContainerTypeIdentifier ,
				  strShippingLineIdentifier  ,
				  intValid , 
				  intValidFiscal ,
				  intValidEIR ,
				  intEIRId ,
				  strSealNumber 
				  , intContainerUniversalId
                  , strServiceIdentifier
		         )
		         SELECT tblclsVisitContainer.strContainerId ,--as 'Contenedor',    
		                tblclsContainerSize.strContainerSizeIdentifier,-- as 'Tam', 
		                tblclsContainerType.strContainerTypeIdentifier,-- as 'Tipo', 
		 
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
		 
		                       END ,-- AS 'Linea', 
		 
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
		                    END  ,--AS 'Valido',  
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
		                    END ,-- AS 'Fiscal' ,   
		                    CASE  WHEN NOT ISNULL(tblclsEIR.intEIRId,0) = 0 THEN 
		                                1 
		                           ELSE 
		                                0 
		                    END,-- AS 'EIR', 
		                    tblclsEIR.intEIRId , 
		                    CASE WHEN tblclsService.strServiceIdentifier IN ('RECLL','RECV','RECVOS') THEN 
		                    	(SELECT  RD.strContRecDetailSealNumber  
								FROM    tblclsContainerReception R, 
										tblclsContainerRecepDetail RD      
								WHERE   R.intContainerReceptionId = RD.intContainerReceptionId and 
										RD.strContainerId         = tblclsVisitContainer.strContainerId AND 
										RD.intVisitId             = @intVisitid ) 
							ELSE '' 
		                    END --, AS 'Seals' 
		                    ,tblclsVisitContainer.intContainerUniversalId
		                    , tblclsService.strServiceIdentifier
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
		                    ( tblclsVisitContainer.intVisitId = @intVisitid)
		                    -- AND ( tblclsService.strServiceIdentifier LIKE @strService +'%' ) 

            --
       END --fin del servicio no esta definido
       
       
      --- fin si el servicio no esta definido
      
      -- retornar la tabla temporal 
             SELECT 
                    strContainerId AS 'Contenedor',
                    strContainerSizeIdentifier AS 'Tam',
                    strContainerTypeIdentifier  AS 'Tipo',
                    strShippingLineIdentifier  AS 'Linea',
                    intValid AS 'Valido', 
                    intValidFiscal AS 'Fiscal',
                    intValidEIR AS 'EIR',
                    ISNULL(intEIRId,0) AS 'intEIRId',
                    strSealNumber  AS 'Seals'
                    , intContainerUniversalId AS 'xintContainerUniversalId'

             FROM #VisitItem
        
             
      DROP TABLE #VisitItem
         
END



