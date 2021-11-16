function drop = dequeueDelta(qtable,ml_model_address,id)
    
    coder.extrinsic('smGetDVP');
    coder.extrinsic('memmapfile');
   
    ml_add = char(nonzeros(ml_model_address))';
    %disp(ml_add);

    persistent predictor_file;
    if isempty(predictor_file)
        % initiate memory-maped file.
        ml_add = [ml_add,'sm_dvp_',sprintf('%d',int32(id)),'.dat'];
        predictor_file = memmapfile(ml_add, 'Writable', true, 'Format', 'double');
    end
    
    nrow = sum(qtable(:,3)==1);
    
    % make the tables and calculate the sum_dvps
    %nrow is at least 1
    sum_dvps = [0.0,0.0];
    for i=0:1 % tables       
        % calc sum_dvp
        sum_dvp = 0.0;
        for j=1+i:nrow % calc dvp of each packet
            res = 0.0;
            state = j-1-i; % starts from 0 to nrow-1-i
            latency_budget = qtable(j,2);
            if latency_budget < 0.0
                res = 1.00;
            else
                res = smGetDVP(state,latency_budget,predictor_file); %ml_add
                if(~isfinite(res))
                    res = 1.00;
                end
            end
            sum_dvp = sum_dvp + res;
        end
        sum_dvp = sum_dvp + i; % add the dropped packet to sum_dvp   
        sum_dvps(i+1) = sum_dvp;
    end
    
    delta = sum_dvps(1) - sum_dvps(2);
    if delta >= 0 %
        drop = 1; % drop
    else
        drop = 0; % pass
    end
    
end

