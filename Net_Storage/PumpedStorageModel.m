%% �������ˮ���ܾ�Ч�����
classdef PumpedStorageModel
   
    properties
        r = 0.05; % ������
        T_HPS = 20; % ��ˮ����װ��ʹ������
        e_V_sub = 0.5; % ��ˮ���ܲ������ĵ�λ�����۸�
        e_HPS_ess_inv = 1000; % ��ˮ����װ�õ�λ�����������
        e_HPS_ope = 1000; % ��̨��ˮ����װ������ά������
    end
    
    methods
        function obj = PumpedStorageModel()
            % ���캯����ʼ��
        end
        
        function revenueFM = calculateRevenueFM(obj, Pt_V_HPS_GL)
            % �������ˮ���ܵ�������
            revenueFM = sum(obj.e_V_sub * Pt_V_HPS_GL);
        end
        
        function investCost = calculateInvestment(obj, P_HPS_GL_ess_r)
            % �������ˮ����װ�ý���ɱ�
            investCost = sum((obj.r * (1 + obj.r)^obj.T_HPS) / ((1 + obj.r)^obj.T_HPS - 1) * obj.e_HPS_ess_inv * P_HPS_GL_ess_r);
        end
        
        function opeCost = calculateOpe(obj, Ni_HPS_GL_ess)
            % �������ˮ����װ������ά���ɱ�
            opeCost = sum(obj.e_HPS_ope * Ni_HPS_GL_ess);
        end
        
        function pumpNetBenefit = calculatePumpNetBenefit(obj, Pt_V_HPS_GL, ...
                                                            P_HPS_GL_ess_r, Ni_HPS_GL_ess)
            % �������ˮ���ܾ�Ч��
            revenueFM = obj.calculateRevenueFM(Pt_V_HPS_GL);
            investCost = obj.calculateInvestment(P_HPS_GL_ess_r);
            opeCost = obj.calculateOpe(Ni_HPS_GL_ess);
            pumpNetBenefit = revenueFM - investCost - opeCost;
        end
    end
end
