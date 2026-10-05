*** Settings ***
Resource          ../Resource/network_keywords.resource
#Suite Setup       Connect to device
Suite Teardown    Disconnect from device

*** Variables ***
${TIMEOUT}       2s
${TERMINATOR}     0D0A
# Update this to the exact path of your compiled .hex or .bin file
${FIRMWARE_FILE}  ${CURDIR}/../Data/NordicApp1.hex

*** Test Cases ***
Verify Hardware Firmware Flashing Sequence
    [Documentation]    Dynamically generates the command script, clears flash, loads firmware, and reboots the target chip.
    [Tags]             Hardware    Flashing
    Flash Firmware    ${FIRMWARE_FILE}
    sleep    5s

To connect to device under test.
    [Documentation]    Connect to the device after flash.
    Connect to device
    sleep    3s
To verify the current firmware version on nordic.
    [Documentation]   	Verify the nordic firmware version.
    Send AT Command And Verify    AT+CGMR?    0.1.7

To disable all GPIO pins without verification
    [Documentation]    Disable all GPIO pins without verification.
    Disable all GPIO
To delete all channels
    [Documentation]    Delete all channels without verification.
    Delete all channels
Test user AT commands to read the state of digital inputs.
    [Documentation]    Data Driven test: Verify the read digital input commands.
    Run AT Commands From Excel    ${CURDIR}/../Data/Read_digital_input_pins.xlsx