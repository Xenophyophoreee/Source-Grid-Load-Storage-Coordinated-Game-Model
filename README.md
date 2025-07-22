# Source-Grid-Load-Storage-Coordinated-Game-Model
## Project profile
This project constructs a coordinated game model among the four entities: source, grid, load, and storage, decomposed into source–storage game, grid–storage game, and load–storage game, and employs cooperative game theory for evolutionary game dynamics.

该项目构建了源网荷储四方的协同博弈模型，分为源储博弈模型、网储博弈模型、荷储博弈模型，并采用合作博弈方式进行博弈演化。
## Project structure description
project-root

├── Load_Storage/  # load–storage game

│   └──FlexibleLoadModel.m/  # Net Benefit Calculation of Flexible Load Demand Response

│   └──LoadSideElectrochemicalStorageModel.m/  # Net Benefit Calculation of Electrochemical Energy Storage on the Load Side

│   └──LoadSideHydrogenStorageModel.m/  # Construction Cost Calculation of Hydrogen Energy Storage on the Load Side

│   └──LoadSidePumpedStorageModel.m/  # Construction Cost Calculation of Pumped Hydro Storage on the Load Side

│   └──loadsidetest.m/  # Load Testing Function

│   └──main.m/  # Main Program for Multi-Agent Evolutionary Game

├── Net_Storage/  # grid–storage game

│   └──E_GL.mat/  # Power Grid Related Data

│   └──ElectrochemicalStorageModel.m/  # Net Benefit Calculation of Electrochemical Energy Storage on the Grid Side

│   └──HydrogenStorageModel.m/  # Net Benefit Calculation of Hydrogen Energy Storage on the Grid Side

│   └──main.m/  # Main Program for Multi-Agent Evolutionary Game

│   └──PowerTransmissionModel.m/  # Net Benefit Calculation of Power Transmission and Transformation Equipment

│   └──PumpedStorageModel.m/  # Net Benefit Calculation of Pumped Hydro Storage on the Grid Side

│   └──test.m/  # Test Functions Can Be Ignored

│   └──test2.m/  # Test Functions Can Be Ignored

├── RenewableEnergy_Storage/  # source–storage game

│   └──ElectrochemicalStorageModel.m/  # Net Benefit Calculation of Electrochemical Energy Storage on the Renewable Energy Side

│   └──HydrogenStorageModel.m/  # Net Benefit Calculation of Hydrogen Energy Storage on the Renewable Energy Side

│   └──main.m/  # Main Program for Multi-Agent Evolutionary Game

│   └──PumpedStorageModel.m/  # Net Benefit Calculation of Pumped Hydro Storage on the Renewable Energy Side

│   └──RenewableEnergyModel.m/  # Net Benefit Calculation of Renewable Energy

│   └──test.m/  # Test Functions Can Be Ignored
## Project contributors
Xinyang Ji, Yumo Shi, Wenhao Gao
