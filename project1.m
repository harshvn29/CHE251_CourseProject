% Basis: 10,000 kg/h dry coal
basis = 10000;

% wt % of coal
wt_C = 0.4810;
wt_H = 0.0310;
wt_S = 0.0060;
wt_N = 0.0140;
wt_O = 0.0856;
wt_Ash = 0.3824;

% Molar Masses
MM_C = 12.01;
MM_H = 1.01;  
MM_S = 32.06;
MM_N2 = 28.02;
MM_O2 = 32.00;
MM_H2O = 18.02;
MM_CO2 = 44.01;
MM_CaCO3 = 100.09;
MM_MEA = 61.08;

% Mass flow rate 
mass_C = basis * wt_C;
mass_H = basis * wt_H;
mass_S = basis * wt_S;
mass_N_coal = basis * wt_N;
mass_O_coal = basis * wt_O;
mass_Ash = basis * wt_Ash;

% Molar flow rate
mol_C = mass_C / MM_C;
mol_H = mass_H / MM_H;
mol_S = mass_S / MM_S;
mol_N2_coal = mass_N_coal / MM_N2; 
mol_O2_coal = mass_O_coal / MM_O2;

% Operating Parameters
excess_air_pct = 0.15; 
air_O2_mol_frac = 0.21;  
air_N2_mol_frac = 0.79;    
co2_capture_efficiency = 0.90;  

% Solvent Parameters 
lean_loading = 0.2; % mol CO2 / mol MEA
rich_loading = 0.5; 
mea_wt_pct = 0.30; 

% Energy Parameters 
reboiler_duty_specific = 3.5; 
steam_latent_heat = 2257;

fprintf('Coal Feed Basis: %.0f kg/h\n', basis);
fprintf('Molar Feed (C):    %.2f kmol/h\n', mol_C);
fprintf('Molar Feed (H):    %.2f kmol/h\n', mol_H);
fprintf('Molar Feed (S):    %.2f kmol/h\n', mol_S);
fprintf('Molar Feed (N2):   %.2f kmol/h\n', mol_N2_coal);
fprintf('Molar Feed (O2):   %.2f kmol/h\n', mol_O2_coal);
fprintf('Mass Feed (Ash):   %.2f kg/h\n\n', mass_Ash);

%% STOICHIOMETRIC AIR 

% O2 required for combustion (kmol/h)
% C + O2 -> CO2
O2_C = mol_C * 1 ;
% 2H2 + O2 -> 2H2O
O2_H = mol_H * 0.25;
% S + O2 -> SO2
O2_S = mol_S * 1;

% Total O2 Required (Gross)
O2_t = O2_C + O2_H + O2_S;

% Net O2 from Air (Theoretical)
% Subtract O2 already present in the coal
O2_th = O2_t - mol_O2_coal;

fprintf('Theoretical O2 Required from Air: %.2f kmol/h\n\n', O2_th);

%% Stoichiometric Case (0% Excess Air)
air_theoretical = O2_th / air_O2_mol_frac;
N2_theoretical = air_theoretical * air_N2_mol_frac;
flue_gas_stoic.CO2 = mol_C;
flue_gas_stoic.H2O = mol_H / 2;
flue_gas_stoic.SO2 = mol_S;
flue_gas_stoic.N2 = N2_theoretical + mol_N2_coal ;
flue_gas_stoic.Total = flue_gas_stoic.CO2 +  flue_gas_stoic.H2O + flue_gas_stoic.SO2 +flue_gas_stoic.N2;
fprintf('Stoichiometric Flue Gas Flow: %.2f kmol/h\n\n', flue_gas_stoic.Total);

%% 15%% EXCESS AIR & FLUE GAS 

% Actual Air Supplied
O2_supplied = O2_th * (1 + 0.15);
N2_supplied = O2_supplied * 79/21;
Excess_O2 = O2_th * 0.15;

fprintf('Actual O2 Supplied:    %.2f kmol/h\n', O2_supplied);
fprintf('Actual N2 Supplied:    %.2f kmol/h\n', N2_supplied);
fprintf('Unreacted (Excess) O2: %.2f kmol/h\n\n', Excess_O2);

