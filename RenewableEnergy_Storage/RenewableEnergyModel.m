%% 新能源净效益计算
classdef RenewableEnergyModel
    properties
        WindPrice = 0.5; % 单位风电售电价格 (元/kWh)
        SolarPrice = 0.4; % 单位光伏售电价格 (元/kWh)
        SubsidyRate = 0.1; % 政府补贴比例 (元/kWh)
        r = 0.05; % 贴现率
        T_renewable_WT = 20; % 风电装机设备寿命（年）
        T_renewable_PV = 30; % 光伏装机设备寿命（年）
        InvestCostRateWind = 8000; % 风电单位容量建设成本 (元/kW)
        InvestCostRateSolar = 6000; % 光伏单位容量建设成本 (元/kW)
        OpeCostRateWind = 100; % 风电运行维护费用 (元/kW·年)
        OpeCostRateSolar = 80; % 光伏运行维护费用 (元/kW·年)
        TradingCostRate = 0.05; % 储能交易电价 (元/kWh)
    end
    
    methods
        function obj = RenewableEnergyModel() 
            % 构造函数初始化
        end

        function revenue = calculateSellRevenue(obj, windOutput, solarOutput, windCapacity, solarCapacity)
            % 新能源售电收益计算
            revenue = sum(windOutput* windCapacity * obj.WindPrice + solarOutput * solarCapacity * obj.SolarPrice) * (15/60); % 注意单位转换
        end

        function subsidy = calculateSubsidy(obj, windOutput, solarOutput, windCapacity, solarCapacity)
            % 新能源发电政府补贴计算
            subsidy = sum(windOutput* windCapacity * obj.SubsidyRate + solarOutput * solarCapacity * obj.SubsidyRate) * (15/60); % 注意单位转换
        end

        function investCost = calculateInvestment(obj, windCapacity, solarCapacity)
            % 新能源建设投资计算
            investCost = ((obj.r*((1+obj.r)^obj.T_renewable_WT))/(((1+obj.r)^obj.T_renewable_WT)-1)) * windCapacity * obj.InvestCostRateWind + ...
                         ((obj.r*((1+obj.r)^obj.T_renewable_PV))/(((1+obj.r)^obj.T_renewable_PV)-1)) * solarCapacity * obj.InvestCostRateSolar;
        end

        function opeCost = calculateOpeCost(obj, windCapacity, solarCapacity)
            % 新能源建设运维成本计算
            opeCost = windCapacity * obj.OpeCostRateWind + ...
                      solarCapacity * obj.OpeCostRateSolar;
        end

        function tradingCost = calculateTradingCost(obj, tradingPower_NE)
            % 新能源与储能的交易成本计算
            tradingCost = sum(tradingPower_NE) * obj.TradingCostRate * (15/60); % 注意单位转换
        end

        function netBenefit = calculateNetBenefit(obj, windOutput, solarOutput, ...
                                                  windCapacity, solarCapacity, tradingPower_NE)
            % 新能源总净效益计算
            revenue = obj.calculateSellRevenue(windOutput, solarOutput, windCapacity, solarCapacity);
            subsidy = obj.calculateSubsidy(windOutput, solarOutput, windCapacity, solarCapacity);
            investCost = obj.calculateInvestment(windCapacity, solarCapacity);
            opeCost = obj.calculateOpeCost(windCapacity, solarCapacity);
            tradingCost = obj.calculateTradingCost(tradingPower_NE);
            netBenefit = revenue + subsidy - investCost - opeCost - tradingCost;
        end
    end
end
