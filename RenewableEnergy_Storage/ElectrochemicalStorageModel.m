%% ����Դ��绯ѧ���ܾ�Ч�����
classdef ElectrochemicalStorageModel
    properties
        WindPrice = 0.5; % ���������� (Ԫ/kWh)
        SolarPrice = 0.4; % ���������� (Ԫ/kWh)
        TradingPrice = 0.05; % ���ܽ��׵�� (Ԫ/kWh)
        InvestCostRate = 3000; % ��λ�������ܽ���ɱ� (Ԫ/kW)
        OpeCostRate = 50; % ��������ά���ɱ� (Ԫ/kW����)
        ChargingEfficiency = 0.95; % ���ܳ��Ч��
        DischargingEfficiency = 0.95; % ���ܷŵ�Ч��
        Lifetime = 15; % �����������꣩
        DiscountRate = 0.05; % ������
    end
    
    methods
        function obj = ElectrochemicalStorageModel()
            % ���캯����ʼ��
        end
        
        function fluRevenue = calculateFluctuationRevenue(obj, windEnergy_15min, solarEnergy_15min)
            % ƽ�ַ����������������
            fluRevenue = sum(windEnergy_15min * obj.WindPrice + solarEnergy_15min * obj.SolarPrice) * (15/60); % 15����תСʱ
        end
        
        function tradingRevenue = calculateTradingRevenue(obj, tradingPower_ESS_15min)
            % ����������Դ�Ľ����������
            tradingRevenue = sum(tradingPower_ESS_15min * obj.TradingPrice) * (15/60); % 15����תСʱ
        end
        
        function investCost = calculateInvestment(obj, storageCapacity_ESS)
            % ���ܽ���ɱ�����
            investCost = obj.InvestCostRate * storageCapacity_ESS * ...
                         (obj.DiscountRate * (1 + obj.DiscountRate)^obj.Lifetime) / ...
                         ((1 + obj.DiscountRate)^obj.Lifetime - 1);
        end
        
        function opeCost = calculateOpeCost(obj, storageCapacity_ESS)
            % ��������ά���ɱ�����
            opeCost = storageCapacity_ESS * obj.OpeCostRate;
        end
        
        function netBenefit = calculateNetBenefit(obj, windEnergy_15min, solarEnergy_15min, ...
                                                  tradingPower_ESS_15min, storageCapacity_ESS)
            % �ܾ�Ч�����
            fluRevenue = obj.calculateFluctuationRevenue(windEnergy_15min, solarEnergy_15min);
            tradingRevenue = obj.calculateTradingRevenue(tradingPower_ESS_15min);
            investCost = obj.calculateInvestment(storageCapacity_ESS);
            opeCost = obj.calculateOpeCost(storageCapacity_ESS);
            netBenefit = fluRevenue + tradingRevenue - investCost - opeCost;
        end
    end
end
