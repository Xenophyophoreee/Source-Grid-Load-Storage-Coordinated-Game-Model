%% 进行四个主体演化博弈
%% 初始化类
model_GL = PowerTransmissionModel();
model_ESS = ElectrochemicalStorageModel();
model_HPS = PumpedStorageModel();
model_H2 = HydrogenStorageModel();

%% 设置决策变量范围
Cap1Range = [10000, 20000]; % 输变电设备新建容量范围 (kW)
Cap2Range = [10000, 20000]; % 输变电设备升级改造容量范围 (kW)
Cap_EES_GLRange = [2000, 5000]; % 电化学储能装置容量范围（kW）
Cap_HPS_GLRange = [5000, 10000]; % 抽水蓄能装机容量范围 (kW)
Cap_ED_GLRange = [1000, 5000]; % 电解槽容量范围 (kW)
Cap_HS_GLRange = [1000, 5000]; % 储氢罐容量范围 (kW)
Cap_GT_GLRange = [1000, 5000]; % 氢燃料电池容量范围 (kW)

%% 初始化参与者策略（初始化四个参与者的决策变量）
strategiesPlayer1 = [15000, 15000]; % 输变电设备策略 (windCapacity, solarCapacity)
strategiesPlayer2 = [3000]; % 电化学储能策略 (storageCapacity_ESS)
strategiesPlayer3 = [7000]; % 抽水蓄能策略 (storageCapacity_HPS)
strategiesPlayer4 = [3000, 2000, 2500]; % 氢储能策略 (electrolyzerCapacity, storageTankCapacity, fuelCellCapacity)

%% 模拟数据
% 电网侧模拟数据
% 输变电设备模拟数据
percentPt_GL_loss = rand(1, 365 * 24 * 4) * 0.05; % 百分比
percentPt_GL_buy_up = rand(1, 365 * 24 * 4) * 0.1;
percentPt_GL_buy_grid = rand(1, 365 * 24 * 4) * 0.1;
percentPt_GL_sell = rand(1, 365 * 24 * 4);
% 电网侧电化学储能模拟数据
percentPt_EES_GL_f = rand(1, 365 * 24 * 4);
% 电网侧抽水蓄能模拟数据
percentPt_V_HPS_GL = rand(1, 365 * 24) * 0.9;
% 电网测氢储能模拟数据
percentPt_H2_GL_dis = rand(1, 365) * 0.9;
percentPt_H2_GL_ch = rand(1, 365) * 0.5;

%% 演化博弈模拟
numIterations = 25; % 迭代次数
learningRate = 0.05; % 策略调整的学习率

% 初始化变量用于绘制图形
decisionVariablesHistory = zeros(numIterations, 7); % 存储决策变量的历史记录
netBenefitHistory = zeros(numIterations, 1); % 存储净效益的历史记录

