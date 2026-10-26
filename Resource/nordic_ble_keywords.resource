*** Settings ***
Library    SerialLibrary
Library    String
Library    Process
Library    OperatingSystem
Library    DateTime 

*** Variables ***
${PORT}          COM5          # Or /dev/ttyUSB0 on Linux
${BAUD}          115200
${TERMINATOR}    \r\n
${DFU_STAGE_1_SUCCESS}    Status x6 - DFU Image in Nordic Flash CRC Check Success (Stage 1 of 2) Complete
${DFU_STAGE_2_SUCCESS}    Status x1 - DFU Success (Stage 2 of 2 complete)

#*** DFU Variables ***
# 📁 Define the absolute path to the folder containing your script
${TARGET_FOLDER}    C:/Users/anuja.joshi/Downloads/Modem_DFU/Modem_DFU/Satellite_Partition/USB
${Log_FOLDER}       C:/Users/anuja.joshi/Downloads/Modem_DFU/Modem_DFU/Satellite_Partition/USB
# 📄 Define the name of the script you want to run (e.g., test.py, run.bat, script.sh)
${SCRIPT_NAME}      INT200_USB_MODEM_dfu_SAT_Partition_controller_serial_transfer_1.6.0_new.py

*** Keywords ***
Connect To Nordic Device
# 1. Clean up any existing port sessions first
    delete all ports
    Add Port    ${PORT}    baudrate=${BAUD}    timeout=2
    Open Port   ${PORT}
    Reset Input Buffer    ${PORT}
    Send AT Command    AT+MFGSECAUTH=1,_}=s!e(yHRD[Pn0W

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

#Run the script and capture all terminal output
    #${result} =    Run Process    python    ${SCRIPT_NAME}    cwd=${TARGET_FOLDER}    shell=True
    
    # Convert terminal output to lowercase to avoid case-sensitivity issues
    #${output} =    Convert To Lowercase    ${result.stdout}
    # 🌟 NEW: Exposes these variables back to your test cases
    #RETURN    ${result}    ${output}

USB DFU Stage 1 Validation
    [Arguments]    ${result.stdout}
    # Check Stage 1 of modem DFU
    # This will fail the test immediately if Stage 1 did not pass
    Should Contain    ${result.stdout}    ${DFU_STAGE_1_SUCCESS}    ignore_case=True    msg=❌ Step 1 Failed: '${DFU_STAGE_1_SUCCESS}' was not found in terminal logs!
    Log To Console    Status x6 - DFU Image in Nordic Flash CRC Check Success (Stage 1 of 2) Complete

USB DFU Stage 2 Validation
    [Arguments]    ${lowercase_output}
    #Check Stage 2 DFU Status
    # Because Stage 1 passed, the script naturally continues here to check Stage 2
    Should Contain    ${lowercase_output}    ${DFU_STAGE_2_SUCCESS}    ignore_case=True    msg=❌ Step 2 Failed: DFU process was not successful!
    Log To Console    Status xA - Stage 2 Image Transfer Attempt 1 Acked

Logs on consol
# 4. Optional: Print full log summary to the console
    [Arguments]    ${log_to_display}
    Log To Console    \n--- Complete Terminal Logs Summary ---
    Log To Console    ${log_to_display}
    Log To Console    --------------------------------------

    # 🌟 NEW: Get current timestamp to make a unique filename
    ${timestamp} =    Get Current Date    result_format=%Y%m%d_%H%M%S
    ${log_filename} =  Set Variable    ${TARGET_FOLDER}/dfu_run_${timestamp}.txt
    
    # 🌟 NEW: Create the new file and save the logs into it
    Create File       ${log_filename}    ${log_to_display}    encoding=utf-8
    Log To Console    💾 Logs successfully saved to: ${log_filename}

Run the script and capture all terminal output
    [Documentation]    Runs the external python script, captures stderr, and prevents shell buffering bugs.
    Log To Console    \n[DEBUG] Executing: python -u ${SCRIPT_NAME} inside ${TARGET_FOLDER}
    
    ${result} =    Run Process    python    -u    ${SCRIPT_NAME}    cwd=${TARGET_FOLDER}    shell=False    stderr=STDOUT
    
    Log To Console    [DEBUG] Script Exit Code: ${result.rc}
    Log To Console    [DEBUG] Captured Output: ${result.stdout}
    Log    Raw Process Output: ${result.stdout}
    
    ${output} =    Convert To Lowercase    ${result.stdout}
    RETURN    ${result}    ${output}

    
    

