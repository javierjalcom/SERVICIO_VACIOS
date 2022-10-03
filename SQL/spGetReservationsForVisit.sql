/*
Highlight and execute the following statement to drop the procedure
before executing the create statement.

DROP PROCEDURE dbo.spGetReservationsForVisit

*/

CREATE PROCEDURE dbo.spGetReservationsForVisit (@intVisitid udtIdentifier) 
 
AS  
 
    BEGIN  
    SELECT tblclsContainerReservation.intContainerReservationId AS RESERVACION, 
            tblclsContainerReservation.strBookingId AS BOOKING, 
            tblclsContainerSize.strContainerSizeIdentifier + '-' + tblclsContainerType.strContainerTypeIdentifier  as TYPESIZE, 
            tblclsShippingLine.strShippingLineIdentifier AS LINEA, 
            count (tblclsVisitContainer.intVisitItemId) as PENDIENTESVISITA , 
            tblclsContReservationDetail.intContReservDetQuantity as RESERVADOS, 
            ( select count (tblContReserv_Inventory.intContainerUniversalId ) 
                   from tblContReserv_Inventory 
                   where tblContReserv_Inventory.intContainerReservationId=tblclsContainerReservation.intContainerReservationId) 
                 as ENTREGADOSRESERV, 
            tblclsContainerDelivery.intContainerDeliveryId  
             
             
             
            from tblclsVisitContainer,  tblclsVisit, 
                   tblclsContainerDelivery, 
                    tblclsContainerReservation,  
                   tblclsContReservationDetail, 
                   tblclsShippingLine, 
                   tblclsContainerType, 
                  tblclsContainerSize, 
                  tblclsContainerCategory, 
                   tblclsService, 
                  tblclsServiceOrderStatus 
                   
            where tblclsVisitContainer.intServiceId = tblclsService.intServiceId  
            and tblclsVisitContainer.intServiceOrderId = tblclsContainerDelivery.intContainerDeliveryId  
            and ( tblclsVisitContainer.intContainerUniversalId=0 OR tblclsVisitContainer.intContainerUniversalId IS NULL) 
            and ( tblclsVisitContainer.strContainerId = ''  OR tblclsVisitContainer.strContainerId  IS NULL ) 
            and tblclsVisitContainer.intVisitId = @intVisitid 
            and tblclsVisitContainer.blnVisitContainerIsCancelled=0  
            and tblclsService.strServiceIdentifier = 'ENTV'  
            and tblclsContainerDelivery.intServiceId =  tblclsService.intServiceId  
            and tblclsContainerDelivery.intContainerReservationId = tblclsContainerReservation.intContainerReservationId  
            and tblclsContainerReservation.intServiceId =  tblclsService.intServiceId  
            and tblclsContReservationDetail.intContainerReservationId = tblclsContainerReservation.intContainerReservationId  
            and tblclsContReservationDetail.intContainerCategoryId = tblclsContainerCategory.intContainerCategoryId 
            and tblclsContReservationDetail.intContainerSizeId = tblclsContainerSize.intContainerSizeId 
            and tblclsContReservationDetail.intContainerTypeId = tblclsContainerType.intContainerTypeId 
            and tblclsContainerReservation.intContReservShippingLineId = tblclsShippingLine.intShippingLineId 
            and tblclsVisit.intVisitId = tblclsVisitContainer.intVisitId 
            and tblclsVisit.dtmVisitDatetimeOut IS NULL 
           and tblclsServiceOrderStatus.intSOStatusId = tblclsVisit.intSOStatusId 
            and tblclsServiceOrderStatus.strSOStatusIdentifier not in ( 'TER', 'CAN' ) 
     
            group by tblclsContainerReservation.intContainerReservationId, 
            tblclsContainerReservation.strBookingId, 
            tblclsContainerSize.strContainerSizeIdentifier , 
            tblclsContainerType.strContainerTypeIdentifier , 
            tblclsShippingLine.strShippingLineIdentifier, tblclsContReservationDetail.intContReservDetQuantity, 
            tblclsContainerDelivery.intContainerDeliveryId   
 END

