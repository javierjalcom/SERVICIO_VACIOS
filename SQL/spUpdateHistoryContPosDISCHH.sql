/*
Highlight and execute the following statement to drop the procedure
before executing the create statement.

DROP PROCEDURE spUpdateHistoryContPosDISCHH

*/

CREATE PROCEDURE spUpdateHistoryContPosDISCHH(@UniversalId udtIdentifier, 
                                                 @YardPosId  udtStringIdentifier, 
                                                 @Block    udtStringIdentifier, 
                                     @Row    udtStringIdentifier, 
                                                 @Bay    udtStringIdentifier, 
                                                 @Stow    udtStringIdentifier, 
                    @Comments udtShortString, 
                                                 @User udtStringIdentifier)                                             
AS  
 
--DESCRIPCION:  
--             Se inserta un registro en la tabla de Hist?rico de Posici?n del Contenedor 
--PARAMETROS:   
--             UniversalId   : Universal Id del Contenedor en el Inventario              
--             YardPosId     : Id de la Posici?n en el Patio 
--             Block         : Bloque 
--             Row          : Fila 
--             Bay           : Bahia 
--             Stow          : Estiba 
--             Comments      : Comentarios 
--             User          : Usuario  
--TABLAS :                      
--             tblclsContYardPositionHistory 
--VALORES DE RETORNO: Ninguno 
--FECHA : 07-JULIO-2004 
--AUTOR : david.garcia  
--CORRECCION:    
 
--IF @@tranchained = 1  RETURN(1) 
 
SET TRANSACTION ISOLATION LEVEL READ COMMITTED 
  
DECLARE   @intTransId  udtIdentifier, 
          @ReturnCode  udtIdentifier, 
          @intError    udtIdentifier 
 
IF CHAR_LENGTH(@Comments) <= 0 SELECT @Comments = 'Se cambio la posici?n a: ' + @YardPosId 
 
--Ejecuta el SP que inserta una Transacci?n y devuelve el Id que se Inserto 
EXECUTE @ReturnCode = spInsertTransaction @UniversalId,'CONFUBI',@Comments,@User,@intTransId OUTPUT 
 
--Si hubo algun Error devuelve 1 y sale del SP 
IF @ReturnCode != 0  RETURN(1) 
 
BEGIN TRANSACTION 
 
 
--Inserta un registro en la tabla del Hist?rico de Posici?n del Contenedor 
INSERT INTO tblclsContYardPositionHistory 
(intContTransHistId, 
 intContainerUniversalId, 
 strYardPositionIdentifier, 
 strYardBlockIdentifier, 
 strYardBlockRowIdentifier, 
 strYardBlockBayIdentifier, 
 strYardBlockStow, 
 strContYPHistComments, 
 dtmContYPHistCreationStamp, 
 strContYPHistCreatedBy, 
 dtmContYPHistLastModified, 
 strContYPHistLastModifiedBy)  
VALUES(@intTransId,@UniversalId,@YardPosId,@Block,@Row,@Bay,@Stow,@Comments,GETDATE(),@User,GETDATE(),@User) 
 
 
--Obtiene el Error 
SELECT @intError = @@error  
  
--Si no hubo error 
IF @intError = 0 
  BEGIN 
     COMMIT TRANSACTION 
     RETURN(0) 
  END 
ELSE --si hubo error 
  BEGIN 
     ROLLBACK TRANSACTION 
     RETURN(1) 
  END



