
function [blob_extracted] = blob_extract (img)
% blob_extract: Extract blob before applying rules
grey_img = rgb2gray(img);
edge_img = edge(grey_img,'sobel');
SE = strel('disk', 3);
%Dilate image twice
dilated_img = imdilate(edge_img,SE); 
dilated_img = imdilate(dilated_img,SE);
%Inverse the dilated img to fill holes
negative_dilated_img = imcomplement(dilated_img);
CC = bwconncomp(negative_dilated_img,4);
stats_first = regionprops(CC,'Area');
idx = find([stats_first.Area] > 300); 
ne_img_with_holes = ismember(labelmatrix(CC), idx);
filled_img = imcomplement(ne_img_with_holes);
%Erode image three times
eroded_img = imerode(filled_img,SE);
eroded_img = imerode(eroded_img,SE);
eroded_img = imerode(eroded_img,SE);
blob_extracted = eroded_img;
end