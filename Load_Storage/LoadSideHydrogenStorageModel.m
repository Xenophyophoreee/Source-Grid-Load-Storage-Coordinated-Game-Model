classdef LoadSideHydrogenStorageModel
    properties
        % 峰谷电价参数
        PeakPrice = 1.2;     % 峰期电价 (元/kWh)
        ValleyPrice = 0.3;   % 谷期电价 (元/kWh)
        
        % 电解槽、储氢罐、氢燃料电池的单位建设成本和运行维护成本
        ElectrolyzerCostRate = 10000; % 电解槽单位建设成本 (元/kW)
        StorageTankCostRate = 1500; % 储氢罐单位建设成本 (元/kW)
        FuelCellCostRate = 6000; % 氢燃料电池单位建设成本 (元/kW)
        
        ElectrolyzerOpeCostRate = 500; % 电解槽运行维护成本 (元/kW·年)
        StorageTankOpeCostRate = 50; % 储氢罐运行维护成本 (元/kW·年)
        FuelCellOpeCostRate = 300; % 氢燃料电池运行维护成本 (元/kW·年)
        
        ChargingEfficiency = 0.85; % 氢储能充电效率
        DischargingEfficiency = 0.90; % 氢储能放电效率
        Lifetime = 25; % 氢储能装置寿命（年）
        DiscountRate = 0.05; % 贴现率
    end
    
    methods
        function obj = LoadSideHydrogenStorageModel()
            % 构造函数初始化
        end
        
        function arbitrageRevenue = calculateArbitrageRevenue(obj, chargePower_H2_1d, dischargePower_H2_1d)
            % 负荷侧氢储能分时电价套利收益计算   
            arbitrageRevenue = sum(dischargePower_H2_1d * obj.PeakPrice-chargePower_H2_1d * obj.ValleyPrice  ) * 24; % 一日转小时
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
        
        function netBenefit = calculateNetBenefit(obj, chargePower_1d, dischargePower_1d, ...
                                                  electrolyzerCapacity, storageTankCapacity, fuelCellCapacity)
            % 总净效益计算
            arbitrageRevenue = obj.calculateArbitrageRevenue(chargePower_1d, dischargePower_1d);
            investCost = obj.calculateInvestment(electrolyzerCapacity, storageTankCapacity, fuelCellCapacity);
            opeCost = obj.calculateOpeCost(electrolyzerCapacity, storageTankCapacity, fuelCellCapacity);
            
            % 计算净效益
            netBenefit = arbitrageRevenue - investCost - opeCost;
        end
    end
end