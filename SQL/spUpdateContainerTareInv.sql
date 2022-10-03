/*
Highlight and execute the following statement to drop the procedure
before executing the create statement.

DROP PROCEDURE dbo.spUpdateContainerTareInv

*/

CREATE PROCEDURE spUpdateContainerTareInv @strContainerId     udtStringIdentifier, 
                                       @decTare udtDecimal , 
                                       @Univ udtIdentifier,
                                       @strUserName udtStringIdentifier

                                                
AS  
/*    
  NOMBRE      : spUpdateContainerTare   
  DESCRIPCION : Actualiza la tara de un contenedor 
  AUTOR : javier cadena 
  FECHAS : 9 -MAYO-2015
  
  PARAMETROS : 
    @strContainerId:  nombre del contenedor 
    @decTare      :   valor de la tara  
    @strUserName  :   valor decimal 

*/

  DECLARE @StatErrSP  udtIdentifier
  DECLARE @OldTare    udtDecimal
  DECLARE @intTableAttrib  udtIdentifier
  DECLARE @Comments udtShortString
  DECLARE @strInfo varchar(10)
  
 --Checa si las Transacciones estan Encadenadas  
  IF @@TRANCHAINED=1   
     --Si estan Encadenadas Aborta el SP  
     RETURN (1)  
    
  --Evitar Dirty Reads  
  SET TRANSACTION ISOLATION LEVEL 1  

  --- obtener el valor de como estaba tara antes 
    SELECT @OldTare = tblclsContainer.decContainerTare
    FROM  tblclsContainer
    WHERE tblclsContainer.strContainerId = @strContainerId
    
   --- realizar la actualizacion    
   BEGIN TRANSACTION 
   
     UPDATE tblclsContainer
     SET tblclsContainer.decContainerTare =  @decTare , 
         tblclsContainer.strContainerLastModifiedBy = @strUserName,
         tblclsContainer.dtmContainerLastModified = GETDATE()
         
     WHERE tblclsContainer.strContainerId = @strContainerId

   
   --Estatus del Insert
    SELECT @StatErrSP = @@Error
                              
     --Valida el Resultado 
     IF @StatErrSP = 0   
      BEGIN         
          COMMIT TRAN     -- Aplica la Actualizacion           
         -- RETURN(0) -- Sin Error         
      END 
     ELSE 
      BEGIN 
          ROLLBACK TRAN   -- Deshace la Actualizacion
          RETURN(1) -- Hubo Error            
      END 	    

	    
    ----------- 05-SEP-2016
      --- adicion para comentarios 
      --obtener el id del valor de atributo de tabla para latinoamerica 
        select @intTableAttrib =  ISNULL(tblclsTableAttribute.intTableAttribId,0)
        from tblclsTableAttribute 
        where  tblclsTableAttribute.strTableAttribColumnName ='decContainerTare' 
        and    tblclsTableAttribute.strTableAttribTableName = 'tblclsContainer'
        and    tblclsTableAttribute.intLanguageId = 1 


       SET @strInfo = 'atrib=' + CONVERT(VARCHAR(10),@intTableAttrib)
       --PRINT @strInfo
       
      --- obtener el ultimo universal activo de este contenedor         
        -- si  encontro el atributo 
        IF ( @intTableAttrib > 0 and @Univ > 0  ) 
         BEGIN  
           SET @Comments = 'Cambio de Tara de:'+ convert(varchar(10),@OldTare ) + 'a:'+ convert(varchar(10),@decTare)
           execute spUpdateHistoryOtherData @Univ,@intTableAttrib,@Comments,@strUserName
         END 
    -----------------------------------
    
    RETURN (0) -- NO HUBO ERROR

