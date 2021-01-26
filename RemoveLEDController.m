function RemoveLEDController(hLEDController)

global FBDC_CHR_LED_CONTROLLER_FID;

doremove = false(size(FBDC_CHR_LED_CONTROLLER_FID));
for i = 1:numel(FBDC_CHR_LED_CONTROLLER_FID),
  doremove(i) = hLEDController.isequal(FBDC_CHR_LED_CONTROLLER_FID{i});
end
fprintf('Removing %d LED controllers from FBDC_CHR_LED_CONTROLLER_FID\n',nnz(doremove));
FBDC_CHR_LED_CONTROLLER_FID(doremove) = [];