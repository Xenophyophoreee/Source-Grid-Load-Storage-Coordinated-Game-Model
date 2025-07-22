%% ����Դ���ˮ���ܾ�Ч�����
classdef PumpedStorageModel
    properties
        WindPrice = 0.5; % ���������� (Ԫ/kWh)
        SolarPrice = 0.4; % ���������� (Ԫ/kWh)
        TradingPrice = 0.05; % ���ܽ��׵�� (Ԫ/kWh)
        InvestCostRate = 5000; % ��λ��������ɱ� (Ԫ/kW)
        OpeCostRate = 200; % ��ˮ��������ά���ɱ� (Ԫ/kW����)
        ChargingEfficiency = 0.85; % ��ˮ���ܳ��Ч��
        DischargingEfficiency = 0.9; % ��ˮ���ܷŵ�Ч��
        Lifetime = 30; % ��ˮ����װ���������꣩
        DiscountRate = 0.05; % ������
    end

    methods
        function obj = PumpedStorageModel()
            % ���캯����ʼ��
        end

        function fluRevenue = calculateFluctuationRevenue(obj, windEnergy_1h, solarEnergy_1h)
            % ƽ�ַ����������������
            fluRevenue = sum(windEnergy_1h * obj.WindPrice + solarEnergy_1h * obj.SolarPrice); % ���� (Ԫ)
        end

        function tradingRevenue = calculateTradingRevenue(obj, tradingPower_HPS_1h)
            % ��ˮ����������Դ�Ľ����������
            tradingRevenue = sum(tradingPower_HPS_1h * obj.TradingPrice); % ���� (Ԫ)
        end

        function investCost = calculateInvestment(obj, storageCapacity_HPS)
            % ��ˮ���ܽ���ɱ�����
            investCost = obj.InvestCostRate * storageCapacity_HPS * ...
                         (obj.DiscountRate * (1 + obj.DiscountRate)^obj.Lifetime) / ...
                         ((1 + obj.DiscountRate)^obj.Lifetime - 1);
        end

        function opeCost = calculateOpeCost(obj, storageCapacity_HPS)
            % ��ˮ��������ά���ɱ�����
            opeCost = storageCapacity_HPS * obj.OpeCostRate; % ����ά�ɱ� (Ԫ)
        end

        function netBenefit = calculateNetBenefit(obj, windEnergy_1h, solarEnergy_1h, ...
                                                  tradingPower_HPS_1h, storageCapacity_HPS)
            % �ܾ�Ч�����
            fluRevenue = obj.calculateFluctuationRevenue(windEnergy_1h, solarEnergy_1h);
            tradingRevenue = obj.calculateTradingRevenue(tradingPower_HPS_1h);
            investCost = obj.calculateInvestment(storageCapacity_HPS);
            opeCost = obj.calculateOpeCost(storageCapacity_HPS);
            netBenefit = fluRevenue + tradingRevenue - investCost - opeCost;
        end
    end
end
