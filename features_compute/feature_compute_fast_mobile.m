% function x_mobile = feature_compute_fast_mobile(im)

% mobile %
% from DIIVINE: 30, bris_17, 26, 27, bris_13, bris_9, 31, 84, 29, 85 
% from BRISQUE: 17, 13, 9
% x_rf <- c('V30', 'V105', 'V26', 'V27', 'V101', 'V97', 'V31', 'V84', 'V29', 'V85')


im = double(im);
%% Constants
num_or = 6;
num_scales = 2;
gam = 0.2:0.001:10;
r_gam = gamma(1./gam).*gamma(3./gam)./(gamma(2./gam)).^2;

%% Wavelet Transform +  Div. Norm.

if(size(im,3)~=1)
    im = (double(rgb2gray(im)));
end
[pyr pind] = buildSFpyr(im,num_scales,num_or-1);

[subband size_band] = norm_sender_normalized(pyr,pind,num_scales,num_or,1,1,3,3,50);

% length(subband) = 12

f = [];

%% Joint Statistics   % f25 - f31
% f26, 27, 29, 30, 31

indices = [2,3,5,6];
for ind = 1:4
    ii = indices(ind);
    t = [subband{ii}; subband{ii+num_or}];
    mu_horz = mean(t);
    sigma_sq_horz(ii) = mean((t-mu_horz).^2);
    E_horz = mean(abs(t-mu_horz));
    rho_horz = sigma_sq_horz(ii)/E_horz^2;
    [min_difference, array_position] = min(abs(rho_horz - r_gam));
    gam_horz = gam(array_position);
    f = [f gam_horz];
end
t = cell2mat(subband');
mu = mean(t);
sigma_sq = mean((t-mu_horz).^2);
E_horz = mean(abs(t-mu_horz));
rho_horz = sigma_sq/E_horz^2;
[min_difference, array_position] = min(abs(rho_horz - r_gam));
gam_horz = gam(array_position);

f = [f gam_horz];

%%  Orientation feature  % f74 - f88
% f84 85
i_list = [3,3];
j_list = [5,6];
wind = fspecial('gaussian', 11, 1.5);
wind = wind/sum(sum(wind));
C1 = 6.5025;
C2 = 58.5225;
% K(1) = 0.01;                                  
% K(2) = 0.03; 
for turn = 1:2
    i = i_list(turn);
    j = j_list(turn);

    img1 = reshape(subband{i},size_band(i,:));
    img2 = reshape(subband{j},size_band(j,:));

    if (size(img1) ~= size(img2))
       ssim_index = -Inf;
       ssim_map = -Inf;
       return;
    end

    [M N] = size(img1);

    if ((M < 11) | (N < 11))
       ssim_index = -Inf;
       ssim_map = -Inf;
       return
    end
    mu1   = filter2(wind, img1, 'valid');
    mu2   = filter2(wind, img2, 'valid');
    mu1_sq = mu1.*mu1;
    mu2_sq = mu2.*mu2;
    mu1_mu2 = mu1.*mu2;
    sigma1_sq = filter2(wind, img1.*img1, 'valid') - mu1_sq;
    sigma2_sq = filter2(wind, img2.*img2, 'valid') - mu2_sq;
    sigma12 = filter2(wind, img1.*img2, 'valid') - mu1_mu2;

    mcs = mean2((2*sigma12 + C2)./(sigma1_sq + sigma2_sq + C2));

    f = [f mcs];
end

% for mobile, brisque features 9th, 13th, 17th 

window = fspecial('gaussian',7,7/6);
window = window/sum(sum(window));

mu            = filter2(window, im, 'same');
mu_sq         = mu.*mu;
sigma         = sqrt(abs(filter2(window, im.*im, 'same') - mu_sq));
structdis     = (im-mu)./(sigma+1);

shifts                   = [ 0 1;1 0 ; 1 1; -1 1];
 
for itr_shift =2:4
    shifted_structdis        = circshift(structdis,shifts(itr_shift,:));
    pair                     = structdis(:).*shifted_structdis(:);
    [alpha leftstd rightstd] = estimateaggdparam(pair);

    f                     =[f leftstd^2]; 
end


x_mobile = [f(4) f(10) f(1) f(2) f(9) f(8) f(5) f(6) f(3) f(7)];
