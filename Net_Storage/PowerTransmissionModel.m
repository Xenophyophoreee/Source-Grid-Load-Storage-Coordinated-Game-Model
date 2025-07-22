%% �����豸��Ч�����
classdef PowerTransmissionModel
      
    properties
        r = 0.05; % ������
        Tl = 20; % �豸ʹ���������꣩
        c_l1 = 3000 % �½�
        c_l2 = 1000 % ��������
        et_GL_sell = 0.5; % tʱ�ε�����λ�۵���(Ԫ/kWh)
        et_GL_buy =  0.4; % tʱ�ε�����λ������(Ԫ/kWh)
    end
    
    methods
        function obj = PowerTransmissionModel()
            % ���캯����ʼ��
        end
        
        function investCost = calculateInvest(obj, N_l1, N_l2)
            % (1)�����豸Ͷ�ʳɱ�
            investCost = (obj.r * (1 + obj.r)^obj.Tl) / ((1 + obj.r)^obj.Tl - 1) * (obj.c_l1 * N_l1 + obj.c_l2 * N_l2);
        end
        
        function lossCost = calculateloss(obj, Pt_GL_loss)
            % (2)������ĳɱ�
            lossCost = sum(Pt_GL_loss .* obj.et_GL_sell) * (15/60);
        end
        
        function purchaseCost = calculatePurchase(obj, Pt_GL_buy_up, Pt_GL_buy_grid)
            % (3)��������ɱ���������ϼ������ͱ�������������ͬ��
            C_GL_buy_up = sum(Pt_GL_buy_up .* obj.et_GL_buy) * (15/60);
            C_GL_buy_grid = sum(Pt_GL_buy_grid .* obj.et_GL_buy) * (15/60);
            purchaseCost =C_GL_buy_up + C_GL_buy_grid;
        end
        
        function revenue = calculateRevenue(obj, Pt_GL_sell)
            % (4)�����۵�����
            revenue = sum(Pt_GL_sell .* obj.et_GL_sell) * (15/60);
        end
       
        function gridNetBenefit = calculateGridNetBenefit(obj, N_l1, N_l2, ...
                                                            Pt_GL_loss, Pt_GL_buy_up, Pt_GL_buy_grid, Pt_GL_sell)
            % �����豸�ܾ�Ч�����
            investCost = obj.calculateInvest(N_l1, N_l2);
            lossCost = obj.calculateloss(Pt_GL_loss);
            purchaseCost = obj.calculatePurchase(Pt_GL_buy_up, Pt_GL_buy_grid);
            revenue = obj.calculateRevenue(Pt_GL_sell);
            gridNetBenefit = revenue - investCost - lossCost - purchaseCost;
        end
        
    end
end

