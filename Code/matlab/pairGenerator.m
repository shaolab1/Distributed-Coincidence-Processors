%% Scanner parameters
detectors = 32; % Detector number, 0 -- detectors-1
det_gap = 2; % Avoid generating coincidence pairs within two adjecant detectors 
total_pairs = detectors * (detectors-1-2*det_gap) / 2
%% Pair Generation
fid = fopen('dcpPair_16Detectors.sv','w');
fwrite(fid, ['parameter int PAIR_NUM = ' num2str(total_pairs) ';' newline 'parameter int COINCIDENCE_PAIR_MAT[PAIR_NUM][2] = ''{']);
%%
pairs_num = [];
for ii = 0:detectors-1
    pairs_str = [];
    for jj = 0:detectors-1
        if abs(ii-jj) <= det_gap || abs(ii-jj) >= detectors - det_gap || jj < ii % avoid adjecant 2 detectors and repeated pairs
            continue
        end
        pairs_num = [pairs_num [ii; jj]];
        pairs_str = [pairs_str [char(39), '{', num2str(ii), ',', num2str(jj), '},']];
    end
    fwrite(fid,[pairs_str newline]);
end
fwrite(fid, '};');
fclose all;
%% Channel Delay matrix gen
%chan_delay = []; % Relative physical channel skews. Rounded. Substract the least channel delay     
chan_delay = round(rand(1,detectors)*5) % Random delay for test
%%
fid = fopen('delayMat_32Detectors.sv','w');
fwrite(fid, ['parameter int DELAY_PAIR = ' num2str(total_pairs) ';' newline 'parameter int CHAN_DELAY_MAT[PAIR_NUM][2] = ''{']);
%%
delay_pair = [];
for ii = 1:detectors
    pairs_str = [];
    for jj = 1:detectors
        if abs(ii-jj) <= det_gap || abs(ii-jj) >= detectors - det_gap || jj < ii % avoid adjecant 2 detectors and repeated pairs
            continue
        end
        delay_pair = [delay_pair [chan_delay(ii); chan_delay(jj)]];
        pairs_str = [pairs_str [char(39), '{', num2str(chan_delay(ii)), ',', num2str(chan_delay(jj)), '},']];
    end
    fwrite(fid,[pairs_str newline]);
end
fwrite(fid, '};');
fclose all;