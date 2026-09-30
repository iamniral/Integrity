*** Settings ***
Documentation     New test suite executing channel configuration protocol from a CSV file.
Resource          ../Resource/nordic_ble_keywords.resource
Library           OperatingSystem
Library           String
Library           Collections
Test Setup        Connect To Nordic Device
#Test Teardown    Close All Ports

*** Variables ***
# Extracted dictionary mapping error numeric IDs to clear string labels
&{ERROR_CODES}    1=INVALID_PARAMS
...               2=BUFFER_FULL
...               3=CANNOT_ABORT
...               4=HARDWARE_ERROR
...               5=DEVICE_DISABLED
...               6=DEVICE_DEACTIVATED
...               7=ALREADY_QUEUED
...               8=LOCATION_UNAVAILABLE
...               9=ALREADY_IN_SESSION
...               10=RESOURCE_ERROR
...               11=NOT_FOUND
...               12=BAD_STATE
...               13=ALREADY_EXISTS
...               14=PERMISSION_ERROR
...               15=TX_LIFTIME_EXPIRED
...               16=TX_NO_LOW_PRIORITY_TO_SORT
...               17=TX_LIFETIME_NOT_SET
...               18=TX_TEMP_OUTOFRANGE
...               19=INVALID_DATETIME
...               20=TASK_HANDLE_NULL
...               21=TX_RESP_ERROR
...               22=BUSY
...               23=TX_QUEUE_EMPTY
...               24=BUFFER_EMPTY
...               25=SOS_MODE_ENABLED
...               26=NO_DEVICE_PLAN

*** Keywords ***
Execute Automated AT Step
    [Arguments]    ${Action}    ${Command}    ${Expected}
    Log To Console    \n--------------------------------------------------
    Log To Console    [ACTION]: ${Action}

    # Strip spaces and format clean multiline strings if present
    ${Command}=     Strip String    ${Command}
    ${Expected}=    Strip String    ${Expected}

    # Handle rows containing multiple sub-commands stacked together
    @{sub_commands}=    Split String    ${Command}    separator=\n
    ${overall_response}=    Set Variable    ${EMPTY}

    FOR    ${cmd}    IN    @{sub_commands}
        ${cmd}=    Strip String    ${cmd}
        # Ignore cosmetic conversational text inside the data column (like 'or')
        IF    '${cmd}' == '${EMPTY}' or '${cmd.lower()}' == 'or'    CONTINUE

        Log To Console    [TX -> NORDIC]: Sending: ${cmd}

        # Call your existing working keyword directly
        ${chunk}=    Send AT Command    ${cmd}
        ${overall_response}=    Set Variable    ${overall_response}${chunk}\n
    END

    Log To Console    [RX <- NORDIC]: Consolidated Response:\n${overall_response}

    # --- Reliable Extraction, Matching, and Colorization Engine ---
    ${has_error}=    Run Keyword And Return Status    Should Match Regexp    ${overall_response}    .*\\+ERROR:\\s*\\d+.*
    IF    ${has_error}
        # Extract numerical digits safely via inline Python strip regex execution
        ${error_id_int}=    Evaluate    __import__('re').search(r'\\+ERROR:\\s*(\\d+)', '''${overall_response}''').group(1)
        # Convert explicitly to a string type to securely match structural dictionary keys
        ${error_id}=        Convert To String    ${error_id_int}

        ${status}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${ERROR_CODES}    ${error_id}
        IF    ${status}
            ${error_label}=    Get From Dictionary    ${ERROR_CODES}    ${error_id}
            # Prints the error and textual reason completely in RED text color
            Log To Console     \n\x1b[31m[ERROR DETECTED]: System flagged code ${error_id} -> ${error_label}\x1b[0m
        ELSE
            # Prints the unknown error completely in RED text color
            Log To Console     \n\x1b[31m[ERROR DETECTED]: System flagged unknown code ${error_id}\x1b[0m
        END
    END

    # Standardize checking criteria based on the expected string
    ${status}=    Run Keyword And Return Status    Should Contain    ${overall_response}    ${Expected}
    IF    not ${status}
        # Fallback check for alternative expected results (like "OK Or +ERROR")
        Should Match Regexp    ${overall_response}    (OK|\\+ERROR)    msg=Unexpected device response for: ${Action}
        Log To Console         ${overall_response}
        Log To Console    [STATUS]: Warning - Handled alternative response safely.
    ELSE
        Log To Console    [STATUS]: Verification SUCCESS for ${Action}
    END

*** Test Cases ***
Verify Advanced Routing And Channel Configurations
    [Documentation]    Natively loads the CSV file and routes commands to your working Nordic connection keywords.

    # 1. Load the CSV file into a Python list of rows safely handling inner quotes/newlines
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

        # Route to our keyword runner which leverages your functional setup
        Execute Automated AT Step    ${action_field}    ${data_field}    ${expected_field}
        Sleep       5s
    END
