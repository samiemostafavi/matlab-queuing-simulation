function drop = updateDropDRL(backlog, dequeue_rate, queue_delay, reward, ml_model_address)
    
    coder.extrinsic('smCommDRL');
    coder.extrinsic('memmapfile');
   
    ml_add = char(nonzeros(ml_model_address))';
    %disp(ml_add);

    persistent predictor_file;
    if isempty(predictor_file)
        % initiate memory-maped file.
        ml_add = [ml_add,'sm_comm.dat'];
        predictor_file = memmapfile(ml_add, 'Writable', true, 'Format', 'double');
    end
    
    drop = 0.0;
    drop = smCommDRL(backlog, dequeue_rate, queue_delay, reward, predictor_file);

end

