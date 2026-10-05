*** Settings ***
Resource          ../Resource/network_keywords.resource
Suite Setup       Connect to device
Suite Teardown    Disconnect from device

*** Variables ***
${TIMEOUT}       2s
${TERMINATOR}     0D0A

*** Test Cases ***
To disable all GPIO pins without verification
    [Documentation]    Disable all GPIO pins without verification.
    Disable all GPIO
To delete all channels
    [Documentation]    Delete all channels without verification.
    Delete all channels
C-R-U-D channel for configured external pins mode1
    [Documentation]    Sequentially executes AT commands to configure and verify external pins and channels.
    # 2. Query external pin configuration
    Send AT Command And Verify    AT+EXTPINCONFIG?    +EXTPINCONFIG: 1
    
    # 3. Configure external pin routing mode to UART+4IO
    Send AT Command And Verify    AT+EXTPINCONFIG=1    +ERROR: 13
    
    # 4. Configure GPIO 3 as Analog Input and Enable it
    Send AT Command And Verify    AT+GPIOCFGA=1,3    OK
    
    # 5. Add channel 1 as Analog Input (type 2) on pin 3
    Send AT Command And Verify    AT+ADDCHANNEL=1,2,3    OK
    
    # 6. Configure GPIO 4 as Analog Input and Enable it
    Send AT Command And Verify    AT+GPIOCFGA=1,4    OK
    
    # 7. Add channel 2 as Analog Input (type 2) on pin 4
    Send AT Command And Verify    AT+ADDCHANNEL=2,2,4    OK
    
    # 8. Read value or state change configuration from channel 1
    Send AT Command And Verify    AT+READCHANNEL=1    +READCHANNEL: 1,2,3${\n}OK
    
    # 9. Read value or state change configuration from channel 2
    Send AT Command And Verify    AT+READCHANNEL=2    +READCHANNEL: 2,2,4${\n}OK
    
    # 10. Configure GPIO 1 as Digital Input and Enable it
    Send AT Command And Verify    AT+GPIOCFGIN=1,1,1    OK
    
    # 11. Configure GPIO 2 as Digital Input and Enable it with setting LOW
    Send AT Command And Verify    AT+GPIOCFGIN=1,2,0    OK
    
    # 12. Update channel 1 to Digital IO for GPIO 2
    Send AT Command And Verify    AT+UPDATECHANNEL=1,1,2    OK
    
    # 13. Update channel 2 to Digital IO for GPIO 1
    Send AT Command And Verify    AT+UPDATECHANNEL=2,1,1    OK
    
    # 14. Delete Channel 1 & 2
    Send AT Command And Verify    AT+DELETECHANNEL=1    OK
    Send AT Command And Verify    AT+DELETECHANNEL=2    OK
    
    # 15. Add channel 3 as Digital Input (type 1) on pin 3
    Send AT Command And Verify    AT+ADDCHANNEL=3,1,1    OK
    
    # 16. Add channel 4 as Digital Input (type 1) on pin 3
    Send AT Command And Verify    AT+ADDCHANNEL=4,1,2    OK
    
    # 17. Read value or state change configuration from channel 3
    Send AT Command And Verify    AT+READCHANNEL=3    +READCHANNEL: 3,1,1${\n}OK
    
    # 18. Read value or state change configuration from channel 4
    Send AT Command And Verify    AT+READCHANNEL=4    +READCHANNEL: 4,1,2${\n}OK
    
    # 19. Update channel 3 to Analog input for GPIO 3
    Send AT Command And Verify    AT+UPDATECHANNEL=3,2,3    OK
    
    # 20. Update channel 4 to Analog input for GPIO 4
    Send AT Command And Verify    AT+UPDATECHANNEL=4,2,4    OK
    Send AT Command     AT+DELETEALLCHANNELS