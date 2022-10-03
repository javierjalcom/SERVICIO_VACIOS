/*
Highlight and execute the following statement to drop the procedure
before executing the create statement.

DROP PROCEDURE dbo.spGetDamage

*/

create procedure spGetDamage (@EIR udtIdentifier           )
as

SELECT  tblclsContainerDamageType.strContDamTypeDescription as TDano , 
tblclsContainerPosition.strContainerPosDescription as Posicion,
tblclsEIRContainerDamage.decEIRContDamQuantity  as Cantidad 
FROM tblclsEIRContainerDamage 
join tblclsContainerDamageType on tblclsContainerDamageType.intContDamTypeId = tblclsEIRContainerDamage.intContDamTypeId 
join tblclsContainerPosition on tblclsContainerPosition.intContainerPositionId = tblclsEIRContainerDamage.intContainerPositionId 
WHERE ( tblclsContainerDamageType.blnContDamTypeActive = 1 ) and ( tblclsEIRContainerDamage.intEIRId =@EIR)

