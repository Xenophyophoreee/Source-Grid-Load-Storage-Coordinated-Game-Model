% 初始化类
model_NE = RenewableEnergyModel();
model_ESS = ElectrochemicalStorageModel();
model_HPS = PumpedStorageModel();
model_H2 = HydrogenStorageModel();

% 未来将会成为决策变量
windCapacity = 20000; % 风机容量 (kW)
solarCapacity = 15000; % 光伏容量 (kW)
storageCapacity_ESS = 5000; % 储能装机容量 (kW)
storageCapacity_HPS = 10000; % 抽水蓄能装机容量 (kW)
electrolyzerCapacity = 5000; % 电解槽容量 (kW)
storageTankCapacity = 5000; % 储氢罐容量 (kW)
fuelCellCapacity = 5000; % 氢燃料电池容量 (kW)

%% 模拟数据
% 新能源侧模拟数据
windOutput = rand(1, 365 * 24 * 4); % 风电出力占装机容量百分比 (%)
solarOutput = rand(1, 365 * 24 * 4); % 光伏出力占装机容量百分比 (%)

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

%% 测试
% 测试新能源净效益计算
% 计算
sellRevenue_NE = model_NE.calculateSellRevenue(windOutput, solarOutput, windCapacity, solarCapacity);
subsidy_NE = model_NE.calculateSubsidy(windOutput, solarOutput, windCapacity, solarCapacity);
investment_NE = model_NE.calculateInvestment(windCapacity, solarCapacity);
opeCost_NE = model_NE.calculateOpeCost(windCapacity, solarCapacity);
tradingCost_NE = model_NE.calculateTradingCost(tradingPower_NE);
netBenefit_NE = model_NE.calculateNetBenefit(windOutput, solarOutput, windCapacity, solarCapacity, tradingPower_NE);

% 输出结果
fprintf('=================新能源净效益=====================\n');
fprintf('售电收益: %.2f 元\n', sellRevenue_NE);
fprintf('政府补贴: %.2f 元\n', subsidy_NE);
fprintf('建设投资: %.2f 元\n', investment_NE);
fprintf('运维成本: %.2f 元\n', opeCost_NE);
fprintf('交易成本: %.2f 元\n', tradingCost_NE);
fprintf('净效益: %.2f 元\n', netBenefit_NE);

% 测试新能源侧电化学储能净效益计算
% 计算
fluRevenue_ESS = model_ESS.calculateFluctuationRevenue(windEnergy_15min, solarEnergy_15min);
tradingRevenue_ESS = model_ESS.calculateTradingRevenue(tradingPower_ESS_15min);
investment_ESS = model_ESS.calculateInvestment(storageCapacity_ESS);
opeCost_ESS = model_ESS.calculateOpeCost(storageCapacity_ESS);
netBenefit_ESS = model_ESS.calculateNetBenefit(windEnergy_15min, solarEnergy_15min, tradingPower_ESS_15min, storageCapacity_ESS);

% 输出结果
fprintf('=================新能源测电化学储能净效益=====================\n');
fprintf('平抑收益: %.2f 元\n', fluRevenue_ESS);
fprintf('交易收益: %.2f 元\n', tradingRevenue_ESS);
fprintf('建设投资: %.2f 元\n', investment_ESS);
fprintf('运维成本: %.2f 元\n', opeCost_ESS);
fprintf('总净效益: %.2f 元\n', netBenefit_ESS);

% 测试新能源侧抽水蓄能净效益计算
% 计算
fluRevenue_HPS = model_HPS.calculateFluctuationRevenue(windEnergy_1h, solarEnergy_1h);
tradingRevenue_HPS = model_HPS.calculateTradingRevenue(tradingPower_HPS_1h);
investment_HPS = model_HPS.calculateInvestment(storageCapacity_HPS);
opeCost_HPS = model_HPS.calculateOpeCost(storageCapacity_HPS);
netBenefit_HPS = model_HPS.calculateNetBenefit(windEnergy_1h, solarEnergy_1h, tradingPower_HPS_1h, storageCapacity_HPS);

% 输出结果
fprintf('=================新能源测抽水蓄能净效益=====================\n');
fprintf('平抑收益: %.2f 元\n', fluRevenue_HPS);
fprintf('交易收益: %.2f 元\n', tradingRevenue_HPS);
fprintf('建设投资: %.2f 元\n', investment_HPS);
fprintf('运行维护成本: %.2f 元\n', opeCost_HPS);
fprintf('总净效益: %.2f 元\n', netBenefit_HPS);

% 测试新能源侧氢储能净效益计算
% 计算
gridSecurityRevenue_H2 = model_H2.calculateGridSecurityRevenue(windEnergy_1d, solarEnergy_1d);
tradingRevenue_H2 = model_H2.calculateTradingRevenue(tradingPower_H2_1d);
investment_H2 = model_H2.calculateInvestment(electrolyzerCapacity, storageTankCapacity, fuelCellCapacity);
opeCost_H2 = model_H2.calculateOpeCost(electrolyzerCapacity, storageTankCapacity, fuelCellCapacity);
netBenefit_H2 = model_H2.calculateNetBenefit(windEnergy_1d, solarEnergy_1d, tradingPower_H2_1d, electrolyzerCapacity, storageTankCapacity, fuelCellCapacity);

% 输出结果
fprintf('=================新能源测氢储能净效益=====================\n');
fprintf('电网安全稳定运行收益: %.2f 元\n', gridSecurityRevenue_H2);
fprintf('交易收益: %.2f 元\n', tradingRevenue_H2);
fprintf('建设投资: %.2f 元\n', investment_H2);
fprintf('运行维护成本: %.2f 元\n', opeCost_H2);
fprintf('总净效益: %.2f 元\n', netBenefit_H2);



















