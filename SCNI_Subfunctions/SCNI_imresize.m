function newimg = NIF_imresize(img,nw,nh)

%=========================== NIF_imresize.m ===============================
% Called when the Image Processing Toolbox's 'imresize.m' is not available.
% Resizes an image using bicubic interpolation
%
% 	NEWIMG = NIF_IMRESIZE(IMG,NW,NH) Given input image IMG,
% 	returns a new image NEWIMG of size NW x NH.

if nargin ~= 3
    if numel(nw)==1
        error('usage: im_resize(image,new_wid,new_ht)');
    elseif numel(nw)==2
        nh = nw(2);
        nw = nw(1);
    end
end

ht_scale    = size(img,1) / nh;
wid_scale   = size(img,2) / nw;
for c = 1:size(img,3)
    newimg(:,:,c)      = interp2(img(:,:,c),(1:nw)*wid_scale,(1:nh)'*ht_scale,'cubic');
end