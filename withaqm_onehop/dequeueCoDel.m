function drop = dequeueCoDel(sojourn_time,now,INTERVAL,TARGET)
    % here sojourn_time means queueing delay

    persistent dropping_;
    persistent drop_next_;
    persistent count_;
    persistent lastcount_;
    
    if isempty(dropping_)
        dropping_= false;
        drop_next_= 0;
        count_= 0;
        lastcount_= 0;
    end

    % do not drop: 0, drop: 1
    drop = 0;
    
    ok_to_drop = dequeueCoDelInternal(sojourn_time,now,INTERVAL,TARGET);
    
    if (dropping_)
        if (~ ok_to_drop)
            % sojourn time below TARGET - leave drop state
            dropping_ = false;
        else
        
            % Time for the next drop.  Drop current packet and dequeue
            % next.  If the dequeue doesn't take us out of dropping
            % state, schedule the next drop.
            if (now >= drop_next_ && dropping_)
                drop = 1; % drop
                count_ = count_+1;
                % schedule the next drop.
                drop_next_ = controllawCoDel(drop_next_, count_,INTERVAL);
            end
            
        end
    % If we get here, we're not in drop state.  The 'ok_to_drop'
    % return from dodequeue means that the sojourn time has been
    % above 'TARGET' for 'INTERVAL', so enter drop state.
    elseif (ok_to_drop)
        drop = 1; % drop
        dropping_ = true;

        % If min went above TARGET close to when it last went
        % below, assume that the drop rate that controlled the
        % queue on the last cycle is a good starting point to
        % control it now.  ('drop_next' will be at most 'INTERVAL'
        % later than the time of the last drop, so 'now - drop_next'
        % is a good approximation of the time from the last drop
        % until now.) Implementations vary slightly here; this is
        % the Linux version, which is more widely deployed and
        % tested.
        delta = count_ - lastcount_;
        count_ = 1;
        if ((delta > 1) && (now - drop_next_ < 16*INTERVAL))
            count_ = delta;
        end
        
        drop_next_ = controllawCoDel(now, count_,INTERVAL);
        lastcount_ = count_;
    end

end

function ok_to_drop = dequeueCoDelInternal(sojourn_time,now,INTERVAL,TARGET)

    persistent first_above_time_;

    if isempty(first_above_time_)
        first_above_time_ = 0;
    end
    
    ok_to_drop = false;

    % interval is finished
    if (sojourn_time < TARGET)
        % went below - stay below for at least INTERVAL
        first_above_time_ = 0;
    else
        if (first_above_time_ == 0)
            % just went above from below. if still above at
            % first_above_time, will say it's ok to drop.
            first_above_time_ = now + INTERVAL;
        elseif (now >= first_above_time_)
            ok_to_drop = true;
        end
    end

end

function drop_next = controllawCoDel(time, count, INTERVAL)
    drop_next = time + INTERVAL/sqrt(count);
end



