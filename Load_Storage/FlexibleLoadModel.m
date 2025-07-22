%% 柔性负荷需求响应净效益计算
classdef FlexibleLoadModel
    properties
        % 需求响应补贴参数
        DRSubsidyPrice = 0.8;    % 需求响应单位补贴价格 (元/kWh)
        
        % 负荷成本参数
        CurtailmentPrice = 10;    % 可削减负荷单位成本 (元/kWh)
        TransferPrice = 5;       % 可转移负荷单位成本 (元/kWh)
    end
    
    methods
        function obj = FlexibleLoadModel()
            % 构造函数初始化
        end
        
        function DRrevenue = calculateDRRevenue(obj, curtailmentCapacity, curtailmentOutput)
            % 计算柔性负荷参与需求响应的收益
            % curtailmentCapacity: 可削减负荷容量
            % curtailmentOutput: 可削减负荷占比
            DRrevenue = sum(obj.DRSubsidyPrice .* curtailmentCapacity .* curtailmentOutput * (15/60));
        end
        
        function curtailmentCost = calculateCurtailmentCost(obj, curtailmentCapacity, curtailmentOutput)
            % 计算可削减负荷的成本
            % curtailmentCapacity: 可削减负荷容量
            % curtailmentOutput: 可削减负荷占比
            curtailmentCost = sum(obj.CurtailmentPrice .* curtailmentCapacity .* curtailmentOutput * (15/60));
        end
        
        function transferCost = calculateTransferCost(obj, transferCapacity, transferOutput)
            % 计算可转移负荷的成本
            % transferCapacity: 可转移负荷容量 
            % transferOutput: 可转移负荷占比
            transferCost = sum(obj.TransferPrice .* transferCapacity .* transferOutput * (15/60));
        end
        
        function netBenefit = calculateNetBenefit(obj, curtailmentCapacity, curtailmentOutput, transferCapacity, transferOutput)
            % 计算柔性负荷需求响应的净效益
            DRrevenue = obj.calculateDRRevenue(curtailmentCapacity, curtailmentOutput);
            curtailmentCost = obj.calculateCurtailmentCost(curtailmentCapacity, curtailmentOutput);
            transferCost = obj.calculateTransferCost(transferCapacity, transferOutput);
            
            netBenefit = DRrevenue - curtailmentCost - transferCost;
        end
    end
end