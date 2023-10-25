*** Settings ***
Library           RequestsLibrary
Library           my_keywords.py
Library           utils.py
Suite Setup       Disable Warnings
*** Variables ***
${BASE_URL}      https://localhost:7022/api/
${EXISTING_ROLE_ID}    1
${NON_EXISTING_ROLE_ID}    999999
${PAIS_NAME}          PaisTest 
${username}   rvasquez
${password}   123
${idRol}    1
${newUsername}    TestUser
${newPassword}    123
${newIdRol}    1
${usernameUpdate}    TestUserUpdate
${NOMBRE_TARJETA}    Juan Perez
${ID_CLIENTE}     7
${MONTO_PAGO}     1000
${ID_COMPRA}      41
${TOKEN_CARD}     4242424242424242
${EXP_MONTH}      10
${EXP_YEAR}        2023
${CVS}            845

*** Test Cases ***

Authentication Test
    Create Session    myapi    ${BASE_URL}    verify=False
    &{headers}=    Create Dictionary    Content-Type=application/json
    ${data}=    Create Dictionary    username=${username}    password=${password}
    ${response}=    POST On Session    myapi    /Authentication/login    headers=${headers}    json=${data}
    Should Be Equal As Strings    ${response.status_code}    200
    ${json_response}=    Set Variable    ${response.json()}
    Should Be Equal    ${json_response['username']}    ${username}
    Should Be Equal As Numbers    ${json_response['idRol']}    ${idRol}
    Should Be Equal As Strings    ${json_response['active']}    ${True}
Get Existing Role
    Create Session    myapi    ${BASE_URL}    verify=False
    ${endpoint}=    Set Variable    /Roles/${EXISTING_ROLE_ID}
    ${response}=    GET On Session    myapi    ${endpoint}
    Should Be Equal As Strings    ${response.status_code}    200
    ${json_response}=    Set Variable    ${response.json()}
    Should Be True    'idRol' in ${json_response}
    Should Be True    'rol' in ${json_response}

Get Non-Existing Role
    Create Session    myapi    ${BASE_URL}    verify=False
    ${endpoint}=    Set Variable    /Roles/${NON_EXISTING_ROLE_ID}
    ${response}=    Get Request And Continue On Failure    ${BASE_URL}    ${endpoint}
    Should Be Equal As Strings    ${response['status_code']}    404

Add New Country And Verify
    Create Session    myapi    ${BASE_URL}    verify=False
    &{headers}=    Create Dictionary    Content-Type=application/json
    ${data}=    Create Dictionary    Pais=${PAIS_NAME}
    ${response}=    POST On Session    myapi    /Paises    headers=${headers}    json=${data}
    Should Be Equal As Strings    ${response.status_code}    200
    ${json_response}=    Set Variable    ${response.json()}
    Should Be True    'idPais' in ${json_response}
    ${NEW_COUNTRY_ID}=    Set Variable    ${json_response['idPais']}

    # Verifying the country is stored correctly
    ${endpoint}=    Set Variable    /Paises/${NEW_COUNTRY_ID}
    ${response}=    GET On Session    myapi    ${endpoint}
    Should Be Equal As Strings    ${response.status_code}    200
    ${json_response}=    Set Variable    ${response.json()}
    Should Be Equal    ${json_response['pais']}    ${PAIS_NAME}

Add New User And Verify And Update
    Create Session    myapi    ${BASE_URL}    verify=False
    # Verifying the user does not exist already and deleting it if it does
    ${existingUserId}=    Get UserId If Exists    ${newUsername}
    Run Keyword If    '${existingUserId}' != 'None'   Delete Existing User    ${existingUserId}
    #Adding the new user
    &{headers}=    Create Dictionary    Content-Type=application/json
    ${dataInsert}=    Create Dictionary    username=${newUsername}    password=${newPassword}    idRol=${newIdRol}    active=${True}
    ${response}=    POST On Session    myapi    /Usuarios    headers=${headers}    json=${dataInsert}
    &{headers}=    Create Dictionary    Content-Type=application/json
    ${DataUpdate}=    Create Dictionary    username=${newUsername}    password=${newPassword}    idRol=${newIdRol}    active=${True}
    ${response}=    POST On Session    myapi    /Usuarios    headers=${headers}    json=${DataUpdate}
    Should Be Equal As Strings    ${response.status_code}    200
    ${json_response}=    Set Variable    ${response.json()}
    Should Be True    'idUsuario' in ${json_response}
    ${NewUserId}=    Set Variable    ${json_response['idUsuario']}
    # Verifying the User is stored correctly
    ${endpoint}=    Set Variable    /Usuarios/${NewUserId}
    ${response}=    GET On Session    myapi    ${endpoint}
    Should Be Equal As Strings    ${response.status_code}    200
    ${json_response}=    Set Variable    ${response.json()}
    Should Be Equal    ${json_response['username']}    ${newUsername}
    #Update User
    ${data}=    Create Dictionary    idUsuario=${NewUserId}    username=${usernameUpdate}    password=${newPassword}    idRol=${newIdRol}    active=${True}
    &{headers}=    Create Dictionary    Content-Type=application/json
    ${response}=    PUT On Session    myapi    /Usuarios/${NewUserId}    headers=${headers}    json=${data}
    Should Be Equal As Strings    ${response.status_code}    200
    ${json_response}=    Set Variable    ${response.json()}
    Should Be Equal    ${json_response['username']}    ${usernameUpdate}
    # #Verifying the User is updated correctly
    ${existingUserId}=    Get UserId If Exists    ${usernameUpdate}
    Should Not Be Equal As Strings    ${existingUserId}    None


Send Payment and Verify Response
    Create Session    myapi    ${BASE_URL}    verify=False
    &{headers}=    Create Dictionary    Content-Type=application/json
    &{payload}=    Create Dictionary    saveCard=${False}
    ...                                      nombreTarjeta=${NOMBRE_TARJETA}
    ...                                      idCliente=${ID_CLIENTE}
    ...                                      montoPago=${MONTO_PAGO}
    ...                                      idCompra=${ID_COMPRA}
    ...                                      tokenCard=${TOKEN_CARD}
    ...                                      expMonth=${EXP_MONTH}
    ...                                      expYear=${EXP_YEAR}
    ...                                      cvs=${CVS}
    Log To Console    ${payload}
    ${response}=      POST On Session    myapi    /Payments    headers=${headers}    json=${payload}
    Should Be Equal As Strings    ${response.status_code}    200    
    ${json_response}=    Set Variable    ${response.json()}
    Should Be Equal As Numbers    ${json_response['idCompra']}    ${ID_COMPRA}
    Should Be Equal As Numbers    ${json_response['montoPago']}    ${MONTO_PAGO}
*** Keywords ***
Get UserId If Exists
    [Arguments]    ${username}
    ${endpoint}=    Set Variable    /Usuarios
    ${response}=    GET On Session    myapi    ${endpoint}
    @{users}=    Set Variable    ${response.json()}
    ${userId}=    Set Variable    None
    FOR    ${user}    IN    @{users}
        IF    '${user["username"]}' == '${username}'
            ${userId}=    Set Variable    ${user['idUsuario']}
            Exit For Loop
        END
    END
    [Return]    ${userId}


Delete Existing User
    [Arguments]    ${userId}
    ${endpoint}=    Set Variable    /Usuarios/${userId}
    ${response}=    DELETE On Session    myapi    ${endpoint}
    Should Be Equal As Strings    ${response.status_code}    200