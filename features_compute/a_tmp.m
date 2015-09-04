size_full = [];
t_full = [];
t_1 = [];
t_2 = [];
t_3 = [];
t_4 = [];
r = 1 + (2000-1) .* rand(1, 50);
for i = 1:50
	im = rgb2gray(imread(['../public/splits/' int2str(floor(r(1,i))) '.jpg']));
	
    try
        tmp = tic;
        feature_compute_fast(im)
        t_delta  = toc(tmp);


        size_im = size(im);
        x = size_im(1,1) / 2;
        y = size_im(1,2) / 2;

        if (x >= 100 && y >= 100)

            im_1 = im(1:x, 1:y);
            im_2 = im(1:x, y+1:y*2);
            im_3 = im(x+1:x*2, 1:y);
            im_4 = im(x+1:x*2, y+1:y*2);

            tmp = tic;
            feature_compute_fast(im_1);
            t_1_delta = toc(tmp);


            tmp = tic;
            feature_compute_fast(im_2);
            t_2_delta = toc(tmp);


            tmp = tic;
            feature_compute_fast(im_3);
            t_3_delta = toc(tmp);


            tmp = tic;
            feature_compute_fast(im_4);
            t_4_delta = toc(tmp);


            t_full = [t_full t_delta];
            size_full = [size_full x*y*4];

            t_1 = [t_1 t_1_delta];
            t_2 = [t_2 t_2_delta];
            t_3 = [t_3 t_3_delta];	
            t_4 = [t_4 t_4_delta];
        end
    
    catch exception
        floor(r(i))
    end
    
end