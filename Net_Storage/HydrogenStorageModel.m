%% 电网侧氢储能净效益计算
classdef HydrogenStorageModel

    properties
        r = 0.05; % 贴现率
        T_H2_GL = 20; % 氢储能装置使用寿命
        c_TOU = 0.5; % 分时电价
        
        % 电解槽(EC)、储氢罐(SC)、氢燃料(FC)电池的单位建设成本和运行维护成本
        e_H2_EC_inv = 12000; % 电解槽单位建设成本 (元/kW)
        e_H2_SC_inv = 1500; % 储氢罐单位建设成本 (元/kW)
        e_H2_FC_inv = 8000; % 氢燃料电池单位建设成本 (元/kW)
        
        e_H2_EC_ope = 500; % 电解槽运行维护成本 (元/kW·年)
        e_H2_SC_ope = 50; % 储氢罐运行维护成本 (元/kW·年)
        e_H2_FC_ope = 300; % 氢燃料电池运行维护成本 (元/kW·年)
    end
    
    methods
        function obj = HydrogenStorageModel()
            % 构造函数初始化
        end
        
        function revenueH2 = calculateRevenueH2(obj, Pt_H2_GL_dis, Pt_H2_GL_ch)
            % 电网侧氢储能参与季节性能量时移的收益
            revenueH2 = sum((Pt_H2_GL_dis - Pt_H2_GL_ch) * obj.c_TOU) * 24;
        end
        
        function investCost = calculateInvestment(obj, P_H2_GL_EC_r, P_H2_GL_SC_r, P_H2_GL_FC_r)
            % 电网侧氢储能装置建设成本,包括电解槽、储氢罐和氢燃料电池
            ec_inv = obj.e_H2_EC_inv * P_H2_GL_EC_r;
            sc_inv = obj.e_H2_SC_inv * P_H2_GL_SC_r;
            fc_inv = obj.e_H2_FC_inv * P_H2_GL_FC_r;
            % 贴现率调整后的年化投资成本
            investCost = ((obj.r * (1 + obj.r)^obj.T_H2_GL) / ((1 + obj.r)^obj.T_H2_GL - 1) * (ec_inv + sc_inv + fc_inv)) * 24;
        end
        
        function opeCost = calculateOpe(obj, Ni_H2_GL_EC_r, Ni_H2_GL_SC_r, Ni_H2_GL_FC_r)
            % 电网侧氢储能装置运行维护成本
            ec_ope = obj.e_H2_EC_ope * Ni_H2_GL_EC_r;
            sc_ope = obj.e_H2_SC_ope * Ni_H2_GL_SC_r;
            fc_ope = obj.e_H2_FC_ope * Ni_H2_GL_FC_r;
            opeCost = ec_ope + sc_ope + fc_ope;
        end
        
        function pumpNetBenefit = calculatePumpNetBenefit(obj, Pt_H2_GL_dis, Pt_H2_GL_ch, P_H2_GL_EC_r, P_H2_GL_SC_r, P_H2_GL_FC_r, ...
                                                        Ni_H2_GL_EC_r, Ni_H2_GL_SC_r, Ni_H2_GL_FC_r)
            % 电网侧氢储能净效益
            revenueH2 = obj.calculateRevenueH2(Pt_H2_GL_dis, Pt_H2_GL_ch);
            investCost = obj.calculateInvestment(P_H2_GL_EC_r, P_H2_GL_SC_r, P_H2_GL_FC_r);
            opeCost = obj.calculateOpe(Ni_H2_GL_EC_r, Ni_H2_GL_SC_r, Ni_H2_GL_FC_r);
            pumpNetBenefit = revenueH2 - investCost - opeCost;
        end
    end
end

