function [V_0n, V_1n, V_2n, I_0n, I_1n, I_2n] = saturatesAndNormalizesSymmetricComponents(V_0, V_1, V_2, I_0, I_1, I_2,maxV,maxI)
% normalizes the vectors of symmetric components considering the scale 
% method. For normalization, the maximum current (maxI) and voltage (maxV)
% values are considered. 256 intensity levels are used, following the 
% standard for grayscale images. Values that exceed the limits stipulated
% by maxI and maxV are saturated. 
    
    % % maximum pixel intensity for grayscale
    maxIntensidade = 255; 
    
    % saturation 
	V_0(V_0 > maxV) = maxV;
    V_1(V_1 > maxV) = maxV;
    V_2(V_2 > maxV) = maxV;
    I_0(I_0 > maxI) = maxI;
    I_1(I_1 > maxI) = maxI;
    I_2(I_2 > maxI) = maxI;    
    
    % normalization
    V_0 = V_0/maxV;
    V_1 = V_1/maxV;
    V_2 = V_2/maxV;
    I_0 = I_0/maxI;
    I_1 = I_1/maxI;
    I_2 = I_2/maxI;
    
    V_0n = round(V_0*maxIntensidade);
    V_1n = round(V_1*maxIntensidade);
    V_2n = round(V_2*maxIntensidade);
    I_0n = round(I_0*maxIntensidade);
    I_1n = round(I_1*maxIntensidade);
    I_2n = round(I_2*maxIntensidade);
       
end