

ALTER TABLE tblclsYardVerificationTicket ADD dtmYVerifTicketInitialDate datetime NULL

ALTER TABLE tblclsYardVerificationTicket ADD dtmYVerifTicketFinalDate datetime NULL




ALTER TABLE tblclsYardVerifTicketItem ADD intYardVerificationType int NULL

ALTER TABLE tblclsYardVerifTicketItem ADD strDescriptionEquipment varchar(25) NULL

ALTER TABLE tblclsYardVerifTicketItem ADD strEliminatedSeals varchar(25) NULL

ALTER TABLE tblclsYardVerifTicketItem ADD strAppliedSeals varchar(25) NULL

ALTER TABLE tblclsSystemConfig  ADD intSystemConfigCFSActive INT NULL


