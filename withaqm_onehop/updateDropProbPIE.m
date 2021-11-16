function [drop_prob,qdelay_old] = updateDropProbPIE(current_qdelay,alpha,beta,QDELAY_REF,T_UPDATE,current_time)

    % Drop Probability Calculation

    persistent qdelay_old_;
    persistent drop_prob_;
    persistent t1;
    t2 = current_time;
    
    if isempty(qdelay_old_)
        qdelay_old_ = current_qdelay;
        drop_prob_ = 0;
        t1 = current_time;
    end
   
    %the PIE algorithm periodically adjusts the drop probability every T_UPDATE interval
    if (t2-t1)>T_UPDATE 
        % calculate drop probability drop_prob_, and autotune it as follows:
        p = alpha*(current_qdelay - QDELAY_REF) + beta*(current_qdelay - qdelay_old_);
        if (drop_prob_ < 0.000001)
                 p = p/2048;
        elseif (drop_prob_ < 0.00001)
                 p = p/512;
        elseif (drop_prob_ < 0.0001)
                 p = p/128;
        elseif (drop_prob_ < 0.001)
                 p = p/32;
        elseif (drop_prob_ < 0.01)
                 p = p/8;
        elseif (drop_prob_ < 0.1)
                 p = p/2;
        else
                 p = p;
        end
             drop_prob_ = drop_prob_ + p;

        % decay the drop probability exponentially:
        if (current_qdelay == 0 && qdelay_old_ == 0)
            drop_prob_ = drop_prob_ * 0.98; % 1 - 1/64 is sufficient
        end

        % bound the drop probability:
        if (drop_prob_ < 0)
            drop_prob_ = 0.0;
        end
        if (drop_prob_ > 1)
            drop_prob_ = 1.0;
        end
        
        % store the current latency value:
        qdelay_old_ = current_qdelay;
        
        % reset the timer
        t1 = current_time;
    end
    
    qdelay_old = qdelay_old_;
    drop_prob = drop_prob_;

end

