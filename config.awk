#
# convert name like PA10 to GPIOA
#
function pinport(input)
{
	if (substr(input, 0, 1) != "P") {
		printf("invalid pinname: %s\n", input)
		exit(-1)
	}

	return "GPIO" substr(input, 2, 1)
}

#
# convert name like PA10 to GPIO_Pin_10
#
function pinname(input)
{
	if (substr(input, 0, 1) != "P") {
		printf("invalid pinname: %s\n", input)
		exit(-1)
	}

	return "GPIO_Pin_" substr(input, 3)
}

function output_define(name, value)
{
	printf("#define %s %s\n", name, value)
}

function output_pinport(prefix, input)
{
	output_define(prefix "PIN", pinname(input));
	output_define(prefix "PORT", pinport(input));
}

function parse_unknow(indent, vname, value)
{
	vn=""
	for (i=0; i<indent; i++) {
		vn=(vn)(vname[i])("->")
	}
	printf("unknow variable: %s%s=\"%s\"\n", vn, vname[indent], value);
	exit(-1)	
}

function parse_motor(indent, vname, value)
{
	key = vname[1]

	if (key == "back_left") {
		output_define("MOTOR0_PIN_" value)
	}
	else if (key == "back_right") {
		output_define("MOTOR2_PIN_" value)
	}
	else if (key == "front_left") {
		output_define("MOTOR1_PIN_" value)
	}
	else if (key == "front_right") {
		output_define("MOTOR3_PIN_" value)
	}
	else parse_unknow(indent, vname, value)
}

function parse_led(indent, vname, value)
{
	key = vname[1]
	if (key == "ports")
	{
		ledname = "LED" vname[2];
		input = value;
		if (substr(value, 0, 1) == "~") {
			output_define(ledname "_INVERT");
			input = substr(value, 2);
		}
		output_pinport(ledname, input);
		led_count++;
	}
	else parse_unknow(indent, vname, value)
}

function parse_battery(indent, vname, value)
{
	key = vname[1]
	if (key == "input")
	{
		output_pinport("BATTERY", value);
	} else if (key == "channel") 
	{
		output_define("BATTERY_ADC_CHANNEL", value);
	} else if (key == "ref")
	{
		output_define("ADC_REF_VOLTAGE", value);
	}
	else if (key == "r1")
	{
		output_define("VOLTAGE_DIVIDER_R1", value);
	}
	else if (key == "r2")
	{
		output_define("VOLTAGE_DIVIDER_R2", value);
	}
	else parse_unknow(indent, vname, value)
}

function parse_radio(indent, vname, value)
{
	key = vname[1]
	if (key == "model") {
		output_define("RADIO_" value);
	} else if (key == "mosi") {
		output_pinport("SPI_MOSI_", value);
		spi_mosi = value
	} else if (key == "miso") {
		output_pinport("SPI_MISO_", value);
		spi_miso = value
	} else if (key == "clk") {
		output_pinport("SPI_CLK_", value);
		spi_clk = value
	} else if (key == "ss") {
		output_pinport("SPI_SS_", value);
	} else if (key == "check") {
		if (value == "on") output_define("RADIO_CHECK");
	}
	else parse_unknow(indent, vname, value)
}

function parse_gyro(indent, vname, value)
{
	key = vname[1]

	if (key == "sda") {
		output_pinport("I2C_SDA", value);
		i2c_sda = value;
	} 
	else if (key == "scl")
	{
		output_pinport("I2C_SCL", value);
		i2c_scl = value;
	} else if (key == "scl_pullup") {
		output_define("SOFTI2C_PUSHPULL_CLK");
	} else if (key == "address")
	{
		output_define("I2C_GYRO_ADDRESS", value);
	} else if (key == "id" && indent == 2) {
		output_define("GYRO_ID_" vname[2], value);
	} else if (key == "rotate") {
		output_define("SENSOR_ROTATE_" value);
	}	
	else parse_unknow(indent, vname, value)
}

function parse_global(indent, vname, value)
{
	key = vname[1]

	if (key == "debug") {
		if (value == "on") output_define("DEBUG")
	} else if (key == "rxdebug") {
		if (value == "on") output_define("RXDEBUG")
	} else if (key == "vreg") {
		output_pinport("VREG_", value);
		output_define("ENABLE_VREG_PIN");
	}
	else parse_unknow(indent, vname, value)
}

function parse(indent, vname, value)
{
	section = vname[0]
	if (lastsection != section) {
		print("\n");
		lastsection = section;
	}

	printf("// %s_%s_%s = %s\n", vname[0], vname[1], vname[2], value)

	if      (section == "global")  parse_global(indent, vname, value)
	else if (section == "gyro")    parse_gyro(indent, vname, value)
	else if (section == "radio")   parse_radio(indent, vname, value)
	else if (section == "battery") parse_battery(indent, vname, value)
	else if (section == "led")     parse_led(indent, vname, value)
	else if (section == "motor")   parse_motor(indent, vname, value)
	else parse_unknow(indent, vname, value)
}

BEGIN {
	printf("// don't manual modify this file\n")
	print("#include \"config.h\"")
	led_count = 0;
}

{
  indent = length($1)/2;
  vname[indent] = $2;
  for (i in vname) {if (i > indent) {delete vname[i]; idx[i]=0}}
  if(length($2)== 0){  vname[indent]= ++idx[indent] };
  if (length($3) > 0) {
  	parse(indent, vname, $3);
  }
}

END {
	print("\n\n");
	output_define("LED_NUMBER", led_count)

	# check if can enable hardware i2c
	if (i2c_sda == "PA10" && i2c_scl == "PA9") {
		output_define("USE_HARDWARE_I2C");
		output_define("HW_I2C_PINS_PA910");
	} else if (i2c_sda == "PB7" && i2c_scl == "PB6") {
		output_define("USE_HARDWARE_I2C");
		output_define("HW_I2C_PINS_PB67");
	} else {
		output_define("USE_SOFTWARE_I2C");	
	}

	# check if can enable spi
	if (spi_miso == "") {
		output_define("SOFTSPI_3WIRE")
	} else {
		output_define("SOFTSPI_4WIRE")	
	}

	printf("// DONE\n")
}