% Raw Flue Gas Composition (Post-Combustion)
% Products from combustion reactions:
mol_CO2_comb = mol_C;
mol_H2O_comb = mol_H / 2;
mol_SO2_comb = mol_S;
mol_N2_total = N2_supplied + mol_N2_coal;
mol_O2_total_out = Excess_O2;
% and Ash which is mass_Ash

fprintf('Raw Flue Gas (pre-FGD) \n');
fprintf('CO2 Flow:   %.2f kmol/h\n', mol_CO2_comb);
fprintf('H2O Flow:   %.2f kmol/h\n', mol_H2O_comb);
fprintf('SO2 Flow:   %.2f kmol/h\n', mol_SO2_comb);
fprintf('N2 Flow:    %.2f kmol/h\n', mol_N2_total);
fprintf('O2 Flow:    %.2f kmol/h\n', mol_O2_total_out);
fprintf('Ash flow:   %.2f kg/h\n', mass_Ash);

total_flue_gas = mol_CO2_comb + mol_H2O_comb + mol_SO2_comb + mol_N2_total + mol_O2_total_out;
fprintf('Total Gas Flow: %.2f kmol/h\n\n', total_flue_gas);
%% Dimensioning of Absorber ( Height of Packing Column & Diameter )
% Column sizing and HTU/NTU calculation (MATLAB)

% Given inputs
nC = mol_C;           % moles of carbon combusted
nCO2 = nC;             
n_flue = total_flue_gas; %dry flue gas CO2+H2O+N2+O2
T_C = 50;              
T = T_C + 273.15;      
R = 8.314;             
P = 101325;           
Uop = 1.0;             % operating gas velocity
MW_avg_flue = 30e-3;   % 30 g/mol average molecular weight
as = 250;              % specific interfacial area
L = 3.57;              % liquid flux 
% composition for NTU
y1 = 0.1553;           %concentration of CO2 in flue gas before mass transfer
%  90% capture effieciency
y2 = 0.0155;           %concentration of CO2 in flue gas after mass transfer

% 1) Volumetric flow rate of dry flue gas
Vdot_flue = n_flue .* R .* T ./ (P .* 3600);  
fprintf('Volumetric flow Vdot_flue = %.4f m^3/s\n', Vdot_flue);

% 2) Column cross-section and diameter
Ac = Vdot_flue ./ Uop;                         
Dc = sqrt(4*Ac/pi);                            
fprintf('Column area Ac = %.4f m^2\n', Ac);
fprintf('Column diameter Dc = %.4f m\n', Dc);

% 3) Mass and molar fluxes
mass_flow = n_flue .* MW_avg_flue ./ 3600;     
G = mass_flow ./ Ac;                           
Gm = (n_flue ./ 3600) ./ Ac;                   
fprintf('Mass flow = %.4f kg/s\n', mass_flow);
fprintf('Mass flux G = %.4f kg/(m^2 s)\n', G);
fprintf('Molar flux Gm = %.4f mol/(m^2 s)\n', Gm);

% 4) NTU (fast reaction, y* negligible)
NTU = log(y1 / y2);
fprintf('NTU = ln(y1/y2) = %.6f\n', NTU);

% 5) Overall mass-transfer coefficient (empirical)
% Empirical form: KGa = C * G^0.7 * L^0.2 * as
% We choose to solve for C so that KGa matches the approximate 0.0299 s^-1
KGa_target = 0.0299;    
C = KGa_target ./ (G.^0.7 .* L.^0.2 .* as);
KGa = C .* G.^0.7 .* L.^0.2 .* as;  % should equal KGa_target
fprintf('Solved empirical constant C = %.5e\n', C);
fprintf('KGa (calculated) = %.5f s^-1\n', KGa);

% 6) Height of a transfer unit (HTU) and total height Z
%  HTU = Gm / (KGa * Pt) with Pt ~ 101.3 
Pt = 101.3;   % numeric factor
HTU = Gm ./ (KGa .* Pt);   
Z = NTU .* HTU;
fprintf('HTU = %.4f m\n', HTU);
fprintf('Column height Z = NTU * HTU = %.4f m\n', Z);

