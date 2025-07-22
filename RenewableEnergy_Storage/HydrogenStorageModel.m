%% ����Դ���ⴢ�ܾ�Ч�����
classdef HydrogenStorageModel
    properties
        WindPrice = 0.5; % ���������� (Ԫ/kWh)
        SolarPrice = 0.4; % ���������� (Ԫ/kWh)
        TradingPrice = 0.05; % �ⴢ�ܽ��׵�� (Ԫ/kWh)
        
        % ���ۡ�����ޡ���ȼ�ϵ�صĵ�λ����ɱ�������ά���ɱ�
        ElectrolyzerCostRate = 12000; % ���۵�λ����ɱ� (Ԫ/kW)
        StorageTankCostRate = 1500; % ����޵�λ����ɱ� (Ԫ/kW)
        FuelCellCostRate = 8000; % ��ȼ�ϵ�ص�λ����ɱ� (Ԫ/kW)
        
        ElectrolyzerOpeCostRate = 500; % ��������ά���ɱ� (Ԫ/kW����)
        StorageTankOpeCostRate = 50; % ���������ά���ɱ� (Ԫ/kW����)
        FuelCellOpeCostRate = 300; % ��ȼ�ϵ������ά���ɱ� (Ԫ/kW����)
        
        ChargingEfficiency = 0.85; % �ⴢ�ܳ��Ч��
        DischargingEfficiency = 0.90; % �ⴢ�ܷŵ�Ч��
        Lifetime = 25; % �ⴢ��װ���������꣩
        DiscountRate = 0.05; % ������
    end
    
    methods
        function obj = HydrogenStorageModel()
            % ���캯����ʼ��
        end
        
        function gridSecurityRevenue = calculateGridSecurityRevenue(obj, windEnergy_1d, solarEnergy_1d)
            % ��ǿ������ȫ�ȶ������������
            gridSecurityRevenue = sum(windEnergy_1d * obj.WindPrice + solarEnergy_1d * obj.SolarPrice) * 24; % һ��תСʱ
        end
        
        function tradingRevenue = calculateTradingRevenue(obj, tradingPower_H2_1d)
            % �ⴢ��������Դ�Ľ����������
            tradingRevenue = sum(tradingPower_H2_1d * obj.TradingPrice) * 24; % һ��תСʱ
        end
        
        function investCost = calculateInvestment(obj, electrolyzerCapacity, storageTankCapacity, fuelCellCapacity)
            % �ⴢ�ܽ���ɱ����㣬�������ۡ�����޺���ȼ�ϵ��
            electrolyzerCost = obj.ElectrolyzerCostRate * electrolyzerCapacity;
            storageTankCost = obj.StorageTankCostRate * storageTankCapacity;
            fuelCellCost = obj.FuelCellCostRate * fuelCellCapacity;
            
            % �����ʵ�������껯Ͷ�ʳɱ�
            totalInvestCost = electrolyzerCost + storageTankCost + fuelCellCost;
            investCost = totalInvestCost * (obj.DiscountRate * (1 + obj.DiscountRate)^obj.Lifetime) / ...
                         ((1 + obj.DiscountRate)^obj.Lifetime - 1);
        end
        
        function opeCost = calculateOpeCost(obj, electrolyzerCapacity, storageTankCapacity, fuelCellCapacity)
            % �ⴢ������ά���ɱ����㣬�������ۡ�����޺���ȼ�ϵ��
            electrolyzerOpeCost = obj.ElectrolyzerOpeCostRate * electrolyzerCapacity;
            storageTankOpeCost = obj.StorageTankOpeCostRate * storageTankCapacity;
            fuelCellOpeCost = obj.FuelCellOpeCostRate * fuelCellCapacity;
            
            totalOpeCost = electrolyzerOpeCost + storageTankOpeCost + fuelCellOpeCost;
            opeCost = totalOpeCost; % ÿ����ά�ɱ� (Ԫ)
        end
        
        function netBenefit = calculateNetBenefit(obj, windEnergy_1d, solarEnergy_1d, ...
                                                  tradingPower_H2_1d, electrolyzerCapacity, storageTankCapacity, fuelCellCapacity)
            % �ܾ�Ч�����
            gridSecurityRevenue = obj.calculateGridSecurityRevenue(windEnergy_1d, solarEnergy_1d);
            tradingRevenue = obj.calculateTradingRevenue(tradingPower_H2_1d);
            investCost = obj.calculateInvestment(electrolyzerCapacity, storageTankCapacity, fuelCellCapacity);
            opeCost = obj.calculateOpeCost(electrolyzerCapacity, storageTankCapacity, fuelCellCapacity);
            netBenefit = gridSecurityRevenue + tradingRevenue - investCost - opeCost;
        end
    end
end
