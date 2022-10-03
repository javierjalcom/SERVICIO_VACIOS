/*
Highlight and execute the following statement to drop the procedure
before executing the create statement.

DROP PROCEDURE dbo.spContainerInOutInventory

*/

CREATE PROCEDURE dbo.spContainerInOutInventory @intVisitId          udtIdentifier,    
                                               @strContainerId      udtStringIdentifier,    
                                               @dtmExecuteDate    udtDatetime,    
                                               @strUser             udtUserName                                                   
    
/*      
  NOMBRE      : spContainerInOutInven (IPMALT) Copia de spContainerInOutInvenHis    
  DESCRIPCION : Este SP realiza todos los Movimientos en el Inventario para la Entrada/Salida de un Contenedor    
    
    
                ENTRADA:    
                  - Genera el Id Universal     
                  - Lo Ingresa al Inventario    
                  --Actualiza el Estatus Adminstrativo en :    
                     -- PENDIENTE POR UBICACION     para Contenedores VACIOS Y LLENOS    
                        Ya que para VACIOS se le captura la Clasificación en el eir    
                        los Contenedores a STOCK se consideran en el EMPTY DEPOT     
                        cuando se ingresan al inventario no deberan tener BV    
                     -- PENDIENTE POR CLASIFICACION para Contenedores VACIOS (OBSOLETOS)    
                  - Refleja el BK de Ingreso al Inventario       
                  - Ingresa los IMOS,Sellos, Daños, SobreDimensiones y Productos asociados Contenedor al Inventario    
                  - Actualiza el Campos Universal Id en el EIR, Visita,Detalle de Recepcion             
                  - Genera el Historial del Contenedor    
                     --Inserta en la tabla del Histórico de Contenedor (tblclsContainerHistory)          
                     --Inserta una Transaccion en tblclsContainerTransaccion    
                     --Genera el Historial para ECRF en tblclsServiceOrderHistory    
                  - Actualiza el Estatus = EN PROCESO de la Orden de Servicio (Recepcion)     
                  - *Actualiza la Hora y Fecha de Entrada de la Visita (esto se hara desde PB con el spVisitInOut)    
                  - *Inserta la Visita en la Cola de Camiones/Visita (esto se hara desde PB con el spVisitInOut)    
                  - * Se Lanza proceso para actualizar la lista de contenedores pendientes por ingresar    
                      
                     
                SALIDA :    
                  -- Marca como Borrado el Registro en el Inventario(CampoActivo=0)    
                  -- Actualiza el Historico del Contenedor para SCRF    
                  -- Inserta un registro en la tabla del Histórico de Contenedor (tblclsContainerHistory)          
                  -- Inserta una Transaccion en tblclsContainerTransaccion    
                  -- Genera el Historial para ECRF en tblclsServiceOrderHistory    
                  -  Actualiza el Estatus = EN PROCESO de la Orden de Servicio (Delivery)     
                  -- *Actualiza la Hora y Fecha de Salida de la Visita  (esto se hara desde PB con el spVisitInOut)    
 -- *Borra la Visita de la Cola de Visitas (esto se hara desde PB con el spVisitInOut)    
    
                     
  PARAMETROS  :     
                @intVisitId        : Id de la Visita de donde proviene el Contenedor       
                @intServiceOrderId   : Número a una Orden de Servicio (Recepcion Id ó Delivery Id)    
                @strContainerId      : Id Cadena del Contendor que Entrará ó Saldra al/del Inventario    
                  
  TABLAS : Segun el Identificador del Servicio  que se le envio es la tabla que se actualizará    
           --------------------------------     
           Identificador  Tabla      
           --------------------------------      
      tblclsContainerReception       tblIMOCode_EIR    
           tblclsContainerRecepDetail     tblIMOCode_ContainerInventory    
           tblclsContainerDelivery        tblclsEIRContainerSeal     
           tblclsContainerDeliveryDetail  tblclsContainerSeal     
           tblclsVisit                    tblclsEIRContainerDamage    
           tblclsVisitContainer           tblclsContainerInventoryDam    
           tblclsEIR                      tblclsEIRContainerOversize    
           tblclsContainerHistory         tblclsContainerInventoryOver    
           tblclsContainerTransaccion     tblclsContainerRecepProduct    
           tblclsServiceOrderHistory      tblclsContainerProduct    
           tblclsVisitQueu               
               
  VALORES DE RETORNO:     
           VALOR -TIPO DE DATO    -DESCRIPCION     
            0     INTEGER    : Para Caso de Exito del SP     
            1     INTEGER    : Para Caso de Error del SP                    
     
  FECHA DE CREACION     :  18-Marzo- 2007 LISLAS   
*/     
    
     
AS     
DECLARE @SUCCESS              INTEGER             --Variable para caso de Exito (0 Errores)      
DECLARE @FAILURE              INTEGER             --Variable para caso de Error (Se Detecto Errores)    
DECLARE @EXISTS               INTEGER             --Variable para Indicar que el contenedor ya ingreso en el inventario o que todavia se encuentre en el mismo    
DECLARE @StatusError          INTEGER             --Variable para determinar el estatus de error    
DECLARE @StatErrSP       INTEGER             --Estatus de Exito/Error del SP que generará el Universal Id    
DECLARE @strService           udtStringIdentifier --Identificador Tipo de Movimiento RECEPCION, ENTREGA    
DECLARE @intServiceId         udtIdentifier       --Id Tipo de Movimiento RECEPCION, ENTREGA    
DECLARE @intServOrderId       udtIdentifier       --Id de la Orden de Servicio (RecepcionId ó DeliveryId)    
DECLARE @intFiscalMovementId  udtIdentifier       --Id del Movimiento Fiscal    
DECLARE @intVesselVoyageId    udtIdentifier       --Id Buque Viaje    
DECLARE @intPhyscalStatId     udtIdentifier       --Id del Estatus Fisico    
DECLARE @strOriginPort        udtStringIdentifier --Identificador del Puerto de Origen    
DECLARE @strFinalPort         udtStringIdentifier --Identificador del Puerto de Destino    
DECLARE @strDischargePort     udtStringIdentifier --Identificador del Puerto de Descarga    
DECLARE @intUniversalId       udtIdentifier       --Id del UniversalId que se asignara al Contenedor    
DECLARE @blnContainerIsFull   udtYesNo            --El Contenedor esta LLeno/Vacio    
DECLARE @intEIRId             udtIdentifier       --Id del EIR asociado al Contenedor    
DECLARE @intFiscalStatId      udtIdentifier       --Id del Estatus Fiscal    
DECLARE @intAdmStatId         udtIdentifier       --Id del Estatus Admvo Default    
DECLARE @intCustomerId        udtIdentifier       --Id del Cliente          <A quien se le Factura>    
DECLARE @intCustomerTypeId    udtIdentifier       --Id del Tipo de Cliente <A quien se le Factura>    
DECLARE @intOperatorTypeId    udtIdentifier       --Id del Tipo de Operador     
DECLARE @intOperatorId        udtIdentifier       --Id del Operador     
DECLARE @intRequiredTypeId    udtIdentifier       --Id del Tipo de quien solicito el servicio    
DECLARE @intRequiredId        udtIdentifier       --Id Solicitado por      
DECLARE @decWeight            udtDecimal          --Peso del Contendor    
DECLARE @intConsecId          udtIdentifier       --Id Consecutivo para Sellos, Daños, SobreDimensiones    
DECLARE @intSOStatusId        udtIdentifier       --Id del status dela maniobra   
DECLARE @strIsFull            varchar(1)          --Lleno o Vacio del Contenedor    
DECLARE @decOptimalTemp       udtDecimal          --Temperatura Optima EIR    
DECLARE @TempMeasu            udtIdentifier       --Unidad de Medidad de la Temperatura            
DECLARE @ContainerCategory    udtIdentifier       --Categoria o Clase del Contenedor                           
DECLARE @strFolio             varchar(255)  -- Maniobra de la que proviene el contendor en Cadena    
DECLARE @strBKIn              udtStringIdentifier --BK de Ingreso (Maniobra)    
DECLARE @dtmCmpDateIniSto     DATETIME            --Variable donde se almacena la Fec. Inicio de Almacenaje Calculada    
dECLARE @intVisitValida     udtIdentifier    
DECLARE @ExpoListId         udtIdentifier      
DECLARE @ShipIdList         udtIdentifier    
DECLARE @IMOCodeId          udtIdentifier    
DECLARE @TareList           udtDecimal    
DECLARE @strSeal  udtStringIdentifier     
DECLARE @blnIsValidate      udtIdentifier    
DECLARE @intReservationId   udtIdentifier    
DECLARE @intRecepType       udtIdentifier    
DECLARE @intTransId         udtIdentifier   
DECLARE @intDelType         udtIdentifier    
DECLARE @intContExists      udtIdentifier         --Almacena la cantidad de Contenedores que van a ingresar o salir de la Maniobra   
DECLARE @intInOutContainer  udtIdentifier         --Almacena la cantidad de Contenedores que ya ingresaron de la maniobra   
DECLARE @strEIRComments     udtStringIdentifier  
DECLARE @dtmDateEndSO       DATETIME              --Fecha de termino de la maniobra   
DECLARE @blnIsYardFiscal		udtYesNo				  --Indica si el contenedor esta en patio Fiscal o No  
  
   
BEGIN     
    
  --Variables para Casos de Error/Exito      
  SELECT @FAILURE = 1 --c/Errores      
  SELECT @SUCCESS = 0 --s/Errores      
  SELECT @EXISTS  = 2 --Contenedor ya exixte en el inventario      
      
  --Checa si las Transacciones estan Encadenadas      
  IF @@TRANCHAINED=1       
     --Si estan Encadenadas Aborta el SP      
     RETURN @FAILURE      
        
 --Evitar Dirty Reads      
  SET TRANSACTION ISOLATION LEVEL 1      
    
  --Determina si es de Recepcion(REC) ó Entrega(ENT) el Contenedor    
  SELECT @intServiceId   = VC.intServiceId,     
         @strService     = RTRIM(strServiceIdentifier)    
  FROM   tblclsVisitContainer VC, tblclsService S    
  WHERE  intVisitId                = @intVisitId      
         AND RTRIM(strContainerId) = @strContainerId     
         AND VC.intServiceId       = S.intServiceId     
         AND blnServiceActive      = 1    
    
    
  --ERROR: No Encontró el Servicio de la Visita    
  IF @@rowcount = 0   RETURN  @FAILURE     
    
      