% Print a summary table
%fprintf('Vdot_flue = %.4f m^3/s\n', Vdot_flue);
fprintf('\nResults:-\nAc = %.4f m^2, Dc = %.4f m\n', Ac, Dc);
%fprintf('Mass flux G = %.4f kg/(m^2 s)\nMolar flux Gm = %.4f mol/(m^2 s)\n', G, Gm);
%fprintf('KGa = %.5f s^-1 (using C = %.5e)\n', KGa, C);
fprintf('HTU = %.4f m, NTU = %.6f\nZ = %.4f m\n', HTU, NTU, Z);


%% FGD (SCRUBBER) BALANCE 

fgd_efficiency = 0.95;

% Ash and SO2 Removed
% CaCO3 + SO2 -> CaSO3 + CO2
SO2_removed = mol_SO2_comb * fgd_efficiency;
SO2_remaining = mol_SO2_comb * (1 - fgd_efficiency);

% Limestone required
CaCO3_required_mol = SO2_removed;
CaCO3_required_mass = CaCO3_required_mol * MM_CaCO3;
fprintf('\nLimestone (CaCO3) Required: %.2f kg/h\n', CaCO3_required_mass);

% Gas composition change
% SO2 removed,CO2 is added in stoichiometric ratio
CO2_from_FGD = SO2_removed;
CO2_to_absorber = mol_CO2_comb + CO2_from_FGD;

% Final Gas to Absorber (FG-ASH-SO2)
gas_in_absorber.CO2 = CO2_to_absorber;
gas_in_absorber.H2O = mol_H2O_comb;
gas_in_absorber.SO2 = SO2_remaining;
gas_in_absorber.N2 = mol_N2_total;
gas_in_absorber.O2 = mol_O2_total_out;
gas_in_absorber.Total = gas_in_absorber.CO2 + gas_in_absorber.H2O + gas_in_absorber.SO2 + gas_in_absorber.N2 +gas_in_absorber.O2 ; 

fprintf('\nGas to Absorber (FG-ASH-SO2)\n');
fprintf('CO2: %.2f kmol/h \n', gas_in_absorber.CO2);
fprintf('H2O: %.2f kmol/h \n', gas_in_absorber.H2O);
fprintf('SO2: %.3f kmol/h \n', gas_in_absorber.SO2);
fprintf('N2:  %.2f kmol/h \n', gas_in_absorber.N2);
fprintf('O2:  %.2f kmol/h \n', gas_in_absorber.O2);
fprintf('Total Flow: %.2f kmol/h\n\n', gas_in_absorber.Total);

%% SOLVENT CIRCULATION CALCULATION
fprintf('Calculating Solvent Circulation\n');

% CO2 to be captured
CO2_captured_molar = gas_in_absorber.CO2 * co2_capture_efficiency;
CO2_captured_mass = CO2_captured_molar * MM_CO2;
fprintf('CO2 Captured: %.2f kmol/h (%.2f kg/h)\n', CO2_captured_molar, CO2_captured_mass);

% Solvent working capacity
working_capacity = rich_loading - lean_loading; % mol CO2 / mol MEA 

% Molar flow of MEA
MEA_molar_flow = CO2_captured_molar / working_capacity;
fprintf('Required MEA Molar Flow: %.2f kmol/h\n', MEA_molar_flow);

% Total solvent mass flow (30 wt% solution)
MEA_mass_flow = MEA_molar_flow * MM_MEA;
Total_Solvent_mass_flow = MEA_mass_flow / mea_wt_pct;
fprintf('Total Solvent Circulation Rate (30%% MEA): %.2f kg/h\n\n', Total_Solvent_mass_flow);


%% REBOILER DUTY CALCULATION
fprintf('Calculating Reboiler Duty\n');

% Total Energy Duty
Total_Reboiler_Duty_MJ_h = CO2_captured_mass * reboiler_duty_specific;
Total_Reboiler_Duty_MW = Total_Reboiler_Duty_MJ_h / 3600; % MJ/h -> MJ/s -> MW

fprintf('Total Reboiler Duty: %.2f MJ/h (%.2f MW)\n', ...
    Total_Reboiler_Duty_MJ_h, Total_Reboiler_Duty_MW);

% Steam Required
Steam_required_kg_h = Total_Reboiler_Duty_MJ_h / (steam_latent_heat / 1000); % Convert kJ to MJ
fprintf('Steam Required (at %.0f kJ/kg): %.2f kg/h\n', ...
    steam_latent_heat, Steam_required_kg_h);
