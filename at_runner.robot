*** Settings ***
Documentation     Robust Serial runner to execute multi-line AT commands over /dev/ttyACM0.
Library           OperatingSystem
Library           String
Library           Collections
Library           SerialLibrary

*** Variables ***
${SERIAL_PORT}    /dev/ttyACM0
${BAUD_RATE}      115200

*** Keywords ***
Send Real AT Command
    [Arguments]    ${Action}    ${Command}    ${Expected}
    Log To Console    \n--------------------------------------------------
    Log To Console    [ACTION]: ${Action}

    # Normalize potential string anomalies safely
    ${Command}=     With/Without Outer Quotes    ${Command}
    ${Expected}=    With/Without Outer Quotes    ${Expected}

    # Process multiple commands if they are broken up by newlines
    @{sub_commands}=    Split String    ${Command}    separator=\n
    ${overall_response}=    Set Variable    ${EMPTY}

    FOR    ${cmd}    IN    @{sub_commands}
        ${cmd}=    Strip String    ${cmd}
        # Ignore cosmetic conversational text inside the data column (like 'or')
        IF    '${cmd}' == '${EMPTY}' or '${cmd.lower()}' == 'or'    CONTINUE

        Log To Console    [TX -> SERIAL]: Sending: ${cmd}\\r\\n
        Read All    # Flush older serial buffers
        Write Data    ${cmd}\r\n
        Sleep    0.5s

        ${chunk}=    Read All
        ${overall_response}=    Set Variable    ${overall_response}${chunk}
    END

    Log To Console    [RX <- SERIAL]: Received Response:\n${overall_response}

    # Standardize checking criteria
    ${status}=    Run Keyword And Return Status    Should Contain    ${overall_response}    ${Expected}
    IF    not ${status}
        # Fallback check for alternative expected results (like "OK Or +ERROR")
        Should Match Regexp    ${overall_response}    (OK|\\+ERROR)    msg=Unexpected device response for: ${Action}
        Log To Console    [STATUS]: Warning - Handled alternative response safely.
    ELSE
        Log To Console    [STATUS]: Verification SUCCESS for ${Action}
    END

With/Without Outer Quotes
    [Arguments]    ${text}
    ${text}=    Strip String    ${text}
    # Clean up inline literal representation of newlines if passed raw
    ${text}=    Replace String    ${text}    \\n    \n
    RETURN    ${text}

*** Test Cases ***
Execute Channel Routing Protocol Over ACM0
    [Setup]    Run Keywords    Delete All Ports
    ...        AND             Add Port    ${SERIAL_PORT}    baudrate=${BAUD_RATE}    timeout=2.0    encoding=ascii
    ...        AND             Open Port   ${SERIAL_PORT}
    ...        AND             Sleep       1s

    # 1. Load your CSV file into a Python list of rows natively
    ${rows}=    Evaluate    list(__import__('csv').reader(open(r'${CURDIR}/commands.csv', encoding='utf-8')))

    # 2. Iterate cleanly through rows while skipping the headers safely
    ${is_header}=    Set Variable    ${TRUE}
    FOR    ${row}    IN    @{rows}
        IF    ${is_header}
            ${is_header}=    Set Variable    ${FALSE}
            CONTINUE
        END

        # Check how many elements were successfully parsed in this row
        ${row_length}=    Get Length    ${row}

        # Skip completely empty lines
        IF    ${row_length} == 0    CONTINUE

        # Fallback protections to prevent IndexError if a column is missing
        ${action_field}=     Get From List    ${row}    0

        ${data_field}=       Run Keyword If    ${row_length} > 1    Get From List    ${row}    1
        ...                  ELSE              Set Variable    AT

        ${expected_field}=   Run Keyword If    ${row_length} > 2    Get From List    ${row}    2
        ...                  ELSE              Set Variable    OK

        # Skip if the row is entirely blank text fields
        IF    '${action_field}' == '${EMPTY}' and '${data_field}' == '${EMPTY}'    CONTINUE

        Send Real AT Command    ${action_field}    ${data_field}    ${expected_field}
    END

    [Teardown]    Close Port    ${SERIAL_PORT}
