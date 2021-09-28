function [Pref, Pref_pu, Qref] = powerReferenceDesenergization(Snom,fpRange,normalOperation,potMax)
%   Assumes the unit operates most of the time delivering active power 
%   to the system. This percentage of time is determined by normalOperation. 
%   This mode of operation is called Normal. In "Normal" operation, 
%   the unit delivers capacitive reactives, so the Qref value is 
%   negative. During the rest of the time, the unit operates by 
%   compensating the network's capacitive reactives as a result of the 
%   discharged line, for example. In this mode Pref assumes a minimum 
% 	value while Qreg assumes values from 10% to 90% of Snom
    
% This function is intended to set the operating point of the unit before
% powering down. For pre-de-energization, the unit's power level is 
% reduced, being defined here by potMax. The minimum value for the power 
% for pre-power-off was defined as 0.05 p.u.

    % Snom: nominal power
    % fpRange: acceptable range of power factor 
    % normalOperation: percentage of operating time delivering active power
    % potMax: maximum power level in pre-power-down operation 
    
    operation = rand;
    if operation < normalOperation
        fp = ramdomValue(fpRange(1),fpRange(2));
        Soperational = Snom*ramdomValue(0.05,potMax);
        Pref = Soperational*fp;
        Pref_pu = Pref/Snom; 
        Qref = -Soperational*sin(acos(fp));
    else
        Pref_pu = 0.02;   % minimum value for the power flow to run 
        Pref = Pref_pu*Snom;
        Qref = Snom*ramdomValue(0.1,0.9);
    end
end