%% ������绯ѧ���ܾ�Ч�����
classdef ElectrochemicalStorageModel
   
    properties
        r = 0.05; % ������
        m = 1.0; % �绯ѧ���ܲ����Ƶ��ƽ���������ϵ��
        T_EES = 20; % �绯ѧ����װ��ʹ������
        et_EES_cap = 0.5; % tʱ�ε绯ѧ���ܵ�λ��Ƶ���������۸�
        et_EES_per = 0.5; % tʱ�ε绯ѧ���ܵ�λ��Ƶ������̲����۸�
        et_EES_ess_inv = 1000; % �绯ѧ����װ�õ�λ�����������
        e_EES_ope = 1000; % ��̨�绯ѧ����װ������ά������
    end
    
    methods
        function obj = ElectrochemicalStorageModel()
            % ���캯����ʼ��
        end
        
        function revenueFM = calculateRevenueFM(obj, Pt_EES_GL_f)
            % ������绯ѧ���ܵ�Ƶ����
            revenueFM = sum((obj.et_EES_cap + obj.et_EES_per * obj.m) * Pt_EES_GL_f) * (15/60);
        end
        
        function investCost = calculateInvestment(obj, P_EES_GL_ess_r)
            % ������绯ѧ����װ�ý���ɱ�
            investCost = sum((obj.r * (1 + obj.r)^obj.T_EES) / ((1 + obj.r)^obj.T_EES - 1) * obj.et_EES_ess_inv * P_EES_GL_ess_r) * (15/60);
        end
        
        function opeCost = calculateOpe(obj, Ni_EES_GL_ess)
            % ������绯ѧ����װ������ά���ɱ�
            opeCost = sum(obj.e_EES_ope * Ni_EES_GL_ess) * (15/60);
        end
        
        function elecNetBenefit = calculateElecNetBenefit(obj, Pt_EES_GL_f, ...
                                                            P_EES_GL_ess_r, Ni_EES_GL_ess)
            % ������绯ѧ���ܾ�Ч��
            revenueFM = obj.calculateRevenueFM(Pt_EES_GL_f);
            investCost = obj.calculateInvestment(P_EES_GL_ess_r);
            opeCost = obj.calculateOpe(Ni_EES_GL_ess);
            elecNetBenefit = revenueFM - investCost - opeCost;
        end
    end
end

