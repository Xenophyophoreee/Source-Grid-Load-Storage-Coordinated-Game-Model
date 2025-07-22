%% �����ĸ������ݻ�����
%% ��ʼ����
model_NE = RenewableEnergyModel();
model_ESS = ElectrochemicalStorageModel();
model_HPS = PumpedStorageModel();
model_H2 = HydrogenStorageModel();

%% ���þ��߱�����Χ
windCapacityRange = [10000, 20000]; % ���������Χ (kW)
solarCapacityRange = [10000, 20000]; % ���������Χ (kW)
storageCapacityESSRange = [2000, 5000]; % �绯ѧ����������Χ (kW)
storageCapacityHPSRange = [5000, 10000]; % ��ˮ����������Χ (kW)
electrolyzerCapacityRange = [1000, 5000]; % ����������Χ (kW)
storageTankCapacityRange = [1000, 5000]; % �����������Χ (kW)
fuelCellCapacityRange = [1000, 5000]; % ��ȼ�ϵ��������Χ (kW)

%% ��ʼ�������߲��ԣ���ʼ���ĸ������ߵľ��߱�����
strategiesPlayer1 = [15000, 12000]; % ����Դ���� (windCapacity, solarCapacity)
strategiesPlayer2 = [3000]; % �绯ѧ���ܲ��� (storageCapacity_ESS)
strategiesPlayer3 = [6000]; % ��ˮ���ܲ��� (storageCapacity_HPS)
strategiesPlayer4 = [3000, 2000, 2000]; % �ⴢ�ܲ��� (electrolyzerCapacity, storageTankCapacity, fuelCellCapacity)

%% ģ������
% ����Դ��ģ������
windOutput = rand(1, 365 * 24 * 4); % ������ռװ�������ٷֱ� (%)
solarOutput = rand(1, 365 * 24 * 4); % �������ռװ�������ٷֱ� (%)

%% �ݻ�����ģ��
numIterations = 25; % ��������
learningRate = 0.05; % ���Ե�����ѧϰ��

% ��ʼ���������ڻ���ͼ��
decisionVariablesHistory = zeros(numIterations, 7); % �洢���߱�������ʷ��¼
netBenefitHistory = zeros(numIterations, 1); % �洢��Ч�����ʷ��¼

