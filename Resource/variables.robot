*** Variables ***
# Target settings mapped from system benchmarks
${TARGET_DEV}     gst-010005781934
${MAC_ADDR}       E6:E6:C7:A8:32:14
${AUTH_KEY}       AT+MFGSECAUTH=1,*QBOXcnuuEqil3Rl
${PORT}       'COM32'
# ${AUTH_KEY}       AT+MFGSECAUTH=1,QEC^9/*;Br/0sy_9
# ${PORT}       'COM39'
${BAUDRATE}       115200
${SERVERPORT}		65432	
# Update this path to match your installation (use JLink.exe for Windows, JLinkExe for Linux/macOS)
${JLINK_EXE_PATH}    C:\\Program Files\\SEGGER\\JLink\\JLink.exe
${TARGET_DEVICE}     nRF52840_xxAA
${INTERFACE}         SWD
${SPEED_KHZ}         4000
${SCRIPT_PATH}       ${CURDIR}/generated_flash.jlink
${TERMINATOR}     0D0A