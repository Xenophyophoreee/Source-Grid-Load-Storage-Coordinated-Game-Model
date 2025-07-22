%% �����ĸ������ݻ�����
%% ��ʼ����
model_GL = PowerTransmissionModel();
model_ESS = ElectrochemicalStorageModel();
model_HPS = PumpedStorageModel();
model_H2 = HydrogenStorageModel();

%% ���þ��߱�����Χ
Cap1Range = [10000, 20000]; % �����豸�½�������Χ (kW)
Cap2Range = [10000, 20000]; % �����豸��������������Χ (kW)
Cap_EES_GLRange = [2000, 5000]; % �绯ѧ����װ��������Χ��kW��
Cap_HPS_GLRange = [5000, 10000]; % ��ˮ����װ��������Χ (kW)
Cap_ED_GLRange = [1000, 5000]; % ����������Χ (kW)
Cap_HS_GLRange = [1000, 5000]; % �����������Χ (kW)
Cap_GT_GLRange = [1000, 5000]; % ��ȼ�ϵ��������Χ (kW)

%% ��ʼ�������߲��ԣ���ʼ���ĸ������ߵľ��߱�����
strategiesPlayer1 = [15000, 15000]; % �����豸���� (windCapacity, solarCapacity)
strategiesPlayer2 = [3000]; % �绯ѧ���ܲ��� (storageCapacity_ESS)
strategiesPlayer3 = [7000]; % ��ˮ���ܲ��� (storageCapacity_HPS)
strategiesPlayer4 = [3000, 2000, 2500]; % �ⴢ�ܲ��� (electrolyzerCapacity, storageTankCapacity, fuelCellCapacity)

%% ģ������
% ������ģ������
% �����豸ģ������
percentPt_GL_loss = rand(1, 365 * 24 * 4) * 0.05; % �ٷֱ�
percentPt_GL_buy_up = rand(1, 365 * 24 * 4) * 0.1;
percentPt_GL_buy_grid = rand(1, 365 * 24 * 4) * 0.1;
percentPt_GL_sell = rand(1, 365 * 24 * 4);
% ������绯ѧ����ģ������
percentPt_EES_GL_f = rand(1, 365 * 24 * 4);
% �������ˮ����ģ������
percentPt_V_HPS_GL = rand(1, 365 * 24) * 0.9;
% �������ⴢ��ģ������
percentPt_H2_GL_dis = rand(1, 365) * 0.9;
percentPt_H2_GL_ch = rand(1, 365) * 0.5;

%% �ݻ�����ģ��
numIterations = 25; % ��������
learningRate = 0.05; % ���Ե�����ѧϰ��

% ��ʼ���������ڻ���ͼ��
decisionVariablesHistory = zeros(numIterations, 7); % �洢���߱�������ʷ��¼
netBenefitHistory = zeros(numIterations, 1); % �洢��Ч�����ʷ��¼

