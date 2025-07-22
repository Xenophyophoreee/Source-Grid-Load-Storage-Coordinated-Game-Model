%% 新能源侧抽水蓄能净效益计算
classdef PumpedStorageModel
    properties
        WindPrice = 0.5; % 风电上网电价 (元/kWh)
        SolarPrice = 0.4; % 光伏上网电价 (元/kWh)
        TradingPrice = 0.05; % 储能交易电价 (元/kWh)
        InvestCostRate = 5000; % 单位容量建设成本 (元/kW)
        OpeCostRate = 200; % 抽水蓄能运行维护成本 (元/kW·年)
        ChargingEfficiency = 0.85; % 抽水蓄能充电效率
        DischargingEfficiency = 0.9; % 抽水蓄能放电效率
        Lifetime = 30; % 抽水蓄能装置寿命（年）
        DiscountRate = 0.05; % 贴现率
    end

    methods
        function obj = PumpedStorageModel()
            % 构造函数初始化
        end

        function fluRevenue = calculateFluctuationRevenue(obj, windEnergy_1h, solarEnergy_1h)
            % 平抑风光出力波动收益计算
            fluRevenue = sum(windEnergy_1h * obj.WindPrice + solarEnergy_1h * obj.SolarPrice); % 收益 (元)
        end

        function tradingRevenue = calculateTradingRevenue(obj, tradingPower_HPS_1h)
            % 抽水蓄能与新能源的交易收入计算
            tradingRevenue = sum(tradingPower_HPS_1h * obj.TradingPrice); % 收益 (元)
        end

        function investCost = calculateInvestment(obj, storageCapacity_HPS)
            % 抽水蓄能建设成本计算
            investCost = obj.InvestCostRate * storageCapacity_HPS * ...
                         (obj.DiscountRate * (1 + obj.DiscountRate)^obj.Lifetime) / ...
                         ((1 + obj.DiscountRate)^obj.Lifetime - 1);
        end

        function opeCost = calculateOpeCost(obj, storageCapacity_HPS)
            % 抽水蓄能运行维护成本计算
            opeCost = storageCapacity_HPS * obj.OpeCostRate; % 年运维成本 (元)
        end

        function netBenefit = calculateNetBenefit(obj, windEnergy_1h, solarEnergy_1h, ...
                                                  tradingPower_HPS_1h, storageCapacity_HPS)
            % 总净效益计算
            fluRevenue = obj.calculateFluctuationRevenue(windEnergy_1h, solarEnergy_1h);
            tradingRevenue = obj.calculateTradingRevenue(tradingPower_HPS_1h);
            investCost = obj.calculateInvestment(storageCapacity_HPS);
            opeCost = obj.calculateOpeCost(storageCapacity_HPS);
            netBenefit = fluRevenue + tradingRevenue - investCost - opeCost;
        end
    end
end