/*******************************************************************************************   
                        RECEPCION/ENTRADA DE CONTENEDOR    
********************************************************************************************/   
   
  --Si el Contenedor es de Recepcion(Entrada)    
  IF RTRIM(@strService)='RECLL' OR RTRIM(@strService)='RECV' OR RTRIM(@strService)='RECVOS'    
  BEGIN    
    --Valida que NO este el Contendor Exista en el Inventario como Contendor Activo    
    IF NOT EXISTS (SELECT strContainerId FROM tblclsContainerInventory     
                   WHERE  RTRIM(strContainerId)     = RTRIM(@strContainerId)    
                    AND blnContainerInvActive = 1)    
    BEGIN              
        -->> Valida que la Integridad de la Informacion (Que la Visita se haya Guardado)    
        IF EXISTS ( SELECT *    
                    FROM   tblclsVisitContainer    
                    WHERE   intVisitId= @intVisitId  and     
                            RTRIM(strContainerId) = RTRIM(@strContainerId) and blnVisitContainerIsCancelled= 0)    
        /*******************************************************************************************   
         1.-Se valida la integridad de los datos y se obtinene toda la información necesaria para    
            realizar el ingreso   
        ********************************************************************************************/   
        BEGIN    
                
            --Obtiene la Orden de Servicio asociada en la Visita    
            SELECT @intServOrderId  = intServiceOrderId     
            FROM   tblclsVisitContainer           
            WHERE   intVisitId= @intVisitId  and     
                    RTRIM(strContainerId) = RTRIM(@strContainerId)    
                
            --Consulta la Visita de la Maniobra de Ingreso    
            SELECT @intVisitValida =intVisitId     
            FROM   tblclsContainerRecepDetail     
            WHERE  intContainerReceptionId=@intServOrderId  and     
                   RTRIM(strContainerId) =  RTRIM(@strContainerId)    
    
            SELECT @intRecepType = intContTransTypeId    
            FROM tblclsContainerTransacType    
            WHERE strContTransTypeIdentifier = 'ECRF'    
                
            --Si no encontró el registro regresa error    
            IF @@rowcount = 0 RETURN @FAILURE   
        
            --Si no tiene Asociada el No.Visita se manda Actualizar en la Maniobra para previnir que NO  Ingrese el Contenedor    
            IF @intVisitValida = 0    
            BEGIN    
                BEGIN TRANSACTION ContainerRecepDetail    
                UPDATE tblclsContainerRecepDetail     
                SET    intVisitId   = @intVisitId ,    
                       strContRecDetailComments  = strContRecDetailComments  + ' Ref.Visita : '+CONVERT(VARCHAR(6),@intVisitId )    
                WHERE  intContainerReceptionId = @intServOrderId  and     
             RTRIM(strContainerId)   = RTRIM(@strContainerId)    
                COMMIT TRANSACTION ContainerRecepDetail    
            END    
            
        END     
            
        --<< Valida que la Integridad de la Informacion (Que la Visita se haya Guardado)    
    
    
    
      --Obtiene el Mov. Fiscal, el Buque Viaje, los Puertos,Datos del Operador,     
      --Lleno,Orden de Servicio(Reception Id),Peso    
      SELECT @intServOrderId               = R.intContainerReceptionId    ,       
          @blnContainerIsFull           = RD.blnContRecDetailIsFull    ,     
             @intFiscalMovementId          = R.intFiscalMovementId        ,       
             @intVesselVoyageId            = R.intVesselVoyageId          ,       
             @strOriginPort                = R.strContRecepPortOfOriginId ,       
             @strDischargePort             = R.strContRecepDischargePortId,       
             @strFinalPort                 = R.strContRecepFinalPortId    ,      
             @intCustomerId                = R.intContRecepInvoiceToId    ,    
             @intCustomerTypeId            = R.intContRecepInvoiceToTypeId,      
             @intOperatorTypeId            = RD.intContRecDetailOperatorTypeId,    
             @intOperatorId       = RD.intContRecDetailOperatorId,    
             @intRequiredTypeId            = ISNULL(R.intContRecepRequiredTypeId,0)  ,         
             @intRequiredId                = ISNULL(R.intContRecepRequiredById,0),    
             @decWeight            = RD.decContRecDetailWeight    ,    
             @strBKIn                      =  RD.strBookingId,    
             @intReservationId             = intContainerReservationId, 
				@blnIsYardFiscal				 = R.blnIsYardFiscal        
      FROM   tblclsContainerRecepDetail RD,       
 tblclsContainerReception   R,       
             tblclsVisitContainer       VC    
      WHERE  RD.intContainerReceptionId   = R.intContainerReceptionId     
             AND VC.intVisitId            = RD.intVisitId     
             AND VC.strContainerId      = RD.strContainerId     
             AND VC.intVisitId            = @intVisitId     
             AND RTRIM(VC.strContainerId) = @strContainerId    
    
           
    
    
    
      --ERROR: No Encontró Informacion Relacionada al Contendor y Visita en la Recepción    
      IF @@rowcount = 0       
      BEGIN    
        SELECT '>>ERROR: No Encontró Informacion Relacionada al Contendor y Visita en la Recepción'    
        RETURN  @FAILURE     
      END    
          
    
      --Si el contendor se encuentra en una lista de exportación validad obtiene los datos de la lista     
      --para darle ingreso con estos datos a el inventario    
           --Si el contenedor existe en la tabla de pendientes, se actualiza el id de la lista de Expo     
        IF EXISTS(SELECT strContainerId FROM tblclsPendingContainers WHERE intVesselVoyageId = @intVesselVoyageId AND strContainerId = @strContainerId)    
    
        BEGIN    
            SELECT @ExpoListId = ISNULL(intContainerExpoListId,0) FROM tblclsPendingContainers WHERE intVesselVoyageId = @intVesselVoyageId AND strContainerId = @strContainerId    
    
            --Se confirma que el contenedor este en la lista de Exportación    
            IF EXISTS(SELECT strContainerId FROM tblclsContainerExpoListItem WHERE  tblclsContainerExpoListItem.intContainerExpoListId = @ExpoListId AND tblclsContainerExpoListItem.strContainerId = @strContainerId)    
    
            BEGIN    
                SELECT @intOperatorId  = tblclsContainerExpoListItem.intShippingLineId,    
                  @IMOCodeId = tblclsContainerExpoListItem.intIMOCodeId,       
                       --@strBKIn = tblclsContainerExpoListItem.strBookingId,       
                       --@strSeal = tblclsContainerExpoListItem.strContExpListSealNumber,    
                       @decOptimalTemp = tblclsContainerExpoListItem.decContExpListTemperature,       
                       @TareList   = tblclsContainerExpoListItem.decContExpListContainerTare,    
                       @decWeight = isnull(decContExpListNetWeight,0),    
                       @strDischargePort = isnull(strContExpListDischargePortId,'0'),    
                       @strFinalPort = isnull(strContExpListFinalPortId,'0')    
                FROM   tblclsContainerExpoListItem,    
              tblclsShippingLine    
                WHERE  tblclsContainerExpoListItem.intContainerExpoListId = @ExpoListId AND    
                       tblclsContainerExpoListItem.strContainerId = @strContainerId  AND    
                       tblclsContainerExpoListItem.intShippingLineId = tblclsShippingLine.intShippingLineId    
                --Se asigna a la variable @blnIsValidate = 1 para indicar que el contenedor si esta en lista    
                SELECT @blnIsValidate = 1    
           END    
       END    
    
    
    
      --Obtiene el Id del Estatus Fiscal (En Deposito)    
      SELECT @intFiscalStatId = intContFisStatusId    
      FROM   tblclsContainerFiscalStatus      
      WHERE  RTRIM(strContFisStatusIdentifier) = 'DEPOSITO'    AND    
             blnContFisStatusActive            = 1        
    
      --ERROR: No Encontró el Estatus Fiscal    
      IF @@rowcount = 0       
      BEGIN    
        SELECT '>>ERROR: No Encontró el Estatus Fiscal'    
        RETURN  @FAILURE     
      END    
            
      --Obtiene el Id del Estatus Administrativo (Pendiente de Ubicación)    
      SELECT @intAdmStatId = intContAdmStatusId             
      FROM   tblclsContainerAdmStatus      
      WHERE  RTRIM(strContAdmStatusIdentifier) =    'PATIO' AND    
             blnContAdmStatusActive           = 1        
    
      --ERROR: No Encontró el Estatus Administrativo    
      IF @@rowcount = 0       
      BEGIN    
        SELECT '>>ERROR: No Encontró el Estatus Administrativo'    
        RETURN  @FAILURE     
      END    
          
    
    
    --Genera el Universal Id    
      EXECUTE @StatErrSP = spGetUniversalId @intUniversalId OUTPUT    
    
      --Valida que se haya Generado el Universal Id    
      IF @StatErrSP = 1             
      BEGIN    
        --ERROR: Hubo un Error al Generar el UniversalId    
        SELECT '>>ERROR: Hubo un Error al Generar el UniversalId'    
        RETURN  @FAILURE     
      END    
          
      IF @intUniversalId IS NULL           
      BEGIN    
        --ERROR: Al Generar el UniversalId    
            
        SELECT '>>ERROR: Al Generar el UniversalId'    
        RETURN  @FAILURE     
      END    
                               
      --Valida que el Contenedor Tenga un EIR Asociado    
      --LISLAS 04/03/2010 Se elimino o adecuo todo lo que tiene que ver con el EIR por que se elimino del proceso de ingreso y salida
      /*IF EXISTS(SELECT * FROM tblclsEIR     
                  WHERE intVisitId          = @intVisitId     
                  AND RTRIM(strContainerId) = @strContainerId)    
      BEGIN   */ 
        --Obtiene la Información el Id EIR     
        SELECT @intEIRId          = intEIRId ,     
     @decOptimalTemp    = decContainerInvOptTemp ,     
               @TempMeasu         = intContainerInvTempMeasu,    
               @ContainerCategory = intContainerCategoryId,  
               @strEIRComments    = strEIRComments        
        FROM tblclsEIR    
        WHERE intVisitId          = @intVisitId     
        AND RTRIM(strContainerId) = @strContainerId    
    
        -->>Calcular Fecha de Inicio de Almacenaje de acuerdo al Tipo de Trafico(IMPO Y RETORNO al dia siguiente cualquier otro al mismo dia)    
        SELECT @dtmCmpDateIniSto = (CASE WHEN strFiscalMovementIdentifier   ='IMPO' OR strFiscalMovementIdentifier   ='RET'    
                                         THEN DateAdd(dd,1,@dtmExecuteDate )    
        ELSE @dtmExecuteDate     
                                    END)     
        FROM tblclsFiscalMovement     
        WHERE intFiscalMovementId  = @intFiscalMovementId    
   
        /*******************************************************************************************   
         2.-   
            >>Se ingresa la información al inventario    
            >>Se Inserta la info. en el historico   
            >>Se Inserta la transacción de Ingreso   
        ********************************************************************************************/   
   
        BEGIN TRAN ContainerInv --Inicia la Transacción    
    
        --Ingresa el Contenedor al Inventario    
        INSERT INTO tblclsContainerInventory      
                    ( intContainerUniversalId       ,strContainerId             , intContFisStatusId,       
                      intContAdmStatusId            ,intFiscalMovementId        , blnContainerIsFull,       
                      intCustomerId                 ,intContainerInvOperatorId  , intContainerInvOperatorTypeId,       
                      intContRecepRequiredTypeId,intContRecepRequiredById ,dtmContainerInvReceptionDate  ,decContainerInventoryWeight, strContainerInvPortOfOriginId,      
                      strContainerInvDischargePortId,strContainerInvFinalPortId , intContainerInvVesselVoyageId,     
                      blnContainerInvActive         ,strContainerInvComments    , dtmContainerInvCreationStamp,     
                      strContainerInvCreatedBy      ,dtmContainerInvLastModified, strContainerInvLastModifiedBy,    
                      intContainerCategoryId        , intContPhyStatId ,dtmContainerInvIniStorageDate,    
                      decContainerInvOptTemp,intContainerInvTempMeasu,blnIsYardFiscal)       
                  
           VALUES   (@intUniversalId  ,@strContainerId     ,@intFiscalStatId   ,    
                     @intAdmStatId    ,@intFiscalMovementId,@blnContainerIsFull,    
                     @intCustomerId   ,@intOperatorId      ,@intOperatorTypeId ,              
                     @intRequiredTypeId  ,@intRequiredId ,@dtmExecuteDate       ,@decWeight          ,@strOriginPort     ,    
                     @strDischargePort,@strFinalPort       ,@intVesselVoyageId ,    
 1                ,@strService + ' ' + @strEIRComments  ,getDate()          ,    
                     @strUser         ,getDate()           ,@strUser           ,    
                     @ContainerCategory , 0, @dtmCmpDateIniSto,    
                     @decOptimalTemp,@TempMeasu,@blnIsYardFiscal      )    
    
    
        --Estatus del Insert    
        SELECT @StatusError = @@Error    
                  
        IF @StatusError = 1  --Validacion al Insertar el Registro    
        BEGIN    
          ROLLBACK TRAN   ContainerInv  --Aborta los Cambios    
          SELECT '>>--ERROR: Al Ingresar el Contenedor a Inventario' 
          raiserror 99999 'ERROR:  Al Ingresar el Contenedor %1! a Inventario',@strContainerId       
          RETURN @FAILURE  --ERROR: Al Ingresar el Contenedor a Inventario    
        END    
           
          
    
        --Convierte    
        SELECT @strIsFull = CONVERT(varchar(1),@blnContainerIsFull)        
        --***Actualiza el Estatus Administrativo del Contenedor    
      --  EXECUTE @StatErrSP = spUpdateContainerStatus @intUniversalId,1 , @strIsFull,'CONEC'    
                  
        IF @StatErrSP  = 1 --Validacion del SP    
        BEGIN    
          ROLLBACK TRAN   --Aborta los Cambios    
          SELECT '>>ERROR: Al Actualizar el Est. Admvo del Contenedor'
          raiserror 99999 'ERROR: Al Actualizar el Est. Admvo del Contenedor %1!',@strContainerId    
          RETURN @FAILURE --ERROR: Al Actualizar el Est. Admvo del Contenedor    
        END    
   
        COMMIT TRAN ContainerInv  --Aplica los Cambios     
           
         --Comienza la Transacción   
        BEGIN TRANSACTION ContainerHistory   
   
        --Inserta un registro en la tabla del Histórico de Contenedor   
      INSERT INTO tblclsContainerHistory   
                        (intContainerUniversalId,strContainerId,intContFisStatusId,intFiscalMovementId,   
                        intContHistOperatorId,intContHistOperatorTypeId,intContainerReservationId,   
                   strBookingId,intContHistRecepTransTypeId,dtmContHistReceptionDate,strContHistPortOfOriginId,   
                        strContHistDischargePortId,strContHistFinalPortId,intContHistVesselVoyageId,dtmContHistCreationStamp,   
           strContHistCreatedBy,dtmContHistLastModified,strContHistLastModifiedBy)                                                                                                                                                      
               VALUES (@intUniversalId,@strContainerId,@intFiscalStatId,@intFiscalMovementId,@intOperatorId,   
                        @intOperatorTypeId,@intReservationId,@strBKIn,@intRecepType,@dtmExecuteDate,@strOriginPort,   
                        @strDischargePort,@strFinalPort,@intVesselVoyageId,GETDATE(),@strUser,GETDATE(),@strUser)   
           
        --Si no hubo error   
        IF @@Error = 0   
          BEGIN   
             COMMIT TRANSACTION ContainerHistory   
          END   
        ELSE --si hubo error   
     BEGIN   
             ROLLBACK TRANSACTION ContainerHistory   
             RETURN @FAILURE   
          END   
   
        /*En Sig. SP se realiza:    
            1.-Inserta una Transaccion en tblclsContainerTransaccion   
            2.-Genera el Historial para ECRF en tblclsServiceOrderHistory   
        */   
   
        SELECT @strFolio  = 'El '+CONVERT(VARCHAR(10),@dtmExecuteDate,103)+' '+CONVERT(VARCHAR(10),@dtmExecuteDate,108)+' con No.Solicitud: '+convert(VARCHAR(8),@intServOrderId ) + ' en Visita '+convert(VARCHAR(8),@intVisitId) + ' EIR : '+convert(VARCHAR(8),@intEIRId )   
        SELECT @strFolio    
            EXECUTE @StatErrSP = spUpdateHistoryCheckInOut 'ECRF' ,@intUniversalId,@intServiceId,@intServOrderId,0,@strFolio  ,@strUser   
           
       /*******************************************************************************************   
         3.- Se actualiza o incerta el resto de la información para el contenedor que ingreso   
            >>Se Actualiza la tabla de EIR con el Universal generado    
            >>Se relacionan los Productos, sellos, sobredimenciones, etc al nuevo universal   
        ********************************************************************************************/   
       
        --**ACTUALIZA el Campo Universal Id del EIR asociado al Contenedor    
        BEGIN TRAN    
          UPDATE tblclsEIR     
          SET    intContainerUniversalId= @intUniversalId    
          WHERE  intEIRId =@intEIRId    
    
        --Estatus del Update    
        SELECT @StatusError = @@Error    
    
        IF @StatusError = 1  --Validacion al Actualizar el Registro    
        BEGIN    
          ROLLBACK TRAN    --Aborta los Cambios    
          SELECT '>>ERROR: Al Actualizar UniversalId del EIR'    
          raiserror 99999 'ERROR: Al Actualizar UniversalId del contendor %1! en EIR',@strContainerId      
    
          RETURN @FAILURE  --ERROR: Al Actualizar UniversalId del EIR    
        END    
          ELSE COMMIT TRAN    --Aplica los Cambios    
    
                  
        --**ACTUALIZA el Campo Universal Id de la Visita asociada al Contenedor    
        BEGIN TRAN  VisitContainer             
          UPDATE tblclsVisitContainer    
          SET    intContainerUniversalId= @intUniversalId    
          WHERE  intVisitId   = @intVisitId     
          AND    strContainerId = @strContainerId           
    
        --Estatus del Update    
        SELECT @StatusError = @@Error    
                  
        IF @StatusError = 1  --Validacion al Actualizar el Registro    
        BEGIN    
          ROLLBACK TRAN VisitContainer  --Aborta los Cambios    
          SELECT 'ERROR: Al Actualizar UniversalId del Det. Visita'
          raiserror 99999 'ERROR: Al Actualizar UniversalId del contendor %1! en Visitas',@strContainerId            
          RETURN @FAILURE  --ERROR: Al Actualizar UniversalId del Det. Visita    
        END    
          ELSE COMMIT TRAN VisitContainer   --Aplica los Cambios    
    
                  
        --**ACTUALIZA el Campo Universal Id del Detalle de Recepcion Asociado al Contenedor    
        BEGIN TRAN ContainerRecepDetail    
          UPDATE tblclsContainerRecepDetail    
          SET    intContainerUniversalId = @intUniversalId    
          WHERE  intContainerReceptionId = @intServOrderId AND     
                 strContainerId = @strContainerId           
    
        --Estatus del Update    
        SELECT @StatusError = @@Error    
    
        IF @StatusError = 1  --Validacion al Actualizar el Registro    
        BEGIN    
          ROLLBACK TRAN    ContainerRecepDetail --Aborta los Cambios    
          SELECT '>>ERROR: Al Actualizar UniversalId del Det. Recepcion'
          raiserror 99999 'ERROR: Al Actualizar UniversalId del contendor %1! en la Maniobra de Recepcion',@strContainerId                  
          RETURN @FAILURE  --ERROR: Al Actualizar UniversalId del Det. Recepcion    
        END    
          ELSE COMMIT TRAN ContainerRecepDetail   --Aplica los Cambios    
            
        -- Actualizar Fecha de Entrada e Insertar Visita a la Cola de Visitas (esto se hace desde el PB)    
        -- con un Metodo del Objeto de la Visita con el spVisitInOut    
              
        --** INSERTA PRODUCTOS DEL CONTENEDOR AL INVENTARIO    
        EXECUTE @StatErrSP = spInsertContProductsInventory @intServOrderId ,    
                                                           @strContainerId,    
                                                    @intUniversalId,    
                                                           @intCustomerId,    
                                                           @intCustomerTypeId,@strUser       
    
        IF @StatErrSP  = 1 --Validacion del SP    
        BEGIN              
            SELECT 'Al Insertar en el Inventario los Prods del Contenedor'
            raiserror 99999 'ERROR: Al Insertar en el Inventario los Prods del Contenedor %1!',@strContainerId                
          RETURN @FAILURE --ERROR: Al Insertar en el Inventario los Prods del Contenedor    
        END    
            
        --** INSERTA IMOS     
        EXECUTE @StatErrSP = spInsertIMOSInventory @intEIRId,@intUniversalId,@strUser    
        --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    
        IF @blnIsValidate = 1  and  @IMOCodeId <>0  
        BEGIN    
            IF NOT EXISTS(SELECT intIMOCodeId FROM tblIMOCode_ContainerInventory WHERE intIMOCodeId = @IMOCodeId AND intContainerUniversalId = @intUniversalId )    
            BEGIN    
                BEGIN TRAN  IMOSREC --Empieza la Transaccion    
                    
                INSERT INTO  tblIMOCode_ContainerInventory                         
                            (intIMOCodeId            ,intContainerUniversalId    ,dtmContIMOCodeCreationStamp,    
                             strContIMOCodeCreatedBy ,dtmContIMOCodeLastModified ,strContIMOCodeLastModifiedBy)    
                VALUES       (@IMOCodeId,@intUniversalId, getDate(),    
                             @strUser     ,      getDate(), @strUser)    
                    
                --Estatus del Insert    
                SELECT @StatusError = @@Error    
                    
                IF @StatusError = 1  --Validacion al Insertar el Registro    
                BEGIN    
           ROLLBACK TRAN   IMOSREC   --Aborta los Cambios    
                     raiserror 99999 'ERROR: No se pudo insertar el Imo de la LIsta de Exportación '  
  
                     RETURN @FAILURE  --ERROR: Hubo Error al Insertar el Sello del Contenedor    
                END    
                ELSE    
                     COMMIT TRAN   IMOSREC   --Aplica los Cambios        
            END      
        END    
        --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    
    
                 
        IF @StatErrSP  = 1 --Validacion del SP    
        BEGIN              
          SELECT 'Al Insertar en el Inventario los IMOS del Contenedor '    
          raiserror 99999 'ERROR: Al Insertar en el Inventario los IMOS del Contenedor %1!',@strContainerId                  
          RETURN @FAILURE --ERROR: Al Insertar en el Inventario los IMOS del Contenedor     
        END    
    
        --** INSERTA DAÑOS    
        EXECUTE @StatErrSP = spInsertDamagesInventory @intEIRId,@intUniversalId,'',@strUser    
                 
        IF @StatErrSP  = 1 --Validacion del SP    
        BEGIN              
 SELECT '>>Al Insertar en el Inventario los Daños del Contenedor '
           raiserror 99999 'ERROR: Al Insertar en el Inventario los Daños del Contenedor %1!',@strContainerId                      
          RETURN @FAILURE --ERROR: Al Insertar en el Inventario los Daños del Contenedor     
        END    
    
        --** INSERTA SOBREDIMENSIONES    
        EXECUTE @StatErrSP = spInsertOversizesInventory @intEIRId,@intUniversalId,@strUser                 
                 
        IF @StatErrSP  = 1 --Validacion del SP    
        BEGIN              
          SELECT '>>Al Insertar en el Inventario los Sobredimensiones del Contenedor '    
          RETURN @FAILURE --ERROR: Al Insertar en el Inventario los Sobredimensiones del Contenedor     
        END    
    
        --** INSERTA SELLOS    
        EXECUTE @StatErrSP = spInsertSealsInventory @intEIRId,@intUniversalId,' ',@strUser    
        
        IF @StatErrSP  = 1 --Validacion del SP    
        BEGIN              
          SELECT '>>Al Insertar en el Inventario los Daños del Contenedor '    
          RETURN @FAILURE --ERROR: Al Insertar en el Inventario los Daños del Contenedor     
        END    
    
         
        BEGIN TRAN BK    
    
        --**Insertar Booking en el Inventario  Agregado por BLOERA 21-Ago-2006    
        INSERT INTO tblclsContainerInvBooking    
        (intContainerUniversalId  ,     
        strBookingId                   ,    
        blnContInvBookMod              ,    
        intContInvBookComments         ,    
        dtmContInvBookCreationStamp,        
        strContInvBookCreatedBy        ,    
        dtmContInvBookLastModified     ,    
        strContInvBookLastModifiedBy   )    
        VALUES (@intUniversalId,     
                @strBKIn    ,    
                1,    
                'BK de Ingreso por Ruta Federal',    
                getDate(),    
      @strUser,    
                getDate(),    
                @strUser)    
    
        --Estatus del Update    
        SELECT @StatusError = @@Error    
                  
        IF @StatusError = 1  --Validacion al Actualizar     
        BEGIN    
     ROLLBACK TRAN  BK  --Aborta los Cambios    
          SELECT '>>Al Insertar el BK de Ingreso'     
          RETURN @FAILURE  --Al Insertar el BK de Ingreso    
        END    
          ELSE COMMIT TRAN BK   --Aplica los Cambios    
    
        --Se obtiene la cantidad de contenedores que estan en la maniobra(@intContExists) y el total de los qua ya ingresaron(@intInOutContainer)   
        SELECT  @intContExists      = COUNT(intContainerReceptionId ),   
                @intInOutContainer  = SUM(case when isnull(intContainerUniversalId,0) <> 0 then 1 ELSE 0 END)    
        FROM tblclsContainerRecepDetail    
        WHERE intContainerReceptionId = @intServOrderId     
           
        IF @intContExists = @intInOutContainer   
        BEGIN   
            --Obtiene el Estatus de la Orden de Servicio (EN PROCESO)    
            SELECT @intSOStatusId = intSOStatusId         
            FROM   tblclsServiceOrderStatus      
            WHERE  strSOStatusIdentifier = 'TER'    
            AND tblclsServiceOrderStatus.blnSOStatusActive = 1        
               
            SELECT @dtmDateEndSO = GETDATE()  
  
            --ERROR: No Encontró el Estatus Administrativo    
            IF @@rowcount = 0   RETURN  @FAILURE             
   
        END   
        ELSE   
    BEGIN   
            --Obtiene el Estatus de la Orden de Servicio (EN PROCESO)    
            SELECT @intSOStatusId = intSOStatusId         
            FROM   tblclsServiceOrderStatus      
            WHERE  strSOStatusIdentifier = 'EJP'    
 AND tblclsServiceOrderStatus.blnSOStatusActive = 1        
              
            SELECT @dtmDateEndSO = NULL   
  
            --ERROR: No Encontró el Estatus Administrativo    
            IF @@rowcount = 0   RETURN  @FAILURE             
   
        END   
           
         BEGIN TRAN ContainerReception    
          
        --**Actualiza el Estatus=EJECUCION EN PROCESO  de la Recepcion                       
         UPDATE tblclsContainerReception    
         SET    intSOStatusId           = @intSOStatusId,  
                dtmContRecepDateIn      = @dtmDateEndSO    
         WHERE  intContainerReceptionId = @intServOrderId              
    
                  
        IF @@Error = 1  --Validacion al Actualizar     
        BEGIN    
          ROLLBACK TRAN ContainerReception --Aborta los Cambios    
          SELECT '>>Al Actualizar el Estatus de la Recepcion'     
          RETURN @FAILURE  --ERROR: Al Actualizar el Estatus de la Recepcion    
        END    
          ELSE COMMIT TRAN ContainerReception   --Aplica los Cambios    
   
    
        --**Fin del Proceso de Entrada de Contenedor a la Terminal     
    
    
        --**Se lanza proceso para Actualizar la Lista de Pendientes por Ingresos.    
        IF @intVesselVoyageId>0     
           EXECUTE spRefreshPendingContainers @intVesselVoyageId, @strUser    
            
        IF @blnIsValidate = 1   
            RETURN 3 -- Que indica que el contenedor entro con información de la listas Validada   
        ELSE          
            RETURN @SUCCESS --Exito de la Entrada del Contenedor x RF    
   
     /*   END --Si el Contenedor tiene EIR Asociado    
      ELSE    
      BEGIN    
        --ERROR: El Contenedor No tiene ningun EIR asociado     
        --SELECT '>>ERROR: El Contenedor No tiene ningun EIR asociado '    
        raiserror 99999 'ERROR: El Contenedor %1! No tiene ningun EIR asociado ',@strContainerId    
        RETURN @FAILURE    
      END */   
          
    END --IF NOT EXISTS     
    ELSE    
    BEGIN    
      SELECT '>>ERROR : Contenedor ya Existe en el Inventario    '    
      RETURN @EXISTS --ERROR : Contenedor ya Existe en el Inventario        
    END    
  END    
    
  -- ***************ENTREGA  /SALIDA  DE CONTENEDOR *******************---    
    
  --Si el Contenedor es de Recepcion(Entrada)    
  IF RTRIM(@strService)='ENTLL' OR RTRIM(@strService)='ENTV'    
  BEGIN    
    --Valida que el Contenedor Exista en el Inventario como Contendor Activo    
    IF EXISTS (SELECT strContainerId FROM tblclsContainerInventory     
               WHERE  RTRIM(strContainerId)     = RTRIM(@strContainerId)    
                      AND blnContainerInvActive = 1)    
    BEGIN    
            
        -->> Valida que la Integridad de la Informacion (Que la Visita se haya Guardado)    
        IF EXISTS ( SELECT *    
             FROM   tblclsVisitContainer           
                    WHERE   intVisitId            = @intVisitId  and     
                            RTRIM(strContainerId) = RTRIM(@strContainerId) and blnVisitContainerIsCancelled= 0)    
        BEGIN    
            --Obtiene la Orden de Servicio asociada en la Visita    
            SELECT  @intServOrderId  = intServiceOrderId     
            FROM    tblclsVisitContainer           
            WHERE   intVisitId= @intVisitId  and     
                    RTRIM(strContainerId) = RTRIM(@strContainerId)    
                
            --Consulta la Visita de la Maniobra de Ingreso    
            SELECT @intVisitValida = intVisitId     
            FROM   tblclsContainerDeliveryDetail     
            WHERE  intContainerDeliveryId=@intServOrderId  and     
                   RTRIM(strContainerId) =  RTRIM(@strContainerId)    
                
            --Si no tiene Asociada el No.Visita se manda Actualizar en la Maniobra para prevenir que el Contenedor se quede en Inventario    
            IF @intVisitValida = 0    
            BEGIN    
                BEGIN TRANSACTION ContainerDeliveryDetail    
                UPDATE tblclsContainerDeliveryDetail     
                SET    intVisitId   = @intVisitId ,    
                strContDelDetailComments  = strContDelDetailComments  + ' Ref.Visita : '+CONVERT(VARCHAR(6),@intVisitId )    
                WHERE  intContainerDeliveryId = @intServOrderId  and     
                       RTRIM(strContainerId)   = RTRIM(@strContainerId)    
                COMMIT TRAN ContainerDeliveryDetail    
             END     
       END    
        --<< Valida que la Integridad de la Informacion (Que la Visita se haya Guardado)    
    
    
      SELECT @intServOrderId = D.intContainerDeliveryId,       
             @intUniversalId = DD.intContainerUniversalId    
      FROM   tblclsContainerDelivery D,       
             tblclsContainerDeliveryDetail DD,       
             tblclsVisitContainer  VC    
      WHERE  D.intContainerDeliveryId = DD.intContainerDeliveryId     
             AND DD.intVisitId = VC.intVisitId      
             AND  DD.strContainerId = VC.strContainerId      
             AND  VC.intVisitId     = @intVisitId     
             AND  VC.strContainerId = @strContainerId    
    
    
      --Obtener el EIR Salida del Contenedor    
      SELECT @intEIRId          = intEIRId                    
      FROM  tblclsEIR    
      WHERE intVisitId                = @intVisitId     
            AND RTRIM(strContainerId) = @strContainerId    
    
    
      --ERROR: No Encontró Informacion Relacionada al Contendor y Visita en la Delivery    