for iter = 1:numIterations
    % ģ����������
    Cap1 = strategiesPlayer1(1);  % �����豸�½����� (kW)
    Cap2 = strategiesPlayer1(2); % �����豸������������ (kW)
    Cap_EES_GL = strategiesPlayer2(1); % ������绯ѧ����װ�õĹ滮����
    Cap_HPS_GL = strategiesPlayer3(1); % ��ˮ����װ�õĹ滮����
    Cap_ED_GL = strategiesPlayer4(1); % �������� (kW)
    Cap_HS_GL = strategiesPlayer4(2); % ��������� (kW)
    Cap_GT_GL = strategiesPlayer4(3); % ��ȼ�ϵ������ (kW)
    
    % �����豸����
    N_l1 = Cap1; % �½��豸������
    N_l2 = Cap2; % ���������豸������
    Pt_GL_loss = percentPt_GL_loss * (N_l1 + N_l2); % ��t������ʱ�ε�������
    Pt_GL_buy_up = percentPt_GL_buy_up * (N_l1 + N_l2); % tʱ�����ϼ�����������
    Pt_GL_buy_grid = percentPt_GL_buy_grid * (N_l1 + N_l2); % tʱ���򱾼�����������
    Pt_GL_sell = percentPt_GL_sell * (N_l1 + N_l2); % tʱ�ε����۵���
    
    % ������绯ѧ��������
    Pt_EES_GL_f = percentPt_EES_GL_f * Cap_EES_GL; % ������tʱ�δ��ܲ����Ƶ���걨����
    P_EES_GL_ess_r = Cap_EES_GL; % ������绯ѧ����װ�õĹ滮����
    Ni_EES_GL_ess = Cap_EES_GL;
    
    % �������ˮ��������
    Pt_V_HPS_GL = percentPt_V_HPS_GL * Cap_HPS_GL; % �������ˮ���ܲ������ʱ�ĳ�繦��
    P_HPS_GL_ess_r = Cap_HPS_GL; % ��ˮ����װ�õĹ滮����
    Ni_HPS_GL_ess = Cap_HPS_GL; 
    
    % �������ⴢ������
    Pt_H2_GL_dis = (percentPt_H2_GL_dis * Cap_ED_GL) + (percentPt_H2_GL_dis * Cap_HS_GL) + (percentPt_H2_GL_dis * Cap_GT_GL); % �������ⴢ����tʱ�εķŵ繦��
    Pt_H2_GL_ch = (percentPt_H2_GL_ch * Cap_ED_GL) + (percentPt_H2_GL_ch * Cap_HS_GL) + (percentPt_H2_GL_ch * Cap_GT_GL); % �������ⴢ����tʱ�εĳ�繦��
    P_H2_GL_EC_r = Cap_ED_GL;
    P_H2_GL_SC_r = Cap_HS_GL;
    P_H2_GL_FC_r = Cap_GT_GL;
    Ni_H2_GL_EC_r = Cap_ED_GL;
    Ni_H2_GL_SC_r = Cap_HS_GL;
    Ni_H2_GL_FC_r = Cap_GT_GL;
    
    % ���㵱ǰ�����µ��ܾ�Ч��
    currentBenefit = model_GL.calculateGridNetBenefit(strategiesPlayer1(1), strategiesPlayer1(2), ...
                                                            Pt_GL_loss, Pt_GL_buy_up, Pt_GL_buy_grid, Pt_GL_sell)+...
        model_ESS.calculateElecNetBenefit(Pt_EES_GL_f, strategiesPlayer2(1), strategiesPlayer2(1)) +...
        model_HPS.calculatePumpNetBenefit(Pt_V_HPS_GL,strategiesPlayer3(1), strategiesPlayer3(1)) +...
        model_H2.calculatePumpNetBenefit(Pt_H2_GL_dis, Pt_H2_GL_ch, strategiesPlayer4(1), strategiesPlayer4(2), strategiesPlayer4(3), strategiesPlayer4(1), strategiesPlayer4(2), strategiesPlayer4(3));
    
    
    
    % ���������߸��ݵ�ǰ���Ե����Լ��ľ���
    % 1. �����豸��ҵ�������
    bestBenefitPlayer1 = currentBenefit;
    bestStrategiesPlayer1 = strategiesPlayer1;
    for deltaCap1 = -500:500:500
        for deltaCap2 = -500:500:500
             newStrategiesPlayer1 = strategiesPlayer1 + [deltaCap1, deltaCap2];
             % ȷ���µĲ����ڷ�Χ��
            if newStrategiesPlayer1(1) < Cap1Range(1) || newStrategiesPlayer1(1) > Cap1Range(2) || ...
               newStrategiesPlayer1(2) < Cap2Range(1) || newStrategiesPlayer1(2) > Cap2Range(2)
                continue;
            end
            
            Cap1 = newStrategiesPlayer1(1);  % �����豸�½����� (kW)
            Cap2 = newStrategiesPlayer1(2); % �����豸������������ (kW)
            % �����豸����
            N_l1 = Cap1; % �½��豸������
            N_l2 = Cap2; % ���������豸������
            Pt_GL_loss = percentPt_GL_loss * (N_l1 + N_l2); % ��t������ʱ�ε�������
            Pt_GL_buy_up = percentPt_GL_buy_up * (N_l1 + N_l2); % tʱ�����ϼ�����������
            Pt_GL_buy_grid = percentPt_GL_buy_grid * (N_l1 + N_l2); % tʱ���򱾼�����������
            Pt_GL_sell = percentPt_GL_sell * (N_l1 + N_l2); % tʱ�ε����۵���

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
    
    % 2. �绯ѧ������ҵ�������
    bestBenefitPlayer2 = currentBenefit;
    bestStrategiesPlayer2 = strategiesPlayer2;
    
    for deltaESS = -500:500:500
        newStrategiesPlayer2 = strategiesPlayer2 + deltaESS;
        % ȷ���µĲ����ڷ�Χ��
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
    
    % 3. ��ˮ������ҵ�������
    bestBenefitPlayer3 = currentBenefit;
    bestStrategiesPlayer3 = strategiesPlayer3;
    
    for deltaHPS = -500:500:500
        newStrategiesPlayer3 = strategiesPlayer3 + deltaHPS;
        % ȷ���µĲ����ڷ�Χ��
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
    
    % 4. �ⴢ����ҵ�������
    bestBenefitPlayer4 = currentBenefit;
    bestStrategiesPlayer4 = strategiesPlayer4;
    
    for deltaElectrolyzer = -500:500:500
        for deltaTank = -500:500:500
            for deltaFuelCell = -500:500:500
                newStrategiesPlayer4 = strategiesPlayer4 + [deltaElectrolyzer, deltaTank, deltaFuelCell];
                % ȷ���µĲ����ڷ�Χ��
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
legend({'Cap1', 'Cap2', 'ESS Capacity', 'HPS Capacity', 'Electrolyzer Capacity', 'Storage Tank Capacity', 'Fuel Cell Capacity'});
title('Decision Variables vs Iterations');

% ���ƾ�Ч��仯ͼ
subplot(2, 1, 2);
plot(1:numIterations, netBenefitHistory(:, 1), 'b-', 'LineWidth', 2);
xlabel('Iteration');
ylabel('Benefit');
legend({'Players Benefit'});
title('Total Benefit vs Iterations');

            
    
    
        
                                                        







