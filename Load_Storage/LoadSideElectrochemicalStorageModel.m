%% 负荷侧电化学储能净效益计算
classdef LoadSideElectrochemicalStorageModel
    properties
        PeakPrice = 1.2;     % 峰期电价 (元/kWh)
        ValleyPrice = 0.3;   % 谷期电价 (元/kWh)
        InvestCostRate = 2000;     % 单位容量储能建设成本 (元/kW)
        OpeCostRate = 40;          % 储能运行维护成本 (元/kW·年)
        Lifetime = 15;            % 储能寿命（年）
        DiscountRate = 0.05;      % 贴现率
    end
    
    methods
        function obj = LoadSideElectrochemicalStorageModel()
            % 构造函数初始化
        end
        
        function arbitrageRevenue = calculateArbitrageRevenue(obj, chargePower_15min, dischargePower_15min)
            % 负荷侧电化学储能套利收益计算
            arbitrageRevenue = sum(dischargePower_15min * obj.PeakPrice - chargePower_15min * obj.ValleyPrice) * (15/60);
        end
        
        function investCost = calculateInvestment(obj, storageCapacity)
            % 储能建设成本计算
            investCost = obj.InvestCostRate * storageCapacity * ...
                         (obj.DiscountRate * (1 + obj.DiscountRate)^obj.Lifetime) / ...
                         ((1 + obj.DiscountRate)^obj.Lifetime - 1);
        end
        
        function opeCost = calculateOpeCost(obj, storageCapacity)
            % 储能运行维护成本计算
            opeCost = storageCapacity * obj.OpeCostRate;
        end
        
        function netBenefit = calculateNetBenefit(obj, chargePower_15min, dischargePower_15min, storageCapacity)
            % 总净效益计算
            arbitrageRevenue = obj.calculateArbitrageRevenue(chargePower_15min, dischargePower_15min);
            investCost = obj.calculateInvestment(storageCapacity);
            opeCost = obj.calculateOpeCost(storageCapacity);
            
            % 计算净效益
            netBenefit = arbitrageRevenue - investCost - opeCost;
        end
    end
end