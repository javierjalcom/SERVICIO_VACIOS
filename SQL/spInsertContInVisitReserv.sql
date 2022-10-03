/*
Highlight and execute the following statement to drop the procedure
before executing the create statement.

DROP PROCEDURE dbo.spInsertContInVisitReserv

*/

CREATE PROCEDURE spInsertContInVisitReserv
     (   @intVisitId      udtIdentifier, 
      	 @intVisitIdItem  udtIdentifier,
      	 @intUniversalId  udtIdentifier, 
      	 @strContainerId  udtStringIdentifier, 
      	 @User udtStringIdentifier
     )
    
AS 

/*
DESCRIPCION: 
            Actualiza el contenedor y el universal en la visita , es para contenedores que se van a asingar a la reservacion
            se tiene que ver si no esta ya asignado un contenedor a la visita 
*/

/*          
PARAMETROS: 
		intVisitId      numero de visita 
      	intVisitIdItem  elemento de la visita 
      	intUniversalId  numero de inventario del contenedor
      	strContainerId  nombre del contenedor 
      	User 			nombre de usuario 
      	
*/

/*
TABLAS:                     
        tblclsVisitContainer

*/

/*
VALORES DE RETORNO: ninguno 
*/

BEGIN 

    DECLARE @lstr_ContainerNameTemp udtStringIdentifier,
	        @lint_UniversalContTemp udtIdentifier,
	        @lint_ItemContainer     udtIdentifier,
	        @lint_Counter 			int,
	        @lstr_msg  				VARCHAR(100),
	        @StatusError 			int 
    -- ver si existe el elemnto que se queire actualizar y traer los valores de numero de contenedor y nombre 
        
		SELECT @lstr_ContainerNameTemp = VC.strContainerId,
		       @lint_UniversalContTemp = VC.intContainerUniversalId
		FROM tblclsVisitContainer VC
		WHERE VC.intVisitId = @intVisitId
		AND   VC.intVisitItemId = @intVisitIdItem
		
        SET @lint_Counter = @@ROWCOUNT 
        
        IF @lint_Counter =0
       	 BEGIN 
	        	SET @lstr_msg  = 'No se encontro el item ' + CONVERT(VARCHAR(2),@intVisitIdItem )
	        	RAISERROR 99999 @lstr_msg 
	     END 
	        
	    IF @lint_UniversalContTemp > 0 
	    BEGIN
	    	SET @lstr_msg  = 'El item ' + CONVERT(VARCHAR(2),@intVisitIdItem ) + 'esta ocupado por ' + @lstr_ContainerNameTemp
        	RAISERROR 99999 @lstr_msg 
	    END  
    
         BEGIN TRANSACTION
                
          	  UPDATE tblclsVisitContainer
	          SET strContainerId = @strContainerId ,
	                intContainerUniversalId = @intUniversalId , 
	                dtmVisitContLastModified =  getdate(),
	                strVisitContLastModifiedBy = @User
	          WHERE intVisitId = @intVisitId
	          AND intVisitItemId = @intVisitIdItem	                
                
			    IF @StatusError > 0   --Validacion al Actualizar el Registro
			      BEGIN
			  	       ROLLBACK TRANSACTION
				       SET @lstr_msg  = 'Error al actualizar visita para el contenedor ' + @strContainerId
				       RAISERROR 99999 @lstr_msg 
				  END 
			    ELSE
				    BEGIN 
				     COMMIT TRANSACTION 
				    END 	   
				    
END

