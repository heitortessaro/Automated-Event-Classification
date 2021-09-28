% This program generate simulation data to be useb by event classifiers
% Heitor, Dionatan 
% 08/2021

clc
clear all
close all

%% Simulated Events
% - Desenergization;
% - Load Increase;
% - Load Decrease;
% - Shut down (faults at low and high side voltage):

%% Basic variable definition
Snom = 200e6;       % Nominal power of the generator (VA)
tbeg = 34;          % Fault instant 
operNormal = 0.8;   % Proportion of time with normal operation, delivering 
                    % active power and not compensating the network's 
                    % capacitive reactives 
powerMin = 0.3;     % Minimum load level of the generator
powerMaxDes = 0.2;  % Maximum power level before the desenergization                    
maxI = 2;           % Current limit in pu used to normalize current 
                    % components
maxV = 1.5;         % Current limit in pu used to normalize voltage 
                    % components

%% Defining the ranges for the used parameters
% vectors composed of the minimum and maximum values associated with each
% variable.  
faultDuration = [0.2 1.5];
temporaryFaultDuration = [0.05 .3];
faultResistence = [0.0001 0.1];
pfRange = [0.9 1];

%% Simulation parameters and output data 
samplingPeriod  = 1/60;   

simulationTime = 240;    
simulationTime = string(simulationTime);          

size2D = round(sqrt((double(simulationTime))*60));               
% 2d matrix size generated for each symmetric component. The value of 120 
% stores the data of a 240s record, equivalent to 14400 samples 

numberExamplesEachCase = 3;   % preference by number multiple of 3 

insertNoise = 1;      % if = 1, insert noise into components, if = 0 no 
plotSymetricalComponents = 0;% if = 1 plots symmetric components, if = 0 no 

%% Simulated event selection 
names =["DESE01"; % Desenergization of the unit
        "LINC02"; % Load increase  
        "LDEC03"; % Load decrease  
        "SPFH04"; % THVS line-to-ground fault shutdown  
        "SPFL05"; % TLVS line-to-ground fault shutdown
        "DPFH06"; % THVS line-to-line fault shutdown
        "DPFL07"; % TLVS line-to-line fault shutdown
        "DGFH08"; % THVS double-line-to-ground fault shutdown
        "DGFL09"; % TLVS double-line-to-ground fault shutdown
        "SGFH10"; % THVS simetric-to-ground fault shutdown  
        "SGFL11"; % TLVS simetric-to-ground fault shutdown  
        "SPTH12"; % THVS temporary line-to-ground fault     
        "DPTH13"; % THVS temporary line-to-line fault       
        "DGTH14"; % THVS temporary double-line-to-ground
        "SGTH15"];% THVS temporary simetric-to-ground fault 



%% Simulation and creation of data files
warning('off','all')
disp('Warnings are disabled. To reverse this action, comment line 71.')

