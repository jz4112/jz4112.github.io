function brisque()
dir_name = '~/ImageDataset2/';
im_type = '.jpg';
        
NUM_IMAGES = 2238;
time_elapsed = ones(1, NUM_IMAGES);
for i = 1:NUM_IMAGES
    for j = 10:10:100
         if (j == 100)
             img_name = [int2str(i) im_type];
         else
             img_name = [int2str(i) '_' int2str(j) im_type];
         end
        try
             path = strcat(dir_name, img_name);
             imdist = imread(path);
             if (j==100)
                f = @() brisque_feature(imdist);
                time_elapsed(i) = timeit(f);
             end
             feat = brisque_feature(imdist);
             printToFile(img_name, feat);
        catch exception
             disp('cannot read image: ');
             img_name
             continue;
        end
    end
end
histogram(time_elapsed);


%---------------------------------------------------------------------
%Quality Score Computation
%---------------------------------------------------------------------

% 
% fid = fopen('test_ind','w');
% 
% for jj = 1:size(feat,1)
%     
% fprintf(fid,'1 ');
% for kk = 1:size(feat,2)
% fprintf(fid,'%d:%f ',kk,feat(jj,kk));
% end
% fprintf(fid,'\n');
% end
% 
% fclose(fid);
% warning off all
% delete output test_ind_scaled dump
% system('svm-scale -r allrange test_ind >> test_ind_scaled');
% system('svm-predict -b 1 test_ind_scaled allmodel output >>dump');
% 
% load output
% qualityscore = output;



function printToFile(img_name, f)
%% print to file
fileID = fopen('~/Brisque_features.txt', 'at');
fprintf(fileID, '%s: ', img_name);
fprintf(fileID, '%.4f ', f);
fprintf(fileID, '\n');
fclose(fileID);