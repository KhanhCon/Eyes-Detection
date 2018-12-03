function [ eyes_detected_img ] = eyes_detect( face_img )
    %EYES_DETECT Detect eyes region then draw box around them
    
    %convert image to gray image
   gray_img = rgb2gray(face_img);
   %Edge detection with sobel
   edge_img = edge(gray_img,'sobel');
   % Dilate the image twice
   dilated_img = dilate(edge_img);
   %Inverse the image then fill the small holes
   negative_dilated_img = imcomplement(dilated_img);
   filled_img = imcomplement(rm_small_cmp(negative_dilated_img, 300));
   %Erode the image three times
   eroded_img = erode(filled_img);
%    eroded_img = blob_extract (face_img, edge_detect_type);
   %Aspect ratio rule
   aspect_img = aspect_ratio_rule(eroded_img);
   
   %The orientation angle of eyes is not greater than 45 degrees.
   angle_img = rm_large_orient(aspect_img,45.0);
   
   %Remove small components
   rm_img = rm_small_cmp(angle_img, 120);
   
   %Apply rules that compare two eyes
   hpadding = 40.0;
   vpadding = 80.0;
   eyes_ratio = 3.0;
   max_orient_diff = 30.0;
   eyes_slope_angle = 15.0;
   eyes_binary_img = two_eyes_rule(rm_img,hpadding,vpadding,eyes_ratio, max_orient_diff, eyes_slope_angle);
   %Draw box around the eyes
   eyes_detected_img = draw_box(eyes_binary_img, face_img );
      

end

function [eyes_binary_img] = two_eyes_rule(img,hpadding,vpadding,eyes_ratio, max_orient_diff, eyes_slope_angle)
    CC = bwconncomp(img,4);
   stats = regionprops(CC,'all'); 

    idx_size = [];
    [y,x] = size(img);
    for i1 = 1 : length(stats) 
        comp1 = stats(i1);
        for  i2 = 1:length(stats)          
         if i1 == i2
                continue;
            end
            comp2 = stats(i2);
         
            far_from_border = far_from_border_rule( comp1,comp2, hpadding,vpadding,x,y);
            ratio_match = ratio_rule (comp1, comp2, eyes_ratio);
            orient_match = orient_rule (comp1, comp2, max_orient_diff);
            slope_angle_match = slope_angle_rule (comp1, comp2 ,eyes_slope_angle);
            if far_from_border && ratio_match && orient_match && slope_angle_match 
                idx_size = [idx_size i1 i2];
                break;
            end 
        end                     
     end
   eyes_binary_img = ismember(labelmatrix(CC), idx_size);
end

function [ far_from_border ] = far_from_border_rule( comp1,comp2 ,hpadding,vpadding,x,y)
    bb1 = comp1.BoundingBox;
    far_from_border1 = hpadding<bb1(1) && bb1(1)+bb1(3)<x-hpadding  && vpadding<bb1(2)&& bb1(2)+bb1(4)<y-vpadding;
    bb2 = comp2.BoundingBox;
    far_from_border2 = hpadding<bb2(1) && bb2(1)+bb2(3)<x-hpadding  && vpadding<bb2(2)&& bb2(2)+bb2(4)<y-vpadding;
    far_from_border = far_from_border1 && far_from_border2;
end

function [ratio_match] = ratio_rule (comp1, comp2, eyes_ratio)
    ratio = comp1.Area/comp2.Area;
    ratio_match = ratio > 1/eyes_ratio && ratio < eyes_ratio;
end

function [orient_match] = orient_rule (comp1, comp2, max_orient_diff)
   orient_match = comp1.Orientation - comp2.Orientation < max_orient_diff;
end

function [slope_angle_match] = slope_angle_rule (comp1, comp2, eyes_slope_angle)
   bb1 = comp1.BoundingBox;
   bb2 = comp2.BoundingBox;
   center1 = [bb1(1)+bb1(3)/2,bb1(2)+bb1(4)/2 ];
   center2 = [bb2(1)+bb2(3)/2, bb2(2)+bb2(4)/2];
   slope_angle = atan2(center2(2)-center1(2),center2(1)-center1(1))* 180/pi;
   slope_angle = abs(slope_angle);
   if slope_angle >  90.0
        slope_angle = 180.0 - slope_angle;
   end
   slope_angle_match = slope_angle < eyes_slope_angle;
end

function [ aspect_ratio_img ] = aspect_ratio_rule( img )
% aspect_ratio: Keep components that have 0.8 < w/h < 4.0

    CC = bwconncomp(img,4);
    stats = regionprops(CC,'all');
    %Aspect ratio rule
    idx_boundingbox = [];
    for k = 1 : length(stats) 
        BB = stats(k).BoundingBox; 
        aspect_ratio = BB(3)/BB(4);
        if aspect_ratio > 0.8 && aspect_ratio < 4.0
            idx_boundingbox = [idx_boundingbox k];
        end
    end

    aspect_ratio_img = ismember(labelmatrix(CC), idx_boundingbox);
    
end

function [ dilated_img ] = dilate( edge_img )
    %dilate Dilate img twice

    SE = strel('disk', 3);
    dilated_img = imdilate(edge_img,SE);
     dilated_img = imdilate(dilated_img,SE);

end

function [ eroded_img ] = erode( filled_img )
    %erode Erode image three times

    SE = strel('disk', 3);
    eroded_img = imerode(filled_img,SE);
    eroded_img = imerode(eroded_img,SE);
    eroded_img = imerode(eroded_img,SE);

end

function [ angle_img ] = rm_large_orient( img, max_orientation )
%rm_large_orient: Remove component with orientation larger than a choosen
%angle

CC = bwconncomp(img,4);
stats = regionprops(CC,'Orientation');
idx = find([stats.Orientation] <= max_orientation); 
angle_img = ismember(labelmatrix(CC), idx);
% figure(),imshow(angle_img),title('angle');

end

function [ rm_img ] = rm_small_cmp( img, min_area )
%rm_small_cmp remove components that are small than min_area
%   Detailed explanation goes here min_are rm2 = 120
    CC = bwconncomp(img,4);
    stats = regionprops(CC,'Area');
    idx = find([stats.Area] > min_area); 
    rm_img = ismember(labelmatrix(CC), idx);
end

function [ eyes_detected_img ] = draw_box( final_binary_img, original_img )
%draw_box: Draw box around the eyes region
%   Detailed explanation goes here

CC = bwconncomp(final_binary_img,4); %final image
stats = regionprops(CC,'BoundingBox');
eyes_detected_img = original_img;
    for k = 1 : length(stats)
        BB = stats(k).BoundingBox;
        f = @() rectangle('Position', [BB(1),BB(2),BB(3),BB(4)]);
        params = {{'EdgeColor','r','LineWidth',2}};
        eyes_detected_img = insertInImage(eyes_detected_img,f,params);
%     rectangle('Position', [BB(1),BB(2),BB(3),BB(4)], 'EdgeColor','r','LineWidth',2 ); 
    end

end



