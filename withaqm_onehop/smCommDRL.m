function output = smCommDRL(backlog, dequeue_rate, queue_delay, reward, m)

    % Wait until the first byte is one,
    % indicating that an action is available.
    while (m.Data(1) == 0.0)
        pause(.0001); % wait 1ms
    end
    
    % save output
    output = m.Data(2);
    
    % Set first byte to one, indicating a message is not yet ready.
    m.Data(1) = double(1);

    % Set values
    m.Data(2) = double(backlog);
    m.Data(3) = double(dequeue_rate);
    m.Data(4) = double(queue_delay);
    m.Data(5) = double(reward);

    % Announce!
    m.Data(1) = double(0);
   
end