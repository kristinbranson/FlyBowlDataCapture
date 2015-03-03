  function [name,str] = USBTC08_error_table(n)
  
  switch n,
    case 0,
      name = 'USBTC08_ERROR_OK';
      str = 'No error occurred.';
    case 1,
      name = 'USBTC08_ERROR_OS_NOT_SUPPORTED';
      str = 'The driver supports Windows XP SP2 and Vista.';
    case 2
      name = 'USBTC08_ERROR_NO_CHANNELS_SET';
      str = 'A call to usb_tc08_set_channel is required.';
    case 3
      name = 'USBTC08_ERROR_INVALID_PARAMETER';
      str = 'One or more of the function arguments were invalid.';
    case 4
      name = 'USBTC08_ERROR_VARIANT_NOT_SUPPORTED';
      str = 'The hardware version is not supported. Download the latest driver.';
    case 5
      name = 'USBTC08_ERROR_INCORRECT_MODE';
      str = 'An incompatible mix of legacy and non-legacy functions wascalled (or usb_tc08_get_single was called while in streaming mode.)';
    case 6
      name = 'USBTC08_ERROR_ENUMERATION_INCOMPLETE';
      str = 'usb_tc08_open_unit_async was called again while a background enumeration was already in progress.';
    otherwise
      name = sprintf('Unknown error %d',n);
      str = '';
  end
  
