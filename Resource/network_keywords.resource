*** Settings ***
Library           ../Libraries/NetworkLibrary.py
resource          variables.robot
Variables         variables.robot
Library           Process
Library           OperatingSystem
Library           SerialLibrary    encoding=ascii   # Assumes serial communication. Change to Telnet or Custom Lib if needed.
Library           String
Library    Collections
Library    ../Libraries/ExcelHelper.py

*** Variables ***
${OUTPUT_DIR}    ${CURDIR}/../Output
# ${AUTH_KEY}       AT+MFGSECAUTH=1,*QBOXcnuuEqil3Rl
# ${PORT}       COM32
${AUTH_KEY}       AT+MFGSECAUTH=1,QEC^9/*;Br/0sy_9
${PORT}       COM39
${BAUDRATE}       115200

*** Keywords ***
Initialize Engine Session
    Connect To Server    host=${HOST}    port=${SERVERPORT}

Perform Step-By-Step Device Handshake
    # 1. Option selection
    Wait For Pattern    Enter 1 for NUS                     timeout=15s
    Send Command        2
    
    # 2. Input scan filtering string
    Wait For Pattern    Enter scan filter.                  timeout=15s
    Send Command        ${TARGET_DEV}
    
    # 3. Handle robust conditional scan sequence
    Scan And Connect To Dut    filter_tag=${TARGET_DEV}    max_retries=15
    
    # 4. Wait for explicit connection milestones
    Wait For Pattern    Connecting to device: ${MAC_ADDR}   timeout=20s
    Wait For Pattern    Connected                          timeout=20s
    Wait For Pattern    Enter Config Service shared key...  timeout=20s
    
    # 5. Send key structure out 
    Send Shared Key
    
    # 6. Await counter processing responses
    Wait For Pattern    Getting Control Point Counter...    timeout=15s
    Wait For Pattern    Control Point Counter Received...   timeout=15s
    
    # 7. Authenticate core configurations
    Send Command        ${AUTH_KEY}
    Wait For Pattern    OK                                  timeout=15s

Terminate Engine Session
    [Documentation]    Sends fallback manual disconnect sequences and cleans sockets.
    Send Manual Command    bye
    Disconnect And Close

Select hex file and create jLink script for flash the DUT
    [Arguments]    ${hex_or_bin_file}
    Log To Console    ${\n}--- Starting Hardware Flashing Sequence ---
    
    # 1. Verify file exists
    File Should Exist    ${hex_or_bin_file}    msg=The firmware file '${hex_or_bin_file}' was not found!
    
    # 2. Build the script using explicit newline breaks
    # This prevents syntax errors inside the J-Link engine
    ${script_content}=    Catenate    SEPARATOR=${\n}
    ...    ExitOnError 1
    ...    r
    ...    h
    ...    erase
    ...    loadfile "${hex_or_bin_file}"
    ...    r
    ...    g
    ...    q
    Create File    ${SCRIPT_PATH}    ${script_content}
    
Set the Device for the J-Link tool
    ${process}=    Run Process    ${JLINK_EXE_PATH}    
    ...    -device         ${TARGET_DEVICE}    
    ...    -if             ${INTERFACE}    
    ...    -speed          ${SPEED_KHZ}    
    ...    -autoconnect    1    
    ...    -CommanderScript    ${SCRIPT_PATH}
    
    # Extract only the exact properties you need right away
    Set Suite Variable    $JLINK_OUTPUT    ${process.stdout}
    Set Suite Variable    $JLINK_RC        ${process.rc}
    
Cleanup jLink file from current directory
    Remove File    ${SCRIPT_PATH}
    
Verify Flash Result
    Log To Console    ${\n}=== J-LINK HARDWARE OUTPUT ===
    Log To Console    ${JLINK_OUTPUT}
    Log To Console    ============================
    Should Be Equal As Integers    ${JLINK_RC}    0    
    ...    msg=JLink process exited with code ${JLINK_RC}. See the hardware output printed above!

Flash Firmware
    [Arguments]    ${hex_or_bin_file}
    Select hex file and create jLink script for flash the DUT    ${hex_or_bin_file}
    Set the Device for the J-Link tool
    Cleanup jLink file from current directory
    Verify Flash Result

Connect to device
    Add Port    ${PORT}    baudrate=${BAUDRATE}   timeout=5
    Reset Input Buffer    ${PORT}
    Send AT Command And Verify    ${AUTH_KEY}    OK

Disconnect from device    
    Close Port

Send AT Command
    [Arguments]    ${command}
    # 1. Send Command 
    IF    "${command}" != "${EMPTY}"
        Write Data    ${command}\r\n
    END
    # 2. Clear incoming response buffer
    Run Keyword And Ignore Error    Read Until    ${TERMINATOR}

Send AT Command And Verify
    [Arguments]    ${command}    ${expected_response}
    
    # 1. Send Command
    IF    "${command}" != "${EMPTY}"
        Write Data    ${command}\r\n
    END

    # 2. Read the response
    ${raw_response}=    Read Until    ${TERMINATOR}

    # 3. Clean spaces/newlines from the response
    ${clean_response}=    Replace String Using Regexp    ${raw_response}    \\s+    ${EMPTY}

    # 4. Safely handle Hex vs Plain Text decoding
    ${is_hex}=    Evaluate    all(c in '0123456789abcdefABCDEF' for c in '${clean_response}') and len('${clean_response}') % 2 == 0 and len('${clean_response}') > 0
    
    IF    ${is_hex}
        ${bytes}=       Evaluate    bytes.fromhex('${clean_response}')
        ${response}=    Evaluate    $bytes.decode('utf-8', errors='ignore')
    ELSE
        ${response}=    Set Variable    ${raw_response}
    END

    # 5. Dynamically construct the response format for queries
    ${final_expected}=    Set Variable    ${expected_response}
    
    # FIX: Using $expected_response syntax avoids string literal formatting errors caused by internal newlines
    IF    "+" not in $expected_response and "OK" != $expected_response and "ERROR" not in $expected_response
        ${cmd_prefix}=    Execute Javascript Or Regex To Extract Prefix    ${command}
        IF    "${cmd_prefix}" != "${EMPTY}"
            ${final_expected}=    Set Variable    +${cmd_prefix}: ${expected_response}
        END
    END

    # 6. Log and Validate (Continues execution on failure)
    Log    Command: ${command} -> Cleaned Response: ${response}
    Run Keyword And Continue On Failure    Should Contain    ${response}    ${final_expected}    msg=Failed to match response for command: ${command}. Expected: ${final_expected}, Got: ${response}
    
    RETURN    ${response}

Execute Javascript Or Regex To Extract Prefix
    [Arguments]    ${command}
    # Helper to strip 'AT+' and everything after '=' or '?'
    ${match}=    Evaluate    re.search(r'AT\\+(.*?)(?:=|$|\\?)', '${command}')    modules=re
    IF    ${match}
        RETURN    ${match.group(1)}
    END
    RETURN    ${EMPTY}
    sleep    3s

Disable all GPIO
    Send AT Command    ${AUTH_KEY}
    Send AT Command    AT+GPIOCFGIN=0,1
    Send AT Command    AT+GPIOCFGIN=0,2
    Send AT Command    AT+GPIOCFGOUT=0,1
    Send AT Command    AT+GPIOCFGOUT=0,2
    Send AT Command    AT+GPIOCFGIN=0,1
    Send AT Command    AT+GPIOCFGA=0,3
    Send AT Command    AT+GPIOCFGA=0,4

Delete all channels
    Send AT Command    ${AUTH_KEY}
    Send AT Command    AT+DELETEALLCHANNELS

Run AT Commands From Excel
    [Arguments]    ${excel_file_path}
    
    ${rows}=    Read Excel Commands    ${excel_file_path}
    ${results_list}=    Create List
    
    FOR    ${row}    IN    @{rows}
        # Step metadata and instructions
        ${step_name}=          Get From Dictionary    ${row}    Action
        ${at_command}=         Get From Dictionary    ${row}    Data
        ${expected_result}=    Get From Dictionary    ${row}    Expected Result
        
        # Initialize default tracking variables
        ${actual_result}=      Set Variable    ${EMPTY}
        ${status}=             Set Variable    Pass
        
        # Execute the AT command from Data and verify it against Expected Result
        ${passed}    ${response}=    Run Keyword And Ignore Error    Send AT Command And Verify    ${at_command}    ${expected_result}
        
        IF    "${passed}" == "FAIL"
            ${status}=          Set Variable    Fail
            ${actual_result}=    Set Variable    ${response}
        ELSE
            ${actual_result}=    Set Variable    ${response}
        END

        # Build data row structure matching required output format
        ${result_row}=    Create Dictionary    
        ...    Action=${step_name}    
        ...    Data=${at_command}    
        ...    Expected Result=${expected_result}    
        ...    Actual Result=${actual_result}    
        ...    Status=${status}
        
        Append To List    ${results_list}    ${result_row}
    END
    
    # Save output to file_name_result_<timestamp>.xlsx
    ${output_file}=    Save Excel Results    ${excel_file_path}    ${results_list}
    Log    Execution complete. Results saved to: ${output_file}
    RETURN    ${output_file}