for iter = 1:numIterations
    % ģ����������
    windCapacity = strategiesPlayer1(1); % ������� (kW)
    solarCapacity = strategiesPlayer1(2); % ������� (kW)
    storageCapacity_ESS = strategiesPlayer2(1); % ����װ������ (kW)
    storageCapacity_HPS = strategiesPlayer3(1); % ��ˮ����װ������ (kW)
    electrolyzerCapacity = strategiesPlayer4(1); % �������� (kW)
    storageTankCapacity = strategiesPlayer4(2); % ��������� (kW)
    fuelCellCapacity = strategiesPlayer4(3); % ��ȼ�ϵ������ (kW)
    
    % ��������Դ������15min��
    windPower_15min = windOutput * windCapacity; % ��繦�� (kW)
    solarPower_15min = solarOutput * solarCapacity; % ������� (kW)

    % ���㹦�ʲ�����
    % ����15min������
    % ������������15���ӹ���ֵ�ı仯������ֵ��
    windPower_15min_diff = diff(windPower_15min); % ��繦�ʲ�ֵ (kW)
    solarPower_15min_diff = diff(solarPower_15min); % ������ʲ�ֵ (kW)

    % ÿ1Сʱ��4��15���ӵ����ݣ���˿��Խ�15������������Ϊ1Сʱ������
    windPower_1h = sum(reshape(windPower_15min, [4, length(windPower_15min)/4]), 1); % ��繦�� (kW/Сʱ)
    solarPower_1h = sum(reshape(solarPower_15min, [4, length(solarPower_15min)/4]), 1); % ������� (kW/Сʱ)
    % ����1Сʱ�߶Ȳ�����
    windPower_1h_diff = diff(windPower_1h); % ��繦�ʲ�ֵ (kW/Сʱ)
    solarPower_1h_diff = diff(solarPower_1h); % ������ʲ�ֵ (kW/Сʱ)

    % ÿ1����24Сʱ�����ݣ���˿��Խ�1Сʱ��������Ϊ1�������
    windPower_1d = sum(reshape(windPower_1h, [24, length(windPower_1h)/24]), 1); % ��繦�� (kW/��)
    solarPower_1d = sum(reshape(solarPower_1h, [24, length(solarPower_1h)/24]), 1); % ������� (kW/��)
    % ����1��߶Ȳ�����
    windPower_1d_diff = diff(windPower_1d); % ��繦�ʲ�ֵ (kWh/��)
    solarPower_1d_diff = diff(solarPower_1d); % ������ʲ�ֵ (kWh/��)

    % ����Դ��绯ѧ����ģ������
    windPower_15min_diff(windPower_15min_diff > storageCapacity_ESS) = storageCapacity_ESS;      % ����װ������
    windPower_15min_diff(windPower_15min_diff < -storageCapacity_ESS) = -storageCapacity_ESS;    % С��װ������
    solarPower_15min_diff(solarPower_15min_diff > storageCapacity_ESS) = storageCapacity_ESS;      % ����װ������
    solarPower_15min_diff(solarPower_15min_diff < -storageCapacity_ESS) = -storageCapacity_ESS;    % С��װ������

    windEnergy_15min = windPower_15min_diff;
    solarEnergy_15min = solarPower_15min_diff;
    combinedEnergy_15min = windEnergy_15min + solarEnergy_15min;
    combinedEnergy_15min(combinedEnergy_15min > storageCapacity_ESS) = storageCapacity_ESS;      % ����װ������
    combinedEnergy_15min(combinedEnergy_15min < -storageCapacity_ESS) = -storageCapacity_ESS;    % С��װ������

    % ����ֵ��ȡ���������������ֵ��tradingPower_ESS_15min
    tradingPower_ESS_15min = zeros(size(combinedEnergy_15min)); % ��ʼ������Ϊ��
    tradingPower_ESS_15min(combinedEnergy_15min < 0) = abs(combinedEnergy_15min(combinedEnergy_15min < 0)); % ֻ������ֵ�ľ���ֵ

    % ����Դ���ˮ����ģ������
    windPower_1h_diff(windPower_1h_diff > storageCapacity_HPS) = storageCapacity_HPS;      % ����װ������
    windPower_1h_diff(windPower_1h_diff < -storageCapacity_HPS) = -storageCapacity_HPS;    % С��װ������
    solarPower_1h_diff(solarPower_1h_diff > storageCapacity_HPS) = storageCapacity_HPS;      % ����װ������
    solarPower_1h_diff(solarPower_1h_diff < -storageCapacity_HPS) = -storageCapacity_HPS;    % С��װ������

    windEnergy_1h = windPower_1h_diff;
    solarEnergy_1h = solarPower_1h_diff;
    combinedEnergy_1h = windEnergy_1h + solarEnergy_1h;
    combinedEnergy_1h(combinedEnergy_1h > storageCapacity_HPS) = storageCapacity_HPS;      % ����װ������
    combinedEnergy_1h(combinedEnergy_1h < -storageCapacity_HPS) = -storageCapacity_HPS;    % С��װ������
    % ����ֵ��ȡ���������������ֵ��tradingPower_HPS_1h
    tradingPower_HPS_1h = zeros(size(combinedEnergy_1h)); % ��ʼ������Ϊ��
    tradingPower_HPS_1h(combinedEnergy_1h < 0) = abs(combinedEnergy_1h(combinedEnergy_1h < 0)); % ֻ������ֵ�ľ���ֵ

    % ����Դ���ⴢ��ģ������
    windPower_1d_diff(windPower_1d_diff > (electrolyzerCapacity + storageTankCapacity + fuelCellCapacity)) = (electrolyzerCapacity + storageTankCapacity + fuelCellCapacity);      % ����װ������
    windPower_1d_diff(windPower_1d_diff < -(electrolyzerCapacity + storageTankCapacity + fuelCellCapacity)) = -(electrolyzerCapacity + storageTankCapacity + fuelCellCapacity);    % С��װ������
    solarPower_1d_diff(solarPower_1d_diff > (electrolyzerCapacity + storageTankCapacity + fuelCellCapacity)) = (electrolyzerCapacity + storageTankCapacity + fuelCellCapacity);      % ����װ������
    solarPower_1d_diff(solarPower_1d_diff < -(electrolyzerCapacity + storageTankCapacity + fuelCellCapacity)) = -(electrolyzerCapacity + storageTankCapacity + fuelCellCapacity);    % С��װ������

    windEnergy_1d = windPower_1d_diff;
    solarEnergy_1d = solarPower_1d_diff;
    combinedEnergy_1d = windEnergy_1d + solarEnergy_1d;
    combinedEnergy_1d(combinedEnergy_1d > (electrolyzerCapacity + storageTankCapacity + fuelCellCapacity)) = (electrolyzerCapacity + storageTankCapacity + fuelCellCapacity);      % ����װ������
    combinedEnergy_1d(combinedEnergy_1d < -(electrolyzerCapacity + storageTankCapacity + fuelCellCapacity)) = -(electrolyzerCapacity + storageTankCapacity + fuelCellCapacity);    % С��װ������
    % ����ֵ��ȡ���������������ֵ��tradingPower_H2_1d
    tradingPower_H2_1d = zeros(size(combinedEnergy_1d)); % ��ʼ������Ϊ��
    tradingPower_H2_1d(combinedEnergy_1d < 0) = abs(combinedEnergy_1d(combinedEnergy_1d < 0)); % ֻ������ֵ�ľ���ֵ

    % ����������Դ���׵ĳ�繦���ܺͼ��� (kW)
    % �������
    tradingPower_NE = repmat([tradingPower_H2_1d, 0], 1, 24 * 4) + repmat([tradingPower_HPS_1h, 0], 1, 4) + [tradingPower_ESS_15min, 0];
    
    % ���㵱ǰ�����µ��ܾ�Ч��
    currentBenefit = model_NE.calculateNetBenefit(windOutput, solarOutput, strategiesPlayer1(1), strategiesPlayer1(2), tradingPower_NE) +...
        model_ESS.calculateNetBenefit(windEnergy_15min, solarEnergy_15min, tradingPower_ESS_15min, strategiesPlayer2(1)) +...
        model_HPS.calculateNetBenefit(windEnergy_1h, solarEnergy_1h, tradingPower_HPS_1h, strategiesPlayer3(1))+...
        model_H2.calculateNetBenefit(windEnergy_1d, solarEnergy_1d, tradingPower_H2_1d, strategiesPlayer4(1), strategiesPlayer4(2), strategiesPlayer4(3));
    
    % ���������߸��ݵ�ǰ���Ե����Լ��ľ���
    % 1. ����Դ��ҵ�������
    bestBenefitPlayer1 = currentBenefit;
    bestStrategiesPlayer1 = strategiesPlayer1;
    for deltaWind = -500:500:500
        for deltaSolar = -500:500:500
            newStrategiesPlayer1 = strategiesPlayer1 + [deltaWind, deltaSolar];
            % ȷ���µĲ����ڷ�Χ��
            if newStrategiesPlayer1(1) < windCapacityRange(1) || newStrategiesPlayer1(1) > windCapacityRange(2) || ...
               newStrategiesPlayer1(2) < solarCapacityRange(1) || newStrategiesPlayer1(2) > solarCapacityRange(2)
                continue;
            end
            newBenefitPlayer1 = model_NE.calculateNetBenefit(windOutput, solarOutput, newStrategiesPlayer1(1), newStrategiesPlayer1(2), tradingPower_NE) +...
                model_ESS.calculateNetBenefit(windEnergy_15min, solarEnergy_15min, tradingPower_ESS_15min, strategiesPlayer2(1)) +...
                model_HPS.calculateNetBenefit(windEnergy_1h, solarEnergy_1h, tradingPower_HPS_1h, strategiesPlayer3(1))+...
                model_H2.calculateNetBenefit(windEnergy_1d, solarEnergy_1d, tradingPower_H2_1d, strategiesPlayer4(1), strategiesPlayer4(2), strategiesPlayer4(3));
            if newBenefitPlayer1 > bestBenefitPlayer1
                bestBenefitPlayer1 = newBenefitPlayer1;
                bestStrategiesPlayer1 = newStrategiesPlayer1;
            end
        end
    end
    strategiesPlayer1 = bestStrategiesPlayer1;
    
    % 2. �绯ѧ������ҵ�������
    bestBenefitPlayer2 = currentBenefit;
    bestStrategiesPlayer2 = strategiesPlayer2;
    
    for deltaESS = -500:500:500
        newStrategiesPlayer2 = strategiesPlayer2 + deltaESS;
        % ȷ���µĲ����ڷ�Χ��
        if newStrategiesPlayer2(1) < storageCapacityESSRange(1) || newStrategiesPlayer2(1) > storageCapacityESSRange(2)
            continue;
        end
        newBenefitPlayer2 = model_NE.calculateNetBenefit(windOutput, solarOutput, strategiesPlayer1(1), strategiesPlayer1(2), tradingPower_NE) +...
            model_ESS.calculateNetBenefit(windEnergy_15min, solarEnergy_15min, tradingPower_ESS_15min, newStrategiesPlayer2(1)) +...
            model_HPS.calculateNetBenefit(windEnergy_1h, solarEnergy_1h, tradingPower_HPS_1h, strategiesPlayer3(1))+...
            model_H2.calculateNetBenefit(windEnergy_1d, solarEnergy_1d, tradingPower_H2_1d, strategiesPlayer4(1), strategiesPlayer4(2), strategiesPlayer4(3));
        if newBenefitPlayer2 > bestBenefitPlayer2
            bestBenefitPlayer2 = newBenefitPlayer2;
            bestStrategiesPlayer2 = newStrategiesPlayer2;
        end
    end
    strategiesPlayer2 = bestStrategiesPlayer2;
    
    % 3. ��ˮ������ҵ�������
    bestBenefitPlayer3 = currentBenefit;
    bestStrategiesPlayer3 = strategiesPlayer3;
    
    for deltaHPS = -500:500:500
        newStrategiesPlayer3 = strategiesPlayer3 + deltaHPS;
        % ȷ���µĲ����ڷ�Χ��
        if newStrategiesPlayer3(1) < storageCapacityHPSRange(1) || newStrategiesPlayer3(1) > storageCapacityHPSRange(2)
            continue;
        end
        newBenefitPlayer3 = model_NE.calculateNetBenefit(windOutput, solarOutput, strategiesPlayer1(1), strategiesPlayer1(2), tradingPower_NE) +...
            model_ESS.calculateNetBenefit(windEnergy_15min, solarEnergy_15min, tradingPower_ESS_15min, strategiesPlayer2(1)) +...
            model_HPS.calculateNetBenefit(windEnergy_1h, solarEnergy_1h, tradingPower_HPS_1h, newStrategiesPlayer3(1))+...
            model_H2.calculateNetBenefit(windEnergy_1d, solarEnergy_1d, tradingPower_H2_1d, strategiesPlayer4(1), strategiesPlayer4(2), strategiesPlayer4(3));
        if newBenefitPlayer3 > bestBenefitPlayer3
            bestBenefitPlayer3 = newBenefitPlayer3;
            bestStrategiesPlayer3 = newStrategiesPlayer3;
        end
    end
    strategiesPlayer3 = bestStrategiesPlayer3;
    
    % 4. �ⴢ����ҵ�������
    bestBenefitPlayer4 = currentBenefit;
    bestStrategiesPlayer4 = strategiesPlayer4;
    
    for deltaElectrolyzer = -500:500:500
        for deltaTank = -500:500:500
            for deltaFuelCell = -500:500:500
                newStrategiesPlayer4 = strategiesPlayer4 + [deltaElectrolyzer, deltaTank, deltaFuelCell];
                % ȷ���µĲ����ڷ�Χ��
                if newStrategiesPlayer4(1) < electrolyzerCapacityRange(1) || newStrategiesPlayer4(1) > electrolyzerCapacityRange(2) || ...
                   newStrategiesPlayer4(2) < storageTankCapacityRange(1) || newStrategiesPlayer4(2) > storageTankCapacityRange(2) || ...
                   newStrategiesPlayer4(3) < fuelCellCapacityRange(1) || newStrategiesPlayer4(3) > fuelCellCapacityRange(2)
                    continue;
                end
                newBenefitPlayer4 = model_NE.calculateNetBenefit(windOutput, solarOutput, strategiesPlayer1(1), strategiesPlayer1(2), tradingPower_NE) +...
                    model_ESS.calculateNetBenefit(windEnergy_15min, solarEnergy_15min, tradingPower_ESS_15min, strategiesPlayer2(1)) +...
                    model_HPS.calculateNetBenefit(windEnergy_1h, solarEnergy_1h, tradingPower_HPS_1h, strategiesPlayer3(1))+...
                    model_H2.calculateNetBenefit(windEnergy_1d, solarEnergy_1d, tradingPower_H2_1d, newStrategiesPlayer4(1), newStrategiesPlayer4(2), newStrategiesPlayer4(3));
                if newBenefitPlayer4 > bestBenefitPlayer4
                    bestBenefitPlayer4 = newBenefitPlayer4;
                    bestStrategiesPlayer4 = newStrategiesPlayer4;
                end
            end
        end
    end
    strategiesPlayer4 = bestStrategiesPlayer4;
    
     % �洢��ǰ�����ľ��߱���
    decisionVariablesHistory(iter, :) = [strategiesPlayer1(1), strategiesPlayer1(2), strategiesPlayer2(1), ...
                                          strategiesPlayer3(1), strategiesPlayer4(1), ...
                                          strategiesPlayer4(2), strategiesPlayer4(3)];
    
    % �洢��ǰ�����ľ�Ч��
    netBenefitHistory(iter, :) = [bestBenefitPlayer4];                                  
                                      
    % �����ǰ���Ľ��
    fprintf('Iteration %d: Player 1 Benefit: %.2f, Player 2 Benefit: %.2f, Player 3 Benefit: %.2f, Player 4 Benefit: %.2f\n', ...
            iter, bestBenefitPlayer1, bestBenefitPlayer2, bestBenefitPlayer3, bestBenefitPlayer4);
