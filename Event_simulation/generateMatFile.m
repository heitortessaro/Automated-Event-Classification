function fileID = generateMatFile(V_0, V_1, V_2, I_0, I_1, I_2, number, name, size2D, isFuzzy)
    % Generates the file with voltage and current phasor data
    % The number defines the index of the file
    % size sets the size of the matrix generated with each phasor
    
    % append zeros to compose the correct size
    vectorSize = size2D^2;
    if size(V_0,1) > vectorSize
        V_0 = V_0(1:end-1,:);
        V_1 = V_1(1:end-1,:);
        V_2 = V_2(1:end-1,:);
        I_0 = I_0(1:end-1,:);
        I_1 = I_1(1:end-1,:);
        I_2 = I_2(1:end-1,:);
    else
        V_0(vectorSize) = 0;
        V_1(vectorSize) = 0;
        V_2(vectorSize) = 0;
        I_0(vectorSize) = 0;
        I_1(vectorSize) = 0;
        I_2(vectorSize) = 0;
    end
    
    % reshape to a 2d array with size defined by size2D
    V_0_2d = reshape(V_0, size2D, size2D);
    V_1_2d = reshape(V_1, size2D, size2D);
    V_2_2d = reshape(V_2, size2D, size2D);
	I_0_2d = reshape(I_0, size2D, size2D);
    I_1_2d = reshape(I_1, size2D, size2D);
    I_2_2d = reshape(I_2, size2D, size2D);
    
    % Group 2d matrices into one 3d
    matrizCompSimetricas = zeros(size2D, size2D, 6); 
	matrizCompSimetricas(:,:,1) = V_0_2d;
    matrizCompSimetricas(:,:,2) = V_1_2d;
    matrizCompSimetricas(:,:,3) = V_2_2d;
    matrizCompSimetricas(:,:,4) = I_0_2d;
    matrizCompSimetricas(:,:,5) = I_1_2d;
    matrizCompSimetricas(:,:,6) = I_2_2d;
    
    
    number_str = string(number);
    formato = ".mat";
    if isFuzzy == 1
        fileID = "Fuzzy" + name + "_" + number_str + formato;
    else
        fileID = name + "_" + number_str + formato;
    end
    save(fileID,'matrizCompSimetricas');
end