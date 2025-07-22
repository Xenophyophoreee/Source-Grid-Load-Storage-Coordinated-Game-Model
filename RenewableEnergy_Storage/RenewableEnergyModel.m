%% ����Դ��Ч�����
classdef RenewableEnergyModel
    properties
        WindPrice = 0.5; % ��λ����۵�۸� (Ԫ/kWh)
        SolarPrice = 0.4; % ��λ����۵�۸� (Ԫ/kWh)
        SubsidyRate = 0.1; % ������������ (Ԫ/kWh)
        r = 0.05; % ������
        T_renewable_WT = 20; % ���װ���豸�������꣩
        T_renewable_PV = 30; % ���װ���豸�������꣩
        InvestCostRateWind = 8000; % ��絥λ��������ɱ� (Ԫ/kW)
        InvestCostRateSolar = 6000; % �����λ��������ɱ� (Ԫ/kW)
        OpeCostRateWind = 100; % �������ά������ (Ԫ/kW����)
        OpeCostRateSolar = 80; % �������ά������ (Ԫ/kW����)
        TradingCostRate = 0.05; % ���ܽ��׵�� (Ԫ/kWh)
    end
    
    methods
        function obj = RenewableEnergyModel() 
            % ���캯����ʼ��
        end

        function revenue = calculateSellRevenue(obj, windOutput, solarOutput, windCapacity, solarCapacity)
            % ����Դ�۵��������
            revenue = sum(windOutput* windCapacity * obj.WindPrice + solarOutput * solarCapacity * obj.SolarPrice) * (15/60); % ע�ⵥλת��
        end

        function subsidy = calculateSubsidy(obj, windOutput, solarOutput, windCapacity, solarCapacity)
            % ����Դ����������������
            subsidy = sum(windOutput* windCapacity * obj.SubsidyRate + solarOutput * solarCapacity * obj.SubsidyRate) * (15/60); % ע�ⵥλת��
        end

        function investCost = calculateInvestment(obj, windCapacity, solarCapacity)
            % ����Դ����Ͷ�ʼ���
            investCost = ((obj.r*((1+obj.r)^obj.T_renewable_WT))/(((1+obj.r)^obj.T_renewable_WT)-1)) * windCapacity * obj.InvestCostRateWind + ...
                         ((obj.r*((1+obj.r)^obj.T_renewable_PV))/(((1+obj.r)^obj.T_renewable_PV)-1)) * solarCapacity * obj.InvestCostRateSolar;
        end

        function opeCost = calculateOpeCost(obj, windCapacity, solarCapacity)
            % ����Դ������ά�ɱ�����
            opeCost = windCapacity * obj.OpeCostRateWind + ...
                      solarCapacity * obj.OpeCostRateSolar;
        end

        function tradingCost = calculateTradingCost(obj, tradingPower_NE)
            % ����Դ�봢�ܵĽ��׳ɱ�����
            tradingCost = sum(tradingPower_NE) * obj.TradingCostRate * (15/60); % ע�ⵥλת��
        end

        function netBenefit = calculateNetBenefit(obj, windOutput, solarOutput, ...
                                                  windCapacity, solarCapacity, tradingPower_NE)
            % ����Դ�ܾ�Ч�����
            revenue = obj.calculateSellRevenue(windOutput, solarOutput, windCapacity, solarCapacity);
            subsidy = obj.calculateSubsidy(windOutput, solarOutput, windCapacity, solarCapacity);
            investCost = obj.calculateInvestment(windCapacity, solarCapacity);
            opeCost = obj.calculateOpeCost(windCapacity, solarCapacity);
            tradingCost = obj.calculateTradingCost(tradingPower_NE);
            netBenefit = revenue + subsidy - investCost - opeCost - tradingCost;
        end
    end
end
