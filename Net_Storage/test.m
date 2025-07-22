% ��ʼ����
model_GL = PowerTransmissionModel();
model_ESS = ElectrochemicalStorageModel();
model_HPS = PumpedStorageModel();
model_H2 = HydrogenStorageModel();

% δ�����߱���
Cap1 = 50000; % �����豸�½����� (kW)
Cap2 = 50000; % �����豸������������ (kW)
Cap_EES_GL = 5000; % �绯ѧ����װ��������kW��
Cap_HPS_GL = 10000; % ��ˮ����װ������ (kW)
Cap_ED_GL = 5000; % �������� (kW)
Cap_HS_GL = 5000; % ��������� (kW)
Cap_GT_GL = 5000; % ��ȼ�ϵ������ (kW)

%% ģ������
% �����豸ģ������
percentPt_GL_loss = rand(1, 365 * 24 * 4) * 0.05; % �ٷֱ�
percentPt_GL_buy_up = rand(1, 365 * 24 * 4) * 0.1;
percentPt_GL_buy_grid = rand(1, 365 * 24 * 4) * 0.1;
percentPt_GL_sell = rand(1, 365 * 24 * 4);

N_l1 = Cap1; % �½��豸������
N_l2 = Cap2; % ���������豸������
Pt_GL_loss = percentPt_GL_loss * (N_l1 + N_l2); % ��t������ʱ�ε�������
Pt_GL_buy_up = percentPt_GL_buy_up * (N_l1 + N_l2); % tʱ�����ϼ�����������
Pt_GL_buy_grid = percentPt_GL_buy_grid * (N_l1 + N_l2); % tʱ���򱾼�����������
Pt_GL_sell = percentPt_GL_sell * (N_l1 + N_l2); % tʱ�ε����۵���

% ������绯ѧ����ģ������
percentPt_EES_GL_f = rand(1, 365 * 24 * 4);

Pt_EES_GL_f = percentPt_EES_GL_f * Cap_EES_GL; % ������tʱ�δ��ܲ����Ƶ���걨����
P_EES_GL_ess_r = Cap_EES_GL; % ������绯ѧ����װ�õĹ滮����
Ni_EES_GL_ess = Cap_EES_GL; 

% �������ˮ����ģ������
percentPt_V_HPS_GL = rand(1, 365 * 24) * 0.9;

Pt_V_HPS_GL = percentPt_V_HPS_GL * Cap_HPS_GL; % �������ˮ���ܲ������ʱ�ĳ�繦��
P_HPS_GL_ess_r = Cap_HPS_GL; % ��ˮ����װ�õĹ滮����
Ni_HPS_GL_ess = Cap_HPS_GL; 

% �������ⴢ��ģ������
percentPt_H2_GL_dis = rand(1, 365) * 0.9;
percentPt_H2_GL_ch = rand(1, 365) * 0.5;

Pt_H2_GL_dis = (percentPt_H2_GL_dis * Cap_ED_GL) + (percentPt_H2_GL_dis * Cap_HS_GL) + (percentPt_H2_GL_dis * Cap_GT_GL); % �������ⴢ����tʱ�εķŵ繦��
Pt_H2_GL_ch = (percentPt_H2_GL_ch * Cap_ED_GL) + (percentPt_H2_GL_ch * Cap_HS_GL) + (percentPt_H2_GL_ch * Cap_GT_GL); % �������ⴢ����tʱ�εĳ�繦��
P_H2_GL_EC_r = Cap_ED_GL;
P_H2_GL_SC_r = Cap_HS_GL;
P_H2_GL_FC_r = Cap_GT_GL;
Ni_H2_GL_EC_r = Cap_ED_GL;
Ni_H2_GL_SC_r = Cap_HS_GL;
Ni_H2_GL_FC_r = Cap_GT_GL;

%% ����
% ���������豸��Ч�����
% ����
inv_GL = model_GL.calculateInvest(N_l1, N_l2);
loss_GL = model_GL.calculateloss(Pt_GL_loss);
pur_GL = model_GL.calculatePurchase(Pt_GL_buy_up, Pt_GL_buy_grid);
rev_GL = model_GL.calculateRevenue(Pt_GL_sell);
netBenefit_GL = model_GL.calculateGridNetBenefit(N_l1, N_l2, ...
                                                            Pt_GL_loss, Pt_GL_buy_up, Pt_GL_buy_grid, Pt_GL_sell);