currentFolder = pwd;   
namesNumber = length(names);
for indexNames = 1:namesNumber
    evenType = names(indexNames);
    switch evenType
        case 'DESE01'
            mkdir DESE01
            name = "DESE01";
            system = 'DESE01';
            for numero = 1:numberExamplesEachCase
                [Pref, Pref_pu, Qref] = powerReferenceDesenergization(Snom,pfRange,operNormal,powerMaxDes);
                trig = tbeg;

                % runs the power flow and the simulink simulation
                Vref = 1;           % initialize variable
                Pmec_pu = Pref_pu;  % initialize variable with any value
                Vf0 = 1.2;          % initialize variable with any value
                Vt0 = 1;            % initialize variable with any value
                LF = power_loadflow(system,'solve');
                Pmec_pu = LF.sm.Pmec/LF.sm.Pnom;    % Correct value
                Vf0 = LF.sm.Vf;                     % Correct value
                Vt0 = abs(LF.sm.Vt);                % Correct value
                Vref = Vt0;
                out = sim(system,'AbsTol','1e-5','StartTime','0','StopTime',simulationTime);

                % calculate symmetric components and extract the data
                [V_0, V_1, V_2, I_0, I_1, I_2, time] = ...
                    generatesSymmetricComponent(out.dados_ph_pu,insertNoise,plotSymetricalComponents);

                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                
                % Fuzzy classifier file 
                isFuzzy = 1;
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\"  ] )
                f=dir('*.mat'); 
                delete(f.name)                  
                
                % generates saturated and normalized components
                [V_0, V_1, V_2, I_0, I_1, I_2] = ...
                    saturatesAndNormalizesSymmetricComponents(V_0, V_1, V_2, ...
                    I_0, I_1, I_2,maxV,maxI);

                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                isFuzzy = 0;
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\" ] )
                f=dir('*.mat'); 
                delete(f.name)  
            end

        case 'LINC02'
            mkdir LINC02
            name = "LINC02";
            system = 'LINC_LDEC';
            for numero = 1:numberExamplesEachCase
                operation = 1; % load increment
                [Pref, Pref_pu, Pref_pu2, Qref] = stepPowerReference(Snom,pfRange,operation);
                p1 = Pref_pu;
                p2 = Pref_pu2;
                tcarga = tbeg;
                trig = 1e3;

                % runs the power flow and the simulink simulation
                Vref = 1;           % initialize variable
                Pmec_pu = Pref_pu;  % initialize variable with any value
                Vf0 = 1.2;          % initialize variable with any value
                Vt0 = 1;            % initialize variable with any value
                LF = power_loadflow(system,'solve');
                Pmec_pu = LF.sm.Pmec/LF.sm.Pnom;    % Correct value
                Vf0 = LF.sm.Vf;                     % Correct value
                Vt0 = abs(LF.sm.Vt);                % Correct value
                Vref = Vt0;
                out = sim(system,'AbsTol','1e-5','StartTime','0','StopTime',simulationTime);

                % calculate symmetric components and extract the data
                [V_0, V_1, V_2, I_0, I_1, I_2, time] = ...
                    generatesSymmetricComponent(out.dados_ph_pu,insertNoise,plotSymetricalComponents);
                
                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                % Fuzzy classifier file 
                isFuzzy = 1;
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\"  ] )
                f=dir('*.mat'); 
                delete(f.name)                   

                % generates saturated and normalized components
                [V_0, V_1, V_2, I_0, I_1, I_2] = ...
                    saturatesAndNormalizesSymmetricComponents(V_0, V_1, V_2, ...
                    I_0, I_1, I_2,maxV,maxI);

                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                isFuzzy = 0;                
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\" ] )
                f=dir('*.mat'); 
                delete(f.name)  
            end
    %
        case 'LDEC03'
            mkdir LDEC03
            name = "LDEC03";
            system = 'LINC_LDEC';
            for numero = 1:numberExamplesEachCase
                operation = 0; %decrement
                [Pref, Pref_pu,  Pref_pu2, Qref] = stepPowerReference(Snom,pfRange,operation);
                p1 = Pref_pu;
                p2 = Pref_pu2;
                tcarga = tbeg;
                trig = 1e3;

                % runs the power flow and the simulink simulation
                Vref = 1.2;           % initialize variable
                Pmec_pu = Pref_pu;  % initialize variable with any value
                Vf0 = 1.2;          % initialize variable with any value
                Vt0 = 1;            % initialize variable with any value
                LF = power_loadflow(system,'solve');
                Pmec_pu = LF.sm.Pmec/LF.sm.Pnom;    % Correct value
                Vf0 = LF.sm.Vf;                     % Correct value
                Vt0 = abs(LF.sm.Vt);                % Correct value
                Vref = Vt0;
                out = sim(system,'AbsTol','1e-5','StartTime','0','StopTime',simulationTime);

                % calculate symmetric components and extract the data
                [V_0, V_1, V_2, I_0, I_1, I_2, time] = ...
                    generatesSymmetricComponent(out.dados_ph_pu,insertNoise,plotSymetricalComponents);
                
                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                % Fuzzy classifier file 
                isFuzzy = 1;
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\"  ] )
                f=dir('*.mat'); 
                delete(f.name)                   

                % generates saturated and normalized components
                [V_0, V_1, V_2, I_0, I_1, I_2] = ...
                    saturatesAndNormalizesSymmetricComponents(V_0, V_1, V_2, ...
                    I_0, I_1, I_2,maxV,maxI);

                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                isFuzzy = 0;                
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\" ] )
                f=dir('*.mat'); 
                delete(f.name)  
            end

        case 'SPFH04'
            mkdir SPFH04
            name = "SPFH04";
            for numero = 1:numberExamplesEachCase
                % select phase fault
                if numero <= numberExamplesEachCase/3
                    system = 'SPFH04_AG';
                elseif numero <= numberExamplesEachCase*2/3
                    system = 'SPFH04_BG';
                else
                    system = 'SPFH04_CG';
                end
                
                [Pref, Pref_pu, Qref] = powerReference(Snom,pfRange,operNormal,powerMin);
                tend = tbeg + ramdomValue(faultDuration(1),faultDuration(2));
                trig = tend;
                Ron = ramdomValue(faultResistence(1),faultResistence(2));
                Rg = ramdomValue(faultResistence(1),faultResistence(2));

                % runs the power flow and the simulink simulation
                Vref = 1;           % initialize variable
                Pmec_pu = Pref_pu;  % initialize variable with any value
                Vf0 = 1.2;          % initialize variable with any value
                Vt0 = 1;            % initialize variable with any value
                LF = power_loadflow(system,'solve');
                Pmec_pu = LF.sm.Pmec/LF.sm.Pnom;    % Correct value
                Vf0 = LF.sm.Vf;                     % Correct value
                Vt0 = abs(LF.sm.Vt);                % Correct value
                Vref = Vt0;
                out = sim(system,'AbsTol','1e-5','StartTime','0','StopTime',simulationTime);

                % calculate symmetric components and extract the data
                [V_0, V_1, V_2, I_0, I_1, I_2, time] = ...
                    generatesSymmetricComponent(out.dados_ph_pu,insertNoise,plotSymetricalComponents);
                
                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                % Fuzzy classifier file 
                isFuzzy = 1;
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\"  ] )
                f=dir('*.mat'); 
                delete(f.name)                   

                % generates saturated and normalized components
                [V_0, V_1, V_2, I_0, I_1, I_2] = ...
                    saturatesAndNormalizesSymmetricComponents(V_0, V_1, V_2, ...
                    I_0, I_1, I_2,maxV,maxI); 

                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                isFuzzy = 0;                
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\" ] )
                f=dir('*.mat'); 
                delete(f.name)  
            end

        case 'SPFL05'
            mkdir SPFL05
            name = "SPFL05";
            for numero = 1:numberExamplesEachCase
                % select phase fault
                if numero <= numberExamplesEachCase/3
                    system = 'SPFL05_AG'; 
                elseif numero <= numberExamplesEachCase*2/3
                    system = 'SPFL05_BG';
                else
                    system = 'SPFL05_CG';
                end

                [Pref, Pref_pu, Qref] = powerReference(Snom,pfRange,operNormal,powerMin);
                tend = tbeg + ramdomValue(faultDuration(1),faultDuration(2));
                trig = tend;
                Ron = ramdomValue(faultResistence(1),faultResistence(2));
                Rg = ramdomValue(faultResistence(1),faultResistence(2));

                % runs the power flow and the simulink simulation
                Vref = 1;           % initialize variable
                Pmec_pu = Pref_pu;  % initialize variable with any value
                Vf0 = 1.2;          % initialize variable with any value
                Vt0 = 1;            % initialize variable with any value
                LF = power_loadflow(system,'solve');
                Pmec_pu = LF.sm.Pmec/LF.sm.Pnom;    % Correct value
                Vf0 = LF.sm.Vf;                     % Correct value
                Vt0 = abs(LF.sm.Vt);                % Correct value
                Vref = Vt0;
                out = sim(system,'AbsTol','1e-5','StartTime','0','StopTime',simulationTime);

                % calculate symmetric components and extract the data
                [V_0, V_1, V_2, I_0, I_1, I_2, time] = ...
                    generatesSymmetricComponent(out.dados_ph_pu,insertNoise,plotSymetricalComponents);
                
                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                % Fuzzy classifier file 
                isFuzzy = 1;
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\"  ] )
                f=dir('*.mat'); 
                delete(f.name)                   

                % generates saturated and normalized components
                [V_0, V_1, V_2, I_0, I_1, I_2] = ...
                    saturatesAndNormalizesSymmetricComponents(V_0, V_1, V_2, ...
                    I_0, I_1, I_2,maxV,maxI); 

                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                isFuzzy = 0;                
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\" ] )
                f=dir('*.mat'); 
                delete(f.name)  
            end

        case 'DPFH06'
            mkdir DPFH06
            name = "DPFH06";
            for numero = 1:numberExamplesEachCase
                % select phase fault
                if numero <= numberExamplesEachCase/3
                    system = 'DPFH06_AB'; 
                elseif numero <= numberExamplesEachCase*2/3
                    system = 'DPFH06_CA';
                else
                    system = 'DPFH06_BC';
                end

                [Pref, Pref_pu, Qref] = powerReference(Snom,pfRange,operNormal,powerMin);
                tend = tbeg + ramdomValue(faultDuration(1),faultDuration(2));
                trig = tend;
                Ron = ramdomValue(faultResistence(1),faultResistence(2));
                Rg = ramdomValue(faultResistence(1),faultResistence(2));

                % runs the power flow and the simulink simulation
                Vref = 1;           % initialize variable
                Pmec_pu = Pref_pu;  % initialize variable with any value
                Vf0 = 1.2;          % initialize variable with any value
                Vt0 = 1;            % initialize variable with any value
                LF = power_loadflow(system,'solve');
                Pmec_pu = LF.sm.Pmec/LF.sm.Pnom;    % Correct value
                Vf0 = LF.sm.Vf;                     % Correct value
                Vt0 = abs(LF.sm.Vt);                % Correct value
                Vref = Vt0;
                out = sim(system,'AbsTol','1e-5','StartTime','0','StopTime',simulationTime);

                % calculate symmetric components and extract the data
                [V_0, V_1, V_2, I_0, I_1, I_2, time] = ...
                    generatesSymmetricComponent(out.dados_ph_pu,insertNoise,plotSymetricalComponents);
                
                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                % Fuzzy classifier file 
                isFuzzy = 1;
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\"  ] )
                f=dir('*.mat'); 
                delete(f.name)                   

                % generates saturated and normalized components
                [V_0, V_1, V_2, I_0, I_1, I_2] = ...
                    saturatesAndNormalizesSymmetricComponents(V_0, V_1, V_2, ...
                    I_0, I_1, I_2,maxV,maxI); 

                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                isFuzzy = 0;                
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\" ] )
                f=dir('*.mat'); 
                delete(f.name)  
            end
            %
        case 'DPFL07'
            mkdir DPFL07
            name = "DPFL07";
            for numero = 1:numberExamplesEachCase
                % select phase fault
                if numero <= numberExamplesEachCase/3
                    system = 'DPFL07_AB';
                elseif numero <= numberExamplesEachCase*2/3
                    system = 'DPFL07_CA';
                else
                    system = 'DPFL07_BC';
                end

                [Pref, Pref_pu, Qref] = powerReference(Snom,pfRange,operNormal,powerMin);
                tend = tbeg + ramdomValue(faultDuration(1),faultDuration(2));
                trig = tend;
                Ron = ramdomValue(faultResistence(1),faultResistence(2));
                Rg = ramdomValue(faultResistence(1),faultResistence(2));

                % runs the power flow and the simulink simulation
                Vref = 1;           % initialize variable
                Pmec_pu = Pref_pu;  % initialize variable with any value
                Vf0 = 1.2;          % initialize variable with any value
                Vt0 = 1;            % initialize variable with any value
                LF = power_loadflow(system,'solve');
                Pmec_pu = LF.sm.Pmec/LF.sm.Pnom;    % Correct value
                Vf0 = LF.sm.Vf;                     % Correct value
                Vt0 = abs(LF.sm.Vt);                % Correct value
                Vref = Vt0;
                out = sim(system,'AbsTol','1e-5','StartTime','0','StopTime',simulationTime);

                % calculate symmetric components and extract the data
                [V_0, V_1, V_2, I_0, I_1, I_2, time] = ...
                    generatesSymmetricComponent(out.dados_ph_pu,insertNoise,plotSymetricalComponents);
                
                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                % Fuzzy classifier file 
                isFuzzy = 1;
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\"  ] )
                f=dir('*.mat'); 
                delete(f.name)                   

                % generates saturated and normalized components
                [V_0, V_1, V_2, I_0, I_1, I_2] = ...
                    saturatesAndNormalizesSymmetricComponents(V_0, V_1, V_2, ...
                    I_0, I_1, I_2,maxV,maxI); 

                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                isFuzzy = 0;                
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\" ] )
                f=dir('*.mat'); 
                delete(f.name)  
            end
            %
        case 'DGFH08'
            mkdir DGFH08
            name = "DGFH08";
            for numero = 1:numberExamplesEachCase
                % select phase fault
                if numero <= numberExamplesEachCase/3
                    system = 'DGFH08_ABG';
                elseif numero <= numberExamplesEachCase*2/3
                    system = 'DGFH08_CAG';
                else
                    system = 'DGFH08_BCG';
                end

                [Pref, Pref_pu, Qref] = powerReference(Snom,pfRange,operNormal,powerMin);
                tend = tbeg + ramdomValue(faultDuration(1),faultDuration(2));
                trig = tend;
                Ron = ramdomValue(faultResistence(1),faultResistence(2));
                Rg = ramdomValue(faultResistence(1),faultResistence(2));

                % runs the power flow and the simulink simulation
                Vref = 1;           % initialize variable
                Pmec_pu = Pref_pu;  % initialize variable with any value
                Vf0 = 1.2;          % initialize variable with any value
                Vt0 = 1;            % initialize variable with any value
                LF = power_loadflow(system,'solve');
                Pmec_pu = LF.sm.Pmec/LF.sm.Pnom;    % Correct value
                Vf0 = LF.sm.Vf;                     % Correct value
                Vt0 = abs(LF.sm.Vt);                % Correct value
                Vref = Vt0;
                out = sim(system,'AbsTol','1e-5','StartTime','0','StopTime',simulationTime);

                % calculate symmetric components and extract the data
                [V_0, V_1, V_2, I_0, I_1, I_2, time] = ...
                    generatesSymmetricComponent(out.dados_ph_pu,insertNoise,plotSymetricalComponents);
                
                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                % Fuzzy classifier file 
                isFuzzy = 1;
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\"  ] )
                f=dir('*.mat'); 
                delete(f.name)                   

                % generates saturated and normalized components
                [V_0, V_1, V_2, I_0, I_1, I_2] = ...
                    saturatesAndNormalizesSymmetricComponents(V_0, V_1, V_2, ...
                    I_0, I_1, I_2,maxV,maxI); 

                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                isFuzzy = 0;                
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\" ] )
                f=dir('*.mat'); 
                delete(f.name)  
            end
            %
        case 'DGFL09'
            mkdir DGFL09
            name = "DGFL09";
            for numero = 1:numberExamplesEachCase
                % select phase fault
                if numero <= numberExamplesEachCase/3
                    system = 'DGFL09_ABG'; 
                elseif numero <= numberExamplesEachCase*2/3
                    system = 'DGFL09_CAG';
                else
                    system = 'DGFL09_BCG';
                end

                [Pref, Pref_pu, Qref] = powerReference(Snom,pfRange,operNormal,powerMin);
                tend = tbeg + ramdomValue(faultDuration(1),faultDuration(2));
                trig = tend;
                Ron = ramdomValue(faultResistence(1),faultResistence(2));
                Rg = ramdomValue(faultResistence(1),faultResistence(2));

                % runs the power flow and the simulink simulation
                Vref = 1;           % initialize variable
                Pmec_pu = Pref_pu;  % initialize variable with any value
                Vf0 = 1.2;          % initialize variable with any value
                Vt0 = 1;            % initialize variable with any value
                LF = power_loadflow(system,'solve');
                Pmec_pu = LF.sm.Pmec/LF.sm.Pnom;    % Correct value
                Vf0 = LF.sm.Vf;                     % Correct value
                Vt0 = abs(LF.sm.Vt);                % Correct value
                Vref = Vt0;
                out = sim(system,'AbsTol','1e-5','StartTime','0','StopTime',simulationTime);

                % calculate symmetric components and extract the data
                [V_0, V_1, V_2, I_0, I_1, I_2, time] = ...
                    generatesSymmetricComponent(out.dados_ph_pu,insertNoise,plotSymetricalComponents);
                
                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                % Fuzzy classifier file 
                isFuzzy = 1;
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\"  ] )
                f=dir('*.mat'); 
                delete(f.name)                   

                % generates saturated and normalized components
                [V_0, V_1, V_2, I_0, I_1, I_2] = ...
                    saturatesAndNormalizesSymmetricComponents(V_0, V_1, V_2, ...
                    I_0, I_1, I_2,maxV,maxI); 

                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                isFuzzy = 0;                
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\" ] )
                f=dir('*.mat'); 
                delete(f.name)  
            end

        case 'SGFH10'
            mkdir SGFH10
            name = "SGFH10";
            for numero = 1:numberExamplesEachCase
                system = 'SGFH10'; 

                [Pref, Pref_pu, Qref] = powerReference(Snom,pfRange,operNormal,powerMin);
                tend = tbeg + ramdomValue(faultDuration(1),faultDuration(2));
                trig = tend;
                Ron = ramdomValue(faultResistence(1),faultResistence(2));
                Rg = ramdomValue(faultResistence(1),faultResistence(2));

                % runs the power flow and the simulink simulation
                Vref = 1;           % initialize variable
                Pmec_pu = Pref_pu;  % initialize variable with any value
                Vf0 = 1.2;          % initialize variable with any value
                Vt0 = 1;            % initialize variable with any value
                LF = power_loadflow(system,'solve');
                Pmec_pu = LF.sm.Pmec/LF.sm.Pnom;    % Correct value
                Vf0 = LF.sm.Vf;                     % Correct value
                Vt0 = abs(LF.sm.Vt);                % Correct value
                Vref = Vt0;
                out = sim(system,'AbsTol','1e-5','StartTime','0','StopTime',simulationTime);

                % calculate symmetric components and extract the data
                [V_0, V_1, V_2, I_0, I_1, I_2, time] = ...
                    generatesSymmetricComponent(out.dados_ph_pu,insertNoise,plotSymetricalComponents);
                
                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                % Fuzzy classifier file 
                isFuzzy = 1;
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\"  ] )
                f=dir('*.mat'); 
                delete(f.name)                   

                % generates saturated and normalized components
                [V_0, V_1, V_2, I_0, I_1, I_2] = ...
                    saturatesAndNormalizesSymmetricComponents(V_0, V_1, V_2, ...
                    I_0, I_1, I_2,maxV,maxI); 

                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                isFuzzy = 0;                
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\" ] )
                f=dir('*.mat'); 
                delete(f.name)  
            end
            %
        case 'SGFL11'
            mkdir SGFL11
            name = "SGFL11";
            for numero = 1:numberExamplesEachCase
                system = 'SGFL11';

                [Pref, Pref_pu, Qref] = powerReference(Snom,pfRange,operNormal,powerMin);
                tend = tbeg + ramdomValue(faultDuration(1),faultDuration(2));
                trig = tend;
                Ron = ramdomValue(faultResistence(1),faultResistence(2));
                Rg = ramdomValue(faultResistence(1),faultResistence(2));

                % runs the power flow and the simulink simulation
                Vref = 1;           % initialize variable
                Pmec_pu = Pref_pu;  % initialize variable with any value
                Vf0 = 1.2;          % initialize variable with any value
                Vt0 = 1;            % initialize variable with any value
                LF = power_loadflow(system,'solve');
                Pmec_pu = LF.sm.Pmec/LF.sm.Pnom;    % Correct value
                Vf0 = LF.sm.Vf;                     % Correct value
                Vt0 = abs(LF.sm.Vt);                % Correct value
                Vref = Vt0;
                out = sim(system,'AbsTol','1e-5','StartTime','0','StopTime',simulationTime);

                % calculate symmetric components and extract the data
                [V_0, V_1, V_2, I_0, I_1, I_2, time] = ...
                    generatesSymmetricComponent(out.dados_ph_pu,insertNoise,plotSymetricalComponents);
                
                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                % Fuzzy classifier file 
                isFuzzy = 1;
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\"  ] )
                f=dir('*.mat'); 
                delete(f.name)                   

                % generates saturated and normalized components
                [V_0, V_1, V_2, I_0, I_1, I_2] = ...
                    saturatesAndNormalizesSymmetricComponents(V_0, V_1, V_2, ...
                    I_0, I_1, I_2,maxV,maxI); 

                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                isFuzzy = 0;                
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\" ] )
                f=dir('*.mat'); 
                delete(f.name)  
            end
            
        case 'SPTH12'
            mkdir SPTH12
            name = "SPTH12";
            for numero = 1:numberExamplesEachCase
                % select phase fault
                if numero <= numberExamplesEachCase/3
                    system = 'SPTH12_AG';
                elseif numero <= numberExamplesEachCase*2/3
                    system = 'SPTH12_BG';
                else
                    system = 'SPTH12_CG';
                end
                
                [Pref, Pref_pu, Qref] = powerReference(Snom,pfRange,operNormal,powerMin);
                tend = tbeg + ramdomValue(temporaryFaultDuration(1),temporaryFaultDuration(2));
                trig = 1e3;
                Ron = ramdomValue(faultResistence(1),faultResistence(2));
                Rg = ramdomValue(faultResistence(1),faultResistence(2));

                % runs the power flow and the simulink simulation
                Vref = 1;           % initialize variable
                Pmec_pu = Pref_pu;  % initialize variable with any value
                Vf0 = 1.2;          % initialize variable with any value
                Vt0 = 1;            % initialize variable with any value
                LF = power_loadflow(system,'solve');
                Pmec_pu = LF.sm.Pmec/LF.sm.Pnom;    % Correct value
                Vf0 = LF.sm.Vf;                     % Correct value
                Vt0 = abs(LF.sm.Vt);                % Correct value
                Vref = Vt0;
                out = sim(system,'AbsTol','1e-5','StartTime','0','StopTime',simulationTime);

                % calculate symmetric components and extract the data
                [V_0, V_1, V_2, I_0, I_1, I_2, time] = ...
                    generatesSymmetricComponent(out.dados_ph_pu,insertNoise,plotSymetricalComponents);
                
                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                % Fuzzy classifier file 
                isFuzzy = 1;
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\"  ] )
                f=dir('*.mat'); 
                delete(f.name)                   

                % generates saturated and normalized components
                [V_0, V_1, V_2, I_0, I_1, I_2] = ...
                    saturatesAndNormalizesSymmetricComponents(V_0, V_1, V_2, ...
                    I_0, I_1, I_2,maxV,maxI); 

                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                isFuzzy = 0;                
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\" ] )
                f=dir('*.mat'); 
                delete(f.name)  
            end

        case 'DPTH13'
            mkdir DPTH13
            name = "DPTH13";
            for numero = 1:numberExamplesEachCase
                % select phase fault
                if numero <= numberExamplesEachCase/3
                    system = 'DPTH13_AB';
                elseif numero <= numberExamplesEachCase*2/3
                    system = 'DPTH13_BC';
                else
                    system = 'DPTH13_CA';
                end

                [Pref, Pref_pu, Qref] = powerReference(Snom,pfRange,operNormal,powerMin);
                tend = tbeg + ramdomValue(temporaryFaultDuration(1),temporaryFaultDuration(2));
                trig = 1e3;
                Ron = ramdomValue(faultResistence(1),faultResistence(2));
                Rg = ramdomValue(faultResistence(1),faultResistence(2));

                % runs the power flow and the simulink simulation
                Vref = 1;           % initialize variable
                Pmec_pu = Pref_pu;  % initialize variable with any value
                Vf0 = 1.2;          % initialize variable with any value
                Vt0 = 1;            % initialize variable with any value
                LF = power_loadflow(system,'solve');
                Pmec_pu = LF.sm.Pmec/LF.sm.Pnom;    % Correct value
                Vf0 = LF.sm.Vf;                     % Correct value
                Vt0 = abs(LF.sm.Vt);                % Correct value
                Vref = Vt0;
                out = sim(system,'AbsTol','1e-5','StartTime','0','StopTime',simulationTime);

                % calculate symmetric components and extract the data
                [V_0, V_1, V_2, I_0, I_1, I_2, time] = ...
                    generatesSymmetricComponent(out.dados_ph_pu,insertNoise,plotSymetricalComponents);
                
                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                % Fuzzy classifier file 
                isFuzzy = 1;
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\"  ] )
                f=dir('*.mat'); 
                delete(f.name)                   

                % generates saturated and normalized components
                [V_0, V_1, V_2, I_0, I_1, I_2] = ...
                    saturatesAndNormalizesSymmetricComponents(V_0, V_1, V_2, ...
                    I_0, I_1, I_2,maxV,maxI); 

                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                isFuzzy = 0;                
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\" ] )
                f=dir('*.mat'); 
                delete(f.name)  
            end

        case 'DGTH14'
            mkdir DGTH14
            name = "DGTH14";
            for numero = 1:numberExamplesEachCase
                % select phase fault
                if numero <= numberExamplesEachCase/3
                    system = 'DGTH14_ABG';
                elseif numero <= numberExamplesEachCase*2/3
                    system = 'DGTH14_BCG';
                else
                    system = 'DGTH14_CAG';
                end

                [Pref, Pref_pu, Qref] = powerReference(Snom,pfRange,operNormal,powerMin);
                tend = tbeg + ramdomValue(temporaryFaultDuration(1),temporaryFaultDuration(2));
                trig = 1e3;
                Ron = ramdomValue(faultResistence(1),faultResistence(2));
                Rg = ramdomValue(faultResistence(1),faultResistence(2));

                % runs the power flow and the simulink simulation
                Vref = 1;           % initialize variable
                Pmec_pu = Pref_pu;  % initialize variable with any value
                Vf0 = 1.2;          % initialize variable with any value
                Vt0 = 1;            % initialize variable with any value
                LF = power_loadflow(system,'solve');
                Pmec_pu = LF.sm.Pmec/LF.sm.Pnom;    % Correct value
                Vf0 = LF.sm.Vf;                     % Correct value
                Vt0 = abs(LF.sm.Vt);                % Correct value
                Vref = Vt0;
                out = sim(system,'AbsTol','1e-5','StartTime','0','StopTime',simulationTime);

                % calculate symmetric components and extract the data
                [V_0, V_1, V_2, I_0, I_1, I_2, time] = ...
                    generatesSymmetricComponent(out.dados_ph_pu,insertNoise,plotSymetricalComponents);
                
                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                % Fuzzy classifier file 
                isFuzzy = 1;
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\"  ] )
                f=dir('*.mat'); 
                delete(f.name)                   

                % generates saturated and normalized components
                [V_0, V_1, V_2, I_0, I_1, I_2] = ...
                    saturatesAndNormalizesSymmetricComponents(V_0, V_1, V_2, ...
                    I_0, I_1, I_2,maxV,maxI); 

                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                isFuzzy = 0;                
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\" ] )
                f=dir('*.mat'); 
                delete(f.name)  
            end   

        case 'SGTH15'
            mkdir SGTH15
            name = "SGTH15";
            for numero = 1:numberExamplesEachCase
                system = 'SGTH15';

                [Pref, Pref_pu, Qref] = powerReference(Snom,pfRange,operNormal,powerMin);
                tend = tbeg + ramdomValue(temporaryFaultDuration(1),temporaryFaultDuration(2));
                trig = 1e3;
                Ron = ramdomValue(faultResistence(1),faultResistence(2));
                Rg = ramdomValue(faultResistence(1),faultResistence(2));

                % runs the power flow and the simulink simulation
                Vref = 1;           % initialize variable
                Pmec_pu = Pref_pu;  % initialize variable with any value
                Vf0 = 1.2;          % initialize variable with any value
                Vt0 = 1;            % initialize variable with any value
                LF = power_loadflow(system,'solve');
                Pmec_pu = LF.sm.Pmec/LF.sm.Pnom;    % Correct value
                Vf0 = LF.sm.Vf;                     % Correct value
                Vt0 = abs(LF.sm.Vt);                % Correct value
                Vref = Vt0;
                out = sim(system,'AbsTol','1e-5','StartTime','0','StopTime',simulationTime);

                % calculate symmetric components and extract the data
                [V_0, V_1, V_2, I_0, I_1, I_2, time] = ...
                    generatesSymmetricComponent(out.dados_ph_pu,insertNoise,plotSymetricalComponents);
                
                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                % Fuzzy classifier file 
                isFuzzy = 1;
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\"  ] )
                f=dir('*.mat'); 
                delete(f.name)                   

                % generates saturated and normalized components
                [V_0, V_1, V_2, I_0, I_1, I_2] = ...
                    saturatesAndNormalizesSymmetricComponents(V_0, V_1, V_2, ...
                    I_0, I_1, I_2,maxV,maxI); 

                % Generate the file in .mat, copy it to the event-related
                % folder and delete the file in the current directory 
                isFuzzy = 0;                
                fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, ...
                    numero, name, size2D, isFuzzy);
                copyfile([currentFolder + "\" + fileID],...
                    [currentFolder + "\" + name + "\" ] )
                f=dir('*.mat'); 
                delete(f.name)  
            end        

        otherwise
            disp('ERROR. CASE NOT DEFINED.')
    end
end
warning('on','all')

