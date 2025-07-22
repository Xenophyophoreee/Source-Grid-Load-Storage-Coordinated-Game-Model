%% �������ⴢ�ܾ�Ч�����
classdef HydrogenStorageModel

    properties
        r = 0.05; % ������
        T_H2_GL = 20; % �ⴢ��װ��ʹ������
        c_TOU = 0.5; % ��ʱ���
        
        % ����(EC)�������(SC)����ȼ��(FC)��صĵ�λ����ɱ�������ά���ɱ�
        e_H2_EC_inv = 12000; % ���۵�λ����ɱ� (Ԫ/kW)
        e_H2_SC_inv = 1500; % ����޵�λ����ɱ� (Ԫ/kW)
        e_H2_FC_inv = 8000; % ��ȼ�ϵ�ص�λ����ɱ� (Ԫ/kW)
        
        e_H2_EC_ope = 500; % ��������ά���ɱ� (Ԫ/kW����)
        e_H2_SC_ope = 50; % ���������ά���ɱ� (Ԫ/kW����)
        e_H2_FC_ope = 300; % ��ȼ�ϵ������ά���ɱ� (Ԫ/kW����)
    end
    
    methods
        function obj = HydrogenStorageModel()
            % ���캯����ʼ��
        end
        
        function revenueH2 = calculateRevenueH2(obj, Pt_H2_GL_dis, Pt_H2_GL_ch)
            % �������ⴢ�ܲ��뼾��������ʱ�Ƶ�����
            revenueH2 = sum((Pt_H2_GL_dis - Pt_H2_GL_ch) * obj.c_TOU) * 24;
        end
        
        function investCost = calculateInvestment(obj, P_H2_GL_EC_r, P_H2_GL_SC_r, P_H2_GL_FC_r)
            % �������ⴢ��װ�ý���ɱ�,�������ۡ�����޺���ȼ�ϵ��
            ec_inv = obj.e_H2_EC_inv * P_H2_GL_EC_r;
            sc_inv = obj.e_H2_SC_inv * P_H2_GL_SC_r;
            fc_inv = obj.e_H2_FC_inv * P_H2_GL_FC_r;
            % �����ʵ�������껯Ͷ�ʳɱ�
            investCost = ((obj.r * (1 + obj.r)^obj.T_H2_GL) / ((1 + obj.r)^obj.T_H2_GL - 1) * (ec_inv + sc_inv + fc_inv)) * 24;
        end
        
        function opeCost = calculateOpe(obj, Ni_H2_GL_EC_r, Ni_H2_GL_SC_r, Ni_H2_GL_FC_r)
            % �������ⴢ��װ������ά���ɱ�
            ec_ope = obj.e_H2_EC_ope * Ni_H2_GL_EC_r;
            sc_ope = obj.e_H2_SC_ope * Ni_H2_GL_SC_r;
            fc_ope = obj.e_H2_FC_ope * Ni_H2_GL_FC_r;
            opeCost = ec_ope + sc_ope + fc_ope;
        end
        
        function pumpNetBenefit = calculatePumpNetBenefit(obj, Pt_H2_GL_dis, Pt_H2_GL_ch, P_H2_GL_EC_r, P_H2_GL_SC_r, P_H2_GL_FC_r, ...
                                                        Ni_H2_GL_EC_r, Ni_H2_GL_SC_r, Ni_H2_GL_FC_r)
            % �������ⴢ�ܾ�Ч��
            revenueH2 = obj.calculateRevenueH2(Pt_H2_GL_dis, Pt_H2_GL_ch);
            investCost = obj.calculateInvestment(P_H2_GL_EC_r, P_H2_GL_SC_r, P_H2_GL_FC_r);
            opeCost = obj.calculateOpe(Ni_H2_GL_EC_r, Ni_H2_GL_SC_r, Ni_H2_GL_FC_r);
            pumpNetBenefit = revenueH2 - investCost - opeCost;
        end
    end
end

