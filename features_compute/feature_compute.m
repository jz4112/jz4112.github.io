function feature_compute(im)
tic
%%%%%%%%%%%%%% diivine %%%%%%%%%%%%%%

im = double(im);

% Function to extract features given an image
%% Constants
num_or = 6;
num_scales = 2;
gam = 0.2:0.001:10;
r_gam = gamma(1./gam).*gamma(3./gam)./(gamma(2./gam)).^2;

%% Wavelet Transform +  Div. Norm.

[pyr pind] = buildSFpyr(im,num_scales,num_or-1);

[subband size_band] = norm_sender_normalized(pyr,pind,num_scales,num_or,1,1,3,3,50);


f = [];

%% Marginal Statistics


h_horz_curr = [];
for ii = 1:length(subband)
    t = subband{ii}; 
    mu_horz = mean(t);
    sigma_sq_horz(ii) = mean((t-mu_horz).^2);
    E_horz = mean(abs(t-mu_horz));
    rho_horz = sigma_sq_horz(ii)/E_horz^2;
    [min_difference, array_position] = min(abs(rho_horz - r_gam));
    gam_horz(ii) = gam(array_position);    
end
f = [f sigma_sq_horz gam_horz]; % ind. subband stats f1-f24

%% Joint Statistics


clear sigma_sq_horz gam_horz
for ii = 1:length(subband)/2
    t = [subband{ii}; subband{ii+num_or}];
    mu_horz = mean(t);
    sigma_sq_horz(ii) = mean((t-mu_horz).^2);
    E_horz = mean(abs(t-mu_horz));
    rho_horz = sigma_sq_horz(ii)/E_horz^2;
    [min_difference, array_position] = min(abs(rho_horz - r_gam));
    gam_horz(ii) = gam(array_position);
end
f = [f gam_horz];
t = cell2mat(subband');
mu = mean(t);
sigma_sq = mean((t-mu_horz).^2);
E_horz = mean(abs(t-mu_horz));
rho_horz = sigma_sq/E_horz^2;
[min_difference, array_position] = min(abs(rho_horz - r_gam));
gam_horz = gam(array_position);

f = [f gam_horz];

%% Hp-BP correlations


hp_band = pyrBand(pyr,pind,1);
for ii = 1:length(subband)
    curr_band = pyrBand(pyr,pind,ii+1);
    [ssim_val(ii), ssim_map, cs_val(ii)] = ssim_index_new(imresize(curr_band,size(hp_band)),hp_band);
end
f = [f cs_val];


%% Spatial Correlation
% 
% b = [];
% for i = 1:length(subband)/2
%     b = [b find_spatial_hist_fast(reshape(subband{i},(size_band(i,:))))];
% end
% f = [f b];

%%  Orientation feature...
% f74 - f88
l = 1; clear ssim_val cs_val
for i = 1:length(subband)/2
    for j = i+1:length(subband)/2
      [ssim_val(l), ssim_map, cs_val(l)] = ssim_index_new(reshape(subband{i},size_band(i,:)),reshape(subband{j},size_band(j,:)));  
      l = l + 1;
    end
end
f = [f cs_val];

%if x > 73 then x -= 30
x_diiv_mobile = [];
indices_mobile = [30,26,27,31,54,29,55];
for i = 1 : 7
    x_diiv_mobile = [x_diiv_mobile f(1, indices_mobile(i))];
end


%if x > 73 then x -= 30
x_diiv_pc = [];
indices_pc = [26, 54, 30, 31, 55, 29, 51, 2, 6];
for i = 1 : 9
    x_diiv_pc = [x_diiv_pc f(1, indices_pc(i))];
end


%%%%%%%%%%%%%% brisque  %%%%%%%%%%%%%%%%%%%%%%

scalenum = 2;
window = fspecial('gaussian',7,7/6);
window = window/sum(sum(window));

feat = [];
for itr_scale = 1:scalenum

mu            = filter2(window, im, 'same');
mu_sq         = mu.*mu;
sigma         = sqrt(abs(filter2(window, im.*im, 'same') - mu_sq));
structdis     = (im-mu)./(sigma+1);

[alpha overallstd]       = estimateggdparam(structdis(:));
feat                     = [feat alpha overallstd^2]; % f1, f2, f19, f20

shifts                   = [ 0 1;1 0 ; 1 1; -1 1];
 
for itr_shift =1:4

shifted_structdis        = circshift(structdis,shifts(itr_shift,:));
pair                     = structdis(:).*shifted_structdis(:);
[alpha leftstd rightstd] = estimateaggdparam(pair);
const                    =(sqrt(gamma(1/alpha))/sqrt(gamma(3/alpha)));
meanparam                =(rightstd-leftstd)*(gamma(2/alpha)/gamma(1/alpha))*const;

feat                     =[feat alpha meanparam leftstd^2 rightstd^2]; 

% f3, f4, .., f18, f21, f22, .., f36
end
im                   = imresize(im,0.5);
end


% res = [f feat];


x_bris_pc = feat(1, 17);


x_bris_mobile = [];
indices_mobile = [17, 13, 9];
for i = 1:3
    x_bris_mobile = [x_bris_mobile feat(1, indices_mobile(i))];
end

x_pc = [x_diiv_pc x_bris_pc];

x_mobile = [x_diiv_mobile(1, 1) x_bris_mobile(1,1) x_diiv_mobile(1,2) x_diiv_mobile(1,3) x_bris_mobile(1, 2) x_bris_mobile(1, 3) x_diiv_mobile(1,4:7)];

toc
% end

% mobile %
% from DIIVINE: 30, bris_17, 26, 27, bris_13, bris_9, 31, 84, 29, 85 
% from BRISQUE: 17, 13, 9
% x_rf <- c('V30', 'V105', 'V26', 'V27', 'V101', 'V97', 'V31', 'V84', 'V29', 'V85')

