*** Settings ***
Library    SerialLibrary
Library    String

*** Variables ***
${PORT}          /dev/ttyACM0          # Or /dev/ttyUSB0 on Linux
${BAUD}          115200
${TERMINATOR}    \r\n

*** Keywords ***
Connect To Nordic Device
# 1. Clean up any existing port sessions first
    delete all ports
    Add Port    ${PORT}    baudrate=${BAUD}    timeout=2
    Open Port   ${PORT}
    Reset Input Buffer    ${PORT}
    Send AT Command    AT+MFGSECAUTH=1,CMJ6/(/!'-GVYBLA

#Authorize Device
#    [Documentation]    Sends the MFG Security Auth code to enable write commands.
#    ${auth_cmd} =    Set Variable    AT+MFGSECAUTH=1,asu'zfzU{Mj#O[4V
#    Log To Console    \nSending Auth Code...
#    ${status} =       Send AT Command    ${auth_cmd}

#    # If successful, the device should return "OK"
#    IF    '${status}' != 'OK'
#        Fatal Error    Device Authorization Failed! State: ${status}
#    END
#    Log To Console    Authorization Successful. Device is now in Write Mode.

Send AT Command
    [Arguments]    ${command}
    # 1. Send the command
    Write Data     ${command}${TERMINATOR}    encoding=utf-8

    # 2. Read the response (currently coming in as Hex)
    ${hex_response} =  Read Until    ${TERMINATOR}

    # 3. Convert Hex to String (Removes spaces and decodes)
    ${clean_hex} =     Remove String    ${hex_response}    ${SPACE}
    ${bytes} =         Evaluate    bytes.fromhex('${clean_hex}')
    ${response} =      Evaluate    $bytes.decode('utf-8')

    Log    Decoded Response: ${response}
    RETURN    ${response}

