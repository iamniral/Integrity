*** Settings ***
Documentation    Automated script to open a directory and execute a script.
Resource    ../Resource/nordic_ble_keywords.resource
Library          Process
Library          String      # 👈 YOU MUST ADD THIS LINE TO FIX THE ERROR
Library    DateTime    



*** Test Cases ***
Verify Script Execution Stages and DFU Status
    [Documentation]    Runs the script, verifies Stage 1 completion, then checks Stage 2 DFU results.
    
    ${result}    ${output} =    Run the script and capture all terminal output

    USB DFU Stage 1 Validation    ${result.stdout}  

    USB DFU Stage 2 Validation    ${output}   

    Logs on consol    ${output}   
    
    # Ensure the script didn't crash with a system error code
    Should Be Equal As Integers    ${result.rc}    0

*** Test Cases ***
Verify Script Execution Stages and DFU Status
    [Documentation]    Runs the script, verifies Stage 1 completion, then checks Stage 2 DFU results.
    
    ${result}    ${output} =    Run the script and capture all terminal output

    USB DFU Stage 1 Validation    ${result.stdout}  
    USB DFU Stage 2 Validation    ${output}   

    # This will now print to console AND create your new text file
    Logs on consol    ${result.stdout}   
    
    Should Be Equal As Integers    ${result.rc}    0
                
