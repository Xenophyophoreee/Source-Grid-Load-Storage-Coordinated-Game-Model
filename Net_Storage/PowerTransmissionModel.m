%% 输变电设备净效益计算
classdef PowerTransmissionModel
      
    properties
        r = 0.05; % 贴现率
        Tl = 20; % 设备使用寿命（年）
        c_l1 = 3000 % 新建
        c_l2 = 1000 % 升级改造
        et_GL_sell = 0.5; % t时段电网单位售电电价(元/kWh)
        et_GL_buy =  0.4; % t时段电网单位购电电价(元/kWh)
    end
    
    methods
        function obj = PowerTransmissionModel()
            % 构造函数初始化
        end
        
        function investCost = calculateInvest(obj, N_l1, N_l2)
            % (1)输变电设备投资成本
            investCost = (obj.r * (1 + obj.r)^obj.Tl) / ((1 + obj.r)^obj.Tl - 1) * (obj.c_l1 * N_l1 + obj.c_l2 * N_l2);
        end
        
        function lossCost = calculateloss(obj, Pt_GL_loss)
            % (2)网络损耗成本
            lossCost = sum(Pt_GL_loss .* obj.et_GL_sell) * (15/60);
        end
        
        function purchaseCost = calculatePurchase(obj, Pt_GL_buy_up, Pt_GL_buy_grid)
            % (3)电网购电成本（假设从上级电网和本级电网买电价相同）
            C_GL_buy_up = sum(Pt_GL_buy_up .* obj.et_GL_buy) * (15/60);
            C_GL_buy_grid = sum(Pt_GL_buy_grid .* obj.et_GL_buy) * (15/60);
            purchaseCost =C_GL_buy_up + C_GL_buy_grid;
        end
        
        function revenue = calculateRevenue(obj, Pt_GL_sell)
            % (4)电网售电收益
            revenue = sum(Pt_GL_sell .* obj.et_GL_sell) * (15/60);
        end
       
        function gridNetBenefit = calculateGridNetBenefit(obj, N_l1, N_l2, ...
                                                            Pt_GL_loss, Pt_GL_buy_up, Pt_GL_buy_grid, Pt_GL_sell)
            % 输变电设备总净效益计算
            investCost = obj.calculateInvest(N_l1, N_l2);
            lossCost = obj.calculateloss(Pt_GL_loss);
            purchaseCost = obj.calculatePurchase(Pt_GL_buy_up, Pt_GL_buy_grid);
            revenue = obj.calculateRevenue(Pt_GL_sell);
            gridNetBenefit = revenue - investCost - lossCost - purchaseCost;
        end
        
    end
end

