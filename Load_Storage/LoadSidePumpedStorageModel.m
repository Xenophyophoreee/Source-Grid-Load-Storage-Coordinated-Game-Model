classdef LoadSidePumpedStorageModel
    properties
        % 峰谷电价参数
        PeakPrice = 1.2;     % 峰期电价 (元/kWh)
        ValleyPrice = 0.3;   % 谷期电价 (元/kWh)
        
        % 抽水蓄能成本参数
        InvestCostRate = 4000; % 单位容量建设成本 (元/kW)
        OpeCostRate = 200; % 抽水蓄能运行维护成本 (元/kW·年)
        
        % 抽水蓄能性能参数
        ChargingEfficiency = 0.85; % 抽水蓄能充电效率
        DischargingEfficiency = 0.9; % 抽水蓄能放电效率
        
        % 经济性参数
        Lifetime = 30; % 抽水蓄能装置寿命（年）
        DiscountRate = 0.05; % 贴现率
    end
    
    methods
        function obj = LoadSidePumpedStorageModel()
            % 构造函数初始化
        end
        
        function arbitrageRevenue = calculateArbitrageRevenue(obj, chargePower_1h, dischargePower_1h)
            % 负荷侧抽水蓄能分时电价套利收益计算
            arbitrageRevenue =sum(dischargePower_1h * obj.PeakPrice - chargePower_1h* obj.ValleyPrice);
        end
        
        function investCost = calculateInvestment(obj, storageCapacity_HPS)
            % 抽水蓄能建设成本计算
            investCost = obj.InvestCostRate * storageCapacity_HPS * ...
                         (obj.DiscountRate * (1 + obj.DiscountRate)^obj.Lifetime) / ...
                         ((1 + obj.DiscountRate)^obj.Lifetime - 1);
        end
        
        function opeCost = calculateOpeCost(obj, storageCapacity_HPS)
            % 抽水蓄能运行维护成本计算
            opeCost = storageCapacity_HPS * obj.OpeCostRate;
        end
        
        function netBenefit = calculateNetBenefit(obj, chargePower_1h, dischargePower_1h, storageCapacity_HPS)
            % 总净效益计算
            arbitrageRevenue = obj.calculateArbitrageRevenue(chargePower_1h, dischargePower_1h);
            investCost = obj.calculateInvestment(storageCapacity_HPS);
            opeCost = obj.calculateOpeCost(storageCapacity_HPS);
            
            % 计算净效益
            netBenefit = arbitrageRevenue - investCost - opeCost;
        end
    end
end