end

% ���ƾ��߱����仯ͼ
figure;
subplot(2, 1, 1);
plot(1:numIterations, decisionVariablesHistory(:, 1), 'b-', 'LineWidth', 2); hold on;
plot(1:numIterations, decisionVariablesHistory(:, 2), 'r-', 'LineWidth', 2);
plot(1:numIterations, decisionVariablesHistory(:, 3), 'g-', 'LineWidth', 2);
plot(1:numIterations, decisionVariablesHistory(:, 4), 'c-', 'LineWidth', 2);
plot(1:numIterations, decisionVariablesHistory(:, 5), 'm-', 'LineWidth', 2);
plot(1:numIterations, decisionVariablesHistory(:, 6), 'y-', 'LineWidth', 2);
plot(1:numIterations, decisionVariablesHistory(:, 7), 'k-', 'LineWidth', 2);
xlabel('Iteration');
ylabel('Decision Variables');
legend({'Wind Capacity', 'Solar Capacity', 'ESS Capacity', 'HPS Capacity', 'Electrolyzer Capacity', 'Storage Tank Capacity', 'Fuel Cell Capacity'});
title('Decision Variables vs Iterations');

% ���ƾ�Ч��仯ͼ
subplot(2, 1, 2);
plot(1:numIterations, netBenefitHistory(:, 1), 'b-', 'LineWidth', 2);
xlabel('Iteration');
ylabel('Benefit');
legend({'Players Benefit'});
title('Total Benefit vs Iterations');




































