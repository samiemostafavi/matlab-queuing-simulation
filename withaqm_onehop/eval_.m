
delay_ref = 10;
window_size = 1000;
data_arr = recordsTable.end2enddelay;
res_arr = [];
for i=0:floor(length(data_arr)/window_size)-1
    windowed_data = data_arr(i*window_size+1:(i+1)*window_size);
    res = [sum(windowed_data>delay_ref)/window_size;sum(~isfinite(windowed_data))/window_size];
    res_arr = [res_arr, res];
end

plot(res_arr(1,:))
hold on;
plot(res_arr(2,:))