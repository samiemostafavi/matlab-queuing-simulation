%% Prep the queues

% format shortG
restoredefaultpath

clear all;
close all;

SIM_NUM = '1';
NUM_WORKERS = 1;
initial_transient_proportion = 0.1; % percentage

sim_name = 'withaqm_onehop';
sim_vars = [ 0, 0.9  ...                % (1)  arrivalfunction          (2)  arrivalrate  
             8, 1, ...                  % (3)  servicefunction_uplink   (4)  servicerate_uplink
             8, 1, ...                  % (5)  servicefunction_compute  (6)  servicerate_compute
             8, 1, ...                  % (7)  servicefunction_downlink (8)  servicerate_downlink
             inf, inf, inf  ...         % (9)  queuecapacity_uplink     (10) queuecapacity_compute  (11) queuecapacity_downlink
             rand(1,1)*100000 ...       % (12) randomseed_offset
           ];

% AQM numbers:
% NoAQM=0, PIE=1, CoDel=2, Delta=3
aqm_params = [ 1, 0, 0 ...                              % GENERAL:  (1)  enabled_aqm_uplink     (2)  enabled_aqm_compute    (3)  enabled_aqm_downlink                         
               1, 1, 3, 15/40, (1 + 1/4)*15+15/800 ...  % UPLINK:   (4)  PIE QDELAY_REF         (5)  PIE MEAN_PKTSIZE       (6)  PIE T_UPDATE          (7) PIE ALPHA  (8) PIE BETA 
               2/3, 2 ...                               %           (9)  CODEL DELAY_TARGET     (10) CODEL INTERVAL
               100 ...                                  %           (11) DELTA QUEUE TABLE SIZE
             ];                       

ml_model_config = [int32(10000), int32(3), int32(16), ... % n_epoch, n_centers, hidden_layer_n
                      int32(1), int32(1), int32(4), int32(-5)]; % ndim_x,  is_emm, learning_rate_p1, learning_rate_p2

ml_model_address = '/Users/ssmos/Desktop/Research Project/Density Estimation/CDE_virtualenv/Conditional_Density_Estimation/'; % address_name emm_1hop_model_30k_norm_cl, emm_1hop_model_5k_cl

         
%% Dataset Generation

tic

stop_time = '50000'; %'50000',ml2,arrival 0.8 -> 292 sec, not that accurate

numSims = 1;
simIn(1:numSims) = Simulink.SimulationInput(sim_name);
seedsOffsets = floor(rand(numSims,1)*100000);
for idx = 1:numSims
    sim_vars(12) = seedsOffsets(idx);
    simIn(idx) = simIn(idx).setVariable('sim_vars', sim_vars);
    simIn(idx) = simIn(idx).setVariable('aqm_params', aqm_params);
    simIn(idx) = simIn(idx).setVariable('ml_model_config', ml_model_config);
    simIn(idx) = simIn(idx).setVariable('ml_model_address', ml_model_address);
    simIn(idx) = simIn(idx).setModelParameter('StopTime',stop_time); 
end
toc

tic
warning off;

delete(gcp('nocreate'))         % shutdown the parallel pool
parpool('local',NUM_WORKERS);   % start a new one

% Simulate the model
simOut = parsim(simIn,'UseFastRestart','on'); % ,'ShowProgress', 'on', 'ShowSimulationManager','on'
recordsTable = table;
for n = 1:numSims
    recordsTable = [recordsTable; logs2table(simOut(n).logsout,initial_transient_proportion)];
end
toc

clear 'simIn' 'simOut' 'idx' 'n';

%% Save all usefull data to 2 files: a .mat and a .parquet

% create the folder if does not exist
if not(isfolder('saves/'))
    mkdir('saves/');
end

clk_str = strrep(strrep(strrep(datestr(clock),' ','_'),':','_'),'-','_');
filename_meta = 'sim3hop_'+sprintf("%s",SIM_NUM)+'_metadata'+'_'+clk_str;
filename_dataset = 'sim3hop_'+sprintf("%s",SIM_NUM)+'_dataset'+'_'+clk_str;

save('saves/'+filename_meta+'.mat','sim_name','sim_vars','aqm_params','stop_time','initial_transient_proportion',  ...
            'numSims','SIM_NUM','NUM_WORKERS','clk_str','seedsOffsets');
        
parquetwrite('saves/'+filename_dataset+'.parquet',recordsTable);

