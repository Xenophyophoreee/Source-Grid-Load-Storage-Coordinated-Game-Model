% 初始化类
model_FL = FlexibleLoadModel();
model_ESS = LoadSideElectrochemicalStorageModel();
model_HPS = LoadSidePumpedStorageModel();
model_H2 = LoadSideHydrogenStorageModel();

% 未来将会成为决策变量
curtailmentCapacity = 6000;  % 可削减负荷容量 (kW)
transferCapacity = 6000;      % 可转移负荷容量 (kW)
storageCapacity_ESS = 2000;   % 电化学储能装机容量 (kW)
storageCapacity_HPS = 5000;  % 抽水蓄能装机容量 (kW)
electrolyzerCapacity = 5000;  % 电解槽容量 (kW)
storageTankCapacity = 5000;   % 储氢罐容量 (kW)
fuelCellCapacity = 5000;      % 氢燃料电池容量 (kW)

%% 模拟数据
% 生成一年的15分钟时间序列数据
total_periods = 365 * 24 * 4;  % 15分钟为单位的一年时间点数

% 生成峰谷时段标志（1表示峰时段，0表示谷时段）
% 假设每天8:00-22:00为峰时段，其余为谷时段
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

% 电化学储能数据模拟（15分钟尺度）
chargePower_15min = storageCapacity_ESS * rand(1, total_periods) .* (1 - peak_periods);  % 谷时段充电
dischargePower_15min = storageCapacity_ESS * rand(1, total_periods) .* peak_periods;     % 峰时段放电

% 抽水蓄能数据模拟（1小时尺度）
chargePower_1h = reshape(sum(reshape(chargePower_15min, 4, []), 1), 1, []);     % 将15分钟数据合并为小时数据
dischargePower_1h = reshape(sum(reshape(dischargePower_15min, 4, []), 1), 1, []);

% 氢储能数据模拟（1天尺度）
chargePower_1d = reshape(sum(reshape(chargePower_1h, 24, []), 1), 1, []);       % 将小时数据合并为天数据
dischargePower_1d = reshape(sum(reshape(dischargePower_1h, 24, []), 1), 1, []);

%% 测试
% 测试柔性负荷需求响应净效益计算
DRrevenue = model_FL.calculateDRRevenue(curtailmentCapacity, curtailmentOutput);
curtailmentCost = model_FL.calculateCurtailmentCost(curtailmentCapacity, curtailmentOutput);
transferCost = model_FL.calculateTransferCost(transferCapacity, transferOutput);
netBenefit_FL = model_FL.calculateNetBenefit(curtailmentCapacity, curtailmentOutput, transferCapacity, transferOutput);

% 输出结果
fprintf('=================柔性负荷需求响应净效益=====================\n');
fprintf('需求响应收益: %.2f 元\n', DRrevenue);
fprintf('可削减负荷成本: %.2f 元\n', curtailmentCost);
fprintf('可转移负荷成本: %.2f 元\n', transferCost);
fprintf('净效益: %.2f 元\n', netBenefit_FL);

% 测试负荷侧电化学储能净效益计算
arbitrageRevenue_ESS = model_ESS.calculateArbitrageRevenue(chargePower_15min, dischargePower_15min);
investment_ESS = model_ESS.calculateInvestment(storageCapacity_ESS);
opeCost_ESS = model_ESS.calculateOpeCost(storageCapacity_ESS);
netBenefit_ESS = model_ESS.calculateNetBenefit(chargePower_15min, dischargePower_15min, storageCapacity_ESS);

% 输出结果
fprintf('=================负荷侧电化学储能净效益=====================\n');
fprintf('套利收益: %.2f 元\n', arbitrageRevenue_ESS);
fprintf('建设投资: %.2f 元\n', investment_ESS);
fprintf('运维成本: %.2f 元\n', opeCost_ESS);
fprintf('总净效益: %.2f 元\n', netBenefit_ESS);

% 测试负荷侧抽水蓄能净效益计算
arbitrageRevenue_HPS = model_HPS.calculateArbitrageRevenue(chargePower_1h, dischargePower_1h);
investment_HPS = model_HPS.calculateInvestment(storageCapacity_HPS);
opeCost_HPS = model_HPS.calculateOpeCost(storageCapacity_HPS);
netBenefit_HPS = model_HPS.calculateNetBenefit(chargePower_1h, dischargePower_1h, storageCapacity_HPS);

% 输出结果
fprintf('=================负荷侧抽水蓄能净效益=====================\n');
fprintf('套利收益: %.2f 元\n', arbitrageRevenue_HPS);
fprintf('建设投资: %.2f 元\n', investment_HPS);
fprintf('运维成本: %.2f 元\n', opeCost_HPS);
fprintf('总净效益: %.2f 元\n', netBenefit_HPS);

% 测试负荷侧氢储能净效益计算
arbitrageRevenue_H2 = model_H2.calculateArbitrageRevenue(chargePower_1d, dischargePower_1d);
investment_H2 = model_H2.calculateInvestment(electrolyzerCapacity, storageTankCapacity, fuelCellCapacity);
opeCost_H2 = model_H2.calculateOpeCost(electrolyzerCapacity, storageTankCapacity, fuelCellCapacity);
netBenefit_H2 = model_H2.calculateNetBenefit(chargePower_1d, dischargePower_1d, electrolyzerCapacity, storageTankCapacity, fuelCellCapacity);

% 输出结果
fprintf('=================负荷侧氢储能净效益=====================\n');
fprintf('套利收益: %.2f 元\n', arbitrageRevenue_H2);
fprintf('建设投资: %.2f 元\n', investment_H2);
fprintf('运维成本: %.2f 元\n', opeCost_H2);
fprintf('总净效益: %.2f 元\n', netBenefit_H2);