function [Pref1, Pref_pu1,  Pref_pu2, Qref] = stepPowerReference(Snom,fpRange,operation)
% This function is only used to generate power references for cases of 
% increase and decrease of load. It is assumed that the unit operates 
% in normal mode only. The initial power of the unit will be limited by 
% the amount of load variation, but will assume random values. The steps 
% in the power reference will be from 0.1 to 0.5 p.u.
    
    % the variable "operation" defines whether it will be an increase (1) 
    % or decrease in load (0) 
    
    fp = ramdomValue(fpRange(1),fpRange(2));
    variationLoadPU = ramdomValue(0.1,0.5);
    variationLoad = variationLoadPU*Snom;
    if operation == 1
        Smax = 1 - variationLoadPU;
        Soperacional1 = Snom*ramdomValue(0.1,Smax);
        Pref1 = Soperacional1*fp;
        Pref_pu1 = Pref1/Snom;
        Qref = -Soperacional1*sin(acos(fp));
        Soperacional2 = Soperacional1 + variationLoad;
        Pref2 = Soperacional2*fp;
        Pref_pu2 = Pref2/Snom;
    elseif operation == 0
        Smin = 0.05 + variationLoadPU;
        Soperacional1 = Snom*ramdomValue(Smin,1);
        Pref1 = Soperacional1*fp;
        Pref_pu1 = Pref1/Snom;
        Qref = -Soperacional1*sin(acos(fp));
        Soperacional2 = Soperacional1 - variationLoad;
        Pref2 = Soperacional2*fp;
        Pref_pu2 = Pref2/Snom;   
    else
        disp('Unfeasible value selected for operation.')
    end
    
end