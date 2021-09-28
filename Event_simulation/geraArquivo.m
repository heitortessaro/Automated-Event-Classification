function ID = geraArquivo(V_0, V_1, V_2, I_0, I_1, I_2, numero, name)
    % Gera o arquivo com os dados dos fasores de tensão e corrente
    % o numero define o indice do arquivo
    numero_str = string(numero);
    formato = ".txt";
    values = [V_0'; V_1'; V_2'; I_0'; I_1'; I_2';];
    ID = name + numero_str + formato;
    fileID = fopen(ID,'w');
    formatSpec = '%6.8f, %6.8f, %6.8f, %6.8f, %6.8f, %6.8f\n';
    fprintf(fileID,formatSpec,values);
    fclose(fileID);
end