% 初始化类
model_GL = PowerTransmissionModel();
model_ESS = ElectrochemicalStorageModel();
model_HPS = PumpedStorageModel();
model_H2 = HydrogenStorageModel();

% 未来决策变量
Cap1 = 50000; % 输变电设备新建容量 (kW)
Cap2 = 50000; % 输变电设备升级改造容量 (kW)
Cap_EES_GL = 5000; % 电化学储能装置容量（kW）
Cap_HPS_GL = 10000; % 抽水蓄能装机容量 (kW)
Cap_ED_GL = 5000; % 电解槽容量 (kW)
Cap_HS_GL = 5000; % 储氢罐容量 (kW)
Cap_GT_GL = 5000; % 氢燃料电池容量 (kW)

%% 模拟数据
% 输变电设备模拟数据
percentPt_GL_loss = rand(1, 365 * 24 * 4) * 0.05; % 百分比
percentPt_GL_buy_up = rand(1, 365 * 24 * 4) * 0.1;
percentPt_GL_buy_grid = rand(1, 365 * 24 * 4) * 0.1;
percentPt_GL_sell = rand(1, 365 * 24 * 4);

N_l1 = Cap1; % 新建设备总容量
N_l2 = Cap2; % 升级改造设备总容量
Pt_GL_loss = percentPt_GL_loss * (N_l1 + N_l2); % 第t个运行时段电网网损
Pt_GL_buy_up = percentPt_GL_buy_up * (N_l1 + N_l2); % t时段向上级电网购电量
Pt_GL_buy_grid = percentPt_GL_buy_grid * (N_l1 + N_l2); % t时段向本级电网购电量
Pt_GL_sell = percentPt_GL_sell * (N_l1 + N_l2); % t时段电网售电量

% 电网侧电化学储能模拟数据
percentPt_EES_GL_f = rand(1, 365 * 24 * 4);

Pt_EES_GL_f = percentPt_EES_GL_f * Cap_EES_GL; % 电网侧t时段储能参与调频的申报容量
P_EES_GL_ess_r = Cap_EES_GL; % 电网侧电化学储能装置的规划容量
Ni_EES_GL_ess = Cap_EES_GL; 

% 电网侧抽水蓄能模拟数据
percentPt_V_HPS_GL = rand(1, 365 * 24) * 0.9;

Pt_V_HPS_GL = percentPt_V_HPS_GL * Cap_HPS_GL; % 电网侧抽水蓄能参与调峰时的充电功率
P_HPS_GL_ess_r = Cap_HPS_GL; % 抽水蓄能装置的规划容量
Ni_HPS_GL_ess = Cap_HPS_GL; 

% 电网测氢储能模拟数据
percentPt_H2_GL_dis = rand(1, 365) * 0.9;
percentPt_H2_GL_ch = rand(1, 365) * 0.5;

Pt_H2_GL_dis = (percentPt_H2_GL_dis * Cap_ED_GL) + (percentPt_H2_GL_dis * Cap_HS_GL) + (percentPt_H2_GL_dis * Cap_GT_GL); % 电网侧氢储能在t时段的放电功率
Pt_H2_GL_ch = (percentPt_H2_GL_ch * Cap_ED_GL) + (percentPt_H2_GL_ch * Cap_HS_GL) + (percentPt_H2_GL_ch * Cap_GT_GL); % 电网侧氢储能在t时段的充电功率
P_H2_GL_EC_r = Cap_ED_GL;
P_H2_GL_SC_r = Cap_HS_GL;
P_H2_GL_FC_r = Cap_GT_GL;
Ni_H2_GL_EC_r = Cap_ED_GL;
Ni_H2_GL_SC_r = Cap_HS_GL;
Ni_H2_GL_FC_r = Cap_GT_GL;

