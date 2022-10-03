Imports System.Web.Services
Imports System.Web.Services.Protocols
Imports System.ComponentModel
Imports System.Data.Odbc
Imports System.Data.OleDb
Imports System.Data
Imports System.Security.Cryptography
Imports SW_CalathusMobile.Informacion_de_Usuario
Imports System.IO
Imports System.Text
Imports iTextSharp.text.pdf

' Para permitir que se llame a este servicio web desde un script, usando ASP.NET AJAX, quite la marca de comentario de la siguiente línea.
' <System.Web.Script.Services.ScriptService()> _
<System.Web.Services.WebService(Namespace:="http://tempuri.org/")> _
<System.Web.Services.WebServiceBinding(ConformsTo:=WsiProfiles.BasicProfile1_1)> _
<ToolboxItem(False)> _
Public Class Servicio_Vacios
    Inherits System.Web.Services.WebService


    Dim ds_ValidVisitItems As New Data.DataSet()
    Dim adp_ValidVisitItems_adapter As New Data.OleDb.OleDbDataAdapter()


    Dim oleDBconnx As OleDbConnection
    Dim oleDBcom As OleDbCommand

    'Contructor del Servicio Web
    Public Sub New()
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand
    End Sub

    <WebMethod()> _
   Public Function Login(ByVal usuario As String, ByVal password As String) As DataTable
        'Dim usuario = "ricardo"
        'Dim password = "E10ADC3949BA59ABBE56E057F20F883E"

        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand

        '----------------------------------
        Dim _ODBPar_UserId As New OleDbParameter("@intUserId", OleDbType.Integer)
        Dim _ODBPar_UserName As New OleDbParameter("@strUserName", OleDbType.VarChar)
        Dim _ODBPar_AuthorizationPassword As New OleDbParameter("@strUserAuthorizationPassword", OleDbType.VarChar)
        Dim _ODBPar_UserPsw As New OleDbParameter("@strUserPassword", OleDbType.VarChar)
        Dim _ODBPar_Active As New OleDbParameter("@blnUserActive", OleDbType.Integer)
        Dim ls_SQL_Command As String
        'redefinicion de parametros

        _ODBPar_UserId.Value = 0
        _ODBPar_UserName.Value = usuario
        _ODBPar_UserPsw.Value = password
        _ODBPar_AuthorizationPassword.Value = ""
        _ODBPar_Active.Value = 1

        ls_SQL_Command = "spFindtblclsUser"

        ' asociacion de parametros al comando

        oleDBcom.Parameters.Add(_ODBPar_UserId)
        oleDBcom.Parameters.Add(_ODBPar_UserName)
        oleDBcom.Parameters.Add(_ODBPar_UserPsw)
        oleDBcom.Parameters.Add(_ODBPar_AuthorizationPassword)
        oleDBcom.Parameters.Add(_ODBPar_Active)

        oleDBcom.CommandText = ls_SQL_Command
        oleDBcom.CommandType = CommandType.StoredProcedure
        Dim DataResult As DataTable = New Data.DataTable() 'DataSet = New DataSet()
        DataResult.TableName = "TrearDatos"
        Dim adapter As OleDbDataAdapter = New OleDbDataAdapter(oleDBcom)

        Try
            oleDBconnx.Open()
            'oleDBcom.ExecuteNonQuery()
            adapter.Fill(DataResult)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
        Finally
            oleDBconnx.Close()
            oleDBconnx.Dispose()
            oleDBconnx = Nothing

        End Try
        Return DataResult

    End Function


    '******************************Ventana Disponibilidad************************************

    <WebMethod()> _
   Public Function Consultar_Info(ByVal VisitId As Integer, ByVal VisitPlate As String, ByRef cadenaError As String) As DataTable

        Dim idt_result As DataTable = New DataTable ' Tabla con el query de resultados 
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        Dim istr_cmd As String '' cadena que tendra el comando sql 

        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()

        idt_result.TableName = "consultar_info"

        VisitPlate = VisitPlate.Trim.ToUpper
        If VisitId > 0 Or VisitPlate.Length > 0 Then
            If VisitPlate.Length > 0 Then
                istr_cmd = "SELECT intVisitId,   " & _
                         "strVisitPlate, " & _
                         "dtmVisitDatetimeIn, " & _
                         "dtmVisitDatetimeOut " & _
                         "FROM tblclsVisit  " & _
                         "WHERE ( tblclsVisit.strVisitPlate = '" & VisitPlate & "') " & _
                         "AND tblclsVisit.dtmVisitDatetimeOut IS  NULL "
            End If
            If VisitId > 0 Then
                istr_cmd = "SELECT intVisitId,   " & _
                         "strVisitPlate, " & _
                         "dtmVisitDatetimeIn, " & _
                         "dtmVisitDatetimeOut " & _
                         "FROM tblclsVisit  " & _
                         "WHERE ( tblclsVisit.intVisitId = " & VisitId & ") " & _
                         "AND tblclsVisit.dtmVisitDatetimeOut IS  NULL "
            End If
            iolecmd_comand.CommandText = istr_cmd

            iAdapt_comand.SelectCommand = iolecmd_comand
            Try
                iolecmd_comand.Connection.Open()
                iAdapt_comand.Fill(idt_result)
            Catch ex As Exception
                Dim strError As String
                strError = ObtenerError(ex.Message, 99999)
            Finally
                iolecmd_comand.Connection.Close()
                iolecmd_comand.Connection.Close()
                iolecmd_comand.Connection.Dispose()
                iAdapt_comand.SelectCommand.Connection.Close()
                iAdapt_comand.SelectCommand.Connection.Dispose()
            End Try

        End If
        iolecmd_comand = Nothing
        iAdapt_comand.Dispose()
        iAdapt_comand = Nothing
        Return idt_result
    End Function

    <WebMethod()> _
  Public Function Cargar_Grid(ByVal VisitId As Integer, ByVal VisitPlate As String, ByRef cadError As String) As DataSet
        '-----------------------------
        ' Dim VisitId = 693649
        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand

        '----------------------------------

        Dim lodb_VisitId As OleDbParameter = New OleDbParameter()
        Dim ls_SQL_Command As String
        'redefinicion de parametros


        lodb_VisitId.OleDbType = OleDbType.Integer
        lodb_VisitId.ParameterName = "@intVisitId"
        lodb_VisitId.Value = Integer.Parse(VisitId)

        ' asignacion de valores

        lodb_VisitId.Value = Integer.Parse(VisitId)
        ls_SQL_Command = "spGetAvailable"

        ' asociacion de parametros al comando

        oleDBcom.Parameters.Add(lodb_VisitId)
        oleDBcom.CommandText = ls_SQL_Command
        oleDBcom.CommandType = CommandType.StoredProcedure

        Dim DataResult As DataSet = New DataSet()

        Dim adapter As OleDbDataAdapter = New OleDbDataAdapter(oleDBcom)

        Try
            oleDBconnx.Open()
            adapter.Fill(DataResult)

        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
        Finally
            oleDBconnx.Close()
        End Try
        Return DataResult
    End Function

    Public Function ObtenerError(ByVal cad As String, ByVal ex As Integer) As String

        If cad.Contains(ex.ToString) And cad.Contains("Sybase Provider]") Then
            Dim idx As Integer
            idx = cad.LastIndexOf("]")
            idx = idx + 1
            If idx > 0 And idx <= cad.Length Then
                Return cad.Substring(idx)
            Else
                Return ""
            End If
        Else
            If cad.Contains("Sybase Provider]") Then
                Dim idx As Integer
                idx = cad.LastIndexOf("]")
                idx = idx + 1
                If idx > 0 And idx <= cad.Length Then
                    Return cad.Substring(idx)
                Else
                    Return ""
                End If

            End If
        End If
        Return ""
    End Function

    '******************************FIN Ventana Disponibilidad************************************

    '*********************************Cambio de Ubicacion************************************

    <WebMethod()> _
    Public Function Buscar_Datos_Contenedor(ByVal strcontainerid As String, ByRef cadError As String) As DataTable
        Dim idt_result As DataTable = New DataTable ' Tabla con el query de resultados 
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        'Dim strcontainerid As String = "IPXU3283286"
        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()
        idt_result.TableName = "Buscar_Datos"

        Dim strSQL As String
        'Dim strcontainerid As String


        'Sentencia SQL que recobra los datos para la pantalla de cambio de Ubicacion
        strSQL = "SELECT  tblclsContainerInventory.strContainerId, " & _
                         "tblclsContainerInventory.intContainerUniversalId, " & _
                         "tblclsContainerType.strContainerTypeIdentifier, " & _
                         "tblclsContainerSize.strContainerSizeIdentifier, " & _
                         "tblclsContainer.decContainerTare, " & _
                         "tblclsContainerInventory.blnContainerIsFull, " & _
                         "(CASE ISNULL(tblclsContainerInventory.intContainerUniversalId, 0) " & _
                               "WHEN 0 THEN 'SIN ESTATUS' " & _
                               "ELSE tblclsContainerFiscalStatus.strContFisStatusIdentifier " & _
                          "END) AS 'strContFisStatusIdentifier' , " & _
                         "tblclsContainerAdmStatus.strContAdmStatusIdentifier, " & _
                         "tblclsContainerInventory.strContainerInvYardPositionId, " & _
                         "tblclsContainerInventory.strContainerInvComments, " & _
                         "DATEDIFF(dd, dtmContainerInvReceptionDate, GETDATE()) As intDaysInTerminal ," & _
                         "  VSS.strVesselName, VVY.vchVesselVoyageDescription " & _
                         " , VSS.strVesselName +'-'+ CONVERT(VARCHAR(2),DATEPART(dd,VVY.dteVesselVoyageArrivalDate)) +'/'+CONVERT(VARCHAR(2),DATEPART(mm,VVY.dteVesselVoyageArrivalDate)) + '/'+CONVERT(VARCHAR(4),DATEPART(yy,VVY.dteVesselVoyageArrivalDate))  AS strVesselAndDate " & _
                         " ,VSS.strVesselIdentifier + '-' +VVY.strVesselVoyageNumIdentifier as strVesselIdandVoyageId" & _
                         " ,SHIP.strShippingLineIdentifier " & _
                         " ,tblclsContainerInventory.strContainerInvComments " & _
                         " , ISNULL(GORY.strContainerCatIdentifier,'') AS strContainerCatIdentifier" & _
                         " , CASE WHEN LEN( tblclsContainerInventory.strContainerInvFinalPortId) > 1 THEN tblclsContainerInventory.strContainerInvFinalPortId " & _
                         "   ELSE tblclsContainerInventory.strContainerInvDischargePortId" & _
                         "  END   AS strFinalPort " & _
                        "FROM tblclsContainerInventory " & _
                         "LEFT OUTER JOIN tblclsContainerFiscalStatus " & _
                          "ON tblclsContainerInventory.intContFisStatusId = tblclsContainerFiscalStatus.intContFisStatusId " & _
                         "LEFT JOIN tblclsContainer " & _
                           "ON tblclsContainerInventory.strContainerId = tblclsContainer.strContainerId " & _
                         "LEFT JOIN tblclsContainerISOCode " & _
                          "ON tblclsContainer.intContISOCodeId = tblclsContainerISOCode.intContISOCodeId " & _
                         "LEFT JOIN tblclsContainerType " & _
                           "ON tblclsContainerISOCode.intContainerTypeId = tblclsContainerType.intContainerTypeId " & _
                         "LEFT JOIN tblclsContainerSize " & _
                           "ON tblclsContainerSize.intContainerSizeId  = tblclsContainerISOCode.intContainerSizeId " & _
                         "LEFT JOIN tblclsVesselVoyage VVY " & _
                           "ON  tblclsContainerInventory.intContainerInvVesselVoyageId = VVY.intVesselVoyageId  " & _
                         "LEFT JOIN tblclsVessel VSS " & _
                           "ON VVY.intVesselId = VSS.intVesselId  " & _
                         "LEFT JOIN tblclsShippingLine SHIP " & _
                           "ON SHIP.intShippingLineId = tblclsContainerInventory.intContainerInvOperatorId  " & _
                         "LEFT JOIN tblclsContainerCategory GORY " & _
                           "ON GORY.intContainerCategoryId = tblclsContainerInventory.intContainerCategoryId , " & _
                         "tblclsContainerAdmStatus " & _
                   "WHERE ( tblclsContainerInventory.strContainerId = tblclsContainer.strContainerId ) and " & _
                         "( tblclsContainerInventory.blnContainerInvActive = 1 ) and " & _
                         "( tblclsContainerInventory.intContAdmStatusId = tblclsContainerAdmStatus.intContAdmStatusId ) and " & _
                         "( tblclsContainerAdmStatus.strContAdmStatusIdentifier NOT IN ( 'PUBIC') ) AND " & _
                         "(tblclsContainerInventory.strContainerId = '" & strcontainerid & "') "

        iolecmd_comand.CommandText = strSQL

        iAdapt_comand.SelectCommand = iolecmd_comand
        Try
            iolecmd_comand.Connection.Open()
            iAdapt_comand.Fill(idt_result)
            cadError = "cad"

        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            cadError = strError
            cadError = "Errorx"

        Finally
            iAdapt_comand.SelectCommand.Connection.Close()
            iolecmd_comand.Connection.Close()
            iolecmd_comand.Connection.Dispose()
            iAdapt_comand.SelectCommand.Connection.Dispose()
            ioleconx_conexion.Close()
            ioleconx_conexion.Dispose()

        End Try

        '' -- si el el resultado obtenido es de un renglon validar que el puerto , si es cadena vacia 
        If idt_result.Rows.Count = 1 Then
            If IsDBNull(idt_result(0)("strFinalPort")) = True Then
                idt_result(0)("strFinalPort") = ""
            End If
        End If
        ''--- fin validacion
        iolecmd_comand.Connection = Nothing
        iAdapt_comand.Dispose()
        iAdapt_comand = Nothing
        Return idt_result
    End Function

    '*********************************Cambio de Ubicacion************************************


    '*******************************Verifica si esta o no ocupada la posicion************************************
    <WebMethod()> _
    Public Function Verify(ByVal lstrcontainerinvyardpositionid As String, ByRef ocupado As Integer) As Integer

        ' Dim lstrcontainerinvyardpositionid As String = "1Z01F1"
        ' Dim ocupado As Integer

        '-----------------------------
        Dim param As New OleDbParameter
        param.ParameterName = ParameterDirection.ReturnValue

        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        Dim x
        x = 0
        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand
        '----------------------------------

        Dim oleDb_param As OleDbParameter = New OleDbParameter()
        Dim oleDb_paramOut As OleDbParameter = New OleDbParameter()
        Dim ls_sql As String

        oleDb_param.ParameterName = "@astrcontainerinvyardpositionid"
        oleDb_param.OleDbType = OleDbType.Char
        oleDb_param.Value = lstrcontainerinvyardpositionid


        oleDb_paramOut.ParameterName = "@intOccupied"
        oleDb_paramOut.OleDbType = OleDbType.Integer
        oleDb_paramOut.Direction = ParameterDirection.Output


        ls_sql = "spValidateYardPosition"

        oleDBcom.CommandText = ls_sql
        oleDBcom.CommandType = CommandType.StoredProcedure
        param = oleDBcom.Parameters.Add("returnvalue", OleDbType.Integer)
        param.Direction = ParameterDirection.ReturnValue
        oleDBcom.Parameters.Add(oleDb_param)
        oleDBcom.Parameters.Add(oleDb_paramOut)


        oleDBcom.CommandTimeout = 0
        Try
            oleDBconnx.Open()
            oleDBcom.ExecuteNonQuery()
            ocupado = oleDb_paramOut.Value
            x = param.Value
            'x = oleDBcom.Parameters("@returnvalue").Value
        Catch ex As Exception
            Return 0
        Finally
            oleDBconnx.Close()
            oleDBconnx.Dispose()

            oleDBcom.Connection.Close()
            oleDBcom.Connection.Dispose()

        End Try
        oleDBconnx = Nothing
        oleDBcom = Nothing

        ''' jcadena 15-07-2016 , invalidar posiciones que no se encontraron 
        If x > 2 Then
            x = 0
        End If
        Return x
    End Function
    '*******************************FIN Verifica si esta o no ocupada la posicion************************************

    '*******************************Guardar Ubicacion VENTANA CAMBIO DE UBICACION************************************
    <WebMethod()> _
    Public Function Search_Tied(ByVal intcontaineruniversalid As String) As Integer
        Dim myConnectionString = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        Dim myConnection As New OleDbConnection(myConnectionString)
        Dim istr_conx As String
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection()
        Dim iolecmd_comand As OleDbCommand
        Dim idt_result As DataTable = New DataTable()
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter()
        Dim iint_RowsCounter As Integer
        Dim lintAttachId As Integer

        Dim mySelectQuery = "SELECT tblclsContainerInvAttachedItem.intContInvAttachId   " & _
                    "FROM tblclsContainerInvAttachedItem   " & _
                     "WHERE (tblclsContainerInvAttachedItem.intContainerUniversalId = " & Str(intcontaineruniversalid) & " )"

        'contador de resultados en 0 
        iint_RowsCounter = 0
        'primero hacer una consulta rapida con un dataset 


        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()
        idt_result.TableName = "TrearDatos"
        iolecmd_comand.CommandText = mySelectQuery

        iAdapt_comand.SelectCommand = iolecmd_comand
        lintAttachId = 0

        Try
            iolecmd_comand.Connection.Open()
            iAdapt_comand.Fill(idt_result)

            '' revisar los resultados 
            If idt_result.Rows.Count > 0 Then
                If idt_result.Columns.Count > 0 Then
                    Try

                        lintAttachId = Convert.ToInt64(idt_result(0)(0))
                        iint_RowsCounter = 1
                    Catch ex As Exception
                        iint_RowsCounter = 0
                    End Try
                End If
            End If

        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
        Finally
            iolecmd_comand.Connection.Close()
            iAdapt_comand.SelectCommand.Connection.Close()
            ioleconx_conexion.Close()

            iolecmd_comand.Connection.Dispose()
            iAdapt_comand.SelectCommand.Connection.Dispose()
            ioleconx_conexion.Dispose()

        End Try

        iAdapt_comand = Nothing
        iolecmd_comand = Nothing
        ioleconx_conexion = Nothing

        Return lintAttachId

        '' -- si la consulta tiene resultados 
        ''
        'Dim myCommand As New OleDbCommand(mySelectQuery, myConnection)
        'myConnection.Open()
        'Dim myReader As OleDbDataReader = myCommand.ExecuteReader()
        'If myReader.HasRows Then
        '    myReader.Read()
        '    Dim No_Atado = myReader(0)

        '    myConnection.Close()
        '    myCommand.Connection.Close()
        '    myReader.Close()
        '    myConnection.Dispose()
        '    myCommand.Connection.Dispose()

        '    myReader = Nothing
        '    myCommand = Nothing
        '    myConnection = Nothing

        '    Return No_Atado

        '    Exit Function
        'Else


        'End If

        'myReader.Close()
        ''myCommand.Connection.Close()
        ''myConnection.Close()

        'myConnection.Dispose()
        'myCommand.Connection.Dispose()

        ''myReader.Close()
        'myReader = Nothing
        'myCommand = Nothing
        'myConnection = Nothing
        'Return 0


    End Function

    '*******************************************************************
    <WebMethod()> _
    Public Function UpdateHistoryContPosition(ByVal intcontaineruniversalid As String, ByVal lstrcontainerinvyardpositionid As String, ByVal lstrusername As String) As Integer
        '-----------------------------
        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand
        '----------------------------------

        Dim oleDb_param As OleDbParameter = New OleDbParameter()
        Dim ls_sql As String

        Dim ol_param_Universal As OleDbParameter = New OleDbParameter()
        Dim ol_param_Posicion As OleDbParameter = New OleDbParameter()
        Dim ol_param_Posicion_Fracc1 As OleDbParameter = New OleDbParameter()
        Dim ol_param_Posicion_Fracc2 As OleDbParameter = New OleDbParameter()
        Dim ol_param_Posicion_Fracc3 As OleDbParameter = New OleDbParameter()
        Dim ol_param_Posicion_Fracc4 As OleDbParameter = New OleDbParameter()
        Dim ol_param_comentarios As OleDbParameter = New OleDbParameter()
        Dim ol_param_User As OleDbParameter = New OleDbParameter()
        Dim comments As String = ""

        ol_param_Universal.ParameterName = "@intcontaineruniversalid"
        ol_param_Universal.OleDbType = OleDbType.Integer
        ol_param_Universal.Value = intcontaineruniversalid

        ol_param_Posicion.ParameterName = "@lstrcontainerinvyardpositionid"
        ol_param_Posicion.OleDbType = OleDbType.Char
        ol_param_Posicion.Value = lstrcontainerinvyardpositionid

        'agregando fraccionarios
        ol_param_Posicion_Fracc1.ParameterName = "@lstrcontainerinvyardpositionid"
        ol_param_Posicion_Fracc1.OleDbType = OleDbType.Char
        ol_param_Posicion_Fracc1.Value = Mid(lstrcontainerinvyardpositionid, 1, 2)

        ol_param_Posicion_Fracc2.ParameterName = "@lstrcontainerinvyardpositionid"
        ol_param_Posicion_Fracc2.OleDbType = OleDbType.Char
        ol_param_Posicion_Fracc2.Value = Mid(lstrcontainerinvyardpositionid, 3, 2)

        ol_param_Posicion_Fracc3.ParameterName = "@lstrcontainerinvyardpositionid"
        ol_param_Posicion_Fracc3.OleDbType = OleDbType.Char
        ol_param_Posicion_Fracc3.Value = Mid(lstrcontainerinvyardpositionid, 5, 1)

        ol_param_Posicion_Fracc4.ParameterName = "@lstrcontainerinvyardpositionid"
        ol_param_Posicion_Fracc4.OleDbType = OleDbType.Char
        ol_param_Posicion_Fracc4.Value = Mid(lstrcontainerinvyardpositionid, 6, 1)

        'fin agregado fraccionarios
        ol_param_comentarios.ParameterName = "@comments"
        ol_param_comentarios.OleDbType = OleDbType.Char
        ol_param_comentarios.Value = comments

        ol_param_User.ParameterName = "@lstrusername"
        ol_param_User.OleDbType = OleDbType.Char
        ol_param_User.Value = lstrusername
        ls_sql = "spUpdateHistoryContPosition"

        oleDBcom.CommandText = ls_sql
        oleDBcom.CommandType = CommandType.StoredProcedure
        oleDBcom.Parameters.Add(ol_param_Universal) '(intcontaineruniversalid) 'Id universal del contenedor)
        oleDBcom.Parameters.Add(ol_param_Posicion)
        oleDBcom.Parameters.Add(ol_param_Posicion_Fracc1)
        oleDBcom.Parameters.Add(ol_param_Posicion_Fracc3) '-- cambio de orden ol_param_Posicion_Fracc3
        oleDBcom.Parameters.Add(ol_param_Posicion_Fracc2) '-- cambio de orden ol_param_Posicion_Fracc2
        oleDBcom.Parameters.Add(ol_param_Posicion_Fracc4)
        oleDBcom.Parameters.Add(ol_param_comentarios)
        oleDBcom.Parameters.Add(ol_param_User)
        oleDBcom.CommandTimeout = 0
        Try
            oleDBconnx.Open()
            oleDBcom.ExecuteNonQuery()

        Catch ex As Exception
            Return 0
        Finally
            oleDBcom.Connection.Close()
            oleDBconnx.Close()
            oleDBcom.Connection.Dispose()
            oleDBconnx.Dispose()
        End Try

        oleDBcom = Nothing
        oleDBconnx = Nothing

    End Function

    '*******************************************************************
    <WebMethod()> _
    Public Function UpdateHistoryContPositionComs(ByVal intcontaineruniversalid As String, ByVal lstrcontainerinvyardpositionid As String, ByVal lstrusername As String, ByVal astrComments As String) As Integer
        '-----------------------------
        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand
        '----------------------------------

        Dim oleDb_param As OleDbParameter = New OleDbParameter()
        Dim ls_sql As String

        Dim ol_param_Universal As OleDbParameter = New OleDbParameter()
        Dim ol_param_Posicion As OleDbParameter = New OleDbParameter()
        Dim ol_param_Posicion_Fracc1 As OleDbParameter = New OleDbParameter()
        Dim ol_param_Posicion_Fracc2 As OleDbParameter = New OleDbParameter()
        Dim ol_param_Posicion_Fracc3 As OleDbParameter = New OleDbParameter()
        Dim ol_param_Posicion_Fracc4 As OleDbParameter = New OleDbParameter()
        Dim ol_param_comentarios As OleDbParameter = New OleDbParameter()
        Dim ol_param_User As OleDbParameter = New OleDbParameter()
        Dim comments As String = ""

        ol_param_Universal.ParameterName = "@UniversalId" ' "@intcontaineruniversalid"
        ol_param_Universal.OleDbType = OleDbType.Integer
        ol_param_Universal.Value = intcontaineruniversalid

        ol_param_Posicion.ParameterName = "@YardPosId" '"@lstrcontainerinvyardpositionid"
        ol_param_Posicion.OleDbType = OleDbType.Char
        ol_param_Posicion.Value = lstrcontainerinvyardpositionid

        'agregando fraccionarios
        ol_param_Posicion_Fracc1.ParameterName = "@Block" ' "@lstrcontainerinvyardpositionid"
        ol_param_Posicion_Fracc1.OleDbType = OleDbType.Char
        ol_param_Posicion_Fracc1.Value = Mid(lstrcontainerinvyardpositionid, 1, 2)

        ol_param_Posicion_Fracc2.ParameterName = "@Row" '"@lstrcontainerinvyardpositionid"
        ol_param_Posicion_Fracc2.OleDbType = OleDbType.Char
        ol_param_Posicion_Fracc2.Value = Mid(lstrcontainerinvyardpositionid, 3, 2)

        ol_param_Posicion_Fracc3.ParameterName = "@Bay" '"@lstrcontainerinvyardpositionid"
        ol_param_Posicion_Fracc3.OleDbType = OleDbType.Char
        ol_param_Posicion_Fracc3.Value = Mid(lstrcontainerinvyardpositionid, 5, 1)

        ol_param_Posicion_Fracc4.ParameterName = "@Stow" ' "@lstrcontainerinvyardpositionid"
        ol_param_Posicion_Fracc4.OleDbType = OleDbType.Char
        ol_param_Posicion_Fracc4.Value = Mid(lstrcontainerinvyardpositionid, 6, 1)


        comments = FixComments(astrComments)
        If comments.Length < 5 Then
            comments = astrComments
        End If
        ol_param_comentarios.ParameterName = "@comments"
        ol_param_comentarios.OleDbType = OleDbType.Char
        'ol_param_comentarios.Value = astrComments
        ol_param_comentarios.Value = comments

        ol_param_User.ParameterName = "@lstrusername"
        ol_param_User.OleDbType = OleDbType.Char
        ol_param_User.Value = lstrusername
        ls_sql = "spUpdateHistoryContPosition"
        's_sql = "exec spUpdateHistoryContPosition ?,?,?,?,?,?, NULL ,? "

        oleDBcom.CommandText = ls_sql
        oleDBcom.CommandType = CommandType.StoredProcedure
        oleDBcom.Parameters.Add(ol_param_Universal) '(intcontaineruniversalid) 'Id universal del contenedor)
        oleDBcom.Parameters.Add(ol_param_Posicion)
        oleDBcom.Parameters.Add(ol_param_Posicion_Fracc1)
        oleDBcom.Parameters.Add(ol_param_Posicion_Fracc2)
        oleDBcom.Parameters.Add(ol_param_Posicion_Fracc3)
        oleDBcom.Parameters.Add(ol_param_Posicion_Fracc4)
        oleDBcom.Parameters.Add(ol_param_comentarios)
        oleDBcom.Parameters.Add(ol_param_User)
        oleDBcom.CommandTimeout = 0
        Try
            oleDBconnx.Open()
            oleDBcom.ExecuteNonQuery()

        Catch ex As Exception
            Return 0
        Finally
            oleDBcom.Connection.Close()
            oleDBconnx.Close()
            oleDBcom.Connection.Dispose()
            oleDBconnx.Dispose()
        End Try

        oleDBcom = Nothing
        oleDBconnx = Nothing

    End Function


    '*******************************************************************
    <WebMethod()> _
    Public Function UpdatePositionInventory(ByVal intcontaineruniversalid As String, ByVal lstrcontainerinvyardpositionid As String, ByVal lstrusername As String) As Integer
        '-----------------------------
        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand
        '----------------------------------

        Dim oleDb_param As OleDbParameter = New OleDbParameter()
        Dim ls_sql As String

        Dim ol_param_Universal As OleDbParameter = New OleDbParameter()
        Dim ol_param_Posicion As OleDbParameter = New OleDbParameter()
        Dim ol_param_Posicion_Fracc1 As OleDbParameter = New OleDbParameter()
        Dim ol_param_Posicion_Fracc2 As OleDbParameter = New OleDbParameter()
        Dim ol_param_Posicion_Fracc3 As OleDbParameter = New OleDbParameter()
        Dim ol_param_Posicion_Fracc4 As OleDbParameter = New OleDbParameter()
        Dim oleDb_paramOut As OleDbParameter = New OleDbParameter()

        Dim comments As String = ""

        ol_param_Universal.ParameterName = "@intcontaineruniversalid"
        ol_param_Universal.OleDbType = OleDbType.Integer
        ol_param_Universal.Value = intcontaineruniversalid

        ol_param_Posicion.ParameterName = "@lstrcontainerinvyardpositionid"
        ol_param_Posicion.OleDbType = OleDbType.Char
        ol_param_Posicion.Value = lstrcontainerinvyardpositionid

        'agregando fraccionarios
        ol_param_Posicion_Fracc1.ParameterName = "@lstrcontainerinvyardpositionid"
        ol_param_Posicion_Fracc1.OleDbType = OleDbType.Char
        ol_param_Posicion_Fracc1.Value = Mid(lstrcontainerinvyardpositionid, 1, 2)

        ol_param_Posicion_Fracc2.ParameterName = "@lstrcontainerinvyardpositionid"
        ol_param_Posicion_Fracc2.OleDbType = OleDbType.Char
        ol_param_Posicion_Fracc2.Value = Mid(lstrcontainerinvyardpositionid, 3, 2)

        ol_param_Posicion_Fracc3.ParameterName = "@lstrcontainerinvyardpositionid"
        ol_param_Posicion_Fracc3.OleDbType = OleDbType.Char
        ol_param_Posicion_Fracc3.Value = Mid(lstrcontainerinvyardpositionid, 5, 1)

        ol_param_Posicion_Fracc4.ParameterName = "@lstrcontainerinvyardpositionid"
        ol_param_Posicion_Fracc4.OleDbType = OleDbType.Char
        ol_param_Posicion_Fracc4.Value = Mid(lstrcontainerinvyardpositionid, 6, 1)

        oleDb_paramOut.ParameterName = "@intErrorCode"
        oleDb_paramOut.OleDbType = OleDbType.Integer
        oleDb_paramOut.Direction = ParameterDirection.Output

        ls_sql = "spUpdatePositionInventory"

        oleDBcom.CommandText = ls_sql
        oleDBcom.CommandType = CommandType.StoredProcedure
        oleDBcom.Parameters.Add(ol_param_Universal) '(intcontaineruniversalid) 'Id universal del contenedor)
        oleDBcom.Parameters.Add(ol_param_Posicion)
        oleDBcom.Parameters.Add(ol_param_Posicion_Fracc1)
        oleDBcom.Parameters.Add(ol_param_Posicion_Fracc3) 'cambiar de orden 
        oleDBcom.Parameters.Add(ol_param_Posicion_Fracc2) '' cambiar de orden ol_param_Posicion_Fracc3
        oleDBcom.Parameters.Add(ol_param_Posicion_Fracc4)
        oleDBcom.Parameters.Add(oleDb_paramOut)
        oleDBcom.CommandTimeout = 0
        Try
            oleDBconnx.Open()
            oleDBcom.ExecuteNonQuery()

        Catch ex As Exception
            Return 0
        Finally
            oleDBcom.Connection.Close()
            oleDBconnx.Close()
            oleDBcom.Connection.Dispose()
            oleDBconnx.Dispose()

        End Try
        oleDBcom = Nothing
        oleDBconnx = Nothing
    End Function

    '*******************************************************************
    <WebMethod()> _
    Public Function Info_atados(ByVal NoAtado As String, ByRef cadError As String, ByVal lstrcontainerinvyardpositionid As String) As DataTable
        'Dim NoAtado As String = "984"
        ' Dim lstrcontainerinvyardpositionid As String = ""
        'Dim lstrcontainerinvyardpositionid = "1Z01B2"
        Dim idt_result As DataTable = New DataTable ' Tabla con el query de resultados 
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        'Dim strcontainerid As String = "IPXU3283286"
        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()
        idt_result.TableName = "TrearDatos"

        Dim strSQL As String
        'Dim strcontainerid As String


        'Sentencia SQL que recobra los datos para la pantalla de cambio de Ubicacion
        strSQL = "SELECT  tblclsContainerInvAttachedItem.intContInvAttachId, " & _
                             "tblclsContainerInventory.intContainerUniversalId AS intContainerUniversalId," & _
                             "tblclsContainerInventory.strContainerInvYardPositionId, " & _
                             "tblclsContainerInventory.strContainerInvBlockIdentifier, " & _
                             "tblclsContainerInventory.strContainerInvPosRow, " & _
                             "tblclsContainerInventory.strContainerInvPosBay, " & _
                             "tblclsContainerInventory.strContainerInvPosStow, " & _
                             "tblclsContainerInventory.strContainerInvComments " & _
                       "FROM  tblclsContainerInvAttachedItem, " & _
                             "tblclsContainerInventory " & _
                     "WHERE (tblclsContainerInventory.intContainerUniversalId = tblclsContainerInvAttachedItem.intContainerUniversalId) " & _
                       " and tblclsContainerInvAttachedItem.intContInvAttachId =" & Str(NoAtado)

        iolecmd_comand.CommandText = strSQL

        iAdapt_comand.SelectCommand = iolecmd_comand
        Try
            iolecmd_comand.Connection.Open()
            iAdapt_comand.Fill(idt_result)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
        Finally
            iolecmd_comand.Connection.Close()
            iAdapt_comand.SelectCommand.Connection.Close()
            ioleconx_conexion.Close()

            iolecmd_comand.Connection.Dispose()
            iAdapt_comand.SelectCommand.Connection.Dispose()
            ioleconx_conexion.Dispose()

        End Try
        'probar
        InsertarDatos_Atados(idt_result, "vacios", lstrcontainerinvyardpositionid)
        'fin probar

        iAdapt_comand = Nothing
        iolecmd_comand = Nothing
        ioleconx_conexion = Nothing

        Return idt_result


    End Function

    <WebMethod()> _
       Public Function InsertarDatos_Atados(ByVal consultar As DataTable, ByVal lstrusername As String, ByVal lstrcontainerinvyardpositionid As String) As Integer
        '-----------------------------

        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand
        '----------------------------------
        Dim oleDb_param As OleDbParameter = New OleDbParameter()
        Dim ls_sql As String

        Dim UniversalId As OleDbParameter = New OleDbParameter()
        Dim YardPosId As OleDbParameter = New OleDbParameter()
        Dim Block As OleDbParameter = New OleDbParameter()
        Dim Row As OleDbParameter = New OleDbParameter()
        Dim Bay As OleDbParameter = New OleDbParameter()
        Dim Stow As OleDbParameter = New OleDbParameter()
        Dim Comments As OleDbParameter = New OleDbParameter()
        Dim User As OleDbParameter = New OleDbParameter()
        Dim str_Comments As String = ""

        For Each valor In consultar.Rows

            oleDBcom = New OleDbCommand()
            oleDBconnx = New OleDbConnection()
            strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
            oleDBconnx.ConnectionString = strconx
            oleDBcom = oleDBconnx.CreateCommand


            UniversalId.ParameterName = "@intcontaineruniversalid"
            UniversalId.OleDbType = OleDbType.Integer
            UniversalId.Value = valor("intContainerUniversalId")

            YardPosId.ParameterName = "@strContainerInvYardPositionId"
            YardPosId.OleDbType = OleDbType.Char
            YardPosId.Value = lstrcontainerinvyardpositionid 'valor("lstrcontainerinvyardpositionid")

            'agregando fraccionarios
            Block.ParameterName = "@strContainerInvYardPositionId"
            Block.OleDbType = OleDbType.Char
            Block.Value = Mid(lstrcontainerinvyardpositionid, 1, 2) 'Mid(valor("strContainerInvYardPositionId"), 1, 2) 'bloque

            Row.ParameterName = "@strContainerInvYardPositionId"
            Row.OleDbType = OleDbType.Char
            Row.Value = Mid(lstrcontainerinvyardpositionid, 3, 2) 'Mid(valor("strContainerInvYardPositionId"), 3, 2) 'baia

            Bay.ParameterName = "@strContainerInvYardPositionId"
            Bay.OleDbType = OleDbType.Char
            Bay.Value = Mid(lstrcontainerinvyardpositionid, 5, 1) 'Mid(valor("strContainerInvYardPositionId"), 5, 1) 'fila

            Stow.ParameterName = "@strContainerInvYardPositionId"
            Stow.OleDbType = OleDbType.Char
            Stow.Value = Mid(lstrcontainerinvyardpositionid, 6, 1) 'Mid(valor("strContainerInvYardPositionId"), 6, 1) 'nivel

            Comments.ParameterName = "@comments"
            Comments.OleDbType = OleDbType.Char
            Comments.Value = str_Comments

            User.ParameterName = "@lstrusername"
            User.OleDbType = OleDbType.Char
            User.Value = lstrusername

            ls_sql = "spUpdateHistoryContPosition"

            oleDBcom.CommandText = ls_sql
            oleDBcom.CommandType = CommandType.StoredProcedure

            oleDBcom.Parameters.Add(UniversalId)
            oleDBcom.Parameters.Add(YardPosId)
            oleDBcom.Parameters.Add(Block) 'bloque
            oleDBcom.Parameters.Add(Row) 'baia
            oleDBcom.Parameters.Add(Bay) 'fila
            oleDBcom.Parameters.Add(Stow) 'nivel
            oleDBcom.Parameters.Add(Comments)
            oleDBcom.Parameters.Add(User)

            oleDBcom.CommandTimeout = 0
            Try
                oleDBconnx.Open()
                oleDBcom.ExecuteNonQuery()

            Catch ex As Exception

                ' hasta aqui va lo que meti
            Finally
                'oleDBcom.Clone()

                oleDBconnx.Close()
                oleDBcom.Parameters.Clear()
                oleDBcom.Connection.Close()
                oleDBconnx.Dispose()
                oleDBcom.Dispose()



            End Try
            '-----------------------------
            oleDBcom = New OleDbCommand()
            oleDBconnx = New OleDbConnection()
            strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
            oleDBconnx.ConnectionString = strconx
            oleDBcom = oleDBconnx.CreateCommand
            '----------------------------------

            Dim oleDb_param2 As OleDbParameter = New OleDbParameter()
            Dim ol_param_Universal As OleDbParameter = New OleDbParameter()
            Dim ol_param_Posicion As OleDbParameter = New OleDbParameter()
            Dim ol_param_Posicion_Fracc1 As OleDbParameter = New OleDbParameter()
            Dim ol_param_Posicion_Fracc2 As OleDbParameter = New OleDbParameter()
            Dim ol_param_Posicion_Fracc3 As OleDbParameter = New OleDbParameter()
            Dim ol_param_Posicion_Fracc4 As OleDbParameter = New OleDbParameter()
            Dim oleDb_paramOut As OleDbParameter = New OleDbParameter()

            Dim comments2 As String = ""

            ol_param_Universal.ParameterName = "@intcontaineruniversalid"
            ol_param_Universal.OleDbType = OleDbType.Integer
            ol_param_Universal.Value = valor("intcontaineruniversalid") 'intcontaineruniversalid

            ol_param_Posicion.ParameterName = "@strContainerInvYardPositionId"
            ol_param_Posicion.OleDbType = OleDbType.Char
            ol_param_Posicion.Value = lstrcontainerinvyardpositionid

            'agregando fraccionarios
            ol_param_Posicion_Fracc1.ParameterName = "@strContainerInvYardPositionId"
            ol_param_Posicion_Fracc1.OleDbType = OleDbType.Char
            ol_param_Posicion_Fracc1.Value = Mid(lstrcontainerinvyardpositionid, 1, 2) 'Mid(valor("strContainerInvYardPositionId"), 1, 2) 'bloque Mid(lstrcontainerinvyardpositionid, 1, 2)

            ol_param_Posicion_Fracc2.ParameterName = "@strContainerInvYardPositionId"
            ol_param_Posicion_Fracc2.OleDbType = OleDbType.Char
            ol_param_Posicion_Fracc2.Value = Mid(lstrcontainerinvyardpositionid, 1, 2) 'Mid(valor("strContainerInvYardPositionId"), 3, 2) 'Mid(lstrcontainerinvyardpositionid, 3, 2)

            ol_param_Posicion_Fracc3.ParameterName = "@strContainerInvYardPositionId"
            ol_param_Posicion_Fracc3.OleDbType = OleDbType.Char
            ol_param_Posicion_Fracc3.Value = Mid(lstrcontainerinvyardpositionid, 1, 2) 'Mid(valor("strContainerInvYardPositionId"), 5, 1) 'Mid(lstrcontainerinvyardpositionid, 5, 1)

            ol_param_Posicion_Fracc4.ParameterName = "@strContainerInvYardPositionId"
            ol_param_Posicion_Fracc4.OleDbType = OleDbType.Char
            ol_param_Posicion_Fracc4.Value = Mid(lstrcontainerinvyardpositionid, 1, 2) 'Mid(valor("strContainerInvYardPositionId"), 6, 1) 'Mid(lstrcontainerinvyardpositionid, 6, 1)

            oleDb_paramOut.ParameterName = "@intErrorCode"
            oleDb_paramOut.OleDbType = OleDbType.Integer
            oleDb_paramOut.Direction = ParameterDirection.Output

            ls_sql = "spUpdatePositionInventory"

            oleDBcom.CommandText = ls_sql
            oleDBcom.CommandType = CommandType.StoredProcedure
            oleDBcom.Parameters.Add(ol_param_Universal) '(intcontaineruniversalid) 'Id universal del contenedor)
            oleDBcom.Parameters.Add(ol_param_Posicion)
            oleDBcom.Parameters.Add(ol_param_Posicion_Fracc1)
            oleDBcom.Parameters.Add(ol_param_Posicion_Fracc2)
            oleDBcom.Parameters.Add(ol_param_Posicion_Fracc3)
            oleDBcom.Parameters.Add(ol_param_Posicion_Fracc4)
            oleDBcom.Parameters.Add(oleDb_paramOut)
            oleDBcom.CommandTimeout = 0
            Try
                oleDBcom.Connection.Open()
                oleDBconnx.Open()
                oleDBcom.ExecuteNonQuery()

            Catch ex As Exception
                Return 0
            Finally
                oleDBconnx.Close()
                oleDBcom.Connection.Close()
                oleDBcom.Connection.Dispose()
                oleDBconnx.Dispose()


            End Try
        Next
    End Function

    <WebMethod()> _
     Public Function Search_For_Containers_Desc(ByVal VisitId As Integer) As DataTable
        '-----------------------------
        ' Dim VisitId As Integer = 721362
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()
        '----------------------------------
        Dim tablafuente As New Data.DataTable("fuente")
        Dim tablaQUERY As New Data.DataTable("fuente")
        tablafuente.Columns.Add("descargado", System.Type.GetType("System.Int32"))
        tablafuente.Columns.Add("contenedor", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("tipo", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("tamaño", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("lleno", System.Type.GetType("System.Int32"))
        tablafuente.Columns.Add("linea", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("clase", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("posicion", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("fecha", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("iduniversal", System.Type.GetType("System.Int32"))
        tablafuente.Columns.Add("servicio", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("status", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("soid", System.Type.GetType("System.Int32"))
        tablafuente.Columns.Add("queueid", System.Type.GetType("System.Int32"))

        Dim ls_SQL_Command As String

        ls_SQL_Command = "SELECT 0 as descargado , SQ.intVisitId," & _
                            "I.strContainerInvYardPositionId, " & _
                                       "(CASE WHEN ( SELECT INV.blnContainerIsFull " & _
                                       "FROM tblclsContainerInventory INV " & _
                                       "WHERE INV.intContainerUniversalId  = SQ.intContainerUniversalId )  = 1 " & _
                                                      "THEN 1 " & _
                                                      "ELSE 0 " & _
                                               "END) as blnContainerIsFull, " & _
                                              "SQ.intContainerUniversalId, " & _
                                              "SV.strServiceIdentifier, " & _
                                              "SQ.strContainerId, " & _
                                              "T.strContainerTypeIdentifier, " & _
                                              "S.strContainerSizeIdentifier, " & _
                                              "SQ.intServiceOrderId, " & _
                                              "SV.strServiceName, " & _
                                              "SQ.dtmServiceQueuStartDate, " & _
                                              "SQ.dtmServiceQueuExecDate, " & _
                                              "SQ.intServiceId, " & _
                                              "SQ.intServiceQueuId, " & _
                                              "SV.strServiceIdentifier, " & _
                                              "(CASE ISNULL(I.intContainerUniversalId,0) " & _
                                              "        WHEN 0 THEN 'SIN ESTATUS' " & _
                                                    "ELSE CFS.strContFisStatusIdentifier " & _
                                               "END) AS status, " & _
                                                 "LINE.strShippingLineIdentifier, " & _
                                                 "CATE.strContainerCatIdentifier , SQ.intServiceOrderId, SQ.intServiceQueuId " & _
                                           "FROM tblclsServiceQueu SQ " & _
                                                "LEFT JOIN tblclsContainerInventory I " & _
                                                  "ON SQ.intContainerUniversalId = I.intContainerUniversalId " & _
                                                  "LEFT JOIN tblclsContainerFiscalStatus CFS " & _
                                                    "ON I.intContFisStatusId =CFS.intContFisStatusId " & _
                                                  "LEFT JOIN tblclsContainerCategory CATE " & _
                                                     "ON I.intContainerCategoryId = CATE.intContainerCategoryId " & _
                                                  "LEFT JOIN  tblclsShippingLine LINE " & _
                                                    "ON I.intContainerInvOperatorId = LINE.intShippingLineId " & _
                                                    "LEFT JOIN tblclsContainer CONT " & _
                                                      "ON I.strContainerId = CONT.strContainerId " & _
                                                      "LEFT JOIN tblclsContainerISOCode ISO " & _
                                                        "ON CONT.intContISOCodeId = ISO.intContISOCodeId " & _
                                                        "LEFT JOIN tblclsContainerSize S " & _
                                                          "ON ISO.intContainerSizeId = S.intContainerSizeId " & _
                                                          "LEFT JOIN tblclsContainerType T " & _
                                                            "ON ISO.intContainerTypeId = T.intContainerTypeId " & _
                                                            "LEFT JOIN tblclsService SV " & _
                                                              "ON SQ.intServiceId = SV.intServiceId " & _
                                       "WHERE  SQ.blnServiceQueuExecuted = 0  AND " & _
                                                    "SQ.dtmServiceQueuCheckIn IS NOT NULL AND " & _
                                                 "SQ.dtmServiceQueuCheckOut IS NULL AND    " & _
                                                 "SQ. dtmServiceQueuExecDate IS NULL AND " & _
                                                 "SQ.intServiceId IN(SELECT SERV.intServiceId " & _
                                                  "FROM tblclsService SERV " & _
                                                 "WHERE SERV.strServiceIdentifier IN ('RECLL','RECV','RECVOS') ) " & _
                                                 "AND  SQ.intVisitId=" & Convert.ToString(VisitId)

        iolecmd_comand.CommandText = ls_SQL_Command

        iAdapt_comand.SelectCommand = iolecmd_comand
        Try
            iolecmd_comand.Connection.Open()
            iAdapt_comand.Fill(tablaQUERY)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
        Finally
            iAdapt_comand.SelectCommand.Connection.Close()
            iolecmd_comand.Connection.Close()
            iAdapt_comand.SelectCommand.Connection.Dispose()
            iolecmd_comand.Connection.Dispose()
        End Try
        For Each valor As DataRow In tablaQUERY.Rows
            Dim registro As DataRow = tablafuente.NewRow()
            registro("descargado") = valor("descargado")
            registro("contenedor") = valor("strContainerId")
            registro("tipo") = valor("strContainerTypeIdentifier")
            registro("tamaño") = valor("strContainerSizeIdentifier")
            registro("lleno") = valor("blnContainerIsFull")
            registro("linea") = valor("strShippingLineIdentifier")
            registro("clase") = valor("strContainerCatIdentifier")
            registro("posicion") = ""
            registro("fecha") = Format(Date.Now, "dd/MM/yyyy HH:mm ")
            registro("iduniversal") = valor("intContainerUniversalId")
            registro("servicio") = valor("strServiceIdentifier")
            registro("status") = valor("status")
            registro("soid") = valor("intServiceOrderId")
            registro("queueid") = valor("intServiceQueuId")
            tablafuente.Rows.Add(registro)
        Next

        iAdapt_comand = Nothing
        iolecmd_comand = Nothing

        Return tablafuente
    End Function

    <WebMethod()> _
    Public Function GetVisitFromContainer_Disch(ByVal astr_ContainerId As String) As Integer

        '-----------------------------
        'Dim VisitId As Integer = 721372
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        Dim ldt_TableResult As DataTable = New DataTable("Result")
        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()
        '----------------------------------

        Dim ls_SQL_Command As String
        ls_SQL_Command = "SELECT VISIT.intVisitId ,  " & _
                        "        VCONT.strContainerId " & _
                        " FROM  tblclsVisitContainer VCONT " & _
                        " INNER JOIN tblclsVisit VISIT ON VISIT.intVisitId = VCONT.intVisitId " & _
                        " INNER JOIN tblclsServiceQueu QUE ON QUE.intVisitId  = VISIT.intVisitId " & _
                        "                                  AND QUE.strContainerId= VCONT.strContainerId " & _
                        " INNER JOIN tblclsService SERV ON SERV.intServiceId =  VCONT.intServiceId  " & _
                        " WHERE VISIT.dtmVisitDatetimeIn IS  NOT NULL AND " & _
                        "        VISIT.dtmVisitDatetimeOut IS NULL AND " & _
                        "        VISIT.intSOStatusId <= 2 AND " & _
                        "      QUE.dtmServiceQueuCheckIn IS NOT NULL AND " & _
                        "      QUE.dtmServiceQueuCheckOut IS NULL AND " & _
                        "      QUE.dtmServiceQueuExecDate IS NULL AND " & _
                        "      SERV.strServiceIdentifier IN ('RECLL','RECV','RECVOS') AND " & _
                        " VCONT.strContainerId = ?"

        iolecmd_comand.CommandText = ls_SQL_Command
        'agrega parametro
        iolecmd_comand.Parameters.Add("@strContainerId", OleDbType.Char)

        ' se pone valor al parametro
        iolecmd_comand.Parameters("@strContainerId").Value = astr_ContainerId

        iAdapt_comand.SelectCommand = iolecmd_comand
        Try
            iolecmd_comand.Connection.Open()
            iAdapt_comand.Fill(ldt_TableResult)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
        Finally
            iAdapt_comand.SelectCommand.Connection.Close()
            iolecmd_comand.Connection.Close()

            iAdapt_comand.SelectCommand.Connection.Dispose()
            iolecmd_comand.Connection.Dispose()
        End Try

        iAdapt_comand = Nothing
        iolecmd_comand = Nothing

        If ldt_TableResult.Rows.Count > 0 Then
            Return Convert.ToInt64(ldt_TableResult(0)("intVisitId"))
        Else
            Return -1
        End If


        Return -1

    End Function

    <WebMethod()> _
    Public Function Search_For_DescItems_FromOneContainer(ByVal astr_ContainerId As String) As DataTable
        '-----------------------------

        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        Dim lint_Visitd As Integer = 0
        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx

        iolecmd_comand = ioleconx_conexion.CreateCommand()
        '----------------------------------
        Dim tablafuente As New Data.DataTable("fuente")
        Dim tablaQUERY As New Data.DataTable("fuente")

        tablafuente.Columns.Add("descargado", System.Type.GetType("System.Int32"))
        tablafuente.Columns.Add("contenedor", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("tipo", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("tamaño", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("lleno", System.Type.GetType("System.Int32"))
        tablafuente.Columns.Add("linea", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("clase", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("posicion", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("fecha", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("iduniversal", System.Type.GetType("System.Int32"))
        tablafuente.Columns.Add("servicio", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("status", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("soid", System.Type.GetType("System.Int32"))
        tablafuente.Columns.Add("queueid", System.Type.GetType("System.Int32"))

        '------------------------------------
        ''busqueda de la visita
        Try
            lint_Visitd = GetVisitFromContainer_Disch(astr_ContainerId)

        Catch ex As Exception
            lint_Visitd = 0
        End Try

        If lint_Visitd = 0 Then
            Return tablafuente
        End If
        '-------------------------------


        Dim ls_SQL_Command As String

        ls_SQL_Command = "SELECT 0 as descargado , SQ.intVisitId," & _
                            "I.strContainerInvYardPositionId, " & _
                                       "(CASE WHEN ( SELECT INV.blnContainerIsFull " & _
                                       "FROM tblclsContainerInventory INV " & _
                                       "WHERE INV.intContainerUniversalId  = SQ.intContainerUniversalId )  = 1 " & _
                                                      "THEN 1 " & _
                                                      "ELSE 0 " & _
                                               "END) as blnContainerIsFull, " & _
                                              "SQ.intContainerUniversalId, " & _
                                              "SV.strServiceIdentifier, " & _
                                              "SQ.strContainerId, " & _
                                              "T.strContainerTypeIdentifier, " & _
                                              "S.strContainerSizeIdentifier, " & _
                                              "SQ.intServiceOrderId, " & _
                                              "SV.strServiceName, " & _
                                              "SQ.dtmServiceQueuStartDate, " & _
                                              "SQ.dtmServiceQueuExecDate, " & _
                                              "SQ.intServiceId, " & _
                                              "SQ.intServiceQueuId, " & _
                                              "SV.strServiceIdentifier, " & _
                                              "(CASE ISNULL(I.intContainerUniversalId,0) " & _
                                              "        WHEN 0 THEN 'SIN ESTATUS' " & _
                                                    "ELSE CFS.strContFisStatusIdentifier " & _
                                               "END) AS status, " & _
                                                 "LINE.strShippingLineIdentifier, " & _
                                                 "CATE.strContainerCatIdentifier , SQ.intServiceOrderId, SQ.intServiceQueuId " & _
                                           "FROM tblclsServiceQueu SQ " & _
                                                "LEFT JOIN tblclsContainerInventory I " & _
                                                  "ON SQ.intContainerUniversalId = I.intContainerUniversalId " & _
                                                  "LEFT JOIN tblclsContainerFiscalStatus CFS " & _
                                                    "ON I.intContFisStatusId =CFS.intContFisStatusId " & _
                                                  "LEFT JOIN tblclsContainerCategory CATE " & _
                                                     "ON I.intContainerCategoryId = CATE.intContainerCategoryId " & _
                                                  "LEFT JOIN  tblclsShippingLine LINE " & _
                                                    "ON I.intContainerInvOperatorId = LINE.intShippingLineId " & _
                                                    "LEFT JOIN tblclsContainer CONT " & _
                                                      "ON I.strContainerId = CONT.strContainerId " & _
                                                      "LEFT JOIN tblclsContainerISOCode ISO " & _
                                                        "ON CONT.intContISOCodeId = ISO.intContISOCodeId " & _
                                                        "LEFT JOIN tblclsContainerSize S " & _
                                                          "ON ISO.intContainerSizeId = S.intContainerSizeId " & _
                                                          "LEFT JOIN tblclsContainerType T " & _
                                                            "ON ISO.intContainerTypeId = T.intContainerTypeId " & _
                                                            "LEFT JOIN tblclsService SV " & _
                                                              "ON SQ.intServiceId = SV.intServiceId " & _
                                       "WHERE  SQ.blnServiceQueuExecuted = 0  AND " & _
                                                    "SQ.dtmServiceQueuCheckIn IS NOT NULL AND " & _
                                                 "SQ.dtmServiceQueuCheckOut IS NULL AND    " & _
                                                 "SQ. dtmServiceQueuExecDate IS NULL AND " & _
                                                 "SQ.intServiceId IN(SELECT SERV.intServiceId " & _
                                                  "FROM tblclsService SERV " & _
                                                 "WHERE SERV.strServiceIdentifier IN ('RECLL','RECV','RECVOS') ) " & _
                                                 "AND  SQ.intVisitId=" & Convert.ToString(lint_Visitd)

        iolecmd_comand.CommandText = ls_SQL_Command

        iAdapt_comand.SelectCommand = iolecmd_comand
        Try
            iAdapt_comand.SelectCommand.Connection.Open()
            iAdapt_comand.Fill(tablaQUERY)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
        Finally
            iAdapt_comand.SelectCommand.Connection.Close()
            iAdapt_comand.SelectCommand.Connection.Dispose()

        End Try
        For Each valor As DataRow In tablaQUERY.Rows
            Dim registro As DataRow = tablafuente.NewRow()
            registro("descargado") = valor("descargado")
            registro("contenedor") = valor("strContainerId")
            registro("tipo") = valor("strContainerTypeIdentifier")
            registro("tamaño") = valor("strContainerSizeIdentifier")
            registro("lleno") = valor("blnContainerIsFull")
            registro("linea") = valor("strShippingLineIdentifier")
            registro("clase") = valor("strContainerCatIdentifier")
            registro("posicion") = ""
            registro("fecha") = Format(Date.Now, "dd/MM/yyyy HH:mm ")
            registro("iduniversal") = valor("intContainerUniversalId")
            registro("servicio") = valor("strServiceIdentifier")
            registro("status") = valor("status")
            registro("soid") = valor("intServiceOrderId")
            registro("queueid") = valor("intServiceQueuId")
            tablafuente.Rows.Add(registro)
        Next
        iAdapt_comand = Nothing
        Return tablafuente
    End Function

    <WebMethod()> _
     Public Function Search_For_Containers_Carga(ByVal VisitId As Integer) As DataTable
        '-----------------------------
        'Dim VisitId As Integer = 721372
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()
        '----------------------------------
        Dim tablafuente As New Data.DataTable("fuente")
        Dim tablaQUERY As New Data.DataTable("fuente")
        tablafuente.Columns.Add("cargado", System.Type.GetType("System.Int32"))
        tablafuente.Columns.Add("contenedor", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("tipo", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("tamaño", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("lleno", System.Type.GetType("System.Int32"))
        tablafuente.Columns.Add("linea", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("clase", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("posicion", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("fecha", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("iduniversal", System.Type.GetType("System.Int32"))
        tablafuente.Columns.Add("servicio", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("status", System.Type.GetType("System.String"))
        tablafuente.Columns.Add("soid", System.Type.GetType("System.Int32"))
        tablafuente.Columns.Add("queueid", System.Type.GetType("System.Int32"))


        Dim ls_SQL_Command As String

        ls_SQL_Command = "SELECT 0 as cargado , SQ.intVisitId," & _
                                            "I.strContainerInvYardPositionId, " & _
                                "(CASE WHEN ( SELECT INV.blnContainerIsFull " & _
                                "FROM tblclsContainerInventory INV " & _
                                "WHERE INV.intContainerUniversalId  = SQ.intContainerUniversalId )  = 1 " & _
                                               "THEN 1 " & _
                                               "ELSE 0 " & _
                                        "END) as blnContainerIsFull, " & _
                                       "SQ.intContainerUniversalId, " & _
                                       "SV.strServiceIdentifier, " & _
                                       "SQ.strContainerId, " & _
                                       "T.strContainerTypeIdentifier, " & _
                                       "S.strContainerSizeIdentifier, " & _
                                       "SQ.intServiceOrderId, " & _
                                       "SV.strServiceName, " & _
                                       "SQ.dtmServiceQueuStartDate, " & _
                                       "SQ.dtmServiceQueuExecDate, " & _
                                       "SQ.intServiceId, " & _
                                       "SQ.intServiceQueuId, " & _
                                       "SV.strServiceIdentifier, " & _
                                       "(CASE ISNULL(I.intContainerUniversalId,0) " & _
                                       "        WHEN 0 THEN 'SIN ESTATUS' " & _
                                             "ELSE CFS.strContFisStatusIdentifier " & _
                                        "END) AS status, " & _
                                          "LINE.strShippingLineIdentifier, " & _
                                          "CATE.strContainerCatIdentifier , SQ.intServiceOrderId, SQ.intServiceQueuId " & _
                                          ", I.strContainerInvYardPositionId " & _
                                    "FROM tblclsServiceQueu SQ " & _
                                         "LEFT JOIN tblclsContainerInventory I " & _
                                           "ON SQ.intContainerUniversalId = I.intContainerUniversalId " & _
                                           "LEFT JOIN tblclsContainerFiscalStatus CFS " & _
                                             "ON I.intContFisStatusId =CFS.intContFisStatusId " & _
                                           "LEFT JOIN tblclsContainerCategory CATE " & _
                                              "ON I.intContainerCategoryId = CATE.intContainerCategoryId " & _
                                           "LEFT JOIN  tblclsShippingLine LINE " & _
                                             "ON I.intContainerInvOperatorId = LINE.intShippingLineId " & _
                                             "LEFT JOIN tblclsContainer CONT " & _
                                               "ON I.strContainerId = CONT.strContainerId " & _
                                               "LEFT JOIN tblclsContainerISOCode ISO " & _
                                                 "ON CONT.intContISOCodeId = ISO.intContISOCodeId " & _
                                                 "LEFT JOIN tblclsContainerSize S " & _
                                                   "ON ISO.intContainerSizeId = S.intContainerSizeId " & _
                                                   "LEFT JOIN tblclsContainerType T " & _
                                                     "ON ISO.intContainerTypeId = T.intContainerTypeId " & _
                                                     "LEFT JOIN tblclsService SV " & _
                                                       "ON SQ.intServiceId = SV.intServiceId " & _
                                "WHERE  SQ.blnServiceQueuExecuted = 0  AND " & _
                                             "SQ.dtmServiceQueuCheckIn IS NOT NULL AND " & _
                                          "SQ.dtmServiceQueuCheckOut IS NULL AND    " & _
                                          "SQ. dtmServiceQueuExecDate IS NULL AND " & _
                                          "SQ.intServiceId IN(SELECT SERV.intServiceId " & _
                                           "FROM tblclsService SERV " & _
                                          "WHERE SERV.strServiceIdentifier IN ('ENTLL','ENTV') ) " & _
                                          " AND ISNULL(I.intContainerUniversalId,0) > 0 " & _
                                          " AND  SQ.intVisitId=" & Convert.ToString(VisitId)

        iolecmd_comand.CommandText = ls_SQL_Command

        iAdapt_comand.SelectCommand = iolecmd_comand
        Try
            iAdapt_comand.SelectCommand.Connection.Open()
            iAdapt_comand.Fill(tablaQUERY)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
        Finally
            iAdapt_comand.SelectCommand.Connection.Close()
            iAdapt_comand.SelectCommand.Connection.Dispose()

        End Try
        For Each valor As DataRow In tablaQUERY.Rows
            Dim registro As DataRow = tablafuente.NewRow()
            registro("cargado") = valor("cargado")
            registro("contenedor") = valor("strContainerId")
            registro("tipo") = valor("strContainerTypeIdentifier")
            registro("tamaño") = valor("strContainerSizeIdentifier")
            registro("lleno") = valor("blnContainerIsFull")
            registro("linea") = valor("strShippingLineIdentifier")
            registro("clase") = valor("strContainerCatIdentifier")
            registro("posicion") = valor("strContainerInvYardPositionId")
            registro("fecha") = Format(Date.Now, "dd/MM/yyyy HH:mm ")
            registro("iduniversal") = valor("intContainerUniversalId")
            registro("servicio") = valor("strServiceIdentifier")
            registro("status") = valor("status")
            registro("soid") = valor("intServiceOrderId")
            registro("queueid") = valor("intServiceQueuId")
            tablafuente.Rows.Add(registro)
        Next
        iAdapt_comand = Nothing

        Return tablafuente
    End Function
    '***************************VENTANA DE CONSULTA DE CONTENEDOR findContainer*****************
    <WebMethod()> _
    Public Function Busqueda_Info(ByVal NumeroContenedor As String) As DataTable
        Dim idt_result As DataTable = New DataTable ' Tabla con el query de resultados 
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()
        idt_result.TableName = "TrearDatos"
        Dim strSQL As String

        'Sentencia SQL que recobra los datos para la pantalla de cambio de Ubicacion
        strSQL = "Select DISTINCT " & _
                     "tblclsContainerInventory.strContainerId, " & _
                     "tblclsContainerInventory.intContainerUniversalId, " & _
                     "tblclsContainerType.strContainerTypeIdentifier, " & _
                     "tblclsContainerSize.strContainerSizeIdentifier, " & _
                     "tblclsContainerInventory.strContainerInvYardPositionId  as strContainerInvYardPositionId, " & _
                     "ISNULL(tblclsContainerCategory.strContainerCatIdentifier,'') AS strContainerCatIdentifier, " & _
                     "tblclsContainerInventory.blnContainerIsFull, " & _
                     "tblclsContainer.blnContIsShiperOwn, " & _
                     "tblclsShippingLine.strShippingLineIdentifier, " & _
                     "CONVERT(VARCHAR(12),tblclsContainerInventory.dtmContainerInvReceptionDate,103) As dtmContainerInvReceptionDate, " & _
                     "tblclsContainerAdmStatus.strContAdmStatusIdentifier, " & _
                     "tblclsContainerFiscalStatus.strContFisStatusIdentifier , " & _
                     "ISNULL(tblclsContainerInvBooking.strBookingId, '') AS strBooking, " & _
                     "ISNULL(tblclsVessel.strVesselName,'') as strVesselName, " & _
                     "isnull((SELECT MAX(tblclsDocument.strDocumentFolio) " & _
                               "FROM tblclsContainerInventoryDoc, " & _
                                    "tblclsDocument, " & _
                                    "tblclsDocumentType " & _
                               "WHERE ( tblclsContainerInventoryDoc.intDocumentId = tblclsDocument.intDocumentId ) and  " & _
                                     "( tblclsDocument.intDocumentTypeId = tblclsDocumentType.intDocumentTypeId ) and  " & _
                                     "( tblclsDocumentType.strDocumentTypeIdentifier = 'TEMP' ) AND  " & _
                                       "tblclsContainerInventoryDoc.intContainerUniversalId = tblclsContainerInventory.intContainerUniversalId ),'Sin Temporal') as Tempo, " & _
                     "DATEDIFF(dd, dtmContainerInvReceptionDate, GETDATE()) AS intDaysInTerminal, " & _
                     "isnull( tblclsContainerInventory.strContainerInvPortOfOriginId,'') as strContainerInvPortOfOriginId, " & _
                     "isnull( tblclsContainerInventory.strContainerInvDischargePortId, '') as strContainerInvDischargePortId, " & _
                     " tblclsContainerInventory.strContainerInvComments " & _
                "From tblclsContainerInventory " & _
                     "Join tblclsContainer " & _
                      "ON tblclsContainerInventory.strContainerId = tblclsContainer.strContainerId " & _
                     "Join tblclsContainerISOCode " & _
                      "ON tblclsContainerISOCode.intContISOCodeId = tblclsContainer.intContISOCodeId " & _
                      "LEFT JOIN tblclsContainerType " & _
                       "ON tblclsContainerISOCode.intContainerTypeId = tblclsContainerType.intContainerTypeId " & _
                       "LEFT JOIN tblclsContainerSize " & _
                        "ON tblclsContainerISOCode.intContainerSizeId = tblclsContainerSize.intContainerSizeId " & _
                        "LEFT JOIN tblclsVesselVoyage " & _
                         "ON tblclsContainerInventory.intContainerInvVesselVoyageId = tblclsVesselVoyage.intVesselVoyageId " & _
                         "LEFT JOIN tblclsContainerInvBooking " & _
                          "ON tblclsContainerInventory.intContainerUniversalId = tblclsContainerInvBooking.intContainerUniversalId " & _
                          "LEFT JOIN tblclsContainerCategory " & _
                           "ON tblclsContainerInventory.intContainerCategoryId = tblclsContainerCategory.intContainerCategoryId " & _
                           "LEFT JOIN tblclsShippingLine " & _
                            "ON tblclsContainerInventory.intContainerInvOperatorId = tblclsShippingLine.intShippingLineId " & _
                            "LEFT JOIN tblclsContainerAdmStatus " & _
                             "ON tblclsContainerInventory.intContAdmStatusId = tblclsContainerAdmStatus.intContAdmStatusId " & _
                             "LEFT JOIN tblclsContainerFiscalStatus " & _
                              "ON tblclsContainerInventory.intContFisStatusId = tblclsContainerFiscalStatus.intContFisStatusId " & _
                              "LEFT JOIN tblclsVessel " & _
                              "ON tblclsVesselVoyage.intVesselId = tblclsVessel.intVesselId " & _
                              "Where tblclsContainerInventory.blnContainerInvActive = 1 " & _
                          "AND tblclsContainerInventory.strContainerId = '" & NumeroContenedor & "' "

        iolecmd_comand.CommandText = strSQL

        iAdapt_comand.SelectCommand = iolecmd_comand
        Try
            'ioleconx_conexion.Open()
            iAdapt_comand.SelectCommand.Connection.Open()
            iAdapt_comand.Fill(idt_result)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
        Finally
            ioleconx_conexion.Close()
            iAdapt_comand.SelectCommand.Connection.Close()
            ioleconx_conexion.Dispose()
            iAdapt_comand.SelectCommand.Connection.Dispose()
        End Try

        ioleconx_conexion = Nothing
        iAdapt_comand = Nothing

        Return idt_result
    End Function

    <WebMethod()> _
       Public Function Busqueda_IMO(ByVal NumeroContenedor As String) As DataTable
        Dim idt_result As DataTable = New DataTable ' Tabla con el query de resultados 
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        'Dim strcontainerid As String = "IPXU3283286"
        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()
        idt_result.TableName = "TrearDatos"
        Dim strSQL As String
        strSQL = "SELECT  tblclsIMOCode.strIMOCodeIdentifier  " & _
                  "FROM tblclsContainerInventory " & _
                  "left join tblIMOCode_ContainerInventory " & _
                  "on tblclsContainerInventory.intContainerUniversalId = tblIMOCode_ContainerInventory.intContainerUniversalId " & _
                  "left join tblclsIMOCode " & _
                  "on tblIMOCode_ContainerInventory.intIMOCodeId = tblclsIMOCode.intIMOCodeId " & _
                  " WHERE tblclsIMOCode.blnIMOCodeActive = 1 " & _
                  "and tblclsContainerInventory.blnContainerInvActive = 1 " & _
                  "and   tblclsContainerInventory.strContainerId = '" & NumeroContenedor & "' "
        iolecmd_comand.CommandText = strSQL

        iAdapt_comand.SelectCommand = iolecmd_comand
        Try
            ' ioleconx_conexion.Open()
            iAdapt_comand.SelectCommand.Connection.Open()
            iAdapt_comand.Fill(idt_result)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
        Finally
            ioleconx_conexion.Close()
            iAdapt_comand.SelectCommand.Connection.Close()
            iAdapt_comand.SelectCommand.Connection.Dispose()
            ioleconx_conexion.Dispose()
        End Try
        ioleconx_conexion = Nothing
        iAdapt_comand = Nothing
        Return idt_result
    End Function
    '***************************VENTANA DE CLASE DE CONTENEDOR WbF_updatecontcategory*****************
    <WebMethod()> _
       Public Function Busqueda_Contenedor(ByVal NumeroContenedor As String) As DataTable
        Dim idt_result As DataTable = New DataTable ' Tabla con el query de resultados 
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        'Dim strcontainerid As String = "IPXU3283286"
        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()
        idt_result.TableName = "TrearDatos"
        Dim strSQL As String
        strSQL = "SELECT tblclsContainerInventory.intContainerUniversalId, " & _
                        "tblclsContainerInventory.strContainerId, " & _
                        "tblclsContainerInventory.blnContainerIsFull, " & _
                        "tblclsContainerInventory.intContainerCategoryId, " & _
                        "tblclsContainerType.strContainerTypeIdentifier, " & _
                        "tblclsContainerSize.strContainerSizeIdentifier, " & _
                        "tblclsShippingLine.strShippingLineIdentifier, " & _
                        "tblclsContainerInventory.strContainerInvComments, " & _
                        "(CASE ISNULL(tblclsContainerInventory.intContainerUniversalId, 0) " & _
                               "WHEN 0 THEN 'SIN ESTATUS' " & _
                               "ELSE tblclsContainerFiscalStatus.strContFisStatusIdentifier " & _
                          "END) AS 'strContFisStatusIdentifier', " & _
                        "(SELECT (CASE WHEN tblclsContainerFiscalStatus.strContFisStatusIdentifier= 'RETENIDO' " & _
                                       "THEN 0 " & _
                                       "WHEN  A.strContAdmStatusIdentifier= 'PCLAS' " & _
                                       "THEN -1 " & _
                                       "ELSE 1 " & _
                                  "END) " & _
                           "FROM tblclsContainerAdmStatus A " & _
                          "WHERE A.intContAdmStatusId =tblclsContainerInventory.intContAdmStatusId  ) " & _
                         "as Valida " & _
        "FROM tblclsContainerInventory " & _
                      "LEFT OUTER JOIN tblclsContainerFiscalStatus " & _
                         "ON tblclsContainerInventory.intContFisStatusId = tblclsContainerFiscalStatus.intContFisStatusId " & _
                       "LEFT JOIN tblclsContainer " & _
                        "ON tblclsContainerInventory.strContainerId = tblclsContainer.strContainerId " & _
                        "LEFT JOIN tblclsContainerISOCode " & _
                         "ON tblclsContainer.intContISOCodeId = tblclsContainerISOCode.intContISOCodeId " & _
                         "LEFT JOIN tblclsContainerType " & _
                          "ON tblclsContainerISOCode.intContainerTypeId = tblclsContainerType.intContainerTypeId " & _
                          "LEFT JOIN tblclsContainerSize " & _
                           "ON tblclsContainerISOCode.intContainerSizeId  = tblclsContainerSize.intContainerSizeId " & _
                           "LEFT JOIN tblclsShippingLine " & _
                            "ON tblclsContainerInventory.intContainerInvOperatorId = tblclsShippingLine.intShippingLineId " & _
        "WHERE tblclsContainerInventory.blnContainerInvActive = 1 " & _
                    "AND tblclsContainerInventory.blnContainerIsFull = 0 " & _
                    "AND tblclsContainerInventory.strContainerId = '" & NumeroContenedor & "'"
        iolecmd_comand.CommandText = strSQL

        iAdapt_comand.SelectCommand = iolecmd_comand
        Try
            ioleconx_conexion.Open()
            'iAdapt_comand.SelectCommand.Connection.Open()
            iAdapt_comand.Fill(idt_result)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
        Finally
            ioleconx_conexion.Close()
            iAdapt_comand.SelectCommand.Connection.Close()
            iAdapt_comand.SelectCommand.Connection.Dispose()
            ioleconx_conexion.Dispose()

        End Try
        ioleconx_conexion = Nothing
        iAdapt_comand = Nothing

        Return idt_result
    End Function
    <WebMethod()> _
       Public Function Clases() As DataTable
        Dim idt_result As DataTable = New DataTable ' Tabla con el query de resultados 
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        'Dim strcontainerid As String = "IPXU3283286"
        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()
        idt_result.TableName = "TrearDatos"
        Dim strSQL As String
        strSQL = "SELECT strContainerCatIdentifier, intContainerCategoryId FROM tblclsContainerCategory ORDER BY strContainerCatIdentifier"
        iolecmd_comand.CommandText = strSQL

        iAdapt_comand.SelectCommand = iolecmd_comand
        Try
            'ioleconx_conexion.Open()
            iAdapt_comand.SelectCommand.Connection.Open()
            iAdapt_comand.Fill(idt_result)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
        Finally
            ioleconx_conexion.Close()
            iAdapt_comand.SelectCommand.Connection.Close()
        End Try
        Return idt_result
    End Function

    <WebMethod()> _
      Public Function Obtener_ClaseActual(ByVal IDClase As Integer) As String
        ' Dim Categoria As String = "AR"
        Dim myConnectionString = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        Dim myConnection As New OleDbConnection(myConnectionString)
        Dim mySelectQuery = "SELECT strContainerCatIdentifier FROM tblclsContainerCategory where intContainerCategoryId=" & IDClase & ""
        Dim myCommand As New OleDbCommand(mySelectQuery, myConnection)

        Dim idt_result As DataTable = New DataTable ' Tabla con el query de resultados 
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim istr_Result As String

        'myConnection.Open()
        'Dim myReader As OleDbDataReader = myCommand.ExecuteReader()
        'If myReader.HasRows Then
        '    myReader.Read()
        '    Dim Id_Categoria = myReader(0)
        '    myConnection.Close()
        '    Return Id_Categoria
        '    myReader.Close()
        '    myReader = Nothing
        '    Exit Function
        'End If
        'myConnection.Close()
        'Return 0
        'myReader.Close()
        ''MyConnection.Open()

        '' inicializa en vacio la variable de resutlado 
        istr_Result = ""

        idt_result.TableName = "TrearDatos"
        'iolecmd_comand.CommandText = strSQL

        iAdapt_comand.SelectCommand = myCommand
        Try
            'ioleconx_conexion.Open()
            iAdapt_comand.SelectCommand.Connection.Open()
            iAdapt_comand.Fill(idt_result)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
        Finally
            myConnection.Close()
            iAdapt_comand.SelectCommand.Connection.Close()
        End Try

        myConnection.Dispose()
        iAdapt_comand.SelectCommand.Connection.Dispose()
        iAdapt_comand.Dispose()

        myConnection = Nothing
        iAdapt_comand = Nothing

        If idt_result.Columns.Count = 1 And idt_result.Rows.Count = 1 Then

            istr_Result = idt_result(0)(0).ToString()

            If istr_Result.Length > 0 And istr_Result.Length < 17 Then '' generalment el nombre de la clase no es muy largo 
                Return istr_Result

            Else
                Return ""
            End If
        Else
            Return ""
        End If

        Return ""

    End Function

    <WebMethod()> _
      Public Function Actualizar_Inventario(ByVal txt_Comentarios As String, ByVal Clase_Seleccionada As String, ByVal id_Universal As Integer) As Integer
        'Dim txt_Comentarios As String = "DEAD NOTHE"
        'Dim Clase_Seleccionada As String = "AR"
        'Dim id_Universal As Integer = 8069992
        Dim resultado = Obtener_IdClase(Clase_Seleccionada)
        'Dim myReader As OleDbDataReader
        Dim myConnectionString = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        Dim myConnection As New OleDbConnection(myConnectionString)
        Dim mySelectQuery As String

        Try
            mySelectQuery = "update tblclsContainerInventory " & _
                 "set tblclsContainerInventory.strContainerInvComments = '" & txt_Comentarios & "', " & _
                 "tblclsContainerInventory.intContainerCategoryId = " & resultado & _
                 "where tblclsContainerInventory.intContainerUniversalId = " & id_Universal
            Dim myCommand As New OleDbCommand(mySelectQuery, myConnection)
            myConnection.Open()
            'myReader = myCommand.ExecuteReader()
            myCommand.ExecuteNonQuery()

        Catch ex As Exception
            Return 0
            'myReader.Close()
            Exit Function
        Finally
            myConnection.Close()
            myConnection.Dispose()
        End Try
        myConnection = Nothing
        Return 1
        'myReader.Close()
    End Function

    <WebMethod()> _
         Public Function Actualizar_Status_Contenedor(ByVal UniversalId As Integer, ByVal CategId As Integer, ByVal Comments As String, ByVal User As String) As Integer
        '-----------------------------
        'Dim UniversalId As Integer = 806999
        'Dim CategId As Integer = 46
        'Dim Comments As String = "Dead Nothe"
        'Dim User As String = "RSathielle"

        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand
        '----------------------------------

        Dim oleDb_param As OleDbParameter = New OleDbParameter()
        Dim ls_sql As String
        Dim ol_param_Universal As OleDbParameter = New OleDbParameter()
        Dim ol_param_CategId As OleDbParameter = New OleDbParameter()
        Dim ol_param_Comments As OleDbParameter = New OleDbParameter()
        Dim ol_param_User As OleDbParameter = New OleDbParameter()

        Dim oleDb_paramOut As OleDbParameter = New OleDbParameter()


        ol_param_Universal.ParameterName = "@UniversalId"
        ol_param_Universal.OleDbType = OleDbType.Integer
        ol_param_Universal.Value = UniversalId

        ol_param_CategId.ParameterName = "@CategId"
        ol_param_CategId.OleDbType = OleDbType.Integer
        ol_param_CategId.Value = CategId

        'agregando fraccionarios
        ol_param_Comments.ParameterName = "@Comments"
        ol_param_Comments.OleDbType = OleDbType.Char
        ol_param_Comments.Value = Comments

        ol_param_User.ParameterName = "@User"
        ol_param_User.OleDbType = OleDbType.Char
        ol_param_User.Value = User

        'oleDb_paramOut.ParameterName = "@intErrorCode"
        'oleDb_paramOut.OleDbType = OleDbType.Integer
        'oleDb_paramOut.Direction = ParameterDirection.Output

        ls_sql = "spUpdateHistoryCategory"

        oleDBcom.CommandText = ls_sql
        oleDBcom.CommandType = CommandType.StoredProcedure
        oleDBcom.Parameters.Add(ol_param_Universal) '(intcontaineruniversalid) 'Id universal del contenedor)
        oleDBcom.Parameters.Add(ol_param_CategId)
        oleDBcom.Parameters.Add(ol_param_Comments)
        oleDBcom.Parameters.Add(ol_param_User)
        oleDBcom.CommandTimeout = 0
        Try
            oleDBconnx.Open()
            oleDBcom.ExecuteNonQuery()

        Catch ex As Exception
            Return 0
            Exit Function
        Finally
            oleDBconnx.Close()
            oleDBcom.Connection.Close()
            oleDBcom.Connection.Dispose()
            oleDBconnx.Dispose()

        End Try
        oleDBconnx = Nothing
        oleDBcom = Nothing

        Return 1
    End Function
    <WebMethod()> _
       Public Function Obtener_IdClase(ByVal Categoria As String) As Integer
        ' Dim Categoria As String = "AR"
        Dim myConnectionString = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        Dim myConnection As New OleDbConnection(myConnectionString)
        Dim mySelectQuery = "SELECT intContainerCategoryId FROM tblclsContainerCategory	where strContainerCatIdentifier='" & Categoria & "'"
        Dim myCommand As New OleDbCommand(mySelectQuery, myConnection)

        'myConnection.Open()
        'Dim myReader As OleDbDataReader = myCommand.ExecuteReader()
        'If myReader.HasRows Then
        '    myReader.Read()
        '    Dim Id_Categoria = myReader(0)
        '    myConnection.Close()
        '    Return Id_Categoria
        '    myReader.Close()
        '    myReader = Nothing
        '    Exit Function
        'End If
        'myConnection.Close()
        'Return 0
        'myReader.Close()

        '---------------------------
        Dim iadpt_ole As OleDbDataAdapter = New OleDbDataAdapter()
        Dim idat_Table As DataTable = New DataTable()
        iadpt_ole.SelectCommand = myCommand
        Dim iint_id As Integer = 0

        Try
            myConnection.Open()
            iadpt_ole.Fill(idat_Table)

            'revisar la informacion que trae la tabla 
            If idat_Table.Columns.Count = 1 And idat_Table.Rows.Count = 1 Then
                iint_id = Convert.ToInt64(idat_Table(0)(0))
            Else
                iint_id = 0
            End If


        Catch ex As Exception
            Dim lstr_Value As String
            lstr_Value = ex.Message
            iint_id = 0
        Finally
            iadpt_ole.SelectCommand.Connection.Close()
            myConnection.Close()

            iadpt_ole.Dispose()
            myConnection.Close()

        End Try

        iadpt_ole = Nothing
        myConnection = Nothing

        Return iint_id


    End Function

    '***************************VENTANA DE Cheak_In *****************
    <WebMethod()> _
      Public Function Datos_de_la_Visita(ByVal Visita As Integer) As Data.DataTable
        Dim idt_result As DataTable = New DataTable ' Tabla con el query de resultados 
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        'Dim strcontainerid As String = "IPXU3283286"
        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()
        idt_result.TableName = "TrearDatos"
        Dim strSQL As String
        Try
            strSQL = "SELECT intVisitId,   " & _
                "strVisitDriver,   " & _
                "strVisitPlate, " & _
                "strCarrierLineName, " & _
                "strVisitDriverLicenceNumber, " & _
                "dtmVisitDatetimeIn, " & _
                "dtmVisitDatetimeOut " & _
                "FROM tblclsVisit, tblclsCarrierLine  " & _
                "WHERE ( tblclsVisit.intCarrierLineId = tblclsCarrierLine.intCarrierLineId ) and " & _
                "( tblclsVisit.intVisitId = " & Convert.ToString(Visita) & ") "
            iolecmd_comand.CommandText = strSQL

            iAdapt_comand.SelectCommand = iolecmd_comand
            iAdapt_comand.Fill(idt_result)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
        Finally
            ioleconx_conexion.Close()
            iolecmd_comand.Connection.Close()
            iolecmd_comand.Connection.Dispose()
            ioleconx_conexion.Dispose()
        End Try
        iolecmd_comand = Nothing
        ioleconx_conexion = Nothing
        Return idt_result
    End Function

    <WebMethod()> _
      Public Function CargarGrid_Visita_Check_in(ByVal Visita As Integer, ByVal cadena As String) As Data.DataTable

        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand

        '----------------------------------

        Dim lodb_VisitId As OleDbParameter = New OleDbParameter()
        Dim lodb_REC As OleDbParameter = New OleDbParameter()
        Dim ls_SQL_Command As String
        'redefinicion de parametros


        lodb_VisitId.OleDbType = OleDbType.Integer
        lodb_VisitId.ParameterName = "@intVisitId"
        lodb_VisitId.Value = Integer.Parse(Visita) '693647 'Integer.Parse(Visita)

        lodb_REC.OleDbType = OleDbType.Char
        lodb_REC.ParameterName = "@strService"
        lodb_REC.Value = cadena

        ' asignacion de valores

        ls_SQL_Command = "spGetVisitItemsToProcess"

        ' asociacion de parametros al comando

        oleDBcom.Parameters.Add(lodb_VisitId)
        oleDBcom.Parameters.Add(lodb_REC)

        oleDBcom.CommandText = ls_SQL_Command
        oleDBcom.CommandType = CommandType.StoredProcedure

        Dim DataResult As DataTable = New Data.DataTable() 'DataSet = New DataSet()
        DataResult.TableName = "TrearDatos"
        Dim adapter As OleDbDataAdapter = New OleDbDataAdapter(oleDBcom)

        Try
            oleDBconnx.Open()
            adapter.Fill(DataResult)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
        Finally
            oleDBconnx.Close()
            adapter.Dispose()
        End Try

        oleDBconnx = Nothing
        adapter = Nothing

        Return DataResult
    End Function

    <WebMethod()> _
     Public Function Guardar_Datos_Check_in(ByVal Visita As Integer, ByRef Free As Integer, ByRef _Error As Integer)
        '-----------------------------

        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand
        '----------------------------------

        Dim oleDb_param As OleDbParameter = New OleDbParameter()
        Dim ls_sql As String

        Dim lodb_VisitId As OleDbParameter = New OleDbParameter()
        Dim lodb_VisitIn As OleDbParameter = New OleDbParameter()
        Dim oleDb_paramOut_Free As OleDbParameter = New OleDbParameter()
        Dim oleDb_paramOut_ErrorCode As OleDbParameter = New OleDbParameter()

        Dim comments As String = ""

        lodb_VisitId.ParameterName = "@intVisitId"
        lodb_VisitId.OleDbType = OleDbType.Integer
        lodb_VisitId.Value = Integer.Parse(Visita)

        lodb_VisitIn.ParameterName = "@blnVisitIn"
        lodb_VisitIn.OleDbType = OleDbType.Integer
        lodb_VisitIn.Value = 1

        oleDb_paramOut_Free.ParameterName = "@intFree"
        oleDb_paramOut_Free.OleDbType = OleDbType.Integer
        oleDb_paramOut_Free.Direction = ParameterDirection.Output

        oleDb_paramOut_ErrorCode.ParameterName = "@intErrorCode"
        oleDb_paramOut_ErrorCode.OleDbType = OleDbType.Integer
        oleDb_paramOut_ErrorCode.Direction = ParameterDirection.Output

        ls_sql = "spValidateItemOutIsFree"

        oleDBcom.CommandText = ls_sql
        oleDBcom.CommandType = CommandType.StoredProcedure
        oleDBcom.Parameters.Add(lodb_VisitId) '(intcontaineruniversalid) 'Id universal del contenedor)
        oleDBcom.Parameters.Add(lodb_VisitIn)
        oleDBcom.Parameters.Add(oleDb_paramOut_Free)
        oleDBcom.Parameters.Add(oleDb_paramOut_ErrorCode)


        oleDBcom.CommandTimeout = 0
        Try
            oleDBconnx.Open()
            oleDBcom.ExecuteNonQuery()
        Catch ex As Exception
            ' Return 0
        Finally
            oleDBconnx.Close()
            oleDBcom.Connection.Close()
            oleDBconnx.Dispose()
            oleDBcom.Connection.Dispose()
        End Try
        If IsDBNull(oleDb_paramOut_Free.Value) = True Then
            Free = 1
        Else
            Free = oleDb_paramOut_Free.Value
        End If

        If IsDBNull(oleDb_paramOut_ErrorCode.Value) = True Then
            _Error = 0
        Else
            _Error = oleDb_paramOut_ErrorCode.Value

        End If
        oleDBconnx = Nothing
        oleDBcom = Nothing
        'Return oleDb_paramOut_ErrorCode.Value
    End Function

    <WebMethod()> _
      Public Function spUpdateSOStatus(ByVal AUT As String, ByVal ENTLL As String, ByVal Visita As Integer) As Integer
        Dim param As New OleDbParameter
        param.ParameterName = ParameterDirection.ReturnValue

        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        Dim x As Integer = 666

        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand
        '----------------------------------

        Dim oleDb_param_AUT As OleDbParameter = New OleDbParameter()
        Dim oleDb_param_ENTLL As OleDbParameter = New OleDbParameter()
        Dim oleDb_param_VisitId As OleDbParameter = New OleDbParameter()

        Dim ls_sql As String

        oleDb_param_AUT.ParameterName = "@StatIdentifier"
        oleDb_param_AUT.OleDbType = OleDbType.Char
        oleDb_param_AUT.Value = "AUT"

        oleDb_param_ENTLL.ParameterName = "@ServIdentifier"
        oleDb_param_ENTLL.OleDbType = OleDbType.Char
        oleDb_param_ENTLL.Value = "ENTLL"

        oleDb_param_VisitId.ParameterName = "@ServRowId"
        oleDb_param_VisitId.OleDbType = OleDbType.Integer
        oleDb_param_VisitId.Value = Integer.Parse(Visita)

        ls_sql = "spUpdateSOStatus"

        oleDBcom.CommandText = ls_sql
        oleDBcom.CommandType = CommandType.StoredProcedure
        param = oleDBcom.Parameters.Add("returnvalue", OleDbType.Integer)
        param.Direction = ParameterDirection.ReturnValue
        oleDBcom.Parameters.Add(oleDb_param_AUT)
        oleDBcom.Parameters.Add(oleDb_param_ENTLL)
        oleDBcom.Parameters.Add(oleDb_param_VisitId)
        oleDBcom.CommandTimeout = 0
        Try
            oleDBconnx.Open()
            oleDBcom.ExecuteNonQuery()
            'ocupado = oleDb_paramOut.Value
            x = param.Value
        Catch ex As Exception
            'Return 0
        Finally
            oleDBconnx.Close()
            oleDBcom.Connection.Close()
            oleDBconnx.Dispose()
            oleDBcom.Connection.Dispose()
        End Try

        oleDBconnx = Nothing
        oleDBcom = Nothing

        Return x
    End Function

    <WebMethod()> _
     Public Function spDeleteESigns(ByVal Visita As Integer) As Integer
        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand
        '----------------------------------
        Dim _Error As Integer
        Dim oleDb_param As OleDbParameter = New OleDbParameter()
        Dim ls_sql As String

        Dim lodb_ServiceOrderId As OleDbParameter = New OleDbParameter()
        Dim lodb_ServiceIdentifier As OleDbParameter = New OleDbParameter()
        Dim oleDb_paramOut_Free As OleDbParameter = New OleDbParameter()
        Dim oleDb_paramOut_ErrorCode As OleDbParameter = New OleDbParameter()

        Dim comments As String = ""



        lodb_ServiceOrderId.ParameterName = "@ServiceOrderId"
        lodb_ServiceOrderId.OleDbType = OleDbType.Integer
        lodb_ServiceOrderId.Value = Integer.Parse(Visita)

        lodb_ServiceIdentifier.ParameterName = "@ServiceIdentifier"
        lodb_ServiceIdentifier.OleDbType = OleDbType.Integer
        lodb_ServiceIdentifier.Value = "ENTLL"

        oleDb_paramOut_ErrorCode.ParameterName = "@ErrorCode"
        oleDb_paramOut_ErrorCode.OleDbType = OleDbType.Integer
        oleDb_paramOut_ErrorCode.Direction = ParameterDirection.Output

        ls_sql = "spDeleteESigns"

        oleDBcom.CommandText = ls_sql
        oleDBcom.CommandType = CommandType.StoredProcedure
        oleDBcom.Parameters.Add(lodb_ServiceOrderId) '(intcontaineruniversalid) 'Id universal del contenedor)
        oleDBcom.Parameters.Add(lodb_ServiceIdentifier)
        oleDBcom.Parameters.Add(oleDb_paramOut_ErrorCode)

        oleDBcom.CommandTimeout = 0
        Try
            oleDBconnx.Open()
            oleDBcom.ExecuteNonQuery()
        Catch ex As Exception
            ' Return 0
        Finally
            oleDBconnx.Close()
            oleDBcom.Connection.Close()
            oleDBcom.Connection.Dispose()
            oleDBconnx.Dispose()
        End Try
        _Error = oleDb_paramOut_ErrorCode.Value
        oleDBcom = Nothing
        oleDBconnx = Nothing
    End Function

    '<WebMethod()> _
    ' Public Function spInOutVisit(ByVal Visita As Integer, ByVal UserName As String, ByVal cadena As String) As Integer
    '    Dim param As New OleDbParameter
    '    param.ParameterName = ParameterDirection.ReturnValue
    '    Dim x As Integer = 666
    '    Dim oleDBconnx As OleDbConnection
    '    Dim oleDBcom As OleDbCommand
    '    oleDBcom = New OleDbCommand()
    '    oleDBconnx = New OleDbConnection()
    '    Dim strconx As String
    '    strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
    '    oleDBconnx.ConnectionString = strconx
    '    oleDBcom = oleDBconnx.CreateCommand
    '    '----------------------------------
    '    Dim oleDb_param As OleDbParameter = New OleDbParameter()
    '    Dim ls_sql As String

    '    Dim lodb_intVisitId As OleDbParameter = New OleDbParameter()
    '    Dim lodb_dtmReceptionDate As OleDbParameter = New OleDbParameter()
    '    Dim lodb_strService As OleDbParameter = New OleDbParameter()
    '    Dim lodb_strUser As OleDbParameter = New OleDbParameter()

    '    Dim comments As String = ""

    '    lodb_intVisitId.ParameterName = "@intVisitId"
    '    lodb_intVisitId.OleDbType = OleDbType.Integer
    '    lodb_intVisitId.Value = Integer.Parse(Visita)

    '    lodb_dtmReceptionDate.ParameterName = "@dtmReceptionDate"
    '    lodb_dtmReceptionDate.OleDbType = OleDbType.Char
    '    lodb_dtmReceptionDate.Value = Format(Date.Now, "yyyyMMdd HH:mm:ss")

    '    lodb_strService.ParameterName = "@strService"
    '    lodb_strService.OleDbType = OleDbType.Char
    '    lodb_strService.Value = cadena


    '    lodb_strUser.ParameterName = "@strUser"
    '    lodb_strUser.OleDbType = OleDbType.Char
    '    lodb_strUser.Value = UserName

    '    ls_sql = "spInOutVisit"

    '    oleDBcom.CommandText = ls_sql

    '    param = oleDBcom.Parameters.Add("returnvalue", OleDbType.Integer)
    '    param.Direction = ParameterDirection.ReturnValue

    '    oleDBcom.CommandType = CommandType.StoredProcedure
    '    oleDBcom.Parameters.Add(lodb_intVisitId) '(intcontaineruniversalid) 'Id universal del contenedor)
    '    oleDBcom.Parameters.Add(lodb_dtmReceptionDate)
    '    oleDBcom.Parameters.Add(lodb_strService)
    '    oleDBcom.Parameters.Add(lodb_strUser)

    '    oleDBcom.CommandTimeout = 0
    '    Try
    '        oleDBconnx.Open()
    '        x = param.Value
    '        oleDBcom.ExecuteNonQuery()
    '    Catch ex As Exception
    '        ' Return 0
    '    Finally
    '        oleDBconnx.Close()
    '        oleDBcom.Connection.Close()
    '        oleDBcom.Connection.Dispose()
    '        oleDBconnx.Dispose()
    '    End Try
    '    ' _Error = oleDb_paramOut_ErrorCode.Value
    '    oleDBcom = Nothing
    '    oleDBconnx = Nothing
    '    Return x
    'End Function

    <WebMethod()> _
  Public Function spInOutVisit(ByVal Visita As Integer, ByVal UserName As String, ByVal cadena As String) As Integer




        Dim param As New OleDbParameter
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim ldt_TableResult As DataTable = New DataTable("Result")
        param.ParameterName = ParameterDirection.ReturnValue

        Dim x As Integer = 666
        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand
        '----------------------------------
        Dim oleDb_param As OleDbParameter = New OleDbParameter()
        Dim ls_sql As String

        Dim lodb_intVisitId As OleDbParameter = New OleDbParameter()
        Dim lodb_dtmReceptionDate As OleDbParameter = New OleDbParameter()
        Dim lodb_strService As OleDbParameter = New OleDbParameter()
        Dim lodb_strUser As OleDbParameter = New OleDbParameter()

        Dim comments As String = ""

        lodb_intVisitId.ParameterName = "@intVisitId"
        lodb_intVisitId.OleDbType = OleDbType.Integer
        lodb_intVisitId.Value = Integer.Parse(Visita)

        lodb_dtmReceptionDate.ParameterName = "@dtmReceptionDate"
        lodb_dtmReceptionDate.OleDbType = OleDbType.Char
        lodb_dtmReceptionDate.Value = Format(Date.Now, "yyyyMMdd HH:mm:ss")

        lodb_strService.ParameterName = "@strService"
        lodb_strService.OleDbType = OleDbType.Char
        lodb_strService.Value = cadena


        lodb_strUser.ParameterName = "@strUser"
        lodb_strUser.OleDbType = OleDbType.Char
        lodb_strUser.Value = UserName


        param = oleDBcom.Parameters.Add("returnvalue", OleDbType.Integer)
        param.Direction = ParameterDirection.ReturnValue


        oleDBcom.Parameters.Add(lodb_intVisitId) '(intcontaineruniversalid) 'Id universal del contenedor)
        oleDBcom.Parameters.Add(lodb_dtmReceptionDate)
        oleDBcom.Parameters.Add(lodb_strService)
        oleDBcom.Parameters.Add(lodb_strUser)
        's_sql = "exec spUpdateHistoryContPosition ?,?,?,?,?,?, NULL ,? "
        's_sql = "exec intVisitId ?,?,?,? "

        ''''''''''''''''''''''''''''''''''''
        '' si el servicio es recepcion 
        'If cadena.IndexOf("REC") >= 0 Then

        '    ls_sql = "spInOutVisit"
        '    oleDBcom.CommandText = ls_sql
        '    oleDBcom.CommandType = CommandType.StoredProcedure

        '    oleDBcom.CommandTimeout = 0
        '    Try
        '        oleDBconnx.Open()
        '        ' x = param.Value
        '        oleDBcom.ExecuteNonQuery()
        '        x = 0
        '    Catch ex As Exception
        '        Dim lstr_ex As String
        '        lstr_ex = ex.Message
        '        Return -1
        '    Finally
        '        oleDBconnx.Close()
        '        oleDBcom.Connection.Close()
        '        oleDBcom.Connection.Dispose()
        '        oleDBconnx.Dispose()
        '    End Try
        '    ' _Error = oleDb_paramOut_ErrorCode.Value
        '    oleDBcom = Nothing
        '    oleDBconnx = Nothing
        'End If ' If cadena.IndexOf("REC") >= 0 Then

        '''''''''''''''''''''''''''''''''''''
        ' si el servicio es salida 
        'If cadena.IndexOf("ENT") >= 0 Then
        If cadena.Length >= 0 Then

            'iolecmd_comand.CommandText = ls_SQL_Command

            'ls_sql = "spInOutVisit"
            'ls_sql = "exec spInOutVisit ?,?,?,? "
            ' ls_sql = "execute  spInOutVisit @intVisitId = ?, @dtmReceptionDate = ?,@strService = ?, @strUser = ? "
            ''execute dbo.spInOutVisit  @intVisitId=1603183, @dtmReceptionDate="20190504 10:54", @strService="ENTLL", @strUser="jcadena"
            '' poner como texto difecto 
            oleDBcom.Parameters.Clear()
            ls_sql = "execute  spInOutVisit @intVisitId = " + lodb_intVisitId.Value.ToString() + " , @dtmReceptionDate = '" + lodb_dtmReceptionDate.Value.ToString() + "' ,@strService = '" + lodb_strService.Value.ToString() + "' , @strUser ='" + lodb_strUser.Value.ToString() + "'"

            oleDBcom.CommandText = ls_sql
            'oleDBcom.CommandType = CommandType.StoredProcedure

            iAdapt_comand.SelectCommand = oleDBcom
            Try
                oleDBcom.Connection.Open()
                iAdapt_comand.Fill(ldt_TableResult)
                x = 0
            Catch ex As Exception
                Dim strError As String
                strError = ObtenerError(ex.Message, 99999)
            Finally
                iAdapt_comand.SelectCommand.Connection.Close()
                oleDBcom.Connection.Close()

                iAdapt_comand.SelectCommand.Connection.Dispose()
                oleDBcom.Connection.Dispose()
            End Try

            iAdapt_comand = Nothing
            oleDBcom = Nothing


        End If 'If lengh >= 0 Then

        '''si hay notiiciones en bandera

        Try
            Dim lint_notifications As Integer
            Dim lstr_CadenaSent As String
            Dim llng_Visit As Long
            Dim llng_Universal As Long
            Dim lstr_Contenedor As String

            lint_notifications = CType(ConfigurationManager.AppSettings.Item("SendNotifications").ToString, Integer)
            lstr_CadenaSent = ""
            'si esta habilitado enviar notificaciones
            If lint_notifications > 0 Then

                ' ver si hay elementos por procesar
                Dim ldt_table As DataTable = New DataTable("elements")
                Dim lstr_Driverlicense As String
                ldt_table = Datos_de_la_Visita(Visita)
                ' si tiene elementos avanza
                If ldt_table.Rows.Count > 0 Then


                    For Each lrow As DataRow In ldt_table.Rows

                        'Obtenner el numero de contenenedor para enviar 
                        lstr_Driverlicense = lrow("strVisitDriverLicenceNumber").ToString()


                        If cadena.IndexOf("REC") > -1 Then
                            lstr_CadenaSent = "CHECKIN"
                        Else
                            lstr_Contenedor = "CHECKOUT"
                        End If

                        ' lservweb.
                        'SentNotificationsForContainer(Visita, llng_Universal, lstr_Contenedor, lstr_CadenaSent, of_ConvertDateToStringGeneralFormat(Date.Now))

                        'si es rec es checkin
                        If cadena.IndexOf("REC") > -1 Then
                            SentNotificationsForCheckIn(Visita, lstr_Driverlicense, UserName)
                        End If

                        'si es ent, es checkout
                        If cadena.IndexOf("ENT") > -1 Then
                            SentNotificationsForCheckOut(Visita, lstr_Driverlicense, UserName)
                        End If

                    Next ' recorrido de listado 

                End If ' si hay elemen tos por avisar
                
            End If ' si hay notificaciones

        Catch ex As Exception

        End Try
        



        '//
        '//
        '///
        '///
        '///
        '///
        '///
        '///
        '///
        '///
        '///
        '///
        '///
        '///
        '//
        '///
        '///

        'Dim ldtb_Result As DataTable = New DataTable()
        'Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter()
        'Dim iolecmd_comand As OleDbCommand = New OleDbCommand()
        'Dim ioleconx_conexion As OleDbConnection = New OleDbConnection()

        'Dim istr_conx As String = ""  ' cadena de conexion
        'Dim strSQL As String = ""
        'Dim lstr_data As String = ""
        'Dim lstr_month As String = ""
        'Dim lstr_day As String = ""
        'Dim lstr_minute As String = ""
        'Dim lstr_hour As String = ""
        'Dim lstr_second As String = ""
        'Dim lstr_result As String = ""
        'Dim lstr_datecov As String = ""
        'Dim x As Integer = 0

        ''''''''


        'istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        'ioleconx_conexion.ConnectionString = istr_conx
        'iolecmd_comand = ioleconx_conexion.CreateCommand()

        'ldtb_Result = New DataTable("User")
        'strSQL = "spInOutVisit"
        ' ''execute dbo.spInOutVisit  @intVisitId=2111283, @dtmReceptionDate="20220325 16:38", @strService="REC", @strUser="jcadena"
        ''strSQL = " execute spInOutVisit  @intVisitId=?, @dtmReceptionDate=?, @strService=?, @strUser=? "
        'strSQL = " execute spInOutVisit ?, ?, ?, ? "


        'iolecmd_comand.Parameters.Add("intVisit", OleDbType.Numeric)
        'iolecmd_comand.Parameters.Add("date", OleDbType.VarChar)
        'iolecmd_comand.Parameters.Add("strservice", OleDbType.VarChar)
        'iolecmd_comand.Parameters.Add("strUser", OleDbType.VarChar)

        'iolecmd_comand.Parameters("intVisit").Value = Visita
        ''    ///iolecmd_comand.Parameters["date"].Value = "GETDATE()";
        ''    /// fecha 
        ''    ///  mes

        'lstr_day = System.DateTime.Now.Day.ToString()
        'If lstr_day.Length < 2 Then
        '    lstr_day = "0" + lstr_day
        'End If


        'lstr_month = System.DateTime.Now.Month.ToString()
        'If lstr_month.Length < 2 Then
        '    lstr_month = "0" + lstr_month
        'End If

        'lstr_hour = System.DateTime.Now.Hour.ToString()
        'If lstr_hour.Length < 2 Then
        '    lstr_hour = "0" + lstr_hour
        'End If


        'lstr_minute = System.DateTime.Now.Minute.ToString()
        'If lstr_minute.Length < 2 Then
        '    lstr_minute = "0" + lstr_minute
        'End If



        'lstr_second = System.DateTime.Now.Second.ToString()
        'If lstr_second.Length < 2 Then
        '    lstr_second = "0" + lstr_second
        'End If

        'iolecmd_comand.Parameters("intVisit").Value = Visita
        'iolecmd_comand.Parameters("date").Value = System.DateTime.Now.Year.ToString() + lstr_month + lstr_day + " " + lstr_hour + ":" + lstr_minute + ":" + lstr_second
        'lstr_datecov = System.DateTime.Now.Year.ToString() + lstr_month + lstr_day + " " + lstr_hour + ":" + lstr_minute + ":" + lstr_second
        'iolecmd_comand.Parameters("strservice").Value = cadena
        'iolecmd_comand.Parameters("strUser").Value = UserName

        'iolecmd_comand.CommandText = strSQL
        ''iolecmd_comand.CommandType = CommandType.StoredProcedure
        'iolecmd_comand.CommandType = CommandType.Text

        'iolecmd_comand.Parameters.Clear()
        'strSQL = "execute  spInOutVisit @intVisitId = " + Visita.ToString() + " , @dtmReceptionDate = '" + lstr_datecov.ToString() + "' ,@strService = '" + cadena.ToString() + "' , @strUser ='" + UserName.ToString() + "'"
        'iolecmd_comand.CommandText = strSQL

        'iolecmd_comand.CommandTimeout = 99999
        '''''
        'Try

        '    iAdapt_comand.SelectCommand = iolecmd_comand
        '    iAdapt_comand.Fill(ldtb_Result)


        '    '    // si tiene una columna y un renglon 

        '    If ldtb_Result.Rows.Count = 1 And ldtb_Result.Columns.Count = 1 Then
        '        lstr_result = ldtb_Result.Rows(0)(0).ToString()
        '        If lstr_result.IndexOf("Solicitud") > 0 And lstr_result.IndexOf("Visita") > 0 And lstr_result.IndexOf("EIR") > 0 Then
        '            Return 0
        '        End If

        '    Else
        '        If ldtb_Result.Rows.Count = 1 And ldtb_Result.Columns.Count = 5 Then
        '            If ldtb_Result(0)(4) = "intVisitId" Then
        '                Return 0
        '            End If
        '        Else
        '            Return 0
        '        End If
        '        Return 0
        '    End If
        '    '{
        '    '    lstr_result = ldtb_Result.Rows[0][0].ToString();

        '    '    if (lstr_result.IndexOf("Solicitud") > 0 && lstr_result.IndexOf("Visita") > 0 && lstr_result.IndexOf("EIR") > 0)
        '    '    {
        '    '        // si la columna y renglon  tienen el contendifo -- Solicitud: 567505 en Visita 1604383 EIR
        '    '        // llamar al metodo de cm 
        '    '        SW_CMREF.CMSIGNALR lref = new SW_CMREF.CMSIGNALR();

        '    '        lref.GetVisitOrderToBlock(alng_visitId, astr_Username);

        '    '    }
        '    'Else
        '    '        return dt_RetrieveErrorTable("no entro signal=" + lstr_result);

        '    '}

        'Catch ex As Exception
        '    Dim strError As String

        '    strError = ex.Message

        '    '// return dt_RetrieveErrorTable(strError);
        '    Return -10
        'Finally
        '    ioleconx_conexion.Close()
        'End Try

        '//
        '//
        '//
        '//
        '//
        '//
        '//
        '//
        '//
        '//
        '//
        '//
        '//
        '//
        '//
        '//
        '//
        '//


        'Dim param As New OleDbParameter
        'param.ParameterName = ParameterDirection.ReturnValue
        'Dim x As Integer = 666
        'Dim oleDBconnx As OleDbConnection
        'Dim oleDBcom As OleDbCommand
        'oleDBcom = New OleDbCommand()
        'oleDBconnx = New OleDbConnection()
        'Dim strconx As String
        'strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        'oleDBconnx.ConnectionString = strconx
        'oleDBcom = oleDBconnx.CreateCommand
        ''----------------------------------
        'Dim oleDb_param As OleDbParameter = New OleDbParameter()
        'Dim ls_sql As String

        'Dim lodb_intVisitId As OleDbParameter = New OleDbParameter()
        'Dim lodb_dtmReceptionDate As OleDbParameter = New OleDbParameter()
        'Dim lodb_strService As OleDbParameter = New OleDbParameter()
        'Dim lodb_strUser As OleDbParameter = New OleDbParameter()

        'Dim comments As String = ""

        'lodb_intVisitId.ParameterName = "@intVisitId"
        'lodb_intVisitId.OleDbType = OleDbType.Integer
        'lodb_intVisitId.Value = Integer.Parse(Visita)

        'lodb_dtmReceptionDate.ParameterName = "@dtmReceptionDate"
        'lodb_dtmReceptionDate.OleDbType = OleDbType.Char
        'lodb_dtmReceptionDate.Value = Format(Date.Now, "yyyyMMdd HH:mm:ss")

        'lodb_strService.ParameterName = "@strService"
        'lodb_strService.OleDbType = OleDbType.Char
        'lodb_strService.Value = cadena


        'lodb_strUser.ParameterName = "@strUser"
        'lodb_strUser.OleDbType = OleDbType.Char
        'lodb_strUser.Value = UserName

        'ls_sql = "spInOutVisit"

        'oleDBcom.CommandText = ls_sql

        'param = oleDBcom.Parameters.Add("returnvalue", OleDbType.Integer)
        'param.Direction = ParameterDirection.ReturnValue

        'oleDBcom.CommandType = CommandType.StoredProcedure
        'oleDBcom.Parameters.Add(lodb_intVisitId) '(intcontaineruniversalid) 'Id universal del contenedor)
        'oleDBcom.Parameters.Add(lodb_dtmReceptionDate)
        'oleDBcom.Parameters.Add(lodb_strService)
        'oleDBcom.Parameters.Add(lodb_strUser)

        'oleDBcom.CommandTimeout = 0
        'Try
        '    oleDBconnx.Open()
        '    x = param.Value
        '    oleDBcom.ExecuteNonQuery()
        'Catch ex As Exception
        '    ' Return 0
        'Finally
        '    oleDBconnx.Close()
        '    oleDBcom.Connection.Close()
        '    oleDBcom.Connection.Dispose()
        '    oleDBconnx.Dispose()
        'End Try
        '' _Error = oleDb_paramOut_ErrorCode.Value
        oleDBcom = Nothing
        oleDBconnx = Nothing
        Return x
    End Function


    '<WebMethod()> _
    'Public Function SentNotificationsCheckin()
    '    Try
    '        Dim lint_notifications As Integer

    '        lint_notifications = CType(ConfigurationManager.AppSettings.Item("SendNotifications").ToString, Integer)

    '        'si esta habilitado enviar notificaciones
    '        If lint_notifications > 0 Then

    '            Dim lservweb As Pushservice.WS = New Pushservice.WS()

    '            lservweb.CheckInOrden()
    '            lservweb.CheckOutOrden()
    '            lservweb.NotificacionOperacionContenedor()
    '            x?op=NotificacionOperacionContenedor

    '        End If ' si hay notificaciones

    '    Catch ex As Exception

    '    End Try


    'End Function




    <WebMethod()> _
    Public Function SentNotificationsForContainer(ByVal alng_visit As Long, ByVal alng_UniversalId As Long, ByVal astr_containerId As String, ByVal astr_operaction As String, ByVal astr_fecha As String) As String
        Try
            Dim lint_notifications As Integer

            lint_notifications = CType(ConfigurationManager.AppSettings.Item("SendNotifications").ToString, Integer)

            'si esta habilitado enviar notificaciones
            If lint_notifications > 0 Then

                If astr_fecha.Length > 4 Then
                    astr_fecha = astr_fecha
                Else
                    astr_fecha = Format(Date.Now, "yyyy-MM-dd HH:mm:ss ")
                End If

                Dim lservweb As Pushservice.WS = New Pushservice.WS()
                Dim lstr_result As String
                lstr_result = lservweb.NotificacionOperacionContenedor(alng_visit, alng_UniversalId, astr_containerId, astr_operaction, astr_fecha)


            End If ' si hay notificaciones

        Catch ex As Exception

        End Try

        Return ""

    End Function

    <WebMethod()> _
   Public Function SentNotificationsForEIRCreated(ByVal alng_visit As Long, ByVal alng_UniversalId As Long, ByVal astr_containerId As String, ByVal aint_EIR As Integer, ByVal astr_Username As String) As String
        Try
            Dim lint_notifications As Integer

            lint_notifications = CType(ConfigurationManager.AppSettings.Item("SendNotifications").ToString, Integer)

            'si esta habilitado enviar notificaciones
            If lint_notifications > 0 Then

                Dim lservweb As Pushservice.WS = New Pushservice.WS()
                Dim lstr_result As String

                lstr_result = lservweb.subirEIR(alng_visit, alng_UniversalId, astr_containerId, aint_EIR, astr_Username)


            End If ' si hay notificaciones

        Catch ex As Exception

        End Try

        Return ""

    End Function

    <WebMethod()> _
 Public Function SentNotificationsForCheckIn(ByVal alng_visit As Long, ByVal astr_DriverLicense As String, ByVal astr_Username As String) As String
        Try
            Dim lint_notifications As Integer

            lint_notifications = CType(ConfigurationManager.AppSettings.Item("SendNotifications").ToString, Integer)

            'si esta habilitado enviar notificaciones
            If lint_notifications > 0 Then

                Dim lservweb As Pushservice.WS = New Pushservice.WS()
                Dim lstr_result As String

                lstr_result = lservweb.CheckInOrden(astr_Username, alng_visit, astr_DriverLicense)

            End If ' si hay notificaciones

        Catch ex As Exception

        End Try

        Return ""

    End Function

    <WebMethod()> _
 Public Function SentNotificationsForCheckOut(ByVal alng_visit As Long, ByVal astr_DriverLicense As String, ByVal astr_Username As String) As String
        Try
            Dim lint_notifications As Integer

            lint_notifications = CType(ConfigurationManager.AppSettings.Item("SendNotifications").ToString, Integer)

            'si esta habilitado enviar notificaciones
            If lint_notifications > 0 Then

                Dim lservweb As Pushservice.WS = New Pushservice.WS()
                Dim lstr_result As String

                lstr_result = lservweb.CheckOutOrden(astr_Username, alng_visit, astr_DriverLicense)

            End If ' si hay notificaciones

        Catch ex As Exception

        End Try

        Return ""

    End Function

    Public Function of_ConvertDateToStringGeneralFormat(ByVal adtm_param As Date) As String

        '''''''''''''''

        Dim lstr_appointmentDate As String
        Dim lstr_tempA As String

        ''''''''''''''''''''
        ' revisar la fecha de la cita 
        Try
            '' obtener el año
            lstr_tempA = adtm_param.Year.ToString()

            If lstr_tempA.Length > 1 Then
                lstr_appointmentDate = lstr_tempA
            Else
                lstr_appointmentDate = ""
            End If 'If lstr_tempA.Length > 1 Then

            'validar cadena de fecha 
            If lstr_appointmentDate.Length > 1 Then
                'obtener mes 
                lstr_tempA = adtm_param.Month.ToString()

                'agregar 0, si es de un digito
                If lstr_tempA.Length = 1 Then
                    lstr_tempA = "0" + lstr_tempA
                End If

                'validacion 
                If lstr_tempA.Length < 2 Then
                    lstr_tempA = ""
                    lstr_appointmentDate = ""
                Else
                    lstr_appointmentDate = lstr_appointmentDate + lstr_tempA
                    'lstr_appointmentDate = ""
                End If

                If adtm_param.Year = 1 Then
                    lstr_appointmentDate = ""
                End If

                If adtm_param.Year < 1910 Then
                    lstr_appointmentDate = ""
                End If
            End If 'If lstr_appointmentDate.Length > 1 Then

            If lstr_appointmentDate.Length > 1 Then
                'obtener el dia 
                lstr_tempA = adtm_param.Day.ToString()

                'agregar 0, si es de un digito
                If lstr_tempA.Length = 1 Then
                    lstr_tempA = "0" + lstr_tempA
                End If

                'validacion
                If lstr_tempA.Length < 2 Then
                    lstr_tempA = ""
                    lstr_appointmentDate = ""
                Else
                    lstr_appointmentDate = lstr_appointmentDate + lstr_tempA
                    'lstr_appointmentDate = ""
                End If ' lstr_tempA.lenght

            End If 'If lstr_appointmentDate.Length > 1 Then

            'hora
            ''''''
            If lstr_appointmentDate.Length > 1 Then
                'obtener el hora
                lstr_tempA = adtm_param.Hour.ToString()

                'agregar 0, si es de un digito
                If lstr_tempA.Length = 1 Then
                    lstr_tempA = "0" + lstr_tempA
                End If

                'validacion
                If lstr_tempA.Length < 2 Then
                    lstr_tempA = ""
                    lstr_appointmentDate = ""
                Else
                    lstr_appointmentDate = lstr_appointmentDate + " " + lstr_tempA
                    'lstr_appointmentDate = ""
                End If ' lstr_tempA.lenght

            End If 'If lstr_appointmentDate.Length > 1 Then


            ''minutos
            ''''''''''
            If lstr_appointmentDate.Length > 1 Then
                'obtener el minutos
                lstr_tempA = adtm_param.Minute.ToString()

                'agregar 0, si es de un digito
                If lstr_tempA.Length = 1 Then
                    lstr_tempA = "0" + lstr_tempA
                End If

                'validacion
                If lstr_tempA.Length < 2 Then
                    lstr_tempA = ""
                    lstr_appointmentDate = ""
                Else
                    lstr_appointmentDate = lstr_appointmentDate + ":" + lstr_tempA
                    'lstr_appointmentDate = ""
                End If ' lstr_tempA.lenght

            End If 'If lstr_appointmentDate.Length > 1 Then


            ''segundos
            ''''''''''
            If lstr_appointmentDate.Length > 1 Then
                'obtener el segundos
                lstr_tempA = adtm_param.Second.ToString()

                'agregar 0, si es de un digito
                If lstr_tempA.Length = 1 Then
                    lstr_tempA = "0" + lstr_tempA
                End If

                'validacion
                If lstr_tempA.Length < 2 Then
                    lstr_tempA = ""
                    lstr_appointmentDate = ""
                Else
                    lstr_appointmentDate = lstr_appointmentDate + ":" + lstr_tempA
                    'lstr_appointmentDate = ""
                End If ' lstr_tempA.lenght

            End If 'If lstr_appointmentDate.Length > 1 Then

        Catch ex As Exception
            lstr_appointmentDate = ""
        End Try

        Return lstr_appointmentDate

        Return ""

    End Function

    <WebMethod()> _
    Public Function ConsultarVisita_EIR(ByVal lvisit As Integer) As Data.DataTable
        Dim idt_result As DataTable = New DataTable ' Tabla con el query de resultados 
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        'Dim strcontainerid As String = "IPXU3283286"
        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()
        idt_result.TableName = "TrearDatos"
        Dim strSQL As String
        'Dim strcontainerid As String

        Try
            strSQL = "SELECT intVisitId,   " & _
                "strVisitDriver,   " & _
                "strVisitPlate, " & _
                "strCarrierLineName, " & _
                "dtmVisitDatetimeIn, " & _
                "dtmVisitDatetimeOut " & _
                "FROM tblclsVisit, tblclsCarrierLine  " & _
                "WHERE ( tblclsVisit.intCarrierLineId = tblclsCarrierLine.intCarrierLineId ) and " & _
                "( tblclsVisit.intVisitId = " & Convert.ToString(lvisit) & ") "
            iolecmd_comand.CommandText = strSQL

            iAdapt_comand.SelectCommand = iolecmd_comand
            iAdapt_comand.Fill(idt_result)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
        Finally
            ioleconx_conexion.Close()
            iAdapt_comand.SelectCommand.Connection.Close()
            iAdapt_comand.SelectCommand.Connection.Dispose()
            ioleconx_conexion.Dispose()
        End Try
        ioleconx_conexion = Nothing
        iAdapt_comand = Nothing

        Return idt_result
    End Function

    <WebMethod()> _
    Public Function spGetVisitItemsToProcess(ByVal lvisit As Integer, ByVal lstr_Serv As String) As Data.DataTable
        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand

        '----------------------------------

        Dim lodb_VisitId As OleDbParameter = New OleDbParameter()
        Dim lodb_Serv As OleDbParameter = New OleDbParameter()
        Dim ls_SQL_Command As String
        'redefinicion de parametros


        lodb_VisitId.OleDbType = OleDbType.Integer
        lodb_VisitId.ParameterName = "@intVisitId"
        lodb_VisitId.Value = Integer.Parse(lvisit) '693647 'Integer.Parse(Visita)

        lodb_Serv.OleDbType = OleDbType.Char
        lodb_Serv.ParameterName = "@strService"
        lodb_Serv.Value = lstr_Serv

        ' asignacion de valores

        ls_SQL_Command = "spGetVisitItemsToProcess"

        ' asociacion de parametros al comando

        oleDBcom.Parameters.Add(lodb_VisitId)
        oleDBcom.Parameters.Add(lodb_Serv)

        oleDBcom.CommandText = ls_SQL_Command
        oleDBcom.CommandType = CommandType.StoredProcedure

        Dim DataResult As DataTable = New Data.DataTable() 'DataSet = New DataSet()
        DataResult.TableName = "TrearDatos"
        Dim adapter As OleDbDataAdapter = New OleDbDataAdapter(oleDBcom)

        Try
            oleDBconnx.Open()
            adapter.Fill(DataResult)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
        Finally
            oleDBconnx.Close()
            adapter.SelectCommand.Connection.Close()
            adapter.SelectCommand.Connection.Dispose()
            oleDBconnx.Dispose()
        End Try

        adapter = Nothing
        oleDBconnx = Nothing

        Return DataResult
    End Function
    '*query para traerse la visita*'
    <WebMethod()> _
    Public Function Search_by_VISIT(ByVal lint_visit As Integer) As Data.DataTable 'Descarga de contenedor
        Dim idt_result As DataTable = New DataTable ' Tabla con el query de resultados 
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        'Dim lint_visit = 721362
        'Dim strcontainerid As String = "IPXU3283286"
        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()
        idt_result.TableName = "TrearDatos"
        Dim strSQL As String
        'Dim strcontainerid As String

        Try
            strSQL = "select V.intVisitId, " & _
                                            "V.dtmVisitDatetimeIn, " & _
                                            "V.dtmVisitDatetimeOut, " & _
                                            "V.strVisitPlate, " & _
                                            "strCarrierLineIdentifier + " & """ :: """ & " +strCarrierLineName AS carrierdata " & _
                                            "from tblclsVisit V ,tblclsServiceOrderStatus SOS, tblclsCarrierLine " & _
                                            "where(V.intSOStatusId = SOS.intSOStatusId) " & _
                                            " and ( V.intCarrierLineId = tblclsCarrierLine.intCarrierLineId )  " & _
                                            "and SOS.strSOStatusIdentifier NOT IN ('TER','CAN') " & _
                                            "AND V.dtmVisitDatetimeIn IS NOT NULL AND V.dtmVisitDatetimeOut IS  NULL " & _
                                            "and V.intVisitId=" & Convert.ToString(lint_visit)
            iolecmd_comand.CommandText = strSQL

            iAdapt_comand.SelectCommand = iolecmd_comand
            iAdapt_comand.Fill(idt_result)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
        Finally

            ioleconx_conexion.Close()
            iAdapt_comand.SelectCommand.Connection.Close()
            iAdapt_comand.SelectCommand.Connection.Dispose()
            iolecmd_comand.Connection.Close()
            iolecmd_comand.Connection.Dispose()
            ioleconx_conexion.Dispose()
        End Try
        iAdapt_comand = Nothing
        iolecmd_comand = Nothing
        ioleconx_conexion = Nothing

        Return idt_result
    End Function
    '*query para traerse la visita*'
    <WebMethod()> _
    Public Function Search_by_PLATES(ByVal lstr_plate As String) As Data.DataTable 'Descarga de contenedor
        Dim idt_result As DataTable = New DataTable ' Tabla con el query de resultados 
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        'Dim lstr_plate = "GRT 890 393"
        'Dim strcontainerid As String = "IPXU3283286"
        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()
        idt_result.TableName = "TrearDatos"
        Dim strSQL As String
        'Dim strcontainerid As String

        Try
            strSQL = "select V.intVisitId, " & _
                                      "V.dtmVisitDatetimeIn, " & _
                                      "V.dtmVisitDatetimeOut, " & _
                                      "V.strVisitPlate, " & _
                                      "strCarrierLineIdentifier + " & """ :: """ & " +strCarrierLineName AS carrierdata " & _
                                      "from tblclsVisit V ,tblclsServiceOrderStatus SOS , tblclsCarrierLine " & _
                                      "where(V.intSOStatusId = SOS.intSOStatusId) " & _
                                      " and ( V.intCarrierLineId = tblclsCarrierLine.intCarrierLineId )  " & _
                                      "and SOS.strSOStatusIdentifier NOT IN ('TER','CAN') " & _
                                      "AND V.dtmVisitDatetimeIn IS NOT NULL AND V.dtmVisitDatetimeOut IS  NULL " & _
                                      "and V.strVisitPlate= '" & lstr_plate & "'"
            iolecmd_comand.CommandText = strSQL

            iAdapt_comand.SelectCommand = iolecmd_comand
            iAdapt_comand.Fill(idt_result)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
        Finally
            iAdapt_comand.SelectCommand.Connection.Close()
            ioleconx_conexion.Close()
            iolecmd_comand.Connection.Close()

            iAdapt_comand.SelectCommand.Connection.Dispose()
            ioleconx_conexion.Dispose()
            iolecmd_comand.Connection.Dispose()

        End Try

        iAdapt_comand = Nothing
        ioleconx_conexion = Nothing
        iolecmd_comand = Nothing

        Return idt_result
    End Function

    <WebMethod()> _
   Public Function Validate_Yard_POSITION(ByVal astrposition As String) As Integer
        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand
        '----------------------------------
        Dim _Error As Integer
        Dim _Error1 As Integer
        Dim oleDb_param As OleDbParameter = New OleDbParameter()
        Dim ls_sql As String
        'Dim astrposition = "1S30B2"

        Dim lodb_YardPosition As OleDbParameter = New OleDbParameter()
        Dim oleDb_paramOut_ErrorCode As OleDbParameter = New OleDbParameter()
        Dim oleDb_paramError As OleDbParameter = New OleDbParameter()

        Dim comments As String = ""

        lodb_YardPosition.OleDbType = OleDbType.Char
        lodb_YardPosition.ParameterName = "@strYardPosition"
        lodb_YardPosition.Value = astrposition

        oleDb_paramOut_ErrorCode.ParameterName = "@intOccupied"
        oleDb_paramOut_ErrorCode.OleDbType = OleDbType.Integer
        oleDb_paramOut_ErrorCode.Direction = ParameterDirection.Output

        oleDb_paramError.ParameterName = "@intError"
        oleDb_paramError.OleDbType = OleDbType.Integer
        oleDb_paramError.Direction = ParameterDirection.Output

        ls_sql = "spValidateYardPosition"

        oleDBcom.CommandText = ls_sql
        oleDBcom.CommandType = CommandType.StoredProcedure

        oleDBcom.Parameters.Add(lodb_YardPosition)
        oleDBcom.Parameters.Add(oleDb_paramOut_ErrorCode) '(intcontaineruniversalid) 'Id universal del contenedor)
        oleDBcom.Parameters.Add(oleDb_paramError)

        oleDBcom.CommandTimeout = 0
        Try

            oleDBconnx.Open()
            'oleDBcom.ExecuteNonQuery()
            Dim value As OleDbDataReader
            value = oleDBcom.ExecuteReader()
            If value.HasRows Then
                value.Read()
                Dim result = value.GetInt64(0)
            End If


        Catch ex As Exception
            Dim er As String = ex.Message
            er = ex.Message
            ' Return 0
        Finally
            oleDBconnx.Close()
            oleDBcom.Connection.Close()

            oleDBconnx.Dispose()
            oleDBcom.Connection.Dispose()
        End Try

        Try
            _Error1 = oleDb_paramError.Value
        Catch ex As Exception
            _Error = 0
        End Try

        oleDBconnx = Nothing
        oleDBcom = Nothing

        Return _Error1
    End Function

    <WebMethod()> _
      Public Function Validar_Posicion_VISITA(ByVal lint_visit As Integer, ByVal lint_universal As Integer, ByVal lstr_service As String, ByVal lstr_posicion As String, ByVal lstr_bloque As String, ByVal lstr_fila As String, ByVal lstr_bahia As String, ByVal lstr_nivel As String, ByVal lint_sosid As Integer, ByVal lint_servqueu As Integer, ByVal lstr_username As String) As Integer
        '-----------------------------
        'Dim lint_visit = 721362
        'Dim lint_universal = 885556
        'Dim lstr_service = "RECLL"
        'Dim lstr_posicion = "1S30B2"
        'Dim lstr_bloque = "1S"
        'Dim lstr_fila = "30"
        'Dim lstr_bahia = "B"
        'Dim lstr_nivel = "2"
        'Dim lint_sosid = 243535
        'Dim lint_servqueu = 998363
        'Dim lstr_username = "NEAR"

        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand
        '------------------------------
        Dim lstr_ValueChange As String
        lstr_ValueChange = lstr_bahia
        lstr_bahia = lstr_fila
        '-- cambio valor
        lstr_fila = lstr_ValueChange
        '----------------------------------
        Dim oleDb_param As OleDbParameter = New OleDbParameter()
        Dim ls_sql As String

        Dim aintVisit As OleDbParameter = New OleDbParameter()
        Dim aiduniversal As OleDbParameter = New OleDbParameter()
        Dim astrservice As OleDbParameter = New OleDbParameter()
        Dim astrposition As OleDbParameter = New OleDbParameter()
        Dim Block As OleDbParameter = New OleDbParameter()
        Dim Row As OleDbParameter = New OleDbParameter()
        Dim Bay As OleDbParameter = New OleDbParameter()
        Dim Stow As OleDbParameter = New OleDbParameter()

        Dim aintSOrderId As OleDbParameter = New OleDbParameter()
        Dim aintServQueu As OleDbParameter = New OleDbParameter()
        Dim dtmprocessdate As OleDbParameter = New OleDbParameter()
        Dim astruser As OleDbParameter = New OleDbParameter()

        Dim lstr_mesaje As String = ""

        'For Each valor In consultar.Rows
        aintVisit.ParameterName = "@aintVisit"
        aintVisit.OleDbType = OleDbType.Integer
        aintVisit.Value = lint_visit

        aiduniversal.ParameterName = "@aiduniversal"
        aiduniversal.OleDbType = OleDbType.Integer
        aiduniversal.Value = lint_universal 'valor("lstrcontainerinvyardpositionid")

        astrservice.ParameterName = "@astrservice"
        astrservice.OleDbType = OleDbType.Char
        astrservice.Value = lstr_service 'Mid(valor("strContainerInvYardPositionId"), 1, 2) 'bloque

        astrposition.ParameterName = "@astrposition"
        astrposition.OleDbType = OleDbType.Char
        astrposition.Value = lstr_posicion 'Mid(valor("strContainerInvYardPositionId"), 3, 2) 'baia

        Block.ParameterName = "@Block"
        Block.OleDbType = OleDbType.Char
        Block.Value = lstr_bloque 'Mid(valor("strContainerInvYardPositionId"), 5, 1) 'fila

        Row.ParameterName = "@Row"
        Row.OleDbType = OleDbType.Char
        Row.Value = lstr_fila 'Mid(valor("strContainerInvYardPositionId"), 6, 1) 'nivel

        Bay.ParameterName = "@Bay"
        Bay.OleDbType = OleDbType.Char
        Bay.Value = lstr_bahia

        Stow.ParameterName = "@Stow"
        Stow.OleDbType = OleDbType.Char
        Stow.Value = lstr_nivel

        aintSOrderId.ParameterName = "@aintSOrderId"
        aintSOrderId.OleDbType = OleDbType.Integer
        aintSOrderId.Value = lint_sosid

        aintServQueu.ParameterName = "@aintServQueu"
        aintServQueu.OleDbType = OleDbType.Integer
        aintServQueu.Value = lint_servqueu

        dtmprocessdate.ParameterName = "@dtmprocessdate"
        dtmprocessdate.OleDbType = OleDbType.Char
        dtmprocessdate.Value = Format(Date.Now, "yyyyMMdd HH:mm")

        astruser.ParameterName = "@astruser"
        astruser.OleDbType = OleDbType.Char
        astruser.Value = lstr_username

        ls_sql = "spProcessVisitQueue"

        oleDBcom.CommandText = ls_sql
        oleDBcom.CommandType = CommandType.StoredProcedure

        oleDBcom.Parameters.Add(aintVisit)
        oleDBcom.Parameters.Add(aiduniversal)
        oleDBcom.Parameters.Add(astrservice)
        oleDBcom.Parameters.Add(astrposition)
        oleDBcom.Parameters.Add(Block)
        oleDBcom.Parameters.Add(Row)
        oleDBcom.Parameters.Add(Bay)
        oleDBcom.Parameters.Add(Stow)
        oleDBcom.Parameters.Add(aintSOrderId)
        oleDBcom.Parameters.Add(aintServQueu)
        oleDBcom.Parameters.Add(dtmprocessdate)
        oleDBcom.Parameters.Add(astruser)

        Dim DataResult As DataTable = New Data.DataTable() 'DataSet = New DataSet()
        DataResult.TableName = "TrearDatos"
        Dim adapter As OleDbDataAdapter = New OleDbDataAdapter(oleDBcom)


        oleDBcom.CommandTimeout = 0
        Try
            oleDBcom.Connection.Open()
            ' oleDBcom.ExecuteNonQuery()
            adapter.Fill(DataResult)

            '' obtener la varaible notificacion 
            Try
                Dim lint_notifications As Integer
                Dim lstr_CadenaSent As String
                Dim llng_Visit As Long
                Dim llng_Universal As Long
                Dim lstr_Contenedor As String
                Dim lstr_searchService As String
                Dim lstr_notificaciion As String


                lint_notifications = CType(ConfigurationManager.AppSettings.Item("SendNotifications").ToString, Integer)
                lstr_CadenaSent = ""
                'si esta habilitado enviar notificaciones
                If lint_notifications > 0 Then

                    ' ver si hay elementos por procesar
                    Dim ldt_table As DataTable = New DataTable("elements")
                    ''INGRESO
                    If lstr_service.IndexOf("REC") > -1 Then
                        lstr_searchService = "REC"
                        lstr_notificaciion = "DESCARGA"
                    End If


                    ''INGRESO
                    If lstr_service.IndexOf("ENT") > -1 Then
                        lstr_searchService = "ENT"
                        lstr_notificaciion = "CARGA"
                    End If



                    ldt_table = CargarGrid_Visita_Check_in(lint_visit, lstr_searchService)
                    ' si tiene elementos avanza
                    If ldt_table.Rows.Count > 0 Then


                        For Each lrow As DataRow In ldt_table.Rows

                            'Obtenner el numero de contenenedor para enviar 
                            lstr_Contenedor = lrow("Contenedor").ToString()
                            llng_Universal = CType(lrow("xintContainerUniversalId").ToString, Long)

                            ' si el universal leido es el mismo que se envia como parametro ,llamar a la notificacion 
                            If llng_Universal = lint_universal Then
                                ' lservweb.
                                'SentNotificationsForContainer(lint_visit, llng_Universal, lstr_Contenedor, lstr_CadenaSent, of_ConvertDateToStringGeneralFormat(Date.Now))
                                SentNotificationsForContainer(lint_visit, llng_Universal, lstr_Contenedor, lstr_notificaciion, "")

                            End If


                        Next ' recorrido de listado 

                    End If ' si hay elemen tos por avisar

                End If ' si hay notificaciones

            Catch ex As Exception

            End Try ' de notificaciones
            
        Catch ex As Exception
            Dim lstr_error As String
            lstr_error = ex.Message
            lstr_error = lstr_error



            Return -1
        Finally
            oleDBcom.Connection.Close()
            adapter.SelectCommand.Connection.Close()
            oleDBconnx.Close()
            oleDBcom.Parameters.Clear()

            oleDBcom.Connection.Dispose()
            oleDBconnx.Dispose()

        End Try
        Return 0
    End Function

    <WebMethod()> _
    Public Function ModuloOpciones_de_Usuario(ByVal intusername As Integer) As Data.DataTable
        'Dim intusername As Integer = 460
        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand

        '----------------------------------

        Dim lodb_intusername As OleDbParameter = New OleDbParameter()
        Dim lodb_aint_moduleid As OleDbParameter = New OleDbParameter()
        Dim ls_SQL_Command As String
        'redefinicion de parametros


        lodb_intusername.OleDbType = OleDbType.Numeric
        lodb_intusername.ParameterName = "@aint_userid"
        lodb_intusername.Value = Integer.Parse(intusername) '693647 'Integer.Parse(Visita)

        lodb_aint_moduleid.OleDbType = OleDbType.Numeric
        lodb_aint_moduleid.ParameterName = "aint_moduleid"
        lodb_aint_moduleid.Value = 7

        ' asignacion de valores

        ls_SQL_Command = "spGetUserModuleOptions"

        ' asociacion de parametros al comando

        oleDBcom.Parameters.Add(lodb_intusername)
        oleDBcom.Parameters.Add(lodb_aint_moduleid)

        oleDBcom.CommandText = ls_SQL_Command
        oleDBcom.CommandType = CommandType.StoredProcedure

        Dim DataResult As DataTable = New Data.DataTable() 'DataSet = New DataSet()
        DataResult.TableName = "TrearDatos"
        Dim adapter As OleDbDataAdapter = New OleDbDataAdapter(oleDBcom)

        Try
            oleDBconnx.Open()
            adapter.Fill(DataResult)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
        Finally
            adapter.SelectCommand.Connection.Close()
            oleDBconnx.Close()

            adapter.SelectCommand.Connection.Dispose()
            oleDBconnx.Dispose()

        End Try

        adapter = Nothing
        oleDBconnx = Nothing

        Return DataResult
    End Function

    '  /////////////////////////////////////////////////////////////////'
    '  /////////////////////////////////////////////////////////////////'
    '  /////////////////////////////////////////////////////////////////'
    '  /////////////////////////////////////////////////////////////////'
    '  /////////////////////////////////////////////////////////////////'
    '  /////////////////////////////////////////////////////////////////'
    '  /////////////////////////////////////////////////////////////////'
    '  /////////////////////////////////////////////////////////////////'
    '  /////////////////////////////////////////////////////////////////
    ''  /////////////////////////////////////////////////////////////////
    '  /////////////////////////////////////////////////////////////////'
    '  /////////////////////////////////////////////////////////////////'
    'inician funciones codigo metodo de Javier  15-04-13
    '  /////////////////////////////////////////////////////////////////'
    '  /////////////////////////////////////////////////////////////////'
    '  /////////////////////////////////////////////////////////////////'

    <WebMethod()> _
  Public Function ConsultarVisita_EIRX(ByVal lvisit As Integer) As Data.DataTable

        Dim idt_result As DataTable = New DataTable ' Tabla con el query de resultados 
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        'Dim strcontainerid As String = "IPXU3283286"
        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()
        idt_result.TableName = "TrearDatos"

        Dim strSQL As String
        'Dim strcontainerid As String

        Try
            strSQL = "SELECT intVisitId,   " & _
                "strVisitDriver,   " & _
                "strVisitPlate, " & _
                "strCarrierLineName, " & _
                "dtmVisitDatetimeIn, " & _
                "dtmVisitDatetimeOut, " & _
                "ISNULL(dtmVisitDatetimeIn,'19000101 00:00') AS 'TIMEIN', " & _
                " ( SELECT MAX( tblclsService.strServiceIdentifier) " & _
                "   FROM tblclsVisitContainer " & _
                "   INNER JOIN tblclsService ON tblclsService.intServiceId = tblclsVisitContainer.intServiceId " & _
                "  WHERE tblclsVisitContainer.intVisitId =  tblclsVisit.intVisitId " & _
                "  ) AS SERVICE " & _
                "FROM tblclsVisit, tblclsCarrierLine  " & _
                "WHERE ( tblclsVisit.intCarrierLineId = tblclsCarrierLine.intCarrierLineId ) and " & _
                "( tblclsVisit.intVisitId = " & Convert.ToString(lvisit) & ") "
            iolecmd_comand.CommandText = strSQL

            iAdapt_comand.SelectCommand = iolecmd_comand
            iAdapt_comand.Fill(idt_result)

            '' revisar si es entregrea, que tenga fecha de ingreso
            Try
                Dim lstr_serv As String
                Dim lstr_dtm As String

                lstr_serv = idt_result(0)("SERVICE").ToString()
                lstr_dtm = idt_result(0)("TIMEIN").ToString()

                lstr_serv = lstr_serv.ToUpper()

                If lstr_serv.IndexOf("ENT") >= 0 Then
                    If lstr_dtm.IndexOf("19000101 00:00") >= 0 Or lstr_dtm.IndexOf("1900-01-01") >= 0 Or lstr_dtm.IndexOf("01/01/1900") >= 0 Then
                        Return dt_RetrieveErrorTable("La visita de entrega no tiene CheckIn")
                    End If
                End If

            Catch ex As Exception

            End Try
            '''
        Catch ex As Exception

            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            '' si obtuvo error
            If Len(strError) < 1 Then
                strError = ex.Message
            End If
            ''retornar el error encapsulado en tabla
            Return dt_RetrieveErrorTable(strError)
        Finally
            iAdapt_comand.SelectCommand.Connection.Close()
            ioleconx_conexion.Close()

            iAdapt_comand.SelectCommand.Connection.Dispose()
            ioleconx_conexion.Dispose()

        End Try

        iolecmd_comand = Nothing
        iAdapt_comand = Nothing

        Return idt_result
    End Function


    <WebMethod()> _
   Public Function WMdt_GetEIRItemToProcess(ByVal aint_visit As Integer) As Data.DataTable

        Dim oleDBconnx As OleDbConnection
        Dim adapter As OleDbDataAdapter
        Dim oleDBcom As OleDbCommand
        Dim oleDBComFCont As OleDbCommand
        Dim oleDBIMOCont As OleDbCommand
        Dim oleDBTemptureCdm As OleDbCommand
        Dim oleDBSOReceptionCmd As OleDbCommand

        Dim oledDBConxService As OleDbConnection
        Dim oledDBComService As OleDbCommand

        oleDBcom = New OleDbCommand()
        oleDBComFCont = New OleDbCommand()
        oleDBIMOCont = New OleDbCommand()
        oleDBTemptureCdm = New OleDbCommand()
        oleDBSOReceptionCmd = New OleDbCommand()

        oleDBconnx = New OleDbConnection()

        oledDBConxService = New OleDbConnection()
        oledDBComService = New OleDbCommand()

        Dim strconx As String

        '' tablas de consulta
        Dim ldt_RECepcion As DataTable = New DataTable("Recepcion")
        Dim ldt_ENTrega As DataTable = New DataTable("ENTrega")
        Dim ldt_VisitaInfo As DataTable = New DataTable("VisitInfo")

        '' tabla de retorno 
        Dim ldt_EIRItems As DataTable = New DataTable("EIRItems")
        Dim lint_UnivId As Integer = -1
        Dim lint_Active As Integer = -1
        Dim lstr_queryIMO As String = ""
        Dim lstr_queryTmpTure As String = ""
        Dim lstr_queryTmpEIR As String = ""
        Dim lstr_querySOReception As String = ""
        Dim lstr_error As String = ""

        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand
        oleDBComFCont = oleDBconnx.CreateCommand
        oleDBIMOCont = oleDBconnx.CreateCommand
        oleDBTemptureCdm = oleDBconnx.CreateCommand
        oleDBSOReceptionCmd = oleDBconnx.CreateCommand

        oledDBConxService.ConnectionString = strconx
        oledDBComService = oleDBconnx.CreateCommand

        '----------------------------------

        Dim lodb_VisitId As OleDbParameter = New OleDbParameter()
        Dim lodb_Serv As OleDbParameter = New OleDbParameter()
        Dim ls_SQL_Command As String
        Dim lrw_newrow As DataRow
        Dim lrw_Newextra As DataRow
        Dim lstr_servicev As String
        Dim lstr_temp As String

        Dim ldt_UnivYActive As DataTable = New DataTable()
        Dim ldt_IMORecption As DataTable = New DataTable()
        Dim ldt_Temperature As DataTable = New DataTable()
        Dim ldt_SOReception As DataTable = New DataTable()
        Dim ldt_ServiceVisit As DataTable = New DataTable()

        'Dim ldt_SetUnivYActive As DataTable = New DataTable()
        Dim lint_idx As Integer = -1

        '' creacion de columnas de la tabla de retorno
        ldt_EIRItems.Columns.Add("Contenedor", GetType(String))
        ldt_EIRItems.Columns.Add("Tam", GetType(String))
        ldt_EIRItems.Columns.Add("Tipo", GetType(String))
        ldt_EIRItems.Columns.Add("Linea", GetType(String))
        ldt_EIRItems.Columns.Add("Valido", GetType(Integer))
        ldt_EIRItems.Columns.Add("Fiscal", GetType(Integer))
        ldt_EIRItems.Columns.Add("EIR", GetType(Integer))
        ldt_EIRItems.Columns.Add("intEIRId", GetType(Integer))
        ldt_EIRItems.Columns.Add("Seals", GetType(String))
        ldt_EIRItems.Columns.Add("Servicio", GetType(String))


        ldt_EIRItems.Columns.Add("intContainerUniversalId", GetType(Integer))
        ldt_EIRItems.Columns.Add("intActiveContainer", GetType(Integer))

        ldt_EIRItems.Columns.Add("intIMOCodeId", GetType(Integer))
        ldt_EIRItems.Columns.Add("strIMOCodeIdentifier", GetType(String))
        ldt_EIRItems.Columns.Add("intServiceOrderId", GetType(Integer))
        ldt_EIRItems.Columns.Add("intIdx", GetType(Integer))

        '' columnas para la temperatura 
        ldt_EIRItems.Columns.Add("strContISOCodeAlias", GetType(String))
        ldt_EIRItems.Columns.Add("intContRecDetailTempMeasu", GetType(Integer))
        ldt_EIRItems.Columns.Add("strMeasureUnitIdentifier", GetType(String))
        ldt_EIRItems.Columns.Add("strMeasureUnitDescription", GetType(String))
        ldt_EIRItems.Columns.Add("decContRecDetailTemperature", GetType(Double))

        '' tipo de servicio 
        ldt_EIRItems.Columns.Add("strServiceIdentifier", GetType(String))
        '' fin creacion de columnas de la tabla de retorno


        '' 2019-AGOSTO-15
        '' consulta la base de datos agregada para saber cual es el servicio
        ''hacer un query 
        ls_SQL_Command = " SELECT MAX(tblclsService.strServiceIdentifier) " & _
                         "   FROM tblclsVisitContainer  " & _
                         "  INNER JOIN tblclsService ON tblclsService.intServiceId = tblclsVisitContainer.intServiceId " & _
                         " WHERE tblclsVisitContainer.intVisitId = ? "

        ''crearle parametros

        oledDBConxService = New OleDbConnection()
        oledDBConxService.ConnectionString = strconx
        oledDBComService = oledDBConxService.CreateCommand


        oledDBComService.Parameters.Clear()
        oledDBComService.Parameters.Add("@intVisitId", OleDbType.Integer)
        oledDBComService.Parameters("@intVisitId").Value = aint_visit

        ''ejecutar el comando para llenar una tabla
        oledDBComService.CommandText = ls_SQL_Command

        ldt_ServiceVisit = New DataTable()

        'oleDBconnx = New OleDbConnection()
        'oleDBconnx.ConnectionString = strconx
        adapter = New OleDbDataAdapter()

        adapter.SelectCommand = oledDBComService

        lstr_error = ""

        Try
            oledDBConxService.Open()
            adapter.Fill(ldt_ServiceVisit)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            '' si obtuvo error
            If Len(strError) < 1 Then
                strError = ex.Message
            End If
            ''retornar el error encapsulado en tabla
            'Return dt_RetrieveErrorTable(strError)
            lstr_error = strError

        Finally
            adapter.SelectCommand.Connection.Close()
            oledDBConxService.Close()

            adapter.SelectCommand.Connection.Dispose()
            oledDBConxService.Dispose()
            adapter = Nothing
            oledDBConxService = Nothing


        End Try

        lstr_servicev = ""
        lstr_temp = ""
        'si no hay error 
        If lstr_error.Length = 0 Then
            'si hay una columa y un renglon 
            If (ldt_ServiceVisit.Rows.Count = 1 And ldt_ServiceVisit.Columns.Count = 1) Then
                lstr_temp = ldt_ServiceVisit.Rows(0)(0).ToString()
                If lstr_temp.Length > 2 Then
                    lstr_servicev = lstr_temp
                End If
            End If 'If (ldt_VisitaInfo.Rows.Count = 1 And ldt_VisitaInfo.Columns.Count = 1) Then

        End If ' si no hay error


        ''<<<<<<<< 15-AGOSTO-2019
        '''''''''''''''''
        'oleDBconnx = New OleDbConnection()

        'redefinicion de parametros
        lodb_VisitId.OleDbType = OleDbType.Integer
        lodb_VisitId.ParameterName = "@intVisitId"
        lodb_VisitId.Value = Integer.Parse(aint_visit) '693647 'Integer.Parse(Visita)

        lodb_Serv.OleDbType = OleDbType.Char
        lodb_Serv.ParameterName = "@strService"

        ' asignacion de valores
        ls_SQL_Command = "spGetVisitItemsToProcess"

        ' asociacion de parametros al comando  
        oleDBcom.Parameters.Add(lodb_VisitId)
        oleDBcom.Parameters.Add(lodb_Serv)

        oleDBcom.CommandText = ls_SQL_Command
        oleDBcom.CommandType = CommandType.StoredProcedure

        '' para saber que servicio trae, se va a consultar la visita si tiene chech-in o chec-out
        '''' obtener la tabla de informacion de la visita
        ldt_VisitaInfo = dt_GetVisitInfo(aint_visit)
        ''''' validar que la tabla de informacion de la visita, si tiene una sola columma es un mensaje de error
        If ldt_VisitaInfo.Rows.Count < 1 Then
            Return dt_RetrieveErrorTable("Error al verificar la visita " + aint_visit.ToString())
        End If
        If ldt_VisitaInfo.Columns.Count < 2 Then
            Return dt_RetrieveErrorTable("Error al verificar la visita " + aint_visit.ToString())
        End If

        '' si la visita tiene check-in, es EIR de salida


        '' si no es EIR de entrada
        'If DBNull.Value.Equals(ldt_VisitaInfo(0)("dtmVisitDatetimeIn")) = False Then
        '    lodb_Serv.Value = "ENT"
        'Else
        '    lodb_Serv.Value = "REC"
        'End If

        lodb_Serv.Value = lstr_servicev

        'Dim adapter As OleDbDataAdapter = New OleDbDataAdapter(oleDBcom)
        adapter = New OleDbDataAdapter(oleDBcom)

        Try
            oleDBconnx.Open()
            adapter.Fill(ldt_RECepcion)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            '' si obtuvo error
            If Len(strError) < 1 Then
                strError = ex.Message
            End If
            ''retornar el error encapsulado en tabla
            Return dt_RetrieveErrorTable(strError)

        Finally
            adapter.SelectCommand.Connection.Close()
            oleDBconnx.Close()
            adapter.SelectCommand.Connection.Dispose()
            oleDBconnx.Dispose()

            oleDBconnx = Nothing
            adapter = Nothing


        End Try

        '''''
        ''se le van a agregar 2 columnas mas 

        '' el universal 
        ldt_RECepcion.Columns.Add("intContainerUniversalId", GetType(Integer))

        '''' si esta activo en inventario
        ldt_RECepcion.Columns.Add("intActiveContainer", GetType(Integer))

        '' el tipo de servicio 
        ldt_RECepcion.Columns.Add("strServiceIdentifier", GetType(String))

        '' si trae elementos , 
        If ldt_RECepcion.Rows.Count > 0 Then

            ''hacer un query 
            ls_SQL_Command = " SELECT VISIT.intContainerUniversalId, " & _
                            " VISIT.strContainerId , " & _
                            " ( " & _
                            "    CASE ISNULL(intContainerUniversalId,0) WHEN 0 THEN 0 " & _
                            "     ELSE ( " & _
                            "            SELECT tblclsContainerInventory.blnContainerInvActive " & _
                             "            FROM tblclsContainerInventory  " & _
                             "            WHERE tblclsContainerInventory.strContainerId = VISIT.strContainerId " & _
                             "            AND tblclsContainerInventory.intContainerUniversalId = VISIT.intContainerUniversalId " & _
                            "          ) " & _
                            "     END ) AS 'blnActive' ,  " & _
                            " SERVICE.strServiceIdentifier " & _
                            " FROM tblclsVisitContainer VISIT " & _
                            " INNER JOIN tblclsService SERVICE ON  VISIT.intServiceId =  SERVICE.intServiceId " & _
                            " WHERE  VISIT.intVisitId = ? " & _
                            "  AND VISIT.strContainerId = ? "


            ''crearle parametros
            oleDBconnx = New OleDbConnection()
            oleDBconnx.ConnectionString = strconx
            oleDBComFCont = oleDBconnx.CreateCommand


            oleDBComFCont.Parameters.Clear()
            oleDBComFCont.Parameters.Add("@intVisitId", OleDbType.Integer)
            oleDBComFCont.Parameters.Add("@strContainerId", OleDbType.Char)

            For Each ldRowElement As DataRow In ldt_RECepcion.Rows

                oleDBconnx = New OleDbConnection()
                oleDBconnx.ConnectionString = strconx
                oleDBComFCont = oleDBconnx.CreateCommand

                oleDBComFCont.Parameters.Clear()
                oleDBComFCont.Parameters.Add("@intVisitId", OleDbType.Integer)
                oleDBComFCont.Parameters.Add("@strContainerId", OleDbType.Char)


                ''asignarle a esos parametros los valores de el renglon actual
                oleDBComFCont.Parameters("@intVisitId").Value = aint_visit
                oleDBComFCont.Parameters("@strContainerId").Value = ldRowElement("Contenedor").ToString()

                ''ejecutar el comando para llenar una tabla
                oleDBComFCont.CommandText = ls_SQL_Command

                ldt_UnivYActive = New DataTable()

                'oleDBconnx = New OleDbConnection()
                'oleDBconnx.ConnectionString = strconx
                adapter = New OleDbDataAdapter()

                adapter.SelectCommand = oleDBComFCont

                Try
                    oleDBconnx.Open()
                    adapter.Fill(ldt_UnivYActive)
                Catch ex As Exception
                    Dim strError As String
                    strError = ObtenerError(ex.Message, 99999)
                    '' si obtuvo error
                    If Len(strError) < 1 Then
                        strError = ex.Message
                    End If
                    ''retornar el error encapsulado en tabla
                    Return dt_RetrieveErrorTable(strError)

                Finally
                    adapter.SelectCommand.Connection.Close()
                    oleDBconnx.Close()

                    adapter.SelectCommand.Connection.Dispose()
                    oleDBconnx.Dispose()
                    adapter = Nothing
                    oleDBconnx = Nothing


                End Try

                '' si no hubo error, leer los elementos del a tabla con las 2 columnas
                '''' asignarselo a el renglon actual con la 2 columnas
                If ldt_UnivYActive.Rows.Count > 0 Then

                    ldRowElement("intContainerUniversalId") = ldt_UnivYActive(0)("intContainerUniversalId")
                    ldRowElement("intActiveContainer") = ldt_UnivYActive(0)("blnActive")
                    ldRowElement("strServiceIdentifier") = ldt_UnivYActive(0)("strServiceIdentifier")

                End If
                ''''  
            Next

        End If

        '''--- comentado jcadena 2015-agosto-10
        ''' 
        '' obtencion de IMO

        '' el codigo IMO
        ldt_RECepcion.Columns.Add("intIMOCodeId", GetType(Integer))

        '' el identificador IMO
        ldt_RECepcion.Columns.Add("strIMOCodeIdentifier", GetType(String))

        '' la maniobra de contenedor
        ldt_RECepcion.Columns.Add("intServiceOrderId", GetType(Integer))


        If ldt_RECepcion.Rows.Count > 0 Then

            '''' crear un query para obtener imo
            lstr_queryIMO = "  SELECT tblclsVisitContainer.strContainerId ," & _
                            " tblclsVisitContainer.intServiceOrderId , " & _
                            " ISNULL(tblclsContainerRecepDetail.intIMOCodeId,0) AS intIMOCodeId, " & _
                            " ISNULL(tblclsIMOCode.strIMOCodeIdentifier,'') AS strIMOCodeIdentifier, " & _
                            " ISNULL(tblclsIMOCode.strIMOCodeDescription,'') AS strIMOCodeDescription  " & _
                            " FROM tblclsVisitContainer " & _
                            "     INNER JOIN tblclsContainerRecepDetail ON tblclsVisitContainer.strContainerId = tblclsContainerRecepDetail.strContainerId " & _
                            "      AND tblclsVisitContainer.intServiceOrderId = tblclsContainerRecepDetail.intContainerReceptionId " & _
                            "      AND tblclsVisitContainer.intVisitId = tblclsContainerRecepDetail.intVisitId " & _
                            "     INNER JOIN tblclsIMOCode              ON tblclsIMOCode.intIMOCodeId = tblclsContainerRecepDetail.intIMOCodeId " & _
                            "  WHERE tblclsVisitContainer.intVisitId = ? " & _
                            "   AND tblclsVisitContainer.strContainerId = ? "

            '''' generara parametros
            oleDBIMOCont.Parameters.Add("@intVisitId", OleDbType.Integer)
            oleDBIMOCont.Parameters.Add("@strContainerId", OleDbType.Char)
            oleDBIMOCont.CommandText = lstr_queryIMO

            Dim lstr_ContainerItem As String = ""

            ''hacer un ciclo que se va a recorrer los contenedores
            For lint_idxContImo As Integer = 0 To ldt_RECepcion.Rows.Count - 1
                ''''''' se va a obtener el servicio
                Dim lstr_Service As String = ""


                oleDBconnx = New OleDbConnection()
                adapter = New OleDbDataAdapter()
                oleDBconnx.ConnectionString = strconx
                oleDBIMOCont = oleDBconnx.CreateCommand
                oleDBIMOCont.Parameters.Clear()
                oleDBIMOCont.CommandText = lstr_queryIMO
                oleDBIMOCont.Parameters.Add("@intVisitId", OleDbType.Integer)
                oleDBIMOCont.Parameters.Add("@strContainerId", OleDbType.Char)


                'lstr_Service = ldt_RECepcion(lint_idxContImo)("Servicio").ToString()
                lstr_Service = lodb_Serv.Value

                ''''''''''' si el servicio es recepcion
                If lstr_Service.ToUpper.IndexOf("REC") >= 0 Then

                    'obtener el nombre del contenedor
                    lstr_ContainerItem = ldt_RECepcion(lint_idxContImo)("Contenedor").ToString()

                    '''' actualizar parametros
                    oleDBIMOCont.Parameters("@intVisitId").Value = aint_visit
                    oleDBIMOCont.Parameters("@strContainerId").Value = lstr_ContainerItem

                    ldt_IMORecption = New DataTable()

                    adapter.SelectCommand = oleDBIMOCont
                    ''''' ejecutar comandos
                    Try

                        oleDBconnx.Open()
                        adapter.Fill(ldt_IMORecption)
                    Catch ex As Exception
                        Dim strError As String
                        strError = ObtenerError(ex.Message, 99999)
                        '' si obtuvo error
                        If Len(strError) < 1 Then
                            strError = ex.Message
                        End If
                        ''retornar el error encapsulado en tabla
                        Return dt_RetrieveErrorTable(strError)
                    Finally
                        adapter.SelectCommand.Connection.Close()
                        oleDBconnx.Close()

                        adapter.SelectCommand.Connection.Dispose()
                        oleDBconnx.Dispose()

                    End Try

                    adapter = Nothing
                    oleDBconnx = Nothing


                    '''''''' si trajo elementos
                    If ldt_IMORecption.Rows.Count > 0 Then
                        ''''''''''''''' asignarselo a la columna de la tabla principal
                        ldt_RECepcion(lint_idxContImo)("intIMOCodeId") = ldt_IMORecption(0)("intIMOCodeId")
                        ldt_RECepcion(lint_idxContImo)("strIMOCodeIdentifier") = ldt_IMORecption(0)("strIMOCodeIdentifier")
                        ldt_RECepcion(lint_idxContImo)("intServiceOrderId") = ldt_IMORecption(0)("intServiceOrderId")

                    Else

                        '''''''' si no
                        ''''''''''''' llenar columna de servicio, imo, strimo, con valores vacios
                        ldt_RECepcion(lint_idxContImo)("intIMOCodeId") = 0
                        ldt_RECepcion(lint_idxContImo)("strIMOCodeIdentifier") = ""
                        ldt_RECepcion(lint_idxContImo)("intServiceOrderId") = 0

                        ''''''fin si

                    End If
                    ''''''''fin si llenar 
                    ''''''''''' fin si el servicio es recepcion

                Else
                    ''''''''' sino es recepcion 
                    ''''''''''''''''''hacer que sean campos 0s los de idservicio, idimo, strimo  esten 0s

                    ldt_RECepcion(lint_idxContImo)("intIMOCodeId") = 0
                    ldt_RECepcion(lint_idxContImo)("strIMOCodeIdentifier") = "0"
                    ldt_RECepcion(lint_idxContImo)("intServiceOrderId") = "0"

                End If
                '''''''fin si                

                ''''fin cilo recorrido de contenedores 
            Next

        End If
        '''' fin obtencion IMO

        '' obtener la temperatura de maniobra de ingreso

        '''''''' agregar las columnas a la tabla general ldt_RECepcion
        ldt_RECepcion.Columns.Add("strContISOCodeAlias", GetType(String))
        ldt_RECepcion.Columns.Add("intContRecDetailTempMeasu", GetType(Integer))
        ldt_RECepcion.Columns.Add("strMeasureUnitIdentifier", GetType(String))
        ldt_RECepcion.Columns.Add("strMeasureUnitDescription", GetType(String))
        ldt_RECepcion.Columns.Add("decContRecDetailTemperature", GetType(Double))


        '' si tiene elementos en el renglon de recepcion
        If ldt_RECepcion.Rows.Count > 0 Then

            ''''''   agregar(parametros)
            lstr_queryTmpTure = " SELECT RECP.intContainerReceptionId ," & _
                                "    RECP.strContainerId, " & _
                                "    ISO.strContISOCodeAlias, " & _
                                "    RECP.decContRecDetailTemperature, " & _
                                "    RECP.intContRecDetailTempMeasu, " & _
                                "    MSUNIT.intMeasureUnitId, " & _
                                "    MSUNIT.strMeasureUnitIdentifier, " & _
                                "    MSUNIT.strMeasureUnitDescription " & _
                                " FROM tblclsContainerRecepDetail RECP " & _
                                "  INNER JOIN tblclsContainer  CONT ON RECP.strContainerId = CONT.strContainerId " & _
                                "  INNER JOIN tblclsContainerISOCode ISO ON ISO.intContISOCodeId = CONT.intContISOCodeId  " & _
                                " LEFT JOIN tblclsMeasurementUnit MSUNIT ON MSUNIT.intMeasureUnitId = RECP.intContRecDetailTempMeasu " & _
                                " WHERE ISO.strContISOCodeAlias LIKE ? " & _
                                " AND RECP.intContainerReceptionId = ? " & _
                                " AND RECP.strContainerId= ? "

            '''' generara parametros
            oleDBTemptureCdm.Parameters.Add("@strCodeAlias", OleDbType.Char)
            oleDBTemptureCdm.Parameters.Add("@intReceptionId", OleDbType.Integer)
            oleDBTemptureCdm.Parameters.Add("@strContainerId", OleDbType.Char)

            ''' se crea query para leer las temperaturas del EIR

            lstr_queryTmpEIR = " SELECT RECP.intContainerReceptionId ," & _
                                "    RECP.strContainerId, " & _
                                "    ISO.strContISOCodeAlias, " & _
                                "    RECP.intContRecDetailTempMeasu as 'intContRecDetailTempMeasu', " & _
                                "    EI.decContainerInvOptTemp as 'decContRecDetailTemperature', " & _
                                "    EI.intContainerInvTempMeasu, " & _
                                "    MSUNIT.intMeasureUnitId, " & _
                                "    MSUNIT.strMeasureUnitIdentifier, " & _
                                "    MSUNIT.strMeasureUnitDescription " & _
                                " FROM tblclsContainerRecepDetail RECP " & _
                                "  INNER JOIN tblclsContainer  CONT ON RECP.strContainerId = CONT.strContainerId " & _
                                "  INNER JOIN tblclsContainerISOCode ISO ON ISO.intContISOCodeId = CONT.intContISOCodeId  " & _
                                "  INNER JOIN tblclsEIR EI  ON EI.intEIRId  = RECP.intEIRId  AND EI.strContainerId = RECP.strContainerId " & _
                                " LEFT JOIN tblclsMeasurementUnit MSUNIT ON MSUNIT.intMeasureUnitId = EI.intContainerInvTempMeasu " & _
                                " WHERE ( ISO.strContISOCodeAlias LIKE ?  OR ISO.strContISOCodeAlias = ISO.strContISOCodeAlias) " & _
                                " AND RECP.intContainerReceptionId = ? " & _
                                " AND RECP.strContainerId= ? "

            oleDBTemptureCdm.CommandText = lstr_queryTmpTure
            Dim lstr_ContainerTemp As String = ""
            Dim lint_SOReception As Integer = 0

            ''
            For lint_idxTempture As Integer = 0 To ldt_RECepcion.Rows.Count - 1
                ''''''' se va a obtener el servicio
                Dim lstr_Service As String = ""
                Dim lint_EIR As Integer = 0

                oleDBconnx = New OleDbConnection()
                oleDBconnx.ConnectionString = strconx
                adapter = New OleDbDataAdapter()

                oleDBSOReceptionCmd = oleDBconnx.CreateCommand
                oleDBSOReceptionCmd.Parameters.Clear()
                'oleDBSOReceptionCmd.Parameters.Add("@intVisitId", OleDbType.Integer)
                'oleDBSOReceptionCmd.Parameters.Add("@strContainerId", OleDbType.Char)




                Try
                    lint_EIR = Convert.ToInt32(ldt_RECepcion(lint_idxTempture)("intEIRId"))
                Catch ex As Exception
                    lint_EIR = 0
                End Try


                'lstr_Service = ldt_RECepcion(lint_idxContImo)("Servicio").ToString()
                lstr_Service = lodb_Serv.Value

                ''''''''''' si el servicio es recepcion
                If lstr_Service.ToUpper.IndexOf("REC") >= 0 Then

                    'obtener el nombre del contenedor
                    lstr_ContainerTemp = ldt_RECepcion(lint_idxTempture)("Contenedor").ToString()

                    '' obtener el id de la maniobra de recepcion del contenedor
                    Try
                        lint_SOReception = ldt_RECepcion(lint_idxTempture)("intServiceOrderId")
                    Catch ex As Exception
                        lint_SOReception = 0
                    End Try

                    If lint_SOReception = 0 Then

                        '' si no tiene maniobra 
                        ''''' se va a buscar la maniobra del contenedor  
                        ''hacer el query
                        lstr_querySOReception = " SELECT intServiceOrderId " & _
                                                " FROM  tblclsVisitContainer " & _
                                                " WHERE  intVisitId= ? " & _
                                                " and strContainerId = ? "

                        '' agregar parametros

                        oleDBSOReceptionCmd = oleDBconnx.CreateCommand
                        'oleDBSOReceptionCmd.Parameters.Clear()
                        oleDBSOReceptionCmd.Parameters.Add("@intVisitId", OleDbType.Integer)
                        oleDBSOReceptionCmd.Parameters.Add("@strContainerId", OleDbType.Char)

                        ' ponerle valor a los parametros 
                        oleDBSOReceptionCmd.Parameters("@intVisitId").Value = aint_visit
                        oleDBSOReceptionCmd.Parameters("@strContainerId").Value = lstr_ContainerTemp

                        oleDBSOReceptionCmd.CommandText = lstr_querySOReception
                        adapter.SelectCommand = oleDBSOReceptionCmd

                        ''' ejecutar el query
                        Dim lint_tempSOSValue = 0

                        Try
                            oleDBconnx.Open()
                            adapter.Fill(ldt_SOReception)
                        Catch ex As Exception
                            lstr_querySOReception = -1
                        Finally
                            adapter.SelectCommand.Connection.Close()
                            oleDBconnx.Close()

                            adapter.SelectCommand.Connection.Dispose()
                            oleDBconnx.Dispose()

                        End Try
                        '''' leer el valor resultado
                        If lint_tempSOSValue >= 0 Then
                            If ldt_SOReception.Rows.Count > 0 Then
                                lint_SOReception = Convert.ToInt32(ldt_SOReception(0)("intServiceOrderId"))
                            End If
                        End If
                        '''''''''  busqueda de maniobra del contenedor
                        '''' fin si no tiene maniobra 
                    End If



                    '''' actualizar parametros                    
                    oleDBconnx = New OleDbConnection()
                    oleDBconnx.ConnectionString = strconx
                    oleDBTemptureCdm = oleDBconnx.CreateCommand

                    oleDBTemptureCdm.Parameters.Add("@strCodeAlias", OleDbType.Char)
                    oleDBTemptureCdm.Parameters.Add("@intReceptionId", OleDbType.Integer)
                    oleDBTemptureCdm.Parameters.Add("@strContainerId", OleDbType.Char)

                    oleDBTemptureCdm.Parameters("@strCodeAlias").Value = "%RF%"
                    oleDBTemptureCdm.Parameters("@intReceptionId").Value = lint_SOReception
                    oleDBTemptureCdm.Parameters("@strContainerId").Value = lstr_ContainerTemp

                    If lint_EIR > 0 Then
                        oleDBTemptureCdm.CommandText = lstr_queryTmpEIR
                    Else
                        oleDBTemptureCdm.CommandText = lstr_queryTmpTure
                    End If
                    'oleDBTemptureCdm.CommandText = lstr_queryTmpTure


                    ldt_Temperature = New DataTable()

                    '''' volver a crear objetos de conexcion y adparte  y comands
                    adapter = New OleDbDataAdapter()

                    '


                    adapter.SelectCommand = oleDBTemptureCdm
                    ''''' ejecutar comandos
                    Try
                        oleDBconnx.Open()
                        adapter.Fill(ldt_Temperature)
                    Catch ex As Exception
                        Dim strError As String
                        strError = ObtenerError(ex.Message, 99999)
                        '' si obtuvo error
                        If Len(strError) < 1 Then
                            strError = ex.Message
                        End If
                        ''retornar el error encapsulado en tabla
                        Return dt_RetrieveErrorTable(strError)
                    Finally
                        adapter.SelectCommand.Connection.Close()
                        oleDBconnx.Close()

                        adapter.SelectCommand.Connection.Dispose()
                        oleDBconnx.Dispose()
                    End Try

                    '''''''' si trajo elementos
                    If ldt_Temperature.Rows.Count > 0 Then
                        ''''''''''''''' asignarselo a la columna de la tabla principal
                        ldt_RECepcion(lint_idxTempture)("strContISOCodeAlias") = ldt_Temperature(0)("strContISOCodeAlias")
                        ldt_RECepcion(lint_idxTempture)("intContRecDetailTempMeasu") = ldt_Temperature(0)("intContRecDetailTempMeasu")
                        ldt_RECepcion(lint_idxTempture)("strMeasureUnitIdentifier") = ldt_Temperature(0)("strMeasureUnitIdentifier")
                        ldt_RECepcion(lint_idxTempture)("strMeasureUnitDescription") = ldt_Temperature(0)("strMeasureUnitDescription")
                        ldt_RECepcion(lint_idxTempture)("decContRecDetailTemperature") = ldt_Temperature(0)("decContRecDetailTemperature")

                    Else

                        '''''''' si no
                        ''''''''''''' llenar columna de servicio, imo, strimo, con valores vacios
                        ldt_RECepcion(lint_idxTempture)("strContISOCodeAlias") = ""
                        ldt_RECepcion(lint_idxTempture)("intContRecDetailTempMeasu") = 0
                        ldt_RECepcion(lint_idxTempture)("strMeasureUnitIdentifier") = ""
                        ldt_RECepcion(lint_idxTempture)("strMeasureUnitDescription") = ""
                        ldt_RECepcion(lint_idxTempture)("decContRecDetailTemperature") = 0.0

                        ''''''fin si

                    End If
                    ''''''''fin si llenar 
                    ''''''''''' fin si el servicio es recepcion

                Else
                    ''''''''' sino es recepcion 
                    ''''''''''''''''''hacer que sean campos 0s los de idservicio, idimo, strimo  esten 0s

                    ldt_RECepcion(lint_idxTempture)("strContISOCodeAlias") = ""
                    ldt_RECepcion(lint_idxTempture)("intContRecDetailTempMeasu") = 0
                    ldt_RECepcion(lint_idxTempture)("strMeasureUnitIdentifier") = ""
                    ldt_RECepcion(lint_idxTempture)("strMeasureUnitDescription") = ""
                    ldt_RECepcion(lint_idxTempture)("decContRecDetailTemperature") = 0.0

                End If
                '' fin si el servicio es recepcion
            Next


            ''''' fin si tiene elementos en el renglon de recepcion
        End If


        ''''''''''''''''' fin de temperatura maniobra

        ''' manejo de la informacion 
        Dim lint_CounterIMO As Integer = 0
        '' si trae elementos se agrega a la tabla de retorno
        If ldt_RECepcion.Rows.Count > 0 Then
            ''''' se le agrega el servicio de ingreso 
            For Each lrw_rowitem As DataRow In ldt_RECepcion.Rows


                lrw_newrow = ldt_EIRItems.NewRow()

                lrw_newrow("Contenedor") = lrw_rowitem("Contenedor")
                lrw_newrow("Tam") = lrw_rowitem("Tam")
                lrw_newrow("Tipo") = lrw_rowitem("Tipo")
                lrw_newrow("Linea") = lrw_rowitem("Linea")
                lrw_newrow("Valido") = lrw_rowitem("Valido")
                lrw_newrow("Fiscal") = lrw_rowitem("Fiscal")
                lrw_newrow("EIR") = lrw_rowitem("EIR")
                lrw_newrow("intEIRId") = lrw_rowitem("intEIRId")

                lrw_newrow("Seals") = lrw_rowitem("Seals")
                lrw_newrow("Servicio") = lodb_Serv.Value
                lrw_newrow("intContainerUniversalId") = lrw_rowitem("intContainerUniversalId")
                lrw_newrow("intActiveContainer") = lrw_rowitem("intActiveContainer")
                ''agrear el imo
                lrw_newrow("intIMOCodeId") = lrw_rowitem("intIMOCodeId")
                lrw_newrow("strIMOCodeIdentifier") = lrw_rowitem("strIMOCodeIdentifier")
                lrw_newrow("intServiceOrderId") = lrw_rowitem("intServiceOrderId")
                '' agregar indice contador
                lrw_newrow("intIdx") = lint_CounterIMO

                lint_CounterIMO = lint_CounterIMO + 1

                ''''' agregar la temperatura
                lrw_newrow("strContISOCodeAlias") = lrw_rowitem("strContISOCodeAlias")
                lrw_newrow("intContRecDetailTempMeasu") = lrw_rowitem("intContRecDetailTempMeasu")
                lrw_newrow("strMeasureUnitIdentifier") = lrw_rowitem("strMeasureUnitIdentifier")
                lrw_newrow("strMeasureUnitDescription") = lrw_rowitem("strMeasureUnitDescription")
                lrw_newrow("decContRecDetailTemperature") = lrw_rowitem("decContRecDetailTemperature")

                ''''''''''fin temperatura
                '' pasa el tipo de servicio 
                lrw_newrow("strServiceIdentifier") = lrw_rowitem("strServiceIdentifier")

                ldt_EIRItems.Rows.Add(lrw_newrow)

            Next

        End If


        Return ldt_EIRItems
    End Function


    Public Function dt_GetVisitInfo(ByVal aint_VisitId) As DataTable

        Dim ldt_VisitData As DataTable = New DataTable ' Tabla con el query de resultados 
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        'Dim strcontainerid As String = "IPXU3283286"
        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()
        ldt_VisitData.TableName = "VisitInfo"
        Dim strSQL As String
        Try
            strSQL = "SELECT intVisitId,   " & _
                "strVisitDriver,   " & _
                "strVisitPlate, " & _
                "strCarrierLineName, " & _
                "dtmVisitDatetimeIn, " & _
                "dtmVisitDatetimeOut " & _
                "FROM tblclsVisit, tblclsCarrierLine  " & _
                "WHERE ( tblclsVisit.intCarrierLineId = tblclsCarrierLine.intCarrierLineId ) and " & _
                "( tblclsVisit.intVisitId = " & Convert.ToString(aint_VisitId) & ") "
            iolecmd_comand.CommandText = strSQL

            iAdapt_comand.SelectCommand = iolecmd_comand
            iAdapt_comand.Fill(ldt_VisitData)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            If Len(strError) = 0 Then
                strError = ex.Message
            End If
            ldt_VisitData.TableName = "Error"
            ldt_VisitData.Columns.Add("Error", GetType(String))
            Dim ldrw_Error As DataRow
            ldrw_Error = ldt_VisitData.NewRow()
            ldrw_Error("Error") = strError
            ldt_VisitData.Rows.Add(ldrw_Error)
            Return ldt_VisitData
        Finally
            iAdapt_comand.SelectCommand.Connection.Close()
            ioleconx_conexion.Close()

            iAdapt_comand.SelectCommand.Connection.Dispose()
            ioleconx_conexion.Dispose()

        End Try
        iAdapt_comand = Nothing
        ioleconx_conexion = Nothing

        Return ldt_VisitData
    End Function

    'metodo para traer los sellos que tenga guardados el eir especifico
    <WebMethod()> _
    Public Function WMdt_GetEIRSeals(ByVal aint_EIR As Integer) As DataTable

        Dim ldt_sealsresult As DataTable 'tabla que guardara el resultado del query
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        Dim strSQL As String

        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()

        ldt_sealsresult = New DataTable("EIRSeals")

        Try
            strSQL = "SELECT intEIRContainerSealId, " & _
                      "strEIRContSealNumber," & _
                      " blnEIRContSealApTerm, " & _
                      " dtmEIRContSealCreationStamp, " & _
                      " strEIRContSealCreatedBy, " & _
                      " dtmEIRContSealLastModified, " & _
                      " strEIRContSealLastModifiedBy  " & _
                      " FROM tblclsEIRContainerSeal " & _
            "WHERE (intEIRId = " & Convert.ToString(aint_EIR) & " ) "

            iolecmd_comand.CommandText = strSQL

            iAdapt_comand.SelectCommand = iolecmd_comand
            iAdapt_comand.Fill(ldt_sealsresult)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            If strError.Length = 0 Then
                strError = ex.Message
            End If
            Return dt_RetrieveErrorTable(strError)
        Finally
            iAdapt_comand.SelectCommand.Connection.Close()
            ioleconx_conexion.Close()

            iAdapt_comand.SelectCommand.Connection.Dispose()
            iAdapt_comand.Dispose()
            ioleconx_conexion.Dispose()
        End Try

        iAdapt_comand = Nothing
        ioleconx_conexion = Nothing

        Return ldt_sealsresult
    End Function

    'metodo para generar el EIR
    <WebMethod()> _
    Public Function WMint_GenerateEIRNumber(ByVal aint_VisitId As Integer, ByVal astr_ContainerName As String, ByVal aint_CategoryId As Integer, ByVal astr_UserName As String) As Integer

        Dim ldt_result As DataTable 'tabla que guardara el resultado del query
        Dim lAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim lolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim loleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        Dim strSQL As String


        'parametros
        Dim lparam_VisitId As OleDbParameter = New OleDbParameter()
        Dim lparam_Container As OleDbParameter = New OleDbParameter()
        Dim lparam_username As OleDbParameter = New OleDbParameter()
        Dim lparam_category As OleDbParameter = New OleDbParameter()


        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        loleconx_conexion.ConnectionString = istr_conx
        lolecmd_comand = loleconx_conexion.CreateCommand()

        'especificacion de valores de parametros
        lparam_VisitId.OleDbType = OleDbType.Integer
        lparam_VisitId.ParameterName = "@intVisitId"
        lparam_VisitId.Value = aint_VisitId
        'contenedor
        lparam_Container.OleDbType = OleDbType.Char
        lparam_Container.ParameterName = "@strContainerId"
        lparam_Container.Value = astr_ContainerName
        'usuario
        lparam_username.OleDbType = OleDbType.Char
        lparam_username.ParameterName = "@strUserId"
        lparam_username.Value = astr_UserName
        'category
        lparam_category.OleDbType = OleDbType.Integer
        lparam_category.ParameterName = "@intContainerCategoryId"
        lparam_category.Value = aint_CategoryId

        ldt_result = New DataTable("EIRNumber")
        lolecmd_comand.CommandText = "spGenerateEIRNumber"

        strSQL = "spGenerateEIRNumber"

        lolecmd_comand.CommandText = strSQL
        lolecmd_comand.CommandType = CommandType.StoredProcedure
        lolecmd_comand.Parameters.Add(lparam_VisitId)
        lolecmd_comand.Parameters.Add(lparam_Container)
        lolecmd_comand.Parameters.Add(lparam_category)
        lolecmd_comand.Parameters.Add(lparam_username)

        Try
            lAdapt_comand.SelectCommand = lolecmd_comand
            lAdapt_comand.Fill(ldt_result)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            Return -1
        Finally
            lAdapt_comand.SelectCommand.Connection.Close()
            loleconx_conexion.Close()

            lAdapt_comand.SelectCommand.Connection.Dispose()
            loleconx_conexion.Dispose()
        End Try

        lAdapt_comand = Nothing
        loleconx_conexion = Nothing


        'analizar el id de el renglon generado
        If ldt_result.Rows.Count = 1 Then
            ' si nada mas obutvo un renglon 
            If ldt_result.Columns.Count = 1 Then
                'ver si la columna se llama intEIRId
                If ldt_result.Columns(0).ColumnName = "intEIRId" Then

                    ''bloque notificacion
                    '' obtener la varaible notificacion 
                    Try
                        Dim lint_notifications As Integer
                        Dim lstr_CadenaSent As String
                        Dim llng_Visit As Long
                        Dim llng_Universal As Long
                        Dim lstr_Contenedor As String
                        Dim lstr_searchService As String
                        Dim lstr_notificaciion As String
                        Dim llng_EirVal As Long

                        lint_notifications = CType(ConfigurationManager.AppSettings.Item("SendNotifications").ToString, Integer)
                        lstr_CadenaSent = ""
                        'si esta habilitado enviar notificaciones
                        If lint_notifications > 0 Then

                            ' ver si hay elementos por procesar
                            Dim ldt_table As DataTable = New DataTable("elements")
                      
                            ldt_table = CargarGrid_Visita_Check_in(aint_VisitId, "0")

                            ' si tiene elementos avanza
                            If ldt_table.Rows.Count > 0 Then
                                ' obtener el servicio


                                For Each lrow As DataRow In ldt_table.Rows

                                    'Obtenner el numero de contenenedor para enviar 
                                    lstr_Contenedor = lrow("Contenedor").ToString()
                                    llng_Universal = CType(lrow("xintContainerUniversalId").ToString, Long)
                                    llng_EirVal = CType(ldt_result(0)(0).ToString, Long)

                                    ' si el universal leido es el mismo que se envia como parametro ,llamar a la notificacion 
                                    If astr_ContainerName = lstr_Contenedor Then
                                        ' lservweb.                                        
                                        SentNotificationsForEIRCreated(aint_VisitId, llng_Universal, lstr_Contenedor, llng_EirVal, astr_UserName)
                                    End If


                                Next ' recorrido de listado 

                            End If ' si hay elemen tos por avisar

                        End If ' si hay notificaciones

                    Catch ex As Exception

                    End Try ' de notificaciones

                    '' fin bloque notificacion


                    Return ldt_result(0)(0)
                Else
                    Return -1
                End If
            Else
                ' si no obtuvo especialmente una columna
                Return -1
            End If
        Else
            'si no obutvo un renglon especifico
            Return -1
        End If

        Return -1



        Return 0

    End Function

    'metodo para actualizar sellos de EIR
    <WebMethod()> _
    Public Function WM_UpdateEIRSeals(ByVal aint_EIR As Integer, ByVal aDtTB_SealsOperation As DataTable, ByVal astr_UserName As String) As String

        Dim ldt_sealsresult As DataTable 'tabla que guardara el resultado del query
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        Dim lint_operation As Integer = 0
        Dim lparamGeneric As OleDbParameter = New OleDbParameter()
        Dim lstr_Seal As String
        Dim lint_SealId As Integer
        Dim lbln_ApplyTerminal As Boolean
        Dim lint_VBlnApTermi As Integer
        Dim lstr_SQL As String
        Dim lstr_Message As String = ""
        Dim lint_itemscount As Integer = 0
        Dim lstr_User As String
        Dim lstr_Date As String

        Dim lint_DeletedItems As Integer = 0
        Dim lint_InserttedItems As Integer = 0
        Dim lint_ModifiedItems As Integer = 0


        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString

        ' Return aDtTB_SealsOperation.Rows.Count.ToString()

        For Each lrow As DataRow In aDtTB_SealsOperation.Rows

            ioleconx_conexion.ConnectionString = istr_conx
            iolecmd_comand = ioleconx_conexion.CreateCommand()

            lint_itemscount = lint_itemscount + 1
            'limpiar cadena sql
            lstr_SQL = ""
            'limpiar comando
            iolecmd_comand.Parameters.Clear()

            'obtener el numero del sello
            lstr_Seal = lrow("strSealNumber")
            lint_SealId = lrow("intSealId")
            lbln_ApplyTerminal = lrow("blnEIRContSealApTerm")
            lstr_Date = lrow("dtmExecDate")

            If lbln_ApplyTerminal = True Then
                lint_VBlnApTermi = 1
            Else
                lint_VBlnApTermi = 0
            End If

            'ver que es lo que se va a hacer 
            lint_operation = lrow("IntOperationType")
            Select Case lint_operation
                Case 1
                    'insercion   1
                    'agregar parametros
                    iolecmd_comand.Parameters.Add("intEIRId", OleDbType.Integer)
                    iolecmd_comand.Parameters.Add("strEIRContSealNumber", OleDbType.Char)
                    iolecmd_comand.Parameters.Add("blnEIRContSealApTerm", OleDbType.Integer)
                    iolecmd_comand.Parameters.Add("strUser", OleDbType.Char)

                    iolecmd_comand.Parameters("intEIRId").Value = aint_EIR
                    iolecmd_comand.Parameters("strEIRContSealNumber").Value = lstr_Seal
                    iolecmd_comand.Parameters("blnEIRContSealApTerm").Value = lint_VBlnApTermi
                    iolecmd_comand.Parameters("strUser").Value = astr_UserName

                    '"exec spAddEIRSeal " & dt.Rows(i)("intEIRId").ToString() & ", '" & strSeal & "', 0, '" & lstrusername & "'"
                    'definir la cadena sql
                    lstr_SQL = "spAddEIRSeal"
                    'definir que tipo de comando se va a ejecutar
                    iolecmd_comand.CommandType = CommandType.StoredProcedure
                    lint_InserttedItems = lint_InserttedItems + 1

                Case 2
                    'edicion      2

                    'definir la cadena sql
                    'lstr_SQL = " UPDATE tblclsEIRContainerSeal " & _
                    '           "  SET strEIRContSealNumber = ?, " & _
                    '           "      blnEIRContSealApTerm = ? ," & _
                    '           "  strEIRContSealLastModifiedBy = ? ," & _
                    '           " dtmEIRContSealLastModified = getdate() " & _
                    '           " WHERE intEIRContainerSealId = ? " & _
                    '           " AND intEIRId= ? "
                    '" dtmEIRContSealLastModified = ? " & _

                    lstr_SQL = " UPDATE tblclsEIRContainerSeal " & _
                           "  SET strEIRContSealNumber = ? ," & _
                           "      blnEIRContSealApTerm = ? ," & _
                           "  strEIRContSealLastModifiedBy = ? ," & _
                           " dtmEIRContSealLastModified = ? " & _
                           " WHERE intEIRContainerSealId = ? " & _
                           " AND intEIRId= ? "

                    'agregar parametros
                    'iolecmd_comand.Parameters.AddWithValue("@prmstr_StrSealName", lstr_Seal)
                    'iolecmd_comand.Parameters.AddWithValue("@prmint_ApplyTerminal", lint_VBlnApTermi)
                    'iolecmd_comand.Parameters.AddWithValue("@prmstr_User", astr_UserName)
                    ''iolecmd_comand.Parameters.AddWithValue("@prmstr_Date", lstr_Date)
                    'iolecmd_comand.Parameters.AddWithValue("@prmint_intSealID", lint_SealId)
                    'iolecmd_comand.Parameters.AddWithValue("@prmint_intEIR", aint_EIR)

                    ''tipo de  dato parametos
                    'iolecmd_comand.Parameters("@prmstr_StrSealName").OleDbType = OleDbType.Char
                    'iolecmd_comand.Parameters("@prmint_ApplyTerminal").OleDbType = OleDbType.Integer
                    'iolecmd_comand.Parameters("@prmstr_User").OleDbType = OleDbType.Char
                    ''iolecmd_comand.Parameters("@prmstr_Date").OleDbType = OleDbType.Char
                    'iolecmd_comand.Parameters("@prmint_intSealID").OleDbType = OleDbType.Integer
                    'iolecmd_comand.Parameters("@prmint_intEIR").OleDbType = OleDbType.Integer



                    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

                    iolecmd_comand.Parameters.AddWithValue("@prmstr_StrSealName", lstr_Seal)
                    iolecmd_comand.Parameters.AddWithValue("@prmint_ApplyTerminal", lint_VBlnApTermi)
                    iolecmd_comand.Parameters.AddWithValue("@prmstr_User", astr_UserName)
                    iolecmd_comand.Parameters.AddWithValue("@prmstr_Date", lstr_Date)
                    iolecmd_comand.Parameters.AddWithValue("@prmint_intSealID", lint_SealId)
                    iolecmd_comand.Parameters.AddWithValue("@prmint_intEIR", aint_EIR)

                    'tipo de  dato parametos
                    iolecmd_comand.Parameters("@prmstr_StrSealName").OleDbType = OleDbType.Char
                    iolecmd_comand.Parameters("@prmint_ApplyTerminal").OleDbType = OleDbType.Integer
                    iolecmd_comand.Parameters("@prmstr_User").OleDbType = OleDbType.Char
                    iolecmd_comand.Parameters("@prmstr_Date").OleDbType = OleDbType.Char
                    iolecmd_comand.Parameters("@prmint_intSealID").OleDbType = OleDbType.Integer
                    iolecmd_comand.Parameters("@prmint_intEIR").OleDbType = OleDbType.Integer

                    'definir que tipo de comando se va a ejecutar
                    iolecmd_comand.CommandType = CommandType.Text
                    lint_ModifiedItems = lint_ModifiedItems + 1

                Case 3
                    'eliminacion   3

                    iolecmd_comand.Parameters.Clear()

                    lstr_SQL = " DELETE tblclsEIRContainerSeal " & _
                               " WHERE intEIRContainerSealId = ? " & _
                               " AND strEIRContSealNumber = ?" & _
                               " AND intEIRId = ? "  ' & _                  
                    'agregar parametros
                    iolecmd_comand.Parameters.AddWithValue("@prmint_intSealID", lint_SealId)
                    iolecmd_comand.Parameters.AddWithValue("@prmstr_StrSealName", lstr_Seal)
                    iolecmd_comand.Parameters.AddWithValue("@prmint_intEIR", aint_EIR)

                    'tipo de  dato parametos
                    iolecmd_comand.Parameters("@prmint_intSealID").OleDbType = OleDbType.Integer
                    iolecmd_comand.Parameters("@prmstr_StrSealName").OleDbType = OleDbType.Char
                    iolecmd_comand.Parameters("@prmint_intEIR").OleDbType = OleDbType.Integer


                    iolecmd_comand.CommandType = CommandType.Text

                    lint_ModifiedItems = lint_ModifiedItems + 1
                Case Else

            End Select

            iolecmd_comand.CommandText = lstr_SQL
            'Return lstr_SQL
            'ejecutar la accion
            ' si el tipo de operacion esta entre 1 y 3
            Try
                ''conectar
                iolecmd_comand.Connection.Open()
                iolecmd_comand.ExecuteNonQuery()
                ''desconectar
            Catch ex As Exception
                lstr_Message = ObtenerError(ex.Message, 9999)
                If lstr_Message.Length > 0 Then
                    Return lstr_Message
                Else
                    Return ex.Message
                End If
            Finally
                iolecmd_comand.Connection.Close()
                iolecmd_comand.Connection.Dispose()
                'ioleconx_conexion.close()
            End Try
            ' Return lint_itemscount.ToString()
            iolecmd_comand = Nothing
        Next
        ' lstr_Message = lstr_Message + "Insertados =" + lint_InserttedItems.ToString() + " Modificados=" + lint_ModifiedItems.ToString() + " Eliminados=" + lint_DeletedItems.ToString() + "EIR=" + aint_EIR.ToString() + " lsello=" + lstr_Seal
        Return lstr_Message

        Return ""

    End Function


    'Esta funcion retorna una tabla con un mensaje de error
    Public Function dt_RetrieveErrorTable(ByVal astr_Message As String) As DataTable

        Dim ldt_ErrorTable As DataTable
        Dim lrw_Error As DataRow

        ldt_ErrorTable = New DataTable("ErrorTable")
        ldt_ErrorTable.Columns.Add("Error", GetType(String))
        lrw_Error = ldt_ErrorTable.NewRow()

        lrw_Error("Error") = astr_Message
        ldt_ErrorTable.Rows.Add(lrw_Error)
        Return ldt_ErrorTable

    End Function


    'Funcion que retorna los daños de un EIR
    'metodo para traer los sellos que tenga guardados el eir especifico
    <WebMethod()> _
    Public Function WMdt_GetEIRDamages(ByVal aint_EIR As Integer) As DataTable

        Dim ldt_Damagessresult As DataTable 'tabla que guardara los DAÑOS
        Dim ldt_CheckedDamresult As DataTable

        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        Dim strSQL As String

        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()

        ldt_Damagessresult = New DataTable("tblclsEIRContainerDamage")
        ldt_CheckedDamresult = New DataTable("tblclsEIRContainerDamage")

        Try
            strSQL = "SELECT intEIRContainerDamageId, " & _
                      " tblclsEIRContainerDamage.intContDamTypeId," & _
                      " tblclsEIRContainerDamage.intContainerPositionId, " & _
                      " strEIRContDamDescription, " & _
                      "  SUBSTRING(strContDamTypeDescription,1,21) AS 'strContDamTypeDescription', " & _
                      " strContDamTypeIdentifier,  " & _
                      " strContainerPosDescription, " & _
                      " strContainerPosIdentifier, " & _
                      " decEIRContDamQuantity " & _
                      " FROM tblclsEIRContainerDamage " & _
                      "  INNER JOIN tblclsContainerDamageType ON tblclsEIRContainerDamage.intContDamTypeId= tblclsContainerDamageType.intContDamTypeId " & _
                      " INNER JOIN tblclsContainerPosition ON tblclsEIRContainerDamage.intContainerPositionId = tblclsContainerPosition.intContainerPositionId " & _
                       "WHERE (intEIRId = " & Convert.ToString(aint_EIR) & " ) "

            iolecmd_comand.CommandText = strSQL

            iAdapt_comand.SelectCommand = iolecmd_comand
            iAdapt_comand.Fill(ldt_Damagessresult)

        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            If strError.Length = 0 Then
                strError = ex.Message
            End If
            Return dt_RetrieveErrorTable(strError)
        Finally
            iAdapt_comand.SelectCommand.Connection.Close()
            ioleconx_conexion.Close()

            iAdapt_comand.SelectCommand.Connection.Dispose()
            ioleconx_conexion.Dispose()
        End Try

        iAdapt_comand = Nothing
        iolecmd_comand = Nothing
        CopyTableAndCheckLatin(ldt_Damagessresult, ldt_CheckedDamresult)
        ldt_CheckedDamresult.TableName = "tblclsEIRContainerDamage"

        'ldt_Damagessresult
        Return ldt_CheckedDamresult

    End Function
    'Function que retorna el catalogo de daños
    <WebMethod()> _
    Public Function WMdt_GetDamagesTypes() As DataTable

        Dim ldt_DamTyperesult As DataTable 'tabla que obtiene el 
        Dim ldt_CheckedDamTyperesult As DataTable
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        Dim strSQL As String
        Dim ldrow_new As DataRow

        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()

        ldt_DamTyperesult = New DataTable("tblclsContainerDamageType")
        ldt_CheckedDamTyperesult = New DataTable("tblclsContainerDamageType")

        Try
            strSQL = "SELECT intContDamTypeId, " & _
                     "strContDamTypeIdentifier, " & _
                     "SUBSTRING(strContDamTypeDescription,1,21) AS 'strContDamTypeDescription', " & _
                     "strContDamTypeEngDescription " & _
                     "FROM tblclsContainerDamageType " & _
                     "WHERE blnContDamTypeActive =1 "

            iolecmd_comand.CommandText = strSQL

            iAdapt_comand.SelectCommand = iolecmd_comand
            iAdapt_comand.Fill(ldt_DamTyperesult)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            If strError.Length = 0 Then
                strError = ex.Message
            End If
            Return dt_RetrieveErrorTable(strError)
        Finally
            iAdapt_comand.SelectCommand.Connection.Close()
            ioleconx_conexion.Close()

            iAdapt_comand.SelectCommand.Connection.Dispose()
            ioleconx_conexion.Dispose()
        End Try

        CopyTableAndCheckLatin(ldt_DamTyperesult, ldt_CheckedDamTyperesult)

        ldt_CheckedDamTyperesult.TableName = "tblclsContainerDamageType"

        If ldt_CheckedDamTyperesult.Rows.Count > 0 Then

            'insertar un registro vacio, para que seleccione 0 , en un principio

            ldrow_new = ldt_CheckedDamTyperesult.NewRow()
            ldrow_new("intContDamTypeId") = -1
            ldrow_new("strContDamTypeIdentifier") = "NUEVO"
            ldrow_new("strContDamTypeDescription") = "NUEVO"
            ldrow_new("strContDamTypeEngDescription") = "NUEVO"

            ldt_CheckedDamTyperesult.Rows.Add(ldrow_new)

        End If

        iAdapt_comand = Nothing
        ioleconx_conexion = Nothing

        Return ldt_CheckedDamTyperesult

    End Function

    'Funcion que retornar catalogo  de posiciones de danios
    <WebMethod()> _
  Public Function WMdt_GetDamagesPositionsCatalog() As DataTable

        Dim ldt_ContPositionresult As DataTable 'tabla que obtiene el 
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        Dim strSQL As String
        Dim ldrow As DataRow

        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()

        ldt_ContPositionresult = New DataTable("tblclsContainerPosition")

        Try
            strSQL = "SELECT	intContainerPositionId," & _
                     " strContainerPosIdentifier, " & _
                     " strContainerPosDescription, " & _
                     " strContainerPosEngDescription " & _
                     " FROM tblclsContainerPosition " & _
                     " WHERE blnContainerPosActive = 1 "

            iolecmd_comand.CommandText = strSQL

            iAdapt_comand.SelectCommand = iolecmd_comand
            iAdapt_comand.Fill(ldt_ContPositionresult)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            If strError.Length = 0 Then
                strError = ex.Message
            End If
            Return dt_RetrieveErrorTable(strError)
        Finally
            iAdapt_comand.SelectCommand.Connection.Close()
            ioleconx_conexion.Close()

            iAdapt_comand.SelectCommand.Connection.Dispose()
            ioleconx_conexion.Dispose()
        End Try

        'si tiene registros la tabla , insertar un renglon para valor 0
        If ldt_ContPositionresult.Rows.Count > 0 Then

            ldrow = ldt_ContPositionresult.NewRow()
            ldrow("intContainerPositionId") = -1
            ldrow("strContainerPosIdentifier") = "NUEVO"
            ldrow("strContainerPosDescription") = "NUEVO"
            ldrow("strContainerPosEngDescription") = "NUEVO"
            ldrow("strContainerPosEngDescription") = "NUEVO"

            ldt_ContPositionresult.Rows.Add(ldrow)

        End If

        iAdapt_comand = Nothing
        ioleconx_conexion = Nothing

        Return ldt_ContPositionresult

    End Function

    'Funcion que actualiza (guarda los daños) los daños
    <WebMethod()> _
   Public Function WM_UpdateEIRDamages(ByVal aint_EIR As Integer, ByVal aDtTB_DamagesOperation As DataTable, ByVal astr_UserName As String) As String

        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        Dim lint_operation As Integer = 0
        Dim lparamGeneric As OleDbParameter = New OleDbParameter()

        Dim lint_EIRDamageID As Integer
        Dim lint_DamageTypeID As Integer
        Dim lint_PositionTypeID As Integer
        Dim ldec_Quantity As Decimal
        Dim lstr_Description As String

        Dim lstr_SQL As String
        Dim lstr_Message As String = ""
        Dim lint_itemscount As Integer = 0
        Dim lstr_User As String
        Dim lstr_Date As String

        Dim lint_DeletedItems As Integer = 0
        Dim lint_InserttedItems As Integer = 0
        Dim lint_ModifiedItems As Integer = 0
        Dim lstr_EIRDamageVB As String = ""
        Dim lstr_PositionTypeVB As String = ""


        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()

        ' Return aDtTB_SealsOperation.Rows.Count.ToString()
        For Each lrow As DataRow In aDtTB_DamagesOperation.Rows


            lint_itemscount = lint_itemscount + 1

            ioleconx_conexion = New OleDbConnection()
            ioleconx_conexion.ConnectionString = istr_conx
            iolecmd_comand = ioleconx_conexion.CreateCommand()

            'limpiar cadena sql
            lstr_SQL = ""
            'limpiar comando
            iolecmd_comand.Parameters.Clear()

            'obtener el numero del sello
            lint_EIRDamageID = lrow("intEIRContainerDamageId")
            lint_DamageTypeID = lrow("intContDamTypeId")
            lstr_EIRDamageVB = lrow("strContDamTypeIdentifier")
            lint_PositionTypeID = lrow("intContainerPositionId")
            lstr_PositionTypeVB = lrow("strContainerPosIdentifier")
            lstr_Description = lrow("strEIRContDamDescription")
            ldec_Quantity = lrow("decEIRContDamQuantity")
            lstr_Date = lrow("dtmEIRContDamLastModified")


            'ver que es lo que se va a hacer 
            lint_operation = lrow("IntOperationType")
            Select Case lint_operation
                Case 1
                    iolecmd_comand.Parameters.Clear()
                    'insercion   1
                    'agregar parametros

                    iolecmd_comand.Parameters.Add("@intEIRId", OleDbType.Integer)
                    iolecmd_comand.Parameters.Add("@strContDamTypeId", OleDbType.Char)
                    iolecmd_comand.Parameters.Add("@strContainerPositionId", OleDbType.Char)
                    iolecmd_comand.Parameters.Add("@decEIRContDamQuantity", OleDbType.Decimal)
                    iolecmd_comand.Parameters.Add("@strUser", OleDbType.Char)


                    iolecmd_comand.Parameters("@intEIRId").Value = aint_EIR
                    iolecmd_comand.Parameters("@strContDamTypeId").Value = lstr_EIRDamageVB
                    iolecmd_comand.Parameters("@strContainerPositionId").Value = lstr_PositionTypeVB
                    iolecmd_comand.Parameters("@decEIRContDamQuantity").Value = ldec_Quantity
                    iolecmd_comand.Parameters("@strUser").Value = astr_UserName

                    'definir la cadena sql
                    lstr_SQL = "spAddEIRDamage"
                    'definir que tipo de comando se va a ejecutar
                    iolecmd_comand.CommandType = CommandType.StoredProcedure
                    lint_InserttedItems = lint_InserttedItems + 1

                Case 2
                    iolecmd_comand.Parameters.Clear()

                    'edicion      2

                    'definir la cadena sql                    

                    lstr_SQL = " UPDATE tblclsEIRContainerDamage " & _
                               " SET intContDamTypeId = ? , " & _
                               " 	intContainerPositionId = ? , " & _
                               " 	decEIRContDamQuantity = ? , " & _
                               " 	strEIRContDamLastModifiedBy = ?, " & _
                               "	dtmEIRContDamLastModified = ?  " & _
                               " WHERE intEIRId = ? " & _
                               " AND intEIRContainerDamageId  = ? "
                    '" 	strEIRContDamDescription = ? , " & _

                    'agregar parametros                            
                    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

                    iolecmd_comand.Parameters.Add("@intContDamTypeId", OleDbType.Integer)
                    iolecmd_comand.Parameters.Add("@intContainerPositionId", OleDbType.Integer)
                    'iolecmd_comand.Parameters.Add("@strEIRContDamDescription", OleDbType.Char)
                    iolecmd_comand.Parameters.Add("@decEIRContDamQuantity", OleDbType.Decimal)
                    iolecmd_comand.Parameters.Add("@strEIRContDamLastModifiedBy", OleDbType.Char)
                    iolecmd_comand.Parameters.Add("@dtmEIRContDamLastModified", OleDbType.Char)
                    iolecmd_comand.Parameters.Add("@intEIRId", OleDbType.Integer)
                    iolecmd_comand.Parameters.Add("@intEIRContainerDamageId", OleDbType.Integer)


                    iolecmd_comand.Parameters("@intContDamTypeId").Value = lint_DamageTypeID
                    iolecmd_comand.Parameters("@intContainerPositionId").Value = lint_PositionTypeID
                    'iolecmd_comand.Parameters("@strEIRContDamDescription").Value = lstr_Description 
                    iolecmd_comand.Parameters("@decEIRContDamQuantity").Value = ldec_Quantity
                    iolecmd_comand.Parameters("@strEIRContDamLastModifiedBy").Value = lstr_User
                    iolecmd_comand.Parameters("@dtmEIRContDamLastModified").Value = lstr_Date
                    iolecmd_comand.Parameters("@intEIRId").Value = aint_EIR
                    iolecmd_comand.Parameters("@intEIRContainerDamageId").Value = lint_EIRDamageID



                    'definir que tipo de comando se va a ejecutar
                    iolecmd_comand.CommandType = CommandType.Text
                    lint_ModifiedItems = lint_ModifiedItems + 1

                Case 3
                    'eliminacion   3

                    iolecmd_comand.Parameters.Clear()

                    lstr_SQL = "  DELETE tblclsEIRContainerDamage " & _
                    " WHERE  intEIRId = ? " & _
                    " AND intEIRContainerDamageId = ? " & _
                    " AND intContDamTypeId = ? "


                    iolecmd_comand.Parameters.Add("@intEIRId", OleDbType.Integer)
                    iolecmd_comand.Parameters.Add("@intEIRContainerDamageId", OleDbType.Integer)
                    iolecmd_comand.Parameters.Add("@intContDamTypeId", OleDbType.Integer)

                    iolecmd_comand.Parameters("@intEIRId").Value = aint_EIR
                    iolecmd_comand.Parameters("@intEIRContainerDamageId").Value = lint_EIRDamageID
                    'iolecmd_comand.Parameters("@strEIRContDamDescription").Value = lstr_Description 
                    iolecmd_comand.Parameters("@intContDamTypeId").Value = lint_DamageTypeID

                    iolecmd_comand.CommandType = CommandType.Text

                    lint_DeletedItems = lint_DeletedItems + 1

                Case Else

            End Select

            iolecmd_comand.CommandText = lstr_SQL
            'Return lstr_SQL
            'ejecutar la accion
            ' si el tipo de operacion esta entre 1 y 3
            Try
                ''conectar
                iolecmd_comand.Connection.Open()
                iolecmd_comand.ExecuteNonQuery()
                ''desconectar
            Catch ex As Exception
                lstr_Message = ObtenerError(ex.Message, 9999)
                If lstr_Message.Length > 0 Then
                    Return lstr_Message
                Else
                    Return ex.Message
                End If
            Finally
                ioleconx_conexion.Close()
                iolecmd_comand.Connection.Close()

                ioleconx_conexion.Dispose()
                iolecmd_comand.Dispose()


            End Try
            ' Return lint_itemscount.ToString()
        Next

        'lstr_Message = "Insertados =" + lint_InserttedItems.ToString() + " Modificados=" + lint_ModifiedItems.ToString() + " Eliminados=" + lint_DeletedItems.ToString()

        ioleconx_conexion = Nothing
        iolecmd_comand = Nothing

        Return lstr_Message

        Return ""

    End Function




    'funcion que retorna las sobredimenciones
    <WebMethod()> _
    Public Function WMdt_GetEIROverSizes(ByVal aint_EIR As Integer) As DataTable

        Dim ldt_OverSizeResult As DataTable 'tabla que guardara los sellos
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        Dim lint_OverTypeId As Integer = 0
        Dim strSQL As String

        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()

        ldt_OverSizeResult = New DataTable("tblclsEIRContainerOversize")

        Try

            strSQL = "  SELECT 	intEIRContainerOversizeId, " & _
                      "	intContainerPositionId, " & _
                      " ( CASE WHEN intContainerPositionId=1 THEN 'OVERHIGH'  " & _
                     "        WHEN intContainerPositionId=2 THEN 'OVERRIGHT' " & _
                     "        WHEN intContainerPositionId=3 THEN 'OVERLEFT' " & _
                     "        WHEN intContainerPositionId=4 THEN 'OVERFRONT' " & _
                     "        WHEN intContainerPositionId=5 THEN 'OVEREND' " & _
                     " ELSE 'N/A' " & _
                     "  END )AS 'strOverSizeIdentifier', " & _
                     "	decEIRContainerOverQuantity, " & _
                     "	dtmEIRContOverCreationStamp, " & _
                     "	strEIRContainerOverCreatedBy, " & _
                     "	dtmEIRContOverLastModified,  " & _
                     "  strEIRContOverLastModifiedBy " & _
                     "  FROM   tblclsEIRContainerOversize " & _
                     " WHERE intEIRId = " & Convert.ToString(aint_EIR)

            'strSQL = "  SELECT 	intEIRContainerOversizeId, " & _
            '         "	intContainerPositionId, " & _
            '         " ( CASE  WHEN intEIRContainerOversizeId=1 THEN 'OVERHIGH'  " & _
            '        "        WHEN intEIRContainerOversizeId=2 THEN 'OVERRIGHT' " & _
            '        "        WHEN intEIRContainerOversizeId=3 THEN 'OVERLEFT' " & _
            '        "        WHEN intEIRContainerOversizeId=4 THEN 'OVERFRONT' " & _
            '        "  END )AS strOverSizeIdentifier, " & _
            '        "	decEIRContainerOverQuantity, " & _
            '        "	dtmEIRContOverCreationStamp, " & _
            '        "	strEIRContainerOverCreatedBy, " & _
            '        "	dtmEIRContOverLastModified,  " & _
            '        "  strEIRContOverLastModifiedBy " & _
            '        "  FROM   tblclsEIRContainerOversize " & _
            '        " WHERE intEIRId = " & Convert.ToString(aint_EIR)


            'strSQL = "  SELECT 	intEIRContainerOversizeId, " & _
            '          "	intContainerPositionId, " & _
            '          "  'identificador' AS strOverSizeIdentifier, " & _
            '         "	decEIRContainerOverQuantity, " & _
            '         "	dtmEIRContOverCreationStamp, " & _
            '         "	strEIRContainerOverCreatedBy, " & _
            '         "	dtmEIRContOverLastModified,  " & _
            '         "  strEIRContOverLastModifiedBy " & _
            '         "  FROM   tblclsEIRContainerOversize " & _
            '         " WHERE intEIRId = " & Convert.ToString(aint_EIR)

            iolecmd_comand.CommandText = strSQL

            iAdapt_comand.SelectCommand = iolecmd_comand
            iAdapt_comand.Fill(ldt_OverSizeResult)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            If strError.Length = 0 Then
                strError = ex.Message
            End If
            Return dt_RetrieveErrorTable(strError)
        Finally
            iAdapt_comand.SelectCommand.Connection.Close()
            ioleconx_conexion.Close()

            iAdapt_comand.SelectCommand.Connection.Dispose()
            ioleconx_conexion.Dispose()
        End Try

        '' si trajo registros, recorrerlos
        'For lint_idx As Integer = 0 To ldt_OverSizeResult.Rows.Count - 1
        '    '' como el query no acepta los cases entonces sera realizara un case por codigo
        '    ''obtener el id del tipo
        '    lint_OverTypeId = ldt_OverSizeResult(lint_idx)("strOverSizeIdentifier")
        '    Select Case lint_OverTypeId
        '        1
        '    End Select
        'Next


        iAdapt_comand = Nothing
        ioleconx_conexion = Nothing

        Return ldt_OverSizeResult

    End Function


    'funcion que retorna los tipos de sobredimenciones  
    <WebMethod()> _
 Public Function WMdt_GetOverSizesType() As DataTable

        Dim ldt_OverSizeTypeResult As DataTable 'tabla que guardara los sellos
        Dim lrow_OverSizeType As DataRow

        ldt_OverSizeTypeResult = New DataTable("OverSizeType")

        ldt_OverSizeTypeResult.Columns.Add("intOverSizeTypeId", GetType(Integer))
        ldt_OverSizeTypeResult.Columns.Add("strOverSizeIdentifier", GetType(String))


        lrow_OverSizeType = ldt_OverSizeTypeResult.NewRow()
        lrow_OverSizeType("intOverSizeTypeId") = 1
        'lrow_OverSizeType("intOverSizeTypeId") = 4 'TECHO
        lrow_OverSizeType("strOverSizeIdentifier") = "OVERHIGH"
        ldt_OverSizeTypeResult.Rows.Add(lrow_OverSizeType)

        lrow_OverSizeType = ldt_OverSizeTypeResult.NewRow()
        lrow_OverSizeType("intOverSizeTypeId") = 2   'PANEL LATERAL DERECHO
        lrow_OverSizeType("strOverSizeIdentifier") = "OVERRIGHT"
        ldt_OverSizeTypeResult.Rows.Add(lrow_OverSizeType)

        lrow_OverSizeType = ldt_OverSizeTypeResult.NewRow()
        lrow_OverSizeType("intOverSizeTypeId") = 3   'PANEL LATERAL IZQUIERDO
        lrow_OverSizeType("strOverSizeIdentifier") = "OVERLEFT"
        ldt_OverSizeTypeResult.Rows.Add(lrow_OverSizeType)

        lrow_OverSizeType = ldt_OverSizeTypeResult.NewRow()
        lrow_OverSizeType("intOverSizeTypeId") = 4
        'lrow_OverSizeType("intOverSizeTypeId") = 1   'PANEL FRONTAL
        lrow_OverSizeType("strOverSizeIdentifier") = "OVERFRONT"
        ldt_OverSizeTypeResult.Rows.Add(lrow_OverSizeType)

        lrow_OverSizeType = ldt_OverSizeTypeResult.NewRow()
        lrow_OverSizeType("intOverSizeTypeId") = 5
        lrow_OverSizeType("strOverSizeIdentifier") = "OVEREND"
        ldt_OverSizeTypeResult.Rows.Add(lrow_OverSizeType)

        lrow_OverSizeType = ldt_OverSizeTypeResult.NewRow()
        lrow_OverSizeType("intOverSizeTypeId") = -1
        lrow_OverSizeType("strOverSizeIdentifier") = "NUEVO"
        ldt_OverSizeTypeResult.Rows.Add(lrow_OverSizeType)


        Return ldt_OverSizeTypeResult

    End Function

    ' Funcion que actualiza el arreglo de sobredimensiones
    <WebMethod()> _
    Public Function WM_UpdateEIROverSizes(ByVal aint_EIR As Integer, ByVal aDtTB_OverSizeOperation As DataTable, ByVal astr_UserName As String) As String

        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        Dim lint_operation As Integer = 0
        Dim lparamGeneric As OleDbParameter = New OleDbParameter()

        Dim lint_EIROverSizeID As Integer
        Dim lint_PositionTypeID As Integer
        Dim ldec_Quantity As Decimal


        Dim lstr_SQL As String
        Dim lstr_Message As String = ""
        Dim lint_itemscount As Integer = 0
        Dim lstr_Date As String

        Dim lint_DeletedItems As Integer = 0
        Dim lint_InserttedItems As Integer = 0
        Dim lint_ModifiedItems As Integer = 0


        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()

        '' Return aDtTB_SealsOperation.Rows.Count.ToString()
        '' iterar por la tabla de operaciones 

        For Each lrow As DataRow In aDtTB_OverSizeOperation.Rows

            lint_itemscount = lint_itemscount + 1
            ioleconx_conexion = New OleDbConnection()
            ioleconx_conexion.ConnectionString = istr_conx
            iolecmd_comand = ioleconx_conexion.CreateCommand()

            'limpiar cadena sql
            lstr_SQL = ""
            'limpiar comando
            iolecmd_comand.Parameters.Clear()

            'obtener el numero del sello
            lint_EIROverSizeID = lrow("intEIRContainerOversizeId")
            lint_PositionTypeID = lrow("intContainerPositionId")
            ldec_Quantity = lrow("decEIRContainerOverQuantity")
            lstr_Date = lrow("dtmEIRContOverLastModified")


            'ver que es lo que se va a hacer 
            lint_operation = lrow("IntOperationType")
            Select Case lint_operation
                Case 1
                    'insercion   1
                    'agregar parametros


                    iolecmd_comand.Parameters.Add("@intEIRId", OleDbType.Integer)
                    iolecmd_comand.Parameters.Add("@intContainerPositionId", OleDbType.Integer)
                    iolecmd_comand.Parameters.Add("decEIRContDamQuantity", OleDbType.Decimal)
                    iolecmd_comand.Parameters.Add("strUser", OleDbType.Char)

                    iolecmd_comand.Parameters("@intEIRId").Value = aint_EIR
                    iolecmd_comand.Parameters("@intContainerPositionId").Value = lint_PositionTypeID
                    iolecmd_comand.Parameters("decEIRContDamQuantity").Value = ldec_Quantity
                    iolecmd_comand.Parameters("strUser").Value = astr_UserName

                    'definir la cadena sql
                    lstr_SQL = "spAddEIROverHH"
                    'definir que tipo de comando se va a ejecutar
                    iolecmd_comand.CommandType = CommandType.StoredProcedure
                    lint_InserttedItems = lint_InserttedItems + 1

                Case 2
                    'edicion      2

                    'validar que no exista ya esa sobredimension, no va a ser necesario, en el formulario se valida
                    'IF NOT EXISTS(SELECT intEIRContainerOversizeId FROM tblclsEIRContainerOversize WHERE intEIRId = @intEIRId and intContainerPositionId = @intContainerPositionId)

                    'definir la cadena sql                    

                    lstr_SQL = " UPDATE tblclsEIRContainerOversize " & _
                               " SET	intContainerPositionId =  ? ," & _
                               " 	decEIRContainerOverQuantity = ? ," & _
                               " 	dtmEIRContOverLastModified = ? , " & _
                               " 	strEIRContOverLastModifiedBy =  ? " & _
                               " WHERE intEIRId = ? " & _
                               " AND intEIRContainerOversizeId = ? "


                    'agregar parametros                            
                    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
                    iolecmd_comand.Parameters.Add("@intContPositionId", OleDbType.Integer)
                    iolecmd_comand.Parameters.Add("@decOverQuantity", OleDbType.Decimal)
                    iolecmd_comand.Parameters.Add("@strTimeLastModified", OleDbType.Char)
                    iolecmd_comand.Parameters.Add("@strUserId", OleDbType.Char)
                    iolecmd_comand.Parameters.Add("@intEIRId", OleDbType.Integer)
                    iolecmd_comand.Parameters.Add("@intOverSizeId", OleDbType.Integer)

                    iolecmd_comand.Parameters("@intContPositionId").Value = lint_PositionTypeID
                    iolecmd_comand.Parameters("@decOverQuantity").Value = ldec_Quantity
                    iolecmd_comand.Parameters("@strTimeLastModified").Value = lstr_Date
                    iolecmd_comand.Parameters("@strUserId").Value = astr_UserName
                    iolecmd_comand.Parameters("@intEIRId").Value = aint_EIR
                    iolecmd_comand.Parameters("@intOverSizeId").Value = lint_EIROverSizeID

                    'definir que tipo de comando se va a ejecutar
                    iolecmd_comand.CommandType = CommandType.Text
                    lint_ModifiedItems = lint_ModifiedItems + 1

                Case 3
                    'eliminacion   3

                    iolecmd_comand.Parameters.Clear()

                    lstr_SQL = "  DELETE tblclsEIRContainerOversize " & _
                    " WHERE  intEIRId = ? " & _
                    " AND intEIRContainerOversizeId  = ? "

                    iolecmd_comand.Parameters.Add("@intEIRId", OleDbType.Integer)
                    iolecmd_comand.Parameters.Add("@intEIRontainerOversizeId", OleDbType.Integer)

                    iolecmd_comand.Parameters("@intEIRId").Value = aint_EIR
                    iolecmd_comand.Parameters("@intEIRontainerOversizeId").Value = lint_EIROverSizeID

                    iolecmd_comand.CommandType = CommandType.Text

                    lint_ModifiedItems = lint_ModifiedItems + 1
                Case Else

            End Select

            iolecmd_comand.CommandText = lstr_SQL
            'Return lstr_SQL
            'ejecutar la accion
            ' si el tipo de operacion esta entre 1 y 3
            Try
                ''conectar
                iolecmd_comand.Connection.Open()
                iolecmd_comand.ExecuteNonQuery()
                ''desconectar
            Catch ex As Exception
                lstr_Message = ObtenerError(ex.Message, 9999)
                If lstr_Message.Length > 0 Then
                    Return lstr_Message
                Else
                    Return ex.Message
                End If
            Finally
                ioleconx_conexion.Close()
                iolecmd_comand.Connection.Close()

                ioleconx_conexion.Dispose()
                iolecmd_comand.Connection.Dispose()


            End Try
            ' Return lint_itemscount.ToString()
        Next
        ' lstr_Message = "Insertados =" + lint_InserttedItems.ToString() + " Modificados=" + lint_ModifiedItems.ToString() + " Eliminados=" + lint_DeletedItems.ToString()

        ioleconx_conexion = Nothing
        iolecmd_comand = Nothing

        Return lstr_Message

        Return ""

    End Function


    ' Funcion que retorna los IMOS asociados a un contenedor

    ''obtener los IMOS DE UN EIR
    <WebMethod()> _
    Public Function WMdt_GetEIRIMOS(ByVal aint_EIR As Integer) As DataTable

        Dim ldt_IMOsresult As DataTable 'tabla que guardara los sellos
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        Dim strSQL As String

        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()

        ldt_IMOsresult = New DataTable("tblclsEIRIMO")

        Try
            strSQL = " SELECT tblIMOCode_EIR.intIMOCodeId," & _
                     " 	 strIMOCodeIdentifier," & _
                     " strIMOCodeIdentifier + ' - '+ strIMOCodeDescription  as strIMOCodeDescription " & _
                     " FROM tblIMOCode_EIR " & _
                     "   INNER JOIN tblclsIMOCode ON tblIMOCode_EIR.intIMOCodeId = tblclsIMOCode.intIMOCodeId" & _
                     " WHERE tblIMOCode_EIR.intEIRId =" & Convert.ToString(aint_EIR)

            iolecmd_comand.CommandText = strSQL

            iAdapt_comand.SelectCommand = iolecmd_comand
            iAdapt_comand.Fill(ldt_IMOsresult)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            If strError.Length = 0 Then
                strError = ex.Message
            End If
            Return dt_RetrieveErrorTable(strError)
        Finally
            iAdapt_comand.SelectCommand.Connection.Close()
            ioleconx_conexion.Close()

            iAdapt_comand.SelectCommand.Connection.Dispose()
            ioleconx_conexion.Dispose()

        End Try

        iAdapt_comand = Nothing
        ioleconx_conexion = Nothing

        Return ldt_IMOsresult

    End Function

    '' obtener el catagolo de IMOS


    <WebMethod()> _
    Public Function WMdt_GetIMOTypes() As DataTable

        Dim ldt_IMOTyperesult As DataTable 'tabla que obtiene el 
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        Dim strSQL As String
        Dim ldrow_new As DataRow

        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()

        ldt_IMOTyperesult = New DataTable("tblclsIMOCodeType")
        'iolecmd_comand.CommandTimeout = 999999

        Try
            strSQL = " SELECT intIMOCodeId,  " & _
                     " strIMOCodeIdentifier, " & _
                     " strIMOCodeIdentifier + ' - '+ strIMOCodeDescription  as strIMOCodeDescription " & _
                     " FROM tblclsIMOCode     " & _
                     " WHERE blnIMOCodeActive = 1 "

            iolecmd_comand.CommandText = strSQL

            iAdapt_comand.SelectCommand = iolecmd_comand
            iAdapt_comand.Fill(ldt_IMOTyperesult)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            If strError.Length = 0 Then
                strError = ex.Message
            End If
            Return dt_RetrieveErrorTable(strError)
        Finally
            iAdapt_comand.SelectCommand.Connection.Close()
            ioleconx_conexion.Close()

            iAdapt_comand.SelectCommand.Connection.Dispose()
            ioleconx_conexion.Dispose()
        End Try

        If ldt_IMOTyperesult.Rows.Count > 0 Then

            'insertar un registro vacio, para que seleccione 0 , en un principio

            ldrow_new = ldt_IMOTyperesult.NewRow()
            ldrow_new("intIMOCodeId") = -1
            ldrow_new("strIMOCodeIdentifier") = "NUEVO"
            ldrow_new("strIMOCodeDescription") = "NUEVO"


            ldt_IMOTyperesult.Rows.Add(ldrow_new)

        End If

        iAdapt_comand.SelectCommand = Nothing
        ioleconx_conexion = Nothing

        Return ldt_IMOTyperesult

    End Function

    ''''' metodo para buscar un IMO
    ''''
    <WebMethod()> _
    Public Function WM_FindIMOforEIR(ByVal aint_EIR As Integer, ByVal aint_IMOKey As Integer) As DataTable

        Dim ldtable_ResultIMO As DataTable = New DataTable("IMOResult")

        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        Dim lint_operation As Integer = 0
        Dim lparamGeneric As OleDbParameter = New OleDbParameter()

        Dim lstr_SQL As String
        Dim lstr_Message As String = ""
        Dim lint_itemscount As Integer = 0

        Dim lint_DeletedItems As Integer = 0
        Dim lint_InserttedItems As Integer = 0
        Dim lint_ModifiedItems As Integer = 0


        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()

        ''buscar el imo por query
        lstr_SQL = "  SELECT intIMOCodeId ,intEIRId " & _
                   "  FROM tblIMOCode_EIR " & _
                   "  WHERE tblIMOCode_EIR.intEIRId =  ? " & _
                   "  AND tblIMOCode_EIR.intIMOCodeId = ? "

        iolecmd_comand.Parameters.Add("@intEIRId", OleDbType.Integer)
        iolecmd_comand.Parameters.Add("@intMOKeyId", OleDbType.Integer)

        iolecmd_comand.Parameters("@intEIRId").Value = aint_EIR
        iolecmd_comand.Parameters("@intMOKeyId").Value = aint_IMOKey

        iolecmd_comand.CommandType = CommandType.Text
        iolecmd_comand.CommandText = lstr_SQL


        Try
            ''conectar
            iAdapt_comand.SelectCommand = iolecmd_comand
            iolecmd_comand.Connection.Open()
            iAdapt_comand.Fill(ldtable_ResultIMO)
            ''desconectar
        Catch ex As Exception
            lstr_Message = ObtenerError(ex.Message, 9999)
            If lstr_Message.Length > 0 Then
                Return dt_RetrieveErrorTable(lstr_Message)
            Else
                Return dt_RetrieveErrorTable(ex.Message)
            End If
        Finally
            iAdapt_comand.SelectCommand.Connection.Close()
            ioleconx_conexion.Close()
            iolecmd_comand.Connection.Close()

            iAdapt_comand.SelectCommand.Connection.Dispose()
            ioleconx_conexion.Dispose()
            iolecmd_comand.Connection.Dispose()

        End Try

        iAdapt_comand = Nothing
        ioleconx_conexion = Nothing
        iolecmd_comand = Nothing

        Return ldtable_ResultIMO

    End Function

    '' actualizar los IMOS
    <WebMethod()> _
  Public Function WM_UpdateEIRIMO(ByVal aint_EIR As Integer, ByVal aDtTB_IMOsOperation As DataTable, ByVal astr_UserName As String) As String

        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        Dim lint_operation As Integer = 0
        Dim lparamGeneric As OleDbParameter = New OleDbParameter()

        Dim lstr_IMOCodeDescription As String
        Dim lstr_IMOCodeIndetifier As String
        Dim lint_IMOCodeTypeID As Integer
        Dim lint_OriginalIMOCodeTypeID As Integer


        Dim lstr_SQL As String
        Dim lstr_Message As String = ""
        Dim lint_itemscount As Integer = 0
        Dim lstr_User As String
        Dim lstr_Date As String

        Dim lint_DeletedItems As Integer = 0
        Dim lint_InserttedItems As Integer = 0
        Dim lint_ModifiedItems As Integer = 0

        Dim ldt_FoundIMO As DataTable = New DataTable("IMOResult")


        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()

        ' Return aDtTB_SealsOperation.Rows.Count.ToString()
        For Each lrow As DataRow In aDtTB_IMOsOperation.Rows


            lint_itemscount = lint_itemscount + 1

            iAdapt_comand = New OleDbDataAdapter()
            ioleconx_conexion = New OleDbConnection()
            istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
            ioleconx_conexion.ConnectionString = istr_conx

            iolecmd_comand = ioleconx_conexion.CreateCommand()

            'limpiar cadena sql
            lstr_SQL = ""
            'limpiar comando
            iolecmd_comand.Parameters.Clear()

            'obtener el numero de IMO
            lint_IMOCodeTypeID = lrow("intIMOCodeId")
            lstr_IMOCodeIndetifier = lrow("strIMOCodeIdentifier")
            lstr_IMOCodeDescription = lrow("strIMOCodeDescription")
            lint_OriginalIMOCodeTypeID = lrow("intOriginalIMOCodeId")


            'ver que es lo que se va a hacer 
            lint_operation = lrow("IntOperationType")
            Select Case lint_operation
                Case 1
                    'insercion   1
                    'agregar parametros

                    iolecmd_comand.Parameters.Add("@intEIRId", OleDbType.Integer)
                    iolecmd_comand.Parameters.Add("@strIMOCodeIdentifier", OleDbType.Char)

                    iolecmd_comand.Parameters("@intEIRId").Value = aint_EIR
                    iolecmd_comand.Parameters("@strIMOCodeIdentifier").Value = lstr_IMOCodeIndetifier

                    'definir la cadena sql
                    lstr_SQL = "spAddEIRIMO"
                    'definir que tipo de comando se va a ejecutar
                    iolecmd_comand.CommandType = CommandType.StoredProcedure
                    lint_InserttedItems = lint_InserttedItems + 1

                Case 2


                    '''' buscar si ya existe ese IMO
                    ldt_FoundIMO = WM_FindIMOforEIR(aint_EIR, lint_IMOCodeTypeID)

                    If ldt_FoundIMO.Rows.Count > 0 Then

                        If ldt_FoundIMO.Columns(0).ColumnName = "Error" Then
                            Return ldt_FoundIMO(0)(0).ToString()
                        End If

                        Return "El imo " + lstr_IMOCodeIndetifier + "ya existe para el EIR"

                    End If

                    'edicion      2

                    'definir la cadena sql      
                    lstr_SQL = " UPDATE tblIMOCode_EIR " & _
                    " SET  intIMOCodeId = ? " & _
                    " WHERE intEIRId = ? " & _
                    " AND intIMOCodeId  = ? "

                    'agregar parametros                            
                    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

                    iolecmd_comand.Parameters.Add("@intIMOCodeIdType", OleDbType.Integer)
                    iolecmd_comand.Parameters.Add("@intEIRId", OleDbType.Integer)
                    iolecmd_comand.Parameters.Add("@intIMOCodeIdKey", OleDbType.Integer)

                    iolecmd_comand.Parameters("@intIMOCodeIdType").Value = lint_IMOCodeTypeID
                    iolecmd_comand.Parameters("@intEIRId").Value = aint_EIR
                    iolecmd_comand.Parameters("@intIMOCodeIdKey").Value = lint_OriginalIMOCodeTypeID

                    'definir que tipo de comando se va a ejecutar
                    iolecmd_comand.CommandType = CommandType.Text
                    lint_ModifiedItems = lint_ModifiedItems + 1

                Case 3
                    'eliminacion   3

                    iolecmd_comand.Parameters.Clear()

                    lstr_SQL = "DELETE tblIMOCode_EIR " & _
                    " WHERE tblIMOCode_EIR.intEIRId = ? " & _
                    " AND tblIMOCode_EIR.intIMOCodeId = ? "


                    iolecmd_comand.Parameters.Add("@intEIRId", OleDbType.Integer)
                    iolecmd_comand.Parameters.Add("@intEIRIMOKey", OleDbType.Integer)

                    iolecmd_comand.Parameters("@intEIRId").Value = aint_EIR
                    iolecmd_comand.Parameters("@intEIRIMOKey").Value = lint_IMOCodeTypeID

                    iolecmd_comand.CommandType = CommandType.Text

                    lint_ModifiedItems = lint_ModifiedItems + 1
                Case Else

            End Select

            iolecmd_comand.CommandText = lstr_SQL
            'Return lstr_SQL
            'ejecutar la accion
            ' si el tipo de operacion esta entre 1 y 3
            Try
                ''conectar
                iolecmd_comand.Connection.Open()
                iolecmd_comand.ExecuteNonQuery()
                ''desconectar
            Catch ex As Exception
                lstr_Message = ObtenerError(ex.Message, 9999)
                If lstr_Message.Length > 0 Then
                    Return lstr_Message
                Else
                    Return ex.Message
                End If
            Finally
                ioleconx_conexion.Close()
                iolecmd_comand.Connection.Close()

                ioleconx_conexion.Dispose()
                iolecmd_comand.Connection.Dispose()

            End Try
            ' Return lint_itemscount.ToString()
        Next

        ioleconx_conexion = Nothing
        iolecmd_comand.Connection = Nothing

        ' lstr_Message = "Insertados =" + lint_InserttedItems.ToString() + " Modificados=" + lint_ModifiedItems.ToString() + " Eliminados=" + lint_DeletedItems.ToString()
        Return lstr_Message

        Return ""

    End Function


    <WebMethod()> _
   Public Function WMdt_FindVisitByContainer(ByVal astr_ContainerId As String, ByVal aint_InOutMode As Integer) As Data.DataTable

        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        Dim lstr_Query As String = ""

        Dim lstr_MODE As String = ""
        '1 REC, 2 ENT

        '' tabla de retorno 
        Dim ldt_VisitData As DataTable = New DataTable("VisitData")


        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand

        Select Case aint_InOutMode
            Case 1
                lstr_MODE = "REC"

            Case 2
                lstr_MODE = "ENT"
            Case Else
                lstr_MODE = "REC"

        End Select

        '--------------------------------------
        '-------- query

        lstr_Query = " SELECT tblclsVisitContainer.intVisitId, " & _
                     " tblclsVisit.dtmVisitDatetimeIn, " & _
                     " tblclsVisit.dtmVisitDatetimeOut, " & _
                     " tblclsVisitContainer.strContainerId, " & _
                     " tblclsVisitContainer.intContainerUniversalId  " & _
                     " FROM tblclsVisit " & _
                     " INNER JOIN tblclsVisitContainer ON tblclsVisit.intVisitId = tblclsVisitContainer.intVisitId " & _
                     " WHERE tblclsVisitContainer.strContainerId = ? " & _
                     " AND tblclsVisit.intSOStatusId <=2 " & _
                     " AND " & _
                     "( " & _
                     "  (   ? = 'REC' " & _
                     "    AND  ISNULL(tblclsVisitContainer.intContainerUniversalId,0)=0 " & _
                     "    AND  ISNULL(tblclsVisit.dtmVisitDatetimeIn,'19000101 00:00') = '19000101 00:00' " & _
                     "   ) " & _
                     "  OR " & _
                     "   (      " & _
                     "      ? = 'ENT' " & _
                     "      AND  ISNULL(tblclsVisitContainer.intContainerUniversalId,0)>0 " & _
                     "    AND  ISNULL(tblclsVisit.dtmVisitDatetimeOut,'19000101 00:00') = '19000101 00:00' " & _
                     "   ) " & _
                     " ) "


        '' se van a definir parametros con tipo
        oleDBcom.Parameters.Add("@strContainerId", OleDbType.Char)
        oleDBcom.Parameters.Add("@strServiceIdA", OleDbType.Char)
        oleDBcom.Parameters.Add("@strServiceIdB", OleDbType.Char)

        oleDBcom.Parameters("@strContainerId").Value = astr_ContainerId
        oleDBcom.Parameters("@strServiceIdA").Value = lstr_MODE
        oleDBcom.Parameters("@strServiceIdB").Value = lstr_MODE

        oleDBcom.CommandText = lstr_Query
        oleDBcom.CommandType = CommandType.Text


        Dim adapter As OleDbDataAdapter = New OleDbDataAdapter(oleDBcom)

        Try
            oleDBconnx.Open()
            adapter.Fill(ldt_VisitData)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            '' si obtuvo error
            If Len(strError) < 1 Then
                strError = ex.Message
            End If
            ''retornar el error encapsulado en tabla
            Return dt_RetrieveErrorTable(strError)

        Finally
            adapter.SelectCommand.Connection.Close()
            oleDBconnx.Close()

            adapter.SelectCommand.Connection.Dispose()
            oleDBconnx.Dispose()

        End Try

        '-----------------------
        adapter = Nothing
        oleDBconnx = Nothing

        Return ldt_VisitData
    End Function

    <WebMethod()> _
    Public Function WMdt_GetTemperatureMeasures() As Data.DataTable
        Dim ldt_ReturnTable As DataTable = New DataTable("TemperatureMeassures")

        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        Dim lstr_Query As String = ""
        Dim ladpt_adapter As OleDbDataAdapter = New OleDbDataAdapter()

        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand

        lstr_Query = "	SELECT 	 MSUNIT.intMeasureUnitId," & _
                     " 	 MSUNIT.strMeasureUnitIdentifier," & _
                     " 	 MSUNIT.strMeasureUnitDescription,	" & _
                     " 	 CASE strMeasureUnitDescription  WHEN 'CELCIUS' THEN 'C'" & _
                     "                                   WHEN 'FARENHEIT' THEN 'F'" & _
                     " 	 END  AS lstrDisplayLetter	 " & _
                     " 	FROM  tblclsMeasurementUnit MSUNIT " & _
                     " 	WHERE strMeasureUnitDescription IN ('CELCIUS','FARENHEIT')"

        oleDBcom.CommandText = lstr_Query
        oleDBcom.CommandType = CommandType.Text

        ladpt_adapter.SelectCommand = oleDBcom

        Try
            ladpt_adapter.Fill(ldt_ReturnTable)
        Catch ex As Exception
            Return ldt_ReturnTable
        Finally
            ladpt_adapter.SelectCommand.Connection.Close()
            oleDBconnx.Close()

            ladpt_adapter.SelectCommand.Connection.Dispose()
            oleDBconnx.Dispose()

        End Try

        ladpt_adapter = Nothing
        oleDBconnx = Nothing

        Return ldt_ReturnTable
    End Function


    <WebMethod()> _
   Public Function WMstr_UpdateEIRTemperature(ByVal aint_EIRNumber As Integer, ByVal adec_Temperature As Double, ByVal aint_MeassureId As Integer) As String

        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        Dim lstr_Query As String = ""


        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand

        lstr_Query = " UPDATE tblclsEIR " & _
                     " SET decContainerInvOptTemp = ? ,  " & _
                     " intContainerInvTempMeasu = ? " & _
                     " WHERE intEIRId  =  ? "

        oleDBcom.Parameters.Add("@decTemperature", OleDbType.Decimal)
        oleDBcom.Parameters.Add("@intTemperatureType", OleDbType.Integer)
        oleDBcom.Parameters.Add("@intEIRId", OleDbType.Integer)

        oleDBcom.Parameters("@decTemperature").Value = adec_Temperature
        oleDBcom.Parameters("@intTemperatureType").Value = aint_MeassureId
        oleDBcom.Parameters("@intEIRId").Value = aint_EIRNumber

        oleDBcom.CommandText = lstr_Query
        oleDBcom.CommandType = CommandType.Text

        Try
            oleDBcom.Connection.Open()
            oleDBcom.ExecuteNonQuery()
        Catch ex As Exception
            Return ex.Message
        Finally
            oleDBcom.Connection.Close()
            oleDBconnx.Close()

            oleDBcom.Connection.Dispose()
            oleDBconnx.Dispose()

        End Try

        Return ""
    End Function



    Public Function of_SearchItemFromTable(ByVal adtb_Table As DataTable, ByVal astr_ColumName As String, ByVal astr_Value As String)

        Dim lstr_readValue As String = ""
        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        Dim lstr_Query As String = ""


        '  // recorrer todos los renglones
        For lint_rowIdx As Integer = 0 To adtb_Table.Rows.Count - 1

            For lint_colIdx As Integer = 0 To adtb_Table.Columns.Count - 1

                If adtb_Table.Columns(lint_colIdx).ColumnName = astr_ColumName Then

                    lstr_readValue = ""

                    lstr_readValue = adtb_Table(lint_rowIdx)(lint_colIdx).ToString().ToUpper()

                    astr_Value = astr_Value.ToUpper()

                    '// si es igual retornar ese valor

                    If lstr_readValue = astr_Value Then
                        Return lint_rowIdx
                    End If

                End If

            Next

        Next

        Return -1
    End Function

    <WebMethod()> _
      Public Function WMdt_FindInfoVisitDeliveryByNumber(ByVal aint_VisitId As Integer) As Data.DataTable

        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        Dim oleADapter As OleDbDataAdapter = New OleDbDataAdapter()

        Dim strconx As String
        Dim lstr_Query As String = ""

        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()

        Dim ldt_VisitResult As DataTable = New DataTable("VisitInfo")
        Dim lstr_SQL As String = ""

        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()

        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand

        lstr_Query = "SELECT DISTINCT tblclsContainerDelivery.intContainerDeliveryId, " & _
                               "tblclsContainerDelivery.intContainerReservationId, " & _
                               "tblclsContainerDelivery.strBookingId, " & _
                               "tblclsContainerReservation.intContReservShippingLineId, " & _
                               "tblclsVisitContainer.intVisitId, " & _
                               "tblclsVisit.strVisitPlate, " & _
                               "tblclsContainerSize.strContainerSizeIdentifier, " & _
                               "tblclsContainerType.strContainerTypeIdentifier, " & _
                               "tblclsContainerCategory.strContainerCatIdentifier, " & _
                               "tblclsVisit.dtmVisitDatetimeIn, " & _
                               "tblclsVisit.dtmVisitDatetimeOut ," & _
                               "tblclsVisit.strVisitDriver ," & _
                               "tblclsCarrierLine.strCarrierLineIdentifier " & _
                          "FROM tblclsContainerDelivery, " & _
                               "tblclsServiceOrderStatus, " & _
                               "tblclsService, " & _
                               "tblclsContainerReservation " & _
                               "LEFT OUTER JOIN  tblclsContReservationDetail " & _
                                "ON tblclsContainerReservation.intContainerReservationId = tblclsContReservationDetail.intContainerReservationId " & _
                                "LEFT JOIN tblclsContainerType " & _
                                 "ON tblclsContReservationDetail.intContainerTypeId = tblclsContainerType.intContainerTypeId " & _
                                 "LEFT JOIN tblclsContainerSize " & _
                                  "ON tblclsContReservationDetail.intContainerSizeId = tblclsContainerSize.intContainerSizeId " & _
                                  "LEFT JOIN tblclsContainerCategory " & _
                                   "ON tblclsContReservationDetail.intContainerCategoryId = tblclsContainerCategory.intContainerCategoryId, " & _
                               "tblclsShippingLine, " & _
                               "tblclsCompany , " & _
                               "tblclsVisitContainer, " & _
                               "tblclsService as SERV, " & _
                               "tblclsVisit ," & _
                               "tblclsCarrierLine " & _
                       "WHERE ( tblclsContainerDelivery.intSOStatusId = tblclsServiceOrderStatus.intSOStatusId ) and " & _
                             "( tblclsContainerDelivery.intServiceId = tblclsService.intServiceId ) and " & _
                             "( tblclsContainerDelivery.intContainerReservationId = tblclsContainerReservation.intContainerReservationId ) and " & _
                             "( tblclsContainerReservation.intContReservShippingLineId = tblclsShippingLine.intShippingLineId ) and " & _
                             "( tblclsShippingLine.intCompanyId = tblclsCompany.intCompanyId ) and " & _
                             "( tblclsServiceOrderStatus.strSOStatusIdentifier = 'AUT' OR tblclsServiceOrderStatus.strSOStatusIdentifier = 'EJP') AND " & _
                             "( tblclsContainerDelivery.intContainerReservationId IS NOT NULL ) AND " & _
                             "( tblclsService.strServiceIdentifier = 'ENTV' ) and " & _
                               "tblclsVisitContainer.intServiceOrderId = tblclsContainerDelivery.intContainerDeliveryId AND " & _
                               "tblclsVisitContainer.intServiceId = SERV.intServiceId AND " & _
                               "tblclsVisit.intVisitId = tblclsVisitContainer.intVisitId AND " & _
                               "SERV.strServiceIdentifier = 'ENTV' AND " & _
                               "tblclsVisitContainer.blnVisitContainerIsCancelled = 0    AND " & _
                              "(tblclsVisitContainer.intContainerUniversalId = 0 OR " & _
                               "tblclsVisitContainer.intContainerUniversalId IS NULL ) " & _
                               "AND tblclsVisit.intSOStatusId NOT IN  ( SELECT tblclsServiceOrderStatus.intSOStatusId " & _
                                                                   "FROM tblclsServiceOrderStatus " & _
                                                                   "WHERE tblclsServiceOrderStatus.blnSOStatusActive = 1 " & _
                                                                   "and tblclsServiceOrderStatus.strSOStatusName   IN ('CANCELADA') ) " & _
                               "AND tblclsVisit.dtmVisitDatetimeIn IS NOT NULL AND tblclsVisit.dtmVisitDatetimeOut IS  NULL " & _
                               "AND tblclsCarrierLine.intCarrierLineId = tblclsVisit.intCarrierLineId " & _
                               "AND tblclsVisit.intVisitId = ?"


        oleDBcom.Parameters.Add("@intVisitId", OleDbType.Integer)

        oleDBcom.Parameters("@intVisitId").Value = aint_VisitId

        oleDBcom.CommandText = lstr_Query
        oleDBcom.CommandType = CommandType.Text


        Try
            oleADapter.SelectCommand = oleDBcom
            oleADapter.Fill(ldt_VisitResult)

            oleDBcom.Connection.Open()
            oleDBcom.ExecuteNonQuery()
        Catch ex As Exception

            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            '' si obtuvo error
            If Len(strError) < 1 Then
                strError = ex.Message
            End If
            ''retornar el error encapsulado en tabla
            Return dt_RetrieveErrorTable(strError)

        Finally
            oleADapter.SelectCommand.Connection.Close()
            oleDBcom.Connection.Close()
            oleDBconnx.Close()


            oleADapter.Dispose()
            oleDBcom.Dispose()
            oleDBconnx.Dispose()
        End Try


        oleADapter = Nothing
        oleDBcom = Nothing
        oleDBconnx = Nothing

        Return ldt_VisitResult

    End Function

    <WebMethod()> _
  Public Function WMdt_FindInfoVisitDeliveryByPlates(ByVal astr_Plates As String) As Data.DataTable

        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        Dim oleADapter As OleDbDataAdapter = New OleDbDataAdapter()

        Dim strconx As String
        Dim lstr_Query As String = ""

        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()

        Dim ldt_VisitResult As DataTable = New DataTable("VisitInfo")
        Dim lstr_SQL As String = ""

        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()

        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand

        lstr_Query = "SELECT DISTINCT tblclsContainerDelivery.intContainerDeliveryId, " & _
                                     "tblclsContainerDelivery.intContainerReservationId, " & _
                                     "tblclsContainerDelivery.strBookingId, " & _
                                     "tblclsContainerReservation.intContReservShippingLineId, " & _
                                     "tblclsVisitContainer.intVisitId, " & _
                                     "tblclsVisit.strVisitPlate, " & _
                                     "tblclsContainerSize.strContainerSizeIdentifier, " & _
                                     "tblclsContainerType.strContainerTypeIdentifier, " & _
                                     "tblclsContainerCategory.strContainerCatIdentifier, " & _
                                     "tblclsVisit.dtmVisitDatetimeIn, " & _
                                     "tblclsVisit.dtmVisitDatetimeOut, " & _
                                     "tblclsVisit.strVisitDriver ," & _
                                     "tblclsCarrierLine.strCarrierLineIdentifier " & _
                                "FROM tblclsContainerDelivery, " & _
                                     "tblclsServiceOrderStatus, " & _
                                     "tblclsService, " & _
                                     "tblclsContainerReservation " & _
                                     "LEFT OUTER JOIN  tblclsContReservationDetail " & _
                                      "ON tblclsContainerReservation.intContainerReservationId = tblclsContReservationDetail.intContainerReservationId " & _
                                      "LEFT JOIN tblclsContainerType " & _
                                       "ON tblclsContReservationDetail.intContainerTypeId = tblclsContainerType.intContainerTypeId " & _
                                       "LEFT JOIN tblclsContainerSize " & _
                                        "ON tblclsContReservationDetail.intContainerSizeId = tblclsContainerSize.intContainerSizeId " & _
                                        "LEFT JOIN tblclsContainerCategory " & _
                                         "ON tblclsContReservationDetail.intContainerCategoryId = tblclsContainerCategory.intContainerCategoryId, " & _
                                     "tblclsShippingLine, " & _
                                     "tblclsCompany , " & _
                                     "tblclsVisitContainer, " & _
                                     "tblclsService as SERV, " & _
                                     "tblclsVisit ," & _
                                     "tblclsCarrierLine " & _
                             "WHERE ( tblclsContainerDelivery.intSOStatusId = tblclsServiceOrderStatus.intSOStatusId ) and " & _
                                   "( tblclsContainerDelivery.intServiceId = tblclsService.intServiceId ) and " & _
                                   "( tblclsContainerDelivery.intContainerReservationId = tblclsContainerReservation.intContainerReservationId ) and " & _
                                   "( tblclsContainerReservation.intContReservShippingLineId = tblclsShippingLine.intShippingLineId ) and " & _
                                   "( tblclsShippingLine.intCompanyId = tblclsCompany.intCompanyId ) and " & _
                                   "( tblclsServiceOrderStatus.strSOStatusIdentifier = 'AUT' OR tblclsServiceOrderStatus.strSOStatusIdentifier = 'EJP') AND " & _
                                   "( tblclsContainerDelivery.intContainerReservationId IS NOT NULL ) AND " & _
                                   "( tblclsService.strServiceIdentifier = 'ENTV' ) and " & _
                                     "tblclsVisitContainer.intServiceOrderId = tblclsContainerDelivery.intContainerDeliveryId AND " & _
                                     "tblclsVisitContainer.intServiceId = SERV.intServiceId AND " & _
                                     "tblclsVisit.intVisitId = tblclsVisitContainer.intVisitId AND " & _
                                     "SERV.strServiceIdentifier = 'ENTV' AND " & _
                                     "tblclsVisitContainer.blnVisitContainerIsCancelled = 0    AND " & _
                                    "(tblclsVisitContainer.intContainerUniversalId = 0 OR " & _
                                     "tblclsVisitContainer.intContainerUniversalId IS NULL ) " & _
                                     "AND tblclsVisit.intSOStatusId NOT IN ( SELECT tblclsServiceOrderStatus.intSOStatusId " & _
                                                                     "FROM tblclsServiceOrderStatus " & _
                                                                     "WHERE tblclsServiceOrderStatus.blnSOStatusActive = 1 " & _
                                                                     "and tblclsServiceOrderStatus.strSOStatusName  IN ('CANCELADA') ) " & _
                                     "AND tblclsVisit.dtmVisitDatetimeIn IS NOT NULL AND tblclsVisit.dtmVisitDatetimeOut IS  NULL " & _
                                      "AND tblclsCarrierLine.intCarrierLineId = tblclsVisit.intCarrierLineId " & _
                                         "AND tblclsVisit.strVisitPlate = ? "



        oleDBcom.Parameters.Add("@strPlate", OleDbType.VarChar)

        oleDBcom.Parameters("@strPlate").Value = astr_Plates

        oleDBcom.CommandText = lstr_Query
        oleDBcom.CommandType = CommandType.Text


        Try
            oleADapter.SelectCommand = oleDBcom
            oleADapter.Fill(ldt_VisitResult)

            oleDBcom.Connection.Open()
            oleDBcom.ExecuteNonQuery()
        Catch ex As Exception

            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            '' si obtuvo error
            If Len(strError) < 1 Then
                strError = ex.Message
            End If
            ''retornar el error encapsulado en tabla
            Return dt_RetrieveErrorTable(strError)

        Finally
            oleADapter.SelectCommand.Connection.Close()
            oleDBcom.Connection.Close()
            oleDBconnx.Close()

            oleADapter.Dispose()
            oleDBcom.Connection.Dispose()
            oleDBconnx.Dispose()

        End Try

        Return ldt_VisitResult

    End Function

    <WebMethod()> _
    Public Function WMdt_GetReservationForVisit(ByVal aint_VisitId As Integer) As DataTable

        Dim ldt_Reservation As DataTable = New DataTable("ReservationVisit")
        Dim ldt_QueryResult As DataTable = New DataTable("Result")
        Dim ldrw_reservfiltrada As DataRow()

        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        Dim oleADapter As OleDbDataAdapter = New OleDbDataAdapter()

        Dim lstr_SQL As String = ""

        Dim strconx As String
        Dim lstr_Query As String = ""

        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()

        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()

        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand
        oleDBcom.CommandText = "spGetReservationsForVisit"
        oleDBcom.CommandType = CommandType.StoredProcedure

        oleDBcom.Parameters.Add("@intVisitid", OleDbType.Integer)
        oleDBcom.Parameters("@intVisitid").Value = aint_VisitId

        Try
            oleADapter.SelectCommand = oleDBcom
            oleADapter.Fill(ldt_QueryResult)

            oleDBcom.Connection.Open()
            oleDBcom.ExecuteNonQuery()
        Catch ex As Exception

            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            '' si obtuvo error
            If Len(strError) < 1 Then
                strError = ex.Message
            End If
            ''retornar el error encapsulado en tabla
            Return dt_RetrieveErrorTable(strError)

        Finally
            oleADapter.SelectCommand.Connection.Close()
            oleDBcom.Connection.Close()
            oleDBconnx.Close()

            oleADapter.SelectCommand.Connection.Dispose()
            oleDBcom.Connection.Dispose()
            oleDBconnx.Dispose()
        End Try


        ldt_Reservation.Columns.Add("Reservacion", System.Type.GetType("System.Int32"))
        ldt_Reservation.Columns.Add("Booking", System.Type.GetType("System.String"))
        ldt_Reservation.Columns.Add("Tipo-Tam", System.Type.GetType("System.String"))
        ldt_Reservation.Columns.Add("Linea", System.Type.GetType("System.String"))
        ldt_Reservation.Columns.Add("Pendientes", System.Type.GetType("System.Int32"))
        ldt_Reservation.Columns.Add("Reservados", System.Type.GetType("System.Int32"))
        ldt_Reservation.Columns.Add("Entregados", System.Type.GetType("System.Int32"))
        ldt_Reservation.Columns.Add("n_orden", System.Type.GetType("System.Int32"))

        Dim ldr_new As DataRow
        For Each drow As DataRow In ldt_QueryResult.Rows

            ldr_new = ldt_Reservation.NewRow

            ldr_new("Reservacion") = drow("RESERVACION")
            ldr_new("Booking") = drow("BOOKING")
            ldr_new("Tipo-Tam") = drow("TYPESIZE")
            ldr_new("Linea") = drow("LINEA")
            ldr_new("Pendientes") = drow("PENDIENTESVISITA")
            ldr_new("Reservados") = drow("RESERVADOS")
            ldr_new("Entregados") = drow("ENTREGADOSRESERV")
            ldr_new("n_orden") = drow("intContainerDeliveryId")

            ldt_Reservation.Rows.Add(ldr_new)
        Next


        ldrw_reservfiltrada = ldt_Reservation.Select("(Reservados - Entregados)<=0")

        For Each renglon As DataRow In ldrw_reservfiltrada
            ldt_Reservation.Rows.Remove(renglon)
        Next


        oleADapter = Nothing
        oleDBcom = Nothing
        oleDBconnx = Nothing

        Return ldt_Reservation

    End Function

    <WebMethod()> _
    Public Function WMdt_GetContainerListForReservation(ByVal aint_Reservation As Integer) As DataTable

        Dim ldt_ContainerReserv As DataTable
        Dim ldt_QueryResult As DataTable = New DataTable("Result")

        ldt_ContainerReserv = New DataTable("ContainerListForReservation")

        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        Dim oleADapter As OleDbDataAdapter = New OleDbDataAdapter()

        Dim lstr_SQL As String = ""

        Dim strconx As String
        Dim lstr_Query As String = ""

        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()

        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()

        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand
        oleDBcom.CommandText = "sp_find_continvreservation"
        oleDBcom.CommandType = CommandType.StoredProcedure

        oleDBcom.Parameters.Add("@int_ReservationId", OleDbType.Integer)
        oleDBcom.Parameters("@int_ReservationId").Value = aint_Reservation

        Try
            oleADapter.SelectCommand = oleDBcom
            oleADapter.Fill(ldt_QueryResult)

            oleDBcom.Connection.Open()
            oleDBcom.ExecuteNonQuery()
        Catch ex As Exception

            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            '' si obtuvo error
            If Len(strError) < 1 Then
                strError = ex.Message
            End If
            ''retornar el error encapsulado en tabla
            Return dt_RetrieveErrorTable(strError)

        Finally
            oleADapter.SelectCommand.Connection.Close()
            oleDBcom.Connection.Close()
            oleDBconnx.Close()

            oleADapter.SelectCommand.Connection.Dispose()
            oleDBcom.Connection.Dispose()
            oleDBconnx.Dispose()
        End Try

        ldt_ContainerReserv.Columns.Add("Entregar", System.Type.GetType("System.Int32"))
        'ldt_ContainerReserv.Columns.Add("Entregar", System.Type.GetType("System.Boolean"))
        ldt_ContainerReserv.Columns.Add("IdUniversal", System.Type.GetType("System.Int32"))
        ldt_ContainerReserv.Columns.Add("Contenedor", System.Type.GetType("System.String"))
        ldt_ContainerReserv.Columns.Add("Booking", System.Type.GetType("System.String"))
        ldt_ContainerReserv.Columns.Add("Temporal", System.Type.GetType("System.String"))
        ldt_ContainerReserv.Columns.Add("Naviera", System.Type.GetType("System.String"))
        ldt_ContainerReserv.Columns.Add("Ubicacion", System.Type.GetType("System.String"))
        ldt_ContainerReserv.Columns.Add("Estadia", System.Type.GetType("System.Int32"))
        ldt_ContainerReserv.Columns.Add("Fiscal", System.Type.GetType("System.String"))


        Dim ldr_new As DataRow
        For Each drow As DataRow In ldt_QueryResult.Rows

            ldr_new = ldt_ContainerReserv.NewRow

            ldr_new("Entregar") = 0
            ldr_new("IdUniversal") = drow("intContainerUniversalId")
            ldr_new("Contenedor") = drow("strContainerId")
            ldr_new("Booking") = drow("BK")
            ldr_new("Temporal") = IIf(IsDBNull(drow("Tempo")), "", drow("Tempo"))
            ldr_new("Naviera") = drow("strShippingLineIdentifier")
            ldr_new("Ubicacion") = drow("strContainerInvYardPositionId")
            ldr_new("Estadia") = drow("intDaysInTerminal")
            ldr_new("Fiscal") = drow("strContFisStatusIdentifier")

            ldt_ContainerReserv.Rows.Add(ldr_new)

        Next

        oleADapter = Nothing
        oleDBcom = Nothing
        oleDBconnx = Nothing

        Return ldt_ContainerReserv

    End Function

    <WebMethod()> _
    Public Function WMdt_GetDeliveredContainersToVisitReservation(ByVal aint_Visit_Id As Integer, ByVal aint_Reservation_Id As Integer) As DataTable

        Dim ldt_ContainerDelivered As DataTable
        Dim ldt_QueryResult As DataTable = New DataTable("result")

        ldt_ContainerDelivered = New DataTable("ContainerDelivered")

        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        Dim oleADapter As OleDbDataAdapter = New OleDbDataAdapter()

        Dim lstr_SQL As String = ""

        Dim strconx As String
        Dim lstr_Query As String = ""

        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()

        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()

        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand
        oleDBcom.CommandType = CommandType.Text
        oleDBcom.CommandText = "   SELECT  tblclsContainerInventory.intContainerUniversalId, " & _
                               "   tblclsContainerInventory.strContainerId , " & _
                               "   ( CASE ISNULL((SELECT MIN(BK.strBookingId)  " & _
                               "                 FROM tblclsContainerInvBooking BK " & _
                               "      WHERE BK.intContainerUniversalId = tblclsContainerInventory.intContainerUniversalId ), '0')  " & _
                               "      WHEN '0' THEN 'Sin BK'  " & _
                               "      WHEN '' THEN 'Sin BK'  " & _
                               "   ELSE (SELECT MIN(BK.strBookingId)  " & _
                               "         FROM tblclsContainerInvBooking BK   " & _
                               "         WHERE BK.intContainerUniversalId = tblclsContainerInventory.intContainerUniversalId)  " & _
                               "   END) As BK ,  " & _
                               "   (CASE  (SELECT MIN(BK.strBookingId)  " & _
                               "         FROM tblclsContainerInvBooking BK  " & _
                               "         WHERE(BK.intContainerUniversalId = tblclsContainerInventory.intContainerUniversalId) " & _
                               "           and BK.strBookingId = tblclsContainerReservation.strBookingId )  " & _
                               "       WHEN NULL THEN 0  " & _
                               "       WHEN '0' THEN 0  " & _
                               "       WHEN '' THEN 0  " & _
                               "       ELSE 1  " & _
                               "   END ) AS blnBKcorrect    , " & _
                               "  ( select max(strDocumentFolio) " & _
                               "    from  DocumentInventory_View " & _
                               "	where DocumentInventory_View.intContainerUniversalId = tblclsContainerInventory.intContainerUniversalId AND  " & _
                               "	strDocumentTypeIdentifier ='TEMP'  ) AS Tempo, " & _
                               "    tblclsShippingLine.strShippingLineIdentifier ,  " & _
                               "  ( CASE  ISNULL( tblclsContainerInventory.intContainerUniversalId, 0 )  " & _
                               "       WHEN 0 THEN 'SIN ESTATUS'  " & _
                               "     ELSE tblclsContainerFiscalStatus.strContFisStatusIdentifier  " & _
                               "    END ) AS strContFisStatusIdentifier  ,  " & _
                               "   DATEDIFF(dd, tblclsContainerInventory.dtmContainerInvReceptionDate, GETDATE() ) AS intDaysInTerminal , " & _
                               "   tblclsContainerInventory.strContainerInvYardPositionId  ,  " & _
                               "  (CASE WHEN EXISTS(select strDocumentFolio " & _
                               "   from DocumentInventory_View " & _
                               "    	where DocumentInventory_View.intContainerUniversalId = tblclsContainerInventory.intContainerUniversalId AND  " & _
                               "	       strDocumentTypeIdentifier ='TEMP' ) " & _
                               "   THEN 1  " & _
                               "     ELSE 0  " & _
                               "   END    ) as hastempo , " & _
                               " tblclsContainerReservation.intContainerReservationId " & _
                               "  FROM tblclsContainerInventory LEFT JOIN tblclsContainerFiscalStatus  " & _
                               "       ON tblclsContainerInventory.intContFisStatusId = tblclsContainerFiscalStatus.intContFisStatusId  " & _
                               "      left join tblclsShippingLine  " & _
                               "       on tblclsContainerInventory.intContainerInvOperatorId = tblclsShippingLine.intShippingLineId,  " & _
                               "  tblclsContainer,  " & _
                               "  tblclsContainerISOCode,  " & _
                               "  tblclsContainerAdmStatus,  " & _
                               "  tblclsContReservationDetail,  " & _
                               "  tblclsCustomerType,  " & _
                               "  tblclsContainerReservation,  " & _
                               "  tblclsService , " & _
                               "  tblContReserv_Inventory, " & _
                               "  tblclsVisitContainer " & _
                               "  WHERE(tblclsContainerInventory.strContainerId = tblclsContainer.strContainerId) " & _
                               "   AND ( tblclsContainer.intContISOCodeId = tblclsContainerISOCode.intContISOCodeId )  " & _
                               "   AND ( tblclsContainerInventory.intContAdmStatusId = tblclsContainerAdmStatus.intContAdmStatusId )  " & _
                               "   AND ( tblclsContainerInventory.intContainerInvOperatorTypeId = tblclsCustomerType.intCustomerTypeId )  " & _
                               "   AND ( tblclsContainerISOCode.intContainerTypeId  = tblclsContReservationDetail.intContainerTypeId) " & _
                               "   AND ( tblclsContainerISOCode.intContainerSizeId = tblclsContReservationDetail.intContainerSizeId) " & _
                               "   AND ( tblclsContainerReservation.intContainerReservationId = tblclsContReservationDetail.intContainerReservationId )  " & _
                               "   AND ( tblclsService.intServiceId = tblclsContainerReservation.intServiceId )  " & _
                               "   AND (    ( tblclsContainerInventory.intFiscalMovementId = 1)  " & _
                               "   OR ( tblclsService.strServiceIdentifier IN ('CONS', 'CONSD') )  " & _
                               "   OR ( ( tblclsContainerInventory.intFiscalMovementId = 2  " & _
                               "   and ( tblclsContainerInventory.intContainerInvVesselVoyageId = 0  " & _
                               "   OR tblclsContainerInventory.intContainerInvVesselVoyageId IS NULL ))))  " & _
                               "   AND ( tblclsContainerInventory.intContainerInvOperatorId =  tblclsContainerReservation.intContReservShippingLineId )  " & _
                               "   AND (  tblclsContainerInventory.blnContainerInvActive = 1 )  " & _
                               "   AND ( tblclsContainerInventory.blnContainerIsFull = 0 )  " & _
                               "   AND ( tblclsContainerAdmStatus.strContAdmStatusIdentifier = 'PATIO'  " & _
                               "   or tblclsContainerAdmStatus.strContAdmStatusIdentifier = 'LIBSAL'  " & _
                               "   or (  ( tblclsService.strServiceIdentifier IN ('CONS', 'CONSD')  )  " & _
                               "   and ( tblclsContainerAdmStatus.strContAdmStatusIdentifier IN ('PATIO','LIBSAL','PTRAS') ) ) )  " & _
                               "   AND ( tblclsContainerInventory.intContainerUniversalId = tblContReserv_Inventory.intContainerUniversalId ) " & _
                               "   AND ( tblclsContReservationDetail.intContainerReservationId  = tblContReserv_Inventory.intContainerReservationId) " & _
                               "   AND ( tblclsVisitContainer.intContainerUniversalId = tblclsContainerInventory.intContainerUniversalId) " & _
                               "   AND ( tblclsContReservationDetail.intContainerReservationId =  ? )  " & _
                               "   AND ( tblclsVisitContainer.intVisitId = ? ) " & _
                               "   AND ( tblclsCustomerType.strCustomerTypeIdentifier = 'SHIPPINGLINE' )  " & _
                               "   AND  tblclsContainerInventory.intContainerCategoryId = tblclsContReservationDetail.intContainerCategoryId  " & _
                               "   ORDER BY blnBKcorrect desc, hastempo DESC, intDaysInTerminal DESC, " & _
                               "    tblclsContainerInventory.strContainerInvBlockIdentifier ASC, " & _
                               "   tblclsContainerInventory.strContainerInvPosBay ASC, tblclsContainerInventory.strContainerInvPosRow ASC,  " & _
                               "   tblclsContainerInventory.strContainerInvPosStow "

        oleDBcom.Parameters.Add("@int_ReservationId", OleDbType.Integer)
        oleDBcom.Parameters("@int_ReservationId").Value = aint_Reservation_Id

        oleDBcom.Parameters.Add("@intVisit_Id", OleDbType.Integer)
        oleDBcom.Parameters("@intVisit_Id").Value = aint_Visit_Id

        Try
            oleADapter.SelectCommand = oleDBcom
            oleDBcom.Connection.Open()

            oleADapter.Fill(ldt_QueryResult)

            'oleDBcom.ExecuteNonQuery()
        Catch ex As Exception

            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            '' si obtuvo error
            If Len(strError) < 1 Then
                strError = ex.Message
            End If
            ''retornar el error encapsulado en tabla
            Return dt_RetrieveErrorTable(strError)

        Finally
            oleADapter.SelectCommand.Connection.Close()
            oleDBcom.Connection.Close()
            oleDBconnx.Close()

            oleADapter.SelectCommand.Connection.Dispose()
            oleDBcom.Connection.Dispose()
            oleDBconnx.Dispose()

        End Try

        ldt_ContainerDelivered.Columns.Add("UniversalId", System.Type.GetType("System.Int64"))
        ldt_ContainerDelivered.Columns.Add("Reservacion", System.Type.GetType("System.Int64"))
        ldt_ContainerDelivered.Columns.Add("Contenedor", System.Type.GetType("System.String"))
        ldt_ContainerDelivered.Columns.Add("Temporal", System.Type.GetType("System.String"))
        ldt_ContainerDelivered.Columns.Add("Naviera", System.Type.GetType("System.String"))
        ldt_ContainerDelivered.Columns.Add("Ubicación", System.Type.GetType("System.String"))
        ldt_ContainerDelivered.Columns.Add("Estadía", System.Type.GetType("System.Int32"))
        ldt_ContainerDelivered.Columns.Add("Fiscal", System.Type.GetType("System.String"))
        'ldt_ContainerDelivered.Columns.Add("BK", System.Type.GetType("System.String"))
        'ldt_ContainerDelivered.Columns.Add("CorrectoBK", System.Type.GetType("System.Int32"))
        'ldt_ContainerDelivered.Columns.Add("iTieneTempo", System.Type.GetType("System.Int32"))

        Dim ldr_new As DataRow
        For Each drow As DataRow In ldt_QueryResult.Rows

            ldr_new = ldt_ContainerDelivered.NewRow

            ldr_new("UniversalId") = drow("intContainerUniversalId")
            ldr_new("Reservacion") = drow("intContainerReservationId")
            ldr_new("Contenedor") = drow("strContainerId")
            ldr_new("Temporal") = IIf(IsDBNull(drow("Tempo")), "", drow("Tempo"))
            ldr_new("Naviera") = drow("strShippingLineIdentifier")
            ldr_new("Ubicación") = drow("strContainerInvYardPositionId")
            ldr_new("Estadía") = drow("intDaysInTerminal")
            ldr_new("Fiscal") = drow("strContFisStatusIdentifier")

            ldt_ContainerDelivered.Rows.Add(ldr_new)

        Next

        oleADapter = Nothing
        oleDBcom = Nothing
        oleDBconnx = Nothing

        Return ldt_ContainerDelivered

    End Function

    <WebMethod()> _
  Public Function WMdt_DeliverEmptyContainerToVisit(ByVal aint_Visit_Id As Integer, ByVal aint_Reservation_Id As Integer, ByVal adtbl_Table As DataTable, ByVal astr_UserName As String) As String

        Dim lstr_InsertResult As String = ""
        Dim lstr_DeliveryResult As String = ""

        '' primero asignar a la visita 
        lstr_InsertResult = of_InsertContainerInVisitToDelivey(aint_Visit_Id, aint_Reservation_Id, adtbl_Table, astr_UserName)
        If lstr_InsertResult.Length > 0 Then
            Return lstr_InsertResult
        End If

        '' luego entregar en la visita 
        lstr_DeliveryResult = of_DeliverContainersToVisit(aint_Visit_Id, adtbl_Table, astr_UserName)
        If lstr_DeliveryResult.Length > 0 Then
            Return lstr_DeliveryResult
        End If

        Return ""
    End Function

    Public Function of_InsertContainerInVisitToDelivey(ByVal aint_VisitId As Integer, ByVal aint_ReservationId As Integer, ByRef adtbl_Containers As DataTable, ByVal astr_Username As String)

        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        Dim oleADapter As OleDbDataAdapter = New OleDbDataAdapter()
        Dim lstr_SQL As String = ""
        Dim strconx As String
        Dim lint_error As Integer = 0
        Dim strError As String = ""

        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()

        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand
        oleDBcom.CommandType = CommandType.StoredProcedure

        lstr_SQL = "spInsertContInVisitReserv"
        oleDBcom.CommandText = lstr_SQL

        oleDBcom.Parameters.Add("@intVisitId", OleDbType.Integer)
        oleDBcom.Parameters.Add("@intVisitIdItem", OleDbType.Integer)
        oleDBcom.Parameters.Add("@intUniversalId", OleDbType.Integer)
        oleDBcom.Parameters.Add("@strContainerId", OleDbType.VarChar)
        oleDBcom.Parameters.Add("@User", OleDbType.VarChar)

        'recorrer la tabla de contenedores
        For lint_idxCont As Integer = 0 To adtbl_Containers.Rows.Count - 1

            oleDBcom = New OleDbCommand()
            oleDBconnx = New OleDbConnection()


            strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
            oleDBconnx.ConnectionString = strconx
            oleDBcom = oleDBconnx.CreateCommand
            oleDBcom.CommandType = CommandType.StoredProcedure

            lstr_SQL = "spInsertContInVisitReserv"
            oleDBcom.CommandText = lstr_SQL


            oleDBcom.Parameters("@intVisitId").Value = Convert.ToInt32(adtbl_Containers(lint_idxCont)("intVisitId"))
            oleDBcom.Parameters("@intVisitIdItem").Value = Convert.ToInt32(adtbl_Containers(lint_idxCont)("intVisitItemId"))
            oleDBcom.Parameters("@intUniversalId").Value = Convert.ToInt32(adtbl_Containers(lint_idxCont)("intContainerUniversalId"))
            oleDBcom.Parameters("@strContainerId").Value = adtbl_Containers(lint_idxCont)("strContainerId").ToString()
            oleDBcom.Parameters("@User").Value = astr_Username

            Try

                oleDBcom.Connection.Open()
                oleDBcom.ExecuteNonQuery()
            Catch ex As Exception

                strError = ObtenerError(ex.Message, 99999)
                '' si obtuvo error
                If Len(strError) < 1 Then
                    strError = ex.Message
                End If

                lint_error = 1
                'Return strError
                'salir del ciclo
                Exit For

            Finally

                oleDBcom.Connection.Close()
                oleDBconnx.Close()

                oleDBcom.Connection.Dispose()
                oleDBconnx.Dispose()
            End Try

            oleDBcom = Nothing
            oleDBconnx = Nothing

        Next

        If lint_error > 0 Then

            oleDBcom.CommandType = CommandType.Text
            lstr_SQL = " UPDATE  tblclsVisitContainer " & _
                       " SET strContainerId = ? ,  " & _
                       "     intContainerUniversalId = ? " & _
                       " WHERE intVisitId = ? " & _
                       " AND intVisitItemId = ? "

            oleDBcom.CommandText = lstr_SQL

            oleDBcom.Parameters.Add("@strContainerId", OleDbType.Char)
            oleDBcom.Parameters.Add("@intContainerUniversalId", OleDbType.Integer)
            oleDBcom.Parameters.Add("@intVisitId", OleDbType.Integer)
            oleDBcom.Parameters.Add("@intVisitItemId", OleDbType.Integer)

            For lint_codx As Integer = 0 To adtbl_Containers.Rows.Count - 1

                oleDBcom = New OleDbCommand()
                oleDBconnx = New OleDbConnection()

                oleDBconnx.ConnectionString = strconx
                oleDBcom = oleDBconnx.CreateCommand
                'oleDBcom.CommandType = CommandType.StoredProcedure
                oleDBcom.CommandType = CommandType.Text
                oleDBcom.CommandText = lstr_SQL

                oleDBcom.Parameters("@strContainerId").Value = ""
                oleDBcom.Parameters("@intContainerUniversalId").Value = 0
                oleDBcom.Parameters("@intVisitId").Value = aint_VisitId
                oleDBcom.Parameters("@intVisitItemId").Value = Convert.ToInt32(adtbl_Containers(lint_codx)("intVisitIdItem"))

                Try

                    oleDBcom.Connection.Open()
                    oleDBcom.ExecuteNonQuery()

                Catch ex As Exception
                    Return "of_InsertContainerInvisitToDelivery Idx(" + ")" + ex.Message
                    Exit For
                Finally
                    oleDBcom.Connection.Close()
                    oleDBconnx.Close()

                    oleDBcom.Connection.Dispose()
                    oleDBconnx.Dispose()


                End Try

                oleDBcom = Nothing
                oleDBconnx = Nothing


            Next

            'regresar la asignacion de los elementos a como estaban, o mejor decir ponerlos en 0s los registros 
            Return strError

        End If

        Return ""

    End Function

    Public Function of_DeliverContainersToVisit(ByVal aint_Visit As Integer, ByRef adtbl_Containers As DataTable, ByVal astr_User As String) As String

        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        Dim oleADapter As OleDbDataAdapter = New OleDbDataAdapter()
        Dim lstr_SQL As String = ""
        Dim strconx As String

        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()

        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand
        oleDBcom.CommandType = CommandType.StoredProcedure

        lstr_SQL = "spVisitContAsig"
        oleDBcom.CommandText = lstr_SQL

        oleDBcom.Parameters.Add("@UniversalId", OleDbType.Integer)
        oleDBcom.Parameters.Add("@intVisitId", OleDbType.Integer)
        oleDBcom.Parameters.Add("@User", OleDbType.VarChar)

        For lint_ContIdx As Integer = 0 To adtbl_Containers.Rows.Count - 1

            oleDBcom = New OleDbCommand()
            oleDBconnx = New OleDbConnection()

            strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
            oleDBconnx.ConnectionString = strconx
            oleDBcom = oleDBconnx.CreateCommand
            oleDBcom.CommandType = CommandType.StoredProcedure

            oleDBcom.CommandText = lstr_SQL

            oleDBcom.Parameters("@UniversalId").Value = Convert.ToInt32(adtbl_Containers(lint_ContIdx)("intContainerUniversalId"))
            oleDBcom.Parameters("@intVisitId").Value = Convert.ToInt32(adtbl_Containers(lint_ContIdx)("intVisitId"))
            oleDBcom.Parameters("@User").Value = astr_User

            Try

                oleDBcom.Connection.Open()
                oleDBcom.ExecuteNonQuery()
            Catch ex As Exception

                Dim strError As String
                strError = ObtenerError(ex.Message, 99999)

                '' si obtuvo error
                If Len(strError) < 1 Then
                    strError = ex.Message
                End If

                ''retornar el error encapsulado en tabla
                Return "-of_DeliverContainersToVisit(" + lint_ContIdx.ToString() + ")" + strError

            Finally
                oleDBcom.Connection.Close()
                oleDBconnx.Close()

                oleDBcom.Connection.Dispose()
                oleDBconnx.Dispose()
            End Try

            oleDBcom = Nothing
            oleDBconnx = Nothing
        Next

        Return ""

    End Function

    <WebMethod()> _
    Public Function WMdt_GetVisitItemsForReservation(ByVal aint_Visit_Id As Integer, ByVal aint_Reservation_Id As Integer) As DataTable

        Dim idt_result As DataTable = New DataTable ' Tabla con el query de resultados 
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion

        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()
        idt_result.TableName = "TrearDatos"

        Dim strSQL As String
        'Dim strcontainerid As String

        Try

            strSQL = " SELECT VC.intVisitId , " & _
                     "        VC.intVisitItemId, " & _
                     "        VC.intContainerUniversalId , " & _
                     "        VC.strContainerId, " & _
                     "        VC.intServiceOrderId, " & _
                     "        VC.blnVisitContainerIsCancelled " & _
                     " FROM tblclsVisitContainer VC " & _
                     "       INNER JOIN tblclsContainerDelivery DELY " & _
                     "      		 ON DELY.intContainerDeliveryId = VC.intServiceOrderId " & _
                     "		  	     AND VC.intServiceId= DELY.intServiceId " & _
                     "       INNER JOIN tblclsContainerReservation RESRV " & _
                     "  			 ON RESRV.intContainerReservationId =  DELY.intContainerReservationId  " & _
                     " WHERE(VC.intVisitId =  ? ) " & _
                     "   AND RESRV.intContainerReservationId = ? "

            iolecmd_comand.CommandText = strSQL

            '''' hay que agregar parametros a el comando

            iolecmd_comand.Parameters.Add("@intVisitId", OleDbType.Integer)
            iolecmd_comand.Parameters.Add("@intReservation", OleDbType.Integer)

            'especificar valores 
            iolecmd_comand.Parameters("@intVisitId").Value = aint_Visit_Id
            iolecmd_comand.Parameters("@intReservation").Value = aint_Reservation_Id

            iAdapt_comand.SelectCommand = iolecmd_comand
            'iAdapt_comand.SelectCommand.Connection.Open()

            iAdapt_comand.Fill(idt_result)

        Catch ex As Exception

            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            '' si obtuvo error
            If Len(strError) < 1 Then
                strError = ex.Message
            End If
            ''retornar el error encapsulado en tabla
            Return dt_RetrieveErrorTable(strError)
        Finally
            iAdapt_comand.SelectCommand.Connection.Close()
            ioleconx_conexion.Close()
            iolecmd_comand.Connection.Close()


        End Try

        iAdapt_comand = Nothing
        ioleconx_conexion = Nothing
        iolecmd_comand = Nothing

        Return idt_result

    End Function

    <WebMethod()> _
    Public Function WMdt_UpdateEIRMasterValues(ByVal aint_EIRid As Integer, ByVal adt_TableListValues As DataTable, ByVal astr_UserName As String) As String

        '' variables 
        Dim loleCmd_Command As OleDbCommand = New OleDbCommand()
        Dim loleCon_Conection As OleDbConnection = New OleDbConnection()
        Dim lstr_Query As String = ""
        Dim lstr_ConectionStr As String
        Dim lstr_Coma As String = ""

        lstr_ConectionStr = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        loleCon_Conection.ConnectionString = lstr_ConectionStr
        loleCmd_Command = loleCon_Conection.CreateCommand()

        Dim lstr_SQL As String
        Dim lstr_ColumName As String = ""
        Dim lstr_UpdateValue As String = ""
        Dim lstr_Sentence As String = ""

        ' si no hay valores salir del metodo 
        If adt_TableListValues.Rows.Count = 0 Then
            Return ""
        End If

        '' armar el query 
        lstr_Query = " UPDATE tblclsEIR  SET "
        For Each ldrow As DataRow In adt_TableListValues.Rows
            lstr_Query = lstr_Query + lstr_Coma
            lstr_ColumName = ldrow(0).ToString
            lstr_UpdateValue = ldrow(1).ToString

            lstr_Sentence = ""
            Select Case lstr_ColumName
                Case "CATEGORIAID"
                    lstr_Sentence = " intContainerCategoryId = " + lstr_UpdateValue + " "
                Case "TEMPVALUE"
                    lstr_Sentence = " decContainerInvOptTemp =   " + lstr_UpdateValue + " "
                Case "TEMPMEASURE"
                    lstr_Sentence = " intContainerInvTempMeasu =   " + lstr_UpdateValue + " "
                Case "COMMENTS"
                    lstr_Sentence = " strEIRComments  =   " + lstr_UpdateValue + " "
            End Select

            lstr_Coma = ","
            lstr_Query = lstr_Query + lstr_Sentence
        Next

        'agregar los campos de modificados
        lstr_Query = lstr_Query + lstr_Coma + " strEIRLastModifiedBy = " + "'" + astr_UserName + "'" + " "
        lstr_Query = lstr_Query + lstr_Coma + " dtmEIRLastModified  = GETDATE() "

        lstr_Query = lstr_Query + " WHERE intEIRId = ?"
        loleCmd_Command.CommandText = lstr_Query
        loleCmd_Command.CommandType = CommandType.Text

        loleCmd_Command.Parameters.Add("@intParameter", OleDbType.Integer)
        loleCmd_Command.Parameters("@intParameter").Value = aint_EIRid


        'ejecutar query
        Try
            loleCmd_Command.Connection.Open()
            loleCmd_Command.ExecuteNonQuery()

        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            Return strError
        Finally
            loleCmd_Command.Connection.Close()
            loleCon_Conection.Close()

            loleCmd_Command.Connection.Dispose()
            loleCon_Conection.Dispose()

        End Try

        loleCmd_Command = Nothing
        loleCon_Conection = Nothing

        Return ""
    End Function

    <WebMethod()> _
 Public Function WM_UpdateEIRComments(ByVal aint_EIR As Integer, ByVal astr_Coments As String, ByVal astr_Username As String) As String


        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion

        Dim lstr_SQL As String
        Dim lstr_Message As String = ""

        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()

        ''buscar el imo por query
        lstr_SQL = "   UPDATE tblclsEIR " & _
                   "   SET strEIRComments = ? " & _
                   "     ,strEIRLastModifiedBy = ?  " & _
                   "     ,dtmEIRLastModified = GETDATE() " & _
                   "   WHERE intEIRId = ? "

        iolecmd_comand.Parameters.Add("@strComments", OleDbType.VarChar)
        iolecmd_comand.Parameters.Add("@strUserName", OleDbType.VarChar)
        iolecmd_comand.Parameters.Add("@intEIRId", OleDbType.Integer)

        iolecmd_comand.Parameters("@strComments").Value = astr_Coments
        iolecmd_comand.Parameters("@strUserName").Value = astr_Username
        iolecmd_comand.Parameters("@intEIRId").Value = aint_EIR

        iolecmd_comand.CommandType = CommandType.Text
        iolecmd_comand.CommandText = lstr_SQL


        Try
            ''conectar
            iolecmd_comand.Connection.Open()
            iolecmd_comand.ExecuteNonQuery()
            iolecmd_comand.Connection.Close()

            ''desconectar
        Catch ex As Exception
            lstr_Message = ObtenerError(ex.Message, 9999)
            Return lstr_Message
        Finally
            iolecmd_comand.Connection.Close()
            ioleconx_conexion.Close()

            iolecmd_comand.Connection.Dispose()
            ioleconx_conexion.Dispose()

        End Try

        Return ""

    End Function

    <WebMethod()> _
  Public Function WMstr_GetEIRComments(ByVal aint_EIR As Integer) As String


        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim ioledbdt_Adapter As OleDbDataAdapter = New OleDbDataAdapter() ' adapatador
        Dim idtb_Result As DataTable = New DataTable() ' DataTable
        Dim istr_conx As String '' cadena de conexion

        Dim lstr_SQL As String
        Dim lstr_Message As String = ""

        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()

        ''buscar el imo por query
        lstr_SQL = " SELECT strEIRComments " & _
                   " FROM tblclsEIR " & _
                   " WHERE intEIRId =  ? "

        iolecmd_comand.Parameters.Add("@intEIRId", OleDbType.Integer)
        iolecmd_comand.Parameters("@intEIRId").Value = aint_EIR

        iolecmd_comand.CommandType = CommandType.Text
        iolecmd_comand.CommandText = lstr_SQL
        ioledbdt_Adapter.SelectCommand = iolecmd_comand


        Try
            ''conectar
            ioleconx_conexion.Open()
            ioledbdt_Adapter.Fill(idtb_Result)
            iolecmd_comand.Connection.Close()

            ''desconectar
        Catch ex As Exception
            lstr_Message = ObtenerError(ex.Message, 9999)
            lstr_Message = lstr_Message
            Return ""
        Finally
            ioledbdt_Adapter.SelectCommand.Connection.Close()
            ioleconx_conexion.Close()

            ioledbdt_Adapter.SelectCommand.Connection.Dispose()
            ioleconx_conexion.Dispose()
            iolecmd_comand.Dispose()
        End Try

        If idtb_Result.Rows.Count > 0 Then
            If idtb_Result.Columns.Count > 0 Then
                Return idtb_Result(0)(0)
            End If
        End If

        ioledbdt_Adapter = Nothing
        ioleconx_conexion = Nothing
        iolecmd_comand = Nothing

        Return ""

    End Function

    <WebMethod()> _
    Public Function WMdt_GetCategoryContainerList() As DataTable

        Dim ldtbl_Result As DataTable = New DataTable("CategoryList")
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim ioledbdt_Adapter As OleDbDataAdapter = New OleDbDataAdapter() ' adapatador
        Dim istr_conx As String '' cadena de conexion

        Dim lstr_SQL As String
        Dim lstr_Message As String = ""

        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()

        ''buscar el imo por query
        lstr_SQL = " SELECT intContainerCategoryId ," & _
                   " strContainerCatIdentifier " & _
                   " FROM tblclsContainerCategory "

        iolecmd_comand.CommandType = CommandType.Text
        iolecmd_comand.CommandText = lstr_SQL
        ioledbdt_Adapter.SelectCommand = iolecmd_comand


        Try
            ''conectar
            ioleconx_conexion.Open()
            ioledbdt_Adapter.Fill(ldtbl_Result)

            ''desconectar
        Catch ex As Exception

            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            '' si obtuvo error
            If Len(strError) < 1 Then
                strError = ex.Message
            End If
            ''retornar el error encapsulado en tabla
            Return dt_RetrieveErrorTable(strError)

        Finally
            ioledbdt_Adapter.SelectCommand.Connection.Close()
            ioleconx_conexion.Close()
            iolecmd_comand.Connection.Close()

            ioledbdt_Adapter.SelectCommand.Connection.Dispose()
            ioleconx_conexion.Dispose()
            iolecmd_comand.Connection.Dispose()


        End Try


        ioledbdt_Adapter = Nothing
        ioleconx_conexion = Nothing
        iolecmd_comand = Nothing

        Return ldtbl_Result

    End Function

    <WebMethod()> _
   Public Function WMdt_GetEIRMasterValues(ByVal aint_EIRid As Integer, ByVal adt_TableListValues As DataTable) As DataTable

        '' variables 
        Dim loleCmd_Command As OleDbCommand = New OleDbCommand()
        Dim loledbAdpt_Adapter As OleDbDataAdapter = New OleDbDataAdapter()
        Dim loleCon_Conection As OleDbConnection = New OleDbConnection()
        Dim ldt_Result As DataTable = New DataTable("MasterValues")
        Dim lstr_Query As String = ""
        Dim lstr_ConectionStr As String
        Dim lstr_Coma As String = ""

        lstr_ConectionStr = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        loleCon_Conection.ConnectionString = lstr_ConectionStr
        loleCmd_Command = loleCon_Conection.CreateCommand()

        Dim lstr_SQL As String
        Dim lstr_ColumName As String = ""
        Dim lstr_UpdateValue As String = ""
        Dim lstr_Sentence As String = ""

        ' si no hay valores salir del metodo 
        If adt_TableListValues.Rows.Count = 0 Then
            Return ldt_Result
        End If

        '' armar el query 
        lstr_Query = " SELECT "
        For Each ldrow As DataRow In adt_TableListValues.Rows
            'lstr_Query = lstr_Query + lstr_Coma
            lstr_ColumName = ldrow(0).ToString

            lstr_Sentence = ""
            Select Case lstr_ColumName
                Case "CATEGORIAID"
                    lstr_Sentence = lstr_Coma + " intContainerCategoryId "
                Case "TEMPVALUE"
                    lstr_Sentence = lstr_Coma + " decContainerInvOptTemp  "
                Case "TEMPMEASURE"
                    lstr_Sentence = lstr_Coma + " intContainerInvTempMeasu  "
                Case "COMMENTS"
                    lstr_Sentence = lstr_Coma + " strEIRComments  "
            End Select

            lstr_Query = lstr_Query + lstr_Sentence
            lstr_Coma = ","
        Next

        lstr_Query = lstr_Query + " FROM tblclsEIR WHERE intEIRId = ? "
        loleCmd_Command.CommandText = lstr_Query
        loleCmd_Command.CommandType = CommandType.Text

        loleCmd_Command.Parameters.Add("@intParameter", OleDbType.Integer)
        loleCmd_Command.Parameters("@intParameter").Value = aint_EIRid

        loledbAdpt_Adapter.SelectCommand = loleCmd_Command

        'ejecutar query
        Try
            loleCon_Conection.Open()
            loledbAdpt_Adapter.Fill(ldt_Result)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            Return dt_RetrieveErrorTable(strError)
        Finally
            loledbAdpt_Adapter.SelectCommand.Connection.Close()
            loleCon_Conection.Close()
            loleCmd_Command.Connection.Close()

            loledbAdpt_Adapter.SelectCommand.Connection.Dispose()
            loleCon_Conection.Dispose()
            loleCmd_Command.Connection.Dispose()

        End Try

        loledbAdpt_Adapter = Nothing
        loleCon_Conection = Nothing
        loleCmd_Command = Nothing

        Return ldt_Result
    End Function


    '' -- metodo web para prueba de narrow TDT 
    '' metodo proporcionado por luis 
    <WebMethod(Description:="Método que permite consultar información básica de un contenedor especifico")> _
    Public Function SearchContainer(ByVal strContainerId As String) As DataTable


        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()

        Dim strconx As String

        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand

        Dim ls_SQL_Command As String

        '----------------------------------

        Dim _ODBPar_ContainerId As New OleDbParameter("@strContainerId", OleDbType.VarChar)

        'redefinicion de parametros

        _ODBPar_ContainerId.Value = strContainerId
        ls_SQL_Command = "spFindYardContainer"



        ' asociacion de parametros al comando



        oleDBcom.Parameters.Add(_ODBPar_ContainerId)





        oleDBcom.CommandText = ls_SQL_Command

        oleDBcom.CommandType = CommandType.StoredProcedure

        Dim DataResult As DataTable = New Data.DataTable() 'DataSet = New DataSet()

        DataResult.TableName = "tblclsContainer"

        Dim adapter As OleDbDataAdapter = New OleDbDataAdapter(oleDBcom)



        Try

            oleDBconnx.Open()

            'oleDBcom.ExecuteNonQuery()

            adapter.Fill(DataResult)

        Catch ex As Exception

            Dim strError As String

            strError = ObtenerError(ex.Message, 99999)

        Finally

            oleDBconnx.Close()



        End Try

        'Dim N As Integer

        'N = P.Prueba.GetUpperBound(0)

        'P.Prueba(N) = "Prueba " + N + ", Contenedor" + strContainerId



        Return DataResult

    End Function

    <WebMethod(Description:="Método que permite cambiar de ubicacion contenedor especifico")> _
   Public Function WMdt_UpdateContainerPosition(ByVal astr_intcontaineruniversalid As String, ByVal lstrOriginalContYardPosition As String, ByVal lstr_Finalcontainerinvyardpositionid As String, ByVal lstrusername As String) As Integer
        ' se van a llamar dos metodos
        Dim lint_Resultvalue As Integer = 0
        Dim lstr_Coments As String

        ' actualiza historico
        lstr_Coments = "De " + lstrOriginalContYardPosition + " a " + lstr_Finalcontainerinvyardpositionid
        lint_Resultvalue = UpdateHistoryContPositionComs(astr_intcontaineruniversalid, lstr_Finalcontainerinvyardpositionid, lstrusername, lstr_Coments)

        ' actualiza inventario
        If lint_Resultvalue <> 1 Then
            lint_Resultvalue = UpdatePositionInventory(astr_intcontaineruniversalid, lstr_Finalcontainerinvyardpositionid, lstrusername)
        Else
            Return lint_Resultvalue
        End If

        Return lint_Resultvalue

    End Function


    <WebMethod()> _
    Public Function WMdt_GetImageFile(ByVal aint_ImageID As Integer) As DataTable

        Dim idt_result As DataTable = New DataTable ' Tabla con el query de resultados 
        Dim iAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim iolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim ioleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion

        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        ioleconx_conexion.ConnectionString = istr_conx
        iolecmd_comand = ioleconx_conexion.CreateCommand()
        idt_result.TableName = "TrearDatos"

        Dim strSQL As String
        'Dim strcontainerid As String

        Try


            strSQL = " SELECT * " & _
            " from tblclsDocument " & _
            " where(intDocumentId = ?) "

            iolecmd_comand.CommandText = strSQL

            '''' hay que agregar parametros a el comando

            iolecmd_comand.Parameters.Add("@ImageId", OleDbType.Integer)


            'especificar valores 
            iolecmd_comand.Parameters("@ImageId").Value = aint_ImageID


            iAdapt_comand.SelectCommand = iolecmd_comand
            'iAdapt_comand.SelectCommand.Connection.Open()

            iAdapt_comand.Fill(idt_result)

        Catch ex As Exception

            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            '' si obtuvo error
            If Len(strError) < 1 Then
                strError = ex.Message
            End If
            ''retornar el error encapsulado en tabla
            Return dt_RetrieveErrorTable(strError)
        Finally
            iAdapt_comand.SelectCommand.Connection.Close()
        End Try
        ''''''''''''''''''''''
        Dim lstr_byte As String
        Dim lbyte_Array As Byte()
        Dim lstr_Temp As String = TimeOfDay.ToString("HHmmss")
        Dim lstr_DecodeValue As String = ""

        lstr_Temp = Server.MapPath(".").ToString() + "\" + lstr_Temp + ".pdf"
        lstr_Temp = lstr_Temp

        Dim ldoc_Document As iTextSharp.text.Document = New iTextSharp.text.Document(iTextSharp.text.PageSize.LETTER)
        Dim lwriter As iTextSharp.text.pdf.PdfWriter = iTextSharp.text.pdf.PdfWriter.GetInstance(ldoc_Document, New System.IO.FileStream(lstr_Temp, System.IO.FileMode.Create))
        Dim lreader As iTextSharp.text.pdf.PdfReader
        Dim lByte_Arr() As Byte = DirectCast(idt_result(0)("imgDocumentImageFile"), Byte())

        Using ms As MemoryStream = New MemoryStream
            lreader = New iTextSharp.text.pdf.PdfReader(lByte_Arr)
            Dim pages As Integer = lreader.NumberOfPages
            ' PdfCopy copy = new PdfCopy(doc, ms);
            'PdfCopyFields copy2 = new PdfCopyFields(ms);



            '    // loop over document pages
            'For i = 1 To i < pages - 1
            '    Dim page As iTextSharp.text.pdf.PdfImportedPage = iTextSharp.t
            'Next

            '        PdfImportedPage page = copy.GetImportedPage(reader, i);
            '        PdfCopy.PageStamp stamp = copy.CreatePageStamp(page);
            '        PdfContentByte cb = stamp.GetUnderContent();
            '        cb.SaveState();
            '        stamp.AlterContents();
            '        copy.AddPage(page);

        End Using

        ldoc_Document.Open()

        Try
            If idt_result.Rows.Count > 0 Then
                Dim lobj = idt_result(0)("imgDocumentImageFile")
                lstr_byte = Convert.ToString(idt_result(0)("imgDocumentImageFile"))
                lbyte_Array = DirectCast(idt_result(0)("imgDocumentImageFile"), Byte())

                'lbyte_Array = DirectCast(of_base64Decode(lstr_byte), Byte())

                If lstr_byte.Length > 0 Then
                    'lbyte_Array = System.Convert.FromBase64String(lstr_byte.ToString())
                    File.WriteAllBytes(lstr_Temp, lobj)

                End If

            End If

        Catch ex As Exception
            Dim lstr_err = ex.Message
            lstr_err = lstr_err
        End Try

        ''''''''''''''''''''''''''

        Dim Doc As String = ""
        Dim PrntrStr As String = "Bullzip PDF Printer"
        Dim starter As New ProcessStartInfo
        Dim Process1 As New Process()

        Doc = "C:\HH-Buques.pdf"
        'this does not work:
        '        starter = New ProcessStartInfo("AcroRd32.exe", "/t " + Doc + " " + PrntrStr + "")

        'this works (to default printer)
        '        starter = New ProcessStartInfo("AcroRd32.exe", "/t " + Doc)
        starter = New ProcessStartInfo("AcroRd32.exe", "/t """ & Doc & """ """ & PrntrStr & """")

        Process1.StartInfo = starter
        Process1.Start()



        Return idt_result



    End Function

    ' 
    '  /////////////////////////////////////////////////////////////////'
    '  /////////////////////////////////////////////////////////////////'
    '  /////////////////////////////////////////////////////////////////'
    '  /////////////////////////////////////////////////////////////////'
    'fin  funciones codigo metodo de Javier  15-04-13
    '
    '  /////////////////////////////////////////////////////////////////'
    '  /////////////////////////////////////////////////////////////////'
    '  /////////////////////////////////////////////////////////////////'
    '  /////////////////////////////////////////////////////////////////'
    '  /////////////////////////////////////////////////////////////////'
    '  /////////////////////////////////////////////////////////////////'

    '<WebMethod()> _
    'Public Function print()
    '    Dim dsEIR As New DataSet
    '    Dim dtEIR As New DataTable
    '    Dim dtDamage As New DataTable
    '    Dim teir As New rptEIR
    '    Dim tDamage As New rptEIR
    '    Dim strEIRId As String = "902066"
    '    Dim connection As New OleDbConnection(ConfigurationManager.ConnectionStrings.Item("dbCalathus").ConnectionString)
    '    Dim str3 As String = ("exec spPrintEIR " & strEIRId)
    '    Dim strDamage As String = ("spGetDamage " & strEIRId)
    '    Dim command As New OleDb.OleDbCommand(str3, connection)
    '    Dim cmdDamage As New OleDb.OleDbCommand(strDamage, connection)
    '    Dim adapter As New OleDb.OleDbDataAdapter
    '    Dim adtDamage As New OleDb.OleDbDataAdapter
    '    Try
    '        command.CommandTimeout = CType(ConfigurationManager.AppSettings.Item("TimeOutConect").ToString, Integer)
    '        adapter.SelectCommand = command
    '        adapter.Fill(dtEIR) ', "tblEIR")
    '        adtDamage.SelectCommand = cmdDamage
    '        adtDamage.Fill(dtDamage) ', "tblDamage")

    '        Dim document As New ReportDocument
    '        'document.Load((Server.MapPath(".") & "\CrystalReportEIR.rpt"))
    '        document.Load("C:\Users\RSathielle\Desktop\PROYECTOS CALATHUSMOBILE-IMPRIMIR EIR\IMPRIMIR EIR\SW_IMPRIMIR\SW_IMPRIMIR\rpEIR.rpt")
    '        Dim row As DataRow = teir.tblEIR.NewRow
    '        row.Item("ContainerId") = dtEIR.Rows(0).Item("ContainerId").ToString
    '        row.Item("ServiceId") = dtEIR.Rows(0).Item("ServiceId").ToString
    '        row.Item("strTipoMov") = dtEIR.Rows(0).Item("strTipoMov").ToString
    '        row.Item("EIR") = dtEIR.Rows(0).Item("EIR").ToString
    '        row.Item("Date") = "20010101" 'FormatDateTime(dtEIR.Rows(0).Item("Date").ToString, DateFormat.ShortDate)
    '        row.Item("GrossWeight") = dtEIR.Rows(0).Item("GrossWeight").ToString
    '        row.Item("Steel") = dtEIR.Rows(0).Item("Steel").ToString
    '        row.Item("ShippingLine") = dtEIR.Rows(0).Item("ShippingLine").ToString
    '        row.Item("Vessel") = dtEIR.Rows(0).Item("Vessel").ToString
    '        row.Item("VesselN") = dtEIR.Rows(0).Item("VesselN").ToString
    '        row.Item("Destino") = dtEIR.Rows(0).Item("Destino").ToString
    '        row.Item("CustomBroker") = dtEIR.Rows(0).Item("CustomBroker").ToString
    '        row.Item("Customer") = dtEIR.Rows(0).Item("Customer").ToString
    '        row.Item("Position") = dtEIR.Rows(0).Item("Position").ToString
    '        row.Item("IMO") = dtEIR.Rows(0).Item("IMO").ToString
    '        row.Item("Seal") = dtEIR.Rows(0).Item("Seal").ToString
    '        row.Item("Temperature") = dtEIR.Rows(0).Item("Temperature").ToString
    '        row.Item("Pedimento") = dtEIR.Rows(0).Item("Pedimento").ToString
    '        row.Item("Comments") = dtEIR.Rows(0).Item("Comments").ToString
    '        row.Item("Recibio") = dtEIR.Rows(0).Item("Recibio").ToString
    '        row.Item("Booking") = dtEIR.Rows(0).Item("Booking").ToString
    '        row.Item("Tipo") = dtEIR.Rows(0).Item("Tipo").ToString
    '        row.Item("strSizeId") = dtEIR.Rows(0).Item("strSizeId").ToString
    '        row.Item("strCarrierLine") = dtEIR.Rows(0).Item("strCarrierLine").ToString
    '        row.Item("strCarrierName") = dtEIR.Rows(0).Item("strCarrierName").ToString
    '        Dim j As Integer
    '        Dim rDamage As DataRow
    '        For j = 0 To dtDamage.Rows.Count - 1
    '            rDamage = teir.tblDamage.NewRow
    '            rDamage.Item("TDano") = dtDamage.Rows(j).Item(0).ToString
    '            rDamage.Item("EIR") = dtDamage.Rows(j).Item(1).ToString
    '            rDamage.Item("Posicion") = dtDamage.Rows(j).Item(2).ToString
    '            rDamage.Item("Cantidad") = dtDamage.Rows(j).Item(3).ToString
    '            teir.tblDamage.Rows.InsertAt(rDamage, 0)
    '        Next
    '        teir.tblEIR.Rows.InsertAt(row, 0)
    '        teir.Tables.Add(dtEIR)
    '        teir.Tables.Add(dtDamage)
    '        document.SetDataSource(DirectCast(teir, DataSet))
    '        document.PrintOptions.PrinterName = "HP LaserJet P2014n" '"CutePDF Writer" ' 
    '        document.PrintToPrinter(1, False, 1, 1)
    '    Catch ex As Exception
    '        Dim msg As String = ex.Message
    '    Finally
    '        connection.Close()
    '    End Try
    'End Function



    <WebMethod(Description:="Este metodo recupera la lista de contenedores que se encuentran activos en el inventario. Se utiliza en la generación del Patio 3D")> _
   Public Function GetInventory() As DataTable

        Dim ldt_tblclsInventory As DataTable = New DataTable("tblclsInventory")
        Dim lstr_String As String

        Dim oleDBconnx As OleDbConnection
        Dim oleDBcom As OleDbCommand
        oleDBcom = New OleDbCommand()
        oleDBconnx = New OleDbConnection()
        Dim strconx As String
        Dim ladpt_adapter As OleDbDataAdapter = New OleDbDataAdapter()

        strconx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        oleDBconnx.ConnectionString = strconx
        oleDBcom = oleDBconnx.CreateCommand


        lstr_String = "SELECT " & _
"tblclsContainerInventory.intContainerUniversalId," & vbNewLine & _
"substring(tblclsContainerInventory.strContainerInvYardPositionId, 1, 2) as strContainerInvBlockIdentifier," & vbNewLine & _
                      "tblclsContainerInventory.strContainerId," & vbNewLine & _
"tblclsContainerInventory.strContainerInvYardPositionId," & vbNewLine & _
"Isnull(tblclsShippingLine.strShippingLineIdentifier, 'na') AS strShippingLineIdentifier," & vbNewLine & _
"tblclsContainerType.strContainerTypeIdentifier,tblclsContainerInventory.blnContainerIsFull," & vbNewLine & _
"isnull(convert(char(12),tblclsContainerInvAttachedItem.intContInvAttachId),' ') as intContInvAttachId," & vbNewLine & _
"isnull(convert(char(2),tblclsContainerInvAttachedItem.intAttachedItemPosition),' ') as intAttachedItemPosition" & vbNewLine & _
                      "from tblclsContainerInventory" & vbNewLine & _
                      "join tblclsContainer on tblclsContainer.strContainerId =tblclsContainerInventory.strContainerId" & vbNewLine & _
                      "join tblclsContainerISOCode on tblclsContainerISOCode.intContISOCodeId = tblclsContainer.intContISOCodeId" & vbNewLine & _
                      "join tblclsContainerSize on tblclsContainerSize.intContainerSizeId = tblclsContainerISOCode.intContainerSizeId" & vbNewLine & _
                      "join tblclsContainerType on tblclsContainerType.intContainerTypeId = tblclsContainerISOCode.intContainerTypeId" & vbNewLine & _
                      "left join tblclsShippingLine on tblclsShippingLine.intShippingLineId = tblclsContainerInventory.intContainerInvOperatorId" & vbNewLine & _
                      "LEFT JOIN tblclsContainerInvAttachedItem ON tblclsContainerInvAttachedItem.intContainerUniversalId = tblclsContainerInventory.intContainerUniversalId" & vbNewLine & _
                      "where blnContainerInvActive = 1 And " & vbNewLine & _
                      "substring(strContainerInvYardPositionId,1,2) <> '00' and " & vbNewLine & _
"Len(tblclsContainerInventory.strContainerInvYardPositionId)>1" & vbNewLine & _
                      "order by tblclsContainerInventory.strContainerInvYardPositionId"

        oleDBcom.CommandText = lstr_String
        oleDBcom.CommandType = CommandType.Text
        ldt_tblclsInventory.TableName = "tblclsInventory"
        ldt_tblclsInventory.Columns.Add("intContainerUniversalId")
        ldt_tblclsInventory.Columns.Add("strContainerInvBlockIdentifier")
        ldt_tblclsInventory.Columns.Add("strContainerId")
        ldt_tblclsInventory.Columns.Add("strContainerInvYardPositionId")
        ldt_tblclsInventory.Columns.Add("strShippingLineIdentifier")
        ldt_tblclsInventory.Columns.Add("blnContainerIsFull")
        ldt_tblclsInventory.Columns.Add("intContInvAttachId")
        ldt_tblclsInventory.Columns.Add("intAttachedItemPosition")


        ladpt_adapter.SelectCommand = oleDBcom

        Try
            ladpt_adapter.Fill(ldt_tblclsInventory)
        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            Return ldt_tblclsInventory
        Finally
            ladpt_adapter.SelectCommand.Connection.Close()
            oleDBconnx.Close()
            oleDBcom.Connection.Close()

            ladpt_adapter.SelectCommand.Connection.Dispose()
            oleDBconnx.Dispose()
            oleDBcom.Connection.Dispose()

        End Try


        ladpt_adapter = Nothing
        oleDBconnx = Nothing
        oleDBcom = Nothing

        Return ldt_tblclsInventory

    End Function

    ''
    'metodo para generar el EIR
    <WebMethod()> _
    Public Function WMdt_GetDamageForVisitContainer(ByVal aint_VisitId As Integer, ByVal astr_ContainerName As String) As DataTable

        Dim ldt_result As DataTable 'tabla que guardara el resultado del query
        Dim ldt_checkresult As DataTable
        Dim lAdapt_comand As OleDbDataAdapter = New OleDbDataAdapter() '' Adaptador que ejecuta la tabla y el comando
        Dim lolecmd_comand As OleDbCommand '' objeto comando que se ejecutara
        Dim loleconx_conexion As OleDbConnection = New OleDbConnection() '' objeto de conexion que se usara para conectar 
        Dim istr_conx As String '' cadena de conexion
        Dim strSQL As String


        'parametros
        Dim lparam_VisitId As OleDbParameter = New OleDbParameter()
        Dim lparam_Container As OleDbParameter = New OleDbParameter()
        Dim lparam_Mode As OleDbParameter = New OleDbParameter()

        'Dim lparam_username As OleDbParameter = New OleDbParameter()
        'Dim lparam_category As OleDbParameter = New OleDbParameter()

        ldt_result = New DataTable("result")
        ldt_checkresult = New DataTable("checked")

        istr_conx = ConfigurationManager.ConnectionStrings("dbCalathus").ConnectionString
        loleconx_conexion.ConnectionString = istr_conx
        lolecmd_comand = loleconx_conexion.CreateCommand()

        'especificacion de valores de parametros
        lparam_VisitId.OleDbType = OleDbType.Integer
        lparam_VisitId.ParameterName = "@intVisitId"
        lparam_VisitId.Value = aint_VisitId
        'contenedor
        lparam_Container.OleDbType = OleDbType.Char
        lparam_Container.ParameterName = "@strContainerId"
        lparam_Container.Value = astr_ContainerName
        ''usuario
        'lparam_username.OleDbType = OleDbType.Char
        'lparam_username.ParameterName = "@strUserId"
        'lparam_username.Value = astr_UserName
        ''category
        'lparam_category.OleDbType = OleDbType.Integer
        'lparam_category.ParameterName = "@intContainerCategoryId"
        'lparam_category.Value = aint_CategoryId

        lparam_Mode.OleDbType = OleDbType.Integer
        lparam_Mode.ParameterName = "@intMode"
        lparam_Mode.Value = 0

        ldt_result = New DataTable("EIRNumber")
        lolecmd_comand.CommandText = "spGetDamagetoVisitContainer"

        strSQL = "spGetDamagetoVisitContainer"

        lolecmd_comand.CommandText = strSQL
        lolecmd_comand.CommandType = CommandType.StoredProcedure
        lolecmd_comand.Parameters.Add(lparam_VisitId)
        lolecmd_comand.Parameters.Add(lparam_Container)
        lolecmd_comand.Parameters.Add(lparam_Mode)
        'lolecmd_comand.Parameters.Add(lparam_category)
        'lolecmd_comand.Parameters.Add(lparam_username)

        Try
            lAdapt_comand.SelectCommand = lolecmd_comand
            lAdapt_comand.Fill(ldt_result)


        Catch ex As Exception
            Dim strError As String
            strError = ObtenerError(ex.Message, 99999)
            'Return -1
            Return ldt_result
        Finally
            lAdapt_comand.SelectCommand.Connection.Close()
            loleconx_conexion.Close()

            lAdapt_comand.SelectCommand.Connection.Dispose()
            loleconx_conexion.Dispose()
        End Try

        lAdapt_comand = Nothing
        loleconx_conexion = Nothing

        'copiar tabla 
        CopyTableAndCheckLatin(ldt_result, ldt_checkresult)
        ldt_checkresult.TableName = "checkedresult"

        'Return ldt_result
        Return ldt_checkresult

        ''analizar el id de el renglon generado
        'If ldt_result.Rows.Count = 1 Then
        '    ' si nada mas obutvo un renglon 
        '    If ldt_result.Columns.Count = 1 Then
        '        'ver si la columna se llama intEIRId
        '        If ldt_result.Columns(0).ColumnName = "intEIRId" Then
        '            Return ldt_result(0)(0)
        '        Else
        '            Return ldt_result
        '        End If
        '    Else
        '        ' si no obtuvo especialmente una columna
        '        Return ldt_result
        '    End If
        'Else
        '    'si no obutvo un renglon especifico
        '    Return ldt_result
        'End If


        'Return ldt_result

    End Function
    '''

    Public Function of_base64Decode(ByVal astr_Value As String) As String


        Try

            Dim encoder As UTF8Encoding = New UTF8Encoding()
            Dim utf8Decode As Decoder = encoder.GetDecoder()
            Dim todecode_byte As Byte() = Convert.FromBase64String(astr_Value)
            Dim charCount As Integer = utf8Decode.GetCharCount(todecode_byte, 0, todecode_byte.Length)
            Dim decoded_char(charCount) As Char
            utf8Decode.GetChars(todecode_byte, 0, todecode_byte.Length, decoded_char, 0)
            Dim result As String = decoded_char.ToString()

            Return result

        Catch ex As Exception

            Dim lstr_Err As String
            lstr_Err = ex.Message
            Return ""

        End Try

        Return ""
    End Function

    Public Function FixComments(ByVal astrComms As String)
        Dim lstr_Value As String
        Dim lstr_subpartA As String
        Dim lstr_subpartB As String
        Dim lint_start As Integer
        Dim lint_middleA As Integer
        Dim lint_middleB As Integer
        Dim lint_endb As Integer
        Dim lint_idx As Integer
        Dim lcr_charA As Char
        Dim lint_flag As Integer
        Dim lcr_Blank As Char

        ' ver si existe el De'
        lint_start = astrComms.IndexOf("De")
        If lint_start < 0 Then
            Return astrComms
        End If

        '' ver si existe el - a -
        lint_middleB = astrComms.IndexOf(" a ")
        If lint_middleB < 0 Then
            Return astrComms
        End If

        '' segunda parte 
        lstr_subpartB = astrComms.Substring(lint_middleB)
        '' obtener el de enmedio 

        lint_idx = 2
        lcr_Blank = " "
        lstr_subpartA = ""

        ' buscar el dato en blanco 
        While lint_idx < astrComms.Length And lint_flag = 0
            lcr_charA = astrComms(lint_idx)
            If lcr_charA = lcr_Blank Then
                lint_flag = 1
            End If

            If Char.IsLetterOrDigit(lcr_charA) = True Then
                lstr_subpartA = lstr_subpartA + lcr_charA
            Else
                lint_flag = 1
            End If
            lint_idx = lint_idx + 1
        End While

        '' si existe la subcadena 
        If lstr_subpartA.Length > 1 Then
            lstr_Value = "De " + lstr_subpartA + lstr_subpartB

            '' validacion de que los comentarios editados 
            If lstr_Value.Length < 5 Then
                Return astrComms
            End If
        Else
            Return astrComms
        End If
        Return lstr_Value

    End Function


    <WebMethod()> _
      Public Function WMTestOperation(ByVal numeroa As Integer, ByVal numerob As Integer) As DataTable

        ' generar la tabla 
        Dim ldt_table As DataTable = New DataTable("return")
        Dim ld_row As DataRow
        Dim lint_result As Integer

        lint_result = numeroa + numerob

        ' agrgar columna resultado
        ldt_table.Columns.Add("colresult", System.Type.GetType("System.String"))

        ld_row = ldt_table.NewRow()
        ld_row("colresult") = lint_result

        ldt_table.Rows.Add(ld_row)

        Return ldt_table

    End Function


    Public Sub CopyTableAndCheckLatin(ByVal atb_Original As DataTable, ByRef atb_Destiny As DataTable)

        atb_Destiny = New DataTable()
        Dim lcolum_new As DataColumn = New DataColumn()
        Dim lrow_new As DataRow

        Dim lstr_eñe_min As String
        Dim lstr_eñe_max As String
        Dim lstr_stringElement As String

        lstr_eñe_min = "¤"
        lstr_eñe_max = "¥"
        lstr_stringElement = ""

        For Each lcolum_table As DataColumn In atb_Original.Columns
            lcolum_new = New DataColumn(lcolum_table.ColumnName)
            lcolum_new.DataType = lcolum_table.DataType
            lcolum_new.Caption = lcolum_table.Caption
            atb_Destiny.Columns.Add(lcolum_new)
        Next

        For Each lrow_original As DataRow In atb_Original.Rows

            lrow_new = atb_Destiny.NewRow()

            For lint_index = 0 To atb_Original.Columns.Count - 1

                If atb_Original.Columns(lint_index).DataType.Name.ToString.ToLower = "string" Then
                    lstr_stringElement = lrow_original(lint_index).ToString

                    ''revision de ñs
                    If lstr_stringElement.IndexOf(lstr_eñe_min) > -1 Then
                        lstr_stringElement = lstr_stringElement.Replace(lstr_eñe_min, "ñ")
                    End If

                    If lstr_stringElement.IndexOf(lstr_eñe_max) > -1 Then
                        lstr_stringElement = lstr_stringElement.Replace(lstr_eñe_max, "Ñ")
                    End If

                    lrow_new(lint_index) = lstr_stringElement
                Else
                    lrow_new(lint_index) = lrow_original(lint_index)
                End If

                ' lrow_new(lint_index) = lrow_original(lint_index)
            Next

            atb_Destiny.Rows.Add(lrow_new)

        Next

    End Sub

End Class