function [V_0, V_1, V_2, I_0, I_1, I_2, time] = generatesSymmetricComponent(data_ph_pu,noise,plotComp)
% From the data from the simulink simulation, it extracts the symmetric 
% components of the voltage and current measured at the generator output. 

    % data_ph_pu: data from simulink in pu
    % noise: if = 1 insert noise, if = 0 do not insert noise

    % Formatting data coming from Simulink: 
    time = data_ph_pu.time;

    data_ph_temp_pu = data_ph_pu.signals.values(:,:);
    VA_pu = data_ph_temp_pu(:,1)';
    VB_pu = data_ph_temp_pu(:,2)';
    VC_pu = data_ph_temp_pu(:,3)';
    IA_pu = data_ph_temp_pu(:,4)';
    IB_pu = data_ph_temp_pu(:,5)';
    IC_pu = data_ph_temp_pu(:,6)';

	dataI = [IA_pu(:,:); IB_pu(:,:); IC_pu(:,:)];
    dataV = [VA_pu(:,:); VB_pu(:,:); VC_pu(:,:)];

    i = sqrt(-1);
    a = -1/2 + sqrt(3)*i/2;

    inv_matriz_A = (1/3)*[1   1       1;
                          1   a^2     a;
                          1   a       a^2]; 
                      
    componentsV = zeros(3, length(VA_pu));
    componentsI = zeros(3, length(VA_pu));

    for j = 1:length(VA_pu)
        % Calculating the Symmetric Components of Voltages and Currents
        componentsV(:,j) = inv_matriz_A*dataV(:,j);
        componentsI(:,j) = inv_matriz_A*dataI(:,j);
    end

    % Ordering the Sequence Components
    % the transpose is given so that they are column vectors.

    V_0 = abs(componentsV(1,:))';
    V_1 = abs(componentsV(2,:))';
    V_2 = abs(componentsV(3,:))';
    I_0 = abs(componentsI(1,:))';
    I_1 = abs(componentsI(2,:))';
    I_2 = abs(componentsI(3,:))';

    if noise == 1
        noiseAmplitude = 0.05;
        len = length(V_0);
        V_0 = abs(V_0 + noiseAmplitude*2*(rand(len, 1)-0.5));
        V_1 = abs(V_1 + noiseAmplitude*2*(rand(len, 1)-0.5));
        V_2 = abs(V_2 + noiseAmplitude*2*(rand(len, 1)-0.5));
        I_0 = abs(I_0 + noiseAmplitude*2*(rand(len, 1)-0.5));
        I_1 = abs(I_1 + noiseAmplitude*2*(rand(len, 1)-0.5));
        I_2 = abs(I_2 + noiseAmplitude*2*(rand(len, 1)-0.5));
    end

    
    if plotComp == 1
        figure
        subplot(2,1,1)
            hold on;
            plot(time, abs(VA_pu), 'LineWidth', 1);
            plot(time, V_0, 'LineWidth', 1);
            plot(time, V_1, 'LineWidth', 1);
            plot(time, V_2, 'LineWidth', 1);
            legend('VA_{pu}','V_0','V_1','V_2');
            title('Voltage')
            hold off;
        subplot(2,1,2)
            hold on;
            plot(time, abs(IA_pu), 'LineWidth', 1);
            plot(time, I_0, 'LineWidth', 1);
            plot(time, I_1, 'LineWidth', 1);
            plot(time, I_2, 'LineWidth', 1);
            legend('IA_{pu}','I_0','I_1','I_2');
            title('Current');
            hold off;
    end

end