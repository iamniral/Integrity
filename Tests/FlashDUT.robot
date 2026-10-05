*** Settings ***
Resource          ../Resource/network_keywords.resource

*** Variables ***
# Update this to the exact path of your compiled .hex or .bin file
${FIRMWARE_FILE}  ${CURDIR}/../Data/NordicApp1.hex

*** Test Cases ***
Verify Hardware Firmware Flashing Sequence
    [Documentation]    Dynamically generates the command script, clears flash, loads firmware, and reboots the target chip.
    [Tags]             Hardware    Flashing
    Flash Firmware    ${FIRMWARE_FILE}
