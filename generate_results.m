 d = uigetdir(pwd, 'Select face_img folder'); %Promt GUI for user to select folder
 files = dir(fullfile(d, '*.jpg'));
 
    mkdir result/eyes_detect;
    mkdir result/blob_extract;

    
for i = 1:length(files)
    file_name = strcat('face_img/',files(i).name);
    dest_name = strcat('result/eyes_detect/',files(i).name);
    blod_dir = strcat('result/blob_extract/',files(i).name);
    imwrite(eyes_detect(imread(file_name)), dest_name);
    imwrite(blob_extract(imread(file_name)), blod_dir);
end

