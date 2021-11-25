%% Prep the queues

% format shortG
restoredefaultpath

clear all;
close all;

SIM_NUM = '1';
NUM_WORKERS = 1;
initial_transient_proportion = 0; % percentage

sim_name = 'withaqm_onehop';
sim_vars = [ 0, 0.9  ...                % (1)  arrivalfunction          (2)  arrivalrate  
             8, 1, ...                  % (3)  servicefunction_uplink   (4)  servicerate_uplink
             8, 1, ...                  % (5)  servicefunction_compute  (6)  servicerate_compute
             8, 1, ...                  % (7)  servicefunction_downlink (8)  servicerate_downlink
             inf, inf, inf  ...         % (9)  queuecapacity_uplink     (10) queuecapacity_compute  (11) queuecapacity_downlink
             rand(1,1)*100000 ...       % (12) randomseed_offset
           ];

% AQM numbers:
% NoAQM=0, PIE=1, CoDel=2, Delta=3, DRL=4
aqm_params = [ 3, 0, 0 ...                              % GENERAL:  (1)  enabled_aqm_uplink     (2)  enabled_aqm_compute    (3)  enabled_aqm_downlink                         
               1, 1, 3, 15/40, (1 + 1/4)*15+15/800 ...  % UPLINK:   (4)  PIE QDELAY_REF         (5)  PIE MEAN_PKTSIZE       (6)  PIE T_UPDATE          (7) PIE ALPHA  (8) PIE BETA 
               2/3, 2 ...                               %           (9)  CODEL TARGET_DELAY     (10) CODEL INTERVAL
               100, 10 ...                              %           (11) DELTA QUEUE TABLE SIZE (12) DELTA TARGET_DELAY
               10, 0.05, 1 ...                          %           (13) DELAY_REF              (14) SCALE_FACTOR           (15) T_UPDATE                             
             ];                       

%sm_address = '../../conditional-latency-probability-prodiction/'; % address_name emm_1hop_model_30k_norm_cl, emm_1hop_model_5k_cl
sm_address = '/Users/ssmos/Desktop/time-sensitive-aqm/conditional-latency-probability-prodiction/';
%sm_address = '/Users/ssmos/Desktop/drl-aqm/';
         
%% Dataset Generation

tic

stop_time = '300000'; %'50000',ml2,arrival 0.8 -> 292 sec, not that accurate DELTA: '300000' one thread, took 3110 seconds

numSims = 1;
simIn(1:numSims) = Simulink.SimulationInput(sim_name);
seedsOffsets = floor(rand(numSims,1)*100000);
for idx = 1:numSims
    sim_vars(12) = seedsOffsets(idx);
    simIn(idx) = simIn(idx).setVariable('sim_vars', sim_vars);
    simIn(idx) = simIn(idx).setVariable('aqm_params', aqm_params);
    simIn(idx) = simIn(idx).setVariable('sm_address', sm_address);
    simIn(idx) = simIn(idx).setModelParameter('StopTime',stop_time);
end
toc

tic
warning off;

%delete(gcp('nocreate'))         % shutdown the parallel pool
%parpool('local',NUM_WORKERS);   % start a new one

% Simulate the model
simOut = sim(simIn);
%simOut = parsim(simIn,'UseFastRestart','on'); % ,'ShowProgress', 'on', 'ShowSimulationManager','on'
recordsTable = table;
for n = 1:numSims
    recordsTable = [recordsTable; logs2table(simOut(n).logsout,initial_transient_proportion)];
end
toc

%clear 'simIn' 'simOut' 'idx' 'n';

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