for iter = 1:numIterations
    % 模拟数据推算
    Cap1 = strategiesPlayer1(1);  % 输变电设备新建容量 (kW)
    Cap2 = strategiesPlayer1(2); % 输变电设备升级改造容量 (kW)
    Cap_EES_GL = strategiesPlayer2(1); % 电网侧电化学储能装置的规划容量
    Cap_HPS_GL = strategiesPlayer3(1); % 抽水蓄能装置的规划容量
    Cap_ED_GL = strategiesPlayer4(1); % 电解槽容量 (kW)
    Cap_HS_GL = strategiesPlayer4(2); % 储氢罐容量 (kW)
    Cap_GT_GL = strategiesPlayer4(3); % 氢燃料电池容量 (kW)
    
    % 输变电设备数据
    N_l1 = Cap1; % 新建设备总容量
    N_l2 = Cap2; % 升级改造设备总容量
    Pt_GL_loss = percentPt_GL_loss * (N_l1 + N_l2); % 第t个运行时段电网网损
    Pt_GL_buy_up = percentPt_GL_buy_up * (N_l1 + N_l2); % t时段向上级电网购电量
    Pt_GL_buy_grid = percentPt_GL_buy_grid * (N_l1 + N_l2); % t时段向本级电网购电量
    Pt_GL_sell = percentPt_GL_sell * (N_l1 + N_l2); % t时段电网售电量
    
    % 电网侧电化学储能数据
    Pt_EES_GL_f = percentPt_EES_GL_f * Cap_EES_GL; % 电网侧t时段储能参与调频的申报容量
    P_EES_GL_ess_r = Cap_EES_GL; % 电网侧电化学储能装置的规划容量
    Ni_EES_GL_ess = Cap_EES_GL;
    
    % 电网侧抽水蓄能数据
    Pt_V_HPS_GL = percentPt_V_HPS_GL * Cap_HPS_GL; % 电网侧抽水蓄能参与调峰时的充电功率
    P_HPS_GL_ess_r = Cap_HPS_GL; % 抽水蓄能装置的规划容量
    Ni_HPS_GL_ess = Cap_HPS_GL; 
    
    % 电网测氢储能数据
    Pt_H2_GL_dis = (percentPt_H2_GL_dis * Cap_ED_GL) + (percentPt_H2_GL_dis * Cap_HS_GL) + (percentPt_H2_GL_dis * Cap_GT_GL); % 电网侧氢储能在t时段的放电功率
    Pt_H2_GL_ch = (percentPt_H2_GL_ch * Cap_ED_GL) + (percentPt_H2_GL_ch * Cap_HS_GL) + (percentPt_H2_GL_ch * Cap_GT_GL); % 电网侧氢储能在t时段的充电功率
    P_H2_GL_EC_r = Cap_ED_GL;
    P_H2_GL_SC_r = Cap_HS_GL;
    P_H2_GL_FC_r = Cap_GT_GL;
    Ni_H2_GL_EC_r = Cap_ED_GL;
    Ni_H2_GL_SC_r = Cap_HS_GL;
    Ni_H2_GL_FC_r = Cap_GT_GL;
    
    % 计算当前策略下的总净效益
    currentBenefit = model_GL.calculateGridNetBenefit(strategiesPlayer1(1), strategiesPlayer1(2), ...
                                                            Pt_GL_loss, Pt_GL_buy_up, Pt_GL_buy_grid, Pt_GL_sell)+...
        model_ESS.calculateElecNetBenefit(Pt_EES_GL_f, strategiesPlayer2(1), strategiesPlayer2(1)) +...
        model_HPS.calculatePumpNetBenefit(Pt_V_HPS_GL,strategiesPlayer3(1), strategiesPlayer3(1)) +...
        model_H2.calculatePumpNetBenefit(Pt_H2_GL_dis, Pt_H2_GL_ch, strategiesPlayer4(1), strategiesPlayer4(2), strategiesPlayer4(3), strategiesPlayer4(1), strategiesPlayer4(2), strategiesPlayer4(3));
    
    
    
    % 各个参与者根据当前策略调整自己的决策
    % 1. 输变电设备玩家调整策略
    bestBenefitPlayer1 = currentBenefit;
    bestStrategiesPlayer1 = strategiesPlayer1;
    for deltaCap1 = -500:500:500
        for deltaCap2 = -500:500:500
             newStrategiesPlayer1 = strategiesPlayer1 + [deltaCap1, deltaCap2];
             % 确保新的策略在范围内
            if newStrategiesPlayer1(1) < Cap1Range(1) || newStrategiesPlayer1(1) > Cap1Range(2) || ...
               newStrategiesPlayer1(2) < Cap2Range(1) || newStrategiesPlayer1(2) > Cap2Range(2)
                continue;
            end
            
            Cap1 = newStrategiesPlayer1(1);  % 输变电设备新建容量 (kW)
            Cap2 = newStrategiesPlayer1(2); % 输变电设备升级改造容量 (kW)
            % 输变电设备数据
            N_l1 = Cap1; % 新建设备总容量
            N_l2 = Cap2; % 升级改造设备总容量
            Pt_GL_loss = percentPt_GL_loss * (N_l1 + N_l2); % 第t个运行时段电网网损
            Pt_GL_buy_up = percentPt_GL_buy_up * (N_l1 + N_l2); % t时段向上级电网购电量
            Pt_GL_buy_grid = percentPt_GL_buy_grid * (N_l1 + N_l2); % t时段向本级电网购电量
            Pt_GL_sell = percentPt_GL_sell * (N_l1 + N_l2); % t时段电网售电量

            newBenefitPlayer1 = model_GL.calculateGridNetBenefit(newStrategiesPlayer1(1), newStrategiesPlayer1(2), ...
                                                            Pt_GL_loss, Pt_GL_buy_up, Pt_GL_buy_grid, Pt_GL_sell)+...
                model_ESS.calculateElecNetBenefit(Pt_EES_GL_f, strategiesPlayer2(1), strategiesPlayer2(1)) +...
                model_HPS.calculatePumpNetBenefit(Pt_V_HPS_GL,strategiesPlayer3(1), strategiesPlayer3(1)) +...
                model_H2.calculatePumpNetBenefit(Pt_H2_GL_dis, Pt_H2_GL_ch, strategiesPlayer4(1), strategiesPlayer4(2), strategiesPlayer4(3), strategiesPlayer4(1), strategiesPlayer4(2), strategiesPlayer4(3));
            
            
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
         if newStrategiesPlayer2(1) < Cap_EES_GLRange(1) || newStrategiesPlayer2(1) > Cap_EES_GLRange(2)
            continue;
        end
        newBenefitPlayer2 = model_GL.calculateGridNetBenefit(strategiesPlayer1(1), strategiesPlayer1(2), ...
                                                            Pt_GL_loss, Pt_GL_buy_up, Pt_GL_buy_grid, Pt_GL_sell)+...
                model_ESS.calculateElecNetBenefit(Pt_EES_GL_f, newStrategiesPlayer2(1), newStrategiesPlayer2(1)) +...
                model_HPS.calculatePumpNetBenefit(Pt_V_HPS_GL,strategiesPlayer3(1), strategiesPlayer3(1)) +...
                model_H2.calculatePumpNetBenefit(Pt_H2_GL_dis, Pt_H2_GL_ch, strategiesPlayer4(1), strategiesPlayer4(2), strategiesPlayer4(3), strategiesPlayer4(1), strategiesPlayer4(2), strategiesPlayer4(3));
        
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
        if newStrategiesPlayer3(1) < Cap_HPS_GLRange(1) || newStrategiesPlayer3(1) > Cap_HPS_GLRange(2)
            continue;
        end
        newBenefitPlayer3 = model_GL.calculateGridNetBenefit(strategiesPlayer1(1), strategiesPlayer1(2), ...
                                                            Pt_GL_loss, Pt_GL_buy_up, Pt_GL_buy_grid, Pt_GL_sell)+...
                model_ESS.calculateElecNetBenefit(Pt_EES_GL_f, strategiesPlayer2(1), strategiesPlayer2(1)) +...
                model_HPS.calculatePumpNetBenefit(Pt_V_HPS_GL,newStrategiesPlayer3(1), newStrategiesPlayer3(1)) +...
                model_H2.calculatePumpNetBenefit(Pt_H2_GL_dis, Pt_H2_GL_ch, strategiesPlayer4(1), strategiesPlayer4(2), strategiesPlayer4(3), strategiesPlayer4(1), strategiesPlayer4(2), strategiesPlayer4(3));
        
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
                if newStrategiesPlayer4(1) < Cap_ED_GLRange(1) || newStrategiesPlayer4(1) > Cap_ED_GLRange(2) || ...
                   newStrategiesPlayer4(2) < Cap_HS_GLRange(1) || newStrategiesPlayer4(2) > Cap_ED_GLRange(2) || ...
                   newStrategiesPlayer4(3) < Cap_GT_GLRange(1) || newStrategiesPlayer4(3) > Cap_GT_GLRange(2)
                    continue;
                end
                newBenefitPlayer4 = model_GL.calculateGridNetBenefit(strategiesPlayer1(1), strategiesPlayer1(2), ...
                                                            Pt_GL_loss, Pt_GL_buy_up, Pt_GL_buy_grid, Pt_GL_sell)+...
                model_ESS.calculateElecNetBenefit(Pt_EES_GL_f, strategiesPlayer2(1), strategiesPlayer2(1)) +...
                model_HPS.calculatePumpNetBenefit(Pt_V_HPS_GL,strategiesPlayer3(1), strategiesPlayer3(1)) +...
                model_H2.calculatePumpNetBenefit(Pt_H2_GL_dis, Pt_H2_GL_ch, newStrategiesPlayer4(1), newStrategiesPlayer4(2), newStrategiesPlayer4(3), newStrategiesPlayer4(1), newStrategiesPlayer4(2), newStrategiesPlayer4(3));
                
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
legend({'Cap1', 'Cap2', 'ESS Capacity', 'HPS Capacity', 'Electrolyzer Capacity', 'Storage Tank Capacity', 'Fuel Cell Capacity'});
title('Decision Variables vs Iterations');

% 绘制净效益变化图
subplot(2, 1, 2);
plot(1:numIterations, netBenefitHistory(:, 1), 'b-', 'LineWidth', 2);
xlabel('Iteration');
ylabel('Benefit');
legend({'Players Benefit'});
title('Total Benefit vs Iterations');

            
    
    
        
                                                        







