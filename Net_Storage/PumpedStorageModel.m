%% 电网侧抽水蓄能净效益计算
classdef PumpedStorageModel
   
    properties
        r = 0.05; % 贴现率
        T_HPS = 20; % 抽水蓄能装置使用寿命
        e_V_sub = 0.5; % 抽水蓄能参与调峰的单位补偿价格
        e_HPS_ess_inv = 1000; % 抽水蓄能装置单位容量建设费用
        e_HPS_ope = 1000; % 单台抽水蓄能装置运行维护费用
    end
    
    methods
        function obj = PumpedStorageModel()
            % 构造函数初始化
        end
        
        function revenueFM = calculateRevenueFM(obj, Pt_V_HPS_GL)
            % 电网侧抽水蓄能调峰收益
            revenueFM = sum(obj.e_V_sub * Pt_V_HPS_GL);
        end
        
        function investCost = calculateInvestment(obj, P_HPS_GL_ess_r)
            % 电网侧抽水蓄能装置建设成本
            investCost = sum((obj.r * (1 + obj.r)^obj.T_HPS) / ((1 + obj.r)^obj.T_HPS - 1) * obj.e_HPS_ess_inv * P_HPS_GL_ess_r);
        end
        
        function opeCost = calculateOpe(obj, Ni_HPS_GL_ess)
            % 电网侧抽水蓄能装置运行维护成本
            opeCost = sum(obj.e_HPS_ope * Ni_HPS_GL_ess);
        end
        
        function pumpNetBenefit = calculatePumpNetBenefit(obj, Pt_V_HPS_GL, ...
                                                            P_HPS_GL_ess_r, Ni_HPS_GL_ess)
            % 电网侧抽水蓄能净效益
            revenueFM = obj.calculateRevenueFM(Pt_V_HPS_GL);
            investCost = obj.calculateInvestment(P_HPS_GL_ess_r);
            opeCost = obj.calculateOpe(Ni_HPS_GL_ess);
            pumpNetBenefit = revenueFM - investCost - opeCost;
        end
    end
end
