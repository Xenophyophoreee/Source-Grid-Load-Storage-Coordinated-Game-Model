%% 进行四个主体演化博弈
%% 初始化类
model_FL = FlexibleLoadModel();
model_ESS = LoadSideElectrochemicalStorageModel();
model_HPS = LoadSidePumpedStorageModel();
model_H2 = LoadSideHydrogenStorageModel();

%% 设置决策变量范围
curtailmentCapacityRange = [4000, 9000];    % 可削减负荷容量范围 (kW)
transferCapacityRange = [3000, 8000];        % 可转移负荷容量范围 (kW)
storageCapacityESSRange = [1000, 3000];      % 电化学储能容量范围 (kW)
storageCapacityHPSRange = [3000, 8000];      % 抽水蓄能容量范围 (kW)
electrolyzerCapacityRange = [1000, 3000];    % 电解槽容量范围 (kW)
storageTankCapacityRange = [1000, 3000];     % 储氢罐容量范围 (kW)
fuelCellCapacityRange = [1000, 3000];        % 氢燃料电池容量范围 (kW)

%% 初始化参与者策略
strategiesPlayer1 = [5000, 4000];        % 柔性负荷策略 (curtailmentCapacity, transferCapacity)
strategiesPlayer2 = [2000];              % 电化学储能策略 (storageCapacity_ESS)
strategiesPlayer3 = [4000];              % 抽水蓄能策略 (storageCapacity_HPS)
strategiesPlayer4 = [2000, 1500, 1500];  % 氢储能策略 (electrolyzerCapacity, storageTankCapacity, fuelCellCapacity)

%% 模拟数据
% 生成一年的15分钟时间序列数据
total_periods = 365 * 24 * 4;  % 15分钟为单位的一年时间点数

% 生成峰谷时段标志（1表示峰时段，0表示谷时段）
peak_periods = zeros(1, total_periods);
for day = 0:364
   day_start = day * 24 * 4 + 1;
   peak_start = day_start + 32;  % 8:00
   peak_end = day_start + 88;    % 22:00
   peak_periods(peak_start:peak_end) = 1;
end

% 柔性负荷响应数据模拟
curtailmentOutput = rand(1, total_periods) .* peak_periods;  % 可削减负荷仅在峰时段响应
transferOutput = rand(1, total_periods);  % 可转移负荷全时段响应

% 储能充放电功率模拟
% 电化学储能（15分钟尺度）
chargePower_15min = zeros(1, total_periods);
dischargePower_15min = zeros(1, total_periods);
chargePower_15min(peak_periods == 0) = strategiesPlayer2(1) * rand(1, sum(peak_periods == 0));     % 谷时段充电
dischargePower_15min(peak_periods == 1) = strategiesPlayer2(1) * rand(1, sum(peak_periods == 1));   % 峰时段放电

% 抽水蓄能（1小时尺度）
chargePower_1h = reshape(sum(reshape(chargePower_15min, 4, []), 1), 1, []);
dischargePower_1h = reshape(sum(reshape(dischargePower_15min, 4, []), 1), 1, []);

% 氢储能（1天尺度）
chargePower_1d = reshape(sum(reshape(chargePower_1h, 24, []), 1), 1, []);
dischargePower_1d = reshape(sum(reshape(dischargePower_1h, 24, []), 1), 1, []);

%% 演化博弈模拟
numIterations = 25; % 迭代次数
learningRate = 0.05; % 策略调整的学习率

% 初始化变量用于绘制图形
decisionVariablesHistory = zeros(numIterations, 7); % 存储决策变量的历史记录
netBenefitHistory = zeros(numIterations, 1); % 存储净效益的历史记录

