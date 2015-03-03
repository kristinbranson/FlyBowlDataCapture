function temp_units = USBTC08_temp_units_code(temp_units_str)

switch upper(temp_units_str),
  case 'CENTIGRADE',
    temp_units = 0;
  case 'FAHRENHEIT',
    temp_units = 1;
  case 'KELVIN',
    temp_units = 2;
  case 'RANKINE',
    temp_units = 3;
end