%% 电网侧电化学储能净效益计算
classdef ElectrochemicalStorageModel
   
    properties
        r = 0.05; % 贴现率
        m = 1.0; % 电化学储能参与调频的平均调用里程系数
        T_EES = 20; % 电化学储能装置使用寿命
        et_EES_cap = 0.5; % t时段电化学储能单位调频容量补偿价格
        et_EES_per = 0.5; % t时段电化学储能单位调频容量里程补偿价格
        et_EES_ess_inv = 1000; % 电化学储能装置单位容量建设费用
        e_EES_ope = 1000; % 单台电化学储能装置运行维护费用
    end
    
    methods
        function obj = ElectrochemicalStorageModel()
            % 构造函数初始化
        end
        
        function revenueFM = calculateRevenueFM(obj, Pt_EES_GL_f)
            % 电网侧电化学储能调频收益
            revenueFM = sum((obj.et_EES_cap + obj.et_EES_per * obj.m) * Pt_EES_GL_f) * (15/60);
        end
        
        function investCost = calculateInvestment(obj, P_EES_GL_ess_r)
            % 电网侧电化学储能装置建设成本
            investCost = sum((obj.r * (1 + obj.r)^obj.T_EES) / ((1 + obj.r)^obj.T_EES - 1) * obj.et_EES_ess_inv * P_EES_GL_ess_r) * (15/60);
        end
        
        function opeCost = calculateOpe(obj, Ni_EES_GL_ess)
            % 电网侧电化学储能装置运行维护成本
            opeCost = sum(obj.e_EES_ope * Ni_EES_GL_ess) * (15/60);
        end
        
        function elecNetBenefit = calculateElecNetBenefit(obj, Pt_EES_GL_f, ...
                                                            P_EES_GL_ess_r, Ni_EES_GL_ess)
            % 电网侧电化学储能净效益
            revenueFM = obj.calculateRevenueFM(Pt_EES_GL_f);
            investCost = obj.calculateInvestment(P_EES_GL_ess_r);
            opeCost = obj.calculateOpe(Ni_EES_GL_ess);
            elecNetBenefit = revenueFM - investCost - opeCost;
        end
    end
end

