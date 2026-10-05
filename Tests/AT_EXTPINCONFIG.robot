*** Settings ***
Resource    ../Resource/nordic_ble_keywords.resource
Library     SerialLibrary
Test Setup       Connect To Nordic Device
#Test Teardown    Close All Ports

*** Test Cases ***
Set cable configuration
    [Documentation]    Checks if the device responds to a basic AT ping.
    ${response} =    Send AT Command    AT+EXTPINCONFIG=1
    should contain    ${response}    +ERROR: 13

Read cable configuration
    [Documentation]    Checks if the device responds to a basic AT ping.
    ${response} =    Send AT Command    AT+EXTPINCONFIG?
    should contain    ${response}    1 
