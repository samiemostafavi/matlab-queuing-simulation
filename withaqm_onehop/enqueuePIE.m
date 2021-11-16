function drop = enqueuePIE(drop_prob,qdelay_old,queue_length,MEAN_PKTSIZE,QDELAY_REF,randomseed)

    % Random Dropping 
    
    persistent randSeed;
    if isempty(randSeed)
        rng(97531+randomseed);
        randSeed = randomseed;
    else
        if (randSeed ~= randomseed)
            rng(97531+randomseed);
            randSeed = randomseed;
        end
    end
    
    drop = 1;
	% Safeguard PIE to be work conserving
    if ( ( (qdelay_old < QDELAY_REF/2) && (drop_prob < 0.2) ) || (queue_length <= 2*MEAN_PKTSIZE) )
         drop = 0;
    else
         % randomly drop the packet with a probability of drop_prob_
         % FIX_ME: does rand use randSeed?
         if ( rand(1) < drop_prob )
            drop = 1;
         end
    end


end

