function [features, target] = engineSchema
features = {'engine_rpm','lub_oil_pressure','fuel_pressure', ...
    'coolant_pressure','lub_oil_temp','coolant_temp'};
target = 'engine_condition';
end