%% 测试
% 测试输变电设备净效益计算
% 计算
inv_GL = model_GL.calculateInvest(N_l1, N_l2);
loss_GL = model_GL.calculateloss(Pt_GL_loss);
pur_GL = model_GL.calculatePurchase(Pt_GL_buy_up, Pt_GL_buy_grid);
rev_GL = model_GL.calculateRevenue(Pt_GL_sell);
netBenefit_GL = model_GL.calculateGridNetBenefit(N_l1, N_l2, ...
                                                            Pt_GL_loss, Pt_GL_buy_up, Pt_GL_buy_grid, Pt_GL_sell);

% 输出结果
fprintf('=================输变电设备净效益=====================\n');
fprintf('售电收益: %.2f 元\n', rev_GL);
fprintf('投资成本: %.2f 元\n', inv_GL);
fprintf('网损成本: %.2f 元\n', loss_GL);
fprintf('购电成本: %.2f 元\n', pur_GL);
fprintf('净效益: %.2f 元\n', netBenefit_GL);

% 测试电网侧电化学储能净效益计算
% 计算
revFM_ESS_GL = model_ESS.calculateRevenueFM(Pt_EES_GL_f);
inv_ESS_GL = model_ESS.calculateInvestment(P_EES_GL_ess_r);
ope_ESS_GL = model_ESS.calculateOpe(Ni_EES_GL_ess);
netBenefit_ESS_GL = model_ESS.calculateElecNetBenefit(Pt_EES_GL_f, P_EES_GL_ess_r, Ni_EES_GL_ess);

% 输出结果
fprintf('=================电网测电化学储能净效益=====================\n');
fprintf('售电收益: %.2f 元\n', revFM_ESS_GL);
fprintf('投资成本: %.2f 元\n', inv_ESS_GL);
fprintf('运维成本: %.2f 元\n', ope_ESS_GL);
fprintf('净效益: %.2f 元\n', netBenefit_ESS_GL);

% 测试电网侧抽水蓄能净效益计算
% 计算
revFM_HPS_GL = model_HPS.calculateRevenueFM(Pt_V_HPS_GL);
inv_HPS_GL = model_HPS.calculateInvestment(P_HPS_GL_ess_r);
ope_HPS_GL = model_HPS.calculateOpe(Ni_HPS_GL_ess);
netBenefit_HPS_GL = model_HPS.calculatePumpNetBenefit(Pt_V_HPS_GL, ...
                                                            P_HPS_GL_ess_r, Ni_HPS_GL_ess);

% 输出结果
fprintf('=================电网测抽水蓄能净效益=====================\n');
fprintf('售电收益: %.2f 元\n', revFM_HPS_GL);
fprintf('投资成本: %.2f 元\n', inv_HPS_GL);
fprintf('运维成本: %.2f 元\n', ope_HPS_GL);
fprintf('净效益: %.2f 元\n', netBenefit_HPS_GL);

% 测试电网侧氢储能净效益计算
% 计算
rev_H2_GL = model_H2.calculateRevenueH2(Pt_H2_GL_dis, Pt_H2_GL_ch);
inv_H2_GL = model_H2.calculateInvestment(P_H2_GL_EC_r, P_H2_GL_SC_r, P_H2_GL_FC_r);
ope_H2_GL = model_H2.calculateOpe(Ni_H2_GL_EC_r, Ni_H2_GL_SC_r, Ni_H2_GL_FC_r);
netBenefit_H2_GL = model_H2.calculatePumpNetBenefit(Pt_H2_GL_dis, Pt_H2_GL_ch, P_H2_GL_EC_r, P_H2_GL_SC_r, P_H2_GL_FC_r, Ni_H2_GL_EC_r, Ni_H2_GL_SC_r, Ni_H2_GL_FC_r);
                                                    
% 输出结果
fprintf('=================电网测氢储能净效益=====================\n');
fprintf('售电收益: %.2f 元\n', rev_H2_GL);
fprintf('投资成本: %.2f 元\n', inv_H2_GL);
fprintf('运维成本: %.2f 元\n', ope_H2_GL);
fprintf('净效益: %.2f 元\n', netBenefit_H2_GL);
















