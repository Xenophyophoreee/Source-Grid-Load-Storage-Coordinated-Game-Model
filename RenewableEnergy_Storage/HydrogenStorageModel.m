%% 新能源侧氢储能净效益计算
classdef HydrogenStorageModel
    properties
        WindPrice = 0.5; % 风电上网电价 (元/kWh)
        SolarPrice = 0.4; % 光伏上网电价 (元/kWh)
        TradingPrice = 0.05; % 氢储能交易电价 (元/kWh)
        
        % 电解槽、储氢罐、氢燃料电池的单位建设成本和运行维护成本
        ElectrolyzerCostRate = 12000; % 电解槽单位建设成本 (元/kW)
        StorageTankCostRate = 1500; % 储氢罐单位建设成本 (元/kW)
        FuelCellCostRate = 8000; % 氢燃料电池单位建设成本 (元/kW)
        
        ElectrolyzerOpeCostRate = 500; % 电解槽运行维护成本 (元/kW·年)
        StorageTankOpeCostRate = 50; % 储氢罐运行维护成本 (元/kW·年)
        FuelCellOpeCostRate = 300; % 氢燃料电池运行维护成本 (元/kW·年)
        
        ChargingEfficiency = 0.85; % 氢储能充电效率
        DischargingEfficiency = 0.90; % 氢储能放电效率
        Lifetime = 25; % 氢储能装置寿命（年）
        DiscountRate = 0.05; % 贴现率
    end
    
    methods
        function obj = HydrogenStorageModel()
            % 构造函数初始化
        end
        
        function gridSecurityRevenue = calculateGridSecurityRevenue(obj, windEnergy_1d, solarEnergy_1d)
            % 增强电网安全稳定运行收益计算
            gridSecurityRevenue = sum(windEnergy_1d * obj.WindPrice + solarEnergy_1d * obj.SolarPrice) * 24; % 一日转小时
        end
        
        function tradingRevenue = calculateTradingRevenue(obj, tradingPower_H2_1d)
            % 氢储能与新能源的交易收入计算
            tradingRevenue = sum(tradingPower_H2_1d * obj.TradingPrice) * 24; % 一日转小时
        end
        
        function investCost = calculateInvestment(obj, electrolyzerCapacity, storageTankCapacity, fuelCellCapacity)
            % 氢储能建设成本计算，包括电解槽、储氢罐和氢燃料电池
            electrolyzerCost = obj.ElectrolyzerCostRate * electrolyzerCapacity;
            storageTankCost = obj.StorageTankCostRate * storageTankCapacity;
            fuelCellCost = obj.FuelCellCostRate * fuelCellCapacity;
            
            % 贴现率调整后的年化投资成本
            totalInvestCost = electrolyzerCost + storageTankCost + fuelCellCost;
            investCost = totalInvestCost * (obj.DiscountRate * (1 + obj.DiscountRate)^obj.Lifetime) / ...
                         ((1 + obj.DiscountRate)^obj.Lifetime - 1);
        end
        
        function opeCost = calculateOpeCost(obj, electrolyzerCapacity, storageTankCapacity, fuelCellCapacity)
            % 氢储能运行维护成本计算，包括电解槽、储氢罐和氢燃料电池
            electrolyzerOpeCost = obj.ElectrolyzerOpeCostRate * electrolyzerCapacity;
            storageTankOpeCost = obj.StorageTankOpeCostRate * storageTankCapacity;
            fuelCellOpeCost = obj.FuelCellOpeCostRate * fuelCellCapacity;
            
            totalOpeCost = electrolyzerOpeCost + storageTankOpeCost + fuelCellOpeCost;
            opeCost = totalOpeCost; % 每年运维成本 (元)
        end
        
        function netBenefit = calculateNetBenefit(obj, windEnergy_1d, solarEnergy_1d, ...
                                                  tradingPower_H2_1d, electrolyzerCapacity, storageTankCapacity, fuelCellCapacity)
            % 总净效益计算
            gridSecurityRevenue = obj.calculateGridSecurityRevenue(windEnergy_1d, solarEnergy_1d);
            tradingRevenue = obj.calculateTradingRevenue(tradingPower_H2_1d);
            investCost = obj.calculateInvestment(electrolyzerCapacity, storageTankCapacity, fuelCellCapacity);
            opeCost = obj.calculateOpeCost(electrolyzerCapacity, storageTankCapacity, fuelCellCapacity);
            netBenefit = gridSecurityRevenue + tradingRevenue - investCost - opeCost;
        end
    end
end
