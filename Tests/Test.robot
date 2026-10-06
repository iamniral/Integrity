*** Settings ***
Documentation     New test suite executing channel configuration protocol from a CSV file.
Resource          ../Resource/nordic_ble_keywords.resource
Resource          ../Resource/Error_code.resource
Library           OperatingSystem
Library           String
Library           Collections
Test Setup        Connect To Nordic Device
#Test Teardown    Close All Ports


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

    # Clean up excess trailing spacing or newlines
    ${overall_response}=    Strip String    ${overall_response}
    Log To Console    [RX <- NORDIC]: Consolidated Response:\n${overall_response}

    # --- Reliable Extraction, Matching, and Colorization Engine ---
    ${error_id}=     Set Variable    ${NONE}
    ${has_error}=    Run Keyword And Return Status    Should Match Regexp    ${overall_response}    .*\\+ERROR:\\s*\\d+.*

    IF    ${has_error}
        # Pure Robot native solution to securely isolate the error code line without inline Python evaluate crashes
        ${error_line}=       Get Lines Matching Regexp    ${overall_response}    .*\\+ERROR:.*
        # Split line out by colon character
        @{error_parts}=      Split String    ${error_line}    separator=:
        ${raw_error_id}=     Get From List    ${error_parts}    1
        # Strip out loose spaces surrounding the remaining digit string
        ${error_id}=         Strip String    ${raw_error_id}

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

    # --- Whitespace Normalization Loop for Robust Substring Verification ---
    # Normalizes spaces/tabs/newlines into unified single spaces to make text comparisons immune to newline formats.
    ${normalized_response}=    Replace String Using Regexp    ${overall_response}    \\s+    ${SPACE}
    ${normalized_expected}=    Replace String Using Regexp    ${Expected}            \\s+    ${SPACE}

    ${status}=    Run Keyword And Return Status    Should Contain    ${normalized_response}    ${normalized_expected}

    IF    not ${status}
        # --- MODIFIED SECTION FOR HANDLING ERROR 12 ---
        IF    '${error_id}' == '12'
            Log To Console    \n\x1b[33m[ERROR 12 DETECTED]: Appending '?' mark to verify expected parameter setup...\x1b[0m

            ${query_cmd}=    Set Variable    ${Command}?
            Log To Console    [TX -> NORDIC]: Sending Query Command: ${query_cmd}

            ${query_response}=    Send AT Command    ${query_cmd}
            ${query_response}=    Strip String    ${query_response}
            Log To Console    [RX <- NORDIC]: Query Command Response:\n${query_response}

            # Normalize whitespace for query validation check too
            ${norm_query_resp}=    Replace String Using Regexp    ${query_response}    \\s+    ${SPACE}
            ${query_status}=    Run Keyword And Return Status    Should Contain    ${norm_query_resp}    ${normalized_expected}

            IF    ${query_status}
                Log To Console    \x1b[32m[STATUS]: Query verification SUCCESS for ${Action} after Error 12 bypass!\x1b[0m
            ELSE
                ${fail_title}=    Set Variable    \n\x1b[31m[STATUS]: Verification FAILED for Query Validation "${Action}"\x1b[0m
                ${header_1}=      Set Variable    \x1b[33m==================================================\x1b[0m

                Log To Console    ${fail_title}
                Log To Console    ${header_1}
                Log To Console    Expected to find substring : ${Expected}
                Log To Console    --------------------------------------------------
                Log To Console    Actual Query Response Received:\n${query_response}
                Log To Console    ${header_1}

                Run Keyword And Continue On Failure    Fail    Query validation response mismatch on action: "${Action}". See logs.
            END
        ELSE
            # FIXED: Variables assigned on single, clean programmatic lines to ensure safe string generation
            ${fail_title}=    Set Variable    \n\x1b[31m[STATUS]: Verification FAILED for "${Action}"\x1b[0m
            ${header_1}=      Set Variable    \x1b[33m==================================================\x1b[0m
            ${header_2}=      Set Variable    \x1b[33m              EXPECTED VS ACTUAL MATCH            \x1b[0m

            # Print visual comparison clearly to terminal console for all other failures
            Log To Console    ${fail_title}
            Log To Console    ${header_1}
            Log To Console    ${header_2}
            Log To Console    ${header_1}
            Log To Console    Expected to find substring : ${Expected}
            Log To Console    --------------------------------------------------
            Log To Console    Actual Device Response Received:\n${overall_response}
            Log To Console    ${header_1}

            # Force the test case status to FAIL but cleanly continue executing subsequent loops
            Run Keyword And Continue On Failure    Fail    Device response mismatch on action: "${Action}". See console logs for details.
        END
    ELSE
        Log To Console    \x1b[32m[STATUS]: Verification SUCCESS for ${Action}\x1b[0m
    END

*** Test Cases ***
Verify Advanced Routing And Channel Configurations
    [Documentation]    Natively loads the CSV file and routes commands to your working Nordic connection keywords.
    ...                Continues execution if any item fails, ignores Error 12, and fails the overall test case at completion if other errors exist.

    # 1. Load the CSV file into a Python list using a safe context manager block
    ${rows}=    Evaluate    (lambda f: [r for r in __import__('csv').reader(f)])(open(r'${CURDIR}/commands.csv', encoding='utf-8'))

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
        Sleep       1s
    END
