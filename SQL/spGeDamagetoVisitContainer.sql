/*
Highlight and execute the following statement to drop the procedure
before executing the create statement.

DROP PROCEDURE dbo.spGetDamagetoVisitContainer


*/

CREATE PROCEDURE spGetDamagetoVisitContainer ( @intVisitid udtIdentifier, @strContainer udtStringIdentifier, @intMode udtIdentifier) 
  
 
AS  
  
    BEGIN  
    
          -- obtener los daños
          
          CREATE TABLE #DamageTable
			       (
			       intContDamTypeId numeric NULL,
			       strContDamTypeDescription varchar(80) NULL,
			       intContainerPositionId numeric NULL,
			       strContainerPosDescription varchar(30) NULL			       
			       )
			       
	       DECLARE @lstrService varchar(16)
	       DECLARE @lintUniversalId udtIdentifier
	       
	       SET @lstrService = ''
	       SET @lintUniversalId = 0
	       
	       -- obtener el servicio  de la visita 
	       SELECT @lstrService = tblclsService.strServiceIdentifier
	             ,@lintUniversalId = tblclsVisitContainer.intContainerUniversalId
	             
	       FROM tblclsVisitContainer
	        INNER JOIN tblclsService ON tblclsService.intServiceId = tblclsVisitContainer.intServiceId
	       WHERE tblclsVisitContainer.strContainerId = @strContainer 
	       AND tblclsVisitContainer.intVisitId =  @intVisitid 
	       
	       -- SI EL SERVICIOS ES SALIDA, Y TIENE UNIVERSAL, INSERTAR LOS DAÑOS DE INVENTARIO
	        IF (  (@lstrService = 'ENTLL' OR @lstrService = 'ENTV') AND @lintUniversalId > 0 )
	        BEGIN
	           INSERT INTO  #DamageTable
	             ( intContDamTypeId ,
			       strContDamTypeDescription ,
			       intContainerPositionId ,
			       strContainerPosDescription 			     
			     )
			    SELECT  tblclsContainerInventoryDam.intContDamTypeId
			           ,tblclsContainerDamageType.strContDamTypeDescription
			           ,tblclsContainerPosition.intContainerPositionId
			           ,tblclsContainerPosition.strContainerPosDescription
			           
			    FROM tblclsContainerInventoryDam
			     INNER JOIN tblclsContainerDamageType   ON tblclsContainerDamageType.intContDamTypeId     = tblclsContainerInventoryDam.intContDamTypeId
			     INNER JOIN tblclsContainerPosition      ON tblclsContainerPosition.intContainerPositionId = tblclsContainerInventoryDam.intContainerPositionId
			    WHERE tblclsContainerInventoryDam.intContainerUniversalId = @lintUniversalId 
                AND tblclsContainerDamageType.blnContDamTypeActive =1 
	           
	        END 
	        -- FIN SI EL SERVICIO DE SALIDA
	        
	       -- insertar los daños por defaul
	           INSERT INTO  #DamageTable
	             ( intContDamTypeId ,
			       strContDamTypeDescription ,
			       intContainerPositionId ,
			       strContainerPosDescription 			     
			     )
			    SELECT   tblclsContainerDamageType.intContDamTypeId 
			           ,tblclsContainerDamageType.strContDamTypeDescription
			           ,tblclsContainerPosition.intContainerPositionId
			           ,tblclsContainerPosition.strContainerPosDescription
			   FROM tblclsContainerDamageType
			     , tblclsContainerPosition
			   WHERE
			   --  tblclsContainerDamageType.intContDamTypeId = 3
			   --AND  tblclsContainerPosition.intContainerPositionId =  3
			   tblclsContainerDamageType.strContDamTypeIdentifier = 'DGU'
			   AND tblclsContainerPosition.strContainerPosIdentifier = 'CNT'
			   AND tblclsContainerDamageType.intContDamTypeId NOT IN (
			                                                           SELECT intContDamTypeId
			                                                           FROM #DamageTable
			                                                         )
			    
			   AND tblclsContainerPosition.intContainerPositionId NOT IN (
			                                                                SELECT intContainerPositionId
			                                                                FROM #DamageTable
			                                                             )
	       
	       -- fin insertar los daños por default 
	       
         SELECT intContDamTypeId
               , SUBSTRING(strContDamTypeDescription,1,21) AS 'strContDamTypeDescription' --,strContDamTypeDescription
               ,intContainerPositionId
               ,strContainerPosDescription
         
         FROM  #DamageTable
	             
      
         
         DROP TABLE #DamageTable
          ---------------------------
    
    END -- final