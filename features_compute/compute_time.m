function runtime = compute_time()
warning off
% trainingFiles = dir('~/temp2');
% runtime_brisque = cell(length(trainingFiles)-3,1);
% runtime_diivine = runtime_brisque;
% for fileIndex = 4:length(trainingFiles) %the first three are . , .. and .DS_Store
%         currentFileName = ['~/temp2/' trainingFiles(fileIndex).name];
%         image = rgb2gray(imread(currentFileName));
% %         b_time = brisque_feature(image);
% %         runtime_brisque{fileIndex-3} = b_time;
%         d_time = divine_feature_extract(image);
%         runtime_diivine{fileIndex-3} = d_time;
% end
% 
% save('runtime_diivine.mat', 'runtime_diivine');

diiv = load('~/mat NR runtime/runtime_diivine.mat');
diiv = diiv.runtime_diivine;

time = zeros(1, 6);
for i = 1 : 50
   time = time + diiv{i};
end
% total number of pics = 50
runtime = time./50;

save('~/mat NR runtime/matavg_runtime_diivine.mat', 'runtime');
end