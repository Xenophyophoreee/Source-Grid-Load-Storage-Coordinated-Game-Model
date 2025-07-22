%% 进行四个主体演化博弈
%% 初始化类
model_NE = RenewableEnergyModel();
model_ESS = ElectrochemicalStorageModel();
model_HPS = PumpedStorageModel();
model_H2 = HydrogenStorageModel();

%% 设置决策变量范围
windCapacityRange = [10000, 20000]; % 风机容量范围 (kW)
solarCapacityRange = [10000, 20000]; % 光伏容量范围 (kW)
storageCapacityESSRange = [2000, 5000]; % 电化学储能容量范围 (kW)
storageCapacityHPSRange = [5000, 10000]; % 抽水蓄能容量范围 (kW)
electrolyzerCapacityRange = [1000, 5000]; % 电解槽容量范围 (kW)
storageTankCapacityRange = [1000, 5000]; % 储氢罐容量范围 (kW)
fuelCellCapacityRange = [1000, 5000]; % 氢燃料电池容量范围 (kW)

%% 初始化参与者策略（初始化四个参与者的决策变量）
strategiesPlayer1 = [15000, 12000]; % 新能源策略 (windCapacity, solarCapacity)
strategiesPlayer2 = [3000]; % 电化学储能策略 (storageCapacity_ESS)
strategiesPlayer3 = [6000]; % 抽水蓄能策略 (storageCapacity_HPS)
strategiesPlayer4 = [3000, 2000, 2000]; % 氢储能策略 (electrolyzerCapacity, storageTankCapacity, fuelCellCapacity)

%% 模拟数据
% 新能源侧模拟数据
windOutput = rand(1, 365 * 24 * 4); % 风电出力占装机容量百分比 (%)
solarOutput = rand(1, 365 * 24 * 4); % 光伏出力占装机容量百分比 (%)

%% 演化博弈模拟
numIterations = 25; % 迭代次数
learningRate = 0.05; % 策略调整的学习率

% 初始化变量用于绘制图形
decisionVariablesHistory = zeros(numIterations, 7); % 存储决策变量的历史记录
netBenefitHistory = zeros(numIterations, 1); % 存储净效益的历史记录

