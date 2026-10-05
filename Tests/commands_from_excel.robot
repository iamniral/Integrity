*** Settings ***
Resource          ../Resource/network_keywords.resource
Suite Setup       Connect to device
Suite Teardown    Disconnect from device

*** Variables ***
${TIMEOUT}       2s
${BAUDRATE}       115200

*** Test Cases ***
To disable all GPIO pins without verification
    [Documentation]    Disable all GPIO pins without verification.
    Disable all GPIO
To delete all channels
    [Documentation]    Delete all channels without verification.
    Delete all channels
Test user AT commands to read the state of digital inputs.
    [Documentation]    Verify the read digital input commands.
    Run AT Commands From Excel    ${CURDIR}/../Data/Read_digital_input_pins.xlsx