for iter = 1:numIterations
   % 获取当前策略
   curtailmentCapacity = strategiesPlayer1(1);
   transferCapacity = strategiesPlayer1(2);
   storageCapacity_ESS = strategiesPlayer2(1);
   storageCapacity_HPS = strategiesPlayer3(1);
   electrolyzerCapacity = strategiesPlayer4(1);
   storageTankCapacity = strategiesPlayer4(2);
   fuelCellCapacity = strategiesPlayer4(3);
   
   % 计算当前策略下的总净效益
   currentBenefit = model_FL.calculateNetBenefit(curtailmentCapacity, curtailmentOutput, transferCapacity, transferOutput) + ...
                   model_ESS.calculateNetBenefit(chargePower_15min, dischargePower_15min, storageCapacity_ESS) + ...
                   model_HPS.calculateNetBenefit(chargePower_1h, dischargePower_1h, storageCapacity_HPS) + ...
                   model_H2.calculateNetBenefit(chargePower_1d, dischargePower_1d, electrolyzerCapacity, storageTankCapacity, fuelCellCapacity);
   
   % 各个参与者根据当前策略调整自己的决策
   % 1. 柔性负荷玩家调整策略
   bestBenefitPlayer1 = currentBenefit;
   bestStrategiesPlayer1 = strategiesPlayer1;
   
   for deltaCurtail = -200:200:200
       for deltaTransfer = -200:200:200
           newStrategiesPlayer1 = strategiesPlayer1 + [deltaCurtail, deltaTransfer];
           % 确保新的策略在范围内
           if newStrategiesPlayer1(1) < curtailmentCapacityRange(1) || newStrategiesPlayer1(1) > curtailmentCapacityRange(2) || ...
              newStrategiesPlayer1(2) < transferCapacityRange(1) || newStrategiesPlayer1(2) > transferCapacityRange(2)
               continue;
           end
           newBenefitPlayer1 = model_FL.calculateNetBenefit(newStrategiesPlayer1(1), curtailmentOutput, newStrategiesPlayer1(2), transferOutput) + ...
                              model_ESS.calculateNetBenefit(chargePower_15min, dischargePower_15min, storageCapacity_ESS) + ...
                              model_HPS.calculateNetBenefit(chargePower_1h, dischargePower_1h, storageCapacity_HPS) + ...
                              model_H2.calculateNetBenefit(chargePower_1d, dischargePower_1d, electrolyzerCapacity, storageTankCapacity, fuelCellCapacity);
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
   
   for deltaESS = -200:200:200
       newStrategiesPlayer2 = strategiesPlayer2 + deltaESS;
       % 确保新的策略在范围内
       if newStrategiesPlayer2(1) < storageCapacityESSRange(1) || newStrategiesPlayer2(1) > storageCapacityESSRange(2)
           continue;
       end
       newBenefitPlayer2 = model_FL.calculateNetBenefit(curtailmentCapacity, curtailmentOutput, transferCapacity, transferOutput) + ...
                          model_ESS.calculateNetBenefit(chargePower_15min, dischargePower_15min, newStrategiesPlayer2(1)) + ...
                          model_HPS.calculateNetBenefit(chargePower_1h, dischargePower_1h, storageCapacity_HPS) + ...
                          model_H2.calculateNetBenefit(chargePower_1d, dischargePower_1d, electrolyzerCapacity, storageTankCapacity, fuelCellCapacity);
       if newBenefitPlayer2 > bestBenefitPlayer2
           bestBenefitPlayer2 = newBenefitPlayer2;
           bestStrategiesPlayer2 = newStrategiesPlayer2;
       end
   end
   strategiesPlayer2 = bestStrategiesPlayer2;
   
   % 3. 抽水蓄能玩家调整策略
   bestBenefitPlayer3 = currentBenefit;
   bestStrategiesPlayer3 = strategiesPlayer3;
   
   for deltaHPS = -200:200:200
       newStrategiesPlayer3 = strategiesPlayer3 + deltaHPS;
       % 确保新的策略在范围内
       if newStrategiesPlayer3(1) < storageCapacityHPSRange(1) || newStrategiesPlayer3(1) > storageCapacityHPSRange(2)
           continue;
       end
       newBenefitPlayer3 = model_FL.calculateNetBenefit(curtailmentCapacity, curtailmentOutput, transferCapacity, transferOutput) + ...
                          model_ESS.calculateNetBenefit(chargePower_15min, dischargePower_15min, storageCapacity_ESS) + ...
                          model_HPS.calculateNetBenefit(chargePower_1h, dischargePower_1h, newStrategiesPlayer3(1)) + ...
                          model_H2.calculateNetBenefit(chargePower_1d, dischargePower_1d, electrolyzerCapacity, storageTankCapacity, fuelCellCapacity);
       if newBenefitPlayer3 > bestBenefitPlayer3
           bestBenefitPlayer3 = newBenefitPlayer3;
           bestStrategiesPlayer3 = newStrategiesPlayer3;
       end
   end
   strategiesPlayer3 = bestStrategiesPlayer3;
   
   % 4. 氢储能玩家调整策略
   bestBenefitPlayer4 = currentBenefit;
   bestStrategiesPlayer4 = strategiesPlayer4;
   
   for deltaElectrolyzer = -200:200:200
       for deltaTank = -200:200:200
           for deltaFuelCell = -200:200:200
               newStrategiesPlayer4 = strategiesPlayer4 + [deltaElectrolyzer, deltaTank, deltaFuelCell];
               % 确保新的策略在范围内
               if newStrategiesPlayer4(1) < electrolyzerCapacityRange(1) || newStrategiesPlayer4(1) > electrolyzerCapacityRange(2) || ...
                  newStrategiesPlayer4(2) < storageTankCapacityRange(1) || newStrategiesPlayer4(2) > storageTankCapacityRange(2) || ...
                  newStrategiesPlayer4(3) < fuelCellCapacityRange(1) || newStrategiesPlayer4(3) > fuelCellCapacityRange(2)
                   continue;
               end
               newBenefitPlayer4 = model_FL.calculateNetBenefit(curtailmentCapacity, curtailmentOutput, transferCapacity, transferOutput) + ...
                                  model_ESS.calculateNetBenefit(chargePower_15min, dischargePower_15min, storageCapacity_ESS) + ...
                                  model_HPS.calculateNetBenefit(chargePower_1h, dischargePower_1h, storageCapacity_HPS) + ...
                                  model_H2.calculateNetBenefit(chargePower_1d, dischargePower_1d, newStrategiesPlayer4(1), newStrategiesPlayer4(2), newStrategiesPlayer4(3));
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
   fprintf('Iteration %d:\nPlayer 1 (Flexible Load) Benefit: %.2f\nPlayer 2 (ESS) Benefit: %.2f\nPlayer 3 (HPS) Benefit: %.2f\nPlayer 4 (H2) Benefit: %.2f\n\n', ...
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
legend({'Curtailment Capacity', 'Transfer Capacity', 'ESS Capacity', 'HPS Capacity', ...
       'Electrolyzer Capacity', 'Storage Tank Capacity', 'Fuel Cell Capacity'});
title('Decision Variables vs Iterations');

% 绘制净效益变化图
subplot(2, 1, 2);
plot(1:numIterations, netBenefitHistory(:, 1), 'b-', 'LineWidth', 2);
xlabel('Iteration');
ylabel('Benefit');
legend({'Total Net Benefit'});
title('Total Benefit vs Iterations');