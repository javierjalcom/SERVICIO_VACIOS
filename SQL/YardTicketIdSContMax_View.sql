--drop view YardTicketIdContMax_View


CREATE VIEW YardTicketIdSContMax_View
AS  
/* Name : YardTicketIdContMax_View 
  Tabla : tblclsYardVerificationTicket  
          tblclsServiceOrderItem  
          tblclsYardVerifTicketItem     
  Consulta  De los pedimentos de importacion  de un Item de la Carga 
  Creado por : JCADENA 10-JUL-2015
   
*/ 


---- VISTA DE ULTIMA TARJA DE CONTENEDOR 

 SELECT tblclsYardVerificationTicket.intYardVerifTicketId , 
        tblclsYardVerificationTicket.dtmYVerifTicketInitialDate,
        tblclsYardVerificationTicket.dtmYVerifTicketFinalDate,
        tblclsServiceOrderItem.strContainerId,
        tblclsServiceOrderItem.intServiceOrderId,
        tblclsServiceOrderItem.intServiceOrderItemId
        
 FROM tblclsYardVerificationTicket
   INNER JOIN tblclsYardVerifTicketItem on   tblclsYardVerifTicketItem.intYardVerifTicketId = tblclsYardVerificationTicket.intYardVerifTicketId
   INNER JOIN tblclsServiceOrderItem ON  tblclsServiceOrderItem.intServiceOrderId     = tblclsYardVerifTicketItem.intServiceOrderId
   									 AND tblclsServiceOrderItem.intServiceOrderItemId = tblclsYardVerifTicketItem.intServiceOrderItemId

          AND tblclsYardVerifTicketItem.intYardVTItemId =
           (    
              SELECT MAX (TITEMIN.intYardVTItemId)   
              FROM tblclsYardVerificationTicket TICKIN
                  INNER JOIN tblclsYardVerifTicketItem TITEMIN ON   TICKIN.intYardVerifTicketId   = TITEMIN.intYardVerifTicketId
                  
              WHERE  tblclsServiceOrderItem.intServiceOrderId     = TITEMIN.intServiceOrderId
               AND   tblclsServiceOrderItem.intServiceOrderItemId = TITEMIN.intServiceOrderItemId
          )