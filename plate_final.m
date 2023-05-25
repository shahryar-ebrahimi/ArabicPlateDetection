
clc
clear
close all

%% Extract Region of Interest

coefficient_min = 0.15;
coefficient_max = 0.3;

sample = imread('sample_17.jpg');
sample = imresize(sample, [1600, 2048]);
sample_gray = rgb2gray(sample);
sample_edge = edge(sample_gray, 'sobel', 0.15, 'vertical');

SE = strel('rectangle', [20 30]);
sample_close = imclose(sample_edge,SE);
[m, n, ~] = size(sample);
sample_connected = regionprops('struct',bwconncomp(sample_close,4), ...
    'BoundingBox','Image','Area','Extent','Centroid','Solidity','PixelIdxList',...
    'PixelList');

for i = 1:length(sample_connected)
    coefficient = sample_connected(i).BoundingBox(4)/sample_connected(i).BoundingBox(3);
    if sample_connected(i).Area<m*n/10000 || coefficient<coefficient_min || coefficient>coefficient_max
        sample_close(sample_connected(i).PixelIdxList) = 0;
    else
        k = i;
    end
end

first_point_row = floor(sample_connected(k).BoundingBox(1));
first_point_col = floor(sample_connected(k).BoundingBox(2));
first_point_row = round(0.997*first_point_row);
end_point_row = round(1.003*(first_point_row+sample_connected(k).BoundingBox(3)));
first_point_col = round(0.997*first_point_col);
end_point_col = round(1.003*(first_point_col+sample_connected(k).BoundingBox(4)));
region_of_plate = sample(first_point_col:end_point_col,first_point_row:end_point_row,:);
region_of_plate = uint8(region_of_plate);
region_of_plate = rgb2hsv(region_of_plate);
region_of_plate = region_of_plate(:,:,3);


%% Segmentation

thresholded_region = adaptthresh(region_of_plate,...
        'ForegroundPolarity','dark');
region_of_plate = region_of_plate<(thresholded_region);
[m,n] = size(region_of_plate);
region_of_plate_connected = regionprops('struct',bwconncomp(region_of_plate,4),'BoundingBox','Image','Area','Extent','Centroid','Solidity','PixelIdxList','PixelList');
area = zeros(1,length(region_of_plate_connected));

for i = 1:length(region_of_plate_connected)
    area(i) = region_of_plate_connected(i).Area;
end

[area_max,area_max_index] = max(area);
region_of_plate(region_of_plate_connected(area_max_index).PixelIdxList) = 0;
for i = 1:length(region_of_plate_connected)
     if  region_of_plate_connected(i).BoundingBox(3)/region_of_plate_connected(i).BoundingBox(4)>2.5
          region_of_plate(region_of_plate_connected(i).PixelIdxList) = 0;
     end
end

horizontal_projection = sum(region_of_plate);
vertical_projection = sum(region_of_plate,2);
[~,locations_h] = findpeaks(horizontal_projection,1:n);
[~,locations_v] = findpeaks(vertical_projection,1:m);
[m,n] = size(region_of_plate);

a = 1;
b = n;
for i = 1:n
    if horizontal_projection(i)<5 && i<locations_h(1)
        a = i;
    end
    if horizontal_projection(i)<5 && i>locations_h(end)
        b = i;
        break
    end
end

c = 1;
d = m;
for i = 1:m
    if vertical_projection(i)<10 && i<locations_v(1)
        c = i;
    end
    if vertical_projection(i)<10 && i>locations_v(end)
        d = i;
        break
    end
end

region_of_plate = region_of_plate(c:d,a:b);
figure
imshow(region_of_plate)
title('Using Pojection')
region_of_plate_plus = region_of_plate;
region_of_plate_plus_connected = regionprops('struct',bwconncomp(region_of_plate_plus,4),'BoundingBox','Image','Area','Extent','Centroid','Solidity','PixelIdxList','PixelList');
for i = 1:length(region_of_plate_plus_connected)
     if region_of_plate_plus_connected(i).Area < m*n/200
         region_of_plate_plus(region_of_plate_plus_connected(i).PixelIdxList) = 0;
     end
end

figure
imshow(region_of_plate_plus)
title('Using Area')

%% OCR

text = ocr(region_of_plate,'Language','C:\Users\Shahryar\Desktop\Plate\plak2\Persian\tessdata\Persian.traineddata','TextLayout','Word');
text_plus = ocr(region_of_plate_plus,'Language','C:\Users\Shahryar\Desktop\Plate\plak2\Persian\tessdata\Persian.traineddata','TextLayout','Word');
text_mean = nanmean(text.CharacterConfidences);
text_plus_mean = nanmean(text_plus.CharacterConfidences);
if  text_plus_mean>text_mean
    text_final = text_plus;
    text_final_mean = text_plus_mean;
else
    text_final = text;
    text_final_mean = text_mean;
end
text_final_revised = '';
num = 0;
for i = 1:length(text_final.Text)
    if ~isnan(text_final.CharacterConfidences(i)) && text_final.CharacterConfidences(i)>text_final_mean-0.15
        num = num + 1;
        text_final_revised(num) = text_final.Text(i);
    end
end