% ������
fprintf('=================�����豸��Ч��=====================\n');
fprintf('�۵�����: %.2f Ԫ\n', rev_GL);
fprintf('Ͷ�ʳɱ�: %.2f Ԫ\n', inv_GL);
fprintf('����ɱ�: %.2f Ԫ\n', loss_GL);
fprintf('����ɱ�: %.2f Ԫ\n', pur_GL);
fprintf('��Ч��: %.2f Ԫ\n', netBenefit_GL);

% ���Ե�����绯ѧ���ܾ�Ч�����
% ����
revFM_ESS_GL = model_ESS.calculateRevenueFM(Pt_EES_GL_f);
inv_ESS_GL = model_ESS.calculateInvestment(P_EES_GL_ess_r);
ope_ESS_GL = model_ESS.calculateOpe(Ni_EES_GL_ess);
netBenefit_ESS_GL = model_ESS.calculateElecNetBenefit(Pt_EES_GL_f, P_EES_GL_ess_r, Ni_EES_GL_ess);

% ������
fprintf('=================������绯ѧ���ܾ�Ч��=====================\n');
fprintf('�۵�����: %.2f Ԫ\n', revFM_ESS_GL);
fprintf('Ͷ�ʳɱ�: %.2f Ԫ\n', inv_ESS_GL);
fprintf('��ά�ɱ�: %.2f Ԫ\n', ope_ESS_GL);
fprintf('��Ч��: %.2f Ԫ\n', netBenefit_ESS_GL);

% ���Ե������ˮ���ܾ�Ч�����
% ����
revFM_HPS_GL = model_HPS.calculateRevenueFM(Pt_V_HPS_GL);
inv_HPS_GL = model_HPS.calculateInvestment(P_HPS_GL_ess_r);
ope_HPS_GL = model_HPS.calculateOpe(Ni_HPS_GL_ess);
netBenefit_HPS_GL = model_HPS.calculatePumpNetBenefit(Pt_V_HPS_GL, ...
                                                            P_HPS_GL_ess_r, Ni_HPS_GL_ess);

% ������
fprintf('=================�������ˮ���ܾ�Ч��=====================\n');
fprintf('�۵�����: %.2f Ԫ\n', revFM_HPS_GL);
fprintf('Ͷ�ʳɱ�: %.2f Ԫ\n', inv_HPS_GL);
fprintf('��ά�ɱ�: %.2f Ԫ\n', ope_HPS_GL);
fprintf('��Ч��: %.2f Ԫ\n', netBenefit_HPS_GL);

% ���Ե������ⴢ�ܾ�Ч�����
% ����
rev_H2_GL = model_H2.calculateRevenueH2(Pt_H2_GL_dis, Pt_H2_GL_ch);
inv_H2_GL = model_H2.calculateInvestment(P_H2_GL_EC_r, P_H2_GL_SC_r, P_H2_GL_FC_r);
ope_H2_GL = model_H2.calculateOpe(Ni_H2_GL_EC_r, Ni_H2_GL_SC_r, Ni_H2_GL_FC_r);
netBenefit_H2_GL = model_H2.calculatePumpNetBenefit(Pt_H2_GL_dis, Pt_H2_GL_ch, P_H2_GL_EC_r, P_H2_GL_SC_r, P_H2_GL_FC_r, Ni_H2_GL_EC_r, Ni_H2_GL_SC_r, Ni_H2_GL_FC_r);
                                                    
% ������
fprintf('=================�������ⴢ�ܾ�Ч��=====================\n');
fprintf('�۵�����: %.2f Ԫ\n', rev_H2_GL);
fprintf('Ͷ�ʳɱ�: %.2f Ԫ\n', inv_H2_GL);
fprintf('��ά�ɱ�: %.2f Ԫ\n', ope_H2_GL);
fprintf('��Ч��: %.2f Ԫ\n', netBenefit_H2_GL);
















