function output = smGetDVP(mx,my,m)

    % Set first byte to smGiveDVP.pyzero, indicating a message is not yet ready.
    m.Data(1) = double(0);

    % Set mx values
    m.Data(2) = double(-1);
    m.Data(3) = double(-1);
    m.Data(4) = double(-1);
    for n = 1:length(mx)
       m.Data(n+1) = double(mx(n));
    end

    % Set my values
    m.Data(5) = double(my);

    % Announce!
    m.Data(1) = double(1);

    % Wait until the first byte is set back to zero, 
    % indicating that a response is available.
    while (m.Data(1) == 1.0)
        pause(.0001); % wait 1ms
    end
    
    % Display the response.
    output = m.Data(2);
   
end