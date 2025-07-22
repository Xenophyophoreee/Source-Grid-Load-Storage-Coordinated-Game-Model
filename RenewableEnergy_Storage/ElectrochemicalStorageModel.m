%% 新能源侧电化学储能净效益计算
classdef ElectrochemicalStorageModel
    properties
        WindPrice = 0.5; % 风电上网电价 (元/kWh)
        SolarPrice = 0.4; % 光伏上网电价 (元/kWh)
        TradingPrice = 0.05; % 储能交易电价 (元/kWh)
        InvestCostRate = 3000; % 单位容量储能建设成本 (元/kW)
        OpeCostRate = 50; % 储能运行维护成本 (元/kW·年)
        ChargingEfficiency = 0.95; % 储能充电效率
        DischargingEfficiency = 0.95; % 储能放电效率
        Lifetime = 15; % 储能寿命（年）
        DiscountRate = 0.05; % 贴现率
    end
    
    methods
        function obj = ElectrochemicalStorageModel()
            % 构造函数初始化
        end
        
        function fluRevenue = calculateFluctuationRevenue(obj, windEnergy_15min, solarEnergy_15min)
            % 平抑风光出力波动收益计算
            fluRevenue = sum(windEnergy_15min * obj.WindPrice + solarEnergy_15min * obj.SolarPrice) * (15/60); % 15分钟转小时
        end
        
        function tradingRevenue = calculateTradingRevenue(obj, tradingPower_ESS_15min)
            % 储能与新能源的交易收入计算
            tradingRevenue = sum(tradingPower_ESS_15min * obj.TradingPrice) * (15/60); % 15分钟转小时
        end
        
        function investCost = calculateInvestment(obj, storageCapacity_ESS)
            % 储能建设成本计算
            investCost = obj.InvestCostRate * storageCapacity_ESS * ...
                         (obj.DiscountRate * (1 + obj.DiscountRate)^obj.Lifetime) / ...
                         ((1 + obj.DiscountRate)^obj.Lifetime - 1);
        end
        
        function opeCost = calculateOpeCost(obj, storageCapacity_ESS)
            % 储能运行维护成本计算
            opeCost = storageCapacity_ESS * obj.OpeCostRate;
        end
        
        function netBenefit = calculateNetBenefit(obj, windEnergy_15min, solarEnergy_15min, ...
                                                  tradingPower_ESS_15min, storageCapacity_ESS)
            % 总净效益计算
            fluRevenue = obj.calculateFluctuationRevenue(windEnergy_15min, solarEnergy_15min);
            tradingRevenue = obj.calculateTradingRevenue(tradingPower_ESS_15min);
            investCost = obj.calculateInvestment(storageCapacity_ESS);
            opeCost = obj.calculateOpeCost(storageCapacity_ESS);
            netBenefit = fluRevenue + tradingRevenue - investCost - opeCost;
        end
    end
end
