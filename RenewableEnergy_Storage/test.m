% ��ʼ����
model_NE = RenewableEnergyModel();
model_ESS = ElectrochemicalStorageModel();
model_HPS = PumpedStorageModel();
model_H2 = HydrogenStorageModel();

% δ�������Ϊ���߱���
windCapacity = 20000; % ������� (kW)
solarCapacity = 15000; % ������� (kW)
storageCapacity_ESS = 5000; % ����װ������ (kW)
storageCapacity_HPS = 10000; % ��ˮ����װ������ (kW)
electrolyzerCapacity = 5000; % �������� (kW)
storageTankCapacity = 5000; % ��������� (kW)
fuelCellCapacity = 5000; % ��ȼ�ϵ������ (kW)

%% ģ������
% ����Դ��ģ������
windOutput = rand(1, 365 * 24 * 4); % ������ռװ�������ٷֱ� (%)
solarOutput = rand(1, 365 * 24 * 4); % �������ռװ�������ٷֱ� (%)

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

%% ����
% ��������Դ��Ч�����
% ����
sellRevenue_NE = model_NE.calculateSellRevenue(windOutput, solarOutput, windCapacity, solarCapacity);
subsidy_NE = model_NE.calculateSubsidy(windOutput, solarOutput, windCapacity, solarCapacity);
investment_NE = model_NE.calculateInvestment(windCapacity, solarCapacity);
opeCost_NE = model_NE.calculateOpeCost(windCapacity, solarCapacity);
tradingCost_NE = model_NE.calculateTradingCost(tradingPower_NE);
netBenefit_NE = model_NE.calculateNetBenefit(windOutput, solarOutput, windCapacity, solarCapacity, tradingPower_NE);

% ������
fprintf('=================����Դ��Ч��=====================\n');
fprintf('�۵�����: %.2f Ԫ\n', sellRevenue_NE);
fprintf('��������: %.2f Ԫ\n', subsidy_NE);
fprintf('����Ͷ��: %.2f Ԫ\n', investment_NE);
fprintf('��ά�ɱ�: %.2f Ԫ\n', opeCost_NE);
fprintf('���׳ɱ�: %.2f Ԫ\n', tradingCost_NE);
fprintf('��Ч��: %.2f Ԫ\n', netBenefit_NE);

% ��������Դ��绯ѧ���ܾ�Ч�����
% ����
fluRevenue_ESS = model_ESS.calculateFluctuationRevenue(windEnergy_15min, solarEnergy_15min);
tradingRevenue_ESS = model_ESS.calculateTradingRevenue(tradingPower_ESS_15min);
investment_ESS = model_ESS.calculateInvestment(storageCapacity_ESS);
opeCost_ESS = model_ESS.calculateOpeCost(storageCapacity_ESS);
netBenefit_ESS = model_ESS.calculateNetBenefit(windEnergy_15min, solarEnergy_15min, tradingPower_ESS_15min, storageCapacity_ESS);

% ������
fprintf('=================����Դ��绯ѧ���ܾ�Ч��=====================\n');
fprintf('ƽ������: %.2f Ԫ\n', fluRevenue_ESS);
fprintf('��������: %.2f Ԫ\n', tradingRevenue_ESS);
fprintf('����Ͷ��: %.2f Ԫ\n', investment_ESS);
fprintf('��ά�ɱ�: %.2f Ԫ\n', opeCost_ESS);
fprintf('�ܾ�Ч��: %.2f Ԫ\n', netBenefit_ESS);

% ��������Դ���ˮ���ܾ�Ч�����
% ����
fluRevenue_HPS = model_HPS.calculateFluctuationRevenue(windEnergy_1h, solarEnergy_1h);
tradingRevenue_HPS = model_HPS.calculateTradingRevenue(tradingPower_HPS_1h);
investment_HPS = model_HPS.calculateInvestment(storageCapacity_HPS);
opeCost_HPS = model_HPS.calculateOpeCost(storageCapacity_HPS);
netBenefit_HPS = model_HPS.calculateNetBenefit(windEnergy_1h, solarEnergy_1h, tradingPower_HPS_1h, storageCapacity_HPS);

% ������
fprintf('=================����Դ���ˮ���ܾ�Ч��=====================\n');
fprintf('ƽ������: %.2f Ԫ\n', fluRevenue_HPS);
fprintf('��������: %.2f Ԫ\n', tradingRevenue_HPS);
fprintf('����Ͷ��: %.2f Ԫ\n', investment_HPS);
fprintf('����ά���ɱ�: %.2f Ԫ\n', opeCost_HPS);
fprintf('�ܾ�Ч��: %.2f Ԫ\n', netBenefit_HPS);

% ��������Դ���ⴢ�ܾ�Ч�����
% ����
gridSecurityRevenue_H2 = model_H2.calculateGridSecurityRevenue(windEnergy_1d, solarEnergy_1d);
tradingRevenue_H2 = model_H2.calculateTradingRevenue(tradingPower_H2_1d);
investment_H2 = model_H2.calculateInvestment(electrolyzerCapacity, storageTankCapacity, fuelCellCapacity);
opeCost_H2 = model_H2.calculateOpeCost(electrolyzerCapacity, storageTankCapacity, fuelCellCapacity);
netBenefit_H2 = model_H2.calculateNetBenefit(windEnergy_1d, solarEnergy_1d, tradingPower_H2_1d, electrolyzerCapacity, storageTankCapacity, fuelCellCapacity);

% ������
fprintf('=================����Դ���ⴢ�ܾ�Ч��=====================\n');
fprintf('������ȫ�ȶ���������: %.2f Ԫ\n', gridSecurityRevenue_H2);
fprintf('��������: %.2f Ԫ\n', tradingRevenue_H2);
fprintf('����Ͷ��: %.2f Ԫ\n', investment_H2);
fprintf('����ά���ɱ�: %.2f Ԫ\n', opeCost_H2);
fprintf('�ܾ�Ч��: %.2f Ԫ\n', netBenefit_H2);



