for iter = 1:numIterations
    % 模拟数据推算
    windCapacity = strategiesPlayer1(1); % 风机容量 (kW)
    solarCapacity = strategiesPlayer1(2); % 光伏容量 (kW)
    storageCapacity_ESS = strategiesPlayer2(1); % 储能装机容量 (kW)
    storageCapacity_HPS = strategiesPlayer3(1); % 抽水蓄能装机容量 (kW)
    electrolyzerCapacity = strategiesPlayer4(1); % 电解槽容量 (kW)
    storageTankCapacity = strategiesPlayer4(2); % 储氢罐容量 (kW)
    fuelCellCapacity = strategiesPlayer4(3); % 氢燃料电池容量 (kW)
    
    % 计算新能源出力（15min）
    windPower_15min = windOutput * windCapacity; % 风电功率 (kW)
    solarPower_15min = solarOutput * solarCapacity; % 光伏功率 (kW)

    % 计算功率波动量
    % 计算15min波动量
    % 波动量是相邻15分钟功率值的变化量（差值）
    windPower_15min_diff = diff(windPower_15min); % 风电功率差值 (kW)
    solarPower_15min_diff = diff(solarPower_15min); % 光伏功率差值 (kW)

    % 每1小时有4个15分钟的数据，因此可以将15分钟数据重组为1小时的数据
    windPower_1h = sum(reshape(windPower_15min, [4, length(windPower_15min)/4]), 1); % 风电功率 (kW/小时)
    solarPower_1h = sum(reshape(solarPower_15min, [4, length(solarPower_15min)/4]), 1); % 光伏功率 (kW/小时)
    % 计算1小时尺度波动量
    windPower_1h_diff = diff(windPower_1h); % 风电功率差值 (kW/小时)
    solarPower_1h_diff = diff(solarPower_1h); % 光伏功率差值 (kW/小时)

    % 每1天有24小时的数据，因此可以将1小时数据重组为1天的数据
    windPower_1d = sum(reshape(windPower_1h, [24, length(windPower_1h)/24]), 1); % 风电功率 (kW/天)
    solarPower_1d = sum(reshape(solarPower_1h, [24, length(solarPower_1h)/24]), 1); % 光伏功率 (kW/天)
    % 计算1天尺度波动量
    windPower_1d_diff = diff(windPower_1d); % 风电功率差值 (kWh/天)
    solarPower_1d_diff = diff(solarPower_1d); % 光伏功率差值 (kWh/天)

    % 新能源侧电化学储能模拟数据
    windPower_15min_diff(windPower_15min_diff > storageCapacity_ESS) = storageCapacity_ESS;      % 大于装机容量
    windPower_15min_diff(windPower_15min_diff < -storageCapacity_ESS) = -storageCapacity_ESS;    % 小于装机容量
    solarPower_15min_diff(solarPower_15min_diff > storageCapacity_ESS) = storageCapacity_ESS;      % 大于装机容量
    solarPower_15min_diff(solarPower_15min_diff < -storageCapacity_ESS) = -storageCapacity_ESS;    % 小于装机容量

    windEnergy_15min = windPower_15min_diff;
    solarEnergy_15min = solarPower_15min_diff;
    combinedEnergy_15min = windEnergy_15min + solarEnergy_15min;
    combinedEnergy_15min(combinedEnergy_15min > storageCapacity_ESS) = storageCapacity_ESS;      % 大于装机容量
    combinedEnergy_15min(combinedEnergy_15min < -storageCapacity_ESS) = -storageCapacity_ESS;    % 小于装机容量

    % 将负值提取出来，并保存绝对值到tradingPower_ESS_15min
    tradingPower_ESS_15min = zeros(size(combinedEnergy_15min)); % 初始化矩阵为零
    tradingPower_ESS_15min(combinedEnergy_15min < 0) = abs(combinedEnergy_15min(combinedEnergy_15min < 0)); % 只保留负值的绝对值

    % 新能源侧抽水蓄能模拟数据
    windPower_1h_diff(windPower_1h_diff > storageCapacity_HPS) = storageCapacity_HPS;      % 大于装机容量
    windPower_1h_diff(windPower_1h_diff < -storageCapacity_HPS) = -storageCapacity_HPS;    % 小于装机容量
    solarPower_1h_diff(solarPower_1h_diff > storageCapacity_HPS) = storageCapacity_HPS;      % 大于装机容量
    solarPower_1h_diff(solarPower_1h_diff < -storageCapacity_HPS) = -storageCapacity_HPS;    % 小于装机容量

    windEnergy_1h = windPower_1h_diff;
    solarEnergy_1h = solarPower_1h_diff;
    combinedEnergy_1h = windEnergy_1h + solarEnergy_1h;
    combinedEnergy_1h(combinedEnergy_1h > storageCapacity_HPS) = storageCapacity_HPS;      % 大于装机容量
    combinedEnergy_1h(combinedEnergy_1h < -storageCapacity_HPS) = -storageCapacity_HPS;    % 小于装机容量
    % 将负值提取出来，并保存绝对值到tradingPower_HPS_1h
    tradingPower_HPS_1h = zeros(size(combinedEnergy_1h)); % 初始化矩阵为零
    tradingPower_HPS_1h(combinedEnergy_1h < 0) = abs(combinedEnergy_1h(combinedEnergy_1h < 0)); % 只保留负值的绝对值

    % 新能源测氢储能模拟数据
    windPower_1d_diff(windPower_1d_diff > (electrolyzerCapacity + storageTankCapacity + fuelCellCapacity)) = (electrolyzerCapacity + storageTankCapacity + fuelCellCapacity);      % 大于装机容量
    windPower_1d_diff(windPower_1d_diff < -(electrolyzerCapacity + storageTankCapacity + fuelCellCapacity)) = -(electrolyzerCapacity + storageTankCapacity + fuelCellCapacity);    % 小于装机容量
    solarPower_1d_diff(solarPower_1d_diff > (electrolyzerCapacity + storageTankCapacity + fuelCellCapacity)) = (electrolyzerCapacity + storageTankCapacity + fuelCellCapacity);      % 大于装机容量
    solarPower_1d_diff(solarPower_1d_diff < -(electrolyzerCapacity + storageTankCapacity + fuelCellCapacity)) = -(electrolyzerCapacity + storageTankCapacity + fuelCellCapacity);    % 小于装机容量

    windEnergy_1d = windPower_1d_diff;
    solarEnergy_1d = solarPower_1d_diff;
    combinedEnergy_1d = windEnergy_1d + solarEnergy_1d;
    combinedEnergy_1d(combinedEnergy_1d > (electrolyzerCapacity + storageTankCapacity + fuelCellCapacity)) = (electrolyzerCapacity + storageTankCapacity + fuelCellCapacity);      % 大于装机容量
    combinedEnergy_1d(combinedEnergy_1d < -(electrolyzerCapacity + storageTankCapacity + fuelCellCapacity)) = -(electrolyzerCapacity + storageTankCapacity + fuelCellCapacity);    % 小于装机容量
    % 将负值提取出来，并保存绝对值到tradingPower_H2_1d
    tradingPower_H2_1d = zeros(size(combinedEnergy_1d)); % 初始化矩阵为零
    tradingPower_H2_1d(combinedEnergy_1d < 0) = abs(combinedEnergy_1d(combinedEnergy_1d < 0)); % 只保留负值的绝对值

    % 储能与新能源交易的充电功率总和计算 (kW)
    % 补零对齐
    tradingPower_NE = repmat([tradingPower_H2_1d, 0], 1, 24 * 4) + repmat([tradingPower_HPS_1h, 0], 1, 4) + [tradingPower_ESS_15min, 0];
    
    % 计算当前策略下的总净效益
    currentBenefit = model_NE.calculateNetBenefit(windOutput, solarOutput, strategiesPlayer1(1), strategiesPlayer1(2), tradingPower_NE) +...
        model_ESS.calculateNetBenefit(windEnergy_15min, solarEnergy_15min, tradingPower_ESS_15min, strategiesPlayer2(1)) +...
        model_HPS.calculateNetBenefit(windEnergy_1h, solarEnergy_1h, tradingPower_HPS_1h, strategiesPlayer3(1))+...
        model_H2.calculateNetBenefit(windEnergy_1d, solarEnergy_1d, tradingPower_H2_1d, strategiesPlayer4(1), strategiesPlayer4(2), strategiesPlayer4(3));
    
    % 各个参与者根据当前策略调整自己的决策
    % 1. 新能源玩家调整策略
    bestBenefitPlayer1 = currentBenefit;
    bestStrategiesPlayer1 = strategiesPlayer1;
    for deltaWind = -500:500:500
        for deltaSolar = -500:500:500
            newStrategiesPlayer1 = strategiesPlayer1 + [deltaWind, deltaSolar];
            % 确保新的策略在范围内
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
    
    % 2. 电化学储能玩家调整策略
    bestBenefitPlayer2 = currentBenefit;
    bestStrategiesPlayer2 = strategiesPlayer2;
    
    for deltaESS = -500:500:500
        newStrategiesPlayer2 = strategiesPlayer2 + deltaESS;
        % 确保新的策略在范围内
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
    
    % 3. 抽水蓄能玩家调整策略
    bestBenefitPlayer3 = currentBenefit;
    bestStrategiesPlayer3 = strategiesPlayer3;
    
    for deltaHPS = -500:500:500
        newStrategiesPlayer3 = strategiesPlayer3 + deltaHPS;
        % 确保新的策略在范围内
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
    
    % 4. 氢储能玩家调整策略
    bestBenefitPlayer4 = currentBenefit;
    bestStrategiesPlayer4 = strategiesPlayer4;
    
    for deltaElectrolyzer = -500:500:500
        for deltaTank = -500:500:500
            for deltaFuelCell = -500:500:500
                newStrategiesPlayer4 = strategiesPlayer4 + [deltaElectrolyzer, deltaTank, deltaFuelCell];
                % 确保新的策略在范围内
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
    
     % 存储当前迭代的决策变量
    decisionVariablesHistory(iter, :) = [strategiesPlayer1(1), strategiesPlayer1(2), strategiesPlayer2(1), ...
                                          strategiesPlayer3(1), strategiesPlayer4(1), ...
                                          strategiesPlayer4(2), strategiesPlayer4(3)];
    
    % 存储当前迭代的净效益
    netBenefitHistory(iter, :) = [bestBenefitPlayer4];                                  
                                      
    % 输出当前博弈结果
    fprintf('Iteration %d: Player 1 Benefit: %.2f, Player 2 Benefit: %.2f, Player 3 Benefit: %.2f, Player 4 Benefit: %.2f\n', ...
            iter, bestBenefitPlayer1, bestBenefitPlayer2, bestBenefitPlayer3, bestBenefitPlayer4);
end

% 绘制决策变量变化图
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

% 绘制净效益变化图
subplot(2, 1, 2);
plot(1:numIterations, netBenefitHistory(:, 1), 'b-', 'LineWidth', 2);
xlabel('Iteration');
ylabel('Benefit');
legend({'Players Benefit'});
title('Total Benefit vs Iterations');




