--      IF @@rowcount = 0   RETURN  @FAILURE     
           
         --Obtiene el Id del Tipo de Recepción   
        SELECT @intDelType = intContTransTypeId   
        FROM tblclsContainerTransacType   
        WHERE strContTransTypeIdentifier = 'SCRF'   
           
        BEGIN TRANSACTION   
           
        --Actualiza la Tabla del Historial del contenedor   
        UPDATE tblclsContainerHistory   
    SET    intContHistDelTransTypeId = @intDelType,   
               dtmContHistDeliveryDate   = @dtmExecuteDate,   
               dtmContHistLastModified   = GETDATE(),   
               strContHistLastModifiedBy = @strUser   
        WHERE  intContainerUniversalId   = @intUniversalId   
   
   
        --Si no hubo error   
        IF @@Error = 0   
          BEGIN   
             COMMIT TRANSACTION   
             PRINT 'NO HUBO ERROR AL ACTUALIZAR EL HISTORICO '   
          END   
        ELSE --si hubo error   
          BEGIN   
             ROLLBACK TRANSACTION   
             PRINT 'HUBO ERROR AL ACTUALIZAR EL HISTORICO'   
             RETURN @FAILURE   
          END   
   
   
    
      --Actualiza LA tblclsContainerTransaccion Y tblclsServiceOrderHistory    
   SELECT @strFolio  = 'El '+ CONVERT(VARCHAR(10),@dtmExecuteDate,103)+' '+CONVERT(VARCHAR(10),@dtmExecuteDate,108)+' con No.Solicitud: '+convert(VARCHAR(8),@intServOrderId ) + ' en Visita '+convert(VARCHAR(8),@intVisitId) + ' EIR :' + convert(VARCHAR(8),@intEIRId)    
      EXECUTE @StatErrSP = spUpdateHistoryCheckInOut 'SCRF',@intUniversalId,@intServiceId,@intServOrderId,0,@strFolio   ,@strUser    
      IF @StatErrSP  = 1 --Validacion del SP    
      BEGIN    
        PRINT 'ERROR EL EL spUpdateHistoryServiceOrder '    
        RETURN @FAILURE --ERROR: Hubo un Error al Actualizar en el Histórico de de la Orden de Servicio    
      END    
            
      --**ACTUALIZA el Campo Activo en 0 del Inventario (Marca como Borrado)    
      BEGIN TRAN ContainerInventory    
        UPDATE tblclsContainerInventory    
        SET    blnContainerInvActive = 0    
        WHERE  intContainerUniversalId = @intUniversalId    
               AND strContainerId      = @strContainerId    
    
      --Estatus del Update    
      SELECT @StatusError = @@Error    
    
      IF @StatusError = 1  --Validacion al Actualizar el Registro    
      BEGIN    
        ROLLBACK TRAN    ContainerInventory --Aborta los Cambios    
        RETURN @FAILURE  --ERROR: Al Actualizar el Campo Activo del Inventario    
      END    
        ELSE COMMIT TRAN    ContainerInventory --Aplica los Cambios    
           
      PRINT 'ALCANZO A DESACTIVAR EL CONTENEDOR '    
      -- Actualizar Fecha de Salida y Borra la Visita a la Cola de Visitas (esto se hace desde el PB)    
      -- con un Metodo del Objeto de la Visita con el spVisitInOut    
   
   
   
      IF RTRIM(@strService)='ENTV'   
      BEGIN   
        SELECT  @intContExists      = tblclsContainerDelivery.intContDelAmountReserv,    
                @intInOutContainer  = SUM( CASE WHEN tblclsContainerInventory.blnContainerInvActive = 0 THEN 1 ELSE 0 END)  
        FROM    tblclsContainerDelivery,   
                tblclsContainerDeliveryDetail,  
                tblclsContainerInventory   
        WHERE   tblclsContainerDelivery.intContainerDeliveryId      = tblclsContainerDeliveryDetail.intContainerDeliveryId and   
                tblclsContainerInventory.intContainerUniversalId    = tblclsContainerDeliveryDetail.intContainerUniversalId and  
                tblclsContainerDelivery.intContainerDeliveryId      =  @intServOrderId   
        GROUP BY tblclsContainerDelivery.intContainerDeliveryId    
      END   
      ELSE   
      BEGIN   
        SELECT @intContExists       = COUNT(intContainerDeliveryId) ,    
               @intInOutContainer  = SUM(case when EXISTS(SELECT intContainerUniversalId    
                                                            FROM    tblclsContainerInventory    
                                                            WHERE   blnContainerInvActive = 0 AND   
                                                                  intContainerUniversalId = tblclsContainerDeliveryDetail.intContainerUniversalId   ) then 1 ELSE 0 END)   
        FROM tblclsContainerDeliveryDetail   
        WHERE intContainerDeliveryId = @intServOrderId   
        GROUP BY intContainerDeliveryId    
      END   
       
      IF @intContExists = @intInOutContainer   
        BEGIN   
            --Obtiene el Estatus de la Orden de Servicio (TERMINADO)    
            SELECT @intSOStatusId = intSOStatusId         
            FROM   tblclsServiceOrderStatus      
            WHERE  strSOStatusIdentifier = 'TER'    
            AND tblclsServiceOrderStatus.blnSOStatusActive = 1        
              
             SELECT @dtmDateEndSO = GETDATE()  
   
          --ERROR: No Encontró el Estatus Administrativo    
            IF @@rowcount = 0   RETURN  @FAILURE             
   
        END   
        ELSE   
        BEGIN   
            --Obtiene el Estatus de la Orden de Servicio (EN PROCESO)    
            SELECT @intSOStatusId = intSOStatusId         
            FROM   tblclsServiceOrderStatus      
            WHERE  strSOStatusIdentifier = 'EJP'    
            AND tblclsServiceOrderStatus.blnSOStatusActive = 1        
  
             SELECT @dtmDateEndSO = NULL  
               
           --ERROR: No Encontró el Estatus Administrativo    
            IF @@rowcount = 0   RETURN  @FAILURE             
   
        END   
      --**Actualiza el Estatus la maniobra   
      BEGIN TRAN ContainerDelivery              
    UPDATE tblclsContainerDelivery    
      SET    intSOStatusId           = @intSOStatusId,  
             dtmContDelDateOut       = @dtmDateEndSO     
      WHERE  intContainerDeliveryId = @intServOrderId              
    
         
      IF @@Error = 1  --Validacion al Actualizar     
      BEGIN    
        ROLLBACK TRAN    ContainerDelivery --Aborta los Cambios    
        RETURN @FAILURE  --ERROR: Al Actualizar el Estatus de la Recepcion    
      END    
      ELSE COMMIT TRAN   ContainerDelivery --Aplica los Cambios    
   
                       
    
      --**Fin del Proceso de Salida de Contenedor a la Terminal     
      RETURN @SUCCESS --Exito de la Salida del Contenedor X RF    
    END     
    ELSE    
       RETURN @EXISTS --ERROR : Contenedor ya Existe en el Inventario    
  END    
END

